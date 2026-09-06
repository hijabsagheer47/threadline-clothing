<?php
/**
 * Account area: saved addresses, notifications, stock alerts, rewards.
 * Everything here requires a signed-in customer.
 */

declare(strict_types=1);

// Route files are includes, never entry points: without the front controller
// route() does not exist. .htaccess blocks them too; this is the fallback for
// servers where it is not applied.
if (!defined('TC_API')) {
    http_response_code(404);
    exit;
}

/* ============================================================================
   ADDRESSES
   ============================================================================ */

/** GET /addresses */
route('GET', '/addresses', static function (): void {
    $customer = api_require_customer();

    if (!tc_table_exists('customer_addresses')) {
        api_ok(['items' => []]);
    }

    $stmt = db()->prepare(
        'SELECT * FROM customer_addresses WHERE customer_id = ? ORDER BY is_default DESC, id DESC'
    );
    $stmt->execute([(int) $customer['id']]);

    api_ok(['items' => array_map('api_address', $stmt->fetchAll())]);
});

/**
 * POST /addresses
 * Body: { address, city, label?, name?, phone?, state?, postal_code?,
 *         country?, is_default? }
 */
route('POST', '/addresses', static function (): void {
    $customer = api_require_customer();

    if (!tc_table_exists('customer_addresses')) {
        api_fail('Saved addresses are not available.', 503);
    }

    $errors = [];
    if (api_input('address') === '') $errors['address'] = 'Please enter the street address.';
    if (api_input('city') === '')    $errors['city']    = 'Please enter the city.';
    if (api_input('phone') !== '' && !valid_phone(api_input('phone'))) {
        $errors['phone'] = 'Please enter a valid phone number.';
    }
    if ($errors) {
        api_invalid($errors);
    }

    $isDefault = api_input_bool('is_default');

    $db = db();
    if ($isDefault) {
        $db->prepare('UPDATE customer_addresses SET is_default = 0 WHERE customer_id = ?')
           ->execute([(int) $customer['id']]);
    } else {
        // The first address a customer saves becomes their default.
        $count = $db->prepare('SELECT COUNT(*) FROM customer_addresses WHERE customer_id = ?');
        $count->execute([(int) $customer['id']]);
        $isDefault = (int) $count->fetchColumn() === 0;
    }

    $db->prepare(
        'INSERT INTO customer_addresses
            (customer_id, label, name, phone, address, city, state, postal_code, country, is_default)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)'
    )->execute([
        (int) $customer['id'],
        api_input('label') ?: null,
        api_input('name', (string) ($customer['name'] ?? '')) ?: null,
        api_input('phone', (string) ($customer['phone'] ?? '')) ?: null,
        api_input('address'),
        api_input('city'),
        api_input('state') ?: null,
        api_input('postal_code') ?: null,
        api_input('country', 'Pakistan'),
        $isDefault ? 1 : 0,
    ]);

    $stmt = $db->prepare('SELECT * FROM customer_addresses WHERE id = ?');
    $stmt->execute([(int) $db->lastInsertId()]);

    api_ok(['address' => api_address($stmt->fetch())], 'Address saved.', 201);
});

/** PUT /addresses/{id} — same body as POST; only the fields sent are changed. */
route('PUT', '/addresses/{id}', static function (array $params): void {
    $customer = api_require_customer();

    $stmt = db()->prepare('SELECT * FROM customer_addresses WHERE id = ? AND customer_id = ? LIMIT 1');
    $stmt->execute([(int) $params['id'], (int) $customer['id']]);
    $address = $stmt->fetch();

    if (!$address) {
        api_fail('Address not found.', 404);
    }

    $body = api_body();
    $set = [];
    $values = [];

    foreach (['label', 'name', 'phone', 'address', 'city', 'state', 'postal_code', 'country'] as $field) {
        if (array_key_exists($field, $body)) {
            $set[] = "{$field} = ?";
            $values[] = trim((string) $body[$field]) ?: null;
        }
    }

    if (array_key_exists('is_default', $body) && api_input_bool('is_default')) {
        db()->prepare('UPDATE customer_addresses SET is_default = 0 WHERE customer_id = ?')
            ->execute([(int) $customer['id']]);
        $set[] = 'is_default = 1';
    }

    if ($set) {
        $values[] = (int) $address['id'];
        db()->prepare('UPDATE customer_addresses SET ' . implode(', ', $set) . ' WHERE id = ?')->execute($values);
    }

    $stmt->execute([(int) $params['id'], (int) $customer['id']]);

    api_ok(['address' => api_address($stmt->fetch())], 'Address updated.');
});

/** DELETE /addresses/{id} */
route('DELETE', '/addresses/{id}', static function (array $params): void {
    $customer = api_require_customer();

    $stmt = db()->prepare('DELETE FROM customer_addresses WHERE id = ? AND customer_id = ?');
    $stmt->execute([(int) $params['id'], (int) $customer['id']]);

    if ($stmt->rowCount() === 0) {
        api_fail('Address not found.', 404);
    }

    api_ok(null, 'Address removed.');
});

