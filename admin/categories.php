<?php
declare(strict_types=1);
require_once __DIR__ . '/../includes/bootstrap.php';

$admin = require_admin();
$db = db();

/* ---------------------------------------------------------------------------
   POST handlers
--------------------------------------------------------------------------- */
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    csrf_require($_POST['csrf_token'] ?? null);
    $action = post('action', 30);

    /* ---------------- save (create / update) ---------------- */
    if ($action === 'save') {
        $id          = post_int('id');
        $name        = post('name', 150);
        $slug        = post('slug', 170);
        $description = post('description', 500);
        $parentId    = post_int('parent_id');
        $status      = !empty($_POST['status']) ? 1 : 0;
        $showInNav   = !empty($_POST['show_in_nav']) ? 1 : 0;
        $sortOrder   = post_int('sort_order');

        $errors = [];
        if ($name === '') $errors[] = 'Category name is required.';
        if ($slug === '') $slug = slugify($name);
        else $slug = slugify($slug);

        if (!$errors) {
            $chk = $db->prepare('SELECT id FROM categories WHERE slug = ? AND id <> ? LIMIT 1');
            $chk->execute([$slug, $id]);
            if ($chk->fetch()) $errors[] = 'A category with this slug already exists.';
        }

        if (!$errors) {
            /* Handle image upload (optional on edit; required-ish on create) */
            $imagePath = null;
            if (!empty($_FILES['image']['name'])) {
                $result = upload_image($_FILES['image'], 'categories');
                if ($result['success']) $imagePath = $result['path'];
                else $errors[] = $result['error'];
            }

            if (!$errors) {
                if ($id > 0) {
                    if ($imagePath) {
                        $stmt = $db->prepare('UPDATE categories SET name=?, slug=?, description=?, parent_id=?, image=?, status=?, show_in_nav=?, sort_order=? WHERE id=?');
                        $stmt->execute([$name, $slug, $description, $parentId ?: null, $imagePath, $status, $showInNav, $sortOrder, $id]);
                    } else {
                        $stmt = $db->prepare('UPDATE categories SET name=?, slug=?, description=?, parent_id=?, status=?, show_in_nav=?, sort_order=? WHERE id=?');
                        $stmt->execute([$name, $slug, $description, $parentId ?: null, $status, $showInNav, $sortOrder, $id]);
                    }
                    record_activity('category_update', 'category', $id, 'Updated category "' . $name . '"');
                    flash_set('success', 'Category updated.');
                } else {
                    $stmt = $db->prepare(
                        'INSERT INTO categories (name, slug, description, parent_id, image, status, show_in_nav, sort_order)
                         VALUES (?, ?, ?, ?, ?, ?, ?, ?)'
                    );
                    $stmt->execute([$name, $slug, $description, $parentId ?: null, $imagePath, $status, $showInNav, $sortOrder]);
                    $newId = (int) $db->lastInsertId();
                    record_activity('category_create', 'category', $newId, 'Created category "' . $name . '"');
                    flash_set('success', 'Category "' . $name . '" created — it is now available on the storefront.');
                }
                redirect(url('/admin/categories.php'));
            }
        }

        foreach ($errors as $err) flash_set('error', $err);
        redirect(url('/admin/categories.php'));
    }

    /* ---------------- toggle status ---------------- */
    if (in_array($action, ['activate', 'deactivate'], true)) {
        $id = post_int('id');
        $newStatus = $action === 'activate' ? 1 : 0;
        db()->prepare('UPDATE categories SET status = ? WHERE id = ?')->execute([$newStatus, $id]);
        record_activity('category_' . $action, 'category', $id, ($newStatus ? 'Activated' : 'Deactivated') . ' category');
        flash_set('success', 'Category ' . ($newStatus ? 'activated' : 'deactivated') . '.');
        redirect(url('/admin/categories.php'));
    }

    /* ---------------- delete (only when unused) ---------------- */
    if ($action === 'delete') {
        $id = post_int('id');
        $linked = (int) db()->prepare('SELECT COUNT(*) FROM product_categories WHERE category_id = ?')->execute([$id]);
        $countStmt = db()->prepare('SELECT COUNT(*) FROM product_categories WHERE category_id = ?');
        $countStmt->execute([$id]);
        $linked = (int) $countStmt->fetchColumn();

        if ($linked > 0) {
            flash_set('error', 'This category has ' . $linked . ' product(s) linked. Deactivate it instead, or remove the links first.');
        } else {
            $img = db()->prepare('SELECT image FROM categories WHERE id = ?');
            $img->execute([$id]);
            $row = $img->fetch();
            if ($row && $row['image']) delete_uploaded_file($row['image']);
            db()->prepare('DELETE FROM categories WHERE id = ?')->execute([$id]);
            record_activity('category_delete', 'category', $id, 'Deleted category');
            flash_set('success', 'Category deleted.');
        }
        redirect(url('/admin/categories.php'));
    }
}

