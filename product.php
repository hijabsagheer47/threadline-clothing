<?php
declare(strict_types=1);
require_once __DIR__ . '/includes/bootstrap.php';

$slug = get_string('slug', 200);
$product = $slug !== '' ? get_product($slug) : null;

if (!$product) {
    http_response_code(404);
    require __DIR__ . '/404.php';
    exit;
}

$images      = get_product_images((int) $product['id']);
$variants    = get_product_variants((int) $product['id']);
$categories  = get_product_categories((int) $product['id']);
$related     = related_products($product, 4);

$primaryImage = image_url($product['primary_image'] ?: ($images[0]['image'] ?? ''));
$outOfStock   = (int) $product['stock_quantity'] < 1;
$onSale       = product_has_sale($product);
$discountPct  = $onSale && (float) $product['price'] > 0
    ? (int) round(((float) $product['price'] - (float) $product['sale_price']) / (float) $product['price'] * 100)
    : 0;

$sizes = array_values(array_filter(array_map('trim', explode(',', (string) $product['size']))));
$colors = array_values(array_filter(array_map('trim', explode(',', (string) $product['color']))));

$page_title     = $product['name'];
$meta_description = mb_substr(strip_tags((string) $product['short_description']), 0, 155);
$canonical      = product_url($product['slug']);
$active_nav     = 'shop.php';

require __DIR__ . '/includes/storefront-header.php';
?>

<!-- BREADCRUMB -->
<section class="breadcrumb-section">
    <div class="container">
        <div class="breadcrumb">
            <a href="<?= url('/index.php') ?>">Home</a>
            <span>/</span>
            <a href="<?= url('/shop.php') ?>">Shop</a>
            <?php if ($categories): ?>
                <span>/</span>
                <a href="<?= e(category_url($categories[0]['slug'])) ?>"><?= e($categories[0]['name']) ?></a>
            <?php endif; ?>
            <span>/</span>
            <span><?= e($product['name']) ?></span>
        </div>
    </div>
</section>

