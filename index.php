<?php
declare(strict_types=1);
require_once __DIR__ . '/includes/bootstrap.php';

/* Homepage SEO — brand + broad commercial intent (one primary topic, no stuffing). */
$full_title       = setting('store_name') . " | Women's Clothing & Fashion Online in Pakistan";
$page_title       = setting('store_tagline', 'Where Style Meets Elegance');
$meta_description = "Shop women's clothing online in Pakistan with " . setting('store_name')
    . '. Explore stitched and unstitched suits, lawn, formal wear, casual styles and new fashion collections.';
$active_nav       = 'index.php';

$homeCategories = categories_with_counts(8);
$newIn          = new_arrivals(8);
$bestSellers    = best_sellers(8);
$saleItems      = sale_products(4);
$heroSlides     = tc_hero_slides();

/* Shop-by-fabric chips + occasion links (real categories only) */
$facets       = product_facets();
$homeFabrics  = array_slice($facets['fabrics'] ?? [], 0, 10);
$homeOccasions = [];
foreach (['formal-wear', 'casual-wear', 'festive-collection', 'eid-collection', 'luxury-collection', 'eastern-wear'] as $occSlug) {
    $occ = get_category_by_slug($occSlug);
    if ($occ && (int) $occ['status'] === 1) {
        $homeOccasions[] = $occ;
    }
}

/* Floating hero cards — real products, never invented data */
$heroCards = [];
foreach (array_slice($newIn, 0, 3) as $hp) {
    $heroCards[] = [
        'name'     => $hp['name'],
        'price'    => money(effective_price($hp)),
        'old'      => product_has_sale($hp) ? money((float) $hp['price']) : '',
        'image'    => image_url($hp['primary_image'] ?? ''),
        'cat'      => $hp['category_names'] !== null && $hp['category_names'] !== ''
                        ? explode(', ', (string) $hp['category_names'])[0]
                        : setting('store_name'),
        'url'      => product_url($hp['slug']),
    ];
}

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

<?php
/* Hero copy: admin-managed slide when present, brand default otherwise. */
$hero = $heroSlides ? $heroSlides[0] : null;
$heroEyebrow   = !empty($hero['eyebrow'])   ? $hero['eyebrow']   : 'NEW SEASON';
$heroTitle     = !empty($hero['title'])     ? $hero['title']     : 'The Signature Edit';
$heroSubtitle  = !empty($hero['subtitle'])  ? $hero['subtitle']  : 'Timeless silhouettes. Contemporary elegance.';
$heroCta1      = !empty($hero['cta_text'])           ? $hero['cta_text']           : 'SHOP NEW ARRIVALS';
$heroCta1Link  = !empty($hero['cta_link'])           ? tc_menu_url(['url' => $hero['cta_link']]) : url('/shop.php?sort=newest');
$heroCta2      = !empty($hero['cta_secondary_text']) ? $hero['cta_secondary_text'] : 'EXPLORE COLLECTION';
$heroCta2Link  = !empty($hero['cta_secondary_link']) ? tc_menu_url(['url' => $hero['cta_secondary_link']]) : url('/collections.php');
$heroImage     = image_url($hero['image'] ?? '');
if ($heroImage === '' && $newIn) {
    $heroImage = image_url($newIn[0]['primary_image'] ?? '');
}
$freeOver   = (float) setting('free_shipping_threshold', '8000');
?>

