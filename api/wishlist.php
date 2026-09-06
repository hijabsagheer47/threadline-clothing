<?php
declare(strict_types=1);
require_once __DIR__ . '/../includes/bootstrap.php';

header('Content-Type: application/json; charset=utf-8');

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['ok' => false, 'error' => 'Method not allowed.']);
    exit;
}

csrf_require($_POST['csrf_token'] ?? null);

$action = post('action', 20);

try {
    switch ($action) {
        case 'toggle':
            $productId = post_int('product_id');
            if ($productId < 1) {
                http_response_code(422);
                echo json_encode(['ok' => false, 'error' => 'Invalid product.']);
                exit;
            }
            $result = wishlist_toggle($productId);
            echo json_encode([
                'ok'      => true,
                'added'   => $result['added'],
                'count'   => $result['count'],
                'message' => $result['added'] ? 'Added to wishlist.' : 'Removed from wishlist.',
            ]);
            break;

        case 'add':
            $productId = post_int('product_id');
            if ($productId < 1 || in_array($productId, wishlist_ids(), true)) {
                http_response_code(422);
                echo json_encode(['ok' => false, 'error' => 'Invalid product.']);
                exit;
            }
            wishlist_toggle($productId);
            echo json_encode(['ok' => true, 'added' => true, 'count' => wishlist_count()]);
            break;

        case 'remove':
            $productId = post_int('product_id');
            if ($productId < 1) {
                http_response_code(422);
                echo json_encode(['ok' => false, 'error' => 'Invalid product.']);
                exit;
            }
            if (in_array($productId, wishlist_ids(), true)) {
                wishlist_toggle($productId);
            }
            echo json_encode(['ok' => true, 'added' => false, 'count' => wishlist_count()]);
            break;

        case 'count':
            echo json_encode(['ok' => true, 'count' => wishlist_count()]);
            break;

        default:
            http_response_code(422);
            echo json_encode(['ok' => false, 'error' => 'Unknown action.']);
    }
} catch (Throwable $e) {
    error_log('[wishlist-api] ' . $e->getMessage());
    http_response_code(500);
    echo json_encode(['ok' => false, 'error' => 'Something went wrong.']);
}