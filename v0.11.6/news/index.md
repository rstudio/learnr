# Changelog

## learnr 0.11.6

CRAN release: 2025-11-13

- Fixed a test that was failing on CRAN’s Fedora gcc environment.
  ([\#827](https://github.com/rstudio/learnr/issues/827))

- Added a new option, `tutorial.exercise.throttle`, to slow down
  successive exercise execution. This option should be set to the number
  of seconds a user will have to wait between performing code
  executions. The option defaults to 1 second to deter rapid code
  executions. To disable submission throttling, call
  `options(tutorial.exercise.throttle = 0)` within your setup chunk.
  ([@internaut](https://github.com/internaut),
  [\#818](https://github.com/rstudio/learnr/issues/818))

- Removed dependency on ellipsis
  ([@olivroy](https://github.com/olivroy),
  [\#809](https://github.com/rstudio/learnr/issues/809))

- Added Norwegian translation contributed by
  [@jonovik](https://github.com/jonovik).
  ([\#806](https://github.com/rstudio/learnr/issues/806))

## learnr 0.11.5

CRAN release: 2023-09-28

### New Features

- You can now customize the “continue” button text in sub-topics by
  adding ‘data-continue-text’ with your custom label as a property of
  the section heading —
  e.g. `### Subtopic Title {data-continue-text="Show Solution"}`
  ([@dave-mills](https://github.com/dave-mills)
  [\#777](https://github.com/rstudio/learnr/issues/777)).

- A new `exercise.pipe` tutorial or exercise chunk option can now be
  used to determine which pipe operator is used for interactive
  exercises. The default is `"|>"` (the native R pipe) when the tutorial
  is rendered with R \>= 4.1.0, or `"%>%"` otherwise (the magrittr
  pipe). You can set the pipe used for the tutorial using
  [`tutorial_options()`](https:/pkgs.rstudio.com/learnr/v0.11.6/reference/tutorial_options.md),
  or you can use `exercise.pipe` as a knitr chunk option on an
  individual exercise chunk.
  ([\#804](https://github.com/rstudio/learnr/issues/804))

### Bug fixes and improvements

- learnr tutorials now work when Quarto comment-style chunk options are
  used to set the chunk `label` (thanks
  [@jimjam-slam](https://github.com/jimjam-slam),
  [\#795](https://github.com/rstudio/learnr/issues/795)).

- Added a new quick restore option that restores both the last submitted
  exercise code and the output of that submission, if the output is
  available to be restored. This option is enabled by setting the global
  option `tutorial.quick_restore = 2` or the environment variable
  `TUTORIAL_QUICK_RESTORE=2`. This option augments the quick restore
  value when `TRUE` or `1`, wherein only the last submitted **code** is
  restored, such that users will need to click the “Submit” button to
  evaluate and see the output.
  ([\#794](https://github.com/rstudio/learnr/issues/794))

- When the `LC_ALL` environment variable is `"C"` or `"C.UTF-8"`, R may
  ignore the `LANGUAGE` environment variable, which means that learnr
  may not be able to control the language of R’s messages. learnr’s
  tests no longer test R message translations in these cases. If you are
  deploying a tutorial written in a language other than English, you
  should ensure that the `LC_ALL` environment variable is not set to
  `"C"` or `"C.UTF-8"` and you may need to set the `LANGUAGE` variable
  via an `.Renviron` file rather than relying on learnr
  ([\#801](https://github.com/rstudio/learnr/issues/801)).

## learnr 0.11.4

CRAN release: 2023-05-24

- Moved curl from Imports to Suggests. curl is only required when using
  an external evaluator
  ([\#776](https://github.com/rstudio/learnr/issues/776)).

- The default `try_again` message for checkbox questions now prompts the
  student to “select every correct answer” regardless of whether the
  question was created by
  [`question()`](https:/pkgs.rstudio.com/learnr/v0.11.6/reference/quiz.md)
  or
  [`question_checkbox()`](https:/pkgs.rstudio.com/learnr/v0.11.6/reference/question_checkbox.md)
  ([\#783](https://github.com/rstudio/learnr/issues/783)).

## learnr 0.11.3

CRAN release: 2023-03-15

- Fixed an issue that prevented authors from using symbols, such as `T`
  or a variable, as the value of the `exercise` chunk option, which
  caused tutorials with chunks with `exercise = T` to fail to render
  (thanks [@cknotz](https://github.com/cknotz)
  [\#757](https://github.com/rstudio/learnr/issues/757),
  [\#758](https://github.com/rstudio/learnr/issues/758)).

- The embedded Ace editor used in learnr exercises now defaults to a tab
  width of 2, aligning with the Tidyverse style guide
  ([\#761](https://github.com/rstudio/learnr/issues/761)).

- learnr now pre-renders (in English) the feedback message it provides
  when non-ASCII characters are included in submitted unparsable R code.
  This makes the feedback useful even if learnr’s in-browser
  translations aren’t available
  ([\#765](https://github.com/rstudio/learnr/issues/765)).

## learnr 0.11.2

CRAN release: 2022-11-08

- Fixed an issue that prevented htmlwidgets from working in exercise
  code unless similar widgets were added to the tutorial prose (thanks
  [@munoztd0](https://github.com/munoztd0)
  [\#744](https://github.com/rstudio/learnr/issues/744),
  [\#745](https://github.com/rstudio/learnr/issues/745)).

- learnr now requires **markdown** version 1.3 or later
  ([\#745](https://github.com/rstudio/learnr/issues/745)).

- Fixed a test involving UTF-8 character strings
  ([\#749](https://github.com/rstudio/learnr/issues/749)).

## learnr 0.11.1

CRAN release: 2022-10-19

This is a maintenance release that adjusts an example and several tests
for CRAN.

## learnr 0.11.0

CRAN release: 2022-10-16

### Authoring

- It is now possible to provide customized feedback when an exercise
  submission produces an evaluation error. The checking function applied
  when the user code results in an error is defined via the
  `exercise.error.checker` option of
  [`tutorial_options()`](https:/pkgs.rstudio.com/learnr/v0.11.6/reference/tutorial_options.md)
  ([\#403](https://github.com/rstudio/learnr/issues/403)).
  `gradethis::grade_learnr_error()` is a sensible default for this
  option.

  Additionally, user submissions for R code exercises are now checked
  for parsing errors prior to any other checks. If the submitted code is
  unparsable, a friendly error feedback message is returned and no
  further evaluation or checking is performed
  ([@rossellhayes](https://github.com/rossellhayes)
  [\#547](https://github.com/rstudio/learnr/issues/547)).

- Authors can now provide data files for use with interactive exercises.
  Any files stored in a `data/` directory adjacent to the tutorial R
  Markdown document are now automatically made available within
  exercises. An alternative directory can be specified using the
  `tutorial.data_dir` global option
  ([@rossellhayes](https://github.com/rossellhayes)
  [\#539](https://github.com/rstudio/learnr/issues/539)).

- An informative error is now thrown when an exercise chunk’s body
  contains nothing, which lets the tutorial author know that something
  (e.g., empty line(s)) must be present in the chunk body for it to be
  rendered as an exercise
  ([@KatherineCox](https://github.com/KatherineCox)
  [\#172](https://github.com/rstudio/learnr/issues/172),
  [\#410](https://github.com/rstudio/learnr/issues/410)).

- Custom CSS files are now loaded last, after all of learnr’s other web
  dependencies ([\#574](https://github.com/rstudio/learnr/issues/574)).

- Footnotes now appear at the end of the section in which they appear
  (thanks [@plukethep](https://github.com/plukethep),
  [\#647](https://github.com/rstudio/learnr/issues/647)).

### Setup Chunk Chaining

- Exercise chunks can now be “chained together” via chained setup
  chunks. The setup chunk of one exercise may depend on other chunks,
  including the setup chunks of other exercises, allowing the author to
  form a chain of setup code that allows interactive exercises to
  progressively work through a problem. These chains are defined using
  the `exercise.setup` chunk option; use
  `run_tutorial("setup_chunks", "learnr")` to run a demo tutorial
  ([@nischalshrestha](https://github.com/nischalshrestha)
  [\#390](https://github.com/rstudio/learnr/issues/390)).

  - As part of this work, learnr now throws an error at pre-render when
    an author specifies an non-existent chunk label in the
    `exercise.setup` of an exercise.
  - learnr also now forces the chunk option `include = FALSE` for setup
    chunks when evaluated as part of an exercise to avoid unexpected
    printing of results.

### Internationalization and Customization

- Text throughout the learnr interface can be customized or localized
  using the new language argument of
  [`tutorial()`](https:/pkgs.rstudio.com/learnr/v0.11.6/reference/tutorial.md)
  ([\#456](https://github.com/rstudio/learnr/issues/456),
  [\#479](https://github.com/rstudio/learnr/issues/479)). The random
  positive and encourage phrases generated by learnr can also be
  translated ([\#538](https://github.com/rstudio/learnr/issues/538)).
  Community contributions for additional languages are welcomed, but it
  is possible to customize the language used for the learnr interface
  and phrases without requiring official support via the learnr package.
  You can read more about these features in
  [`vignette("multilang", package = "learnr")`](https:/pkgs.rstudio.com/learnr/v0.11.6/articles/multilang.md).

  We are very grateful to the following community members for providing
  additional languages:

  - Basque language support was contributed by
    [@mikelmadina](https://github.com/mikelmadina)
    ([\#489](https://github.com/rstudio/learnr/issues/489))
  - Portuguese language support was contributed by
    [@beatrizmilz](https://github.com/beatrizmilz)
    ([\#488](https://github.com/rstudio/learnr/issues/488),
    [\#551](https://github.com/rstudio/learnr/issues/551))
  - Spanish language support was contributed by
    [@yabellini](https://github.com/yabellini)
    ([\#483](https://github.com/rstudio/learnr/issues/483),
    [\#546](https://github.com/rstudio/learnr/issues/546))
  - Turkish language support was contributed by
    [@hyigit2](https://github.com/hyigit2) and
    [@coatless](https://github.com/coatless)
    ([\#493](https://github.com/rstudio/learnr/issues/493),
    [\#554](https://github.com/rstudio/learnr/issues/554))
  - German language support was contributed by
    [@NinaCorrelAid](https://github.com/NinaCorrelAid)
    ([\#611](https://github.com/rstudio/learnr/issues/611),
    [\#612](https://github.com/rstudio/learnr/issues/612))
  - Korean language support was contributed by
    [@choonghyunryu](https://github.com/choonghyunryu)
    ([\#634](https://github.com/rstudio/learnr/issues/634))
  - Chinese language support was contributed by
    [@shalom-lab](https://github.com/shalom-lab)
    ([\#681](https://github.com/rstudio/learnr/issues/681))
  - Polish language support was contributed by Jakub Jędrusiak
    ([@kuba58426](https://github.com/kuba58426))
    ([\#686](https://github.com/rstudio/learnr/issues/686))

- Messages generated by R during exercises are now translated to match
  the tutorial language, if translations are available either in base R
  or in the R package generating the message
  ([@rossellhayes](https://github.com/rossellhayes)
  [\#558](https://github.com/rstudio/learnr/issues/558)).

- **Breaking Change:**
  [`random_praise()`](https:/pkgs.rstudio.com/learnr/v0.11.6/reference/random_praise.md)
  no longer includes the phrase `"Correct! "`. Instead, it simply
  returns a random praising statement
  ([\#453](https://github.com/rstudio/learnr/issues/453),
  [\#463](https://github.com/rstudio/learnr/issues/463)).

### Support for Additional Programming Languages

- Added a new polyglot tutorial to learnr. This tutorial demonstrates
  how learnr tutorials might mix R, Python, and SQL exercises. See
  `run_tutorial("polyglot", "learnr")` for a an example
  ([\#397](https://github.com/rstudio/learnr/issues/397)).

- `engine` is now passed to the `exercise.checker` to communicate which
  programming language is being checked in the exercise
  ([\#397](https://github.com/rstudio/learnr/issues/397)).

- The `exercise.cap` exercise/chunk option now accepts HTML input. If no
  `exercise.cap` is provided, the `exercise.cap` will default to the
  combination of the exercise engine and `" code"`
  ([\#397](https://github.com/rstudio/learnr/issues/397),
  [\#429](https://github.com/rstudio/learnr/issues/429)).

- Improved support for SQL exercises makes it possible to check student
  submissions for SQL exercises. See
  `run_tutorial("sql-exericse", "learnr")` or the [online SQL exercise
  demo](https://learnr-examples.shinyapps.io/sql-exercise) for an
  example tutorial with graded SQL exercises
  ([\#668](https://github.com/rstudio/learnr/issues/668)).

- Exercise editors now use syntax highlighting and basic autocompletion
  for exercises in languages other than R with syntax highlighting
  support for JavaScript, Julia, Python and SQL
  ([\#693](https://github.com/rstudio/learnr/issues/693)).

- Broadly improved support for additional programming languages and
  added support for Python exercises
  ([\#724](https://github.com/rstudio/learnr/issues/724)).

### Interactive Exercises and Questions

#### Exercises

- Users are now warned if their submission contains blanks they are
  expected to fill in. The default blank pattern is three or more
  underscores, e.g. `____`. The pattern for blanks can be set with the
  `exercise.blanks` chunk or tutorial option
  ([@rossellhayes](https://github.com/rossellhayes)
  [\#547](https://github.com/rstudio/learnr/issues/547)).

- Users who submit unparsable code containing non-ASCII characters are
  now presented with more informative feedback. Non-ASCII characters are
  a common source of code problems and often appear in code when
  students copy and paste text from a source that applies automatic
  Unicode formatting. If the submission contains Unicode-formatted
  quotation marks (e.g. curly quotes) or dashes, the student is given a
  suggested replacement with ASCII characters. In other cases, the
  student is simply prompted to delete the non-ASCII characters and
  retype them manually ([@rossellhayes](https://github.com/rossellhayes)
  [\#642](https://github.com/rstudio/learnr/issues/642)).

- Authors can choose to reveal (default) or hide the solution to an
  exercise. Set `exercise.reveal_solution` in the chunk options of a
  `*-solution` chunk to choose whether or not the solution is revealed
  to the user. The option can also be set globally with
  [`tutorial_options()`](https:/pkgs.rstudio.com/learnr/v0.11.6/reference/tutorial_options.md).
  In a future version of learnr, the default will likely be changed to
  hide solutions
  ([\#402](https://github.com/rstudio/learnr/issues/402)).

- Exercises may now include `-tests` chunks. These chunks don’t appear
  in the tutorial text but the code in them is stored in the internal
  exercise data. In the future, these chunks will be used to provide
  automated exercise testing
  ([\#664](https://github.com/rstudio/learnr/issues/664),
  [\#700](https://github.com/rstudio/learnr/issues/700)).

- Keyboard navigation and keyboard shortcuts for the interactive
  exercise code editor have been improved:

  - To avoid trapping keyboard focus and to allow users to navigate
    through a tutorial with the keyboard, pressing Esc in an interactive
    exercise code editor now temporarily disables the use of Tab for
    indenting, making it possible for users to move to the next or
    previous element in the tutorial
    ([\#652](https://github.com/rstudio/learnr/issues/652)).

  - Interactive exercises now know the RStudio shortcuts for the pipe
    (`%>%`) (Command/Control + Shift + M) and assignment (`<-`) (Alt +
    -) operators in exercise code boxes
    ([\#472](https://github.com/rstudio/learnr/issues/472)).

  - Clicking **Run Code** or using the keyboard shortcut (Cmd/Ctrl +
    Enter) now runs the selected code only, if any code is selected
    (thanks [@petzi53](https://github.com/petzi53)
    [\#512](https://github.com/rstudio/learnr/issues/512),
    [\#514](https://github.com/rstudio/learnr/issues/514)).

  - Commented code within an exercise is no longer be auto completed
    ([\#604](https://github.com/rstudio/learnr/issues/604)).

  - Hitting the TAB key in an exercise has always opened the
    auto-completion drop down. Now, hitting the TAB key will also
    complete the currently selected code completion
    ([\#428](https://github.com/rstudio/learnr/issues/428)).

- The native R pipe, introduced in R 4.1, is now recognized as a valid R
  operator in the interactive exercise editor (thanks
  [@ijlyttle](https://github.com/ijlyttle),
  [\#595](https://github.com/rstudio/learnr/issues/595)).

- Feedback messages can now be an
  [`htmltools::tag()`](https://rstudio.github.io/htmltools/reference/builder.html),
  [`htmltools::tagList()`](https://rstudio.github.io/htmltools/reference/tagList.html),
  or a character message
  ([\#458](https://github.com/rstudio/learnr/issues/458)).

- We no longer display an invisible exercise result warning
  automatically. Instead, authors must set the exercise chunk option
  exercise.warn_invisible = TRUE to display an invisible result warning
  message ([@nischalshrestha](https://github.com/nischalshrestha)
  [\#373](https://github.com/rstudio/learnr/issues/373)).

- When `exercise.completion = TRUE`, completion is no longer performed
  inside of quotes. This (intentionally) prevents the student from being
  able to list files on the R server
  ([\#401](https://github.com/rstudio/learnr/issues/401)).

- When an exercise returns HTML generated with
  [htmlwidgets](https://github.com/ramnathv/htmlwidgets) or
  [htmltools](https://github.com/rstudio/htmltools), learnr will remove
  the HTML dependences created with `htmltools::tags$head()` from the
  result returned to the tutorial. This avoids conflicts with the
  scripts and dependencies used by the learnr tutorial (thanks
  [@andysouth](https://github.com/andysouth),
  [\#484](https://github.com/rstudio/learnr/issues/484)).

- Fixed exercise progress spinner being prematurely cleared
  ([\#384](https://github.com/rstudio/learnr/issues/384)).

- Empty exercise chunks are now allowed. Please use caution: in very
  rare cases, knitr and learnr may not notice duplicate chunk labels
  when an exercise uses a duplicated label. Allowing empty exercise
  chunks improves the ergonomics when using [knitr’s chunk option
  comments](https://yihui.org/en/2022/01/knitr-news/)
  ([\#712](https://github.com/rstudio/learnr/issues/712)).

#### Exercise Evaluation

- **Breaking Change:** If a `-code-check` chunk returns feedback for an
  exercise submission, the result of the exercise is no longer displayed
  for a correct answer (only the feedback is displayed). If both the
  result and feedback should be displayed, all checking should be
  performed in a `-check` chunk (i.e., don’t provide a `-code-check`
  chunk) ([\#403](https://github.com/rstudio/learnr/issues/403)).

- Exercise checking is now conducted in the same temporary directory
  where exercises are evaluated
  ([@rossellhayes](https://github.com/rossellhayes)
  [\#544](https://github.com/rstudio/learnr/issues/544)).

- Exercises evaluation now communicates the stage of evaluation via a
  new `stage` argument passed to the checker function. Stages may be
  `"code_check"`, `"error_check"`, or `"check"`. This makes it easier
  for the exercise checking function to determine at which point
  checking is being applied in the exercise evaluation life cycle
  ([@rossellhayes](https://github.com/rossellhayes)
  [\#610](https://github.com/rstudio/learnr/issues/610)).

- [`options()`](https://rdrr.io/r/base/options.html) and environment
  variables are now reset after rendering exercises so that changes made
  by user input or checking code cannot affect other exercises
  ([@rossellhayes](https://github.com/rossellhayes)
  [\#542](https://github.com/rstudio/learnr/issues/542)).

- Parse errors from user code that fails to parse can now be inspected
  by the error checker, but errors in exercise setup chunks cannot.
  Instead, global setup and setup chunk errors are raised as internal
  errors with a user-facing warning. In general, internal errors are now
  handled more consistently
  ([\#596](https://github.com/rstudio/learnr/issues/596)).

  - The parsing error object now has a `"parse_error"` class so that you
    can use `inherits(last_value, "parse_error")` in learnr error
    checking code or `inherits(.result, "parse_error")` in gradethis
    error checking to differentiate the parse error from other error
    types ([\#658](https://github.com/rstudio/learnr/issues/658)).

- learnr now properly enforces the time limit set by the
  `exercise.timelimit` chunk option
  ([\#366](https://github.com/rstudio/learnr/issues/366),
  [\#368](https://github.com/rstudio/learnr/issues/368),
  [\#494](https://github.com/rstudio/learnr/issues/494)).

- The `envir_prep` environment used in exercise checking now accurately
  captures the result of both global and exercise-specific setup code,
  representing the environment in which the user code will be evaluated
  (as was described in the documentation). learnr also ensures that
  `envir_result` (the environment containing the result of evaluating
  global, setup and user code) is a sibling of `envir_prep`
  ([\#480](https://github.com/rstudio/learnr/issues/480)).

- When `allow_skip` is set to `FALSE`, users are now required to run an
  exercise once with non-empty code in order to move forward. If the
  exercise has grading code, users are required to submit one
  (non-empty) answer (thanks [@gaelso](https://github.com/gaelso)
  [\#616](https://github.com/rstudio/learnr/issues/616),
  [\#633](https://github.com/rstudio/learnr/issues/633)).

- If an exercise includes a `-check` chunk but no `exercise.checker`
  function has been defined, learnr will now throw an error at render
  reminding the author to use
  [`tutorial_options()`](https:/pkgs.rstudio.com/learnr/v0.11.6/reference/tutorial_options.md)
  to define an exercise checker
  ([\#640](https://github.com/rstudio/learnr/issues/640)).

#### Questions

- Authors can now provide function-answers with
  [`answer_fn()`](https:/pkgs.rstudio.com/learnr/v0.11.6/reference/answer.md).
  Authors can provide a function that takes a single argument that will
  be passed the student’s question submission. This function decides if
  the question is correct and provides feedback by returning
  [`correct()`](https:/pkgs.rstudio.com/learnr/v0.11.6/reference/mark_as_correct_incorrect.md)
  or
  [`incorrect()`](https:/pkgs.rstudio.com/learnr/v0.11.6/reference/mark_as_correct_incorrect.md)
  with a feedback message
  ([\#657](https://github.com/rstudio/learnr/issues/657)).

- A new
  [`question_numeric()`](https:/pkgs.rstudio.com/learnr/v0.11.6/reference/question_numeric.md)
  question type allows authors to ask users to provide a number
  ([\#461](https://github.com/rstudio/learnr/issues/461)).

- [`question_text()`](https:/pkgs.rstudio.com/learnr/v0.11.6/reference/question_text.md)
  gains `rows` and `cols` parameters. If either is provided, a
  multi-line `textAreaInput()` is used for the text input (thanks
  [@dtkaplan](https://github.com/dtkaplan)
  [\#455](https://github.com/rstudio/learnr/issues/455),
  [\#460](https://github.com/rstudio/learnr/issues/460)).

- Correct/incorrect question markers are now configurable via CSS. You
  can change or style these markers using the
  `.tutorial-question .question-final .correct::before` and
  `.tutorial-question .question-final .incorrect::before` selectors. A
  new helper function,
  [`finalize_question()`](https:/pkgs.rstudio.com/learnr/v0.11.6/reference/finalize_question.md),
  can be used to apply the `.question-final` class to custom learnr
  questions ([\#531](https://github.com/rstudio/learnr/issues/531)).

- Fixed a bug to avoid selecting the answer labeled `"FALSE"` by default
  in
  [`question_radio()`](https:/pkgs.rstudio.com/learnr/v0.11.6/reference/question_radio.md)
  ([\#515](https://github.com/rstudio/learnr/issues/515)).

- Fixed unexpected behavior for `question_is_correct.learnr_text()`
  where `trim = FALSE`. Comparisons will now happen with the original
  input value, not the `HTML()` formatted answer value
  ([\#376](https://github.com/rstudio/learnr/issues/376)).

- When a quiz’s question or answer text are not characters, e.g. HTML,
  [htmltools](https://github.com/rstudio/htmltools) tags, numeric, etc.,
  they are now cast to characters for the displayed answer text and the
  quiz’s default loading text
  ([\#450](https://github.com/rstudio/learnr/issues/450)).

### Events and State

- **Breaking Change:** The `exercise_submission` event was renamed to
  `exercise_result` and now includes the following new fields
  ([\#337](https://github.com/rstudio/learnr/issues/337)):

  - `id` - a randomly generated identifier that can be used to align
    with the associated `exercise_result` event
  - `time_elapsed` - the time required to run the exercise (in seconds)
  - `timeout_exceeded` - indicates whether the exercise was interrupted
    due to an exceeded timeout. May be `NA` for some
    platforms/evaluators if that information is not known or reported.

- Added a general-purpose event handler system, powered by the functions
  [`event_register_handler()`](https:/pkgs.rstudio.com/learnr/v0.11.6/reference/event_register_handler.md)
  and
  [`one_time()`](https:/pkgs.rstudio.com/learnr/v0.11.6/reference/one_time.md).
  These functions can be used to execute code every time a
  learnr-specific event occurs
  ([\#398](https://github.com/rstudio/learnr/issues/398)).

- Several learnr events were updated and two new events were created:

  - A new event named `"section_viewed"` now reports when a new section
    becomes visible.
  - Added an `"exercise_submitted"` event which is fired before
    evaluating an exercise. This event can be associated with an
    `"exercise_result"` event using the randomly generated id included
    in the data of both events
    ([\#337](https://github.com/rstudio/learnr/issues/337)). The
    `"exercise_submitted"` event also now contains a `restore` field
    indicating whether the exercise is being restored from a previous
    execution (`TRUE`), or that the exercise is being run interactively
    (`FALSE`) ([\#370](https://github.com/rstudio/learnr/issues/370)).
  - A new `label` field of the `"exercise_hint"` event identifies the
    exercise for which the user requested a hint
    ([\#377](https://github.com/rstudio/learnr/issues/377)).
  - Previously, when a question submission was reset, it would be
    recorded as a `"question_submission"` event with the value
    `reset = TRUE`. Now it a separate event,
    `"reset_question_submission"`.

- Tutorial authors can now access the current state of the user’s
  progress in a tutorial with
  [`get_tutorial_state()`](https:/pkgs.rstudio.com/learnr/v0.11.6/reference/get_tutorial_state.md)
  or get information about the current tutorial with
  [`get_tutorial_info()`](https:/pkgs.rstudio.com/learnr/v0.11.6/reference/get_tutorial_info.md)
  ([\#562](https://github.com/rstudio/learnr/issues/562)). Tutorial
  state is now returned by
  [`get_tutorial_state()`](https:/pkgs.rstudio.com/learnr/v0.11.6/reference/get_tutorial_state.md)
  in order of appearance in the tutorial. The full list of exercises and
  questions is included as items in the list returned by
  [`get_tutorial_info()`](https:/pkgs.rstudio.com/learnr/v0.11.6/reference/get_tutorial_info.md)
  (thanks [@NuoWenLei](https://github.com/NuoWenLei)
  [\#570](https://github.com/rstudio/learnr/issues/570),
  [\#571](https://github.com/rstudio/learnr/issues/571)).

- [`get_tutorial_info()`](https:/pkgs.rstudio.com/learnr/v0.11.6/reference/get_tutorial_info.md)
  can now provide complete tutorial info for an `.Rmd` or pre-rendered
  `.html` tutorial file outside of a Shiny app
  ([\#688](https://github.com/rstudio/learnr/issues/688),
  [\#702](https://github.com/rstudio/learnr/issues/702)).

- We no longer forward the checker code to browser (in html), but
  instead cache it
  ([@nischalshrestha](https://github.com/nischalshrestha)
  [\#390](https://github.com/rstudio/learnr/issues/390)).

- Fail gracefully when unable to open an indexedDB store (e.g. in
  cross-origin iframes in Safari)
  ([\#417](https://github.com/rstudio/learnr/issues/417)).

### Running Tutorials

- Running learnr tutorials with
  [`run_tutorial()`](https:/pkgs.rstudio.com/learnr/v0.11.6/reference/run_tutorial.md)
  has been improved
  ([\#601](https://github.com/rstudio/learnr/issues/601)):

  - [`run_tutorial()`](https:/pkgs.rstudio.com/learnr/v0.11.6/reference/run_tutorial.md)
    can now run local tutorials in addition to tutorials hosted in a
    package. To run a local tutorial provide the path to the tutorial or
    the directory containing the tutorial via the `name` argument
    without providing the `package` argument.
  - **Breaking change:** names must be provided for all arguments to
    [`run_tutorial()`](https:/pkgs.rstudio.com/learnr/v0.11.6/reference/run_tutorial.md)
    other than `name` and `package`.
  - [`run_tutorial()`](https:/pkgs.rstudio.com/learnr/v0.11.6/reference/run_tutorial.md)
    gains a `clean` argument to completely re-render the tutorial if
    needed.
  - learnr tutorials are now run as background RStudio jobs and open in
    the viewer pane when
    [`run_tutorial()`](https:/pkgs.rstudio.com/learnr/v0.11.6/reference/run_tutorial.md)
    is called in RStudio. This default is disabled in non-interactive
    settings or when `as_rstudio_job = FALSE`. You can control where the
    tutorial is opened with the `shiny.launch.browser` global option.
  - [`run_tutorial()`](https:/pkgs.rstudio.com/learnr/v0.11.6/reference/run_tutorial.md)
    now renders tutorials in a temp directory if the R user does not
    have write permissions
    ([\#347](https://github.com/rstudio/learnr/issues/347)).

- Many of the HTML dependencies used by learnr have been updated to more
  recent versions
  ([\#655](https://github.com/rstudio/learnr/issues/655)). learnr now
  uses:

  - [Ace](https://ace.c9.io/) version
    [1.10.1](https://github.com/ajaxorg/ace/blob/ff3dd698/CHANGELOG.md)
  - [clipboard.js](https://clipboardjs.com/) version
    [2.0.10](https://github.com/zenorocha/clipboard.js/releases)
  - [Bootbox](https://bootboxjs.com/) version
    [5.5.2](https://github.com/bootboxjs/bootbox/blob/HEAD/CHANGELOG.md)
  - [i18next](https://www.i18next.com/) version
    [21.6.10](https://github.com/i18next/i18next/blob/master/CHANGELOG.md)

- learnr’s knitr hooks are now set by the
  [`learnr::tutorial`](https:/pkgs.rstudio.com/learnr/v0.11.6/reference/tutorial.md)
  R Markdown format. They are also registered for any tutorials run by
  [`run_tutorial()`](https:/pkgs.rstudio.com/learnr/v0.11.6/reference/run_tutorial.md)
  (thanks [@czucca](https://github.com/czucca)
  [\#598](https://github.com/rstudio/learnr/issues/598),
  [\#599](https://github.com/rstudio/learnr/issues/599)).

- For the “forked” evaluator (the default used on Linux), learnr now
  limits the number of forked exercises that learnr will execute in
  parallel. Previously, this was uncapped, which could cause a learnr
  process to run out of memory when an influx of traffic arrived. The
  default limit is 3, but it can be configured using the
  `tutorial.max.forked.procs` option or the `TUTORIAL_MAX_FORKED_PROCS`
  environment variable
  ([\#353](https://github.com/rstudio/learnr/issues/353)).

- Introduced an experimental function
  [`external_evaluator()`](https:/pkgs.rstudio.com/learnr/v0.11.6/reference/external_evaluator.md)
  which can be used to define an exercise evaluator that runs on a
  remote server and is invoked via HTTP. This allows all exercise
  execution to be performed outside of the Shiny process hosting the
  learnr document
  ([\#345](https://github.com/rstudio/learnr/issues/345),
  [\#354](https://github.com/rstudio/learnr/issues/354)).

- Added option for quickly restoring a tutorial without re-evaluating
  the last stored exercise submission. This feature is enabled by
  setting the global option `tutorial.quick_restore = TRUE` or the
  environment variable `TUTORIAL_QUICK_RESTORE=1` (thanks
  [@mstackhouse](https://github.com/mstackhouse),
  [\#509](https://github.com/rstudio/learnr/issues/509)).

- `exercise_result()` no longer combines the code output and feedback;
  this now happens just before presenting the exercise result to the
  user ([\#522](https://github.com/rstudio/learnr/issues/522)).

- Support the updated Bootstrap 4+ popover dispose method name,
  previously destroy
  ([\#560](https://github.com/rstudio/learnr/issues/560)).

- Forked evaluator (used by default on Linux and
  [shinyapps.io](https://www.shinyapps.io/)) now only collects the
  exercise evaluation result once, avoiding a “cannot wait for child”
  warning (thanks [@tombeesley](https://github.com/tombeesley)
  [\#449](https://github.com/rstudio/learnr/issues/449),
  [\#631](https://github.com/rstudio/learnr/issues/631)).

- [`learnr::tutorial()`](https:/pkgs.rstudio.com/learnr/v0.11.6/reference/tutorial.md)
  now allows authors to adjust the value of `lib_dir`
  ([\#648](https://github.com/rstudio/learnr/issues/648)).

- learnr now uses and suggests
  [shinytest2](https://rstudio.github.io/shinytest2/) for automated
  testing of tutorials in the browser. If you were previously using
  [shinytest](https://rstudio.github.io/shinytest/) to test your
  tutorials, you may find the [Migrating from
  shinytest](https://rstudio.github.io/shinytest2//articles/z-migration.html)
  article to be helpful
  ([\#694](https://github.com/rstudio/learnr/issues/694)).

## learnr 0.10.1

CRAN release: 2020-02-13

### New features

### Minor new features and improvements

- `learnr` gained the function
  [`learnr::tutorial_package_dependencies()`](https:/pkgs.rstudio.com/learnr/v0.11.6/reference/tutorial_package_dependencies.md),
  used to enumerate a tutorial’s R package dependencies. Front-ends can
  use this to ensure a tutorial’s dependencies are satisfied before
  attempting to run that tutorial.
  [`learnr::available_tutorials()`](https:/pkgs.rstudio.com/learnr/v0.11.6/reference/available_tutorials.md)
  gained the column `package_dependencies` containing the required
  packages to run the document
  ([\#329](https://github.com/rstudio/learnr/issues/329)).

- Include vignette about publishing learnr tutorials on shinyapps.io
  ([\#322](https://github.com/rstudio/learnr/issues/322)).

- `learnr`’s built-in tutorials now come with a description as part of
  the YAML header, with the intention of this being used in front-end
  software that catalogues available `learnr` tutorials on the system
  ([\#312](https://github.com/rstudio/learnr/issues/312)).

- Add `session_start` and `session_stop` events
  ([\#311](https://github.com/rstudio/learnr/issues/311)).

### Bug fixes

- Fixed a bug where broken exercise code created non-“length-one
  character vector”
  ([\#311](https://github.com/rstudio/learnr/issues/311)).

- Fixed extra parameter documentation bug for CRAN
  ([\#323](https://github.com/rstudio/learnr/issues/323)).

- Fixed video initialization error caused by a jQuery version increase
  in Shiny ([\#326](https://github.com/rstudio/learnr/issues/326)).

- Fixed progressive reveal bug where the next section would not be
  displayed unless refreshed
  ([\#330](https://github.com/rstudio/learnr/issues/330)).

- Fixed a bug where topics would not be loaded if they contained
  non-ascii characters
  ([\#330](https://github.com/rstudio/learnr/issues/330)).

## learnr 0.10.0

CRAN release: 2019-11-09

### New features

- Quiz questions are implemented using shiny modules (instead of
  htmlwidgets) ([\#194](https://github.com/rstudio/learnr/issues/194)).

- Aggressively rerender prerendered tutorials in favor of a cohesive
  exercise environment
  ([\#169](https://github.com/rstudio/learnr/issues/169),
  [\#179](https://github.com/rstudio/learnr/issues/179), and
  [rstudio/rmarkdown#1420](https://github.com/rstudio/rmarkdown/pull/1420))

- Added a new function, `safe`, which evaluates code in a new, safe R
  environment ([\#174](https://github.com/rstudio/learnr/issues/174)).

### Minor new features and improvements

- Added the last evaluated exercise submission value, `last_value`, as
  an exercise checker function argument
  ([\#228](https://github.com/rstudio/learnr/issues/228)).

- Added tabset support
  ([\#219](https://github.com/rstudio/learnr/issues/219)
  [\#212](https://github.com/rstudio/learnr/issues/212)).

- Question width will expand to the container width
  ([\#222](https://github.com/rstudio/learnr/issues/222)).

- Available tutorial names will be displayed when no `name` parameter or
  an incorrect `name` is provided to
  [`run_tutorial()`](https:/pkgs.rstudio.com/learnr/v0.11.6/reference/run_tutorial.md)
  ([\#234](https://github.com/rstudio/learnr/issues/234)).

- The `options` parameter was added to `question` to allow custom
  questions to pass along custom information. See
  `sortable::sortable_question` for an example
  ([\#243](https://github.com/rstudio/learnr/issues/243)).

- Missing package dependencies will ask to be installed at tutorial run
  time ([@isteves](https://github.com/isteves),
  [\#253](https://github.com/rstudio/learnr/issues/253)).

- When questions are tried again, the existing answer will remain, not
  forcing the user to restart from scratch
  ([\#270](https://github.com/rstudio/learnr/issues/270)).

- A version number has been added to `question_submission` events. This
  will help when using custom storage methods
  ([\#291](https://github.com/rstudio/learnr/issues/291)).

- Tutorial storage on the browser is now executed directly on
  `indexedDB` using `idb-keyval` (dropping `localforage`). This change
  prevents browser tabs from blocking each other when trying to access
  `indexedDB` data
  ([\#305](https://github.com/rstudio/learnr/issues/305)).

### Bug fixes

- Fixed a spurious console warning when running exercises using Pandoc
  2.0 ([\#154](https://github.com/rstudio/learnr/issues/154)).

- Added a fail-safe to try-catch bad student code that would crash the
  tutorial ([@adamblake](https://github.com/adamblake)
  [\#229](https://github.com/rstudio/learnr/issues/229)).

- Replaced references to `checkthat` and `grader` in docs with
  [gradethis](https://github.com/rstudio/gradethis)
  ([\#269](https://github.com/rstudio/learnr/issues/269))

- Removed a warning created by pandoc when evaluating exercises where
  pandoc was wanting a title or pagetitle.
  [\#303](https://github.com/rstudio/learnr/issues/303)

## learnr 0.9.2

CRAN release: 2018-03-09

- Fixed [\#136](https://github.com/rstudio/learnr/issues/136) by
  displaying full HTML messages (rather than just the text) if provided
  by the `incorrect` or the `correct` args to
  [`question()`](https:/pkgs.rstudio.com/learnr/v0.11.6/reference/quiz.md)
  ([\#146](https://github.com/rstudio/learnr/issues/146)).

- Improved documentation for deploying `learnr` tutorials in Shiny
  Server ([\#142](https://github.com/rstudio/learnr/issues/142)).

- Fixed a highlight.js issue from rmarkdown 1.8
  ([\#133](https://github.com/rstudio/learnr/issues/133)).

- Fixed an false positive in the diagnostics system
  ([\#141](https://github.com/rstudio/learnr/issues/141)).

## learnr 0.9.1

CRAN release: 2017-11-16

- Fixed a compatibility issue, so that existing tutorials don’t break
  when using Pandoc 2.0
  ([\#130](https://github.com/rstudio/learnr/issues/130)).

## learnr 0.9.0

@ commit
[\#14413cc](https://github.com/rstudio/learnr/commit/14413cc7ea20fa3b5938b29fab2b01282e6f0c1f)

## learnr 0.8.0

@ commit
[\#eeae534](https://github.com/rstudio/learnr/commit/eeae534fa792dcd369075a90b59b042ad26f945f)

## learnr 0.7.0

@ commit
[\#b71c637](https://github.com/rstudio/learnr/commit/b71c637cb0b1e0cb817e8e0c2fa56a4fcabd58dd)

## learnr 0.6.0

@ commit
[\#55c33cf](https://github.com/rstudio/learnr/commit/55c33cf616d3259c508ae234d301964c599a3039)

## learnr 0.5.0

@ commit
[\#a853163](https://github.com/rstudio/learnr/commit/a8531633f38c13333da6e1c76c6cb6c720e299dd)

## learnr 0.4.0

@ commit
[\#3339f8a](https://github.com/rstudio/learnr/commit/3339f8aaa2d0402622b1881aa42fcc78ea87db51)

## learnr 0.3.0

@ commit
[\#9cd0082](https://github.com/rstudio/learnr/commit/9cd00828bfa2429d88ad9efdbd51ad8475a6efb2)

## learnr 0.2.0

@ commit
[\#a81a694](https://github.com/rstudio/learnr/commit/a81a69498823d860f54c153128719e280de3d831)

## learnr 0.1.0

init commit!
[\#e2dbb20](https://github.com/rstudio/learnr/commit/e2dbb20d8fb7208cffcb339ea0fc5a8c9c45adb5)
