<?php
/**
 * Device session.
 *
 * There is no sign-in: the app shops as a guest, the same way a visitor does
 * on the website. The token issued here is an anonymous device identity that
 * carries the cart and the wishlist between requests, because a phone has no
 * session cookie to do it.
 */

declare(strict_types=1);

// Route files are includes, never entry points: without the front controller
// route() does not exist. .htaccess blocks them too; this is the fallback for
// servers where it is not applied.
if (!defined('TC_API')) {
    http_response_code(404);
    exit;
}

/* GET /health — connectivity + install check. */
route('GET', '/health', static function (): void {
    api_ok([
        'status'      => 'ok',
        'api_version' => 'v1',
        'store'       => setting('store_name', 'Fashlab Studio'),
        'server_time' => date('c'),
    ]);
});

/**
 * POST /session
 * Body: { device_name?, platform? }
 *
 * Call once on first launch and store the token. Safe to call on every launch:
 * presented with a valid token it returns that same token rather than starting
 * a new cart.
 */
route('POST', '/session', static function (): void {
    api_ok([
        'token'          => api_token(),
        'is_new'         => (bool) ($GLOBALS['api_token_is_new'] ?? false),
        'cart_count'     => cart_count(),
        'wishlist_count' => wishlist_count(),
    ]);
});
