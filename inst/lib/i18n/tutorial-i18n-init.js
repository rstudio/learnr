/* globals $,i18next,Shiny */

'use strict'

$.extend({
  keys: function (obj) {
    return $.map(obj, function (v, k) {
      return k
    })
  },
  includes: function (arr, val) {
    return $.inArray(val, arr)
  }
})

$(document).on('shiny:sessioninitialized', function () {
  // customizations are stored as JSON in #i18n-cstm-trns <script>
  let i18nCustom = document.getElementById('i18n-cstm-trns')

  if (!i18nCustom) {
    i18nCustom = {
      language: 'en'
    }
  } else {
    i18nCustom = JSON.parse(i18nCustom.innerText)
  }

  if (i18nCustom.resources) {
    // copy customizations into base translation namespace
    $.keys(i18nCustom.resources).forEach(function (lng) {
      const resource = i18nCustom.resources[lng]

      if (resource.custom) {
        if (resource.translation) {
          $.keys(resource.custom).forEach(function (keyGroup) {
            $.extend(resource.translation[keyGroup], resource.custom[keyGroup])
          })
        } else {
          resource.translation = resource.custom
        }
      }
    })
  }

  function localize (selector, opts) {
    selector = selector || '[data-i18n]'
    opts = opts || {}
    const $els = $(selector).filter(function () {
      return $.includes(this.dataset, 'i18n')
    })

    // tell the shiny process that the language was changed
    Shiny.setInputValue('__tutorial_language', i18next.language)

    if (!$els.length) {
      // No elements found for localization with selector
      return
    }

    $els.each(function (idx) {
      let optsItem = $.extend({}, opts)
      // Note: `this.dataset.i18nOpts` maps directly to the DOM element attribute `data-i18n-opts`
      //       And `this.dataset.i18nAttrVALUE` to element attribute `data-i18n-attr-VALUE`
      // Link: https://developer.mozilla.org/en-US/docs/Learn/HTML/Howto/Use_data_attributes
      // Reference:
      // > To get a data attribute through the dataset object, get the property
      // > by the part of the attribute name after data
      // > (note that dashes are converted to camelCase).

      if (this.dataset.i18nOpts) {
        optsItem = $.extend(optsItem, JSON.parse(this.dataset.i18nOpts))
      }

      // Translate the item itself
      if (this.dataset.i18n) {
        this.innerHTML = i18next.t(this.dataset.i18n, optsItem)
      }

      // Translate element attributes, where keys for the translation of
      // attribute VALUE are stored in element attribute data-i18n-attr-<VALUE>
      // e.g. <span title="english title" data-i18n-attr-title="title.demo"></span>
      //      will use title.demo to look up and translated the text in the title attribute
      const i18nAttrs = $.keys(this.dataset).filter(function (x) {
        return x.match('i18nAttr')
      })

      for (let j = 0; j < i18nAttrs.length; j++) {
        this.setAttribute(
          i18nAttrs[j].replace(/^i18nAttr/, '').toLowerCase(),
          i18next.t(this.dataset[i18nAttrs[j]], optsItem)
        )
      }
    })
    return $els
  }

  i18next.init(
    {
      lng: i18nCustom.language || 'en',
      fallbackLng: 'en',
      ns: 'translation',
      resources: i18nCustom.resources || {}
    },
    function (err, t) {
      if (err) return console.log('[i18next] Error loading translations:', err)
      localize()
    }
  )
  /* Method for localization of the tutorial
   *
   * @param lang New language for tutorial, if undefined returns the object with
   *   language customizations used to initialize i18next
   * @param selector CSS selector of elements to localize
   * @param opts Options passed to .localize() method from jqueryI18next
   *
   */

  window.tutorial.$localize = function (lang, selector, opts) {
    if (typeof lang === 'undefined') {
      return i18nCustom
    }

    i18next.changeLanguage(lang)
    localize(selector, opts)
  }

  // localize question buttons when shown
  $(document).on('shiny:value', '.tutorial-question', function (ev) {
    // Allow DOM to update before translating question UI
    setTimeout(function () {
      localize(
        ev.target.closest('.tutorial-question').querySelectorAll('[data-i18n]')
      )
    }, 0)
  })

  // localize exercise output when shown
  $(document).on('shiny:value', '.tutorial-exercise-output', function (ev) {
    // Allow DOM to update before translating question UI
    setTimeout(function () {
      localize(
        ev.target
          .closest('.tutorial-exercise-output')
          .querySelectorAll('[data-i18n]')
      )
    }, 0)
  })

  // translate targets of i18n events
  $(document).on('i18n', function (ev) {
    // translate the event target itself
    localize(ev.target)

    // and also any descendants
    localize(ev.target.querySelectorAll('[data-i18n]'))
  })

  function localizeHandler (x) {
    let selector, language

    if (
      typeof x === 'string' ||
      (Array.isArray(x) &&
        x.every(function (s) {
          return typeof s === 'string'
        }))
    ) {
      selector = x
    } else if (typeof x === 'object') {
      selector = x.selector || '[data-i18n]'
      language = x.language
    } else {
      return console.log(
        'localize message must be a string with selector(s) or an object with optional keys selector and language.'
      )
    }

    if (language) {
      i18next.changeLanguage(language)
    }

    localize(selector, x.opts || {})
  }

  Shiny.addCustomMessageHandler('localize', localizeHandler)
})
