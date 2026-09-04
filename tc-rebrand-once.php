<?php
/**
 * ONE-OFF migration: replace the old brand name inside seeded product copy.
 * Token-gated and deleted immediately after use.
 */
declare(strict_types=1);
require_once __DIR__ . '/includes/bootstrap.php';
header('Content-Type: text/plain; charset=utf-8');

if (($_GET['token'] ?? '') !== '4f43ab87bda41d9bd19c59a6') {
    http_response_code(404);
    exit;
}

$db  = db();
$old = 'TayyabaCollective';
$new = setting('store_name');

$before = (int) $db->query(
    "SELECT COUNT(*) FROM products
     WHERE description LIKE '%{$old}%' OR short_description LIKE '%{$old}%'"
)->fetchColumn();
echo "products containing '{$old}' before: {$before}\n";

$stmt = $db->prepare(
    'UPDATE products
        SET description       = REPLACE(description, ?, ?),
            short_description = REPLACE(short_description, ?, ?)
      WHERE description LIKE ? OR short_description LIKE ?'
);
$like = '%' . $old . '%';
$stmt->execute([$old, $new, $old, $new, $like, $like]);
echo "rows updated: " . $stmt->rowCount() . "\n";

// Categories carry the same seeded phrasing.
$catStmt = $db->prepare('UPDATE categories SET description = REPLACE(description, ?, ?) WHERE description LIKE ?');
$catStmt->execute([$old, $new, $like]);
echo "categories updated: " . $catStmt->rowCount() . "\n";

$after = (int) $db->query(
    "SELECT COUNT(*) FROM products
     WHERE description LIKE '%{$old}%' OR short_description LIKE '%{$old}%'"
)->fetchColumn();
echo "products containing '{$old}' after: {$after}\n";
echo "new name used: {$new}\n";
