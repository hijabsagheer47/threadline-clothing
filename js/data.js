/* ============================================================
   RESHAM HOUSE — seed data
   Generates simple SVG "swatch" artwork for demo dresses so the
   catalogue has something to show before a real photo is uploaded.
   Real products added through admin.html store actual uploaded
   photos (as data URLs) in localStorage instead.
   ============================================================ */

const CATEGORIES = ["Stitched", "Unstitched", "Western", "Eastern"];
const COLLECTION_GROUPS = [
  {
    label: "Unstitched",
    items: [
      { label: "View All Unstitched", href: "https://pk.sapphireonline.pk/collections/unstitched" },
      { label: "Shop By Collection", isHeading: true },
      { label: "Intermix '26", href: "https://pk.sapphireonline.pk/collections/uns-intermix-26" },
      { label: "Lawn '26", href: "https://pk.sapphireonline.pk/collections/unstitched-lawn" },
      { label: "Shop By Concept", isHeading: true },
      { label: "Sukoon", href: "https://pk.sapphireonline.pk/collections/sukoon" },
      { label: "Andaaz", href: "https://pk.sapphireonline.pk/collections/andaaz" },
      { label: "Raunak", href: "https://pk.sapphireonline.pk/collections/raunak" },
      { label: "Shop By Piece", isHeading: true },
      { label: "1 Piece", href: "https://pk.sapphireonline.pk/collections/one-piece-unstitched" },
      { label: "2 Piece", href: "https://pk.sapphireonline.pk/collections/two-piece-unstitched" },
      { label: "3 Piece", href: "https://pk.sapphireonline.pk/collections/three-piece-unstitched" },
      { label: "CATALOGUE", isHeading: true },
      { label: "Intermix '26 - New Arrivals", href: "https://pk.sapphireonline.pk/pages/unstitched-intermix-26-catalogue.html" },
      { label: "Fabric Glossary", href: "https://pk.sapphireonline.pk/pages/woman-fabric-glossary.html" }
    ]
  },
  {
    label: "Western",
    items: [
      { label: "View All WEST", href: "https://pk.sapphireonline.pk/collections/western-wear" },
      { label: "Shop By Collection", isHeading: true },
      { label: "Summer '26", href: "https://pk.sapphireonline.pk/collections/west-summer-26" },
      { label: "Shop By Product", isHeading: true },
      { label: "TOPS | SHIRTS", href: "https://pk.sapphireonline.pk/collections/women-tops" },
      { label: "Dresses", href: "https://pk.sapphireonline.pk/collections/dresses" },
      { label: "Co-ord Sets", href: "https://pk.sapphireonline.pk/collections/co-ord-sets" },
      { label: "TROUSERS | SKIRTS", href: "https://pk.sapphireonline.pk/collections/west-womens-bottoms" },
      { label: "Jeans", href: "https://pk.sapphireonline.pk/collections/jeans" },
      { label: "Essentials", href: "https://pk.sapphireonline.pk/collections/essentials" },
      { label: "SCARVES", href: "https://pk.sapphireonline.pk/collections/accessories-scarves" },
      { label: "Featured", isHeading: true },
      { label: "Denim Fit Guide", href: "https://pk.sapphireonline.pk/pages/the-denim-fit-guide.html" }
    ]
  },
  {
    label: "Modest Wear",
    items: [
      { label: "View All Modest Wear", href: "https://pk.sapphireonline.pk/collections/modest-wear" },
      { label: "Abayas", href: "https://pk.sapphireonline.pk/collections/abayas" },
      { label: "Hijabs", href: "https://pk.sapphireonline.pk/collections/hijabs" },
      { label: "Co-ord Sets", href: "https://pk.sapphireonline.pk/collections/modest-co-ords-sets" }
    ]
  },
  {
    label: "Ready to Wear",
    items: [
      { label: "View All Ready to Wear", href: "https://pk.sapphireonline.pk/collections/ready-to-wear" },
      { label: "Shop By Collection", isHeading: true },
      { label: "Intermix '26", href: "https://pk.sapphireonline.pk/collections/rtw-intermix-26" },
      { label: "Lawn '26", href: "https://pk.sapphireonline.pk/collections/ready-to-wear-lawn" },
      { label: "Shop By Type", isHeading: true },
      { label: "Casual", href: "https://pk.sapphireonline.pk/collections/rtw-casual" },
      { label: "Smart Casual", href: "https://pk.sapphireonline.pk/collections/rtw-smart-casual" },
      { label: "Formal", href: "https://pk.sapphireonline.pk/collections/rtw-formal" },
      { label: "Fusion", href: "https://pk.sapphireonline.pk/collections/rtw-fusion" },
      { label: "Shop By Product", isHeading: true },
      { label: "Shirts", href: "https://pk.sapphireonline.pk/collections/rtw-shirts" },
      { label: "Dupattas", href: "https://pk.sapphireonline.pk/collections/dupattas-shawls" },
      { label: "Bottoms", href: "https://pk.sapphireonline.pk/collections/rtw-bottoms" },
      { label: "Outfits", href: "https://pk.sapphireonline.pk/collections/ready-to-wear-outfits" },
      { label: "Matching Separates", href: "https://pk.sapphireonline.pk/collections/matching-separates" }
    ]
  },
  {
    label: "New In",
    items: [
      { label: "View All New In", href: "https://pk.sapphireonline.pk/collections/new-arrivals" },
      { label: "Intermix '26", href: "https://pk.sapphireonline.pk/collections/uns-intermix-26" },
      { label: "Summer '26", href: "https://pk.sapphireonline.pk/collections/west-summer-26" },
      { label: "Lawn '26", href: "https://pk.sapphireonline.pk/collections/ready-to-wear-lawn" }
    ]
  }
];

