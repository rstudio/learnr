
Tutor.prototype.$initializeExerciseEvaluation = function() {
  
  // alias this
  var thiz = this;
  
  // get the current label context of an element
  function exerciseLabel(el) {
    return thiz.$exerciseContainer(el).attr('data-label');
  }
  
  // ensure that the exercise containing this element is fully visible
  function ensureExerciseVisible(el) {
    // convert to containing exercise element
    var exerciseEl = thiz.$exerciseContainer(el)[0];

    // ensure visibility
    thiz.$scrollIntoView(exerciseEl);
  }
  
  // register a shiny input binding for code editors
  var exerciseInputBinding = new Shiny.InputBinding();
  $.extend(exerciseInputBinding, {
    
    find: function(scope) {
      return $(scope).find('.tutor-exercise-code-editor');
    },
    
    getValue: function(el) {
      
      // return null if we haven't been clicked and this isn't a restore
      if (!this.clicked && !this.restore)
        return null;
      
      // value object to return 
      var value = {};
      
      // get the label
      value.label = exerciseLabel(el);
      
      // get the code from the editor
      var editor = ace.edit($(el).attr('id'));
      value.code = editor.getSession().getValue();
      
      // get the preserved chunk options (if any)
      var options_script = thiz.$exerciseContainer(el).find('script[data-opts-chunk="1"]');
      if (options_script.length == 1)
        value.options = JSON.parse(options_script.text());
      else
        value.options = {};
      
      // restore flag
      value.restore = this.restore;

      // get any setup, solution, or check chunks
      
      // setup
      var label = exerciseLabel(el);
      if (value.options["exercise.setup"])
        value.setup = thiz.$exerciseSupportCode(value.options["exercise.setup"]);     
      else
        value.setup = thiz.$exerciseSupportCode(label + "-setup");
        
      // solution
      value.solution = thiz.$exerciseSupportCode(label + "-solution");  
        
      // check
      if (this.check)
        value.check = thiz.$exerciseCheckCode(label);

      // some randomness to ensure we re-execute on button clicks
      value.timestamp = new Date().getTime();
      
      // return the value
      return value;
    },
    
    subscribe: function(el, callback) {
      var binding = this;
      this.runButtons(el).on('click.exerciseInputBinding', function(ev) {
        binding.restore = false;
        binding.clicked = true;
        binding.check = ev.target.hasAttribute('data-check');
        callback(true);
      });
      $(el).on('restore.exerciseInputBinding', function(ev) {
        binding.restore = true;
        binding.clicked = false;
        binding.check = false;
        callback(true);
      });
    },
    
    unsubscribe: function(el) {
      this.runButtons(el).off('.exerciseInputBinding');
    },
    
    runButtons: function(el) {
      var exercise = thiz.$exerciseContainer(el);
      return exercise.find('.btn-tutor-run');
    },
    
    restore: false,
    clicked: false,
    check: false
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
      
      // bind bootstrap tables if necessary
      if (window.bootstrapStylePandocTables)
        window.bootstrapStylePandocTables();
      
      // bind paged tables if necessary
      if (window.PagedTableDoc)
        window.PagedTableDoc.initAll();
      
      // see if this was restored
      var restored = data.indexOf("<!-- tutor-exercise-output-restored -->") != -1;
      
      // scroll exercise fully into view if necessary
      if (!restored)
        ensureExerciseVisible(el);
    },
    
    showProgress: function(el, show) {
      thiz.$showExerciseProgress(el, null, show);
    },
    
    outputFrame: function(el) {
      return $(el).closest('.tutor-exercise-output-frame');
    }
  });
  Shiny.outputBindings.register(exerciseOutputBinding, 'tutor.exerciseOutput');
};
