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

// ============ Contact form (static demo — no backend wired up) ============
const form = document.getElementById('advisoryForm');
if (form) {
  const note = document.getElementById('formNote');
  form.addEventListener('submit', (e) => {
    e.preventDefault();
    if (note) note.textContent = 'Request received — thank you. An advisor will follow up shortly.';
    form.reset();
  });
}