globalThis.CATEGORIES = CATEGORIES;
globalThis.COLLECTION_GROUPS = COLLECTION_GROUPS;

function swatchSVG(bg, bg2, label){
  return `data:image/svg+xml;utf8,${encodeURIComponent(`
  <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 480 640">
    <defs>
      <linearGradient id="g" x1="0" y1="0" x2="1" y2="1">
        <stop offset="0" stop-color="${bg}"/>
        <stop offset="1" stop-color="${bg2}"/>
      </linearGradient>
    </defs>
    <rect width="480" height="640" fill="url(#g)"/>
    <g opacity="0.5" stroke="#F6EFE4" stroke-width="1.4" fill="none">
      <path d="M240 90 C170 120 160 210 160 260 L150 560 L330 560 L320 260 C320 210 310 120 240 90 Z"/>
      <path d="M240 90 C210 100 190 130 185 165"/>
      <path d="M240 90 C270 100 290 130 295 165"/>
      <line x1="160" y1="330" x2="320" y2="330"/>
    </g>
    <text x="240" y="600" font-family="Georgia, serif" font-size="22" fill="#F6EFE4" text-anchor="middle" opacity="0.85">${label}</text>
  </svg>`)}`;
}

/* Seed catalogue: name, price (PKR), category, details, 3-4 images */
const PHOTO_POOL = [
  "https://images.unsplash.com/photo-1529139574466-a303027c1d8b?auto=format&fit=crop&w=900&q=80",
  "https://images.unsplash.com/photo-1483985988355-763728e1935b?auto=format&fit=crop&w=900&q=80",
  "https://images.unsplash.com/photo-1524504388940-b1c1722653e1?auto=format&fit=crop&w=900&q=80",
  "https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?auto=format&fit=crop&w=900&q=80",
  "https://images.unsplash.com/photo-1521572267360-ee0c2909d518?auto=format&fit=crop&w=900&q=80",
  "https://images.unsplash.com/photo-1487412720507-e7ab37603c6f?auto=format&fit=crop&w=900&q=80",
  "https://images.unsplash.com/photo-1496747611176-843222e1e57c?auto=format&fit=crop&w=900&q=80",
  "https://images.unsplash.com/photo-1523381210434-271e8be1f52b?auto=format&fit=crop&w=900&q=80",
  "https://images.unsplash.com/photo-1524504388940-b1c1722653e1?auto=format&fit=crop&w=900&q=80",
  "https://images.unsplash.com/photo-1524504388940-b1c1722653e1?auto=format&fit=crop&w=900&q=80"
];

function buildImages(seedIndex, categoryName) {
  const base = PHOTO_POOL;
  const offset = (seedIndex * 3) % base.length;
  const chosen = [
    base[(offset + 0) % base.length],
    base[(offset + 1) % base.length],
    base[(offset + 2) % base.length],
    base[(offset + 4) % base.length]
  ];

  if (categoryName === "Western") {
    return chosen.slice(0, 4);
  }

  return chosen.slice(0, 3);
}

