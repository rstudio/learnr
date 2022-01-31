/* global ace */

const TutorialDiagnostics = function (tutorial) { // eslint-disable-line no-unused-vars
  this.$tutorial = tutorial
  const self = this

  const unmatchedClosingBracket = function (token) {
    return {
      row: token.position.row,
      column: token.position.column,
      type: 'error',
      text: "unmatched closing bracket '" + token.value + "'"
    }
  }

  const unmatchedOpeningBracket = function (token) {
    return {
      row: token.position.row,
      column: token.position.column,
      type: 'error',
      text: "unmatched opening bracket '" + token.value + "'"
    }
  }

  const unexpected = function (symbol, token, type) {
    return {
      row: token.position.row,
      column: token.position.column,
      type: type || 'error',
      text: 'unexpected ' + symbol + " '" + token.value + "'"
    }
  }

  const isSymbol = function (token) {
    // this is a kludge so that 'in' is treated as though it were an
    // operator by the diagnostics system
    const value = token.value || ''
    if (value === 'in') { return false }

    const type = token.type || ''
    return type === 'string' ||
           type === 'constant.numeric' ||
           type === 'constant.language.boolean' ||
           type === 'identifier' ||
           type === 'keyword' ||
           type === 'variable.language'
  }

  const isOperator = function (token) {
    const type = token.type || ''
    return type === 'keyword.operator'
  }

  const isUnaryOperator = function (token) {
    const value = token.value || ''
    return value === '+' ||
           value === '-' ||
           value === '~' ||
           value === '!' ||
           value === '?'
  }

  const diagnose = function () {
    // alias editor
    const editor = this

    // create tokenizer -- we do this manually as we do not
    // want Ace to merge brackets sitting together
    const Tokenizer = ace.require('ace/tokenizer').Tokenizer
    const RHighlightRules = ace.require('ace/mode/r_highlight_rules').RHighlightRules
    const rules = new RHighlightRules().getRules()
    for (const key in rules) {
      const rule = rules[key]
      for (let i = 0; i < rule.length; i++) {
        rule[i].merge = false
      }
    }

    // fix up rules
    rules.start.unshift({
      token: 'string',
      regex: '"(?:(?:\\\\.)|(?:[^"\\\\]))*?"',
      merge: false,
      next: 'start'
    })

    rules.start.unshift({
      token: 'string',
      regex: "'(?:(?:\\\\.)|(?:[^'\\\\]))*?'",
      merge: false,
      next: 'start'
    })

    rules.start.unshift({
      token: 'keyword.operator',
      regex: ':::|::|:=|%%|>=|<=|==|!=|\\|>|\\->|<\\-|<<\\-|\\|\\||&&|=|\\+|\\-|\\*\\*?|/|\\^|>|<|!|&|\\||~|\\$|:|@|\\?',
      merge: false,
      next: 'start'
    })

    rules.start.unshift({
      token: 'punctuation',
      regex: '[;,]',
      merge: false,
      next: 'start'
    })

    const tokenizer = new Tokenizer(rules)

    // clear old diagnostics
    editor.session.clearAnnotations()

    // retrieve contents and tokenize
    const lines = editor.session.doc.$lines
    let tokens = []
    let state = 'start'
    for (let i = 0; i < lines.length; i++) {
      const tokenized = tokenizer.getLineTokens(lines[i], state)
      for (let j = 0; j < tokenized.tokens.length; j++) { tokens.push(tokenized.tokens[j]) }
      tokens.push({ type: 'text', value: '\n' })
      state = tokenized.state
    }

    // add row, column to each token
    const doc = editor.session.doc
    let docIndex = 0
    for (let i = 0; i < tokens.length; i++) {
      tokens[i].position = doc.indexToPosition(docIndex)
      docIndex += tokens[i].value.length
    }

    // remove whitespace, comments (not relevant for syntax diagnostics)
    tokens = tokens.filter(function (token) {
      return token.type !== 'comment' && !/^\s+$/.test(token.value)
    })

    // state related to our simple diagnostics engine
    const diagnostics = []
    const bracketStack = []

    // iterate through tokens and look for invalid sequences
    for (let i = 0; i < tokens.length; i++) {
      // update local state
      const token = tokens[i]
      const type = token.type // eslint-disable-line no-unused-vars
      const value = token.value

      // handle left brackets
      if (value === '(' || value === '{' || value === '[') {
        bracketStack.push(token)
        continue
      }

      // handle right brackets
      if (value === ')' || value === '}' || value === ']') {
        // empty bracket stack: signal unmatched
        if (bracketStack.length === 0) {
          diagnostics.push(unmatchedClosingBracket(token))
          continue
        }

        // pop off from bracket stack and verify
        const openBracket = bracketStack.pop()

        const ok =
          (value === ')' && openBracket.value === '(') ||
          (value === ']' && openBracket.value === '[') ||
          (value === '}' && openBracket.value === '{')

        if (!ok) {
          diagnostics.push(unmatchedClosingBracket(token))
          diagnostics.push(unmatchedOpeningBracket(openBracket))
          continue
        }
      }

      if (i > 0) {
        const lhs = tokens[i - 1]
        const rhs = tokens[i]
        const bracket = bracketStack[bracketStack.length - 1] || {}

        // if we have two symbols in a row with no binary operator in between, syntax error
        if (lhs.position.row === rhs.position.row && isSymbol(lhs) && isSymbol(rhs)) {
          diagnostics.push(unexpected('symbol', rhs))
          continue
        }

        // if we have an operator followed by a binary-only operator, syntax error
        if (lhs.position.row === rhs.position.row && isOperator(lhs) && isOperator(rhs) && !isUnaryOperator(rhs)) {
          diagnostics.push(unexpected('operator', rhs))
          continue
        }

        // if we have multiple commas in a row within a parenthetical context, warn
        if (lhs.value === ',' && rhs.value === ',' && bracket.value === '(') {
          diagnostics.push(unexpected('comma', rhs, 'warning'))
          continue
        }

        // if we have a comma preceding a closing bracket, warn
        if (lhs.value === ',' && (rhs.value === '}' || rhs.value === ')' || rhs.value === ']')) {
          diagnostics.push(unexpected('comma', lhs, 'warning'))
          continue
        }
      }
    }

    // if we still have things on the bracket stack, they're unmatched
    for (let i = 0; i < bracketStack.length; i++) {
      diagnostics.push(unmatchedOpeningBracket(bracketStack[i]))
    }

    // signal diagnostics to Ace
    editor.session.setAnnotations(diagnostics)
  }

  const findActiveAceInstance = function () {
    let el = document.activeElement
    while (el != null) {
      if (el.env && el.env.editor) { return el.env.editor }
      el = el.parentElement
    }
    return null
  }

  const ensureInitialized = function (editor) {
    if (editor.$diagnosticsInitialized) { return }

    if (!editor.tutorial.diagnostics) { return }

    // register handlers
    const handlers = {}
    handlers.change = self.$onChange.bind(editor)
    handlers.destroy = function (event) {
      for (const key in handlers) { this.off(key, handlers[key]) }
    }.bind(editor)

    for (const key in handlers) { editor.on(key, handlers[key]) }

    editor.$liveDiagnostics = diagnose.bind(editor)

    editor.$diagnosticsInitialized = 1
  }

  this.$onChange = function (data) {
    if (!this.tutorial.diagnostics) { return }

    clearTimeout(this.$diagnosticsTimerId)
    this.session.clearAnnotations()
    this.$diagnosticsTimerId = setTimeout(this.$liveDiagnostics, 1000)
  }

  this.$onKeyDown = function (event) {
    const editor = findActiveAceInstance()
    if (editor != null) {
      ensureInitialized(editor)
      document.removeEventListener('keydown', this.$onKeyDown)
    }
  }

  document.addEventListener('keydown', this.$onKeyDown)
}
