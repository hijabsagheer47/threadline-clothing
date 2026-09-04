/* ============================================================
  TAYYABACOLLECTIVE — PRODUCT IMAGE URL MAPPING
   30 Stitched
   30 Unstitched
   30 Western
   30 Eastern
   ============================================================ */

function legacyBuildImages(index, category, name) {

  const imageSets = {

    /* ========================================================
       STITCHED — 30 IMAGES
       ======================================================== */
    Stitched: [
      "https://loremflickr.com/900/1200/pakistani,fashion,dress?lock=101",
      "https://loremflickr.com/900/1200/pakistani,kurta,fashion?lock=102",
      "https://loremflickr.com/900/1200/pakistani,dress,woman?lock=103",
      "https://loremflickr.com/900/1200/pakistani,shalwar,kameez?lock=104",
      "https://loremflickr.com/900/1200/southasian,fashion,dress?lock=105",
      "https://loremflickr.com/900/1200/pakistani,clothing,model?lock=106",
      "https://loremflickr.com/900/1200/pakistani,embroidered,dress?lock=107",
      "https://loremflickr.com/900/1200/pakistani,lawn,dress?lock=108",
      "https://loremflickr.com/900/1200/pakistani,kurta,woman?lock=109",
      "https://loremflickr.com/900/1200/eastern,fashion,woman?lock=110",
      "https://loremflickr.com/900/1200/pakistani,traditional,dress?lock=111",
      "https://loremflickr.com/900/1200/pakistani,printed,dress?lock=112",
      "https://loremflickr.com/900/1200/pakistani,chiffon,dress?lock=113",
      "https://loremflickr.com/900/1200/pakistani,cotton,dress?lock=114",
      "https://loremflickr.com/900/1200/pakistani,linen,dress?lock=115",
      "https://loremflickr.com/900/1200/pakistani,floral,dress?lock=116",
      "https://loremflickr.com/900/1200/pakistani,pastel,dress?lock=117",
      "https://loremflickr.com/900/1200/pakistani,festive,dress?lock=118",
      "https://loremflickr.com/900/1200/pakistani,formal,dress?lock=119",
      "https://loremflickr.com/900/1200/pakistani,designer,dress?lock=120",
      "https://loremflickr.com/900/1200/southasian,kurta,woman?lock=121",
      "https://loremflickr.com/900/1200/southasian,traditional,dress?lock=122",
      "https://loremflickr.com/900/1200/pakistani,ethnic,dress?lock=123",
      "https://loremflickr.com/900/1200/pakistani,summer,fashion?lock=124",
      "https://loremflickr.com/900/1200/pakistani,summer,dress?lock=125",
      "https://loremflickr.com/900/1200/pakistani,modern,kurta?lock=126",
      "https://loremflickr.com/900/1200/pakistani,elegant,dress?lock=127",
      "https://loremflickr.com/900/1200/pakistani,style,woman?lock=128",
      "https://loremflickr.com/900/1200/pakistani,threepiece,dress?lock=129",
      "https://loremflickr.com/900/1200/pakistani,luxury,fashion?lock=130"
    ],

    /* ========================================================
       UNSTITCHED — 30 IMAGES
       ======================================================== */
    Unstitched: [
      "https://loremflickr.com/900/1200/fabric,textile,fashion?lock=201",
      "https://loremflickr.com/900/1200/lawn,fabric,clothing?lock=202",
      "https://loremflickr.com/900/1200/chiffon,fabric,fashion?lock=203",
      "https://loremflickr.com/900/1200/cotton,fabric,textile?lock=204",
      "https://loremflickr.com/900/1200/printed,fabric,fashion?lock=205",
      "https://loremflickr.com/900/1200/embroidered,fabric?lock=206",
      "https://loremflickr.com/900/1200/pakistani,fabric,lawn?lock=207",
      "https://loremflickr.com/900/1200/pakistani,textile,fashion?lock=208",
      "https://loremflickr.com/900/1200/lawn,suit,fabric?lock=209",
      "https://loremflickr.com/900/1200/karandi,fabric?lock=210",
      "https://loremflickr.com/900/1200/silk,fabric,fashion?lock=211",
      "https://loremflickr.com/900/1200/printed,textile,clothing?lock=212",
      "https://loremflickr.com/900/1200/floral,fabric,textile?lock=213",
      "https://loremflickr.com/900/1200/pastel,fabric,fashion?lock=214",
      "https://loremflickr.com/900/1200/colorful,fabric,textile?lock=215",
      "https://loremflickr.com/900/1200/fashion,fabric,collection?lock=216",
      "https://loremflickr.com/900/1200/textile,pattern,fabric?lock=217",
      "https://loremflickr.com/900/1200/cotton,print,textile?lock=218",
      "https://loremflickr.com/900/1200/luxury,textile,fabric?lock=219",
      "https://loremflickr.com/900/1200/ethnic,fabric,fashion?lock=220",
      "https://loremflickr.com/900/1200/indian,fabric,textile?lock=221",
      "https://loremflickr.com/900/1200/southasian,textile,fabric?lock=222",
      "https://loremflickr.com/900/1200/fabric,dupattas,textile?lock=223",
      "https://loremflickr.com/900/1200/scarf,fabric,fashion?lock=224",
      "https://loremflickr.com/900/1200/fabric,embroidery,textile?lock=225",
      "https://loremflickr.com/900/1200/floral,textile,fabric?lock=226",
      "https://loremflickr.com/900/1200/summer,fabric,lawn?lock=227",
      "https://loremflickr.com/900/1200/premium,fabric,textile?lock=228",
      "https://loremflickr.com/900/1200/designer,fabric,fashion?lock=229",
      "https://loremflickr.com/900/1200/pakistani,lawn,textile?lock=230"
    ],

    /* ========================================================
       WESTERN — 30 IMAGES
       ======================================================== */
    Western: [
      "https://loremflickr.com/900/1200/women,western,fashion?lock=301",
      "https://loremflickr.com/900/1200/woman,blazer,fashion?lock=302",
      "https://loremflickr.com/900/1200/woman,co-ord,fashion?lock=303",
      "https://loremflickr.com/900/1200/woman,satin,dress?lock=304",
      "https://loremflickr.com/900/1200/woman,linen,dress?lock=305",
      "https://loremflickr.com/900/1200/woman,western,dress?lock=306",
      "https://loremflickr.com/900/1200/woman,tailored,suit?lock=307",
      "https://loremflickr.com/900/1200/woman,trousers,fashion?lock=308",
      "https://loremflickr.com/900/1200/woman,midi,dress?lock=309",
      "https://loremflickr.com/900/1200/woman,modern,fashion?lock=310",
      "https://loremflickr.com/900/1200/woman,casual,fashion?lock=311",
      "https://loremflickr.com/900/1200/woman,elegant,dress?lock=312",
      "https://loremflickr.com/900/1200/woman,formal,fashion?lock=313",
      "https://loremflickr.com/900/1200/woman,black,dress?lock=314",
      "https://loremflickr.com/900/1200/woman,white,dress?lock=315",
      "https://loremflickr.com/900/1200/woman,beige,fashion?lock=316",
      "https://loremflickr.com/900/1200/woman,neutral,fashion?lock=317",
      "https://loremflickr.com/900/1200/woman,professional,fashion?lock=318",
      "https://loremflickr.com/900/1200/woman,office,fashion?lock=319",
      "https://loremflickr.com/900/1200/woman,jumpsuit,fashion?lock=320",
      "https://loremflickr.com/900/1200/woman,skirt,fashion?lock=321",
      "https://loremflickr.com/900/1200/woman,knitwear,fashion?lock=322",
      "https://loremflickr.com/900/1200/woman,oversized,shirt?lock=323",
      "https://loremflickr.com/900/1200/woman,denim,fashion?lock=324",
      "https://loremflickr.com/900/1200/woman,blouse,fashion?lock=325",
      "https://loremflickr.com/900/1200/woman,street,fashion?lock=326",
      "https://loremflickr.com/900/1200/woman,luxury,fashion?lock=327",
      "https://loremflickr.com/900/1200/woman,minimal,fashion?lock=328",
      "https://loremflickr.com/900/1200/woman,chic,clothing?lock=329",
      "https://loremflickr.com/900/1200/woman,designer,fashion?lock=330"
    ],

    /* ========================================================
       EASTERN — 30 IMAGES
       ======================================================== */
    Eastern: [
      "https://loremflickr.com/900/1200/pakistani,eastern,dress?lock=401",
      "https://loremflickr.com/900/1200/pakistani,bridal,dress?lock=402",
      "https://loremflickr.com/900/1200/pakistani,formal,dress?lock=403",
      "https://loremflickr.com/900/1200/pakistani,sharara,dress?lock=404",
      "https://loremflickr.com/900/1200/pakistani,gown,dress?lock=405",
      "https://loremflickr.com/900/1200/pakistani,organza,dress?lock=406",
      "https://loremflickr.com/900/1200/pakistani,silk,dress?lock=407",
      "https://loremflickr.com/900/1200/pakistani,embroidered,dress?lock=408",
      "https://loremflickr.com/900/1200/pakistani,festive,dress?lock=409",
      "https://loremflickr.com/900/1200/pakistani,partywear,dress?lock=410",
      "https://loremflickr.com/900/1200/pakistani,traditional,fashion?lock=411",
      "https://loremflickr.com/900/1200/pakistani,luxury,dress?lock=412",
      "https://loremflickr.com/900/1200/pakistani,designer,dress?lock=413",
      "https://loremflickr.com/900/1200/pakistani,anarkali,dress?lock=414",
      "https://loremflickr.com/900/1200/pakistani,angrakha,dress?lock=415",
      "https://loremflickr.com/900/1200/pakistani,gharara,dress?lock=416",
      "https://loremflickr.com/900/1200/pakistani,shalwar,kameez?lock=417",
      "https://loremflickr.com/900/1200/pakistani,chiffon,dress?lock=418",
      "https://loremflickr.com/900/1200/pakistani,velvet,dress?lock=419",
      "https://loremflickr.com/900/1200/pakistani,gota,dress?lock=420",
      "https://loremflickr.com/900/1200/pakistani,lace,dress?lock=421",
      "https://loremflickr.com/900/1200/pakistani,pearls,dress?lock=422",
      "https://loremflickr.com/900/1200/pakistani,pastel,dress?lock=423",
      "https://loremflickr.com/900/1200/pakistani,rose,dress?lock=424",
      "https://loremflickr.com/900/1200/pakistani,gold,dress?lock=425",
      "https://loremflickr.com/900/1200/pakistani,red,bridal?lock=426",
      "https://loremflickr.com/900/1200/pakistani,white,formal?lock=427",
      "https://loremflickr.com/900/1200/pakistani,green,eastern?lock=428",
      "https://loremflickr.com/900/1200/pakistani,pink,eastern?lock=429",
      "https://loremflickr.com/900/1200/pakistani,couture,fashion?lock=430"
    ]
  };

  const categoryImages = imageSets[category];

  if (!categoryImages || categoryImages.length === 0) {
    return [];
  }

  const image = categoryImages[index % categoryImages.length];

  return [image, image];
}

