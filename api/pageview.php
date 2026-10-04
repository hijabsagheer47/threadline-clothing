<?php
declare(strict_types=1);
require_once __DIR__ . '/../includes/bootstrap.php';

header('Content-Type: application/json; charset=utf-8');
header('Cache-Control: no-store, max-age=0');

/*
 * First-party pageview beacon.
 * Accepts POST JSON {path, referrer} (navigator.sendBeacon with a Blob).
 * Privacy: stores the path without query string, an external referrer only,
 * a hashed session id (never the raw cookie) and a device class — no raw UA.
 */

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['ok' => false, 'error' => 'Method not allowed.']);
    exit;
}

/* Reject cross-site posts (Origin, when present, must match this host). */
$origin = $_SERVER['HTTP_ORIGIN'] ?? '';
if ($origin !== '') {
    $originHost = parse_url($origin, PHP_URL_HOST);
    $reqHost = $_SERVER['HTTP_HOST'] ?? '';
    $reqHostNoPort = preg_replace('/:\d+$/', '', $reqHost);
    if ($originHost === null || strcasecmp((string)$originHost, (string)$reqHostNoPort) !== 0) {
        http_response_code(403);
        echo json_encode(['ok' => false, 'error' => 'Forbidden.']);
        exit;
    }
}

$raw = file_get_contents('php://input') ?: '';
$in = json_decode($raw, true);
if (!is_array($in)) {
    $in = [];
}

/* --- path: storefront path + slug-style params only (never search terms) --- */
$raw_path = isset($in['path']) && is_string($in['path']) ? $in['path'] : '';
$pathOnly = parse_url($raw_path, PHP_URL_PATH);
$pathOnly = is_string($pathOnly) && $pathOnly !== '' ? $pathOnly : '/index.php';

$queryKeep = '';
$qPos = strpos($raw_path, '?');
if ($qPos !== false) {
    parse_str(substr($raw_path, $qPos + 1), $qin);
    $keep = [];
    foreach (['slug', 'id', 'sort', 'sale', 'collection'] as $k) {
        if (!isset($qin[$k]) || !is_string($qin[$k])) continue;
        $v = preg_replace('/[^A-Za-z0-9._-]/', '', $qin[$k]);
        if ($v !== '' && strlen($v) <= 120) $keep[$k] = $v;
    }
    if ($keep) $queryKeep = '?' . http_build_query($keep);
}
$path = '/' . ltrim($pathOnly, '/') . $queryKeep;
if ($path === '/' || !preg_match('#^/[A-Za-z0-9._/?=&-]{0,499}$#', $path)) {
    $path = '/index.php';
}

/* Normalize: strip the app base path (site may live in a subdirectory). */
$basePath = (string) (parse_url((string) BASE_URL, PHP_URL_PATH) ?: '');
if ($basePath !== '' && $basePath !== '/' && strpos($path, $basePath) === 0) {
    $path = substr($path, strlen($basePath));
    if ($path === '' || $path === false) $path = '/';
    if ($path[0] !== '/') $path = '/' . $path;
    if ($path === '/') $path = '/index.php';
}
if (strpos($path, '/admin/') === 0 || $path === '/admin') {
    echo json_encode(['ok' => true, 'recorded' => false]);
    exit;
}
if (!tc_table_exists('page_views')) {
    echo json_encode(['ok' => true, 'recorded' => false]);
    exit;
}

/* --- page type (for the dashboard) --- */
$base = strtolower((string)basename((string)parse_url($path, PHP_URL_PATH)));
$pageType = 'other';
if ($base === 'index.php' || $path === '/') $pageType = 'home';
elseif ($base === 'shop.php') $pageType = 'shop';
elseif ($base === 'category.php') $pageType = 'category';
elseif ($base === 'product.php') $pageType = 'product';
elseif ($base === 'cart.php') $pageType = 'cart';
elseif ($base === 'checkout.php') $pageType = 'checkout';
elseif ($base === 'collections.php') $pageType = 'collection';
elseif ($base === 'journal.php' || $base === 'journal-article.php') $pageType = 'journal';
elseif (in_array($base, ['contact.php', 'about.php', 'wishlist.php', 'search.php'], true)) $pageType = 'static';

/* --- session: first-party cookie, only its hash is stored --- */
$sid = $_COOKIE['fl_sid'] ?? '';
if (!preg_match('/^[a-f0-9]{32}$/', $sid)) {
    $sid = bin2hex(random_bytes(16));
    setcookie('fl_sid', $sid, [
        'expires'  => time() + 86400 * 365,
        'path'     => '/',
        'samesite' => 'Lax',
        'httponly' => true,
        'secure'   => !empty($_SERVER['HTTPS']),
    ]);
}
$sessionHash = hash('sha256', $sid . '|fashlab-pv');

/* --- device class from UA family only (raw UA is never stored) --- */
$ua = strtolower($_SERVER['HTTP_USER_AGENT'] ?? '');
$device = 'desktop';
if (preg_match('/ipad|tablet|playbook|silk|(android(?!.*mobile))|kindle|sch-i/', $ua)) {
    $device = 'tablet';
} elseif (preg_match('/mobi|iphone|ipod|android.*mobile|windows phone/', $ua)) {
    $device = 'mobile';
}

/* --- referrer: external only; internal navigation is not a referrer --- */
$referrer = null;
$ref = isset($in['referrer']) && is_string($in['referrer']) ? $in['referrer'] : ($_SERVER['HTTP_REFERER'] ?? '');
if ($ref !== '' && preg_match('#^https?://#i', $ref)) {
    $refHost = parse_url($ref, PHP_URL_HOST);
    $selfHost = preg_replace('/^www\./', '', strtolower((string)preg_replace('/:\d+$/', '', $_SERVER['HTTP_HOST'] ?? '')));
    $refHostNorm = preg_replace('/^www\./', '', strtolower((string)$refHost));
    $isInternal = $refHostNorm !== '' && $refHostNorm === $selfHost;
    if (!$isInternal) {
        $referrer = mb_substr($ref, 0, 500);
    }
}

try {
    $db = db();
    $stmt = $db->prepare(
        'INSERT INTO page_views (session_hash, path, page_type, referrer, device, created_at)
         VALUES (?, ?, ?, ?, ?, NOW())'
    );
    $stmt->execute([$sessionHash, mb_substr($path, 0, 500), $pageType, $referrer, $device]);
    echo json_encode(['ok' => true, 'recorded' => true]);
} catch (Throwable $e) {
    /* Never break the page because analytics failed. */
    error_log('[pageview] ' . $e->getMessage());
    echo json_encode(['ok' => true, 'recorded' => false]);
}
