skip_on_cran()
library(shinytest2)

check_popover_exists <- function(selector) {
  selector_exists(paste(selector, "+ .popover"))
}

check_popover_closed <- function(selector) {
  selector_doesnt_exist(paste(selector, "+ .popover"))
}

get_popover_editor_value <- function(selector) {
  get_editor_value(paste(selector, "+ .popover .ace_editor"))
}

describe("sequential hints", {
  app <- AppDriver$new(test_path("tutorials/next-hint"))
  withr::defer(app$stop())

  if (FALSE) {
    # for interactive viewing/debugging
    app$view()
  }

  describe("with one hint only", {
    one_hint <- "#tutorial-exercise-one-input .btn-tutorial-hint"

    it("shows hint when hint button is clicked", {
      app$
        wait_for_js(selector_exists(one_hint))$
        click(selector = one_hint)$
        wait_for_js(check_popover_exists(one_hint))$
        succeed()
    })

    it("doesn't have a next hint button", {
      one_next_hint_button <- paste(one_hint, "+ .popover .btn-tutorial-hint")
      app$
        wait_for_js(selector_doesnt_exist(one_next_hint_button))$
        succeed()
    })

    it("shows the correct hint in the editor", {
      expect_equal(
        app$get_js(get_popover_editor_value(one_hint)),
        "# one hint"
      )
    })

    it("hides the popover when clicking on the hint button again", {
      app$
        wait_for_js(check_popover_exists(one_hint))$
        click(selector = one_hint)$
        wait_for_js(check_popover_closed(one_hint))$
        succeed()
    })
  })

  describe("with two hints", {
    two_hint <- "#tutorial-exercise-two-input .btn-tutorial-hint"

    it("shows hints when hint button is clicked", {
      app$
        click(selector = two_hint)$
        wait_for_js(check_popover_exists(two_hint))$
        succeed()
    })

    two_next_hint_button <- paste(two_hint, "+ .popover .btn-tutorial-next-hint")

    it("has a next hint button", {
      app$
        wait_for_js(selector_exists(two_next_hint_button))$
        succeed()
    })

    it("shows the first hint in the editor", {
      expect_equal(
        app$get_js(get_popover_editor_value(two_hint)),
        "# first hint"
      )
    })

    it("shows the next hint when clicking on the next hint button", {
      app$click(selector = two_next_hint_button)
      expect_equal(
        app$get_js(get_popover_editor_value(two_hint)),
        "# second hint"
      )
    })

    it("disables the next hint button when the last hint is shown", {
      two_next_hint_btn_classes <- unlist(
        app$get_js(selector_classlist(two_next_hint_button))
      )

      expect_true("disabled" %in% two_next_hint_btn_classes)
      expect_true(app$get_js(selector_attributes(two_next_hint_button))$disabled)
    })

    it("doesn't do anything when disabled hint button is clicked", {
      app$click(selector = two_next_hint_button)
      expect_equal(
        app$get_js(get_popover_editor_value(two_hint)),
        "# second hint"
      )
    })

    it("hides the hints when clicking on the hint button again", {
      app$
        wait_for_js(check_popover_exists(two_hint))$
        click(selector = two_hint)$
        wait_for_js(check_popover_closed(two_hint))
    })
  })

  describe("with hints and solution", {
    three_hint <- "#tutorial-exercise-three-input .btn-tutorial-hint"

    it("shows hints when hint button is clicked", {
      app$
        click(selector = three_hint)$
        wait_for_js(check_popover_exists(three_hint))$
        succeed()
    })

    three_next_hint_button <- paste(three_hint, "+ .popover .btn-tutorial-next-hint")

    it("has a next hint button", {
      app$
        wait_for_js(selector_exists(three_next_hint_button))$
        succeed()
    })

    it("shows the first hint in the editor", {
      expect_equal(
        app$get_js(get_popover_editor_value(three_hint)),
        "# 3 - first hint"
      )
    })

    it("shows the next hint when clicking on the next hint button", {
      app$
        click(selector = three_next_hint_button)$
        wait_for_js(check_popover_exists(three_hint))$
        succeed()

      expect_equal(
        app$get_js(get_popover_editor_value(three_hint)),
        "# 3 - second hint"
      )
    })

    it("shows the solution after the last hint", {
      app$
        click(selector = three_next_hint_button)$
        wait_for_js(check_popover_exists(three_hint))$
        succeed()

      expect_equal(
        app$get_js(get_popover_editor_value(three_hint)),
        "2 + 2"
      )
    })

    it("disables the next hint button when the solution is shown", {
      button_classes <- app$get_js(selector_classlist(three_next_hint_button))
      button_classes <- unlist(button_classes)

      expect_true("disabled" %in% button_classes)
      expect_true(app$get_js(selector_attributes(three_next_hint_button))$disabled)
    })

    it("doesn't do anything when disabled hint button is clicked", {
      app$
        click(selector = three_next_hint_button)$
        wait_for_js(check_popover_exists(three_hint))$
        succeed()

      expect_equal(
        app$get_js(get_popover_editor_value(three_hint)),
        "2 + 2"
      )
    })

    it("hides the hints when clicking on the hint button again", {
      app$
        wait_for_js(check_popover_exists(three_hint))$
        click(selector = three_hint)$
        wait_for_js(check_popover_closed(three_hint))$
        succeed()
    })
  })
})
