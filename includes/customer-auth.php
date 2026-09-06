<?php
/**
 * Customer accounts (storefront + mobile app).
 *
 * Deliberately separate from includes/auth.php, which is admin-only: an admin
 * session must never authenticate a customer, or vice versa. Passwords go
 * through password_hash()/password_verify(); plain passwords are never stored.
 *
 * The current customer is resolved from $GLOBALS['tc_customer'] (set by the
 * API bootstrap from the bearer token) falling back to the web session, so the
 * same helpers serve both the website and the app.
 */

declare(strict_types=1);

const CUSTOMER_PASSWORD_MIN = 8;

function customer_by_id(int $id): ?array
{
    $stmt = db()->prepare('SELECT * FROM customers WHERE id = ? AND status = 1 LIMIT 1');
    $stmt->execute([$id]);
    $row = $stmt->fetch();
    return $row ?: null;
}

function customer_by_email(string $email): ?array
{
    $stmt = db()->prepare('SELECT * FROM customers WHERE email = ? LIMIT 1');
    $stmt->execute([mb_strtolower(trim($email))]);
    $row = $stmt->fetch();
    return $row ?: null;
}

/** The signed-in customer, or null. */
function current_customer(): ?array
{
    if (isset($GLOBALS['tc_customer']) && is_array($GLOBALS['tc_customer'])) {
        return $GLOBALS['tc_customer'];
    }
    $id = (int) ($_SESSION['customer_id'] ?? 0);
    return $id > 0 ? customer_by_id($id) : null;
}

function current_customer_id(): ?int
{
    $customer = current_customer();
    return $customer ? (int) $customer['id'] : null;
}

/**
 * Register a new customer.
 * @return array{ok: bool, customer?: array, errors?: array<string,string>}
 */
function customer_register(string $name, string $email, string $password, string $phone = '', bool $newsletter = false): array
{
    $errors = [];
    $name  = trim($name);
    $email = mb_strtolower(trim($email));

    if ($name === '')                                  $errors['name']     = 'Please enter your name.';
    if (!valid_email($email))                          $errors['email']    = 'Please enter a valid email address.';
    if (mb_strlen($password) < CUSTOMER_PASSWORD_MIN)  $errors['password'] = 'Password must be at least ' . CUSTOMER_PASSWORD_MIN . ' characters.';
    if ($phone !== '' && !valid_phone($phone))         $errors['phone']    = 'Please enter a valid phone number.';

    if (!$errors && customer_by_email($email)) {
        $errors['email'] = 'An account with this email already exists.';
    }
    if ($errors) {
        return ['ok' => false, 'errors' => $errors];
    }

    $columns = ['name', 'email', 'phone', 'password_hash', 'status'];
    $values  = [$name, $email, $phone !== '' ? $phone : null, password_hash($password, PASSWORD_DEFAULT), 1];

    // Migration columns are optional so the API also runs on the base schema.
    if (tc_column_exists('customers', 'newsletter_optin')) {
        $columns[] = 'newsletter_optin';
        $values[]  = $newsletter ? 1 : 0;
    }
    if (tc_column_exists('customers', 'referral_code')) {
        $columns[] = 'referral_code';
        $values[]  = strtoupper(bin2hex(random_bytes(4)));
    }

    $sql = 'INSERT INTO customers (' . implode(', ', $columns) . ') VALUES ('
         . implode(', ', array_fill(0, count($columns), '?')) . ')';
    db()->prepare($sql)->execute($values);

    $customer = customer_by_id((int) db()->lastInsertId());

    if ($newsletter && $customer) {
        db()->prepare('INSERT IGNORE INTO subscribers (email, status) VALUES (?, 1)')->execute([$email]);
    }

    return ['ok' => true, 'customer' => $customer];
}

/**
 * Verify credentials. Reuses the admin brute-force ledger (login_attempts) so
 * repeated guesses against a customer email are throttled the same way.
 * @return array{ok: bool, customer?: array, message?: string}
 */
function customer_authenticate(string $email, string $password): array
{
    $email = mb_strtolower(trim($email));

    if (admin_attempts_exceeded($email)) {
        return [
            'ok'      => false,
            'message' => 'Too many failed attempts. Please wait ' . LOGIN_LOCKOUT_MINUTES . ' minutes and try again.',
        ];
    }

    $customer = customer_by_email($email);

    if (!$customer || empty($customer['password_hash']) || !password_verify($password, $customer['password_hash'])) {
        admin_record_attempt($email);
        return ['ok' => false, 'message' => 'Invalid email or password.'];
    }
    if ((int) $customer['status'] !== 1) {
        return ['ok' => false, 'message' => 'This account has been disabled. Please contact support.'];
    }

    admin_clear_attempts($email);

    if (tc_column_exists('customers', 'last_login')) {
        db()->prepare('UPDATE customers SET last_login = NOW() WHERE id = ?')->execute([(int) $customer['id']]);
    }

    return ['ok' => true, 'customer' => $customer];
}

