<?php
declare(strict_types=1);
require_once __DIR__ . '/includes/bootstrap.php';

http_response_code(403);

$page_title       = 'Access Denied';
$meta_description = 'You do not have permission to view this page.';
$active_nav       = '';

require __DIR__ . '/includes/storefront-header.php';
?>

<section class="error-page section-padding">
    <div class="container error-content">
        <span class="error-code">403</span>
        <h1>Access Denied</h1>
        <p>You don't have permission to view this page. If you believe this is a mistake, please contact us.</p>
        <div class="error-actions">
            <a href="<?= url('/index.php') ?>" class="btn btn-primary">Back to Home</a>
            <a href="<?= url('/contact.php') ?>" class="btn btn-outline">Contact Us</a>
        </div>
    </div>
</section>

<?php require __DIR__ . '/includes/storefront-footer.php'; ?>