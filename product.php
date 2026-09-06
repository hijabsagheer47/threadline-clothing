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

$images        = get_product_images((int) $product['id']);
$variants      = get_product_variants((int) $product['id']);
$categories    = get_product_categories((int) $product['id']);
$related       = related_products($product, 4);
$reviewSummary = tc_review_summary((int) $product['id']);
$reviews       = tc_product_reviews((int) $product['id'], 10);
$wished        = in_array((int) $product['id'], wishlist_ids(), true);

// Review submission (stored pending until an admin approves it).
if ($_SERVER['REQUEST_METHOD'] === 'POST' && ($_POST['review_submit'] ?? '') === '1') {
    csrf_require($_POST['csrf_token'] ?? null);
    $result = tc_submit_review([
        'product_id' => (int) $product['id'],
        'name'       => post('review_name', 150),
        'email'      => post('review_email', 190),
        'rating'     => post_int('review_rating'),
        'title'      => post('review_title', 190),
        'body'       => post_text('review_body', 2000),
    ]);
    flash_set($result['ok'] ? 'success' : 'error', $result['ok'] ? $result['message'] : $result['error']);
    redirect(url('/product.php?slug=' . urlencode($product['slug'])) . '#tab-reviews');
}

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
                    <?php if ($reviewSummary['count'] > 0): ?>
                        <?php for ($i = 1; $i <= 5; $i++): ?>
                            <i class="fa-<?= $i <= (int) round($reviewSummary['avg']) ? 'solid' : 'regular' ?> fa-star"></i>
                        <?php endfor; ?>
                    <?php else: ?>
                        <?php for ($i = 1; $i <= 5; $i++): ?><i class="fa-solid fa-star"></i><?php endfor; ?>
                    <?php endif; ?>
                </div>
                <span>
                    <?php if ($reviewSummary['count'] > 0): ?>
                        <?= $reviewSummary['avg'] ?> (<?= (int) $reviewSummary['count'] ?> review<?= (int) $reviewSummary['count'] === 1 ? '' : 's' ?>)
                    <?php else: ?>
                        Premium <?= e($categories[0]['name'] ?? setting('store_name')) ?> piece
                    <?php endif; ?>
                </span>
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

            <!-- Wishlist -->
            <button type="button" class="btn btn-outline product-wishlist<?= $wished ? ' active' : '' ?>"
                    data-product-id="<?= (int) $product['id'] ?>"
                    data-added="<?= $wished ? '1' : '0' ?>"
                    aria-pressed="<?= $wished ? 'true' : 'false' ?>">
                <i class="fa-<?= $wished ? 'solid' : 'regular' ?> fa-heart"></i>
                <span><?= $wished ? 'In Wishlist' : 'Wishlist' ?></span>
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

            <?php if (!tc_table_exists('reviews')): ?>
                <p>Reviews are coming soon. In the meantime, feel free to <a href="<?= url('/contact.php') ?>">contact us</a> with any questions about this piece.</p>
            <?php else: ?>

            <div class="reviews-summary">
                <div class="reviews-score">
                    <strong><?= $reviewSummary['count'] > 0 ? $reviewSummary['avg'] : '—' ?></strong>
                    <div class="stars">
                        <?php for ($i = 1; $i <= 5; $i++): ?>
                            <i class="fa-<?= $i <= (int) round($reviewSummary['avg']) ? 'solid' : 'regular' ?> fa-star"></i>
                        <?php endfor; ?>
                    </div>
                    <span><?= (int) $reviewSummary['count'] ?> review<?= (int) $reviewSummary['count'] === 1 ? '' : 's' ?></span>
                </div>
                <div class="reviews-bars">
                    <?php foreach ([5, 4, 3, 2, 1] as $star): ?>
                        <?php
                        $n = $reviewSummary['breakdown'][$star] ?? 0;
                        $pct = $reviewSummary['count'] > 0 ? (int) round($n / $reviewSummary['count'] * 100) : 0;
                        ?>
                        <div class="review-bar">
                            <span><?= $star ?> <i class="fa-solid fa-star"></i></span>
                            <div class="review-bar-track"><span style="width: <?= $pct ?>%"></span></div>
                            <em><?= $n ?></em>
                        </div>
                    <?php endforeach; ?>
                </div>
            </div>

            <?php if ($reviews): ?>
                <div class="reviews-list">
                    <?php foreach ($reviews as $review): ?>
                        <article class="review-entry">
                            <div class="review-entry-head">
                                <div class="review-entry-avatar"><?= e(mb_strtoupper(mb_substr($review['name'], 0, 1))) ?></div>
                                <div>
                                    <strong><?= e($review['name']) ?></strong>
                                    <?php if ((int) $review['is_verified_purchase'] === 1): ?>
                                        <span class="verified-badge"><i class="fa-solid fa-circle-check"></i> Verified Purchase</span>
                                    <?php endif; ?>
                                    <div class="stars">
                                        <?php for ($i = 1; $i <= 5; $i++): ?>
                                            <i class="fa-<?= $i <= (int) $review['rating'] ? 'solid' : 'regular' ?> fa-star"></i>
                                        <?php endfor; ?>
                                    </div>
                                </div>
                                <time><?= e(format_date($review['created_at'])) ?></time>
                            </div>
                            <?php if ($review['title'] !== ''): ?><h4><?= e($review['title']) ?></h4><?php endif; ?>
                            <p><?= nl2br(e($review['body'])) ?></p>
                        </article>
                    <?php endforeach; ?>
                </div>
            <?php else: ?>
                <p class="reviews-none">No reviews yet — be the first to review this piece.</p>
            <?php endif; ?>

            <form method="post" action="<?= e(url('/product.php?slug=' . urlencode($product['slug']))) ?>#tab-reviews" class="review-form" id="reviewForm">
                <?= csrf_field() ?>
                <h4>Write a Review</h4>
                <input type="hidden" name="review_submit" value="1">
                <input type="hidden" name="product_id" value="<?= (int) $product['id'] ?>">
                <div class="form-row">
                    <div class="form-group">
                        <label for="review_name">Name <span class="required">*</span></label>
                        <input type="text" id="review_name" name="review_name" required>
                    </div>
                    <div class="form-group">
                        <label for="review_email">Email <span class="required">*</span></label>
                        <input type="email" id="review_email" name="review_email" required>
                    </div>
                </div>
                <div class="form-row">
                    <div class="form-group">
                        <label for="review_rating">Rating <span class="required">*</span></label>
                        <select id="review_rating" name="review_rating" required>
                            <option value="">Select…</option>
                            <?php for ($i = 5; $i >= 1; $i--): ?>
                                <option value="<?= $i ?>"><?= $i ?> star<?= $i === 1 ? '' : 's' ?></option>
                            <?php endfor; ?>
                        </select>
                    </div>
                    <div class="form-group">
                        <label for="review_title">Title</label>
                        <input type="text" id="review_title" name="review_title" maxlength="190">
                    </div>
                </div>
                <div class="form-group">
                    <label for="review_body">Your Review <span class="required">*</span></label>
                    <textarea id="review_body" name="review_body" rows="4" required></textarea>
                </div>
                <button type="submit" class="btn btn-primary">Submit Review</button>
            </form>

            <?php endif; ?>
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