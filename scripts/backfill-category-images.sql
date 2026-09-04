-- ============================================================================
-- TayyabaCollective — Category cover backfill for EXISTING databases
-- ----------------------------------------------------------------------------
-- Databases created before the category-image fix left most seeded categories
-- without an image (blank collection cards on the homepage/collections pages).
--
-- This script sets a real product photo as the cover for every seeded category
-- that does NOT already have an admin-uploaded image. It only touches rows that
-- have no image, a NULL image, or the old broken 'images/categories/...' value,
-- so any cover you uploaded yourself in the Admin Panel is never overwritten.
--
-- Run it once against your live database, e.g.:
--   mysql -u USERNAME -p DBNAME < scripts/backfill-category-images.sql
--
-- Fresh installs do NOT need this — database.sql already ships these covers.
-- ============================================================================

UPDATE categories SET image = 'images/products/catalog-001.jpg' WHERE slug = 'stitched'        AND (image IS NULL OR image = '' OR image LIKE 'images/categories/%');
UPDATE categories SET image = 'images/products/catalog-031.jpg' WHERE slug = 'unstitched'      AND (image IS NULL OR image = '' OR image LIKE 'images/categories/%');
UPDATE categories SET image = 'images/products/catalog-010.jpg' WHERE slug = 'new-arrivals'    AND (image IS NULL OR image = '' OR image LIKE 'images/categories/%');
UPDATE categories SET image = 'images/products/catalog-038.jpg' WHERE slug = 'best-sellers'    AND (image IS NULL OR image = '' OR image LIKE 'images/categories/%');
UPDATE categories SET image = 'images/products/catalog-017.jpg' WHERE slug = 'sale'            AND (image IS NULL OR image = '' OR image LIKE 'images/categories/%');
UPDATE categories SET image = 'images/products/catalog-064.jpg' WHERE slug = 'formal-wear'     AND (image IS NULL OR image = '' OR image LIKE 'images/categories/%');
UPDATE categories SET image = 'images/products/catalog-016.jpg' WHERE slug = 'casual-wear'     AND (image IS NULL OR image = '' OR image LIKE 'images/categories/%');
UPDATE categories SET image = 'images/products/catalog-026.jpg' WHERE slug = 'luxury-collection' AND (image IS NULL OR image = '' OR image LIKE 'images/categories/%');
UPDATE categories SET image = 'images/products/catalog-022.jpg' WHERE slug = 'festive-collection' AND (image IS NULL OR image = '' OR image LIKE 'images/categories/%');
UPDATE categories SET image = 'images/products/catalog-021.jpg' WHERE slug = 'lawn-collection' AND (image IS NULL OR image = '' OR image LIKE 'images/categories/%');
UPDATE categories SET image = 'images/products/catalog-009.jpg' WHERE slug = 'cotton-collection' AND (image IS NULL OR image = '' OR image LIKE 'images/categories/%');
UPDATE categories SET image = 'images/products/catalog-074.jpg' WHERE slug = 'linen-collection' AND (image IS NULL OR image = '' OR image LIKE 'images/categories/%');
UPDATE categories SET image = 'images/products/catalog-011.jpg' WHERE slug = 'embroidered'      AND (image IS NULL OR image = '' OR image LIKE 'images/categories/%');
UPDATE categories SET image = 'images/products/catalog-029.jpg' WHERE slug = 'printed'          AND (image IS NULL OR image = '' OR image LIKE 'images/categories/%');
UPDATE categories SET image = 'images/products/catalog-003.jpg' WHERE slug = 'pret-wear'        AND (image IS NULL OR image = '' OR image LIKE 'images/categories/%');
UPDATE categories SET image = 'images/products/catalog-047.jpg' WHERE slug = 'three-piece'      AND (image IS NULL OR image = '' OR image LIKE 'images/categories/%');
UPDATE categories SET image = 'images/products/catalog-066.jpg' WHERE slug = 'western-wear'     AND (image IS NULL OR image = '' OR image LIKE 'images/categories/%');
UPDATE categories SET image = 'images/products/catalog-091.jpg' WHERE slug = 'eastern-wear'     AND (image IS NULL OR image = '' OR image LIKE 'images/categories/%');

-- 'Eid Collection' and 'Two Piece' intentionally keep no cover: they have no
-- products yet and show the branded placeholder until collections are added.
