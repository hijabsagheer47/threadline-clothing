<?php
declare(strict_types=1);
require_once __DIR__ . '/includes/bootstrap.php';

$db = db();
$store = setting('store_name');

$slug = '';
if (isset($_GET['slug']) && is_string($_GET['slug'])) {
    $slug = preg_replace('/[^a-z0-9\-]/', '', strtolower($_GET['slug'])) ?? '';
}

$post = null;
if ($slug !== '' && tc_table_exists('journal_posts')) {
    $stmt = $db->prepare(
        "SELECT p.*, c.name AS category_name, c.slug AS category_slug
         FROM journal_posts p
         LEFT JOIN journal_categories c ON c.id = p.category_id
         WHERE p.slug = ? AND p.status = 'published'
           AND (p.published_at IS NULL OR p.published_at <= NOW())
         LIMIT 1"
    );
    $stmt->execute([$slug]);
    $post = $stmt->fetch() ?: null;
}

if (!$post) {
    http_response_code(404);
    $page_title       = 'Article Not Found';
    $robots_noindex   = true;
    $meta_description = 'This article could not be found.';
    require __DIR__ . '/includes/storefront-header.php';
    ?>
    <section class="lx-journal section-padding">
        <div class="container lx-journal-empty">
            <i class="fa-solid fa-feather-pointed"></i>
            <p>Sorry — this article could not be found.</p>
            <a href="<?= e(url('/journal.php')) ?>" class="lx-btn lx-btn-ghost">BACK TO THE STYLE JOURNAL</a>
        </div>
    </section>
    <?php
    require __DIR__ . '/includes/storefront-footer.php';
    exit;
}

/* --------------------------------------------------------------------- SEO */
$readMin  = (int) max(1, ceil(str_word_count(strip_tags((string) $post['content'])) / 200));
$excerpt  = (string) ($post['excerpt'] ?: mb_substr(strip_tags((string) $post['content']), 0, 155) . '…');
$full_title = ($post['meta_title'] ?: $post['title']) . ' | ' . $store . ' Style Journal';
$meta_description = $post['meta_description'] ?: $excerpt;
$canonical = abs_url('/journal-article.php?slug=' . rawurlencode($post['slug']));
$og_image = !empty($post['image']) ? abs_url(image_url($post['image'])) : '';

$articleUrl = $canonical;
$extra_schema = [
    [
        '@context' => 'https://schema.org',
        '@type' => 'Article',
        'headline' => $post['title'],
        'description' => $excerpt,
        'datePublished' => !empty($post['published_at']) ? date('c', strtotime($post['published_at'])) : date('c', strtotime($post['created_at'])),
        'dateModified' => date('c', strtotime($post['updated_at'])),
        'author' => ['@type' => 'Organization', 'name' => $store],
        'publisher' => ['@type' => 'Organization', 'name' => $store, 'url' => abs_url('/index.php')],
        'mainEntityOfPage' => ['@type' => 'WebPage', '@id' => $articleUrl],
        'url' => $articleUrl,
    ],
    [
        '@context' => 'https://schema.org',
        '@type' => 'BreadcrumbList',
        'itemListElement' => [
            ['@type' => 'ListItem', 'position' => 1, 'name' => 'Home', 'item' => abs_url('/index.php')],
            ['@type' => 'ListItem', 'position' => 2, 'name' => 'Style Journal', 'item' => abs_url('/journal.php')],
            ['@type' => 'ListItem', 'position' => 3, 'name' => $post['title'], 'item' => $articleUrl],
        ],
    ],
];

/* Related reading — real other published articles only. */
$related = [];
if (tc_table_exists('journal_posts')) {
    $stmt = $db->prepare(
        "SELECT title, slug, excerpt FROM journal_posts
         WHERE status = 'published' AND id <> ?
           AND (published_at IS NULL OR published_at <= NOW())
         ORDER BY COALESCE(published_at, created_at) DESC LIMIT 3"
    );
    $stmt->execute([(int) $post['id']]);
    $related = $stmt->fetchAll();
}

require __DIR__ . '/includes/storefront-header.php';
?>

<nav class="lx-breadcrumb container" aria-label="Breadcrumb">
    <a href="<?= e(url('/index.php')) ?>">Home</a>
    <i class="fa-solid fa-chevron-right"></i>
    <a href="<?= e(url('/journal.php')) ?>">Style Journal</a>
    <i class="fa-solid fa-chevron-right"></i>
    <span aria-current="page"><?= e($post['title']) ?></span>
</nav>

<article class="lx-article section-padding">
    <div class="container lx-article-wrap">

        <header class="lx-article-head">
            <?php if (!empty($post['category_name'])): ?>
                <a class="lj-cat" href="<?= e(url('/journal.php?category=' . rawurlencode((string) $post['category_slug']))) ?>"><?= e($post['category_name']) ?></a>
            <?php endif; ?>
            <h1><?= e($post['title']) ?></h1>
            <?php if ($excerpt !== ''): ?>
                <p class="lx-article-lead"><?= e($excerpt) ?></p>
            <?php endif; ?>
            <div class="lx-article-meta">
                <?php if (!empty($post['published_at'])): ?>
                    <time datetime="<?= e(date('Y-m-d', strtotime($post['published_at']))) ?>"><?= e(date('F j, Y', strtotime($post['published_at']))) ?></time>
                <?php endif; ?>
                <span>·</span>
                <span><?= $readMin ?> min read</span>
                <span>·</span>
                <span>By <?= e(!empty($post['author']) ? (string) $post['author'] : $store) ?></span>
            </div>
        </header>

        <?php if (!empty($post['image'])): ?>
            <figure class="lx-article-image">
                <img src="<?= e(image_url($post['image'])) ?>" alt="<?= e($post['title']) ?> — <?= e($store) ?>" loading="lazy">
            </figure>
        <?php endif; ?>

        <div class="lx-article-content">
            <?= $post['content'] /* admin-authored HTML */ ?>
        </div>

        <aside class="lx-article-cta">
            <div>
                <p class="section-label">EXPLORE THE COLLECTION</p>
                <h2>Find your next favourite outfit</h2>
            </div>
            <div class="lx-article-cta-btns">
                <a href="<?= e(url('/shop.php')) ?>" class="lx-btn lx-btn-primary">SHOP ALL</a>
                <a href="<?= e(category_url('new-arrivals')) ?>" class="lx-btn lx-btn-ghost">NEW ARRIVALS</a>
            </div>
        </aside>

        <?php if ($related): ?>
        <section class="lx-article-related" aria-labelledby="lx-related-title">
            <h2 id="lx-related-title">Keep reading</h2>
            <div class="lx-journal-grid">
                <?php foreach ($related as $r): ?>
                    <article class="lx-journal-card">
                        <div class="lj-body">
                            <h3><a href="<?= e(url('/journal-article.php?slug=' . rawurlencode($r['slug']))) ?>"><?= e($r['title']) ?></a></h3>
                            <?php if (!empty($r['excerpt'])): ?><p><?= e($r['excerpt']) ?></p><?php endif; ?>
                        </div>
                    </article>
                <?php endforeach; ?>
            </div>
        </section>
        <?php endif; ?>

        <p class="lx-article-back">
            <a href="<?= e(url('/journal.php')) ?>"><i class="fa-solid fa-arrow-left"></i> All Style Journal articles</a>
        </p>

    </div>
</article>

<?php require __DIR__ . '/includes/storefront-footer.php'; ?>
