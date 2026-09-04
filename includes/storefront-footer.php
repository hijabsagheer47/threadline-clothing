<?php
/**
 * Storefront footer partial.
 */
declare(strict_types=1);

$storeName  = setting('store_name');
$footerCats = get_categories(true); // first five, no nav filter
$shopCats   = array_slice($footerCats, 0, 5);
$credit     = setting('footer_credit', '');
$waUrl      = whatsapp_url('Hello! I would like to know more about your collection.');
$waNumber   = setting('whatsapp_number', '+92 334 232 2324');
$freeOver   = (float) setting('free_shipping_threshold', '8000');
?>
</main>

<!-- Trust bar -->
<section class="trust-bar">
    <div class="container">
        <div class="trust-grid">
            <div class="trust-item">
                <i class="fa-solid fa-hand-holding-dollar"></i>
                <div>
                    <h4>Cash on Delivery</h4>
                    <p>Pay when your parcel arrives</p>
                </div>
            </div>
            <div class="trust-item">
                <i class="fa-solid fa-truck-fast"></i>
                <div>
                    <h4>Free Delivery</h4>
                    <p>On orders above <?= e(money($freeOver)) ?></p>
                </div>
            </div>
            <div class="trust-item">
                <i class="fa-solid fa-rotate-left"></i>
                <div>
                    <h4>Easy Exchange</h4>
                    <p>7-day hassle-free exchange</p>
                </div>
            </div>
            <div class="trust-item">
                <i class="fa-brands fa-whatsapp"></i>
                <div>
                    <h4>Order on WhatsApp</h4>
                    <p><?= e($waNumber) ?></p>
                </div>
            </div>
        </div>
    </div>
</section>

<!-- Footer -->
<footer class="site-footer">
    <div class="container footer-grid">

        <div class="footer-brand">
            <a href="<?= url('/index.php') ?>" class="footer-logo"><?= e($storeName) ?></a>
            <p>Thoughtfully designed clothing for every version of you.</p>

            <div class="social-links">
                <a class="s-instagram" href="<?= e(setting('instagram_url', '#')) ?>" aria-label="Instagram on <?= e($storeName) ?>" target="_blank" rel="noopener noreferrer"><i class="fa-brands fa-instagram"></i></a>
                <a class="s-facebook" href="<?= e(setting('facebook_url', '#')) ?>" aria-label="Facebook page" target="_blank" rel="noopener noreferrer"><i class="fa-brands fa-facebook-f"></i></a>
                <a class="s-linkedin" href="<?= e(setting('linkedin_url', '#')) ?>" aria-label="LinkedIn profile" target="_blank" rel="noopener noreferrer"><i class="fa-brands fa-linkedin-in"></i></a>
                <?php if ($waUrl !== ''): ?>
                <a class="s-whatsapp" href="<?= e($waUrl) ?>" aria-label="Chat on WhatsApp" target="_blank" rel="noopener noreferrer"><i class="fa-brands fa-whatsapp"></i></a>
                <?php endif; ?>
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

<?php if ($waUrl !== ''): ?>
<a class="wa-float" href="<?= e($waUrl) ?>" target="_blank" rel="noopener noreferrer"
   aria-label="Chat with us on WhatsApp">
    <i class="fa-brands fa-whatsapp" aria-hidden="true"></i>
    <span>Chat with us</span>
</a>
<?php endif; ?>

<script src="<?= e(asset_url('assets/js/site.js')) ?>"></script>
<script src="<?= e(asset_url('assets/js/premium.js')) ?>"></script>
</body>
</html>