<?php
declare(strict_types=1);
require_once __DIR__ . '/includes/bootstrap.php';

$errors = [];
$sent   = false;
$old    = [];

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    csrf_require($_POST['csrf_token'] ?? null);

    $old = [
        'name'    => post('name', 120),
        'email'   => post('email', 150),
        'phone'   => post('phone', 30),
        'subject' => post('subject', 200),
        'message' => post_text('message', 5000),
    ];

    if ($old['name'] === '')              $errors['name'] = 'Please enter your name.';
    if (!valid_email($old['email']))      $errors['email'] = 'Please enter a valid email address.';
    if ($old['subject'] === '')           $errors['subject'] = 'Please enter a subject.';
    if (mb_strlen($old['message']) < 10)  $errors['message'] = 'Please write a message of at least 10 characters.';

    if (!$errors) {
        try {
            $stmt = db()->prepare(
                'INSERT INTO contact_messages (name, email, phone, subject, message) VALUES (?, ?, ?, ?, ?)'
            );
            $stmt->execute([$old['name'], $old['email'], $old['phone'], $old['subject'], $old['message']]);
            $sent = true;
            $old = [];
        } catch (PDOException $ex) {
            error_log('[contact] ' . $ex->getMessage());
            $errors['form'] = 'We could not send your message right now. Please try again shortly.';
        }
    }
}

$storeEmail   = setting('store_email', 'hello@tayyabacollective.mytechrcm.com');
$storePhone   = setting('store_phone', '+92 300 1234567');
$storeAddress = setting('store_address', 'TayyabaCollective Studio, Islamabad, Pakistan');

$page_title       = 'Contact Us';
$meta_description = 'Get in touch with ' . setting('store_name') . ' — questions about collections, orders, shipping and more.';
$active_nav       = 'contact.php';

require __DIR__ . '/includes/storefront-header.php';
?>

