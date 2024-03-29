% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/question_methods.R
\name{question_ui_initialize}
\alias{question_ui_initialize}
\alias{question_ui_try_again}
\alias{question_ui_completed}
\alias{question_is_valid}
\alias{question_is_correct}
\alias{question_ui_initialize.default}
\alias{question_ui_try_again.default}
\alias{question_ui_completed.default}
\alias{question_is_valid.default}
\alias{question_is_correct.default}
\title{Custom question methods}
\usage{
question_ui_initialize(question, value, ...)

question_ui_try_again(question, value, ...)

question_ui_completed(question, value, ...)

question_is_valid(question, value, ...)

question_is_correct(question, value, ...)

\method{question_ui_initialize}{default}(question, value, ...)

\method{question_ui_try_again}{default}(question, value, ...)

\method{question_ui_completed}{default}(question, value, ...)

\method{question_is_valid}{default}(question, value, ...)

\method{question_is_correct}{default}(question, value, ...)
}
\arguments{
\item{question}{\link{question} object used}

\item{value}{user input value}

\item{...}{future parameter expansion and custom arguments to be used in dispatched s3 methods.}
}
\value{
learnr question objects, UI elements, results or server methods.
}
\description{
There are five methods used to define a custom question.  Each S3 method
should correspond to the \code{type = TYPE} supplied to the question.
\itemize{
\item \code{question_ui_initialize.TYPE(question, value, ...)}
\itemize{
\item Determines how the question is initially displayed to the users. This should return a shiny UI object that can be displayed using \link[shiny:renderUI]{shiny::renderUI}. For example, in the case of \code{question_ui_initialize.radio}, it returns a \link[shiny:radioButtons]{shiny::radioButtons} object. This method will be re-executed if the question is attempted again.
}
\item \code{question_ui_completed.TYPE(question, ...)}
\itemize{
\item Determines how the question is displayed after a submission.  Just like \code{question_ui_initialize}, this method should return an shiny UI object that can be displayed using \link[shiny:renderUI]{shiny::renderUI}.
}
\item \code{question_is_valid.TYPE(question, value, ...)}
\itemize{
\item This method should return a boolean that determines if the input answer is valid.  Depending on the value, this function enables and disables the submission button.
}
\item \code{question_is_correct.TYPE(question, value, ...)}
\itemize{
\item This function should return the output of \link{correct}, \link{incorrect}, or \link{mark_as}. Each method allows for custom messages in addition to the determination of an answer being correct.  See \link{correct}, \link{incorrect}, or \link{mark_as} for more details.
}
\item \verb{question_ui_try_again <- function(question, value, ...)}
\itemize{
\item Determines how the question is displayed to the users while  the "Try again" screen is displayed.  Usually this function will disable inputs to the question, i.e. prevent the student from changing the answer options. Similar to \code{question_ui_initialize}, this should should return a shiny UI object that can be displayed using \link[shiny:renderUI]{shiny::renderUI}.
}
}
}
\examples{
q <- question(
  "Which package helps you teach programming skills?",
  answer("dplyr"),
  answer("learnr", correct = TRUE),
  answer("base")
)
question_is_correct(q, "dplyr")
question_is_correct(q, "learnr")

}
\seealso{
For more information and question type extension examples, please
see the \strong{Custom Question Types} section of the \code{quiz_question} tutorial:
\code{learnr::run_tutorial("quiz_question", "learnr")}.
}
