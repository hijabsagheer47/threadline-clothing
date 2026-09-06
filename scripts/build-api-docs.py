#!/usr/bin/env python3
"""
Build the API artefacts from one description of the customer API:

  api/v1/openapi.json                  OpenAPI 3 spec (served, and read by
                                       the Swagger UI page)
  Fashlab-API.postman_collection.json  Postman collection, derived from that
                                       same spec

...then check both against the routes actually registered in
api/v1/routes/*.php, and fail if they have drifted.

Hand-maintaining either one meant it went stale the moment an endpoint moved,
so neither is written by hand any more. Run this after changing routes:

    python3 scripts/build-api-docs.py
"""

import collections, glob, json, os, re, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SERVER = "https://fashlabstudio.mytechrcm.com/api/v1/index.php"

STR, INT, NUM, BOOL = ({"type": "string"}, {"type": "integer"},
                       {"type": "number"}, {"type": "boolean"})
NSTR = {"type": "string", "nullable": True}
REF = lambda n: {"$ref": "#/components/schemas/" + n}
ARR = lambda n: {"type": "array", "items": REF(n)}


def envelope(data=None, desc="Success"):
    return {"description": desc, "content": {"application/json": {"schema": {
        "type": "object",
        "properties": {
            "success": {"type": "boolean", "example": True},
            "message": NSTR,
            "data": data or {"type": "object", "nullable": True},
            "errors": {"type": "object", "additionalProperties": STR},
        }}}}}


def body(props, required=()):
    schema = {"type": "object", "properties": props}
    if required:
        schema["required"] = list(required)
    return {"required": True, "content": {"application/json": {"schema": schema}}}


def q(name, schema, desc="", **kw):
    return {"name": name, "in": "query", "schema": schema, "description": desc, **kw}


def path_param(name, desc="", schema=None):
    return {"name": name, "in": "path", "required": True,
            "schema": schema or STR, "description": desc}


schemas = {
    "ProductCard": {"type": "object", "properties": {
        "id": INT, "name": STR, "slug": STR, "sku": STR, "short_description": NSTR,
        "image": {"type": "string", "format": "uri"},
        "price": NUM, "sale_price": {"type": "number", "nullable": True}, "final_price": NUM,
        "on_sale": BOOL, "discount_percent": INT,
        "formatted_price": STR, "formatted_compare_at": NSTR, "currency": STR,
        "in_stock": BOOL, "stock_quantity": INT, "stock_status": STR,
        "rating": NUM, "rating_count": INT, "featured": BOOL,
        "badges": {"type": "array", "items": {"type": "object",
                                              "properties": {"label": STR, "type": STR}}},
        "category": NSTR, "colors": NSTR, "fabric": NSTR}},
    "ProductDetail": {"allOf": [REF("ProductCard"), {"type": "object", "properties": {
        "description": NSTR, "care_instructions": NSTR, "product_type": NSTR,
        "material": NSTR, "occasion": NSTR, "style": NSTR, "size": NSTR, "gender": NSTR,
        "tags": {"type": "array", "items": STR}, "video_url": NSTR,
        "images": {"type": "array", "items": {"type": "object", "properties": {
            "id": INT, "url": {"type": "string", "format": "uri"}, "is_primary": BOOL}}},
        "variant_groups": {"type": "array", "items": {"type": "object", "properties": {
            "name": STR,
            "options": {"type": "array", "items": {"type": "object", "properties": {
                "id": INT, "value": STR, "price_adjustment": NUM, "final_price": NUM,
                "stock_quantity": INT, "in_stock": BOOL, "sku": NSTR}}}}}},
        "categories": ARR("Category"),
        "share_url": {"type": "string", "format": "uri"}}}]},
    "Category": {"type": "object", "properties": {
        "id": INT, "parent_id": {"type": "integer", "nullable": True},
        "name": STR, "slug": STR, "description": NSTR,
        "image": {"type": "string", "format": "uri"},
        "product_count": {"type": "integer", "nullable": True}}},
    "Collection": {"type": "object", "properties": {
        "id": INT, "name": STR, "slug": STR, "type": NSTR, "description": NSTR,
        "image": {"type": "string", "format": "uri"},
        "banner": {"type": "string", "format": "uri"},
        "is_featured": BOOL, "product_count": {"type": "integer", "nullable": True}}},
    "CartLine": {"type": "object", "properties": {
        "key": dict(STR, example="92:0",
                    description="product:variant. Prefer the body forms of update/remove."),
        "product_id": INT, "variant_id": {"type": "integer", "nullable": True},
        "name": STR, "slug": STR, "image": {"type": "string", "format": "uri"},
        "variant_label": NSTR, "quantity": INT, "unit_price": NUM, "line_total": NUM,
        "formatted_unit_price": STR, "formatted_line_total": STR,
        "available": BOOL, "max_quantity": INT}},
    "Cart": {"type": "object", "properties": {
        "items": ARR("CartLine"),
        "coupon": {"type": "object", "nullable": True, "properties": {
            "code": STR, "discount": NUM, "formatted_discount": STR}},
        "totals": {"type": "object", "properties": {
            "subtotal": NUM, "shipping": NUM, "discount": NUM, "total": NUM,
            "formatted": {"type": "object", "properties": {
                "subtotal": STR, "shipping": STR, "discount": STR, "total": STR}}}},
        "summary": {"type": "object", "properties": {
            "line_count": INT, "item_count": INT, "has_unavailable": BOOL,
            "free_shipping_threshold": NUM, "amount_to_free_shipping": NUM}},
        "currency": STR}},
    "OrderSummary": {"type": "object", "properties": {
        "id": INT, "order_number": STR, "status": STR, "payment_status": STR,
        "payment_method": dict(STR, example="cod"),
        "total": NUM, "formatted_total": STR,
        "item_count": {"type": "integer", "nullable": True},
        "placed_at": STR, "placed_at_human": STR}},
    "OrderDetail": {"allOf": [REF("OrderSummary"), {"type": "object", "properties": {
        "customer": {"type": "object",
                     "description": "The details typed into the checkout form.",
                     "properties": {"name": STR, "email": STR, "phone": NSTR}},
        "shipping": {"type": "object", "properties": {
            "address": STR, "city": STR, "postal_code": STR, "country": STR,
            "method": NSTR, "tracking_number": NSTR, "delivery_estimate": NSTR}},
        "totals": {"type": "object", "properties": {
            "subtotal": NUM, "shipping": NUM, "discount": NUM, "tax": NUM, "total": NUM}},
        "coupon_code": NSTR, "notes": NSTR, "is_gift": BOOL,
        "items": {"type": "array", "items": {"type": "object", "properties": {
            "product_id": {"type": "integer", "nullable": True}, "name": STR,
            "variant_label": NSTR, "quantity": INT, "price": NUM, "subtotal": NUM,
            "image": {"type": "string", "format": "uri"}}}},
        "timeline": {"type": "array", "items": {"type": "object", "properties": {
            "status": STR, "label": STR, "note": NSTR, "created_at": STR, "human": STR}}},
        "flow": {"type": "array", "items": STR},
        "can_cancel": BOOL}}]},
    "Review": {"type": "object", "properties": {
        "id": INT, "name": STR, "rating": INT, "title": NSTR, "body": NSTR,
        "fit_feedback": NSTR, "verified": BOOL, "helpful_yes": INT,
        "created_at": STR, "human": STR,
        "images": {"type": "array", "items": {"type": "string", "format": "uri"}}}},
    "Meta": {"type": "object", "properties": {
        "page": INT, "per_page": INT, "total": INT, "pages": INT, "has_more": BOOL}},
}

