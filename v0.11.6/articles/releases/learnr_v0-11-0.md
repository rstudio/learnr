# learnr v0.11.0

## Intro

We are happy to announce that version `0.11.0` of learnr has arrived at
a CRAN mirror near you. This release collects many large and small
improvements to the learnr package, all with the goal of making it
easier to create interactive tutorials for teaching programming concepts
and skills.

Read on for an overview of the changes in version `0.11.0`, or review
the
[changelog](https:/pkgs.rstudio.com/learnr/v0.11.6/news/index.html#learnr-0110)
for a full list of updates. Use
[`install.packages()`](https://rdrr.io/r/utils/install.packages.html) to
install the latest version of learnr, which includes demonstrations of
many of the new features.

``` r
install.packages("learnr")
```

## learnr speaks more than R

learnr tutorials are a great way to teach others R: it’s in the package
name, after all. And thanks to R Markdown’s flexibility, learnr is a
great way to teach other programming languages as well, using the spoken
language of your choice!

### Internationalization

learnr now allows tutorial authors to choose the words or language used
for learnr’s UI elements using the `language` argument of the `tutorial`
format. We are very grateful for the contributions of a number of
community members to allow learnr to include out-of-the-box support for
the following languages:

- Basque (eu) language support was contributed by [Mikel
  Madina](https://github.com/mikelmadina)
  ([\#489](https://github.com/rstudio/learnr/issues/489))
- Portuguese (pt) language support was contributed by [Beatriz
  Milz](https://github.com/beatrizmilz)
  ([\#488](https://github.com/rstudio/learnr/issues/488),
  [\#551](https://github.com/rstudio/learnr/issues/551))
- Spanish (es) language support was contributed by [Yanina Bellini
  Saibene](https://github.com/yabellini)
  ([\#483](https://github.com/rstudio/learnr/issues/483),
  [\#546](https://github.com/rstudio/learnr/issues/546))
- Turkish (tr) language support was contributed by [Hulya
  Yigit](https://github.com/hyigit2) and [James J
  Balamuta](https://github.com/coatless) (
  [\#493](https://github.com/rstudio/learnr/issues/493),
  [\#554](https://github.com/rstudio/learnr/issues/554))
- German (de) language support was contributed by
  [@NinaCorrelAid](https://github.com/NinaCorrelAid)
  ([\#611](https://github.com/rstudio/learnr/issues/611),
  [\#612](https://github.com/rstudio/learnr/issues/612))
- Korean (ko) language support was contributed by [Choonghyun
  Ryu](https://github.com/choonghyunryu)
  ([\#634](https://github.com/rstudio/learnr/issues/634))
- Chinese (zh) language support was contributed by
  [@shalom-lab](https://github.com/shalom-lab)
  ([\#681](https://github.com/rstudio/learnr/issues/681))
- Polish (pl) language support was contributed by [Jakub
  Jędrusiak](https://github.com/kuba58426)
  ([\#686](https://github.com/rstudio/learnr/issues/686))

You can choose one of the above via the `language` setting in your
tutorial’s YAML frontmatter:

    ---
    output:
      learnr::tutorial:
        language: es
    runtime: shinyrmd
    ---

The language chosen for the tutorial is passed to the R session used to
evaluate exercise code, so that translatable messages from R will also
be presented in the specified language (thanks [Alex Rossell
Hayes](https://github.com/rossellhayes)).

In addition, you can customize the words displayed on specific UI
elements using a named list. For example, the default text used on the
“Run Code” button in Spanish is *Ejecutar código*. You can use the
Spanish language translation and modify this particular translation
using a named list:

    ---
    output:
      learnr::tutorial:
        language: 
          es:
            button:
              runcode: Ejecutar
    runtime: shinyrmd
    ---

You can learn more about internationalization features and the full
syntax for customizing the language used by learnr in the
[internationalization
vignette](https:/pkgs.rstudio.com/learnr/v0.11.6/articles/multilang.md).

*We would love to support **more** languages and would happily [welcome
your
contribution](https:/pkgs.rstudio.com/learnr/v0.11.6/articles/multilang.html#complete-translations).*

### Support for additional programming languages

In addition to spoken languages, learnr is now better at running code in
programming languages other than R. The biggest improvement is for SQL
exercises, where learners can execute SQL queries on a database. This
was previously possible, but now tutorial authors can use grading
packages like [gradethis](https://pkgs.rstudio.com/gradethis) to grade
the tables returned by the student’s queries. You can see this in action
using `run_tutorial("sql-exercise", "learnr")` ([SQL demo online
version](https://learnr-examples.shinyapps.io/sql-exercise)).

learnr also includes UI improvements in the interactive exercise
component for other languages, including syntax highlighting and basic
auto-completion for exercise code in languages such as Python,
JavaScript, Julia and SQL. Try `run_tutorial("polyglot", "learnr")`
([polyglot online
version](https://learnr-examples.shinyapps.io/polyglot/)) to see several
programming languages in use in the same tutorial.

![One R and one Python interactive exercise component, with the same
source code but which evaluates differently in each language. The code
is: x = 5 x \<- 10 print(x)](images/r-python-exercise.png)

For exercise checking, learnr communicates the exercise engine to
exercise-checking functions via a new `engine` argument that should be
included in the exercise checker function signature.

## Exercises

Beyond expanded language support, interactive exercises and questions in
learnr tutorials have received a number of updates and improvements.

### Setup chunk chaining

Thanks to [Nischal Shrestha](https://github.com/nischalshrestha),
exercises can now be chained together via chained setup chunks such that
the setup of one exercise may depend on other exercises[¹](#fn1),
including the setup chunks of other exercises in the tutorial. This
makes it easier for the author to progressively work through a problem
with a series of interactive exercises that build on each other.

An exercise chunk — an R chunk with `exercise = TRUE` — can specify its
setup chunk using the `{label}-chunk` naming convention or with the
`exercise.setup` chunk option. Any chunk being used as a setup chunk may
also include an `execise.setup` option specifying its own parent chunk.

Try `run_tutorial("setup-chunks", "learnr")` ([setup-chunks online
version](https://learnr-examples.shinyapps.io/setup-chunks/)) to see
chained setup chunks in action.

### Catching common code issues

When teaching new programming concepts, it can be helpful to provide
learners with some scaffolding in an exercise to focus their attention
on skills they just recently learned.

For example, if you are explaining the difference between the
`names_from` and `values_from` arguments in `tidyr::pivot_wider()`, you
might want to ask students to practice using the arguments without
distracting them with writing code to set up a transformation. It’s
common to use underscores or other patterns to indicate that students
should fill in a missing piece.

``` r
library(tidyverse)

us_rent_income %>% 
  select(name = NAME, variable, estimate) %>%
  pivot_wider(names_from = ____, values_from = ____)
```

If students submit code containing blanks, learnr will warn the student
that they should replace the `____` with valid code.

![A learnr exercise box with the feedback from submitting the code
above. A red callout says "This exercise contains 2 blanks. Please
replace \_\_\_\_ with valid code."](images/blanks-warning.png)

Blanks are detected using regular expressions (since blanks may make the
code unparsable), and learnr’s default pattern is to detect three or
more consecutive underscores. Authors can choose the pattern for
detecting blanks with the `exercise.blanks` chunk option. Setting
`exercise.blanks = "[.]{2}[a-z]+[.]{2}"`, for example, would allow the
author to use valid R syntax for blanks. The warning message shown to
students calls out the blanks they need to fill in.

![A learnr exercise box with the feedback from submitting the example
code with a custom exercise.blanks pattern. A red callout says "This
exercise contains 2 blanks. Please replace '..names..' and '..values..'
with valid code."](images/blanks-warning-custom.png)

Another common problem in code involves character conversions when a
student copies code from an application with automatic formatting and
pastes the text into a learnr tutorial. We frequently see problems with
quotation marks in code samples being converted to Unicode-formatted
quotation marks (curly quotes). In general, these kinds of conversions
make the R code unparsable. Now learnr will detect these mistakes and
suggest a replacement.

![A learnr exercise box where the student's code contains curly quotes.
The feedback message reads It looks like your R code contains specially
formatted quotation marks or "curly" quotes (“) around character
strings, making your code invalid. R requires character values to be
contained in straight quotation marks (" or '). 1: c(“hello”, “world”)
Don't worry, this is a common source of errors when you copy code from
another app that applies its own formatting to text. You can try
replacing the code on that line with the following. There may be other
places that need to be fixed, too. c("hello", "world")
](images/fancy-quotes-warning.png)

Finally, if the learner submits code that isn’t parsable – and not for
any of the above reasons – learnr now returns a generic, but helpful,
feedback message with guidance about common syntax errors.

![A learnr exercise box where the student's code contains invalid R
code. The feedback message reads: It looks like this might not be valid
R code. R cannot determine how to turn your text into a complete
command. You may have forgotten to fill in a blank, to remove an
underscore, to include a comma between arguments, or to close an opening
", ', ( or { with a matching ", ', ) or }.](images/syntax-warning.png)

In all of the above cases, the actual R output, often an error message,
is always shown to the learner. This helps students acclimate to the
error messages they would see in their console if encountered in their
every-day usage of R.

### Improved keyboard support

Keyboard navigation and shortcuts for the interactive exercise code
editor has been improved. Previously, the editor would trap keyboard
focus because the Tab key is used for indentation in the editor. Now,
users can press Escape when the editor has focus to temporarily disable
using Tab for indentation, making it possible to move to the next or
previous element in the tutorial.

![](images/exercise-tab-example.gif)

A demonstration of navigating through an exercise editor. At the start
of the animation, the editor has focus and '2 + 2' is typed into the
editor. Then the user presses the Esc key and a dark outline is applied
to the editor container. Pressing Shift and Tab moves to the previous
element, the 'Run Code' button in the exercise toolbar. Then the user
uses Tab to move back into the editor and again presses Esc to disable
indentation, followed by Tab to move out of the editor to the next
focusable element in the page.

The exercise editor also supports a few additional keyboard shortcuts:

- The (magrittr) pipe `%>%` with Cmd / Ctrl + Shift + M

- The assignment arrow, `<-` with Opt / Alt + -

- Cmd / Ctrl + Enter runs the selected code

### The `data` directory

When users submit code as part of an exercise, learnr evaluates their
code in a temporary directory that’s used just for the evaluation of
their submission. This helps ensure that every submission returns the
same value, but it makes it harder for authors to write exercises that
use files, such as `.csv` or other files, as inputs for the user’s code.

To remedy this, thanks to work by [Alex Rossell
Hayes](https://github.com/rossellhayes), learnr now treats a `data/`
directory, stored adjacent to the tutorial, as special. Authors can
reference files in the `data/` directory in the static content of
tutorials, and the files are also made available for student use in the
exercises. Each exercise evaluation copies the directory into the
exercise’s temporary directory so that subsequent submissions work even
if the student accidentally overwrites or deletes the files. In all
cases, files in `data/` can be referenced using the same relative path,
e.g. `"data/estimates.csv"`.

### Error checking

It is now possible to provide customized feedback when a learner’s
exercise submission produces an evaluation error. The
`exercise.error.checker` option of
[`tutorial_options()`](https:/pkgs.rstudio.com/learnr/v0.11.6/reference/tutorial_options.md)
allows authors to define an error-checking function that is applied when
an error is thrown by a user’s code. You may also use
`exercise.error.check.code` to define the default error checking code
that would normally be written in an `-error-check` chunk.

An excellent default error checker is
`gradethis::gradethis_error_checker()`, which is enabled by default if
[gradethis](https://pkgs.rstudio.com/gradethis) is loaded in a learnr
tutorial. The gradethis error checker automatically provides the student
with a hint when an error is encountered, by comparing the submitted
code with the expected solution.

![A learnr exercise box where the student's code results in an error.
The submitted code is 'runif(max = 10)' and the feedback message reads
Your call to 'runif()' should include "n" as one of its arguments. You
may have misspelled an argument name, or left out an important argument.
That's okay: you learn more from mistakes than successes. Let's do it
one more time.](images/error-checker.png)

## Questions

This release of learnr includes a new question type,
[`question_numeric()`](https:/pkgs.rstudio.com/learnr/v0.11.6/reference/question_numeric.md).
The numeric question type is a complement to
[`question_text()`](https:/pkgs.rstudio.com/learnr/v0.11.6/reference/question_text.md)
when a numeric answer is required.

![A learnr question input asking "What is pi rounded to 2 digits?"
followed by an input box with the text
"3.14"](images/question-numeric.png)

In general, question answers are specified with the
[`answer()`](https:/pkgs.rstudio.com/learnr/v0.11.6/reference/answer.md)
function, but these answers can only be a single value, which has
limited applicability in text and numeric questions.

Now, authors can use
[`answer_fn()`](https:/pkgs.rstudio.com/learnr/v0.11.6/reference/answer.md)
to provide a single-argument function that takes the student’s submitted
answer and determines if their submission is correct. This allows
authors to check a range of values or answers at once.

## Thanks

We are hugely thankful for the 101 community members who have
contributed pull requests, submitted translations, or reported issues
since our last release. There are many more contributions and updates to
this version of learnr that aren’t covered in this post; be sure to
check out [the full list of
changes](https:/pkgs.rstudio.com/learnr/v0.11.6/news/index.html#learnr-0110).

Thank you also to the previous maintainer of learnr, [Barrett
Schloerke](https://github.com/schloerke)! (learnr is now maintained by
me, [Garrick Aden-Buie](https://github.com/gadenbuie).)

🙏 Big thank you to all of our contributors:

[@acarzfr](https://github.com/acarzfr),
[@acastleman](https://github.com/acastleman),
[@adisarid](https://github.com/adisarid),
[@agmath](https://github.com/agmath),
[@AlbertLeeUCSF](https://github.com/AlbertLeeUCSF),
[@andysouth](https://github.com/andysouth),
[@annafergusson](https://github.com/annafergusson),
[@assignUser](https://github.com/assignUser),
[@batpigandme](https://github.com/batpigandme),
[@bbitarello](https://github.com/bbitarello),
[@beatrizmilz](https://github.com/beatrizmilz),
[@bhogan-mitre](https://github.com/bhogan-mitre),
[@bjornerstedt](https://github.com/bjornerstedt),
[@blaiseli](https://github.com/blaiseli),
[@Brunox13](https://github.com/Brunox13),
[@C4caesar](https://github.com/C4caesar),
[@caievelyn](https://github.com/caievelyn),
[@cderv](https://github.com/cderv),
[@chendaniely](https://github.com/chendaniely),
[@choonghyunryu](https://github.com/choonghyunryu),
[@chrisaberson](https://github.com/chrisaberson),
[@coatless](https://github.com/coatless),
[@ColinFay](https://github.com/ColinFay),
[@cpsievert](https://github.com/cpsievert),
[@cswclui](https://github.com/cswclui),
[@czucca](https://github.com/czucca),
[@davidkane9](https://github.com/davidkane9),
[@dcossyleon](https://github.com/dcossyleon),
[@ddauber](https://github.com/ddauber),
[@deepanshu88](https://github.com/deepanshu88),
[@dfailing](https://github.com/dfailing),
[@dmenne](https://github.com/dmenne),
[@dputhier](https://github.com/dputhier),
[@DrAtzi](https://github.com/DrAtzi),
[@drmowinckels](https://github.com/drmowinckels),
[@dtkaplan](https://github.com/dtkaplan),
[@elimillera](https://github.com/elimillera),
[@elmstedt](https://github.com/elmstedt),
[@emarsh25](https://github.com/emarsh25),
[@enoches](https://github.com/enoches),
[@ericemc3](https://github.com/ericemc3),
[@ethelpruss](https://github.com/ethelpruss),
[@gadenbuie](https://github.com/gadenbuie),
[@gaelso](https://github.com/gaelso),
[@garrettgman](https://github.com/garrettgman),
[@gdkrmr](https://github.com/gdkrmr),
[@gtritchie](https://github.com/gtritchie),
[@gvwilson](https://github.com/gvwilson),
[@helix84](https://github.com/helix84),
[@hyigit2](https://github.com/hyigit2),
[@ijlyttle](https://github.com/ijlyttle),
[@indenkun](https://github.com/indenkun),
[@jakub-jedrusiak](https://github.com/jakub-jedrusiak),
[@jcheng5](https://github.com/jcheng5),
[@jennybc](https://github.com/jennybc),
[@jhk0530](https://github.com/jhk0530),
[@joe-chelladurai](https://github.com/joe-chelladurai),
[@johnbde](https://github.com/johnbde),
[@jooyoungseo](https://github.com/jooyoungseo),
[@jtelleriar](https://github.com/jtelleriar),
[@jtransue](https://github.com/jtransue),
[@kaisamng](https://github.com/kaisamng),
[@KatherineCox](https://github.com/KatherineCox),
[@kendavidn](https://github.com/kendavidn),
[@kevinushey](https://github.com/kevinushey),
[@lorenzwalthert](https://github.com/lorenzwalthert),
[@ltl-manabi](https://github.com/ltl-manabi),
[@MAGALLANESJoseManuel](https://github.com/MAGALLANESJoseManuel),
[@MaralDorri](https://github.com/MaralDorri),
[@markwsac](https://github.com/markwsac),
[@MayaGans](https://github.com/MayaGans),
[@meatballhat](https://github.com/meatballhat),
[@mikelmadina](https://github.com/mikelmadina),
[@mine-cetinkaya-rundel](https://github.com/mine-cetinkaya-rundel),
[@mpjashby](https://github.com/mpjashby),
[@mstackhouse](https://github.com/mstackhouse),
[@mutlusun](https://github.com/mutlusun),
[@NinaCorrelAid](https://github.com/NinaCorrelAid),
[@nischalshrestha](https://github.com/nischalshrestha),
[@NuoWenLei](https://github.com/NuoWenLei),
[@petzi53](https://github.com/petzi53),
[@plukethep](https://github.com/plukethep),
[@profandyfield](https://github.com/profandyfield),
[@psads-git](https://github.com/psads-git),
[@pseudorational](https://github.com/pseudorational),
[@RaymondBalise](https://github.com/RaymondBalise),
[@rossellhayes](https://github.com/rossellhayes),
[@rundel](https://github.com/rundel),
[@schloerke](https://github.com/schloerke),
[@shalom-lab](https://github.com/shalom-lab),
[@shalutiwari](https://github.com/shalutiwari),
[@siebrenf](https://github.com/siebrenf),
[@SilasK](https://github.com/SilasK),
[@stragu](https://github.com/stragu),
[@themfrees](https://github.com/themfrees),
[@tombeesley](https://github.com/tombeesley),
[@trestletech](https://github.com/trestletech),
[@tvedebrink](https://github.com/tvedebrink),
[@vnijs](https://github.com/vnijs), [@wch](https://github.com/wch), and
[@yabellini](https://github.com/yabellini).

------------------------------------------------------------------------

1.  Note that with chained setup chunks, an exercise only ever uses the
    code as written in the chunks in the source document. Exercises are
    still completely independent of each other when viewed by a user.
