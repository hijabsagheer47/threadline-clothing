# Threadline — Clothing Brand Website

A complete, responsive storefront for a clothing brand, covering **Stitched**,
**Unstitched**, **Western**, and **Eastern** wear.

## How to open it

No build step, no server required — it's plain HTML/CSS/JS.

1. Unzip the folder.
2. Double-click `index.html` (or right-click → Open with your browser).
3. To browse it like a real site with clean links, you can also serve it
   locally, e.g. from inside the folder: `python3 -m http.server 8000`,
   then visit `http://localhost:8000`.

## Pages

| File | Purpose |
|---|---|
| `index.html` | Homepage — hero, category tiles, recently-added dresses |
| `shop.html` | Full catalogue with category filter tabs + search |
| `product.html?id=...` | Single dress: 3–4 photo gallery, price, fabric, sizes, details |
| `admin.html` | **Upload panel** — post a new dress (name, price, category, details, 3–4 photos) and remove existing listings |
| `about.html` | Brand story |
| `contact.html` | Contact details + enquiry form |

## How "posting a dress" works

`admin.html` is the upload panel. Fill in the name, price, category,
fabric/sizes and details, then click each of the 4 photo boxes to choose a
picture (at least 3 are required, the 4th is optional). On submit, the dress
is saved to the browser's `localStorage` and immediately appears in
`shop.html`, on the homepage, and gets its own `product.html` detail page
with a full photo gallery.

This is a genuine, working front-end feature — photos are read straight from
your device using the browser's File API and stored as the dress's images.
The catalogue also ships with 8 demo dresses (two per category) so the shop
isn't empty on first load; those use simple colour-swatch placeholder
graphics in place of real product photography.

**Note on storage:** since this is a static front-end site with no backend
database, uploaded dresses are stored in that specific browser's
`localStorage`. They'll stay there across visits on the same device/browser,
but won't sync to other visitors or other devices. To make listings visible
to everyone (a real multi-user storefront), the `addProduct` /
`loadProducts` functions in `js/main.js` are the place to swap `localStorage`
calls for real API calls to a backend (Node/Express + a database, Firebase,
etc.) — the rest of the site (rendering, filtering, the gallery) already
expects that same product shape and needs no other changes.

## Project structure

```
threadline-clothing-website/
├── index.html
├── shop.html
├── product.html
├── admin.html
├── about.html
├── contact.html
├── css/
│   └── style.css
└── js/
    ├── data.js     ← seed/demo products + placeholder artwork generator
    └── main.js     ← storage (localStorage), rendering helpers, nav
```

## Design

- Palette: deep maroon, muted gold, warm ivory, charcoal ink.
- Type: Cormorant Garamond (display) + Jost (body/UI), via Google Fonts.
- Fully responsive: nav collapses to a mobile menu, grids reflow down to a
  single column, the product gallery stacks on small screens.

## Customising

- Edit brand name, phone, address and footer text directly in each HTML
  file's header/footer (repeated per page since this is a static site).
- Edit or remove the demo dresses in `js/data.js` (`SEED_PRODUCTS`).
- Colours and fonts are CSS variables at the top of `css/style.css`
  (`:root { --maroon: ...; --font-display: ...; }`).