/* ---------------------------------------------------------------------------
   View
--------------------------------------------------------------------------- */
$categories = $db->query(
    'SELECT c.*, p.name AS parent_name,
            (SELECT COUNT(*) FROM product_categories pc JOIN products pr ON pr.id = pc.product_id AND pr.status = 1 WHERE pc.category_id = c.id) AS product_count
     FROM categories c
     LEFT JOIN categories p ON p.id = c.parent_id
     ORDER BY c.sort_order ASC, c.name ASC'
)->fetchAll();

$categoryOptions = '';
foreach ($categories as $c) {
    $categoryOptions .= '<option value="' . (int) $c['id'] . '">' . e($c['name']) . '</option>';
}

$page_title = 'Categories';
$active     = 'categories';

ob_start();
?>

<div class="page-header">
    <div>
        <h1>Categories</h1>
        <p>New categories automatically appear in the storefront collections and navigation.</p>
    </div>
</div>

<div class="detail-grid">
    <div class="card">
        <div class="card-title">All Categories (<?= count($categories) ?>)</div>
        <div class="table-wrap">
            <table class="admin-table">
                <thead>
                    <tr>
                        <th>Category</th>
                        <th>Slug</th>
                        <th>Parent</th>
                        <th>Products</th>
                        <th>Nav</th>
                        <th>Order</th>
                        <th>Status</th>
                        <th style="text-align:right">Actions</th>
                    </tr>
                </thead>
                <tbody>
                    <?php if (!$categories): ?>
                        <tr><td colspan="8" style="text-align:center;color:var(--admin-muted);padding:36px">No categories yet — create your first one on the right.</td></tr>
                    <?php endif; ?>
                    <?php foreach ($categories as $c): ?>
                        <tr>
                            <td>
                                <div class="prod-cell">
                                    <?php if ($c['image']): ?>
                                        <img class="table-img" src="<?= e(image_url($c['image'])) ?>" alt="" style="width:46px;height:38px">
                                    <?php else: ?>
                                        <div class="table-img" style="width:46px;height:38px;background:#f0ece8;display:flex;align-items:center;justify-content:center;color:var(--admin-muted)"><i class="fa-solid fa-image"></i></div>
                                    <?php endif; ?>
                                    <strong><?= e($c['name']) ?></strong>
                                </div>
                            </td>
                            <td>/category/<?= e($c['slug']) ?></td>
                            <td><?= e($c['parent_name'] ?? '—') ?></td>
                            <td><?= (int) $c['product_count'] ?></td>
                            <td><?= (int) $c['show_in_nav'] === 1 ? '✓' : '—' ?></td>
                            <td><?= (int) $c['sort_order'] ?></td>
                            <td>
                                <span class="badge <?= (int) $c['status'] === 1 ? 'green' : 'gray' ?>">
                                    <?= (int) $c['status'] === 1 ? 'Active' : 'Inactive' ?>
                                </span>
                            </td>
                            <td style="text-align:right;white-space:nowrap">
                                <a class="btn btn-outline btn-xs" href="#cat-<?= (int) $c['id'] ?>">Edit</a>
                                <?php if ((int) $c['status'] === 1): ?>
                                    <form method="post" style="display:inline">
                                        <?= csrf_field() ?>
                                        <input type="hidden" name="action" value="deactivate">
                                        <input type="hidden" name="id" value="<?= (int) $c['id'] ?>">
                                        <button class="btn btn-outline btn-xs">Deactivate</button>
                                    </form>
                                <?php else: ?>
                                    <form method="post" style="display:inline">
                                        <?= csrf_field() ?>
                                        <input type="hidden" name="action" value="activate">
                                        <input type="hidden" name="id" value="<?= (int) $c['id'] ?>">
                                        <button class="btn btn-outline btn-xs">Restore</button>
                                    </form>
                                <?php endif; ?>
                                <form method="post" style="display:inline" onsubmit="return confirm('Delete this category permanently?')">
                                    <?= csrf_field() ?>
                                    <input type="hidden" name="action" value="delete">
                                    <input type="hidden" name="id" value="<?= (int) $c['id'] ?>">
                                    <button class="btn btn-danger btn-xs"><i class="fa-solid fa-trash"></i></button>
                                </form>
                            </td>
                        </tr>
                    <?php endforeach; ?>
                </tbody>
            </table>
        </div>
    </div>

    <div>
        <!-- ADD / EDIT FORM -->
        <?php $editId = (int) ($_GET['edit'] ?? 0); ?>
        <?php
        $editCat = null;
        if ($editId > 0) {
            $st = $db->prepare('SELECT * FROM categories WHERE id = ?');
            $st->execute([$editId]);
            $editCat = $st->fetch();
        }
        ?>
        <div class="card">
            <div class="card-title" id="cat-form-title"><?= $editCat ? 'Edit Category' : 'Add Category' ?></div>
            <?php if ($editCat): ?>
                <a href="<?= url('/admin/categories.php') ?>" style="font-size:12.5px;display:block;margin-bottom:12px">← Cancel editing</a>
            <?php endif; ?>

            <form method="post" enctype="multipart/form-data" action="<?= e(url('/admin/categories.php')) ?>">
                <?= csrf_field() ?>
                <input type="hidden" name="action" value="save">
                <input type="hidden" name="id" value="<?= (int) ($editCat['id'] ?? 0) ?>">

                <div class="form-group">
                    <label for="cat-name">Name <span class="required">*</span></label>
                    <input type="text" id="cat-name" name="name" value="<?= e($editCat['name'] ?? '') ?>" required>
                </div>
                <div class="form-group">
                    <label for="cat-slug">Slug</label>
                    <input type="text" id="cat-slug" name="slug" placeholder="auto-generated" value="<?= e($editCat['slug'] ?? '') ?>">
                    <p class="help">Used in the URL: /category/your-slug</p>
                </div>
                <div class="form-group">
                    <label for="cat-desc">Description</label>
                    <input type="text" id="cat-desc" name="description" maxlength="500" value="<?= e($editCat['description'] ?? '') ?>">
                </div>
                <div class="form-group">
                    <label for="cat-parent">Parent Category</label>
                    <select id="cat-parent" name="parent_id">
                        <option value="0">— None —</option>
                        <?php foreach ($categories as $c): ?>
                            <?php if ($editCat && (int) $c['id'] === (int) $editCat['id']) continue; ?>
                            <option value="<?= (int) $c['id'] ?>" <?= (int) ($editCat['parent_id'] ?? 0) === (int) $c['id'] ? 'selected' : '' ?>>
                                <?= e($c['name']) ?>
                            </option>
                        <?php endforeach; ?>
                    </select>
                </div>
                <div class="form-grid">
                    <div class="form-group">
                        <label for="cat-image">Image</label>
                        <input type="file" id="cat-image" name="image" accept="image/jpeg,image/png,image/webp,image/gif">
                        <?php if ($editCat && $editCat['image']): ?>
                            <p class="help">Current: <img src="<?= e(image_url($editCat['image'])) ?>" alt="" style="height:40px;border-radius:4px;vertical-align:middle"> Upload replaces it.</p>
                        <?php endif; ?>
                    </div>
                    <div class="form-group">
                        <label for="cat-order">Sort Order</label>
                        <input type="number" id="cat-order" name="sort_order" min="0" value="<?= e((string) ($editCat['sort_order'] ?? 0)) ?>">
                    </div>
                </div>
                <div class="checkbox-line">
                    <input type="checkbox" id="cat-status" name="status" value="1" <?= !isset($editCat['status']) || (int) $editCat['status'] === 1 ? 'checked' : '' ?>>
                    <label for="cat-status">Active (visible on storefront)</label>
                </div>
                <div class="checkbox-line">
                    <input type="checkbox" id="cat-nav" name="show_in_nav" value="1" <?= !empty($editCat['show_in_nav']) ? 'checked' : '' ?>>
                    <label for="cat-nav">Show in navigation dropdown</label>
                </div>
                <button type="submit" class="btn btn-primary" style="width:100%">
                    <i class="fa-solid fa-floppy-disk"></i> <?= $editCat ? 'Save Changes' : 'Create Category' ?>
                </button>
            </form>
        </div>
    </div>
</div>

<?php
$content = ob_get_clean();
require __DIR__ . '/layout.php';