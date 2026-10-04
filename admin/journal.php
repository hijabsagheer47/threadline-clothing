<?php
declare(strict_types=1);
require_once __DIR__ . '/../includes/bootstrap.php';

$admin = require_admin();
$db = db();

if (!tc_table_exists('journal_posts')) {
    http_response_code(500);
    exit('journal_posts table is missing. Run migration-fashlab-upgrade.sql first.');
}
$hasCats = tc_table_exists('journal_categories');

/* ------------------------------------------------------------- POST handler */
if (($_SERVER['REQUEST_METHOD'] ?? 'GET') === 'POST') {
    csrf_require($_POST['csrf_token'] ?? null);
    $action = post('action', 20);

    if ($action === 'delete') {
        $id = (int) ($_POST['id'] ?? 0);
        if ($id > 0) {
            $stmt = $db->prepare('DELETE FROM journal_posts WHERE id = ?');
            $stmt->execute([$id]);
            flash_set('success', 'Article deleted.');
        }
        redirect(url('/admin/journal.php'));
    }

    if ($action === 'save') {
        $id         = (int) ($_POST['id'] ?? 0);
        $title      = post('title', 190);
        $slug       = strtolower(preg_replace('/[^a-z0-9\-]/', '', post('slug', 220)) ?? '');
        $categoryId = (int) ($_POST['category_id'] ?? 0) ?: null;
        $excerpt    = post('excerpt', 500);
        $contentRaw = (string) ($_POST['content'] ?? '');
        $status     = in_array($_POST['status'] ?? '', ['draft', 'published', 'archived'], true) ? $_POST['status'] : 'draft';
        $publishedAt = post('published_at', 19);
        $author     = post('author', 150);
        $image      = post('image', 255);
        $metaTitle  = post('meta_title', 200);
        $metaDesc   = post('meta_description', 500);

        $errors = [];
        if ($title === '')  $errors[] = 'A title is required.';
        if ($contentRaw === '') $errors[] = 'The article body cannot be empty.';

        if ($slug === '' && $title !== '') {
            $slug = slugify($title);
        }

        /* Unique slug (excluding this post). */
        if ($slug !== '') {
            $stmt = $db->prepare('SELECT id FROM journal_posts WHERE slug = ? AND id <> ? LIMIT 1');
            $stmt->execute([$slug, $id]);
            if ($stmt->fetch()) {
                $base = $slug;
                $n = 2;
                do {
                    $slug = $base . '-' . $n++;
                    $stmt->execute([$slug, $id]);
                } while ($stmt->fetch());
            }
        }

        /* Body: keep HTML when the author wrote HTML, otherwise paragraphs. */
        $content = $contentRaw;
        if (stripos($contentRaw, '<p') === false && stripos($contentRaw, '<h') === false) {
            $paras = preg_split('/\n{2,}/', trim($contentRaw));
            $content = '';
            foreach ((array) $paras as $para) {
                $para = trim($para);
                if ($para === '') continue;
                $content .= '<p>' . nl2br(e($para)) . "</p>\n";
            }
        }

        if ($publishedAt !== '' && !preg_match('/^\d{4}-\d{2}-\d{2}( \d{2}:\d{2})?$/', $publishedAt)) {
            $publishedAt = '';
        }
        if ($publishedAt !== '' && strlen($publishedAt) === 10) {
            $publishedAt .= ' 00:00';
        }
        if ($status === 'published' && $publishedAt === '') {
            $publishedAt = date('Y-m-d H:i:s');
        }

        if (!$errors) {
            try {
                if ($id > 0) {
                    $stmt = $db->prepare(
                        'UPDATE journal_posts SET category_id=?, title=?, slug=?, excerpt=?, content=?, image=?,
                                author=?, status=?, published_at=?, meta_title=?, meta_description=? WHERE id=?'
                    );
                    $stmt->execute([$categoryId, $title, $slug, $excerpt, $content, $image, $author,
                        $status, $publishedAt ?: null, $metaTitle, $metaDesc, $id]);
                    flash_set('success', 'Article updated.');
                } else {
                    $stmt = $db->prepare(
                        'INSERT INTO journal_posts (category_id, title, slug, excerpt, content, image, author,
                                status, published_at, meta_title, meta_description)
                         VALUES (?,?,?,?,?,?,?,?,?,?,?)'
                    );
                    $stmt->execute([$categoryId, $title, $slug, $excerpt, $content, $image, $author,
                        $status, $publishedAt ?: null, $metaTitle, $metaDesc]);
                    flash_set('success', 'Article created.');
                }
                redirect(url('/admin/journal.php'));
            } catch (PDOException $ex) {
                error_log('[journal] ' . $ex->getMessage());
                $errors[] = 'Could not save the article. Check that the slug is unique.';
            }
        }
    }
}

