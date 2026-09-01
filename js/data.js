/* ============================================================
   THREADLINE — PRODUCT DATA
   30 dresses are available in each category:
   Stitched, Unstitched, Western, Eastern
   ============================================================ */

const CATEGORIES = ["Stitched", "Unstitched", "Western", "Eastern"];

globalThis.CATEGORIES = CATEGORIES;


/* ============================================================
   ARTWORK ENGINE
   Every single dress gets its own hand-drawn-style SVG artwork —
   a unique pastel palette + a silhouette that matches its
   category, so no two products (and no two categories) ever
   share the same picture. Swap these for real photography any
   time by editing a product's `images` array in the console.
   ============================================================ */

// 30 distinct, pretty pastel duos — one reserved per item in a category
const PALETTE = [
  ["#FBE4EC", "#F3B6C9"], ["#FFEFE3", "#F6C9A0"], ["#EAF1FF", "#B9D2F5"],
  ["#F1E9FF", "#CDB4F0"], ["#E7F7EE", "#A9DFC0"], ["#FFF3E0", "#F8CBA6"],
  ["#FDEBEF", "#E9A7BE"], ["#EAF6F6", "#A9D7D6"], ["#FFF0F5", "#F0B9CE"],
  ["#F4F0FF", "#C6B6EE"], ["#FFF7E0", "#F3D98B"], ["#E9F3FF", "#A9C8ED"],
  ["#FCEAE2", "#EAAE93"], ["#EFF7E4", "#BBD98C"], ["#FDE9F3", "#E39FC4"],
  ["#E6F5F0", "#93D2BA"], ["#FFF1E6", "#F4B98A"], ["#EDEBFF", "#B7ADEE"],
  ["#FFEAEA", "#F0A6A6"], ["#EAF4FB", "#9FCBE8"], ["#F6EDFB", "#D2A6E8"],
  ["#EFFAE8", "#A6D28A"], ["#FFF2EF", "#F2A98F"], ["#E8F1F8", "#A3BEDB"],
  ["#FDF0DE", "#E9B36E"], ["#F4EEFA", "#C09EDD"], ["#E6FAF5", "#84D3B8"],
  ["#FFEFF6", "#E893B7"], ["#F0F6FF", "#9BB8E8"], ["#FBEFE0", "#E0A467"]
];

const ACCENT = {
  Stitched: "#7A2E3B",
  Unstitched: "#8A6C38",
  Western: "#3C4A63",
  Eastern: "#6E3B7A"
};

