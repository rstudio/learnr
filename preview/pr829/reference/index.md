# Package index

## learnr Tutorials

### Run a learnr Tutorial

- [`run_tutorial()`](https:/pkgs.rstudio.com/learnr/preview/pr829/reference/run_tutorial.md)
  : Run a tutorial
- [`available_tutorials()`](https:/pkgs.rstudio.com/learnr/preview/pr829/reference/available_tutorials.md)
  : List available tutorials
- [`safe()`](https:/pkgs.rstudio.com/learnr/preview/pr829/reference/safe.md)
  : Execute R code in a safe R environment

### Write or Configure a learnr Tutorial

- [`tutorial()`](https:/pkgs.rstudio.com/learnr/preview/pr829/reference/tutorial.md)
  : Tutorial document format
- [`tutorial_options()`](https:/pkgs.rstudio.com/learnr/preview/pr829/reference/tutorial_options.md)
  : Set tutorial options
- [`tutorial_package_dependencies()`](https:/pkgs.rstudio.com/learnr/preview/pr829/reference/tutorial_package_dependencies.md)
  : List tutorial dependencies

## Interactive Questions

- [`quiz()`](https:/pkgs.rstudio.com/learnr/preview/pr829/reference/quiz.md)
  [`question()`](https:/pkgs.rstudio.com/learnr/preview/pr829/reference/quiz.md)
  : Tutorial quiz questions
- [`question_checkbox()`](https:/pkgs.rstudio.com/learnr/preview/pr829/reference/question_checkbox.md)
  : Checkbox question
- [`question_radio()`](https:/pkgs.rstudio.com/learnr/preview/pr829/reference/question_radio.md)
  : Radio question
- [`question_numeric()`](https:/pkgs.rstudio.com/learnr/preview/pr829/reference/question_numeric.md)
  : Number question
- [`question_text()`](https:/pkgs.rstudio.com/learnr/preview/pr829/reference/question_text.md)
  : Text box question
- [`answer()`](https:/pkgs.rstudio.com/learnr/preview/pr829/reference/answer.md)
  [`answer_fn()`](https:/pkgs.rstudio.com/learnr/preview/pr829/reference/answer.md)
  : Question answer options
- [`correct()`](https:/pkgs.rstudio.com/learnr/preview/pr829/reference/mark_as_correct_incorrect.md)
  [`incorrect()`](https:/pkgs.rstudio.com/learnr/preview/pr829/reference/mark_as_correct_incorrect.md)
  [`mark_as()`](https:/pkgs.rstudio.com/learnr/preview/pr829/reference/mark_as_correct_incorrect.md)
  : Mark submission as correct or incorrect

## Random Praise and Encouragement

- [`random_praise()`](https:/pkgs.rstudio.com/learnr/preview/pr829/reference/random_praise.md)
  [`random_encouragement()`](https:/pkgs.rstudio.com/learnr/preview/pr829/reference/random_praise.md)
  : Random praise and encouragement
- [`random_phrases_add()`](https:/pkgs.rstudio.com/learnr/preview/pr829/reference/random_phrases_add.md)
  : Add phrases to the bank of random phrases

## Developer Tools

These functions were designed for use by developers who want to extend
learnr with custom formats or interactive question types, or for those
who wish to deploy learnr tutorials in custom environments.

### Questions

Functions intended for use by developers creating custom questions for
learnr.

- [`disable_all_tags()`](https:/pkgs.rstudio.com/learnr/preview/pr829/reference/disable_all_tags.md)
  : Disable all html tags
- [`finalize_question()`](https:/pkgs.rstudio.com/learnr/preview/pr829/reference/finalize_question.md)
  : Finalize a question
- [`question_ui_initialize()`](https:/pkgs.rstudio.com/learnr/preview/pr829/reference/question_methods.md)
  [`question_ui_try_again()`](https:/pkgs.rstudio.com/learnr/preview/pr829/reference/question_methods.md)
  [`question_ui_completed()`](https:/pkgs.rstudio.com/learnr/preview/pr829/reference/question_methods.md)
  [`question_is_valid()`](https:/pkgs.rstudio.com/learnr/preview/pr829/reference/question_methods.md)
  [`question_is_correct()`](https:/pkgs.rstudio.com/learnr/preview/pr829/reference/question_methods.md)
  : Custom question methods
- [`knit_print(`*`<tutorial_question>`*`)`](https:/pkgs.rstudio.com/learnr/preview/pr829/reference/knit_print.md)
  [`knit_print(`*`<tutorial_quiz>`*`)`](https:/pkgs.rstudio.com/learnr/preview/pr829/reference/knit_print.md)
  : Knitr quiz print methods
- [`format(`*`<tutorial_question_answer>`*`)`](https:/pkgs.rstudio.com/learnr/preview/pr829/reference/format_quiz.md)
  [`format(`*`<tutorial_question>`*`)`](https:/pkgs.rstudio.com/learnr/preview/pr829/reference/format_quiz.md)
  [`format(`*`<tutorial_quiz>`*`)`](https:/pkgs.rstudio.com/learnr/preview/pr829/reference/format_quiz.md)
  [`print(`*`<tutorial_question>`*`)`](https:/pkgs.rstudio.com/learnr/preview/pr829/reference/format_quiz.md)
  [`print(`*`<tutorial_question_answer>`*`)`](https:/pkgs.rstudio.com/learnr/preview/pr829/reference/format_quiz.md)
  [`print(`*`<tutorial_quiz>`*`)`](https:/pkgs.rstudio.com/learnr/preview/pr829/reference/format_quiz.md)
  : Formatting and printing quizzes, questions, and answers

### State and Events

- [`get_tutorial_info()`](https:/pkgs.rstudio.com/learnr/preview/pr829/reference/get_tutorial_info.md)
  : Get information about the current tutorial
- [`get_tutorial_state()`](https:/pkgs.rstudio.com/learnr/preview/pr829/reference/get_tutorial_state.md)
  : Observe the user's progress in the tutorial
- [`filesystem_storage()`](https:/pkgs.rstudio.com/learnr/preview/pr829/reference/filesystem_storage.md)
  : Filesystem-based storage for tutor state data
- [`event_register_handler()`](https:/pkgs.rstudio.com/learnr/preview/pr829/reference/event_register_handler.md)
  : Register an event handler callback
- [`one_time()`](https:/pkgs.rstudio.com/learnr/preview/pr829/reference/one_time.md)
  : Wrap an expression that will be executed one time in an event
  handler

### General Tools

- [`duplicate_env()`](https:/pkgs.rstudio.com/learnr/preview/pr829/reference/duplicate_env.md)
  : Create a duplicate of an environment
- [`initialize_tutorial()`](https:/pkgs.rstudio.com/learnr/preview/pr829/reference/initialize_tutorial.md)
  : Initialize tutorial R Markdown extensions
- [`external_evaluator()`](https:/pkgs.rstudio.com/learnr/preview/pr829/reference/external_evaluator.md)
  : External execution evaluator
- [`tutorial_html_dependency()`](https:/pkgs.rstudio.com/learnr/preview/pr829/reference/tutorial_html_dependency.md)
  : Tutorial HTML dependency
