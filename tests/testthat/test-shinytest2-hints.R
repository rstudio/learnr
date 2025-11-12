# test_that()
skip_on_cran()
skip_on_ci_if_not_pr()

library(shinytest2)

check_popover_exists <- function(id) {
  selector_exists(exercise_selector_hint_popover(id))
}

check_popover_closed <- function(id) {
  selector_doesnt_exist(exercise_selector_hint_popover(id))
}

get_popover_editor_value <- function(id) {
  get_editor_value(exercise_selector_hint_popover(id), ".ace_editor")
}

it <- function(desc, code) {
  testthat:::test_code(desc, substitute(code), parent.frame())
}

describe("sequential hints", {
  app <- AppDriver$new(test_path("tutorials/hint-next"))
  withr::defer(app$stop())

  if (FALSE) {
    # for interactive viewing/debugging
    app$view()
  }

  describe("with one hint only", {
    id <- "one"

    it("shows hint when hint button is clicked", {
      app$wait_for_js(selector_exists(exercise_selector_hint_btn(id)))$click(
        selector = exercise_selector_hint_btn(id)
      )$wait_for_js(check_popover_exists(id))$expect("succeed")
    })

    it("doesn't have a next hint button", {
      app$wait_for_js(
        selector_doesnt_exist(
          exercise_selector_hint_popover(id),
          ".btn-tutorial-hint"
        )
      )$expect("succeed")
    })

    it("shows the correct hint in the editor", {
      app$expect("equal", get_js(get_popover_editor_value(id)), "# one hint")

      hint_text <- app$get_js(get_popover_editor_value(id))
      expect_equal(hint_text, "# one hint")
    })

    it("hides the popover when clicking on the hint button again", {
      app$wait_for_js(check_popover_exists(id))$click(
        selector = exercise_selector_hint_btn(id)
      )$wait_for_js(check_popover_closed(id))$expect("succeed")
    })
  })

  describe("with two hints", {
    id <- "two"

    it("shows hints when hint button is clicked", {
      app$wait_for_js(selector_exists(exercise_selector_hint_btn(id)))$click(
        selector = exercise_selector_hint_btn(id)
      )$wait_for_js(check_popover_exists(id))$expect("succeed")
    })

    next_hint_button <- paste(
      exercise_selector_hint_popover(id),
      ".btn-tutorial-next-hint"
    )

    it("has a next hint button", {
      app$wait_for_js(selector_exists(next_hint_button))$expect("succeed")
    })

    it("shows the first hint in the editor", {
      app$expect("equal", get_js(get_popover_editor_value(id)), "# first hint")
    })

    it("shows the next hint when clicking on the next hint button", {
      app$click(selector = next_hint_button)$expect(
        "equal",
        get_js(get_popover_editor_value(id)),
        "# second hint"
      )
    })

    it("disables the next hint button when the last hint is shown", {
      app$expect(
        "true",
        "disabled" %in% unlist(get_js(selector_classlist(next_hint_button)))
      )$expect(
        "true",
        get_js(selector_attributes(next_hint_button))$disabled %in%
          c("true", "disabled", "")
      )
    })

    it("doesn't do anything when disabled hint button is clicked", {
      app$click(selector = next_hint_button)$expect(
        "equal",
        get_js(get_popover_editor_value(id)),
        "# second hint"
      )
    })

    it("hides the hints when clicking on the hint button again", {
      app$wait_for_js(check_popover_exists(id))$click(
        selector = exercise_selector_hint_btn(id)
      )$wait_for_js(check_popover_closed(id))$expect("succeed")
    })
  })

  describe("with hints and solution", {
    id <- "three"

    it("shows hints when hint button is clicked", {
      app$wait_for_js(selector_exists(exercise_selector_hint_btn(id)))$click(
        selector = exercise_selector_hint_btn(id)
      )$wait_for_js(check_popover_exists(id))$expect("succeed")
    })

    next_hint_button <- paste(
      exercise_selector_hint_popover(id),
      ".btn-tutorial-next-hint"
    )

    it("has a next hint button", {
      app$wait_for_js(selector_exists(next_hint_button))$expect("succeed")
    })

    it("shows the first hint in the editor", {
      app$expect(
        "equal",
        get_js(get_popover_editor_value(id)),
        "# 3 - first hint"
      )
    })

    it("shows the next hint when clicking on the next hint button", {
      app$click(selector = next_hint_button)$wait_for_js(check_popover_exists(
        id
      ))$expect("succeed")$expect(
        "equal",
        get_js(get_popover_editor_value(id)),
        "# 3 - second hint"
      )
    })

    it("shows the solution after the last hint", {
      app$click(selector = next_hint_button)$wait_for_js(check_popover_exists(
        id
      ))$expect("succeed")$expect(
        "equal",
        get_js(get_popover_editor_value(id)),
        "2 + 2"
      )
    })

    it("adds disabled class and attribute when the next hint button is shown", {
      app$expect(
        "true",
        "disabled" %in% unlist(get_js(selector_classlist(next_hint_button)))
      )$expect(
        "true",
        get_js(selector_attributes(next_hint_button))$disabled %in%
          c("true", "disabled", "")
      )
    })

    it("doesn't do anything when disabled hint button is clicked", {
      app$click(selector = next_hint_button)$wait_for_js(check_popover_exists(
        id
      ))$expect("succeed")$expect(
        "equal",
        get_js(get_popover_editor_value(id)),
        "2 + 2"
      )
    })

    it("hides the hints when clicking on the hint button again", {
      app$wait_for_js(check_popover_exists(id))$click(
        selector = exercise_selector_hint_btn(id)
      )$wait_for_js(check_popover_closed(id))$expect("succeed")
    })
  })
})