const STITCHED_ITEMS = [
  { name: "Areeba Floral Lawn Set", price: 7400, fabric: "Lawn, Chiffon", sizes: "S · M · L · XL", details: "Soft pastel lawn set with delicate floral print, fitted shirt, straight trouser and coordinated chiffon dupatta." },
  { name: "Nisha Printed Lawn Kurta", price: 6900, fabric: "Lawn", sizes: "S · M · L · XL", details: "Classic lawn kurta with refined block print, side slits, and a flattering straight silhouette for everyday elegance." },
  { name: "Hiba Cotton Shirt Set", price: 8300, fabric: "Cotton", sizes: "S · M · L · XL", details: "Easy cotton shirt set with a polished collar, comfortable fit and soft texture for daily wear." },
  { name: "Sana Formal Linen Ensemble", price: 11200, fabric: "Linen blend", sizes: "XS · S · M · L", details: "Linen-blend stitched set with a clean tailored finish, made for polished daytime looks and smart casual styling." },
  { name: "Alina Pastel Chiffon Three Piece", price: 9600, fabric: "Chiffon", sizes: "S · M · L · XL", details: "Airy chiffon set with soft pastel tones, fluttering dupatta and modern cut designed for festive elegance." },
  { name: "Noor Festive Cotton Suit", price: 10150, fabric: "Cotton, net dupatta", sizes: "S · M · L · XL", details: "Festive cotton suit with subtle detailing and polished silhouette, ideal for semi-formal occasions and family gatherings." },
  { name: "Zareen Embroidered Suit", price: 8900, fabric: "Lawn, Net dupatta", sizes: "S · M · L · XL", details: "Three-piece stitched suit in chikankari embroidery on lawn, with dyed trouser and matching net dupatta. Fully finished and ready to wear." },
  { name: "Mira Khaddar Suit", price: 6200, fabric: "Khaddar, Shawl", sizes: "S · M · L · XL", details: "Winter khaddar three-piece with a soft texture, block print and shawl finish for cold-weather styling." },
  { name: "Rida Cotton Kurta Set", price: 7800, fabric: "Cotton", sizes: "S · M · L · XL", details: "Classic stitched cotton kurta with straight lines and relaxed comfort for everyday elegance." },
  { name: "Maham Printed Lawn Suit", price: 8100, fabric: "Lawn", sizes: "S · M · L · XL", details: "Printed lawn suit with an easy drape and soft finish, ideal for brunches, errands and light events." },
  { name: "Saira Chikankari Set", price: 9300, fabric: "Lawn, net dupatta", sizes: "S · M · L · XL", details: "Threadwork details on the front panel give this stitched set a premium traditional finish." },
  { name: "Farah Minimal Kurta", price: 7600, fabric: "Lawn", sizes: "S · M · L · XL", details: "Minimalist stitched kurta with clean finishes and a modest yet contemporary cut." },
  { name: "Tania Soft Silk Set", price: 14500, fabric: "Silk blend", sizes: "S · M · L · XL", details: "Soft silk stitched ensemble with graceful movement and polished occasion styling." },
  { name: "Hira Printed Cotton Kurta", price: 8500, fabric: "Cotton, chiffon dupatta", sizes: "S · M · L · XL", details: "This cotton kurta is airy, comfortable and designed in a minimal floral print." },
  { name: "Kiran Bordered Lawn Set", price: 8750, fabric: "Lawn, bordered dupatta", sizes: "S · M · L · XL", details: "Fresh lawn outfit with bordered detailing, refined trim and effortless festive charm." },
  { name: "Ansa Casual Stitched Suit", price: 7900, fabric: "Cotton lawn", sizes: "S · M · L · XL", details: "A comfortable stitched suit with a relaxed shape and minimal detailing for casual styling." },
  { name: "Hania Everyday Lawn Set", price: 7200, fabric: "Lawn", sizes: "S · M · L · XL", details: "Easy everyday lawn set designed for all-day comfort while keeping a polished silhouette." },
  { name: "Mila Festive Cotton Set", price: 9800, fabric: "Cotton, dupatta", sizes: "S · M · L · XL", details: "Festive woven cotton style with a soft texture and a polished stitched finish." },
  { name: "Aiza Soft Drape Suit", price: 10450, fabric: "Cotton chiffon", sizes: "S · M · L · XL", details: "A flowy stitched set with a soft drape and dressy finish for elevated casual wear." },
  { name: "Yumna Embellished Kurta", price: 11900, fabric: "Cotton silk", sizes: "S · M · L · XL", details: "Subtle embellishment along the neckline and front panel brings a premium look to this shirt set." },
  { name: "Ayesha Classic Lawn Suit", price: 7900, fabric: "Lawn", sizes: "S · M · L · XL", details: "A clean and classic stitched lawn suit with a timeless look for daily wear and gatherings." },
  { name: "Rimsha Cotton Festive Set", price: 9800, fabric: "Cotton", sizes: "S · M · L · XL", details: "A refined festive set with polished tailoring and easy styling for family events." },
  { name: "Nadia Printed Shirt Set", price: 8700, fabric: "Lawn, chiffon dupatta", sizes: "S · M · L · XL", details: "Printed shirt set with soft movement and a minimal design that works for both day and evening occasions." },
  { name: "Sana Grace Kurta Set", price: 10100, fabric: "Lawn, net dupatta", sizes: "S · M · L · XL", details: "Graceful lounge-to-event kurta set with soft detailing and neat stitching throughout." },
  { name: "Sahar Floral Chiffon Set", price: 11800, fabric: "Chiffon", sizes: "S · M · L · XL", details: "Floral chiffon styling with a graceful silhouette and lightweight comfort for events." },
  { name: "Maryam Luxe Lawn Set", price: 12400, fabric: "Lawn, silk dupatta", sizes: "S · M · L · XL", details: "Elevated lawn set with refined textures and premium finishing for special gatherings." },
  { name: "Emaan Everyday Stitched Set", price: 7350, fabric: "Cotton", sizes: "S · M · L · XL", details: "Lightweight stitched set for easy daywear, combining comfort with a neat tailored finish." },
  { name: "Zoya Flow Kurta Set", price: 10900, fabric: "Cotton silk", sizes: "S · M · L · XL", details: "Soft drape and neat finishing make this set easy to style for formal or semi-formal settings." },
  { name: "Mahira Soft Printed Set", price: 8400, fabric: "Lawn", sizes: "S · M · L · XL", details: "A minimal printed set with a soft hand feel and very easy styling across the year." },
  { name: "Samiya Classic Shirt Suit", price: 9150, fabric: "Cotton weave", sizes: "S · M · L · XL", details: "Polished cotton shirt suit with everyday polish and a crisp silhouette." }
];

