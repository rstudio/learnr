
/* Tutor construction and initialization */

function Tutor() {
  
  // Function to record an event
  this.record_event = function(label, event, data) {
    var params = {
      label: label,
      event: event,
      data: data
    };
    this.$serverRequest("record_event", params, null);
  };
  
  // Function to notify the server of a question submission
  this.questionSubmission = function(label, question, answers, correct) {
    var params = {
      label: label,
      question: question,
      answers: answers,
      correct: correct
    };
    this.$serverRequest("question_submission", params, null);
  };
  
  // Initialization
  this.$initializeVideos();  
  this.$initializeExercises();
  this.$initializeServer();
}


$(document).ready(function() {
  window.tutor = new Tutor();
});


//* Tutor initialization */

Tutor.prototype.$initializeServer = function() {
  
  // one-shot function to initialize server (wait for Shiny.shinyapp
  // to be available before attempting to call server)
  var thiz = this;
  function initializeServer() {
    if (typeof Shiny !== "undefined" && typeof Shiny.shinyapp !== "undefined") {
      thiz.$serverRequest("initialize", { location: window.location }, function(data) {
        // now that the server is initialized we can restore state
        thiz.$restoreState();
      });
    }
    else {
      setTimeout(function(){
        initializeServer();
      },250);
    }
  }
  
  // call initialize function
  initializeServer();
};

//* Tutor shared utility functions */

Tutor.prototype.$serverRequest = function (type, data, success) {
  return $.ajax({
    type: "POST",
    url: "session/" + Shiny.shinyapp.config.sessionId + 
           "/dataobj/" + type + "?w=" + Shiny.shinyapp.config.workerId,
    contentType: "application/json",
    data: JSON.stringify(data),
    dataType: "json",
    success: success
  });
};

Tutor.prototype.$scrollIntoView = function(element) {
  element = $(element);
  var rect = element[0].getBoundingClientRect();
  if (rect.top < 0 || rect.bottom > $(window).height()) {
    if (element[0].scrollIntoView) {
      element[0].scrollIntoView(false);
      document.body.scrollTop += 20;
    }  
  }
};

Tutor.prototype.$countLines = function(str) { 
  return str.split(/\r\n|\r|\n/).length; 
};







