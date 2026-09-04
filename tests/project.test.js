'use strict';

const { test } = require('node:test');
const assert = require('node:assert');
const fs = require('node:fs');
const path = require('node:path');
const { execFileSync } = require('node:child_process');

const ROOT = path.resolve(__dirname, '..');

function allFiles(dir, ext, out = []) {
    for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
        if (entry.name === '.git' || entry.name === 'node_modules') continue;
        const full = path.join(dir, entry.name);
        if (entry.isDirectory()) allFiles(full, ext, out);
        else if (ext === null || full.endsWith(ext)) out.push(full);
    }
    return out;
}

test('every PHP file passes php -l', () => {
    const php = process.env.PHP_BIN || 'php';
    const files = allFiles(ROOT, '.php');
    assert.ok(files.length >= 30, `expected many PHP files, found ${files.length}`);

    for (const file of files) {
        const rel = path.relative(ROOT, file);
        try {
            execFileSync(php, ['-l', file], { stdio: 'pipe' });
        } catch (err) {
            assert.fail(`php -l failed for ${rel}:\n${err.stderr}`);
        }
    }
});

test('required project structure exists', () => {
    const required = [
        'database.sql',
        'config/config.example.php',
        'includes/bootstrap.php',
        'includes/db.php',
        'includes/auth.php',
        'includes/csrf.php',
        'includes/cart.php',
        'includes/product-functions.php',
        'includes/settings.php',
        'includes/uploads.php',
        'includes/storefront-header.php',
        'includes/storefront-footer.php',
        'index.php',
        'shop.php',
        'product.php',
        'category.php',
        'collections.php',
        'cart.php',
        'checkout.php',
        'order-confirmation.php',
        'contact.php',
        'about.php',
        '404.php',
        '403.php',
        '500.php',
        '.htaccess',
        'assets/js/site.js',
        'assets/css/admin.css',
        'css/dynamic.css',
        'admin/login.php',
        'admin/index.php',
        'admin/products.php',
        'admin/product-form.php',
        'admin/categories.php',
        'admin/orders.php',
        'admin/customers.php',
        'admin/subscribers.php',
        'admin/messages.php',
        'admin/reports.php',
        'admin/settings.php',
        'admin/profile.php',
        'admin/activity.php',
        'api/cart.php',
        'api/newsletter.php',
    ];
    for (const rel of required) {
        assert.ok(fs.existsSync(path.join(ROOT, rel)), `missing required file: ${rel}`);
    }
});

test('database.sql defines all core tables', () => {
    const sql = fs.readFileSync(path.join(ROOT, 'database.sql'), 'utf8');
    const tables = [
        'admins', 'categories', 'products', 'product_images',
        'product_variants', 'product_categories', 'orders', 'order_items',
        'customers', 'subscribers', 'contact_messages', 'admin_activity_logs',
        'login_attempts', 'settings',
    ];
    for (const t of tables) {
        assert.ok(sql.includes(`CREATE TABLE \`${t}\``), `missing table: ${t}`);
    }
});

test('database.sql seeds 120 products, 480 images and a hashed admin password', () => {
    const sql = fs.readFileSync(path.join(ROOT, 'database.sql'), 'utf8');

    assert.strictEqual((sql.match(/INSERT INTO `products` /g) || []).length, 120, '120 migrated products');
    assert.strictEqual((sql.match(/INSERT INTO `product_images` /g) || []).length, 480, '480 product images');
    assert.ok(sql.includes("'Areeba Floral Lawn Set'"), 'a migrated product name is present');
    assert.ok(sql.includes("'admin@tayyabacollective.mytechrcm.com'"), 'admin seed email present');

    // The seeded admin password must be a bcrypt hash, never the plain text.
    assert.ok(sql.includes('INSERT INTO `admins`'), 'admin seed present');
    assert.ok(sql.includes('$2y$10$'), 'admin password stored as a bcrypt ($2y$) hash');
    assert.ok(!sql.includes('TC_Admin@2026#Secure'), 'plaintext admin password must never appear in database.sql');
});

test('storefront templates do not hardcode product names or categories', () => {
    // Names/categories that existed on the old static site must now come from MySQL.
    const hardcoded = ['Classic Embroidered Suit', 'Premium Lawn Collection', 'Elegant Formal Wear'];
    const templates = [
        'index.php', 'shop.php', 'product.php', 'collections.php', 'category.php',
        'includes/storefront-header.php', 'includes/storefront-footer.php',
    ];
    for (const tpl of templates) {
        const src = fs.readFileSync(path.join(ROOT, tpl), 'utf8');
        for (const name of hardcoded) {
            assert.ok(!src.includes(name), `${tpl} must not hardcode "${name}"`);
        }
        assert.ok(!src.includes('data.js'), `${tpl} must not reference the obsolete js/data.js`);
    }
});

test('old static demo files have been removed', () => {
    for (const f of [
        'index.html', 'shop.html', 'product.html', 'categories.html',
        'cart.html', 'checkout.html', 'order-confirmation.html',
        'contact.html', 'about.html', 'admin.html', 'upload-dress.htm',
        'js/data.js', 'js/main.js',
    ]) {
        assert.ok(!fs.existsSync(path.join(ROOT, f)), `obsolete file still present: ${f}`);
    }
});