const UNSTITCHED_ITEMS = [
  { name: "Aisha Soft Cotton Lawn", price: 5000, fabric: "Lawn", sizes: "Unstitched — one size", details: "Lightweight unstitched lawn set for warm weather dressing, with soft texture and easy tailoring options." },
  { name: "Meher Printed Chiffon Set", price: 6100, fabric: "Chiffon", sizes: "Unstitched — one size", details: "Rich printed chiffon set with feminine drape and refined finishing, excellent for custom tailoring." },
  { name: "Fizza Summer Floral Unstitched", price: 5600, fabric: "Cotton lawn", sizes: "Unstitched — one size", details: "Summer floral unstitched purchase with breezy fabric and a flattering, easy-to-style silhouette." },
  { name: "Zara Premium Lawn 3 Piece", price: 5800, fabric: "Premium lawn", sizes: "Unstitched — one size", details: "Premium lawn three-piece set with classic floral artwork and a crisp, tailored finish when stitched." },
  { name: "Mariam Embroidered Unstitched", price: 6800, fabric: "Lawn, dupatta", sizes: "Unstitched — one size", details: "Elegant embroidered set with a soft hand feel and rich detailing suited for festive, family, and event styling." },
  { name: "Sheza Classic Karandi Set", price: 6200, fabric: "Karandi, shawl", sizes: "Unstitched — one size", details: "Classic karandi unstitched set with understated styling and versatile tailoring options for every season." },
  { name: "Sahil Printed Lawn", price: 4500, fabric: "Lawn, Chiffon dupatta", sizes: "Unstitched — one size", details: "Three-piece unstitched printed lawn set with floral detail and a soft border finish." },
  { name: "Sana Karandi Unstitched Set", price: 5200, fabric: "Karandi, Shawl", sizes: "Unstitched — one size", details: "Winter karandi unstitched three-piece with embroidered neckline patch, straight trouser and printed shawl." },
  { name: "Maham Pastel Lawn Set", price: 5400, fabric: "Lawn", sizes: "Unstitched — one size", details: "Subtle pastel lawn set with a light print and soft drape for a chic custom finish." },
  { name: "Rida Floral Chiffon Set", price: 6400, fabric: "Chiffon", sizes: "Unstitched — one size", details: "Printed chiffon set with an elegant fall and ample room for a tailored custom fit." },
  { name: "Areeba Cotton Printed Set", price: 5100, fabric: "Cotton lawn", sizes: "Unstitched — one size", details: "A breathable and easy-to-style unstitched set in a classic cotton lawn finish." },
  { name: "Noor Multicolor Lawn Set", price: 5900, fabric: "Lawn, chiffon dupatta", sizes: "Unstitched — one size", details: "A bright and lively lawn set that allows custom styling with a playful summer mood." },
  { name: "Hania Garden Print Set", price: 5700, fabric: "Lawn", sizes: "Unstitched — one size", details: "Garden print styling with a soft fabric feel and effortless tailoring options." },
  { name: "Maryam Premium Karandi", price: 6600, fabric: "Karandi, shawl", sizes: "Unstitched — one size", details: "A premium karandi set with refined texture and a classic silhouette for custom tailoring." },
  { name: "Ayesha Printed Dupatta Set", price: 6300, fabric: "Lawn, dupatta", sizes: "Unstitched — one size", details: "A crisp printed set with soft tailoring potential and a feminine, modern finish." },
  { name: "Fariha Soft Chiffon Set", price: 6500, fabric: "Chiffon", sizes: "Unstitched — one size", details: "Premium chiffon styling with an airy feel and enough body for custom-stitched results." },
  { name: "Hira Classic 3 Piece", price: 6100, fabric: "Lawn", sizes: "Unstitched — one size", details: "Classic 3-piece lawn set with a neat cut and a smooth, breezy drape for summer styling." },
  { name: "Nadia Printed Lawn", price: 5500, fabric: "Printed lawn", sizes: "Unstitched — one size", details: "A feminine printed lawn purchase with a comfortable balance between softness and structure." },
  { name: "Sahar Tie-Dye Lawn Set", price: 5900, fabric: "Lawn", sizes: "Unstitched — one size", details: "Tie-dye inspired lawn set with fresh colour play and a relaxed tailored finish." },
  { name: "Areej Minimal Lawn", price: 5200, fabric: "Lawn", sizes: "Unstitched — one size", details: "Minimal printed lawn set with a subtle palette and an easy, wearable custom silhouette." },
  { name: "Hina Cotton Festive Set", price: 7000, fabric: "Cotton lawn", sizes: "Unstitched — one size", details: "A festive unstitched set with soft texture and stylable drape for event wear." },
  { name: "Sana Bloom Lawn Set", price: 5900, fabric: "Lawn", sizes: "Unstitched — one size", details: "Bloom-inspired printed lawn set in soft earthy tones for modern tailoring." },
  { name: "Mira Textured Lawn", price: 6200, fabric: "Lawn", sizes: "Unstitched — one size", details: "Textured lawn with a soft touch and a modern feel that works beautifully when stitched." },
  { name: "Ansa Stripe Lawn Set", price: 5600, fabric: "Lawn", sizes: "Unstitched — one size", details: "Minimal stripe detailing gives this unstitched set a cleaner, more polished look." },
  { name: "Zainab Soft Floral Set", price: 6700, fabric: "Cotton lawn", sizes: "Unstitched — one size", details: "Soft floral theme and comfortable hand feel give this fabric set a relaxed luxury finish." },
  { name: "Aiza Printed Lawn Duo", price: 6000, fabric: "Lawn", sizes: "Unstitched — one size", details: "Printed lawn duo in a modern palette that suits versatile custom styling." },
  { name: "Rimsha Daily Lawn Set", price: 5300, fabric: "Lawn, chiffon dupatta", sizes: "Unstitched — one size", details: "A practical and pretty daily lawn set for comfortable custom wear and easy styling." },
  { name: "Faryal Luxe Printed Lawn", price: 7200, fabric: "Premium lawn", sizes: "Unstitched — one size", details: "Luxury lawn set with premium fall, crisp tailoring potential and an elevated print palette." },
  { name: "Maryam Cotton Bloom Set", price: 6800, fabric: "Cotton lawn", sizes: "Unstitched — one size", details: "Cotton bloom set that offers chic tailoring flexibility with a soft, comfortable finish." },
  { name: "Kiran Modern Lawn Pack", price: 6100, fabric: "Lawn", sizes: "Unstitched — one size", details: "Modern lawn design with a subtle print and elegant resilience for season-long styling." }
];

