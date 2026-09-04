<?php
/**
 * Storefront header partial.
 * Expected variables (optional): $page_title, $meta_description, $canonical, $active_nav
 */
declare(strict_types=1);

$page_title      = $page_title      ?? '';
$meta_description = $meta_description ?? setting('meta_description', '');
$canonical       = $canonical       ?? url($_SERVER['REQUEST_URI'] ?? '/');
$active_nav      = $active_nav      ?? '';

$storeName  = setting('store_name', 'TayyabaCollective');
$fullTitle  = $page_title !== ''
    ? (str_contains($page_title, $storeName) ? $page_title : $page_title . ' | ' . $storeName)
    : $storeName;

$navCategories = get_categories(true, true);
$cartCount     = cart_count();

$navItem = static fn(string $key, string $label): string =>
    '<a href="' . url('/' . $key) . '"' . ($active_nav === $key ? ' class="active"' : '') . '>' . e($label) . '</a>';

$dropdownHtml = '';
if ($navCategories) {
    $dropdownLinks = '<a href="' . url('/collections.php') . '">All Collections</a>';
    foreach ($navCategories as $cat) {
        $dropdownLinks .= '<a href="' . e(category_url($cat['slug'])) . '">' . e($cat['name']) . '</a>';
    }
    $dropdownHtml = '<div class="nav-dropdown">
        <button type="button" class="nav-dropdown-toggle" aria-expanded="false">
            Collections <i class="fa-solid fa-chevron-down"></i>
        </button>
        <div class="nav-dropdown-menu">' . $dropdownLinks . '</div>
    </div>';
}
?><!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><?= e($fullTitle) ?></title>
    <meta name="description" content="<?= e($meta_description) ?>">
    <meta name="author" content="<?= e($storeName) ?>">
    <link rel="canonical" href="<?= e($canonical) ?>">
    <meta name="csrf-token" content="<?= e(csrf_token()) ?>">

    <!-- Google Fonts -->
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=DM+Sans:wght@400;500;600;700&family=Playfair+Display:wght@500;600;700&display=swap" rel="stylesheet">

    <!-- Font Awesome -->
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.2/css/all.min.css">

    <!-- Main CSS -->
    <link rel="stylesheet" href="<?= e(asset_url('css/style.css')) ?>">
    <link rel="stylesheet" href="<?= e(asset_url('css/premium.css')) ?>">
    <link rel="stylesheet" href="<?= e(asset_url('css/dynamic.css')) ?>">

    <script>
        window.TC_SETTINGS = {
            baseUrl: <?= json_encode(BASE_URL, JSON_UNESCAPED_SLASHES) ?>,
            currencySymbol: <?= json_encode(setting('currency_symbol', 'Rs.'), JSON_UNESCAPED_UNICODE) ?>
        };
    </script>
</head>
<body>

<!-- Announcement bar -->
<?php $announcement = setting('announcement_bar'); ?>
<?php if ($announcement !== ''): ?>
<div class="announcement-bar"><p><?= e($announcement) ?></p></div>
<?php endif; ?>

<!-- Navbar -->
<header class="site-header">
    <div class="container nav-container">

        <a href="<?= url('/index.php') ?>" class="brand-logo">
            <img src="<?= e(asset_url('images/tayyaba-collective-logo.svg')) ?>" alt="<?= e($storeName) ?> logo">
            <?= e($storeName) ?>
        </a>

        <button class="nav-toggle" aria-label="Open navigation menu" type="button">
            <i class="fa-solid fa-bars"></i>
        </button>

        <nav class="site-nav">
            <?= $navItem('index.php', 'Home') ?>
            <?= $navItem('shop.php', 'Shop') ?>
            <?= $dropdownHtml ?>
            <?= $navItem('about.php', 'About') ?>
            <?= $navItem('contact.php', 'Contact') ?>
        </nav>

        <div class="nav-actions">
            <a href="<?= url('/shop.php') ?>" aria-label="Search"><i class="fa-solid fa-magnifying-glass"></i></a>
            <a href="<?= url('/shop.php') ?>" aria-label="Account"><i class="fa-regular fa-user"></i></a>
            <a href="#" aria-label="Wishlist"><i class="fa-regular fa-heart"></i></a>
            <a href="<?= url('/cart.php') ?>" class="cart-link" aria-label="Shopping cart">
                <i class="fa-solid fa-bag-shopping"></i>
                <span class="cart-count"><?= (int) $cartCount ?></span>
            </a>
        </div>

    </div>
</header>

<main>
<?= flash_render() ?>