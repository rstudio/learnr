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
        resources: {
            // English
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
                        startover: "Start Over",
                        areyousure: "Are you sure you want to start over? (all exercise progress will be reset)",
                        youmustcomplete: "You must complete the",
                        inthissection: "in this section before continuing."
                    }
                }
            },
            // French
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
                        startover: "Recommencer",
                        areyousure: "Êtes-vous certains de vouloir recommencer ? (La progression sera remise à zéro)",
                        youmustcomplete: "Vous devez d'abord compléter l'exercice",
                        inthissection: "de cette section avec de continuer."
                    }
                }
            },
            // Emoji
            emo: {
                translation: {
                    button: {
                        runcode: "🏃",
                        hints: "🔎",
                        startover: "⏮",
                        continue: "✅ ",
                        submitanswer: "🆗",
                        previoustopic: "⬅",
                        nexttopic: "➡"
                    },
                    text: {
                        startover: "⏮",
                        areyousure: "🤔",
                        youmustcomplete: "⚠️ 👉",
                        inthissection: "."
                    }
                }
            }
        }
    }, function(err, t) {
        jqueryI18next.init(i18next, $);
        $('html').localize();
    });
});