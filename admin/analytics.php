<?php
declare(strict_types=1);
require_once __DIR__ . '/../includes/bootstrap.php';

$admin = require_admin();
$db = db();

/* ----------------------------------------------------------------- range */
$days = (int) (get_string('days', 3) ?: 14);
if (!in_array($days, [7, 14, 30, 90], true)) {
    $days = 14;
}
$since = date('Y-m-d 00:00:00', strtotime('-' . ($days - 1) . ' days'));

$hasTable = tc_table_exists('page_views');

/* ------------------------------------------------------------------ data */
$stats    = ['views' => 0, 'visitors' => 0];
$daily    = [];   // day => [views, visitors]
$topPages = [];
$topRefs  = [];
$devices  = [];
$direct   = 0;

if ($hasTable) {
    $stmt = $db->prepare(
        'SELECT COUNT(*) AS views, COUNT(DISTINCT session_hash) AS visitors
         FROM page_views WHERE created_at >= ?'
    );
    $stmt->execute([$since]);
    $stats = $stmt->fetch() ?: $stats;

    $stmt = $db->prepare(
        'SELECT DATE(created_at) AS d, COUNT(*) AS views, COUNT(DISTINCT session_hash) AS visitors
         FROM page_views WHERE created_at >= ?
         GROUP BY DATE(created_at) ORDER BY d'
    );
    $stmt->execute([$since]);
    foreach ($stmt->fetchAll() as $row) {
        $daily[(string) $row['d']] = [
            'views'    => (int) $row['views'],
            'visitors' => (int) $row['visitors'],
        ];
    }
    /* fill gaps so the chart is continuous */
    for ($t = strtotime($since); $t <= time(); $t = strtotime('+1 day', $t)) {
        $k = date('Y-m-d', $t);
        if (!isset($daily[$k])) $daily[$k] = ['views' => 0, 'visitors' => 0];
    }
    ksort($daily);

    $stmt = $db->prepare(
        'SELECT path, page_type, COUNT(*) AS c
         FROM page_views WHERE created_at >= ?
         GROUP BY path, page_type ORDER BY c DESC LIMIT 10'
    );
    $stmt->execute([$since]);
    $topPages = $stmt->fetchAll();

    $stmt = $db->prepare(
        'SELECT referrer, COUNT(*) AS c
         FROM page_views WHERE created_at >= ? AND referrer IS NOT NULL
         GROUP BY referrer ORDER BY c DESC LIMIT 8'
    );
    $stmt->execute([$since]);
    $topRefs = $stmt->fetchAll();

    $stmt = $db->prepare('SELECT COUNT(*) FROM page_views WHERE created_at >= ? AND referrer IS NULL');
    $stmt->execute([$since]);
    $direct = (int) $stmt->fetchColumn();

    $stmt = $db->prepare('SELECT device, COUNT(*) AS c FROM page_views WHERE created_at >= ? GROUP BY device');
    $stmt->execute([$since]);
    foreach ($stmt->fetchAll() as $row) {
        $devices[(string) $row['device']] = (int) $row['c'];
    }
}

$totalViews = (int) $stats['views'];
$visitors   = (int) $stats['visitors'];
$perVisit   = $visitors > 0 ? round($totalViews / $visitors, 1) : 0.0;

$maxViewsDay = 1;
foreach ($daily as $d) {
    $maxViewsDay = max($maxViewsDay, (int) $d['views']);
}

/* --------------------------------------------------------------- helpers */
function anx_pretty_path(string $path): string
{
    $q = parse_url($path, PHP_URL_QUERY);
    $base = strtolower((string) basename((string) parse_url($path, PHP_URL_PATH)));
    $label = str_replace('.php', '', $base);
    if ($label === 'index' || $label === '') $label = 'home';

    $slug = '';
    if (is_string($q)) {
        parse_str($q, $qs);
        if (!empty($qs['slug']) && is_string($qs['slug'])) {
            $slug = ucwords(str_replace(['-', '_'], ' ', $qs['slug']));
        }
    }
    $label = ucwords(str_replace(['-', '_'], ' ', $label));
    return $slug !== '' ? $label . ' — ' . $slug : $label;
}

function anx_ref_label(string $ref): string
{
    $host = parse_url($ref, PHP_URL_HOST);
    $path = parse_url($ref, PHP_URL_PATH);
    $out = $host !== null ? preg_replace('/^www\./', '', $host) : $ref;
    if (is_string($path) && $path !== '' && $path !== '/') {
        $out .= mb_substr($path, 0, 40);
    }
    return (string) $out;
}

$page_title = 'Analytics';
$active     = 'analytics';

ob_start();
?>

