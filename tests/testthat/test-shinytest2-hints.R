skip_on_cran()
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
  app <- AppDriver$new(test_path("tutorials/next-hint"))
  withr::defer(app$stop())

  if (FALSE) {
    # for interactive viewing/debugging
    app$view()
  }

  describe("with one hint only", {
    id <- "one"

    it("shows hint when hint button is clicked", {
      app$
        wait_for_js(selector_exists(exercise_selector_hint_btn(id)))$
        click(selector = exercise_selector_hint_btn(id))$
        wait_for_js(check_popover_exists(id))$
        succeed()
    })

    it("doesn't have a next hint button", {
      app$
        wait_for_js(
          selector_doesnt_exist(
            exercise_selector_hint_popover(id),
            ".btn-tutorial-hint"
          )
        )$
        succeed()
    })

    it("shows the correct hint in the editor", {
      expect_equal(
        app$get_js(get_popover_editor_value(id)),
        "# one hint"
      )
    })

    it("hides the popover when clicking on the hint button again", {
      app$
        wait_for_js(check_popover_exists(id))$
        click(selector = exercise_selector_hint_btn(id))$
        wait_for_js(check_popover_closed(id))$
        succeed()
    })
  })

  describe("with two hints", {
    id <- "two"

    it("shows hints when hint button is clicked", {
      app$
        wait_for_js(selector_exists(exercise_selector_hint_btn(id)))$
        click(selector = exercise_selector_hint_btn(id))$
        wait_for_js(check_popover_exists(id))$
        succeed()
    })

    next_hint_button <- paste(
      exercise_selector_hint_popover(id),
      ".btn-tutorial-next-hint"
    )

    it("has a next hint button", {
      app$
        wait_for_js(selector_exists(next_hint_button))$
        succeed()
    })

    it("shows the first hint in the editor", {
      expect_equal(
        app$get_js(get_popover_editor_value(id)),
        "# first hint"
      )
    })

    it("shows the next hint when clicking on the next hint button", {
      app$click(selector = next_hint_button)
      expect_equal(
        app$get_js(get_popover_editor_value(id)),
        "# second hint"
      )
    })

    it("disables the next hint button when the last hint is shown", {
      next_hint_btn_classes <- unlist(
        app$get_js(selector_classlist(next_hint_button))
      )

      expect_true("disabled" %in% next_hint_btn_classes)
      expect_true(
        app$get_js(selector_attributes(next_hint_button))$disabled %in%
        c("true", "disabled", "")
      )
    })

    it("doesn't do anything when disabled hint button is clicked", {
      app$click(selector = next_hint_button)
      expect_equal(
        app$get_js(get_popover_editor_value(id)),
        "# second hint"
      )
    })

    it("hides the hints when clicking on the hint button again", {
      app$
        wait_for_js(check_popover_exists(id))$
        click(selector = exercise_selector_hint_btn(id))$
        wait_for_js(check_popover_closed(id))
    })
  })

  describe("with hints and solution", {
    id <- "three"

    it("shows hints when hint button is clicked", {
      app$
        wait_for_js(selector_exists(exercise_selector_hint_btn(id)))$
        click(selector = exercise_selector_hint_btn(id))$
        wait_for_js(check_popover_exists(id))$
        succeed()
    })

    next_hint_button <- paste(
      exercise_selector_hint_popover(id),
      ".btn-tutorial-next-hint"
    )

    it("has a next hint button", {
      app$
        wait_for_js(selector_exists(next_hint_button))$
        succeed()
    })

    it("shows the first hint in the editor", {
      expect_equal(
        app$get_js(get_popover_editor_value(id)),
        "# 3 - first hint"
      )
    })

    it("shows the next hint when clicking on the next hint button", {
      app$
        click(selector = next_hint_button)$
        wait_for_js(check_popover_exists(id))$
        succeed()

      expect_equal(
        app$get_js(get_popover_editor_value(id)),
        "# 3 - second hint"
      )
    })

    it("shows the solution after the last hint", {
      app$
        click(selector = next_hint_button)$
        wait_for_js(check_popover_exists(id))$
        succeed()

      expect_equal(
        app$get_js(get_popover_editor_value(id)),
        "2 + 2"
      )
    })

    it("disables the next hint button when the solution is shown", {
      button_classes <- app$get_js(selector_classlist(next_hint_button))
      button_classes <- unlist(button_classes)

      expect_true("disabled" %in% button_classes)
      expect_true(
        app$get_js(selector_attributes(next_hint_button))$disabled %in%
        c("true", "disabled", "")
      )
    })

    it("doesn't do anything when disabled hint button is clicked", {
      app$
        click(selector = next_hint_button)$
        wait_for_js(check_popover_exists(id))$
        succeed()

      expect_equal(
        app$get_js(get_popover_editor_value(id)),
        "2 + 2"
      )
    })

    it("hides the hints when clicking on the hint button again", {
      app$
        wait_for_js(check_popover_exists(id))$
        click(selector = exercise_selector_hint_btn(id))$
        wait_for_js(check_popover_closed(id))$
        succeed()
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
  app$
    click(selector = ".resetButton")$
    wait_for_js(selector_exists(".bootbox .bootbox-accept"))$
    click(selector = ".bootbox .bootbox-accept")

  # Wait for page reload to complete
  chrome$Page$loadEventFired()

  # enable clipboard support
  # chrome$parent$debug_messages(TRUE)
  chrome$Browser$grantPermissions(list("clipboardReadWrite"))
  chrome$Emulation$setTouchEmulationEnabled(FALSE)
  chrome$Emulation$setEmitTouchEventsForMouse(FALSE)

  describe("copy hints", {
    id <- "ex1"

    it("clipboard button in hints popover copies editor text", {
      app$
        wait_for_js(check_popover_closed(id), timeout = 5000)$
        click(selector = exercise_selector_hint_btn(id))$
        wait_for_js(check_popover_exists(id))$
        succeed("hint popover exists")$
        wait_for_js(
          selector_exists(
            exercise_selector_hint_popover(id),
            ".btn-tutorial-copy-solution"
          )
        )$
        succeed("hint popover has copy solution button")$
        wait_for_js(
          selector_exists(exercise_selector_hint_popover(id), ".ace_editor")
        )$
        succeed("popover has editor with hint")

      hint_text <- app$get_js(get_popover_editor_value(id))
      expect_equal(hint_text, "c(\n  1,\n  2,\n  3\n)")

      copy_btn_coords <- app$get_js(
        selector_coordinates_center(
          exercise_selector_hint_popover(id),
          ".btn-tutorial-copy-solution"
        )
      )

      for (event in c("mousePressed", "mouseReleased")) {
        chrome$Input$dispatchMouseEvent(
          type = event,
          x = copy_btn_coords$x,
          y = copy_btn_coords$y,
          clickCount = 1,
          pointerType = "mouse",
          button = "left", # left button
          buttons = 1
        )
      }

      app$wait_for_js(check_popover_closed(id))

      expect_equal(
        app$get_js('navigator.clipboard.readText()'),
        hint_text
      )

      app$wait_for_js(
        sprintf(
          "navigator.clipboard.readText()
            .then(text => ace.edit(document.querySelector('%s')).insert(text))
            .then(() => true)
          ",
          exercise_selector_editor(id)
        )
      )

      # app$expect_screenshot(selector = exercise_selector(id))

      expect_equal(
        trimws(app$get_js(get_editor_value(exercise_selector_editor(id)))),
        trimws(hint_text)
      )
    })

    it("evaluates the pasted hint text correctly", {
      app$
        click(selector = exercise_selector_run_btn(id))$
        wait_for_js(exercise_has_output(id))

      output <- app$get_html(
        selector = paste(exercise_selector_output(id), "pre code"),
        outer_html = FALSE
      )

      expected_output <- app$get_html(
        selector = "#section-ex1-expected-output pre code",
        outer_html = FALSE
      )

      expect_equal(output, expected_output)
    })
  })

  describe("copy solutions", {
    id <- "ex2"
    expected_solution <- 'c(\n  "apple",\n  "banana",\n  "coconut"\n)'

    it("clipboard button in solution popover copies editor text", {
      app$
        wait_for_js(check_popover_closed(id), timeout = 5000)$
        click(selector = exercise_selector_hint_btn(id))$
        wait_for_js(check_popover_exists(id))$
        succeed("hint popover exists")$
        wait_for_js(
          selector_exists(
            exercise_selector_hint_popover(id),
            ".btn-tutorial-copy-solution"
          )
        )$
        succeed("solution popover has copy solution button")$
        wait_for_js(
          selector_exists(exercise_selector_hint_popover(id), ".ace_editor")
        )$
        succeed("popover has editor with hint")

      solution_text <- app$get_js(get_popover_editor_value(id))
      expect_equal(solution_text, expected_solution)

      copy_btn_coords <- app$get_js(
        selector_coordinates_center(
          exercise_selector_hint_popover(id),
          ".btn-tutorial-copy-solution"
        )
      )

      for (event in c("mousePressed", "mouseReleased")) {
        chrome$Input$dispatchMouseEvent(
          type = event,
          x = copy_btn_coords$x,
          y = copy_btn_coords$y,
          clickCount = 1,
          pointerType = "mouse",
          button = "left", # left button
          buttons = 1
        )
      }

      app$wait_for_js(check_popover_closed(id))

      expect_equal(
        app$get_js('navigator.clipboard.readText()'),
        solution_text
      )

      app$wait_for_js(
        sprintf(
          "navigator.clipboard.readText()
            .then(text => ace.edit(document.querySelector('%s')).insert(text))
            .then(() => true)
          ",
          exercise_selector_editor(id)
        )
      )

      # app$expect_screenshot(selector = exercise_selector(id))

      expect_equal(
        trimws(app$get_js(get_editor_value(exercise_selector_editor(id)))),
        trimws(solution_text)
      )
    })

    it("evaluates the pasted hint text correctly", {
      app$
        click(selector = exercise_selector_run_btn(id))$
        wait_for_js(exercise_has_output(id))

      output <- app$get_html(
        selector = paste(exercise_selector_output(id), "pre code"),
        outer_html = FALSE
      )

      expected_output <- app$get_html(
        selector = "#section-ex2-expected-output pre code",
        outer_html = FALSE
      )

      expect_equal(output, expected_output)
    })
  })
})
