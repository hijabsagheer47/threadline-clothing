<?php
/**
 * Catalogue: home screen, products, categories, collections, search, reviews.
 * All read-only and open to guest tokens.
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
 * GET /home
 * One call for the whole home screen — hero, rails and shortcuts — so the app
 * paints in a single round trip instead of six.
 */
route('GET', '/home', static function (): void {
    $slides = array_map(static fn (array $s): array => [
        'id'        => (int) $s['id'],
        'eyebrow'   => $s['eyebrow'] ?? null,
        'title'     => (string) $s['title'],
        'subtitle'  => $s['subtitle'] ?? null,
        'image'     => api_image($s['image'] ?? ''),
        'video_url' => $s['video_url'] ?? null,
        'cta_text'  => $s['cta_text'] ?? null,
        'cta_link'  => $s['cta_link'] ?? null,
        'cta_secondary_text' => $s['cta_secondary_text'] ?? null,
        'cta_secondary_link' => $s['cta_secondary_link'] ?? null,
    ], tc_hero_slides());

    $testimonials = [];
    if (tc_table_exists('testimonials')) {
        $rows = db()->query(
            'SELECT * FROM testimonials WHERE status = 1 ORDER BY sort_order ASC, id DESC LIMIT 10'
        )->fetchAll();
        $testimonials = array_map(static fn (array $t): array => [
            'id'     => (int) $t['id'],
            'name'   => (string) $t['name'],
            'role'   => $t['role'] ?? null,
            'quote'  => (string) $t['quote'],
            'rating' => (int) $t['rating'],
            'image'  => api_image($t['image'] ?? ''),
        ], $rows);
    }

    api_ok([
        'announcement'   => setting('announcement_bar', ''),
        'hero_slides'    => $slides,
        'categories'     => array_map('api_category', categories_with_counts(12)),
        'collections'    => array_map('api_collection', array_slice(tc_collections(), 0, 8)),
        'featured'       => array_map('api_product_card', featured_products(10)),
        'new_arrivals'   => array_map('api_product_card', new_arrivals(10)),
        'best_sellers'   => array_map('api_product_card', best_sellers(10)),
        'on_sale'        => array_map('api_product_card', sale_products(10)),
        'testimonials'   => $testimonials,
    ]);
});

/**
 * GET /products
 * Query: q, category (slug or id), collection (slug or id), sort, price,
 *        price_min, price_max, fabric, color, size, availability, sale,
 *        featured, page, per_page
 */
route('GET', '/products', static function (): void {
    $filters = [
        'page'      => max(1, api_query_int('page', 1)),
        'per_page'  => max(1, min(48, api_query_int('per_page', 20))),
        'q'         => api_query('q'),
        'sort'      => api_query('sort', 'newest'),
        'price'     => api_query('price'),
        'price_min' => api_query('price_min'),
        'price_max' => api_query('price_max'),
        'fabric'    => api_query('fabric'),
        'color'     => api_query('color'),
        'size'      => api_query('size'),
        'availability' => api_query('availability') !== '' ? 1 : 0,
        'sale'      => api_query('sale') !== '' ? 1 : 0,
        'featured'  => api_query('featured') !== '' ? 1 : 0,
    ];

    $category = api_query('category');
    if ($category !== '') {
        $row = ctype_digit($category)
            ? ['id' => (int) $category]
            : get_category_by_slug($category);
        if (!$row) {
            api_fail('Category not found.', 404);
        }
        $filters['category_id'] = (int) $row['id'];
    }

    // Collections are not part of get_products()'s filter set, so restrict by
    // the collection's product ids instead of duplicating the query builder.
    $collection = api_query('collection');
    $collectionIds = null;
    if ($collection !== '') {
        $row = tc_collection($collection);
        if (!$row) {
            api_fail('Collection not found.', 404);
        }
        $stmt = db()->prepare('SELECT product_id FROM collection_products WHERE collection_id = ?');
        $stmt->execute([(int) $row['id']]);
        $collectionIds = array_map('intval', array_column($stmt->fetchAll(), 'product_id'));
        if (!$collectionIds) {
            api_ok(api_paginated([], $filters['page'], $filters['per_page'], 0));
        }
    }

    $result = get_products($filters);
    $items  = $result['items'];

    if ($collectionIds !== null) {
        $items = array_values(array_filter(
            $items,
            static fn (array $p): bool => in_array((int) $p['id'], $collectionIds, true)
        ));
    }

    // Aggregate search analytics (query text only, no personal data).
    if ($filters['q'] !== '' && tc_table_exists('search_logs')) {
        db()->prepare('INSERT INTO search_logs (query, results_count, session_id) VALUES (?, ?, ?)')
            ->execute([mb_substr($filters['q'], 0, 190), (int) $result['total'], api_token()]);
    }

    api_ok(api_paginated(
        array_map('api_product_card', $items),
        (int) $result['page'],
        (int) $result['per_page'],
        (int) $result['total']
    ));
});

