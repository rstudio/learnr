"use strict";

require("core-js/modules/es.object.define-property.js");

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.TutorialCompleter = TutorialCompleter;

require("core-js/modules/es.regexp.exec.js");

require("core-js/modules/es.regexp.test.js");

require("core-js/modules/es.array.map.js");

require("core-js/modules/es.string.trim.js");

function TutorialCompleter(tutorial) {
  this.$tutorial = tutorial;
  var self = this;

  this.$onChange = function (data) {
    clearTimeout(this.$autocompletionTimerId);
    data = data || {};

    if (data.action !== 'insert') {
      return;
    }

    var lines = data.lines || [];

    if (lines.length !== 1) {
      return;
    }

    var pos = this.getCursorPosition();
    var line = this.session.getLine(pos.row);
    var popup = (this.completer || {}).popup;

    if (popup && popup.isOpen && !/::$/.test(line)) {
      return;
    }

    var delayMs = 300;

    if (/[$@]$|::$/.test(line)) {
      delayMs = 10;
    }

    this.$autocompletionTimerId = setTimeout(this.$liveAutocompleter, delayMs);
  };

  var MODIFIER_NONE = 0;
  var MODIFIER_CTRL = 1;
  var MODIFIER_ALT = 2;
  var MODIFIER_SHIFT = 4;
  var KEYCODE_TAB = 9;
  var KEYCODE_SPACE = 32;

  var KeyCombination = function KeyCombination(event) {
    this.keyCode = event.keyCode || event.which;
    this.modifier = MODIFIER_NONE;
    this.modifier |= event.ctrlKey ? MODIFIER_CTRL : 0;
    this.modifier |= event.altKey ? MODIFIER_ALT : 0;
    this.modifier |= event.shiftKey ? MODIFIER_SHIFT : 0;
  };

  function initializeAceEventListeners(editor) {
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
  }

  function initializeCompletionEngine(editor) {
    editor.completers = editor.completers || [];
    editor.completers.push({
      getCompletions: function getCompletions(editor, session, position, prefix, callback) {
        var contents = session.getTextRange({
          start: {
            row: 0,
            column: 0
          },
          end: position
        });
        var payload = {
          contents: contents,
          label: editor.tutorial.label
        };
        self.$tutorial.$serverRequest('completion', payload, function (data) {
          data = data || [];
          var completer = {
            insertMatch: function insertMatch(editor, data) {
              var ranges = editor.selection.getAllRanges();
              var completions = editor.completer.completions;
              var n = completions.filterText.length;

              for (var i = 0; i < ranges.length; i++) {
                ranges[i].start.column -= n;
                editor.session.remove(ranges[i]);
              }

              var term = data.value + (data.is_function ? '()' : '');
              editor.execCommand('insertstring', term);

              if (data.is_function) {
                editor.navigateLeft(1);
              }
            }
          };
          var completions = data.map(function (el) {
            return {
              caption: el[0] + (el[1] ? '()' : ''),
              value: el[0],
              score: 0,
              meta: 'R',
              is_function: el[1],
              completer: completer
            };
          });
          callback(null, completions);
        });
      }
    });
    editor.setOptions({
      enableBasicAutocompletion: true,
      enableLiveAutocompletion: false
    });
  }

  function initializeSetupChunk(editor) {
    var data = editor.tutorial;
    self.$tutorial.$serverRequest('initialize_chunk', data);
  }

  function ensureInitialized(editor) {
    if (!editor.tutorial.completion) {
      return;
    }

    if (editor.$autocompletionInitialized) {
      return;
    }

    initializeAceEventListeners(editor);
    initializeCompletionEngine(editor);
    initializeSetupChunk(editor);

    if (typeof editor.$liveAutocompleter === 'undefined') {
      editor.$liveAutocompleter = function () {
        this.execCommand('startAutocomplete');
      }.bind(editor);
    }

    editor.$autocompletionInitialized = 1;
  }

  function findActiveAceInstance() {
    var el = document.activeElement;

    while (el != null) {
      if (el.env && el.env.editor) {
        return el.env.editor;
      }

      el = el.parentElement;
    }

    return null;
  }

  function autocomplete(event) {
    var editor = findActiveAceInstance();

    if (editor == null) {
      return;
    }

    if (!editor.tutorial.completion) {
      return;
    }

    ensureInitialized(editor);
    clearTimeout(editor.$autocompletionTimerId);
    var keys = new KeyCombination(event);

    if (keys.keyCode === KEYCODE_TAB) {
      if (editor.container.matches('.ace_indent_off')) {
        return;
      }

      var pos = editor.getCursorPosition();
      var line = editor.session.getLine(pos.row);
      var isCursorAtStart = line.substr(0, pos.column).trim() === '';

      if (isCursorAtStart) {
        return;
      }
    }

    event.stopPropagation();
    event.preventDefault();
    editor.execCommand('startAutocomplete');
  }

  document.addEventListener('keydown', function (event) {
    var editor = findActiveAceInstance();

    if (editor !== null) {
      ensureInitialized(editor);
    }

    if (editor !== null && !editor.tutorial.completion) {
      return;
    }

    var keys = new KeyCombination(event);

    if (keys.keyCode === KEYCODE_TAB && keys.modifier === MODIFIER_NONE) {
      if (editor && editor.completer && editor.completer.activated) {
        return;
      }

      return autocomplete(event);
    }

    if (keys.keyCode === KEYCODE_SPACE && keys.modifier === MODIFIER_CTRL) {
      return autocomplete(event);
    }
  }, true);
}