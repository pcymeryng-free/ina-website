// ============================================================
// INA — lightweight client-side EN/ES toggle
// Looks up window.INA_I18N[key][lang] and swaps innerHTML for any
// element with [data-i18n="key"]. If a key or language is missing,
// the element is left as-is (graceful fallback to its default
// English markup already present in the HTML).
// ============================================================
(function () {
  var STORAGE_KEY = 'ina-lang';
  var DICT = window.INA_I18N || {};

  function getLang() {
    var saved = null;
    try { saved = localStorage.getItem(STORAGE_KEY); } catch (e) {}
    return saved === 'es' ? 'es' : 'en';
  }

  function setLang(lang) {
    try { localStorage.setItem(STORAGE_KEY, lang); } catch (e) {}
    applyLang(lang);
  }

  function applyLang(lang) {
    document.documentElement.setAttribute('lang', lang);

    document.querySelectorAll('[data-i18n]').forEach(function (el) {
      var key = el.getAttribute('data-i18n');
      var entry = DICT[key];
      if (entry && entry[lang]) {
        el.innerHTML = entry[lang];
      }
    });

    document.querySelectorAll('[data-i18n-placeholder]').forEach(function (el) {
      var key = el.getAttribute('data-i18n-placeholder');
      var entry = DICT[key];
      if (entry && entry[lang]) {
        el.setAttribute('placeholder', entry[lang]);
      }
    });

    document.querySelectorAll('.lang-toggle button').forEach(function (btn) {
      var isActive = btn.getAttribute('data-lang') === lang;
      btn.classList.toggle('active', isActive);
      btn.setAttribute('aria-pressed', isActive ? 'true' : 'false');
    });
  }

  document.addEventListener('click', function (e) {
    var btn = e.target.closest('[data-lang]');
    if (!btn) return;
    var lang = btn.getAttribute('data-lang');
    if (lang === 'en' || lang === 'es') setLang(lang);
  });

  document.addEventListener('DOMContentLoaded', function () {
    applyLang(getLang());
  });
})();
