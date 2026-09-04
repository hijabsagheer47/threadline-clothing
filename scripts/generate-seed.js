#!/usr/bin/env node
/* ============================================================
   TAYYABACOLLECTIVE — SEED GENERATOR
   Migrates the 120 original static-catalogue products
   (30 Stitched, 30 Unstitched, 30 Western, 30 Eastern) into
   SQL INSERT statements and appends them to database.sql.

   Run:  node scripts/generate-seed.js
   ============================================================ */
'use strict';

const fs = require('fs');
const path = require('path');

const CATEGORY_IDS = { Stitched: 1, Unstitched: 2, 'Western Wear': 19, 'Eastern Wear': 20 };

const PRODUCT_NAMES = {
  Stitched: [
    'Areeba Floral Lawn Set', 'Nisha Printed Lawn Kurta', 'Hiba Cotton Shirt Set',
    'Sana Formal Linen Ensemble', 'Alina Pastel Chiffon Three Piece', 'Noor Festive Cotton Suit',
    'Zareen Embroidered Suit', 'Mira Khaddar Suit', 'Rida Cotton Kurta Set',
    'Maham Printed Lawn Suit', 'Saira Chikankari Set', 'Farah Minimal Kurta',
    'Tania Soft Silk Set', 'Hira Printed Cotton Kurta', 'Kiran Bordered Lawn Set',
    'Ansa Casual Stitched Suit', 'Hania Everyday Lawn Set', 'Mila Festive Cotton Set',
    'Aiza Soft Drape Suit', 'Yumna Embellished Kurta', 'Ayesha Classic Lawn Suit',
    'Rimsha Cotton Festive Set', 'Nadia Printed Shirt Set', 'Sana Grace Kurta Set',
    'Sahar Floral Chiffon Set', 'Maryam Luxe Lawn Set', 'Emaan Everyday Stitched Set',
    'Zoya Flow Kurta Set', 'Mahira Soft Printed Set', 'Samiya Classic Shirt Suit'
  ],
  Unstitched: [
    'Aisha Soft Cotton Lawn', 'Meher Printed Chiffon Set', 'Fizza Summer Floral Unstitched',
    'Zara Premium Lawn 3 Piece', 'Mariam Embroidered Unstitched', 'Sheza Classic Karandi Set',
    'Sahil Printed Lawn', 'Sana Karandi Unstitched Set', 'Maham Pastel Lawn Set',
    'Rida Floral Chiffon Set', 'Areeba Cotton Printed Set', 'Noor Multicolor Lawn Set',
    'Hania Garden Print Set', 'Maryam Premium Karandi', 'Ayesha Printed Dupatta Set',
    'Fariha Soft Chiffon Set', 'Hira Classic 3 Piece', 'Nadia Printed Lawn',
    'Sahar Tie-Dye Lawn Set', 'Areej Minimal Lawn', 'Hina Cotton Festive Set',
    'Sana Bloom Lawn Set', 'Mira Textured Lawn', 'Ansa Stripe Lawn Set',
    'Zainab Soft Floral Set', 'Aiza Printed Lawn Duo', 'Rimsha Daily Lawn Set',
    'Faryal Luxe Printed Lawn', 'Maryam Cotton Bloom Set', 'Kiran Modern Lawn Pack'
  ],
  'Western Wear': [
    'Noor Tailored Blazer Dress', 'Elan Wide-Leg Trouser Set', 'Rida Linen Co-ord Set',
    'Zara Structured Satin Dress', 'Hania Pleated Midi Dress', 'Iman Oversized Button Shirt',
    'Ayesha Denim Co-ord', 'Nadia Structured Mini Dress', 'Sana Relaxed Blazer Set',
    'Fahra Satin Slip Dress', 'Mia Wide-Leg Trousers', 'Ira Cashmere Knit Set',
    'Anaya Pleated Skirt Set', 'Emaan White Linen Shirt', 'Zoya Tailored Pant Suit',
    'Maryam Knit Polo Dress', 'Hira Layered Co-ord', 'Sofia Pleated Jumpsuit',
    'Rania Smart Casual Set', 'Aisha Monochrome Co-ord', 'Mahir Cotton Shirt Dress',
    'Nisa Belted Midi Dress', 'Farah Relaxed Twill Suit', 'Rimsha Lounge Dress',
    'Areeba Longline Blazer', 'Sahar Utility Co-ord', 'Hira Soft Knit Dress',
    'Leena Professional Set', 'Aiza Neutral Shirtdress', 'Rida Tailored Skirt Set'
  ],
  'Eastern Wear': [
    'Anaya Bridal Eastern Ensemble', 'Hania Eastern Angrakha', 'Mahnoor Gota Work Kurta',
    'Rania Embroidered Sharara', 'Faryal Net Dupatta Set', 'Aisha Silk Festive Suit',
    'Maham Modern Eastern Set', 'Sadia Embroidered Gown', 'Nisha Festive Kurta Set',
    'Areeba Traditional Chiffon Set', 'Hira Organza Angrakha', 'Maryam Pastel Eastern Set',
    'Alina Gharara Set', 'Rida Festive Kurta Pant', 'Maham Silk Dupatta Set',
    'Zoya Rose Gold Set', 'Hania Bridal Chiffon Set', 'Aisha Printed Eastern Suit',
    'Nadia Formal Eastern Set', 'Mila Embroidered Kurta', 'Sahar Georgette Set',
    'Fiza Pearled Dupatta Set', 'Areej Satin Kurta Set', 'Yumna Chiffon Festive Set',
    'Sana Lace Eastern Set', 'Fariha Silk Gown', 'Emaan Embellished Shalwar',
    'Rimsha Party Eastern Suit', 'Aiza Luxe Eastern Set', 'Hira Velvet Eastern Set'
  ]
};

