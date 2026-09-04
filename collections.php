<?php
declare(strict_types=1);
require_once __DIR__ . '/includes/bootstrap.php';

$cats = categories_with_counts();

$page_title       = 'Shop By Category';
$meta_description = 'Explore thoughtfully curated TayyabaCollective fashion collections — stitched, unstitched, formal, casual and more.';
$active_nav       = 'shop.php';

require __DIR__ . '/includes/storefront-header.php';
?>

<!-- HERO -->
<section class="categories-hero">
    <div class="container">
        <div class="categories-hero-content">
            <span class="eyebrow">TAYYABACOLLECTIVE COLLECTIONS</span>
            <h1>Shop By Category</h1>
            <p>Explore thoughtfully curated fashion collections designed for every mood, occasion and personal style.</p>
        </div>
    </div>
</section>

<!-- INTRO -->
<section class="categories-intro">
    <div class="container">
        <div class="categories-intro-inner">
            <span class="eyebrow">FIND YOUR STYLE</span>
            <h2>Designed For Every Occasion</h2>
            <p>From effortless everyday essentials to statement festive looks, discover pieces that reflect your individual style and make every moment memorable.</p>
        </div>
    </div>
</section>

<!-- CATEGORY COLLECTIONS (dynamic from MySQL) -->
<section class="fashion-categories">
    <div class="container">

        <?php if (!$cats): ?>
            <div class="section-empty">
                <i class="fa-regular fa-sparkles"></i>
                <h3>Collections coming soon</h3>
                <p>New collections are being prepared. Please check back shortly.</p>
            </div>
        <?php else: ?>

        <div class="fashion-category-grid">
            <?php foreach ($cats as $i => $cat): ?>
                <?php
                $isLarge = $i < 2;
                $img = image_url($cat['image'] ?? '');
                ?>
                <article class="fashion-category-card<?= $isLarge ? ' large' : '' ?>">
                    <div class="fashion-category-image">
                        <img src="<?= e($img) ?>" alt="<?= e($cat['name']) ?> collection" loading="lazy">
                    </div>
                    <div class="fashion-category-overlay"></div>
                    <div class="fashion-category-content">
                        <span class="category-number"><?= str_pad((string) ($i + 1), 2, '0', STR_PAD_LEFT) ?> / <?= str_pad((string) count($cats), 2, '0', STR_PAD_LEFT) ?></span>
                        <h3><?= e(strtoupper($cat['name'])) ?></h3>
                        <p><?= (int) $cat['product_count'] ?> piece<?= (int) $cat['product_count'] === 1 ? '' : 's' ?></p>
                        <a href="<?= e(category_url($cat['slug'])) ?>" class="category-shop-btn">
                            Shop Collection <i class="fa-solid fa-arrow-right"></i>
                        </a>
                    </div>
                </article>
            <?php endforeach; ?>
        </div>

        <?php endif; ?>
    </div>
</section>

<!-- WHY SHOP BY CATEGORY -->
<section class="category-feature-strip">
    <div class="container">
        <div class="category-feature-grid">
            <div class="category-feature">
                <i class="fa-solid fa-shirt"></i>
                <h3>Curated Styles</h3>
                <p>Carefully selected designs for different occasions and personal styles.</p>
            </div>
            <div class="category-feature">
                <i class="fa-solid fa-wand-magic-sparkles"></i>
                <h3>Premium Quality</h3>
                <p>Thoughtfully chosen fabrics with attention to detail in every stitch.</p>
            </div>
            <div class="category-feature">
                <i class="fa-solid fa-truck-fast"></i>
                <h3>Nationwide Delivery</h3>
                <p>Reliable delivery to your doorstep anywhere in Pakistan.</p>
            </div>
        </div>
    </div>
</section>

<?php require __DIR__ . '/includes/storefront-footer.php'; ?>