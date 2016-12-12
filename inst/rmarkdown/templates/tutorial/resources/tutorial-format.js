

$(document).ready(function() {
  
  // sign up for tutor init event
  tutor.onInit(function() {
    
    var tocControls = $('<div class="toc-controls"></div>');
    var button = $('<button class="btn btn-light btn-sm"></button>');
    var icon = $('<i class="fa fa-refresh"></i>');
    button.append(icon);
    button.append("Restart Tutorial");
    button.on('click', function() {
      tutor.startOver();
    });
    tocControls.append(button);
    
    
    // append controls to toc
    $("#section-TOC").append(tocControls);
    
  });
  
 
  
  
});