paged = lambda ref: {"type": "object", "properties": {"items": ARR(ref), "meta": REF("Meta")}}

paths = collections.OrderedDict()


def op(method, path, tag, summary, description="", params=None, reqbody=None,
       data=None, responses=None):
    entry = paths.setdefault(path, {})
    o = {"tags": [tag], "summary": summary,
         "operationId": method.lower() + re.sub(r'[/{}]', '_', path),
         "responses": responses or {"200": envelope(data)}}
    if description: o["description"] = description
    if params: o["parameters"] = params
    if reqbody: o["requestBody"] = reqbody
    entry[method.lower()] = o


# -------------------------------------------------------------- Session
op("GET", "/health", "Session", "Connectivity check",
   "Confirms the API is installed and reachable.",
   data={"type": "object", "properties": {
       "status": STR, "api_version": STR, "store": STR, "server_time": STR}})

op("POST", "/session", "Session", "Get a device token",
   "**Call this on first launch and store the token.**\n\n"
   "This is not a login — there are no customer accounts. The token is an anonymous device "
   "identity that carries the cart and the wishlist between requests, because a phone has no "
   "session cookie.\n\n"
   "Safe to call on every launch: presented with a valid token it returns that same token "
   "rather than starting a new cart.",
   reqbody=body({"platform": dict(STR, example="android"),
                 "device_name": dict(STR, example="Pixel 8")}),
   data={"type": "object", "properties": {
       "token": STR, "is_new": BOOL, "cart_count": INT, "wishlist_count": INT}})

# -------------------------------------------------------------- Catalogue
op("GET", "/home", "Catalogue", "Everything the home screen needs",
   "One call for the whole home screen, so it paints in a single round trip.",
   data={"type": "object", "properties": {
       "announcement": STR,
       "hero_slides": {"type": "array", "items": {"type": "object", "properties": {
           "id": INT, "eyebrow": NSTR, "title": STR, "subtitle": NSTR,
           "image": {"type": "string", "format": "uri"},
           "cta_text": NSTR, "cta_link": NSTR}}},
       "categories": ARR("Category"), "collections": ARR("Collection"),
       "featured": ARR("ProductCard"), "new_arrivals": ARR("ProductCard"),
       "best_sellers": ARR("ProductCard"), "on_sale": ARR("ProductCard"),
       "testimonials": {"type": "array", "items": {"type": "object"}}}})

