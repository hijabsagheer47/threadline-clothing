<?php
declare(strict_types=1);
require_once __DIR__ . '/includes/bootstrap.php';

$db = db();
$hasPosts = tc_table_exists('journal_posts');
$hasCats  = tc_table_exists('journal_categories');

/* ---------------------------------------------------------- category filter */
$catSlug = '';
if (isset($_GET['category']) && is_string($_GET['category'])) {
    $catSlug = strtolower(preg_replace('/[^a-z0-9\-]/', '', $_GET['category']) ?? '');
}

$currentCat = null;
$cats = [];
if ($hasCats) {
    $cats = $db->query('SELECT id, name, slug FROM journal_categories WHERE status = 1 ORDER BY sort_order, name')->fetchAll();
    if ($catSlug !== '') {
        foreach ($cats as $c) {
            if ($c['slug'] === $catSlug) { $currentCat = $c; break; }
        }
    }
}

/* --------------------------------------------------------------- published */
$posts = [];
if ($hasPosts) {
    if ($currentCat) {
        $stmt = $db->prepare(
            "SELECT p.*, c.name AS category_name, c.slug AS category_slug
             FROM journal_posts p
             LEFT JOIN journal_categories c ON c.id = p.category_id
             WHERE p.status = 'published'
               AND (p.published_at IS NULL OR p.published_at <= NOW())
               AND p.category_id = ?
             ORDER BY COALESCE(p.published_at, p.created_at) DESC"
        );
        $stmt->execute([(int) $currentCat['id']]);
    } else {
        $stmt = $db->query(
            "SELECT p.*, c.name AS category_name, c.slug AS category_slug
             FROM journal_posts p
             LEFT JOIN journal_categories c ON c.id = p.category_id
             WHERE p.status = 'published'
               AND (p.published_at IS NULL OR p.published_at <= NOW())
             ORDER BY COALESCE(p.published_at, p.created_at) DESC"
        );
    }
    $posts = $stmt->fetchAll();
}

/* --------------------------------------------------------------------- SEO */
$store = setting('store_name');
$full_title = $currentCat
    ? $currentCat['name'] . ' Articles & Styling Advice | ' . $store . ' Style Journal'
    : 'Fashlab Style Journal — Fashion, Fabrics & Styling Tips | ' . $store;
$meta_description = $currentCat
    ? 'Read ' . $currentCat['name'] . ' articles from the ' . $store . ' Style Journal — practical advice on fabrics, fits and styling Pakistani women\'s clothing.'
    : 'The ' . $store . ' Style Journal — genuinely useful guides on lawn, stitched vs unstitched suits, formal wear, wedding dressing and Pakistani fashion styling.';
$active_nav = 'journal.php';

$canonical = abs_url('/journal.php' . ($currentCat ? '?category=' . rawurlencode($currentCat['slug']) : ''));

$extra_schema = [];
$crumbs = [
    ['name' => 'Home', 'url' => abs_url('/index.php')],
    ['name' => 'Style Journal', 'url' => abs_url('/journal.php')],
];
if ($currentCat) {
    $crumbs[] = ['name' => $currentCat['name'], 'url' => $canonical];
}
$extra_schema[] = [
    '@context' => 'https://schema.org',
    '@type' => 'BreadcrumbList',
    'itemListElement' => array_map(fn($i, $c) => [
        '@type' => 'ListItem', 'position' => $i + 1, 'name' => $c['name'], 'item' => $c['url'],
    ], array_keys($crumbs), $crumbs),
];

require __DIR__ . '/includes/storefront-header.php';
?>

<nav class="lx-breadcrumb container" aria-label="Breadcrumb">
    <a href="<?= e(url('/index.php')) ?>">Home</a>
    <i class="fa-solid fa-chevron-right"></i>
    <?php if ($currentCat): ?>
        <a href="<?= e(url('/journal.php')) ?>">Style Journal</a>
        <i class="fa-solid fa-chevron-right"></i>
        <span aria-current="page"><?= e($currentCat['name']) ?></span>
    <?php else: ?>
        <span aria-current="page">Style Journal</span>
    <?php endif; ?>