/** GET /products/{slug} — accepts a slug or a numeric id. */
route('GET', '/products/{slug}', static function (array $params): void {
    $product = get_product($params['slug']);
    if (!$product) {
        api_fail('Product not found.', 404);
    }

    // View counter + recently viewed, both best-effort.
    if (tc_column_exists('products', 'views')) {
        db()->prepare('UPDATE products SET views = views + 1 WHERE id = ?')->execute([(int) $product['id']]);
    }
    if (tc_table_exists('recently_viewed')) {
        db()->prepare(
            'INSERT INTO recently_viewed (customer_id, session_id, product_id, viewed_at)
             VALUES (NULL, ?, ?, NOW())
             ON DUPLICATE KEY UPDATE viewed_at = NOW()'
        )->execute([api_token(), (int) $product['id']]);
    }

    api_ok([
        'product'    => api_product_detail($product),
        'related'    => array_map('api_product_card', related_products($product, 8)),
        'reviews'    => [
            'summary' => tc_review_summary((int) $product['id']),
            'items'   => array_map('api_review', tc_product_reviews((int) $product['id'], 5)),
        ],
        'size_chart'   => api_size_chart(),
        'in_wishlist'  => in_array((int) $product['id'], wishlist_ids(), true),
    ]);
});

/** GET /products/{slug}/reviews — Query: page, per_page */
route('GET', '/products/{slug}/reviews', static function (array $params): void {
    $product = get_product($params['slug']);
    if (!$product) {
        api_fail('Product not found.', 404);
    }

    $page    = max(1, api_query_int('page', 1));
    $perPage = max(1, min(50, api_query_int('per_page', 20)));

    $countStmt = db()->prepare(
        "SELECT COUNT(*) FROM reviews WHERE product_id = ? AND status IN ('approved','featured')"
    );
    $countStmt->execute([(int) $product['id']]);
    $total = (int) $countStmt->fetchColumn();

    $stmt = db()->prepare(
        "SELECT * FROM reviews
          WHERE product_id = ? AND status IN ('approved','featured')
          ORDER BY status = 'featured' DESC, id DESC
          LIMIT {$perPage} OFFSET " . (($page - 1) * $perPage)
    );
    $stmt->execute([(int) $product['id']]);

    api_ok(api_paginated(array_map('api_review', $stmt->fetchAll()), $page, $perPage, $total) + [
        'summary' => tc_review_summary((int) $product['id']),
    ]);
});

/**
 * POST /products/{slug}/reviews
 * Body: { rating, name, email, title?, body?, fit_feedback? }
 *
 * Reviews are held for moderation, exactly as they are on the website. Name
 * and email are typed in by the reviewer, as there are no accounts.
 */
route('POST', '/products/{slug}/reviews', static function (array $params): void {
    $product = get_product($params['slug']);
    if (!$product) {
        api_fail('Product not found.', 404);
    }

    $result = tc_submit_review([
        'product_id'   => (int) $product['id'],
        'name'         => api_input('name'),
        'email'        => api_input('email'),
        'rating'       => api_input_int('rating', 5),
        'title'        => api_input('title'),
        'body'         => api_input('body'),
        'fit_feedback' => api_input('fit_feedback'),
    ]);

    if (empty($result['ok'])) {
        api_fail((string) ($result['error'] ?? 'We could not save your review.'), 422);
    }

    api_ok(null, $result['message'] ?? 'Thank you! Your review will appear once approved.', 201);
});

/** GET /categories — the full tree with product counts. */
route('GET', '/categories', static function (): void {
    api_ok(['items' => array_map('api_category', categories_with_counts())]);
});

/** GET /categories/{slug} */
route('GET', '/categories/{slug}', static function (array $params): void {
    $category = get_category_by_slug($params['slug']);
    if (!$category) {
        api_fail('Category not found.', 404);
    }

    $children = db()->prepare('SELECT * FROM categories WHERE parent_id = ? AND status = 1 ORDER BY sort_order ASC');
    $children->execute([(int) $category['id']]);

    api_ok([
        'category' => api_category($category),
        'children' => array_map('api_category', $children->fetchAll()),
    ]);
});

/** GET /collections */
route('GET', '/collections', static function (): void {
    api_ok(['items' => array_map('api_collection', tc_collections())]);
});

/** GET /collections/{slug} — the collection plus its products. */
route('GET', '/collections/{slug}', static function (array $params): void {
    $collection = tc_collection($params['slug']);
    if (!$collection) {
        api_fail('Collection not found.', 404);
    }

    api_ok([
        'collection' => api_collection($collection),
        'products'   => array_map(
            'api_product_card',
            tc_collection_products((int) $collection['id'], max(1, min(60, api_query_int('limit', 24))))
        ),
    ]);
});

