<?php
/**
 * Wishlist. Works for guest tokens too — the rows are keyed by the token, and
 * a guest wishlist is carried over to the account at login.
 */

declare(strict_types=1);

// Route files are includes, never entry points: without the front controller
// route() does not exist. .htaccess blocks them too; this is the fallback for
// servers where it is not applied.
if (!defined('TC_API')) {
    http_response_code(404);
    exit;
}

/** GET /wishlist */
route('GET', '/wishlist', static function (): void {
    $items = array_map(static fn (array $item): array => api_product_card($item['product']), wishlist_items());

    api_ok([
        'items' => $items,
        'count' => count($items),
    ]);
});

/** GET /wishlist/count */
route('GET', '/wishlist/count', static function (): void {
    api_ok(['count' => wishlist_count()]);
});

/** GET /wishlist/ids — for painting heart icons across a product grid. */
route('GET', '/wishlist/ids', static function (): void {
    api_ok(['ids' => wishlist_ids()]);
});

/**
 * POST /wishlist
 * Body: { product_id }
 * Idempotent: adding an item already saved is not an error.
 */
route('POST', '/wishlist', static function (): void {
    $productId = api_input_int('product_id');
    if ($productId < 1) {
        api_invalid(['product_id' => 'Please choose a product.']);
    }

    $stmt = db()->prepare('SELECT id FROM products WHERE id = ? AND status = 1 LIMIT 1');
    $stmt->execute([$productId]);
    if (!$stmt->fetchColumn()) {
        api_fail('Product not found.', 404);
    }

    // wishlist_ids() memoises per request, so its count is stale straight after
    // a write. Take the count the toggle itself computed.
    $count = in_array($productId, wishlist_ids(), true)
        ? wishlist_count()
        : (int) wishlist_toggle($productId)['count'];

    api_ok(['saved' => true, 'count' => $count], 'Saved to your wishlist.');
});

/**
 * POST /wishlist/toggle
 * Body: { product_id }
 */
route('POST', '/wishlist/toggle', static function (): void {
    $productId = api_input_int('product_id');
    if ($productId < 1) {
        api_invalid(['product_id' => 'Please choose a product.']);
    }

    $result = wishlist_toggle($productId);

    api_ok(
        ['saved' => (bool) $result['added'], 'count' => (int) $result['count']],
        $result['added'] ? 'Saved to your wishlist.' : 'Removed from your wishlist.'
    );
});

/** DELETE /wishlist/{product_id} */
route('DELETE', '/wishlist/{product_id}', static function (array $params): void {
    $productId = (int) $params['product_id'];

    $count = in_array($productId, wishlist_ids(), true)
        ? (int) wishlist_toggle($productId)['count']
        : wishlist_count();

    api_ok(['saved' => false, 'count' => $count], 'Removed from your wishlist.');
});

/**
 * POST /wishlist/move-to-cart
 * Body: { product_id, variant_id?, quantity? }
 */
route('POST', '/wishlist/move-to-cart', static function (): void {
    $productId = api_input_int('product_id');
    if ($productId < 1) {
        api_invalid(['product_id' => 'Please choose a product.']);
    }

    $result = cart_add($productId, api_input_int('variant_id') ?: null, max(1, api_input_int('quantity', 1)));
    if (!$result['ok']) {
        api_fail((string) $result['message'], 422);
    }

    $count = in_array($productId, wishlist_ids(), true)
        ? (int) wishlist_toggle($productId)['count']
        : wishlist_count();

    api_ok([
        'cart'           => api_cart_payload(),
        'wishlist_count' => $count,
    ], 'Moved to your cart.');
});
