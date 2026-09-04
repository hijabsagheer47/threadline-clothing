<?php
declare(strict_types=1);
require_once __DIR__ . '/includes/bootstrap.php';

$slug = get_string('slug', 200);
$category = $slug !== '' ? get_category_by_slug($slug) : null;

if (!$category) {
    http_response_code(404);
    require __DIR__ . '/404.php';
    exit;
}

$categoryId = (int) $category['id'];

/* ---------------------------------------------------------------------------
   Filters (same pipeline as shop.php, with category pre-selected)
--------------------------------------------------------------------------- */
$q            = get_string('q', 100);
$extraCatIds  = array_values(array_filter(array_map('intval', (array) ($_GET['category'] ?? []))));
$price        = get_string('price', 30);
$fabric       = get_string('fabric', 60);
$color        = get_string('color', 60);
$size         = get_string('size', 40);
$availability = get_string('availability', 20) === 'in_stock';
$sale         = get_string('sale', 10) === '1';
$featured     = get_string('featured', 10) === '1';
$sort         = get_string('sort', 30);
$page         = max(1, (int) ($_GET['page'] ?? 1));
$perPage      = 12;

if (!in_array($sort, ['newest', 'price_low', 'price_high', 'featured', 'best_selling', 'name'], true)) {
    $sort = 'newest';
}

$filters = [
    'q'             => $q,
    'category_id'   => $categoryId,
    'price'         => $price,
    'fabric'        => $fabric,
    'color'         => $color,
    'size'          => $size,
    'availability'  => $availability,
    'sale'          => $sale,
    'featured'      => $featured,
    'sort'          => $sort,
    'page'          => $page,
    'per_page'      => $perPage,
];

$result = get_products($filters);
$facets = product_facets();
$cats   = categories_with_counts();

$qsParts = [];
if ($q !== '')          $qsParts['q'] = $q;
if ($price !== '')      $qsParts['price'] = $price;
if ($fabric !== '')     $qsParts['fabric'] = $fabric;
if ($color !== '')      $qsParts['color'] = $color;
if ($size !== '')       $qsParts['size'] = $size;
if ($availability)      $qsParts['availability'] = 'in_stock';
if ($sale)              $qsParts['sale'] = '1';
if ($featured)          $qsParts['featured'] = '1';
if ($sort !== 'newest') $qsParts['sort'] = $sort;
$baseQuery = http_build_query($qsParts);

if (is_ajax()) {
    header('Content-Type: text/html; charset=utf-8');
    echo render_products_grid($result['items']);
    echo '<input type="hidden" id="ajax-total" value="' . (int) $result['total'] . '">';
    echo '<input type="hidden" id="ajax-pages" value="' . (int) $result['pages'] . '">';
    echo '<input type="hidden" id="ajax-page" value="' . (int) $result['page'] . '">';
    exit;
}

$page_title       = $category['name'];
$meta_description = $category['description'] ?: 'Shop the ' . $category['name'] . ' collection at ' . setting('store_name') . '.';
$canonical        = category_url($category['slug']);
$active_nav       = 'shop.php';

require __DIR__ . '/includes/storefront-header.php';
?>

<!-- HERO -->
<section class="categories-hero">
    <div class="container">
        <div class="categories-hero-content">
            <span class="eyebrow"><?= e(strtoupper(setting('store_name'))) ?> COLLECTION</span>
            <h1><?= e($category['name']) ?></h1>
            <p><?= e($category['description'] ?: 'Discover the ' . $category['name'] . ' collection — thoughtfully designed pieces for every occasion.') ?></p>
        </div>
    </div>
</section>

