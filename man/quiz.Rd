% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/quiz.R
\name{quiz}
\alias{quiz}
\alias{question}
\title{Tutorial quiz questions}
\usage{
quiz(..., caption = rlang::missing_arg())

question(
  text,
  ...,
  type = c("auto", "single", "multiple", "learnr_radio", "learnr_checkbox",
    "learnr_text", "learnr_numeric"),
  correct = "Correct!",
  incorrect = "Incorrect",
  try_again = NULL,
  message = NULL,
  post_message = NULL,
  loading = NULL,
  submit_button = rlang::missing_arg(),
  try_again_button = rlang::missing_arg(),
  allow_retry = FALSE,
  random_answer_order = FALSE,
  options = list()
)
}
\arguments{
\item{...}{One or more questions or answers}

\item{caption}{Optional quiz caption (defaults to "Quiz")}

\item{text}{Question or option text}

\item{type}{Type of quiz question. Typically this can be automatically
determined based on the provided answers. Pass \code{"radio"} to indicate that
even though multiple correct answers are specified that inputs which
include only one correct answer are still correct. Pass \code{"checkbox"} to
force the use of checkboxes (as opposed to radio buttons) even though only
one correct answer was provided.}

\item{correct}{For \code{question}, text to print for a correct answer (defaults
to "Correct!"). For \code{answer}, a boolean indicating whether this answer is
correct.}

\item{incorrect}{Text to print for an incorrect answer (defaults to
"Incorrect") when \code{allow_retry} is \code{FALSE}.}

\item{try_again}{Text to print for an incorrect answer when \code{allow_retry}
is \code{TRUE}.
Defaults to "Incorrect. Be sure to select every correct answer." for
checkbox questions and "Incorrect" for non-checkbox questions.}

\item{message}{Additional message to display along with correct/incorrect
feedback. This message is always displayed after a question submission.}

\item{post_message}{Additional message to display along with
correct/incorrect feedback. If \code{allow_retry} is \code{TRUE}, this
message will only be displayed after the correct submission.  If
\code{allow_retry} is \code{FALSE}, it will produce a second message
alongside the \code{message} message value.}

\item{loading}{Loading text to display as a placeholder while the question is
loaded. If not provided, generic "Loading..." or placeholder elements will
be displayed.}

\item{submit_button}{Label for the submit button. Defaults to \code{"Submit Answer"}}

\item{try_again_button}{Label for the try again button. Defaults to \code{"Submit Answer"}}

\item{allow_retry}{Allow retry for incorrect answers. Defaults to \code{FALSE}.}

\item{random_answer_order}{Display answers in a random order.}

\item{options}{Extra options to be stored in the question object. This is
useful when using custom question types. See \code{\link[sortable:question_rank]{sortable::question_rank()}}
for an example question implementation that uses the \code{options} parameter.}
}
\value{
A learnr quiz, or collection of questions.
}
\description{
Add interactive quiz questions to a tutorial. Each quiz question is executed
within a shiny runtime to provide more flexibility in the types of questions
offered. There are four default types of quiz questions:

\describe{
\item{\code{learnr_radio}}{Radio button question.  This question type will
only allow for a single answer submission by the user.  An answer must be
marked for the user to submit their answer.}
\item{\code{learnr_checkbox}}{Check box question.  This question type will
allow for one or more answers to be submitted by the user.  At least one
answer must be marked for the user to submit their answer.}
\item{\code{learnr_text}}{Text box question.  This question type will allow
for free form text to be submitted by the user.  At least one non-whitespace
character must be added for the user to submit their answer.}
\item{\code{learnr_numeric}}{Numeric question.  This question type will allow
for a number to be submitted by the user.  At least one number must be added
for the user to submit their answer.}
}

Note, the print behavior has changed as the runtime is now Shiny based.  If
\code{question}s and \code{quiz}es are printed in the console, the S3
structure and information will be displayed.
}
\examples{
quiz(
  question("What number is the letter A in the alphabet?",
    answer("8"),
    answer("14"),
    answer("1", correct = TRUE),
    answer("23"),
    incorrect = "See [here](https://en.wikipedia.org/wiki/English_alphabet) and try again.",
    allow_retry = TRUE
  ),

  question("Where are you right now? (select ALL that apply)",
    answer("Planet Earth", correct = TRUE),
    answer("Pluto"),
    answer("At a computing device", correct = TRUE),
    answer("In the Milky Way", correct = TRUE),
    incorrect = paste0("Incorrect. You're on Earth, ",
                       "in the Milky Way, at a computer.")
  )
)

}
\seealso{
\code{\link[=random_praise]{random_praise()}}, \code{\link[=random_encouragement]{random_encouragement()}}

For more information and question type extension examples, please
see the help documentation for \link[=question_ui_initialize]{question_methods}
and view the \code{question_type} tutorial:
\code{learnr::run_tutorial("question_type", "learnr")}.

Other Interactive Questions: 
\code{\link{question_checkbox}()},
\code{\link{question_numeric}()},
\code{\link{question_radio}()},
\code{\link{question_text}()}
}
\concept{Interactive Questions}
