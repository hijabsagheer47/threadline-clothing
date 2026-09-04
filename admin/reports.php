<?php
declare(strict_types=1);
require_once __DIR__ . '/../includes/bootstrap.php';

$admin = require_admin();
$db = db();

$from = get_string('from', 10);
$to   = get_string('to', 10);
if ($from === '') $from = date('Y-m-d', strtotime('-30 days'));
if ($to === '')   $to   = date('Y-m-d');

$rangeWhere = "o.created_at >= ? AND o.created_at < DATE_ADD(?, INTERVAL 1 DAY) AND o.order_status <> 'cancelled'";
$rangeParams = [$from . ' 00:00:00', $to];

/* Summary */
$summary = $db->prepare(
    "SELECT COUNT(*) AS order_count,
            COALESCE(SUM(o.total), 0) AS revenue,
            COALESCE(SUM(o.subtotal), 0) AS subtotal,
            COALESCE(SUM(o.shipping_fee), 0) AS shipping
     FROM orders o WHERE {$rangeWhere}"
);
$summary->execute($rangeParams);
$summary = $summary->fetch();

/* Top products */
$topProducts = $db->prepare(
    "SELECT oi.product_name, SUM(oi.quantity) AS qty, SUM(oi.subtotal) AS revenue
     FROM order_items oi
     JOIN orders o ON o.id = oi.order_id
     WHERE {$rangeWhere}
     GROUP BY oi.product_id, oi.product_name
     ORDER BY qty DESC
     LIMIT 10"
);
$topProducts->execute($rangeParams);
$topProducts = $topProducts->fetchAll();

/* Orders by status */
$statusCounts = $db->prepare(
    "SELECT order_status, COUNT(*) AS cnt FROM orders o WHERE {$rangeWhere} GROUP BY order_status"
);
$statusCounts->execute($rangeParams);
$statusCounts = $statusCounts->fetchAll();

/* Daily revenue for the chart */
$daily = $db->prepare(
    "SELECT DATE(o.created_at) AS day, COUNT(*) AS orders, COALESCE(SUM(o.total), 0) AS revenue
     FROM orders o WHERE {$rangeWhere}
     GROUP BY DATE(o.created_at) ORDER BY day ASC"
);
$daily->execute($rangeParams);
$daily = $daily->fetchAll();

$chartLabels = [];
$chartValues = [];
foreach ($daily as $d) {
    $chartLabels[] = date('M j', strtotime($d['day']));
    $chartValues[] = (float) $d['revenue'];
}

$page_title = 'Reports';
$active     = 'reports';

ob_start();
?>

<div class="page-header">
    <div>
        <h1>Reports</h1>
        <p>Sales and order analytics — excluding cancelled orders.</p>
    </div>
</div>

<form class="report-toolbar" method="get" action="<?= e(url('/admin/reports.php')) ?>">
    <div class="form-group">
        <label for="from">From</label>
        <input type="date" id="from" name="from" value="<?= e($from) ?>">
    </div>
    <div class="form-group">
        <label for="to">To</label>
        <input type="date" id="to" name="to" value="<?= e($to) ?>">
    </div>
    <button type="submit" class="btn btn-primary">Generate Report</button>
</form>

<div class="stat-grid">
    <div class="stat-card">
        <div class="stat-icon green"><i class="fa-solid fa-receipt"></i></div>
        <div>
            <div class="stat-value"><?= (int) $summary['order_count'] ?></div>
            <div class="stat-label">Orders</div>
        </div>
    </div>
    <div class="stat-card">
        <div class="stat-icon gold"><i class="fa-solid fa-sack-dollar"></i></div>
        <div>
            <div class="stat-value"><?= money((float) $summary['revenue']) ?></div>
            <div class="stat-label">Total Revenue</div>
        </div>
    </div>
    <div class="stat-card">
        <div class="stat-icon blue"><i class="fa-solid fa-shirt"></i></div>
        <div>
            <div class="stat-value"><?= money((float) $summary['subtotal']) ?></div>
            <div class="stat-label">Product Sales</div>
        </div>
    </div>
    <div class="stat-card">
        <div class="stat-icon blue"><i class="fa-solid fa-truck"></i></div>
        <div>
            <div class="stat-value"><?= money((float) $summary['shipping']) ?></div>
            <div class="stat-label">Shipping Collected</div>
        </div>
    </div>
</div>

