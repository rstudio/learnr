

Tutor.prototype.$exerciseEditor = function(label) {
  return this.$exerciseForLabel(label).find('.tutor-exercise-code-editor');
};

Tutor.prototype.$initializeExerciseEditors = function() {
  
  // alias this
  var thiz = this;

  this.$forEachExercise(function(exercise) {
    
    // capture label and caption
    var label = exercise.attr('data-label');
    var caption = exercise.attr('data-caption');

    // helper to create an id
    function create_id(suffix) {
      return "tutor-exercise-" + label + "-" + suffix;
    } 


    // when we receive focus hide solutions in other exercises
    exercise.on('focusin', function() {
      $('.btn-tutor-solution').each(function() {
        if (exercise.has($(this)).length === 0)
          thiz.$removeSolution(thiz.$exerciseContainer($(this)));
      });
    });
     
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
    for (var i=lines; i<thiz.kMinLines;i++)
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
    panel_heading.text(caption);
    input_div.append(panel_heading);

    // create body
    var panel_body = $('<div class="panel-body"></div>');
    input_div.append(panel_body);
    
    // function to add a submit button
    function add_submit_button(icon, style, text, check) {
      var button = $('<a class="btn ' + style + ' btn-xs btn-tutor-run ' + 
                       'pull-right"></a>');
      button.append($('<i class="fa ' + icon + '"></i>'));
      button.attr('type', 'button');
      button.append(' ' + text);
      var isMac = navigator.platform.toUpperCase().indexOf('MAC') >= 0;
      var title = text;
      if (!check)
        title = title + " (" + (isMac ? "Cmd" : "Ctrl") + "+Shift+Enter)";
      button.attr('title', title);
      if (check)
        button.attr('data-check', '1');
      button.attr('data-icon', icon);
      button.on('click', function() {
        thiz.$removeSolution(exercise);
        thiz.$showExerciseProgress(output_frame, button, true);
      });
      panel_heading.append(button);
      return button;
    }
    
    // create submit answer button if checks are enabled
    if (thiz.$exerciseCheckCode(label) !== null)
      add_submit_button("fa-check-square-o", "btn-primary", "Submit Answer", true);
    
    // create run button
    var run_button = add_submit_button("fa-play", "btn-success", "Run Code", false);
    
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
    var editor = thiz.$attachAceEditor(code_id, code);
    
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
    
    // re-focus the editor on run button click
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
            minLines: thiz.kMinLines,
            maxLines: Math.max(Math.min(editor.session.getLength(), 15), 
                               thiz.kMinLines)
         });
      }
     
    };
    updateAceHeight();
    editor.getSession().on('change', updateAceHeight);

    // add solution button if necessary
    thiz.$addSolution(exercise, panel_heading, editor);

  });  
};