<!-- HERO — 3D fashion experience -->
<section class="lx-hero" aria-label="Featured collection">
    <canvas class="lx-hero-particles" aria-hidden="true"></canvas>
    <canvas class="lx-hero-3d" aria-hidden="true"></canvas>
    <div class="container lx-hero-inner">

        <div class="lx-hero-copy">
            <p class="lx-hero-eyebrow"><?= e($heroEyebrow) ?></p>
            <?php if ($heroTitle !== ''): ?>
            <p class="lx-hero-campaign"><?= e($heroTitle) ?></p>
            <?php endif; ?>
            <h1 class="lx-hero-title">Women's Fashion <span class="line-2">&amp; Clothing Online in Pakistan</span></h1>
            <p class="lx-hero-sub"><?= e($heroSubtitle) ?> Discover thoughtfully designed women's clothing from <?= e(setting('store_name')) ?>, including stitched and unstitched outfits, lawn, formal wear, casual wear, co-ords and seasonal collections.</p>
            <div class="lx-hero-cta">
                <a href="<?= e($heroCta1Link) ?>" class="lx-btn lx-btn-primary"><?= e($heroCta1) ?></a>
                <a href="<?= e($heroCta2Link) ?>" class="lx-btn lx-btn-ghost"><?= e($heroCta2) ?></a>
            </div>
            <div class="lx-hero-trust">
                <span><i class="fa-solid fa-truck-fast"></i> Free delivery over <?= e(money($freeOver)) ?></span>
                <span><i class="fa-solid fa-rotate-left"></i> <?= (int) setting('exchange_policy_days', '7') ?>-day exchange</span>
                <span><i class="fa-solid fa-hand-holding-dollar"></i> Cash on delivery</span>
            </div>
        </div>

        <div class="lx-hero-stage">
            <canvas class="lx-fabric-canvas" aria-hidden="true"></canvas>
            <div class="lx-hero-frame-ghost" aria-hidden="true"></div>
            <?php if ($heroImage !== ''): ?>
            <div class="lx-hero-frame">
                <img src="<?= e($heroImage) ?>"
                     alt="<?= e($heroTitle) ?> — <?= e(setting('store_name')) ?>"
                     fetchpriority="high" width="900" height="1200">
            </div>
            <?php endif; ?>

            <?php $cardClasses = ['lx-float-card--a', 'lx-float-card--b', 'lx-float-card--c']; ?>
            <?php foreach ($heroCards as $i => $hc): ?>
            <a class="lx-float-card <?= e($cardClasses[$i] ?? 'lx-float-card--a') ?>" href="<?= e($hc['url']) ?>">
                <img src="<?= e($hc['image']) ?>" alt="<?= e($hc['name']) ?>" loading="lazy" width="108" height="132">
                <span class="fc-body">
                    <span class="fc-cat"><?= e($hc['cat']) ?></span>
                    <span class="fc-name"><?= e($hc['name']) ?></span>
                    <span class="fc-price"><?php if ($hc['old'] !== ''): ?><s><?= e($hc['old']) ?></s><?php endif; ?><?= e($hc['price']) ?></span>
                </span>
            </a>
            <?php endforeach; ?>
        </div>

    </div>
    <a class="lx-hero-cue" href="#shop-by-category">Scroll<span></span></a>
</section>

<!-- TRUST STRIP -->
<section class="trust-strip" aria-label="Store promises">
    <div class="container">
        <div class="trust-item">
            <i class="fa-solid fa-truck-fast"></i>
            <div><strong>Fast Delivery</strong><span>Nationwide, 2–5 working days</span></div>
        </div>
        <div class="trust-item">
            <i class="fa-solid fa-hand-holding-dollar"></i>
            <div><strong>Cash on Delivery</strong><span>Pay when your order arrives</span></div>
        </div>
        <div class="trust-item">
            <i class="fa-solid fa-rotate-left"></i>
            <div><strong>Easy Returns</strong><span>7-day hassle-free exchange</span></div>
        </div>
        <div class="trust-item">
            <i class="fa-solid fa-headset"></i>
            <div><strong>Dedicated Support</strong><span>We reply within hours</span></div>
        </div>
    </div>
</section>

<!-- SHOP BY CATEGORY (dynamic) -->
<section class="category-section section-padding" id="shop-by-category">
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

<!-- SHOP BY FABRIC + OCCASION -->
<section class="fabric-section section-padding" id="shop-by-fabric">
    <div class="container">
        <div class="section-heading">
            <p class="section-label">FIND YOUR STYLE</p>
            <h2>Shop By Fabric &amp; Occasion</h2>
            <p>Explore the collection by the fabric you love or the moment you are dressing for.</p>
        </div>

        <div class="fabric-groups">
            <?php if ($homeFabrics): ?>
            <div class="fabric-group">
                <h3>Fabric</h3>
                <div class="fabric-strip">
                    <?php foreach ($homeFabrics as $fab): ?>
                        <a class="fabric-chip" href="<?= e(url('/shop.php?fabric=' . rawurlencode((string) $fab))) ?>"><?= e((string) $fab) ?></a>
                    <?php endforeach; ?>
                </div>
            </div>
            <?php endif; ?>

            <?php if ($homeOccasions): ?>
            <div class="fabric-group">
                <h3>Occasion</h3>
                <div class="fabric-strip">
                    <?php foreach ($homeOccasions as $occ): ?>
                        <a class="fabric-chip" href="<?= e(category_url($occ['slug'])) ?>"><?= e($occ['name']) ?></a>
                    <?php endforeach; ?>
                </div>
            </div>
            <?php endif; ?>
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
             alt="<?= e(setting('store_name')) ?> featured fashion collection" loading="lazy">
    </div>
    <div class="featured-content">
        <p class="section-label">THE <?= e(strtoupper(setting('store_name'))) ?> EDIT</p>
        <h2>Made for Moments<br>That Matter</h2>
        <p>
            From effortless everyday looks to statement pieces
            for special occasions, discover designs created to
            make you feel confident, comfortable and beautifully you.
        </p>
        <a href="<?= url('/shop.php?featured=1') ?>" class="btn btn-primary">Discover The Collection</a>
    </div>
