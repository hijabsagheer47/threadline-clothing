# Fashlab Studio — Customer API (v1)

REST API for the Flutter mobile app. Customer side only — nothing here touches
the admin panel.

**Base URL:** `https://fashlabstudio.mytechrcm.com/api/v1/index.php`

> This webspace applies mod_rewrite *patterns* but silently drops the
> *substitution* — which is why the storefront's pretty permalinks
> (`/product/{slug}`) 404 there and it serves `/product.php?slug=…` instead.
> The API therefore routes on `PATH_INFO`, not on a rewrite, so
> `…/api/v1/index.php/products` is the form to use.
>
> Two fallbacks are built in and need no server support at all:
>
> | Form | URL |
> |---|---|
> | PATH_INFO (**use this**) | `…/api/v1/index.php/products?per_page=20` |
> | Query string | `…/api/v1/index.php?_route=products&per_page=20` |
> | Clean (only where rewrites work) | `…/api/v1/products?per_page=20` |
>
> Set the base URL once in your Dio/http client and the endpoint tables below
> read the same either way.

---

## 1. Install (one time)

1. Import the migration:

   ```bash
   mysql -u USER -p DBNAME < migration-mobile-api.sql
   ```

2. Upload the new/changed files (see *Changed files* at the bottom).
3. Check it is live:

   ```bash
   curl https://fashlabstudio.mytechrcm.com/api/v1/index.php/health
   ```

   ```json
   { "success": true, "data": { "status": "ok", "api_version": "v1", "store": "Fashlab Studio" } }
   ```

If `/health` returns *"The mobile API is not installed"*, the migration has not
been run yet.

---

## 2. How every response looks

```json
{
  "success": true,
  "message": "Saved to your wishlist.",
  "data":    { },
  "errors":  { }
}
```

- `success` — always present. Branch on this, not on the HTTP status.
- `message` — safe to show to the customer as-is.
- `data`    — the payload; `null` on failure.
- `errors`  — `{ "field": "message" }` on a 422, so it maps straight onto
  Flutter form validators.

**Status codes:** `200` ok · `201` created · `401` sign in required ·
`404` not found · `405` wrong method · `409` conflict · `422` validation ·
`503` store closed / API not installed.

Paginated endpoints wrap their list:

```json
{ "items": [ ], "meta": { "page": 1, "per_page": 20, "total": 120, "pages": 6, "has_more": true } }
```

---

## 3. Authentication

Every request carries a bearer token — including anonymous browsing.

```
Authorization: Bearer <token>
```

Some PHP-CGI setups strip `Authorization` before PHP sees it. If
`/auth/me` keeps returning 401 with a token you know is good, send the token in
`X-Api-Token` instead — the API accepts either, and no server strips that
header.

The token holds the cart and the wishlist, so a shopper can fill a basket
before they ever create an account. When they register or sign in, **the same
token is bound to their account** — nothing is lost.

### First launch

```
POST /auth/guest      { "platform": "android", "device_name": "Pixel 8" }
→ data: { token, is_new, customer, cart_count, wishlist_count }
```

Store `token` in secure storage and send it on every request afterwards. Safe
to call on every launch: with a valid token it returns that same token.

If a request arrives with a missing, unknown or expired token, the API issues a
fresh guest token instead of failing, and returns it in the **`X-Api-Token`**
response header. Read that header on every response and, when it differs from
the one you hold, replace your stored token.

Tokens last 180 days and the clock resets on each request.

| Method | Endpoint | Notes |
|---|---|---|
| POST | `/auth/guest` | Issue / confirm a token |
| POST | `/auth/register` | `name, email, password, phone?, newsletter?` |
| POST | `/auth/login` | `email, password` |
| POST | `/auth/logout` | Revokes this device's token — call `/auth/guest` after |
| POST | `/auth/logout-all` | Revokes every device |
| GET  | `/auth/me` | Customer + cart/wishlist/order counts |
| PUT  | `/auth/profile` | `name?, phone?, preferred_size?, newsletter_optin?` |
| POST | `/auth/change-password` | `current_password, new_password` |
| POST | `/auth/forgot-password` | `email` — always answers the same way |
| POST | `/auth/reset-password` | `token, password` |

Passwords must be at least 8 characters. Repeated failed logins are locked out
for 15 minutes, the same rule the admin panel uses.

---

## 4. Catalogue

