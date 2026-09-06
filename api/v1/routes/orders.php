<?php
/**
 * Checkout and orders.
 *
 * Orders are created through includes/order-service.php — the same function
 * the website checkout calls — so stock, coupons and the inventory log behave
 * identically on both channels.
 */

declare(strict_types=1);

// Route files are includes, never entry points: without the front controller
// route() does not exist. .htaccess blocks them too; this is the fallback for
// servers where it is not applied.
if (!defined('TC_API')) {
    http_response_code(404);
    exit;
}

/**
 * GET /checkout — everything the checkout screen needs before it can submit:
 * live totals, delivery options, saved addresses and the payment methods that
 * are actually accepted.
 */
route('GET', '/checkout', static function (): void {
    $customer  = current_customer();
    $addresses = [];

    if ($customer && tc_table_exists('customer_addresses')) {
        $stmt = db()->prepare(
            'SELECT * FROM customer_addresses WHERE customer_id = ? ORDER BY is_default DESC, id DESC'
        );
        $stmt->execute([(int) $customer['id']]);
        $addresses = array_map('api_address', $stmt->fetchAll());
    }

    $shippingMethods = [];
    if (tc_table_exists('shipping_methods')) {
        $rows = db()->query(
            'SELECT * FROM shipping_methods WHERE status = 1 ORDER BY sort_order ASC, id ASC'
        )->fetchAll();
        $shippingMethods = array_map(static fn (array $m): array => [
            'code'           => (string) $m['code'],
            'name'           => (string) $m['name'],
            'description'    => $m['description'] ?? null,
            'fee'            => round((float) $m['fee'], 2),
            'formatted_fee'  => (float) $m['fee'] > 0 ? money((float) $m['fee']) : 'Free',
            'free_above'     => $m['free_above'] !== null ? round((float) $m['free_above'], 2) : null,
            'estimated_days' => $m['estimated_days'] ?? null,
        ], $rows);
    }

    if (!$shippingMethods) {
        $shippingMethods = array_values(array_map(static fn (array $o): array => [
            'code'           => $o['code'],
            'name'           => $o['label'],
            'description'    => $o['note'],
            'fee'            => $o['fee'],
            'formatted_fee'  => $o['fee'] > 0 ? money($o['fee']) : 'Included',
            'free_above'     => null,
            'estimated_days' => $o['note'],
        ], order_delivery_options()));
    }

    api_ok([
        'cart'      => api_cart_payload(),
        'customer'  => $customer ? api_customer($customer) : null,
        'addresses' => $addresses,
        'delivery_options' => $shippingMethods,
        // Only COD is offered: no payment gateway is connected, and taking a
        // card payment the store cannot settle would strand the order.
        'payment_methods'  => [
            ['code' => 'cod', 'name' => 'Cash on Delivery', 'enabled' => true],
        ],
        'free_shipping_threshold' => (float) setting('free_shipping_threshold', '8000'),
    ]);
});

/**
 * POST /orders — place the order from the current cart.
 * Body: { name, email, phone, address, city, postal_code?, notes?,
 *         delivery?, address_id?, is_gift?, gift_message? }
 *
 * Prices, shipping and the coupon are recalculated server-side; anything the
 * client sends about money is ignored.
 */
route('POST', '/orders', static function (): void {
    $customer = current_customer();

    $input = [
        'name'        => api_input('name', $customer['name'] ?? ''),
        'email'       => api_input('email', $customer['email'] ?? ''),
        'phone'       => api_input('phone', $customer['phone'] ?? ''),
        'address'     => api_input('address'),
        'city'        => api_input('city'),
        'postal_code' => api_input('postal_code'),
        'notes'       => api_input('notes'),
        'delivery'    => api_input('delivery', 'standard'),
        'country'     => api_input('country', 'Pakistan'),
        'is_gift'     => api_input_bool('is_gift'),
        'gift_message'=> api_input('gift_message'),
        'customer_id' => $customer ? (int) $customer['id'] : null,
    ];

    // A saved address wins over loose fields, so the app can post just an id.
    $addressId = api_input_int('address_id');
    if ($addressId > 0 && $customer && tc_table_exists('customer_addresses')) {
        $stmt = db()->prepare('SELECT * FROM customer_addresses WHERE id = ? AND customer_id = ? LIMIT 1');
        $stmt->execute([$addressId, (int) $customer['id']]);
        $saved = $stmt->fetch();
        if (!$saved) {
            api_fail('That saved address could not be found.', 404);
        }
        $input['address']     = (string) $saved['address'];
        $input['city']        = (string) $saved['city'];
        $input['postal_code'] = (string) ($saved['postal_code'] ?? '');
        $input['country']     = (string) ($saved['country'] ?? 'Pakistan');
        if (!empty($saved['name']))  $input['name']  = (string) $saved['name'];
        if (!empty($saved['phone'])) $input['phone'] = (string) $saved['phone'];
    }

    $result = place_order($input);

    if (!$result['ok']) {
        api_invalid($result['errors'], $result['errors']['cart'] ?? 'Please check the highlighted fields.');
    }

    $order = order_by_number((string) $result['order_number']);

    api_ok([
        'order' => $order ? api_order_detail($order) : null,
        'cart'  => api_cart_payload(),
    ], 'Order ' . $result['order_number'] . ' placed. Thank you!', 201);
});

