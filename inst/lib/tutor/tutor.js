
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


Tutor.prototype.$scrollIntoView = function(element) {
  var element = $(element);
  var rect = element[0].getBoundingClientRect();
  if (rect.top < 0 || rect.bottom > $(window).height()) {
    if (element[0].scrollIntoView) {
      element[0].scrollIntoView(false);
      document.body.scrollTop += 20;
    }  
  }
};