| Method | Endpoint | Notes |
|---|---|---|
| GET | `/home` | **One call for the whole home screen** — hero slides, categories, collections, featured / new / best sellers / on sale, testimonials |
| GET | `/products` | See filters below |
| GET | `/products/{slug}` | Full detail + related + reviews + size chart + `in_wishlist` |
| GET | `/products/{slug}/reviews` | Paginated, with a rating breakdown |
| POST | `/products/{slug}/reviews` | `rating, name?, email?, title?, body?` — held for moderation |
| GET | `/categories` | Full tree with product counts |
| GET | `/categories/{slug}` | Category + children |
| GET | `/collections` | Curated edits |
| GET | `/collections/{slug}` | Collection + its products |
| GET | `/filters` | Facet values, sort options and price presets for the filter sheet |
| GET | `/search/suggest?q=` | Type-ahead (min 2 characters) |
| GET | `/search/trending` | What customers actually search for |
| GET | `/recently-viewed` | Tracked automatically per token |
| GET | `/looks` | Shop-the-look sets |

### `/products` query parameters

| Param | Values |
|---|---|
| `q` | free text |
| `category` | slug or id |
| `collection` | slug or id |
| `sort` | `newest` `featured` `best_selling` `price_low` `price_high` `name` |
| `price` | `under-5000` `5000-10000` `10000-15000` `over-15000` |
| `price_min` / `price_max` | numbers (ignored when `price` is set) |
| `fabric` / `color` / `size` | facet values from `/filters` |
| `availability` | any value = in stock only |
| `sale` | any value = on sale only |
| `featured` | any value = featured only |
| `page` / `per_page` | `per_page` max 48, default 20 |

Every product carries display-ready fields so the app does no price maths:

```json
{
  "id": 92, "name": "...", "slug": "...",
  "price": 6875, "sale_price": 6050, "final_price": 6050,
  "on_sale": true, "discount_percent": 12,
  "formatted_price": "Rs. 6,050", "formatted_compare_at": "Rs. 6,875",
  "in_stock": true, "stock_quantity": 10,
  "rating": 4.5, "rating_count": 12,
  "badges": [ { "label": "SALE", "type": "sale" } ],
  "image": "https://fashlabstudio.mytechrcm.com/images/products/x.jpg"
}
```

Image URLs are always absolute. Product detail adds `images[]`,
`variant_groups[]` (options grouped by "Size", "Colour", …), `categories[]`,
`description`, `care_instructions` and `share_url`.

---

## 5. Cart

Every cart call returns the **complete cart**, so you never need a follow-up
`GET`.

| Method | Endpoint | Body |
|---|---|---|
| GET | `/cart` | — |
| GET | `/cart/count` | — (cheap badge refresh) |
| POST | `/cart/items` | `product_id, variant_id?, quantity?` |
| PATCH | `/cart/items` | `key, quantity` — **preferred** |
| PATCH | `/cart/items/{key}` | `quantity` |
| POST | `/cart/items/remove` | `key` — **preferred** |
| DELETE | `/cart/items/{key}` | — |
| DELETE | `/cart` | Empties the cart and drops the coupon |
| POST | `/cart/coupon` | `code` |
| DELETE | `/cart/coupon` | — |

A cart key looks like `92:0` (`product:variant`). The colon is legal in a URL
path but some HTTP clients and proxies mangle it, so **prefer the body forms**;
percent-encode the key (`92%3A0`) if you use the path form.

```json
{
  "items": [ { "key": "92:0", "name": "...", "quantity": 2, "unit_price": 6875,
               "line_total": 13750, "available": true, "max_quantity": 10 } ],
  "coupon": { "code": "WELCOME10", "discount": 1375, "formatted_discount": "Rs. 1,375" },
  "totals": { "subtotal": 13750, "shipping": 0, "discount": 1375, "total": 12375,
              "formatted": { "subtotal": "Rs. 13,750", "shipping": "Free", "total": "Rs. 12,375" } },
  "summary": { "line_count": 1, "item_count": 2, "has_unavailable": false,
               "free_shipping_threshold": 8000, "amount_to_free_shipping": 0 }
}
```

Prices, stock and coupon validity are recalculated on the server every time.
Anything the client sends about money is ignored.

---

## 6. Wishlist

Works for guests as well as signed-in customers.

| Method | Endpoint | Body |
|---|---|---|
| GET | `/wishlist` | — |
| GET | `/wishlist/count` | — |
| GET | `/wishlist/ids` | — (to paint hearts across a grid) |
| POST | `/wishlist` | `product_id` — idempotent |
| POST | `/wishlist/toggle` | `product_id` |
| DELETE | `/wishlist/{product_id}` | — |
| POST | `/wishlist/move-to-cart` | `product_id, variant_id?, quantity?` |

---

## 7. Checkout and orders

| Method | Endpoint | Auth | Body |
|---|---|---|---|
| GET | `/checkout` | guest ok | Cart, saved addresses, delivery and payment options |
| POST | `/orders` | guest ok | See below |
| GET | `/orders` | **required** | Order history |
| GET | `/orders/{order_number}` | required, or `?contact=` | Full detail + timeline |
| POST | `/orders/track` | guest ok | `order_number, contact` |
| POST | `/orders/{order_number}/cancel` | **required** | `reason?` |
| POST | `/orders/{order_number}/reorder` | **required** | Puts the items back in the cart |

