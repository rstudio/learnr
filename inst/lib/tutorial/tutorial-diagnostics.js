"use strict";

require("core-js/modules/es.object.define-property.js");

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.TutorialDiagnostics = TutorialDiagnostics;

require("core-js/modules/es.array.filter.js");

require("core-js/modules/es.object.to-string.js");

require("core-js/modules/es.regexp.exec.js");

require("core-js/modules/es.regexp.test.js");

function TutorialDiagnostics(tutorial) {
  this.$tutorial = tutorial;
  var self = this;

  var unmatchedClosingBracket = function unmatchedClosingBracket(token) {
    return {
      row: token.position.row,
      column: token.position.column,
      type: 'error',
      text: "unmatched closing bracket '" + token.value + "'"
    };
  };

  var unmatchedOpeningBracket = function unmatchedOpeningBracket(token) {
    return {
      row: token.position.row,
      column: token.position.column,
      type: 'error',
      text: "unmatched opening bracket '" + token.value + "'"
    };
  };

  var unexpected = function unexpected(symbol, token, type) {
    return {
      row: token.position.row,
      column: token.position.column,
      type: type || 'error',
      text: 'unexpected ' + symbol + " '" + token.value + "'"
    };
  };

  var isSymbol = function isSymbol(token) {
    var value = token.value || '';

    if (value === 'in') {
      return false;
    }

    var type = token.type || '';
    return type === 'string' || type === 'constant.numeric' || type === 'constant.language.boolean' || type === 'identifier' || type === 'keyword' || type === 'variable.language';
  };

  var isOperator = function isOperator(token) {
    var type = token.type || '';
    return type === 'keyword.operator';
  };

  var isUnaryOperator = function isUnaryOperator(token) {
    var value = token.value || '';
    return value === '+' || value === '-' || value === '~' || value === '!' || value === '?';
  };

  var diagnose = function diagnose() {
    var editor = this;

    var Tokenizer = ace.require('ace/tokenizer').Tokenizer;

    var RHighlightRules = ace.require('ace/mode/r_highlight_rules').RHighlightRules;

    var rules = new RHighlightRules().getRules();

    for (var key in rules) {
      var rule = rules[key];

      for (var i = 0; i < rule.length; i++) {
        rule[i].merge = false;
      }
    }

    rules.start.unshift({
      token: 'string',
      regex: '"(?:(?:\\\\.)|(?:[^"\\\\]))*?"',
      merge: false,
      next: 'start'
    });
    rules.start.unshift({
      token: 'string',
      regex: "'(?:(?:\\\\.)|(?:[^'\\\\]))*?'",
      merge: false,
      next: 'start'
    });
    rules.start.unshift({
      token: 'keyword.operator',
      regex: ':::|::|:=|%%|>=|<=|==|!=|\\|>|\\->|<\\-|<<\\-|\\|\\||&&|=|\\+|\\-|\\*\\*?|/|\\^|>|<|!|&|\\||~|\\$|:|@|\\?',
      merge: false,
      next: 'start'
    });
    rules.start.unshift({
      token: 'punctuation',
      regex: '[;,]',
      merge: false,
      next: 'start'
    });
    var tokenizer = new Tokenizer(rules);
    editor.session.clearAnnotations();
    var lines = editor.session.doc.$lines;
    var tokens = [];
    var state = 'start';

    for (var _i = 0; _i < lines.length; _i++) {
      var tokenized = tokenizer.getLineTokens(lines[_i], state);

      for (var j = 0; j < tokenized.tokens.length; j++) {
        tokens.push(tokenized.tokens[j]);
      }

      tokens.push({
        type: 'text',
        value: '\n'
      });
      state = tokenized.state;
    }

    var doc = editor.session.doc;
    var docIndex = 0;

    for (var _i2 = 0; _i2 < tokens.length; _i2++) {
      tokens[_i2].position = doc.indexToPosition(docIndex);
      docIndex += tokens[_i2].value.length;
    }

    tokens = tokens.filter(function (token) {
      return token.type !== 'comment' && !/^\s+$/.test(token.value);
    });
    var diagnostics = [];
    var bracketStack = [];

    for (var _i3 = 0; _i3 < tokens.length; _i3++) {
      var token = tokens[_i3];
      var type = token.type;
      var value = token.value;

      if (value === '(' || value === '{' || value === '[') {
        bracketStack.push(token);
        continue;
      }

      if (value === ')' || value === '}' || value === ']') {
        if (bracketStack.length === 0) {
          diagnostics.push(unmatchedClosingBracket(token));
          continue;
        }

        var openBracket = bracketStack.pop();
        var ok = value === ')' && openBracket.value === '(' || value === ']' && openBracket.value === '[' || value === '}' && openBracket.value === '{';

        if (!ok) {
          diagnostics.push(unmatchedClosingBracket(token));
          diagnostics.push(unmatchedOpeningBracket(openBracket));
          continue;
        }
      }

      if (_i3 > 0) {
        var lhs = tokens[_i3 - 1];
        var rhs = tokens[_i3];
        var bracket = bracketStack[bracketStack.length - 1] || {};

        if (lhs.position.row === rhs.position.row && isSymbol(lhs) && isSymbol(rhs)) {
          diagnostics.push(unexpected('symbol', rhs));
          continue;
        }

        if (lhs.position.row === rhs.position.row && isOperator(lhs) && isOperator(rhs) && !isUnaryOperator(rhs)) {
          diagnostics.push(unexpected('operator', rhs));
          continue;
        }

        if (lhs.value === ',' && rhs.value === ',' && bracket.value === '(') {
          diagnostics.push(unexpected('comma', rhs, 'warning'));
          continue;
        }

        if (lhs.value === ',' && (rhs.value === '}' || rhs.value === ')' || rhs.value === ']')) {
          diagnostics.push(unexpected('comma', lhs, 'warning'));
          continue;
        }
      }
    }

    for (var _i4 = 0; _i4 < bracketStack.length; _i4++) {
      diagnostics.push(unmatchedOpeningBracket(bracketStack[_i4]));
    }

    editor.session.setAnnotations(diagnostics);
  };

  var findActiveAceInstance = function findActiveAceInstance() {
    var el = document.activeElement;

    while (el != null) {
      if (el.env && el.env.editor) {
        return el.env.editor;
      }

      el = el.parentElement;
    }

    return null;
  };

  var ensureInitialized = function ensureInitialized(editor) {
    if (editor.$diagnosticsInitialized) {
      return;
    }

    if (!editor.tutorial.diagnostics) {
      return;
    }

    var handlers = {};
    handlers.change = self.$onChange.bind(editor);

    handlers.destroy = function (event) {
      for (var key in handlers) {
        this.off(key, handlers[key]);
      }
    }.bind(editor);

    for (var key in handlers) {
      editor.on(key, handlers[key]);
    }

    editor.$liveDiagnostics = diagnose.bind(editor);
    editor.$diagnosticsInitialized = 1;
  };

  this.$onChange = function (data) {
    if (!this.tutorial.diagnostics) {
      return;
    }

    clearTimeout(this.$diagnosticsTimerId);
    this.session.clearAnnotations();
    this.$diagnosticsTimerId = setTimeout(this.$liveDiagnostics, 1000);
  };

  this.$onKeyDown = function (event) {
    var editor = findActiveAceInstance();

    if (editor != null) {
      ensureInitialized(editor);
      document.removeEventListener('keydown', this.$onKeyDown);
    }
  };

  document.addEventListener('keydown', this.$onKeyDown);
}