/* -------------------------------------------------------------- GET state */
$editId = (int) (get_string('edit', 6) ?: 0);
$post = null;
if ($editId > 0) {
    $stmt = $db->prepare('SELECT * FROM journal_posts WHERE id = ?');
    $stmt->execute([$editId]);
    $post = $stmt->fetch() ?: null;
}
$newPost = (get_string('new', 3) !== '');

$posts = $db->query(
    "SELECT p.*, c.name AS category_name
     FROM journal_posts p
     LEFT JOIN journal_categories c ON c.id = p.category_id
     ORDER BY COALESCE(p.published_at, p.created_at) DESC"
)->fetchAll();

$cats = $hasCats
    ? $db->query('SELECT id, name FROM journal_categories WHERE status = 1 ORDER BY sort_order, name')->fetchAll()
    : [];

$page_title = 'Style Journal';
$active     = 'journal';

ob_start();
?>

<div class="page-header">
    <div>
        <h1>Style Journal</h1>
        <p>Editorial articles for the storefront journal — written and published by you.</p>
    </div>
    <a href="<?= e(url('/admin/journal.php?new=1')) ?>" class="btn btn-primary"><i class="fa-solid fa-plus"></i> New Article</a>
</div>

<?php if (!empty($errors)): ?>
    <div class="admin-flash error"><span><?= e(implode(' ', $errors)) ?></span></div>
<?php endif; ?>

<?php if ($post || $newPost): ?>
    <?php $p = $post ?: []; ?>
    <div class="card" style="margin-bottom:26px">
        <h2 style="margin-bottom:16px"><?= $post ? 'Edit Article' : 'New Article' ?></h2>
        <form method="post" action="<?= e(url('/admin/journal.php')) ?>">
            <?= csrf_field() ?>
            <input type="hidden" name="action" value="save">
            <input type="hidden" name="id" value="<?= (int) ($p['id'] ?? 0) ?>">

            <div style="display:grid;grid-template-columns:1fr 1fr;gap:14px">
                <div class="form-group" style="grid-column:1/-1">
                    <label for="j-title">Title *</label>
                    <input type="text" id="j-title" name="title" maxlength="190" required
                           value="<?= e($p['title'] ?? '') ?>">
                </div>
                <div class="form-group">
                    <label for="j-slug">Slug (leave blank to auto-generate)</label>
                    <input type="text" id="j-slug" name="slug" maxlength="220"
                           value="<?= e($p['slug'] ?? '') ?>" placeholder="how-to-style-a-lawn-kurta">
                </div>
                <div class="form-group">
                    <label for="j-cat">Category</label>
                    <select id="j-cat" name="category_id">
                        <option value="0">— None —</option>
                        <?php foreach ($cats as $c): ?>
                            <option value="<?= (int) $c['id'] ?>" <?= (int) ($p['category_id'] ?? 0) === (int) $c['id'] ? 'selected' : '' ?>><?= e($c['name']) ?></option>
                        <?php endforeach; ?>
                    </select>
                </div>
                <div class="form-group" style="grid-column:1/-1">
                    <label for="j-excerpt">Excerpt (shown on cards &amp; as meta description fallback)</label>
                    <textarea id="j-excerpt" name="excerpt" rows="2" maxlength="500"><?= e($p['excerpt'] ?? '') ?></textarea>
                </div>
                <div class="form-group" style="grid-column:1/-1">
                    <label for="j-content">Content * — plain text or HTML; blank lines become paragraphs</label>
                    <textarea id="j-content" name="content" rows="14" style="font-family:monospace" required><?= e($p['content'] ?? '') ?></textarea>
                </div>
                <div class="form-group">
                    <label for="j-status">Status</label>
                    <select id="j-status" name="status">
                        <?php foreach (['draft' => 'Draft', 'published' => 'Published', 'archived' => 'Archived'] as $sv => $sl): ?>
                            <option value="<?= $sv ?>" <?= ($p['status'] ?? 'draft') === $sv ? 'selected' : '' ?>><?= $sl ?></option>
                        <?php endforeach; ?>
                    </select>
                </div>
                <div class="form-group">
                    <label for="j-pub">Publish date (YYYY-MM-DD or YYYY-MM-DD HH:MM)</label>
                    <input type="text" id="j-pub" name="published_at" maxlength="19"
                           value="<?= e($p['published_at'] ?? date('Y-m-d H:i:s')) ?>">
                </div>
                <div class="form-group">
                    <label for="j-author">Author</label>
                    <input type="text" id="j-author" name="author" maxlength="150"
                           value="<?= e($p['author'] ?? setting('store_name')) ?>">
                </div>
                <div class="form-group">
                    <label for="j-image">Image path (optional, e.g. uploads/journal/foo.jpg)</label>
                    <input type="text" id="j-image" name="image" maxlength="255" value="<?= e($p['image'] ?? '') ?>">
                </div>
                <div class="form-group">
                    <label for="j-meta-t">Meta title (optional override)</label>
                    <input type="text" id="j-meta-t" name="meta_title" maxlength="200" value="<?= e($p['meta_title'] ?? '') ?>">
                </div>
                <div class="form-group">
                    <label for="j-meta-d">Meta description (optional override)</label>
                    <input type="text" id="j-meta-d" name="meta_description" maxlength="500" value="<?= e($p['meta_description'] ?? '') ?>">
                </div>
            </div>

            <div style="margin-top:18px;display:flex;gap:10px">
                <button type="submit" class="btn btn-primary">Save Article</button>
                <a href="<?= e(url('/admin/journal.php')) ?>" class="btn btn-outline">Cancel</a>
                <?php if ($post): ?>
                    <a href="<?= e(url('/journal-article.php?slug=' . rawurlencode((string) $post['slug']))) ?>"
                       class="btn btn-outline" target="_blank" rel="noopener">View live</a>
                <?php endif; ?>
            </div>
        </form>
    </div>