### Placing an order

```json
POST /orders
{
  "name": "Ayesha Khan",
  "email": "ayesha@example.com",
  "phone": "03001234567",
  "address": "House 12, Street 4, DHA Phase 5",
  "city": "Karachi",
  "postal_code": "75500",
  "delivery": "standard",
  "notes": "Please call before delivery",
  "is_gift": false
}
```

A signed-in customer can post `{"address_id": 3}` instead of the address
fields, and `name` / `email` / `phone` default to their profile.

`delivery` is `standard` or `express` (express adds a flat fee).
**Payment is Cash on Delivery only** — no gateway is connected, so accepting a
card would create an order the store could never settle.

Cancellation is allowed while the order is `pending` or `confirmed`, and
returns the stock to the shelf.

Orders are created by the same server-side function the website checkout uses,
so stock, coupons and the inventory log can never drift between the two.

---

## 8. Account

| Method | Endpoint | Auth |
|---|---|---|
| GET / POST | `/addresses` | required |
| PUT / DELETE | `/addresses/{id}` | required |
| GET | `/notifications` | required |
| POST | `/notifications/{id}/read` · `/notifications/read-all` | required |
| GET | `/rewards` | required |
| POST | `/product-alerts` | guest ok — `product_id, email?, type?` ("tell me when it's back") |

---

## 9. Content and store config

| Method | Endpoint | Notes |
|---|---|---|
| GET | `/settings` | **Cache this.** Store name, currency, shipping rules, social links, support contacts |
| GET | `/menus` | The navigation the admin manages — build the drawer from this |
| GET | `/pages` · `/pages/{slug}` | CMS pages (policies, guides) |
| GET | `/faqs` | Grouped by category |
| GET | `/size-chart` | Global measurements table |
| GET | `/journal` · `/journal/{slug}` | Blog |
| POST | `/newsletter` | `email` |
| POST | `/contact` | `name, email, message, phone?, subject?` |
| POST | `/personal-shopper` | `name, phone, occasion?, budget?, …` |
| GET | `/health` | Connectivity check |

---

## 9a. Install checklist

Both migrations must be imported for the app and the website to offer the same
features:

| File | Adds | Without it |
|---|---|---|
| `migration-fashlab-upgrade.sql` | Collections, wishlists, reviews, coupons, saved addresses, notifications, menus, CMS pages, FAQs, journal, size charts, order tracking history | Those endpoints return empty and the wishlist is session-only |
| `migration-mobile-api.sql` | `api_tokens` | The API refuses every request with *"The mobile API is not installed"* |

Both are additive and idempotent — they create tables and columns, never drop
or overwrite existing data, and re-running them is harmless.

---

## 10. Flutter notes

**Screen → call**

| Screen | Call |
|---|---|
| Splash | `POST /auth/guest`, then `GET /settings` |
| Home | `GET /home` |
| Shop / search results | `GET /products?…` |
| Filter sheet | `GET /filters` |
| Product | `GET /products/{slug}` |
| Cart | `GET /cart` |
| Checkout | `GET /checkout` → `POST /orders` |
| Account | `GET /auth/me` |
| Orders | `GET /orders` → `GET /orders/{number}` |

**Interceptor checklist**

1. Attach `Authorization: Bearer <token>` to every request.
2. After each response, if `X-Api-Token` differs from your stored token, save
   the new one.
3. On `401`, clear the stored customer and send the user to sign-in.
4. On `503`, show a "store is closed" screen.
5. Read `success` first; show `message` on failure; map `errors` onto form
   fields on a `422`.

Send bodies as JSON (`Content-Type: application/json`); form-encoded works too.

**No CSRF token is needed.** The website's `/api/cart.php` and
`/api/wishlist.php` still require one — those are for the browser and are
unchanged. The app should use `/api/v1/*` only.

---

## 11. Changed files

**New**

```
migration-mobile-api.sql      the api_tokens table
includes/api-auth.php         bearer tokens + cart/wishlist state
includes/customer-auth.php    customer accounts (register, login, profile, reset)
includes/order-service.php    shared order placement + cancellation
api/v1/index.php              router
api/v1/bootstrap.php          JSON errors, CORS, token resolution
api/v1/helpers.php            response envelope + JSON transformers
api/v1/routes/*.php           the endpoints
```

**Modified**

| File | Change |
|---|---|
| `.htaccess` | Route `/api/v1/*` to the front controller; preserve the `Authorization` header on PHP-CGI |
| `includes/bootstrap.php` | Load the three new files; exempt `/api/` from the HTML maintenance page |
| `checkout.php` | Order placement moved into `includes/order-service.php` — same behaviour, now shared with the API, and wrapped in a transaction so a mid-write failure can no longer leave a half-created order |

Nothing else on the website changed. Templates, styling, the admin panel and
all existing data are untouched.
