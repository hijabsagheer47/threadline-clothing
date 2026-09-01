/* ============================================================
   RESHAM HOUSE — shared logic
   Products are kept in the browser's localStorage under RH_KEY.
   Seed products (js/data.js) ship with the site as demo content;
   anything added via admin.html is saved on top of that and
   persists for that browser only (no server / database involved).
   ============================================================ */

const RH_KEY = "rh_products_v1";
const FALLBACK_CATEGORIES = ["Stitched", "Unstitched", "Western", "Eastern"];

function safeCategories(){
  return Array.isArray(globalThis.CATEGORIES) && globalThis.CATEGORIES.length ? globalThis.CATEGORIES : FALLBACK_CATEGORIES;
}

function safeStorageGet(key){
  if (typeof localStorage === "undefined") return null;
  try { return localStorage.getItem(key); } catch (e) { return null; }
}

function safeStorageSet(key, value){
  if (typeof localStorage === "undefined") return;
  try { localStorage.setItem(key, value); } catch (e) { /* no-op */ }
}

function money(n){
  return "Rs " + Number(n).toLocaleString("en-PK");
}

function normalizeProductList(list){
  const categories = safeCategories();
  const safeList = Array.isArray(list) ? list : [];
  const byCategory = {};

  categories.forEach(cat => {
    byCategory[cat] = [];
  });

  safeList.forEach(product => {
    const category = product && product.category && categories.includes(product.category) ? product.category : "Stitched";
    if (byCategory[category].length < 30) {
      byCategory[category].push(product);
    }
  });

  const normalized = [];
  categories.forEach(cat => {
    normalized.push(...byCategory[cat]);
  });

  return normalized;
}

function loadProducts(){
  let stored;
  try{ stored = JSON.parse(safeStorageGet(RH_KEY)); }catch(e){ stored = null; }
  if(!stored){
    stored = Array.isArray(typeof SEED_PRODUCTS !== "undefined" ? SEED_PRODUCTS : []) ? (typeof SEED_PRODUCTS !== "undefined" ? SEED_PRODUCTS : []) : [];
    saveProducts(stored);
  }

  const normalized = normalizeProductList(stored);
  if (JSON.stringify(normalized) !== JSON.stringify(stored)) {
    saveProducts(normalized);
  }
  return normalized;
}

function saveProducts(list){
  const normalized = normalizeProductList(list || []);
  safeStorageSet(RH_KEY, JSON.stringify(normalized));
}

function getProductById(id){
  return loadProducts().find(p => p.id === id);
}

function addProduct(product){
  const list = loadProducts();
  product.id = "p-" + Date.now();
  list.unshift(product);
  saveProducts(list);
  return product;
}

function deleteProduct(id){
  const list = loadProducts().filter(p => p.id !== id);
  saveProducts(list);
}

function categoryCount(cat){
  return loadProducts().filter(p => p.category === cat).length;
}

function ensureVisibleCategoryLimit(){
  const categories = safeCategories();
  const products = loadProducts();
  const counts = {};
  categories.forEach(cat => counts[cat] = 0);

  const next = [];
  products.forEach(product => {
    const cat = product && product.category && categories.includes(product.category) ? product.category : "Stitched";
    if (counts[cat] < 30) {
      counts[cat] += 1;
      next.push(product);
    }
  });

  saveProducts(next);
  return next;
}

/* ---------- cart + checkout helpers ---------- */
const CART_KEY = "rh_cart_v1";
const ORDERS_KEY = "rh_orders_v1";
const DELIVERY_CHARGE = 300;

function getCart(){
  let cart;
  try { cart = JSON.parse(safeStorageGet(CART_KEY)); } catch (e) { cart = null; }
  if(!Array.isArray(cart)) return [];
  return cart;
}

function saveCart(cart){
  safeStorageSet(CART_KEY, JSON.stringify(cart || []));
}

function addToCart(product, qty = 1){
  const cart = getCart();
  const itemQty = Number(qty) || 1;
  if(!product || !product.id) return cart;

  const existing = cart.find(item => item.id === product.id);
  if(existing){
    existing.qty += itemQty;
  }else{
    cart.push({
      id: product.id,
      name: product.name,
      price: Number(product.price || 0),
      image: product.image || (product.images && product.images[0]) || "",
      qty: itemQty
    });
  }

  saveCart(cart);
  return cart;
}

function updateCartItemQty(productId, qty){
  const cart = getCart();
  const nextQty = Number(qty) || 0;
  const updated = cart
    .map(item => item.id === productId ? { ...item, qty: nextQty } : item)
    .filter(item => item.qty > 0);
  saveCart(updated);
  return updated;
}

function removeCartItem(productId){
  const filtered = getCart().filter(item => item.id !== productId);
  saveCart(filtered);
  return filtered;
}

function getCartTotals(){
  const cart = getCart();
  const subtotal = cart.reduce((sum, item) => sum + (Number(item.price) * Number(item.qty || 0)), 0);
  const delivery = cart.length ? DELIVERY_CHARGE : 0;
  const total = subtotal + delivery;
  return { subtotal, delivery, total, itemCount: cart.reduce((sum, item) => sum + Number(item.qty || 0), 0) };
}

function createOrderNumber(){
  const now = new Date();
  const stamp = `${now.getFullYear()}${String(now.getMonth() + 1).padStart(2, "0")}${String(now.getDate()).padStart(2, "0")}`;
  const token = Math.random().toString(36).slice(2, 8).toUpperCase();
  return `TH-${stamp}-${token}`;
}