const ORDER = ['Stitched', 'Unstitched', 'Western Wear', 'Eastern Wear'];
const CODE = { Stitched: 'ST', Unstitched: 'UN', 'Western Wear': 'WS', 'Eastern Wear': 'ES' };
const FABRIC = {
  Stitched: 'Premium lawn & chiffon',
  Unstitched: 'Premium lawn fabric',
  'Western Wear': 'Premium blended fabric',
  'Eastern Wear': 'Premium silk & chiffon'
};
const COLORS = ['Maroon & Gold', 'Ivory', 'Emerald', 'Navy', 'Blush Pink', 'Black & Gold', 'Mustard', 'Dusty Rose', 'Teal', 'Charcoal'];

function esc(value) {
  return String(value).replace(/\\/g, '\\\\').replace(/'/g, "''");
}

function slugify(name) {
  return name.toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '');
}

function extraCategories(name, index, base) {
  const cats = new Set();
  if (base === 'Stitched') cats.add(16); // Pret Wear
  if (/lawn/i.test(name)) cats.add(11);
  if (/cotton/i.test(name)) cats.add(12);
  if (/linen/i.test(name)) cats.add(13);
  if (/embroidered|embellished|gota|pearl|chikankari/i.test(name)) cats.add(14);
  if (/printed|print|tie-dye/i.test(name)) cats.add(15);
  if (/formal|blazer|tailored|structured|professional|office/i.test(name)) cats.add(6);
  if (/casual|everyday|soft|relaxed|lounge|minimal/i.test(name)) cats.add(7);
  if (/luxe|luxury|premium|designer|silk|velvet|satin/i.test(name)) cats.add(8);
  if (/eid/i.test(name)) cats.add(9);
  if (/festive|bridal|party|occasion|celebration/i.test(name)) cats.add(10);
  if (/two piece/i.test(name)) cats.add(17);
  if (/three piece|3 piece/i.test(name)) cats.add(18);
  return [...cats];
}

let productsSql = '';
let linksSql = '';
let imagesSql = '';
let productId = 1;
const bestSellers = [];

