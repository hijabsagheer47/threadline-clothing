-- ============================================================================
-- FASHLAB STUDIO — ENTERPRISE FEATURE MIGRATION
-- ============================================================================
-- Target:  the LIVE database created from database.sql (TayyabaCollective /
--          Fashlab Studio e-commerce store).
--
-- WHAT THIS FILE DOES
--   1. Extends the EXISTING tables (products, categories, orders, order_items,
--      customers, subscribers) with new columns — additively, never removing
--      or renaming anything the current code depends on.
--   2. Creates all NEW feature tables (collections, reviews, wishlists,
--      coupons, inventory logs, order status history, payments, shipping,
--      menus, hero slides, homepage builder, CMS pages, FAQs, looks/bundles,
--      gift cards, product alerts, rewards, referrals, journal, quiz,
--      personal shopper, search analytics, abandoned carts, RBAC, ...).
--   3. Seeds Fashlab Studio configuration (settings, roles, size charts,
--      colours, shipping methods, currencies, navigation menus, collections).
--
-- SAFETY GUARANTEES
--   * NO table is dropped, truncated or emptied.
--   * Existing rows are NEVER deleted; existing settings are NEVER
--     overwritten (new keys are inserted only).
--   * No fabricated business data: no fake orders, reviews, testimonials,
--     customers or analytics. Derived flags (new-in, best-seller) are
--     calculated from REAL existing data (created_at / order_items).
--   * The file is IDEMPOTENT — importing it twice is safe. Columns, indexes
--     and foreign keys are only added when missing (checked against
--     information_schema), and all seed inserts use INSERT IGNORE.
--
-- HOW TO IMPORT
--   phpMyAdmin : select your Fashlab database -> Import -> choose this file.
--   CLI        : mysql -u USERNAME -p DBNAME < migration-fashlab-upgrade.sql
--
-- ============================================================================

-- ============================================================================
-- 0. MIGRATION REGISTRY + SAFE-DDL HELPERS
-- ============================================================================

