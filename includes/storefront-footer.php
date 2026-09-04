<?php
/**
 * Storefront footer partial.
 */
declare(strict_types=1);

$storeName  = setting('store_name', 'TayyabaCollective');
$footerCats = get_categories(true); // first five, no nav filter
$shopCats   = array_slice($footerCats, 0, 5);
$credit     = setting('footer_credit', '');
?>
</main>

<!-- Footer -->
<footer class="site-footer">
    <div class="container footer-grid">

        <div class="footer-brand">
            <a href="<?= url('/index.php') ?>" class="footer-logo"><?= e($storeName) ?></a>
            <p>Thoughtfully designed clothing for every version of you.</p>

            <div class="social-links">
                <a href="<?= e(setting('instagram_url', '#')) ?>" aria-label="Instagram"><i class="fa-brands fa-instagram"></i></a>
                <a href="<?= e(setting('facebook_url', '#')) ?>" aria-label="Facebook"><i class="fa-brands fa-facebook-f"></i></a>
                <a href="<?= e(setting('tiktok_url', '#')) ?>" aria-label="TikTok"><i class="fa-brands fa-tiktok"></i></a>
            </div>
        </div>

        <div class="footer-column">
            <h3>Shop</h3>
            <a href="<?= url('/shop.php?sort=newest') ?>">New Arrivals</a>
            <?php foreach ($shopCats as $cat): ?>
                <a href="<?= e(category_url($cat['slug'])) ?>"><?= e($cat['name']) ?></a>
            <?php endforeach; ?>
        </div>

        <div class="footer-column">
            <h3>Customer Care</h3>
            <a href="<?= url('/contact.php') ?>">Contact Us</a>
            <a href="<?= url('/shop.php') ?>">Shipping &amp; Delivery</a>
            <a href="<?= url('/contact.php') ?>">Returns &amp; Exchange</a>
            <a href="<?= url('/contact.php') ?>">Size Guide</a>
            <a href="<?= url('/contact.php') ?>#faq">FAQs</a>
        </div>

        <div class="footer-column">
            <h3>Information</h3>
            <a href="<?= url('/about.php') ?>">About <?= e($storeName) ?></a>
            <a href="<?= url('/contact.php') ?>">Privacy Policy</a>
            <a href="<?= url('/contact.php') ?>">Terms &amp; Conditions</a>
            <a href="<?= url('/order-confirmation.php') ?>">Track Order</a>
            <a href="<?= url('/contact.php') ?>">Help</a>
        </div>

    </div>

    <div class="footer-bottom">
        <div class="container">
            <p>&copy; <span id="year"></span> <?= e($storeName) ?>. All Rights Reserved.</p>
            <?php if ($credit !== ''): ?><p><?= e($credit) ?></p><?php endif; ?>
        </div>
    </div>
</footer>

<script src="<?= e(asset_url('assets/js/site.js')) ?>"></script>
</body>
</html>