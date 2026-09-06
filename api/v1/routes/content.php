<?php
/**
 * Store configuration and editorial content: settings, menus, CMS pages, FAQs,
 * the journal, size charts, newsletter and contact.
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
 * GET /settings — the store config the app needs to render itself. Cache it on
 * the device and refresh on launch.
 */
route('GET', '/settings', static function (): void {
    api_ok([
        'store' => [
            'name'         => setting('store_name', 'Fashlab Studio'),
            'tagline'      => setting('store_tagline', ''),
            'email'        => setting('store_email', ''),
            'phone'        => setting('store_phone', ''),
            'address'      => setting('store_address', ''),
            'announcement' => setting('announcement_bar', ''),
            'is_open'      => store_is_open(),
            'logo'         => api_image('images/logo.png'),
            'website'      => abs_url('/'),
        ],
        'currency' => [
            'code'   => setting('currency', 'PKR'),
            'symbol' => setting('currency_symbol', 'Rs.'),
        ],
        'shipping' => [
            'fee'                     => (float) setting('shipping_fee', '250'),
            'free_shipping_threshold' => (float) setting('free_shipping_threshold', '8000'),
            'min_order_amount'        => (float) setting('min_order_amount', '0'),
        ],
        'social' => array_filter([
            'instagram' => setting('instagram_url', ''),
            'facebook'  => setting('facebook_url', ''),
            'tiktok'    => setting('tiktok_url', ''),
            'linkedin'  => setting('linkedin_url', ''),
            'whatsapp'  => whatsapp_url(),
        ], static fn (string $v): bool => $v !== '' && $v !== '#'),
        'support' => [
            'whatsapp_number' => whatsapp_number(),
            'email'           => setting('store_email', ''),
            'phone'           => setting('store_phone', ''),
        ],
        'payment_methods' => [
            ['code' => 'cod', 'name' => 'Cash on Delivery', 'enabled' => true],
        ],
    ]);
});

/** GET /menus — the navigation the admin manages, ready to render as a drawer. */
route('GET', '/menus', static function (): void {
    $locations = ['main', 'mobile', 'footer_shop', 'footer_explore', 'footer_care', 'footer_about'];
    $menus = [];

    foreach ($locations as $location) {
        // tc_menu_tree() yields nodes shaped ['item' => row, 'children' => [...]].
        $map = static function (array $node) use (&$map): array {
            $item = $node['item'];
            return [
                'label'    => (string) $item['label'],
                'url'      => tc_menu_url($item),
                'group'    => $item['group_label'] ?? null,
                'children' => array_map($map, $node['children'] ?? []),
            ];
        };
        $menus[$location] = array_map($map, tc_menu_tree($location));
    }

    api_ok(['menus' => $menus]);
});

/** GET /pages — the CMS pages available (policies, guides, about). */
route('GET', '/pages', static function (): void {
    if (!tc_table_exists('cms_pages')) {
        api_ok(['items' => []]);
    }

    $rows = db()->query('SELECT slug, title FROM cms_pages WHERE status = 1 ORDER BY title ASC')->fetchAll();

    api_ok(['items' => array_map(static fn (array $p): array => [
        'slug'  => (string) $p['slug'],
        'title' => (string) $p['title'],
    ], $rows)]);
});

/** GET /pages/{slug} — a single CMS page, content included. */
route('GET', '/pages/{slug}', static function (array $params): void {
    if (!tc_table_exists('cms_pages')) {
        api_fail('Page not found.', 404);
    }

    $stmt = db()->prepare('SELECT * FROM cms_pages WHERE slug = ? AND status = 1 LIMIT 1');
    $stmt->execute([(string) $params['slug']]);
    $page = $stmt->fetch();

    if (!$page) {
        api_fail('Page not found.', 404);
    }

    api_ok(['page' => [
        'slug'       => (string) $page['slug'],
        'title'      => (string) $page['title'],
        'content'    => $page['content'] ?? '',
        'updated_at' => $page['updated_at'] ?? null,
    ]]);
});

