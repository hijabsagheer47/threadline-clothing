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
-- One row per app install. There are no customer accounts -- the app shops as
-- a guest, exactly as a visitor does on the website -- so this is an anonymous
-- device identity, not a credential.
--
-- cart_json / coupon_code hold the same structures the website keeps in the
-- PHP session, which is why every existing cart/coupon/wishlist helper is
-- reused unchanged instead of being reimplemented for a client that has no
-- session cookie.
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `api_tokens` (
  `id`           INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `token`        CHAR(64) NOT NULL,
  `device_name`  VARCHAR(120) NULL DEFAULT NULL,
  `platform`     VARCHAR(20)  NULL DEFAULT NULL COMMENT 'android | ios | web',
  `cart_json`    MEDIUMTEXT NULL COMMENT 'JSON mirror of the session cart + wishlist',
  `coupon_code`  VARCHAR(50) NULL DEFAULT NULL,
  `last_used_at` DATETIME NULL DEFAULT NULL,
  `expires_at`   DATETIME NULL DEFAULT NULL,
  `created_at`   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_api_tokens_token` (`token`),
  KEY `idx_api_tokens_expiry` (`expires_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- Installs made before customer accounts were dropped carry an unused
-- customer_id column and its foreign key. Removed here, guarded so a fresh
-- install -- where neither ever existed -- runs without error.
-- ----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS `tc_api_drop_customer_id`;
DELIMITER $$
CREATE PROCEDURE `tc_api_drop_customer_id`()
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.TABLE_CONSTRAINTS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'api_tokens'
      AND CONSTRAINT_NAME = 'fk_api_tokens_customer'
  ) THEN
    ALTER TABLE `api_tokens` DROP FOREIGN KEY `fk_api_tokens_customer`;
  END IF;

  IF EXISTS (
    SELECT 1 FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'api_tokens'
      AND COLUMN_NAME = 'customer_id'
  ) THEN
    ALTER TABLE `api_tokens` DROP COLUMN `customer_id`;
  END IF;
END$$
DELIMITER ;

CALL tc_api_drop_customer_id();
DROP PROCEDURE IF EXISTS `tc_api_drop_customer_id`;
