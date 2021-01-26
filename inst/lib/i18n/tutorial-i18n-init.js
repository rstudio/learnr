$(document).on("shiny:sessioninitialized", function() {
  // This can be uncommented to allow to switch from one lang to the other
  // For testing
  /*
  var arr = [
    { val: "en", text: 'English' },
    { val: "fr", text: 'French' }
  ];
  var sel = $('<select>')

  arr.map(x => ($(sel).append(`<option value="${x.val}">${x.text}</option>`)));
  sel.name = "lang"
  sel.on('change', function() {
    i18next.changeLanguage(this.value)
    $('html').localize();
  });

  $("#tutorial-topic").append(
    '<label for="lang">Switch lang</label>'
  );
  $("#tutorial-topic").append(sel);
  */

  // customizations are stored as JSON in #i18n-cstm-trns <script>
  var i18nCustom = document.getElementById('i18n-cstm-trns');
  if (!i18nCustom) {
    i18nCustom = {language: 'en'};
  } else {
    i18nCustom = JSON.parse(i18nCustom.innerText);
  }

  if (i18nCustom.resources) {
    // copy customizations into base translation namespace
    Object.keys(i18nCustom.resources).forEach(function(lng) {
      var resource = i18nCustom.resources[lng]
      if (resource.custom) {
        if (resource.translation) {
          Object.keys(resource.custom).forEach(function(keyGroup) {
            Object.assign(resource.translation[keyGroup], resource.custom[keyGroup])
          })
        } else {
          resource.translation = resource.custom
        }
      }
    })
  }

  function localize(selector, opts) {
    selector = selector || '[data-i18n]';
    opts = opts || {};
    var els;

    // selector is a string or array of strings (CSS selectors) or an element or array of elements
    if (
      typeof selector === 'string' ||
      (Array.isArray(selector) && selector.every(function(x) { return typeof selector === 'string'; }))
    ) {
      els = document.querySelectorAll(selector);
    } else if (selector instanceof HTMLElement || selector instanceof HTMLDivElement) {
      els = [selector];
    } else {
      els = selector;
    }
    els = Array.from(els).filter(function(x) { return Object.keys(x.dataset).includes('i18n'); });
    if (!els.length) {
      // console.error('No elements found for localization with selector ' + selector);
      return;
    }
    for (var i = 0; i < els.length; i++) {
      var optsItem = Object.assign({}, opts);
      // Can pass options via data-i18n-opts attributes
      if (els[i].dataset.i18nOpts) {
        optsItem = Object.assign(optsItem, JSON.parse(els[i].dataset.i18nOpts));
      }

      // Translate the item iteslf
      if (els[i].dataset.i18n) {
        els[i].innerHTML = i18next.t(els[i].dataset.i18n, optsItem);
      }

      // Translate attribute values, getting keys from data-i18n-attr-<value>
      var i18nAttrs = Object.keys(els[i].dataset).filter(function(x) { return x.match('i18nAttr'); });
      for (var j = 0; j < i18nAttrs.length; j++) {
        els[i].setAttribute(
          i18nAttrs[j].replace(/^i18nAttr/, '').toLowerCase(),
          i18next.t(els[i].dataset[i18nAttrs[j]], optsItem)
        );
      }
    }
    return els;
  }

  i18next.init({
    lng: i18nCustom.language || 'en',
    fallbackLng: 'en',
    ns: 'translation',
    resources: i18nCustom.resources || {}
  }, function(err, t) {
    if (err) return console.log('[i18next] Error loading translations:', err);
    localize();
  });

  /* Method for localization of the tutorial
   *
   * @param lang New language for tutorial, if undefined returns the object with
   *   language customizations used to initialize i18next
   * @param selector CSS selector of elements to localize
   * @param opts Options passed to .localize() method from jqueryI18next
   *
   */
  window.tutorial.$localize = function(lang, selector, opts) {
    if (typeof lang === 'undefined') {
      return i18nCustom;
    }
    i18next.changeLanguage(lang);
    localize(selector, opts);
  }

  // localize question buttons when shown
  $(document).on('shiny:value', '.tutorial-question', function(ev) {
    setTimeout(function() {
      localize(ev.target.closest('.tutorial-question').querySelectorAll('[data-i18n]'));
    }, 0);
  });

  function localizeHandler(x) {
    var selector,language;
    if (
      typeof x === 'string' ||
      (Array.isArray(x) && x.every(function(s) { return typeof s === 'string' }))
    ) {
      selector = x;
    } else if (typeof x === 'object') {
      selector = x.selector || '[data-i18n]';
      language = x.language;
    } else {
      return console.log('localize message must be a string with selector(s) or an object with optional keys selector and language.');
    }
    if (language) {
      i18next.changeLanguage(language);
    }
    localize(selector, x.opts || {});
  }

  Shiny.addCustomMessageHandler('localize', localizeHandler);
});