function svgWrap(inner, viewBox) {
  const svg = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="${viewBox}">${inner}</svg>`;
  return "data:image/svg+xml;utf8," + encodeURIComponent(svg);
}

function softBg(a, b, angle, id) {
  return `
    <defs>
      <linearGradient id="g${id}" x1="0" y1="0" x2="${angle}" y2="1">
        <stop offset="0" stop-color="${a}"/>
        <stop offset="1" stop-color="${b}"/>
      </linearGradient>
    </defs>
    <rect width="100%" height="100%" fill="url(#g${id})"/>
    <circle cx="60" cy="70" r="140" fill="#ffffff" opacity="0.14"/>
    <circle cx="480" cy="560" r="180" fill="#ffffff" opacity="0.10"/>
  `;
}

// category silhouettes, drawn around a 300x520 figure box centred at x=300
function silhouette(category, ink, flipped, scale) {
  const t = flipped ? `translate(600,0) scale(-1,1)` : "";
  const s = `translate(300,0) scale(${scale})`;
  const shapes = {
    Stitched: `
      <path d="M0,-170 C-50,-150 -66,-110 -70,-70 L-96,260 L96,260 L70,-70
                C66,-110 50,-150 0,-170 Z" fill="none" stroke="${ink}" stroke-width="3"/>
      <path d="M0,-170 C-30,-150 -46,-120 -50,-90" fill="none" stroke="${ink}" stroke-width="2.4"/>
      <path d="M0,-170 C30,-150 46,-120 50,-90" fill="none" stroke="${ink}" stroke-width="2.4"/>
      <path d="M-70,-40 C-140,10 -150,90 -130,150" fill="none" stroke="${ink}" stroke-width="2" opacity="0.7"/>
      <path d="M70,-40 C140,10 150,90 130,150" fill="none" stroke="${ink}" stroke-width="2" opacity="0.7"/>
      <line x1="-52" y1="10" x2="52" y2="10" stroke="${ink}" stroke-width="1.4" opacity="0.5"/>
    `,
    Unstitched: `
      <g stroke="${ink}" stroke-width="2.6" fill="none">
        <rect x="-120" y="-140" width="240" height="60" rx="6"/>
        <rect x="-120" y="-70" width="240" height="60" rx="6" opacity="0.85"/>
        <rect x="-120" y="0" width="240" height="60" rx="6" opacity="0.7"/>
        <rect x="-120" y="70" width="240" height="60" rx="6" opacity="0.55"/>
      </g>
      <circle cx="96" cy="-150" r="16" fill="none" stroke="${ink}" stroke-width="2.4"/>
      <line x1="96" y1="-166" x2="96" y2="-134" stroke="${ink}" stroke-width="1.6"/>
    `,
    Western: `
      <path d="M0,-170 C-40,-160 -46,-120 -40,-90 C-90,-40 -80,120 -60,230
                L60,230 C80,120 90,-40 40,-90 C46,-120 40,-160 0,-170 Z"
            fill="none" stroke="${ink}" stroke-width="3"/>
      <path d="M-40,-90 C-8,-70 8,-70 40,-90" fill="none" stroke="${ink}" stroke-width="2.2"/>
      <line x1="-52" y1="30" x2="52" y2="30" stroke="${ink}" stroke-width="1.4" opacity="0.55"/>
      <line x1="-58" y1="90" x2="58" y2="90" stroke="${ink}" stroke-width="1.4" opacity="0.4"/>
    `,
    Eastern: `
      <path d="M0,-170 C-46,-150 -60,-110 -56,-70 C-130,10 -170,150 -150,260
                L150,260 C170,150 130,10 56,-70 C60,-110 46,-150 0,-170 Z"
            fill="none" stroke="${ink}" stroke-width="3"/>
      <path d="M0,-170 C-26,-150 -40,-120 -44,-95" fill="none" stroke="${ink}" stroke-width="2.2"/>
      <path d="M0,-170 C26,-150 40,-120 44,-95" fill="none" stroke="${ink}" stroke-width="2.2"/>
      <g fill="${ink}" opacity="0.55">
        <circle cx="-60" cy="150" r="3.4"/><circle cx="-20" cy="170" r="3.4"/>
        <circle cx="20" cy="170" r="3.4"/><circle cx="60" cy="150" r="3.4"/>
        <circle cx="-90" cy="200" r="3.4"/><circle cx="90" cy="200" r="3.4"/>
      </g>
      <path d="M-56,-70 C-110,-40 -70,10 -20,-10" fill="none" stroke="${ink}" stroke-width="1.6" opacity="0.6"/>
    `
  };
  return `<g transform="${t}"><g transform="${s}">${shapes[category] || shapes.Stitched}</g></g>`;
}

function frame(ink) {
  return `<rect x="14" y="14" width="572" height="572" fill="none" stroke="${ink}" stroke-width="1.2" opacity="0.35"/>`;
}

// three distinct, coordinated views for one product: front, detail/back, flat-lay
function buildImages(index, category, name) {
  const paletteIndex = index % PALETTE.length;
  const [a, b] = PALETTE[paletteIndex];
  const ink = ACCENT[category] || "#5a4d46";
  const seed = `${category}-${index}`;
  const box = "0 0 600 600";

  const front =
    softBg(a, b, 1, seed + "f") +
    `<g transform="translate(0,60)">${silhouette(category, ink, false, 1.12)}</g>` +
    frame(ink);

  const detail =
    softBg(b, a, 0.4, seed + "d") +
    `<g transform="translate(40,30)">${silhouette(category, ink, true, 1.5)}</g>` +
    frame(ink);

  const flat =
    softBg(a, b, 1.6, seed + "l") +
    `<g transform="translate(0,90) rotate(-6)">${silhouette(category, ink, false, 0.92)}</g>` +
    frame(ink);

  return [svgWrap(front, box), svgWrap(detail, box), svgWrap(flat, box)];
}


/* ============================================================
   STITCHED — 35 PRODUCTS
   ============================================================ */

const STITCHED_ITEMS = [

  {
    name: "Areeba Floral Lawn Set",
    price: 7400,
    fabric: "Lawn, Chiffon",
    sizes: "S · M · L · XL",
    details: "Soft pastel lawn set with delicate floral print, fitted shirt, straight trouser and coordinated chiffon dupatta."
  },

  {
    name: "Nisha Printed Lawn Kurta",
    price: 6900,
    fabric: "Lawn",
    sizes: "S · M · L · XL",
    details: "Classic lawn kurta with refined block print and a flattering straight silhouette."
  },

  {
    name: "Hiba Cotton Shirt Set",
    price: 8300,
    fabric: "Cotton",
    sizes: "S · M · L · XL",
    details: "Easy cotton shirt set with polished collar and comfortable fit."
  },

  {
    name: "Sana Formal Linen Ensemble",
    price: 11200,
    fabric: "Linen blend",
    sizes: "XS · S · M · L",
    details: "Linen blend stitched set with clean tailored finishing."
  },

  {
    name: "Alina Pastel Chiffon Three Piece",
    price: 9600,
    fabric: "Chiffon",
    sizes: "S · M · L · XL",
    details: "Airy chiffon three-piece set with soft pastel tones."
  },

  {
    name: "Noor Festive Cotton Suit",
    price: 10150,
    fabric: "Cotton, Net Dupatta",
    sizes: "S · M · L · XL",
    details: "Festive cotton suit with subtle detailing and polished silhouette."
  },

  {
    name: "Zareen Embroidered Suit",
    price: 8900,
    fabric: "Lawn, Net Dupatta",
    sizes: "S · M · L · XL",
    details: "Three-piece stitched suit with delicate embroidery."
  },

  {
    name: "Mira Khaddar Suit",
    price: 6200,
    fabric: "Khaddar, Shawl",
    sizes: "S · M · L · XL",
    details: "Winter khaddar three-piece with soft texture and printed shawl."
  },

  {
    name: "Rida Cotton Kurta Set",
    price: 7800,
    fabric: "Cotton",
    sizes: "S · M · L · XL",
    details: "Classic stitched cotton kurta with relaxed comfort."
  },

  {
    name: "Maham Printed Lawn Suit",
    price: 8100,
    fabric: "Lawn",
    sizes: "S · M · L · XL",
    details: "Printed lawn suit with easy drape and soft finish."
  },

  {
    name: "Saira Chikankari Set",
    price: 9300,
    fabric: "Lawn, Net Dupatta",
    sizes: "S · M · L · XL",
    details: "Threadwork details give this stitched set a premium traditional finish."
  },

  {
    name: "Farah Minimal Kurta",
    price: 7600,
    fabric: "Lawn",
    sizes: "S · M · L · XL",
    details: "Minimalist stitched kurta with clean finishing."
  },

  {
    name: "Tania Soft Silk Set",
    price: 14500,
    fabric: "Silk Blend",
    sizes: "S · M · L · XL",
    details: "Soft silk stitched ensemble with graceful movement."
  },

  {
    name: "Hira Printed Cotton Kurta",
    price: 8500,
    fabric: "Cotton, Chiffon Dupatta",
    sizes: "S · M · L · XL",
    details: "Airy cotton kurta designed in a minimal floral print."
  },

  {
    name: "Kiran Bordered Lawn Set",
    price: 8750,
    fabric: "Lawn, Bordered Dupatta",
    sizes: "S · M · L · XL",
    details: "Fresh lawn outfit with bordered detailing."
  },

  {
    name: "Ansa Casual Stitched Suit",
    price: 7900,
    fabric: "Cotton Lawn",
    sizes: "S · M · L · XL",
    details: "Comfortable stitched suit with relaxed shape."
  },

  {
    name: "Hania Everyday Lawn Set",
    price: 7200,
    fabric: "Lawn",
    sizes: "S · M · L · XL",
    details: "Easy everyday lawn set designed for all-day comfort."
  },

  {
    name: "Mila Festive Cotton Set",
    price: 9800,
    fabric: "Cotton",
    sizes: "S · M · L · XL",
    details: "Festive woven cotton style with polished stitched finish."
  },

  {
    name: "Aiza Soft Drape Suit",
    price: 10450,
    fabric: "Cotton Chiffon",
    sizes: "S · M · L · XL",
    details: "Flowy stitched set with soft drape and dressy finish."
  },

  {
    name: "Yumna Embellished Kurta",
    price: 11900,
    fabric: "Cotton Silk",
    sizes: "S · M · L · XL",
    details: "Subtle embellishment along neckline and front panel."
  },

  {
    name: "Ayesha Classic Lawn Suit",
    price: 7900,
    fabric: "Lawn",
    sizes: "S · M · L · XL",
    details: "Clean and classic stitched lawn suit."
  },

  {
    name: "Rimsha Cotton Festive Set",
    price: 9800,
    fabric: "Cotton",
    sizes: "S · M · L · XL",
    details: "Refined festive set with polished tailoring."
  },

  {
    name: "Nadia Printed Shirt Set",
    price: 8700,
    fabric: "Lawn, Chiffon Dupatta",
    sizes: "S · M · L · XL",
    details: "Printed shirt set with soft movement and minimal design."
  },

  {
    name: "Sana Grace Kurta Set",
    price: 10100,
    fabric: "Lawn, Net Dupatta",
    sizes: "S · M · L · XL",
    details: "Graceful kurta set with neat stitching."
  },

  {
    name: "Sahar Floral Chiffon Set",
    price: 11800,
    fabric: "Chiffon",
    sizes: "S · M · L · XL",
    details: "Floral chiffon styling with graceful silhouette."
  },

  {
    name: "Maryam Luxe Lawn Set",
    price: 12400,
    fabric: "Lawn, Silk Dupatta",
    sizes: "S · M · L · XL",
    details: "Elevated lawn set with premium finishing."
  },

  {
    name: "Emaan Everyday Stitched Set",
    price: 7350,
    fabric: "Cotton",
    sizes: "S · M · L · XL",
    details: "Lightweight stitched set for easy daywear."
  },

  {
    name: "Zoya Flow Kurta Set",
    price: 10900,
    fabric: "Cotton Silk",
    sizes: "S · M · L · XL",
    details: "Soft drape and neat finishing for formal settings."
  },

  {
    name: "Mahira Soft Printed Set",
    price: 8400,
    fabric: "Lawn",
    sizes: "S · M · L · XL",
    details: "Minimal printed set with soft hand feel."
  },

  {
    name: "Samiya Classic Shirt Suit",
    price: 9150,
    fabric: "Cotton Weave",
    sizes: "S · M · L · XL",
    details: "Polished cotton shirt suit with crisp silhouette."
  }

];


/* ============================================================
   UNSTITCHED — 35 PRODUCTS
   ============================================================ */

const UNSTITCHED_ITEMS = [

  {
    name: "Aisha Soft Cotton Lawn",
    price: 5000,
    fabric: "Lawn",
    sizes: "Unstitched — One Size",
    details: "Lightweight unstitched lawn set for warm weather dressing."
  },

  {
    name: "Meher Printed Chiffon Set",
    price: 6100,
    fabric: "Chiffon",
    sizes: "Unstitched — One Size",
    details: "Rich printed chiffon set with feminine drape."
  },

  {
    name: "Fizza Summer Floral Unstitched",
    price: 5600,
    fabric: "Cotton Lawn",
    sizes: "Unstitched — One Size",
    details: "Summer floral unstitched set with breezy fabric."
  },

  {
    name: "Zara Premium Lawn 3 Piece",
    price: 5800,
    fabric: "Premium Lawn",
    sizes: "Unstitched — One Size",
    details: "Premium lawn three-piece set with floral artwork."
  },

  {
    name: "Mariam Embroidered Unstitched",
    price: 6800,
    fabric: "Lawn, Dupatta",
    sizes: "Unstitched — One Size",
    details: "Elegant embroidered set suited for festive styling."
  },

  {
    name: "Sheza Classic Karandi Set",
    price: 6200,
    fabric: "Karandi, Shawl",
    sizes: "Unstitched — One Size",
    details: "Classic karandi unstitched set."
  },

  {
    name: "Sahil Printed Lawn",
    price: 4500,
    fabric: "Lawn, Chiffon Dupatta",
    sizes: "Unstitched — One Size",
    details: "Three-piece unstitched printed lawn set."
  },

  {
    name: "Sana Karandi Unstitched Set",
    price: 5200,
    fabric: "Karandi, Shawl",
    sizes: "Unstitched — One Size",
    details: "Winter karandi unstitched three-piece."
  },

  {
    name: "Maham Pastel Lawn Set",
    price: 5400,
    fabric: "Lawn",
    sizes: "Unstitched — One Size",
    details: "Subtle pastel lawn set with soft drape."
  },

  {
    name: "Rida Floral Chiffon Set",
    price: 6400,
    fabric: "Chiffon",
    sizes: "Unstitched — One Size",
    details: "Printed chiffon set with elegant fall."
  },

  {
    name: "Areeba Cotton Printed Set",
    price: 5100,
    fabric: "Cotton Lawn",
    sizes: "Unstitched — One Size",
    details: "Breathable cotton lawn unstitched set."
  },

  {
    name: "Noor Multicolor Lawn Set",
    price: 5900,
    fabric: "Lawn, Chiffon Dupatta",
    sizes: "Unstitched — One Size",
    details: "Bright and lively lawn set."
  },

  {
    name: "Hania Garden Print Set",
    price: 5700,
    fabric: "Lawn",
    sizes: "Unstitched — One Size",
    details: "Garden print styling with soft fabric."
  },

  {
    name: "Maryam Premium Karandi",
    price: 6600,
    fabric: "Karandi, Shawl",
    sizes: "Unstitched — One Size",
    details: "Premium karandi set with refined texture."
  },

  {
    name: "Ayesha Printed Dupatta Set",
    price: 6300,
    fabric: "Lawn, Dupatta",
    sizes: "Unstitched — One Size",
    details: "Crisp printed set with feminine finish."
  },

  {
    name: "Fariha Soft Chiffon Set",
    price: 6500,
    fabric: "Chiffon",
    sizes: "Unstitched — One Size",
    details: "Premium chiffon styling with airy feel."
  },

  {
    name: "Hira Classic 3 Piece",
    price: 6100,
    fabric: "Lawn",
    sizes: "Unstitched — One Size",
    details: "Classic three-piece lawn set."
  },

  {
    name: "Nadia Printed Lawn",
    price: 5500,
    fabric: "Printed Lawn",
    sizes: "Unstitched — One Size",
    details: "Feminine printed lawn set."
  },

  {
    name: "Sahar Tie-Dye Lawn Set",
    price: 5900,
    fabric: "Lawn",
    sizes: "Unstitched — One Size",
    details: "Tie-dye inspired lawn set."
  },

  {
    name: "Areej Minimal Lawn",
    price: 5200,
    fabric: "Lawn",
    sizes: "Unstitched — One Size",
    details: "Minimal printed lawn set."
  },

  {
    name: "Hina Cotton Festive Set",
    price: 7000,
    fabric: "Cotton Lawn",
    sizes: "Unstitched — One Size",
    details: "Festive unstitched set with soft texture."
  },

  {
    name: "Sana Bloom Lawn Set",
    price: 5900,
    fabric: "Lawn",
    sizes: "Unstitched — One Size",
    details: "Bloom-inspired printed lawn set."
  },

  {
    name: "Mira Textured Lawn",
    price: 6200,
    fabric: "Lawn",
    sizes: "Unstitched — One Size",
    details: "Textured lawn with modern feel."
  },

  {
    name: "Ansa Stripe Lawn Set",
    price: 5600,
    fabric: "Lawn",
    sizes: "Unstitched — One Size",
    details: "Minimal stripe detailing with polished look."
  },

  {
    name: "Zainab Soft Floral Set",
    price: 6700,
    fabric: "Cotton Lawn",
    sizes: "Unstitched — One Size",
    details: "Soft floral theme with comfortable fabric."
  },

  {
    name: "Aiza Printed Lawn Duo",
    price: 6000,
    fabric: "Lawn",
    sizes: "Unstitched — One Size",
    details: "Printed lawn duo in modern palette."
  },

  {
    name: "Rimsha Daily Lawn Set",
    price: 5300,
    fabric: "Lawn, Chiffon Dupatta",
    sizes: "Unstitched — One Size",
    details: "Pretty daily lawn set for comfortable wear."
  },

  {
    name: "Faryal Luxe Printed Lawn",
    price: 7200,
    fabric: "Premium Lawn",
    sizes: "Unstitched — One Size",
    details: "Luxury lawn set with elevated print palette."
  },

  {
    name: "Maryam Cotton Bloom Set",
    price: 6800,
    fabric: "Cotton Lawn",
    sizes: "Unstitched — One Size",
    details: "Cotton bloom set with soft finish."
  },

  {
    name: "Kiran Modern Lawn Pack",
    price: 6100,
    fabric: "Lawn",
    sizes: "Unstitched — One Size",
    details: "Modern lawn design with subtle print."
  }

];


/* ============================================================
   WESTERN — 35 PRODUCTS
   ============================================================ */

const WESTERN_ITEMS = [

  {
    name: "Noor Tailored Blazer Dress",
    price: 12500,
    fabric: "Crepe, Fully Lined",
    sizes: "XS · S · M · L",
    details: "Structured tailored blazer dress with belted waist."
  },

  {
    name: "Elan Wide-Leg Trouser Set",
    price: 9800,
    fabric: "Linen Blend",
    sizes: "XS · S · M · L",
    details: "Two-piece western set with cropped tailored top."
  },

  {
    name: "Rida Linen Co-ord Set",
    price: 13600,
    fabric: "Linen Blend",
    sizes: "XS · S · M · L",
    details: "Modern linen co-ord set with tailored lines."
  },

  {
    name: "Zara Structured Satin Dress",
    price: 14800,
    fabric: "Satin",
    sizes: "XS · S · M · L",
    details: "Elegant satin dress with structured fit."
  },

  {
    name: "Hania Pleated Midi Dress",
    price: 14300,
    fabric: "Viscose Blend",
    sizes: "XS · S · M · L",
    details: "Pleated midi dress for day-to-night styling."
  },

  {
    name: "Iman Oversized Button Shirt",
    price: 9800,
    fabric: "Cotton Twill",
    sizes: "XS · S · M · L",
    details: "Oversized button-down shirt in premium fabric."
  },

  {
    name: "Ayesha Denim Co-ord",
    price: 15700,
    fabric: "Denim",
    sizes: "S · M · L · XL",
    details: "Relaxed denim co-ord in modern silhouette."
  },

  {
    name: "Nadia Structured Mini Dress",
    price: 12900,
    fabric: "Cotton Blend",
    sizes: "XS · S · M · L",
    details: "Minimal structured mini dress."
  },

  {
    name: "Sana Relaxed Blazer Set",
    price: 14700,
    fabric: "Wool Blend",
    sizes: "XS · S · M · L",
    details: "Soft blazer and trouser pairing."
  },

  {
    name: "Fahra Satin Slip Dress",
    price: 15300,
    fabric: "Satin",
    sizes: "XS · S · M · L",
    details: "Silky slip dress with flattering drape."
  },

  {
    name: "Mia Wide-Leg Trousers",
    price: 10600,
    fabric: "Cotton Twill",
    sizes: "XS · S · M · L",
    details: "High-waist wide-leg trousers."
  },

  {
    name: "Ira Cashmere Knit Set",
    price: 16800,
    fabric: "Cashmere Blend",
    sizes: "XS · S · M · L",
    details: "Soft premium knit pairing."
  },

  {
    name: "Anaya Pleated Skirt Set",
    price: 13800,
    fabric: "Viscose",
    sizes: "XS · S · M · L",
    details: "Pleated skirt and matching knit top."
  },

  {
    name: "Emaan White Linen Shirt",
    price: 9700,
    fabric: "Linen",
    sizes: "XS · S · M · L",
    details: "Lightweight linen shirt with clean drape."
  },

  {
    name: "Zoya Tailored Pant Suit",
    price: 16900,
    fabric: "Cotton Twill",
    sizes: "XS · S · M · L",
    details: "Structured pant suit with sharp silhouette."
  },

  {
    name: "Maryam Knit Polo Dress",
    price: 12100,
    fabric: "Cotton Knit",
    sizes: "XS · S · M · L",
    details: "Lightweight knit dress with fitted top."
  },

  {
    name: "Hira Layered Co-ord",
    price: 14200,
    fabric: "Cotton Blend",
    sizes: "XS · S · M · L",
    details: "Layered co-ord with relaxed silhouette."
  },

  {
    name: "Sofia Pleated Jumpsuit",
    price: 15900,
    fabric: "Crepe",
    sizes: "XS · S · M · L",
    details: "Classic jumpsuit with pleated detailing."
  },

  {
    name: "Rania Smart Casual Set",
    price: 13700,
    fabric: "Linen Blend",
    sizes: "XS · S · M · L",
    details: "Smart casual pairing with modern structure."
  },

  {
    name: "Aisha Monochrome Co-ord",
    price: 13400,
    fabric: "Cotton Blend",
    sizes: "XS · S · M · L",
    details: "Minimal monochrome co-ord."
  },

  {
    name: "Mahir Cotton Shirt Dress",
    price: 12600,
    fabric: "Cotton Satin",
    sizes: "XS · S · M · L",
    details: "Classic shirt dress with soft structure."
  },

  {
    name: "Nisa Belted Midi Dress",
    price: 14500,
    fabric: "Crepe",
    sizes: "XS · S · M · L",
    details: "Belted midi dress with structured waistline."
  },

  {
    name: "Farah Relaxed Twill Suit",
    price: 14700,
    fabric: "Twill",
    sizes: "XS · S · M · L",
    details: "Relaxed twill suit balancing comfort and polish."
  },

  {
    name: "Rimsha Lounge Dress",
    price: 12800,
    fabric: "Viscose",
    sizes: "XS · S · M · L",
    details: "Lounge-inspired dress with smooth fabric."
  },

  {
    name: "Areeba Longline Blazer",
    price: 15100,
    fabric: "Woven Blend",
    sizes: "XS · S · M · L",
    details: "Longline blazer designed for versatility."
  },

  {
    name: "Sahar Utility Co-ord",
    price: 13600,
    fabric: "Cotton Twill",
    sizes: "XS · S · M · L",
    details: "Utility-inspired modern co-ord."
  },

  {
    name: "Hira Soft Knit Dress",
    price: 11900,
    fabric: "Knit Blend",
    sizes: "XS · S · M · L",
    details: "Soft knit dress with comfortable movement."
  },

  {
    name: "Leena Professional Set",
    price: 16000,
    fabric: "Cotton Blend",
    sizes: "XS · S · M · L",
    details: "Streamlined professional set for meetings and events."
  },

  {
    name: "Aiza Neutral Shirtdress",
    price: 12200,
    fabric: "Linen Blend",
    sizes: "XS · S · M · L",
    details: "Neutral shirtdress with tailored collar."
  },

  {
    name: "Rida Tailored Skirt Set",
    price: 13900,
    fabric: "Crepe",
    sizes: "XS · S · M · L",
    details: "Tailored skirt set with elegant structure."
  }

];


/* ============================================================
   EASTERN — 35 PRODUCTS
   ============================================================ */

const EASTERN_ITEMS = [

  {
    name: "Anaya Bridal Eastern Ensemble",
    price: 42000,
    fabric: "Raw Silk, Hand Embellished",
    sizes: "Made to Order",
    details: "Heavy hand-embellished eastern ensemble."
  },

  {
    name: "Hania Eastern Angrakha",
    price: 15800,
    fabric: "Organza, Gota Lace",
    sizes: "S · M · L",
    details: "Stitched angrakha-style eastern kurta."
  },

  {
    name: "Mahnoor Gota Work Kurta",
    price: 11800,
    fabric: "Silk Blend, Gota Work",
    sizes: "S · M · L · XL",
    details: "Festive gota work kurta."
  },

  {
    name: "Rania Embroidered Sharara",
    price: 16800,
    fabric: "Silk Blend, Embroidery",
    sizes: "S · M · L · XL",
    details: "Statement sharara set with rich embroidery."
  },

  {
    name: "Faryal Net Dupatta Set",
    price: 13400,
    fabric: "Net, Chiffon",
    sizes: "S · M · L · XL",
    details: "Soft net dupatta set with elegant fall."
  },

  {
    name: "Aisha Silk Festive Suit",
    price: 17100,
    fabric: "Silk Blend",
    sizes: "S · M · L · XL",
    details: "Silk festive suit with elegant tailored cut."
  },

  {
    name: "Maham Modern Eastern Set",
    price: 15400,
    fabric: "Cotton Silk, Dupatta",
    sizes: "S · M · L · XL",
    details: "Polished eastern set with contemporary proportions."
  },

  {
    name: "Sadia Embroidered Gown",
    price: 18400,
    fabric: "Silk Blend, Hand Work",
    sizes: "S · M · L · XL",
    details: "Graceful eastern gown with bridal-inspired embroidery."
  },

  {
    name: "Nisha Festive Kurta Set",
    price: 12700,
    fabric: "Cotton Silk",
    sizes: "S · M · L · XL",
    details: "Refined festive eastern set."
  },

  {
    name: "Areeba Traditional Chiffon Set",
    price: 11900,
    fabric: "Chiffon, Dupatta",
    sizes: "S · M · L · XL",
    details: "Traditional styling with chiffon texture."
  },

  {
    name: "Hira Organza Angrakha",
    price: 16200,
    fabric: "Organza, Lace",
    sizes: "S · M · L · XL",
    details: "Light organza angrakha with lace detailing."
  },

  {
    name: "Maryam Pastel Eastern Set",
    price: 14100,
    fabric: "Cotton Silk",
    sizes: "S · M · L · XL",
    details: "Pastel eastern ensemble."
  },

  {
    name: "Alina Gharara Set",
    price: 17200,
    fabric: "Silk Blend",
    sizes: "S · M · L · XL",
    details: "Gharara-inspired eastern set."
  },

  {
    name: "Rida Festive Kurta Pant",
    price: 13800,
    fabric: "Cotton Silk",
    sizes: "S · M · L · XL",
    details: "Relaxed kurta and pant pairing."
  },

  {
    name: "Maham Silk Dupatta Set",
    price: 15900,
    fabric: "Silk Blend, Dupatta",
    sizes: "S · M · L · XL",
    details: "Statement eastern set with silk dupatta."
  },

  {
    name: "Zoya Rose Gold Set",
    price: 17600,
    fabric: "Silk Blend",
    sizes: "S · M · L · XL",
    details: "Rose-toned eastern outfit with subtle shimmer."
  },

  {
    name: "Hania Bridal Chiffon Set",
    price: 18700,
    fabric: "Chiffon, Net Dupatta",
    sizes: "S · M · L · XL",
    details: "Bridal-inspired eastern set."
  },

  {
    name: "Aisha Printed Eastern Suit",
    price: 12400,
    fabric: "Lawn, Chiffon Dupatta",
    sizes: "S · M · L · XL",
    details: "Printed eastern suit with soft movement."
  },

  {
    name: "Nadia Formal Eastern Set",
    price: 14900,
    fabric: "Silk Blend",
    sizes: "S · M · L · XL",
    details: "Formal eastern set with premium fabric."
  },

  {
    name: "Mila Embroidered Kurta",
    price: 15300,
    fabric: "Cotton Silk, Embroidery",
    sizes: "S · M · L · XL",
    details: "Classic embroidered kurta."
  },

  {
    name: "Sahar Georgette Set",
    price: 14800,
    fabric: "Georgette",
    sizes: "S · M · L · XL",
    details: "Georgette eastern set with soft flow."
  },

  {
    name: "Fiza Pearled Dupatta Set",
    price: 15800,
    fabric: "Silk Blend, Net Dupatta",
    sizes: "S · M · L · XL",
    details: "Pearled detail with flowing dupatta."
  },

  {
    name: "Areej Satin Kurta Set",
    price: 16900,
    fabric: "Satin",
    sizes: "S · M · L · XL",
    details: "Smooth satin eastern set."
  },

  {
    name: "Yumna Chiffon Festive Set",
    price: 13700,
    fabric: "Chiffon",
    sizes: "S · M · L · XL",
    details: "Festive chiffon set with graceful drape."
  },

  {
    name: "Sana Lace Eastern Set",
    price: 16100,
    fabric: "Organza, Lace",
    sizes: "S · M · L · XL",
    details: "Refined lace detailing eastern set."
  },

  {
    name: "Fariha Silk Gown",
    price: 17900,
    fabric: "Silk Blend",
    sizes: "S · M · L · XL",
    details: "Gown-inspired eastern piece."
  },

  {
    name: "Emaan Embellished Shalwar",
    price: 14600,
    fabric: "Silk Blend",
    sizes: "S · M · L · XL",
    details: "Embellished eastern shalwar and kurta."
  },

  {
    name: "Rimsha Party Eastern Suit",
    price: 15200,
    fabric: "Cotton Silk",
    sizes: "S · M · L · XL",
    details: "Party-ready eastern suit."
  },

  {
    name: "Aiza Luxe Eastern Set",
    price: 17300,
    fabric: "Silk Blend, Net Dupatta",
    sizes: "S · M · L · XL",
    details: "Luxe eastern styling with elegant layers."
  },

  {
    name: "Hira Velvet Eastern Set",
    price: 18100,
    fabric: "Velvet Blend",
    sizes: "S · M · L · XL",
    details: "Velvet eastern set designed for winter events."
  }

];


/* ============================================================
   CREATE FINAL PRODUCT LIST
   ============================================================ */

const SEED_PRODUCTS = [

  ...STITCHED_ITEMS.map((item, index) => ({
    id: `stitched-${index + 1}`,
    category: "Stitched",
    ...item,
    images: buildImages(index, "Stitched", item.name)
  })),

  ...UNSTITCHED_ITEMS.map((item, index) => ({
    id: `unstitched-${index + 1}`,
    category: "Unstitched",
    ...item,
    images: buildImages(index, "Unstitched", item.name)
  })),

  ...WESTERN_ITEMS.map((item, index) => ({
    id: `western-${index + 1}`,
    category: "Western",
    ...item,
    images: buildImages(index, "Western", item.name)
  })),

  ...EASTERN_ITEMS.map((item, index) => ({
    id: `eastern-${index + 1}`,
    category: "Eastern",
    ...item,
    images: buildImages(index, "Eastern", item.name)
  }))

];

/* ============================================================
   EXPORT
   ============================================================ */

globalThis.SEED_PRODUCTS = SEED_PRODUCTS;

globalThis.COLLECTION_GROUPS = [
  {
    label: "Unstitched",
    items: [
      { label: "View All Unstitched", href: "shop.html?category=unstitched" },
      { label: "Soft Pastels", href: "shop.html?category=unstitched" },
      { label: "Premium Lawn", href: "shop.html?category=unstitched" }
    ]
  },
  {
    label: "Western",
    items: [
      { label: "View All WEST", href: "shop.html?category=western" },
      { label: "Co-ords", href: "shop.html?category=western" },
      { label: "Statement Pieces", href: "shop.html?category=western" }
    ]
  },
  {
    label: "Ready to Wear",
    items: [
      { label: "View All Ready to Wear", href: "shop.html?category=stitched" },
      { label: "Minimal Chic", href: "shop.html?category=stitched" },
      { label: "Occasion Edit", href: "shop.html?category=stitched" }
    ]
  },
  {
    label: "New In",
    items: [
      { label: "View All New In", href: "shop.html?category=new-arrivals" },
      { label: "Fresh Launches", href: "shop.html?category=new-arrivals" },
      { label: "Trending Now", href: "shop.html?category=new-arrivals" }
    ]
  }
];

console.log("Threadline products loaded:", SEED_PRODUCTS.length);
console.log("Stitched:", STITCHED_ITEMS.length);
console.log("Unstitched:", UNSTITCHED_ITEMS.length);
console.log("Western:", WESTERN_ITEMS.length);
console.log("Eastern:", EASTERN_ITEMS.length);