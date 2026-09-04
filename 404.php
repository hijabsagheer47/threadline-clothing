<?php
declare(strict_types=1);
require_once __DIR__ . '/includes/bootstrap.php';

http_response_code(404);

$page_title       = 'Page Not Found';
$meta_description = 'The page you are looking for could not be found.';
$active_nav       = '';

require __DIR__ . '/includes/storefront-header.php';
?>

<section class="error-page section-padding">
    <div class="container error-content">
        <span class="error-code">404</span>
        <h1>Page Not Found</h1>
        <p>The page you are looking for doesn't exist or has been moved. Let's get you back to the good stuff.</p>
        <div class="error-actions">
            <a href="<?= url('/index.php') ?>" class="btn btn-primary">Back to Home</a>
            <a href="<?= url('/shop.php') ?>" class="btn btn-outline">Shop Collection</a>
        </div>
    </div>
</section>

<?php require __DIR__ . '/includes/storefront-footer.php'; ?>