<div class="detail-grid">
    <div>
        <div class="card">
            <div class="card-title">Revenue by Day</div>
            <?php if (!$daily): ?>
                <p style="color:var(--admin-muted)">No sales in this period.</p>
            <?php else: ?>
                <canvas id="revenueChart" height="220" style="max-width:100%"></canvas>
            <?php endif; ?>
        </div>

        <div class="card">
            <div class="card-title">Top Selling Products</div>
            <div class="table-wrap">
                <table class="admin-table">
                    <thead><tr><th>Product</th><th>Units Sold</th><th>Revenue</th></tr></thead>
                    <tbody>
                        <?php if (!$topProducts): ?>
                            <tr><td colspan="3" style="text-align:center;color:var(--admin-muted);padding:24px">No sales in this period.</td></tr>
                        <?php endif; ?>
                        <?php foreach ($topProducts as $p): ?>
                            <tr>
                                <td><strong><?= e($p['product_name']) ?></strong></td>
                                <td><?= (int) $p['qty'] ?></td>
                                <td><?= money((float) $p['revenue']) ?></td>
                            </tr>
                        <?php endforeach; ?>
                    </tbody>
                </table>
            </div>
        </div>
    </div>

    <div>
        <div class="card">
            <div class="card-title">Orders by Status</div>
            <?php
            $statusTotals = ['pending' => 0, 'confirmed' => 0, 'processing' => 0, 'shipped' => 0, 'delivered' => 0, 'cancelled' => 0];
            foreach ($statusCounts as $sc) $statusTotals[$sc['order_status']] = (int) $sc['cnt'];
            $statusLabels = ['pending' => 'Pending', 'confirmed' => 'Confirmed', 'processing' => 'Processing', 'shipped' => 'Shipped', 'delivered' => 'Delivered', 'cancelled' => 'Cancelled'];
            foreach ($statusLabels as $key => $label): ?>
                <div style="display:flex;justify-content:space-between;padding:9px 0;border-bottom:1px dashed var(--admin-border)">
                    <span><?= e($label) ?></span>
                    <span class="badge <?= e(order_status_color($key)) ?>"><?= $statusTotals[$key] ?></span>
                </div>
            <?php endforeach; ?>
        </div>

        <div class="card">
            <div class="card-title">Inventory Snapshot</div>
            <ul class="detail-list">
                <li><span>Total products</span><strong><?= (int) $db->query('SELECT COUNT(*) FROM products')->fetchColumn() ?></strong></li>
                <li><span>Active products</span><strong><?= (int) $db->query('SELECT COUNT(*) FROM products WHERE status = 1')->fetchColumn() ?></strong></li>
                <li><span>In stock</span><strong><?= (int) $db->query('SELECT COUNT(*) FROM products WHERE status = 1 AND stock_quantity > 0')->fetchColumn() ?></strong></li>
                <li><span>Low stock</span><strong><?= (int) $db->query('SELECT COUNT(*) FROM products WHERE status = 1 AND stock_quantity <= ' . (int) setting('low_stock_threshold', '5'))->fetchColumn() ?></strong></li>
                <li><span>Out of stock</span><strong><?= (int) $db->query('SELECT COUNT(*) FROM products WHERE status = 1 AND stock_quantity < 1')->fetchColumn() ?></strong></li>
                <li><span>Customers</span><strong><?= (int) $db->query('SELECT COUNT(*) FROM customers')->fetchColumn() ?></strong></li>
                <li><span>Subscribers</span><strong><?= (int) $db->query('SELECT COUNT(*) FROM subscribers WHERE status = 1')->fetchColumn() ?></strong></li>
            </ul>
        </div>
    </div>
</div>

<?php if ($daily): ?>
<script>
    (function () {
        var canvas = document.getElementById('revenueChart');
        if (!canvas || !window.CanvasRenderingContext2D) return;
        var ctx = canvas.getContext('2d');
        var labels = <?= json_encode($chartLabels) ?>;
        var values = <?= json_encode($chartValues) ?>;
        var w = canvas.width = canvas.offsetWidth * (window.devicePixelRatio || 1);
        var h = canvas.height = 220 * (window.devicePixelRatio || 1);
        ctx.scale(window.devicePixelRatio || 1, window.devicePixelRatio || 1);
        var padL = 10, padR = 10, padT = 16, padB = 28;
        var plotW = canvas.width / (window.devicePixelRatio || 1) - padL - padR;
        var plotH = 220 - padT - padB;
        var max = Math.max.apply(null, values) * 1.1 || 1;
        ctx.clearRect(0, 0, canvas.width, canvas.height);
        ctx.strokeStyle = '#f0e9e2';
        ctx.lineWidth = 1;
        for (var g = 0; g <= 4; g++) {
            var gy = padT + (plotH / 4) * g;
            ctx.beginPath(); ctx.moveTo(padL, gy); ctx.lineTo(padL + plotW, gy); ctx.stroke();
        }
        ctx.beginPath();
        ctx.strokeStyle = '#b98d6f';
        ctx.lineWidth = 2;
        for (var i = 0; i < values.length; i++) {
            var x = padL + (plotW / (values.length - 1 || 1)) * i;
            var y = padT + plotH - (values[i] / max) * plotH;
            if (i === 0) ctx.moveTo(x, y); else ctx.lineTo(x, y);
        }
        ctx.stroke();
        ctx.fillStyle = '#8a7a70';
        ctx.font = '10px sans-serif';
        ctx.textAlign = 'center';
        var step = Math.ceil(labels.length / 8);
        for (var j = 0; j < labels.length; j += step) {
            var lx = padL + (plotW / (values.length - 1 || 1)) * j;
            ctx.fillText(labels[j], lx, 220 - 10);
        }
    })();
</script>
<?php endif; ?>

<?php
$content = ob_get_clean();
require __DIR__ . '/layout.php';