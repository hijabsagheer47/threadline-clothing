<?php
declare(strict_types=1);
require_once __DIR__ . '/../includes/bootstrap.php';

header('Content-Type: application/json; charset=utf-8');

$productId = (int) ($_GET['id'] ?? 0);
if ($productId < 1) {
    http_response_code(422);
    echo json_encode(['ok' => false, 'error' => 'Invalid product.']);
    exit;
}

$stmt = db()->prepare(
    'SELECT p.*, pi.image AS primary_image
     FROM products p
     LEFT JOIN product_images pi ON pi.product_id = p.id AND pi.is_primary = 1
     WHERE p.id = ? AND p.status = 1 LIMIT 1'
);
$stmt->execute([$productId]);
$product = $stmt->fetch();

if (!$product) {
    http_response_code(404);
    echo json_encode(['ok' => false, 'error' => 'Sorry, this product is no longer available.']);
    exit;
}

$images   = get_product_images($productId);
$variants = get_product_variants($productId);
$summary  = tc_review_summary($productId);

$outOfStock = (int) $product['stock_quantity'] < 1;
$sizes  = array_values(array_filter(array_map('trim', explode(',', (string) $product['size']))));
$colors = array_values(array_filter(array_map('trim', explode(',', (string) $product['color']))));

$img2 = isset($images[1]['image']) ? image_url($images[1]['image']) : '';

ob_start();
?>
<div class="qv-layout">
    <div class="qv-gallery">
        <img class="qv-main" src="<?= e(image_url($product['primary_image'] ?: ($images[0]['image'] ?? ''))) ?>" alt="<?= e($product['name']) ?>">
        <?php if ($img2 !== ''): ?>
            <img class="qv-thumb" src="<?= e($img2) ?>" alt="" loading="lazy">
        <?php endif; ?>
    </div>
    <div class="qv-info">
        <span class="qv-eyebrow"><?= e($product['product_type'] ?: 'Ready to wear') ?></span>
        <h2 class="qv-title"><?= e($product['name']) ?></h2>
        <?php if ($summary['count'] > 0): ?>
            <div class="qv-rating">
                <span class="stars">
                    <?php for ($i = 1; $i <= 5; $i++): ?>
                        <i class="fa-<?= $i <= (int) round($summary['avg']) ? 'solid' : 'regular' ?> fa-star"></i>
                    <?php endfor; ?>
                </span>
                <span><?= $summary['avg'] ?> (<?= (int) $summary['count'] ?> review<?= (int) $summary['count'] === 1 ? '' : 's' ?>)</span>
            </div>
        <?php endif; ?>
        <div class="qv-price">
            <span class="current-price"><?= money(effective_price($product)) ?></span>
            <?php if (product_has_sale($product)): ?>
                <span class="old-price"><?= money((float) $product['price']) ?></span>
            <?php endif; ?>
        </div>
        <p class="qv-desc"><?= e($product['short_description'] ?: mb_substr(strip_tags((string) $product['description']), 0, 180)) ?></p>

        <?php if ($colors): ?>
            <div class="qv-option"><strong>Color:</strong> <span><?= e(implode(', ', $colors)) ?></span></div>
        <?php endif; ?>
        <?php if ($sizes): ?>
            <div class="qv-option"><strong>Size:</strong> <span><?= e(implode(', ', $sizes)) ?></span></div>
        <?php endif; ?>

        <?php if ($variants): ?>
            <div class="qv-option">
                <strong>Options:</strong>
                <select class="qv-variant" data-product-id="<?= (int) $product['id'] ?>">
                    <?php foreach ($variants as $v): ?>
                        <option value="<?= (int) $v['id'] ?>" data-price="<?= effective_price($product, (float) $v['price_adjustment']) ?>"
                                <?= (int) $v['stock_quantity'] < 1 ? 'disabled' : '' ?>>
                            <?= e(trim($v['variant_name'] . ' — ' . $v['variant_value'], ' —')) ?>
                            <?= (int) $v['stock_quantity'] < 1 ? ' (Sold out)' : '' ?>
                        </option>
                    <?php endforeach; ?>
                </select>
            </div>
        <?php endif; ?>

        <div class="qv-stock <?= $outOfStock ? 'out' : 'in' ?>">
            <i class="fa-solid <?= $outOfStock ? 'fa-circle-xmark' : 'fa-circle-check' ?>"></i>
            <?= $outOfStock ? 'Currently out of stock' : 'In stock — ' . (int) $product['stock_quantity'] . ' available' ?>
        </div>

        <div class="qv-actions">
            <div class="quantity-selector qv-qty">
                <button type="button" class="qty-btn" data-qty="-1" aria-label="Decrease quantity">−</button>
                <span class="qv-qty-value">1</span>
                <button type="button" class="qty-btn" data-qty="1" aria-label="Increase quantity">+</button>
            </div>
            <button type="button" class="btn btn-primary qv-add" data-product-id="<?= (int) $product['id'] ?>" <?= $outOfStock ? 'disabled' : '' ?>>
                <i class="fa-solid fa-bag-shopping"></i> ADD TO BAG
            </button>
        </div>

        <a href="<?= e(product_url($product['slug'])) ?>" class="qv-details-link">View Full Details <i class="fa-solid fa-arrow-right"></i></a>
    </div>
</div>
<?php
$html = ob_get_clean();

echo json_encode(['ok' => true, 'html' => $html]);