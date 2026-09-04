<?php
declare(strict_types=1);
require_once __DIR__ . '/../includes/bootstrap.php';

$admin = require_admin();

$db = db();

$stats = [
    'products'        => (int) $db->query('SELECT COUNT(*) FROM products')->fetchColumn(),
    'active_products' => (int) $db->query('SELECT COUNT(*) FROM products WHERE status = 1')->fetchColumn(),
    'out_of_stock'    => (int) $db->query('SELECT COUNT(*) FROM products WHERE status = 1 AND stock_quantity < 1')->fetchColumn(),
    'categories'      => (int) $db->query('SELECT COUNT(*) FROM categories WHERE status = 1')->fetchColumn(),
    'orders'          => (int) $db->query('SELECT COUNT(*) FROM orders')->fetchColumn(),
    'pending_orders'  => (int) $db->query("SELECT COUNT(*) FROM orders WHERE order_status = 'pending'")->fetchColumn(),
    'completed_orders'=> (int) $db->query("SELECT COUNT(*) FROM orders WHERE order_status IN ('delivered','shipped')")->fetchColumn(),
    'customers'       => (int) $db->query('SELECT COUNT(*) FROM customers')->fetchColumn(),
];

$revenue = $db->query("SELECT COALESCE(SUM(total), 0) FROM orders WHERE order_status NOT IN ('cancelled')")->fetchColumn();

$lowStockThreshold = (int) setting('low_stock_threshold', '5');
$lowStock = $db->prepare(
    'SELECT p.id, p.name, p.sku, p.stock_quantity, pi.image AS primary_image
     FROM products p
     LEFT JOIN product_images pi ON pi.product_id = p.id AND pi.is_primary = 1
     WHERE p.status = 1 AND p.stock_quantity <= ?
     ORDER BY p.stock_quantity ASC
     LIMIT 8'
);
$lowStock->execute([$lowStockThreshold]);
$lowStock = $lowStock->fetchAll();

$recentOrders = $db->query(
    'SELECT id, order_number, customer_name, total, order_status, payment_status, created_at
     FROM orders ORDER BY created_at DESC LIMIT 8'
)->fetchAll();

$recentProducts = $db->query(
    'SELECT p.id, p.name, p.sku, p.price, p.sale_price, p.stock_quantity, p.status, p.created_at, pi.image AS primary_image
     FROM products p
     LEFT JOIN product_images pi ON pi.product_id = p.id AND pi.is_primary = 1
     ORDER BY p.created_at DESC LIMIT 6'
)->fetchAll();

$page_title = 'Dashboard';
$active     = 'dashboard';

ob_start();
?>

<div class="page-header">
    <div>
        <h1>Welcome back, <?= e($admin['name']) ?> 👋</h1>
        <p>Here's what's happening at <?= e(setting('store_name', 'TayyabaCollective')) ?> today.</p>
    </div>
    <div class="page-actions">
        <a href="<?= url('/admin/product-form.php') ?>" class="btn btn-accent"><i class="fa-solid fa-plus"></i> Add Product</a>
        <a href="<?= url('/admin/orders.php') ?>" class="btn btn-outline"><i class="fa-solid fa-receipt"></i> View Orders</a>
    </div>
</div>

<div class="stat-grid">
    <div class="stat-card">
        <div class="stat-icon gold"><i class="fa-solid fa-shirt"></i></div>
        <div>
            <div class="stat-value"><?= (int) $stats['products'] ?></div>
            <div class="stat-label">Total Products (<?= (int) $stats['active_products'] ?> active)</div>
        </div>
    </div>
    <div class="stat-card">
        <div class="stat-icon red"><i class="fa-solid fa-box-open"></i></div>
        <div>
            <div class="stat-value"><?= (int) $stats['out_of_stock'] ?></div>
            <div class="stat-label">Out of Stock</div>
        </div>
    </div>
    <div class="stat-card">
        <div class="stat-icon blue"><i class="fa-solid fa-table-cells-large"></i></div>
        <div>
            <div class="stat-value"><?= (int) $stats['categories'] ?></div>
            <div class="stat-label">Active Categories</div>
        </div>
    </div>
    <div class="stat-card">
        <div class="stat-icon green"><i class="fa-solid fa-receipt"></i></div>
        <div>
            <div class="stat-value"><?= (int) $stats['orders'] ?></div>
            <div class="stat-label">Total Orders (<?= (int) $stats['pending_orders'] ?> pending)</div>
        </div>
    </div>
    <div class="stat-card">
        <div class="stat-icon green"><i class="fa-solid fa-circle-check"></i></div>
        <div>
            <div class="stat-value"><?= (int) $stats['completed_orders'] ?></div>
            <div class="stat-label">Delivered / Shipped</div>
        </div>
    </div>
    <div class="stat-card">
        <div class="stat-icon gold"><i class="fa-solid fa-users"></i></div>
        <div>
            <div class="stat-value"><?= (int) $stats['customers'] ?></div>
            <div class="stat-label">Customers</div>
        </div>
    </div>
    <div class="stat-card">
        <div class="stat-icon blue"><i class="fa-solid fa-sack-dollar"></i></div>
        <div>
            <div class="stat-value"><?= money((float) $revenue) ?></div>
            <div class="stat-label">Revenue (excl. cancelled)</div>
        </div>
    </div>
