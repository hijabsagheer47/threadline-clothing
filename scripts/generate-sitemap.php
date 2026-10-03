<?php
declare(strict_types=1);

/**
 * Regenerate sitemap.xml from the live database.
 *
 * Usage:
 *   php scripts/generate-sitemap.php [base-url]
 *
 * base-url defaults to https://fashlabstudio.mytechrcm.com — pass another
 * origin when generating for staging (e.g. http://localhost).
 * Only real, published rows are emitted (status = 1); nothing is invented.
 */

if (PHP_SAPI !== 'cli') {
    http_response_code(403);
    exit("CLI only\n");
}

require __DIR__ . '/../includes/bootstrap.php';

$base = rtrim($argv[1] ?? 'https://fashlabstudio.mytechrcm.com', '/');

/** Absolute storefront URL using query-string routes (pretty URLs are off on production). */
$abs = static function (string $path) use ($base): string {
    return $base . $path;
};

$entries = [];

$add = static function (string $loc, ?string $lastmod, string $freq, float $priority) use (&$entries): void {
    $entries[] = ['loc' => $loc, 'lastmod' => $lastmod, 'freq' => $freq, 'priority' => $priority];
};

$add($abs('/index.php'), null, 'daily', 1.0);
$add($abs('/shop.php'), null, 'daily', 0.9);
$add($abs('/collections.php'), null, 'weekly', 0.8);
$add($abs('/about.php'), null, 'monthly', 0.5);
$add($abs('/contact.php'), null, 'monthly', 0.5);

// Categories
foreach (db()->query('SELECT slug, updated_at FROM categories WHERE status = 1 ORDER BY sort_order, id') as $row) {
    $add($abs('/category.php?slug=' . rawurlencode((string) $row['slug'])), $row['updated_at'] ?? null, 'weekly', 0.8);
}

// Collections (table exists only after the Fashlab upgrade migration).
if (tc_table_exists('collections')) {
    $slugCol = tc_column_exists('collections', 'slug') ? 'slug' : 'id';
    foreach (db()->query("SELECT {$slugCol} AS slug, updated_at FROM collections WHERE status = 1 ORDER BY id") as $row) {
        $add($abs('/collection.php?slug=' . rawurlencode((string) $row['slug'])), $row['updated_at'] ?? null, 'weekly', 0.7);
    }
}

// Products
foreach (db()->query('SELECT slug, updated_at FROM products WHERE status = 1 ORDER BY id') as $row) {
    $add($abs('/product.php?slug=' . rawurlencode((string) $row['slug'])), $row['updated_at'] ?? null, 'weekly', 0.9);
}

$xml = '<?xml version="1.0" encoding="UTF-8"?>' . "\n";
$xml .= '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">' . "\n";
foreach ($entries as $entry) {
    $xml .= "  <url>\n";
    $xml .= '    <loc>' . htmlspecialchars($entry['loc'], ENT_XML1) . "</loc>\n";
    if ($entry['lastmod']) {
        $xml .= '    <lastmod>' . date('Y-m-d', strtotime((string) $entry['lastmod'])) . "</lastmod>\n";
    }
    $xml .= '    <changefreq>' . $entry['freq'] . "</changefreq>\n";
    $xml .= '    <priority>' . number_format($entry['priority'], 1) . "</priority>\n";
    $xml .= "  </url>\n";
}
$xml .= '</urlset>' . "\n";

$out = __DIR__ . '/../sitemap.xml';
file_put_contents($out, $xml);

$robots = "User-agent: *\n"
    . "Allow: /\n\n"
    . "User-agent: GPTBot\n"
    . "Disallow: /\n\n"
    . "Disallow: /admin\n"
    . "Disallow: /api/\n"
    . "Disallow: /config/\n"
    . "Disallow: /includes/\n"
    . "Disallow: /scripts/\n"
    . "Disallow: /cart.php\n"
    . "Disallow: /checkout.php\n"
    . "Disallow: /my-orders.php\n"
    . "Disallow: /*?sort=\n"
    . "Disallow: /*?page=\n\n"
    . "Sitemap: {$base}/sitemap.xml\n";
file_put_contents(__DIR__ . '/../robots.txt', $robots);

printf("Wrote sitemap.xml (%d URLs) and robots.txt for %s\n", count($entries), $base);
