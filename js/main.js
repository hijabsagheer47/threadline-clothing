/* ============================================================
   THREADLINE — SHARED LOGIC
   Maximum 35 products per category
   ============================================================ */

const RH_KEY = "rh_products_v3";

const FALLBACK_CATEGORIES = [
  "Stitched",
  "Unstitched",
  "Western",
  "Eastern"
];

const MAX_PRODUCTS_PER_CATEGORY = 35;


/* ============================================================
   CATEGORIES
   ============================================================ */

function safeCategories() {

  if (
    Array.isArray(globalThis.CATEGORIES) &&
    globalThis.CATEGORIES.length
  ) {
    return globalThis.CATEGORIES;
  }

  return FALLBACK_CATEGORIES;
}


/* ============================================================
   LOCAL STORAGE HELPERS
   ============================================================ */

function safeStorageGet(key) {

  if (typeof localStorage === "undefined") {
    return null;
  }

  try {
    return localStorage.getItem(key);
  } catch (e) {
    return null;
  }
}


function safeStorageSet(key, value) {

  if (typeof localStorage === "undefined") {
    return;
  }

  try {
    localStorage.setItem(key, value);
  } catch (e) {
    console.warn("Could not save to localStorage.");
  }
}


/* ============================================================
   MONEY
   ============================================================ */

function money(n) {

  return "Rs " + Number(n || 0).toLocaleString("en-PK");

}


/* ============================================================
   NORMALIZE PRODUCTS
   MAXIMUM 35 PRODUCTS PER CATEGORY
   ============================================================ */

function normalizeProductList(list) {

  const categories = safeCategories();

  const safeList = Array.isArray(list)
    ? list
    : [];

  const byCategory = {};

  categories.forEach(category => {
    byCategory[category] = [];
  });


  safeList.forEach(product => {

    if (!product) {
      return;
    }

    const category =
      product.category &&
      categories.includes(product.category)
        ? product.category
        : "Stitched";


    if (
      byCategory[category].length <
      MAX_PRODUCTS_PER_CATEGORY
    ) {

      byCategory[category].push(product);

    }

  });


  const normalized = [];


  categories.forEach(category => {

    normalized.push(
      ...byCategory[category]
    );

  });


  return normalized;

}


/* ============================================================
   LOAD PRODUCTS
   ============================================================ */

function loadProducts() {

  let stored;


  try {

    stored = JSON.parse(
      safeStorageGet(RH_KEY)
    );

  } catch (e) {

    stored = null;

  }


  /*
     If there are no saved products,
     load the 140 seed products.

     35 Stitched
     35 Unstitched
     35 Western
     35 Eastern
  */

  if (!Array.isArray(stored) || stored.length === 0) {

    stored =
      Array.isArray(globalThis.SEED_PRODUCTS)
        ? globalThis.SEED_PRODUCTS
        : [];


    saveProducts(stored);

  }


  const normalized =
    normalizeProductList(stored);


  if (
    JSON.stringify(normalized) !==
    JSON.stringify(stored)
  ) {

    saveProducts(normalized);

  }


  return normalized;

}


/* ============================================================
   SAVE PRODUCTS
   ============================================================ */

function saveProducts(list) {

  const normalized =
    normalizeProductList(list || []);


  safeStorageSet(
    RH_KEY,
    JSON.stringify(normalized)
  );

}


/* ============================================================
   GET PRODUCT
   ============================================================ */

function getProductById(id) {

  return loadProducts().find(
    product => product.id === id
  );

}


/* ============================================================
   ADD PRODUCT
   ============================================================ */

function addProduct(product) {

  const list = loadProducts();


  if (!product || !product.category) {

    return null;

  }


  /*
     Check category limit.
     Each category can contain maximum 35 products.
  */

  const categoryProducts =
    list.filter(
      item => item.category === product.category
    );


  if (
    categoryProducts.length >=
    MAX_PRODUCTS_PER_CATEGORY
  ) {

    alert(
      `${product.category} already has ${MAX_PRODUCTS_PER_CATEGORY} products.`
    );

    return null;

  }


  product.id =
    "p-" + Date.now();


  list.unshift(product);


  saveProducts(list);


  return product;

}


/* ============================================================
   DELETE PRODUCT
   ============================================================ */

