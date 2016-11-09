
/* Tutor construction and initialization */

function Tutor() {
  this.$initializeVideos();  
  this.$initializeExercises();
}

$(document).ready(function() {
  new Tutor();
});



//* Tutor shared utility functions */

Tutor.prototype.$serverRequest = function (type, params, success) {
  $.get("session/" + Shiny.shinyapp.config.sessionId + 
        "/dataobj/" + type + "?w=" + Shiny.shinyapp.config.workerId, 
        params)
    .done(function(data) {
      success(data);
    });
};







