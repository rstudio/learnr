

//* Exercise initialization */

Tutor.prototype.$initializeExercises = function() {
  
  this.$initializeExerciseEditors();
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

Tutor.prototype.$exerciseCheckCode = function(label) {
  return this.$exerciseSupportCode(label + "-check");
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

// behavior constants
Tutor.prototype.kMinLines = 3;

