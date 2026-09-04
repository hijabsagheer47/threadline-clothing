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

$email = post('email', 150);

if (!valid_email($email)) {
    http_response_code(422);
    echo json_encode(['ok' => false, 'error' => 'Please enter a valid email address.']);
    exit;
}

try {
    $db = db();

    /* Already subscribed? */
    $stmt = $db->prepare('SELECT id, status FROM subscribers WHERE email = ? LIMIT 1');
    $stmt->execute([$email]);
    $existing = $stmt->fetch();

    if ($existing) {
        if ((int) $existing['status'] !== 1) {
            $db->prepare('UPDATE subscribers SET status = 1 WHERE id = ?')->execute([(int) $existing['id']]);
        }
        echo json_encode(['ok' => true, 'message' => 'You are already subscribed. Thank you!']);
        exit;
    }

    $stmt = $db->prepare('INSERT INTO subscribers (email, status) VALUES (?, 1)');
    $stmt->execute([$email]);

    echo json_encode(['ok' => true, 'message' => 'Thank you for subscribing!']);
} catch (Throwable $e) {
    error_log('[newsletter] ' . $e->getMessage());
    http_response_code(500);
    echo json_encode(['ok' => false, 'error' => 'Something went wrong. Please try again.']);
}