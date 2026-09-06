<?php
declare(strict_types=1);
require_once __DIR__ . '/includes/bootstrap.php';

$items  = wishlist_items();
$wished = wishlist_ids();

$page_title       = 'My Wishlist';
$meta_description = 'Your saved favourites at ' . setting('store_name') . '.';
$active_nav       = 'wishlist.php';

require __DIR__ . '/includes/storefront-header.php';
?>

<section class="cart-hero">
    <div class="container">
        <span class="eyebrow">MY FAVORITES</span>
        <h1>Wishlist</h1>
        <p>Save your favourite pieces here and come back anytime.</p>
    </div>
</section>

<main class="cart-section">
    <div class="container">

        <?php if (!$items): ?>
            <div class="empty-cart">
                <div class="empty-cart-icon"><i class="fa-regular fa-heart"></i></div>
                <h2>Your wishlist is waiting for something beautiful</h2>
                <p>Tap the heart on any product to save it here.</p>
                <a href="<?= url('/shop.php') ?>">EXPLORE COLLECTION</a>
            </div>
        <?php else: ?>
            <div class="product-grid wishlist-grid">
                <?php foreach ($items as $item): ?>
                    <article class="product-card" data-product-id="<?= (int) $item['id'] ?>">
                        <a class="product-card-link" href="<?= e(product_url($item['slug'])) ?>">
                            <div class="product-thumb">
                                <div class="product-badges"></div>
                                <div class="product-actions">
                                    <button type="button" class="wishlist-toggle active" data-product-id="<?= (int) $item['id'] ?>"
                                            data-added="1" aria-label="Remove from wishlist" aria-pressed="true" title="Wishlist">
                                        <i class="fa-solid fa-heart"></i>
                                    </button>
                                </div>
                                <img src="<?= e($item['image']) ?>" alt="<?= e($item['name']) ?>" loading="lazy">
                                <?php if (!$item['in_stock']): ?>
                                    <span class="product-tag out-of-stock">Out of Stock</span>
                                <?php endif; ?>
                            </div>
                            <div class="product-info">
                                <div class="p-name"><?= e($item['name']) ?></div>
                                <div class="p-price"><?= money($item['price']) ?></div>
                            </div>
                        </a>
                        <button type="button" class="mini-cart-btn"
                                data-product-id="<?= (int) $item['id'] ?>"
                                data-product-name="<?= e($item['name']) ?>"
                                data-product-price="<?= $item['price'] ?>"
                                data-product-image="<?= e($item['image']) ?>"
                                <?= $item['in_stock'] ? '' : 'disabled' ?>>
                            <?= $item['in_stock'] ? 'Add to Cart' : 'Sold Out' ?>
                        </button>
                    </article>
                <?php endforeach; ?>
            </div>
        <?php endif; ?>

    </div>
</main>

<?php require __DIR__ . '/includes/storefront-footer.php'; ?>