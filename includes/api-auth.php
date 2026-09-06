<?php
/**
 * Bearer tokens for the mobile app.
 *
 * One row per app install. A token is issued as a guest token and upgraded in
 * place on login, so the cart and wishlist a shopper built before signing in
 * are not lost.
 *
 * The cart and applied coupon are mirrored into the token row because the app
 * has no session cookie. api_state_load() copies them into $_SESSION before a
 * request runs and api_state_save() writes them back, which lets every
 * existing cart/coupon/wishlist helper be reused unchanged.
 */

declare(strict_types=1);

const API_TOKEN_TTL_DAYS = 180;

function api_tokens_available(): bool
{
    return tc_table_exists('api_tokens');
}

/** Create a token row and return the raw token string. */
function api_token_issue(?int $customerId = null, string $device = '', string $platform = ''): string
{
    $token = bin2hex(random_bytes(32));

    db()->prepare(
        'INSERT INTO api_tokens (token, customer_id, device_name, platform, last_used_at, expires_at)
         VALUES (?, ?, ?, ?, NOW(), DATE_ADD(NOW(), INTERVAL ' . API_TOKEN_TTL_DAYS . ' DAY))'
    )->execute([
        $token,
        $customerId,
        $device !== '' ? mb_substr($device, 0, 120) : null,
        $platform !== '' ? mb_substr($platform, 0, 20) : null,
    ]);

    return $token;
}

/** The token row, or null when unknown/expired. */
function api_token_row(string $token): ?array
{
    if ($token === '' || !preg_match('/^[a-f0-9]{64}$/', $token)) {
        return null;
    }
    $stmt = db()->prepare(
        'SELECT * FROM api_tokens
         WHERE token = ? AND (expires_at IS NULL OR expires_at > NOW()) LIMIT 1'
    );
    $stmt->execute([$token]);
    $row = $stmt->fetch();
    return $row ?: null;
}

function api_token_touch(string $token): void
{
    db()->prepare(
        'UPDATE api_tokens
            SET last_used_at = NOW(),
                expires_at   = DATE_ADD(NOW(), INTERVAL ' . API_TOKEN_TTL_DAYS . ' DAY)
          WHERE token = ?'
    )->execute([$token]);
}

/** Bind a guest token to a customer after a successful login/registration. */
function api_token_attach_customer(string $token, int $customerId): void
{
    db()->prepare('UPDATE api_tokens SET customer_id = ? WHERE token = ?')->execute([$customerId, $token]);
}

function api_token_revoke(string $token): void
{
    db()->prepare('DELETE FROM api_tokens WHERE token = ?')->execute([$token]);
}

/** Revoke every token of a customer (e.g. "sign out of all devices"). */
function api_token_revoke_all(int $customerId): void
{
    db()->prepare('DELETE FROM api_tokens WHERE customer_id = ?')->execute([$customerId]);
}

/**
 * Drop expired tokens, plus guest tokens that were never used again.
 *
 * Every request without a valid token mints a new guest token, so without this
 * the table grows with every crawler and every reinstall. Called
 * probabilistically from the API bootstrap, which is cheap enough to keep the
 * table tidy without needing a cron job.
 */
function api_tokens_gc(): void
{
    $db = db();

    $db->exec('DELETE FROM api_tokens WHERE expires_at IS NOT NULL AND expires_at < NOW()');

    // Abandoned guest tokens: never signed in, nothing saved, untouched for a
    // week. The literals cover the current empty state and the bare-cart rows
    // written before the wishlist moved in alongside it.
    $db->prepare(
        "DELETE FROM api_tokens
          WHERE customer_id IS NULL
            AND (cart_json IS NULL OR cart_json IN ('', '[]', '{}', ?))
            AND last_used_at < DATE_SUB(NOW(), INTERVAL 7 DAY)"
    )->execute([API_EMPTY_STATE]);
}

/* ---------------------------------------------------------------------------
   Cart / coupon / wishlist state carried by the token
--------------------------------------------------------------------------- */

/** The empty state, as api_state_save() encodes it. Used by the collector. */
const API_EMPTY_STATE = '{"cart":[],"wishlist":[]}';

/** Copy the token's stored state into the request session. */
function api_state_load(array $tokenRow): void
{
    $state = json_decode((string) ($tokenRow['cart_json'] ?? ''), true);

    if (isset($state['cart']) || isset($state['wishlist'])) {
        $_SESSION['cart']        = is_array($state['cart'] ?? null) ? $state['cart'] : [];
        $_SESSION['tc_wishlist'] = is_array($state['wishlist'] ?? null) ? $state['wishlist'] : [];
    } else {
        // Rows written before the wishlist was carried here held a bare cart.
        // (Cart keys look like "92:0", so they can never be mistaken for the
        // "cart"/"wishlist" keys above.)
        $_SESSION['cart']        = is_array($state) ? $state : [];
        $_SESSION['tc_wishlist'] = [];
    }

    // wishlist_items rows are keyed by tc_visitor_id(); pinning it to the
    // token gives the app a wishlist that survives across requests.
    $_SESSION['tc_visitor'] = (string) $tokenRow['token'];

    $coupon = (string) ($tokenRow['coupon_code'] ?? '');
    if ($coupon !== '') {
        $_SESSION['tc_coupon_code'] = $coupon;
    } else {
        unset($_SESSION['tc_coupon_code']);
    }
}

/**
 * Persist the session cart/wishlist/coupon back onto the token row.
 *
 * The wishlist normally lives in wishlist_items, but enterprise.php falls back
 * to the session when that table is absent. Without carrying that fallback
 * here the app's wishlist would vanish between requests on the base schema.
 */
function api_state_save(string $token): void
{
    db()->prepare('UPDATE api_tokens SET cart_json = ?, coupon_code = ? WHERE token = ?')
        ->execute([
            json_encode([
                'cart'     => $_SESSION['cart'] ?? [],
                'wishlist' => $_SESSION['tc_wishlist'] ?? [],
            ], JSON_UNESCAPED_UNICODE),
            $_SESSION['tc_coupon_code'] ?? null,
            $token,
        ]);
}

/**
 * Move a guest wishlist onto the customer's own token after login, so nothing
 * is lost and the rows are not duplicated.
 */
function api_merge_guest_wishlist(string $fromToken, string $toToken): void
{
    if ($fromToken === $toToken || !tc_table_exists('wishlist_items')) {
        return;
    }
    db()->prepare(
        'UPDATE IGNORE wishlist_items SET session_id = ? WHERE session_id = ?'
    )->execute([$toToken, $fromToken]);
    db()->prepare('DELETE FROM wishlist_items WHERE session_id = ?')->execute([$fromToken]);
}
