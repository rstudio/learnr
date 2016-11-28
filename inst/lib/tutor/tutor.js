
/* Tutor construction and initialization */

function Tutor() {
  
  // Initialize DOM/members
  this.$initializeVideos();  
  this.$initializeExercises();
  
  // Function to record a user action
  this.record = function(label, action, data) {
    var params = {
      label: label,
      action: action,
      data: data
    };
    this.$serverRequest("record", params, null);
  };
  
  // one-shot function to initialize server (wait for Shiny.shinyapp
  // to be available fore attempting to call server)
  var thiz = this;
  function initializeServer() {
    if (typeof Shiny !== "undefined" && 
        typeof Shiny.shinyapp !== "undefined") {
      thiz.$serverRequest("initialize", null, function(data) {
        console.log("tutorial_id: " + data.identifiers.tutorial_id);
        console.log("user_id: " + data.identifiers.user_id);
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

}

$(document).ready(function() {
  
  // create tutor
  window.tutor = new Tutor();

});


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