/** GET /faqs — grouped by category. */
route('GET', '/faqs', static function (): void {
    if (!tc_table_exists('faqs')) {
        api_ok(['items' => []]);
    }

    $rows = db()->query(
        'SELECT f.*, c.name AS category_name, c.slug AS category_slug
           FROM faqs f
           LEFT JOIN faq_categories c ON c.id = f.category_id AND c.status = 1
          WHERE f.status = 1
          ORDER BY c.sort_order ASC, f.sort_order ASC, f.id ASC'
    )->fetchAll();

    $grouped = [];
    foreach ($rows as $row) {
        $key = (string) ($row['category_slug'] ?? 'general');
        $grouped[$key] ??= [
            'slug'  => $key,
            'name'  => (string) ($row['category_name'] ?? 'General'),
            'items' => [],
        ];
        $grouped[$key]['items'][] = [
            'id'       => (int) $row['id'],
            'question' => (string) $row['question'],
            'answer'   => (string) $row['answer'],
        ];
    }

    api_ok(['items' => array_values($grouped)]);
});

/** GET /size-chart */
route('GET', '/size-chart', static function (): void {
    api_ok(['measurements' => api_size_chart()]);
});

/** GET /journal — Query: page, per_page, category */
route('GET', '/journal', static function (): void {
    if (!tc_table_exists('journal_posts')) {
        api_ok(api_paginated([], 1, 20, 0));
    }

    $page    = max(1, api_query_int('page', 1));
    $perPage = max(1, min(30, api_query_int('per_page', 10)));

    $where  = "p.status = 'published' AND (p.published_at IS NULL OR p.published_at <= NOW())";
    $params = [];

    $category = api_query('category');
    if ($category !== '') {
        $where .= ' AND c.slug = ?';
        $params[] = $category;
    }

    $countStmt = db()->prepare(
        "SELECT COUNT(*) FROM journal_posts p
           LEFT JOIN journal_categories c ON c.id = p.category_id
          WHERE {$where}"
    );
    $countStmt->execute($params);
    $total = (int) $countStmt->fetchColumn();

    $stmt = db()->prepare(
        "SELECT p.*, c.name AS category_name, c.slug AS category_slug
           FROM journal_posts p
           LEFT JOIN journal_categories c ON c.id = p.category_id
          WHERE {$where}
          ORDER BY p.published_at DESC, p.id DESC
          LIMIT {$perPage} OFFSET " . (($page - 1) * $perPage)
    );
    $stmt->execute($params);

    api_ok(api_paginated(array_map(static fn (array $p): array => [
        'id'           => (int) $p['id'],
        'title'        => (string) $p['title'],
        'slug'         => (string) $p['slug'],
        'excerpt'      => $p['excerpt'] ?? null,
        'image'        => api_image($p['image'] ?? ''),
        'author'       => $p['author'] ?? null,
        'category'     => $p['category_name'] ?? null,
        'published_at' => $p['published_at'],
        'human'        => format_date($p['published_at'] ?? null),
    ], $stmt->fetchAll()), $page, $perPage, $total));
});

/** GET /journal/{slug} */
route('GET', '/journal/{slug}', static function (array $params): void {
    if (!tc_table_exists('journal_posts')) {
        api_fail('Post not found.', 404);
    }

    $stmt = db()->prepare(
        "SELECT p.*, c.name AS category_name
           FROM journal_posts p
           LEFT JOIN journal_categories c ON c.id = p.category_id
          WHERE p.slug = ? AND p.status = 'published' LIMIT 1"
    );
    $stmt->execute([(string) $params['slug']]);
    $post = $stmt->fetch();

    if (!$post) {
        api_fail('Post not found.', 404);
    }

    api_ok(['post' => [
        'id'           => (int) $post['id'],
        'title'        => (string) $post['title'],
        'slug'         => (string) $post['slug'],
        'excerpt'      => $post['excerpt'] ?? null,
        'content'      => $post['content'] ?? '',
        'image'        => api_image($post['image'] ?? ''),
        'author'       => $post['author'] ?? null,
        'category'     => $post['category_name'] ?? null,
        'published_at' => $post['published_at'],
        'human'        => format_date($post['published_at'] ?? null),
    ]]);
});