const WESTERN_ITEMS = [
  { name: "Noor Tailored Blazer Dress", price: 12500, fabric: "Crepe, fully lined", sizes: "XS · S · M · L", details: "Structured tailored blazer dress in crepe, single-breasted with belted waist. Fully lined, finished with statement buttons." },
  { name: "Elan Wide-Leg Trouser Set", price: 9800, fabric: "Linen blend", sizes: "XS · S · M · L", details: "Two-piece western set with cropped tailored top and high-waist wide-leg trousers in a soft linen blend." },
  { name: "Rida Linen Co-ord Set", price: 13600, fabric: "Linen blend", sizes: "XS · S · M · L", details: "Modern linen co-ord set with tailored lines, warm neutrals and a relaxed premium feel." },
  { name: "Zara Structured Satin Dress", price: 14800, fabric: "Satin", sizes: "XS · S · M · L", details: "Satin dress with structured fit and elegant drape, styled for evening events and modern festive occasions." },
  { name: "Hania Pleated Midi Dress", price: 14300, fabric: "Viscose blend", sizes: "XS · S · M · L", details: "Pleated midi dress with soft waistline and casual luxury feel, ideal for day-to-night styling." },
  { name: "Iman Oversized Button Shirt", price: 9800, fabric: "Cotton twill", sizes: "XS · S · M · L", details: "Oversized button-down shirt in premium fabric, giving a sharp, elevated look with easy layering potential." },
  { name: "Ayesha Denim Co-ord", price: 15700, fabric: "Denim", sizes: "S · M · L · XL", details: "Relaxed denim co-ord in a modern silhouette, styled for polished casual wear with a subtle luxe finish." },
  { name: "Nadia Structured Mini Dress", price: 12900, fabric: "Cotton blend", sizes: "XS · S · M · L", details: "Minimal structured mini dress with polished lines and quick, effortless styling." },
  { name: "Sana Relaxed Blazer Set", price: 14700, fabric: "Wool blend", sizes: "XS · S · M · L", details: "Soft blazer and trouser pairing with a minimalist form and elevated office-to-evening appeal." },
  { name: "Fahra Satin Slip Dress", price: 15300, fabric: "Satin", sizes: "XS · S · M · L", details: "Silky slip dress with a flattering drape, designed for sleek evenings and special occasions." },
  { name: "Mia Wide-Leg Trousers", price: 10600, fabric: "Cotton twill", sizes: "XS · S · M · L", details: "High-waist wide-leg trousers with a modern drape and clean finish for chic everyday wear." },
  { name: "Ira Cashmere Knit Set", price: 16800, fabric: "Cashmere blend", sizes: "XS · S · M · L", details: "Soft knit pairing with a premium feel, designed for elevated comfort and understated elegance." },
  { name: "Anaya Pleated Skirt Set", price: 13800, fabric: "Viscose", sizes: "XS · S · M · L", details: "Pleated skirt and matching knit top combination for a polished day-to-night look." },
  { name: "Emaan White Linen Shirt", price: 9700, fabric: "Linen", sizes: "XS · S · M · L", details: "Lightweight linen shirt cut with a clean drape and effortless summer layering potential." },
  { name: "Zoya Tailored Pant Suit", price: 16900, fabric: "Cotton twill", sizes: "XS · S · M · L", details: "Structured pant suit with a sharp silhouette and elevated tailoring for smart occasions." },
  { name: "Maryam Knit Polo Dress", price: 12100, fabric: "Cotton knit", sizes: "XS · S · M · L", details: "A lightweight knit dress with a fitted top and streamlined skirt for refined casual styling." },
  { name: "Hira Layered Co-ord", price: 14200, fabric: "Cotton blend", sizes: "XS · S · M · L", details: "Layered co-ord with a relaxed silhouette and premium-feel fabric for easy daywear dressing." },
  { name: "Sofia Pleated Jumpsuit", price: 15900, fabric: "Crepe", sizes: "XS · S · M · L", details: "Classic jumpsuit with pleated detailing and a flattering fitted waist for occasion dressing." },
  { name: "Rania Smart Casual Set", price: 13700, fabric: "Linen blend", sizes: "XS · S · M · L", details: "Smart casual pairing with a breathable texture and modern structure for daily dressing." },
  { name: "Aisha Monochrome Co-ord", price: 13400, fabric: "Cotton blend", sizes: "XS · S · M · L", details: "Minimal monochrome co-ord delivering a sleek and elegant look with easy layering." },
  { name: "Mahir Cotton Shirt Dress", price: 12600, fabric: "Cotton satin", sizes: "XS · S · M · L", details: "Classic shirt dress with soft structure and an elevated feel for city-day styling." },
  { name: "Nisa Belted Midi Dress", price: 14500, fabric: "Crepe", sizes: "XS · S · M · L", details: "Belted midi dress for a structured waistline and clean feminine silhouette." },
  { name: "Farah Relaxed Twill Suit", price: 14700, fabric: "Twill", sizes: "XS · S · M · L", details: "Relaxed twill suit balancing clean lines with comfort and premium polish." },
  { name: "Rimsha Lounge Dress", price: 12800, fabric: "Viscose", sizes: "XS · S · M · L", details: "Lounge-inspired dress with smooth fabric and a gentle elegance for off-duty styling." },
  { name: "Areeba Longline Blazer", price: 15100, fabric: "Woven blend", sizes: "XS · S · M · L", details: "Longline blazer in a soft neutral palette, designed for polish and versatility." },
  { name: "Sahar Utility Co-ord", price: 13600, fabric: "Cotton twill", sizes: "XS · S · M · L", details: "Utility-inspired co-ord with understated detailing and a strong modern identity." },
  { name: "Hira Soft Knit Dress", price: 11900, fabric: "Knit blend", sizes: "XS · S · M · L", details: "Soft knit dress with a flattering drop and comfortable movement for everyday occasions." },
  { name: "Leena Professional Set", price: 16000, fabric: "Cotton blend", sizes: "XS · S · M · L", details: "Streamlined professional set with a luxe finish suitable for meetings and events." },
  { name: "Aiza Neutral Shirtdress", price: 12200, fabric: "Linen blend", sizes: "XS · S · M · L", details: "Neutral shirtdress with tailored collar and soft movement for elevated daily dressing." },
  { name: "Rida Tailored Skirt Set", price: 13900, fabric: "Crepe", sizes: "XS · S · M · L", details: "Tailored skirt set delivering a clean line and elegant structure in a modern palette." }
];

