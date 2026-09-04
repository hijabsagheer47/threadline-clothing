<?php
declare(strict_types=1);
require_once __DIR__ . '/includes/bootstrap.php';

$items  = cart_items();
$totals = cart_totals();
$errors = [];
$old    = [];

/* ---------------------------------------------------------------------------
   POST: place the order
--------------------------------------------------------------------------- */
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    csrf_require($_POST['csrf_token'] ?? null);

    $old = [
        'fullName'  => post('fullName', 120),
        'email'     => post('email', 150),
        'phone'     => post('phone', 30),
        'city'      => post('city', 100),
        'address'   => post('address', 255),
        'postal'    => post('postalCode', 20),
        'delivery'  => post('delivery', 20),
        'payment'   => post('payment', 30),
        'notes'     => post_text('notes', 1000),
    ];

    if ($old['fullName'] === '')                       $errors['fullName'] = 'Please enter your full name.';
    if (!valid_email($old['email']))                   $errors['email'] = 'Please enter a valid email address.';
    if (!valid_phone($old['phone']))                   $errors['phone'] = 'Please enter a valid phone number.';
    if ($old['city'] === '')                           $errors['city'] = 'Please enter your city.';
    if ($old['address'] === '')                        $errors['address'] = 'Please enter your complete address.';
    if (!in_array($old['delivery'], ['standard', 'express'], true)) $old['delivery'] = 'standard';
    // Card is not wired to a gateway yet, so accepting it would create an
    // order that can never be settled. COD is forced until one exists.
    $old['payment'] = 'cod';

    if (!$items) {
        $errors['cart'] = 'Your cart is empty.';
    }

    if (!$errors && $totals['has_unavailable']) {
        $errors['cart'] = 'One or more items in your cart are no longer available. Please review your cart.';
    }

    if (!$errors) {
        $deliveryFee = $totals['shipping'];
        if ($old['delivery'] === 'express') {
            $deliveryFee += 250;
        }

        $orderNumber = 'TC-' . date('Ymd') . '-' . strtoupper(substr(bin2hex(random_bytes(4)), 0, 6));

        try {
            $db = db();

            $stmt = $db->prepare(
                'INSERT INTO orders (order_number, customer_name, customer_email, customer_phone,
                                     shipping_address, city, postal_code, notes,
                                     subtotal, shipping_fee, discount, total,
                                     payment_method, payment_status, order_status)
                 VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)'
            );
            $stmt->execute([
                $orderNumber,
                $old['fullName'],
                $old['email'],
                $old['phone'],
                $old['address'],
                $old['city'],
                $old['postal'],
                $old['notes'],
                decimal($totals['subtotal']),
                decimal($deliveryFee),
                decimal($totals['discount']),
                decimal($totals['subtotal'] + $deliveryFee - $totals['discount']),
                'cod',
                'pending',
                'pending',
            ]);
            $orderId = (int) $db->lastInsertId();

            $itemStmt = $db->prepare(
                'INSERT INTO order_items (order_id, product_id, product_name, quantity, price, subtotal)
                 VALUES (?, ?, ?, ?, ?, ?)'
            );
            $stockStmt = $db->prepare(
                'UPDATE products SET stock_quantity = GREATEST(0, stock_quantity - ?) WHERE id = ?'
            );
            $variantStockStmt = $db->prepare(
                'UPDATE product_variants SET stock_quantity = GREATEST(0, stock_quantity - ?) WHERE id = ?'
            );

            foreach ($items as $item) {
                $itemStmt->execute([
                    $orderId,
                    (int) $item['product_id'],
                    $item['name'],
                    (int) $item['qty'],
                    decimal($item['unit_price']),
                    decimal($item['line_total']),
                ]);
                $stockStmt->execute([(int) $item['qty'], (int) $item['product_id']]);
                if (!empty($item['variant_id'])) {
                    $variantStockStmt->execute([(int) $item['qty'], (int) $item['variant_id']]);
                }
            }

            cart_clear();

            $_SESSION['last_order'] = [
                'order_number' => $orderNumber,
                'customer_name' => $old['fullName'],
                'phone' => $old['phone'],
                'payment_method' => 'Cash on Delivery',
                'total' => $totals['subtotal'] + $deliveryFee - $totals['discount'],
                'items' => array_map(static fn($it) => [
                    'name' => $it['name'], 'qty' => $it['qty'], 'price' => $it['unit_price'],
                ], $items),
            ];

            redirect(url('/order-confirmation.php'));
        } catch (PDOException $ex) {
            error_log('[checkout] ' . $ex->getMessage());
            $errors['cart'] = 'We could not place your order right now. Please try again.';
        }
    }
}

