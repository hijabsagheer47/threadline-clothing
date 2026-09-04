<?php
declare(strict_types=1);
require_once __DIR__ . '/../includes/bootstrap.php';

$admin = require_admin();
$db = db();

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    csrf_require($_POST['csrf_token'] ?? null);
    $action = post('action', 20);
    $id = post_int('id');

    if ($action === 'read' && $id > 0) {
        $db->prepare('UPDATE contact_messages SET status = 1 WHERE id = ?')->execute([$id]);
        flash_set('success', 'Message marked as read.');
        redirect(url('/admin/messages.php'));
    }
    if ($action === 'unread' && $id > 0) {
        $db->prepare('UPDATE contact_messages SET status = 0 WHERE id = ?')->execute([$id]);
        flash_set('success', 'Message marked as unread.');
        redirect(url('/admin/messages.php'));
    }
    if ($action === 'delete' && $id > 0) {
        $db->prepare('DELETE FROM contact_messages WHERE id = ?')->execute([$id]);
        flash_set('success', 'Message deleted.');
        redirect(url('/admin/messages.php'));
    }
}

$page = max(1, (int) ($_GET['page'] ?? 1));
$perPage = 20;
$filter = get_string('filter', 10);

$where = '';
if ($filter === 'unread') $where = 'WHERE status = 0';
elseif ($filter === 'read') $where = 'WHERE status = 1';

$total = (int) $db->query("SELECT COUNT(*) FROM contact_messages {$where}")->fetchColumn();
$pages = max(1, (int) ceil($total / $perPage));
$page  = min($page, $pages);
$offset = ($page - 1) * $perPage;

$messages = $db->query(
    "SELECT * FROM contact_messages {$where} ORDER BY created_at DESC LIMIT {$perPage} OFFSET {$offset}"
)->fetchAll();

$qs = $filter !== '' ? 'filter=' . urlencode($filter) : '';

$page_title = 'Messages';
$active     = 'messages';

ob_start();
?>

<div class="page-header">
    <div>
        <h1>Contact Messages</h1>
        <p><?= (int) $total ?> message<?= (int) $total === 1 ? '' : 's' ?></p>
    </div>
    <div class="page-actions">
        <a href="<?= url('/admin/messages.php') ?>" class="btn btn-outline btn-sm">All</a>
        <a href="<?= url('/admin/messages.php?filter=unread') ?>" class="btn btn-outline btn-sm">Unread</a>
        <a href="<?= url('/admin/messages.php?filter=read') ?>" class="btn btn-outline btn-sm">Read</a>
    </div>
</div>

<?php if (!$messages): ?>
    <div class="card" style="text-align:center;color:var(--admin-muted);padding:48px">
        <i class="fa-regular fa-envelope-open" style="font-size:32px;display:block;margin-bottom:12px"></i>
        No messages here.
    </div>
<?php endif; ?>

<?php foreach ($messages as $m): ?>
    <div class="card" style="<?= (int) $m['status'] === 0 ? 'border-left:3px solid var(--admin-accent)' : '' ?>">
        <div style="display:flex;justify-content:space-between;gap:12px;flex-wrap:wrap;margin-bottom:10px">
            <div>
                <strong><?= e($m['name']) ?></strong>
                <?php if ($m['email']): ?> &lt;<a href="mailto:<?= e($m['email']) ?>"><?= e($m['email']) ?></a>&gt;<?php endif; ?>
                <?php if ($m['phone']): ?><span style="color:var(--admin-muted)"> · <?= e($m['phone']) ?></span><?php endif; ?>
                <?php if ((int) $m['status'] === 0): ?><span class="badge gold" style="margin-left:8px">Unread</span><?php endif; ?>
            </div>
            <span style="color:var(--admin-muted);font-size:12.5px"><?= e(format_datetime($m['created_at'])) ?></span>
        </div>
        <h3 style="font-size:15px;margin-bottom:6px"><?= e($m['subject']) ?></h3>
        <p style="margin:0 0 14px;white-space:pre-line"><?= e($m['message']) ?></p>
        <div style="display:flex;gap:8px">
            <?php if ((int) $m['status'] === 0): ?>
                <form method="post">
                    <?= csrf_field() ?>
                    <input type="hidden" name="action" value="read">
                    <input type="hidden" name="id" value="<?= (int) $m['id'] ?>">
                    <button class="btn btn-outline btn-xs"><i class="fa-solid fa-check"></i> Mark Read</button>
                </form>
            <?php else: ?>
                <form method="post">
                    <?= csrf_field() ?>
                    <input type="hidden" name="action" value="unread">
                    <input type="hidden" name="id" value="<?= (int) $m['id'] ?>">
                    <button class="btn btn-outline btn-xs">Mark Unread</button>
                </form>
            <?php endif; ?>
            <?php if ($m['email']): ?>
                <a class="btn btn-outline btn-xs" href="mailto:<?= e($m['email']) ?>?subject=Re: <?= e($m['subject']) ?>">Reply</a>
            <?php endif; ?>
            <form method="post" onsubmit="return confirm('Delete this message?')">
                <?= csrf_field() ?>
                <input type="hidden" name="action" value="delete">
                <input type="hidden" name="id" value="<?= (int) $m['id'] ?>">
                <button class="btn btn-danger btn-xs"><i class="fa-solid fa-trash"></i></button>
            </form>
        </div>
    </div>
<?php endforeach; ?>

<?= pagination_links($page, $pages, $qs) ?>

<?php
$content = ob_get_clean();
require __DIR__ . '/layout.php';