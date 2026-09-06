<?php
/**
 * Cart and coupons.
 *
 * Every mutation returns the complete cart, so the app updates its state from
 * one response instead of chasing a second GET.
 *
 * Prices, stock and coupon validity are always recomputed server-side — the
 * client's numbers are never trusted.
 */

declare(strict_types=1);

// Route files are includes, never entry points: without the front controller
// route() does not exist. .htaccess blocks them too; this is the fallback for
// servers where it is not applied.
if (!defined('TC_API')) {
    http_response_code(404);
    exit;
}

/** GET /cart */
route('GET', '/cart', static function (): void {
    api_ok(api_cart_payload());
});

/** GET /cart/count — cheap badge refresh for the app shell. */
route('GET', '/cart/count', static function (): void {
    api_ok(['count' => cart_count()]);
});

/**
 * POST /cart/items
 * Body: { product_id, variant_id?, quantity? }
 */
route('POST', '/cart/items', static function (): void {
    $productId = api_input_int('product_id');
    $variantId = api_input_int('variant_id') ?: null;
    $quantity  = max(1, min(99, api_input_int('quantity', 1)));

    if ($productId < 1) {
        api_invalid(['product_id' => 'Please choose a product.']);
    }

    $result = cart_add($productId, $variantId, $quantity);
    if (!$result['ok']) {
        api_fail((string) $result['message'], 422, ['cart' => (string) $result['message']]);
    }

    api_ok(api_cart_payload(), (string) $result['message']);
});

/**
 * Update one cart line.
 *
 *   PATCH /cart/items        Body: { key, quantity }
 *   PATCH /cart/items/{key}  Body: { quantity }
 *
 * A cart key looks like "92:0" (product:variant). The colon is legal in a path
 * segment but trips up some HTTP clients and proxies, so the body form is the
 * one to prefer; percent-encode the key if you use the path form.
 *
 * A quantity of 0 removes the line.
 */
$updateCartLine = static function (array $params = []): void {
    $key      = (string) ($params['key'] ?? api_input('key'));
    $quantity = api_input_int('quantity', 1);

    if ($key === '') {
        api_invalid(['key' => 'Which cart item should be updated?']);
    }
    if (!isset(cart_get()[$key])) {
        api_fail('That item is no longer in your cart.', 404);
    }

    if ($quantity < 1) {
        cart_remove($key);
        api_ok(api_cart_payload(), 'Item removed.');
    }

    $result = cart_update($key, min(99, $quantity));
    if (!$result['ok']) {
        api_fail((string) $result['message'], 422);
    }

    api_ok(api_cart_payload(), (string) $result['message']);
};

route('PATCH', '/cart/items', $updateCartLine);
route('PATCH', '/cart/items/{key}', $updateCartLine);

/**
 * Remove one cart line.
 *
 *   POST   /cart/items/remove  Body: { key }
 *   DELETE /cart/items/{key}
 */
$removeCartLine = static function (array $params = []): void {
    $key = (string) ($params['key'] ?? api_input('key'));

    if ($key === '') {
        api_invalid(['key' => 'Which cart item should be removed?']);
    }

    cart_remove($key);
    api_ok(api_cart_payload(), 'Item removed.');
};

route('POST', '/cart/items/remove', $removeCartLine);
route('DELETE', '/cart/items/{key}', $removeCartLine);

/** DELETE /cart — empty the cart and drop any applied coupon. */
route('DELETE', '/cart', static function (): void {
    cart_clear();
    unset($_SESSION['tc_coupon_code']);
    api_ok(api_cart_payload(), 'Your cart is now empty.');
});

/**
 * POST /cart/coupon
 * Body: { code }
 */
route('POST', '/cart/coupon', static function (): void {
    $code = api_input('code');
    if ($code === '') {
        api_invalid(['code' => 'Please enter a coupon code.']);
    }

    $totals = cart_totals();
    if ((float) $totals['subtotal'] <= 0) {
        api_fail('Add something to your cart before applying a coupon.', 422);
    }

    $result = tc_apply_coupon($code, (float) $totals['subtotal']);
    if (!$result['ok']) {
        api_fail((string) $result['error'], 422, ['code' => (string) $result['error']]);
    }

    $_SESSION['tc_coupon_code'] = $result['code'];

    api_ok(api_cart_payload(), 'Coupon applied — ' . money((float) $result['discount']) . ' off.');
});

/** DELETE /cart/coupon */
route('DELETE', '/cart/coupon', static function (): void {
    unset($_SESSION['tc_coupon_code']);
    api_ok(api_cart_payload(), 'Coupon removed.');
});
