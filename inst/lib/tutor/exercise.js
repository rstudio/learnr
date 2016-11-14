

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

// get the exercise container of an element
Tutor.prototype.$exerciseContainer = function(el) {
  return $(el).closest(".tutor-exercise");
};

// show progress for exercise
Tutor.prototype.$showExerciseProgress = function(el, show) {
  var exercise = this.$exerciseContainer(el);
  var outputFrame = exercise.children('.tutor-exercise-output-frame');
  var runIcon = exercise.find('.btn-tutor-run-code').children('i');
  var spinner = 'fa-spinner fa-spin fa-fw';
  if (show) {
    outputFrame.addClass('recalculating');
    runIcon.removeClass('fa-play');
    runIcon.addClass(spinner);
  }
  else {
    outputFrame.removeClass('recalculating');
    runIcon.addClass('fa-play');
    runIcon.removeClass(spinner);
  }
};