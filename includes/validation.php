<?php
/**
 * Input sanitization & server-side validation helpers.
 */

declare(strict_types=1);

/** Trim + strip tags (single line). */
function clean(string $value, int $max = 255): string
{
    $value = trim(strip_tags($value));
    if ($max > 0 && mb_strlen($value) > $max) {
        $value = mb_substr($value, 0, $max);
    }
    return $value;
}

/** Trim + strip tags (multi-line). */
function clean_text(?string $value, int $max = 0): string
{
    $value = trim(strip_tags((string) $value));
    if ($max > 0 && mb_strlen($value) > $max) {
        $value = mb_substr($value, 0, $max);
    }
    return $value;
}

function valid_email(?string $value): bool
{
    return is_string($value) && filter_var($value, FILTER_VALIDATE_EMAIL) !== false;
}

/** Accept digits, spaces and + - ( ) — typical phone formats. */
function valid_phone(?string $value): bool
{
    return is_string($value) && preg_match('/^[0-9+\-\s()]{7,25}$/', trim($value)) === 1;
}

function valid_int(?string $value, int $min = 0, ?int $max = null): bool
{
    if ($value === null || $value === '') return false;
    if (filter_var($value, FILTER_VALIDATE_INT) === false) return false;
    $n = (int) $value;
    if ($n < $min) return false;
    if ($max !== null && $n > $max) return false;
    return true;
}

function valid_price(?string $value, float $min = 0.0, ?float $max = null): bool
{
    if ($value === null || $value === '') return false;
    if (!is_numeric($value)) return false;
    $n = (float) $value;
    if ($n < $min) return false;
    if ($max !== null && $n > $max) return false;
    return true;
}

/** Fetch a POST field, sanitized. */
function post(string $key, int $max = 255): string
{
    return clean((string) ($_POST[$key] ?? ''), $max);
}

function post_text(string $key, int $max = 0): string
{
    return clean_text($_POST[$key] ?? null, $max);
}

function post_int(string $key, int $default = 0): int
{
    $v = (string) ($_POST[$key] ?? '');
    return filter_var($v, FILTER_VALIDATE_INT) !== false ? (int) $v : $default;
}

function post_float(string $key, float $default = 0.0): float
{
    $v = (string) ($_POST[$key] ?? '');
    return is_numeric($v) ? (float) $v : $default;
}

function get_string(string $key, int $max = 255): string
{
    return clean((string) ($_GET[$key] ?? ''), $max);
}