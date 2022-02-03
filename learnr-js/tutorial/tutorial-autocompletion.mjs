export function TutorialCompleter (tutorial) { // eslint-disable-line no-unused-vars
  this.$tutorial = tutorial
  const self = this

  this.$onChange = function (data) {
    clearTimeout(this.$autocompletionTimerId)
    data = data || {}

    // only perform live autocompletion while user
    // is typing (ie, single-character text insertions)
    if (data.action !== 'insert') { return }

    const lines = data.lines || []
    if (lines.length !== 1) { return }

    // NOTE: Ace has already updated the document line at this point
    // so we can just look at the state of that line
    const pos = this.getCursorPosition()
    const line = this.session.getLine(pos.row)

    // NOTE: we allow new autocompletion sessions following a
    // ':' insertion just to enable cases where the user is
    // typing e.g. 'stats::rnorm()' while the popup is visible
    const popup = (this.completer || {}).popup
    if (popup && popup.isOpen && !/::$/.test(line)) { return }

    // figure out appropriate delay -- want to autocomplete
    // immediately after a '$' or '@' insertion, but need to
    // execute on timeout to allow Ace to finish processing
    // events (if any)
    let delayMs = 300
    if (/[$@]$|::$/.test(line)) { delayMs = 10 }

    this.$autocompletionTimerId = setTimeout(this.$liveAutocompleter, delayMs)
  }

  const MODIFIER_NONE = 0
  const MODIFIER_CTRL = 1
  const MODIFIER_ALT = 2
  const MODIFIER_SHIFT = 4

  const KEYCODE_TAB = 9
  const KEYCODE_SPACE = 32

  const KeyCombination = function (event) {
    this.keyCode = event.keyCode || event.which
    this.modifier = MODIFIER_NONE
    this.modifier |= event.ctrlKey ? MODIFIER_CTRL : 0
    this.modifier |= event.altKey ? MODIFIER_ALT : 0
    this.modifier |= event.shiftKey ? MODIFIER_SHIFT : 0
  }

  function initializeAceEventListeners (editor) {
    // NOTE: each Ace instance gets its own handlers, so
    // we don't store these as instance variables on the
    // TutorialCompleter instance (as we have 1 TutorialCompleter
    // handling completions for all Ace instances)
    const handlers = {}

    handlers.change = self.$onChange.bind(editor)
    handlers.destroy = function (event) {
      for (const key in handlers) { this.off(key, handlers[key]) }
    }.bind(editor)

    // register our handlers on the Ace editor
    for (const key in handlers) { editor.on(key, handlers[key]) }
  }

  function initializeCompletionEngine (editor) {
    editor.completers = editor.completers || []
    editor.completers.push({

      getCompletions: function (editor, session, position, prefix, callback) {
        // send autocompletion request with document contents up to cursor
        // position (done to enable multi-line autocompletions)
        const contents = session.getTextRange({
          start: { row: 0, column: 0 },
          end: position
        })

        const payload = {
          contents: contents,
          label: editor.tutorial.label
        }

        self.$tutorial.$serverRequest('completion', payload, function (data) {
          data = data || []

          // define a custom completer -- used for e.g. automatic
          // parenthesis insertion, and so on
          const completer = {
            insertMatch: function (editor, data) {
              // remove prefix
              const ranges = editor.selection.getAllRanges()
              const completions = editor.completer.completions
              const n = completions.filterText.length
              for (let i = 0; i < ranges.length; i++) {
                ranges[i].start.column -= n
                editor.session.remove(ranges[i])
              }

              // insert completion term (add parentheses for functions)
              const term = data.value + (data.is_function ? '()' : '')
              editor.execCommand('insertstring', term)

              // move cursor backwards for functions
              if (data.is_function) { editor.navigateLeft(1) }
            }
          }

          const completions = data.map(function (el) {
            return {
              caption: el[0] + (el[1] ? '()' : ''),
              value: el[0],
              score: 0,
              meta: 'R',
              is_function: el[1],
              completer: completer
            }
          })

          callback(null, completions)
        })
      }

    })

    editor.setOptions({
      enableBasicAutocompletion: true,
      enableLiveAutocompletion: false
    })
  }

  function initializeSetupChunk (editor) {
    const data = editor.tutorial
    self.$tutorial.$serverRequest('initialize_chunk', data)
  }

  function ensureInitialized (editor) {
    // bail if completions are disabled for this editor
    if (!editor.tutorial.completion) { return }

    if (editor.$autocompletionInitialized) { return }

    initializeAceEventListeners(editor)
    initializeCompletionEngine(editor)
    initializeSetupChunk(editor)

    // generate a live autocompleter for this editor if
    // not yet available
    if (typeof editor.$liveAutocompleter === 'undefined') {
      editor.$liveAutocompleter = function () {
        this.execCommand('startAutocomplete')
      }.bind(editor)
    }

    editor.$autocompletionInitialized = 1
  }

  function findActiveAceInstance () {
    let el = document.activeElement
    while (el != null) {
      if (el.env && el.env.editor) { return el.env.editor }
      el = el.parentElement
    }
    return null
  }

  function autocomplete (event) {
    // find active Ace instance
    const editor = findActiveAceInstance()
    if (editor == null) { return }

    // bail if completions are disabled for this editor
    if (!editor.tutorial.completion) { return }

    // ensure completion engine initialized
    ensureInitialized(editor)

    // cancel any pending live autocompletion
    clearTimeout(editor.$autocompletionTimerId)

    const keys = new KeyCombination(event)

    if (keys.keyCode === KEYCODE_TAB) {
      // don't autocomplete when tabbing away from editor
      if (editor.container.matches('.ace_indent_off')) {
        return
      }

      // check that we're not at the start of the line
      const pos = editor.getCursorPosition()
      const line = editor.session.getLine(pos.row)
      const isCursorAtStart = line.substr(0, pos.column).trim() === ''
      if (isCursorAtStart) {
        return
      }
    }

    event.stopPropagation()
    event.preventDefault()
    editor.execCommand('startAutocomplete')
  }

  document.addEventListener('keydown', function (event) {
    // TODO: find more appropriate place for one-time initialization
    const editor = findActiveAceInstance()
    if (editor !== null) { ensureInitialized(editor) }

    // bail if completions are disabled for this editor
    if (editor !== null && !editor.tutorial.completion) { return }

    const keys = new KeyCombination(event)
    if (keys.keyCode === KEYCODE_TAB && keys.modifier === MODIFIER_NONE) {
      if (editor && editor.completer && editor.completer.activated) {
        // it is already activated. Accept the top choice. To do this, do nothing and it will be resolved by the autocompleter
        return
      }
      // autocompleter is not active. enable it
      return autocomplete(event)
    }

    if (keys.keyCode === KEYCODE_SPACE && keys.modifier === MODIFIER_CTRL) {
      return autocomplete(event)
    }
  }, true)
}
