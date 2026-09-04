<?php
declare(strict_types=1);
require_once __DIR__ . '/includes/bootstrap.php';

$page_title = setting('store_tagline', 'Where Style Meets Elegance');
$active_nav = 'index.php';

$homeCategories = categories_with_counts(8);
$newIn          = new_arrivals(8);
$bestSellers    = best_sellers(8);
$saleItems      = sale_products(4);

function section_empty(string $label): string
{
    return '<div class="section-empty">
        <i class="fa-regular fa-sparkles"></i>
        <h3>Coming soon</h3>
        <p>New ' . e($label) . ' pieces are being prepared. Please check back shortly.</p>
    </div>';
}

require __DIR__ . '/includes/storefront-header.php';
?>

<!-- HERO -->
<section class="hero-section">
    <div class="hero-overlay"></div>
    <div class="container hero-content">
        <p class="hero-eyebrow">NEW SEASON 2026</p>
        <h1>Elegance Woven<br>Into Every Thread</h1>
        <p class="hero-description">
            Discover thoughtfully designed pieces that bring
            timeless elegance and modern style to every occasion.
        </p>
        <div class="hero-buttons">
            <a href="<?= url('/shop.php') ?>" class="btn btn-primary">Shop Collection</a>
            <a href="<?= url('/collections.php') ?>" class="btn btn-outline">Explore Categories</a>
        </div>
    </div>
</section>

<!-- SHOP BY CATEGORY (dynamic) -->
<section class="category-section section-padding">
    <div class="container">
        <div class="section-heading">
            <p class="section-label">EXPLORE</p>
            <h2>Shop By Category</h2>
            <p>Find a style that feels uniquely yours.</p>
        </div>

        <div class="category-grid">
            <?php if (!$homeCategories): ?>
                <div class="category-grid-empty">Categories are being prepared.</div>
            <?php endif; ?>
            <?php foreach ($homeCategories as $cat): ?>
                <a href="<?= e(category_url($cat['slug'])) ?>" class="category-card">
                    <div class="category-image">
                        <img src="<?= e(image_url($cat['image'] ?? '')) ?>"
                             alt="<?= e($cat['name']) ?>" loading="lazy">
                    </div>
                    <div class="category-content">
                        <h3><?= e($cat['name']) ?></h3>
                        <span>Explore Collection <i class="fa-solid fa-arrow-right"></i></span>
                    </div>
                </a>
            <?php endforeach; ?>
        </div>
    </div>
</section>

<!-- NEW ARRIVALS (dynamic) -->
<section class="products-section section-padding">
    <div class="container">
        <div class="section-top">
            <div class="section-heading left">
                <p class="section-label">JUST IN</p>
                <h2>New Arrivals</h2>
                <p>Fresh silhouettes designed for the season.</p>
            </div>
            <a href="<?= url('/shop.php?sort=newest') ?>" class="text-link">View All <i class="fa-solid fa-arrow-right"></i></a>
        </div>

        <?php if (!$newIn): ?>
            <?= section_empty('arrival') ?>
        <?php else: ?>
        <div class="product-grid">
            <?php foreach ($newIn as $product) echo render_product_card($product); ?>
        </div>
        <?php endif; ?>
    </div>
</section>

<!-- FEATURED EDIT (brand banner) -->
<section class="featured-section">
    <div class="featured-image">
        <img src="https://images.unsplash.com/photo-1485230895905-ec40ba36b9bc?auto=format&fit=crop&w=1400&q=90"
             alt="TayyabaCollective featured fashion collection" loading="lazy">
    </div>
    <div class="featured-content">
        <p class="section-label">THE TAYYABACOLLECTIVE EDIT</p>
        <h2>Made for Moments<br>That Matter</h2>
        <p>
            From effortless everyday looks to statement pieces
            for special occasions, discover designs created to
            make you feel confident, comfortable and beautifully you.
        </p>
        <a href="<?= url('/shop.php?featured=1') ?>" class="btn btn-primary">Discover The Collection</a>
    </div>
</section>

<!-- WHY TAYYABACOLLECTIVE -->
<section class="why-section section-padding">
    <div class="container">
        <div class="section-heading">
            <p class="section-label">WHY TAYYABACOLLECTIVE</p>
            <h2>Designed With You In Mind</h2>
        </div>
        <div class="features-grid">
            <div class="feature-card">
                <div class="feature-icon"><i class="fa-solid fa-gem"></i></div>
                <h3>Quality Fabrics</h3>
                <p>Carefully selected fabrics designed for comfort, durability and everyday elegance.</p>
            </div>
            <div class="feature-card">
                <div class="feature-icon"><i class="fa-solid fa-scissors"></i></div>
                <h3>Thoughtful Design</h3>
                <p>Every silhouette is designed with attention to fit, detail and timeless style.</p>
            </div>
            <div class="feature-card">
                <div class="feature-icon"><i class="fa-solid fa-truck-fast"></i></div>
                <h3>Easy Delivery</h3>
                <p>Reliable delivery options that bring your favorite pieces right to your doorstep.</p>
            </div>
            <div class="feature-card">
                <div class="feature-icon"><i class="fa-solid fa-headset"></i></div>
                <h3>Customer Care</h3>
                <p>Our team is here to help you before and after every purchase.</p>
            </div>
        </div>
    </div>
