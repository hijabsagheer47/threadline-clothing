<?php
/**
 * CSRF protection helpers.
 * Every state-changing form must include csrf_field() and every POST handler
 * must call csrf_verify() first.
 */

declare(strict_types=1);

function csrf_token(): string
{
    if (empty($_SESSION['csrf_token'])) {
        $_SESSION['csrf_token'] = bin2hex(random_bytes(32));
    }
    return $_SESSION['csrf_token'];
}

function csrf_field(): string
{
    return '<input type="hidden" name="csrf_token" value="' . e(csrf_token()) . '">';
}

/**
 * Verify a submitted CSRF token. Pass the raw value (usually $_POST['csrf_token']).
 * Returns true when valid.
 */
function csrf_verify(?string $token): bool
{
    $expected = $_SESSION['csrf_token'] ?? '';
    return is_string($token) && $token !== '' && $expected !== '' && hash_equals($expected, $token);
}

/** Abort the request with a 403 when the CSRF token is missing/invalid. */
function csrf_require(?string $token): void
{
    if (!csrf_verify($token)) {
        http_response_code(403);
        if (str_starts_with($_SERVER['REQUEST_URI'] ?? '', '/api/')) {
            header('Content-Type: application/json');
            echo json_encode(['ok' => false, 'message' => 'Invalid security token. Please refresh the page and try again.']);
        } else {
            require __DIR__ . '/../403.php';
        }
        exit;
    }
}