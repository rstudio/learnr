
(function () {

  var $ = jQuery;

  // helper function to get the exercise container of an element
  function exerciseContainer(el) {
    return $(el).closest(".tutor-exercise");
  }

  // helper function to get the current label context
  function exerciseLabel(el) {
    return exerciseContainer(el).attr('data-label');
  }

  // initialize exercises
  function initializeExercises() {
    
    $(".tutor-exercise").each(function() {
      
      // alias exercise
      var exercise = $(this);
       
      // helper to create an id
      function create_id(suffix) {
        return "tutor-exercise-" + exercise.attr('data-label') + "-" + suffix;
      }
      
      // get all <pre class='text'> elements, get their code, then remove them
      var code = '';
      var code_blocks = exercise.children('pre[class="text"]');
      code_blocks.each(function() {
        var code_element = $(this).children('code');
        if (code_element.length > 0)
          code = code + code_element.text() + "\n";
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
      var run_button = $('<button class="btn btn-success btn-xs tutor-exercise-run action-button"></button>');
      run_button.attr('type', 'button');
      run_button.text('Run Code');
      run_button.attr('id', create_id('button'));
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
      
      // bind Cmd+Shift+Enter
      editor.commands.addCommand({
        name: "execute",
        bindKey: {win: "Ctrl+Shift+Enter", mac: "Command+Shift+Enter"},
        exec: function(editor) {
          run_button.trigger('click');
        }
      });
      
      // mange ace height as the document changes
      var updateAceHeight = function()  {
        editor.setOptions({
          minLines: 2,
          maxLines: Math.max(Math.min(editor.session.getLength(), 15), 2)
        });
      };
      updateAceHeight();
      editor.getSession().on('change', updateAceHeight);
    });
  }


  function registerShinyBindings() {
    
    // register a shiny input binding for code editors
    var exerciseInputBinding = new Shiny.InputBinding();
    $.extend(exerciseInputBinding, {
      
      find: function(scope) {
        return $(scope).find('.tutor-exercise-code-editor');
      },
      
      getValue: function(el) {
        
        // value object to return 
        var value = {};
        
        // get the code from the editor
        var editor = ace.edit($(el).attr('id'));
        value.code = editor.getSession().getValue();
        
        // get any setup or check chunks
        var label = exerciseLabel(el);
        function supportingCode(name) {
          var selector = '.tutor-exercise-support[data-label="' + label + '-' + name + '"]';
          var code = $(selector).children('pre').children('code');
          if (code.length > 0)
            return code.text();
          else
            return null;
        }
        value.setup = supportingCode("setup");
        value.check = supportingCode("check");
        
        // get the preserved chunk options (if any)
        var options_script = exerciseContainer(el).find('script[data-opts-chunk="1"]');
        if (options_script.length == 1)
          value.options = JSON.parse(options_script.text());
        else
          value.options = {};
        
        // return the value
        return value;
      },
      
      subscribe: function(el, callback) {
        this.executeButton(el).on('click.exerciseInputBinding', function() {
          callback(true);
        });
      },
      
      unsubscribe: function(el) {
        this.executeButton(el).off('.exerciseInputBinding');
      },
      
      executeButton: function(el) {
        var label = exerciseLabel(el);
        return $("#tutor-exercise-" + label + "-button");
      }
    });
    Shiny.inputBindings.register(exerciseInputBinding, 'tutor.exerciseInput');
    
    // register an output binding for exercise output
    var exerciseOutputBinding = new Shiny.OutputBinding();
    $.extend(exerciseOutputBinding, {
      
      find: function find(scope) {
        return $(scope).find('.tutor-exercise-output');
      },
      
      onValueError: function onValueError(el, err) {
       
        Shiny.unbindAll(el);
        this.renderError(el, err);
      },
      
      renderValue: function renderValue(el, data) {
    
        // remove default content (if any)
        this.outputFrame(el).children().not($(el)).remove();
        
        // render the content
        Shiny.renderContent(el, data);
      },
      
      showProgress: function (el, show) {
        var RECALCULATING = 'recalculating';
        if (show)
          this.outputFrame(el).addClass(RECALCULATING);
        else
          this.outputFrame(el).removeClass(RECALCULATING);
      },
      
      outputFrame: function(el) {
        return $(el).closest('.tutor-exercise-output-frame');
      }
    });
    Shiny.outputBindings.register(exerciseOutputBinding, 'tutor.exerciseOutput');
  }

  $(document).ready(function() {
    
    initializeExercises();
    
    registerShinyBindings();
    
  });

})();
