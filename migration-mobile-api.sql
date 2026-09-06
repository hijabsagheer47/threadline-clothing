-- ============================================================================
-- FASHLAB STUDIO — MOBILE API MIGRATION
-- ----------------------------------------------------------------------------
-- Adds the single table the Flutter app needs. Nothing existing is altered,
-- so the website keeps working exactly as it does today.
--
-- Run once:  mysql -u USER -p DBNAME < migration-mobile-api.sql
--            (or paste into phpMyAdmin -> SQL)
-- Re-running is safe.
-- ============================================================================

SET NAMES utf8mb4;

-- ----------------------------------------------------------------------------
-- API TOKENS
-- One row per app install. A token starts as a guest token (customer_id NULL)
-- and is upgraded in place when the customer logs in, so the guest cart and
-- wishlist survive the login.
--
-- cart_json / coupon_code hold the same structures the website keeps in the
-- PHP session, which is why every existing cart/coupon helper is reused
-- unchanged instead of being reimplemented for the app.
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `api_tokens` (
  `id`           INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `token`        CHAR(64) NOT NULL,
  `customer_id`  INT UNSIGNED NULL DEFAULT NULL,
  `device_name`  VARCHAR(120) NULL DEFAULT NULL,
  `platform`     VARCHAR(20)  NULL DEFAULT NULL COMMENT 'android | ios | web',
  `cart_json`    MEDIUMTEXT NULL COMMENT 'JSON mirror of the session cart',
  `coupon_code`  VARCHAR(50) NULL DEFAULT NULL,
  `last_used_at` DATETIME NULL DEFAULT NULL,
  `expires_at`   DATETIME NULL DEFAULT NULL,
  `created_at`   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_api_tokens_token` (`token`),
  KEY `idx_api_tokens_customer` (`customer_id`),
  KEY `idx_api_tokens_expiry` (`expires_at`),
  CONSTRAINT `fk_api_tokens_customer` FOREIGN KEY (`customer_id`)
    REFERENCES `customers` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
