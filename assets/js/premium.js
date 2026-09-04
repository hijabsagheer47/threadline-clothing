/* ============================================================================
   TAYYABACOLLECTIVE — PREMIUM INTERACTIONS
   ----------------------------------------------------------------------------
   Loaded after site.js and deliberately decoupled from it: this file never
   calls the cart API itself, it only reacts to what site.js already did.
   Everything degrades to plain HTML if this script fails to load.
   ========================================================================== */
(function () {
    'use strict';

    var qs  = function (s, c) { return (c || document).querySelector(s); };
    var qsa = function (s, c) { return Array.prototype.slice.call((c || document).querySelectorAll(s)); };

    /* ------------------------------------------------------ sticky header */
    function initHeader() {
        var header = qs('.site-header');
        if (!header) return;

        var ticking = false;
        function apply() {
            header.classList.toggle('is-stuck', window.scrollY > 8);
            ticking = false;
        }
        window.addEventListener('scroll', function () {
            if (!ticking) { ticking = true; window.requestAnimationFrame(apply); }
        }, { passive: true });
        apply();
    }

    /* ------------------------------------------------------------ toasts */
    function toastHost() {
        var host = qs('.tc-toasts');
        if (!host) {
            host = document.createElement('div');
            host.className = 'tc-toasts';
            host.setAttribute('role', 'status');
            host.setAttribute('aria-live', 'polite');
            document.body.appendChild(host);
        }
        return host;
    }

    function toast(message, kind) {
        var el = document.createElement('div');
        el.className = 'tc-toast is-' + (kind || 'success');
        el.innerHTML = '<i class="fa-solid ' +
            (kind === 'error' ? 'fa-circle-exclamation' : 'fa-circle-check') +
            '"></i><span></span>';
        qs('span', el).textContent = message;
        toastHost().appendChild(el);

        setTimeout(function () {
            el.classList.add('is-out');
            el.addEventListener('animationend', function () { el.remove(); }, { once: true });
        }, 2600);
    }

    window.tcToast = toast;

    /* -------------------------------------------- cart badge: bump + toast */
    /* site.js updates .cart-count after a successful add. Watching the node
       means the toast only ever fires on a real server success, and we never
       have to duplicate the request logic. */
    function initCartFeedback() {
        var badge = qs('.cart-count');
        if (!badge || !window.MutationObserver) return;

        var last = parseInt(badge.textContent, 10) || 0;

        new MutationObserver(function () {
            var now = parseInt(badge.textContent, 10) || 0;
            if (now === last) return;

            if (now > last) {
                badge.classList.remove('is-bumped');
                void badge.offsetWidth;           /* restart the animation */
                badge.classList.add('is-bumped');
                toast('Added to your bag', 'success');
            }
            last = now;
        }).observe(badge, { childList: true, characterData: true, subtree: true });
    }

    /* -------------------------------------------------- scroll reveals */
    function initReveals() {
        if (!('IntersectionObserver' in window)) return;

        var targets = qsa('.section-header, .product-card, .category-card, .trust-item, .collection-card');
        if (!targets.length) return;

        var io = new IntersectionObserver(function (entries) {
            entries.forEach(function (entry) {
                if (!entry.isIntersecting) return;
                entry.target.classList.add('is-visible');
                io.unobserve(entry.target);
            });
        }, { rootMargin: '0px 0px -8% 0px', threshold: .08 });

        targets.forEach(function (el, i) {
            el.classList.add('tc-reveal');
            /* A short stagger within a row, capped so later cards are not slow */
            el.style.transitionDelay = Math.min(i % 4, 3) * 60 + 'ms';
            io.observe(el);
        });
    }

    function init() {
        initHeader();
        initCartFeedback();
        initReveals();
    }

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', init);
    } else {
        init();
    }
})();
