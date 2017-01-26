function TutorCompleter(tutor) {
  
  this.tutor = tutor;

  var MODIFIER_NONE  = 0;
  var MODIFIER_CTRL  = 1;
  var MODIFIER_ALT   = 2;
  var MODIFIER_SHIFT = 4;

  var KEYCODE_TAB   =  9;
  var KEYCODE_SPACE = 32;

  var KeyCombination = function(event) {
    this.keyCode = event.keyCode || event.which;
    this.modifier = MODIFIER_NONE;
    this.modifier |= event.ctrlKey ? MODIFIER_CTRL : 0;
    this.modifier |= event.altKey ? MODIFIER_ALT : 0;
    this.modifier |= event.shiftKey ? MODIFIER_SHIFT : 0;
  }

  var ensureInitialized = function(editor) {
    if (editor.$autocompletionInitialized)
      return;

    // register completion engine
    editor.completers = editor.completers || [];
    editor.completers.push({

      getCompletions: function(editor, session, position, prefix, callback) {
        
        // send autocompletion request with document contents up to cursor
        // position (done to enable multi-line autocompletions)
        var contents = session.getTextRange({
          start: {row: 0, column: 0},
          end: position
        });

        tutor.$serverRequest("completion", contents, function(data) {
          
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

    // set autocompletion options
    editor.setOptions({
      enableBasicAutocompletion: true,
      enableLiveAutocompletion: true
    });

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