function deleteProduct(id) {

  const list =
    loadProducts().filter(
      product => product.id !== id
    );


  saveProducts(list);

}


/* ============================================================
   CATEGORY COUNT
   ============================================================ */

function categoryCount(category) {

  return loadProducts().filter(
    product => product.category === category
  ).length;

}


function normalizeCategoryQuery(value) {

  if (!value) {
    return "";
  }

  const normalized = String(value)
    .trim()
    .toLowerCase()
    .replace(/[_\s]+/g, "-")
    .replace(/[^a-z0-9-]/g, "");

  const map = {
    stitched: "Stitched",
    unstitched: "Unstitched",
    western: "Western",
    eastern: "Eastern",
    "new-arrivals": "new-arrivals",
    "new-arrivals-collection": "new-arrivals",
    "newin": "new-arrivals",
    "new-in": "new-arrivals"
  };

  return map[normalized] || "";

}


function isNewArrivalProduct(product) {

  if (!product) {
    return false;
  }

  const badge =
    String(
      product.badge ||
      product.label ||
      ""
    )
      .trim()
      .toLowerCase();

  if (product.isNew === true || badge === "new") {
    return true;
  }

  return false;

}


/* ============================================================
   ENSURE CATEGORY LIMIT
   ============================================================ */

function ensureVisibleCategoryLimit() {

  const categories =
    safeCategories();

  const products =
    loadProducts();


  const counts = {};


  categories.forEach(category => {

    counts[category] = 0;

  });


  const next = [];


  products.forEach(product => {

    const category =
      product &&
      product.category &&
      categories.includes(product.category)
        ? product.category
        : "Stitched";


    if (
      counts[category] <
      MAX_PRODUCTS_PER_CATEGORY
    ) {

      counts[category]++;

      next.push(product);

    }

  });


  saveProducts(next);


  return next;

}


/* ============================================================
   CART
   ============================================================ */

const CART_KEY = "rh_cart_v1";

const ORDERS_KEY = "rh_orders_v1";

const DELIVERY_CHARGE = 300;


/* ============================================================
   GET CART
   ============================================================ */

function getCart() {

  let cart;


  try {

    cart = JSON.parse(
      safeStorageGet(CART_KEY)
    );

  } catch (e) {

    cart = null;

  }


  if (!Array.isArray(cart)) {

    return [];

  }


  return cart;

}


/* ============================================================
   SAVE CART
   ============================================================ */

function saveCart(cart) {

  safeStorageSet(
    CART_KEY,
    JSON.stringify(cart || [])
  );

}


/* ============================================================
   ADD TO CART
   ============================================================ */

function addToCart(product, qty = 1) {

  const cart =
    getCart();


  const itemQty =
    Number(qty) || 1;


  if (
    !product ||
    !product.id
  ) {

    return cart;

  }


  const existing =
    cart.find(
      item => item.id === product.id
    );


  if (existing) {

    existing.qty += itemQty;

  } else {

    cart.push({

      id: product.id,

      name: product.name,

      price: Number(
        product.price || 0
      ),

      image:
        product.image ||
        (
          product.images &&
          product.images[0]
        ) ||
        "",

      qty: itemQty

    });

  }


  saveCart(cart);


  return cart;

}


/* ============================================================
   UPDATE CART
   ============================================================ */

function updateCartItemQty(
  productId,
  qty
) {

  const cart =
    getCart();


  const nextQty =
    Number(qty) || 0;


  const updated =
    cart
      .map(item => {

        if (item.id === productId) {

          return {
            ...item,
            qty: nextQty
          };

        }

        return item;

      })
      .filter(
        item => item.qty > 0
      );


  saveCart(updated);


  return updated;

}


/* ============================================================
   REMOVE CART ITEM
   ============================================================ */

function removeCartItem(productId) {

  const filtered =
    getCart().filter(
      item => item.id !== productId
    );


  saveCart(filtered);


  return filtered;

}


/* ============================================================
   CART TOTALS
   ============================================================ */