const EASTERN_ITEMS = [
  { name: "Anaya Bridal Eastern Ensemble", price: 42000, fabric: "Raw silk, hand embellished", sizes: "Made to order", details: "Heavy hand-embellished eastern ensemble in raw silk with gown, dupatta and matching trouser." },
  { name: "Hania Eastern Angrakha", price: 15800, fabric: "Organza, Gota lace", sizes: "S · M · L", details: "Stitched angrakha-style eastern kurta in organza with gota lace, paired with cigarette trouser and dupatta." },
  { name: "Mahnoor Gota Work Kurta", price: 11800, fabric: "Silk blend, gota work", sizes: "S · M · L · XL", details: "Festive gota work kurta in a flattering silhouette, paired with soft trousers and lightweight dupatta for special events." },
  { name: "Rania Embroidered Sharara", price: 16800, fabric: "Silk blend, embroidery", sizes: "S · M · L · XL", details: "Statement sharara set with rich embroidery, flared silhouette and coordinated dupatta for occasion dressing." },
  { name: "Faryal Net Dupatta Set", price: 13400, fabric: "Net, chiffon", sizes: "S · M · L · XL", details: "Soft net dupatta set with elegant fall, decorative border and refined festive finish perfect for occasion wear." },
  { name: "Aisha Silk Festive Suit", price: 17100, fabric: "Silk blend", sizes: "S · M · L · XL", details: "Silk festive suit designed with elegant tailored cut, soft sheen and celebratory styling for premium occasions." },
  { name: "Maham Modern Eastern Set", price: 15400, fabric: "Cotton silk, dupatta", sizes: "S · M · L · XL", details: "Polished eastern set with contemporary proportions, subtle embellishment and soft pastel finish." },
  { name: "Sadia Embroidered Gown", price: 18400, fabric: "Silk blend, hand work", sizes: "S · M · L · XL", details: "A graceful eastern gown with bridal-inspired embroidery and fluid movement for memorable events." },
  { name: "Nisha Festive Kurta Set", price: 12700, fabric: "Cotton silk", sizes: "S · M · L · XL", details: "A refined festive set combining soft texture, gentle structure and elegant eastern styling." },
  { name: "Areeba Traditional Chiffon Set", price: 11900, fabric: "Chiffon, dupatta", sizes: "S · M · L · XL", details: "Traditional styling softened with chiffon texture and a comfortable festive drape." },
  { name: "Hira Organza Angrakha", price: 16200, fabric: "Organza, lace", sizes: "S · M · L · XL", details: "Light organza angrakha with delicate lace detailing and a graceful event-ready silhouette." },
  { name: "Maryam Pastel Eastern Set", price: 14100, fabric: "Cotton silk", sizes: "S · M · L · XL", details: "Pastel eastern ensemble polished for daytime gatherings, family events and soft festive styling." },
  { name: "Alina Gharara Set", price: 17200, fabric: "Silk blend", sizes: "S · M · L · XL", details: "Gharara-inspired eastern set with flowy structure and premium finishing for occasion wear." },
  { name: "Rida Festive Kurta Pant", price: 13800, fabric: "Cotton silk", sizes: "S · M · L · XL", details: "Relaxed kurta and pant pairing designed for a clean eastern silhouette with festive polish." },
  { name: "Maham Silk Dupatta Set", price: 15900, fabric: "Silk blend, dupatta", sizes: "S · M · L · XL", details: "Statement eastern set with matching silk dupatta and refined shimmers for special events." },
  { name: "Zoya Rose Gold Set", price: 17600, fabric: "Silk blend", sizes: "S · M · L · XL", details: "Rose-toned eastern outfit with subtle shimmer and soft tailoring to suit premium rituals." },
  { name: "Hania Bridal Chiffon Set", price: 18700, fabric: "Chiffon, net dupatta", sizes: "S · M · L · XL", details: "A graceful bridal-inspired eastern set with delicate layering and event-ready elegance." },
  { name: "Aisha Printed Eastern Suit", price: 12400, fabric: "Lawn, chiffon dupatta", sizes: "S · M · L · XL", details: "Printed eastern suit made for an easy, modern festive fit with soft movement and clean lines." },
  { name: "Nadia Formal Eastern Set", price: 14900, fabric: "Silk blend", sizes: "S · M · L · XL", details: "Formal eastern set with a sharper silhouette and premium fabric treatment for elegant styling." },
  { name: "Mila Embroidered Kurta", price: 15300, fabric: "Cotton silk, embroidery", sizes: "S · M · L · XL", details: "Classic kurta with embroidery details and a balanced eastern cut designed for satin-smooth elegance." },
  { name: "Sahar Georgette Set", price: 14800, fabric: "Georgette", sizes: "S · M · L · XL", details: "Georgette eastern set with soft flow and a polished finish for elegant dinners and functions." },
  { name: "Fiza Pearled Dupatta Set", price: 15800, fabric: "Silk blend, net dupatta", sizes: "S · M · L · XL", details: "Pearled detail and flowing dupatta give this eastern styling a celebratory and luxurious feel." },
  { name: "Areej Satin Kurta Set", price: 16900, fabric: "Satin", sizes: "S · M · L · XL", details: "Smooth satin eastern set with a chic silhouette and premium satin sheen for evening elegance." },
  { name: "Yumna Chiffon Festive Set", price: 13700, fabric: "Chiffon", sizes: "S · M · L · XL", details: "A festive chiffon set with easy tailoring, graceful drape and modern eastern finish." },
  { name: "Sana Lace Eastern Set", price: 16100, fabric: "Organza, lace", sizes: "S · M · L · XL", details: "A refined lace detailing eastern set with soft structure and special-event brightness." },
  { name: "Fariha Silk Gown", price: 17900, fabric: "Silk blend", sizes: "S · M · L · XL", details: "Gown-inspired eastern piece with premium texture and strong event appeal in a fluid silhouette." },
  { name: "Emaan Embellished Shalwar", price: 14600, fabric: "Silk blend", sizes: "S · M · L · XL", details: "Embellished eastern shalwar and kurta styling with a fluid cut and refined finish." },
  { name: "Rimsha Party Eastern Suit", price: 15200, fabric: "Cotton silk", sizes: "S · M · L · XL", details: "Party-ready eastern suit with soft pastel palette, elegant drape and balanced modern proportions." },
  { name: "Aiza Luxe Eastern Set", price: 17300, fabric: "Silk blend, net dupatta", sizes: "S · M · L · XL", details: "Luxe eastern styling with elegant layers and a refined premium look for festive dressing." },
  { name: "Hira Velvet Eastern Set", price: 18100, fabric: "Velvet blend", sizes: "S · M · L · XL", details: "Velvet eastern set with rich depth and warmth designed for winter parties and formal events." }
];

