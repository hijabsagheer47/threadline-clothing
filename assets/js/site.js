/* ============================================================================
   TayyabaCollective — storefront scripts
   Vanilla JavaScript, no dependencies.
   ============================================================================ */
(function () {
    'use strict';

    /* ---------------------------------------------------------------- utils */
    function qs(sel, root) { return (root || document).querySelector(sel); }
    function qsa(sel, root) { return Array.prototype.slice.call((root || document).querySelectorAll(sel)); }
    function csrfToken() {
        var meta = qs('meta[name="csrf-token"]');
        return meta ? meta.getAttribute('content') : '';
    }
    function baseUrl() {
        return (window.TC_SETTINGS && TC_SETTINGS.baseUrl) || '';
    }
    function flash(type, message) {
        var el = document.createElement('div');
        el.className = 'flash flash-' + type;
        el.innerHTML = '<span></span><button type="button" class="flash-close" aria-label="Dismiss">&times;</button>';
        qs('span', el).textContent = message;
        var main = qs('main');
        if (main) main.prepend(el);
        else document.body.prepend(el);
        bindFlashDismiss();
        setTimeout(function () { el.classList.add('flash-hide'); }, 5000);
    }
    function bindFlashDismiss() {
        qsa('.flash-close').forEach(function (btn) {
            btn.addEventListener('click', function () {
                var f = btn.closest('.flash');
                if (f) f.remove();
            });
        });
    }
    function money(n) {
        return (window.TC_SETTINGS && TC_SETTINGS.currencySymbol || 'Rs.') + ' ' + Number(n || 0).toLocaleString('en-PK', { maximumFractionDigits: 0 });
    }

    /* --------------------------------------------------------- cart (AJAX) */
    function cartFetch(action, payload, onDone) {
        var data = new URLSearchParams();
        data.set('action', action);
        data.set('csrf_token', csrfToken());
        Object.keys(payload || {}).forEach(function (k) { data.set(k, payload[k]); });

        fetch(baseUrl() + '/api/cart.php', {
            method: 'POST',
            headers: { 'X-Requested-With': 'XMLHttpRequest', 'Content-Type': 'application/x-www-form-urlencoded' },
            body: data.toString(),
            credentials: 'same-origin'
        })
            .then(function (r) { return r.json(); })
            .then(function (res) {
                if (!res.ok) { flash('error', res.error || 'Something went wrong.'); return; }
                if (typeof onDone === 'function') onDone(res);
            })
            .catch(function () { flash('error', 'Could not reach the server. Please try again.'); });
    }

    function refreshCartBadge(count) {
        qsa('.cart-count').forEach(function (el) { el.textContent = String(count); });
        qsa('.cart-badge').forEach(function (el) { el.textContent = String(count); });
    }

    /* Mini add-to-cart buttons on product cards */
    function bindMiniCartButtons() {
        qsa('.mini-cart-btn').forEach(function (btn) {
            btn.addEventListener('click', function (ev) {
                ev.preventDefault();
                ev.stopPropagation();
                if (btn.disabled) return;
                var original = btn.textContent;
                btn.textContent = 'Adding…';
                cartFetch('add', {
                    product_id: btn.getAttribute('data-product-id'),
                    qty: 1
                }, function (res) {
                    btn.textContent = 'Added ✓';
                    refreshCartBadge(res.count);
                    setTimeout(function () { btn.textContent = original; }, 1500);
                });
            });
        });
    }

    /* --------------------------------------------------------------- shop */
    function shopState() {
        var params = new URLSearchParams();
        var q = qs('#shop-search');
        if (q && q.value.trim()) params.set('q', q.value.trim());

        qsa('.filter-sidebar input[name="category"]:checked').forEach(function (el) {
            params.append('category', el.value);
        });
        var price = qs('.filter-sidebar input[name="price"]:checked');
        if (price && price.value) params.set('price', price.value);
        qsa('.filter-sidebar input[name="fabric"]:checked').forEach(function (el) { params.set('fabric', el.value); });
        qsa('.filter-sidebar input[name="color"]:checked').forEach(function (el) { params.set('color', el.value); });
        qsa('.filter-sidebar input[name="size"]:checked').forEach(function (el) { params.set('size', el.value); });
        qsa('.filter-sidebar input[name="availability"]:checked').forEach(function (el) { params.set('availability', el.value); });
        qsa('.filter-sidebar input[name="sale"]:checked').forEach(function (el) { params.set('sale', '1'); });
        qsa('.filter-sidebar input[name="featured"]:checked').forEach(function (el) { params.set('featured', '1'); });

        var sort = qs('#sort-products');
        if (sort && sort.value && sort.value !== 'newest') params.set('sort', sort.value);

        return params;
    }

    function buildPagination(params, pages, page) {
        var wrap = qs('#shop-pagination');
        if (!wrap) return;
        if (pages <= 1) { wrap.innerHTML = ''; return; }
        var html = '<nav class="pagination" aria-label="Pagination">';
        if (page > 1) {
            var prev = new URLSearchParams(params); prev.set('page', page - 1);
            html += '<a class="page-link" href="?' + prev.toString() + '" data-page="' + (page - 1) + '">&laquo;</a>';
        }
        var start = Math.max(1, page - 2), end = Math.min(pages, page + 2);
        for (var i = start; i <= end; i++) {
            var p = new URLSearchParams(params); p.set('page', i);
            html += '<a class="page-link' + (i === page ? ' active' : '') + '" href="?' + p.toString() + '" data-page="' + i + '">' + i + '</a>';
        }
        if (page < pages) {
            var next = new URLSearchParams(params); next.set('page', page + 1);
            html += '<a class="page-link" href="?' + next.toString() + '" data-page="' + (page + 1) + '">&raquo;</a>';
        }
        html += '</nav>';
        wrap.innerHTML = html;
        qsa('#shop-pagination a[data-page]').forEach(function (a) {
            a.addEventListener('click', function (ev) {
                ev.preventDefault();
                var p = new URLSearchParams(params); p.set('page', a.getAttribute('data-page'));
                loadShop(p);
            });
        });
    }

    var shopTimer = null;
    function loadShop(params, replaceUrl) {
        if (shopTimer) clearTimeout(shopTimer);
        shopTimer = setTimeout(function () {
            var target = qs('#shop-product-grid');
            if (!target) return;
            target.classList.add('loading');
            var url = window.location.pathname + '?' + params.toString();
            if (replaceUrl !== false) history.replaceState(null, '', url);

            fetch(url, { headers: { 'X-Requested-With': 'XMLHttpRequest' } })
                .then(function (r) { return r.text(); })
                .then(function (html) {
                    target.classList.remove('loading');
                    target.innerHTML = html;
                    var totalEl = qs('#ajax-total', target), pagesEl = qs('#ajax-pages', target), pageEl = qs('#ajax-page', target);
                    var total = totalEl ? parseInt(totalEl.value, 10) : 0;
                    var pages = pagesEl ? parseInt(pagesEl.value, 10) : 1;
                    var page = pageEl ? parseInt(pageEl.value, 10) : 1;
                    if (totalEl) totalEl.remove(); if (pagesEl) pagesEl.remove(); if (pageEl) pageEl.remove();

                    var countEl = qs('#product-count');
                    if (countEl) countEl.textContent = String(total);
                    buildPagination(params, pages, page);
                    bindMiniCartButtons();
                })
                .catch(function () { target.classList.remove('loading'); });
        }, 350);
    }

    function bindShop() {
        if (!qs('.shop-layout')) return;

        var search = qs('#shop-search');
        if (search) {
            var searchTimer = null;
            search.addEventListener('input', function () {
                if (searchTimer) clearTimeout(searchTimer);
                searchTimer = setTimeout(function () { loadShop(shopState()); }, 450);
            });
        }

        var sort = qs('#sort-products');
        if (sort) sort.addEventListener('change', function () { loadShop(shopState()); });

        qsa('.filter-sidebar input').forEach(function (input) {
            input.addEventListener('change', function () { loadShop(shopState()); });
        });

        qsa('.filter-sidebar .clear-filters, .shop-empty .clear-filters').forEach(function (btn) {
            btn.addEventListener('click', function () {
                qsa('.filter-sidebar input').forEach(function (i) {
                    if (i.type === 'radio') i.checked = i.value === '' || (i.name === 'price' && i.value === '');
                    else i.checked = false;
                });
                if (search) search.value = '';
                if (sort) sort.value = 'newest';
                loadShop(shopState());
            });
        });

        /* Mobile filter toggle */
        var toggle = qs('.filter-toggle'), sidebar = qs('#filter-sidebar');
        if (toggle && sidebar) {
            toggle.addEventListener('click', function () { sidebar.classList.add('open'); });
            var close = qs('.filter-close', sidebar);
            if (close) close.addEventListener('click', function () { sidebar.classList.remove('open'); });
        }
    }

    /* ------------------------------------------------------------- product */
    function bindProductPage() {
        if (!qs('.product-details-section')) return;

        /* Gallery */
        var mainImg = qs('#mainProductImage');
        qsa('.product-thumb').forEach(function (thumb) {
            thumb.addEventListener('click', function () {
                var img = qs('img', thumb);
                if (img && mainImg) {
                    mainImg.src = img.src;
                    mainImg.alt = img.alt;
                }
                qsa('.product-thumb').forEach(function (t) { t.classList.remove('active'); });
                thumb.classList.add('active');
            });
        });

        /* Quantity */
        var qtyEl = qs('#quantity');
        qsa('.quantity-selector .qty-btn').forEach(function (btn) {
            btn.addEventListener('click', function () {
                if (!qtyEl) return;
                var current = parseInt(qtyEl.textContent, 10) || 1;
                var delta = parseInt(btn.getAttribute('data-qty'), 10) || 0;
                var next = current + delta;
                var maxStock = window.TC_PRODUCT ? TC_PRODUCT.maxStock : 99;
                if (next < 1) next = 1;
                if (maxStock > 0 && next > maxStock) next = maxStock;
                qtyEl.textContent = String(next);
            });
        });

        /* Color swatches */
        qsa('.color-option').forEach(function (sw) {
            sw.addEventListener('click', function () {
                qsa('.color-option').forEach(function (s) { s.classList.remove('active'); });
                sw.classList.add('active');
                var label = qs('#selectedColor');
                if (label && sw.getAttribute('data-color')) label.textContent = sw.getAttribute('data-color');
            });
        });

        /* Sizes */
        qsa('.size-option').forEach(function (sz) {
            sz.addEventListener('click', function () {
                qsa('.size-option').forEach(function (s) { s.classList.remove('active'); });
                sz.classList.add('active');
            });
        });

        /* Variant select → update displayed price */
        var variantSel = qs('#variantSelect');
        if (variantSel) {
            variantSel.addEventListener('change', function () {
                var opt = variantSel.options[variantSel.selectedIndex];
                var priceEl = qs('.product-price .current-price');
                if (opt && priceEl && opt.getAttribute('data-price')) {
                    priceEl.textContent = money(opt.getAttribute('data-price'));
                }
            });
        }

        /* Add to cart */
        var addBtn = qs('.product-add-cart');
        if (addBtn) {
            addBtn.addEventListener('click', function () {
                if (addBtn.disabled) return;
                var productId = addBtn.getAttribute('data-product-id');
                var variantId = variantSel ? variantSel.value : '';
                var qty = qtyEl ? parseInt(qtyEl.textContent, 10) || 1 : 1;
                var original = addBtn.innerHTML;
                addBtn.disabled = true;
                addBtn.innerHTML = '<i class="fa-solid fa-spinner fa-spin"></i> ADDING…';
                cartFetch('add', { product_id: productId, variant_id: variantId, qty: qty }, function (res) {
                    addBtn.disabled = false;
                    addBtn.innerHTML = '<i class="fa-solid fa-check"></i> ADDED TO CART ✓';
                    refreshCartBadge(res.count);
                    setTimeout(function () { addBtn.innerHTML = original; }, 2000);
                });
            });
        }

        /* Buy now → add then go to checkout */
        var buyBtn = qs('.product-buy-now');
        if (buyBtn) {
            buyBtn.addEventListener('click', function () {
                if (buyBtn.disabled) return;
                var productId = buyBtn.getAttribute('data-product-id');
                var variantId = variantSel ? variantSel.value : '';
                var qty = qtyEl ? parseInt(qtyEl.textContent, 10) || 1 : 1;
                cartFetch('add', { product_id: productId, variant_id: variantId, qty: qty }, function () {
                    window.location.href = baseUrl() + '/checkout.php';
                });
            });
        }

        /* Tabs */
        qsa('.product-tab').forEach(function (tab) {
            tab.addEventListener('click', function () {
                qsa('.product-tab').forEach(function (t) { t.classList.remove('active'); });
                qsa('.product-tab-content').forEach(function (c) { c.classList.remove('active'); });
                tab.classList.add('active');
                var content = qs('#tab-' + tab.getAttribute('data-tab'));
                if (content) content.classList.add('active');
            });
        });
    }

    /* ---------------------------------------------------------------- cart */
    function bindCartPage() {
        if (!qs('.cart-section')) return;

        function reloadCart() {
            window.location.reload();
        }

        qsa('.cart-quantity .qty-btn').forEach(function (btn) {
            btn.addEventListener('click', function () {
                var key = btn.getAttribute('data-key');
                var input = qs('.qty-input[data-key="' + key + '"]');
                var current = input ? parseInt(input.value, 10) || 1 : 1;
                var delta = parseInt(btn.getAttribute('data-qty'), 10) || 0;
                var next = current + delta;
                if (next < 1) next = 1;
                if (input && input.max && next > parseInt(input.max, 10)) next = parseInt(input.max, 10);
                cartFetch('update', { key: key, qty: next }, reloadCart);
            });
        });

        qsa('.qty-input').forEach(function (input) {
            input.addEventListener('change', function () {
                var val = parseInt(input.value, 10) || 1;
                if (val < 1) val = 1;
                cartFetch('update', { key: input.getAttribute('data-key'), qty: val }, reloadCart);
            });
        });

        qsa('.cart-remove').forEach(function (btn) {
            btn.addEventListener('click', function () {
                cartFetch('remove', { key: btn.getAttribute('data-key') }, reloadCart);
            });
        });

        var clearBtn = qs('#clearCart');
        if (clearBtn) {
            clearBtn.addEventListener('click', function () {
                if (!window.confirm('Clear your entire cart?')) return;
                cartFetch('clear', {}, reloadCart);
            });
        }
    }

    /* ------------------------------------------------------------ checkout */
    function bindCheckout() {
        if (!qs('.checkout-page') && !qs('.checkout-container')) return;
        if (!window.TC_CHECKOUT) return;

        function updateTotals() {
            var delivery = qs('input[name="delivery"]:checked');
            var shipping = Number(TC_CHECKOUT.shipping || 0);
            if (delivery && delivery.value === 'express') shipping += Number(TC_CHECKOUT.expressExtra || 250);
            var total = Number(TC_CHECKOUT.subtotal || 0) + shipping;

            var shipEls = qsa('#checkoutShipping, #standardPrice, #expressPrice');
            if (qs('#checkoutShipping')) qs('#checkoutShipping').textContent = shipping > 0 ? money(shipping) : 'FREE';
            if (qs('#checkoutTotal')) qs('#checkoutTotal').textContent = money(total);
        }

        qsa('input[name="delivery"]').forEach(function (radio) {
            radio.addEventListener('change', updateTotals);
        });
        updateTotals();
    }

    /* ---------------------------------------------------------- newsletter */
    function bindNewsletter() {
        qsa('[data-newsletter-form]').forEach(function (form) {
            form.addEventListener('submit', function (ev) {
                ev.preventDefault();
                var email = qs('input[name="email"]', form);
                if (!email || !email.value || email.value.indexOf('@') < 1) {
                    flash('error', 'Please enter a valid email address.');
                    return;
                }
                var btn = qs('button[type="submit"]', form);
                var original = btn.textContent;
                btn.disabled = true;
                btn.textContent = 'Subscribing…';

                var data = new URLSearchParams();
                data.set('email', email.value);
                data.set('csrf_token', csrfToken());

                fetch(baseUrl() + '/api/newsletter.php', {
                    method: 'POST',
                    headers: { 'X-Requested-With': 'XMLHttpRequest', 'Content-Type': 'application/x-www-form-urlencoded' },
                    body: data.toString(),
                    credentials: 'same-origin'
                })
                    .then(function (r) { return r.json(); })
                    .then(function (res) {
                        btn.disabled = false;
                        btn.textContent = original;
                        if (res.ok) {
                            form.innerHTML = '<p class="newsletter-success">' + (res.message || 'Thank you for subscribing!') + '</p>';
                        } else {
                            flash('error', res.error || 'Could not subscribe. Please try again.');
                        }
                    })
                    .catch(function () {
                        btn.disabled = false;
                        btn.textContent = original;
                        flash('error', 'Could not reach the server. Please try again.');
                    });
            });
        });
    }

    /* ----------------------------------------------------------------- misc */
    function bindFaq() {
        qsa('.faq-question').forEach(function (q) {
            q.addEventListener('click', function () {
                var item = q.closest('.faq-item');
                var wasOpen = item.classList.contains('open');
                qsa('.faq-item').forEach(function (i) { i.classList.remove('open'); });
                if (!wasOpen) item.classList.add('open');
            });
        });
    }

    function bindNav() {
        var toggle = qs('.nav-toggle');
        var nav = qs('.site-nav');
        if (toggle && nav) {
            toggle.addEventListener('click', function () {
                nav.classList.toggle('open');
                var expanded = nav.classList.contains('open');
                toggle.setAttribute('aria-expanded', expanded ? 'true' : 'false');
            });
        }

        var dropdownToggle = qs('.nav-dropdown-toggle');
        var dropdown = qs('.nav-dropdown');
        if (dropdownToggle && dropdown) {
            dropdownToggle.addEventListener('click', function () {
                var open = dropdown.classList.toggle('open');
                dropdownToggle.setAttribute('aria-expanded', open ? 'true' : 'false');
            });
            document.addEventListener('click', function (ev) {
                if (!dropdown.contains(ev.target)) {
                    dropdown.classList.remove('open');
                    dropdownToggle.setAttribute('aria-expanded', 'false');
                }
            });
        }
    }

    function bindYear() {
        var y = qs('#year');
        if (y) y.textContent = String(new Date().getFullYear());
    }

    /* ------------------------------------------------------------- init */
    document.addEventListener('DOMContentLoaded', function () {
        bindFlashDismiss();
        bindYear();
        bindNav();
        bindFaq();
        bindMiniCartButtons();
        bindShop();
        bindProductPage();
        bindCartPage();
        bindCheckout();
        bindNewsletter();
    });
})();