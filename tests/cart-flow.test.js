const test = require('node:test');
const assert = require('node:assert/strict');

globalThis.localStorage = {
  store: {},
  getItem(key) { return Object.prototype.hasOwnProperty.call(this.store, key) ? this.store[key] : null; },
  setItem(key, value) { this.store[key] = String(value); },
  removeItem(key) { delete this.store[key]; },
  clear() { this.store = {}; }
};

globalThis.document = { addEventListener() {} };

delete require.cache[require.resolve('../js/main.js')];
const { getCart, addToCart, updateCartItemQty, removeCartItem, getCartTotals, createOrderNumber } = require('../js/main.js');

test('cart helpers add and update item quantities', () => {
  localStorage.clear();
  addToCart({ id: 'sku-1', price: 500, name: 'Test dress' }, 2);
  addToCart({ id: 'sku-1', price: 500, name: 'Test dress' }, 1);
  assert.equal(getCart().length, 1);
  assert.equal(getCart()[0].qty, 3);
  assert.equal(getCart()[0].price, 500);

  updateCartItemQty('sku-1', 5);
  assert.equal(getCart()[0].qty, 5);

  removeCartItem('sku-1');
  assert.deepEqual(getCart(), []);
});

test('cart totals include delivery charge and order number generation', () => {
  localStorage.clear();
  addToCart({ id: 'sku-2', price: 1200, name: 'Second dress' }, 2);
  const totals = getCartTotals();
  assert.equal(totals.subtotal, 2400);
  assert.equal(totals.delivery, 300);
  assert.equal(totals.total, 2700);
  assert.match(createOrderNumber(), /^TH-[A-Z0-9-]+$/);
});

test('product catalog falls back to seed data without browser-only globals', () => {
  localStorage.clear();
  globalThis.SEED_PRODUCTS = [{ id: 'seed-abc', name: 'Seed Test Dress', price: 1500, category: 'Western', images: ['a.jpg'] }];

  delete require.cache[require.resolve('../js/main.js')];
  const { loadProducts } = require('../js/main.js');

  assert.equal(loadProducts().length, 1);
  assert.equal(loadProducts()[0].id, 'seed-abc');
});

test('cart badge sync is a safe no-op when document is unavailable', () => {
  const originalDocument = globalThis.document;
  delete globalThis.document;

  delete require.cache[require.resolve('../js/main.js')];
  const { syncCartBadge } = require('../js/main.js');
  assert.doesNotThrow(() => syncCartBadge());

  globalThis.document = originalDocument;
});

test('site collection groups include the requested unstitched, west, ready-to-wear and new in sections', () => {
  delete require.cache[require.resolve('../js/data.js')];
  require('../js/data.js');

  assert.ok(Array.isArray(globalThis.COLLECTION_GROUPS));
  assert.ok(globalThis.COLLECTION_GROUPS.some(group => group.label === 'Unstitched'));
  assert.ok(globalThis.COLLECTION_GROUPS.some(group => group.label === 'Western'));
  assert.ok(globalThis.COLLECTION_GROUPS.some(group => group.label === 'Ready to Wear'));
  assert.ok(globalThis.COLLECTION_GROUPS.some(group => group.label === 'New In'));

  const unstitched = globalThis.COLLECTION_GROUPS.find(group => group.label === 'Unstitched');
  const western = globalThis.COLLECTION_GROUPS.find(group => group.label === 'Western');
  const readyToWear = globalThis.COLLECTION_GROUPS.find(group => group.label === 'Ready to Wear');

  assert.ok(unstitched.items.some(item => item.label === 'View All Unstitched'));
  assert.ok(western.items.some(item => item.label === 'View All WEST'));
  assert.ok(readyToWear.items.some(item => item.label === 'View All Ready to Wear'));
});

test('catalogue contains 30 products in each main section', () => {
  delete require.cache[require.resolve('../js/data.js')];
  require('../js/data.js');

  const counts = globalThis.SEED_PRODUCTS.reduce((acc, product) => {
    acc[product.category] = (acc[product.category] || 0) + 1;
    return acc;
  }, {});

  assert.equal(counts.Stitched, 30);
  assert.equal(counts.Unstitched, 30);
  assert.equal(counts.Western, 30);
  assert.equal(counts.Eastern, 30);
});

test('visible products are capped at 30 per category even when storage contains more', () => {
  localStorage.clear();
  const expanded = [];

  for (let i = 0; i < 40; i++) {
    expanded.push({ id: `extra-${i}`, category: 'Stitched', name: `Stitched ${i + 1}`, price: 1000, images: ['a.jpg'] });
    expanded.push({ id: `extra-u-${i}`, category: 'Unstitched', name: `Unstitched ${i + 1}`, price: 1000, images: ['b.jpg'] });
    expanded.push({ id: `extra-w-${i}`, category: 'Western', name: `Western ${i + 1}`, price: 1000, images: ['c.jpg'] });
    expanded.push({ id: `extra-e-${i}`, category: 'Eastern', name: `Eastern ${i + 1}`, price: 1000, images: ['d.jpg'] });
  }

  localStorage.setItem('rh_products_v1', JSON.stringify(expanded));

  delete require.cache[require.resolve('../js/main.js')];
  const { loadProducts, categoryCount } = require('../js/main.js');

  assert.equal(loadProducts().filter(p => p.category === 'Stitched').slice(0, 30).length, 30);
  assert.equal(loadProducts().filter(p => p.category === 'Unstitched').slice(0, 30).length, 30);
  assert.equal(loadProducts().filter(p => p.category === 'Western').slice(0, 30).length, 30);
  assert.equal(loadProducts().filter(p => p.category === 'Eastern').slice(0, 30).length, 30);
  assert.equal(categoryCount('Stitched'), 30);
  assert.equal(categoryCount('Unstitched'), 30);
  assert.equal(categoryCount('Western'), 30);
  assert.equal(categoryCount('Eastern'), 30);
});