</section>

<!-- WHY US -->
<section class="why-section section-padding">
    <div class="container">
        <div class="section-heading lx-reveal">
            <p class="section-label">WHY <?= e(strtoupper(setting('store_name'))) ?></p>
            <h2>Designed With You In Mind</h2>
        </div>
        <div class="features-grid">
            <div class="feature-card lx-reveal" style="--lx-delay: 0ms">
                <div class="lx-lottie" data-lottie="quality"><i class="fa-solid fa-gem"></i></div>
                <h3>Quality Fabrics</h3>
                <p>Carefully selected fabrics designed for comfort, durability and everyday elegance.</p>
            </div>
            <div class="feature-card lx-reveal" style="--lx-delay: 90ms">
                <div class="lx-lottie" data-lottie="design"><i class="fa-solid fa-scissors"></i></div>
                <h3>Thoughtful Design</h3>
                <p>Every silhouette is designed with attention to fit, detail and timeless style.</p>
            </div>
            <div class="feature-card lx-reveal" style="--lx-delay: 180ms">
                <div class="lx-lottie" data-lottie="truck"><i class="fa-solid fa-truck-fast"></i></div>
                <h3>Easy Delivery</h3>
                <p>Reliable delivery options that bring your favorite pieces right to your doorstep.</p>
            </div>
            <div class="feature-card lx-reveal" style="--lx-delay: 270ms">
                <div class="lx-lottie" data-lottie="support"><i class="fa-solid fa-headset"></i></div>
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

<!-- THE FASHLAB EXPERIENCE — signature 3D section -->
<section class="lx-experience" aria-labelledby="lx-exp-title">
    <div class="lx-exp-fallback" aria-hidden="true"><div class="ring"></div></div>
    <canvas class="lx-exp-canvas" aria-hidden="true"></canvas>
    <div class="lx-exp-inner lx-reveal">
        <p class="section-label">THE <?= e(strtoupper(setting('store_name'))) ?> EXPERIENCE</p>
        <h2 id="lx-exp-title">Designed for <em>Your Moments.</em></h2>
        <p>From effortless everyday looks to statement pieces for special occasions — every silhouette is crafted to move with you.</p>
        <a href="<?= url('/collections.php') ?>" class="lx-btn lx-btn-primary">Discover The Collection</a>
    </div>
</section>

<!-- SALE (dynamic, only when sale products exist) -->
<?php if ($saleItems): ?>
<section class="products-section sale-section section-padding">
    <div class="container">
        <div class="section-top">
            <div class="section-heading left">
                <p class="section-label">LIMITED TIME</p>
                <h2>The Sale Edit</h2>
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
        <div class="section-heading lx-reveal">
            <p class="section-label">CUSTOMER LOVE</p>
            <h2>What Our Customers Say</h2>
        </div>
        <?php
        /* Real approved reviews from the database take precedence; the original
           curated testimonials remain as the fallback when none exist yet. */
        $homeReviews = tc_table_exists('reviews')
            ? db()->query("SELECT * FROM reviews WHERE status IN ('approved','featured') ORDER BY (status='featured') DESC, created_at DESC LIMIT 3")->fetchAll()
            : [];
        ?>
        <?php if ($homeReviews): ?>
        <div class="reviews-grid">
            <?php foreach ($homeReviews as $rv): ?>
            <article class="review-card lx-reveal">
                <div class="review-stars"><?php for ($s = 1; $s <= 5; $s++): ?><?= $s <= (int) $rv['rating'] ? '★' : '☆' ?><?php endfor; ?></div>
                <p>"<?= e($rv['body']) ?>"</p>
                <div class="review-author">
                    <div class="author-avatar"><?= e(mb_strtoupper(mb_substr($rv['name'], 0, 1))) ?></div>
                    <div><strong><?= e($rv['name']) ?></strong>
                    <?php if ((int) $rv['is_verified_purchase'] === 1): ?><span>Verified Customer</span><?php endif; ?></div>
                </div>
            </article>
            <?php endforeach; ?>
        </div>
        <?php else: ?>
        <div class="reviews-grid">
            <article class="review-card lx-reveal" style="--lx-delay: 0ms">
                <div class="review-stars">★★★★★</div>
                <p>"The fabric quality was even better than I expected. The dress looked beautiful and the finishing was perfect."</p>
                <div class="review-author"><div class="author-avatar">A</div><div><strong>Ayesha K.</strong><span>Verified Customer</span></div></div>
            </article>
            <article class="review-card lx-reveal" style="--lx-delay: 90ms">
                <div class="review-stars">★★★★★</div>
                <p>"I loved the fit and the details. Everything from ordering to delivery was smooth and easy."</p>
                <div class="review-author"><div class="author-avatar">M</div><div><strong>Maham R.</strong><span>Verified Customer</span></div></div>
            </article>
            <article class="review-card lx-reveal" style="--lx-delay: 180ms">
                <div class="review-stars">★★★★★</div>
                <p>"Beautiful collection and very elegant designs. Definitely coming back for the next collection."</p>
                <div class="review-author"><div class="author-avatar">S</div><div><strong>Sara A.</strong><span>Verified Customer</span></div></div>
            </article>
        </div>
        <?php endif; ?>
    </div>