function getCartTotals() {

  const cart =
    getCart();


  const subtotal =
    cart.reduce(
      (sum, item) =>
        sum +
        (
          Number(item.price) *
          Number(item.qty || 0)
        ),
      0
    );


  const delivery =
    cart.length
      ? DELIVERY_CHARGE
      : 0;


  const total =
    subtotal + delivery;


  const itemCount =
    cart.reduce(
      (sum, item) =>
        sum +
        Number(item.qty || 0),
      0
    );


  return {
    subtotal,
    delivery,
    total,
    itemCount
  };

}


/* ============================================================
   ORDER NUMBER
   ============================================================ */

function createOrderNumber() {

  const now =
    new Date();


  const stamp =
    `${now.getFullYear()}${String(
      now.getMonth() + 1
    ).padStart(2, "0")}${String(
      now.getDate()
    ).padStart(2, "0")}`;


  const token =
    Math.random()
      .toString(36)
      .slice(2, 8)
      .toUpperCase();


  return `TH-${stamp}-${token}`;

}


/* ============================================================
   SAVED ORDERS
   ============================================================ */

function getSavedOrders() {

  let orders;


  try {

    orders = JSON.parse(
      safeStorageGet(ORDERS_KEY)
    );

  } catch (e) {

    orders = null;

  }


  if (!Array.isArray(orders)) {

    return [];

  }


  return orders;

}


/* ============================================================
   SAVE ORDERS
   ============================================================ */

function saveOrders(orders) {

  safeStorageSet(
    ORDERS_KEY,
    JSON.stringify(orders || [])
  );

}


/* ============================================================
   PLACE ORDER
   ============================================================ */

function placeOrder(customer) {

  const cart =
    getCart();


  if (!cart.length) {

    return null;

  }


  const totals =
    getCartTotals();


  const order = {

    orderNumber:
      createOrderNumber(),

    paymentMethod:
      customer.paymentMethod ||
      "Cash on Delivery",

    customerName:
      customer.customerName ||
      "",

    phone:
      customer.phone ||
      "",

    email:
      customer.email ||
      "",

    city:
      customer.city ||
      "",

    address:
      customer.address ||
      "",

    items:
      cart.map(item => ({
        ...item
      })),

    subtotal:
      totals.subtotal,

    delivery:
      totals.delivery,

    total:
      totals.total,

    createdAt:
      new Date().toISOString()

  };


  const orders =
    getSavedOrders();


  orders.unshift(order);


  saveOrders(orders);


  saveCart([]);


  return order;

}


/* ============================================================
   LATEST ORDER
   ============================================================ */

function getLatestOrder() {

  const orders =
    getSavedOrders();


  return orders[0] || null;

}


/* ============================================================
   CART BADGE
   ============================================================ */

function syncCartBadge() {

  if (
    typeof document ===
    "undefined"
  ) {

    return;

  }


  const count =
    getCart().reduce(
      (sum, item) =>
        sum +
        Number(item.qty || 0),
      0
    );


  document
    .querySelectorAll(".cart-badge")
    .forEach(el => {

      el.textContent =
        count;


      el.style.display =
        count > 0
          ? "inline-flex"
          : "none";

    });

}


/* ============================================================
   CATEGORY SWATCH
   ============================================================ */

function categorySwatch(category) {

  const map = {

    Stitched:
      ["#7A2E3B", "#5E212C"],

    Unstitched:
      ["#AD8A4E", "#8A6C38"],

    Western:
      ["#2B211D", "#40342C"],

    Eastern:
      ["#7A2E3B", "#AD8A4E"]

  };


  const colors =
    map[category] ||
    ["#7A2E3B", "#5E212C"];


  const a =
    colors[0];

  const b =
    colors[1];


  return `
    <svg
      class="swatch"
      viewBox="0 0 300 300"
      xmlns="http://www.w3.org/2000/svg"
      preserveAspectRatio="xMidYMid slice"
    >

      <defs>

        <linearGradient
          id="grad-${category}"
          x1="0"
          y1="0"
          x2="1"
          y2="1"
        >

          <stop
            offset="0"
            stop-color="${a}"
          />

          <stop
            offset="1"
            stop-color="${b}"
          />

        </linearGradient>

      </defs>

      <rect
        width="300"
        height="300"
        fill="url(#grad-${category})"
      />

    </svg>
  `;

}


/* ============================================================
   PRODUCT CARD
   ============================================================ */

