<?php
declare(strict_types=1);
require_once __DIR__ . '/../includes/bootstrap.php';

/* Already logged in? */
if (current_admin()) {
    redirect(url('/admin/index.php'));
}

$errors = [];
$email  = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    csrf_require($_POST['csrf_token'] ?? null);

    $email    = post('email', 150);
    $password = (string) ($_POST['password'] ?? '');

    if (!valid_email($email)) {
        $errors[] = 'Please enter a valid email address.';
    }
    if ($password === '') {
        $errors[] = 'Please enter your password.';
    }

    if (!$errors) {
        $result = admin_login($email, $password);
        if ($result['success']) {
            redirect(url('/admin/index.php'));
        }
        $errors[] = $result['message'];
    }
}

$flashes = flash_get();
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Admin Login | <?= e(setting('store_name')) ?></title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=DM+Sans:wght@400;500;600;700&family=Playfair+Display:wght@500;600;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.2/css/all.min.css">
    <link rel="stylesheet" href="<?= e(asset_url('assets/css/admin.css')) ?>">
</head>
<body class="login-body">

    <div class="login-card">
        <div class="login-brand">
            <h1><?= e(setting('store_name')) ?></h1>
            <p>Admin Panel — Sign in to continue</p>
        </div>

        <?php foreach ($flashes as $f): ?>
            <div class="admin-flash <?= e($f['type']) ?>">
                <span><?= e($f['message']) ?></span>
            </div>
        <?php endforeach; ?>

        <?php foreach ($errors as $err): ?>
            <div class="admin-flash error">
                <span><?= e($err) ?></span>
            </div>
        <?php endforeach; ?>

        <form method="post" action="<?= e(url('/admin/login.php')) ?>" autocomplete="off">
            <?= csrf_field() ?>

            <div class="form-group">
                <label for="email">Email Address</label>
                <input type="email" id="email" name="email" placeholder="admin@example.com"
                       value="<?= e($email) ?>" required autofocus>
            </div>

            <div class="form-group">
                <label for="password">Password</label>
                <input type="password" id="password" name="password" placeholder="Your password" required>
            </div>

            <button type="submit" class="btn btn-primary login-submit">
                <i class="fa-solid fa-lock"></i> Sign In
            </button>
        </form>

        <p class="login-note">
            <a href="<?= url('/index.php') ?>"><i class="fa-solid fa-arrow-left"></i> Back to store</a>
        </p>
    </div>

</body>
</html>