</div>

<div class="detail-grid">
    <div>
        <div class="card">
            <div class="card-title">Recent Orders <a href="<?= url('/admin/orders.php') ?>">View all →</a></div>
            <div class="table-wrap">
                <table class="admin-table">
                    <thead>
                        <tr>
                            <th>Order</th>
                            <th>Customer</th>
                            <th>Total</th>
                            <th>Status</th>
                            <th>Date</th>
                        </tr>
                    </thead>
                    <tbody>
                        <?php if (!$recentOrders): ?>
                            <tr><td colspan="5" style="text-align:center;color:var(--admin-muted)">No orders yet.</td></tr>
                        <?php endif; ?>
                        <?php foreach ($recentOrders as $o): ?>
                            <tr>
                                <td><a href="<?= url('/admin/orders.php?id=' . (int) $o['id']) ?>"><strong><?= e($o['order_number']) ?></strong></a></td>
                                <td><?= e($o['customer_name']) ?></td>
                                <td><?= money((float) $o['total']) ?></td>
                                <td><span class="badge <?= e(order_status_color($o['order_status'])) ?>"><?= e(ucfirst($o['order_status'])) ?></span></td>
                                <td><?= e(format_date($o['created_at'])) ?></td>
                            </tr>
                        <?php endforeach; ?>
                    </tbody>
                </table>
            </div>
        </div>
    </div>

    <div>
        <div class="card">
            <div class="card-title">Low Stock Alerts <a href="<?= url('/admin/products.php?stock=low') ?>">View all →</a></div>
            <?php if (!$lowStock): ?>
                <p style="color:var(--admin-muted)">All products are well stocked. 🎉</p>
            <?php endif; ?>
            <?php foreach ($lowStock as $p): ?>
                <div style="display:flex;align-items:center;gap:12px;padding:9px 0;border-bottom:1px solid #f0e9e2">
                    <img src="<?= e(image_url($p['primary_image'] ?? '')) ?>" alt="" style="width:38px;height:46px;object-fit:cover;border-radius:6px">
                    <div style="flex:1;min-width:0">
                        <div style="font-weight:600;font-size:13px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap"><?= e($p['name']) ?></div>
                        <div style="font-size:12px;color:var(--admin-muted)"><?= e($p['sku']) ?></div>
                    </div>
                    <span class="badge <?= (int) $p['stock_quantity'] < 1 ? 'red' : 'gold' ?>">
                        <?= (int) $p['stock_quantity'] < 1 ? 'Out' : (int) $p['stock_quantity'] . ' left' ?>
                    </span>
                </div>
            <?php endforeach; ?>
        </div>

        <div class="card">
            <div class="card-title">Recent Products <a href="<?= url('/admin/products.php') ?>">View all →</a></div>
            <?php if (!$recentProducts): ?>
                <p style="color:var(--admin-muted)">No products yet — <a href="<?= url('/admin/product-form.php') ?>">add your first one</a>.</p>
            <?php endif; ?>
            <?php foreach ($recentProducts as $p): ?>
                <div style="display:flex;align-items:center;gap:12px;padding:8px 0;border-bottom:1px solid #f0e9e2">
                    <img src="<?= e(image_url($p['primary_image'] ?? '')) ?>" alt="" style="width:38px;height:46px;object-fit:cover;border-radius:6px">
                    <div style="flex:1;min-width:0">
                        <div style="font-weight:600;font-size:13px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap"><?= e($p['name']) ?></div>
                        <div style="font-size:12px;color:var(--admin-muted)"><?= e(format_date($p['created_at'])) ?></div>
                    </div>
                    <span class="badge <?= (int) $p['status'] === 1 ? 'green' : 'gray' ?>"><?= (int) $p['status'] === 1 ? 'Active' : 'Inactive' ?></span>
                </div>
            <?php endforeach; ?>
        </div>
    </div>
</div>

<?php
$content = ob_get_clean();
require __DIR__ . '/layout.php';