<main class="contact-page">

    <!-- HERO -->
    <section class="contact-hero">
        <h1>Get in Touch</h1>
        <p>Have a question about our collections, your order, shipping or anything else? We'd love to hear from you.</p>
    </section>

    <!-- CONTACT INFO + FORM -->
    <section class="contact-container">
        <div class="contact-grid">

            <div class="contact-info">
                <div class="small-heading">We'd Love To Hear From You</div>
                <h2>Let's Start a Conversation</h2>
                <p>Whether you need help choosing the perfect outfit, have a question about your order, or simply want to know more about <?= e(setting('store_name')) ?>, our team is here to help.</p>

                <div class="contact-details">
                    <div class="contact-detail">
                        <div class="contact-icon"><i class="fa-solid fa-location-dot" aria-hidden="true"></i></div>
                        <div>
                            <h3>Address</h3>
                            <p><?= nl2br(e($storeAddress)) ?></p>
                        </div>
                    </div>
                    <div class="contact-detail">
                        <div class="contact-icon"><i class="fa-solid fa-phone" aria-hidden="true"></i></div>
                        <div>
                            <h3>Phone</h3>
                            <a href="tel:<?= e(preg_replace('/[^0-9+]/', '', $storePhone)) ?>"><?= e($storePhone) ?></a>
                        </div>
                    </div>
                    <div class="contact-detail">
                        <div class="contact-icon"><i class="fa-solid fa-envelope" aria-hidden="true"></i></div>
                        <div>
                            <h3>Email</h3>
                            <a href="mailto:<?= e($storeEmail) ?>"><?= e($storeEmail) ?></a>
                        </div>
                    </div>
                    <div class="contact-detail">
                        <div class="contact-icon"><i class="fa-regular fa-clock" aria-hidden="true"></i></div>
                        <div>
                            <h3>Opening Hours</h3>
                            <p>Monday – Saturday<br>10:00 AM – 7:00 PM</p>
                        </div>
                    </div>
                </div>

                <div class="contact-social">
                    <h3>Follow <?= e(setting('store_name')) ?></h3>
                    <div class="social-links">
                        <a class="s-instagram" href="<?= e(setting('instagram_url', '#')) ?>" aria-label="Instagram" target="_blank" rel="noopener noreferrer"><i class="fa-brands fa-instagram"></i></a>
                        <a class="s-facebook" href="<?= e(setting('facebook_url', '#')) ?>" aria-label="Facebook" target="_blank" rel="noopener noreferrer"><i class="fa-brands fa-facebook-f"></i></a>
                        <a class="s-linkedin" href="<?= e(setting('linkedin_url', '#')) ?>" aria-label="LinkedIn" target="_blank" rel="noopener noreferrer"><i class="fa-brands fa-linkedin-in"></i></a>
                        <?php $waUrl = whatsapp_url('Hello! I have a question.'); if ($waUrl !== ''): ?>
                        <a class="s-whatsapp" href="<?= e($waUrl) ?>" aria-label="WhatsApp" target="_blank" rel="noopener noreferrer"><i class="fa-brands fa-whatsapp"></i></a>
                        <?php endif; ?>
                    </div>
                </div>
            </div>

            <div class="contact-form-wrapper">
                <h2>Send Us a Message</h2>
                <p>Fill out the form below and our team will get back to you as soon as possible.</p>

                <?php if ($sent): ?>
                    <div class="flash flash-success">
                        <span>Thank you for contacting <?= e(setting('store_name')) ?>. Your message has been received and we will reply shortly.</span>
                    </div>
                <?php endif; ?>

                <?php if (!empty($errors['form'])): ?>
                    <div class="flash flash-error"><span><?= e($errors['form']) ?></span></div>
                <?php endif; ?>

                <form class="contact-form" id="contactForm" method="post" action="<?= e(url('/contact.php')) ?>" novalidate>
                    <?= csrf_field() ?>

                    <div class="form-row">
                        <div class="form-group">
                            <label for="name">Name <span class="required">*</span></label>
                            <input type="text" id="name" name="name" placeholder="Your full name" value="<?= e($old['name'] ?? '') ?>" required>
                            <?php if (isset($errors['name'])): ?><p class="field-error"><?= e($errors['name']) ?></p><?php endif; ?>
                        </div>
                        <div class="form-group">
                            <label for="email">Email <span class="required">*</span></label>
                            <input type="email" id="email" name="email" placeholder="you@example.com" value="<?= e($old['email'] ?? '') ?>" required>
                            <?php if (isset($errors['email'])): ?><p class="field-error"><?= e($errors['email']) ?></p><?php endif; ?>
                        </div>
                    </div>

                    <div class="form-group">
                        <label for="phone">Phone <span class="optional">(optional)</span></label>
                        <input type="tel" id="phone" name="phone" placeholder="03XX XXXXXXX" value="<?= e($old['phone'] ?? '') ?>">
                    </div>

                    <div class="form-group">
                        <label for="subject">Subject <span class="required">*</span></label>
                        <input type="text" id="subject" name="subject" placeholder="How can we help?" value="<?= e($old['subject'] ?? '') ?>" required>
                        <?php if (isset($errors['subject'])): ?><p class="field-error"><?= e($errors['subject']) ?></p><?php endif; ?>
                    </div>

                    <div class="form-group">
                        <label for="message">Message <span class="required">*</span></label>
                        <textarea id="message" name="message" placeholder="Write your message here..." required><?= e($old['message'] ?? '') ?></textarea>
                        <?php if (isset($errors['message'])): ?><p class="field-error"><?= e($errors['message']) ?></p><?php endif; ?>
                    </div>

                    <button type="submit" class="send-message-btn">Send Message</button>
                </form>
            </div>
        </div>
    </section>

    <!-- FAQ -->
    <section class="faq-section">
        <div class="faq-container">
            <div class="faq-heading">
                <div class="small-heading">Frequently Asked Questions</div>
                <h2>How Can We Help?</h2>
                <p>Find quick answers to some of our most common questions.</p>
            </div>

            <div class="faq-list">
                <div class="faq-item">
                    <button class="faq-question" type="button"><span>How long does delivery take?</span><i class="fa-solid fa-chevron-down faq-chevron" aria-hidden="true"></i></button>
                    <div class="faq-answer">Standard delivery usually takes 3–5 working days, while express delivery takes approximately 1–2 working days.</div>
                </div>
                <div class="faq-item">
                    <button class="faq-question" type="button"><span>Do you offer cash on delivery?</span><i class="fa-solid fa-chevron-down faq-chevron" aria-hidden="true"></i></button>
                    <div class="faq-answer">Yes, we offer Cash on Delivery across Pakistan. You can also pay securely online at checkout where available.</div>
                </div>
                <div class="faq-item">
                    <button class="faq-question" type="button"><span>What is your return policy?</span><i class="fa-solid fa-chevron-down faq-chevron" aria-hidden="true"></i></button>
                    <div class="faq-answer">We offer a 7-day return and exchange policy on unworn items in their original packaging.</div>
                </div>
                <div class="faq-item">
                    <button class="faq-question" type="button"><span>How do I know which size to order?</span><i class="fa-solid fa-chevron-down faq-chevron" aria-hidden="true"></i></button>
                    <div class="faq-answer">Each product page lists available sizes. If you need help choosing, message us with your measurements and we will guide you.</div>
                </div>
            </div>
        </div>
    </section>

    <!-- CTA -->
    <section class="contact-bottom-cta">
        <div class="container">
            <h2>Prefer To Talk?</h2>
            <p>Call us at <a href="tel:<?= e(preg_replace('/[^0-9+]/', '', $storePhone)) ?>"><?= e($storePhone) ?></a> during opening hours and our team will be happy to help.</p>
        </div>
    </section>

</main>

<?php require __DIR__ . '/includes/storefront-footer.php'; ?>