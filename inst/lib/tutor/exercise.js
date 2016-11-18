

//* Exercise initialization */

Tutor.prototype.$initializeExercises = function() {
  
  this.$initializeExerciseEditors();
  this.$initializeExerciseSolutions();
  this.$initializeExerciseEvaluation();
  
};

//* Exercise shared utility functions */

Tutor.prototype.$forEachExercise = function(operation) {
  return $(".tutor-exercise").each(function() {
    var exercise = $(this);
    operation(exercise);
  });
};

Tutor.prototype.$exerciseSupportCode = function(label) {
  var selector = '.tutor-exercise-support[data-label="' + label + '"]';
  var code = $(selector).children('pre').children('code');
  if (code.length > 0)
    return code.text();
  else
    return null;
};

Tutor.prototype.$exerciseSolutionCode = function(label) {
  return this.$exerciseSupportCode(label + "-solution");
};

Tutor.prototype.$exerciseCheckCode = function(label) {
  return this.$exerciseSupportCode(label + "-check");
};

Tutor.prototype.$exerciseHintsCode = function(label) {
  
  // look for a single hint
  var hint = this.$exerciseSupportCode(label + "-hint");
  if (hint !== null)
    return [hint];
    
  // look for a sequence of hints
  var hints = [];
  var index = 1;
  while(true) {
    var hintLabel = label + "-hint-" + index++;
    hint = this.$exerciseSupportCode(hintLabel);
    if (hint !== null)
      hints.push(hint);
    else
      break;
  }
  
  // return what we have (null if empty)
  if (hints.length > 0)
    return hints;
  else
    return null;
};

// get the exercise container of an element
Tutor.prototype.$exerciseContainer = function(el) {
  return $(el).closest(".tutor-exercise");
};

// show progress for exercise
Tutor.prototype.$showExerciseProgress = function(el, button, show) {
  
  // references to various UI elements
  var exercise = this.$exerciseContainer(el);
  var outputFrame = exercise.children('.tutor-exercise-output-frame');
  var runButtons = exercise.find('.btn-tutor-run');
  
  // show/hide progress UI
  var spinner = 'fa-spinner fa-spin fa-fw';
  if (show) {
    outputFrame.addClass('recalculating');
    runButtons.addClass('disabled');
    if (button !== null) {
      var runIcon = button.children('i');
      runIcon.removeClass(button.attr('data-icon'));
      runIcon.addClass(spinner);
    }
  }
  else {
    outputFrame.removeClass('recalculating');
    runButtons.removeClass('disabled');
    runButtons.each(function() {
      var button = $(this);
      var runIcon = button.children('i');
      runIcon.addClass(button.attr('data-icon'));
      runIcon.removeClass(spinner);
    });
  }
};


// edit code within an ace editor
Tutor.prototype.$attachAceEditor = function(target, code) {
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
};

// behavior constants
Tutor.prototype.kMinLines = 3;

