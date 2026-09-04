<?php
declare(strict_types=1);
require_once __DIR__ . '/../includes/bootstrap.php';

$admin = require_admin();
$db = db();

$page = max(1, (int) ($_GET['page'] ?? 1));
$perPage = 30;

$total = (int) $db->query('SELECT COUNT(*) FROM admin_activity_logs')->fetchColumn();
$pages = max(1, (int) ceil($total / $perPage));
$page  = min($page, $pages);
$offset = ($page - 1) * $perPage;

$logs = $db->query(
    'SELECT l.*, a.name AS admin_name
     FROM admin_activity_logs l
     LEFT JOIN admins a ON a.id = l.admin_id
     ORDER BY l.created_at DESC
     LIMIT ' . $perPage . ' OFFSET ' . $offset
)->fetchAll();

$page_title = 'Activity Log';
$active     = 'activity';

ob_start();
?>

<div class="page-header">
    <div>
        <h1>Activity Log</h1>
        <p>Every admin action is recorded here with the IP address.</p>
    </div>
</div>

<div class="card">
    <div class="table-wrap">
        <table class="admin-table">
            <thead>
                <tr>
                    <th>Admin</th>
                    <th>Action</th>
                    <th>Entity</th>
                    <th>Description</th>
                    <th>IP Address</th>
                    <th>Time</th>
                </tr>
            </thead>
            <tbody>
                <?php if (!$logs): ?>
                    <tr><td colspan="6" style="text-align:center;color:var(--admin-muted);padding:36px">No activity recorded yet.</td></tr>
                <?php endif; ?>
                <?php foreach ($logs as $l): ?>
                    <tr>
                        <td><strong><?= e($l['admin_name'] ?? 'System') ?></strong></td>
                        <td><span class="badge blue"><?= e($l['action']) ?></span></td>
                        <td><?= e($l['entity_type'] ?: '—') ?> <?= $l['entity_id'] ? '#' . (int) $l['entity_id'] : '' ?></td>
                        <td><?= e($l['description'] ?: '—') ?></td>
                        <td><?= e($l['ip_address'] ?: '—') ?></td>
                        <td style="white-space:nowrap"><?= e(format_datetime($l['created_at'])) ?></td>
                    </tr>
                <?php endforeach; ?>
            </tbody>
        </table>
    </div>
    <?= pagination_links($page, $pages, '') ?>
</div>

<?php
$content = ob_get_clean();
require __DIR__ . '/layout.php';