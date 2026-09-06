<?php
/**
 * Authentication.
 *
 * The app always holds a token. /auth/guest hands one out on first launch;
 * register and login bind that same token to a customer so the guest cart and
 * wishlist carry over instead of being dropped at sign-in.
 */

declare(strict_types=1);

// Route files are includes, never entry points: without the front controller
// route() does not exist. .htaccess blocks them too; this is the fallback for
// servers where it is not applied.
if (!defined('TC_API')) {
    http_response_code(404);
    exit;
}

/* GET /health — connectivity + install check, no auth needed. */
route('GET', '/health', static function (): void {
    api_ok([
        'status'      => 'ok',
        'api_version' => 'v1',
        'store'       => setting('store_name', 'Fashlab Studio'),
        'server_time' => date('c'),
    ]);
});

/**
 * POST /auth/guest
 * Body: { device_name?, platform? }
 * Returns the token to store on the device. Calling it with an existing valid
 * token returns that token unchanged, so it is safe to call on every launch.
 */
route('POST', '/auth/guest', static function (): void {
    api_ok([
        'token'       => api_token(),
        'is_new'      => (bool) ($GLOBALS['api_token_is_new'] ?? false),
        'customer'    => current_customer() ? api_customer(current_customer()) : null,
        'cart_count'  => cart_count(),
        'wishlist_count' => wishlist_count(),
    ]);
});

/**
 * POST /auth/register
 * Body: { name, email, password, phone?, newsletter? }
 */
route('POST', '/auth/register', static function (): void {
    if (current_customer()) {
        api_fail('You are already signed in.', 409);
    }

    $result = customer_register(
        api_input('name'),
        api_input('email'),
        (string) (api_body()['password'] ?? ''),
        api_input('phone'),
        api_input_bool('newsletter')
    );

    if (!$result['ok']) {
        api_invalid($result['errors']);
    }

    $customer = $result['customer'];
    api_token_attach_customer(api_token(), (int) $customer['id']);
    $GLOBALS['tc_customer'] = $customer;

    api_ok([
        'token'    => api_token(),
        'customer' => api_customer($customer),
        'cart'     => api_cart_payload(),
    ], 'Welcome to ' . setting('store_name', 'Fashlab Studio') . '!', 201);
});

/**
 * POST /auth/login
 * Body: { email, password }
 *
 * The guest wishlist is merged onto the account before the token is bound, so
 * a shopper who saved items before signing in keeps them.
 */
route('POST', '/auth/login', static function (): void {
    $email    = api_input('email');
    $password = (string) (api_body()['password'] ?? '');

    if ($email === '' || $password === '') {
        api_invalid([
            'email'    => $email === '' ? 'Please enter your email address.' : null,
            'password' => $password === '' ? 'Please enter your password.' : null,
        ]);
    }

    $result = customer_authenticate($email, $password);
    if (!$result['ok']) {
        api_fail($result['message'], 401);
    }

    $customer = $result['customer'];

    // Carry the guest wishlist across, then adopt any items the account
    // already had on another device.
    $existing = db()->prepare(
        'SELECT token FROM api_tokens WHERE customer_id = ? AND token <> ? ORDER BY id DESC LIMIT 1'
    );
    $existing->execute([(int) $customer['id'], api_token()]);
    $previous = (string) ($existing->fetchColumn() ?: '');
    if ($previous !== '') {
        api_merge_guest_wishlist($previous, api_token());
    }

    api_token_attach_customer(api_token(), (int) $customer['id']);
    $GLOBALS['tc_customer'] = $customer;

    api_ok([
        'token'    => api_token(),
        'customer' => api_customer($customer),
        'cart'     => api_cart_payload(),
        'wishlist_count' => wishlist_count(),
    ], 'Welcome back, ' . ($customer['name'] ?: 'there') . '!');
});

/**
 * POST /auth/logout
 * Revokes this device's token. The app should then call /auth/guest.
 */
route('POST', '/auth/logout', static function (): void {
    api_require_customer();

    $token = api_token();
    // Stop the shutdown hook writing to a row that is about to disappear.
    $GLOBALS['api_token'] = '';
    api_token_revoke($token);

    api_ok(null, 'You have been signed out.');
});

/** POST /auth/logout-all — sign out of every device. */
route('POST', '/auth/logout-all', static function (): void {
    $customer = api_require_customer();

    $GLOBALS['api_token'] = '';
    api_token_revoke_all((int) $customer['id']);

    api_ok(null, 'You have been signed out on all devices.');
});

/** GET /auth/me — the signed-in customer plus counters for the app shell. */
route('GET', '/auth/me', static function (): void {
    $customer = api_require_customer();

    $stmt = db()->prepare('SELECT COUNT(*) FROM orders WHERE customer_email = ?');
    $stmt->execute([$customer['email']]);

    api_ok([
        'customer'       => api_customer($customer),
        'order_count'    => (int) $stmt->fetchColumn(),
        'cart_count'     => cart_count(),
        'wishlist_count' => wishlist_count(),
    ]);
});

/** PUT /auth/profile — Body: { name?, phone?, preferred_size?, newsletter_optin? } */
route('PUT', '/auth/profile', static function (): void {
    $customer = api_require_customer();

    $fields = array_intersect_key(
        api_body(),
        array_flip(['name', 'phone', 'preferred_size', 'newsletter_optin'])
    );

    $result = customer_update_profile((int) $customer['id'], $fields);
    if (!$result['ok']) {
        api_invalid($result['errors']);
    }

    api_ok(['customer' => api_customer($result['customer'])], 'Profile updated.');
});

/** POST /auth/change-password — Body: { current_password, new_password } */
route('POST', '/auth/change-password', static function (): void {
    $customer = api_require_customer();

    $result = customer_change_password(
        (int) $customer['id'],
        (string) (api_body()['current_password'] ?? ''),
        (string) (api_body()['new_password'] ?? '')
    );

    if (!$result['ok']) {
        api_fail($result['message'], 422);
    }

    api_ok(null, 'Password changed.');
});

/**
 * POST /auth/forgot-password — Body: { email }
 *
 * Always answers the same way, whether or not the email has an account, so the
 * endpoint cannot be used to enumerate customers. The token is returned only
 * in development, where no mailer is configured.
 */
route('POST', '/auth/forgot-password', static function (): void {
    $email = api_input('email');
    if (!valid_email($email)) {
        api_invalid(['email' => 'Please enter a valid email address.']);
    }

    $result = customer_create_reset_token($email);

    $data = null;
    if (APP_ENV === 'development' && $result['token'] !== null) {
        $data = ['reset_token' => $result['token']];
    }

    api_ok($data, 'If an account exists for that email, a reset link is on its way.');
});

/** POST /auth/reset-password — Body: { token, password } */
route('POST', '/auth/reset-password', static function (): void {
    $result = customer_reset_password(
        api_input('token'),
        (string) (api_body()['password'] ?? '')
    );

    if (!$result['ok']) {
        api_fail($result['message'], 422);
    }

    api_ok(null, 'Your password has been reset. Please sign in.');
});