<!-- PRODUCTS -->
<section class="shop-section section-padding">
    <div class="container">

        <div class="shop-topbar">
            <div>
                <p class="shop-result-count">Showing <strong id="product-count"><?= (int) $result['total'] ?></strong> products</p>
            </div>
            <div class="shop-controls">
                <button class="filter-toggle" type="button">
                    <i class="fa-solid fa-sliders"></i> Filters
                </button>
                <label for="sort-products" class="sort-label">Sort by:</label>
                <select id="sort-products" class="sort-select">
                    <option value="newest"       <?= $sort === 'newest' ? 'selected' : '' ?>>Newest</option>
                    <option value="featured"     <?= $sort === 'featured' ? 'selected' : '' ?>>Featured</option>
                    <option value="best_selling" <?= $sort === 'best_selling' ? 'selected' : '' ?>>Best Selling</option>
                    <option value="price_low"    <?= $sort === 'price_low' ? 'selected' : '' ?>>Price: Low to High</option>
                    <option value="price_high"   <?= $sort === 'price_high' ? 'selected' : '' ?>>Price: High to Low</option>
                    <option value="name"         <?= $sort === 'name' ? 'selected' : '' ?>>Name: A to Z</option>
                </select>
            </div>
        </div>

        <div class="shop-layout">
            <aside class="filter-sidebar" id="filter-sidebar">
                <div class="filter-header">
                    <h2>Filters</h2>
                    <button type="button" class="filter-close" aria-label="Close filters">
                        <i class="fa-solid fa-xmark"></i>
                    </button>
                </div>

                <div class="filter-group">
                    <h3>Category</h3>
                    <?php foreach ($cats as $cat): ?>
                        <label class="filter-option">
                            <input type="checkbox" name="category" value="<?= (int) $cat['id'] ?>"
                                   <?= (int) $cat['id'] === $categoryId || in_array((int) $cat['id'], $extraCatIds, true) ? 'checked' : '' ?>>
                            <span><?= e($cat['name']) ?> <em>(<?= (int) $cat['product_count'] ?>)</em></span>
                        </label>
                    <?php endforeach; ?>
                </div>

                <div class="filter-group">
                    <h3>Price Range</h3>
                    <?php
                    $priceOptions = [
                        ''            => 'All Prices',
                        'under-5000'  => 'Under Rs 5,000',
                        '5000-10000'  => 'Rs 5,000 – Rs 10,000',
                        '10000-15000' => 'Rs 10,000 – Rs 15,000',
                        'over-15000'  => 'Above Rs 15,000',
                    ];
                    foreach ($priceOptions as $val => $label): ?>
                        <label class="filter-option">
                            <input type="radio" name="price" value="<?= e($val) ?>" <?= $price === $val ? 'checked' : '' ?>>
                            <span><?= e($label) ?></span>
                        </label>
                    <?php endforeach; ?>
                </div>

                <?php if ($facets['fabrics']): ?>
                <div class="filter-group">
                    <h3>Fabric</h3>
                    <?php foreach ($facets['fabrics'] as $f): ?>
                        <label class="filter-option">
                            <input type="checkbox" name="fabric" value="<?= e($f) ?>" <?= $fabric === $f ? 'checked' : '' ?>>
                            <span><?= e($f) ?></span>
                        </label>
                    <?php endforeach; ?>
                </div>
                <?php endif; ?>

                <?php if ($facets['colors']): ?>
                <div class="filter-group">
                    <h3>Color</h3>
                    <?php foreach ($facets['colors'] as $c): ?>
                        <label class="filter-option">
                            <input type="checkbox" name="color" value="<?= e($c) ?>" <?= $color === $c ? 'checked' : '' ?>>
                            <span><?= e($c) ?></span>
                        </label>
                    <?php endforeach; ?>
                </div>
                <?php endif; ?>

                <?php if ($facets['sizes']): ?>
                <div class="filter-group">
                    <h3>Size</h3>
                    <?php foreach ($facets['sizes'] as $s): ?>
                        <label class="filter-option">
                            <input type="checkbox" name="size" value="<?= e($s) ?>" <?= $size === $s ? 'checked' : '' ?>>
                            <span><?= e($s) ?></span>
                        </label>
                    <?php endforeach; ?>
                </div>
                <?php endif; ?>

                <div class="filter-group">
                    <h3>Availability</h3>
                    <label class="filter-option">
                        <input type="checkbox" name="availability" value="in_stock" <?= $availability ? 'checked' : '' ?>>
                        <span>In Stock Only</span>
                    </label>
                </div>

                <div class="filter-group">
                    <h3>Special</h3>
                    <label class="filter-option">
                        <input type="checkbox" name="sale" value="1" <?= $sale ? 'checked' : '' ?>>
                        <span>On Sale</span>
                    </label>
                    <label class="filter-option">
                        <input type="checkbox" name="featured" value="1" <?= $featured ? 'checked' : '' ?>>
                        <span>Featured</span>
                    </label>
                </div>

                <button type="button" class="clear-filters">Clear All Filters</button>
            </aside>

            <div class="shop-products">
                <div class="shop-search">
                    <div class="search-box">
                        <i class="fa-solid fa-magnifying-glass"></i>
                        <input type="search" id="shop-search" placeholder="Search in <?= e($category['name']) ?>..."
                               value="<?= e($q) ?>">
                    </div>
                </div>

                <div class="product-grid shop-product-grid" id="shop-product-grid">
                    <?php echo render_products_grid($result['items']); ?>
                </div>

                <div id="shop-pagination">
                    <?= pagination_links($result['page'], $result['pages'], $baseQuery) ?>
                </div>
            </div>
        </div>
    </div>
</section>

<script>
    window.TC_SHOP_STATE = {
        baseQuery: <?= json_encode($baseQuery, JSON_UNESCAPED_SLASHES) ?>,
        categoryId: <?= (int) $categoryId ?>,
        page: <?= (int) $result['page'] ?>,
        pages: <?= (int) $result['pages'] ?>,
        total: <?= (int) $result['total'] ?>
    };
</script>

<?php require __DIR__ . '/includes/storefront-footer.php'; ?>