op("GET", "/products", "Catalogue", "Browse and search products",
   params=[q("q", STR, "Free text search"),
           q("category", STR, "Category slug or id"),
           q("collection", STR, "Collection slug or id"),
           q("sort", {"type": "string", "default": "newest",
                      "enum": ["newest", "featured", "best_selling",
                               "price_low", "price_high", "name"]}),
           q("price", {"type": "string",
                       "enum": ["under-5000", "5000-10000", "10000-15000", "over-15000"]},
             "Preset band. Overrides price_min / price_max."),
           q("price_min", NUM), q("price_max", NUM),
           q("fabric", STR, "Value from /filters"),
           q("color", STR, "Value from /filters"),
           q("size", STR, "Value from /filters"),
           q("availability", INT, "Any value = in stock only"),
           q("sale", INT, "Any value = on sale only"),
           q("featured", INT, "Any value = featured only"),
           q("page", {"type": "integer", "default": 1}),
           q("per_page", {"type": "integer", "default": 20, "maximum": 48})],
   data=paged("ProductCard"))

op("GET", "/products/{slug}", "Catalogue", "Product detail",
   "Accepts a slug or a numeric id. Also records the view and the recently-viewed entry.",
   params=[path_param("slug", "Product slug or id")],
   responses={"200": envelope({"type": "object", "properties": {
       "product": REF("ProductDetail"), "related": ARR("ProductCard"),
       "reviews": {"type": "object", "properties": {
           "summary": {"type": "object", "properties": {
               "avg": NUM, "count": INT, "breakdown": {"type": "object"}}},
           "items": ARR("Review")}},
       "size_chart": {"type": "array", "items": {"type": "object"}},
       "in_wishlist": BOOL}}),
       "404": envelope(None, "Product not found")})

op("GET", "/products/{slug}/reviews", "Catalogue", "Product reviews",
   params=[path_param("slug"), q("page", {"type": "integer", "default": 1}),
           q("per_page", {"type": "integer", "default": 20})],
   data=paged("Review"))

op("POST", "/products/{slug}/reviews", "Catalogue", "Submit a review",
   "Name and email are typed in by the reviewer, as there are no accounts. Reviews are held "
   "for moderation before they appear, exactly as on the website.",
   params=[path_param("slug")],
   reqbody=body({"rating": {"type": "integer", "minimum": 1, "maximum": 5},
                 "name": STR, "email": {"type": "string", "format": "email"},
                 "title": STR, "body": {"type": "string", "minLength": 10},
                 "fit_feedback": STR}, ("rating", "name", "email", "body")),
   responses={"201": envelope(None, "Submitted for moderation"),
              "422": envelope(None, "Validation failed")})

op("GET", "/categories", "Catalogue", "All categories",
   data={"type": "object", "properties": {"items": ARR("Category")}})
op("GET", "/categories/{slug}", "Catalogue", "Category detail",
   params=[path_param("slug")],
   data={"type": "object", "properties": {
       "category": REF("Category"), "children": ARR("Category")}})
op("GET", "/collections", "Catalogue", "All collections",
   data={"type": "object", "properties": {"items": ARR("Collection")}})
op("GET", "/collections/{slug}", "Catalogue", "Collection detail",
   params=[path_param("slug"), q("limit", {"type": "integer", "default": 24})],
   data={"type": "object", "properties": {
       "collection": REF("Collection"), "products": ARR("ProductCard")}})
op("GET", "/filters", "Catalogue", "Facets for the filter sheet",
   data={"type": "object", "properties": {
       "facets": {"type": "object", "properties": {
           "fabrics": {"type": "array", "items": STR},
           "colors": {"type": "array", "items": STR},
           "sizes": {"type": "array", "items": STR}}},
       "categories": ARR("Category"),
       "sorts": {"type": "array", "items": {"type": "object",
                                            "properties": {"value": STR, "label": STR}}},
       "price_presets": {"type": "array", "items": {"type": "object",
                                                    "properties": {"value": STR, "label": STR}}}}})
op("GET", "/search/suggest", "Catalogue", "Type-ahead suggestions",
   "Needs at least 2 characters; returns empty lists below that.",
   params=[q("q", STR, "Search text", required=True)],
   data={"type": "object", "properties": {
       "products": ARR("ProductCard"), "categories": ARR("Category"),
       "collections": ARR("Collection")}})
op("GET", "/search/trending", "Catalogue", "Trending searches",
   data={"type": "object", "properties": {"items": {"type": "array", "items": STR}}})
op("GET", "/recently-viewed", "Catalogue", "Recently viewed products",
   "Tracked per device token.",
   data={"type": "object", "properties": {"items": ARR("ProductCard")}})
op("GET", "/looks", "Catalogue", "Shop-the-look sets",
   data={"type": "object", "properties": {
       "items": {"type": "array", "items": {"type": "object"}}}})

# -------------------------------------------------------------- Cart
CART = {"200": envelope(REF("Cart"), "The complete cart")}
op("GET", "/cart", "Cart", "Get the cart", responses=CART)
op("GET", "/cart/count", "Cart", "Cart badge count",
   data={"type": "object", "properties": {"count": INT}})
op("POST", "/cart/items", "Cart", "Add an item",
   "Stock is checked server-side; an out-of-stock item is refused with 422.",
   reqbody=body({"product_id": INT, "variant_id": INT,
                 "quantity": {"type": "integer", "default": 1, "maximum": 99}},
                ("product_id",)),
   responses={"200": envelope(REF("Cart")),
              "422": envelope(None, "Out of stock or invalid product")})