</section>

<!-- BEST SELLERS (dynamic) -->
<section class="products-section section-padding">
    <div class="container">
        <div class="section-top">
            <div class="section-heading left">
                <p class="section-label">CUSTOMER FAVORITES</p>
                <h2>Best Sellers</h2>
                <p>Pieces our customers keep coming back for.</p>
            </div>
            <a href="<?= url('/shop.php?sort=best_selling') ?>" class="text-link">Shop All <i class="fa-solid fa-arrow-right"></i></a>
        </div>

        <?php if (!$bestSellers): ?>
            <?= section_empty('best seller') ?>
        <?php else: ?>
        <div class="product-grid">
            <?php foreach ($bestSellers as $product) echo render_product_card($product); ?>
        </div>
        <?php endif; ?>
    </div>
</section>

<!-- SALE (dynamic, only when sale products exist) -->
<?php if ($saleItems): ?>
<section class="products-section sale-section section-padding">
    <div class="container">
        <div class="section-top">
            <div class="section-heading left">
                <p class="section-label">LIMITED TIME</p>
                <h2>On Sale</h2>
                <p>Marked-down favourites while stock lasts.</p>
            </div>
            <a href="<?= url('/shop.php?sale=1') ?>" class="text-link">View Sale <i class="fa-solid fa-arrow-right"></i></a>
        </div>
        <div class="product-grid">
            <?php foreach ($saleItems as $product) echo render_product_card($product); ?>
        </div>
    </div>
</section>
<?php endif; ?>

<!-- CUSTOMER REVIEWS -->
<section class="reviews-section section-padding">
    <div class="container">
        <div class="section-heading">
            <p class="section-label">CUSTOMER LOVE</p>
            <h2>What Our Customers Say</h2>
        </div>
        <div class="reviews-grid">
            <article class="review-card">
                <div class="review-stars">★★★★★</div>
                <p>"The fabric quality was even better than I expected. The dress looked beautiful and the finishing was perfect."</p>
                <div class="review-author"><div class="author-avatar">A</div><div><strong>Ayesha K.</strong><span>Verified Customer</span></div></div>
            </article>
            <article class="review-card">
                <div class="review-stars">★★★★★</div>
                <p>"I loved the fit and the details. Everything from ordering to delivery was smooth and easy."</p>
                <div class="review-author"><div class="author-avatar">M</div><div><strong>Maham R.</strong><span>Verified Customer</span></div></div>
            </article>
            <article class="review-card">
                <div class="review-stars">★★★★★</div>
                <p>"Beautiful collection and very elegant designs. Definitely coming back for the next collection."</p>
                <div class="review-author"><div class="author-avatar">S</div><div><strong>Sara A.</strong><span>Verified Customer</span></div></div>
            </article>
        </div>
    </div>
</section>

<!-- NEWSLETTER -->
<section class="newsletter-section">
    <div class="container newsletter-container">
        <div class="newsletter-content">
            <p class="section-label">STAY IN THE LOOP</p>
            <h2>Be the first to know.</h2>
            <p>Sign up for new arrivals, exclusive offers and seasonal inspiration.</p>
        </div>
        <form class="newsletter-form" data-newsletter-form>
            <?= csrf_field() ?>
            <label for="newsletter-email" class="sr-only">Email address</label>
            <input type="email" id="newsletter-email" name="email" placeholder="Enter your email address" required>
            <button type="submit">Subscribe</button>
        </form>
    </div>
</section>

<!-- GALLERY -->
<section class="gallery-section section-padding">
    <div class="container">
        <div class="section-heading">
            <p class="section-label">@TAYYABACOLLECTIVE</p>
            <h2>Follow Our Style</h2>
            <p>Everyday inspiration, new collections and more.</p>
        </div>
        <div class="gallery-grid">
            <img src="https://images.unsplash.com/photo-1485230895905-ec40ba36b9bc?auto=format&fit=crop&w=700&q=85" alt="TayyabaCollective fashion style" loading="lazy">
            <img src="https://images.unsplash.com/photo-1525507119028-ed4c629a60a3?auto=format&fit=crop&w=700&q=85" alt="Fashion collection" loading="lazy">
            <img src="https://images.unsplash.com/photo-1496747611176-843222e1e57c?auto=format&fit=crop&w=700&q=85" alt="Women's fashion" loading="lazy">
            <img src="https://images.unsplash.com/photo-1509631179647-0177331693ae?auto=format&fit=crop&w=700&q=85" alt="Elegant fashion outfit" loading="lazy">
        </div>
    </div>
</section>

<?php require __DIR__ . '/includes/storefront-footer.php'; ?>