describe("copy button", {
  app <- AppDriver$new(
    test_path("tutorials", "hint-copy"),
    variant = platform_variant()
  )
  withr::defer(app$stop())
  chrome <- app$get_chromote_session()

  if (FALSE) {
    app$view()
  }

  # Reset tutorial via "Start Over" button
  app$click(selector = ".resetButton")$wait_for_js(selector_exists(
    ".bootbox .bootbox-accept"
  ))$click(selector = ".bootbox .bootbox-accept")

  # Wait for page reload to complete
  chrome$Page$loadEventFired()

  # enable clipboard support
  # chrome$parent$debug_messages(TRUE)
  chrome$Browser$grantPermissions(list("clipboardReadWrite"))
  chrome$Emulation$setTouchEmulationEnabled(FALSE)
  chrome$Emulation$setEmitTouchEventsForMouse(FALSE)

  describe("copy hints", {
    id <- "ex1"
    hint_text_expected <- c(
      "c(\n  1,\n  2,\n  3\n)",
      "c(\r\n  1,\r\n  2,\r\n  3\r\n)"
    )

    it("clicks hint button to open hint popover", {
      app$wait_for_js(check_popover_closed(id), timeout = 5000)$click(
        selector = exercise_selector_hint_btn(id)
      )$wait_for_js(check_popover_exists(id))$expect(
        "succeed",
        "hint popover exists"
      )$wait_for_js(
        selector_exists(
          exercise_selector_hint_popover(id),
          ".btn-tutorial-copy-solution"
        )
      )$expect("succeed", "hint popover has copy solution button")$wait_for_js(
        selector_exists(exercise_selector_hint_popover(id), ".ace_editor")
      )$expect("succeed", "popover has editor with hint")
    })

    it("hint text in editor matches expectations", {
      app$expect(
        "true",
        get_js(get_popover_editor_value(id)) %in% hint_text_expected
      )
    })

    it("clicks copy solution button to copy hint and close popover", {
      copy_btn <- paste(
        exercise_selector_hint_popover(id),
        ".btn-tutorial-copy-solution"
      )

      app_real_click(app, copy_btn)$wait_for_js(check_popover_closed(
        id
      ))$expect(
        "true",
        get_js('navigator.clipboard.readText()') %in% hint_text_expected
      )
    })

    it("pastes the copied text into the editor", {
      app$wait_for_js(
        sprintf(
          "navigator.clipboard.readText()
            .then(text => ace.edit(document.querySelector('%s')).insert(text))
            .then(() => true)
          ",
          exercise_selector_editor(id)
        )
      )$expect(
        "true",
        trimws(app$get_js(get_editor_value(exercise_selector_editor(id)))) %in%
          hint_text_expected
      )
    })

    it("evaluates the pasted hint text correctly", {
      app$click(
        selector = exercise_selector_run_btn(id)
      )$wait_for_js(exercise_has_output(id))$expect(
        "equal",
        get_html(
          selector = paste(exercise_selector_output(id), "pre code"),
          outer_html = FALSE
        ),
        get_html(
          selector = "#section-ex1-expected-output pre code",
          outer_html = FALSE
        )
      )
    })
  })

  describe("copy solutions", {
    id <- "ex2"
    solution_text_expected <- c(
      'c(\r\n  "apple",\r\n  "banana",\r\n  "coconut"\r\n)',
      'c(\n  "apple",\n  "banana",\n  "coconut"\n)'
    )

    it("clicks hint button to open hint popover", {
      app$wait_for_js(check_popover_closed(id), timeout = 5000)$click(
        selector = exercise_selector_hint_btn(id)
      )$wait_for_js(check_popover_exists(id))$expect(
        "succeed",
        "hint popover exists"
      )$wait_for_js(
        selector_exists(
          exercise_selector_hint_popover(id),
          ".btn-tutorial-copy-solution"
        )
      )$expect("succeed", "hint popover has copy solution button")$wait_for_js(
        selector_exists(exercise_selector_hint_popover(id), ".ace_editor")
      )$expect("succeed", "popover has editor with hint")
    })

    it("hint text in editor matches expectations", {
      app$expect(
        "true",
        get_js(get_popover_editor_value(id)) %in% solution_text_expected
      )
    })

    it("clicks copy solution button to copy hint and close popover", {
      copy_btn <- paste(
        exercise_selector_hint_popover(id),
        ".btn-tutorial-copy-solution"
      )

      app_real_click(app, copy_btn)$wait_for_js(check_popover_closed(
        id
      ))$expect(
        "true",
        get_js('navigator.clipboard.readText()') %in% solution_text_expected
      )
    })

    it("pastes the copied text into the editor", {
      app$wait_for_js(
        sprintf(
          "navigator.clipboard.readText()
            .then(text => ace.edit(document.querySelector('%s')).insert(text))
            .then(() => true)
          ",
          exercise_selector_editor(id)
        )
      )$expect(
        "true",
        trimws(app$get_js(get_editor_value(exercise_selector_editor(id)))) %in%
          solution_text_expected
      )
    })

    it("evaluates the pasted hint text correctly", {
      app$click(
        selector = exercise_selector_run_btn(id)
      )$wait_for_js(exercise_has_output(id))$expect(
        "equal",
        get_html(
          selector = paste(exercise_selector_output(id), "pre code"),
          outer_html = FALSE
        ),
        get_html(
          selector = "#section-ex2-expected-output pre code",
          outer_html = FALSE
        )
      )
    })
  })
})