op("PATCH", "/cart/items", "Cart", "Update quantity (preferred)",
   "Body form. Prefer this over the path form — a cart key contains a colon, which some "
   "clients and proxies mangle in a URL path.\n\nA quantity of 0 removes the line.",
   reqbody=body({"key": dict(STR, example="92:0"), "quantity": INT}, ("key", "quantity")),
   responses=CART)
op("PATCH", "/cart/items/{key}", "Cart", "Update quantity (path form)",
   "Percent-encode the colon: `92%3A0`.",
   params=[path_param("key", "Cart key, e.g. 92:0")],
   reqbody=body({"quantity": INT}, ("quantity",)), responses=CART)
op("POST", "/cart/items/remove", "Cart", "Remove an item (preferred)",
   reqbody=body({"key": dict(STR, example="92:0")}, ("key",)), responses=CART)
op("DELETE", "/cart/items/{key}", "Cart", "Remove an item (path form)",
   params=[path_param("key", "Cart key, percent-encoded")], responses=CART)
op("DELETE", "/cart", "Cart", "Empty the cart",
   "Also drops any applied coupon.", responses=CART)
op("POST", "/cart/coupon", "Cart", "Apply a coupon",
   "Validity, minimum order and usage limits are all checked server-side.\n\n"
   "`WELCOME10` in the example is a placeholder — replace it with a code that exists in "
   "Admin -> Coupons, or the response is a 422 saying the code is not valid.",
   reqbody=body({"code": dict(STR, example="WELCOME10")}, ("code",)),
   responses={"200": envelope(REF("Cart")),
              "422": envelope(None, "Coupon not valid for this cart")})
op("DELETE", "/cart/coupon", "Cart", "Remove the coupon", responses=CART)

# -------------------------------------------------------------- Wishlist
op("GET", "/wishlist", "Wishlist", "Saved products",
   "Held against the device token, like the website holds it against the session.",
   data={"type": "object", "properties": {"items": ARR("ProductCard"), "count": INT}})
op("GET", "/wishlist/count", "Wishlist", "Wishlist badge count",
   data={"type": "object", "properties": {"count": INT}})
op("GET", "/wishlist/ids", "Wishlist", "Saved product ids",
   "For painting heart icons across a product grid in one call.",
   data={"type": "object", "properties": {"ids": {"type": "array", "items": INT}}})
op("POST", "/wishlist", "Wishlist", "Save a product",
   "Idempotent — saving an item already on the list is not an error.",
   reqbody=body({"product_id": INT}, ("product_id",)),
   data={"type": "object", "properties": {"saved": BOOL, "count": INT}})
op("POST", "/wishlist/toggle", "Wishlist", "Toggle a product",
   reqbody=body({"product_id": INT}, ("product_id",)),
   data={"type": "object", "properties": {"saved": BOOL, "count": INT}})
op("DELETE", "/wishlist/{product_id}", "Wishlist", "Remove a product",
   params=[path_param("product_id", schema=INT)],
   data={"type": "object", "properties": {"saved": BOOL, "count": INT}})
op("POST", "/wishlist/move-to-cart", "Wishlist", "Move to cart",
   reqbody=body({"product_id": INT, "variant_id": INT, "quantity": INT}, ("product_id",)),
   data={"type": "object", "properties": {"cart": REF("Cart"), "wishlist_count": INT}})

# -------------------------------------------------------------- Orders
op("GET", "/checkout", "Checkout & Orders", "Everything the checkout screen needs",
   "Live totals, delivery options and the payment methods actually accepted.",
   data={"type": "object", "properties": {
       "cart": REF("Cart"),
       "delivery_options": {"type": "array", "items": {"type": "object", "properties": {
           "code": STR, "name": STR, "description": NSTR, "fee": NUM,
           "formatted_fee": STR, "estimated_days": NSTR}}},
       "payment_methods": {"type": "array", "items": {"type": "object", "properties": {
           "code": STR, "name": STR, "enabled": BOOL}}},
       "free_shipping_threshold": NUM}})

op("POST", "/orders", "Checkout & Orders", "Place an order",
   "Guest checkout, exactly like the website: fill in the form and order. There is no account.\n\n"
   "Prices, shipping and the coupon are recalculated server-side — anything the client sends "
   "about money is ignored.\n\n"
   "**Keep `order_number` from the response.** With no account, that number plus the email or "
   "phone is the only way back to the order.\n\n"
   "**Payment is Cash on Delivery only.** No gateway is connected, so a card order could never "
   "be settled.",
   reqbody=body({
       "name": STR, "email": {"type": "string", "format": "email"}, "phone": STR,
       "address": STR, "city": STR, "postal_code": STR, "notes": STR,
       "delivery": {"type": "string", "enum": ["standard", "express"], "default": "standard"},
       "country": dict(STR, default="Pakistan"),
       "is_gift": BOOL, "gift_message": STR},
       ("name", "email", "phone", "address", "city")),
   responses={"201": envelope({"type": "object", "properties": {
       "order": REF("OrderDetail"), "cart": REF("Cart")}}, "Order placed"),
       "422": envelope(None, "Validation failed, or the cart is empty / has unavailable items")})

