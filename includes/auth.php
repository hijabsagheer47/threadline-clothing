<?php
/**
 * Admin authentication & authorization.
 * - password_hash() / password_verify() — plain passwords never stored.
 * - Session-based auth with session regeneration after login.
 * - Session idle timeout.
 * - Basic brute-force protection (login_attempts table).
 * - Activity logging.
 */

declare(strict_types=1);

function admin_attempts_exceeded(string $identifier): bool
{
    $stmt = db()->prepare(
        'SELECT COUNT(*) FROM login_attempts
         WHERE (identifier = ? OR ip_address = ?)
           AND attempted_at > DATE_SUB(NOW(), INTERVAL ' . (int) LOGIN_LOCKOUT_MINUTES . ' MINUTE)'
    );
    $stmt->execute([mb_strtolower($identifier), client_ip()]);
    return (int) $stmt->fetchColumn() >= (int) LOGIN_MAX_ATTEMPTS;
}

function admin_record_attempt(string $identifier): void
{
    $stmt = db()->prepare('INSERT INTO login_attempts (identifier, ip_address) VALUES (?, ?)');
    $stmt->execute([mb_strtolower($identifier), client_ip()]);
}

function admin_clear_attempts(string $identifier): void
{
    $stmt = db()->prepare('DELETE FROM login_attempts WHERE identifier = ?');
    $stmt->execute([mb_strtolower($identifier)]);
}

/**
 * Attempt an admin login.
 * @return array{success: bool, message: string}
 */
function admin_login(string $email, string $password): array
{
    $email = mb_strtolower(trim($email));

    if (admin_attempts_exceeded($email)) {
        return [
            'success' => false,
            'message' => 'Too many failed attempts. Please wait ' . LOGIN_LOCKOUT_MINUTES . ' minutes and try again.',
        ];
    }

    $stmt = db()->prepare('SELECT * FROM admins WHERE email = ? LIMIT 1');
    $stmt->execute([$email]);
    $admin = $stmt->fetch();

    if (!$admin || (int) $admin['status'] !== 1 || !password_verify($password, $admin['password_hash'])) {
        admin_record_attempt($email);
        return ['success' => false, 'message' => 'Invalid email or password.'];
    }

    admin_clear_attempts($email);

    db()->prepare('UPDATE admins SET last_login = NOW() WHERE id = ?')->execute([$admin['id']]);

    // Prevent session fixation.
    session_regenerate_id(true);

    $_SESSION['admin'] = [
        'id'       => (int) $admin['id'],
        'name'     => $admin['name'],
        'email'    => $admin['email'],
        'role'     => $admin['role'],
        'login_at' => time(),
    ];

    record_activity('admin_login', 'admin', (int) $admin['id'], 'Admin logged in');

    return ['success' => true, 'message' => 'Welcome back, ' . $admin['name'] . '!'];
}

function current_admin(): ?array
{
    $admin = $_SESSION['admin'] ?? null;

    if (!is_array($admin) || empty($admin['id'])) {
        return null;
    }

    // Session idle timeout.
    if (time() - (int) ($admin['login_at'] ?? 0) > (int) SESSION_TIMEOUT) {
        unset($_SESSION['admin']);
        return null;
    }

    return $admin;
}

/**
 * Protect an admin page. Redirects to the login page when unauthenticated.
 * Also verifies the admin account is still active in the database.
 */
function require_admin(): array
{
    $admin = current_admin();

    if ($admin === null) {
        $_SESSION['flash'][] = ['type' => 'error', 'message' => 'Please log in to continue.'];
        redirect(url('/admin/login.php'));
    }

    $stmt = db()->prepare('SELECT id, status FROM admins WHERE id = ? LIMIT 1');
    $stmt->execute([$admin['id']]);
    $row = $stmt->fetch();

    if (!$row || (int) $row['status'] !== 1) {
        unset($_SESSION['admin']);
        redirect(url('/admin/login.php'));
    }

    // Refresh idle timestamp on activity.
    $_SESSION['admin']['login_at'] = time();

    return $admin;
}

function admin_logout(): void
{
    $_SESSION = [];
    if (ini_get('session.use_cookies')) {
        $params = session_get_cookie_params();
        setcookie(session_name(), '', time() - 42000, $params['path'], $params['domain'], $params['secure'], $params['httponly']);
    }
    session_destroy();
}

/** Write an entry into admin_activity_logs. */
function record_activity(string $action, ?string $entityType = null, ?int $entityId = null, ?string $description = null): void
{
    $admin = current_admin();
    $adminId = $admin ? (int) $admin['id'] : null;

    $stmt = db()->prepare(
        'INSERT INTO admin_activity_logs (admin_id, action, entity_type, entity_id, description, ip_address)
         VALUES (?, ?, ?, ?, ?, ?)'
    );
    $stmt->execute([$adminId, $action, $entityType, $entityId, $description, client_ip()]);
}