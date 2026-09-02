// ============ Mobile menu ============
const navToggle = document.getElementById('navToggle');
const mobileMenu = document.getElementById('mobileMenu');
if (navToggle && mobileMenu) {
  navToggle.addEventListener('click', () => {
    mobileMenu.style.display = mobileMenu.style.display === 'none' ? 'block' : 'none';
  });
  document.querySelectorAll('#mobileMenu a').forEach(a =>
    a.addEventListener('click', () => (mobileMenu.style.display = 'none'))
  );
}

// ============ Admin nav dropdown menu (app/*.html header) ============
// Reuses the same .menu/.nav-menu/.menu-trigger/.menu-panel/.menu-item
// component app/project.html pioneered for its own Project/Analysis nav
// menus (see assets/app.css) — wired centrally here instead of repeating
// this open/close/outside-click/Escape logic in the 14 other app/*.html
// pages that now carry a dropdown "Admin" menu (currently just one item,
// "User Management" → admin.html — see the "Master Data se desprende del
// menu admin" request; more admin-only tools can be added as additional
// .menu-item rows later without any JS changes here).
//
// Scoped to the specific #adminNavMenu id, NOT a broad ".nav-menu"
// selector — project.html has its own "Project"/"Analysis" nav menus
// (also .menu.nav-menu, inside the same .app-nav) with their own,
// separate wiring (including extra keepMenuPanelOnScreen() positioning
// logic project.html needs and this one doesn't). A broad selector here
// would double-wire those and break them; project.html doesn't have
// #adminNavMenu at all, so this only ever touches the Admin dropdown.
const adminNavMenu = document.getElementById('adminNavMenu');
if (adminNavMenu) {
  const adminNavTrigger = adminNavMenu.querySelector('.menu-trigger');
  function closeAdminNavMenu() {
    adminNavMenu.classList.remove('open');
    adminNavTrigger.setAttribute('aria-expanded', 'false');
  }
  adminNavTrigger.addEventListener('click', (e) => {
    e.stopPropagation();
    const willOpen = !adminNavMenu.classList.contains('open');
    if (willOpen) {
      adminNavMenu.classList.add('open');
      adminNavTrigger.setAttribute('aria-expanded', 'true');
    } else {
      closeAdminNavMenu();
    }
  });
  adminNavMenu.querySelectorAll('.menu-item').forEach((item) => {
    item.addEventListener('click', closeAdminNavMenu);
  });
  document.addEventListener('click', closeAdminNavMenu);
  document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') closeAdminNavMenu();
  });
}

// ============ Reveal on scroll ============
const revealEls = document.querySelectorAll('.reveal');
if (revealEls.length) {
  const io = new IntersectionObserver(
    (entries) => {
      entries.forEach((e) => {
        if (e.isIntersecting) {
          e.target.classList.add('in');
          io.unobserve(e.target);
        }
      });
    },
    { threshold: 0.14 }
  );
  revealEls.forEach((el) => io.observe(el));
}

// ============ Framework page: scrollspy for sticky TOC ============
const tocLinks = document.querySelectorAll('.fw-toc a');
const fwSections = document.querySelectorAll('.fw-section[id]');
if (tocLinks.length && fwSections.length) {
  const spy = new IntersectionObserver(
    (entries) => {
      entries.forEach((entry) => {
        const id = entry.target.getAttribute('id');
        const link = document.querySelector(`.fw-toc a[href="#${id}"]`);
        if (!link) return;
        if (entry.isIntersecting) {
          tocLinks.forEach((l) => l.classList.remove('active'));
          link.classList.add('active');
        }
      });
    },
    { rootMargin: '-20% 0px -70% 0px' }
  );
  fwSections.forEach((s) => spy.observe(s));
}

// ============ Contact form (real send via /contact.php, runs directly on Bluehost) ============
// contact.php sits at the site root (next to contact.html) and sends
// through the local mail server on the same account that runs
// info@inaai.co — no Vercel, no SMTP credentials, no environment
// variables involved.
//
// This form submits as a real <form method="POST" action="/contact.php">
// — NOT a fetch()/AJAX call. That's deliberate: Bluehost's WAF runs a
// "Human Presence Check" on POSTs it isn't sure come from a real browser,
// replying with a tiny HTML/JS challenge page (sets a cookie, then
// reloads) instead of forwarding the request to contact.php. A real
// browser navigation runs that challenge script and passes it
// automatically; fetch() never executes a returned <script> tag, so AJAX
// submissions were silently dying against that wall no matter what the
// PHP code did.
//
// To avoid a visible full-page reload while still submitting as a real
// navigation (so the anti-bot challenge still gets satisfied), the form
// targets a hidden <iframe> (see contact.html, #contactTargetFrame)
// instead of the top-level window. The browser genuinely navigates —
// just contained inside that invisible frame — so the visitor's page
// never flashes/scrolls to the top.
//
// When contact.html finishes loading *inside that hidden iframe* (after
// the redirect from contact.php lands), this very same script runs again
// there too. Rather than have the top-level page try to peek at the
// iframe's URL (fragile: this script's own query-string-reading logic
// below, running inside the iframe, rewrites that URL via
// history.replaceState() essentially as soon as it loads — racing
// against the parent trying to read it, and losing more often than not),
// the iframe copy explicitly tells the parent what happened via
// postMessage(). That's the standard, race-free way for two same-origin
// documents to talk to each other.
//
// The plain action="/contact.php" + query-string-reading logic below is
// also what runs for a plain top-level submit (JS-disabled browsers, or
// this page loaded standalone/not inside our own iframe) — graceful
// fallback either way.
const CONTACT_EMAIL = 'info@inaai.co';
const CONTACT_MESSAGE_SOURCE = 'ina-contact-form';