CREATE TABLE IF NOT EXISTS `schema_migrations` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `migration_name` VARCHAR(190) NOT NULL,
  `applied_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_sm_name` (`migration_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Helper: add a column only when it does not exist yet.
DROP PROCEDURE IF EXISTS `tc_add_column`;
DELIMITER $$
CREATE PROCEDURE `tc_add_column`(IN p_table VARCHAR(64), IN p_column VARCHAR(64), IN p_ddl VARCHAR(512))
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = p_table AND COLUMN_NAME = p_column
  ) THEN
    SET @tc_sql = CONCAT('ALTER TABLE `', p_table, '` ADD COLUMN ', p_ddl);
    PREPARE tc_stmt FROM @tc_sql;
    EXECUTE tc_stmt;
    DEALLOCATE PREPARE tc_stmt;
  END IF;
END$$
DELIMITER ;

-- Helper: add an index only when it does not exist yet.
DROP PROCEDURE IF EXISTS `tc_add_index`;
DELIMITER $$
CREATE PROCEDURE `tc_add_index`(IN p_table VARCHAR(64), IN p_index VARCHAR(64), IN p_ddl VARCHAR(512))
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.STATISTICS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = p_table AND INDEX_NAME = p_index
  ) THEN
    SET @tc_sql = CONCAT('ALTER TABLE `', p_table, '` ADD INDEX `', p_index, '` ', p_ddl);
    PREPARE tc_stmt FROM @tc_sql;
    EXECUTE tc_stmt;
    DEALLOCATE PREPARE tc_stmt;
  END IF;
END$$
DELIMITER ;

-- Helper: add a unique key only when it does not exist yet.
DROP PROCEDURE IF EXISTS `tc_add_unique`;
DELIMITER $$
CREATE PROCEDURE `tc_add_unique`(IN p_table VARCHAR(64), IN p_index VARCHAR(64), IN p_ddl VARCHAR(512))
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.STATISTICS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = p_table AND INDEX_NAME = p_index
  ) THEN
    SET @tc_sql = CONCAT('ALTER TABLE `', p_table, '` ADD UNIQUE KEY `', p_index, '` ', p_ddl);
    PREPARE tc_stmt FROM @tc_sql;
    EXECUTE tc_stmt;
    DEALLOCATE PREPARE tc_stmt;
  END IF;
END$$
DELIMITER ;

-- Helper: add a foreign key only when it does not exist yet.
DROP PROCEDURE IF EXISTS `tc_add_fk`;
DELIMITER $$
CREATE PROCEDURE `tc_add_fk`(IN p_table VARCHAR(64), IN p_constraint VARCHAR(64), IN p_ddl VARCHAR(512))
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.TABLE_CONSTRAINTS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = p_table AND CONSTRAINT_NAME = p_constraint
  ) THEN
    SET @tc_sql = CONCAT('ALTER TABLE `', p_table, '` ADD CONSTRAINT `', p_constraint, '` ', p_ddl);
    PREPARE tc_stmt FROM @tc_sql;
    EXECUTE tc_stmt;
    DEALLOCATE PREPARE tc_stmt;
  END IF;
END$$
DELIMITER ;

-- ============================================================================
-- 1. EXTEND EXISTING TABLES (additive only)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- PRODUCTS — collections, occasions, style, SEO, media, product flags,
-- rating cache, sort order. The original columns are untouched, so every
-- existing query keeps working.
-- ----------------------------------------------------------------------------
CALL tc_add_column('products', 'collection_id',        '`collection_id` INT UNSIGNED NULL DEFAULT NULL AFTER `category_id`');
CALL tc_add_column('products', 'occasion',             '`occasion` VARCHAR(150) NULL DEFAULT NULL AFTER `color`');
CALL tc_add_column('products', 'style',                '`style` VARCHAR(150) NULL DEFAULT NULL AFTER `occasion`');
CALL tc_add_column('products', 'material',             '`material` VARCHAR(150) NULL DEFAULT NULL AFTER `fabric`');
CALL tc_add_column('products', 'tags',                 '`tags` VARCHAR(500) NULL DEFAULT NULL AFTER `material`');
CALL tc_add_column('products', 'care_instructions',    '`care_instructions` TEXT NULL AFTER `description`');
CALL tc_add_column('products', 'gender',               '`gender` VARCHAR(20) NULL DEFAULT NULL AFTER `product_type`');
CALL tc_add_column('products', 'garment_length',       '`garment_length` VARCHAR(50) NULL DEFAULT NULL AFTER `size`');
CALL tc_add_column('products', 'video_url',            '`video_url` VARCHAR(255) NULL DEFAULT NULL AFTER `garment_length`');
CALL tc_add_column('products', 'views',                '`views` INT UNSIGNED NOT NULL DEFAULT 0 AFTER `stock_status`');
CALL tc_add_column('products', 'rating_avg',           '`rating_avg` DECIMAL(3,2) NOT NULL DEFAULT 0.00 AFTER `views`');
CALL tc_add_column('products', 'rating_count',         '`rating_count` INT UNSIGNED NOT NULL DEFAULT 0 AFTER `rating_avg`');
CALL tc_add_column('products', 'sort_order',           '`sort_order` INT NOT NULL DEFAULT 0 AFTER `featured`');
CALL tc_add_column('products', 'is_new',               '`is_new` TINYINT(1) NOT NULL DEFAULT 0 AFTER `sort_order`');
CALL tc_add_column('products', 'is_best_seller',       '`is_best_seller` TINYINT(1) NOT NULL DEFAULT 0 AFTER `is_new`');
CALL tc_add_column('products', 'is_trending',          '`is_trending` TINYINT(1) NOT NULL DEFAULT 0 AFTER `is_best_seller`');
CALL tc_add_column('products', 'is_editor_pick',       '`is_editor_pick` TINYINT(1) NOT NULL DEFAULT 0 AFTER `is_trending`');
CALL tc_add_column('products', 'is_exclusive',         '`is_exclusive` TINYINT(1) NOT NULL DEFAULT 0 AFTER `is_editor_pick`');
CALL tc_add_column('products', 'is_limited_edition',   '`is_limited_edition` TINYINT(1) NOT NULL DEFAULT 0 AFTER `is_exclusive`');
CALL tc_add_column('products', 'website_exclusive',    '`website_exclusive` TINYINT(1) NOT NULL DEFAULT 0 AFTER `is_limited_edition`');
CALL tc_add_column('products', 'is_preorder',          '`is_preorder` TINYINT(1) NOT NULL DEFAULT 0 AFTER `website_exclusive`');
CALL tc_add_column('products', 'preorder_dispatch_date','`preorder_dispatch_date` DATE NULL DEFAULT NULL AFTER `is_preorder`');
CALL tc_add_column('products', 'is_coming_soon',       '`is_coming_soon` TINYINT(1) NOT NULL DEFAULT 0 AFTER `preorder_dispatch_date`');
CALL tc_add_column('products', 'launch_date',          '`launch_date` DATE NULL DEFAULT NULL AFTER `is_coming_soon`');
CALL tc_add_column('products', 'meta_title',           '`meta_title` VARCHAR(200) NULL DEFAULT NULL AFTER `launch_date`');
CALL tc_add_column('products', 'meta_description',     '`meta_description` VARCHAR(500) NULL DEFAULT NULL AFTER `meta_title`');
CALL tc_add_column('products', 'meta_keywords',        '`meta_keywords` VARCHAR(300) NULL DEFAULT NULL AFTER `meta_description`');

-- ----------------------------------------------------------------------------
-- CATEGORIES — banner, alt text, SEO
-- ----------------------------------------------------------------------------
CALL tc_add_column('categories', 'banner',            '`banner` VARCHAR(255) NULL DEFAULT NULL AFTER `image`');
CALL tc_add_column('categories', 'image_alt',         '`image_alt` VARCHAR(255) NULL DEFAULT NULL AFTER `banner`');
CALL tc_add_column('categories', 'meta_title',        '`meta_title` VARCHAR(200) NULL DEFAULT NULL AFTER `description`');
CALL tc_add_column('categories', 'meta_description',  '`meta_description` VARCHAR(500) NULL DEFAULT NULL AFTER `meta_title`');
CALL tc_add_column('categories', 'meta_keywords',     '`meta_keywords` VARCHAR(300) NULL DEFAULT NULL AFTER `meta_description`');

-- ----------------------------------------------------------------------------
-- ORDERS — customer link, country, shipping, tracking, coupon, tax, gift,
-- source. ENUMs are extended (values added, none removed) so old rows stay
-- valid and the admin/order-tracking flows can use the full status list.
-- ----------------------------------------------------------------------------
CALL tc_add_column('orders', 'customer_id',      '`customer_id` INT UNSIGNED NULL DEFAULT NULL AFTER `id`');
CALL tc_add_column('orders', 'country',          '`country` VARCHAR(100) NULL DEFAULT ''Pakistan'' AFTER `city`');
CALL tc_add_column('orders', 'shipping_method',  '`shipping_method` VARCHAR(50) NULL DEFAULT NULL AFTER `payment_status`');
CALL tc_add_column('orders', 'tracking_number',  '`tracking_number` VARCHAR(100) NULL DEFAULT NULL AFTER `shipping_method`');
CALL tc_add_column('orders', 'delivery_estimate','`delivery_estimate` VARCHAR(100) NULL DEFAULT NULL AFTER `tracking_number`');
CALL tc_add_column('orders', 'coupon_code',      '`coupon_code` VARCHAR(50) NULL DEFAULT NULL AFTER `discount`');
CALL tc_add_column('orders', 'coupon_discount',  '`coupon_discount` DECIMAL(12,2) NOT NULL DEFAULT 0.00 AFTER `coupon_code`');
CALL tc_add_column('orders', 'tax',              '`tax` DECIMAL(12,2) NOT NULL DEFAULT 0.00 AFTER `coupon_discount`');
CALL tc_add_column('orders', 'is_gift',          '`is_gift` TINYINT(1) NOT NULL DEFAULT 0 AFTER `notes`');
CALL tc_add_column('orders', 'gift_message',     '`gift_message` TEXT NULL AFTER `is_gift`');
CALL tc_add_column('orders', 'ip_address',       '`ip_address` VARCHAR(45) NULL DEFAULT NULL AFTER `gift_message`');

-- Extend order status (packed, out for delivery, returned, refunded) and
-- payment status (processing, partial). MODIFY is safe to re-run.
ALTER TABLE `orders`
  MODIFY `order_status` ENUM('pending','confirmed','processing','packed','shipped','out_for_delivery','delivered','cancelled','returned','refunded') NOT NULL DEFAULT 'pending',
  MODIFY `payment_status` ENUM('pending','processing','paid','failed','refunded','partial') NOT NULL DEFAULT 'pending';

-- ----------------------------------------------------------------------------
-- ORDER ITEMS — variant link, colour, size, image snapshot
-- ----------------------------------------------------------------------------
CALL tc_add_column('order_items', 'variant_id', '`variant_id` INT UNSIGNED NULL DEFAULT NULL AFTER `product_id`');
CALL tc_add_column('order_items', 'color',      '`color` VARCHAR(150) NULL DEFAULT NULL AFTER `variant_label`');
CALL tc_add_column('order_items', 'size',       '`size` VARCHAR(50) NULL DEFAULT NULL AFTER `color`');
CALL tc_add_column('order_items', 'image',      '`image` VARCHAR(255) NULL DEFAULT NULL AFTER `size`');

-- ----------------------------------------------------------------------------
-- CUSTOMERS — preferences, newsletter opt-in, referral code
-- ----------------------------------------------------------------------------
CALL tc_add_column('customers', 'preferred_size',   '`preferred_size` VARCHAR(20) NULL DEFAULT NULL AFTER `phone`');
CALL tc_add_column('customers', 'newsletter_optin', '`newsletter_optin` TINYINT(1) NOT NULL DEFAULT 0 AFTER `status`');
CALL tc_add_column('customers', 'referral_code',    '`referral_code` VARCHAR(30) NULL DEFAULT NULL AFTER `newsletter_optin`');
CALL tc_add_column('customers', 'last_login',       '`last_login` DATETIME NULL DEFAULT NULL AFTER `referral_code`');

-- ----------------------------------------------------------------------------
-- SUBSCRIBERS — unsubscribe token, source, unsubscribe timestamp
-- ----------------------------------------------------------------------------
CALL tc_add_column('subscribers', 'token',           '`token` VARCHAR(64) NULL DEFAULT NULL AFTER `email`');
CALL tc_add_column('subscribers', 'source',          '`source` VARCHAR(50) NULL DEFAULT ''storefront'' AFTER `status`');
CALL tc_add_column('subscribers', 'unsubscribed_at', '`unsubscribed_at` DATETIME NULL DEFAULT NULL AFTER `source`');

-- ============================================================================
-- 2. NEW FEATURE TABLES
-- ============================================================================

-- ----------------------------------------------------------------------------
-- COLLECTIONS (curated groups, e.g. Summer Edit, Wedding Edit)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `collections` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(150) NOT NULL,
  `slug` VARCHAR(190) NOT NULL,
  `collection_type` VARCHAR(50) NULL DEFAULT NULL COMMENT 'seasonal | theme | curated | sale | ...',
  `description` TEXT NULL,
  `image` VARCHAR(255) NULL,
  `banner` VARCHAR(255) NULL,
  `status` TINYINT(1) NOT NULL DEFAULT 1,
  `is_featured` TINYINT(1) NOT NULL DEFAULT 0,
  `sort_order` INT NOT NULL DEFAULT 0,
  `start_date` DATE NULL DEFAULT NULL,
  `end_date` DATE NULL DEFAULT NULL,
  `meta_title` VARCHAR(200) NULL DEFAULT NULL,
  `meta_description` VARCHAR(500) NULL DEFAULT NULL,
  `meta_keywords` VARCHAR(300) NULL DEFAULT NULL,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_collections_slug` (`slug`),
  KEY `idx_collections_status_sort` (`status`, `sort_order`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `collection_products` (
  `collection_id` INT UNSIGNED NOT NULL,
  `product_id` INT UNSIGNED NOT NULL,
  `sort_order` INT NOT NULL DEFAULT 0,
  PRIMARY KEY (`collection_id`, `product_id`),
  KEY `idx_cp_product` (`product_id`),
  CONSTRAINT `fk_cp_collection` FOREIGN KEY (`collection_id`) REFERENCES `collections` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_cp_product` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- COLOURS (visual swatches for Shop By Color)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `colors` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(60) NOT NULL,
  `hex_code` VARCHAR(7) NULL DEFAULT NULL,
  `sort_order` INT NOT NULL DEFAULT 0,
  `status` TINYINT(1) NOT NULL DEFAULT 1,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_colors_name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- SIZE CHARTS (Find My Size / Size Guide)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `size_charts` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(150) NOT NULL,
  `description` TEXT NULL,
  `is_global` TINYINT(1) NOT NULL DEFAULT 0,
  `status` TINYINT(1) NOT NULL DEFAULT 1,
  `sort_order` INT NOT NULL DEFAULT 0,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_sc_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `size_chart_measurements` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `size_chart_id` INT UNSIGNED NOT NULL,
  `size_label` VARCHAR(20) NOT NULL,
  `chest_cm` DECIMAL(6,2) NULL DEFAULT NULL,
  `waist_cm` DECIMAL(6,2) NULL DEFAULT NULL,
  `hip_cm` DECIMAL(6,2) NULL DEFAULT NULL,
  `shoulder_cm` DECIMAL(6,2) NULL DEFAULT NULL,
  `length_cm` DECIMAL(6,2) NULL DEFAULT NULL,
  `sort_order` INT NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_scm_size` (`size_chart_id`, `size_label`),
  KEY `idx_scm_chart` (`size_chart_id`),
  CONSTRAINT `fk_scm_chart` FOREIGN KEY (`size_chart_id`) REFERENCES `size_charts` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- INVENTORY LOG (every stock change, who/when/why)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `inventory_logs` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `product_id` INT UNSIGNED NULL DEFAULT NULL,
  `variant_id` INT UNSIGNED NULL DEFAULT NULL,
  `change_qty` INT NOT NULL COMMENT 'positive = stock in, negative = stock out',
  `previous_qty` INT NOT NULL DEFAULT 0,
  `new_qty` INT NOT NULL DEFAULT 0,
  `reason` VARCHAR(190) NULL DEFAULT NULL,
  `reference_type` VARCHAR(50) NULL DEFAULT NULL COMMENT 'order | manual_adjustment | restock | ...',
  `reference_id` INT UNSIGNED NULL DEFAULT NULL,
  `admin_id` INT UNSIGNED NULL DEFAULT NULL,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_il_product` (`product_id`, `created_at`),
  KEY `idx_il_variant` (`variant_id`),
  KEY `idx_il_ref` (`reference_type`, `reference_id`),
  KEY `idx_il_admin` (`admin_id`),
  CONSTRAINT `fk_il_product` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_il_variant` FOREIGN KEY (`variant_id`) REFERENCES `product_variants` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_il_admin` FOREIGN KEY (`admin_id`) REFERENCES `admins` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- WISHLIST (guest via session_id, logged-in via customer_id)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `wishlist_items` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `customer_id` INT UNSIGNED NULL DEFAULT NULL,
  `session_id` VARCHAR(64) NULL DEFAULT NULL,
  `product_id` INT UNSIGNED NOT NULL,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_wl_customer` (`customer_id`, `product_id`),
  KEY `idx_wl_session` (`session_id`, `product_id`),
  KEY `idx_wl_product` (`product_id`),
  CONSTRAINT `fk_wl_customer` FOREIGN KEY (`customer_id`) REFERENCES `customers` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_wl_product` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- REVIEWS (+ photos). Never seeded — only real customer reviews.
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `reviews` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `product_id` INT UNSIGNED NOT NULL,
  `customer_id` INT UNSIGNED NULL DEFAULT NULL,
  `order_id` INT UNSIGNED NULL DEFAULT NULL,
  `name` VARCHAR(150) NOT NULL,
  `email` VARCHAR(190) NOT NULL,
  `rating` TINYINT UNSIGNED NOT NULL DEFAULT 5,
  `title` VARCHAR(190) NULL DEFAULT NULL,
  `body` TEXT NULL,
  `fit_feedback` VARCHAR(190) NULL DEFAULT NULL,
  `quality_rating` TINYINT UNSIGNED NULL DEFAULT NULL,
  `is_verified_purchase` TINYINT(1) NOT NULL DEFAULT 0,
  `status` ENUM('pending','approved','rejected','featured') NOT NULL DEFAULT 'pending',
  `helpful_yes` INT UNSIGNED NOT NULL DEFAULT 0,
  `helpful_no` INT UNSIGNED NOT NULL DEFAULT 0,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_rev_product_status` (`product_id`, `status`),
  KEY `idx_rev_status` (`status`),
  KEY `idx_rev_customer` (`customer_id`),
  KEY `idx_rev_order` (`order_id`),
  CONSTRAINT `fk_rev_product` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_rev_customer` FOREIGN KEY (`customer_id`) REFERENCES `customers` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_rev_order` FOREIGN KEY (`order_id`) REFERENCES `orders` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `review_images` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `review_id` INT UNSIGNED NOT NULL,
  `image` VARCHAR(255) NOT NULL,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_ri_review` (`review_id`),
  CONSTRAINT `fk_ri_review` FOREIGN KEY (`review_id`) REFERENCES `reviews` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- COUPONS (+ product / category / collection scoping, usage ledger)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `coupons` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `code` VARCHAR(50) NOT NULL,
  `description` VARCHAR(300) NULL DEFAULT NULL,
  `type` ENUM('percent','fixed') NOT NULL DEFAULT 'percent',
  `value` DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  `min_order` DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  `max_discount` DECIMAL(12,2) NULL DEFAULT NULL,
  `usage_limit` INT NOT NULL DEFAULT 0 COMMENT '0 = unlimited',
  `used_count` INT NOT NULL DEFAULT 0,
  `per_customer_limit` INT NOT NULL DEFAULT 1 COMMENT '0 = unlimited per customer',
  `is_first_order` TINYINT(1) NOT NULL DEFAULT 0,
  `starts_at` DATETIME NULL DEFAULT NULL,
  `expires_at` DATETIME NULL DEFAULT NULL,
  `status` TINYINT(1) NOT NULL DEFAULT 1,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_coupons_code` (`code`),
  KEY `idx_coupons_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `coupon_products` (
  `coupon_id` INT UNSIGNED NOT NULL,
  `product_id` INT UNSIGNED NOT NULL,
  PRIMARY KEY (`coupon_id`, `product_id`),
  KEY `idx_cp2_product` (`product_id`),
  CONSTRAINT `fk_cp2_coupon` FOREIGN KEY (`coupon_id`) REFERENCES `coupons` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_cp2_product` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `coupon_categories` (
  `coupon_id` INT UNSIGNED NOT NULL,
  `category_id` INT UNSIGNED NOT NULL,
  PRIMARY KEY (`coupon_id`, `category_id`),
  KEY `idx_cc_cat` (`category_id`),
  CONSTRAINT `fk_cc_coupon` FOREIGN KEY (`coupon_id`) REFERENCES `coupons` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_cc_category` FOREIGN KEY (`category_id`) REFERENCES `categories` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `coupon_collections` (
  `coupon_id` INT UNSIGNED NOT NULL,
  `collection_id` INT UNSIGNED NOT NULL,
  PRIMARY KEY (`coupon_id`, `collection_id`),
  KEY `idx_cc2_collection` (`collection_id`),
  CONSTRAINT `fk_cc2_coupon` FOREIGN KEY (`coupon_id`) REFERENCES `coupons` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_cc2_collection` FOREIGN KEY (`collection_id`) REFERENCES `collections` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `coupon_usages` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `coupon_id` INT UNSIGNED NOT NULL,
  `order_id` INT UNSIGNED NULL DEFAULT NULL,
  `customer_id` INT UNSIGNED NULL DEFAULT NULL,
  `email` VARCHAR(190) NULL DEFAULT NULL,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_cu_coupon` (`coupon_id`, `created_at`),
  KEY `idx_cu_order` (`order_id`),
  KEY `idx_cu_customer` (`customer_id`),
  CONSTRAINT `fk_cu_coupon` FOREIGN KEY (`coupon_id`) REFERENCES `coupons` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_cu_order` FOREIGN KEY (`order_id`) REFERENCES `orders` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_cu_customer` FOREIGN KEY (`customer_id`) REFERENCES `customers` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- ORDER STATUS HISTORY (timeline for order tracking)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `order_status_history` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `order_id` INT UNSIGNED NOT NULL,
  `status` VARCHAR(30) NOT NULL,
  `note` VARCHAR(500) NULL DEFAULT NULL,
  `admin_id` INT UNSIGNED NULL DEFAULT NULL,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_osh_order` (`order_id`, `created_at`),
  KEY `idx_osh_admin` (`admin_id`),
  CONSTRAINT `fk_osh_order` FOREIGN KEY (`order_id`) REFERENCES `orders` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_osh_admin` FOREIGN KEY (`admin_id`) REFERENCES `admins` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- PAYMENTS (gateway-ready ledger)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `payments` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `order_id` INT UNSIGNED NOT NULL,
  `method` VARCHAR(50) NOT NULL,
  `transaction_id` VARCHAR(100) NULL DEFAULT NULL,
  `amount` DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  `status` ENUM('pending','processing','paid','failed','refunded','partial') NOT NULL DEFAULT 'pending',
  `gateway` VARCHAR(50) NULL DEFAULT NULL,
  `raw_response` TEXT NULL,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_pay_order` (`order_id`),
  KEY `idx_pay_status` (`status`),
  CONSTRAINT `fk_pay_order` FOREIGN KEY (`order_id`) REFERENCES `orders` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- SHIPPING METHODS (admin-configurable)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `shipping_methods` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(100) NOT NULL,
  `code` VARCHAR(50) NOT NULL,
  `description` VARCHAR(300) NULL DEFAULT NULL,
  `fee` DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  `free_above` DECIMAL(12,2) NULL DEFAULT NULL,
  `estimated_days` VARCHAR(60) NULL DEFAULT NULL,
  `status` TINYINT(1) NOT NULL DEFAULT 1,
  `sort_order` INT NOT NULL DEFAULT 0,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_sm_code` (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- NOTIFICATIONS (customer notification centre)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `notifications` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `customer_id` INT UNSIGNED NULL DEFAULT NULL,
  `email` VARCHAR(190) NULL DEFAULT NULL,
  `type` VARCHAR(50) NULL DEFAULT NULL COMMENT 'order | promotion | back_in_stock | price_drop | reward | ...',
  `title` VARCHAR(190) NOT NULL,
  `body` TEXT NULL,
  `link` VARCHAR(255) NULL DEFAULT NULL,
  `is_read` TINYINT(1) NOT NULL DEFAULT 0,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_notif_customer` (`customer_id`, `is_read`),
  CONSTRAINT `fk_notif_customer` FOREIGN KEY (`customer_id`) REFERENCES `customers` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- CUSTOMER ADDRESSES
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `customer_addresses` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `customer_id` INT UNSIGNED NOT NULL,
  `label` VARCHAR(60) NULL DEFAULT NULL COMMENT 'Home | Work | ...',
  `name` VARCHAR(150) NULL DEFAULT NULL,
  `phone` VARCHAR(40) NULL DEFAULT NULL,
  `address` VARCHAR(255) NOT NULL,
  `city` VARCHAR(100) NOT NULL,
  `state` VARCHAR(100) NULL DEFAULT NULL,
  `postal_code` VARCHAR(20) NULL DEFAULT NULL,
  `country` VARCHAR(100) NULL DEFAULT 'Pakistan',
  `is_default` TINYINT(1) NOT NULL DEFAULT 0,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_ca_customer` (`customer_id`),
  CONSTRAINT `fk_ca_customer` FOREIGN KEY (`customer_id`) REFERENCES `customers` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- NAVIGATION MENUS (admin-controlled, mega-menu ready)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `menu_items` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `parent_id` INT UNSIGNED NULL DEFAULT NULL,
  `item_key` VARCHAR(100) NULL DEFAULT NULL COMMENT 'stable seed key for safe re-imports',
  `label` VARCHAR(100) NOT NULL,
  `url` VARCHAR(255) NOT NULL,
  `group_label` VARCHAR(60) NULL DEFAULT NULL COMMENT 'mega menu column heading',
  `location` ENUM('main','footer_shop','footer_explore','footer_care','footer_about','mobile') NOT NULL DEFAULT 'main',
  `sort_order` INT NOT NULL DEFAULT 0,
  `status` TINYINT(1) NOT NULL DEFAULT 1,
  `desktop_visible` TINYINT(1) NOT NULL DEFAULT 1,
  `mobile_visible` TINYINT(1) NOT NULL DEFAULT 1,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_menu_item_key` (`item_key`),
  KEY `idx_menu_location_status` (`location`, `status`, `sort_order`),
  KEY `idx_menu_parent` (`parent_id`),
  CONSTRAINT `fk_menu_parent` FOREIGN KEY (`parent_id`) REFERENCES `menu_items` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- HERO SLIDES (admin-managed homepage hero)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `hero_slides` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `eyebrow` VARCHAR(100) NULL DEFAULT NULL,
  `title` VARCHAR(190) NOT NULL,
  `subtitle` VARCHAR(300) NULL DEFAULT NULL,
  `image` VARCHAR(255) NULL DEFAULT NULL,
  `video_url` VARCHAR(255) NULL DEFAULT NULL,
  `cta_text` VARCHAR(60) NULL DEFAULT NULL,
  `cta_link` VARCHAR(255) NULL DEFAULT NULL,
  `cta_secondary_text` VARCHAR(60) NULL DEFAULT NULL,
  `cta_secondary_link` VARCHAR(255) NULL DEFAULT NULL,
  `sort_order` INT NOT NULL DEFAULT 0,
  `status` TINYINT(1) NOT NULL DEFAULT 1,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_hero_status_sort` (`status`, `sort_order`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- HOMEPAGE BUILDER (configurable sections)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `homepage_sections` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `section_key` VARCHAR(100) NOT NULL,
  `title` VARCHAR(190) NULL DEFAULT NULL,
  `subtitle` VARCHAR(300) NULL DEFAULT NULL,
  `content` TEXT NULL,
  `image` VARCHAR(255) NULL DEFAULT NULL,
  `cta_text` VARCHAR(60) NULL DEFAULT NULL,
  `cta_link` VARCHAR(255) NULL DEFAULT NULL,
  `sort_order` INT NOT NULL DEFAULT 0,
  `status` TINYINT(1) NOT NULL DEFAULT 1,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_hs_key` (`section_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- TESTIMONIALS (admin-managed; only real customer quotes)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `testimonials` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(150) NOT NULL,
  `role` VARCHAR(100) NULL DEFAULT NULL,
  `quote` TEXT NOT NULL,
  `image` VARCHAR(255) NULL DEFAULT NULL,
  `rating` TINYINT UNSIGNED NOT NULL DEFAULT 5,
  `sort_order` INT NOT NULL DEFAULT 0,
  `status` TINYINT(1) NOT NULL DEFAULT 1,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_testi_status_sort` (`status`, `sort_order`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- FAQS (admin-managed, categorised)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `faq_categories` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(100) NOT NULL,
  `slug` VARCHAR(150) NOT NULL,
  `sort_order` INT NOT NULL DEFAULT 0,
  `status` TINYINT(1) NOT NULL DEFAULT 1,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_faqc_slug` (`slug`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `faqs` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `category_id` INT UNSIGNED NULL DEFAULT NULL,
  `question` VARCHAR(500) NOT NULL,
  `answer` TEXT NOT NULL,
  `sort_order` INT NOT NULL DEFAULT 0,
  `status` TINYINT(1) NOT NULL DEFAULT 1,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_faqs_cat_status` (`category_id`, `status`, `sort_order`),
  CONSTRAINT `fk_faqs_category` FOREIGN KEY (`category_id`) REFERENCES `faq_categories` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- CMS PAGES (policies, fabric guide, care guide, style guides, about content)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `cms_pages` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `slug` VARCHAR(190) NOT NULL,
  `title` VARCHAR(190) NOT NULL,
  `content` LONGTEXT NULL,
  `meta_title` VARCHAR(200) NULL DEFAULT NULL,
  `meta_description` VARCHAR(500) NULL DEFAULT NULL,
  `status` TINYINT(1) NOT NULL DEFAULT 1,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_cms_slug` (`slug`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- SHOP THE LOOK / COMPLETE THE LOOK
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `looks` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(150) NOT NULL,
  `slug` VARCHAR(190) NOT NULL,
  `description` TEXT NULL,
  `image` VARCHAR(255) NULL DEFAULT NULL,
  `status` TINYINT(1) NOT NULL DEFAULT 1,
  `sort_order` INT NOT NULL DEFAULT 0,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_looks_slug` (`slug`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `look_products` (
  `look_id` INT UNSIGNED NOT NULL,
  `product_id` INT UNSIGNED NOT NULL,
  `label` VARCHAR(60) NULL DEFAULT NULL COMMENT 'e.g. Kurta | Trouser | Dupatta',
  `sort_order` INT NOT NULL DEFAULT 0,
  PRIMARY KEY (`look_id`, `product_id`),
  KEY `idx_lp_product` (`product_id`),
  CONSTRAINT `fk_lp_look` FOREIGN KEY (`look_id`) REFERENCES `looks` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_lp_product` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- BUNDLES (e.g. 3 Piece Summer Set) — bundle inventory validates every item
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `bundles` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(150) NOT NULL,
  `slug` VARCHAR(190) NOT NULL,
  `description` TEXT NULL,
  `image` VARCHAR(255) NULL DEFAULT NULL,
  `bundle_price` DECIMAL(12,2) NULL DEFAULT NULL,
  `status` TINYINT(1) NOT NULL DEFAULT 1,
  `sort_order` INT NOT NULL DEFAULT 0,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_bundles_slug` (`slug`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `bundle_items` (
  `bundle_id` INT UNSIGNED NOT NULL,
  `product_id` INT UNSIGNED NOT NULL,
  `quantity` INT NOT NULL DEFAULT 1,
  `sort_order` INT NOT NULL DEFAULT 0,
  PRIMARY KEY (`bundle_id`, `product_id`),
  KEY `idx_bi_product` (`product_id`),
  CONSTRAINT `fk_bi_bundle` FOREIGN KEY (`bundle_id`) REFERENCES `bundles` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_bi_product` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- GIFT CARDS (secure random code, balance ledger)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `gift_cards` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `code` VARCHAR(40) NOT NULL,
  `amount` DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  `balance` DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  `recipient_name` VARCHAR(150) NULL DEFAULT NULL,
  `recipient_email` VARCHAR(190) NULL DEFAULT NULL,
  `message` TEXT NULL,
  `delivery_date` DATE NULL DEFAULT NULL,
  `customer_id` INT UNSIGNED NULL DEFAULT NULL,
  `status` ENUM('active','partially_redeemed','redeemed','expired','void') NOT NULL DEFAULT 'active',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_gc_code` (`code`),
  KEY `idx_gc_status` (`status`),
  CONSTRAINT `fk_gc_customer` FOREIGN KEY (`customer_id`) REFERENCES `customers` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- PRODUCT ALERTS (back in stock / price drop / launch)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `product_alerts` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `type` ENUM('back_in_stock','price_drop','new_color','new_size','launch') NOT NULL DEFAULT 'back_in_stock',
  `product_id` INT UNSIGNED NOT NULL,
  `customer_id` INT UNSIGNED NULL DEFAULT NULL,
  `email` VARCHAR(190) NOT NULL,
  `phone` VARCHAR(40) NULL DEFAULT NULL,
  `desired_price` DECIMAL(12,2) NULL DEFAULT NULL,
  `notified_at` DATETIME NULL DEFAULT NULL,
  `status` TINYINT(1) NOT NULL DEFAULT 1,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_pa_product_type_email` (`product_id`, `type`, `email`),
  KEY `idx_pa_email` (`email`),
  CONSTRAINT `fk_pa_product` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_pa_customer` FOREIGN KEY (`customer_id`) REFERENCES `customers` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- RECENTLY VIEWED (privacy-conscious: per customer or session)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `recently_viewed` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `customer_id` INT UNSIGNED NULL DEFAULT NULL,
  `session_id` VARCHAR(64) NULL DEFAULT NULL,
  `product_id` INT UNSIGNED NOT NULL,
  `viewed_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_rv_customer` (`customer_id`, `product_id`),
  KEY `idx_rv_session` (`session_id`, `product_id`),
  KEY `idx_rv_product` (`product_id`),
  CONSTRAINT `fk_rv_customer` FOREIGN KEY (`customer_id`) REFERENCES `customers` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_rv_product` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- SEARCH ANALYTICS (aggregate only — top searches, no-result searches)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `search_logs` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `query` VARCHAR(190) NOT NULL,
  `results_count` INT NOT NULL DEFAULT 0,
  `customer_id` INT UNSIGNED NULL DEFAULT NULL,
  `session_id` VARCHAR(64) NULL DEFAULT NULL,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_sl_query` (`query`, `created_at`),
  KEY `idx_sl_created` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- ABANDONED CARTS (recovery-ready; never auto-sends without consent)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `abandoned_carts` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `customer_id` INT UNSIGNED NULL DEFAULT NULL,
  `session_id` VARCHAR(64) NULL DEFAULT NULL,
  `email` VARCHAR(190) NULL DEFAULT NULL,
  `phone` VARCHAR(40) NULL DEFAULT NULL,
  `cart_data` TEXT NULL COMMENT 'serialized cart snapshot',
  `subtotal` DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  `status` ENUM('active','recovered','closed') NOT NULL DEFAULT 'active',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_ac_status` (`status`, `updated_at`),
  KEY `idx_ac_customer` (`customer_id`),
  KEY `idx_ac_email` (`email`),
  CONSTRAINT `fk_ac_customer` FOREIGN KEY (`customer_id`) REFERENCES `customers` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- EMAIL TEMPLATES + LOG (transactional email architecture)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `email_templates` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `template_key` VARCHAR(100) NOT NULL,
  `subject` VARCHAR(190) NOT NULL,
  `body` TEXT NOT NULL,
  `status` TINYINT(1) NOT NULL DEFAULT 1,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_et_key` (`template_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `email_logs` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `recipient` VARCHAR(190) NOT NULL,
  `template_key` VARCHAR(100) NULL DEFAULT NULL,
  `subject` VARCHAR(190) NULL DEFAULT NULL,
  `status` ENUM('queued','sent','failed') NOT NULL DEFAULT 'queued',
  `error` VARCHAR(500) NULL DEFAULT NULL,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_el_recipient` (`recipient`, `created_at`),
  KEY `idx_el_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- PASSWORD RESET TOKENS (customer + admin)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `password_reset_tokens` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `email` VARCHAR(190) NOT NULL,
  `token` VARCHAR(64) NOT NULL,
  `expires_at` DATETIME NOT NULL,
  `used_at` DATETIME NULL DEFAULT NULL,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_prt_token` (`token`),
  KEY `idx_prt_email` (`email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- RBAC — ROLES & PERMISSIONS (admins.role stays for backward compatibility;
-- the new tables power fine-grained control)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `roles` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(60) NOT NULL,
  `description` VARCHAR(300) NULL DEFAULT NULL,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_roles_name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `permissions` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `permission_key` VARCHAR(100) NOT NULL,
  `description` VARCHAR(300) NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_perm_key` (`permission_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `role_permissions` (
  `role_id` INT UNSIGNED NOT NULL,
  `permission_id` INT UNSIGNED NOT NULL,
  PRIMARY KEY (`role_id`, `permission_id`),
  KEY `idx_rp_permission` (`permission_id`),
  CONSTRAINT `fk_rp_role` FOREIGN KEY (`role_id`) REFERENCES `roles` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_rp_permission` FOREIGN KEY (`permission_id`) REFERENCES `permissions` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `admin_roles` (
  `admin_id` INT UNSIGNED NOT NULL,
  `role_id` INT UNSIGNED NOT NULL,
  PRIMARY KEY (`admin_id`, `role_id`),
  KEY `idx_ar_role` (`role_id`),
  CONSTRAINT `fk_ar_admin` FOREIGN KEY (`admin_id`) REFERENCES `admins` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_ar_role` FOREIGN KEY (`role_id`) REFERENCES `roles` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- REFER & EARN
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `referrals` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `referrer_customer_id` INT UNSIGNED NOT NULL,
  `referral_code` VARCHAR(30) NOT NULL,
  `referred_email` VARCHAR(190) NOT NULL,
  `referred_customer_id` INT UNSIGNED NULL DEFAULT NULL,
  `status` ENUM('pending','converted','rewarded','void') NOT NULL DEFAULT 'pending',
  `reward_amount` DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_ref_code` (`referral_code`),
  KEY `idx_ref_referrer` (`referrer_customer_id`),
  KEY `idx_ref_email` (`referred_email`),
  CONSTRAINT `fk_ref_referrer` FOREIGN KEY (`referrer_customer_id`) REFERENCES `customers` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_ref_referred` FOREIGN KEY (`referred_customer_id`) REFERENCES `customers` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- REWARDS (points ledger + tiers — architecture only, configurable)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `reward_accounts` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `customer_id` INT UNSIGNED NOT NULL,
  `points_balance` INT NOT NULL DEFAULT 0,
  `lifetime_points` INT NOT NULL DEFAULT 0,
  `tier` ENUM('silver','gold','platinum') NOT NULL DEFAULT 'silver',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_ra_customer` (`customer_id`),
  CONSTRAINT `fk_ra_customer` FOREIGN KEY (`customer_id`) REFERENCES `customers` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `reward_transactions` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `account_id` INT UNSIGNED NOT NULL,
  `points_change` INT NOT NULL COMMENT 'positive = earned, negative = redeemed',
  `reason` VARCHAR(190) NOT NULL,
  `reference_type` VARCHAR(50) NULL DEFAULT NULL,
  `reference_id` INT UNSIGNED NULL DEFAULT NULL,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_rt_account` (`account_id`, `created_at`),
  CONSTRAINT `fk_rt_account` FOREIGN KEY (`account_id`) REFERENCES `reward_accounts` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- JOURNAL / BLOG
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `journal_categories` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(100) NOT NULL,
  `slug` VARCHAR(150) NOT NULL,
  `sort_order` INT NOT NULL DEFAULT 0,
  `status` TINYINT(1) NOT NULL DEFAULT 1,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_jc_slug` (`slug`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `journal_posts` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `category_id` INT UNSIGNED NULL DEFAULT NULL,
  `title` VARCHAR(190) NOT NULL,
  `slug` VARCHAR(220) NOT NULL,
  `excerpt` VARCHAR(500) NULL DEFAULT NULL,
  `content` LONGTEXT NULL,
  `image` VARCHAR(255) NULL DEFAULT NULL,
  `author` VARCHAR(150) NULL DEFAULT NULL,
  `status` ENUM('draft','published','archived') NOT NULL DEFAULT 'draft',
  `published_at` DATETIME NULL DEFAULT NULL,
  `meta_title` VARCHAR(200) NULL DEFAULT NULL,
  `meta_description` VARCHAR(500) NULL DEFAULT NULL,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_jp_slug` (`slug`),
  KEY `idx_jp_status` (`status`, `published_at`),
  KEY `idx_jp_category` (`category_id`),
  CONSTRAINT `fk_jp_category` FOREIGN KEY (`category_id`) REFERENCES `journal_categories` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- STYLE QUIZ (Find Your Style)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `quiz_questions` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `question` VARCHAR(300) NOT NULL,
  `question_type` ENUM('single','multi') NOT NULL DEFAULT 'single',
  `sort_order` INT NOT NULL DEFAULT 0,
  `status` TINYINT(1) NOT NULL DEFAULT 1,
  PRIMARY KEY (`id`),
  KEY `idx_qq_status_sort` (`status`, `sort_order`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `quiz_options` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `question_id` INT UNSIGNED NOT NULL,
  `label` VARCHAR(190) NOT NULL,
  `value` VARCHAR(190) NULL DEFAULT NULL COMMENT 'maps to product attributes: occasion/style/fabric/budget',
  `sort_order` INT NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `idx_qo_question` (`question_id`),
  CONSTRAINT `fk_qo_question` FOREIGN KEY (`question_id`) REFERENCES `quiz_questions` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `quiz_results` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `customer_id` INT UNSIGNED NULL DEFAULT NULL,
  `session_id` VARCHAR(64) NULL DEFAULT NULL,
  `answers` TEXT NULL COMMENT 'JSON of selected option values',
  `recommended_products` TEXT NULL COMMENT 'JSON product ids',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_qr_session` (`session_id`),
  KEY `idx_qr_customer` (`customer_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- PERSONAL SHOPPER REQUESTS
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `shopper_requests` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(150) NOT NULL,
  `phone` VARCHAR(40) NOT NULL,
  `email` VARCHAR(190) NULL DEFAULT NULL,
  `occasion` VARCHAR(100) NULL DEFAULT NULL,
  `budget` VARCHAR(100) NULL DEFAULT NULL,
  `preferred_style` VARCHAR(150) NULL DEFAULT NULL,
  `preferred_color` VARCHAR(150) NULL DEFAULT NULL,
  `preferred_size` VARCHAR(50) NULL DEFAULT NULL,
  `message` TEXT NULL,
  `status` ENUM('new','contacted','closed') NOT NULL DEFAULT 'new',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_sr_status` (`status`, `created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- CUSTOMER OUTFIT PHOTOS (#TAYYABACOLLECTIVE — admin-approved only)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `customer_photos` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `customer_id` INT UNSIGNED NULL DEFAULT NULL,
  `product_id` INT UNSIGNED NULL DEFAULT NULL,
  `image` VARCHAR(255) NOT NULL,
  `caption` VARCHAR(500) NULL DEFAULT NULL,
  `status` ENUM('pending','approved','rejected') NOT NULL DEFAULT 'pending',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_cph_status` (`status`),
  KEY `idx_cph_product` (`product_id`),
  CONSTRAINT `fk_cph_customer` FOREIGN KEY (`customer_id`) REFERENCES `customers` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_cph_product` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- CURRENCIES (admin-controlled; no fake exchange rates — rate stays NULL
-- until a live rate provider is integrated)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `currencies` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `code` VARCHAR(10) NOT NULL,
  `name` VARCHAR(60) NOT NULL,
  `symbol` VARCHAR(10) NULL DEFAULT NULL,
  `rate` DECIMAL(14,6) NULL DEFAULT NULL COMMENT 'NULL until a live provider is connected',
  `is_default` TINYINT(1) NOT NULL DEFAULT 0,
  `is_active` TINYINT(1) NOT NULL DEFAULT 0,
  `sort_order` INT NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_cur_code` (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- 3. NEW INDEXES + FOREIGN KEYS ON EXISTING TABLES
-- ============================================================================

CALL tc_add_index('products', 'idx_products_collection',    '(`collection_id`)');
CALL tc_add_index('products', 'idx_products_occasion',      '(`occasion`)');
CALL tc_add_index('products', 'idx_products_style',         '(`style`)');
CALL tc_add_index('products', 'idx_products_new',           '(`is_new`)');
CALL tc_add_index('products', 'idx_products_best_seller',   '(`is_best_seller`)');
CALL tc_add_index('products', 'idx_products_trending',      '(`is_trending`)');
CALL tc_add_index('products', 'idx_products_views',         '(`views`)');
CALL tc_add_index('products', 'idx_products_rating',        '(`rating_avg`)');
CALL tc_add_index('products', 'idx_products_sort',          '(`sort_order`)');

CALL tc_add_fk('products', 'fk_products_collection',
               'FOREIGN KEY (`collection_id`) REFERENCES `collections` (`id`) ON DELETE SET NULL');

CALL tc_add_index('orders', 'idx_orders_customer',   '(`customer_id`)');
CALL tc_add_index('orders', 'idx_orders_coupon',     '(`coupon_code`)');
CALL tc_add_index('orders', 'idx_orders_tracking',   '(`tracking_number`)');

CALL tc_add_fk('orders', 'fk_orders_customer',
               'FOREIGN KEY (`customer_id`) REFERENCES `customers` (`id`) ON DELETE SET NULL');

CALL tc_add_index('order_items', 'idx_oi_variant', '(`variant_id`)');
CALL tc_add_fk('order_items', 'fk_oi_variant',
               'FOREIGN KEY (`variant_id`) REFERENCES `product_variants` (`id`) ON DELETE SET NULL');

CALL tc_add_unique('customers', 'uq_customers_referral', '(`referral_code`)');

-- ============================================================================
-- 4. SEED: STORE SETTINGS (FASHLAB STUDIO)
--    INSERT IGNORE — existing keys are never overwritten.
-- ============================================================================

INSERT IGNORE INTO `settings` (`setting_key`, `setting_value`) VALUES
-- Brand / assets (real files shipped with the rebrand)
('brand_name',            'Fashlab Studio'),
('logo_path',             'images/brand/logo-wordmark.png'),
('logo_dark_path',        'images/brand/logo-wordmark.png'),
('favicon_path',          'images/brand/favicon.ico'),
('og_image',              'images/brand/logo-square.png'),
('seo_default_title',     'Fashlab Studio — Premium Stitched & Unstitched Fashion'),
-- Orders / checkout
('order_prefix',          'TC-'),
('tax_rate',              '0'),
('cod_enabled',           '1'),
('bank_transfer_enabled', '0'),
('online_payment_enabled','0'),
('express_delivery_fee',  '250'),
('delivery_estimate_standard', '3–5 working days'),
('delivery_estimate_express',  '1–2 working days'),
-- Policies (admin-editable)
('exchange_policy_days',  '7'),
('return_policy_days',    '7'),
-- Gift wrapping
('gift_wrapping_enabled', '1'),
('gift_wrapping_fee',     '250'),
('gift_wrapping_message_max', '300'),
-- Buy More Save More (configurable tiers, disabled until configured)
('buy_more_save_more_enabled', '0'),
('buy_more_save_more_tiers',   '{"2":5,"3":10,"4":15}'),
-- Loyalty / referrals (architecture ready, off by default)
('loyalty_enabled',       '0'),
('reward_points_per_rs',  '1'),
('reward_signup_bonus',   '100'),
('referral_enabled',      '0'),
('referral_reward_amount','200'),
('vip_enabled',           '0'),
-- Newsletter
('newsletter_heading',    'Be the first to know.'),
('newsletter_subtext',    'Join our list for early access to new arrivals, exclusive edits and private offers.'),
-- Footer / contact
('footer_about_text',     'Fashlab Studio — premium stitched and unstitched fashion for every occasion.'),
('business_hours',        'Mon – Sat · 11:00 AM – 8:00 PM'),
('pinterest_url',         ''),
('youtube_url',           ''),
-- WhatsApp ordering
('whatsapp_order_template','Hi Fashlab Studio, I am interested in:'),
-- Storefront behaviour
('products_per_page',     '12'),
('search_min_chars',      '2'),
('enable_wishlist',       '1'),
('enable_compare',        '1'),
('compare_max_items',     '4'),
('enable_recently_viewed','1'),
('enable_stock_alerts',   '1'),
('enable_reviews',        '1'),
('reviews_auto_approve',  '0'),
('enable_gift_cards',     '1'),
('size_chart_global_enabled', '1'),
('trending_window_days',  '14'),
('bestseller_window_days','90'),
('maintenance_message',   'We are updating our store. Please check back soon.');

-- ============================================================================
-- 5. SEED: RBAC ROLES + PERMISSIONS
-- ============================================================================

INSERT IGNORE INTO `roles` (`name`, `description`) VALUES
('super_admin',      'Full unrestricted access to every area of the admin panel.'),
('admin',            'Day-to-day store administration (no user/role management).'),
('manager',          'Store manager — orders, products, customers and reports.'),
('order_manager',    'Orders, payments, shipping and tracking only.'),
('product_manager',  'Products, categories, collections and inventory only.'),
('content_manager',  'CMS content, reviews, marketing, journal and FAQs only.');

INSERT IGNORE INTO `permissions` (`permission_key`, `description`) VALUES
('dashboard.view',      'View the admin dashboard and analytics'),
('orders.view',         'View orders and order details'),
('orders.manage',       'Update order status, payment status and tracking'),
('products.view',       'View the product catalogue'),
('products.manage',     'Create, edit, delete and publish products'),
('categories.manage',   'Manage categories'),
('collections.manage',  'Manage collections and looks'),
('inventory.manage',    'Manage stock and inventory logs'),
('customers.view',      'View customers and their order history'),
('customers.manage',    'Edit customers, addresses and status'),
('reviews.manage',      'Moderate reviews and customer photos'),
('coupons.manage',      'Manage coupons and discounts'),
('marketing.manage',    'Manage campaigns, bundles and gift cards'),
('content.manage',      'Manage CMS pages, FAQs, journal, hero and homepage sections'),
('settings.manage',     'Manage store settings'),
('users.manage',        'Manage admin users, roles and permissions'),
('reports.view',        'View reports and analytics'),
('audit.view',          'View the audit log');

-- super_admin: every permission
INSERT IGNORE INTO `role_permissions` (`role_id`, `permission_id`)
SELECT r.id, p.id FROM roles r CROSS JOIN permissions p WHERE r.name = 'super_admin';

-- admin: everything except user/role management
INSERT IGNORE INTO `role_permissions` (`role_id`, `permission_id`)
SELECT r.id, p.id FROM roles r CROSS JOIN permissions p
WHERE r.name = 'admin' AND p.permission_key NOT IN ('users.manage');

-- manager
INSERT IGNORE INTO `role_permissions` (`role_id`, `permission_id`)
SELECT r.id, p.id FROM roles r CROSS JOIN permissions p
WHERE r.name = 'manager'
  AND p.permission_key IN ('dashboard.view','orders.view','orders.manage','products.view','products.manage','categories.manage','collections.manage','inventory.manage','customers.view','reports.view');

-- order_manager
INSERT IGNORE INTO `role_permissions` (`role_id`, `permission_id`)
SELECT r.id, p.id FROM roles r CROSS JOIN permissions p
WHERE r.name = 'order_manager'
  AND p.permission_key IN ('dashboard.view','orders.view','orders.manage','customers.view');

-- product_manager
INSERT IGNORE INTO `role_permissions` (`role_id`, `permission_id`)
SELECT r.id, p.id FROM roles r CROSS JOIN permissions p
WHERE r.name = 'product_manager'
  AND p.permission_key IN ('products.view','products.manage','categories.manage','collections.manage','inventory.manage');

-- content_manager
INSERT IGNORE INTO `role_permissions` (`role_id`, `permission_id`)
SELECT r.id, p.id FROM roles r CROSS JOIN permissions p
WHERE r.name = 'content_manager'
  AND p.permission_key IN ('dashboard.view','reviews.manage','coupons.manage','marketing.manage','content.manage');

-- Link existing admins to their legacy role (admins.role) so RBAC is active
-- immediately without touching the admins table.
INSERT IGNORE INTO `admin_roles` (`admin_id`, `role_id`)
SELECT a.id, r.id FROM admins a JOIN roles r ON r.name = a.role;

-- ============================================================================
-- 6. SEED: SIZE CHARTS, COLOURS, SHIPPING, CURRENCIES
-- ============================================================================

-- Global women-apparel size chart. Values are standard industry cm ranges —
-- verify/adjust them once in the Admin before going live.
INSERT IGNORE INTO `size_charts` (`id`, `name`, `description`, `is_global`, `status`, `sort_order`) VALUES
(1, 'Women Apparel — Size Guide', 'Bust / Waist / Hip in centimetres for stitched and ready-to-wear pieces.', 1, 1, 1);

INSERT IGNORE INTO `size_chart_measurements` (`size_chart_id`, `size_label`, `chest_cm`, `waist_cm`, `hip_cm`, `shoulder_cm`, `length_cm`, `sort_order`) VALUES
(1, 'XS',   82.00, 64.00,  88.00, 36.00, 142.00, 1),
(1, 'S',    86.00, 68.00,  92.00, 37.00, 143.00, 2),
(1, 'M',    90.00, 72.00,  96.00, 38.00, 144.00, 3),
(1, 'L',    96.00, 78.00, 102.00, 39.00, 145.00, 4),
(1, 'XL',  102.00, 84.00, 108.00, 40.00, 146.00, 5),
(1, 'XXL', 108.00, 90.00, 114.00, 41.00, 147.00, 6);

-- Colour swatches for Shop By Color (admin-editable)
INSERT IGNORE INTO `colors` (`name`, `hex_code`, `sort_order`, `status`) VALUES
('Black', '#1C1C1C', 1, 1),
('White', '#FFFFFF', 2, 1),
('Ivory', '#FFFFF0', 3, 1),
('Beige', '#E8DCC8', 4, 1),
('Blush Pink', '#F4C2C2', 5, 1),
('Maroon', '#800000', 6, 1),
('Red', '#C62828', 7, 1),
('Emerald', '#046307', 8, 1),
('Green', '#2E7D32', 9, 1),
('Navy', '#000080', 10, 1),
('Blue', '#1976D2', 11, 1),
('Mustard', '#E1AD01', 12, 1),
('Charcoal', '#36454F', 13, 1),
('Dusty Rose', '#C9A9A6', 14, 1),
('Teal', '#008080', 15, 1),
('Purple', '#6A0DAD', 16, 1),
('Gold', '#B08D57', 17, 1),
('Grey', '#808080', 18, 1);

-- Shipping methods mirroring the checkout (standard + express)
INSERT IGNORE INTO `shipping_methods` (`name`, `code`, `description`, `fee`, `free_above`, `estimated_days`, `status`, `sort_order`) VALUES
('Standard Delivery', 'standard', 'Reliable nationwide delivery to your doorstep.', 250.00, 8000.00, '3–5 working days', 1, 1),
('Express Delivery',  'express',  'Faster delivery, prioritised dispatch.',          500.00, 8000.00, '1–2 working days', 1, 2);

-- Currencies: PKR is the live default; international currencies are
-- placeholders WITHOUT rates until a live exchange provider is connected.
INSERT IGNORE INTO `currencies` (`code`, `name`, `symbol`, `rate`, `is_default`, `is_active`, `sort_order`) VALUES
('PKR', 'Pakistani Rupee', 'Rs.', NULL, 1, 1, 1),
('USD', 'US Dollar',       '$',   NULL, 0, 0, 2),
('GBP', 'British Pound',   '£',   NULL, 0, 0, 3),
('AED', 'UAE Dirham',      'AED', NULL, 0, 0, 4),
('SAR', 'Saudi Riyal',     'SAR', NULL, 0, 0, 5),
('CAD', 'Canadian Dollar', 'C$',  NULL, 0, 0, 6);

-- ============================================================================
-- 7. SEED: COLLECTIONS (linked to REAL existing products — no invented stock)
-- ============================================================================

INSERT IGNORE INTO `collections` (`id`, `name`, `slug`, `collection_type`, `description`, `image`, `status`, `is_featured`, `sort_order`) VALUES
(1, 'Signature Collection', 'signature-collection', 'curated', 'The pieces that define Fashlab Studio — our featured favourites.', 'images/products/catalog-001.jpg', 1, 1, 1),
(2, 'Summer Edit',          'summer-edit',          'seasonal', 'Breathable lawn and cotton for warmer days.', 'images/products/catalog-021.jpg', 1, 1, 2),
(3, 'Festive Edit',         'festive-edit',         'seasonal', 'Statement pieces for festive celebrations.', 'images/products/catalog-022.jpg', 1, 0, 3),
(4, 'Wedding Edit',         'wedding-edit',         'seasonal', 'Elegant ensembles for weddings and special occasions.', 'images/products/catalog-064.jpg', 1, 0, 4),
(5, 'Luxury Collection',    'luxury-collection',    'theme',    'Our premium edit — silk, velvet and couture finishing.', 'images/products/catalog-026.jpg', 1, 0, 5),
(6, 'Everyday Essentials',  'everyday-essentials',  'theme',    'Easy, comfortable everyday silhouettes.', 'images/products/catalog-016.jpg', 1, 0, 6),
(7, 'Sale Edit',            'sale-edit',            'sale',     'Marked-down favourites — limited stock.', 'images/products/catalog-017.jpg', 1, 0, 7),
(8, 'New In',               'new-in',               'curated',  'The latest pieces, fresh from the studio.', 'images/products/catalog-010.jpg', 1, 0, 8);

-- Backfill collection membership from REAL existing data.
-- 1. Signature Collection  <- products flagged featured
INSERT IGNORE INTO `collection_products` (`collection_id`, `product_id`, `sort_order`)
SELECT 1, p.id, 0 FROM products p WHERE p.status = 1 AND p.featured = 1;

-- 2. Summer Edit           <- lawn + cotton categories
INSERT IGNORE INTO `collection_products` (`collection_id`, `product_id`, `sort_order`)
SELECT 2, pc.product_id, 0
FROM product_categories pc
JOIN categories c ON c.id = pc.category_id
WHERE c.slug IN ('lawn-collection', 'cotton-collection') AND pc.product_id IN (SELECT id FROM products WHERE status = 1);

-- 3. Festive Edit          <- festive + eid categories
INSERT IGNORE INTO `collection_products` (`collection_id`, `product_id`, `sort_order`)
SELECT 3, pc.product_id, 0
FROM product_categories pc
JOIN categories c ON c.id = pc.category_id
WHERE c.slug IN ('festive-collection', 'eid-collection') AND pc.product_id IN (SELECT id FROM products WHERE status = 1);

-- 4. Wedding Edit          <- formal + eastern categories
INSERT IGNORE INTO `collection_products` (`collection_id`, `product_id`, `sort_order`)
SELECT 4, pc.product_id, 0
FROM product_categories pc
JOIN categories c ON c.id = pc.category_id
WHERE c.slug IN ('formal-wear', 'eastern-wear') AND pc.product_id IN (SELECT id FROM products WHERE status = 1);

-- 5. Luxury Collection     <- luxury category
INSERT IGNORE INTO `collection_products` (`collection_id`, `product_id`, `sort_order`)
SELECT 5, pc.product_id, 0
FROM product_categories pc
JOIN categories c ON c.id = pc.category_id
WHERE c.slug = 'luxury-collection' AND pc.product_id IN (SELECT id FROM products WHERE status = 1);

-- 6. Everyday Essentials   <- casual + pret categories
INSERT IGNORE INTO `collection_products` (`collection_id`, `product_id`, `sort_order`)
SELECT 6, pc.product_id, 0
FROM product_categories pc
JOIN categories c ON c.id = pc.category_id
WHERE c.slug IN ('casual-wear', 'pret-wear') AND pc.product_id IN (SELECT id FROM products WHERE status = 1);

-- 7. Sale Edit             <- products with a REAL live discount
INSERT IGNORE INTO `collection_products` (`collection_id`, `product_id`, `sort_order`)
SELECT 7, p.id, 0 FROM products p
WHERE p.status = 1 AND p.sale_price IS NOT NULL AND p.sale_price > 0 AND p.sale_price < p.price;

-- 8. New In                <- products created in the last 60 days
INSERT IGNORE INTO `collection_products` (`collection_id`, `product_id`, `sort_order`)
SELECT 8, p.id, 0 FROM products p
WHERE p.status = 1 AND p.created_at >= DATE_SUB(NOW(), INTERVAL 60 DAY);

-- Set a deterministic primary collection on each product (first matching
-- collection in seed order wins) — admin can refine it per product later.
UPDATE products p SET collection_id = 1 WHERE collection_id IS NULL AND p.id IN (SELECT product_id FROM collection_products WHERE collection_id = 1);
UPDATE products p SET collection_id = 2 WHERE collection_id IS NULL AND p.id IN (SELECT product_id FROM collection_products WHERE collection_id = 2);
UPDATE products p SET collection_id = 3 WHERE collection_id IS NULL AND p.id IN (SELECT product_id FROM collection_products WHERE collection_id = 3);
UPDATE products p SET collection_id = 4 WHERE collection_id IS NULL AND p.id IN (SELECT product_id FROM collection_products WHERE collection_id = 4);
UPDATE products p SET collection_id = 5 WHERE collection_id IS NULL AND p.id IN (SELECT product_id FROM collection_products WHERE collection_id = 5);
UPDATE products p SET collection_id = 6 WHERE collection_id IS NULL AND p.id IN (SELECT product_id FROM collection_products WHERE collection_id = 6);
UPDATE products p SET collection_id = 7 WHERE collection_id IS NULL AND p.id IN (SELECT product_id FROM collection_products WHERE collection_id = 7);
UPDATE products p SET collection_id = 8 WHERE collection_id IS NULL AND p.id IN (SELECT product_id FROM collection_products WHERE collection_id = 8);

-- ============================================================================
-- 8. SEED: HERO SLIDES + HOMEPAGE SECTIONS
--    Hero uses a real in-project photo; titles match the current homepage.
-- ============================================================================

INSERT IGNORE INTO `hero_slides` (`id`, `eyebrow`, `title`, `subtitle`, `image`, `cta_text`, `cta_link`, `cta_secondary_text`, `cta_secondary_link`, `sort_order`, `status`) VALUES
(1, 'NEW SEASON', 'The Signature Edit', 'Timeless silhouettes. Contemporary elegance.', 'images/products/catalog-001.jpg', 'SHOP NEW ARRIVALS', 'shop.php?sort=newest', 'EXPLORE COLLECTION', 'collections.php', 1, 1);

INSERT IGNORE INTO `homepage_sections` (`section_key`, `title`, `subtitle`, `image`, `cta_text`, `cta_link`, `sort_order`, `status`) VALUES
('featured_collection', 'Featured Collection', 'The pieces our customers love most.', 'images/products/catalog-001.jpg', 'SHOP THE COLLECTION', 'shop.php?featured=1', 1, 1),
('shop_by_category',    'Shop By Category',   'Designed for every occasion.',          'images/products/catalog-031.jpg', 'VIEW ALL', 'collections.php', 2, 1),
('new_arrivals',        'New Arrivals',       'Fresh in from the studio.',             'images/products/catalog-010.jpg', 'SHOP NEW IN', 'shop.php?sort=newest', 3, 1),
('best_sellers',        'Best Sellers',       'The pieces everyone keeps coming back for.', 'images/products/catalog-038.jpg', 'SHOP BEST SELLERS', 'shop.php?sort=best_selling', 4, 1),
('editorial_banner',    'Made for Moments That Matter', 'An edit of our most-loved silhouettes.', 'images/products/catalog-026.jpg', 'EXPLORE', 'collections.php', 5, 1),
('shop_the_look',       'Shop The Look',      'Complete looks, styled for you.',       'images/products/catalog-064.jpg', 'VIEW LOOKS', 'looks.php', 6, 0),
('sale_collection',     'On Sale',            'Limited-time favourites.',              'images/products/catalog-017.jpg', 'SHOP SALE', 'shop.php?sale=1', 7, 1),
('why_us',              'Designed With You In Mind', 'Quality, care and craftsmanship in every piece.', NULL, NULL, NULL, 8, 1),
('testimonials',        'What Our Customers Say', NULL, NULL, NULL, NULL, 9, 1),
('instagram',           'Follow Our Style',   NULL, 'images/products/catalog-016.jpg', NULL, NULL, 10, 1),
('newsletter',          'Be the first to know.', 'Join our list for early access and private offers.', NULL, NULL, NULL, 11, 1);

-- ============================================================================
-- 9. SEED: NAVIGATION MENUS
--    status = 0 entries point at storefront pages that ship in the next
--    deployment wave (journal, looks, policies, track-order, size-guide).
--    Flip them on in the Admin as soon as the pages exist — nothing 404s
--    before then because disabled items are not rendered.
-- ============================================================================

-- -------- MAIN NAVIGATION (top level) --------
INSERT IGNORE INTO `menu_items` (`item_key`, `parent_id`, `label`, `url`, `group_label`, `location`, `sort_order`, `status`, `desktop_visible`, `mobile_visible`) VALUES
('main-shop',        NULL, 'Shop',          'shop.php',               NULL, 'main', 1, 1, 1, 1),
('main-collections', NULL, 'Collections',   'collections.php',        NULL, 'main', 2, 1, 1, 1),
('main-new-in',      NULL, 'New In',        'shop.php?sort=newest',   NULL, 'main', 3, 1, 1, 1),
('main-best-sellers',NULL, 'Best Sellers',  'shop.php?sort=best_selling', NULL, 'main', 4, 1, 1, 1),
('main-occasions',   NULL, 'Occasions',     'shop.php',               NULL, 'main', 5, 1, 1, 1),
('main-style-edit',  NULL, 'Style Edit',    'collections.php',        NULL, 'main', 6, 0, 1, 1),
('main-sale',        NULL, 'Sale',          'shop.php?sale=1',        NULL, 'main', 7, 1, 1, 1),
('main-journal',     NULL, 'Journal',       'journal.php',            NULL, 'main', 8, 0, 1, 1),
('main-about',       NULL, 'About',         'about.php',              NULL, 'main', 9, 1, 1, 1),
('main-contact',     NULL, 'Contact',       'contact.php',            NULL, 'main', 10, 1, 1, 1);

-- -------- SHOP MEGA MENU (children) --------
-- (parent ids resolved via a user variable: MySQL forbids reading the
--  target table inside INSERT ... VALUES subqueries)
SELECT id INTO @tc_menu_main_shop FROM menu_items WHERE item_key = 'main-shop' LIMIT 1;
INSERT IGNORE INTO `menu_items` (`item_key`, `parent_id`, `label`, `url`, `group_label`, `location`, `sort_order`, `status`, `desktop_visible`, `mobile_visible`) VALUES
('main-shop-stitched',   @tc_menu_main_shop, 'Stitched',   'category.php?slug=stitched',      'Clothing', 'main', 1, 1, 1, 1),
('main-shop-unstitched', @tc_menu_main_shop, 'Unstitched', 'category.php?slug=unstitched',    'Clothing', 'main', 2, 1, 1, 1),
('main-shop-2piece',     @tc_menu_main_shop, '2 Piece',    'category.php?slug=two-piece',     'Clothing', 'main', 3, 1, 1, 1),
('main-shop-3piece',     @tc_menu_main_shop, '3 Piece',    'category.php?slug=three-piece',   'Clothing', 'main', 4, 1, 1, 1),
('main-shop-kurtas',     @tc_menu_main_shop, 'Kurtas',     'shop.php?q=kurtas',               'Clothing', 'main', 5, 1, 1, 1),
('main-shop-coords',     @tc_menu_main_shop, 'Co-ords',    'shop.php?q=co-ord',               'Clothing', 'main', 6, 1, 1, 1),
('main-shop-dupattas',   @tc_menu_main_shop, 'Dupattas',   'shop.php?q=dupatta',              'Clothing', 'main', 7, 1, 1, 1),
('main-shop-trousers',   @tc_menu_main_shop, 'Trousers',   'shop.php?q=trouser',              'Clothing', 'main', 8, 1, 1, 1),
('main-shop-lawn',       @tc_menu_main_shop, 'Lawn',       'category.php?slug=lawn-collection', 'Shop By Fabric', 'main', 1, 1, 1, 1),
('main-shop-cotton',     @tc_menu_main_shop, 'Cotton',     'category.php?slug=cotton-collection', 'Shop By Fabric', 'main', 2, 1, 1, 1),
('main-shop-chiffon',    @tc_menu_main_shop, 'Chiffon',    'shop.php?q=chiffon',              'Shop By Fabric', 'main', 3, 1, 1, 1),
('main-shop-silk',       @tc_menu_main_shop, 'Silk',       'shop.php?q=silk',                 'Shop By Fabric', 'main', 4, 1, 1, 1),
('main-shop-linen',      @tc_menu_main_shop, 'Linen',      'category.php?slug=linen-collection', 'Shop By Fabric', 'main', 5, 1, 1, 1),
('main-shop-velvet',     @tc_menu_main_shop, 'Velvet',     'shop.php?q=velvet',               'Shop By Fabric', 'main', 6, 1, 1, 1),
('main-shop-khaddar',    @tc_menu_main_shop, 'Khaddar',    'shop.php?q=khaddar',              'Shop By Fabric', 'main', 7, 1, 1, 1),
('main-shop-price-1',    @tc_menu_main_shop, 'Under Rs. 5,000',     'shop.php?price=under-5000',   'Shop By Price', 'main', 1, 1, 1, 1),
('main-shop-price-2',    @tc_menu_main_shop, 'Rs. 5,000 – Rs. 10,000', 'shop.php?price=5000-10000', 'Shop By Price', 'main', 2, 1, 1, 1),
('main-shop-price-3',    @tc_menu_main_shop, 'Rs. 10,000 – Rs. 15,000', 'shop.php?price=10000-15000', 'Shop By Price', 'main', 3, 1, 1, 1),
('main-shop-price-4',    @tc_menu_main_shop, 'Above Rs. 15,000',    'shop.php?price=over-15000',   'Shop By Price', 'main', 4, 1, 1, 1),
('main-shop-new',        @tc_menu_main_shop, 'New Arrivals',  'shop.php?sort=newest',       'Featured', 'main', 1, 1, 1, 1),
('main-shop-best',       @tc_menu_main_shop, 'Best Sellers',  'shop.php?sort=best_selling', 'Featured', 'main', 2, 1, 1, 1),
('main-shop-trending',   @tc_menu_main_shop, 'Trending',      'shop.php?sort=newest',       'Featured', 'main', 3, 1, 1, 1),
('main-shop-limited',    @tc_menu_main_shop, 'Limited Edition','shop.php?sort=featured',    'Featured', 'main', 4, 1, 1, 1),
('main-shop-exclusive',  @tc_menu_main_shop, 'Exclusive',     'shop.php?sort=featured',     'Featured', 'main', 5, 1, 1, 1),
('main-shop-sale',       @tc_menu_main_shop, 'Sale',          'shop.php?sale=1',            'Featured', 'main', 6, 1, 1, 1);

-- -------- OCCASIONS (children) --------
SELECT id INTO @tc_menu_main_occasions FROM menu_items WHERE item_key = 'main-occasions' LIMIT 1;
INSERT IGNORE INTO `menu_items` (`item_key`, `parent_id`, `label`, `url`, `group_label`, `location`, `sort_order`, `status`, `desktop_visible`, `mobile_visible`) VALUES
('main-occ-wedding',   @tc_menu_main_occasions, 'Wedding Guest', 'category.php?slug=eastern-wear',      NULL, 'main', 1, 1, 1, 1),
('main-occ-formal',    @tc_menu_main_occasions, 'Formal',        'category.php?slug=formal-wear',       NULL, 'main', 2, 1, 1, 1),
('main-occ-casual',    @tc_menu_main_occasions, 'Casual',        'category.php?slug=casual-wear',       NULL, 'main', 3, 1, 1, 1),
('main-occ-festive',   @tc_menu_main_occasions, 'Festive',       'category.php?slug=festive-collection',NULL, 'main', 4, 1, 1, 1),
('main-occ-eid',       @tc_menu_main_occasions, 'Eid',           'category.php?slug=eid-collection',    NULL, 'main', 5, 1, 1, 1),
('main-occ-party',     @tc_menu_main_occasions, 'Party Wear',    'category.php?slug=western-wear',      NULL, 'main', 6, 1, 1, 1),
('main-occ-everyday',  @tc_menu_main_occasions, 'Everyday Wear', 'category.php?slug=pret-wear',         NULL, 'main', 7, 1, 1, 1),
('main-occ-luxury',    @tc_menu_main_occasions, 'Luxury',        'category.php?slug=luxury-collection', NULL, 'main', 8, 1, 1, 1),
('main-occ-office',    @tc_menu_main_occasions, 'Office Wear',   'shop.php?q=office',                   NULL, 'main', 9, 1, 1, 1),
('main-occ-dinner',    @tc_menu_main_occasions, 'Dinner',        'shop.php?q=dinner',                   NULL, 'main', 10, 1, 1, 1),
('main-occ-brunch',    @tc_menu_main_occasions, 'Brunch',        'shop.php?q=brunch',                   NULL, 'main', 11, 1, 1, 1);

-- -------- FOOTER: SHOP --------
INSERT IGNORE INTO `menu_items` (`item_key`, `parent_id`, `label`, `url`, `group_label`, `location`, `sort_order`, `status`, `desktop_visible`, `mobile_visible`) VALUES
('foot-shop-new',       NULL, 'New In',       'shop.php?sort=newest',       NULL, 'footer_shop', 1, 1, 1, 0),
('foot-shop-best',      NULL, 'Best Sellers', 'shop.php?sort=best_selling', NULL, 'footer_shop', 2, 1, 1, 0),
('foot-shop-stitched',  NULL, 'Stitched',     'category.php?slug=stitched', NULL, 'footer_shop', 3, 1, 1, 0),
('foot-shop-unstitched',NULL, 'Unstitched',   'category.php?slug=unstitched',NULL, 'footer_shop', 4, 1, 1, 0),
('foot-shop-collections',NULL,'Collections',  'collections.php',            NULL, 'footer_shop', 5, 1, 1, 0),
('foot-shop-sale',      NULL, 'Sale',         'shop.php?sale=1',            NULL, 'footer_shop', 6, 1, 1, 0);

-- -------- FOOTER: EXPLORE --------
INSERT IGNORE INTO `menu_items` (`item_key`, `parent_id`, `label`, `url`, `group_label`, `location`, `sort_order`, `status`, `desktop_visible`, `mobile_visible`) VALUES
('foot-explore-style',  NULL, 'Style Edit',    'collections.php',     NULL, 'footer_explore', 1, 0, 1, 0),
('foot-explore-looks',  NULL, 'Shop The Look', 'looks.php',           NULL, 'footer_explore', 2, 0, 1, 0),
('foot-explore-journal',NULL, 'Journal',       'journal.php',         NULL, 'footer_explore', 3, 0, 1, 0),
('foot-explore-fabric', NULL, 'Fabric Guide',  'fabric-guide.php',    NULL, 'footer_explore', 4, 0, 1, 0),
('foot-explore-care',   NULL, 'Care Guide',    'care-guide.php',      NULL, 'footer_explore', 5, 0, 1, 0);

-- -------- FOOTER: CUSTOMER CARE --------
INSERT IGNORE INTO `menu_items` (`item_key`, `parent_id`, `label`, `url`, `group_label`, `location`, `sort_order`, `status`, `desktop_visible`, `mobile_visible`) VALUES
('foot-care-contact',  NULL, 'Contact',       'contact.php',                         NULL, 'footer_care', 1, 1, 1, 0),
('foot-care-whatsapp', NULL, 'WhatsApp Support', 'contact.php',                      NULL, 'footer_care', 2, 1, 1, 0),
('foot-care-faq',      NULL, 'FAQs',          'faq.php',                            NULL, 'footer_care', 3, 0, 1, 0),
('foot-care-shipping', NULL, 'Shipping',      'policy.php?slug=shipping-policy',    NULL, 'footer_care', 4, 0, 1, 0),
('foot-care-returns',  NULL, 'Returns',       'policy.php?slug=return-policy',      NULL, 'footer_care', 5, 0, 1, 0),
('foot-care-exchange', NULL, 'Exchange',      'policy.php?slug=exchange-policy',    NULL, 'footer_care', 6, 0, 1, 0),
('foot-care-track',    NULL, 'Track Order',   'track-order.php',                    NULL, 'footer_care', 7, 0, 1, 0),
('foot-care-size',     NULL, 'Size Guide',    'size-guide.php',                     NULL, 'footer_care', 8, 0, 1, 0);

-- -------- FOOTER: ABOUT --------
INSERT IGNORE INTO `menu_items` (`item_key`, `parent_id`, `label`, `url`, `group_label`, `location`, `sort_order`, `status`, `desktop_visible`, `mobile_visible`) VALUES
('foot-about-story',  NULL, 'Our Story',      'about.php',   NULL, 'footer_about', 1, 1, 1, 0),
('foot-about-contact',NULL, 'Contact',        'contact.php', NULL, 'footer_about', 2, 1, 1, 0);

-- ============================================================================
-- 10. SEED: CMS PAGES (policy drafts — published only when admin adds content)
-- ============================================================================

INSERT IGNORE INTO `cms_pages` (`slug`, `title`, `content`, `meta_title`, `meta_description`, `status`) VALUES
('shipping-policy',  'Shipping Policy',  NULL, 'Shipping Policy — Fashlab Studio',  'Our shipping policy, delivery timelines and free-shipping details.', 0),
('return-policy',    'Return Policy',    NULL, 'Return Policy — Fashlab Studio',    'Our 7-day return policy explained.', 0),
('exchange-policy',  'Exchange Policy',  NULL, 'Exchange Policy — Fashlab Studio',  'How exchanges work within 7 days of delivery.', 0),
('privacy-policy',   'Privacy Policy',   NULL, 'Privacy Policy — Fashlab Studio',   'How we collect, use and protect your information.', 0),
('terms-conditions', 'Terms & Conditions', NULL, 'Terms & Conditions — Fashlab Studio', 'The terms that apply when you shop with us.', 0);

-- ============================================================================
-- 11. SEED: FAQ CATEGORIES + JOURNAL CATEGORIES (taxonomy only — no content)
-- ============================================================================

INSERT IGNORE INTO `faq_categories` (`name`, `slug`, `sort_order`, `status`) VALUES
('Orders', 'orders', 1, 1),
('Shipping', 'shipping', 2, 1),
('Payment', 'payment', 3, 1),
('Exchange & Returns', 'exchange-returns', 4, 1),
('Sizing', 'sizing', 5, 1),
('Products', 'products', 6, 1);

INSERT IGNORE INTO `journal_categories` (`name`, `slug`, `sort_order`, `status`) VALUES
('Fashion', 'fashion', 1, 1),
('Styling', 'styling', 2, 1),
('Fabrics', 'fabrics', 3, 1),
('Trends', 'trends', 4, 1),
('Collections', 'collections', 5, 1),
('Behind The Brand', 'behind-the-brand', 6, 1),
('Care Guide', 'care-guide', 7, 1);

-- ============================================================================
-- 12. SEED: EMAIL TEMPLATES (editable; placeholders like {{order_number}})
-- ============================================================================

INSERT IGNORE INTO `email_templates` (`template_key`, `subject`, `body`, `status`) VALUES
('order_confirmation', 'Your Fashlab Studio order {{order_number}} is confirmed', 'Hi {{customer_name}},\n\nThank you for your order {{order_number}}. We have received it and will confirm once it is processed.\n\nOrder total: {{order_total}}\nPayment method: {{payment_method}}\n\nWe will keep you updated at every step.\n\n— Fashlab Studio', 1),
('order_shipped', 'Your order {{order_number}} has shipped', 'Hi {{customer_name}},\n\nGreat news — your order {{order_number}} is on its way!\n\nTracking: {{tracking_number}}\nEstimated delivery: {{delivery_estimate}}\n\n— Fashlab Studio', 1),
('order_delivered', 'Your order {{order_number}} has been delivered', 'Hi {{customer_name}},\n\nYour order {{order_number}} has been delivered. We hope you love it!\n\nWe would love to hear what you think — leave a review for the pieces you ordered.\n\n— Fashlab Studio', 1),
('order_cancelled', 'Your order {{order_number}} has been cancelled', 'Hi {{customer_name}},\n\nYour order {{order_number}} has been cancelled. If this was unexpected, please contact us.\n\n— Fashlab Studio', 1),
('password_reset', 'Reset your Fashlab Studio password', 'Hi {{customer_name}},\n\nClick the link below to reset your password:\n{{reset_link}}\n\nThis link expires in 60 minutes.\n\n— Fashlab Studio', 1),
('welcome', 'Welcome to Fashlab Studio', 'Hi {{customer_name}},\n\nWelcome to Fashlab Studio. Explore our latest collections and enjoy a beautifully curated shopping experience.\n\n— Fashlab Studio', 1),
('back_in_stock', 'Good news — {{product_name}} is back in stock', 'Hi {{customer_name}},\n\nThe item you were waiting for is back:\n{{product_name}}\n{{product_url}}\n\n— Fashlab Studio', 1),
('review_request', 'How did you like {{product_name}}?', 'Hi {{customer_name}},\n\nWe hope you are enjoying your purchase. Share your feedback:\n{{review_url}}\n\n— Fashlab Studio', 1),
('newsletter', 'Fashlab Studio — {{newsletter_title}}', '{{newsletter_body}}\n\nUnsubscribe: {{unsubscribe_link}}\n\n— Fashlab Studio', 1);

-- ============================================================================
-- 13. BACKFILL DERIVED PRODUCT FLAGS FROM REAL DATA
--     (new-in = created recently; best-seller = real order history)
-- ============================================================================

UPDATE products SET is_new = 1
WHERE is_new = 0 AND created_at >= DATE_SUB(NOW(), INTERVAL 60 DAY);

UPDATE products p
JOIN (SELECT product_id, SUM(quantity) AS sold FROM order_items GROUP BY product_id HAVING SUM(quantity) >= 5) s ON s.product_id = p.id
SET p.is_best_seller = 1
WHERE p.is_best_seller = 0;

-- ============================================================================
-- 14. RECORD THIS MIGRATION
-- ============================================================================

INSERT IGNORE INTO `schema_migrations` (`migration_name`) VALUES ('2026-09-04_fashlab_enterprise_upgrade_v1');

-- ============================================================================
-- 15. CLEANUP: remove the temporary helper procedures
-- ============================================================================

DROP PROCEDURE IF EXISTS `tc_add_column`;
DROP PROCEDURE IF EXISTS `tc_add_index`;
DROP PROCEDURE IF EXISTS `tc_add_unique`;
DROP PROCEDURE IF EXISTS `tc_add_fk`;

-- ============================================================================
-- 16. VERIFICATION
--     Run the SELECTs below to confirm the migration applied cleanly.
-- ============================================================================

SELECT 'Existing tables extended' AS check_name, COUNT(*) AS count
FROM information_schema.COLUMNS
WHERE TABLE_SCHEMA = DATABASE()
  AND ((TABLE_NAME = 'products'   AND COLUMN_NAME IN ('occasion','is_new','is_best_seller','is_preorder','collection_id','meta_title'))
    OR (TABLE_NAME = 'orders'     AND COLUMN_NAME IN ('customer_id','tracking_number','coupon_code','order_status'))
    OR (TABLE_NAME = 'categories' AND COLUMN_NAME IN ('banner','meta_description')));

SELECT 'New feature tables' AS check_name, COUNT(*) AS count
FROM information_schema.TABLES
WHERE TABLE_SCHEMA = DATABASE()
  AND TABLE_NAME IN ('collections','collection_products','colors','size_charts','size_chart_measurements','inventory_logs','wishlist_items','reviews','review_images','coupons','coupon_products','coupon_categories','coupon_collections','coupon_usages','order_status_history','payments','shipping_methods','notifications','customer_addresses','menu_items','hero_slides','homepage_sections','testimonials','faq_categories','faqs','cms_pages','looks','look_products','bundles','bundle_items','gift_cards','product_alerts','recently_viewed','search_logs','abandoned_carts','email_templates','email_logs','password_reset_tokens','roles','permissions','role_permissions','admin_roles','referrals','reward_accounts','reward_transactions','journal_categories','journal_posts','quiz_questions','quiz_options','quiz_results','shopper_requests','customer_photos','currencies','schema_migrations');

SELECT 'Products linked to collections' AS check_name, COUNT(DISTINCT product_id) AS count FROM collection_products;

SELECT 'Main nav menu items' AS check_name, COUNT(*) AS count FROM menu_items WHERE location = 'main';