</section>

<!-- STYLE JOURNAL (real published articles) -->
<?php
$homeJournal = [];
if (tc_table_exists('journal_posts')) {
    $homeJournal = db()->query(
        "SELECT title, slug, excerpt, published_at, created_at
         FROM journal_posts
         WHERE status = 'published'
           AND (published_at IS NULL OR published_at <= NOW())
         ORDER BY COALESCE(published_at, created_at) DESC
         LIMIT 3"
    )->fetchAll();
}
?>
<?php if ($homeJournal): ?>
<section class="products-section section-padding" aria-labelledby="lx-home-journal-title">
    <div class="container">
        <div class="section-top">
            <div class="section-heading left lx-reveal">
                <p class="section-label">FROM THE JOURNAL</p>
                <h2 id="lx-home-journal-title">The Style Journal</h2>
                <p>Fabric guides, styling notes and dressing advice — worth reading before your next order.</p>
            </div>
            <a href="<?= e(url('/journal.php')) ?>" class="text-link">Read The Journal <i class="fa-solid fa-arrow-right"></i></a>
        </div>
        <div class="lx-journal-grid">
            <?php foreach ($homeJournal as $jp): ?>
                <article class="lx-journal-card lx-reveal">
                    <div class="lj-body">
                        <h3><a href="<?= e(url('/journal-article.php?slug=' . rawurlencode($jp['slug']))) ?>"><?= e($jp['title']) ?></a></h3>
                        <?php if (!empty($jp['excerpt'])): ?><p><?= e($jp['excerpt']) ?></p><?php endif; ?>
                        <span class="lj-meta">
                            <time datetime="<?= e(date('Y-m-d', strtotime($jp['published_at'] ?: $jp['created_at']))) ?>"><?= e(date('M j, Y', strtotime($jp['published_at'] ?: $jp['created_at']))) ?></time>
                        </span>
                    </div>
                </article>
            <?php endforeach; ?>
        </div>
    </div>
</section>
<?php endif; ?>

<!-- GALLERY -->
<section class="gallery-section section-padding">
    <div class="container">
        <div class="section-heading lx-reveal">
            <p class="section-label">@<?= e(strtoupper(str_replace(' ', '', setting('store_name')))) ?></p>
            <h2>Follow Our Style</h2>
            <p>Everyday inspiration, new collections and more.</p>
        </div>
        <div class="gallery-grid">
            <img src="https://images.unsplash.com/photo-1485230895905-ec40ba36b9bc?auto=format&fit=crop&w=700&q=85" alt="<?= e(setting('store_name')) ?> fashion style" loading="lazy">
            <img src="https://images.unsplash.com/photo-1525507119028-ed4c629a60a3?auto=format&fit=crop&w=700&q=85" alt="Fashion collection" loading="lazy">
            <img src="https://images.unsplash.com/photo-1496747611176-843222e1e57c?auto=format&fit=crop&w=700&q=85" alt="Women's fashion" loading="lazy">
            <img src="https://images.unsplash.com/photo-1509631179647-0177331693ae?auto=format&fit=crop&w=700&q=85" alt="Elegant fashion outfit" loading="lazy">
        </div>
        <?php if (setting('instagram_url', '#') !== '#' && setting('instagram_url', '') !== ''): ?>
        <div class="gallery-cta">
            <a href="<?= e(setting('instagram_url')) ?>" class="lx-btn lx-btn-ghost" target="_blank" rel="noopener noreferrer">
                <i class="fa-brands fa-instagram"></i> Follow @<?= e(strtoupper(str_replace(' ', '', setting('store_name')))) ?>
            </a>
        </div>
        <?php endif; ?>
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

<?php require __DIR__ . '/includes/storefront-footer.php'; ?>