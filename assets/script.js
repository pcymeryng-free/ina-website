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

// ============ Contact form (mailto — no backend, static site) ============
const CONTACT_EMAIL = 'info@inaai.co';
const form = document.getElementById('advisoryForm');
if (form) {
  const note = document.getElementById('formNote');
  form.addEventListener('submit', (e) => {
    e.preventDefault();

    const name = (document.getElementById('name') || {}).value || '';
    const org = (document.getElementById('org') || {}).value || '';
    const typeSelect = document.getElementById('type');
    const type = typeSelect ? typeSelect.options[typeSelect.selectedIndex].text : '';
    const email = (document.getElementById('email') || {}).value || '';
    const msg = (document.getElementById('msg') || {}).value || '';

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

    window.location.href = mailtoLink;

    const lang = document.documentElement.getAttribute('lang') === 'es' ? 'es' : 'en';
    const dict = (typeof I18N !== 'undefined') ? I18N : {};
    const entry = dict['contact.note.sent'];
    if (note) {
      note.textContent = entry && entry[lang]
        ? entry[lang]
        : `Your email app should open with the message ready to send to ${CONTACT_EMAIL}.`;
    }
    form.reset();
  });
}