/* Lock each remote photo to one product so catalog cards never share a URL. */
const REAL_FASHION_TAGS = {
  Stitched: "pakistani,fashion,dress",
  Unstitched: "pakistani,fabric,textile",
  Western: "women,western,fashion",
  Eastern: "pakistani,eastern,dress"
};

const FALLBACK_FASHION_PHOTOS = [
  "https://images.unsplash.com/photo-1490481651871-ab68de25d43d?auto=format&fit=crop&w=900&q=85",
  "https://images.unsplash.com/photo-1483985988355-763728e1935b?auto=format&fit=crop&w=900&q=85",
  "https://images.unsplash.com/photo-1529139574466-a303027c1d8b?auto=format&fit=crop&w=900&q=85",
  "https://images.unsplash.com/photo-1496747611176-843222e1e57c?auto=format&fit=crop&w=900&q=85",
  "https://images.unsplash.com/photo-1485968579580-b6d095142e6e?auto=format&fit=crop&w=900&q=85",
  "https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?auto=format&fit=crop&w=900&q=85",
  "https://images.unsplash.com/photo-1509631179647-0177331693ae?auto=format&fit=crop&w=900&q=85",
  "https://images.unsplash.com/photo-1539109136881-3be0616acf4b?auto=format&fit=crop&w=900&q=85",
  "https://images.unsplash.com/photo-1525507119028-ed4c629a60a3?auto=format&fit=crop&w=900&q=85",
  "https://images.unsplash.com/photo-1496217590455-aa63a8350eea?auto=format&fit=crop&w=900&q=85",
  "https://images.unsplash.com/photo-1445205170230-053b83016050?auto=format&fit=crop&w=900&q=85",
  "https://images.unsplash.com/photo-1485230895905-ec40ba36b9bc?auto=format&fit=crop&w=900&q=85"
];