$page_title       = 'Checkout';
$meta_description = 'Complete your order with TayyabaCollective.';
$active_nav       = 'shop.php';

require __DIR__ . '/includes/storefront-header.php';
?>

<section class="checkout-hero">
    <h1>Checkout</h1>
    <p>Complete your order with TayyabaCollective.</p>
</section>

<div class="checkout-container">

    <?php if (!$items): ?>
        <div class="empty-checkout">
            <h2>Your Cart Is Empty</h2>
            <p>Please add some products before proceeding to checkout.</p>
            <a href="<?= url('/shop.php') ?>" class="continue-shopping">Continue Shopping</a>
        </div>
    <?php else: ?>

        <?php if ($errors): ?>
            <div class="flash flash-error">
                <span>
                    <?php foreach ($errors as $err): ?>
                        <?= e($err) ?><br>
                    <?php endforeach; ?>
                </span>
            </div>
        <?php endif; ?>

        <div class="checkout-grid">

            <div class="checkout-form">
                <form id="checkoutForm" method="post" action="<?= e(url('/checkout.php')) ?>" novalidate>
                    <?= csrf_field() ?>

                    <!-- CONTACT INFORMATION -->
                    <section class="checkout-section">
                        <div class="checkout-section-title">
                            <span class="checkout-section-number">1</span>
                            <h2>Contact Information</h2>
                        </div>

                        <div class="form-row">
                            <div class="form-group">
                                <label for="fullName">Full Name <span class="required">*</span></label>
                                <input type="text" id="fullName" name="fullName" placeholder="Enter your full name"
                                       value="<?= e($old['fullName'] ?? '') ?>" required>
                                <?php if (isset($errors['fullName'])): ?><p class="field-error"><?= e($errors['fullName']) ?></p><?php endif; ?>
                            </div>
                            <div class="form-group">
                                <label for="email">Email Address <span class="required">*</span></label>
                                <input type="email" id="email" name="email" placeholder="you@example.com"
                                       value="<?= e($old['email'] ?? '') ?>" required>
                                <?php if (isset($errors['email'])): ?><p class="field-error"><?= e($errors['email']) ?></p><?php endif; ?>
                            </div>
                        </div>

                        <div class="form-row">
                            <div class="form-group">
                                <label for="phone">Phone Number <span class="required">*</span></label>
                                <input type="tel" id="phone" name="phone" placeholder="03XX XXXXXXX"
                                       value="<?= e($old['phone'] ?? '') ?>" required>
                                <?php if (isset($errors['phone'])): ?><p class="field-error"><?= e($errors['phone']) ?></p><?php endif; ?>
                            </div>
                            <div class="form-group">
                                <label for="city">City <span class="required">*</span></label>
                                <input type="text" id="city" name="city" placeholder="Islamabad"
                                       value="<?= e($old['city'] ?? '') ?>" required>
                                <?php if (isset($errors['city'])): ?><p class="field-error"><?= e($errors['city']) ?></p><?php endif; ?>
                            </div>
                        </div>

                        <div class="form-row">
                            <div class="form-group">
                                <label for="address">Complete Address <span class="required">*</span></label>
                                <input type="text" id="address" name="address" placeholder="House No, Street, Area"
                                       value="<?= e($old['address'] ?? '') ?>" required>
                                <?php if (isset($errors['address'])): ?><p class="field-error"><?= e($errors['address']) ?></p><?php endif; ?>
                            </div>
                            <div class="form-group">
                                <label for="postalCode">Postal Code</label>
                                <input type="text" id="postalCode" name="postalCode" placeholder="44000"
                                       value="<?= e($old['postal'] ?? '') ?>">
                            </div>
                        </div>
                    </section>

                    <!-- DELIVERY -->
                    <section class="checkout-section">
                        <div class="checkout-section-title">
                            <span class="checkout-section-number">2</span>
                            <h2>Delivery Method</h2>
                        </div>

                        <div class="delivery-options">
                            <div class="delivery-option">
                                <input type="radio" id="standardDelivery" name="delivery" value="standard"
                                       <?= ($old['delivery'] ?? 'standard') === 'standard' ? 'checked' : '' ?>>
                                <label for="standardDelivery" class="delivery-label">
                                    <div class="delivery-left">
                                        <span class="radio-circle"></span>
                                        <div class="delivery-info">
                                            <strong>Standard Delivery</strong>
                                            <span>Delivery within 3–5 working days</span>
                                        </div>
                                    </div>
                                    <span class="delivery-price" id="standardPrice">
                                        <?= $totals['shipping'] > 0 ? money($totals['shipping']) : 'FREE' ?>
                                    </span>
                                </label>
                            </div>
                            <div class="delivery-option">
                                <input type="radio" id="expressDelivery" name="delivery" value="express"
                                       <?= ($old['delivery'] ?? '') === 'express' ? 'checked' : '' ?>>
                                <label for="expressDelivery" class="delivery-label">
                                    <div class="delivery-left">
                                        <span class="radio-circle"></span>
                                        <div class="delivery-info">
                                            <strong>Express Delivery</strong>
                                            <span>Faster delivery within 1–2 working days</span>
                                        </div>
                                    </div>
                                    <span class="delivery-price" id="expressPrice">
                                        <?= money(max(0, $totals['shipping']) + 250) ?>
                                    </span>
                                </label>
                            </div>
                        </div>
                    </section>

                    <!-- PAYMENT -->
                    <section class="checkout-section">
                        <div class="checkout-section-title">
                            <span class="checkout-section-number">3</span>
                            <h2>Payment Method</h2>
                        </div>

                        <div class="payment-options">
                            <div class="payment-option">
                                <input type="radio" id="cod" name="payment" value="cod" checked>
                                <label for="cod" class="payment-label">
                                    <div class="payment-icon"><i class="fa-solid fa-hand-holding-dollar"></i></div>
                                    <div>
                                        <strong>Cash on Delivery</strong>
                                        <span>Pay in cash when your parcel reaches you</span>
                                    </div>
                                    <span class="pay-flag">Recommended</span>
                                </label>
                            </div>
                            <div class="payment-option is-disabled">
                                <input type="radio" id="card" name="payment" value="card" disabled>
                                <label for="card" class="payment-label">
                                    <div class="payment-icon"><i class="fa-solid fa-credit-card"></i></div>
                                    <div>
                                        <strong>Card / Online Payment</strong>
                                        <span>Coming soon</span>
                                    </div>
                                </label>
                            </div>
                        </div>
                        <div class="card-note">
                            <i class="fa-solid fa-circle-info"></i>
                            <span>Online card payment is not live yet, so every order is placed as
                            <strong>Cash on Delivery</strong> &mdash; you pay the courier at your door.</span>
                        </div>
                    </section>

                    <!-- NOTES -->
                    <section class="checkout-section">
                        <div class="checkout-section-title">
                            <span class="checkout-section-number">4</span>
                            <h2>Order Notes</h2>
                        </div>
                        <div class="form-group">
                            <label for="notes">Additional Notes</label>
                            <textarea id="notes" name="notes" placeholder="Any special instructions for your order..."><?= e($old['notes'] ?? '') ?></textarea>
                        </div>
                    </section>

                    <button type="submit" class="btn btn-primary checkout-submit">PLACE ORDER</button>
                </form>
            </div>

            <!-- ORDER SUMMARY -->
            <aside class="order-summary">
                <h2>Your Order</h2>

                <div class="checkout-products" id="checkoutProducts">
                    <?php foreach ($items as $item): ?>
                        <div class="checkout-product">
                            <img src="<?= e($item['image']) ?>" alt="<?= e($item['name']) ?>" class="checkout-product-image">
                            <div class="checkout-product-info">
                                <h3><?= e($item['name']) ?></h3>
                                <?php if ($item['variant_label']): ?><p><?= e($item['variant_label']) ?></p><?php endif; ?>
                                <p>Quantity: <?= (int) $item['qty'] ?></p>
                            </div>
                            <div class="checkout-product-price"><?= money($item['line_total']) ?></div>
                        </div>
                    <?php endforeach; ?>
                </div>

                <div class="summary-lines">
                    <div class="summary-line"><span>Subtotal</span><strong><?= money($totals['subtotal']) ?></strong></div>
                    <div class="summary-line"><span>Shipping</span><strong id="checkoutShipping"><?= $totals['shipping'] > 0 ? money($totals['shipping']) : 'FREE' ?></strong></div>
                    <?php if ($totals['discount'] > 0): ?>
                        <div class="summary-line"><span>Discount</span><strong>-<?= money($totals['discount']) ?></strong></div>
                    <?php endif; ?>
                </div>

                <div class="summary-total">
                    <span>Total</span>
                    <span id="checkoutTotal"><?= money($totals['total']) ?></span>
                </div>

                <div class="secure-note"><i class="fa-solid fa-lock"></i> Secure &amp; encrypted checkout</div>
            </aside>

        </div>
    <?php endif; ?>
</div>

<script>
    window.TC_CHECKOUT = {
        shipping: <?= (float) $totals['shipping'] ?>,
        subtotal: <?= (float) $totals['subtotal'] ?>,
        expressExtra: 250
    };
</script>

<?php require __DIR__ . '/includes/storefront-footer.php'; ?>