</nav>

<section class="lx-journal-hero">
    <div class="container">
        <p class="section-label">THE <?= e(strtoupper($store)) ?> STYLE JOURNAL</p>
        <h1><?= $currentCat ? e($currentCat['name']) . ' — Style Notes' : 'Fashion Notes, Fabric Guides & Styling Advice' ?></h1>
        <p>Practical, no-fluff reading for getting more out of your wardrobe — from choosing the right lawn to dressing for a Pakistani wedding.</p>
    </div>
</section>

<?php if ($cats && count($cats) > 1): ?>
<section class="lx-journal-cats">
    <div class="container">
        <a href="<?= e(url('/journal.php')) ?>" class="lx-chip <?= !$currentCat ? 'is-active' : '' ?>">All</a>
        <?php foreach ($cats as $c): ?>
            <a href="<?= e(url('/journal.php?category=' . rawurlencode($c['slug']))) ?>"
               class="lx-chip <?= $currentCat && $currentCat['slug'] === $c['slug'] ? 'is-active' : '' ?>"><?= e($c['name']) ?></a>
        <?php endforeach; ?>
    </div>
</section>
<?php endif; ?>

<section class="lx-journal section-padding">
    <div class="container">
        <?php if (!$posts): ?>
            <div class="lx-journal-empty">
                <i class="fa-solid fa-feather-pointed"></i>
                <p><?= $currentCat ? 'No articles in this section yet.' : 'New articles are being written. Check back soon.' ?></p>
                <a href="<?= e(url('/shop.php')) ?>" class="lx-btn lx-btn-ghost">BROWSE THE COLLECTION</a>
            </div>
        <?php else: ?>
            <div class="lx-journal-grid">
                <?php foreach ($posts as $i => $p): ?>
                    <article class="lx-journal-card lx-reveal" style="--lx-delay: <?= ($i % 3) * 90 ?>ms">
                        <a href="<?= e(url('/journal-article.php?slug=' . rawurlencode($p['slug']))) ?>" class="lj-media">
                            <?php if (!empty($p['image'])): ?>
                                <img src="<?= e(image_url($p['image'])) ?>" alt="<?= e($p['title']) ?>" loading="lazy">
                            <?php else: ?>
                                <span class="lj-fallback" aria-hidden="true"><i class="fa-solid fa-feather-pointed"></i></span>
                            <?php endif; ?>
                        </a>
                        <div class="lj-body">
                            <?php if (!empty($p['category_name'])): ?>
                                <a class="lj-cat" href="<?= e(url('/journal.php?category=' . rawurlencode((string) $p['category_slug']))) ?>"><?= e($p['category_name']) ?></a>
                            <?php endif; ?>
                            <h2><a href="<?= e(url('/journal-article.php?slug=' . rawurlencode($p['slug']))) ?>"><?= e($p['title']) ?></a></h2>
                            <?php if (!empty($p['excerpt'])): ?>
                                <p><?= e($p['excerpt']) ?></p>
                            <?php endif; ?>
                            <span class="lj-meta">
                                <?php if (!empty($p['published_at'])): ?><time datetime="<?= e(date('Y-m-d', strtotime($p['published_at']))) ?>"><?= e(date('M j, Y', strtotime($p['published_at']))) ?></time><?php endif; ?>
                                <span>·</span>
                                <span><?= (int) max(1, ceil(str_word_count(strip_tags((string) $p['content'])) / 200)) ?> min read</span>
                            </span>
                        </div>
                    </article>
                <?php endforeach; ?>
            </div>
        <?php endif; ?>
    </div>
</section>

<section class="lx-journal-cta">
    <div class="container">
        <p>Ready to refresh your wardrobe?</p>
        <a href="<?= e(url('/shop.php')) ?>" class="lx-btn lx-btn-primary">SHOP WOMEN'S CLOTHING</a>
    </div>
</section>

<?php require __DIR__ . '/includes/storefront-footer.php'; ?>
