

- During render create a <div class="shiny-ui-output"> to hold the results of the Knit

- Create an input binding for the ace editor which collects up other related data (e.g. code in setup chunks)

- Create an action button which has the "Run" behavior

observeEvent(actionButton, {
  code <- input$code
  output$chunk-output <- run knitr and return HTML and dependencies
})

(can also consider calling Shiny.onInputChange if the above doesn't work out,
but we'd lose debouncing and other Shiny-level niceities)

Run the Knit in a contained environment (environment/process/jail/etc.). Will also need to ensure that images written by knitr end up addressable (probably should give each user their own temp directory where all chunk files go, managing uniqueness via knitr chunk labels)


