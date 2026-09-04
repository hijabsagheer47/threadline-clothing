<?php
/**
 * General helper functions used across the storefront and admin panel.
 */

declare(strict_types=1);

/** Escape output for safe HTML. Use for EVERY value rendered into markup. */
function e(?string $value): string
{
    return htmlspecialchars((string) $value, ENT_QUOTES, 'UTF-8');
}

/** Format a number as store currency, e.g. Rs. 12,500. */
function money(float|int|string $amount): string
{
    $symbol = (string) setting('currency_symbol', 'Rs.');
    return $symbol . ' ' . number_format((float) $amount);
}

function format_price(float|int|string $amount): string
{
    return number_format((float) $amount, 2);
}

/** Turn "Black Embroidered 3 Piece Suit" into "black-embroidered-3-piece-suit". */
function slugify(string $text): string
{
    $text = mb_strtolower(trim($text));
    $text = preg_replace('/[^a-z0-9]+/', '-', $text) ?? '';
    $text = trim($text, '-');
    return $text !== '' ? $text : 'item-' . substr(bin2hex(random_bytes(3)), 0, 6);
}

/** Root-relative URL (respects BASE_URL when installed in a sub-folder). */
function url(string $path = ''): string
{
    return BASE_URL . $path;
}

function product_url(string $slug): string
{
    return url('/product/' . rawurlencode($slug));
}

function category_url(string $slug): string
{
    return url('/category/' . rawurlencode($slug));
}

function asset_url(string $path): string
{
    return url('/' . ltrim($path, '/'));
}

/**
 * Resolve a stored image path (DB value) into a browser-ready URL.
 *
 * Stored paths are root-relative (e.g. "images/products/x.jpg" or
 * "uploads/products/x.jpg") and must ALWAYS go through this helper so they
 * resolve correctly on pretty-URL pages (/product/..., /category/...) and in
 * the /admin/ folder. Empty values fall back to a branded placeholder.
 */
function image_url(?string $path): string
{
    $path = trim((string) $path);
    if ($path === '') {
        return asset_url('images/placeholder.svg');
    }
    // External URLs (http/https/protocol-relative) pass through untouched.
    if (preg_match('#^(https?:)?//#i', $path)) {
        return $path;
    }
    return url('/' . ltrim($path, '/'));
}

/** Safe redirect. */
function redirect(string $to): never
{
    header('Location: ' . $to);
    exit;
}

/** Flash messages stored in the session, shown once. */
function flash_set(string $type, string $message): void
{
    $_SESSION['flash'][] = ['type' => $type, 'message' => $message];
}

function flash_get(): array
{
    $messages = $_SESSION['flash'] ?? [];
    unset($_SESSION['flash']);
    return $messages;
}

function flash_render(): string
{
    $html = '';
    foreach (flash_get() as $f) {
        $html .= '<div class="flash flash-' . e($f['type']) . '">'
               . '<span>' . e($f['message']) . '</span>'
               . '<button type="button" class="flash-close" aria-label="Dismiss">&times;</button></div>';
    }
    return $html;
}

function client_ip(): string
{
    $ip = $_SERVER['REMOTE_ADDR'] ?? '';
    if (!empty($_SERVER['HTTP_X_FORWARDED_FOR'])) {
        $parts = explode(',', $_SERVER['HTTP_X_FORWARDED_FOR']);
        $first = trim((string) ($parts[0] ?? ''));
        if (filter_var($first, FILTER_VALIDATE_IP)) {
            $ip = $first;
        }
    }
    return $ip;
}

function format_date(?string $datetime, string $format = 'M j, Y'): string
{
    if (!$datetime) return '—';
    $ts = strtotime($datetime);
    return $ts ? date($format, $ts) : '—';
}

function format_datetime(?string $datetime): string
{
    return format_date($datetime, 'M j, Y g:i A');
}

function time_ago(?string $datetime): string
{
    if (!$datetime) return '';
    $ts = strtotime($datetime);
    if (!$ts) return '';
    $diff = time() - $ts;
    if ($diff < 60) return 'just now';
    if ($diff < 3600) return floor($diff / 60) . ' min ago';
    if ($diff < 86400) return floor($diff / 3600) . ' hr ago';
    if ($diff < 86400 * 30) return floor($diff / 86400) . ' day' . (floor($diff / 86400) > 1 ? 's' : '') . ' ago';
    return format_date($datetime);
}

/** Generate a pagination bar. Returns '' when only one page exists. */
function pagination_links(int $page, int $pages, string $queryString): string
{
    if ($pages <= 1) return '';

    $build = static function (int $p) use ($queryString): string {
        $qs = $queryString !== '' ? $queryString . '&page=' . $p : 'page=' . $p;
        return '?' . $qs;
    };

    $html = '<nav class="pagination" aria-label="Pagination">';

    if ($page > 1) {
        $html .= '<a class="page-link" href="' . e($build($page - 1)) . '" aria-label="Previous page">&laquo;</a>';
    }

    $start = max(1, $page - 2);
    $end   = min($pages, $page + 2);
    for ($i = $start; $i <= $end; $i++) {
        $active = $i === $page ? ' active' : '';
        $html .= '<a class="page-link' . $active . '" href="' . e($build($i)) . '">' . $i . '</a>';
    }

    if ($page < $pages) {
        $html .= '<a class="page-link" href="' . e($build($page + 1)) . '" aria-label="Next page">&raquo;</a>';
    }

    $html .= '</nav>';
    return $html;
}

/** ISO currency amount from a decimal string. */
function decimal(float|int|string $value): string
{
    return number_format((float) $value, 2, '.', '');
}

/** Badge color class for an order status. */
function order_status_color(string $status): string
{
    return match ($status) {
        'pending'    => 'gold',
        'confirmed'  => 'blue',
        'processing' => 'blue',
        'shipped'    => 'purple',
        'delivered'  => 'green',
        'cancelled'  => 'red',
        default      => 'gray',
    };
}

/** Badge color class for a payment status. */
function payment_status_color(string $status): string
{
    return match ($status) {
        'paid'       => 'green',
        'pending'    => 'gold',
        'unpaid'     => 'red',
        'refunded'   => 'purple',
        default      => 'gray',
    };
}

/** True when the request is an AJAX/fetch request. */
function is_ajax(): bool
{
    return strtolower((string) ($_SERVER['HTTP_X_REQUESTED_WITH'] ?? '')) === 'xmlhttprequest'
        || (($_SERVER['HTTP_ACCEPT'] ?? '') !== '' && str_contains($_SERVER['HTTP_ACCEPT'] ?? '', 'application/json'));
}