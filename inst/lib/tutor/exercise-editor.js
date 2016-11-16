

Tutor.prototype.$initializeExerciseEditors = function() {
  
  // alias this
  var thiz = this;

  // behavior constants
  var kMinLines = 3;

  // edit code within an ace editor
  function attachAceEditor(target, code) {
    var editor = ace.edit(target);
    editor.setHighlightActiveLine(false);
    editor.setShowPrintMargin(false);
    editor.setShowFoldWidgets(false);
    editor.renderer.setDisplayIndentGuides(false);
    editor.setTheme("ace/theme/textmate");
    editor.$blockScrolling = Infinity;
    editor.session.setMode("ace/mode/r");
    editor.session.getSelection().clearSelection();
    editor.setValue(code, -1);
    return editor;
  }

  // remove a solution for an exercise
  function removeSolution(exercise) {
    // destory clipboardjs object if we've got one
    var solutionButton = exercise.find('.btn-tutor-copy-solution');
    if (solutionButton.length > 0)
      solutionButton.data('clipboard').destroy();
      
    // destroy popover
    exercise.find('.btn-tutor-solution').popover('destroy');
  }

  // hide solutions when clicking outside exercises
  $(document).on('mouseup', function(ev) {
    var exercise = thiz.$exerciseContainer(ev.target);
    if (exercise.length === 0) {
      thiz.$forEachExercise(removeSolution);
    }
  });


  // add a solution for the specified exercise label
  function addSolution(exercise, panel_heading, editor) {

    // get label
    var label = exercise.attr('data-label');

    // see if there is a solution for this exercise
    var solution = thiz.$exerciseSupportCode(label + "-solution");
    if (solution) {
      
      // create solution buttion
      var button = $('<a class="btn btn-light btn-xs btn-tutor-solution"></a>');
      button.attr('role', 'button');
      button.attr('title', 'Solution');
      button.append($('<i class="fa fa-lightbulb-o"></i>'));
      button.append(' Solution'); 
      panel_heading.append(button);      
      
      // handle showing and hiding the popover
      button.on('click', function() {
        var visible = button.next('div.popover:visible').length > 0;
        if (!visible) {
          var popover = button.popover({
            placement: 'top',
            template: '<div class="popover tutor-solution-popover" role="tooltip">' + 
                      '<div class="arrow"></div>' + 
                      '<div class="popover-title tutor-panel-heading"></div>' + 
                      '<div class="popover-content"></div>' + 
                      '</div>',
            content: solution,
            trigger: "manual"
          });
          popover.on('inserted.bs.popover', function() {
            
            // get popover element
            var dataPopover = popover.data('bs.popover');
            var popoverTip = dataPopover.tip();
            var content = popoverTip.find('.popover-content');
            
            // adjust editor and container height
            var solutionEditor = attachAceEditor(content.get(0), solution);
            solutionEditor.setReadOnly(true);
            var lines = Math.max(solutionEditor.session.getLength(), kMinLines);
            solutionEditor.setOptions({
              minLines: lines
            });
            var height = lines * solutionEditor.renderer.lineHeight;
            content.css('height', height + 'px');
            
            // add copy button
            var popoverTitle = popoverTip.find('.popover-title');
            var copyButton = $('<a class="btn btn-light btn-xs btn-tutor-copy-solution pull-right"></a>');
            copyButton.append($('<i class="fa fa-copy"></i>'));
            copyButton.append(" Copy to Clipboard");
            popoverTitle.append(copyButton);
            var clipboard = new Clipboard(copyButton[0], {
              text: function(trigger) {
                return solutionEditor.getValue();
              }
            });
            clipboard.on('success', function(e) {
              removeSolution(exercise);
              editor.focus();
            });
            copyButton.data('clipboard', clipboard);
            
          });
          button.popover('show');
          
          // left position of popover and arrow
          var popoverElement = exercise.find('.tutor-solution-popover');
          popoverElement.css('left', '0');
          var popoverArrow = popoverElement.find('.arrow');
          popoverArrow.css('left', button.position().left + (button.outerWidth()/2) + 'px');

          // scroll into view if necessary
          thiz.$scrollIntoView(popoverElement);
        }
        else {
          removeSolution(exercise);
        }

        // always refocus editor
        editor.focus();
      });
    }
  }


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
          removeSolution(thiz.$exerciseContainer($(this)));
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
        removeSolution(exercise);
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
    var editor = attachAceEditor(code_id, code);
    
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
            minLines: kMinLines,
            maxLines: Math.max(Math.min(editor.session.getLength(), 15), kMinLines)
         });
      }
     
    };
    updateAceHeight();
    editor.getSession().on('change', updateAceHeight);

    // add solution button if necessary
    addSolution(exercise, panel_heading, editor);

  });  
};

