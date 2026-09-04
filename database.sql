-- ============================================================================
-- TAYYABACOLLECTIVE — E-COMMERCE DATABASE
-- MySQL / MariaDB schema + seed data
-- Import via phpMyAdmin or:  mysql -u USER -p < database.sql
-- ============================================================================

CREATE DATABASE IF NOT EXISTS `tayyaba_collective`
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE `tayyaba_collective`;

SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS `login_attempts`;
DROP TABLE IF EXISTS `admin_activity_logs`;
DROP TABLE IF EXISTS `order_items`;
DROP TABLE IF EXISTS `orders`;
DROP TABLE IF EXISTS `product_images`;
DROP TABLE IF EXISTS `product_variants`;
DROP TABLE IF EXISTS `product_categories`;
DROP TABLE IF EXISTS `products`;
DROP TABLE IF EXISTS `categories`;
DROP TABLE IF EXISTS `customers`;
DROP TABLE IF EXISTS `subscribers`;
DROP TABLE IF EXISTS `contact_messages`;
DROP TABLE IF EXISTS `settings`;
DROP TABLE IF EXISTS `admins`;
SET FOREIGN_KEY_CHECKS = 1;

-- ============================================================================
-- ADMINS
-- ============================================================================

CREATE TABLE `admins` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(100) NOT NULL,
  `email` VARCHAR(190) NOT NULL,
  `password_hash` VARCHAR(255) NOT NULL,
  `role` ENUM('super_admin','admin') NOT NULL DEFAULT 'admin',
  `status` TINYINT(1) NOT NULL DEFAULT 1,
  `last_login` DATETIME NULL DEFAULT NULL,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_admins_email` (`email`),
  KEY `idx_admins_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- CATEGORIES (hierarchical; parent_id optional)
-- ============================================================================

CREATE TABLE `categories` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `parent_id` INT UNSIGNED NULL DEFAULT NULL,
  `name` VARCHAR(150) NOT NULL,
  `slug` VARCHAR(190) NOT NULL,
  `description` TEXT NULL,
  `image` VARCHAR(255) NULL,
  `status` TINYINT(1) NOT NULL DEFAULT 1,
  `show_in_nav` TINYINT(1) NOT NULL DEFAULT 0,
  `sort_order` INT NOT NULL DEFAULT 0,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_categories_slug` (`slug`),
  KEY `idx_categories_status_sort` (`status`, `sort_order`),
  KEY `idx_categories_parent` (`parent_id`),
  CONSTRAINT `fk_categories_parent` FOREIGN KEY (`parent_id`)
    REFERENCES `categories` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- PRODUCTS
-- ============================================================================

CREATE TABLE `products` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `category_id` INT UNSIGNED NULL DEFAULT NULL COMMENT 'Primary category (convenience). Product may belong to many categories via product_categories.',
  `name` VARCHAR(200) NOT NULL,
  `slug` VARCHAR(220) NOT NULL,
  `sku` VARCHAR(100) NOT NULL,
  `short_description` VARCHAR(500) NULL DEFAULT NULL,
  `description` TEXT NULL,
  `price` DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  `sale_price` DECIMAL(12,2) NULL DEFAULT NULL,
  `cost_price` DECIMAL(12,2) NULL DEFAULT NULL,
  `stock_quantity` INT NOT NULL DEFAULT 0,
  `stock_status` ENUM('in_stock','low_stock','out_of_stock','backorder') NOT NULL DEFAULT 'in_stock',
  `product_type` VARCHAR(100) NULL DEFAULT NULL,
  `fabric` VARCHAR(150) NULL DEFAULT NULL,
  `color` VARCHAR(150) NULL DEFAULT NULL,
  `size` VARCHAR(150) NULL DEFAULT NULL,
  `featured` TINYINT(1) NOT NULL DEFAULT 0,
  `status` TINYINT(1) NOT NULL DEFAULT 1,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_products_slug` (`slug`),
  UNIQUE KEY `uq_products_sku` (`sku`),
  KEY `idx_products_category` (`category_id`),
  KEY `idx_products_status` (`status`),
  KEY `idx_products_featured` (`featured`),
  KEY `idx_products_sale` (`sale_price`),
  KEY `idx_products_created` (`created_at`),
  KEY `idx_products_stock_status` (`stock_status`),
  CONSTRAINT `fk_products_category` FOREIGN KEY (`category_id`)
    REFERENCES `categories` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- PRODUCT <-> CATEGORY (many-to-many)
-- ============================================================================

