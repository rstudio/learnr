# Internationalization

## Choosing a Tutorial’s Language

To change the language of the UI element, you can use the following
parameter in your YAML:

    output:
      learnr::tutorial:
        language: fr

Currently, 11 language translations are supported:

- `en` for English (default)
- `fr` for French / Français
- `es` for Spanish / Español
- `pt` for Portuguese
- `tr` for Turkish
- `eu` for Basque
- `de` for German
- `ko` for Korean
- `zh` for Chinese
- `pl` for Polish
- `no` for Norwegian

Note that `"no"` needs to be quoted because it is a reserved word in
YAML.

## Customizable UI elements:

There are many elements whose language can be translated or customized,
each identified by a *key*. Note that you do not need to customize *all*
of the keys, the UI will fall back to the default tutorial language for
keys that are not specifically customized.

The keys are organized into 2 groups: button and text.

### Buttons

The following keys are available for translating button text:

``` yaml
button:
  runcode: Run Code
  runcodetitle: $t(button.runcode) ({{kbd}})
  hint: Hint
  hint_plural: Hints
  hinttitle: $t(button.hint)
  hintnext: Next Hint
  hintprev: Previous Hint
  solution: Solution
  solutiontitle: $t(button.solution)
  copyclipboard: Copy to Clipboard
  startover: Start Over
  startovertitle: $t(button.startover)
  continue: Continue
  submitanswer: Submit Answer
  submitanswertitle: $t(button.submitanswer)
  previoustopic: Previous Topic
  nexttopic: Next Topic
  questionsubmit: $t(button.submitanswer)
  questiontryagain: Try Again
```

### Text

The following keys are available for translating text elements:

``` yaml
text:
  startover: Start Over
  areyousure: Are you sure you want to start over? (All exercise progress will be reset)
  youmustcomplete: You must complete the
  exercise: exercise
  exercise_plural: exercises
  inthissection: in this section before continuing.
  code: Code
  enginecap: {{engine}} $t(text.code)
  quiz: Quiz
  blank: blank
  blank_plural: blanks
  exercisecontainsblank: This exercise contains {{count}} $t(text.blank).
  pleasereplaceblank: Please replace {{blank}} with valid code.
  unparsable: It looks like this might not be valid R code. R cannot determine how to turn your text into a complete command. You may have forgotten to fill in a blank, to remove an underscore, to include a comma between arguments, or to close an opening <code>&quot;</code>, <code>'</code>, <code>(</code> or <code>{</code> with a matching <code>&quot;</code>, <code>'</code>, <code>)</code> or <code>}</code>.

  unparsablequotes: <p>It looks like your R code contains specially formatted quotation marks or &quot;curly&quot; quotes (<code>{{character}}</code>) around character strings, making your code invalid. R requires character values to be contained in straight quotation marks (<code>&quot;</code> or <code>'</code>).</p> {{code}} <p>Don't worry, this is a common source of errors when you copy code from another app that applies its own formatting to text. You can try replacing the code on that line with the following. There may be other places that need to be fixed, too.</p> {{suggestion}}

  unparsableunicode: <p>It looks like your R code contains an unexpected special character (<code>{{character}}</code>) that makes your code invalid.</p> {{code}} <p>Sometimes your code may contain a special character that looks like a regular character, especially if you copy and paste the code from another app. Try deleting the special character from your code and retyping it manually.</p>

  unparsableunicodesuggestion: <p>It looks like your R code contains an unexpected special character (<code>{{character}}</code>) that makes your code invalid.</p> {{code}} <p>Sometimes your code may contain a special character that looks like a regular character, especially if you copy and paste the code from another app. You can try replacing the code on that line with the following. There may be other places that need to be fixed, too.</p> {{suggestion}}

  and: and
  or: or
  listcomma: , 
  oxfordcomma: ,
```

## Format of `language` Option in YAML Header:

There are several ways that you can use the `language` option to choose
a language translation or to customize the phrasing used in a particular
language.

### Default Language

Chose the default language for the tutorial. learnr currently provides
complete translations for `"en"`, `"fr"`, `"es"`, `"pt"`, `"tr"`,
`"eu"`, `"de"`, `"ko"`, `"zh"`, `"pl"`, and `"no"`. A translation does
not need to be available for you to use as the default language, in
particular if you are providing a custom translation for a language
without an available complete translation.

If you only want to change the default language, use:

``` yaml
language: "fr"
```

If you are also providing language customizations, the first language in
the list of customizations will be the default language.

### Customizing a Single Language

To customize the displayed text for a single language, use the following
format. In this format the customization will be applied to the English
translation, which will also be the default language of the tutorial.

``` yaml
language:
  en:
    button:
      runcode: Run!
    text:
      startover: Restart!
```

### Customizing Multiple Languages

To provide custom display text for multiple languages, provide a list
containing `button` and/or `text` custom labels. In the example below,
the default tutorial language will be Spanish (`es`).

``` yaml
language:
  es:
    button:
      runcode: Ejecutar
  en:
    button:
      runcode: Run!
    text:
      startover: Restart!
```

Note that only the first language and its customizations are used in the
rendered tutorial. In the future, we may extend the multi-language
features of learnr to accommodate dynamic localization.

### Store Customizations in a JSON File

If you intend to reuse the same custom language repeatedly, it may be
helpful to store the custom language parameters in a JSON file and
simply import the file. In this case, you can set the language code item
to the path to a single JSON file, written with the same structure as
the YAML.

For example, you could write Spanish language customizations to
`tutorial_es.json` with the following R code:

``` r
jsonlite::write_json(
  list(
    button = list(runcode = "Ejecutar"),
    text = list(startover = "Empezar de nuevo")
  ),
  path = "tutorial_es.json",
  auto_unbox = TRUE
)
```

You could then load customizations from this file by referencing it in
the YAML header.

``` yaml
language:
  es: tutorial_es.json
```

Similarly, you can store the entire `language` list in a JSON file and
provide the path to the JSON file to the `language` key.

``` r
jsonlite::write_json(
  list(
    en = list(
      button = list(runcode = "Run the code"),
      text = list(startover = "Restart the tutorial")
    ),
    es = list(
      button = list(runcode = "Ejecutar"),
      text = list(startover = "Empezar de nuevo")
    )
  ),
  path = "custom_language.json",
  auto_unbox = TRUE
)
```

The R code above writes the custom text for `en` and `es` languages into
`custom_language.json`, which we then reference in the YAML header:

``` yaml
language: custom_language.json
```

## Complete Translations

Complete translations are provided by the internal function
`i18n_translations()`. To contribute a complete translation for a
language not currently provided by learnr, please submit a pull request
to [github.com/rstudio/learnr](https://github.com/rstudio/learnr)
updating the list in `data-raw/i18n_translations.yml`, following the
format described in that file.

Note that for the language to be available inside the alert boxes of
learnr, you’ll need to set the language to one of the [language codes
used by
bootbox](https://bootboxjs.com/v5.x/documentation.html)[¹](#fn1). If
your language is not available for `bootbox`, then the buttons will
default to English.

------------------------------------------------------------------------

1.  `ar`, `bg_BG`, `cs`, `de`, `en`, `et`, `fa`, `fr`, `hr`, `id`, `ja`,
    `ko`, `lv`, `no`, `pt`, `sk`, `sq`, `sw`, `th`, `uk`, `zh_CN`, `az`,
    `br`, `da`, `el`, `es`, `eu`, `fi`, `he`, `hu`, `it`, `ka`, `lt`,
    `nl`, `pl`, `ru`, `sl`, `sv`, `ta`, `tr`, `vi`, or `zh_TW`