function fallbackFashionImage(index) {
  const value = String(index || "");
  const hash = Array.from(value).reduce((total, character) => {
    return total + character.charCodeAt(0);
  }, 0);
  return `images/products/catalog-${String((hash % 240) + 1).padStart(3, "0")}.jpg`;
}

globalThis.fallbackFashionImage = fallbackFashionImage;

function buildImages(index, category, name) {
  const photoNumber = CATEGORIES.indexOf(category) * 30 + index + 1;
  const first = `images/products/catalog-${String(photoNumber).padStart(3, "0")}.jpg`;
  const second = `images/products/catalog-${String(photoNumber + 120).padStart(3, "0")}.jpg`;
  const third = `images/products/catalog-${String(photoNumber + 60).padStart(3, "0")}.jpg`;
  const fourth = `images/products/catalog-${String(photoNumber + 180).padStart(3, "0")}.jpg`;
  return [first, second, third, fourth];
}

const CATEGORIES = ["Stitched", "Unstitched", "Western", "Eastern"];
globalThis.CATEGORIES = CATEGORIES;

const PRODUCT_NAMES = {
  Stitched: [
    "Areeba Floral Lawn Set", "Nisha Printed Lawn Kurta", "Hiba Cotton Shirt Set", "Sana Formal Linen Ensemble", "Alina Pastel Chiffon Three Piece", "Noor Festive Cotton Suit", "Zareen Embroidered Suit", "Mira Khaddar Suit", "Rida Cotton Kurta Set", "Maham Printed Lawn Suit", "Saira Chikankari Set", "Farah Minimal Kurta", "Tania Soft Silk Set", "Hira Printed Cotton Kurta", "Kiran Bordered Lawn Set", "Ansa Casual Stitched Suit", "Hania Everyday Lawn Set", "Mila Festive Cotton Set", "Aiza Soft Drape Suit", "Yumna Embellished Kurta", "Ayesha Classic Lawn Suit", "Rimsha Cotton Festive Set", "Nadia Printed Shirt Set", "Sana Grace Kurta Set", "Sahar Floral Chiffon Set", "Maryam Luxe Lawn Set", "Emaan Everyday Stitched Set", "Zoya Flow Kurta Set", "Mahira Soft Printed Set", "Samiya Classic Shirt Suit"
  ],
  Unstitched: [
    "Aisha Soft Cotton Lawn", "Meher Printed Chiffon Set", "Fizza Summer Floral Unstitched", "Zara Premium Lawn 3 Piece", "Mariam Embroidered Unstitched", "Sheza Classic Karandi Set", "Sahil Printed Lawn", "Sana Karandi Unstitched Set", "Maham Pastel Lawn Set", "Rida Floral Chiffon Set", "Areeba Cotton Printed Set", "Noor Multicolor Lawn Set", "Hania Garden Print Set", "Maryam Premium Karandi", "Ayesha Printed Dupatta Set", "Fariha Soft Chiffon Set", "Hira Classic 3 Piece", "Nadia Printed Lawn", "Sahar Tie-Dye Lawn Set", "Areej Minimal Lawn", "Hina Cotton Festive Set", "Sana Bloom Lawn Set", "Mira Textured Lawn", "Ansa Stripe Lawn Set", "Zainab Soft Floral Set", "Aiza Printed Lawn Duo", "Rimsha Daily Lawn Set", "Faryal Luxe Printed Lawn", "Maryam Cotton Bloom Set", "Kiran Modern Lawn Pack"
  ],
  Western: [
    "Noor Tailored Blazer Dress", "Elan Wide-Leg Trouser Set", "Rida Linen Co-ord Set", "Zara Structured Satin Dress", "Hania Pleated Midi Dress", "Iman Oversized Button Shirt", "Ayesha Denim Co-ord", "Nadia Structured Mini Dress", "Sana Relaxed Blazer Set", "Fahra Satin Slip Dress", "Mia Wide-Leg Trousers", "Ira Cashmere Knit Set", "Anaya Pleated Skirt Set", "Emaan White Linen Shirt", "Zoya Tailored Pant Suit", "Maryam Knit Polo Dress", "Hira Layered Co-ord", "Sofia Pleated Jumpsuit", "Rania Smart Casual Set", "Aisha Monochrome Co-ord", "Mahir Cotton Shirt Dress", "Nisa Belted Midi Dress", "Farah Relaxed Twill Suit", "Rimsha Lounge Dress", "Areeba Longline Blazer", "Sahar Utility Co-ord", "Hira Soft Knit Dress", "Leena Professional Set", "Aiza Neutral Shirtdress", "Rida Tailored Skirt Set"
  ],
  Eastern: [
    "Anaya Bridal Eastern Ensemble", "Hania Eastern Angrakha", "Mahnoor Gota Work Kurta", "Rania Embroidered Sharara", "Faryal Net Dupatta Set", "Aisha Silk Festive Suit", "Maham Modern Eastern Set", "Sadia Embroidered Gown", "Nisha Festive Kurta Set", "Areeba Traditional Chiffon Set", "Hira Organza Angrakha", "Maryam Pastel Eastern Set", "Alina Gharara Set", "Rida Festive Kurta Pant", "Maham Silk Dupatta Set", "Zoya Rose Gold Set", "Hania Bridal Chiffon Set", "Aisha Printed Eastern Suit", "Nadia Formal Eastern Set", "Mila Embroidered Kurta", "Sahar Georgette Set", "Fiza Pearled Dupatta Set", "Areej Satin Kurta Set", "Yumna Chiffon Festive Set", "Sana Lace Eastern Set", "Fariha Silk Gown", "Emaan Embellished Shalwar", "Rimsha Party Eastern Suit", "Aiza Luxe Eastern Set", "Hira Velvet Eastern Set"
  ]
};

const SEED_PRODUCTS = CATEGORIES.flatMap(category =>
  PRODUCT_NAMES[category].map((name, index) => ({
    id: `${category.toLowerCase()}-${index + 1}`,
    name,
    category,
    price: 6200 + ((index * 675) % 8500),
    fabric: category === "Western" ? "Premium blended fabric" : "Premium lawn and chiffon",
    sizes: "S · M · L · XL",
    details: `A thoughtfully designed ${category.toLowerCase()} piece with refined finishing and an easy, elegant fit.`,
    images: buildImages(index, category, name)
  }))
);

globalThis.SEED_PRODUCTS = SEED_PRODUCTS;

const COLLECTION_GROUPS = [
  {
    label: "Unstitched",
    items: [{ label: "View All Unstitched", href: "shop.html?category=unstitched" }]
  },
  {
    label: "Western",
    items: [{ label: "View All WEST", href: "shop.html?category=western" }]
  },
  {
    label: "Ready to Wear",
    items: [{ label: "View All Ready to Wear", href: "shop.html?category=stitched" }]
  },
  {
    label: "New In",
    items: [{ label: "View All New In", href: "shop.html?category=new-arrivals" }]
  }
];

globalThis.COLLECTION_GROUPS = COLLECTION_GROUPS;