<?php endif; ?>

<div class="card">
    <h2 style="margin-bottom:14px">All Articles (<?= count($posts) ?>)</h2>
    <?php if (!$posts): ?>
        <p style="color:#8d8177">No articles yet. Create the first one above.</p>
    <?php else: ?>
        <div style="overflow-x:auto">
            <table class="admin-table">
                <thead>
                <tr>
                    <th>Title</th><th>Category</th><th>Status</th><th>Published</th><th>Updated</th><th></th>
                </tr>
                </thead>
                <tbody>
                <?php foreach ($posts as $row): ?>
                    <tr>
                        <td>
                            <strong><?= e($row['title']) ?></strong><br>
                            <small style="color:#8d8177">/journal-article.php?slug=<?= e($row['slug']) ?></small>
                        </td>
                        <td><?= e($row['category_name'] ?? '—') ?></td>
                        <td>
                            <span style="padding:3px 10px;border-radius:999px;font-size:12px;<?= $row['status'] === 'published'
                                ? 'background:#e7f4ea;color:#1f7a3d' : 'background:#f4efe7;color:#8d8177' ?>">
                                <?= e(ucfirst($row['status'])) ?>
                            </span>
                        </td>
                        <td><?= e($row['published_at'] ? date('M j, Y', strtotime($row['published_at'])) : '—') ?></td>
                        <td><?= e(date('M j, Y', strtotime($row['updated_at']))) ?></td>
                        <td style="white-space:nowrap">
                            <a href="<?= e(url('/admin/journal.php?edit=' . (int) $row['id'])) ?>" class="btn btn-outline btn-sm">Edit</a>
                            <form method="post" style="display:inline" onsubmit="return confirm('Delete this article permanently?')">
                                <?= csrf_field() ?>
                                <input type="hidden" name="action" value="delete">
                                <input type="hidden" name="id" value="<?= (int) $row['id'] ?>">
                                <button type="submit" class="btn btn-outline btn-sm" style="color:#b3413e;border-color:#e8cfce">Delete</button>
                            </form>
                        </td>
                    </tr>
                <?php endforeach; ?>
                </tbody>
            </table>
        </div>
    <?php endif; ?>
</div>

<?php
$content = ob_get_clean();
require __DIR__ . '/layout.php';