<!-- PRODUCT DETAILS -->
<section class="product-details-section">
    <div class="container product-details-wrapper">

        <!-- LEFT - GALLERY -->
        <div class="product-gallery">
            <div class="product-thumbnails">
                <?php foreach ($images as $i => $img): ?>
                    <button class="product-thumb<?= $i === 0 ? ' active' : '' ?>" type="button"
                            data-image="<?= e(image_url($img['image'] ?? '')) ?>">
                        <img src="<?= e(image_url($img['image'] ?? '')) ?>" alt="<?= e($product['name']) ?> view <?= (int) ($i + 1) ?>" loading="lazy">
                    </button>
                <?php endforeach; ?>
            </div>

            <div class="product-main-image" id="productImageContainer">
                <img id="mainProductImage" src="<?= e($primaryImage) ?>" alt="<?= e($product['name']) ?>">
                <div class="zoom-hint"><i class="fa-solid fa-magnifying-glass-plus"></i> Hover to zoom</div>
            </div>
        </div>

        <!-- RIGHT - INFORMATION -->
        <div class="product-information">

            <?php if ($categories): ?>
                <span class="product-category"><?= e($categories[0]['name']) ?></span>
            <?php endif; ?>

            <h1 class="product-title"><?= e($product['name']) ?></h1>

            <div class="product-rating">
                <div class="stars">
                    <i class="fa-solid fa-star"></i><i class="fa-solid fa-star"></i><i class="fa-solid fa-star"></i><i class="fa-solid fa-star"></i><i class="fa-solid fa-star"></i>
                </div>
                <span>Premium <?= e($categories[0]['name'] ?? setting('store_name')) ?> piece</span>
            </div>

            <div class="product-price">
                <span class="current-price"><?= money(effective_price($product)) ?></span>
                <?php if ($onSale): ?>
                    <span class="old-price"><?= money((float) $product['price']) ?></span>
                    <span class="discount"><?= (int) $discountPct ?>% OFF</span>
                <?php endif; ?>
            </div>

            <p class="product-short-description">
                <?= e($product['short_description'] ?: 'A beautifully crafted contemporary outfit designed with delicate detailing and a comfortable silhouette.') ?>
            </p>

            <?php if ($product['sku'] !== ''): ?>
            <p class="product-sku">SKU: <strong><?= e($product['sku']) ?></strong></p>
            <?php endif; ?>

            <div class="product-divider"></div>

            <!-- Variants -->
            <?php if ($variants): ?>
                <div class="product-option">
                    <div class="option-heading"><strong>Available Options</strong></div>
                    <select class="variant-select" id="variantSelect" data-product-id="<?= (int) $product['id'] ?>">
                        <?php foreach ($variants as $v): ?>
                            <option value="<?= (int) $v['id'] ?>"
                                    data-price="<?= effective_price($product, (float) $v['price_adjustment']) ?>"
                                    data-stock="<?= (int) $v['stock_quantity'] ?>"
                                    <?= (int) $v['stock_quantity'] < 1 ? 'disabled' : '' ?>>
                                <?= e(trim($v['variant_name'] . ' — ' . $v['variant_value'], ' —')) ?>
                                <?= (float) $v['price_adjustment'] != 0 ? ' (+' . money((float) $v['price_adjustment']) . ')' : '' ?>
                                <?= (int) $v['stock_quantity'] < 1 ? ' (Sold out)' : '' ?>
                            </option>
                        <?php endforeach; ?>
                    </select>
                </div>
            <?php endif; ?>

            <!-- Color -->
            <?php if ($colors): ?>
                <div class="product-option">
                    <div class="option-heading"><strong>Color</strong> <span id="selectedColor"><?= e($colors[0]) ?></span></div>
                    <div class="color-options">
                        <?php foreach ($colors as $ci => $col): ?>
                            <button type="button"
                                    class="color-option<?= $ci === 0 ? ' active' : '' ?> color-swatch"
                                    data-color="<?= e($col) ?>"
                                    style="background-color: <?= e(strtolower($col) === 'black' ? '#1a1a1a' : (strtolower($col) === 'white' ? '#f4f4f4' : '#b98d6f')) ?>"
                                    aria-label="<?= e($col) ?>"></button>
                        <?php endforeach; ?>
                    </div>
                </div>
            <?php endif; ?>

            <!-- Size -->
            <?php if ($sizes): ?>
                <div class="product-option">
                    <div class="option-heading"><strong>Size</strong> <a href="#size-guide">Size Guide</a></div>
                    <div class="size-options">
                        <?php foreach ($sizes as $si => $sz): ?>
                            <button type="button" class="size-option<?= $si === 0 ? ' active' : '' ?>"><?= e($sz) ?></button>
                        <?php endforeach; ?>
                    </div>
                </div>
            <?php endif; ?>

            <!-- Quantity -->
            <div class="product-option">
                <div class="option-heading"><strong>Quantity</strong></div>
                <div class="quantity-selector">
                    <button type="button" class="qty-btn" data-qty="-1" aria-label="Decrease quantity">−</button>
                    <span id="quantity">1</span>
                    <button type="button" class="qty-btn" data-qty="1" aria-label="Increase quantity">+</button>
                </div>
            </div>

            <!-- Stock status -->
            <p class="stock-status <?= $outOfStock ? 'out' : 'in' ?>">
                <i class="fa-solid <?= $outOfStock ? 'fa-circle-xmark' : 'fa-circle-check' ?>"></i>
                <?= $outOfStock ? 'Currently out of stock' : 'In stock — ' . (int) $product['stock_quantity'] . ' available' ?>
            </p>

            <!-- Add To Cart -->
            <button type="button" class="btn btn-primary product-add-cart"
                    data-product-id="<?= (int) $product['id'] ?>"
                    data-product-name="<?= e($product['name']) ?>"
                    <?= $outOfStock ? 'disabled' : '' ?>>
                <i class="fa-solid fa-bag-shopping"></i> ADD TO CART
            </button>

            <!-- Buy Now -->
            <button type="button" class="btn btn-outline product-buy-now"
                    data-product-id="<?= (int) $product['id'] ?>"
                    <?= $outOfStock ? 'disabled' : '' ?>>
                BUY NOW
            </button>

            <!-- Product Benefits -->
            <div class="product-benefits">
                <div class="benefit-item">
                    <i class="fa-solid fa-truck"></i>
                    <div><strong>Free Shipping</strong><span>On orders above <?= money(setting('free_shipping_threshold', '8000')) ?></span></div>
                </div>
                <div class="benefit-item">
                    <i class="fa-solid fa-rotate-left"></i>
                    <div><strong>Easy Returns</strong><span>7 days return &amp; exchange</span></div>
                </div>
                <div class="benefit-item">
                    <i class="fa-solid fa-shield-halved"></i>
                    <div><strong>Secure Payment</strong><span>Safe &amp; secure checkout</span></div>
                </div>
            </div>
        </div>
    </div>