/** Update the profile fields a customer is allowed to change themselves. */
function customer_update_profile(int $customerId, array $fields): array
{
    $errors = [];
    $set    = [];
    $params = [];

    if (array_key_exists('name', $fields)) {
        $name = trim((string) $fields['name']);
        if ($name === '') {
            $errors['name'] = 'Please enter your name.';
        } else {
            $set[] = 'name = ?';
            $params[] = $name;
        }
    }
    if (array_key_exists('phone', $fields)) {
        $phone = trim((string) $fields['phone']);
        if ($phone !== '' && !valid_phone($phone)) {
            $errors['phone'] = 'Please enter a valid phone number.';
        } else {
            $set[] = 'phone = ?';
            $params[] = $phone !== '' ? $phone : null;
        }
    }
    if (array_key_exists('preferred_size', $fields) && tc_column_exists('customers', 'preferred_size')) {
        $set[] = 'preferred_size = ?';
        $params[] = trim((string) $fields['preferred_size']) ?: null;
    }
    if (array_key_exists('newsletter_optin', $fields) && tc_column_exists('customers', 'newsletter_optin')) {
        $set[] = 'newsletter_optin = ?';
        $params[] = !empty($fields['newsletter_optin']) ? 1 : 0;
    }

    if ($errors) {
        return ['ok' => false, 'errors' => $errors];
    }
    if (!$set) {
        return ['ok' => true, 'customer' => customer_by_id($customerId)];
    }

    $params[] = $customerId;
    db()->prepare('UPDATE customers SET ' . implode(', ', $set) . ' WHERE id = ?')->execute($params);

    return ['ok' => true, 'customer' => customer_by_id($customerId)];
}

/** @return array{ok: bool, message?: string} */
function customer_change_password(int $customerId, string $current, string $new): array
{
    $stmt = db()->prepare('SELECT password_hash FROM customers WHERE id = ? LIMIT 1');
    $stmt->execute([$customerId]);
    $hash = (string) $stmt->fetchColumn();

    if ($hash === '' || !password_verify($current, $hash)) {
        return ['ok' => false, 'message' => 'Your current password is incorrect.'];
    }
    if (mb_strlen($new) < CUSTOMER_PASSWORD_MIN) {
        return ['ok' => false, 'message' => 'Password must be at least ' . CUSTOMER_PASSWORD_MIN . ' characters.'];
    }

    db()->prepare('UPDATE customers SET password_hash = ? WHERE id = ?')
        ->execute([password_hash($new, PASSWORD_DEFAULT), $customerId]);

    return ['ok' => true];
}

/**
 * Issue a password reset token. Always reports success to the caller so the
 * endpoint cannot be used to discover which emails have accounts.
 * @return array{token: ?string, email: string}
 */
function customer_create_reset_token(string $email): array
{
    $email = mb_strtolower(trim($email));
    $customer = customer_by_email($email);

    if (!$customer || !tc_table_exists('password_reset_tokens')) {
        return ['token' => null, 'email' => $email];
    }

    $token = bin2hex(random_bytes(32));
    db()->prepare(
        'INSERT INTO password_reset_tokens (email, token, expires_at)
         VALUES (?, ?, DATE_ADD(NOW(), INTERVAL 60 MINUTE))'
    )->execute([$email, $token]);

    return ['token' => $token, 'email' => $email];
}

/** @return array{ok: bool, message?: string} */
function customer_reset_password(string $token, string $password): array
{
    if (!tc_table_exists('password_reset_tokens')) {
        return ['ok' => false, 'message' => 'Password reset is not available.'];
    }
    if (mb_strlen($password) < CUSTOMER_PASSWORD_MIN) {
        return ['ok' => false, 'message' => 'Password must be at least ' . CUSTOMER_PASSWORD_MIN . ' characters.'];
    }

    $stmt = db()->prepare(
        'SELECT * FROM password_reset_tokens
         WHERE token = ? AND used_at IS NULL AND expires_at > NOW() LIMIT 1'
    );
    $stmt->execute([$token]);
    $row = $stmt->fetch();

    if (!$row) {
        return ['ok' => false, 'message' => 'This reset link is invalid or has expired.'];
    }

    $customer = customer_by_email((string) $row['email']);
    if (!$customer) {
        return ['ok' => false, 'message' => 'This reset link is invalid or has expired.'];
    }

    db()->prepare('UPDATE customers SET password_hash = ? WHERE id = ?')
        ->execute([password_hash($password, PASSWORD_DEFAULT), (int) $customer['id']]);
    db()->prepare('UPDATE password_reset_tokens SET used_at = NOW() WHERE id = ?')
        ->execute([(int) $row['id']]);

    return ['ok' => true];
}
