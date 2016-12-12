

$(document).ready(function() {
  
  // sign up for tutor init event
  tutor.onInit(function() {
    
    var tocControls = $('<div class="toc-controls"></div>');
    var button = $('<button class="btn btn-light btn-sm"></button>');
    var icon = $('<i class="fa fa-refresh"></i>');
    button.append(icon);
    button.append("Start Over");
    button.on('click', function() {
      if (window.confirm("Are you sure you want to start over? (all exercise progress will be reset)"))
        tutor.startOver();
    });
    tocControls.append(button);
    
    
    // append controls to toc
    $("#section-TOC").append(tocControls);
    
  });
  
 
  
  
});