/** POST /newsletter — Body: { email } */
route('POST', '/newsletter', static function (): void {
    $email = api_input('email');
    if (!valid_email($email)) {
        api_invalid(['email' => 'Please enter a valid email address.']);
    }

    $db = db();
    $stmt = $db->prepare('SELECT id, status FROM subscribers WHERE email = ? LIMIT 1');
    $stmt->execute([$email]);
    $existing = $stmt->fetch();

    if ($existing) {
        if ((int) $existing['status'] !== 1) {
            $db->prepare('UPDATE subscribers SET status = 1 WHERE id = ?')->execute([(int) $existing['id']]);
        }
        api_ok(null, 'You are already subscribed. Thank you!');
    }

    $db->prepare('INSERT INTO subscribers (email, status) VALUES (?, 1)')->execute([$email]);

    api_ok(null, 'Thank you for subscribing!', 201);
});

/** POST /contact — Body: { name, email, phone?, subject?, message } */
route('POST', '/contact', static function (): void {
    $customer = current_customer();

    $name    = api_input('name', (string) ($customer['name'] ?? ''));
    $email   = api_input('email', (string) ($customer['email'] ?? ''));
    $message = api_input('message');
    $phone   = api_input('phone', (string) ($customer['phone'] ?? ''));

    $errors = [];
    if ($name === '')            $errors['name']    = 'Please enter your name.';
    if (!valid_email($email))    $errors['email']   = 'Please enter a valid email address.';
    if (mb_strlen($message) < 5) $errors['message'] = 'Please write your message.';
    if ($phone !== '' && !valid_phone($phone)) $errors['phone'] = 'Please enter a valid phone number.';

    if ($errors) {
        api_invalid($errors);
    }

    db()->prepare(
        'INSERT INTO contact_messages (name, email, phone, subject, message) VALUES (?, ?, ?, ?, ?)'
    )->execute([
        mb_substr($name, 0, 150),
        $email,
        $phone !== '' ? mb_substr($phone, 0, 40) : null,
        mb_substr(api_input('subject'), 0, 200) ?: null,
        mb_substr($message, 0, 5000),
    ]);

    api_ok(null, 'Thank you for getting in touch. We will reply shortly.', 201);
});

/**
 * POST /personal-shopper
 * Body: { name, phone, email?, occasion?, budget?, preferred_style?,
 *         preferred_color?, preferred_size?, message? }
 */
route('POST', '/personal-shopper', static function (): void {
    if (!tc_table_exists('shopper_requests')) {
        api_fail('This service is not available.', 503);
    }

    $customer = current_customer();
    $name  = api_input('name', (string) ($customer['name'] ?? ''));
    $phone = api_input('phone', (string) ($customer['phone'] ?? ''));

    $errors = [];
    if ($name === '')          $errors['name']  = 'Please enter your name.';
    if (!valid_phone($phone))  $errors['phone'] = 'Please enter a valid phone number.';
    if ($errors) {
        api_invalid($errors);
    }

    db()->prepare(
        'INSERT INTO shopper_requests
            (name, phone, email, occasion, budget, preferred_style, preferred_color, preferred_size, message)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)'
    )->execute([
        mb_substr($name, 0, 150),
        mb_substr($phone, 0, 40),
        api_input('email', (string) ($customer['email'] ?? '')) ?: null,
        api_input('occasion') ?: null,
        api_input('budget') ?: null,
        api_input('preferred_style') ?: null,
        api_input('preferred_color') ?: null,
        api_input('preferred_size') ?: null,
        api_input('message') ?: null,
    ]);

    api_ok(null, 'Thank you — a stylist will be in touch shortly.', 201);
});
