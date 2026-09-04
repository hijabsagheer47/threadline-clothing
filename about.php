<?php
declare(strict_types=1);
require_once __DIR__ . '/includes/bootstrap.php';

$page_title       = 'About Us';
$meta_description = 'The story behind ' . setting('store_name') . ' — thoughtfully designed clothing for every version of you.';
$active_nav       = 'about.php';

require __DIR__ . '/includes/storefront-header.php';
?>

<section class="about-hero">
    <div class="about-hero-overlay"></div>
    <div class="container about-hero-content">
        <p class="section-label">OUR STORY</p>
        <h1>Designed with intention.</h1>
        <p>Fashion that celebrates individuality, confidence and timeless elegance.</p>
    </div>
</section>

<!-- INTRO -->
<section class="about-intro section-padding">
    <div class="container about-intro-grid">
        <div class="about-intro-content">
            <p class="section-label">ABOUT <?= e(strtoupper(setting('store_name'))) ?></p>
            <h2>Where timeless style meets modern expression.</h2>
            <p><?= e(setting('store_name')) ?> was created with a simple idea — clothing should feel as beautiful as it looks.</p>
            <p>We bring together refined silhouettes, thoughtful details and carefully selected fabrics to create pieces that can become part of your everyday wardrobe.</p>
            <p>From elegant eastern wear to contemporary western styles, every collection is designed to make you feel confident, comfortable and effortlessly yourself.</p>
        </div>
        <div class="about-intro-image">
            <img src="https://images.unsplash.com/photo-1496747611176-843222e1e57c?auto=format&fit=crop&w=1000&q=90" alt="<?= e(setting('store_name')) ?> fashion collection">
        </div>
    </div>
</section>

<!-- PHILOSOPHY -->
<section class="about-philosophy section-padding">
    <div class="container">
        <div class="section-heading">
            <p class="section-label">OUR PHILOSOPHY</p>
            <h2>Less noise. More meaning.</h2>
            <p>We believe great fashion is about pieces that stay relevant beyond a season.</p>
        </div>
        <div class="philosophy-grid">
            <div class="philosophy-card">
                <div class="philosophy-number">01</div>
                <h3>Thoughtful Design</h3>
                <p>Every silhouette, detail and finish is carefully considered to create clothing that feels effortlessly refined.</p>
            </div>
            <div class="philosophy-card">
                <div class="philosophy-number">02</div>
                <h3>Timeless Style</h3>
                <p>We create collections that move beyond temporary trends and remain beautiful season after season.</p>
            </div>
            <div class="philosophy-card">
                <div class="philosophy-number">03</div>
                <h3>Made for You</h3>
                <p>From everyday essentials to occasion pieces, our clothing is designed around the way modern women live and express themselves.</p>
            </div>
        </div>
    </div>
</section>

<!-- STATEMENT -->
<section class="about-statement">
    <div class="about-statement-image">
        <img src="https://images.unsplash.com/photo-1483985988355-763728e1935b?auto=format&fit=crop&w=1800&q=90" alt="Elegant fashion styling">
    </div>
    <div class="about-statement-content">
        <p class="section-label">THE <?= e(strtoupper(setting('store_name'))) ?> WOMAN</p>
        <h2>Confident. Individual. Unapologetically herself.</h2>
        <p><?= e(setting('store_name')) ?> is for every version of you — the woman who keeps things classic, the one who loves experimenting and the one who simply wants to feel good in what she wears.</p>
        <a href="<?= url('/shop.php') ?>" class="btn btn-primary">Explore Collection <i class="fa-solid fa-arrow-right"></i></a>
    </div>
</section>

<!-- VALUES -->
<section class="about-values section-padding">
    <div class="container">
        <div class="section-top">
            <div class="section-heading left">
                <p class="section-label">WHAT WE VALUE</p>
                <h2>The details matter.</h2>
            </div>
        </div>
        <div class="values-grid">
            <div class="value-card">
                <i class="fa-solid fa-gem"></i>
                <h3>Quality</h3>
                <p>We focus on fabrics, finishing and details that make every piece feel considered.</p>
            </div>
            <div class="value-card">
                <i class="fa-solid fa-leaf"></i>
                <h3>Simplicity</h3>
                <p>Clean silhouettes and thoughtful design allow each piece to speak for itself.</p>
            </div>
            <div class="value-card">
                <i class="fa-solid fa-heart"></i>
                <h3>Confidence</h3>
                <p>Clothing should help you express yourself and feel comfortable in your own identity.</p>
            </div>
            <div class="value-card">
                <i class="fa-solid fa-star"></i>
                <h3>Craftsmanship</h3>
                <p>We appreciate the small details that transform a simple garment into something special.</p>
            </div>
        </div>
    </div>
</section>

<!-- CTA -->
<section class="about-cta">
    <div class="container">
        <p class="section-label">FIND YOUR STYLE</p>
        <h2>Your wardrobe, your story.</h2>
        <p>Explore collections designed to celebrate you.</p>
        <a href="<?= url('/collections.php') ?>" class="btn btn-outline">Shop Collections</a>
    </div>
</section>

<?php require __DIR__ . '/includes/storefront-footer.php'; ?>