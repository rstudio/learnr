

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
}

