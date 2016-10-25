
(function () {

  var $ = jQuery;

  // initialize exercises
  function initializeExercises() {
    
    $(".tutor-exercise").each(function() {
      
      // alias exercise
      var exercise = $(this);
       
      // helper to create an id
      function create_id(suffix) {
        return "tutor-exercise-" + exercise.attr('data-label') + "-" + suffix;
      }
      
      // get code then remove the code element
      var code_element = exercise.children('pre').children('code');
      var code = code_element.text() + "\n";
      code_element.parent().remove();
      
      // wrap the remaining elements in an output frame div
      exercise.wrapInner('<div class="tutor-exercise-output-frame"></div>');
      var output_frame = exercise.children('.tutor-exercise-output-frame');
      
      // create input div
      var input_div = $('<div class="tutor-exercise-input"></div>');
      input_div.attr('id', create_id('input'));
      
      // create action button
      // <button id="foo" type="button" class="btn btn-default action-button"></button>
      var run_button = $('<button class="btn btn-success action-button"></button>');
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
          maxLines: Math.max(editor.session.getLength(), 2)
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
        var editor = ace.edit($(el).attr('id'));
        return editor.getSession().getValue();
      },
      
      subscribe: function(el, callback) {
        var editor = ace.edit($(el).attr('id'));
        editor.getSession().on("change", function () {
          callback(true);
        });
      },
      
      unsubscribe: function(el) {
        var editor = ace.edit($(el).attr('id'));
        editor.getSession().removeAllListeners('change');
      },
      
      receiveMessage: function (el, data) {
        
      },
    
      getState: function (el, data) {
        
      },

      getRatePolicy: function () {
        return null;
      },
      
      initialize: function (el) {
      
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