function getSavedOrders(){
  let orders;
  try { orders = JSON.parse(safeStorageGet(ORDERS_KEY)); } catch (e) { orders = null; }
  if(!Array.isArray(orders)) return [];
  return orders;
}

function saveOrders(orders){
  safeStorageSet(ORDERS_KEY, JSON.stringify(orders || []));
}

function placeOrder(customer){
  const cart = getCart();
  if(!cart.length) return null;

  const totals = getCartTotals();
  const order = {
    orderNumber: createOrderNumber(),
    paymentMethod: customer.paymentMethod || "Cash on Delivery",
    customerName: customer.customerName || "",
    phone: customer.phone || "",
    email: customer.email || "",
    city: customer.city || "",
    address: customer.address || "",
    items: cart.map(item => ({ ...item })),
    subtotal: totals.subtotal,
    delivery: totals.delivery,
    total: totals.total,
    createdAt: new Date().toISOString()
  };

  const orders = getSavedOrders();
  orders.unshift(order);
  saveOrders(orders);
  saveCart([]);
  return order;
}

function getLatestOrder(){
  const orders = getSavedOrders();
  return orders[0] || null;
}

function syncCartBadge(){
  if (typeof document === "undefined") return;
  const count = getCart().reduce((sum, item) => sum + Number(item.qty || 0), 0);
  document.querySelectorAll(".cart-badge").forEach(el => {
    el.textContent = count;
    el.style.display = count > 0 ? "inline-flex" : "none";
  });
}

/* ---------- shared render helpers ---------- */
function categorySwatch(cat){
  const map = {
    Stitched:   ["#7A2E3B","#5E212C"],
    Unstitched: ["#AD8A4E","#8a6c38"],
    Western:    ["#2B211D","#40342c"],
    Eastern:    ["#7A2E3B","#AD8A4E"]
  };
  const [a,b] = map[cat] || ["#7A2E3B","#5E212C"];
  return `<svg class="swatch" viewBox="0 0 300 300" xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMidYMid slice">
    <defs><linearGradient id="grad-${cat}" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stop-color="${a}"/><stop offset="1" stop-color="${b}"/>
    </linearGradient></defs>
    <rect width="300" height="300" fill="url(#grad-${cat})"/>
  </svg>`;
}

function productCardHTML(p){
  const img1 = p.images[0];
  const img2 = p.images[1] || p.images[0];
  return `
    <div class="product-card">
      <a class="product-card-link" href="product.html?id=${p.id}">
        <div class="product-thumb">
          <img src="${img1}" alt="${p.name}">
          <img class="img-alt" src="${img2}" alt="">
          <span class="product-tag">${p.category}</span>
        </div>
        <div class="product-info">
          <div class="p-name">${p.name}</div>
          <div class="p-price">${money(p.price)}</div>
          <div class="p-cat">${p.category}</div>
        </div>
      </a>
      <button type="button" class="mini-cart-btn" data-product-id="${p.id}" data-product-name="${p.name}" data-product-price="${p.price}" data-product-image="${p.images[0]}">Add to cart</button>
    </div>`;
}

function bindCartButtons(){
  document.querySelectorAll(".mini-cart-btn, .add-to-cart-btn").forEach(btn => {
    if(btn.dataset.bound === "true") return;
    btn.dataset.bound = "true";
    btn.addEventListener("click", (e) => {
      e.preventDefault();
      e.stopPropagation();

      const product = {
        id: btn.dataset.productId,
        name: btn.dataset.productName,
        price: Number(btn.dataset.productPrice || 0),
        image: btn.dataset.productImage || "",
        images: btn.dataset.productImage ? [btn.dataset.productImage] : []
      };

      addToCart(product, Number(btn.dataset.qty || 1));
      syncCartBadge();

      const originalText = btn.textContent.trim();
      btn.textContent = "Added";
      btn.disabled = true;
      setTimeout(() => {
        btn.textContent = originalText;
        btn.disabled = false;
      }, 900);
    });
  });
}

/* ---------- shared chrome: mobile nav + footer year ---------- */
function initChrome(){
  const toggle = document.querySelector(".nav-toggle");
  const links = document.querySelector(".nav-links");
  if(toggle && links){
    toggle.addEventListener("click", () => links.classList.toggle("open"));
  }
  document.querySelectorAll(".nav-links a").forEach(a=>{
    if(a.getAttribute("href") === location.pathname.split("/").pop()){
      a.classList.add("active");
    }
  });
  const yearEl = document.getElementById("year");
  if(yearEl) yearEl.textContent = new Date().getFullYear();
}

if (typeof document !== "undefined") {
  document.addEventListener("DOMContentLoaded", () => {
    initChrome();
    syncCartBadge();
    bindCartButtons();
  });
}

if (typeof module !== "undefined" && module.exports) {
  module.exports = {
    RH_KEY,
    CART_KEY,
    ORDERS_KEY,
    DELIVERY_CHARGE,
    money,
    loadProducts,
    saveProducts,
    getProductById,
    addProduct,
    deleteProduct,
    categoryCount,
    getCart,
    saveCart,
    addToCart,
    updateCartItemQty,
    removeCartItem,
    getCartTotals,
    createOrderNumber,
    getSavedOrders,
    saveOrders,
    placeOrder,
    getLatestOrder,
    syncCartBadge,
    categorySwatch,
    productCardHTML,
    bindCartButtons,
    initChrome
  };
}
