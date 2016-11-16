---
title: "Questions"
---

## Overview

You can include one or more multiple-choice quiz questions within a tutorial to help verify that readers understand the concepts presented. Questions can either have a single or multiple correct answers. 

Include a question by calling the `question` function within an R code chunk:

    ```{r letter-a, echo=FALSE}
    question("What number is the letter A in the English alphabet?",
      answer("8"),
      answer("14"),
      answer("1", correct = TRUE),
      answer("23")
    )
    ```
    
The above example defines a question with a single correct answer. You can also create questions that require multiple answers to be specified:

    ```{r where-am-i, echo=FALSE}
    question("Where are you right now? (select ALL that apply)",
      answer("Planet Earth", correct = TRUE),
      answer("Pluto"),
      answer("At a computing device", correct = TRUE),
      answer("In the Milky Way", correct = TRUE),
      incorrect = "Incorrect. You're on Earth, in the Milky Way, at a computer.")
    )
    ```

Note that for the examples above we specify the `echo = FALSE` option on the R code chunks that produce the questions. This is required to ensure that the R source code for the questions is not printed within the document.

This is what the above example quiz questions would look like within a tutorial:

<img src="images/questions.png" width=731 height=521>

## Custom Messages

You can add answer-specific correct/incorrect messages using the `message` option. For example:

    ```{r letter-a, echo=FALSE}
    question("What number is the letter A in the *English* alphabet?",
      answer("8"),
      answer("1", correct = TRUE),
      answer("2", message = "2 is close but it's the letter B rather than A."),
      answer("26")
    )
    ```

<img src="images/questions-message.png" width=730 height=254>

## Formatting and Math

You can use markdown to format text within questions, answers, and custom messages. You can also include embedded LaTeX math using the `$` delimiter. For example:

    ```{r math, echo=FALSE}
    x <- 42
    question(sprintf("Suppose $x = %s$. Choose the correct statement:", x),
      answer(sprintf("$\\sqrt{x} = %d$", x + 1)),
      answer(sprintf("$x ^ 2 = %d$", x^2), correct = TRUE),
      answer("$\\sin x = 1$")
    )
    ```

Note the use of a double-backslash (`\\`) as the prefix for LaTeX macros. This is necessary to "escape" the single-backslash so that R doesn't interpret it as a special character. Here's what this example would look like within a tutorial:

<img src="images/question-math.png" width=732 height=262>



## Random Answer Order

If you want the answers to questions to be randomly arranged, you can add the `random_answer_order` option. For example:

    ```{r letter-a, echo=FALSE}
    question("What number is the letter A in the English alphabet?",
      answer("8"),
      answer("14"),
      answer("1", correct = TRUE),
      answer("23"),
      random_answer_order = TRUE
    )
    ```


## Groups of Questions

You can present a group of related questions as a quiz by wrapping your questions within the `quiz` function. For example:

    ```{r quiz1, echo=FALSE}
    quiz(caption = "Quiz 1",
      question("What number is the letter A in the *English* alphabet?",
        answer("8"),
        answer("14"),
        answer("1", correct = TRUE),
        answer("23")
      ),
      question("Where are you right now? (select ALL that apply)",
        answer("Planet Earth", correct = TRUE),
        answer("Pluto"),
        answer("At a computing device", correct = TRUE),
        answer("In the Milky Way", correct = TRUE),
        incorrect = "Incorrect. You're on Earth, in the Milky Way, at a computer."
      )
    )
    ```

