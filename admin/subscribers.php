<?php
declare(strict_types=1);
require_once __DIR__ . '/../includes/bootstrap.php';

$admin = require_admin();
$db = db();

/* ---------------------------------------------------------------------------
   Actions
--------------------------------------------------------------------------- */
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    csrf_require($_POST['csrf_token'] ?? null);
    $action = post('action', 20);
    $id = post_int('id');

    if ($action === 'remove' && $id > 0) {
        $db->prepare('DELETE FROM subscribers WHERE id = ?')->execute([$id]);
        flash_set('success', 'Subscriber removed.');
        redirect(url('/admin/subscribers.php'));
    }
    if ($action === 'unsubscribe' && $id > 0) {
        $db->prepare('UPDATE subscribers SET status = 0 WHERE id = ?')->execute([$id]);
        flash_set('success', 'Subscriber unsubscribed.');
        redirect(url('/admin/subscribers.php'));
    }
}

/* CSV export */
if (($_GET['export'] ?? '') === 'csv') {
    header('Content-Type: text/csv; charset=utf-8');
    header('Content-Disposition: attachment; filename="subscribers-' . date('Y-m-d') . '.csv"');
    $out = fopen('php://output', 'w');
    fputcsv($out, ['Email', 'Status', 'Subscribed At']);
    foreach ($db->query('SELECT email, status, created_at FROM subscribers ORDER BY created_at DESC') as $row) {
        fputcsv($out, [$row['email'], (int) $row['status'] === 1 ? 'subscribed' : 'unsubscribed', $row['created_at']]);
    }
    fclose($out);
    exit;
}

$q    = get_string('q', 100);
$page = max(1, (int) ($_GET['page'] ?? 1));
$perPage = 30;

$where  = [];
$params = [];
if ($q !== '') {
    $where[] = 'email LIKE ?';
    $params[] = '%' . $q . '%';
}
$whereSql = $where ? 'WHERE ' . implode(' AND ', $where) : '';

$countStmt = $db->prepare("SELECT COUNT(*) FROM subscribers {$whereSql}");
$countStmt->execute($params);
$total = (int) $countStmt->fetchColumn();
$pages = max(1, (int) ceil($total / $perPage));
$page  = min($page, $pages);
$offset = ($page - 1) * $perPage;

$stmt = $db->prepare("SELECT * FROM subscribers {$whereSql} ORDER BY created_at DESC LIMIT {$perPage} OFFSET {$offset}");
$stmt->execute($params);
$subscribers = $stmt->fetchAll();

$qs = $q !== '' ? 'q=' . urlencode($q) : '';

$page_title = 'Subscribers';
$active     = 'subscribers';

ob_start();
?>

<div class="page-header">
    <div>
        <h1>Subscribers</h1>
        <p><?= (int) $total ?> newsletter subscriber<?= (int) $total === 1 ? '' : 's' ?></p>
    </div>
    <div class="page-actions">
        <a href="<?= e(url('/admin/subscribers.php?export=csv')) ?>" class="btn btn-outline"><i class="fa-solid fa-file-csv"></i> Export CSV</a>
    </div>
</div>

<form class="filter-bar" method="get" action="<?= e(url('/admin/subscribers.php')) ?>">
    <input type="search" name="q" placeholder="Search email…" value="<?= e($q) ?>">
    <button type="submit" class="btn btn-outline btn-sm">Search</button>
    <?php if ($qs): ?><a href="<?= url('/admin/subscribers.php') ?>" class="btn btn-outline btn-sm">Clear</a><?php endif; ?>
</form>

<div class="card">
    <div class="table-wrap">
        <table class="admin-table">
            <thead>
                <tr>
                    <th>Email</th>
                    <th>Status</th>
                    <th>Subscribed</th>
                    <th style="text-align:right">Actions</th>
                </tr>
            </thead>
            <tbody>
                <?php if (!$subscribers): ?>
                    <tr><td colspan="4" style="text-align:center;color:var(--admin-muted);padding:36px">No subscribers yet.</td></tr>
                <?php endif; ?>
                <?php foreach ($subscribers as $s): ?>
                    <tr>
                        <td><strong><?= e($s['email']) ?></strong></td>
                        <td><span class="badge <?= (int) $s['status'] === 1 ? 'green' : 'gray' ?>"><?= (int) $s['status'] === 1 ? 'Subscribed' : 'Unsubscribed' ?></span></td>
                        <td><?= e(format_date($s['created_at'])) ?></td>
                        <td style="text-align:right;white-space:nowrap">
                            <?php if ((int) $s['status'] === 1): ?>
                                <form method="post" style="display:inline">
                                    <?= csrf_field() ?>
                                    <input type="hidden" name="action" value="unsubscribe">
                                    <input type="hidden" name="id" value="<?= (int) $s['id'] ?>">
                                    <button class="btn btn-outline btn-xs">Unsubscribe</button>
                                </form>
                            <?php endif; ?>
                            <form method="post" style="display:inline" onsubmit="return confirm('Remove this subscriber permanently?')">
                                <?= csrf_field() ?>
                                <input type="hidden" name="action" value="remove">
                                <input type="hidden" name="id" value="<?= (int) $s['id'] ?>">
                                <button class="btn btn-danger btn-xs"><i class="fa-solid fa-trash"></i></button>
                            </form>
                        </td>
                    </tr>
                <?php endforeach; ?>
            </tbody>
        </table>
    </div>
    <?= pagination_links($page, $pages, $qs) ?>
</div>

<?php
$content = ob_get_clean();
require __DIR__ . '/layout.php';