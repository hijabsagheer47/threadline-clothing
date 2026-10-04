-- ============================================================================
-- FASHLAB STUDIO — VISITOR ANALYTICS (page_views)
-- Lightweight first-party page tracking for the admin Analytics dashboard.
-- Privacy-friendly: hashed session id, path only (no query strings),
-- no raw user agents, external referrers only.
-- Idempotent: safe to run more than once.
-- ============================================================================

CREATE TABLE IF NOT EXISTS `page_views` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `session_hash` CHAR(64) NOT NULL,
  `path` VARCHAR(500) NOT NULL,
  `page_type` VARCHAR(30) NOT NULL DEFAULT 'other',
  `referrer` VARCHAR(500) NULL DEFAULT NULL,
  `device` ENUM('desktop','tablet','mobile') NOT NULL DEFAULT 'desktop',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_pv_created` (`created_at`),
  KEY `idx_pv_session` (`session_hash`, `created_at`),
  KEY `idx_pv_path` (`path`(120)),
  KEY `idx_pv_device` (`device`, `created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
