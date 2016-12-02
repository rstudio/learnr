
/* Tutor construction and initialization */

function Tutor() {
  
  // Alias this
  var thiz = this;
  
  // Function to record an event
  this.recordEvent = function(label, event, data) {
    var params = {
      label: label,
      event: event,
      data: data
    };
    thiz.$serverRequest("record_event", params, null);
  };
  
  // Function to start over
  this.startOver = function() {
    thiz.$removeState(function() {
      thiz.$serverRequest("remove_state", null, function() {
        window.location.replace(window.location.href);
      });
    });
  };
  
  // Initialization
  thiz.$initializeVideos();  
  thiz.$initializeExercises();
  thiz.$initializeServer();
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
    // wait for shiny config to be available (required for $serverRequest)
    if (typeof ((Shiny || {}).shinyapp || {}).config !== "undefined")  {
      thiz.$serverRequest("initialize", { location: window.location }, 
        function(identifiers) {
          // initialize storage then restore state
          thiz.$initializeStorage(identifiers, function(objects) {
            thiz.$restoreState(objects);
          });
        }
      );
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