const SEED_PRODUCTS = [
  ...STITCHED_ITEMS.map((item, index) => ({
    id: `seed-${index + 1}`,
    category: "Stitched",
    ...item,
    images: buildImages(index, "Stitched")
  })),
  ...UNSTITCHED_ITEMS.map((item, index) => ({
    id: `seed-${STITCHED_ITEMS.length + index + 1}`,
    category: "Unstitched",
    ...item,
    images: buildImages(index + STITCHED_ITEMS.length, "Unstitched")
  })),
  ...WESTERN_ITEMS.map((item, index) => ({
    id: `seed-${STITCHED_ITEMS.length + UNSTITCHED_ITEMS.length + index + 1}`,
    category: "Western",
    ...item,
    images: buildImages(index + STITCHED_ITEMS.length + UNSTITCHED_ITEMS.length, "Western")
  })),
  ...EASTERN_ITEMS.map((item, index) => ({
    id: `seed-${STITCHED_ITEMS.length + UNSTITCHED_ITEMS.length + WESTERN_ITEMS.length + index + 1}`,
    category: "Eastern",
    ...item,
    images: buildImages(index + STITCHED_ITEMS.length + UNSTITCHED_ITEMS.length + WESTERN_ITEMS.length, "Eastern")
  }))
];

globalThis.SEED_PRODUCTS = SEED_PRODUCTS;
