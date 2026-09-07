<?php
/**
 * Mobile API bootstrap.
 *
 * Loads the same application layer the website uses, then swaps the HTML
 * behaviours (error pages, maintenance page, redirects) for JSON ones and
 * resolves the caller from the Authorization bearer token.
 */

declare(strict_types=1);

define('TC_API', true);

require_once __DIR__ . '/../../includes/bootstrap.php';
require_once __DIR__ . '/../../includes/api-auth.php';
require_once __DIR__ . '/helpers.php';

/* ---------------------------------------------------------------------------
   JSON error handling — the shared handler renders 500.php, which an app
   cannot parse.
--------------------------------------------------------------------------- */
set_exception_handler(static function (Throwable $e): void {
    error_log('[api] ' . $e->getMessage() . ' @ ' . $e->getFile() . ':' . $e->getLine());
    api_fail('Something went wrong. Please try again.', 500);
});

/* ---------------------------------------------------------------------------
   CORS. Same-origin app traffic does not need it, but Flutter Web and local
   tooling do, and a preflight must never reach a handler.
--------------------------------------------------------------------------- */
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, PATCH, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With');
header('Access-Control-Max-Age: 86400');
header('Content-Type: application/json; charset=utf-8');
header('X-Content-Type-Options: nosniff');

if (($_SERVER['REQUEST_METHOD'] ?? '') === 'OPTIONS') {
    http_response_code(204);
    exit;
}

/* ---------------------------------------------------------------------------
   Store closed — answer in JSON so the app can show its own screen.
   (includes/bootstrap.php exempts /api/ from the HTML maintenance page.)
--------------------------------------------------------------------------- */
if (!store_is_open()) {
    api_fail('The store is temporarily closed for maintenance.', 503);
}

if (!api_tokens_available()) {
    api_fail('The mobile API is not installed. Run migration-mobile-api.sql.', 503);
}

/* ---------------------------------------------------------------------------
   Identify the device.

   There is nothing to authenticate: the app shops as a guest, exactly as a
   visitor does on the website. The token is an anonymous device identity that
   carries the cart and wishlist, nothing more, so a missing or stale one is
   never an error — a fresh token is issued and returned in the X-Api-Token
   response header for the app to store.
--------------------------------------------------------------------------- */
$GLOBALS['api_token']        = '';
$GLOBALS['api_token_row']    = null;
$GLOBALS['api_token_is_new'] = false;

$presented = api_bearer_token();
$row = $presented !== '' ? api_token_row($presented) : null;

if ($row === null) {
    $issued = api_token_issue(api_header('X-Device-Name'), api_header('X-Platform'));
    $row = api_token_row($issued);
    $GLOBALS['api_token_is_new'] = true;
}

$GLOBALS['api_token']     = (string) $row['token'];
$GLOBALS['api_token_row'] = $row;

header('X-Api-Token: ' . $GLOBALS['api_token']);

api_state_load($row);
api_token_touch($GLOBALS['api_token']);

// Housekeeping on roughly one request in a hundred, so abandoned guest tokens
// do not accumulate. Never allowed to break the request it rides along with.
if (random_int(1, 100) === 1) {
    try {
        api_tokens_gc();
    } catch (Throwable $e) {
        error_log('[api] token gc failed: ' . $e->getMessage());
    }
}

// Cart/coupon changes made by a handler are written back once, at the end of
// the request, whether the handler returned normally or exited early.
register_shutdown_function(static function (): void {
    if (!empty($GLOBALS['api_token'])) {
        try {
            api_state_save((string) $GLOBALS['api_token']);
        } catch (Throwable $e) {
            error_log('[api] state save failed: ' . $e->getMessage());
        }
    }
});
