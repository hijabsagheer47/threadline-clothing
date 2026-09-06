<?php
declare(strict_types=1);
require_once __DIR__ . '/../includes/bootstrap.php';

header('Content-Type: application/json; charset=utf-8');

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    http_response_code(405);
    echo json_encode(['ok' => false, 'error' => 'Method not allowed.']);
    exit;
}

$items  = cart_items();
$totals = cart_totals();

ob_start();
require __DIR__ . '/../includes/cart-drawer.php';
$html = ob_get_clean();

echo json_encode([
    'ok'      => true,
    'html'    => $html,
    'count'   => $totals['piece_count'],
    'total'   => money($totals['total']),
]);