CREATE TABLE `product_categories` (
  `product_id` INT UNSIGNED NOT NULL,
  `category_id` INT UNSIGNED NOT NULL,
  PRIMARY KEY (`product_id`, `category_id`),
  KEY `idx_pc_category` (`category_id`),
  CONSTRAINT `fk_pc_product` FOREIGN KEY (`product_id`)
    REFERENCES `products` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_pc_category` FOREIGN KEY (`category_id`)
    REFERENCES `categories` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- PRODUCT IMAGES
-- ============================================================================

CREATE TABLE `product_images` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `product_id` INT UNSIGNED NOT NULL,
  `image` VARCHAR(255) NOT NULL,
  `sort_order` INT NOT NULL DEFAULT 0,
  `is_primary` TINYINT(1) NOT NULL DEFAULT 0,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_pi_product` (`product_id`),
  CONSTRAINT `fk_pi_product` FOREIGN KEY (`product_id`)
    REFERENCES `products` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- PRODUCT VARIANTS
-- ============================================================================

CREATE TABLE `product_variants` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `product_id` INT UNSIGNED NOT NULL,
  `variant_name` VARCHAR(100) NOT NULL,
  `variant_value` VARCHAR(150) NOT NULL,
  `price_adjustment` DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  `stock_quantity` INT NOT NULL DEFAULT 0,
  `sku` VARCHAR(100) NULL DEFAULT NULL,
  `status` TINYINT(1) NOT NULL DEFAULT 1,
  PRIMARY KEY (`id`),
  KEY `idx_pv_product` (`product_id`),
  CONSTRAINT `fk_pv_product` FOREIGN KEY (`product_id`)
    REFERENCES `products` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- ORDERS
-- ============================================================================

CREATE TABLE `orders` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `order_number` VARCHAR(40) NOT NULL,
  `customer_name` VARCHAR(150) NOT NULL,
  `customer_email` VARCHAR(190) NOT NULL,
  `customer_phone` VARCHAR(40) NULL DEFAULT NULL,
  `shipping_address` TEXT NULL,
  `city` VARCHAR(100) NULL DEFAULT NULL,
  `postal_code` VARCHAR(20) NULL DEFAULT NULL,
  `notes` TEXT NULL,
  `subtotal` DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  `shipping_fee` DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  `discount` DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  `total` DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  `payment_method` VARCHAR(50) NOT NULL DEFAULT 'cod',
  `payment_status` ENUM('pending','paid','failed','refunded') NOT NULL DEFAULT 'pending',
  `order_status` ENUM('pending','confirmed','processing','shipped','delivered','cancelled') NOT NULL DEFAULT 'pending',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_orders_number` (`order_number`),
  KEY `idx_orders_email` (`customer_email`),
  KEY `idx_orders_status` (`order_status`),
  KEY `idx_orders_created` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- ORDER ITEMS
-- ============================================================================

CREATE TABLE `order_items` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `order_id` INT UNSIGNED NOT NULL,
  `product_id` INT UNSIGNED NULL DEFAULT NULL,
  `product_name` VARCHAR(200) NOT NULL,
  `variant_label` VARCHAR(200) NULL DEFAULT NULL,
  `quantity` INT NOT NULL DEFAULT 1,
  `price` DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  `subtotal` DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  PRIMARY KEY (`id`),
  KEY `idx_oi_order` (`order_id`),
  KEY `idx_oi_product` (`product_id`),
  CONSTRAINT `fk_oi_order` FOREIGN KEY (`order_id`)
    REFERENCES `orders` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_oi_product` FOREIGN KEY (`product_id`)
    REFERENCES `products` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- CUSTOMERS
-- ============================================================================

CREATE TABLE `customers` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(150) NULL DEFAULT NULL,
  `email` VARCHAR(190) NOT NULL,
  `phone` VARCHAR(40) NULL DEFAULT NULL,
  `password_hash` VARCHAR(255) NULL DEFAULT NULL,
  `status` TINYINT(1) NOT NULL DEFAULT 1,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_customers_email` (`email`),
  KEY `idx_customers_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- SUBSCRIBERS (newsletter)
-- ============================================================================

CREATE TABLE `subscribers` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `email` VARCHAR(190) NOT NULL,
  `status` TINYINT(1) NOT NULL DEFAULT 1,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_subscribers_email` (`email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- CONTACT MESSAGES
-- ============================================================================

CREATE TABLE `contact_messages` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(150) NOT NULL,
  `email` VARCHAR(190) NOT NULL,
  `phone` VARCHAR(40) NULL DEFAULT NULL,
  `subject` VARCHAR(200) NULL DEFAULT NULL,
  `message` TEXT NOT NULL,
  `status` ENUM('new','read','replied','archived') NOT NULL DEFAULT 'new',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_cm_status` (`status`),
  KEY `idx_cm_created` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- ADMIN ACTIVITY LOG
-- ============================================================================

CREATE TABLE `admin_activity_logs` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `admin_id` INT UNSIGNED NULL DEFAULT NULL,
  `action` VARCHAR(100) NOT NULL,
  `entity_type` VARCHAR(50) NULL DEFAULT NULL,
  `entity_id` INT UNSIGNED NULL DEFAULT NULL,
  `description` VARCHAR(500) NULL DEFAULT NULL,
  `ip_address` VARCHAR(45) NULL DEFAULT NULL,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_aal_admin` (`admin_id`),
  KEY `idx_aal_entity` (`entity_type`, `entity_id`),
  KEY `idx_aal_created` (`created_at`),
  CONSTRAINT `fk_aal_admin` FOREIGN KEY (`admin_id`)
    REFERENCES `admins` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- SETTINGS (key/value store)
-- ============================================================================

CREATE TABLE `settings` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `setting_key` VARCHAR(100) NOT NULL,
  `setting_value` TEXT NULL,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_settings_key` (`setting_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- LOGIN ATTEMPTS (brute-force protection)
-- ============================================================================

CREATE TABLE `login_attempts` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `identifier` VARCHAR(190) NOT NULL COMMENT 'Email attempted (lowercased)',
  `ip_address` VARCHAR(45) NOT NULL,
  `attempted_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_la_identifier` (`identifier`, `attempted_at`),
  KEY `idx_la_ip` (`ip_address`, `attempted_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- SEED: SETTINGS
-- ============================================================================

INSERT INTO `settings` (`setting_key`, `setting_value`) VALUES
('store_name', 'Fashlab Studio'),
('store_tagline', 'Where Style Meets Elegance'),
('store_email', 'hello@tayyabacollective.mytechrcm.com'),
('store_phone', '+92 300 1234567'),
('store_address', 'TayyabaCollective Studio, Islamabad, Pakistan'),
('currency', 'Rs'),
('currency_symbol', 'Rs.'),
('shipping_fee', '250'),
('free_shipping_threshold', '8000'),
('min_order_amount', '0'),
('low_stock_threshold', '5'),
('announcement_bar', 'Free delivery on orders above Rs. 8,000'),
('instagram_url', '#'),
('facebook_url', '#'),
('linkedin_url', '#'),
('tiktok_url', '#'),
('whatsapp_number', '+92 334 232 2324'),
('store_status', 'open'),
('meta_description', 'Discover TayyabaCollective — elegant stitched, unstitched, eastern and western wear designed for every occasion.'),
('footer_credit', 'Developed by Gopang IT Solution');

-- ============================================================================
-- SEED: CATEGORIES
-- ============================================================================

INSERT INTO `categories` (`id`, `parent_id`, `name`, `slug`, `description`, `image`, `status`, `show_in_nav`, `sort_order`) VALUES
(1,  NULL, 'Stitched',            'stitched',           'Ready-to-wear stitched suits and dresses in premium fabrics.', 'images/products/catalog-001.jpg', 1, 1, 1),
(2,  NULL, 'Unstitched',          'unstitched',         'Beautiful unstitched fabric suits — lawn, cotton and more.',  'images/products/catalog-031.jpg', 1, 1, 2),
(3,  NULL, 'New Arrivals',        'new-arrivals',       'The latest pieces, fresh in from the TayyabaCollective studio.', 'images/products/catalog-010.jpg', 1, 1, 3),
(4,  NULL, 'Best Sellers',        'best-sellers',       'The pieces our customers keep coming back for.', 'images/products/catalog-038.jpg', 1, 0, 4),
(5,  NULL, 'Sale',                'sale',               'Marked-down favourites — limited stock.', 'images/products/catalog-017.jpg', 1, 1, 5),
(6,  NULL, 'Formal Wear',         'formal-wear',        'Elegant ensembles for weddings, evenings and special occasions.', 'images/products/catalog-064.jpg', 1, 1, 6),
(7,  NULL, 'Casual Wear',         'casual-wear',        'Easy, comfortable everyday silhouettes.', 'images/products/catalog-016.jpg', 1, 1, 7),
(8,  NULL, 'Luxury Collection',   'luxury-collection',  'Our premium edit — silk, velvet and couture finishing.', 'images/products/catalog-026.jpg', 1, 1, 8),
(9,  NULL, 'Eid Collection',      'eid-collection',     'Celebrate the season in style.', NULL, 1, 0, 9),
(10, NULL, 'Festive Collection',  'festive-collection', 'Statement pieces for festive celebrations.', 'images/products/catalog-022.jpg', 1, 0, 10),
(11, NULL, 'Lawn Collection',     'lawn-collection',    'Breathable premium lawn suits for warmer days.', 'images/products/catalog-021.jpg', 1, 0, 11),
(12, NULL, 'Cotton Collection',   'cotton-collection',  'Soft, breathable cotton sets for everyday comfort.', 'images/products/catalog-009.jpg', 1, 0, 12),
(13, NULL, 'Linen Collection',    'linen-collection',   'Relaxed linen pieces with a refined drape.', 'images/products/catalog-074.jpg', 1, 0, 13),
(14, NULL, 'Embroidered',         'embroidered',        'Hand-finished embroidery and embellished detailing.', 'images/products/catalog-011.jpg', 1, 0, 14),
(15, NULL, 'Printed',             'printed',            'Fresh prints and timeless patterns.', 'images/products/catalog-029.jpg', 1, 0, 15),
(16, NULL, 'Pret Wear',           'pret-wear',          'Modern ready-to-wear styles for every day.', 'images/products/catalog-003.jpg', 1, 0, 16),
(17, NULL, 'Two Piece',           'two-piece',          'Coordinated two-piece sets.', NULL, 1, 0, 17),
(18, NULL, 'Three Piece',         'three-piece',        'Complete three-piece ensembles.', 'images/products/catalog-047.jpg', 1, 0, 18),
(19, NULL, 'Western Wear',        'western-wear',       'Contemporary western silhouettes — blazers, co-ords and dresses.', 'images/products/catalog-066.jpg', 1, 0, 19),
(20, NULL, 'Eastern Wear',        'eastern-wear',       'Traditional eastern ensembles — shararas, gowns and angrakhas.', 'images/products/catalog-091.jpg', 1, 0, 20);

-- ============================================================================
-- SEED: ADMIN ACCOUNT
-- Email:    admin@tayyabacollective.mytechrcm.com
-- Password: stored below ONLY as a bcrypt hash. The default password is
--           documented in SETUP.md — log in and change it immediately.
-- ============================================================================

INSERT INTO `admins` (`name`, `email`, `password_hash`, `role`, `status`) VALUES
('Super Admin', 'admin@tayyabacollective.mytechrcm.com', '$2y$10$lJ7L.KkTsnnEFxjdL/myEOIuPr1l4NZoUAbh7.ND7PToSzB817VxS', 'super_admin', 1);

-- ============================================================================
-- PRODUCT SEED DATA (migrated from the original static catalogue)
-- Appended by scripts/generate-seed.js — do not edit manually.
-- ============================================================================
-- ============================================================================
-- MIGRATED PRODUCTS (120 — generated by scripts/generate-seed.js)
-- ============================================================================

INSERT INTO `products` (`category_id`, `name`, `slug`, `sku`, `short_description`, `description`, `price`, `sale_price`, `cost_price`, `stock_quantity`, `stock_status`, `product_type`, `fabric`, `color`, `size`, `featured`, `status`, `created_at`) VALUES
(1, 'Areeba Floral Lawn Set', 'areeba-floral-lawn-set', 'TC-ST-0001', 'A thoughtfully designed stitched piece with refined finishing and an easy, elegant fit.', 'A thoughtfully designed stitched piece with refined finishing and an easy, elegant fit. Crafted from carefully selected fabric with attention to detail, this piece is part of the TayyabaCollective collection — designed to make you feel confident, comfortable and beautifully you.', 6200, 5456, NULL, 0, 'out_of_stock', 'Stitched', 'Premium lawn & chiffon', 'Maroon & Gold', 'S · M · L · XL', 1, 1, DATE_SUB(NOW(), INTERVAL 1 DAY));
INSERT INTO `products` (`category_id`, `name`, `slug`, `sku`, `short_description`, `description`, `price`, `sale_price`, `cost_price`, `stock_quantity`, `stock_status`, `product_type`, `fabric`, `color`, `size`, `featured`, `status`, `created_at`) VALUES
(1, 'Nisha Printed Lawn Kurta', 'nisha-printed-lawn-kurta', 'TC-ST-0002', 'A thoughtfully designed stitched piece with refined finishing and an easy, elegant fit.', 'A thoughtfully designed stitched piece with refined finishing and an easy, elegant fit. Crafted from carefully selected fabric with attention to detail, this piece is part of the TayyabaCollective collection — designed to make you feel confident, comfortable and beautifully you.', 6875, NULL, NULL, 10, 'in_stock', 'Stitched', 'Premium lawn & chiffon', 'Ivory', 'S · M · L · XL', 0, 1, DATE_SUB(NOW(), INTERVAL 2 DAY));
INSERT INTO `products` (`category_id`, `name`, `slug`, `sku`, `short_description`, `description`, `price`, `sale_price`, `cost_price`, `stock_quantity`, `stock_status`, `product_type`, `fabric`, `color`, `size`, `featured`, `status`, `created_at`) VALUES
(1, 'Hiba Cotton Shirt Set', 'hiba-cotton-shirt-set', 'TC-ST-0003', 'A thoughtfully designed stitched piece with refined finishing and an easy, elegant fit.', 'A thoughtfully designed stitched piece with refined finishing and an easy, elegant fit. Crafted from carefully selected fabric with attention to detail, this piece is part of the TayyabaCollective collection — designed to make you feel confident, comfortable and beautifully you.', 7550, NULL, NULL, 17, 'in_stock', 'Stitched', 'Premium lawn & chiffon', 'Emerald', 'S · M · L · XL', 0, 1, DATE_SUB(NOW(), INTERVAL 3 DAY));
INSERT INTO `products` (`category_id`, `name`, `slug`, `sku`, `short_description`, `description`, `price`, `sale_price`, `cost_price`, `stock_quantity`, `stock_status`, `product_type`, `fabric`, `color`, `size`, `featured`, `status`, `created_at`) VALUES
(1, 'Sana Formal Linen Ensemble', 'sana-formal-linen-ensemble', 'TC-ST-0004', 'A thoughtfully designed stitched piece with refined finishing and an easy, elegant fit.', 'A thoughtfully designed stitched piece with refined finishing and an easy, elegant fit. Crafted from carefully selected fabric with attention to detail, this piece is part of the TayyabaCollective collection — designed to make you feel confident, comfortable and beautifully you.', 8225, NULL, NULL, 24, 'in_stock', 'Stitched', 'Premium lawn & chiffon', 'Navy', 'S · M · L · XL', 0, 1, DATE_SUB(NOW(), INTERVAL 4 DAY));
INSERT INTO `products` (`category_id`, `name`, `slug`, `sku`, `short_description`, `description`, `price`, `sale_price`, `cost_price`, `stock_quantity`, `stock_status`, `product_type`, `fabric`, `color`, `size`, `featured`, `status`, `created_at`) VALUES
(1, 'Alina Pastel Chiffon Three Piece', 'alina-pastel-chiffon-three-piece', 'TC-ST-0005', 'A thoughtfully designed stitched piece with refined finishing and an easy, elegant fit.', 'A thoughtfully designed stitched piece with refined finishing and an easy, elegant fit. Crafted from carefully selected fabric with attention to detail, this piece is part of the TayyabaCollective collection — designed to make you feel confident, comfortable and beautifully you.', 8900, NULL, NULL, 31, 'in_stock', 'Stitched', 'Premium lawn & chiffon', 'Blush Pink', 'S · M · L · XL', 0, 1, DATE_SUB(NOW(), INTERVAL 5 DAY));
INSERT INTO `products` (`category_id`, `name`, `slug`, `sku`, `short_description`, `description`, `price`, `sale_price`, `cost_price`, `stock_quantity`, `stock_status`, `product_type`, `fabric`, `color`, `size`, `featured`, `status`, `created_at`) VALUES
(1, 'Noor Festive Cotton Suit', 'noor-festive-cotton-suit', 'TC-ST-0006', 'A thoughtfully designed stitched piece with refined finishing and an easy, elegant fit.', 'A thoughtfully designed stitched piece with refined finishing and an easy, elegant fit. Crafted from carefully selected fabric with attention to detail, this piece is part of the TayyabaCollective collection — designed to make you feel confident, comfortable and beautifully you.', 9575, NULL, NULL, 38, 'in_stock', 'Stitched', 'Premium lawn & chiffon', 'Black & Gold', 'S · M · L · XL', 0, 1, DATE_SUB(NOW(), INTERVAL 6 DAY));
INSERT INTO `products` (`category_id`, `name`, `slug`, `sku`, `short_description`, `description`, `price`, `sale_price`, `cost_price`, `stock_quantity`, `stock_status`, `product_type`, `fabric`, `color`, `size`, `featured`, `status`, `created_at`) VALUES
(1, 'Zareen Embroidered Suit', 'zareen-embroidered-suit', 'TC-ST-0007', 'A thoughtfully designed stitched piece with refined finishing and an easy, elegant fit.', 'A thoughtfully designed stitched piece with refined finishing and an easy, elegant fit. Crafted from carefully selected fabric with attention to detail, this piece is part of the TayyabaCollective collection — designed to make you feel confident, comfortable and beautifully you.', 10250, NULL, NULL, 45, 'in_stock', 'Stitched', 'Premium lawn & chiffon', 'Mustard', 'S · M · L · XL', 0, 1, DATE_SUB(NOW(), INTERVAL 7 DAY));
INSERT INTO `products` (`category_id`, `name`, `slug`, `sku`, `short_description`, `description`, `price`, `sale_price`, `cost_price`, `stock_quantity`, `stock_status`, `product_type`, `fabric`, `color`, `size`, `featured`, `status`, `created_at`) VALUES
(1, 'Mira Khaddar Suit', 'mira-khaddar-suit', 'TC-ST-0008', 'A thoughtfully designed stitched piece with refined finishing and an easy, elegant fit.', 'A thoughtfully designed stitched piece with refined finishing and an easy, elegant fit. Crafted from carefully selected fabric with attention to detail, this piece is part of the TayyabaCollective collection — designed to make you feel confident, comfortable and beautifully you.', 10925, NULL, NULL, 7, 'in_stock', 'Stitched', 'Premium lawn & chiffon', 'Dusty Rose', 'S · M · L · XL', 0, 1, DATE_SUB(NOW(), INTERVAL 8 DAY));
INSERT INTO `products` (`category_id`, `name`, `slug`, `sku`, `short_description`, `description`, `price`, `sale_price`, `cost_price`, `stock_quantity`, `stock_status`, `product_type`, `fabric`, `color`, `size`, `featured`, `status`, `created_at`) VALUES
(1, 'Rida Cotton Kurta Set', 'rida-cotton-kurta-set', 'TC-ST-0009', 'A thoughtfully designed stitched piece with refined finishing and an easy, elegant fit.', 'A thoughtfully designed stitched piece with refined finishing and an easy, elegant fit. Crafted from carefully selected fabric with attention to detail, this piece is part of the TayyabaCollective collection — designed to make you feel confident, comfortable and beautifully you.', 11600, 10208, NULL, 14, 'in_stock', 'Stitched', 'Premium lawn & chiffon', 'Teal', 'S · M · L · XL', 0, 1, DATE_SUB(NOW(), INTERVAL 9 DAY));
INSERT INTO `products` (`category_id`, `name`, `slug`, `sku`, `short_description`, `description`, `price`, `sale_price`, `cost_price`, `stock_quantity`, `stock_status`, `product_type`, `fabric`, `color`, `size`, `featured`, `status`, `created_at`) VALUES
(1, 'Maham Printed Lawn Suit', 'maham-printed-lawn-suit', 'TC-ST-0010', 'A thoughtfully designed stitched piece with refined finishing and an easy, elegant fit.', 'A thoughtfully designed stitched piece with refined finishing and an easy, elegant fit. Crafted from carefully selected fabric with attention to detail, this piece is part of the TayyabaCollective collection — designed to make you feel confident, comfortable and beautifully you.', 12275, NULL, NULL, 21, 'in_stock', 'Stitched', 'Premium lawn & chiffon', 'Charcoal', 'S · M · L · XL', 1, 1, DATE_SUB(NOW(), INTERVAL 10 DAY));
INSERT INTO `products` (`category_id`, `name`, `slug`, `sku`, `short_description`, `description`, `price`, `sale_price`, `cost_price`, `stock_quantity`, `stock_status`, `product_type`, `fabric`, `color`, `size`, `featured`, `status`, `created_at`) VALUES
(1, 'Saira Chikankari Set', 'saira-chikankari-set', 'TC-ST-0011', 'A thoughtfully designed stitched piece with refined finishing and an easy, elegant fit.', 'A thoughtfully designed stitched piece with refined finishing and an easy, elegant fit. Crafted from carefully selected fabric with attention to detail, this piece is part of the TayyabaCollective collection — designed to make you feel confident, comfortable and beautifully you.', 12950, NULL, NULL, 28, 'in_stock', 'Stitched', 'Premium lawn & chiffon', 'Maroon & Gold', 'S · M · L · XL', 0, 1, DATE_SUB(NOW(), INTERVAL 11 DAY));
INSERT INTO `products` (`category_id`, `name`, `slug`, `sku`, `short_description`, `description`, `price`, `sale_price`, `cost_price`, `stock_quantity`, `stock_status`, `product_type`, `fabric`, `color`, `size`, `featured`, `status`, `created_at`) VALUES
(1, 'Farah Minimal Kurta', 'farah-minimal-kurta', 'TC-ST-0012', 'A thoughtfully designed stitched piece with refined finishing and an easy, elegant fit.', 'A thoughtfully designed stitched piece with refined finishing and an easy, elegant fit. Crafted from carefully selected fabric with attention to detail, this piece is part of the TayyabaCollective collection — designed to make you feel confident, comfortable and beautifully you.', 13625, NULL, NULL, 0, 'out_of_stock', 'Stitched', 'Premium lawn & chiffon', 'Ivory', 'S · M · L · XL', 0, 1, DATE_SUB(NOW(), INTERVAL 12 DAY));
INSERT INTO `products` (`category_id`, `name`, `slug`, `sku`, `short_description`, `description`, `price`, `sale_price`, `cost_price`, `stock_quantity`, `stock_status`, `product_type`, `fabric`, `color`, `size`, `featured`, `status`, `created_at`) VALUES
(1, 'Tania Soft Silk Set', 'tania-soft-silk-set', 'TC-ST-0013', 'A thoughtfully designed stitched piece with refined finishing and an easy, elegant fit.', 'A thoughtfully designed stitched piece with refined finishing and an easy, elegant fit. Crafted from carefully selected fabric with attention to detail, this piece is part of the TayyabaCollective collection — designed to make you feel confident, comfortable and beautifully you.', 14300, NULL, NULL, 42, 'in_stock', 'Stitched', 'Premium lawn & chiffon', 'Emerald', 'S · M · L · XL', 0, 1, DATE_SUB(NOW(), INTERVAL 13 DAY));
INSERT INTO `products` (`category_id`, `name`, `slug`, `sku`, `short_description`, `description`, `price`, `sale_price`, `cost_price`, `stock_quantity`, `stock_status`, `product_type`, `fabric`, `color`, `size`, `featured`, `status`, `created_at`) VALUES
(1, 'Hira Printed Cotton Kurta', 'hira-printed-cotton-kurta', 'TC-ST-0014', 'A thoughtfully designed stitched piece with refined finishing and an easy, elegant fit.', 'A thoughtfully designed stitched piece with refined finishing and an easy, elegant fit. Crafted from carefully selected fabric with attention to detail, this piece is part of the TayyabaCollective collection — designed to make you feel confident, comfortable and beautifully you.', 6475, NULL, NULL, 4, 'low_stock', 'Stitched', 'Premium lawn & chiffon', 'Navy', 'S · M · L · XL', 0, 1, DATE_SUB(NOW(), INTERVAL 14 DAY));
INSERT INTO `products` (`category_id`, `name`, `slug`, `sku`, `short_description`, `description`, `price`, `sale_price`, `cost_price`, `stock_quantity`, `stock_status`, `product_type`, `fabric`, `color`, `size`, `featured`, `status`, `created_at`) VALUES
(1, 'Kiran Bordered Lawn Set', 'kiran-bordered-lawn-set', 'TC-ST-0015', 'A thoughtfully designed stitched piece with refined finishing and an easy, elegant fit.', 'A thoughtfully designed stitched piece with refined finishing and an easy, elegant fit. Crafted from carefully selected fabric with attention to detail, this piece is part of the TayyabaCollective collection — designed to make you feel confident, comfortable and beautifully you.', 7150, NULL, NULL, 11, 'in_stock', 'Stitched', 'Premium lawn & chiffon', 'Blush Pink', 'S · M · L · XL', 0, 1, DATE_SUB(NOW(), INTERVAL 15 DAY));
INSERT INTO `products` (`category_id`, `name`, `slug`, `sku`, `short_description`, `description`, `price`, `sale_price`, `cost_price`, `stock_quantity`, `stock_status`, `product_type`, `fabric`, `color`, `size`, `featured`, `status`, `created_at`) VALUES
(1, 'Ansa Casual Stitched Suit', 'ansa-casual-stitched-suit', 'TC-ST-0016', 'A thoughtfully designed stitched piece with refined finishing and an easy, elegant fit.', 'A thoughtfully designed stitched piece with refined finishing and an easy, elegant fit. Crafted from carefully selected fabric with attention to detail, this piece is part of the TayyabaCollective collection — designed to make you feel confident, comfortable and beautifully you.', 7825, NULL, NULL, 18, 'in_stock', 'Stitched', 'Premium lawn & chiffon', 'Black & Gold', 'S · M · L · XL', 0, 1, DATE_SUB(NOW(), INTERVAL 16 DAY));
INSERT INTO `products` (`category_id`, `name`, `slug`, `sku`, `short_description`, `description`, `price`, `sale_price`, `cost_price`, `stock_quantity`, `stock_status`, `product_type`, `fabric`, `color`, `size`, `featured`, `status`, `created_at`) VALUES
(1, 'Hania Everyday Lawn Set', 'hania-everyday-lawn-set', 'TC-ST-0017', 'A thoughtfully designed stitched piece with refined finishing and an easy, elegant fit.', 'A thoughtfully designed stitched piece with refined finishing and an easy, elegant fit. Crafted from carefully selected fabric with attention to detail, this piece is part of the TayyabaCollective collection — designed to make you feel confident, comfortable and beautifully you.', 8500, 7480, NULL, 25, 'in_stock', 'Stitched', 'Premium lawn & chiffon', 'Mustard', 'S · M · L · XL', 0, 1, DATE_SUB(NOW(), INTERVAL 17 DAY));
INSERT INTO `products` (`category_id`, `name`, `slug`, `sku`, `short_description`, `description`, `price`, `sale_price`, `cost_price`, `stock_quantity`, `stock_status`, `product_type`, `fabric`, `color`, `size`, `featured`, `status`, `created_at`) VALUES
(1, 'Mila Festive Cotton Set', 'mila-festive-cotton-set', 'TC-ST-0018', 'A thoughtfully designed stitched piece with refined finishing and an easy, elegant fit.', 'A thoughtfully designed stitched piece with refined finishing and an easy, elegant fit. Crafted from carefully selected fabric with attention to detail, this piece is part of the TayyabaCollective collection — designed to make you feel confident, comfortable and beautifully you.', 9175, NULL, NULL, 32, 'in_stock', 'Stitched', 'Premium lawn & chiffon', 'Dusty Rose', 'S · M · L · XL', 0, 1, DATE_SUB(NOW(), INTERVAL 18 DAY));
INSERT INTO `products` (`category_id`, `name`, `slug`, `sku`, `short_description`, `description`, `price`, `sale_price`, `cost_price`, `stock_quantity`, `stock_status`, `product_type`, `fabric`, `color`, `size`, `featured`, `status`, `created_at`) VALUES
(1, 'Aiza Soft Drape Suit', 'aiza-soft-drape-suit', 'TC-ST-0019', 'A thoughtfully designed stitched piece with refined finishing and an easy, elegant fit.', 'A thoughtfully designed stitched piece with refined finishing and an easy, elegant fit. Crafted from carefully selected fabric with attention to detail, this piece is part of the TayyabaCollective collection — designed to make you feel confident, comfortable and beautifully you.', 9850, NULL, NULL, 39, 'in_stock', 'Stitched', 'Premium lawn & chiffon', 'Teal', 'S · M · L · XL', 1, 1, DATE_SUB(NOW(), INTERVAL 19 DAY));
INSERT INTO `products` (`category_id`, `name`, `slug`, `sku`, `short_description`, `description`, `price`, `sale_price`, `cost_price`, `stock_quantity`, `stock_status`, `product_type`, `fabric`, `color`, `size`, `featured`, `status`, `created_at`) VALUES
(1, 'Yumna Embellished Kurta', 'yumna-embellished-kurta', 'TC-ST-0020', 'A thoughtfully designed stitched piece with refined finishing and an easy, elegant fit.', 'A thoughtfully designed stitched piece with refined finishing and an easy, elegant fit. Crafted from carefully selected fabric with attention to detail, this piece is part of the TayyabaCollective collection — designed to make you feel confident, comfortable and beautifully you.', 10525, NULL, NULL, 46, 'in_stock', 'Stitched', 'Premium lawn & chiffon', 'Charcoal', 'S · M · L · XL', 0, 1, DATE_SUB(NOW(), INTERVAL 20 DAY));
INSERT INTO `products` (`category_id`, `name`, `slug`, `sku`, `short_description`, `description`, `price`, `sale_price`, `cost_price`, `stock_quantity`, `stock_status`, `product_type`, `fabric`, `color`, `size`, `featured`, `status`, `created_at`) VALUES
(1, 'Ayesha Classic Lawn Suit', 'ayesha-classic-lawn-suit', 'TC-ST-0021', 'A thoughtfully designed stitched piece with refined finishing and an easy, elegant fit.', 'A thoughtfully designed stitched piece with refined finishing and an easy, elegant fit. Crafted from carefully selected fabric with attention to detail, this piece is part of the TayyabaCollective collection — designed to make you feel confident, comfortable and beautifully you.', 11200, NULL, NULL, 8, 'in_stock', 'Stitched', 'Premium lawn & chiffon', 'Maroon & Gold', 'S · M · L · XL', 0, 1, DATE_SUB(NOW(), INTERVAL 21 DAY));
INSERT INTO `products` (`category_id`, `name`, `slug`, `sku`, `short_description`, `description`, `price`, `sale_price`, `cost_price`, `stock_quantity`, `stock_status`, `product_type`, `fabric`, `color`, `size`, `featured`, `status`, `created_at`) VALUES
(1, 'Rimsha Cotton Festive Set', 'rimsha-cotton-festive-set', 'TC-ST-0022', 'A thoughtfully designed stitched piece with refined finishing and an easy, elegant fit.', 'A thoughtfully designed stitched piece with refined finishing and an easy, elegant fit. Crafted from carefully selected fabric with attention to detail, this piece is part of the TayyabaCollective collection — designed to make you feel confident, comfortable and beautifully you.', 11875, NULL, NULL, 15, 'in_stock', 'Stitched', 'Premium lawn & chiffon', 'Ivory', 'S · M · L · XL', 0, 1, DATE_SUB(NOW(), INTERVAL 22 DAY));
INSERT INTO `products` (`category_id`, `name`, `slug`, `sku`, `short_description`, `description`, `price`, `sale_price`, `cost_price`, `stock_quantity`, `stock_status`, `product_type`, `fabric`, `color`, `size`, `featured`, `status`, `created_at`) VALUES
(1, 'Nadia Printed Shirt Set', 'nadia-printed-shirt-set', 'TC-ST-0023', 'A thoughtfully designed stitched piece with refined finishing and an easy, elegant fit.', 'A thoughtfully designed stitched piece with refined finishing and an easy, elegant fit. Crafted from carefully selected fabric with attention to detail, this piece is part of the TayyabaCollective collection — designed to make you feel confident, comfortable and beautifully you.', 12550, NULL, NULL, 0, 'out_of_stock', 'Stitched', 'Premium lawn & chiffon', 'Emerald', 'S · M · L · XL', 0, 1, DATE_SUB(NOW(), INTERVAL 23 DAY));
INSERT INTO `products` (`category_id`, `name`, `slug`, `sku`, `short_description`, `description`, `price`, `sale_price`, `cost_price`, `stock_quantity`, `stock_status`, `product_type`, `fabric`, `color`, `size`, `featured`, `status`, `created_at`) VALUES
(1, 'Sana Grace Kurta Set', 'sana-grace-kurta-set', 'TC-ST-0024', 'A thoughtfully designed stitched piece with refined finishing and an easy, elegant fit.', 'A thoughtfully designed stitched piece with refined finishing and an easy, elegant fit. Crafted from carefully selected fabric with attention to detail, this piece is part of the TayyabaCollective collection — designed to make you feel confident, comfortable and beautifully you.', 13225, NULL, NULL, 29, 'in_stock', 'Stitched', 'Premium lawn & chiffon', 'Navy', 'S · M · L · XL', 0, 1, DATE_SUB(NOW(), INTERVAL 24 DAY));
INSERT INTO `products` (`category_id`, `name`, `slug`, `sku`, `short_description`, `description`, `price`, `sale_price`, `cost_price`, `stock_quantity`, `stock_status`, `product_type`, `fabric`, `color`, `size`, `featured`, `status`, `created_at`) VALUES
(1, 'Sahar Floral Chiffon Set', 'sahar-floral-chiffon-set', 'TC-ST-0025', 'A thoughtfully designed stitched piece with refined finishing and an easy, elegant fit.', 'A thoughtfully designed stitched piece with refined finishing and an easy, elegant fit. Crafted from carefully selected fabric with attention to detail, this piece is part of the TayyabaCollective collection — designed to make you feel confident, comfortable and beautifully you.', 13900, 12232, NULL, 36, 'in_stock', 'Stitched', 'Premium lawn & chiffon', 'Blush Pink', 'S · M · L · XL', 0, 1, DATE_SUB(NOW(), INTERVAL 25 DAY));
INSERT INTO `products` (`category_id`, `name`, `slug`, `sku`, `short_description`, `description`, `price`, `sale_price`, `cost_price`, `stock_quantity`, `stock_status`, `product_type`, `fabric`, `color`, `size`, `featured`, `status`, `created_at`) VALUES
(1, 'Maryam Luxe Lawn Set', 'maryam-luxe-lawn-set', 'TC-ST-0026', 'A thoughtfully designed stitched piece with refined finishing and an easy, elegant fit.', 'A thoughtfully designed stitched piece with refined finishing and an easy, elegant fit. Crafted from carefully selected fabric with attention to detail, this piece is part of the TayyabaCollective collection — designed to make you feel confident, comfortable and beautifully you.', 14575, NULL, NULL, 43, 'in_stock', 'Stitched', 'Premium lawn & chiffon', 'Black & Gold', 'S · M · L · XL', 0, 1, DATE_SUB(NOW(), INTERVAL 26 DAY));
INSERT INTO `products` (`category_id`, `name`, `slug`, `sku`, `short_description`, `description`, `price`, `sale_price`, `cost_price`, `stock_quantity`, `stock_status`, `product_type`, `fabric`, `color`, `size`, `featured`, `status`, `created_at`) VALUES
(1, 'Emaan Everyday Stitched Set', 'emaan-everyday-stitched-set', 'TC-ST-0027', 'A thoughtfully designed stitched piece with refined finishing and an easy, elegant fit.', 'A thoughtfully designed stitched piece with refined finishing and an easy, elegant fit. Crafted from carefully selected fabric with attention to detail, this piece is part of the TayyabaCollective collection — designed to make you feel confident, comfortable and beautifully you.', 6750, NULL, NULL, 5, 'low_stock', 'Stitched', 'Premium lawn & chiffon', 'Mustard', 'S · M · L · XL', 0, 1, DATE_SUB(NOW(), INTERVAL 27 DAY));
INSERT INTO `products` (`category_id`, `name`, `slug`, `sku`, `short_description`, `description`, `price`, `sale_price`, `cost_price`, `stock_quantity`, `stock_status`, `product_type`, `fabric`, `color`, `size`, `featured`, `status`, `created_at`) VALUES
(1, 'Zoya Flow Kurta Set', 'zoya-flow-kurta-set', 'TC-ST-0028', 'A thoughtfully designed stitched piece with refined finishing and an easy, elegant fit.', 'A thoughtfully designed stitched piece with refined finishing and an easy, elegant fit. Crafted from carefully selected fabric with attention to detail, this piece is part of the TayyabaCollective collection — designed to make you feel confident, comfortable and beautifully you.', 7425, NULL, NULL, 12, 'in_stock', 'Stitched', 'Premium lawn & chiffon', 'Dusty Rose', 'S · M · L · XL', 1, 1, DATE_SUB(NOW(), INTERVAL 28 DAY));
INSERT INTO `products` (`category_id`, `name`, `slug`, `sku`, `short_description`, `description`, `price`, `sale_price`, `cost_price`, `stock_quantity`, `stock_status`, `product_type`, `fabric`, `color`, `size`, `featured`, `status`, `created_at`) VALUES
(1, 'Mahira Soft Printed Set', 'mahira-soft-printed-set', 'TC-ST-0029', 'A thoughtfully designed stitched piece with refined finishing and an easy, elegant fit.', 'A thoughtfully designed stitched piece with refined finishing and an easy, elegant fit. Crafted from carefully selected fabric with attention to detail, this piece is part of the TayyabaCollective collection — designed to make you feel confident, comfortable and beautifully you.', 8100, NULL, NULL, 19, 'in_stock', 'Stitched', 'Premium lawn & chiffon', 'Teal', 'S · M · L · XL', 0, 1, DATE_SUB(NOW(), INTERVAL 29 DAY));
INSERT INTO `products` (`category_id`, `name`, `slug`, `sku`, `short_description`, `description`, `price`, `sale_price`, `cost_price`, `stock_quantity`, `stock_status`, `product_type`, `fabric`, `color`, `size`, `featured`, `status`, `created_at`) VALUES
(1, 'Samiya Classic Shirt Suit', 'samiya-classic-shirt-suit', 'TC-ST-0030', 'A thoughtfully designed stitched piece with refined finishing and an easy, elegant fit.', 'A thoughtfully designed stitched piece with refined finishing and an easy, elegant fit. Crafted from carefully selected fabric with attention to detail, this piece is part of the TayyabaCollective collection — designed to make you feel confident, comfortable and beautifully you.', 8775, NULL, NULL, 26, 'in_stock', 'Stitched', 'Premium lawn & chiffon', 'Charcoal', 'S · M · L · XL', 0, 1, DATE_SUB(NOW(), INTERVAL 30 DAY));
INSERT INTO `products` (`category_id`, `name`, `slug`, `sku`, `short_description`, `description`, `price`, `sale_price`, `cost_price`, `stock_quantity`, `stock_status`, `product_type`, `fabric`, `color`, `size`, `featured`, `status`, `created_at`) VALUES
(2, 'Aisha Soft Cotton Lawn', 'aisha-soft-cotton-lawn', 'TC-UN-0001', 'A thoughtfully designed unstitched piece with refined finishing and an easy, elegant fit.', 'A thoughtfully designed unstitched piece with refined finishing and an easy, elegant fit. Crafted from carefully selected fabric with attention to detail, this piece is part of the TayyabaCollective collection — designed to make you feel confident, comfortable and beautifully you.', 6200, 5456, NULL, 0, 'out_of_stock', 'Unstitched', 'Premium lawn fabric', 'Maroon & Gold', 'One Size', 1, 1, DATE_SUB(NOW(), INTERVAL 1 DAY));
INSERT INTO `products` (`category_id`, `name`, `slug`, `sku`, `short_description`, `description`, `price`, `sale_price`, `cost_price`, `stock_quantity`, `stock_status`, `product_type`, `fabric`, `color`, `size`, `featured`, `status`, `created_at`) VALUES
(2, 'Meher Printed Chiffon Set', 'meher-printed-chiffon-set', 'TC-UN-0002', 'A thoughtfully designed unstitched piece with refined finishing and an easy, elegant fit.', 'A thoughtfully designed unstitched piece with refined finishing and an easy, elegant fit. Crafted from carefully selected fabric with attention to detail, this piece is part of the TayyabaCollective collection — designed to make you feel confident, comfortable and beautifully you.', 6875, NULL, NULL, 10, 'in_stock', 'Unstitched', 'Premium lawn fabric', 'Ivory', 'One Size', 0, 1, DATE_SUB(NOW(), INTERVAL 2 DAY));
INSERT INTO `products` (`category_id`, `name`, `slug`, `sku`, `short_description`, `description`, `price`, `sale_price`, `cost_price`, `stock_quantity`, `stock_status`, `product_type`, `fabric`, `color`, `size`, `featured`, `status`, `created_at`) VALUES
(2, 'Fizza Summer Floral Unstitched', 'fizza-summer-floral-unstitched', 'TC-UN-0003', 'A thoughtfully designed unstitched piece with refined finishing and an easy, elegant fit.', 'A thoughtfully designed unstitched piece with refined finishing and an easy, elegant fit. Crafted from carefully selected fabric with attention to detail, this piece is part of the TayyabaCollective collection — designed to make you feel confident, comfortable and beautifully you.', 7550, NULL, NULL, 17, 'in_stock', 'Unstitched', 'Premium lawn fabric', 'Emerald', 'One Size', 0, 1, DATE_SUB(NOW(), INTERVAL 3 DAY));
INSERT INTO `products` (`category_id`, `name`, `slug`, `sku`, `short_description`, `description`, `price`, `sale_price`, `cost_price`, `stock_quantity`, `stock_status`, `product_type`, `fabric`, `color`, `size`, `featured`, `status`, `created_at`) VALUES
(2, 'Zara Premium Lawn 3 Piece', 'zara-premium-lawn-3-piece', 'TC-UN-0004', 'A thoughtfully designed unstitched piece with refined finishing and an easy, elegant fit.', 'A thoughtfully designed unstitched piece with refined finishing and an easy, elegant fit. Crafted from carefully selected fabric with attention to detail, this piece is part of the TayyabaCollective collection — designed to make you feel confident, comfortable and beautifully you.', 8225, NULL, NULL, 24, 'in_stock', 'Unstitched', 'Premium lawn fabric', 'Navy', 'One Size', 0, 1, DATE_SUB(NOW(), INTERVAL 4 DAY));
INSERT INTO `products` (`category_id`, `name`, `slug`, `sku`, `short_description`, `description`, `price`, `sale_price`, `cost_price`, `stock_quantity`, `stock_status`, `product_type`, `fabric`, `color`, `size`, `featured`, `status`, `created_at`) VALUES
(2, 'Mariam Embroidered Unstitched', 'mariam-embroidered-unstitched', 'TC-UN-0005', 'A thoughtfully designed unstitched piece with refined finishing and an easy, elegant fit.', 'A thoughtfully designed unstitched piece with refined finishing and an easy, elegant fit. Crafted from carefully selected fabric with attention to detail, this piece is part of the TayyabaCollective collection — designed to make you feel confident, comfortable and beautifully you.', 8900, NULL, NULL, 31, 'in_stock', 'Unstitched', 'Premium lawn fabric', 'Blush Pink', 'One Size', 0, 1, DATE_SUB(NOW(), INTERVAL 5 DAY));
INSERT INTO `products` (`category_id`, `name`, `slug`, `sku`, `short_description`, `description`, `price`, `sale_price`, `cost_price`, `stock_quantity`, `stock_status`, `product_type`, `fabric`, `color`, `size`, `featured`, `status`, `created_at`) VALUES
(2, 'Sheza Classic Karandi Set', 'sheza-classic-karandi-set', 'TC-UN-0006', 'A thoughtfully designed unstitched piece with refined finishing and an easy, elegant fit.', 'A thoughtfully designed unstitched piece with refined finishing and an easy, elegant fit. Crafted from carefully selected fabric with attention to detail, this piece is part of the TayyabaCollective collection — designed to make you feel confident, comfortable and beautifully you.', 9575, NULL, NULL, 38, 'in_stock', 'Unstitched', 'Premium lawn fabric', 'Black & Gold', 'One Size', 0, 1, DATE_SUB(NOW(), INTERVAL 6 DAY));
INSERT INTO `products` (`category_id`, `name`, `slug`, `sku`, `short_description`, `description`, `price`, `sale_price`, `cost_price`, `stock_quantity`, `stock_status`, `product_type`, `fabric`, `color`, `size`, `featured`, `status`, `created_at`) VALUES
(2, 'Sahil Printed Lawn', 'sahil-printed-lawn', 'TC-UN-0007', 'A thoughtfully designed unstitched piece with refined finishing and an easy, elegant fit.', 'A thoughtfully designed unstitched piece with refined finishing and an easy, elegant fit. Crafted from carefully selected fabric with attention to detail, this piece is part of the TayyabaCollective collection — designed to make you feel confident, comfortable and beautifully you.', 10250, NULL, NULL, 45, 'in_stock', 'Unstitched', 'Premium lawn fabric', 'Mustard', 'One Size', 0, 1, DATE_SUB(NOW(), INTERVAL 7 DAY));
INSERT INTO `products` (`category_id`, `name`, `slug`, `sku`, `short_description`, `description`, `price`, `sale_price`, `cost_price`, `stock_quantity`, `stock_status`, `product_type`, `fabric`, `color`, `size`, `featured`, `status`, `created_at`) VALUES
(2, 'Sana Karandi Unstitched Set', 'sana-karandi-unstitched-set', 'TC-UN-0008', 'A thoughtfully designed unstitched piece with refined finishing and an easy, elegant fit.', 'A thoughtfully designed unstitched piece with refined finishing and an easy, elegant fit. Crafted from carefully selected fabric with attention to detail, this piece is part of the TayyabaCollective collection — designed to make you feel confident, comfortable and beautifully you.', 10925, NULL, NULL, 7, 'in_stock', 'Unstitched', 'Premium lawn fabric', 'Dusty Rose', 'One Size', 0, 1, DATE_SUB(NOW(), INTERVAL 8 DAY));
INSERT INTO `products` (`category_id`, `name`, `slug`, `sku`, `short_description`, `description`, `price`, `sale_price`, `cost_price`, `stock_quantity`, `stock_status`, `product_type`, `fabric`, `color`, `size`, `featured`, `status`, `created_at`) VALUES
(2, 'Maham Pastel Lawn Set', 'maham-pastel-lawn-set', 'TC-UN-0009', 'A thoughtfully designed unstitched piece with refined finishing and an easy, elegant fit.', 'A thoughtfully designed unstitched piece with refined finishing and an easy, elegant fit. Crafted from carefully selected fabric with attention to detail, this piece is part of the TayyabaCollective collection — designed to make you feel confident, comfortable and beautifully you.', 11600, 10208, NULL, 14, 'in_stock', 'Unstitched', 'Premium lawn fabric', 'Teal', 'One Size', 0, 1, DATE_SUB(NOW(), INTERVAL 9 DAY));
INSERT INTO `products` (`category_id`, `name`, `slug`, `sku`, `short_description`, `description`, `price`, `sale_price`, `cost_price`, `stock_quantity`, `stock_status`, `product_type`, `fabric`, `color`, `size`, `featured`, `status`, `created_at`) VALUES
(2, 'Rida Floral Chiffon Set', 'rida-floral-chiffon-set', 'TC-UN-0010', 'A thoughtfully designed unstitched piece with refined finishing and an easy, elegant fit.', 'A thoughtfully designed unstitched piece with refined finishing and an easy, elegant fit. Crafted from carefully selected fabric with attention to detail, this piece is part of the TayyabaCollective collection — designed to make you feel confident, comfortable and beautifully you.', 12275, NULL, NULL, 21, 'in_stock', 'Unstitched', 'Premium lawn fabric', 'Charcoal', 'One Size', 1, 1, DATE_SUB(NOW(), INTERVAL 10 DAY));
INSERT INTO `products` (`category_id`, `name`, `slug`, `sku`, `short_description`, `description`, `price`, `sale_price`, `cost_price`, `stock_quantity`, `stock_status`, `product_type`, `fabric`, `color`, `size`, `featured`, `status`, `created_at`) VALUES
(2, 'Areeba Cotton Printed Set', 'areeba-cotton-printed-set', 'TC-UN-0011', 'A thoughtfully designed unstitched piece with refined finishing and an easy, elegant fit.', 'A thoughtfully designed unstitched piece with refined finishing and an easy, elegant fit. Crafted from carefully selected fabric with attention to detail, this piece is part of the TayyabaCollective collection — designed to make you feel confident, comfortable and beautifully you.', 12950, NULL, NULL, 28, 'in_stock', 'Unstitched', 'Premium lawn fabric', 'Maroon & Gold', 'One Size', 0, 1, DATE_SUB(NOW(), INTERVAL 11 DAY));
INSERT INTO `products` (`category_id`, `name`, `slug`, `sku`, `short_description`, `description`, `price`, `sale_price`, `cost_price`, `stock_quantity`, `stock_status`, `product_type`, `fabric`, `color`, `size`, `featured`, `status`, `created_at`) VALUES
(2, 'Noor Multicolor Lawn Set', 'noor-multicolor-lawn-set', 'TC-UN-0012', 'A thoughtfully designed unstitched piece with refined finishing and an easy, elegant fit.', 'A thoughtfully designed unstitched piece with refined finishing and an easy, elegant fit. Crafted from carefully selected fabric with attention to detail, this piece is part of the TayyabaCollective collection — designed to make you feel confident, comfortable and beautifully you.', 13625, NULL, NULL, 0, 'out_of_stock', 'Unstitched', 'Premium lawn fabric', 'Ivory', 'One Size', 0, 1, DATE_SUB(NOW(), INTERVAL 12 DAY));
INSERT INTO `products` (`category_id`, `name`, `slug`, `sku`, `short_description`, `description`, `price`, `sale_price`, `cost_price`, `stock_quantity`, `stock_status`, `product_type`, `fabric`, `color`, `size`, `featured`, `status`, `created_at`) VALUES
(2, 'Hania Garden Print Set', 'hania-garden-print-set', 'TC-UN-0013', 'A thoughtfully designed unstitched piece with refined finishing and an easy, elegant fit.', 'A thoughtfully designed unstitched piece with refined finishing and an easy, elegant fit. Crafted from carefully selected fabric with attention to detail, this piece is part of the TayyabaCollective collection — designed to make you feel confident, comfortable and beautifully you.', 14300, NULL, NULL, 42, 'in_stock', 'Unstitched', 'Premium lawn fabric', 'Emerald', 'One Size', 0, 1, DATE_SUB(NOW(), INTERVAL 13 DAY));
INSERT INTO `products` (`category_id`, `name`, `slug`, `sku`, `short_description`, `description`, `price`, `sale_price`, `cost_price`, `stock_quantity`, `stock_status`, `product_type`, `fabric`, `color`, `size`, `featured`, `status`, `created_at`) VALUES
(2, 'Maryam Premium Karandi', 'maryam-premium-karandi', 'TC-UN-0014', 'A thoughtfully designed unstitched piece with refined finishing and an easy, elegant fit.', 'A thoughtfully designed unstitched piece with refined finishing and an easy, elegant fit. Crafted from carefully selected fabric with attention to detail, this piece is part of the TayyabaCollective collection — designed to make you feel confident, comfortable and beautifully you.', 6475, NULL, NULL, 4, 'low_stock', 'Unstitched', 'Premium lawn fabric', 'Navy', 'One Size', 0, 1, DATE_SUB(NOW(), INTERVAL 14 DAY));
INSERT INTO `products` (`category_id`, `name`, `slug`, `sku`, `short_description`, `description`, `price`, `sale_price`, `cost_price`, `stock_quantity`, `stock_status`, `product_type`, `fabric`, `color`, `size`, `featured`, `status`, `created_at`) VALUES
(2, 'Ayesha Printed Dupatta Set', 'ayesha-printed-dupatta-set', 'TC-UN-0015', 'A thoughtfully designed unstitched piece with refined finishing and an easy, elegant fit.', 'A thoughtfully designed unstitched piece with refined finishing and an easy, elegant fit. Crafted from carefully selected fabric with attention to detail, this piece is part of the TayyabaCollective collection — designed to make you feel confident, comfortable and beautifully you.', 7150, NULL, NULL, 11, 'in_stock', 'Unstitched', 'Premium lawn fabric', 'Blush Pink', 'One Size', 0, 1, DATE_SUB(NOW(), INTERVAL 15 DAY));
INSERT INTO `products` (`category_id`, `name`, `slug`, `sku`, `short_description`, `description`, `price`, `sale_price`, `cost_price`, `stock_quantity`, `stock_status`, `product_type`, `fabric`, `color`, `size`, `featured`, `status`, `created_at`) VALUES
(2, 'Fariha Soft Chiffon Set', 'fariha-soft-chiffon-set', 'TC-UN-0016', 'A thoughtfully designed unstitched piece with refined finishing and an easy, elegant fit.', 'A thoughtfully designed unstitched piece with refined finishing and an easy, elegant fit. Crafted from carefully selected fabric with attention to detail, this piece is part of the TayyabaCollective collection — designed to make you feel confident, comfortable and beautifully you.', 7825, NULL, NULL, 18, 'in_stock', 'Unstitched', 'Premium lawn fabric', 'Black & Gold', 'One Size', 0, 1, DATE_SUB(NOW(), INTERVAL 16 DAY));
INSERT INTO `products` (`category_id`, `name`, `slug`, `sku`, `short_description`, `description`, `price`, `sale_price`, `cost_price`, `stock_quantity`, `stock_status`, `product_type`, `fabric`, `color`, `size`, `featured`, `status`, `created_at`) VALUES
(2, 'Hira Classic 3 Piece', 'hira-classic-3-piece', 'TC-UN-0017', 'A thoughtfully designed unstitched piece with refined finishing and an easy, elegant fit.', 'A thoughtfully designed unstitched piece with refined finishing and an easy, elegant fit. Crafted from carefully selected fabric with attention to detail, this piece is part of the TayyabaCollective collection — designed to make you feel confident, comfortable and beautifully you.', 8500, 7480, NULL, 25, 'in_stock', 'Unstitched', 'Premium lawn fabric', 'Mustard', 'One Size', 0, 1, DATE_SUB(NOW(), INTERVAL 17 DAY));
INSERT INTO `products` (`category_id`, `name`, `slug`, `sku`, `short_description`, `description`, `price`, `sale_price`, `cost_price`, `stock_quantity`, `stock_status`, `product_type`, `fabric`, `color`, `size`, `featured`, `status`, `created_at`) VALUES
(2, 'Nadia Printed Lawn', 'nadia-printed-lawn', 'TC-UN-0018', 'A thoughtfully designed unstitched piece with refined finishing and an easy, elegant fit.', 'A thoughtfully designed unstitched piece with refined finishing and an easy, elegant fit. Crafted from carefully selected fabric with attention to detail, this piece is part of the TayyabaCollective collection — designed to make you feel confident, comfortable and beautifully you.', 9175, NULL, NULL, 32, 'in_stock', 'Unstitched', 'Premium lawn fabric', 'Dusty Rose', 'One Size', 0, 1, DATE_SUB(NOW(), INTERVAL 18 DAY));
INSERT INTO `products` (`category_id`, `name`, `slug`, `sku`, `short_description`, `description`, `price`, `sale_price`, `cost_price`, `stock_quantity`, `stock_status`, `product_type`, `fabric`, `color`, `size`, `featured`, `status`, `created_at`) VALUES
(2, 'Sahar Tie-Dye Lawn Set', 'sahar-tie-dye-lawn-set', 'TC-UN-0019', 'A thoughtfully designed unstitched piece with refined finishing and an easy, elegant fit.', 'A thoughtfully designed unstitched piece with refined finishing and an easy, elegant fit. Crafted from carefully selected fabric with attention to detail, this piece is part of the TayyabaCollective collection — designed to make you feel confident, comfortable and beautifully you.', 9850, NULL, NULL, 39, 'in_stock', 'Unstitched', 'Premium lawn fabric', 'Teal', 'One Size', 1, 1, DATE_SUB(NOW(), INTERVAL 19 DAY));
INSERT INTO `products` (`category_id`, `name`, `slug`, `sku`, `short_description`, `description`, `price`, `sale_price`, `cost_price`, `stock_quantity`, `stock_status`, `product_type`, `fabric`, `color`, `size`, `featured`, `status`, `created_at`) VALUES
(2, 'Areej Minimal Lawn', 'areej-minimal-lawn', 'TC-UN-0020', 'A thoughtfully designed unstitched piece with refined finishing and an easy, elegant fit.', 'A thoughtfully designed unstitched piece with refined finishing and an easy, elegant fit. Crafted from carefully selected fabric with attention to detail, this piece is part of the TayyabaCollective collection — designed to make you feel confident, comfortable and beautifully you.', 10525, NULL, NULL, 46, 'in_stock', 'Unstitched', 'Premium lawn fabric', 'Charcoal', 'One Size', 0, 1, DATE_SUB(NOW(), INTERVAL 20 DAY));
INSERT INTO `products` (`category_id`, `name`, `slug`, `sku`, `short_description`, `description`, `price`, `sale_price`, `cost_price`, `stock_quantity`, `stock_status`, `product_type`, `fabric`, `color`, `size`, `featured`, `status`, `created_at`) VALUES
(2, 'Hina Cotton Festive Set', 'hina-cotton-festive-set', 'TC-UN-0021', 'A thoughtfully designed unstitched piece with refined finishing and an easy, elegant fit.', 'A thoughtfully designed unstitched piece with refined finishing and an easy, elegant fit. Crafted from carefully selected fabric with attention to detail, this piece is part of the TayyabaCollective collection — designed to make you feel confident, comfortable and beautifully you.', 11200, NULL, NULL, 8, 'in_stock', 'Unstitched', 'Premium lawn fabric', 'Maroon & Gold', 'One Size', 0, 1, DATE_SUB(NOW(), INTERVAL 21 DAY));
INSERT INTO `products` (`category_id`, `name`, `slug`, `sku`, `short_description`, `description`, `price`, `sale_price`, `cost_price`, `stock_quantity`, `stock_status`, `product_type`, `fabric`, `color`, `size`, `featured`, `status`, `created_at`) VALUES
(2, 'Sana Bloom Lawn Set', 'sana-bloom-lawn-set', 'TC-UN-0022', 'A thoughtfully designed unstitched piece with refined finishing and an easy, elegant fit.', 'A thoughtfully designed unstitched piece with refined finishing and an easy, elegant fit. Crafted from carefully selected fabric with attention to detail, this piece is part of the TayyabaCollective collection — designed to make you feel confident, comfortable and beautifully you.', 11875, NULL, NULL, 15, 'in_stock', 'Unstitched', 'Premium lawn fabric', 'Ivory', 'One Size', 0, 1, DATE_SUB(NOW(), INTERVAL 22 DAY));
INSERT INTO `products` (`category_id`, `name`, `slug`, `sku`, `short_description`, `description`, `price`, `sale_price`, `cost_price`, `stock_quantity`, `stock_status`, `product_type`, `fabric`, `color`, `size`, `featured`, `status`, `created_at`) VALUES
(2, 'Mira Textured Lawn', 'mira-textured-lawn', 'TC-UN-0023', 'A thoughtfully designed unstitched piece with refined finishing and an easy, elegant fit.', 'A thoughtfully designed unstitched piece with refined finishing and an easy, elegant fit. Crafted from carefully selected fabric with attention to detail, this piece is part of the TayyabaCollective collection — designed to make you feel confident, comfortable and beautifully you.', 12550, NULL, NULL, 0, 'out_of_stock', 'Unstitched', 'Premium lawn fabric', 'Emerald', 'One Size', 0, 1, DATE_SUB(NOW(), INTERVAL 23 DAY));
INSERT INTO `products` (`category_id`, `name`, `slug`, `sku`, `short_description`, `description`, `price`, `sale_price`, `cost_price`, `stock_quantity`, `stock_status`, `product_type`, `fabric`, `color`, `size`, `featured`, `status`, `created_at`) VALUES
(2, 'Ansa Stripe Lawn Set', 'ansa-stripe-lawn-set', 'TC-UN-0024', 'A thoughtfully designed unstitched piece with refined finishing and an easy, elegant fit.', 'A thoughtfully designed unstitched piece with refined finishing and an easy, elegant fit. Crafted from carefully selected fabric with attention to detail, this piece is part of the TayyabaCollective collection — designed to make you feel confident, comfortable and beautifully you.', 13225, NULL, NULL, 29, 'in_stock', 'Unstitched', 'Premium lawn fabric', 'Navy', 'One Size', 0, 1, DATE_SUB(NOW(), INTERVAL 24 DAY));
INSERT INTO `products` (`category_id`, `name`, `slug`, `sku`, `short_description`, `description`, `price`, `sale_price`, `cost_price`, `stock_quantity`, `stock_status`, `product_type`, `fabric`, `color`, `size`, `featured`, `status`, `created_at`) VALUES
(2, 'Zainab Soft Floral Set', 'zainab-soft-floral-set', 'TC-UN-0025', 'A thoughtfully designed unstitched piece with refined finishing and an easy, elegant fit.', 'A thoughtfully designed unstitched piece with refined finishing and an easy, elegant fit. Crafted from carefully selected fabric with attention to detail, this piece is part of the TayyabaCollective collection — designed to make you feel confident, comfortable and beautifully you.', 13900, 12232, NULL, 36, 'in_stock', 'Unstitched', 'Premium lawn fabric', 'Blush Pink', 'One Size', 0, 1, DATE_SUB(NOW(), INTERVAL 25 DAY));
INSERT INTO `products` (`category_id`, `name`, `slug`, `sku`, `short_description`, `description`, `price`, `sale_price`, `cost_price`, `stock_quantity`, `stock_status`, `product_type`, `fabric`, `color`, `size`, `featured`, `status`, `created_at`) VALUES
(2, 'Aiza Printed Lawn Duo', 'aiza-printed-lawn-duo', 'TC-UN-0026', 'A thoughtfully designed unstitched piece with refined finishing and an easy, elegant fit.', 'A thoughtfully designed unstitched piece with refined finishing and an easy, elegant fit. Crafted from carefully selected fabric with attention to detail, this piece is part of the TayyabaCollective collection — designed to make you feel confident, comfortable and beautifully you.', 14575, NULL, NULL, 43, 'in_stock', 'Unstitched', 'Premium lawn fabric', 'Black & Gold', 'One Size', 0, 1, DATE_SUB(NOW(), INTERVAL 26 DAY));
INSERT INTO `products` (`category_id`, `name`, `slug`, `sku`, `short_description`, `description`, `price`, `sale_price`, `cost_price`, `stock_quantity`, `stock_status`, `product_type`, `fabric`, `color`, `size`, `featured`, `status`, `created_at`) VALUES
(2, 'Rimsha Daily Lawn Set', 'rimsha-daily-lawn-set', 'TC-UN-0027', 'A thoughtfully designed unstitched piece with refined finishing and an easy, elegant fit.', 'A thoughtfully designed unstitched piece with refined finishing and an easy, elegant fit. Crafted from carefully selected fabric with attention to detail, this piece is part of the TayyabaCollective collection — designed to make you feel confident, comfortable and beautifully you.', 6750, NULL, NULL, 5, 'low_stock', 'Unstitched', 'Premium lawn fabric', 'Mustard', 'One Size', 0, 1, DATE_SUB(NOW(), INTERVAL 27 DAY));
INSERT INTO `products` (`category_id`, `name`, `slug`, `sku`, `short_description`, `description`, `price`, `sale_price`, `cost_price`, `stock_quantity`, `stock_status`, `product_type`, `fabric`, `color`, `size`, `featured`, `status`, `created_at`) VALUES
(2, 'Faryal Luxe Printed Lawn', 'faryal-luxe-printed-lawn', 'TC-UN-0028', 'A thoughtfully designed unstitched piece with refined finishing and an easy, elegant fit.', 'A thoughtfully designed unstitched piece with refined finishing and an easy, elegant fit. Crafted from carefully selected fabric with attention to detail, this piece is part of the TayyabaCollective collection — designed to make you feel confident, comfortable and beautifully you.', 7425, NULL, NULL, 12, 'in_stock', 'Unstitched', 'Premium lawn fabric', 'Dusty Rose', 'One Size', 1, 1, DATE_SUB(NOW(), INTERVAL 28 DAY));
INSERT INTO `products` (`category_id`, `name`, `slug`, `sku`, `short_description`, `description`, `price`, `sale_price`, `cost_price`, `stock_quantity`, `stock_status`, `product_type`, `fabric`, `color`, `size`, `featured`, `status`, `created_at`) VALUES
(2, 'Maryam Cotton Bloom Set', 'maryam-cotton-bloom-set', 'TC-UN-0029', 'A thoughtfully designed unstitched piece with refined finishing and an easy, elegant fit.', 'A thoughtfully designed unstitched piece with refined finishing and an easy, elegant fit. Crafted from carefully selected fabric with attention to detail, this piece is part of the TayyabaCollective collection — designed to make you feel confident, comfortable and beautifully you.', 8100, NULL, NULL, 19, 'in_stock', 'Unstitched', 'Premium lawn fabric', 'Teal', 'One Size', 0, 1, DATE_SUB(NOW(), INTERVAL 29 DAY));
INSERT INTO `products` (`category_id`, `name`, `slug`, `sku`, `short_description`, `description`, `price`, `sale_price`, `cost_price`, `stock_quantity`, `stock_status`, `product_type`, `fabric`, `color`, `size`, `featured`, `status`, `created_at`) VALUES
(2, 'Kiran Modern Lawn Pack', 'kiran-modern-lawn-pack', 'TC-UN-0030', 'A thoughtfully designed unstitched piece with refined finishing and an easy, elegant fit.', 'A thoughtfully designed unstitched piece with refined finishing and an easy, elegant fit. Crafted from carefully selected fabric with attention to detail, this piece is part of the TayyabaCollective collection — designed to make you feel confident, comfortable and beautifully you.', 8775, NULL, NULL, 26, 'in_stock', 'Unstitched', 'Premium lawn fabric', 'Charcoal', 'One Size', 0, 1, DATE_SUB(NOW(), INTERVAL 30 DAY));
INSERT INTO `products` (`category_id`, `name`, `slug`, `sku`, `short_description`, `description`, `price`, `sale_price`, `cost_price`, `stock_quantity`, `stock_status`, `product_type`, `fabric`, `color`, `size`, `featured`, `status`, `created_at`) VALUES
(19, 'Noor Tailored Blazer Dress', 'noor-tailored-blazer-dress', 'TC-WS-0001', 'A thoughtfully designed western wear piece with refined finishing and an easy, elegant fit.', 'A thoughtfully designed western wear piece with refined finishing and an easy, elegant fit. Crafted from carefully selected fabric with attention to detail, this piece is part of the TayyabaCollective collection — designed to make you feel confident, comfortable and beautifully you.', 6200, 5456, NULL, 0, 'out_of_stock', 'Western Wear', 'Premium blended fabric', 'Maroon & Gold', 'S · M · L · XL', 1, 1, DATE_SUB(NOW(), INTERVAL 1 DAY));
INSERT INTO `products` (`category_id`, `name`, `slug`, `sku`, `short_description`, `description`, `price`, `sale_price`, `cost_price`, `stock_quantity`, `stock_status`, `product_type`, `fabric`, `color`, `size`, `featured`, `status`, `created_at`) VALUES
(19, 'Elan Wide-Leg Trouser Set', 'elan-wide-leg-trouser-set', 'TC-WS-0002', 'A thoughtfully designed western wear piece with refined finishing and an easy, elegant fit.', 'A thoughtfully designed western wear piece with refined finishing and an easy, elegant fit. Crafted from carefully selected fabric with attention to detail, this piece is part of the TayyabaCollective collection — designed to make you feel confident, comfortable and beautifully you.', 6875, NULL, NULL, 10, 'in_stock', 'Western Wear', 'Premium blended fabric', 'Ivory', 'S · M · L · XL', 0, 1, DATE_SUB(NOW(), INTERVAL 2 DAY));
INSERT INTO `products` (`category_id`, `name`, `slug`, `sku`, `short_description`, `description`, `price`, `sale_price`, `cost_price`, `stock_quantity`, `stock_status`, `product_type`, `fabric`, `color`, `size`, `featured`, `status`, `created_at`) VALUES
(19, 'Rida Linen Co-ord Set', 'rida-linen-co-ord-set', 'TC-WS-0003', 'A thoughtfully designed western wear piece with refined finishing and an easy, elegant fit.', 'A thoughtfully designed western wear piece with refined finishing and an easy, elegant fit. Crafted from carefully selected fabric with attention to detail, this piece is part of the TayyabaCollective collection — designed to make you feel confident, comfortable and beautifully you.', 7550, NULL, NULL, 17, 'in_stock', 'Western Wear', 'Premium blended fabric', 'Emerald', 'S · M · L · XL', 0, 1, DATE_SUB(NOW(), INTERVAL 3 DAY));
INSERT INTO `products` (`category_id`, `name`, `slug`, `sku`, `short_description`, `description`, `price`, `sale_price`, `cost_price`, `stock_quantity`, `stock_status`, `product_type`, `fabric`, `color`, `size`, `featured`, `status`, `created_at`) VALUES
(19, 'Zara Structured Satin Dress', 'zara-structured-satin-dress', 'TC-WS-0004', 'A thoughtfully designed western wear piece with refined finishing and an easy, elegant fit.', 'A thoughtfully designed western wear piece with refined finishing and an easy, elegant fit. Crafted from carefully selected fabric with attention to detail, this piece is part of the TayyabaCollective collection — designed to make you feel confident, comfortable and beautifully you.', 8225, NULL, NULL, 24, 'in_stock', 'Western Wear', 'Premium blended fabric', 'Navy', 'S · M · L · XL', 0, 1, DATE_SUB(NOW(), INTERVAL 4 DAY));
INSERT INTO `products` (`category_id`, `name`, `slug`, `sku`, `short_description`, `description`, `price`, `sale_price`, `cost_price`, `stock_quantity`, `stock_status`, `product_type`, `fabric`, `color`, `size`, `featured`, `status`, `created_at`) VALUES
(19, 'Hania Pleated Midi Dress', 'hania-pleated-midi-dress', 'TC-WS-0005', 'A thoughtfully designed western wear piece with refined finishing and an easy, elegant fit.', 'A thoughtfully designed western wear piece with refined finishing and an easy, elegant fit. Crafted from carefully selected fabric with attention to detail, this piece is part of the TayyabaCollective collection — designed to make you feel confident, comfortable and beautifully you.', 8900, NULL, NULL, 31, 'in_stock', 'Western Wear', 'Premium blended fabric', 'Blush Pink', 'S · M · L · XL', 0, 1, DATE_SUB(NOW(), INTERVAL 5 DAY));
INSERT INTO `products` (`category_id`, `name`, `slug`, `sku`, `short_description`, `description`, `price`, `sale_price`, `cost_price`, `stock_quantity`, `stock_status`, `product_type`, `fabric`, `color`, `size`, `featured`, `status`, `created_at`) VALUES
(19, 'Iman Oversized Button Shirt', 'iman-oversized-button-shirt', 'TC-WS-0006', 'A thoughtfully designed western wear piece with refined finishing and an easy, elegant fit.', 'A thoughtfully designed western wear piece with refined finishing and an easy, elegant fit. Crafted from carefully selected fabric with attention to detail, this piece is part of the TayyabaCollective collection — designed to make you feel confident, comfortable and beautifully you.', 9575, NULL, NULL, 38, 'in_stock', 'Western Wear', 'Premium blended fabric', 'Black & Gold', 'S · M · L · XL', 0, 1, DATE_SUB(NOW(), INTERVAL 6 DAY));
INSERT INTO `products` (`category_id`, `name`, `slug`, `sku`, `short_description`, `description`, `price`, `sale_price`, `cost_price`, `stock_quantity`, `stock_status`, `product_type`, `fabric`, `color`, `size`, `featured`, `status`, `created_at`) VALUES
(19, 'Ayesha Denim Co-ord', 'ayesha-denim-co-ord', 'TC-WS-0007', 'A thoughtfully designed western wear piece with refined finishing and an easy, elegant fit.', 'A thoughtfully designed western wear piece with refined finishing and an easy, elegant fit. Crafted from carefully selected fabric with attention to detail, this piece is part of the TayyabaCollective collection — designed to make you feel confident, comfortable and beautifully you.', 10250, NULL, NULL, 45, 'in_stock', 'Western Wear', 'Premium blended fabric', 'Mustard', 'S · M · L · XL', 0, 1, DATE_SUB(NOW(), INTERVAL 7 DAY));
INSERT INTO `products` (`category_id`, `name`, `slug`, `sku`, `short_description`, `description`, `price`, `sale_price`, `cost_price`, `stock_quantity`, `stock_status`, `product_type`, `fabric`, `color`, `size`, `featured`, `status`, `created_at`) VALUES
(19, 'Nadia Structured Mini Dress', 'nadia-structured-mini-dress', 'TC-WS-0008', 'A thoughtfully designed western wear piece with refined finishing and an easy, elegant fit.', 'A thoughtfully designed western wear piece with refined finishing and an easy, elegant fit. Crafted from carefully selected fabric with attention to detail, this piece is part of the TayyabaCollective collection — designed to make you feel confident, comfortable and beautifully you.', 10925, NULL, NULL, 7, 'in_stock', 'Western Wear', 'Premium blended fabric', 'Dusty Rose', 'S · M · L · XL', 0, 1, DATE_SUB(NOW(), INTERVAL 8 DAY));
INSERT INTO `products` (`category_id`, `name`, `slug`, `sku`, `short_description`, `description`, `price`, `sale_price`, `cost_price`, `stock_quantity`, `stock_status`, `product_type`, `fabric`, `color`, `size`, `featured`, `status`, `created_at`) VALUES
(19, 'Sana Relaxed Blazer Set', 'sana-relaxed-blazer-set', 'TC-WS-0009', 'A thoughtfully designed western wear piece with refined finishing and an easy, elegant fit.', 'A thoughtfully designed western wear piece with refined finishing and an easy, elegant fit. Crafted from carefully selected fabric with attention to detail, this piece is part of the TayyabaCollective collection — designed to make you feel confident, comfortable and beautifully you.', 11600, 10208, NULL, 14, 'in_stock', 'Western Wear', 'Premium blended fabric', 'Teal', 'S · M · L · XL', 0, 1, DATE_SUB(NOW(), INTERVAL 9 DAY));
INSERT INTO `products` (`category_id`, `name`, `slug`, `sku`, `short_description`, `description`, `price`, `sale_price`, `cost_price`, `stock_quantity`, `stock_status`, `product_type`, `fabric`, `color`, `size`, `featured`, `status`, `created_at`) VALUES
(19, 'Fahra Satin Slip Dress', 'fahra-satin-slip-dress', 'TC-WS-0010', 'A thoughtfully designed western wear piece with refined finishing and an easy, elegant fit.', 'A thoughtfully designed western wear piece with refined finishing and an easy, elegant fit. Crafted from carefully selected fabric with attention to detail, this piece is part of the TayyabaCollective collection — designed to make you feel confident, comfortable and beautifully you.', 12275, NULL, NULL, 21, 'in_stock', 'Western Wear', 'Premium blended fabric', 'Charcoal', 'S · M · L · XL', 1, 1, DATE_SUB(NOW(), INTERVAL 10 DAY));
INSERT INTO `products` (`category_id`, `name`, `slug`, `sku`, `short_description`, `description`, `price`, `sale_price`, `cost_price`, `stock_quantity`, `stock_status`, `product_type`, `fabric`, `color`, `size`, `featured`, `status`, `created_at`) VALUES
(19, 'Mia Wide-Leg Trousers', 'mia-wide-leg-trousers', 'TC-WS-0011', 'A thoughtfully designed western wear piece with refined finishing and an easy, elegant fit.', 'A thoughtfully designed western wear piece with refined finishing and an easy, elegant fit. Crafted from carefully selected fabric with attention to detail, this piece is part of the TayyabaCollective collection — designed to make you feel confident, comfortable and beautifully you.', 12950, NULL, NULL, 28, 'in_stock', 'Western Wear', 'Premium blended fabric', 'Maroon & Gold', 'S · M · L · XL', 0, 1, DATE_SUB(NOW(), INTERVAL 11 DAY));
INSERT INTO `products` (`category_id`, `name`, `slug`, `sku`, `short_description`, `description`, `price`, `sale_price`, `cost_price`, `stock_quantity`, `stock_status`, `product_type`, `fabric`, `color`, `size`, `featured`, `status`, `created_at`) VALUES
(19, 'Ira Cashmere Knit Set', 'ira-cashmere-knit-set', 'TC-WS-0012', 'A thoughtfully designed western wear piece with refined finishing and an easy, elegant fit.', 'A thoughtfully designed western wear piece with refined finishing and an easy, elegant fit. Crafted from carefully selected fabric with attention to detail, this piece is part of the TayyabaCollective collection — designed to make you feel confident, comfortable and beautifully you.', 13625, NULL, NULL, 0, 'out_of_stock', 'Western Wear', 'Premium blended fabric', 'Ivory', 'S · M · L · XL', 0, 1, DATE_SUB(NOW(), INTERVAL 12 DAY));
INSERT INTO `products` (`category_id`, `name`, `slug`, `sku`, `short_description`, `description`, `price`, `sale_price`, `cost_price`, `stock_quantity`, `stock_status`, `product_type`, `fabric`, `color`, `size`, `featured`, `status`, `created_at`) VALUES
(19, 'Anaya Pleated Skirt Set', 'anaya-pleated-skirt-set', 'TC-WS-0013', 'A thoughtfully designed western wear piece with refined finishing and an easy, elegant fit.', 'A thoughtfully designed western wear piece with refined finishing and an easy, elegant fit. Crafted from carefully selected fabric with attention to detail, this piece is part of the TayyabaCollective collection — designed to make you feel confident, comfortable and beautifully you.', 14300, NULL, NULL, 42, 'in_stock', 'Western Wear', 'Premium blended fabric', 'Emerald', 'S · M · L · XL', 0, 1, DATE_SUB(NOW(), INTERVAL 13 DAY));
INSERT INTO `products` (`category_id`, `name`, `slug`, `sku`, `short_description`, `description`, `price`, `sale_price`, `cost_price`, `stock_quantity`, `stock_status`, `product_type`, `fabric`, `color`, `size`, `featured`, `status`, `created_at`) VALUES
(19, 'Emaan White Linen Shirt', 'emaan-white-linen-shirt', 'TC-WS-0014', 'A thoughtfully designed western wear piece with refined finishing and an easy, elegant fit.', 'A thoughtfully designed western wear piece with refined finishing and an easy, elegant fit. Crafted from carefully selected fabric with attention to detail, this piece is part of the TayyabaCollective collection — designed to make you feel confident, comfortable and beautifully you.', 6475, NULL, NULL, 4, 'low_stock', 'Western Wear', 'Premium blended fabric', 'Navy', 'S · M · L · XL', 0, 1, DATE_SUB(NOW(), INTERVAL 14 DAY));
INSERT INTO `products` (`category_id`, `name`, `slug`, `sku`, `short_description`, `description`, `price`, `sale_price`, `cost_price`, `stock_quantity`, `stock_status`, `product_type`, `fabric`, `color`, `size`, `featured`, `status`, `created_at`) VALUES
(19, 'Zoya Tailored Pant Suit', 'zoya-tailored-pant-suit', 'TC-WS-0015', 'A thoughtfully designed western wear piece with refined finishing and an easy, elegant fit.', 'A thoughtfully designed western wear piece with refined finishing and an easy, elegant fit. Crafted from carefully selected fabric with attention to detail, this piece is part of the TayyabaCollective collection — designed to make you feel confident, comfortable and beautifully you.', 7150, NULL, NULL, 11, 'in_stock', 'Western Wear', 'Premium blended fabric', 'Blush Pink', 'S · M · L · XL', 0, 1, DATE_SUB(NOW(), INTERVAL 15 DAY));
INSERT INTO `products` (`category_id`, `name`, `slug`, `sku`, `short_description`, `description`, `price`, `sale_price`, `cost_price`, `stock_quantity`, `stock_status`, `product_type`, `fabric`, `color`, `size`, `featured`, `status`, `created_at`) VALUES
(19, 'Maryam Knit Polo Dress', 'maryam-knit-polo-dress', 'TC-WS-0016', 'A thoughtfully designed western wear piece with refined finishing and an easy, elegant fit.', 'A thoughtfully designed western wear piece with refined finishing and an easy, elegant fit. Crafted from carefully selected fabric with attention to detail, this piece is part of the TayyabaCollective collection — designed to make you feel confident, comfortable and beautifully you.', 7825, NULL, NULL, 18, 'in_stock', 'Western Wear', 'Premium blended fabric', 'Black & Gold', 'S · M · L · XL', 0, 1, DATE_SUB(NOW(), INTERVAL 16 DAY));
INSERT INTO `products` (`category_id`, `name`, `slug`, `sku`, `short_description`, `description`, `price`, `sale_price`, `cost_price`, `stock_quantity`, `stock_status`, `product_type`, `fabric`, `color`, `size`, `featured`, `status`, `created_at`) VALUES
(19, 'Hira Layered Co-ord', 'hira-layered-co-ord', 'TC-WS-0017', 'A thoughtfully designed western wear piece with refined finishing and an easy, elegant fit.', 'A thoughtfully designed western wear piece with refined finishing and an easy, elegant fit. Crafted from carefully selected fabric with attention to detail, this piece is part of the TayyabaCollective collection — designed to make you feel confident, comfortable and beautifully you.', 8500, 7480, NULL, 25, 'in_stock', 'Western Wear', 'Premium blended fabric', 'Mustard', 'S · M · L · XL', 0, 1, DATE_SUB(NOW(), INTERVAL 17 DAY));
INSERT INTO `products` (`category_id`, `name`, `slug`, `sku`, `short_description`, `description`, `price`, `sale_price`, `cost_price`, `stock_quantity`, `stock_status`, `product_type`, `fabric`, `color`, `size`, `featured`, `status`, `created_at`) VALUES
(19, 'Sofia Pleated Jumpsuit', 'sofia-pleated-jumpsuit', 'TC-WS-0018', 'A thoughtfully designed western wear piece with refined finishing and an easy, elegant fit.', 'A thoughtfully designed western wear piece with refined finishing and an easy, elegant fit. Crafted from carefully selected fabric with attention to detail, this piece is part of the TayyabaCollective collection — designed to make you feel confident, comfortable and beautifully you.', 9175, NULL, NULL, 32, 'in_stock', 'Western Wear', 'Premium blended fabric', 'Dusty Rose', 'S · M · L · XL', 0, 1, DATE_SUB(NOW(), INTERVAL 18 DAY));
INSERT INTO `products` (`category_id`, `name`, `slug`, `sku`, `short_description`, `description`, `price`, `sale_price`, `cost_price`, `stock_quantity`, `stock_status`, `product_type`, `fabric`, `color`, `size`, `featured`, `status`, `created_at`) VALUES
(19, 'Rania Smart Casual Set', 'rania-smart-casual-set', 'TC-WS-0019', 'A thoughtfully designed western wear piece with refined finishing and an easy, elegant fit.', 'A thoughtfully designed western wear piece with refined finishing and an easy, elegant fit. Crafted from carefully selected fabric with attention to detail, this piece is part of the TayyabaCollective collection — designed to make you feel confident, comfortable and beautifully you.', 9850, NULL, NULL, 39, 'in_stock', 'Western Wear', 'Premium blended fabric', 'Teal', 'S · M · L · XL', 1, 1, DATE_SUB(NOW(), INTERVAL 19 DAY));
INSERT INTO `products` (`category_id`, `name`, `slug`, `sku`, `short_description`, `description`, `price`, `sale_price`, `cost_price`, `stock_quantity`, `stock_status`, `product_type`, `fabric`, `color`, `size`, `featured`, `status`, `created_at`) VALUES
(19, 'Aisha Monochrome Co-ord', 'aisha-monochrome-co-ord', 'TC-WS-0020', 'A thoughtfully designed western wear piece with refined finishing and an easy, elegant fit.', 'A thoughtfully designed western wear piece with refined finishing and an easy, elegant fit. Crafted from carefully selected fabric with attention to detail, this piece is part of the TayyabaCollective collection — designed to make you feel confident, comfortable and beautifully you.', 10525, NULL, NULL, 46, 'in_stock', 'Western Wear', 'Premium blended fabric', 'Charcoal', 'S · M · L · XL', 0, 1, DATE_SUB(NOW(), INTERVAL 20 DAY));
INSERT INTO `products` (`category_id`, `name`, `slug`, `sku`, `short_description`, `description`, `price`, `sale_price`, `cost_price`, `stock_quantity`, `stock_status`, `product_type`, `fabric`, `color`, `size`, `featured`, `status`, `created_at`) VALUES
(19, 'Mahir Cotton Shirt Dress', 'mahir-cotton-shirt-dress', 'TC-WS-0021', 'A thoughtfully designed western wear piece with refined finishing and an easy, elegant fit.', 'A thoughtfully designed western wear piece with refined finishing and an easy, elegant fit. Crafted from carefully selected fabric with attention to detail, this piece is part of the TayyabaCollective collection — designed to make you feel confident, comfortable and beautifully you.', 11200, NULL, NULL, 8, 'in_stock', 'Western Wear', 'Premium blended fabric', 'Maroon & Gold', 'S · M · L · XL', 0, 1, DATE_SUB(NOW(), INTERVAL 21 DAY));
INSERT INTO `products` (`category_id`, `name`, `slug`, `sku`, `short_description`, `description`, `price`, `sale_price`, `cost_price`, `stock_quantity`, `stock_status`, `product_type`, `fabric`, `color`, `size`, `featured`, `status`, `created_at`) VALUES
(19, 'Nisa Belted Midi Dress', 'nisa-belted-midi-dress', 'TC-WS-0022', 'A thoughtfully designed western wear piece with refined finishing and an easy, elegant fit.', 'A thoughtfully designed western wear piece with refined finishing and an easy, elegant fit. Crafted from carefully selected fabric with attention to detail, this piece is part of the TayyabaCollective collection — designed to make you feel confident, comfortable and beautifully you.', 11875, NULL, NULL, 15, 'in_stock', 'Western Wear', 'Premium blended fabric', 'Ivory', 'S · M · L · XL', 0, 1, DATE_SUB(NOW(), INTERVAL 22 DAY));
INSERT INTO `products` (`category_id`, `name`, `slug`, `sku`, `short_description`, `description`, `price`, `sale_price`, `cost_price`, `stock_quantity`, `stock_status`, `product_type`, `fabric`, `color`, `size`, `featured`, `status`, `created_at`) VALUES
(19, 'Farah Relaxed Twill Suit', 'farah-relaxed-twill-suit', 'TC-WS-0023', 'A thoughtfully designed western wear piece with refined finishing and an easy, elegant fit.', 'A thoughtfully designed western wear piece with refined finishing and an easy, elegant fit. Crafted from carefully selected fabric with attention to detail, this piece is part of the TayyabaCollective collection — designed to make you feel confident, comfortable and beautifully you.', 12550, NULL, NULL, 0, 'out_of_stock', 'Western Wear', 'Premium blended fabric', 'Emerald', 'S · M · L · XL', 0, 1, DATE_SUB(NOW(), INTERVAL 23 DAY));
INSERT INTO `products` (`category_id`, `name`, `slug`, `sku`, `short_description`, `description`, `price`, `sale_price`, `cost_price`, `stock_quantity`, `stock_status`, `product_type`, `fabric`, `color`, `size`, `featured`, `status`, `created_at`) VALUES
(19, 'Rimsha Lounge Dress', 'rimsha-lounge-dress', 'TC-WS-0024', 'A thoughtfully designed western wear piece with refined finishing and an easy, elegant fit.', 'A thoughtfully designed western wear piece with refined finishing and an easy, elegant fit. Crafted from carefully selected fabric with attention to detail, this piece is part of the TayyabaCollective collection — designed to make you feel confident, comfortable and beautifully you.', 13225, NULL, NULL, 29, 'in_stock', 'Western Wear', 'Premium blended fabric', 'Navy', 'S · M · L · XL', 0, 1, DATE_SUB(NOW(), INTERVAL 24 DAY));
INSERT INTO `products` (`category_id`, `name`, `slug`, `sku`, `short_description`, `description`, `price`, `sale_price`, `cost_price`, `stock_quantity`, `stock_status`, `product_type`, `fabric`, `color`, `size`, `featured`, `status`, `created_at`) VALUES
(19, 'Areeba Longline Blazer', 'areeba-longline-blazer', 'TC-WS-0025', 'A thoughtfully designed western wear piece with refined finishing and an easy, elegant fit.', 'A thoughtfully designed western wear piece with refined finishing and an easy, elegant fit. Crafted from carefully selected fabric with attention to detail, this piece is part of the TayyabaCollective collection — designed to make you feel confident, comfortable and beautifully you.', 13900, 12232, NULL, 36, 'in_stock', 'Western Wear', 'Premium blended fabric', 'Blush Pink', 'S · M · L · XL', 0, 1, DATE_SUB(NOW(), INTERVAL 25 DAY));
INSERT INTO `products` (`category_id`, `name`, `slug`, `sku`, `short_description`, `description`, `price`, `sale_price`, `cost_price`, `stock_quantity`, `stock_status`, `product_type`, `fabric`, `color`, `size`, `featured`, `status`, `created_at`) VALUES
(19, 'Sahar Utility Co-ord', 'sahar-utility-co-ord', 'TC-WS-0026', 'A thoughtfully designed western wear piece with refined finishing and an easy, elegant fit.', 'A thoughtfully designed western wear piece with refined finishing and an easy, elegant fit. Crafted from carefully selected fabric with attention to detail, this piece is part of the TayyabaCollective collection — designed to make you feel confident, comfortable and beautifully you.', 14575, NULL, NULL, 43, 'in_stock', 'Western Wear', 'Premium blended fabric', 'Black & Gold', 'S · M · L · XL', 0, 1, DATE_SUB(NOW(), INTERVAL 26 DAY));
INSERT INTO `products` (`category_id`, `name`, `slug`, `sku`, `short_description`, `description`, `price`, `sale_price`, `cost_price`, `stock_quantity`, `stock_status`, `product_type`, `fabric`, `color`, `size`, `featured`, `status`, `created_at`) VALUES
(19, 'Hira Soft Knit Dress', 'hira-soft-knit-dress', 'TC-WS-0027', 'A thoughtfully designed western wear piece with refined finishing and an easy, elegant fit.', 'A thoughtfully designed western wear piece with refined finishing and an easy, elegant fit. Crafted from carefully selected fabric with attention to detail, this piece is part of the TayyabaCollective collection — designed to make you feel confident, comfortable and beautifully you.', 6750, NULL, NULL, 5, 'low_stock', 'Western Wear', 'Premium blended fabric', 'Mustard', 'S · M · L · XL', 0, 1, DATE_SUB(NOW(), INTERVAL 27 DAY));
INSERT INTO `products` (`category_id`, `name`, `slug`, `sku`, `short_description`, `description`, `price`, `sale_price`, `cost_price`, `stock_quantity`, `stock_status`, `product_type`, `fabric`, `color`, `size`, `featured`, `status`, `created_at`) VALUES
(19, 'Leena Professional Set', 'leena-professional-set', 'TC-WS-0028', 'A thoughtfully designed western wear piece with refined finishing and an easy, elegant fit.', 'A thoughtfully designed western wear piece with refined finishing and an easy, elegant fit. Crafted from carefully selected fabric with attention to detail, this piece is part of the TayyabaCollective collection — designed to make you feel confident, comfortable and beautifully you.', 7425, NULL, NULL, 12, 'in_stock', 'Western Wear', 'Premium blended fabric', 'Dusty Rose', 'S · M · L · XL', 1, 1, DATE_SUB(NOW(), INTERVAL 28 DAY));
INSERT INTO `products` (`category_id`, `name`, `slug`, `sku`, `short_description`, `description`, `price`, `sale_price`, `cost_price`, `stock_quantity`, `stock_status`, `product_type`, `fabric`, `color`, `size`, `featured`, `status`, `created_at`) VALUES
(19, 'Aiza Neutral Shirtdress', 'aiza-neutral-shirtdress', 'TC-WS-0029', 'A thoughtfully designed western wear piece with refined finishing and an easy, elegant fit.', 'A thoughtfully designed western wear piece with refined finishing and an easy, elegant fit. Crafted from carefully selected fabric with attention to detail, this piece is part of the TayyabaCollective collection — designed to make you feel confident, comfortable and beautifully you.', 8100, NULL, NULL, 19, 'in_stock', 'Western Wear', 'Premium blended fabric', 'Teal', 'S · M · L · XL', 0, 1, DATE_SUB(NOW(), INTERVAL 29 DAY));
INSERT INTO `products` (`category_id`, `name`, `slug`, `sku`, `short_description`, `description`, `price`, `sale_price`, `cost_price`, `stock_quantity`, `stock_status`, `product_type`, `fabric`, `color`, `size`, `featured`, `status`, `created_at`) VALUES
(19, 'Rida Tailored Skirt Set', 'rida-tailored-skirt-set', 'TC-WS-0030', 'A thoughtfully designed western wear piece with refined finishing and an easy, elegant fit.', 'A thoughtfully designed western wear piece with refined finishing and an easy, elegant fit. Crafted from carefully selected fabric with attention to detail, this piece is part of the TayyabaCollective collection — designed to make you feel confident, comfortable and beautifully you.', 8775, NULL, NULL, 26, 'in_stock', 'Western Wear', 'Premium blended fabric', 'Charcoal', 'S · M · L · XL', 0, 1, DATE_SUB(NOW(), INTERVAL 30 DAY));
INSERT INTO `products` (`category_id`, `name`, `slug`, `sku`, `short_description`, `description`, `price`, `sale_price`, `cost_price`, `stock_quantity`, `stock_status`, `product_type`, `fabric`, `color`, `size`, `featured`, `status`, `created_at`) VALUES
(20, 'Anaya Bridal Eastern Ensemble', 'anaya-bridal-eastern-ensemble', 'TC-ES-0001', 'A thoughtfully designed eastern wear piece with refined finishing and an easy, elegant fit.', 'A thoughtfully designed eastern wear piece with refined finishing and an easy, elegant fit. Crafted from carefully selected fabric with attention to detail, this piece is part of the TayyabaCollective collection — designed to make you feel confident, comfortable and beautifully you.', 6200, 5456, NULL, 0, 'out_of_stock', 'Eastern Wear', 'Premium silk & chiffon', 'Maroon & Gold', 'S · M · L · XL', 1, 1, DATE_SUB(NOW(), INTERVAL 1 DAY));
INSERT INTO `products` (`category_id`, `name`, `slug`, `sku`, `short_description`, `description`, `price`, `sale_price`, `cost_price`, `stock_quantity`, `stock_status`, `product_type`, `fabric`, `color`, `size`, `featured`, `status`, `created_at`) VALUES
(20, 'Hania Eastern Angrakha', 'hania-eastern-angrakha', 'TC-ES-0002', 'A thoughtfully designed eastern wear piece with refined finishing and an easy, elegant fit.', 'A thoughtfully designed eastern wear piece with refined finishing and an easy, elegant fit. Crafted from carefully selected fabric with attention to detail, this piece is part of the TayyabaCollective collection — designed to make you feel confident, comfortable and beautifully you.', 6875, NULL, NULL, 10, 'in_stock', 'Eastern Wear', 'Premium silk & chiffon', 'Ivory', 'S · M · L · XL', 0, 1, DATE_SUB(NOW(), INTERVAL 2 DAY));
INSERT INTO `products` (`category_id`, `name`, `slug`, `sku`, `short_description`, `description`, `price`, `sale_price`, `cost_price`, `stock_quantity`, `stock_status`, `product_type`, `fabric`, `color`, `size`, `featured`, `status`, `created_at`) VALUES
(20, 'Mahnoor Gota Work Kurta', 'mahnoor-gota-work-kurta', 'TC-ES-0003', 'A thoughtfully designed eastern wear piece with refined finishing and an easy, elegant fit.', 'A thoughtfully designed eastern wear piece with refined finishing and an easy, elegant fit. Crafted from carefully selected fabric with attention to detail, this piece is part of the TayyabaCollective collection — designed to make you feel confident, comfortable and beautifully you.', 7550, NULL, NULL, 17, 'in_stock', 'Eastern Wear', 'Premium silk & chiffon', 'Emerald', 'S · M · L · XL', 0, 1, DATE_SUB(NOW(), INTERVAL 3 DAY));
INSERT INTO `products` (`category_id`, `name`, `slug`, `sku`, `short_description`, `description`, `price`, `sale_price`, `cost_price`, `stock_quantity`, `stock_status`, `product_type`, `fabric`, `color`, `size`, `featured`, `status`, `created_at`) VALUES
(20, 'Rania Embroidered Sharara', 'rania-embroidered-sharara', 'TC-ES-0004', 'A thoughtfully designed eastern wear piece with refined finishing and an easy, elegant fit.', 'A thoughtfully designed eastern wear piece with refined finishing and an easy, elegant fit. Crafted from carefully selected fabric with attention to detail, this piece is part of the TayyabaCollective collection — designed to make you feel confident, comfortable and beautifully you.', 8225, NULL, NULL, 24, 'in_stock', 'Eastern Wear', 'Premium silk & chiffon', 'Navy', 'S · M · L · XL', 0, 1, DATE_SUB(NOW(), INTERVAL 4 DAY));
INSERT INTO `products` (`category_id`, `name`, `slug`, `sku`, `short_description`, `description`, `price`, `sale_price`, `cost_price`, `stock_quantity`, `stock_status`, `product_type`, `fabric`, `color`, `size`, `featured`, `status`, `created_at`) VALUES
(20, 'Faryal Net Dupatta Set', 'faryal-net-dupatta-set', 'TC-ES-0005', 'A thoughtfully designed eastern wear piece with refined finishing and an easy, elegant fit.', 'A thoughtfully designed eastern wear piece with refined finishing and an easy, elegant fit. Crafted from carefully selected fabric with attention to detail, this piece is part of the TayyabaCollective collection — designed to make you feel confident, comfortable and beautifully you.', 8900, NULL, NULL, 31, 'in_stock', 'Eastern Wear', 'Premium silk & chiffon', 'Blush Pink', 'S · M · L · XL', 0, 1, DATE_SUB(NOW(), INTERVAL 5 DAY));
INSERT INTO `products` (`category_id`, `name`, `slug`, `sku`, `short_description`, `description`, `price`, `sale_price`, `cost_price`, `stock_quantity`, `stock_status`, `product_type`, `fabric`, `color`, `size`, `featured`, `status`, `created_at`) VALUES
(20, 'Aisha Silk Festive Suit', 'aisha-silk-festive-suit', 'TC-ES-0006', 'A thoughtfully designed eastern wear piece with refined finishing and an easy, elegant fit.', 'A thoughtfully designed eastern wear piece with refined finishing and an easy, elegant fit. Crafted from carefully selected fabric with attention to detail, this piece is part of the TayyabaCollective collection — designed to make you feel confident, comfortable and beautifully you.', 9575, NULL, NULL, 38, 'in_stock', 'Eastern Wear', 'Premium silk & chiffon', 'Black & Gold', 'S · M · L · XL', 0, 1, DATE_SUB(NOW(), INTERVAL 6 DAY));
INSERT INTO `products` (`category_id`, `name`, `slug`, `sku`, `short_description`, `description`, `price`, `sale_price`, `cost_price`, `stock_quantity`, `stock_status`, `product_type`, `fabric`, `color`, `size`, `featured`, `status`, `created_at`) VALUES
(20, 'Maham Modern Eastern Set', 'maham-modern-eastern-set', 'TC-ES-0007', 'A thoughtfully designed eastern wear piece with refined finishing and an easy, elegant fit.', 'A thoughtfully designed eastern wear piece with refined finishing and an easy, elegant fit. Crafted from carefully selected fabric with attention to detail, this piece is part of the TayyabaCollective collection — designed to make you feel confident, comfortable and beautifully you.', 10250, NULL, NULL, 45, 'in_stock', 'Eastern Wear', 'Premium silk & chiffon', 'Mustard', 'S · M · L · XL', 0, 1, DATE_SUB(NOW(), INTERVAL 7 DAY));
INSERT INTO `products` (`category_id`, `name`, `slug`, `sku`, `short_description`, `description`, `price`, `sale_price`, `cost_price`, `stock_quantity`, `stock_status`, `product_type`, `fabric`, `color`, `size`, `featured`, `status`, `created_at`) VALUES
(20, 'Sadia Embroidered Gown', 'sadia-embroidered-gown', 'TC-ES-0008', 'A thoughtfully designed eastern wear piece with refined finishing and an easy, elegant fit.', 'A thoughtfully designed eastern wear piece with refined finishing and an easy, elegant fit. Crafted from carefully selected fabric with attention to detail, this piece is part of the TayyabaCollective collection — designed to make you feel confident, comfortable and beautifully you.', 10925, NULL, NULL, 7, 'in_stock', 'Eastern Wear', 'Premium silk & chiffon', 'Dusty Rose', 'S · M · L · XL', 0, 1, DATE_SUB(NOW(), INTERVAL 8 DAY));
INSERT INTO `products` (`category_id`, `name`, `slug`, `sku`, `short_description`, `description`, `price`, `sale_price`, `cost_price`, `stock_quantity`, `stock_status`, `product_type`, `fabric`, `color`, `size`, `featured`, `status`, `created_at`) VALUES
(20, 'Nisha Festive Kurta Set', 'nisha-festive-kurta-set', 'TC-ES-0009', 'A thoughtfully designed eastern wear piece with refined finishing and an easy, elegant fit.', 'A thoughtfully designed eastern wear piece with refined finishing and an easy, elegant fit. Crafted from carefully selected fabric with attention to detail, this piece is part of the TayyabaCollective collection — designed to make you feel confident, comfortable and beautifully you.', 11600, 10208, NULL, 14, 'in_stock', 'Eastern Wear', 'Premium silk & chiffon', 'Teal', 'S · M · L · XL', 0, 1, DATE_SUB(NOW(), INTERVAL 9 DAY));
INSERT INTO `products` (`category_id`, `name`, `slug`, `sku`, `short_description`, `description`, `price`, `sale_price`, `cost_price`, `stock_quantity`, `stock_status`, `product_type`, `fabric`, `color`, `size`, `featured`, `status`, `created_at`) VALUES
(20, 'Areeba Traditional Chiffon Set', 'areeba-traditional-chiffon-set', 'TC-ES-0010', 'A thoughtfully designed eastern wear piece with refined finishing and an easy, elegant fit.', 'A thoughtfully designed eastern wear piece with refined finishing and an easy, elegant fit. Crafted from carefully selected fabric with attention to detail, this piece is part of the TayyabaCollective collection — designed to make you feel confident, comfortable and beautifully you.', 12275, NULL, NULL, 21, 'in_stock', 'Eastern Wear', 'Premium silk & chiffon', 'Charcoal', 'S · M · L · XL', 1, 1, DATE_SUB(NOW(), INTERVAL 10 DAY));
INSERT INTO `products` (`category_id`, `name`, `slug`, `sku`, `short_description`, `description`, `price`, `sale_price`, `cost_price`, `stock_quantity`, `stock_status`, `product_type`, `fabric`, `color`, `size`, `featured`, `status`, `created_at`) VALUES
(20, 'Hira Organza Angrakha', 'hira-organza-angrakha', 'TC-ES-0011', 'A thoughtfully designed eastern wear piece with refined finishing and an easy, elegant fit.', 'A thoughtfully designed eastern wear piece with refined finishing and an easy, elegant fit. Crafted from carefully selected fabric with attention to detail, this piece is part of the TayyabaCollective collection — designed to make you feel confident, comfortable and beautifully you.', 12950, NULL, NULL, 28, 'in_stock', 'Eastern Wear', 'Premium silk & chiffon', 'Maroon & Gold', 'S · M · L · XL', 0, 1, DATE_SUB(NOW(), INTERVAL 11 DAY));
INSERT INTO `products` (`category_id`, `name`, `slug`, `sku`, `short_description`, `description`, `price`, `sale_price`, `cost_price`, `stock_quantity`, `stock_status`, `product_type`, `fabric`, `color`, `size`, `featured`, `status`, `created_at`) VALUES
(20, 'Maryam Pastel Eastern Set', 'maryam-pastel-eastern-set', 'TC-ES-0012', 'A thoughtfully designed eastern wear piece with refined finishing and an easy, elegant fit.', 'A thoughtfully designed eastern wear piece with refined finishing and an easy, elegant fit. Crafted from carefully selected fabric with attention to detail, this piece is part of the TayyabaCollective collection — designed to make you feel confident, comfortable and beautifully you.', 13625, NULL, NULL, 0, 'out_of_stock', 'Eastern Wear', 'Premium silk & chiffon', 'Ivory', 'S · M · L · XL', 0, 1, DATE_SUB(NOW(), INTERVAL 12 DAY));
INSERT INTO `products` (`category_id`, `name`, `slug`, `sku`, `short_description`, `description`, `price`, `sale_price`, `cost_price`, `stock_quantity`, `stock_status`, `product_type`, `fabric`, `color`, `size`, `featured`, `status`, `created_at`) VALUES
(20, 'Alina Gharara Set', 'alina-gharara-set', 'TC-ES-0013', 'A thoughtfully designed eastern wear piece with refined finishing and an easy, elegant fit.', 'A thoughtfully designed eastern wear piece with refined finishing and an easy, elegant fit. Crafted from carefully selected fabric with attention to detail, this piece is part of the TayyabaCollective collection — designed to make you feel confident, comfortable and beautifully you.', 14300, NULL, NULL, 42, 'in_stock', 'Eastern Wear', 'Premium silk & chiffon', 'Emerald', 'S · M · L · XL', 0, 1, DATE_SUB(NOW(), INTERVAL 13 DAY));
INSERT INTO `products` (`category_id`, `name`, `slug`, `sku`, `short_description`, `description`, `price`, `sale_price`, `cost_price`, `stock_quantity`, `stock_status`, `product_type`, `fabric`, `color`, `size`, `featured`, `status`, `created_at`) VALUES
(20, 'Rida Festive Kurta Pant', 'rida-festive-kurta-pant', 'TC-ES-0014', 'A thoughtfully designed eastern wear piece with refined finishing and an easy, elegant fit.', 'A thoughtfully designed eastern wear piece with refined finishing and an easy, elegant fit. Crafted from carefully selected fabric with attention to detail, this piece is part of the TayyabaCollective collection — designed to make you feel confident, comfortable and beautifully you.', 6475, NULL, NULL, 4, 'low_stock', 'Eastern Wear', 'Premium silk & chiffon', 'Navy', 'S · M · L · XL', 0, 1, DATE_SUB(NOW(), INTERVAL 14 DAY));
INSERT INTO `products` (`category_id`, `name`, `slug`, `sku`, `short_description`, `description`, `price`, `sale_price`, `cost_price`, `stock_quantity`, `stock_status`, `product_type`, `fabric`, `color`, `size`, `featured`, `status`, `created_at`) VALUES
(20, 'Maham Silk Dupatta Set', 'maham-silk-dupatta-set', 'TC-ES-0015', 'A thoughtfully designed eastern wear piece with refined finishing and an easy, elegant fit.', 'A thoughtfully designed eastern wear piece with refined finishing and an easy, elegant fit. Crafted from carefully selected fabric with attention to detail, this piece is part of the TayyabaCollective collection — designed to make you feel confident, comfortable and beautifully you.', 7150, NULL, NULL, 11, 'in_stock', 'Eastern Wear', 'Premium silk & chiffon', 'Blush Pink', 'S · M · L · XL', 0, 1, DATE_SUB(NOW(), INTERVAL 15 DAY));
INSERT INTO `products` (`category_id`, `name`, `slug`, `sku`, `short_description`, `description`, `price`, `sale_price`, `cost_price`, `stock_quantity`, `stock_status`, `product_type`, `fabric`, `color`, `size`, `featured`, `status`, `created_at`) VALUES
(20, 'Zoya Rose Gold Set', 'zoya-rose-gold-set', 'TC-ES-0016', 'A thoughtfully designed eastern wear piece with refined finishing and an easy, elegant fit.', 'A thoughtfully designed eastern wear piece with refined finishing and an easy, elegant fit. Crafted from carefully selected fabric with attention to detail, this piece is part of the TayyabaCollective collection — designed to make you feel confident, comfortable and beautifully you.', 7825, NULL, NULL, 18, 'in_stock', 'Eastern Wear', 'Premium silk & chiffon', 'Black & Gold', 'S · M · L · XL', 0, 1, DATE_SUB(NOW(), INTERVAL 16 DAY));
INSERT INTO `products` (`category_id`, `name`, `slug`, `sku`, `short_description`, `description`, `price`, `sale_price`, `cost_price`, `stock_quantity`, `stock_status`, `product_type`, `fabric`, `color`, `size`, `featured`, `status`, `created_at`) VALUES
(20, 'Hania Bridal Chiffon Set', 'hania-bridal-chiffon-set', 'TC-ES-0017', 'A thoughtfully designed eastern wear piece with refined finishing and an easy, elegant fit.', 'A thoughtfully designed eastern wear piece with refined finishing and an easy, elegant fit. Crafted from carefully selected fabric with attention to detail, this piece is part of the TayyabaCollective collection — designed to make you feel confident, comfortable and beautifully you.', 8500, 7480, NULL, 25, 'in_stock', 'Eastern Wear', 'Premium silk & chiffon', 'Mustard', 'S · M · L · XL', 0, 1, DATE_SUB(NOW(), INTERVAL 17 DAY));
INSERT INTO `products` (`category_id`, `name`, `slug`, `sku`, `short_description`, `description`, `price`, `sale_price`, `cost_price`, `stock_quantity`, `stock_status`, `product_type`, `fabric`, `color`, `size`, `featured`, `status`, `created_at`) VALUES
(20, 'Aisha Printed Eastern Suit', 'aisha-printed-eastern-suit', 'TC-ES-0018', 'A thoughtfully designed eastern wear piece with refined finishing and an easy, elegant fit.', 'A thoughtfully designed eastern wear piece with refined finishing and an easy, elegant fit. Crafted from carefully selected fabric with attention to detail, this piece is part of the TayyabaCollective collection — designed to make you feel confident, comfortable and beautifully you.', 9175, NULL, NULL, 32, 'in_stock', 'Eastern Wear', 'Premium silk & chiffon', 'Dusty Rose', 'S · M · L · XL', 0, 1, DATE_SUB(NOW(), INTERVAL 18 DAY));
INSERT INTO `products` (`category_id`, `name`, `slug`, `sku`, `short_description`, `description`, `price`, `sale_price`, `cost_price`, `stock_quantity`, `stock_status`, `product_type`, `fabric`, `color`, `size`, `featured`, `status`, `created_at`) VALUES
(20, 'Nadia Formal Eastern Set', 'nadia-formal-eastern-set', 'TC-ES-0019', 'A thoughtfully designed eastern wear piece with refined finishing and an easy, elegant fit.', 'A thoughtfully designed eastern wear piece with refined finishing and an easy, elegant fit. Crafted from carefully selected fabric with attention to detail, this piece is part of the TayyabaCollective collection — designed to make you feel confident, comfortable and beautifully you.', 9850, NULL, NULL, 39, 'in_stock', 'Eastern Wear', 'Premium silk & chiffon', 'Teal', 'S · M · L · XL', 1, 1, DATE_SUB(NOW(), INTERVAL 19 DAY));
INSERT INTO `products` (`category_id`, `name`, `slug`, `sku`, `short_description`, `description`, `price`, `sale_price`, `cost_price`, `stock_quantity`, `stock_status`, `product_type`, `fabric`, `color`, `size`, `featured`, `status`, `created_at`) VALUES
(20, 'Mila Embroidered Kurta', 'mila-embroidered-kurta', 'TC-ES-0020', 'A thoughtfully designed eastern wear piece with refined finishing and an easy, elegant fit.', 'A thoughtfully designed eastern wear piece with refined finishing and an easy, elegant fit. Crafted from carefully selected fabric with attention to detail, this piece is part of the TayyabaCollective collection — designed to make you feel confident, comfortable and beautifully you.', 10525, NULL, NULL, 46, 'in_stock', 'Eastern Wear', 'Premium silk & chiffon', 'Charcoal', 'S · M · L · XL', 0, 1, DATE_SUB(NOW(), INTERVAL 20 DAY));
INSERT INTO `products` (`category_id`, `name`, `slug`, `sku`, `short_description`, `description`, `price`, `sale_price`, `cost_price`, `stock_quantity`, `stock_status`, `product_type`, `fabric`, `color`, `size`, `featured`, `status`, `created_at`) VALUES
(20, 'Sahar Georgette Set', 'sahar-georgette-set', 'TC-ES-0021', 'A thoughtfully designed eastern wear piece with refined finishing and an easy, elegant fit.', 'A thoughtfully designed eastern wear piece with refined finishing and an easy, elegant fit. Crafted from carefully selected fabric with attention to detail, this piece is part of the TayyabaCollective collection — designed to make you feel confident, comfortable and beautifully you.', 11200, NULL, NULL, 8, 'in_stock', 'Eastern Wear', 'Premium silk & chiffon', 'Maroon & Gold', 'S · M · L · XL', 0, 1, DATE_SUB(NOW(), INTERVAL 21 DAY));
INSERT INTO `products` (`category_id`, `name`, `slug`, `sku`, `short_description`, `description`, `price`, `sale_price`, `cost_price`, `stock_quantity`, `stock_status`, `product_type`, `fabric`, `color`, `size`, `featured`, `status`, `created_at`) VALUES
(20, 'Fiza Pearled Dupatta Set', 'fiza-pearled-dupatta-set', 'TC-ES-0022', 'A thoughtfully designed eastern wear piece with refined finishing and an easy, elegant fit.', 'A thoughtfully designed eastern wear piece with refined finishing and an easy, elegant fit. Crafted from carefully selected fabric with attention to detail, this piece is part of the TayyabaCollective collection — designed to make you feel confident, comfortable and beautifully you.', 11875, NULL, NULL, 15, 'in_stock', 'Eastern Wear', 'Premium silk & chiffon', 'Ivory', 'S · M · L · XL', 0, 1, DATE_SUB(NOW(), INTERVAL 22 DAY));
INSERT INTO `products` (`category_id`, `name`, `slug`, `sku`, `short_description`, `description`, `price`, `sale_price`, `cost_price`, `stock_quantity`, `stock_status`, `product_type`, `fabric`, `color`, `size`, `featured`, `status`, `created_at`) VALUES
(20, 'Areej Satin Kurta Set', 'areej-satin-kurta-set', 'TC-ES-0023', 'A thoughtfully designed eastern wear piece with refined finishing and an easy, elegant fit.', 'A thoughtfully designed eastern wear piece with refined finishing and an easy, elegant fit. Crafted from carefully selected fabric with attention to detail, this piece is part of the TayyabaCollective collection — designed to make you feel confident, comfortable and beautifully you.', 12550, NULL, NULL, 0, 'out_of_stock', 'Eastern Wear', 'Premium silk & chiffon', 'Emerald', 'S · M · L · XL', 0, 1, DATE_SUB(NOW(), INTERVAL 23 DAY));
INSERT INTO `products` (`category_id`, `name`, `slug`, `sku`, `short_description`, `description`, `price`, `sale_price`, `cost_price`, `stock_quantity`, `stock_status`, `product_type`, `fabric`, `color`, `size`, `featured`, `status`, `created_at`) VALUES
(20, 'Yumna Chiffon Festive Set', 'yumna-chiffon-festive-set', 'TC-ES-0024', 'A thoughtfully designed eastern wear piece with refined finishing and an easy, elegant fit.', 'A thoughtfully designed eastern wear piece with refined finishing and an easy, elegant fit. Crafted from carefully selected fabric with attention to detail, this piece is part of the TayyabaCollective collection — designed to make you feel confident, comfortable and beautifully you.', 13225, NULL, NULL, 29, 'in_stock', 'Eastern Wear', 'Premium silk & chiffon', 'Navy', 'S · M · L · XL', 0, 1, DATE_SUB(NOW(), INTERVAL 24 DAY));
INSERT INTO `products` (`category_id`, `name`, `slug`, `sku`, `short_description`, `description`, `price`, `sale_price`, `cost_price`, `stock_quantity`, `stock_status`, `product_type`, `fabric`, `color`, `size`, `featured`, `status`, `created_at`) VALUES
(20, 'Sana Lace Eastern Set', 'sana-lace-eastern-set', 'TC-ES-0025', 'A thoughtfully designed eastern wear piece with refined finishing and an easy, elegant fit.', 'A thoughtfully designed eastern wear piece with refined finishing and an easy, elegant fit. Crafted from carefully selected fabric with attention to detail, this piece is part of the TayyabaCollective collection — designed to make you feel confident, comfortable and beautifully you.', 13900, 12232, NULL, 36, 'in_stock', 'Eastern Wear', 'Premium silk & chiffon', 'Blush Pink', 'S · M · L · XL', 0, 1, DATE_SUB(NOW(), INTERVAL 25 DAY));
INSERT INTO `products` (`category_id`, `name`, `slug`, `sku`, `short_description`, `description`, `price`, `sale_price`, `cost_price`, `stock_quantity`, `stock_status`, `product_type`, `fabric`, `color`, `size`, `featured`, `status`, `created_at`) VALUES
(20, 'Fariha Silk Gown', 'fariha-silk-gown', 'TC-ES-0026', 'A thoughtfully designed eastern wear piece with refined finishing and an easy, elegant fit.', 'A thoughtfully designed eastern wear piece with refined finishing and an easy, elegant fit. Crafted from carefully selected fabric with attention to detail, this piece is part of the TayyabaCollective collection — designed to make you feel confident, comfortable and beautifully you.', 14575, NULL, NULL, 43, 'in_stock', 'Eastern Wear', 'Premium silk & chiffon', 'Black & Gold', 'S · M · L · XL', 0, 1, DATE_SUB(NOW(), INTERVAL 26 DAY));
INSERT INTO `products` (`category_id`, `name`, `slug`, `sku`, `short_description`, `description`, `price`, `sale_price`, `cost_price`, `stock_quantity`, `stock_status`, `product_type`, `fabric`, `color`, `size`, `featured`, `status`, `created_at`) VALUES
(20, 'Emaan Embellished Shalwar', 'emaan-embellished-shalwar', 'TC-ES-0027', 'A thoughtfully designed eastern wear piece with refined finishing and an easy, elegant fit.', 'A thoughtfully designed eastern wear piece with refined finishing and an easy, elegant fit. Crafted from carefully selected fabric with attention to detail, this piece is part of the TayyabaCollective collection — designed to make you feel confident, comfortable and beautifully you.', 6750, NULL, NULL, 5, 'low_stock', 'Eastern Wear', 'Premium silk & chiffon', 'Mustard', 'S · M · L · XL', 0, 1, DATE_SUB(NOW(), INTERVAL 27 DAY));
INSERT INTO `products` (`category_id`, `name`, `slug`, `sku`, `short_description`, `description`, `price`, `sale_price`, `cost_price`, `stock_quantity`, `stock_status`, `product_type`, `fabric`, `color`, `size`, `featured`, `status`, `created_at`) VALUES
(20, 'Rimsha Party Eastern Suit', 'rimsha-party-eastern-suit', 'TC-ES-0028', 'A thoughtfully designed eastern wear piece with refined finishing and an easy, elegant fit.', 'A thoughtfully designed eastern wear piece with refined finishing and an easy, elegant fit. Crafted from carefully selected fabric with attention to detail, this piece is part of the TayyabaCollective collection — designed to make you feel confident, comfortable and beautifully you.', 7425, NULL, NULL, 12, 'in_stock', 'Eastern Wear', 'Premium silk & chiffon', 'Dusty Rose', 'S · M · L · XL', 1, 1, DATE_SUB(NOW(), INTERVAL 28 DAY));
INSERT INTO `products` (`category_id`, `name`, `slug`, `sku`, `short_description`, `description`, `price`, `sale_price`, `cost_price`, `stock_quantity`, `stock_status`, `product_type`, `fabric`, `color`, `size`, `featured`, `status`, `created_at`) VALUES
(20, 'Aiza Luxe Eastern Set', 'aiza-luxe-eastern-set', 'TC-ES-0029', 'A thoughtfully designed eastern wear piece with refined finishing and an easy, elegant fit.', 'A thoughtfully designed eastern wear piece with refined finishing and an easy, elegant fit. Crafted from carefully selected fabric with attention to detail, this piece is part of the TayyabaCollective collection — designed to make you feel confident, comfortable and beautifully you.', 8100, NULL, NULL, 19, 'in_stock', 'Eastern Wear', 'Premium silk & chiffon', 'Teal', 'S · M · L · XL', 0, 1, DATE_SUB(NOW(), INTERVAL 29 DAY));
INSERT INTO `products` (`category_id`, `name`, `slug`, `sku`, `short_description`, `description`, `price`, `sale_price`, `cost_price`, `stock_quantity`, `stock_status`, `product_type`, `fabric`, `color`, `size`, `featured`, `status`, `created_at`) VALUES
(20, 'Hira Velvet Eastern Set', 'hira-velvet-eastern-set', 'TC-ES-0030', 'A thoughtfully designed eastern wear piece with refined finishing and an easy, elegant fit.', 'A thoughtfully designed eastern wear piece with refined finishing and an easy, elegant fit. Crafted from carefully selected fabric with attention to detail, this piece is part of the TayyabaCollective collection — designed to make you feel confident, comfortable and beautifully you.', 8775, NULL, NULL, 26, 'in_stock', 'Eastern Wear', 'Premium silk & chiffon', 'Charcoal', 'S · M · L · XL', 0, 1, DATE_SUB(NOW(), INTERVAL 30 DAY));

-- Product <-> category links

INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (1, 1);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (1, 3);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (1, 16);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (1, 11);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (1, 5);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (2, 1);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (2, 3);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (2, 16);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (2, 11);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (2, 15);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (3, 1);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (3, 3);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (3, 16);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (3, 12);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (3, 4);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (4, 1);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (4, 3);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (4, 16);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (4, 13);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (4, 6);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (5, 1);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (5, 3);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (5, 16);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (5, 18);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (6, 1);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (6, 3);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (6, 16);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (6, 12);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (6, 10);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (7, 1);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (7, 3);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (7, 16);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (7, 14);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (8, 1);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (8, 3);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (8, 16);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (8, 4);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (9, 1);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (9, 3);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (9, 16);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (9, 12);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (9, 5);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (10, 1);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (10, 3);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (10, 16);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (10, 11);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (10, 15);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (11, 1);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (11, 3);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (11, 16);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (11, 14);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (12, 1);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (12, 3);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (12, 16);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (12, 7);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (13, 1);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (13, 3);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (13, 16);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (13, 7);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (13, 8);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (14, 1);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (14, 3);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (14, 16);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (14, 12);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (14, 15);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (15, 1);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (15, 3);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (15, 16);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (15, 11);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (16, 1);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (16, 3);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (16, 16);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (16, 7);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (16, 4);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (17, 1);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (17, 3);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (17, 16);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (17, 11);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (17, 7);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (17, 5);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (18, 1);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (18, 3);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (18, 16);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (18, 12);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (18, 10);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (19, 1);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (19, 3);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (19, 16);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (19, 7);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (20, 1);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (20, 3);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (20, 16);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (20, 14);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (21, 1);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (21, 3);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (21, 16);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (21, 11);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (22, 1);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (22, 3);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (22, 16);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (22, 12);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (22, 10);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (23, 1);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (23, 3);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (23, 16);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (23, 15);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (24, 1);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (24, 3);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (24, 16);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (25, 1);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (25, 3);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (25, 16);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (25, 5);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (25, 4);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (26, 1);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (26, 3);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (26, 16);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (26, 11);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (26, 8);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (27, 1);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (27, 3);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (27, 16);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (27, 7);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (28, 1);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (28, 3);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (28, 16);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (29, 1);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (29, 3);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (29, 16);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (29, 15);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (29, 7);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (30, 1);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (30, 3);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (30, 16);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (31, 2);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (31, 3);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (31, 11);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (31, 12);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (31, 7);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (31, 5);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (32, 2);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (32, 3);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (32, 15);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (33, 2);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (33, 3);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (33, 4);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (34, 2);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (34, 3);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (34, 11);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (34, 8);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (34, 18);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (35, 2);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (35, 3);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (35, 14);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (36, 2);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (36, 3);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (37, 2);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (37, 3);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (37, 11);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (37, 15);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (38, 2);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (38, 3);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (38, 4);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (39, 2);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (39, 3);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (39, 11);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (39, 5);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (40, 2);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (40, 3);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (41, 2);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (41, 3);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (41, 12);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (41, 15);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (42, 2);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (42, 3);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (42, 11);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (43, 2);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (43, 3);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (43, 15);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (44, 2);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (44, 3);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (44, 8);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (45, 2);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (45, 3);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (45, 15);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (46, 2);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (46, 3);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (46, 7);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (46, 4);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (47, 2);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (47, 3);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (47, 18);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (47, 5);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (48, 2);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (48, 3);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (48, 11);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (48, 15);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (49, 2);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (49, 3);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (49, 11);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (49, 15);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (50, 2);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (50, 3);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (50, 11);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (50, 7);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (51, 2);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (51, 3);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (51, 12);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (51, 10);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (52, 2);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (52, 3);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (52, 11);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (53, 2);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (53, 3);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (53, 11);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (54, 2);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (54, 3);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (54, 11);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (55, 2);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (55, 3);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (55, 7);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (55, 5);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (55, 4);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (56, 2);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (56, 3);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (56, 11);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (56, 15);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (57, 2);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (57, 3);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (57, 11);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (58, 2);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (58, 3);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (58, 11);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (58, 15);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (58, 8);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (59, 2);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (59, 3);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (59, 12);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (60, 2);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (60, 3);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (60, 11);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (61, 19);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (61, 3);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (61, 6);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (61, 5);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (62, 19);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (62, 3);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (63, 19);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (63, 3);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (63, 13);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (63, 4);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (64, 19);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (64, 3);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (64, 6);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (64, 8);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (65, 19);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (65, 3);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (66, 19);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (66, 3);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (67, 19);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (67, 3);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (68, 19);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (68, 3);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (68, 6);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (68, 4);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (69, 19);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (69, 3);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (69, 6);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (69, 7);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (69, 5);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (70, 19);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (70, 3);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (70, 8);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (71, 19);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (71, 3);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (72, 19);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (72, 3);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (73, 19);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (73, 3);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (74, 19);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (74, 3);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (74, 13);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (75, 19);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (75, 3);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (75, 6);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (76, 19);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (76, 3);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (76, 4);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (77, 19);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (77, 3);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (77, 5);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (78, 19);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (78, 3);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (79, 19);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (79, 3);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (79, 7);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (80, 19);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (80, 3);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (81, 19);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (81, 3);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (81, 12);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (82, 19);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (82, 3);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (83, 19);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (83, 3);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (83, 7);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (84, 19);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (84, 3);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (84, 7);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (85, 19);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (85, 3);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (85, 6);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (85, 5);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (85, 4);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (86, 19);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (86, 3);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (87, 19);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (87, 3);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (87, 7);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (88, 19);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (88, 3);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (88, 6);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (89, 19);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (89, 3);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (90, 19);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (90, 3);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (90, 6);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (91, 20);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (91, 3);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (91, 10);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (91, 5);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (92, 20);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (92, 3);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (93, 20);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (93, 3);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (93, 14);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (93, 4);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (94, 20);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (94, 3);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (94, 14);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (95, 20);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (95, 3);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (96, 20);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (96, 3);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (96, 8);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (96, 10);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (97, 20);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (97, 3);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (98, 20);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (98, 3);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (98, 14);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (98, 4);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (99, 20);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (99, 3);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (99, 10);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (99, 5);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (100, 20);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (100, 3);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (101, 20);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (101, 3);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (102, 20);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (102, 3);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (103, 20);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (103, 3);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (104, 20);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (104, 3);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (104, 10);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (105, 20);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (105, 3);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (105, 8);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (106, 20);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (106, 3);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (106, 4);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (107, 20);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (107, 3);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (107, 10);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (107, 5);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (108, 20);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (108, 3);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (108, 15);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (109, 20);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (109, 3);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (109, 6);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (110, 20);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (110, 3);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (110, 14);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (111, 20);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (111, 3);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (112, 20);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (112, 3);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (112, 14);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (113, 20);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (113, 3);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (113, 8);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (114, 20);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (114, 3);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (114, 10);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (115, 20);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (115, 3);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (115, 5);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (115, 4);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (116, 20);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (116, 3);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (116, 8);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (117, 20);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (117, 3);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (117, 14);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (118, 20);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (118, 3);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (118, 10);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (119, 20);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (119, 3);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (119, 8);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (120, 20);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (120, 3);
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES (120, 8);

-- Product images

INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (1, 'images/products/catalog-001.jpg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (1, 'images/products/catalog-121.jpg', 2, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (1, 'images/products/catalog-061.jpg', 3, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (1, 'images/products/catalog-181.jpg', 4, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (2, 'images/products/catalog-002.jpg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (2, 'images/products/catalog-122.jpg', 2, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (2, 'images/products/catalog-062.jpg', 3, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (2, 'images/products/catalog-182.jpg', 4, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (3, 'images/products/catalog-003.jpg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (3, 'images/products/catalog-123.jpg', 2, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (3, 'images/products/catalog-063.jpg', 3, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (3, 'images/products/catalog-183.jpg', 4, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (4, 'images/products/catalog-004.jpg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (4, 'images/products/catalog-124.jpg', 2, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (4, 'images/products/catalog-064.jpg', 3, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (4, 'images/products/catalog-184.jpg', 4, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (5, 'images/products/catalog-005.jpg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (5, 'images/products/catalog-125.jpg', 2, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (5, 'images/products/catalog-065.jpg', 3, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (5, 'images/products/catalog-185.jpg', 4, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (6, 'images/products/catalog-006.jpg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (6, 'images/products/catalog-126.jpg', 2, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (6, 'images/products/catalog-066.jpg', 3, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (6, 'images/products/catalog-186.jpg', 4, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (7, 'images/products/catalog-007.jpg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (7, 'images/products/catalog-127.jpg', 2, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (7, 'images/products/catalog-067.jpg', 3, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (7, 'images/products/catalog-187.jpg', 4, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (8, 'images/products/catalog-008.jpg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (8, 'images/products/catalog-128.jpg', 2, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (8, 'images/products/catalog-068.jpg', 3, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (8, 'images/products/catalog-188.jpg', 4, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (9, 'images/products/catalog-009.jpg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (9, 'images/products/catalog-129.jpg', 2, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (9, 'images/products/catalog-069.jpg', 3, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (9, 'images/products/catalog-189.jpg', 4, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (10, 'images/products/catalog-010.jpg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (10, 'images/products/catalog-130.jpg', 2, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (10, 'images/products/catalog-070.jpg', 3, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (10, 'images/products/catalog-190.jpg', 4, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (11, 'images/products/catalog-011.jpg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (11, 'images/products/catalog-131.jpg', 2, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (11, 'images/products/catalog-071.jpg', 3, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (11, 'images/products/catalog-191.jpg', 4, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (12, 'images/products/catalog-012.jpg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (12, 'images/products/catalog-132.jpg', 2, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (12, 'images/products/catalog-072.jpg', 3, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (12, 'images/products/catalog-192.jpg', 4, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (13, 'images/products/catalog-013.jpg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (13, 'images/products/catalog-133.jpg', 2, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (13, 'images/products/catalog-073.jpg', 3, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (13, 'images/products/catalog-193.jpg', 4, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (14, 'images/products/catalog-014.jpg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (14, 'images/products/catalog-134.jpg', 2, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (14, 'images/products/catalog-074.jpg', 3, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (14, 'images/products/catalog-194.jpg', 4, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (15, 'images/products/catalog-015.jpg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (15, 'images/products/catalog-135.jpg', 2, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (15, 'images/products/catalog-075.jpg', 3, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (15, 'images/products/catalog-195.jpg', 4, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (16, 'images/products/catalog-016.jpg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (16, 'images/products/catalog-136.jpg', 2, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (16, 'images/products/catalog-076.jpg', 3, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (16, 'images/products/catalog-196.jpg', 4, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (17, 'images/products/catalog-017.jpg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (17, 'images/products/catalog-137.jpg', 2, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (17, 'images/products/catalog-077.jpg', 3, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (17, 'images/products/catalog-197.jpg', 4, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (18, 'images/products/catalog-018.jpg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (18, 'images/products/catalog-138.jpg', 2, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (18, 'images/products/catalog-078.jpg', 3, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (18, 'images/products/catalog-198.jpg', 4, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (19, 'images/products/catalog-019.jpg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (19, 'images/products/catalog-139.jpg', 2, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (19, 'images/products/catalog-079.jpg', 3, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (19, 'images/products/catalog-199.jpg', 4, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (20, 'images/products/catalog-020.jpg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (20, 'images/products/catalog-140.jpg', 2, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (20, 'images/products/catalog-080.jpg', 3, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (20, 'images/products/catalog-200.jpg', 4, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (21, 'images/products/catalog-021.jpg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (21, 'images/products/catalog-141.jpg', 2, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (21, 'images/products/catalog-081.jpg', 3, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (21, 'images/products/catalog-201.jpg', 4, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (22, 'images/products/catalog-022.jpg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (22, 'images/products/catalog-142.jpg', 2, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (22, 'images/products/catalog-082.jpg', 3, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (22, 'images/products/catalog-202.jpg', 4, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (23, 'images/products/catalog-023.jpg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (23, 'images/products/catalog-143.jpg', 2, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (23, 'images/products/catalog-083.jpg', 3, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (23, 'images/products/catalog-203.jpg', 4, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (24, 'images/products/catalog-024.jpg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (24, 'images/products/catalog-144.jpg', 2, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (24, 'images/products/catalog-084.jpg', 3, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (24, 'images/products/catalog-204.jpg', 4, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (25, 'images/products/catalog-025.jpg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (25, 'images/products/catalog-145.jpg', 2, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (25, 'images/products/catalog-085.jpg', 3, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (25, 'images/products/catalog-205.jpg', 4, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (26, 'images/products/catalog-026.jpg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (26, 'images/products/catalog-146.jpg', 2, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (26, 'images/products/catalog-086.jpg', 3, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (26, 'images/products/catalog-206.jpg', 4, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (27, 'images/products/catalog-027.jpg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (27, 'images/products/catalog-147.jpg', 2, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (27, 'images/products/catalog-087.jpg', 3, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (27, 'images/products/catalog-207.jpg', 4, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (28, 'images/products/catalog-028.jpg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (28, 'images/products/catalog-148.jpg', 2, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (28, 'images/products/catalog-088.jpg', 3, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (28, 'images/products/catalog-208.jpg', 4, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (29, 'images/products/catalog-029.jpg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (29, 'images/products/catalog-149.jpg', 2, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (29, 'images/products/catalog-089.jpg', 3, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (29, 'images/products/catalog-209.jpg', 4, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (30, 'images/products/catalog-030.jpg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (30, 'images/products/catalog-150.jpg', 2, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (30, 'images/products/catalog-090.jpg', 3, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (30, 'images/products/catalog-210.jpg', 4, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (31, 'images/products/catalog-031.jpg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (31, 'images/products/catalog-151.jpg', 2, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (31, 'images/products/catalog-091.jpg', 3, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (31, 'images/products/catalog-211.jpg', 4, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (32, 'images/products/catalog-032.jpg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (32, 'images/products/catalog-152.jpg', 2, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (32, 'images/products/catalog-092.jpg', 3, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (32, 'images/products/catalog-212.jpg', 4, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (33, 'images/products/catalog-033.jpg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (33, 'images/products/catalog-153.jpg', 2, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (33, 'images/products/catalog-093.jpg', 3, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (33, 'images/products/catalog-213.jpg', 4, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (34, 'images/products/catalog-034.jpg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (34, 'images/products/catalog-154.jpg', 2, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (34, 'images/products/catalog-094.jpg', 3, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (34, 'images/products/catalog-214.jpg', 4, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (35, 'images/products/catalog-035.jpg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (35, 'images/products/catalog-155.jpg', 2, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (35, 'images/products/catalog-095.jpg', 3, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (35, 'images/products/catalog-215.jpg', 4, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (36, 'images/products/catalog-036.jpg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (36, 'images/products/catalog-156.jpg', 2, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (36, 'images/products/catalog-096.jpg', 3, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (36, 'images/products/catalog-216.jpg', 4, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (37, 'images/products/catalog-037.jpg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (37, 'images/products/catalog-157.jpg', 2, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (37, 'images/products/catalog-097.jpg', 3, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (37, 'images/products/catalog-217.jpg', 4, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (38, 'images/products/catalog-038.jpg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (38, 'images/products/catalog-158.jpg', 2, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (38, 'images/products/catalog-098.jpg', 3, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (38, 'images/products/catalog-218.jpg', 4, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (39, 'images/products/catalog-039.jpg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (39, 'images/products/catalog-159.jpg', 2, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (39, 'images/products/catalog-099.jpg', 3, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (39, 'images/products/catalog-219.jpg', 4, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (40, 'images/products/catalog-040.jpg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (40, 'images/products/catalog-160.jpg', 2, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (40, 'images/products/catalog-100.jpg', 3, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (40, 'images/products/catalog-220.jpg', 4, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (41, 'images/products/catalog-041.jpg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (41, 'images/products/catalog-161.jpg', 2, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (41, 'images/products/catalog-101.jpg', 3, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (41, 'images/products/catalog-221.jpg', 4, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (42, 'images/products/catalog-042.jpg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (42, 'images/products/catalog-162.jpg', 2, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (42, 'images/products/catalog-102.jpg', 3, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (42, 'images/products/catalog-222.jpg', 4, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (43, 'images/products/catalog-043.jpg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (43, 'images/products/catalog-163.jpg', 2, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (43, 'images/products/catalog-103.jpg', 3, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (43, 'images/products/catalog-223.jpg', 4, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (44, 'images/products/catalog-044.jpg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (44, 'images/products/catalog-164.jpg', 2, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (44, 'images/products/catalog-104.jpg', 3, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (44, 'images/products/catalog-224.jpg', 4, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (45, 'images/products/catalog-045.jpg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (45, 'images/products/catalog-165.jpg', 2, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (45, 'images/products/catalog-105.jpg', 3, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (45, 'images/products/catalog-225.jpg', 4, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (46, 'images/products/catalog-046.jpg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (46, 'images/products/catalog-166.jpg', 2, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (46, 'images/products/catalog-106.jpg', 3, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (46, 'images/products/catalog-226.jpg', 4, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (47, 'images/products/catalog-047.jpg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (47, 'images/products/catalog-167.jpg', 2, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (47, 'images/products/catalog-107.jpg', 3, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (47, 'images/products/catalog-227.jpg', 4, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (48, 'images/products/catalog-048.jpg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (48, 'images/products/catalog-168.jpg', 2, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (48, 'images/products/catalog-108.jpg', 3, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (48, 'images/products/catalog-228.jpg', 4, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (49, 'images/products/catalog-049.jpg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (49, 'images/products/catalog-169.jpg', 2, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (49, 'images/products/catalog-109.jpg', 3, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (49, 'images/products/catalog-229.jpg', 4, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (50, 'images/products/catalog-050.jpg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (50, 'images/products/catalog-170.jpg', 2, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (50, 'images/products/catalog-110.jpg', 3, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (50, 'images/products/catalog-230.jpg', 4, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (51, 'images/products/catalog-051.jpg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (51, 'images/products/catalog-171.jpg', 2, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (51, 'images/products/catalog-111.jpg', 3, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (51, 'images/products/catalog-231.jpg', 4, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (52, 'images/products/catalog-052.jpg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (52, 'images/products/catalog-172.jpg', 2, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (52, 'images/products/catalog-112.jpg', 3, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (52, 'images/products/catalog-232.jpg', 4, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (53, 'images/products/catalog-053.jpg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (53, 'images/products/catalog-173.jpg', 2, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (53, 'images/products/catalog-113.jpg', 3, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (53, 'images/products/catalog-233.jpg', 4, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (54, 'images/products/catalog-054.jpg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (54, 'images/products/catalog-174.jpg', 2, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (54, 'images/products/catalog-114.jpg', 3, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (54, 'images/products/catalog-234.jpg', 4, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (55, 'images/products/catalog-055.jpg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (55, 'images/products/catalog-175.jpg', 2, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (55, 'images/products/catalog-115.jpg', 3, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (55, 'images/products/catalog-235.jpg', 4, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (56, 'images/products/catalog-056.jpg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (56, 'images/products/catalog-176.jpg', 2, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (56, 'images/products/catalog-116.jpg', 3, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (56, 'images/products/catalog-236.jpg', 4, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (57, 'images/products/catalog-057.jpg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (57, 'images/products/catalog-177.jpg', 2, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (57, 'images/products/catalog-117.jpg', 3, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (57, 'images/products/catalog-237.jpg', 4, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (58, 'images/products/catalog-058.jpg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (58, 'images/products/catalog-178.jpg', 2, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (58, 'images/products/catalog-118.jpg', 3, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (58, 'images/products/catalog-238.jpg', 4, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (59, 'images/products/catalog-059.jpg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (59, 'images/products/catalog-179.jpg', 2, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (59, 'images/products/catalog-119.jpg', 3, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (59, 'images/products/catalog-239.jpg', 4, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (60, 'images/products/catalog-060.jpg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (60, 'images/products/catalog-180.jpg', 2, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (60, 'images/products/catalog-120.jpg', 3, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (60, 'images/products/catalog-240.jpg', 4, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (61, 'images/products/catalog-061.jpg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (61, 'images/products/catalog-181.jpg', 2, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (61, 'images/products/catalog-121.jpg', 3, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (61, 'images/products/catalog-241.jpg', 4, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (62, 'images/products/catalog-062.jpg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (62, 'images/products/catalog-182.jpg', 2, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (62, 'images/products/catalog-122.jpg', 3, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (62, 'images/products/catalog-242.jpg', 4, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (63, 'images/products/catalog-063.jpg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (63, 'images/products/catalog-183.jpg', 2, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (63, 'images/products/catalog-123.jpg', 3, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (63, 'images/products/catalog-243.jpg', 4, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (64, 'images/products/catalog-064.jpg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (64, 'images/products/catalog-184.jpg', 2, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (64, 'images/products/catalog-124.jpg', 3, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (64, 'images/products/catalog-244.jpg', 4, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (65, 'images/products/catalog-065.jpg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (65, 'images/products/catalog-185.jpg', 2, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (65, 'images/products/catalog-125.jpg', 3, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (65, 'images/products/catalog-245.jpg', 4, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (66, 'images/products/catalog-066.jpg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (66, 'images/products/catalog-186.jpg', 2, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (66, 'images/products/catalog-126.jpg', 3, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (66, 'images/products/catalog-246.jpg', 4, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (67, 'images/products/catalog-067.jpg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (67, 'images/products/catalog-187.jpg', 2, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (67, 'images/products/catalog-127.jpg', 3, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (67, 'images/products/catalog-247.jpg', 4, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (68, 'images/products/catalog-068.jpg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (68, 'images/products/catalog-188.jpg', 2, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (68, 'images/products/catalog-128.jpg', 3, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (68, 'images/products/catalog-248.jpg', 4, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (69, 'images/products/catalog-069.jpg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (69, 'images/products/catalog-189.jpg', 2, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (69, 'images/products/catalog-129.jpg', 3, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (69, 'images/products/catalog-249.jpg', 4, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (70, 'images/products/catalog-070.jpg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (70, 'images/products/catalog-190.jpg', 2, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (70, 'images/products/catalog-130.jpg', 3, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (70, 'images/products/catalog-250.jpg', 4, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (71, 'images/products/catalog-071.jpg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (71, 'images/products/catalog-191.jpg', 2, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (71, 'images/products/catalog-131.jpg', 3, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (71, 'images/products/catalog-251.jpg', 4, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (72, 'images/products/catalog-072.jpg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (72, 'images/products/catalog-192.jpg', 2, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (72, 'images/products/catalog-132.jpg', 3, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (72, 'images/products/catalog-252.jpg', 4, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (73, 'images/products/catalog-073.jpg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (73, 'images/products/catalog-193.jpg', 2, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (73, 'images/products/catalog-133.jpg', 3, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (73, 'images/products/catalog-253.jpg', 4, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (74, 'images/products/catalog-074.jpg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (74, 'images/products/catalog-194.jpg', 2, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (74, 'images/products/catalog-134.jpg', 3, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (74, 'images/products/catalog-254.jpg', 4, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (75, 'images/products/catalog-075.jpg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (75, 'images/products/catalog-195.jpg', 2, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (75, 'images/products/catalog-135.jpg', 3, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (75, 'images/products/catalog-255.jpg', 4, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (76, 'images/products/catalog-076.jpg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (76, 'images/products/catalog-196.jpg', 2, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (76, 'images/products/catalog-136.jpg', 3, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (76, 'images/products/catalog-256.jpg', 4, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (77, 'images/products/catalog-077.jpg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (77, 'images/products/catalog-197.jpg', 2, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (77, 'images/products/catalog-137.jpg', 3, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (77, 'images/products/catalog-257.jpg', 4, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (78, 'images/products/catalog-078.jpg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (78, 'images/products/catalog-198.jpg', 2, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (78, 'images/products/catalog-138.jpg', 3, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (78, 'images/products/catalog-258.jpg', 4, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (79, 'images/products/catalog-079.jpg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (79, 'images/products/catalog-199.jpg', 2, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (79, 'images/products/catalog-139.jpg', 3, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (79, 'images/products/catalog-259.jpg', 4, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (80, 'images/products/catalog-080.jpg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (80, 'images/products/catalog-200.jpg', 2, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (80, 'images/products/catalog-140.jpg', 3, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (80, 'images/products/catalog-260.jpg', 4, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (81, 'images/products/catalog-081.jpg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (81, 'images/products/catalog-201.jpg', 2, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (81, 'images/products/catalog-141.jpg', 3, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (81, 'images/products/catalog-261.jpg', 4, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (82, 'images/products/catalog-082.jpg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (82, 'images/products/catalog-202.jpg', 2, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (82, 'images/products/catalog-142.jpg', 3, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (82, 'images/products/catalog-262.jpg', 4, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (83, 'images/products/catalog-083.jpg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (83, 'images/products/catalog-203.jpg', 2, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (83, 'images/products/catalog-143.jpg', 3, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (83, 'images/products/catalog-263.jpg', 4, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (84, 'images/products/catalog-084.jpg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (84, 'images/products/catalog-204.jpg', 2, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (84, 'images/products/catalog-144.jpg', 3, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (84, 'images/products/catalog-264.jpg', 4, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (85, 'images/products/catalog-085.jpg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (85, 'images/products/catalog-205.jpg', 2, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (85, 'images/products/catalog-145.jpg', 3, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (85, 'images/products/catalog-265.jpg', 4, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (86, 'images/products/catalog-086.jpg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (86, 'images/products/catalog-206.jpg', 2, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (86, 'images/products/catalog-146.jpg', 3, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (86, 'images/products/catalog-266.jpg', 4, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (87, 'images/products/catalog-087.jpg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (87, 'images/products/catalog-207.jpg', 2, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (87, 'images/products/catalog-147.jpg', 3, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (87, 'images/products/catalog-267.jpg', 4, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (88, 'images/products/catalog-088.jpg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (88, 'images/products/catalog-208.jpg', 2, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (88, 'images/products/catalog-148.jpg', 3, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (88, 'images/products/catalog-268.jpg', 4, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (89, 'images/products/catalog-089.jpg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (89, 'images/products/catalog-209.jpg', 2, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (89, 'images/products/catalog-149.jpg', 3, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (89, 'images/products/catalog-269.jpg', 4, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (90, 'images/products/catalog-090.jpg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (90, 'images/products/catalog-210.jpg', 2, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (90, 'images/products/catalog-150.jpg', 3, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (90, 'images/products/catalog-270.jpg', 4, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (91, 'images/products/catalog-091.jpg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (91, 'images/products/catalog-211.jpg', 2, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (91, 'images/products/catalog-151.jpg', 3, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (91, 'images/products/catalog-271.jpg', 4, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (92, 'images/products/catalog-092.jpg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (92, 'images/products/catalog-212.jpg', 2, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (92, 'images/products/catalog-152.jpg', 3, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (92, 'images/products/catalog-272.jpg', 4, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (93, 'images/products/catalog-093.jpg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (93, 'images/products/catalog-213.jpg', 2, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (93, 'images/products/catalog-153.jpg', 3, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (93, 'images/products/catalog-273.jpg', 4, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (94, 'images/products/catalog-094.jpg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (94, 'images/products/catalog-214.jpg', 2, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (94, 'images/products/catalog-154.jpg', 3, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (94, 'images/products/catalog-274.jpg', 4, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (95, 'images/products/catalog-095.jpg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (95, 'images/products/catalog-215.jpg', 2, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (95, 'images/products/catalog-155.jpg', 3, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (95, 'images/products/catalog-275.jpg', 4, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (96, 'images/products/catalog-096.jpg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (96, 'images/products/catalog-216.jpg', 2, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (96, 'images/products/catalog-156.jpg', 3, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (96, 'images/products/catalog-276.jpg', 4, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (97, 'images/products/catalog-097.jpg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (97, 'images/products/catalog-217.jpg', 2, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (97, 'images/products/catalog-157.jpg', 3, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (97, 'images/products/catalog-277.jpg', 4, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (98, 'images/products/catalog-098.jpg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (98, 'images/products/catalog-218.jpg', 2, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (98, 'images/products/catalog-158.jpg', 3, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (98, 'images/products/catalog-278.jpg', 4, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (99, 'images/products/catalog-099.jpg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (99, 'images/products/catalog-219.jpg', 2, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (99, 'images/products/catalog-159.jpg', 3, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (99, 'images/products/catalog-279.jpg', 4, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (100, 'images/products/catalog-100.jpg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (100, 'images/products/catalog-220.jpg', 2, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (100, 'images/products/catalog-160.jpg', 3, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (100, 'images/products/catalog-280.jpg', 4, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (101, 'images/products/catalog-101.jpg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (101, 'images/products/catalog-221.jpg', 2, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (101, 'images/products/catalog-161.jpg', 3, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (101, 'images/products/catalog-281.jpg', 4, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (102, 'images/products/catalog-102.jpg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (102, 'images/products/catalog-222.jpg', 2, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (102, 'images/products/catalog-162.jpg', 3, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (102, 'images/products/catalog-282.jpg', 4, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (103, 'images/products/catalog-103.jpg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (103, 'images/products/catalog-223.jpg', 2, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (103, 'images/products/catalog-163.jpg', 3, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (103, 'images/products/catalog-283.jpg', 4, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (104, 'images/products/catalog-104.jpg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (104, 'images/products/catalog-224.jpg', 2, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (104, 'images/products/catalog-164.jpg', 3, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (104, 'images/products/catalog-284.jpg', 4, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (105, 'images/products/catalog-105.jpg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (105, 'images/products/catalog-225.jpg', 2, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (105, 'images/products/catalog-165.jpg', 3, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (105, 'images/products/catalog-285.jpg', 4, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (106, 'images/products/catalog-106.jpg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (106, 'images/products/catalog-226.jpg', 2, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (106, 'images/products/catalog-166.jpg', 3, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (106, 'images/products/catalog-286.jpg', 4, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (107, 'images/products/catalog-107.jpg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (107, 'images/products/catalog-227.jpg', 2, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (107, 'images/products/catalog-167.jpg', 3, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (107, 'images/products/catalog-287.jpg', 4, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (108, 'images/products/catalog-108.jpg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (108, 'images/products/catalog-228.jpg', 2, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (108, 'images/products/catalog-168.jpg', 3, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (108, 'images/products/catalog-288.jpg', 4, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (109, 'images/products/catalog-109.jpg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (109, 'images/products/catalog-229.jpg', 2, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (109, 'images/products/catalog-169.jpg', 3, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (109, 'images/products/catalog-289.jpg', 4, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (110, 'images/products/catalog-110.jpg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (110, 'images/products/catalog-230.jpg', 2, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (110, 'images/products/catalog-170.jpg', 3, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (110, 'images/products/catalog-290.jpg', 4, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (111, 'images/products/catalog-111.jpg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (111, 'images/products/catalog-231.jpg', 2, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (111, 'images/products/catalog-171.jpg', 3, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (111, 'images/products/catalog-291.jpg', 4, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (112, 'images/products/catalog-112.jpg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (112, 'images/products/catalog-232.jpg', 2, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (112, 'images/products/catalog-172.jpg', 3, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (112, 'images/products/catalog-292.jpg', 4, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (113, 'images/products/catalog-113.jpg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (113, 'images/products/catalog-233.jpg', 2, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (113, 'images/products/catalog-173.jpg', 3, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (113, 'images/products/catalog-293.jpg', 4, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (114, 'images/products/catalog-114.jpg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (114, 'images/products/catalog-234.jpg', 2, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (114, 'images/products/catalog-174.jpg', 3, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (114, 'images/products/catalog-294.jpg', 4, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (115, 'images/products/catalog-115.jpg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (115, 'images/products/catalog-235.jpg', 2, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (115, 'images/products/catalog-175.jpg', 3, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (115, 'images/products/catalog-295.jpg', 4, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (116, 'images/products/catalog-116.jpg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (116, 'images/products/catalog-236.jpg', 2, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (116, 'images/products/catalog-176.jpg', 3, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (116, 'images/products/catalog-296.jpg', 4, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (117, 'images/products/catalog-117.jpg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (117, 'images/products/catalog-237.jpg', 2, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (117, 'images/products/catalog-177.jpg', 3, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (117, 'images/products/catalog-297.jpg', 4, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (118, 'images/products/catalog-118.jpg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (118, 'images/products/catalog-238.jpg', 2, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (118, 'images/products/catalog-178.jpg', 3, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (118, 'images/products/catalog-298.jpg', 4, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (119, 'images/products/catalog-119.jpg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (119, 'images/products/catalog-239.jpg', 2, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (119, 'images/products/catalog-179.jpg', 3, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (119, 'images/products/catalog-299.jpg', 4, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (120, 'images/products/catalog-120.jpg', 1, 1);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (120, 'images/products/catalog-240.jpg', 2, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (120, 'images/products/catalog-180.jpg', 3, 0);
INSERT INTO `product_images` (`product_id`, `image`, `sort_order`, `is_primary`) VALUES (120, 'images/products/catalog-300.jpg', 4, 0);