/** GET /orders — the signed-in customer's order history. */
route('GET', '/orders', static function (): void {
    $customer = api_require_customer();

    $page    = max(1, api_query_int('page', 1));
    $perPage = max(1, min(50, api_query_int('per_page', 20)));

    // Match on customer_id when the migration column exists, and always on the
    // email, so orders placed as a guest before signing up still show up.
    $where  = 'customer_email = ?';
    $params = [$customer['email']];
    if (tc_column_exists('orders', 'customer_id')) {
        $where = '(customer_id = ? OR customer_email = ?)';
        $params = [(int) $customer['id'], $customer['email']];
    }

    $countStmt = db()->prepare("SELECT COUNT(*) FROM orders WHERE {$where}");
    $countStmt->execute($params);
    $total = (int) $countStmt->fetchColumn();

    $stmt = db()->prepare(
        "SELECT o.*, (SELECT COUNT(*) FROM order_items oi WHERE oi.order_id = o.id) AS item_count
           FROM orders o
          WHERE {$where}
          ORDER BY o.id DESC
          LIMIT {$perPage} OFFSET " . (($page - 1) * $perPage)
    );
    $stmt->execute($params);

    api_ok(api_paginated(array_map('api_order_summary', $stmt->fetchAll()), $page, $perPage, $total));
});

/**
 * GET /orders/{order_number}
 * Signed-in customers see their own orders. Guests may pass ?contact= with the
 * email or phone on the order, which is the same check the website's tracking
 * page uses.
 */
route('GET', '/orders/{order_number}', static function (array $params): void {
    $orderNumber = (string) $params['order_number'];
    $customer    = current_customer();

    $order = null;

    if ($customer) {
        $order = order_by_number($orderNumber);
        if ($order && mb_strtolower((string) $order['customer_email']) !== mb_strtolower((string) $customer['email'])) {
            $sameId = tc_column_exists('orders', 'customer_id')
                && (int) ($order['customer_id'] ?? 0) === (int) $customer['id'];
            if (!$sameId) {
                $order = null;
            }
        }
    }

    if (!$order) {
        $contact = api_query('contact');
        if ($contact === '') {
            api_fail('Order not found.', 404);
        }
        $order = tc_find_order($orderNumber, $contact);
    }

    if (!$order) {
        api_fail('Order not found. Please check the order number and contact details.', 404);
    }

    api_ok(['order' => api_order_detail($order)]);
});

/**
 * POST /orders/track — Body: { order_number, contact }
 * Guest tracking: the contact must match the email or phone on the order.
 */
route('POST', '/orders/track', static function (): void {
    $orderNumber = api_input('order_number');
    $contact     = api_input('contact');

    if ($orderNumber === '' || $contact === '') {
        api_invalid([
            'order_number' => $orderNumber === '' ? 'Please enter your order number.' : null,
            'contact'      => $contact === '' ? 'Please enter the email or phone used on the order.' : null,
        ]);
    }

    $order = tc_find_order($orderNumber, $contact);
    if (!$order) {
        api_fail('We could not find that order. Please check the details and try again.', 404);
    }

    api_ok(['order' => api_order_detail($order)]);
});

/**
 * POST /orders/{order_number}/cancel — Body: { reason? }
 * Allowed while the order is still pending or confirmed; stock is returned.
 */
route('POST', '/orders/{order_number}/cancel', static function (array $params): void {
    $customer = api_require_customer();

    $order = order_by_number((string) $params['order_number']);
    $owns  = $order
        && (mb_strtolower((string) $order['customer_email']) === mb_strtolower((string) $customer['email'])
            || (tc_column_exists('orders', 'customer_id') && (int) ($order['customer_id'] ?? 0) === (int) $customer['id']));

    if (!$owns) {
        api_fail('Order not found.', 404);
    }

    $result = order_cancel($order, api_input('reason'));
    if (!$result['ok']) {
        api_fail($result['message'], 409);
    }

    api_ok(['order' => api_order_detail(order_by_number((string) $order['order_number']))], $result['message']);
});

/**
 * POST /orders/{order_number}/reorder — put a past order's items back in the
 * cart. Items that are gone or out of stock are reported, not silently dropped.
 */
route('POST', '/orders/{order_number}/reorder', static function (array $params): void {
    $customer = api_require_customer();

    $order = order_by_number((string) $params['order_number']);
    if (!$order || mb_strtolower((string) $order['customer_email']) !== mb_strtolower((string) $customer['email'])) {
        api_fail('Order not found.', 404);
    }

    $stmt = db()->prepare('SELECT * FROM order_items WHERE order_id = ?');
    $stmt->execute([(int) $order['id']]);

    $skipped = [];
    foreach ($stmt->fetchAll() as $line) {
        if (empty($line['product_id'])) {
            $skipped[] = (string) $line['product_name'];
            continue;
        }
        $variantId = tc_column_exists('order_items', 'variant_id') && !empty($line['variant_id'])
            ? (int) $line['variant_id']
            : null;

        $result = cart_add((int) $line['product_id'], $variantId, (int) $line['quantity']);
        if (!$result['ok']) {
            $skipped[] = (string) $line['product_name'];
        }
    }

    api_ok([
        'cart'    => api_cart_payload(),
        'skipped' => $skipped,
    ], $skipped ? 'Some items are no longer available and were skipped.' : 'Your items are back in the cart.');
});