<style>
    .anx-range { display: flex; gap: 8px; flex-wrap: wrap; margin: 14px 0 20px; }
    .anx-range a {
        padding: 6px 14px; border-radius: 999px; border: 1px solid #e4dcd2;
        font-size: 13px; color: #6b5f57; text-decoration: none; background: #fff;
        transition: all .2s ease;
    }
    .anx-range a:hover { border-color: #c9a96a; color: #9c7c3f; }
    .anx-range a.is-active { background: #c9a96a; border-color: #c9a96a; color: #fff; }

    .anx-chart {
        display: flex; align-items: flex-end; gap: 4px;
        height: 220px; padding: 18px 14px 6px;
        background: linear-gradient(180deg, #fffdf9, #fdfaf4);
        border: 1px solid #eee6da; border-radius: 14px; margin-bottom: 22px;
    }
    .anx-day { flex: 1; display: flex; flex-direction: column; align-items: center; gap: 6px; min-width: 0; height: 100%; justify-content: flex-end; }
    .anx-bars { display: flex; align-items: flex-end; gap: 2px; width: 100%; height: calc(100% - 26px); justify-content: center; }
    .anx-bar { width: 42%; max-width: 16px; border-radius: 3px 3px 0 0; min-height: 2px; transition: height .4s ease; }
    .anx-bar.views { background: linear-gradient(180deg, #c9a96a, #b99a63); }
    .anx-bar.vis { background: rgba(201, 169, 106, .35); }
    .anx-day label { font-size: 10px; color: #8d8177; white-space: nowrap; overflow: hidden; max-width: 100%; }
    .anx-legend { display: flex; gap: 16px; font-size: 12px; color: #6b5f57; margin-bottom: 18px; }
    .anx-legend i { width: 10px; height: 10px; border-radius: 3px; display: inline-block; margin-right: 6px; }
    .anx-legend .l-vis { background: rgba(201, 169, 106, .35); }
    .anx-legend .l-views { background: #c9a96a; }

    .anx-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 20px; }
    .anx-panel { background: #fff; border: 1px solid #eee6da; border-radius: 14px; padding: 18px 20px; }
    .anx-panel h3 { font-size: 13px; letter-spacing: .12em; text-transform: uppercase; color: #9c7c3f; margin-bottom: 14px; }
    .anx-row { display: flex; justify-content: space-between; align-items: center; gap: 12px; padding: 8px 0; border-bottom: 1px solid #f4efe7; font-size: 14px; }
    .anx-row:last-child { border-bottom: 0; }
    .anx-row .lbl { color: #3b2b26; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
    .anx-row .val { color: #8d8177; font-variant-numeric: tabular-nums; flex-shrink: 0; }
    .anx-meter { height: 6px; border-radius: 999px; background: #f4efe7; overflow: hidden; margin-top: 5px; }
    .anx-meter > span { display: block; height: 100%; background: linear-gradient(90deg, #e3cda1, #c9a96a); border-radius: 999px; }
    .anx-empty { text-align: center; padding: 46px 20px; color: #8d8177; font-size: 14.5px; background: #fffdf9; border: 1px dashed #e4dcd2; border-radius: 14px; }
    .anx-empty i { font-size: 30px; color: #c9a96a; display: block; margin-bottom: 12px; }
    @media (max-width: 720px) { .anx-day label { display: none; } }
</style>

<div class="page-header">
    <div>
        <h1>Analytics</h1>
        <p>First-party visitor analytics — collected on your own server, no third-party trackers.</p>
    </div>
</div>

<div class="anx-range">
    <?php foreach ([7 => 'Last 7 days', 14 => 'Last 14 days', 30 => 'Last 30 days', 90 => 'Last 90 days'] as $dOpt => $dLabel): ?>
        <a href="<?= e(url('/admin/analytics.php?days=' . $dOpt)) ?>" class="<?= $days === $dOpt ? 'is-active' : '' ?>"><?= e($dLabel) ?></a>
    <?php endforeach; ?>
</div>

<?php if (!$hasTable): ?>
    <div class="anx-empty">
        <i class="fa-solid fa-database"></i>
        The <code>page_views</code> table has not been created yet.<br>
        Run <code>migration-analytics.sql</code> once to enable visitor analytics.
    </div>
<?php elseif ($totalViews === 0): ?>
    <div class="anx-empty">
        <i class="fa-solid fa-chart-line"></i>
        No page views recorded yet in this period.<br>
        Tracking starts as soon as visitors open the storefront with JavaScript enabled.
    </div>
<?php else: ?>

    <div class="stat-grid">
        <div class="stat-card">
            <div class="stat-icon gold"><i class="fa-solid fa-users"></i></div>
            <div>
                <div class="stat-value"><?= (int) $visitors ?></div>
                <div class="stat-label">Visitors</div>
            </div>
        </div>
        <div class="stat-card">
            <div class="stat-icon blue"><i class="fa-solid fa-eye"></i></div>
            <div>
                <div class="stat-value"><?= (int) $totalViews ?></div>
                <div class="stat-label">Page Views</div>
            </div>
        </div>
        <div class="stat-card">
            <div class="stat-icon green"><i class="fa-solid fa-arrow-pointer"></i></div>
            <div>
                <div class="stat-value"><?= e((string) $perVisit) ?></div>
                <div class="stat-label">Views / Visit</div>
            </div>
        </div>
        <div class="stat-card">
            <div class="stat-icon gold"><i class="fa-solid fa-mobile-screen"></i></div>
            <div>
                <div class="stat-value">
                    <?php
                    $dominant = '—';
                    $domCount = 0;
                    foreach ($devices as $dvc => $cnt) {
                        if ($cnt > $domCount) { $domCount = $cnt; $dominant = $dvc; }
                    }
                    echo e(ucfirst($dominant));
                    ?>
                </div>
                <div class="stat-label">Top Device</div>
            </div>
        </div>
    </div>

    <div class="anx-legend">
        <span><i class="l-views"></i> Page views</span>
        <span><i class="l-vis"></i> Visitors</span>
    </div>

    <div class="anx-chart" role="img" aria-label="Daily page views and visitors for the selected period">
        <?php
        $labels = array_keys($daily);
        $labelStep = max(1, (int) ceil(count($daily) / 12));
        foreach ($daily as $dayKey => $dRow):
            $vPct = (int) round($dRow['views'] / $maxViewsDay * 100);
            $sPct = (int) round($dRow['visitors'] / $maxViewsDay * 100);
            $idx = array_search($dayKey, $labels, true);
            ?>
            <div class="anx-day" title="<?= e($dayKey) ?> — <?= (int) $dRow['views'] ?> views, <?= (int) $dRow['visitors'] ?> visitors">
                <div class="anx-bars">
                    <span class="anx-bar vis" style="height: <?= $sPct ?>%"></span>
                    <span class="anx-bar views" style="height: <?= $vPct ?>%"></span>
                </div>
                <label><?= $idx !== false && $idx % $labelStep === 0 ? e(date('M j', strtotime($dayKey))) : '' ?></label>
            </div>
        <?php endforeach; ?>
    </div>

    <div class="anx-grid">
        <div class="anx-panel">
            <h3>Top Pages</h3>
            <?php $maxP = 1; foreach ($topPages as $tp) $maxP = max($maxP, (int) $tp['c']); ?>
            <?php foreach ($topPages as $tp): ?>
                <div class="anx-row" style="display:block">
                    <div style="display:flex;justify-content:space-between;gap:12px">
                        <span class="lbl" title="<?= e($tp['path']) ?>"><?= e(anx_pretty_path((string) $tp['path'])) ?></span>
                        <span class="val"><?= (int) $tp['c'] ?></span>
                    </div>
                    <div class="anx-meter"><span style="width: <?= (int) round((int) $tp['c'] / $maxP * 100) ?>%"></span></div>
                </div>
            <?php endforeach; ?>
            <?php if (!$topPages): ?><div class="anx-row"><span class="lbl">No data</span></div><?php endif; ?>
        </div>

        <div class="anx-panel">
            <h3>Traffic Sources</h3>
            <?php
            $refRows = [];
            foreach ($topRefs as $tr) $refRows[] = ['label' => anx_ref_label((string) $tr['referrer']), 'c' => (int) $tr['c']];
            if ($direct > 0) $refRows[] = ['label' => 'Direct / no referrer', 'c' => $direct];
            usort($refRows, fn($a, $b) => $b['c'] <=> $a['c']);
            $maxR = 1;
            foreach ($refRows as $rr) $maxR = max($maxR, $rr['c']);
            ?>
            <?php foreach ($refRows as $rr): ?>
                <div class="anx-row" style="display:block">
                    <div style="display:flex;justify-content:space-between;gap:12px">
                        <span class="lbl" title="<?= e($rr['label']) ?>"><?= e($rr['label']) ?></span>
                        <span class="val"><?= (int) $rr['c'] ?></span>
                    </div>
                    <div class="anx-meter"><span style="width: <?= (int) round($rr['c'] / $maxR * 100) ?>%"></span></div>
                </div>
            <?php endforeach; ?>
            <?php if (!$refRows): ?><div class="anx-row"><span class="lbl">No data</span></div><?php endif; ?>
        </div>

        <div class="anx-panel">
            <h3>Devices</h3>
            <?php $maxD = 1; foreach ($devices as $dv) $maxD = max($maxD, $dv); ?>
            <?php foreach (['desktop', 'tablet', 'mobile'] as $dOrder): ?>
                <?php if (!isset($devices[$dOrder])) continue; $dv = $devices[$dOrder]; ?>
                <div class="anx-row" style="display:block">
                    <div style="display:flex;justify-content:space-between;gap:12px">
                        <span class="lbl"><i class="fa-solid <?= $dOrder === 'mobile' ? 'fa-mobile-screen' : ($dOrder === 'tablet' ? 'fa-tablet-screen-button' : 'fa-desktop') ?>" style="color:#c9a96a;margin-right:8px"></i><?= e(ucfirst($dOrder)) ?></span>
                        <span class="val"><?= (int) $dv ?> (<?= (int) $totalViews > 0 ? round($dv / $totalViews * 100) : 0 ?>%)</span>
                    </div>
                    <div class="anx-meter"><span style="width: <?= (int) round($dv / $maxD * 100) ?>%"></span></div>
                </div>
            <?php endforeach; ?>
            <?php if (!$devices): ?><div class="anx-row"><span class="lbl">No data</span></div><?php endif; ?>
        </div>
    </div>

<?php endif; ?>

<?php
$content = ob_get_clean();
require __DIR__ . '/layout.php';
