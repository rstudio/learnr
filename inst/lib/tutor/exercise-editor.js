

Tutor.prototype.$initializeExerciseEditors = function() {
  
  // behavior constants
  var kMinLines = 3;

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
        code = code + code_element.text();
      else 
        code = code + $(this).text();
    });
    code_blocks.remove();
    // ensure a minimum of 3 lines
    var lines = code.split(/\r\n|\r|\n/).length;
    for (var i=lines; i<kMinLines;i++)
      code = code + "\n";
        
    
    // get the knitr options script block and detach it (will move to input div)
    var options_script = exercise.children('script[data-opts-chunk="1"]').detach();
    
    // wrap the remaining elements in an output frame div
    exercise.wrapInner('<div class="tutor-exercise-output-frame"></div>');
    var output_frame = exercise.children('.tutor-exercise-output-frame');
    
    // create input div
    var input_div = $('<div class="tutor-exercise-input panel panel-default"></div>');
    input_div.attr('id', create_id('input'));

    // creating heading
    var panel_heading = $('<div class="panel-heading tutor-panel-heading"></div>');
    panel_heading.text('Exercise');
    input_div.append(panel_heading);

    // create body
    var panel_body = $('<div class="panel-body"></div>');
    input_div.append(panel_body);
    
    // create action button
    var run_button = $('<a class="btn btn-success btn-xs ' + 
                       'pull-right action-button"></a>');
    run_button.append($('<i class="fa fa-play"></i>'));
    run_button.attr('type', 'button');
    run_button.append(' Run Code');
    run_button.attr('id', create_id('button'));
    var isMac = navigator.platform.toUpperCase().indexOf('MAC') >= 0;
    var title = "Run code (" + (isMac ? "Cmd" : "Ctrl") + "+Shift+Enter)";
    run_button.attr('title', title);
    run_button.on('click', function() {
      output_frame.addClass('recalculating');
    });
    panel_heading.append(run_button);

    // create hint button
    var hint_button = $('<a class="btn btn-warning btn-xs pull-right"></a>');
    hint_button.append($('<i class="fa fa-lightbulb-o"></i>'));
    hint_button.append(' Solution');
    hint_button.attr('title', 'See the solution');
    panel_heading.append(hint_button);


    
    // create code div and add it to the input div
    var code_div = $('<div class="tutor-exercise-code-editor"></div>');
    var code_id = create_id('code-editor');
    code_div.attr('id', code_id);
    panel_body.append(code_div);
    
    // add the knitr options script to the input div
    panel_body.append(options_script);
    
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
    
    // re-focus the editor on click
    run_button.on('click', function() {
      editor.focus();
    });

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
            minLines: kMinLines,
            maxLines: Math.max(Math.min(editor.session.getLength(), 15), kMinLines)
         });
      }
     
    };
    updateAceHeight();
    editor.getSession().on('change', updateAceHeight);
  });  
};