/** GET /filters — the facet values to build the filter sheet. */
route('GET', '/filters', static function (): void {
    $facets = product_facets();

    api_ok([
        'facets'     => $facets,
        'categories' => array_map('api_category', categories_with_counts()),
        'sorts'      => [
            ['value' => 'newest',       'label' => 'Newest'],
            ['value' => 'featured',     'label' => 'Featured'],
            ['value' => 'best_selling', 'label' => 'Best selling'],
            ['value' => 'price_low',    'label' => 'Price: low to high'],
            ['value' => 'price_high',   'label' => 'Price: high to low'],
            ['value' => 'name',         'label' => 'Name A-Z'],
        ],
        'price_presets' => [
            ['value' => 'under-5000',   'label' => 'Under ' . money(5000)],
            ['value' => '5000-10000',   'label' => money(5000) . ' - ' . money(10000)],
            ['value' => '10000-15000',  'label' => money(10000) . ' - ' . money(15000)],
            ['value' => 'over-15000',   'label' => 'Over ' . money(15000)],
        ],
    ]);
});

/** GET /search/suggest?q= — lightweight type-ahead. */
route('GET', '/search/suggest', static function (): void {
    $q = api_query('q');
    if (mb_strlen($q) < 2) {
        api_ok(['products' => [], 'categories' => [], 'collections' => []]);
    }

    $like = '%' . $q . '%';

    $products = db()->prepare(
        'SELECT p.*, pi.image AS primary_image
           FROM products p
           LEFT JOIN product_images pi ON pi.product_id = p.id AND pi.is_primary = 1
          WHERE p.status = 1 AND (p.name LIKE ? OR p.sku LIKE ? OR p.fabric LIKE ? OR p.color LIKE ?)
          ORDER BY p.featured DESC, p.id DESC
          LIMIT 8'
    );
    $products->execute([$like, $like, $like, $like]);

    $categories = db()->prepare(
        'SELECT * FROM categories WHERE status = 1 AND name LIKE ? ORDER BY sort_order ASC LIMIT 5'
    );
    $categories->execute([$like]);

    $collections = [];
    if (tc_table_exists('collections')) {
        $stmt = db()->prepare('SELECT * FROM collections WHERE status = 1 AND name LIKE ? LIMIT 5');
        $stmt->execute([$like]);
        $collections = array_map('api_collection', $stmt->fetchAll());
    }

    api_ok([
        'products'    => array_map('api_product_card', $products->fetchAll()),
        'categories'  => array_map('api_category', $categories->fetchAll()),
        'collections' => $collections,
    ]);
});

/** GET /search/trending — the searches customers actually run. */
route('GET', '/search/trending', static function (): void {
    if (!tc_table_exists('search_logs')) {
        api_ok(['items' => []]);
    }

    $rows = db()->query(
        'SELECT query, COUNT(*) AS hits
           FROM search_logs
          WHERE results_count > 0 AND created_at > DATE_SUB(NOW(), INTERVAL 30 DAY)
          GROUP BY query
          ORDER BY hits DESC
          LIMIT 10'
    )->fetchAll();

    api_ok(['items' => array_column($rows, 'query')]);
});

/** GET /recently-viewed */
route('GET', '/recently-viewed', static function (): void {
    if (!tc_table_exists('recently_viewed')) {
        api_ok(['items' => []]);
    }

    $stmt = db()->prepare(
        'SELECT p.*, pi.image AS primary_image
           FROM recently_viewed rv
           JOIN products p ON p.id = rv.product_id AND p.status = 1
           LEFT JOIN product_images pi ON pi.product_id = p.id AND pi.is_primary = 1
          WHERE rv.session_id = ?
          ORDER BY rv.viewed_at DESC
          LIMIT 20'
    );
    $stmt->execute([api_token()]);

    api_ok(['items' => array_map('api_product_card', $stmt->fetchAll())]);
});

/** GET /looks — shop-the-look sets. */
route('GET', '/looks', static function (): void {
    if (!tc_table_exists('looks')) {
        api_ok(['items' => []]);
    }

    $looks = db()->query('SELECT * FROM looks WHERE status = 1 ORDER BY sort_order ASC, id DESC LIMIT 20')->fetchAll();

    $items = [];
    foreach ($looks as $look) {
        $stmt = db()->prepare(
            'SELECT p.*, pi.image AS primary_image, lp.label
               FROM look_products lp
               JOIN products p ON p.id = lp.product_id AND p.status = 1
               LEFT JOIN product_images pi ON pi.product_id = p.id AND pi.is_primary = 1
              WHERE lp.look_id = ?
              ORDER BY lp.sort_order ASC'
        );
        $stmt->execute([(int) $look['id']]);

        $items[] = [
            'id'          => (int) $look['id'],
            'name'        => (string) $look['name'],
            'slug'        => (string) $look['slug'],
            'description' => $look['description'] ?? null,
            'image'       => api_image($look['image'] ?? ''),
            'products'    => array_map(
                static fn (array $p): array => api_product_card($p) + ['look_label' => $p['label'] ?? null],
                $stmt->fetchAll()
            ),
        ];
    }

    api_ok(['items' => $items]);
});
