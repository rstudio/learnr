

$(document).ready(function() {

  // transform the DOM here, e.g.
  var container = $('<div class="robby-container"></div>');
  $(document.body).wrapInner(container);
  
  
  // update navigation w/ progress
  function showProgress(section) {
    
    
  }

  // initialize components within tutor.onInit event
  tutor.onInit(function() {
    
    // show progress for section completed events
    tutor.onProgress(function(progressEvent) {
      if (progressEvent.event === "section_completed")
        showProgress($(progressEvent.element));
    });
    
  });
  
});