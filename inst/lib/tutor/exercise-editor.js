

Tutor.prototype.$initializeExerciseEditors = function() {
  
  this.$forEachExercise(function(exercise) {
    
    // helper to create an id
    function create_id(suffix) {
      return "tutor-exercise-" + exercise.attr('data-label') + "-" + suffix;
    } 
     
    // get all <pre class='text'> elements, get their code, then remove them
    var code = '';
    var code_blocks = exercise.children('pre.text, pre.lang-text');
    code_blocks.each(function() {
      var code_element = $(this).children('code');
      if (code_element.length > 0)
        code = code + code_element.text() + "\n";
      else 
        code = code + $(this).text();
    });
    code_blocks.remove();
    
    // get the knitr options script block and detach it (will move to input div)
    var options_script = exercise.children('script[data-opts-chunk="1"]').detach();
    
    // wrap the remaining elements in an output frame div
    exercise.wrapInner('<div class="tutor-exercise-output-frame"></div>');
    var output_frame = exercise.children('.tutor-exercise-output-frame');
    
    // create input div
    var input_div = $('<div class="tutor-exercise-input"></div>');
    input_div.attr('id', create_id('input'));
    
    // create action button
    var run_button = $('<button class="btn btn-success btn-xs ' + 
                       'tutor-exercise-run action-button"></button>');
    run_button.attr('type', 'button');
    run_button.text('Run Code');
    run_button.attr('id', create_id('button'));
    var isMac = navigator.platform.toUpperCase().indexOf('MAC') >= 0;
    var title = "Run code (" + (isMac ? "Cmd" : "Ctrl") + "+Shift+Enter)";
    run_button.attr('title', title);
    run_button.on('click', function() {
      output_frame.addClass('recalculating');
    });
    input_div.append(run_button);
    
    // create code div and add it to the input div
    var code_div = $('<div class="tutor-exercise-code-editor"></div>');
    var code_id = create_id('code-editor');
    code_div.attr('id', code_id);
    input_div.append(code_div);
    
    // add the knitr options script to the input div
    input_div.append(options_script);
    
    // prepend the input div to the exercise container
    exercise.prepend(input_div);
    
    // create an output div and append it to the output_frame
    var output_div = $('<div class="tutor-exercise-output"></div>');
    output_div.attr('id', create_id('output'));
    output_frame.append(output_div);
      
    // activate the ace editor
    var editor = ace.edit(code_id);
    editor.setHighlightActiveLine(false);
    editor.setShowPrintMargin(false);
    editor.setShowFoldWidgets(false);
    editor.renderer.setDisplayIndentGuides(false);
    editor.setTheme("ace/theme/textmate");
    editor.$blockScrolling = Infinity;
    editor.session.setMode("ace/mode/r");
    editor.session.getSelection().clearSelection();
    editor.setValue(code, -1);
    
    // bind execution keys 
    function bindExecutionKey(name, key) {
      var macKey = key.replace("Ctrl+", "Command+");
      editor.commands.addCommand({
        name: name,
        bindKey: {win: key, mac: macKey},
        exec: function(editor) {
          run_button.trigger('click');
        }
      });
    }
    bindExecutionKey("execute1", "Ctrl+Enter");
    bindExecutionKey("execute2", "Ctrl+Shift+Enter");
    bindExecutionKey("execute3", "Ctrl+R");
    
    // mange ace height as the document changes
    var updateAceHeight = function()  {
      var lines = exercise.attr('data-lines');
      if (lines && (lines > 0)) {
         editor.setOptions({
            minLines: lines,
            maxLines: lines
         });
      } else {
         editor.setOptions({
            minLines: 2,
            maxLines: Math.max(Math.min(editor.session.getLength(), 15), 2)
         });
      }
     
    };
    updateAceHeight();
    editor.getSession().on('change', updateAceHeight);
  });  
};

