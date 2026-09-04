<?php
/**
 * Secure image upload handling.
 * - Validates MIME type via finfo, extension, size and dimensions.
 * - Generates a safe random filename — user filenames are never trusted.
 * - Stores files on disk (never in the database); only the path is saved.
 *
 * Returns: ['success' => bool, 'path' => string, 'error' => string]
 */

declare(strict_types=1);

const ALLOWED_IMAGE_TYPES = [
    'image/jpeg' => ['jpg', 'jpeg'],
    'image/png'  => ['png'],
    'image/webp' => ['webp'],
    'image/gif'  => ['gif'],
];

const MIN_IMAGE_DIMENSION = 200;

function upload_image(array $file, string $subdir): array
{
    $result = ['success' => false, 'path' => '', 'error' => ''];

    if (!isset($file['error']) || is_array($file['error'])) {
        $result['error'] = 'Invalid upload.';
        return $result;
    }

    if ($file['error'] !== UPLOAD_ERR_OK) {
        $result['error'] = match ($file['error']) {
            UPLOAD_ERR_INI_SIZE, UPLOAD_ERR_FORM_SIZE => 'Image is too large (max ' . round(UPLOAD_MAX_SIZE / 1048576) . ' MB).',
            UPLOAD_ERR_NO_FILE => 'No file was selected.',
            default => 'Upload failed. Please try again.',
        };
        return $result;
    }

    if ($file['size'] > UPLOAD_MAX_SIZE) {
        $result['error'] = 'Image is too large (max ' . round(UPLOAD_MAX_SIZE / 1048576) . ' MB).';
        return $result;
    }

    // Real MIME type — never trust the client header.
    $finfo = new finfo(FILEINFO_MIME_TYPE);
    $mime  = (string) $finfo->file($file['tmp_name']);

    if (!isset(ALLOWED_IMAGE_TYPES[$mime])) {
        $result['error'] = 'Only JPG, PNG, WebP or GIF images are allowed.';
        return $result;
    }

    // Dimensions (also rejects corrupt files).
    $dimensions = @getimagesize($file['tmp_name']);
    if ($dimensions === false) {
        $result['error'] = 'The uploaded file is not a valid image.';
        return $result;
    }
    if ($dimensions[0] < MIN_IMAGE_DIMENSION || $dimensions[1] < MIN_IMAGE_DIMENSION) {
        $result['error'] = 'Image is too small (minimum ' . MIN_IMAGE_DIMENSION . 'x' . MIN_IMAGE_DIMENSION . 'px).';
        return $result;
    }

    $ext      = ALLOWED_IMAGE_TYPES[$mime][0];
    $filename = bin2hex(random_bytes(16)) . '.' . $ext;

    $baseDir = __DIR__ . '/../uploads/';
    $targetDir = $baseDir . $subdir;
    if (!is_dir($targetDir)) {
        if (!@mkdir($targetDir, 0755, true) && !is_dir($targetDir)) {
            $result['error'] = 'Upload directory is not writable.';
            return $result;
        }
    }

    $relative = 'uploads/' . $subdir . '/' . $filename;
    $target   = $baseDir . $subdir . '/' . $filename;

    if (!@move_uploaded_file($file['tmp_name'], $target)) {
        $result['error'] = 'Could not save the uploaded image.';
        return $result;
    }

    @chmod($target, 0644);
    $result['success'] = true;
    $result['path']    = $relative;
    return $result;
}

/** Delete an image file if it lives inside uploads/. Returns void. */
function delete_uploaded_file(string $relativePath): void
{
    $relativePath = ltrim($relativePath, '/');
    if (!str_starts_with($relativePath, 'uploads/')) {
        return;
    }
    $full = __DIR__ . '/../' . $relativePath;
    $base = realpath(__DIR__ . '/../uploads/');
    $fullReal = realpath($full);
    if ($fullReal !== false && $base !== false && str_starts_with($fullReal, $base)) {
        @unlink($fullReal);
    }
}