op("POST", "/orders/track", "Checkout & Orders", "Track an order",
   "`contact` must be the email or phone used on the order. Requiring it is what stops an "
   "order number on its own from exposing someone's address.",
   reqbody=body({"order_number": STR,
                 "contact": dict(STR, description="Email or phone used on the order")},
                ("order_number", "contact")),
   responses={"200": envelope({"type": "object", "properties": {"order": REF("OrderDetail")}}),
              "404": envelope(None, "No order matches that number and contact")})

op("GET", "/orders/{order_number}", "Checkout & Orders", "Look up an order",
   "The same lookup as `/orders/track`, for deep links and for polling an order just placed. "
   "`contact` is required for the same reason.",
   params=[path_param("order_number"),
           q("contact", STR, "Email or phone used on the order", required=True)],
   responses={"200": envelope({"type": "object", "properties": {"order": REF("OrderDetail")}}),
              "404": envelope(None, "No order matches"),
              "422": envelope(None, "contact was not supplied")})

# -------------------------------------------------------------- Content
op("GET", "/settings", "Content", "Store configuration",
   "**Cache this on the device** and refresh on launch.",
   data={"type": "object", "properties": {
       "store": {"type": "object", "properties": {
           "name": STR, "tagline": STR, "email": STR, "phone": STR, "address": STR,
           "announcement": STR, "is_open": BOOL, "logo": STR, "website": STR}},
       "currency": {"type": "object", "properties": {"code": STR, "symbol": STR}},
       "shipping": {"type": "object", "properties": {
           "fee": NUM, "free_shipping_threshold": NUM, "min_order_amount": NUM}},
       "social": {"type": "object"},
       "support": {"type": "object", "properties": {
           "whatsapp_number": STR, "email": STR, "phone": STR}},
       "payment_methods": {"type": "array", "items": {"type": "object"}}}})
op("GET", "/menus", "Content", "Navigation menus",
   "The navigation the admin manages. Build the app drawer from this rather than hard-coding it.",
   data={"type": "object", "properties": {"menus": {"type": "object"}}})
op("GET", "/pages", "Content", "CMS pages index",
   data={"type": "object", "properties": {"items": {"type": "array", "items": {
       "type": "object", "properties": {"slug": STR, "title": STR}}}}})
op("GET", "/pages/{slug}", "Content", "CMS page", params=[path_param("slug")],
   data={"type": "object", "properties": {"page": {"type": "object", "properties": {
       "slug": STR, "title": STR, "content": STR, "updated_at": STR}}}})
op("GET", "/faqs", "Content", "FAQs grouped by category",
   data={"type": "object", "properties": {
       "items": {"type": "array", "items": {"type": "object"}}}})
op("GET", "/size-chart", "Content", "Size chart",
   data={"type": "object", "properties": {
       "measurements": {"type": "array", "items": {"type": "object"}}}})
op("GET", "/journal", "Content", "Journal posts",
   params=[q("page", {"type": "integer", "default": 1}),
           q("per_page", {"type": "integer", "default": 10}), q("category", STR)],
   data={"type": "object", "properties": {
       "items": {"type": "array", "items": {"type": "object"}}, "meta": REF("Meta")}})
op("GET", "/journal/{slug}", "Content", "Journal post", params=[path_param("slug")],
   data={"type": "object", "properties": {"post": {"type": "object"}}})
op("POST", "/newsletter", "Content", "Subscribe to the newsletter",
   reqbody=body({"email": {"type": "string", "format": "email"}}, ("email",)))
op("POST", "/contact", "Content", "Contact form",
   reqbody=body({"name": STR, "email": {"type": "string", "format": "email"},
                 "phone": STR, "subject": STR,
                 "message": {"type": "string", "minLength": 5}},
                ("name", "email", "message")))
op("POST", "/personal-shopper", "Content", "Personal shopper request",
   reqbody=body({"name": STR, "phone": STR, "email": STR, "occasion": STR, "budget": STR,
                 "preferred_style": STR, "preferred_color": STR, "preferred_size": STR,
                 "message": STR}, ("name", "phone")))