</section>

<!-- PRODUCT INFORMATION TABS -->
<section class="product-information-section">
    <div class="container">
        <div class="product-tabs">
            <button class="product-tab active" type="button" data-tab="description">Description</button>
            <button class="product-tab" type="button" data-tab="details">Product Details</button>
            <button class="product-tab" type="button" data-tab="shipping">Shipping &amp; Returns</button>
            <button class="product-tab" type="button" data-tab="reviews">Reviews</button>
        </div>

        <div class="product-tab-content active" id="tab-description">
            <h3>About this piece</h3>
            <p><?= nl2br(e($product['description'] ?: 'No additional description available.')) ?></p>
        </div>

        <div class="product-tab-content" id="tab-details">
            <h3>Product Details</h3>
            <ul class="details-list">
                <?php if ($product['sku'] !== ''): ?><li><strong>SKU:</strong> <?= e($product['sku']) ?></li><?php endif; ?>
                <?php if ($product['product_type'] !== ''): ?><li><strong>Type:</strong> <?= e($product['product_type']) ?></li><?php endif; ?>
                <?php if ($product['fabric'] !== ''): ?><li><strong>Fabric:</strong> <?= e($product['fabric']) ?></li><?php endif; ?>
                <?php if ($product['color'] !== ''): ?><li><strong>Color:</strong> <?= e($product['color']) ?></li><?php endif; ?>
                <?php if ($product['size'] !== ''): ?><li><strong>Size:</strong> <?= e($product['size']) ?></li><?php endif; ?>
                <?php if ($categories): ?><li><strong>Category:</strong> <?= e(implode(', ', array_column($categories, 'name'))) ?></li><?php endif; ?>
                <li><strong>Availability:</strong> <?= $outOfStock ? 'Out of stock' : 'In stock (' . (int) $product['stock_quantity'] . ' pieces)' ?></li>
            </ul>
        </div>

        <div class="product-tab-content" id="tab-shipping">
            <h3>Shipping &amp; Returns</h3>
            <p>Orders are delivered within 3–5 working days across Pakistan. Delivery is free on orders above <?= money(setting('free_shipping_threshold', '8000')) ?>; otherwise a flat shipping fee of <?= money(setting('shipping_fee', '250')) ?> applies. We offer a 7-day return and exchange policy on unworn items.</p>
        </div>

        <div class="product-tab-content" id="tab-reviews">
            <h3>Customer Reviews</h3>
            <p>Review functionality is coming soon. In the meantime, feel free to <a href="<?= url('/contact.php') ?>">contact us</a> with any questions about this piece.</p>
        </div>
    </div>
</section>

<!-- RELATED PRODUCTS -->
<?php if ($related): ?>
<section class="section-padding related-products">
    <div class="container">
        <div class="section-top">
            <div class="section-heading left">
                <p class="section-label">YOU MAY ALSO LIKE</p>
                <h2>Complete The Look</h2>
            </div>
            <a href="<?= url('/shop.php') ?>" class="text-link">View All <i class="fa-solid fa-arrow-right"></i></a>
        </div>
        <div class="product-grid">
            <?php foreach ($related as $rel) echo render_product_card($rel); ?>
        </div>
    </div>
</section>
<?php endif; ?>

<script>
    window.TC_PRODUCT = {
        id: <?= (int) $product['id'] ?>,
        name: <?= json_encode($product['name'], JSON_UNESCAPED_UNICODE) ?>,
        image: <?= json_encode(image_url($product['primary_image'] ?? ''), JSON_UNESCAPED_SLASHES) ?>,
        price: <?= effective_price($product) ?>,
        inStock: <?= $outOfStock ? 'false' : 'true' ?>,
        maxStock: <?= (int) $product['stock_quantity'] ?>
    };
</script>

<?php require __DIR__ . '/includes/storefront-footer.php'; ?>