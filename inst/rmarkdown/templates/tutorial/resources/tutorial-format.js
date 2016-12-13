

$(document).ready(function() {
  
  // update toc w/ section completed events
  function showProgress(section) {
    
    // get the data-unique name from inside the section
    var dataUnique = section.children('div[data-unique]');
    if (dataUnique.length > 0) {
       // find toc entry w/ this data-unique and add a check to it
       dataUnique = dataUnique.attr('data-unique');
       var tocEntry = $("#section-TOC").find('li[data-unique="' + dataUnique + '"]');
       var check = $('<div class="pull-right"></div>');
       var icon = $('<i class="fa fa-check progress-check"></i>');
       check.append(icon);
       check.append("&nbsp;");
       tocEntry.append(check);
    }
  }
  
  // add start over button to toc
  function addStartOverButton() {
    
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
  }
  
  // initialize components within tutor.onInit event
  tutor.onInit(function() {
    
    // show progress for section completed events
    tutor.onProgress(function(progressEvent) {
      if (progressEvent.event === "section_completed")
        showProgress($(progressEvent.element));
    });
    
    // add a start-over button to the TOC
    addStartOverButton();
  });
  
});