spec = {
    "openapi": "3.0.3",
    "info": {
        "title": "Fashlab Studio — Customer API",
        "version": "2.0.0",
        "description": (
            "Customer-side REST API for the Fashlab Studio mobile app.\n\n"
            "### There are no customer accounts\n"
            "The app mirrors the website: a visitor browses, fills in the checkout form and "
            "orders as a guest. There is no registration, no sign-in and no order history. "
            "The only login anywhere is the admin panel on the website, which this API does "
            "not expose.\n\n"
            "An order is reached afterwards by its **order number plus the email or phone used "
            "on it** — `/orders/track` — which is what the site's track-order page does.\n\n"
            "### Start here\n"
            "1. **POST `/session`** — returns a device token. It is not a credential; it just "
            "carries the cart and wishlist, because a phone has no session cookie. Click "
            "**Authorize** above and paste it in.\n"
            "2. Browse `/home` and `/products`, add to `/cart`, save to `/wishlist`.\n"
            "3. **POST `/orders`** with the form fields to place the order.\n\n"
            "If a request arrives with no token, or a stale one, a fresh token is issued and "
            "returned in the **`X-Api-Token`** response header — read that header on every "
            "response and replace your stored token when it differs.\n\n"
            "### Every response has the same shape\n"
            "```json\n"
            "{ \"success\": true, \"message\": null, \"data\": { }, \"errors\": { } }\n"
            "```\n"
            "Branch on `success`, show `message` to the customer, and map `errors` "
            "(`{\"field\": \"message\"}`) straight onto form validators on a 422.\n\n"
            "### Base URL\n"
            "This webspace applies mod_rewrite patterns but drops the substitution — the same "
            "reason the storefront serves `/product.php?slug=…` instead of pretty permalinks — "
            "so the API routes on `PATH_INFO` and the base URL ends in `/index.php`. "
            "`…/index.php?_route=products` works too, and needs no server support at all.\n\n"
            "### Notes\n"
            "- Prices come back pre-formatted (`\"Rs. 6,050\"`); the app does no money maths.\n"
            "- Image URLs are absolute.\n"
            "- Payment is **Cash on Delivery only** — no gateway is connected.\n"
            "- If a host strips `Authorization`, send the token in `X-Api-Token` instead.\n"
            "- No CSRF token is needed."
        ),
    },
    "servers": [{"url": SERVER, "description": "Live"}],
    "tags": [
        {"name": "Session", "description": "The anonymous device token — not a login"},
        {"name": "Catalogue", "description": "Home, products, categories, collections, search"},
        {"name": "Cart", "description": "Cart lines and coupons — every call returns the whole cart"},
        {"name": "Wishlist", "description": "Saved products, held against the device token"},
        {"name": "Checkout & Orders", "description": "Guest checkout and order tracking"},
        {"name": "Content", "description": "Store settings, menus, pages, FAQs, journal"},
    ],
    "components": {
        "securitySchemes": {"bearerAuth": {
            "type": "http", "scheme": "bearer",
            "description": "The device token from POST /session."}},
        "schemas": schemas,
    },
    "security": [{"bearerAuth": []}],
    "paths": paths,
}

spec_path = os.path.join(ROOT, "api/v1/openapi.json")
with open(spec_path, "w") as f:
    json.dump(spec, f, indent=2)


# ============================================================================
# POSTMAN COLLECTION, derived from the spec above
# ============================================================================

# A path parameter's meaning depends on the endpoint, not just its name: the
# "slug" in /products/{slug} and /categories/{slug} are different things, so
# each one gets its own collection variable rather than sharing "productSlug".
PATH_VARS = {
    "/products/{slug}":                {"slug": "{{productSlug}}"},
    "/products/{slug}/reviews":        {"slug": "{{productSlug}}"},
    "/categories/{slug}":              {"slug": "{{categorySlug}}"},
    "/collections/{slug}":             {"slug": "{{collectionSlug}}"},
    "/pages/{slug}":                   {"slug": "{{pageSlug}}"},
    "/journal/{slug}":                 {"slug": "{{journalSlug}}"},
    "/orders/{order_number}":          {"order_number": "{{orderNumber}}"},
    "/wishlist/{product_id}":          {"product_id": "{{productId}}"},
    # The cart-key path form needs the colon percent-encoded, which a variable
    # cannot carry cleanly; the body form alongside it uses the raw {{cartKey}}.
    "/cart/items/{key}":               {"key": "92%3A0"},
}

# Seeded values so the collection answers on the first send, before any
# chaining has run. They are overwritten by the test script as soon as the
# matching list endpoint is called.
VAR_DEFAULTS = {
    "baseUrl":        SERVER,
    "token":          "",
    # A product that is actually in stock, so "add to cart" works on the first
    # send rather than answering "out of stock".
    "productSlug":    "hania-eastern-angrakha",
    "productId":      "92",
    "categorySlug":   "stitched",
    "collectionSlug": "signature-collection",
    "pageSlug":       "shipping-policy",
    "journalSlug":    "",
    "cartKey":        "92:0",
    "orderNumber":    "",
}

# Readable stand-ins, so a request can be sent as-is and get a real response.
FIELD_EXAMPLES = {
    "name": "Ayesha Khan", "email": "ayesha@example.com", "phone": "03001234567",
    "address": "House 12, Street 4, DHA Phase 5", "city": "Karachi",
    "postal_code": "75500", "country": "Pakistan", "notes": "Please call before delivery",
    "message": "Do you ship to Quetta?", "subject": "Question",
    "title": "Beautiful", "body": "The fabric and fit are lovely.",
    "code": "WELCOME10", "contact": "ayesha@example.com",
    "order_number": "{{orderNumber}}", "key": "{{cartKey}}",
    "product_id": "{{productId}}", "quantity": 2, "rating": 5,
    "device_name": "Pixel 8", "platform": "android",
    "occasion": "Wedding", "budget": "20000-30000",
    "gift_message": "Happy birthday!",
    "q": "lawn", "category": "stitched", "collection": "signature-collection",
    "fabric": "Premium lawn fabric", "color": "Blush Pink",
    "reason": "Changed my mind",
}


def example_for(field, schema):
    """A sendable value for one field, or None when there is nothing sensible."""
    # The curated list wins over the schema's own example, because several of
    # these are {{variables}} that make the requests chain -- and where they are
    # not, the two agree anyway.
    if field in FIELD_EXAMPLES:
        return FIELD_EXAMPLES[field]
    if "example" in schema:
        return schema["example"]
    if "default" in schema:
        return schema["default"]
    if "enum" in schema:
        return schema["enum"][0]
    if schema.get("format") == "email":
        return "ayesha@example.com"

    t = schema.get("type")
    if t == "boolean":
        return False
    if t == "string":
        return ""
    # An invented integer id (a variant, say) would just make the request fail,
    # so leave it out rather than guess.
    return None


