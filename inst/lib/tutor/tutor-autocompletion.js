function TutorCompleter(tutor) {
  this.$tutor = tutor;
  var self = this;

  this.$onChange = function(data) {
    clearTimeout(this.$autocompletionTimerId);
    data = data || {};

    var popup = this.completer.popup;
    if (popup && popup.isOpen)
      return;

    if (data.action !== "insert")
      return;

    var lines = data.lines || [];
    if (lines.length !== 1)
      return;
    
    var text = lines[0];
    if (text.length !== 1)
      return;
    
    var self = this;
    this.$autocompletionTimerId = setTimeout(function() {
      self.execCommand("startAutocomplete");
    }, 300);
  };
 
  var MODIFIER_NONE  = 0;
  var MODIFIER_CTRL  = 1;
  var MODIFIER_ALT   = 2;
  var MODIFIER_SHIFT = 4;

  var KEYCODE_TAB   =  9;
  var KEYCODE_SPACE = 32;

  var KeyCombination = function(event) {
    this.keyCode = event.keyCode || event.which;
    this.modifier = MODIFIER_NONE;
    this.modifier |= event.ctrlKey  ? MODIFIER_CTRL  : 0;
    this.modifier |= event.altKey   ? MODIFIER_ALT   : 0;
    this.modifier |= event.shiftKey ? MODIFIER_SHIFT : 0;
  }

  function initializeAceEventListeners(editor) {

    // NOTE: each Ace instance gets its own handlers, so
    // we don't store these as instance variables on the
    // TutorCompleter instance (as we have 1 TutorCompleter
    // handling completions for all Ace instances)
    var handlers = {};

    handlers["change"]  = self.$onChange.bind(editor);
    handlers["destroy"] = function(event) {
      for (var key in handlers)
        this.off(key, handlers[key]);
    }.bind(editor);

    // register our handlers on the Ace editor
    for (var key in handlers)
      editor.on(key, handlers[key]);
  }

  function initializeCompletionEngine(editor) {

    editor.completers = editor.completers || [];
    editor.completers.push({

      getCompletions: function(editor, session, position, prefix, callback) {
        
        // send autocompletion request with document contents up to cursor
        // position (done to enable multi-line autocompletions)
        var contents = session.getTextRange({
          start: {row: 0, column: 0},
          end: position
        });

        self.$tutor.$serverRequest("completion", contents, function(data) {
          
          data = data || [];
          var completions = data.map(function(value) {
            return {
              caption: value,
              value: value,
              score: 0,
              meta: "r"
            };
          });

          callback(null, completions);
        })
      }

    });

    editor.setOptions({
      enableBasicAutocompletion: true,
      enableLiveAutocompletion: false
    });

  }

  var ensureInitialized = function(editor) {
    if (editor.$autocompletionInitialized)
      return;

    initializeAceEventListeners(editor);
    initializeCompletionEngine(editor);

    editor.$autocompletionInitialized = 1;
  }

  var autocomplete = function() {

    // find active Ace instance
    var editor = null;
    var el = document.activeElement;
    while (el != null) {
      if (el.env && el.env.editor) {
        editor = el.env.editor;
        break;
      }
      el = el.parentElement;
    }

    if (editor == null)
      return;
    
    // ensure completion engine initialized
    ensureInitialized(editor);

    // manually handle event
    event.stopPropagation();
    event.preventDefault();
    editor.execCommand("startAutocomplete");
  }

  document.addEventListener("keydown", function(event) {
    var keys = new KeyCombination(event);
    if (keys.keyCode == KEYCODE_TAB && keys.modifier == MODIFIER_NONE)
       return autocomplete();
    
    if (keys.keyCode == KEYCODE_SPACE && keys.modifier == MODIFIER_CTRL)
       return autocomplete();

  }, true);
  
}
