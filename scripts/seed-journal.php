<?php
declare(strict_types=1);
/**
 * One-off seed for the Fashlab Style Journal.
 * Publishes the initial editorial articles into journal_posts.
 * Idempotent: existing slugs are skipped, so it is safe to re-run.
 *
 * Run: /Applications/XAMPP/xamppfiles/bin/php scripts/seed-journal.php
 */

require __DIR__ . '/../includes/bootstrap.php';

if (!tc_table_exists('journal_posts') || !tc_table_exists('journal_categories')) {
    fwrite(STDERR, "journal tables missing — run migration-fashlab-upgrade.sql first.\n");
    exit(1);
}

$db = db();

$catIds = [];
foreach ($db->query('SELECT id, slug FROM journal_categories')->fetchAll() as $row) {
    $catIds[$row['slug']] = (int) $row['id'];
}

$store = setting('store_name');

$articles = [
    [
        'cat' => 'fabrics',
        'title' => 'How to Choose the Right Lawn Suit in Pakistan',
        'slug' => 'how-to-choose-the-right-lawn-suit',
        'excerpt' => 'Lawn looks the same on every rack — until you know what to check. Here is how to judge lawn quality before you buy.',
        'meta_title' => 'How to Choose the Right Lawn Suit in Pakistan | Fashlab Studio',
        'meta_description' => 'Practical tips for judging lawn fabric quality, print clarity and stitching before you buy a lawn suit in Pakistan.',
        'content' => <<<HTML
<p>Lawn is the default fabric of a Pakistani summer, which is exactly why every store — online and on the road — claims to sell "fine lawn". The label alone does not tell you much. What tells you everything is how the fabric behaves in your hands. Here is a simple way to judge a lawn suit before you commit to it.</p>

<h2>Feel the weave, not the packaging</h2>
<p>Good lawn is a lightweight, tightly woven cotton with a smooth, almost cool hand-feel. Run the fabric between your fingers: it should feel even, with no slubs, no rough patches and no paper-like stiffness. Hold it up to the light. A well-woven lawn lets light through gently without looking transparent — if it goes sheer at a single layer, expect to need a slip or a lining underneath.</p>

<h2>Check the print, not just the design</h2>
<p>Look closely at the print itself. Colours should be crisp, with clean edges between motifs and no faint double-impressions where the pattern blurs. Turn the fabric over: on printed lawn, the reverse usually shows a muted version of the front. If the back is completely white, you are looking at a surface print that may fade faster with washing.</p>

<ul>
    <li>Match the print across seams in stitched suits — sloppy alignment is a sign of rushed stitching.</li>
    <li>Check the dupatta print separately; it is often a different, lighter weave and wears differently.</li>
    <li>Look at the trouser fabric too — some sets use a cheaper cambric for the bottom instead of lawn.</li>
</ul>

<h2>Stitched or unstitched?</h2>
<p>If your measurements are standard and you like a predictable fit, a stitched lawn suit saves time. If you are particular about sleeve length, kameez height or how the dupatta sits, unstitched gives you full control — and it is easier to alter later. Our guide on <a href="journal-article.php?slug=stitched-vs-unstitched-suits">stitched vs unstitched suits</a> goes deeper on which one suits which person.</p>

<h2>After you buy: the first wash matters</h2>
<p>Always wash lawn separately the first time, in cool water and a mild detergent. Don't leave wet fabric in direct sunlight — that is what makes bright summer prints fade early. Dry in shade and the colours will hold far longer.</p>

<p>Ready to browse? Explore the full <a href="category.php?slug=lawn-collection">lawn collection</a> or see what just arrived in <a href="category.php?slug=new-arrivals">new arrivals</a>.</p>
HTML,
    ],
    [
        'cat' => 'styling',
        'title' => 'Stitched vs Unstitched Suits: Which One Should You Buy?',
        'slug' => 'stitched-vs-unstitched-suits',
        'excerpt' => 'Both have a place in a real wardrobe. The right choice depends on your fit, your timeline and how you like to dress.',
        'meta_title' => 'Stitched vs Unstitched Suits | Fashlab Studio Style Journal',
        'meta_description' => 'A practical comparison of stitched and unstitched suits — fit control, cost, timing and when each option makes more sense.',
        'content' => <<<HTML
<p>It is one of the most common questions in any Pakistani clothing store: should you buy stitched or unstitched? Neither answer is universally right. They solve different problems, and knowing which one you are actually solving makes the decision easy.</p>

<h2>What you are really choosing: control vs convenience</h2>
<p><strong>Unstitched</strong> is fabric — a shirt piece, trouser piece and usually a dupatta, cut and finished exactly the way you want. You choose the tailor, the neckline, the sleeve length, the khaj cut, everything. The trade-off is time: fabric, then tailoring, then fittings.</p>

<p><strong>Stitched</strong> is a finished outfit you can wear the day it arrives. The trade-off is that you are accepting someone else's measurements. For standard sizes this works well; for unusual proportions it can mean alterations.</p>

<h2>Choose unstitched when…</h2>
<ul>
    <li>Your measurements fall between standard sizes.</li>
    <li>You are particular about length — short kameez, long kameez, wide trousers.</li>
    <li>You want the same fabric in your own preferred cut across several suits.</li>
    <li>You plan to re-stitch or restyle it later.</li>
</ul>

<h2>Choose stitched when…</h2>
<ul>
    <li>You need an outfit for a specific date and do not have tailoring time.</li>
    <li>You have bought from the brand before and know the size runs true.</li>
    <li>You want consistent finishing — matching linings, neat piping, uniform seams.</li>
    <li>You are shopping for someone else and know their usual size.</li>
</ul>

<h2>A quick note on measurements</h2>
<p>If you are ordering stitched online, measure a suit that already fits you — laid flat, not on your body — and compare those numbers with the size chart. A printed size chart in centimetres is worth more than any label. When between two sizes, go up: taking in is easy, letting out is not.</p>

<p>Browse both options: <a href="category.php?slug=stitched">stitched women's clothing</a> and <a href="category.php?slug=unstitched">unstitched suits</a>.</p>
HTML,
    ],
    [
        'cat' => 'styling',
        'title' => 'How to Style a Pakistani 3 Piece Suit',
        'slug' => 'how-to-style-a-pakistani-3-piece-suit',
        'excerpt' => 'Shirt, trouser and dupatta — three pieces, many more looks. Simple ways to make a three-piece suit feel new.',
        'meta_title' => 'How to Style a Pakistani 3 Piece Suit | Fashlab Studio',
        'meta_description' => 'Ways to style a three-piece suit — dupatta draping, balance, footwear and how to re-wear one outfit in several ways.',
        'content' => <<<HTML
<p>A three-piece suit — shirt, trouser and dupatta — is the most complete outfit in a Pakistani wardrobe, and the most under-used. Most of us wear it the same way every time. A few small changes in how you treat the three pieces give you genuinely different looks from one outfit.</p>

<h2>Start with balance</h2>
<p>The rule that works with almost every three-piece: if the shirt is heavily embroidered or printed, keep the trouser simple and let the dupatta carry one colour from the shirt. If the shirt is plain or block-printed, the dupatta can be the loud piece. Trying to make all three pieces shout at once is what makes an outfit feel busy.</p>

<h2>The dupatta is your variable</h2>
<ul>
    <li><strong>Over one shoulder</strong> — the classic, tidy way; best for functions where you will sit for long periods.</li>
    <li><strong>Both shoulders, pinned</strong> — formal, elegant, and keeps your hands free.</li>
    <li><strong>Wrapped like a scarf</strong> — instantly modern; works especially well with straight-cut shirts.</li>
    <li><strong>Held loosely in one hand</strong> — relaxed and editorial; good for photos and walking-heavy events.</li>
</ul>
<p>If the dupatta is a heavy formal weave, folding it once across the shoulder is more comfortable than letting it hang full width.</p>

<h2>Swap the trousers to change the silhouette</h2>
<p>Wide trousers with a short shirt, cigarette pants with a long kameez, a straight shalwar with a classic cut — the same shirt reads differently with each. This is one advantage of buying <a href="category.php?slug=unstitched">unstitched three-piece suits</a>: you control the cut of every piece.</p>

<h2>Finish with intention</h2>
<p>Match your footwear to the occasion, not automatically to the outfit — khussas dress a printed lawn down to festive, while a slim heel lifts the same suit to formal. Keep jewellery to one focus: jhumkas <em>or</em> a necklace, rarely both at full size.</p>

<p>See the full <a href="category.php?slug=three-piece">three-piece collection</a> for outfits built to be styled this way.</p>
HTML,
    ],
    [
        'cat' => 'fabrics',
        'title' => 'Best Fabrics for Pakistani Summer Clothing',
        'slug' => 'best-fabrics-for-pakistani-summer',
        'excerpt' => 'From May heat to humid coastal days — which fabrics actually keep you cool, and which only look like they do.',
        'meta_title' => 'Best Fabrics for Pakistani Summer Clothing | Fashlab Studio',
        'meta_description' => 'A practical guide to summer fabrics in Pakistan — lawn, cotton, linen and chiffon compared for breathability, comfort and coverage.',
        'content' => <<<HTML
<p>Pakistani summers are long, and the wrong fabric makes every hour of them worse. Here is how the usual summer fabrics actually behave, so you can choose for the day you are dressing for — not just the colour on the hanger.</p>

<h2>Lawn — the everyday answer</h2>
<p>Lightweight, finely woven cotton: excellent airflow, soft against skin, and light enough for a full day out. Lawn is at its best in dry heat. Its weakness is exactly its lightness — very fine lawn can be sheer, so check the weave or keep a slip nearby. Best for: daily wear, office, daytime functions.</p>

<h2>Cotton cambric and slub cotton — the structured option</h2>
<p>Slightly heavier than lawn, with more body. Cambric holds a crisp silhouette and is less likely to go sheer, which makes it a favourite for tailored shirts and trousers. Slub cotton has a visible texture that hides creasing better — useful on days you cannot iron twice.</p>

<h2>Linen — the breathable one with opinions</h2>
<p>Linen breathes beautifully and handles humidity well, making it well suited to Karachi-style coastal heat. It wrinkles — that is linen being linen. If you like a relaxed, lived-in look, it is a feature; if you need a sharp crease all day, choose cotton instead.</p>

<h2>Chiffon and georgette — for evenings</h2>
<p>Sheer, flowy and dressier, chiffon works for evening events where you will be indoors or out of the sun. It is not a noon-in-June fabric; wear it when the temperature drops or the venue has air conditioning.</p>

<h2>What to avoid in peak summer</h2>
<ul>
    <li>Heavy velvet and thick khaddar — they belong to winter, no matter how good the colour looks.</li>
    <li>Synthetic satins with no breathability — shiny and warm.</li>
    <li>Dark colours for full-day outdoor wear — they absorb heat; reserve them for evening.</li>
</ul>

<h2>One care tip that extends every summer outfit</h2>
<p>Wash in cool water, dry in shade. Sun-dried dark cotton fades fast, and faded fabric looks tired long before it wears out.</p>

<p>Shop the seasonal fabric edits: <a href="category.php?slug=lawn-collection">lawn</a>, <a href="category.php?slug=cotton-collection">cotton</a> and <a href="category.php?slug=linen-collection">linen</a>.</p>
HTML,
    ],
    [
        'cat' => 'fashion',
        'title' => 'How to Choose Women\'s Formal Wear',
        'slug' => 'how-to-choose-womens-formal-wear',
        'excerpt' => 'Formal dressing is about reading the room and dressing with intent. A clear framework for choosing the right formal outfit.',
        'meta_title' => 'How to Choose Women\'s Formal Wear | Fashlab Studio',
        'meta_description' => 'How to choose formal wear for women in Pakistan — occasion level, fabric, colour, embellishment and fit, without overdoing it.',
        'content' => <<<HTML
<p>Formal wear fails in two directions: too little (you feel underdressed all evening) or too much (the outfit wears you). Choosing well is mostly about reading the occasion correctly and then letting one element lead.</p>

<h2>Start with the occasion, not the outfit</h2>
<p>Ask three questions: Is it daytime or evening? Indoor or outdoor? Traditional or contemporary? A daytime outdoor gathering wants lighter fabrics and softer colours; an evening indoor function can carry darker tones, heavier embellishment and sheen. A corporate formal event sits at the restrained end — clean lines, minimal sparkle.</p>

<h2>Let the fabric do the formality</h2>
<ul>
    <li><strong>Raw silk and tissue</strong> — structured, polished, immediately formal.</li>
    <li><strong>Chiffon and georgette</strong> — flowy and dressy; ideal for evening functions.</li>
    <li><strong>Embroidered cotton and lawn</strong> — smart-casual; perfect for daytime events.</li>
    <li><strong>Velvet</strong> — winter formality; rich without needing heavy embellishment.</li>
</ul>

<h2>Pick one statement, keep the rest quiet</h2>
<p>If the shirt is heavily embroidered, keep the dupatta plainer and the jewellery small. If the outfit is solid and minimal, one pair of statement earrings or a heavily worked dupatta provides the focus. Two loud elements fight each other; one loud element looks deliberate.</p>

<h2>Colour: follow the time of day</h2>
<p>Daytime favours pastels, ivory, soft jewel tones. Evening welcomes black, deep emerald, maroon, gold. For wedding-adjacent events, check the family's colour preferences first — some palettes are traditionally reserved, and arriving in the bride's colour is the one mistake no one forgets.</p>

<h2>Fit is the final layer of formality</h2>
<p>An ordinary fabric tailored perfectly looks more expensive than a luxurious fabric pulled badly. Check the shoulder seam — it should sit at your shoulder edge, not down your arm. Check sleeve length while raising your arm. If the kameez sits right, everything else forgives.</p>

<p>Browse <a href="category.php?slug=formal-wear">women's formal wear</a> or the richer <a href="category.php?slug=luxury-collection">luxury collection</a>.</p>
HTML,
    ],
    [
        'cat' => 'fashion',
        'title' => 'What to Wear to a Pakistani Wedding',
        'slug' => 'what-to-wear-to-a-pakistani-wedding',
        'excerpt' => 'Mehndi, nikkah, walima — each event has its own energy. A guest\'s guide to dressing right for every function.',
        'meta_title' => 'What to Wear to a Pakistani Wedding | Fashlab Studio Style Journal',
        'meta_description' => 'A practical guest guide to dressing for a Pakistani wedding — what works for mehndi, nikkah and walima, plus comfort and colour tips.',
        'content' => <<<HTML
<p>A Pakistani wedding is rarely one event — it is three or four, each with its own mood. Dressing well as a guest means matching the energy of each function without outshining the hosts. Here is a simple map.</p>

<h2>Mehndi — colour and comfort</h2>
<p>The relaxed, high-energy one. This is where yellow, orange, green and hot pink belong. Go for lighter fabrics and easy silhouettes — you will be sitting on the floor, dancing, and eating from a low table. A printed or embroidered lawn or cotton three-piece with a bright dupatta fits the mood perfectly. Skip the heels you cannot walk in; khussas or flat sandals are both traditional and practical.</p>

<h2>Nikkah — elegant and refined</h2>
<p>The ceremony itself is quieter and often daytime. Soft tones — ivory, blush, powder blue, sage — with neat tailoring read best here. If you are close family, a modest amount of embellishment is appropriate; for distant guests, clean lines with good jewellery say more than heavy work. A pinned, draped dupatta adds formality without effort.</p>

<h2>Walima — the formal one</h2>
<p>This is where formal fabrics earn their place: chiffon, raw silk, embroidered formal sets in jewel tones or classic pastels. A floor-length or long shirt with a flowing dupatta photographs beautifully under evening lighting. If the walima is a daytime brunch, dial back to structured cottons and softer colours.</p>

<h2>Three things that work at every function</h2>
<ul>
    <li><strong>A well-fitted outfit you can sit in for hours</strong> — comfort is visible; discomfort is more visible.</li>
    <li><strong>One focus for accessories</strong> — a clutch, earrings or a statement dupatta, not all three competing.</li>
    <li><strong>A shawl or wrap</strong> — air-conditioned halls and winter terraces are colder than they look.</li>
</ul>

<h2>A note on colour etiquette</h2>
<p>Avoid pure white and the exact palette the bride has announced, unless the family suggests it. Beyond that, wear what makes you feel good — a guest who is comfortable and confident always looks better dressed than one who followed every rule reluctantly.</p>

<p>Find your function's outfit in <a href="category.php?slug=formal-wear">formal wear</a>, <a href="category.php?slug=festive-collection">festive collection</a> and <a href="category.php?slug=eid-collection">Eid collection</a>.</p>
HTML,
    ],
    [
        'cat' => 'styling',
        'title' => '2 Piece vs 3 Piece Suits: What Is the Actual Difference?',
        'slug' => '2-piece-vs-3-piece-suits',
        'excerpt' => 'Two pieces or three? The difference is more than one dupatta — it changes how you style, layer and wear the outfit.',
        'meta_title' => '2 Piece vs 3 Piece Suits in Pakistan | Fashlab Studio',
        'meta_description' => 'What separates a two-piece suit from a three-piece — contents, styling flexibility, value and how to choose between them.',
        'content' => <<<HTML
<p>On the rack, a two-piece and a three-piece can look almost identical. In the wardrobe they behave very differently. The difference is not just one extra piece of fabric — it is about how much styling freedom the outfit gives you afterwards.</p>

<h2>What is actually in each</h2>
<p>A <strong>two-piece suit</strong> is usually a shirt piece and a trouser piece (some brands mean shirt + dupatta, so always check the contents list). A <strong>three-piece suit</strong> adds the dupatta — shirt, trouser and dupatta — giving you the complete traditional set.</p>

<h2>What a two-piece gives you</h2>
<ul>
    <li>Lower cost for the same fabric quality — you are paying for two pieces, not three.</li>
    <li>Simpler daily dressing; no dupatta to manage at work or while travelling.</li>
    <li>Freedom to pair the shirt with your own trousers or jeans — a printed shirt over plain trousers is its own look.</li>
    <li>Less fabric to carry in summer heat.</li>
</ul>

<h2>What a three-piece gives you</h2>
<ul>
    <li>A complete, coordinated outfit with zero mixing decisions.</li>
    <li>The dupatta as a styling tool — see our guide on <a href="journal-article.php?slug=how-to-style-a-pakistani-3-piece-suit">styling a three-piece suit</a>.</li>
    <li>Modesty and formality when the occasion needs it — a dupatta instantly dresses an outfit up.</li>
    <li>Better value for events: one purchase covers the whole function.</li>
</ul>

<h2>So which should you buy?</h2>
<p>If you are building everyday work or college wear, two-piece is the practical base — more outfits per rupee and easier to live in. If you are shopping for functions, family gatherings or anywhere a dupatta completes the look, three-piece is the right call. Many wardrobes end up with both: two-pieces for the week, three-pieces for the calendar's better days.</p>

<p>Browse <a href="category.php?slug=two-piece">two-piece suits</a> and <a href="category.php?slug=three-piece">three-piece suits</a>.</p>
HTML,
    ],
];

$inserted = 0;
$skipped  = 0;

foreach ($articles as $a) {
    $stmt = $db->prepare('SELECT 1 FROM journal_posts WHERE slug = ? LIMIT 1');
    $stmt->execute([$a['slug']]);
    if ($stmt->fetch()) {
        $skipped++;
        continue;
    }
    $catId = $catIds[$a['cat']] ?? null;
    $stmt = $db->prepare(
        "INSERT INTO journal_posts (category_id, title, slug, excerpt, content, author, status, published_at, meta_title, meta_description)
         VALUES (?,?,?,?,?,?,'published',NOW(),?,?)"
    );
    $stmt->execute([$catId, $a['title'], $a['slug'], $a['excerpt'], $a['content'], $store, $a['meta_title'], $a['meta_description']]);
    $inserted++;
}

echo "Journal seed complete: {$inserted} inserted, {$skipped} already present.\n";