function productCardHTML(product) {

  const img1 =
    product.images &&
    product.images[0]
      ? product.images[0]
      : "";


  const img2 =
    product.images &&
    product.images[1]
      ? product.images[1]
      : img1;


  return `

    <div class="product-card">

      <a
        class="product-card-link"
        href="product.html?id=${encodeURIComponent(
          product.id
        )}"
      >

        <div class="product-thumb">

          <img
            src="${img1}"
            alt="${product.name}"
            loading="lazy"
          />

          <img
            class="img-alt"
            src="${img2}"
            alt=""
            loading="lazy"
          />

          <span class="product-tag">
            ${product.category}
          </span>

        </div>


        <div class="product-info">

          <div class="p-name">
            ${product.name}
          </div>

          <div class="p-price">
            ${money(product.price)}
          </div>

          <div class="p-cat">
            ${product.category}
          </div>

        </div>

      </a>


      <button
        type="button"
        class="mini-cart-btn"
        data-product-id="${product.id}"
        data-product-name="${product.name}"
        data-product-price="${product.price}"
        data-product-image="${img1}"
      >
        Add to cart
      </button>

    </div>

  `;

}


/* ============================================================
   CART BUTTONS
   ============================================================ */

function bindCartButtons() {

  if (
    typeof document ===
    "undefined"
  ) {

    return;

  }


  document
    .querySelectorAll(
      ".mini-cart-btn, .add-to-cart-btn"
    )
    .forEach(btn => {


      if (
        btn.dataset.bound ===
        "true"
      ) {

        return;

      }


      btn.dataset.bound =
        "true";


      btn.addEventListener(
        "click",
        event => {

          event.preventDefault();

          event.stopPropagation();


          const product = {

            id:
              btn.dataset.productId,

            name:
              btn.dataset.productName,

            price:
              Number(
                btn.dataset.productPrice ||
                0
              ),

            image:
              btn.dataset.productImage ||
              "",

            images:
              btn.dataset.productImage
                ? [
                    btn.dataset.productImage
                  ]
                : []

          };


          addToCart(
            product,
            Number(
              btn.dataset.qty ||
              1
            )
          );


          syncCartBadge();


          const originalText =
            btn.textContent.trim();


          btn.textContent =
            "Added";


          btn.disabled =
            true;


          setTimeout(() => {

            btn.textContent =
              originalText;

            btn.disabled =
              false;

          }, 900);

        }
      );

    });

}


/* ============================================================
   MOBILE NAV + FOOTER
   ============================================================ */

function initChrome() {

  if (
    typeof document ===
    "undefined"
  ) {

    return;

  }


  const toggle =
    document.querySelector(
      ".nav-toggle"
    );


  const links =
    document.querySelector(
      ".nav-links"
    );


  if (
    toggle &&
    links
  ) {

    toggle.addEventListener(
      "click",
      () => {

        links.classList.toggle(
          "open"
        );

      }
    );

  }


  document
    .querySelectorAll(
      ".nav-links a"
    )
    .forEach(a => {

      const href =
        a.getAttribute(
          "href"
        );


      if (
        href ===
        location.pathname
          .split("/")
          .pop()
      ) {

        a.classList.add(
          "active"
        );

      }

    });


  const yearEl =
    document.getElementById(
      "year"
    );


  if (yearEl) {

    yearEl.textContent =
      new Date().getFullYear();

  }

}


/* ============================================================
   INITIALIZE
   ============================================================ */

if (
  typeof document !==
  "undefined"
) {

  document.addEventListener(
    "DOMContentLoaded",
    () => {

      initChrome();

      syncCartBadge();

      bindCartButtons();

    }
  );

}


/* ============================================================
   NODE EXPORT
   ============================================================ */

if (
  typeof module !==
  "undefined" &&
  module.exports
) {

  module.exports = {

    RH_KEY,

    CART_KEY,

    ORDERS_KEY,

    DELIVERY_CHARGE,

    MAX_PRODUCTS_PER_CATEGORY,

    money,

    normalizeCategoryQuery,

    isNewArrivalProduct,

    loadProducts,

    saveProducts,

    getProductById,

    addProduct,

    deleteProduct,

    categoryCount,

    ensureVisibleCategoryLimit,

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