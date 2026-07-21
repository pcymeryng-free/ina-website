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

// ============ Contact form (real send via /api/contact, SMTP to info@inaai.co) ============
const CONTACT_EMAIL = 'info@inaai.co';

// Same pattern as INAPlatform.analyzeProjectUrl() in assets/platform.js:
// on the production domain (Bluehost, static hosting, no Node.js) this
// calls the api. subdomain which points at the Vercel function; on
// Vercel itself (and localhost during development) it uses the
// relative path, since /api/contact.js is same-origin there.
const CONTACT_PRODUCTION_HOSTNAMES = ['international-network-advisors.com', 'www.international-network-advisors.com'];
const CONTACT_PRODUCTION_API_ORIGIN = 'https://api.international-network-advisors.com';
function contactUrl() {
  if (typeof location !== 'undefined' && CONTACT_PRODUCTION_HOSTNAMES.includes(location.hostname)) {
    return `${CONTACT_PRODUCTION_API_ORIGIN}/contact`;
  }
  return '/api/contact';
}

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

  form.addEventListener('submit', async (e) => {
    e.preventDefault();
    if (submitBtn) submitBtn.disabled = true;

    const name = (document.getElementById('name') || {}).value || '';
    const org = (document.getElementById('org') || {}).value || '';
    const typeSelect = document.getElementById('type');
    const type = typeSelect ? typeSelect.options[typeSelect.selectedIndex].text : '';
    const email = (document.getElementById('email') || {}).value || '';
    const msg = (document.getElementById('msg') || {}).value || '';
    const honeypot = (document.getElementById('company_website') || {}).value || '';

    if (note) note.textContent = contactNoteText('contact.note.sending', 'Sending…');

    try {
      const res = await fetch(contactUrl(), {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ name, org, type, email, message: msg, company_website: honeypot }),
      });
      if (!res.ok) throw new Error('send failed');

      if (note) note.textContent = contactNoteText('contact.note.sent', 'Request received — thank you. An advisor will follow up shortly.');
      form.reset();
    } catch (err) {
      // Fall back to a mailto link so the visitor's request isn't lost
      // even if the server-side send is down or not configured yet.
      const subject = `Advisory Request — ${org || name}`;
      const body =
        `Name: ${name}\n` +
        `Organization: ${org}\n` +
        `Type: ${type}\n` +
        `Email: ${email}\n\n` +
        `Message:\n${msg}`;
      const mailtoLink =
        `mailto:${CONTACT_EMAIL}` +
        `?subject=${encodeURIComponent(subject)}` +
        `&body=${encodeURIComponent(body)}`;

      if (note) {
        const errorMsg = contactNoteText(
          'contact.note.error',
          `We couldn't send that automatically. Click here to email us directly at ${CONTACT_EMAIL}.`
        );
        note.innerHTML = '';
        const link = document.createElement('a');
        link.href = mailtoLink;
        link.textContent = errorMsg;
        link.style.textDecoration = 'underline';
        note.appendChild(link);
      }
    } finally {
      if (submitBtn) submitBtn.disabled = false;
    }
  });
}
