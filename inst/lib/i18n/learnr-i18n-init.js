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

  i18next.init({
    lng: i18nCustom.language || 'en',
    ns: ['custom', 'translation'],
    defaultNS: 'custom',
    fallbackNS: 'translation',
    resources: i18nCustom.resources || {}
  }, function(err, t) {
    if (err) return console.log('[i18next] Error loading translations:', err);
    jqueryI18next.init(i18next, $);
    $('html').localize();
  });
});