/* ============================================================================
   NOTIFICATIONS
   ============================================================================ */

/** GET /notifications */
route('GET', '/notifications', static function (): void {
    $customer = api_require_customer();

    if (!tc_table_exists('notifications')) {
        api_ok(['items' => [], 'unread' => 0]);
    }

    $stmt = db()->prepare(
        'SELECT * FROM notifications WHERE customer_id = ? OR email = ? ORDER BY id DESC LIMIT 50'
    );
    $stmt->execute([(int) $customer['id'], $customer['email']]);
    $rows = $stmt->fetchAll();

    api_ok([
        'items' => array_map(static fn (array $n): array => [
            'id'         => (int) $n['id'],
            'type'       => $n['type'] ?? 'general',
            'title'      => (string) $n['title'],
            'body'       => $n['body'] ?? null,
            'link'       => $n['link'] ?? null,
            'is_read'    => (bool) $n['is_read'],
            'created_at' => $n['created_at'],
            'human'      => time_ago($n['created_at'] ?? null),
        ], $rows),
        'unread' => count(array_filter($rows, static fn (array $n): bool => (int) $n['is_read'] === 0)),
    ]);
});

/** POST /notifications/{id}/read */
route('POST', '/notifications/{id}/read', static function (array $params): void {
    $customer = api_require_customer();

    db()->prepare('UPDATE notifications SET is_read = 1 WHERE id = ? AND (customer_id = ? OR email = ?)')
        ->execute([(int) $params['id'], (int) $customer['id'], $customer['email']]);

    api_ok(null, 'Marked as read.');
});

/** POST /notifications/read-all */
route('POST', '/notifications/read-all', static function (): void {
    $customer = api_require_customer();

    db()->prepare('UPDATE notifications SET is_read = 1 WHERE customer_id = ? OR email = ?')
        ->execute([(int) $customer['id'], $customer['email']]);

    api_ok(null, 'All notifications marked as read.');
});

/* ============================================================================
   STOCK / PRICE ALERTS — "tell me when this is back"
   ============================================================================ */

/**
 * POST /product-alerts
 * Body: { product_id, type?, email?, desired_price? }
 * Open to guests: an email is all that is needed.
 */
route('POST', '/product-alerts', static function (): void {
    if (!tc_table_exists('product_alerts')) {
        api_fail('Alerts are not available.', 503);
    }

    $customer  = current_customer();
    $productId = api_input_int('product_id');
    $email     = api_input('email', (string) ($customer['email'] ?? ''));
    $type      = api_input('type', 'back_in_stock');

    if (!in_array($type, ['back_in_stock', 'price_drop', 'new_color', 'new_size', 'launch'], true)) {
        $type = 'back_in_stock';
    }
    if ($productId < 1) {
        api_invalid(['product_id' => 'Please choose a product.']);
    }
    if (!valid_email($email)) {
        api_invalid(['email' => 'Please enter a valid email address.']);
    }

    db()->prepare(
        'INSERT INTO product_alerts (type, product_id, customer_id, email, phone, desired_price)
         VALUES (?, ?, ?, ?, ?, ?)
         ON DUPLICATE KEY UPDATE status = 1, desired_price = VALUES(desired_price)'
    )->execute([
        $type,
        $productId,
        $customer ? (int) $customer['id'] : null,
        $email,
        api_input('phone') ?: null,
        api_input('desired_price') !== '' ? decimal(api_input('desired_price')) : null,
    ]);

    api_ok(null, 'We will let you know as soon as it is available.', 201);
});

/* ============================================================================
   REWARDS
   ============================================================================ */

/** GET /rewards — points balance and recent ledger entries. */
route('GET', '/rewards', static function (): void {
    $customer = api_require_customer();

    if (!tc_table_exists('reward_accounts')) {
        api_ok(['enabled' => false]);
    }

    $stmt = db()->prepare('SELECT * FROM reward_accounts WHERE customer_id = ? LIMIT 1');
    $stmt->execute([(int) $customer['id']]);
    $account = $stmt->fetch();

    if (!$account) {
        api_ok([
            'enabled'       => true,
            'points'        => 0,
            'lifetime'      => 0,
            'tier'          => 'silver',
            'transactions'  => [],
            'referral_code' => $customer['referral_code'] ?? null,
        ]);
    }

    $tx = db()->prepare(
        'SELECT * FROM reward_transactions WHERE account_id = ? ORDER BY id DESC LIMIT 30'
    );
    $tx->execute([(int) $account['id']]);

    api_ok([
        'enabled'  => true,
        'points'   => (int) $account['points_balance'],
        'lifetime' => (int) $account['lifetime_points'],
        'tier'     => (string) $account['tier'],
        'transactions' => array_map(static fn (array $t): array => [
            'points'     => (int) $t['points_change'],
            'reason'     => (string) $t['reason'],
            'created_at' => $t['created_at'],
            'human'      => time_ago($t['created_at'] ?? null),
        ], $tx->fetchAll()),
        'referral_code' => $customer['referral_code'] ?? null,
    ]);
});
