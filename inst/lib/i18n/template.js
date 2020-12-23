$(document).on("shiny:sessioninitialized", function() {
    // This can be uncommented to allow to switch from one lang to the other
    // For testing
    /* var arr = [
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
    $("#tutorial-topic").append(sel); */

    i18next.init({
        lng: '{{language}}',
        fallbackLng: 'en',
        ns: ['custom', 'translation'],
        defaultNS: 'custom',
        fallbackNS: 'translation',
        resources: {{resources}}
    }, function(err, t) {
        jqueryI18next.init(i18next, $);
        $('html').localize();
    });
});