function contactNoteText(key, fallback) {
  const lang = document.documentElement.getAttribute('lang') === 'es' ? 'es' : 'en';
  const dict = (typeof I18N !== 'undefined') ? I18N : {};
  const entry = dict[key];
  return entry && entry[lang] ? entry[lang] : fallback;
}

const form = document.getElementById('advisoryForm');
if (form) {
  const note = document.getElementById('formNote');
  const submitBtn = form.querySelector('button[type="submit"]');
  const isEmbedded = window.self !== window.top;

  function showContactResult(type) {
    if (!note) return;
    note.innerHTML = '';
    if (type === 'sent') {
      note.textContent = contactNoteText('contact.note.sent', 'Request received — thank you. An advisor will follow up shortly.');
    } else if (type === 'validation') {
      note.textContent = contactNoteText('contact.note.error.validation', 'Please fill in all required fields and try again.');
    } else if (type === 'email') {
      note.textContent = contactNoteText('contact.note.error.email', 'Please enter a valid email address and try again.');
    } else if (type === 'length') {
      note.textContent = contactNoteText('contact.note.error.length', 'Your message is too long. Please shorten it and try again.');
    } else if (type === 'timeout') {
      note.textContent = contactNoteText(
        'contact.note.error.timeout',
        "This is taking longer than expected. Please try again in a moment, or email us directly."
      );
    } else {
      // 'mail' (server-side send failed) or anything unrecognized — offer
      // a mailto fallback so the visitor's request isn't lost.
      const link = document.createElement('a');
      link.href = `mailto:${CONTACT_EMAIL}?subject=${encodeURIComponent('Advisory Request')}`;
      link.textContent = contactNoteText(
        'contact.note.error',
        `We couldn't send that automatically. Click here to email us directly at ${CONTACT_EMAIL}.`
      );
      link.style.textDecoration = 'underline';
      note.appendChild(link);
    }
    // This form is wrapped in ".reveal" (opacity:0 until scrolled into
    // view). Force it visible immediately so the result is never hidden
    // behind an animation the visitor hasn't triggered yet.
    form.classList.add('in');
  }

  const params = new URLSearchParams(location.search);
  let resultType = null;
  if (params.get('sent') === '1') resultType = 'sent';
  else if (params.has('error')) resultType = params.get('error') || 'error';

  // TEMPORARY diagnostic logging — remove once the iframe/postMessage
  // handoff is confirmed working end-to-end. Prefixed so it's easy to
  // spot and to grep back out later.
  console.log('[INA contact] script loaded', { isEmbedded, href: location.href, resultType });

  if (isEmbedded) {
    // This copy of the page is running inside our own hidden submission
    // iframe — there's no visitor looking at it. Its only job is to
    // report the result to the parent page and stay out of the way.
    if (resultType && window.parent) {
      try {
        console.log('[INA contact] embedded copy posting result to parent', resultType);
        window.parent.postMessage({ source: CONTACT_MESSAGE_SOURCE, result: resultType }, location.origin);
      } catch (e) {
        console.log('[INA contact] postMessage threw', e);
        // Cross-origin or unavailable — nothing more we can do from here;
        // the parent's own 15s timeout will cover it.
      }
    } else {
      console.log('[INA contact] embedded copy has no resultType to report (or no window.parent)');
    }
  } else {
    // --- Fallback path: a plain top-level submit landed back here with a
    // result in the query string (JS-disabled browsers, or the iframe
    // trick below being unavailable for some reason). ---
    if (resultType) {
      showContactResult(resultType);
      if (resultType === 'sent') form.reset();
      history.replaceState(null, '', location.pathname);
      setTimeout(() => note && note.scrollIntoView({ behavior: 'smooth', block: 'center' }), 50);
    }

    // --- Preferred path: submit into the hidden iframe so the visible
    // page never navigates at all; wait for it to postMessage() the
    // result back once it lands. ---
    const targetFrame = document.getElementById('contactTargetFrame');
    if (targetFrame) {
      form.setAttribute('target', 'contact_target');

      let submissionInFlight = false;
      let timeoutId = null;

      form.addEventListener('submit', () => {
        console.log('[INA contact] form submitted, target=', form.getAttribute('target'));
        submissionInFlight = true;
        if (submitBtn) submitBtn.disabled = true;
        if (note) {
          note.textContent = contactNoteText('contact.note.sending', 'Sending…');
          form.classList.add('in');
        }
        clearTimeout(timeoutId);
        // The anti-bot challenge (when it triggers) resolves itself within
        // a couple seconds; if we still haven't heard back after 15s,
        // something's actually wrong — stop waiting and let the visitor know.
        timeoutId = setTimeout(() => {
          console.log('[INA contact] 15s timeout fired, submissionInFlight=', submissionInFlight);
          if (!submissionInFlight) return;
          submissionInFlight = false;
          if (submitBtn) submitBtn.disabled = false;
          showContactResult('timeout');
        }, 15000);
      });

      window.addEventListener('message', (event) => {
        console.log('[INA contact] parent received a message event', {
          origin: event.origin,
          expectedOrigin: location.origin,
          data: event.data,
          submissionInFlight,
        });
        if (event.origin !== location.origin) return;
        if (!event.data || event.data.source !== CONTACT_MESSAGE_SOURCE) return;
        if (!submissionInFlight) return;

        submissionInFlight = false;
        clearTimeout(timeoutId);
        if (submitBtn) submitBtn.disabled = false;

        const result = event.data.result;
        showContactResult(result);
        if (result === 'sent') form.reset();
      });
    }
  }
}
