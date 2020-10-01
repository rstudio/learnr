$(document).on("shiny:sessioninitialized", function() {
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
        '<label for="lang" data-i18n = "text.choosealang"></label>'
    );
    $("#tutorial-topic").append(sel);

    i18next.init({
        lng: '{{language}}',
        resources: {
            en: {
                translation: {
                    button: {
                        runcode: "Run Code",
                        hints: "Hints",
                        startover: "Start Over",
                        continue: "Continue",
                        submitanswer: "Submit Answer",
                        previoustopic: "Previous Topic",
                        nexttopic: "Next Topic"
                    },
                    text: {
                        choosealang: "Choose a language:",
                        startover: "Start Over"
                    }
                }
            },
            fr: {
                translation: {
                    button: {
                        runcode: "Lancer le Code",
                        hints: "Indice",
                        startover: "Recommencer",
                        continue: "Continuer",
                        submitanswer: "Soumettre",
                        previoustopic: "Chapitre précédent",
                        nexttopic: "Chapitre Suivant"
                    },
                    text: {
                        choosealang: "Choisir une langue:",
                        startover: "Recommencer"
                    }
                }
            }
        }
    }, function(err, t) {
        jqueryI18next.init(i18next, $);
        $('html').localize();
    });
});