def postman_request(method, path, operation):
    raw_path = path
    for name, value in PATH_VARS.get(path, {}).items():
        raw_path = raw_path.replace("{%s}" % name, value)

    params = operation.get("parameters", [])
    query = [p for p in params if p.get("in") == "query"]

    url = {
        "raw": "{{baseUrl}}" + raw_path,
        "host": ["{{baseUrl}}"],
        "path": [s for s in raw_path.strip("/").split("/") if s],
    }

    if query:
        entries = []
        for p in query:
            value = example_for(p["name"], p.get("schema", {}))
            entry = {"key": p["name"], "value": "" if value is None else str(value),
                     "description": p.get("description", "")}
            # Optional filters ship disabled: visible in Postman for discovery,
            # but not silently narrowing the first response someone sends.
            if not p.get("required") and "default" not in p.get("schema", {}):
                entry["disabled"] = True
            entries.append(entry)
        url["query"] = entries
        enabled = [e for e in entries if not e.get("disabled")]
        if enabled:
            url["raw"] += "?" + "&".join("%s=%s" % (e["key"], e["value"]) for e in enabled)

    request = {
        "method": method.upper(),
        "header": [],
        "url": url,
        "description": operation.get("description", operation.get("summary", "")),
    }

    schema = (operation.get("requestBody", {})
                       .get("content", {})
                       .get("application/json", {})
                       .get("schema"))
    if schema:
        props = schema.get("properties", {})
        required = schema.get("required", [])
        # Required fields first: that is the order someone reads them in.
        ordered = ([k for k in props if k in required]
                   + [k for k in props if k not in required])
        payload = {}
        for k in ordered:
            value = example_for(k, props[k])
            # Required fields always ship, even if only as a blank to fill in.
            if value is None:
                if k not in required:
                    continue
                value = ""
            payload[k] = value
        raw = json.dumps(payload, indent=2)
        # A {{variable}} standing in for a number has to go into the JSON
        # unquoted, or the body advertises a string where the schema says
        # integer. Postman substitutes the raw text, so dropping the quotes is
        # all it takes.
        for key, value in payload.items():
            if (props[key].get("type") in ("integer", "number")
                    and isinstance(value, str) and value.startswith("{{")):
                raw = raw.replace('"%s": "%s"' % (key, value), '"%s": %s' % (key, value))

        request["header"] = [{"key": "Content-Type", "value": "application/json"}]
        request["body"] = {"mode": "raw", "raw": raw,
                           "options": {"raw": {"language": "json"}}}

    return {"name": operation.get("summary", method + " " + path), "request": request}


# Spec order is grouped by resource, which puts DELETE /cart before the request
# that fills the cart -- fine to read, useless to run. These folders get an
# explicit lifecycle instead, so "Run folder" works top to bottom. Anything not
# listed keeps spec order, after the listed ones.
FOLDER_ORDER = {
    "Cart": [
        ("post", "/cart/items"),
        ("get", "/cart"),
        ("get", "/cart/count"),
        ("patch", "/cart/items"),
        ("patch", "/cart/items/{key}"),
        ("post", "/cart/coupon"),
        ("delete", "/cart/coupon"),
        ("post", "/cart/items/remove"),
        ("delete", "/cart/items/{key}"),
        ("delete", "/cart"),
    ],
    "Wishlist": [
        ("post", "/wishlist"),
        ("get", "/wishlist"),
        ("get", "/wishlist/count"),
        ("get", "/wishlist/ids"),
        ("post", "/wishlist/toggle"),
        ("post", "/wishlist/move-to-cart"),
        ("delete", "/wishlist/{product_id}"),
    ],
    "Catalogue": [
        # List first: it fills productSlug for the detail requests below.
        ("get", "/home"),
        ("get", "/products"),
        ("get", "/products/{slug}"),
    ],
}

by_tag = collections.OrderedDict((t["name"], []) for t in spec["tags"])
for path, methods in spec["paths"].items():
    for method, operation in methods.items():
        if method not in ("get", "post", "put", "patch", "delete"):
            continue
        tag = (operation.get("tags") or ["Other"])[0]
        by_tag.setdefault(tag, []).append((method, path, operation))

for tag, entries in by_tag.items():
    order = FOLDER_ORDER.get(tag, [])
    def rank(entry, order=order):
        key = (entry[0], entry[1])
        return order.index(key) if key in order else len(order)
    entries.sort(key=rank)  # stable: unlisted keep spec order
    by_tag[tag] = [postman_request(m, p, op) for m, p, op in entries]

