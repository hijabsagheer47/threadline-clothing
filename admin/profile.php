<?php
declare(strict_types=1);
require_once __DIR__ . '/../includes/bootstrap.php';

$admin = require_admin();
$db = db();

$errors = [];

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    csrf_require($_POST['csrf_token'] ?? null);
    $action = post('action', 20);

    /* ---------------- profile ---------------- */
    if ($action === 'profile') {
        $name  = post('name', 120);
        $email = mb_strtolower(post('email', 150));

        if ($name === '')        $errors['name'] = 'Name is required.';
        if (!valid_email($email)) $errors['email'] = 'Enter a valid email address.';

        if (!$errors) {
            $chk = $db->prepare('SELECT id FROM admins WHERE email = ? AND id <> ? LIMIT 1');
            $chk->execute([$email, $admin['id']]);
            if ($chk->fetch()) {
                $errors['email'] = 'That email is already in use by another admin.';
            }
        }

        if (!$errors) {
            $db->prepare('UPDATE admins SET name = ?, email = ? WHERE id = ?')->execute([$name, $email, $admin['id']]);
            $_SESSION['admin']['name'] = $name;
            $_SESSION['admin']['email'] = $email;
            record_activity('admin_profile_update', 'admin', $admin['id'], 'Profile updated');
            flash_set('success', 'Profile updated.');
            redirect(url('/admin/profile.php'));
        }
    }

    /* ---------------- password ---------------- */
    if ($action === 'password') {
        $current    = (string) ($_POST['current_password'] ?? '');
        $newPass    = (string) ($_POST['new_password'] ?? '');
        $confirm    = (string) ($_POST['confirm_password'] ?? '');

        $stmt = $db->prepare('SELECT password_hash FROM admins WHERE id = ?');
        $stmt->execute([$admin['id']]);
        $hash = $stmt->fetchColumn();

        if (!password_verify($current, (string) $hash)) {
            $errors['current'] = 'Current password is incorrect.';
        }
        if (strlen($newPass) < 8) {
            $errors['new'] = 'New password must be at least 8 characters.';
        }
        if ($newPass !== $confirm) {
            $errors['confirm'] = 'Passwords do not match.';
        }

        if (!$errors) {
            $db->prepare('UPDATE admins SET password_hash = ? WHERE id = ?')
               ->execute([password_hash($newPass, PASSWORD_DEFAULT), $admin['id']]);
            record_activity('admin_password_change', 'admin', $admin['id'], 'Password changed');
            flash_set('success', 'Password updated successfully.');
            redirect(url('/admin/profile.php'));
        }
    }
}

$page_title = 'My Profile';
$active     = 'profile';

ob_start();
?>

<div class="page-header">
    <div>
        <h1>My Profile</h1>
        <p>Update your account details and password.</p>
    </div>
</div>

<?php if ($errors): ?>
    <div class="admin-flash error">
        <span>
            <?php foreach ($errors as $err): ?>
                <?= e($err) ?><br>
            <?php endforeach; ?>
        </span>
    </div>
<?php endif; ?>

<div class="detail-grid">
    <div class="card">
        <div class="card-title">Profile Details</div>
        <form method="post" action="<?= e(url('/admin/profile.php')) ?>">
            <?= csrf_field() ?>
            <input type="hidden" name="action" value="profile">

            <div class="form-group">
                <label for="name">Full Name</label>
                <input type="text" id="name" name="name" value="<?= e($admin['name']) ?>">
            </div>
            <div class="form-group">
                <label for="email">Email Address</label>
                <input type="email" id="email" name="email" value="<?= e($admin['email']) ?>">
            </div>
            <div class="form-group">
                <label>Role</label>
                <input type="text" value="<?= e($admin['role']) ?>" disabled>
            </div>
            <button type="submit" class="btn btn-primary"><i class="fa-solid fa-floppy-disk"></i> Save Profile</button>
        </form>
    </div>

    <div class="card">
        <div class="card-title">Change Password</div>
        <form method="post" action="<?= e(url('/admin/profile.php')) ?>">
            <?= csrf_field() ?>
            <input type="hidden" name="action" value="password">

            <div class="form-group">
                <label for="current_password">Current Password</label>
                <input type="password" id="current_password" name="current_password" required>
            </div>
            <div class="form-group">
                <label for="new_password">New Password</label>
                <input type="password" id="new_password" name="new_password" required minlength="8">
                <p class="help">At least 8 characters. Stored hashed with password_hash() — never in plain text.</p>
            </div>
            <div class="form-group">
                <label for="confirm_password">Confirm New Password</label>
                <input type="password" id="confirm_password" name="confirm_password" required>
            </div>
            <button type="submit" class="btn btn-accent"><i class="fa-solid fa-key"></i> Update Password</button>
        </form>
    </div>
</div>

<?php
$content = ob_get_clean();
require __DIR__ . '/layout.php';