for (const category of ORDER) {
  const baseCatId = CATEGORY_IDS[category];
  PRODUCT_NAMES[category].forEach((name, index) => {
    const price = 6200 + ((index * 675) % 8500);
    const hasSale = index % 8 === 0;
    const salePrice = hasSale ? Math.round(price * 0.88) : null;
    const stock = index % 11 === 0 ? 0 : 3 + ((index * 7) % 45);
    const stockStatus = stock === 0 ? 'out_of_stock' : stock < 6 ? 'low_stock' : 'in_stock';
    const featured = index % 9 === 0 ? 1 : 0;
    const sku = `TC-${CODE[category]}-${String(index + 1).padStart(4, '0')}`;
    const slug = slugify(name);
    const fabric = FABRIC[category];
    const color = COLORS[index % COLORS.length];
    const size = category === 'Unstitched' ? 'One Size' : 'S · M · L · XL';
    const productType = category;
    const shortDesc = `A thoughtfully designed ${category.toLowerCase()} piece with refined finishing and an easy, elegant fit.`;
    const description = shortDesc + ' Crafted from carefully selected fabric with attention to detail, this piece is part of the TayyabaCollective collection — designed to make you feel confident, comfortable and beautifully you.';
    const daysAgo = index + 1;

    const photoNumber = ORDER.indexOf(category) * 30 + index + 1;
    const images = [
      `images/products/catalog-${String(photoNumber).padStart(3, '0')}.jpg`,
      `images/products/catalog-${String(photoNumber + 120).padStart(3, '0')}.jpg`,
      `images/products/catalog-${String(photoNumber + 60).padStart(3, '0')}.jpg`,
      `images/products/catalog-${String(photoNumber + 180).padStart(3, '0')}.jpg`
    ];

    productsSql += `INSERT INTO \`products\` (\`category_id\`, \`name\`, \`slug\`, \`sku\`, \`short_description\`, \`description\`, \`price\`, \`sale_price\`, \`cost_price\`, \`stock_quantity\`, \`stock_status\`, \`product_type\`, \`fabric\`, \`color\`, \`size\`, \`featured\`, \`status\`, \`created_at\`) VALUES\n`;
    productsSql += `(${baseCatId}, '${esc(name)}', '${slug}', '${sku}', '${esc(shortDesc)}', '${esc(description)}', ${price}, ${salePrice ?? 'NULL'}, NULL, ${stock}, '${stockStatus}', '${esc(productType)}', '${esc(fabric)}', '${esc(color)}', '${esc(size)}', ${featured}, 1, DATE_SUB(NOW(), INTERVAL ${daysAgo} DAY));\n`;

    // Many-to-many category links
    const catIds = new Set([baseCatId, 3]); // base + New Arrivals
    extraCategories(name, index, category).forEach(c => catIds.add(c));
    if (hasSale) catIds.add(5); // Sale
    if (index === 2 || index === 7 || index === 15 || index === 24) {
      catIds.add(4);
      bestSellers.push(productId);
    }
    for (const cid of catIds) {
      linksSql += `INSERT INTO \`product_categories\` (\`product_id\`, \`category_id\`) VALUES (${productId}, ${cid});\n`;
    }

    // Images
    images.forEach((img, i) => {
      imagesSql += `INSERT INTO \`product_images\` (\`product_id\`, \`image\`, \`sort_order\`, \`is_primary\`) VALUES (${productId}, '${img}', ${i + 1}, ${i === 0 ? 1 : 0});\n`;
    });

    productId++;
  });
}

const output =
  '\n-- ============================================================================\n' +
  '-- MIGRATED PRODUCTS (120 — generated by scripts/generate-seed.js)\n' +
  '-- ============================================================================\n\n' +
  productsSql + '\n' +
  '-- Product <-> category links\n\n' +
  linksSql + '\n' +
  '-- Product images\n\n' +
  imagesSql;

const target = path.join(__dirname, '..', 'database.sql');
let existing = fs.readFileSync(target, 'utf8');

// Idempotency: replace any previously generated block instead of duplicating it.
const startMarker = '-- ============================================================================\n-- MIGRATED PRODUCTS (120';
const start = existing.indexOf(startMarker);
if (start !== -1) {
  existing = existing.slice(0, start);
}

fs.writeFileSync(target, existing + output);
console.log(`Appended seed SQL for ${productId - 1} products to database.sql`);
console.log('Best sellers:', bestSellers.join(', '));