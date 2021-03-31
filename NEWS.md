learnr (development version)
===========

## Breaking Changes

* Renamed the `exercise_submission` event to `exercise_result` and added the following fields:
  1. `id` - a randomly generated identifier that can be used to align with the associated `exercise_result` event.
  2. `time_elapsed` - the time required to run the exercise (in seconds)
  3. `timeout_exceeded` - indicates whether the exercise was interrupted due to an exceeded timeout. May be `NA` for some platforms/evaluators if that information is not known or reported. ([#337](https://github.com/rstudio/learnr/pull/337))
* If a `-code-check` chunk returns feedback for an exercise submission, the result of the exercise is no longer displayed for a correct answer (only the feedback is displayed). If both the result and feedback should be displayed, all checking should be performed in a `-check` chunk (i.e., don't provide a `-code-check` chunk). ([#403](https://github.com/rstudio/learnr/pull/403))
* `random_praise()` no longer includes the phrase _Correct!_. Instead, it returns a random praising statement. ([#463](https://github.com/rstudio/learnr/pull/463), [#453](https://github.com/rstudio/learnr/issues/453))

## New features

* Introduced "setup chunk chaining", which allows a setup chunk to depend on another setup chunk and so on, forming a chain of setup code that can be used for exercises via `exercise.setup`. Run `run_tutorial("setup-chunks", "learnr")` for a demo. ([#390](https://github.com/rstudio/learnr/pull/390))
* Introduced an [experimental](https://www.tidyverse.org/lifecycle/#experimental) function `external_evaluator()` which can be used to define an exercise evaluator that runs on a remote server and is invoked via HTTP. This allows all exercise execution to be performed outside of the Shiny process hosting the learnr document. ([#345](https://github.com/rstudio/learnr/pull/345), [#354](https://github.com/rstudio/learnr/pull/354))
* For the "forked" evaluator (the default used on Linux), add a limit to the number of forked exercises that learnr will execute in parallel. Previously, this was uncapped, which could cause a learnr process to run out of memory when an influx of traffic arrived. The default limit is 3, but it can be configured using the `tutorial.max.forked.procs` option or the `TUTORIAL_MAX_FORKED_PROCS` environment variable. ([#353](https://github.com/rstudio/learnr/pull/353))
* Added a new `tutorial_options()`, namely `exercise.error.checker`, for customizing feedback when exercise submission code produces an evaluation error. This option accepts a function with the same arguments as `exercise.checker`. Use `gradethis::grade_learnr_error()` for a sensible default for this option. ([#403](https://github.com/rstudio/learnr/pull/403))
* Added an event handler system, with the functions `event_register_handler()` and `one_time()`. There is also a new event `"section_viewed"`, which is triggered when a new section becomes visible. ([#398](https://github.com/rstudio/learnr/pull/398))
* Previously, when a question submission was reset, it would be recorded as a `"question_submission"` event with the value `reset=TRUE`. Now it a separate event, `"reset_question_submission"`. ([#398](https://github.com/rstudio/learnr/pull/398))
* Added a new `polyglot` tutorial to learnr. This tutorial displays mixing R, python, and sql exercises. See [`run_tutorial("polyglot", "learnr")`](https://learnr-examples.shinyapps.io/polyglot) for a an example. ([#397](https://github.com/rstudio/learnr/pull/397))
* Text throughout the learnr interface can be customized or localized using the new `language` argument of `tutorial()`. Translations for English and French are provided and contributes will be welcomed. Read more about these features in `vignette("multilang", package = "learnr")`. ([#456](https://github.com/rstudio/learnr/pull/456), [#479](https://github.com/rstudio/learnr/pull/479))

## Minor new features and improvements

* Added an `exercise_submitted` event which is fired before evaluating an exercise. This event can be associated with an `exercise_result` event using the randomly generated `id` included in the data of both events. ([#337](https://github.com/rstudio/learnr/pull/337))
* Added a `restore` flag on `exercise_submitted` events which is `TRUE` if the exercise is being restored from a previous execution, or `FALSE` if the exercise is being run interactively.
* Add `label` field to the `exercise_hint` event to identify for which exercise the user requested a hint. ([#377](https://github.com/rstudio/learnr/pull/377))
* Added `include=FALSE` to setup chunks to prevent exercises from printing out messages or potential code output for those setup chunks. ([#390](https://github.com/rstudio/learnr/pull/390))
* Added error handling when user specifies a non-existent label for `exercise.setup` option with an error message. ([#390](https://github.com/rstudio/learnr/pull/390))
* We no longer forward the checker code to browser (in html), but instead cache it. ([#390](https://github.com/rstudio/learnr/pull/390))
* We no longer display an invisible exercise result warning automatically. Instead, authors must set the exercise chunk option `exercise.warn_invisible = TRUE` to display an invisible result warning message. ([#373](https://github.com/rstudio/learnr/pull/373))
* `exercise.cap` now accepts HTML input. If no `exercise.cap` is provided, an icon of the exercise engine will be displayed. If no icon is known, the `exercise.cap` will default to the combination of the exercise engine and `" code"`. ([#397](https://github.com/rstudio/learnr/pull/397), [#429](https://github.com/rstudio/learnr/pull/429))
* `engine` is now passed to the `exercise.checker` to help distinguish what language is being checked in the exercise. ([#397](https://github.com/rstudio/learnr/pull/397))
* Hitting the `TAB` key in an exercise has always opened the auto-completion drop down. Now, hitting the `TAB` key will also complete the currently selected code completion. ([#428](https://github.com/rstudio/learnr/pull/428))
* `question_text()` gains `rows` and `cols` parameters. If either is provided, a multi-line `textAreaInput()` is used for the text input. ([#460](https://github.com/rstudio/learnr/pull/460), [#455](https://github.com/rstudio/learnr/issues/455))
* Feedback messages can now be an htmltools tag or tagList, or a character message ([#458](https://github.com/rstudio/learnr/pull/458))
* Added an option to reveal [default] (or hide) the solution to an exercise. Set `exercise.reveal_solution` in the chunk options of a `*-solution` chunk to choose whether or not the solution is revealed to the user. The option can also be set globally with `tutorial_options()`. In a future version of learnr, the default will be changed to hide solutions. ([#402](https://github.com/rstudio/learnr/issue/402))
* Added shortcuts for pipe (`Command/Control+Shift+M`) and assignment (`Alt+-`) operators in exercise code boxes. ([#472](https://github.com/rstudio/learnr/pull/472))
* Added Spanish language support (@yabellini [#483](https://github.com/rstudio/learnr/pull/483))
* Added Portuguese language support (@beatrizmilz [#488](https://github.com/rstudio/learnr/pull/488))
* Added Basque language support (@mikelmadina [#489](https://github.com/rstudio/learnr/pull/489))
* Added Turkish language support (@hyigit2, @coatless [#493](https://github.com/rstudio/learnr/pull/493))
* Added option for quickly restoring a tutorial without re-evaluating the last stored exercise submission. This feature is enabled by setting the global option `tutorial.quick_restore = TRUE` or the environment variable `TUTORIAL_QUICK_RESTORE=1` (thanks @mstackhouse, [#509](https://github.com/rstudio/learnr/pull/509)).


## Bug fixes

* Properly enforce time limits and measure exercise execution times that exceed 60 seconds ([#366](https://github.com/rstudio/learnr/pull/366), [#368](https://github.com/rstudio/learnr/pull/368))
* Fixed unexpected behavior for `question_is_correct.learnr_text()` where `trim = FALSE`. Comparisons will now happen with the original input value, not the `HTML()` formatted answer value. ([#376](https://github.com/rstudio/learnr/pull/376))
* Fixed exercise progress spinner being prematurely cleared. ([#384](https://github.com/rstudio/learnr/pull/384))
* Updated `run_tutorial()` to render tutorials in a temp directory if the R user does not have write permissions. ([#347](https://github.com/rstudio/learnr/issues/347))
* An informative error is now thrown when an exercise chunk's body contains nothing, which lets the tutorial author know that something (e.g., empty line(s)) must be present in the chunk body for it to be rendered as an exercise. ([#410](https://github.com/rstudio/learnr/issues/410)) ([#172](https://github.com/rstudio/learnr/issues/172))
* When `exercise.completion=TRUE`, completion is no longer performed inside of quotes. This (intentionally) prevents the student from being able to list files on the R server ([#401](https://github.com/rstudio/learnr/issues/401)).
* Fail gracefully when unable to open an indexedDB store (e.g. in cross-origin iframes in Safari). ([#417](https://github.com/rstudio/learnr/issues/417)).
* When a quiz's question or answer text are not characters, e.g. HTML, `htmltools` tags, numeric, etc., they are now cast to characters for the displayed answer text and the quiz's default loading text ([#450](https://github.com/rstudio/learnr/pull/450)).
* The `envir_prep` environment used in exercise checking now captures the result of both global and exercise-specific setup code, representing the environment in which the user code will be evaluated as described in the documentation. We also ensure that `envir_result` (the environment containing the result of evaluating global, setup and user code) is a sibling of `envir_prep`. ([#480](https://github.com/rstudio/learnr/pull/480))
* HTML dependencies of exercises run by users now excludes dependencies created with `htmltools::tags$head()`. (thanks @andysouth, [#484](https://github.com/rstudio/learnr/issues/484))

learnr 0.10.1
===========

## New features

## Minor new features and improvements

* `learnr` gained the function `learnr::tutorial_package_dependencies()`, used to enumerate a tutorial's R package dependencies. Front-ends can use this to ensure a tutorial's dependencies are satisfied before attempting to run that tutorial. `learnr::available_tutorials()` gained the column `package_dependencies` containing the required packages to run the document. ([#329](https://github.com/rstudio/learnr/pull/329))

* Include vignette about publishing learnr tutorials on shinyapps.io. ([#322](https://github.com/rstudio/learnr/pull/322))

* `learnr`'s built-in tutorials now come with a description as part of the YAML header, with the intention of this being used in front-end software that catalogues available `learnr` tutorials on the system. ([#312](https://github.com/rstudio/learnr/issues/312))

* Add `session_start` and `session_stop` events. ([#311](https://github.com/rstudio/learnr/pull/328))

## Bug fixes

* Fixed a bug where broken exercise code created non-"length-one character vector". ([#311](https://github.com/rstudio/learnr/pull/311))

* Fixed extra parameter documentation bug for CRAN. ([#323](https://github.com/rstudio/learnr/pull/323))

* Fixed video initialization error caused by a jQuery version increase in Shiny. ([#326](https://github.com/rstudio/learnr/pull/326))

* Fixed progressive reveal bug where the next section would not be displayed unless refreshed. ([#330](https://github.com/rstudio/learnr/pull/330))

* Fixed a bug where topics would not be loaded if they contained non-ascii characters. ([#330](https://github.com/rstudio/learnr/pull/330))


learnr 0.10.0
===========

## New features

* Quiz questions are implemented using shiny modules (instead of htmlwidgets). ([#194](https://github.com/rstudio/learnr/pull/194))

* Aggressively rerender prerendered tutorials in favor of a cohesive exercise environment ([#169](https://github.com/rstudio/learnr/issues/169), [#179](https://github.com/rstudio/learnr/pull/179), and [rstudio/rmarkdown#1420](https://github.com/rstudio/rmarkdown/pull/1420))

* Added a new function, `safe`, which evaluates code in a new, safe R environment. ([#174](https://github.com/rstudio/learnr/pull/174))

## Minor new features and improvements

* Added the last evaluated exercise submission value, `last_value`, as an exercise checker function argument. ([#228](https://github.com/rstudio/learnr/pull/228))

* Added tabset support. ([#219](https://github.com/rstudio/learnr/pull/219) [#212](https://github.com/rstudio/learnr/issues/212))

* Question width will expand to the container width. ([#222](https://github.com/rstudio/learnr/pull/222))

* Available tutorial names will be displayed when no `name` parameter or an incorrect `name` is provided to `run_tutorial()`. ([#234](https://github.com/rstudio/learnr/pull/234))

* The `options` parameter was added to `question` to allow custom questions to pass along custom information.  See `sortable::sortable_question` for an example. ([#243](https://github.com/rstudio/learnr/pull/243))

* Missing package dependencies will ask to be installed at tutorial run time. (@isteves, [#253](https://github.com/rstudio/learnr/issues/253))

* When questions are tried again, the existing answer will remain, not forcing the user to restart from scratch. ([#270](https://github.com/rstudio/learnr/issues/270))

* A version number has been added to `question_submission` events.  This will help when using custom storage methods. ([#291](https://github.com/rstudio/learnr/pull/291))

* Tutorial storage on the browser is now executed directly on `indexedDB` using `idb-keyval` (dropping `localforage`).  This change prevents browser tabs from blocking each other when trying to access `indexedDB` data. ([#305](https://github.com/rstudio/learnr/pull/305))

## Bug fixes

* Fixed a spurious console warning when running exercises using Pandoc 2.0. ([#154](https://github.com/rstudio/learnr/issues/154))

* Added a fail-safe to try-catch bad student code that would crash the tutorial. ([@adamblake](https://github.com/adamblake), [#229](https://github.com/rstudio/learnr/issues/229))

* Replaced references to `checkthat` and `grader` in docs with [gradethis](https://github.com/rstudio-education/gradethis) ([#269](https://github.com/rstudio/learnr/issues/269))

* Removed a warning created by pandoc when evaluating exercises where pandoc was wanting a title or pagetitle. [#303](https://github.com/rstudio/learnr/pull/303)



learnr 0.9.2
===========

* Fixed [#136](https://github.com/rstudio/learnr/issues/136) by displaying full HTML messages (rather than just the text) if provided by the `incorrect` or the `correct` args to `question()`. ([#146](https://github.com/rstudio/learnr/pull/146))

* Improved documentation for deploying `learnr` tutorials in Shiny Server. ([#142](https://github.com/rstudio/learnr/issues/142))

* Fixed a highlight.js issue from rmarkdown 1.8. ([#133](https://github.com/rstudio/learnr/issues/133))

* Fixed an false positive in the diagnostics system. ([#141](https://github.com/rstudio/learnr/issues/141))

learnr 0.9.1
===========

* Fixed a compatibility issue, so that existing tutorials don't break when using Pandoc 2.0. ([#130](https://github.com/rstudio/learnr/pull/130))

learnr 0.9.0
===========

@ commit [#14413cc](https://github.com/rstudio/learnr/commit/14413cc7ea20fa3b5938b29fab2b01282e6f0c1f)

learnr 0.8.0
===========

@ commit [#eeae534](https://github.com/rstudio/learnr/commit/eeae534fa792dcd369075a90b59b042ad26f945f)

learnr 0.7.0
===========

@ commit [#b71c637](https://github.com/rstudio/learnr/commit/b71c637cb0b1e0cb817e8e0c2fa56a4fcabd58dd)

learnr 0.6.0
===========

@ commit [#55c33cf](https://github.com/rstudio/learnr/commit/55c33cf616d3259c508ae234d301964c599a3039)

learnr 0.5.0
===========

@ commit [#a853163](https://github.com/rstudio/learnr/commit/a8531633f38c13333da6e1c76c6cb6c720e299dd)

learnr 0.4.0
===========

@ commit [#3339f8a](https://github.com/rstudio/learnr/commit/3339f8aaa2d0402622b1881aa42fcc78ea87db51)

learnr 0.3.0
===========

@ commit [#9cd0082](https://github.com/rstudio/learnr/commit/9cd00828bfa2429d88ad9efdbd51ad8475a6efb2)

learnr 0.2.0
===========

@ commit [#a81a694](https://github.com/rstudio/learnr/commit/a81a69498823d860f54c153128719e280de3d831)

learnr 0.1.0
===========

init commit! [#e2dbb20](https://github.com/rstudio/learnr/commit/e2dbb20d8fb7208cffcb339ea0fc5a8c9c45adb5)
