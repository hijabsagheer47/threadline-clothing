<?php
declare(strict_types=1);
require_once __DIR__ . '/../includes/bootstrap.php';

$admin = require_admin();
$db = db();

$q    = get_string('q', 100);
$page = max(1, (int) ($_GET['page'] ?? 1));
$perPage = 25;

$where  = [];
$params = [];
if ($q !== '') {
    $like = '%' . $q . '%';
    $where[] = '(name LIKE ? OR email LIKE ? OR phone LIKE ?)';
    array_push($params, $like, $like, $like);
}
$whereSql = $where ? 'WHERE ' . implode(' AND ', $where) : '';

$countStmt = $db->prepare("SELECT COUNT(*) FROM customers {$whereSql}");
$countStmt->execute($params);
$total = (int) $countStmt->fetchColumn();
$pages = max(1, (int) ceil($total / $perPage));
$page  = min($page, $pages);
$offset = ($page - 1) * $perPage;

$stmt = $db->prepare(
    "SELECT c.*,
            (SELECT COUNT(*) FROM orders o WHERE o.customer_email = c.email) AS order_count,
            (SELECT COALESCE(SUM(o.total), 0) FROM orders o WHERE o.customer_email = c.email AND o.order_status <> 'cancelled') AS total_spent
     FROM customers c
     {$whereSql}
     ORDER BY c.created_at DESC
     LIMIT {$perPage} OFFSET {$offset}"
);
$stmt->execute($params);
$customers = $stmt->fetchAll();

$qs = $q !== '' ? 'q=' . urlencode($q) : '';

$page_title = 'Customers';
$active     = 'customers';

ob_start();
?>

<div class="page-header">
    <div>
        <h1>Customers</h1>
        <p><?= (int) $total ?> customer<?= (int) $total === 1 ? '' : 's' ?></p>
    </div>
</div>

<form class="filter-bar" method="get" action="<?= e(url('/admin/customers.php')) ?>">
    <input type="search" name="q" placeholder="Search name, email or phone…" value="<?= e($q) ?>">
    <button type="submit" class="btn btn-outline btn-sm">Search</button>
    <?php if ($qs): ?><a href="<?= url('/admin/customers.php') ?>" class="btn btn-outline btn-sm">Clear</a><?php endif; ?>
</form>

<div class="card">
    <div class="table-wrap">
        <table class="admin-table">
            <thead>
                <tr>
                    <th>Customer</th>
                    <th>Email</th>
                    <th>Phone</th>
                    <th>Orders</th>
                    <th>Total Spent</th>
                    <th>Status</th>
                    <th>Joined</th>
                </tr>
            </thead>
            <tbody>
                <?php if (!$customers): ?>
                    <tr><td colspan="7" style="text-align:center;color:var(--admin-muted);padding:36px">No customers yet.</td></tr>
                <?php endif; ?>
                <?php foreach ($customers as $c): ?>
                    <tr>
                        <td><strong><?= e($c['name']) ?></strong></td>
                        <td><?= e($c['email']) ?></td>
                        <td><?= e($c['phone'] ?: '—') ?></td>
                        <td><?= (int) $c['order_count'] ?></td>
                        <td><?= money((float) $c['total_spent']) ?></td>
                        <td><span class="badge <?= (int) $c['status'] === 1 ? 'green' : 'gray' ?>"><?= (int) $c['status'] === 1 ? 'Active' : 'Inactive' ?></span></td>
                        <td><?= e(format_date($c['created_at'])) ?></td>
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