describe("div hints", {
  app <- AppDriver$new(
    test_path("tutorials", "hint-div"),
    variant = platform_variant()
  )
  withr::defer(app$stop())

  describe("exercise 'html'", {
    btn <- exercise_selector_hint_btn("html")
    div <- exercise_selector_hint_src_div("html")
    hint_panel <- exercise_selector_hint_panel("html")

    it("has a hint button", {
      app$wait_for_js(selector_exists(btn))
    })

    it("has a hidden hint div", {
      app$wait_for_js(selector_exists(div))$expect(
        "equal",
        get_js(selector_computed_style(div))$display,
        "none"
      )
    })

    it("reveals hint when hint button is clicked", {
      app$click(selector = btn)$wait_for_js(selector_exists(
        hint_panel,
        ".tutorial-hint"
      ))$expect(
        "equal",
        trimws(get_html(
          paste(hint_panel, ".tutorial-hint"),
          outer_html = FALSE
        )),
        "<p>This is the <strong>HTML hint</strong>.</p>"
      )
    })

    it("hides the hint when the button is clicked again", {
      app$click(selector = btn)$wait_for_js(selector_doesnt_exist(
        hint_panel,
        ".tutorial-hint"
      ))
    })
  })

  describe("exercise 'md'", {
    btn <- exercise_selector_hint_btn("md")
    div <- exercise_selector_hint_src_div("md")
    hint_panel <- exercise_selector_hint_panel("md")

    it("has a hint button", {
      app$wait_for_js(selector_exists(btn))
    })

    it("has a hidden hint div", {
      app$wait_for_js(selector_exists(div))$expect(
        "equal",
        get_js(selector_computed_style(div))$display,
        "none"
      )
    })

    it("reveals hint when hint button is clicked", {
      app$click(selector = btn)$wait_for_js(selector_exists(
        hint_panel,
        ".tutorial-hint"
      ))$expect(
        "equal",
        trimws(get_html(
          paste(hint_panel, ".tutorial-hint"),
          outer_html = FALSE
        )),
        "<p>This is the <strong>md hint</strong>.</p>"
      )
    })

    it("hides the hint when the button is clicked again", {
      app$click(selector = btn)$wait_for_js(selector_doesnt_exist(
        hint_panel,
        ".tutorial-hint"
      ))
    })
  })
})