collection = {
    "info": {
        "name": "Fashlab Studio — Customer API v1",
        "description": (
            spec["info"]["description"]
            + "\n\n---\n\n**Using this collection:** run **Session → Get a device token** "
              "first. Its response is saved into the `token` variable and every other request "
              "picks it up automatically. Listing products, categories, collections, pages or "
              "the journal fills that list's own slug variable; adding to the cart fills "
              "`cartKey`; placing an order fills `orderNumber` — so the requests chain without "
              "copying values by hand. The variables also ship with working defaults, so any "
              "request answers on the first send.\n\n"
              "Optional query filters ship **disabled** — tick them in Postman's Params tab to "
              "use them.\n\n"
            + "_Generated by scripts/build-api-docs.py — do not edit by hand._"
        ),
        "schema": "https://schema.getpostman.com/json/collection/v2.1.0/collection.json",
    },
    "auth": {"type": "bearer",
             "bearer": [{"key": "token", "value": "{{token}}", "type": "string"}]},
    "event": [{"listen": "test", "script": {"type": "text/javascript", "exec": [
        "// The API re-issues a token whenever the one sent is missing or stale,",
        "// and returns it in X-Api-Token. Keep ours in step.",
        "const issued = pm.response.headers.get('X-Api-Token');",
        "if (issued) { pm.collectionVariables.set('token', issued); }",
        "",
        "let body;",
        "try { body = pm.response.json(); } catch (e) { body = null; }",
        "if (!body || !body.data) { return; }",
        "",
        "const d = body.data;",
        "if (d.token) { pm.collectionVariables.set('token', d.token); }",
        "if (d.product && d.product.slug) { pm.collectionVariables.set('productSlug', d.product.slug); }",
        "if (d.order && d.order.order_number) { pm.collectionVariables.set('orderNumber', d.order.order_number); }",
        "",
        "// A 'slug' means something different per endpoint, so key off the path",
        "// rather than writing every list's first slug into productSlug.",
        "const path = pm.request.url.getPath();",
        "const SLUG_VARS = {",
        "    '/products': 'productSlug',",
        "    '/categories': 'categorySlug',",
        "    '/collections': 'collectionSlug',",
        "    '/pages': 'pageSlug',",
        "    '/journal': 'journalSlug',",
        "};",
        "",
        "if (Array.isArray(d.items) && d.items.length) {",
        "    // Prefer something in stock, so the cart requests below work on",
        "    // the first run instead of hitting a sold-out item.",
        "    const first = d.items.find(function (i) { return i.in_stock; }) || d.items[0];",
        "    if (first.key) { pm.collectionVariables.set('cartKey', first.key); }",
        "    if (first.id && path.endsWith('/products')) {",
        "        pm.collectionVariables.set('productId', String(first.id));",
        "    }",
        "    if (first.slug) {",
        "        for (const [suffix, variable] of Object.entries(SLUG_VARS)) {",
        "            if (path.endsWith(suffix)) {",
        "                pm.collectionVariables.set(variable, first.slug);",
        "                break;",
        "            }",
        "        }",
        "    }",
        "}",
    ]}}],
    "variable": [{"key": k, "value": v} for k, v in VAR_DEFAULTS.items()],
    "item": [{"name": tag, "item": items} for tag, items in by_tag.items() if items],
}

collection_path = os.path.join(ROOT, "Fashlab-API.postman_collection.json")
with open(collection_path, "w") as f:
    json.dump(collection, f, indent=2)


# ---- check both artefacts against the routes actually registered -----------
declared = set()
for f in glob.glob(os.path.join(ROOT, "api/v1/routes/*.php")):
    for m in re.finditer(r"route\('([A-Z]+)',\s*'([^']+)'", open(f).read()):
        declared.add((m.group(1), m.group(2)))

documented = {(m.upper(), p) for p, v in paths.items()
              for m in v if m in ("get", "post", "put", "patch", "delete")}

missing = declared - documented
extra = documented - declared
refs = set(re.findall(r'"#/components/schemas/([A-Za-z]+)"', json.dumps(spec)))
unresolved = refs - set(schemas)

# The collection is derived from the spec, so it can only drift if the
# generator above drops something -- check it the same way.
def route_shape(path):
    return "/".join("{x}" if s.startswith("{") else s
                    for s in path.strip("/").split("/"))

declared_shapes = {(m, route_shape(p)) for m, p in declared}
collected = set()
for folder in collection["item"]:
    for item in folder["item"]:
        raw = item["request"]["url"]["raw"].replace("{{baseUrl}}", "").split("?")[0]
        segments = raw.strip("/").split("/")
        # A concrete value stands in for a path parameter, so try every
        # combination of literal and placeholder to find the route it maps to.
        options = {""}
        for seg in segments:
            options = {(prefix + "/" + part).lstrip("/")
                       for prefix in options for part in (seg, "{x}")}
        hit = next((o for o in options
                    if (item["request"]["method"], o) in declared_shapes), None)
        if hit:
            collected.add((item["request"]["method"], hit))

uncollected = declared_shapes - collected

print("routes in code:      %d" % len(declared))
print("operations in spec:  %d" % len(documented))
print("requests in Postman: %d" % sum(len(f["item"]) for f in collection["item"]))
if missing:      print("UNDOCUMENTED:", sorted(missing))
if extra:        print("DOCUMENTED BUT MISSING FROM CODE:", sorted(extra))
if unresolved:   print("UNRESOLVED $refs:", sorted(unresolved))
if uncollected:  print("MISSING FROM THE POSTMAN COLLECTION:", sorted(uncollected))
if missing or extra or unresolved or uncollected:
    sys.exit(1)

print()
print("both match the code exactly:")
print("  " + spec_path)
print("  " + collection_path)
