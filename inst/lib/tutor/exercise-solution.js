

Tutor.prototype.$initializeSolutions = function() {
  
  // alias this
  var thiz = this;
  
  // hide solutions when clicking outside exercises
  $(document).on('mouseup', function(ev) {
    var exercise = thiz.$exerciseContainer(ev.target);
    if (exercise.length === 0) {
      thiz.$forEachExercise(thiz.$removeSolution);
    }
  });
};


// add a solution for the specified exercise label
Tutor.prototype.$addSolution = function(exercise, panel_heading, editor) {

  // alias this
  var thiz = this;

  // get label
  var label = exercise.attr('data-label');

  // see if there is a solution for this exercise
  var hint = thiz.$exerciseSupportCode(label + "-hint");
  var solution = thiz.$exerciseSupportCode(label + "-solution");
  if (hint || solution) {
    
    // determine caption
    var caption = null;
    if (hint) {
      caption = "Hint";
      solution = hint;
    }
    else {
      caption = "Solution";
    }
    
    // create solution buttion
    var button = $('<a class="btn btn-light btn-xs btn-tutor-solution"></a>');
    button.attr('role', 'button');
    button.attr('title', caption);
    button.append($('<i class="fa fa-lightbulb-o"></i>'));
    button.append(' ' + caption); 
    panel_heading.append(button);      
    
    // handle showing and hiding the popover
    button.on('click', function() {
      var visible = button.next('div.popover:visible').length > 0;
      if (!visible) {
        var popover = button.popover({
          placement: 'top',
          template: '<div class="popover tutor-solution-popover" role="tooltip">' + 
                    '<div class="arrow"></div>' + 
                    '<div class="popover-title tutor-panel-heading"></div>' + 
                    '<div class="popover-content"></div>' + 
                    '</div>',
          content: solution,
          trigger: "manual"
        });
        popover.on('inserted.bs.popover', function() {
          
          // get popover element
          var dataPopover = popover.data('bs.popover');
          var popoverTip = dataPopover.tip();
          var content = popoverTip.find('.popover-content');
          
          // adjust editor and container height
          var solutionEditor = thiz.$attachAceEditor(content.get(0), solution);
          solutionEditor.setReadOnly(true);
          var lines = Math.max(solutionEditor.session.getLength(), thiz.kMinLines);
          solutionEditor.setOptions({
            minLines: lines
          });
          var height = lines * solutionEditor.renderer.lineHeight;
          content.css('height', height + 'px');
          
          // add copy button
          var popoverTitle = popoverTip.find('.popover-title');
          var copyButton = $('<a class="btn btn-light btn-xs ' + 
                             'btn-tutor-copy-solution pull-right"></a>');
          copyButton.append($('<i class="fa fa-copy"></i>'));
          copyButton.append(" Copy to Clipboard");
          popoverTitle.append(copyButton);
          var clipboard = new Clipboard(copyButton[0], {
            text: function(trigger) {
              return solutionEditor.getValue();
            }
          });
          clipboard.on('success', function(e) {
            thiz.$removeSolution(exercise);
            editor.focus();
          });
          copyButton.data('clipboard', clipboard);
          
        });
        button.popover('show');
        
        // left position of popover and arrow
        var popoverElement = exercise.find('.tutor-solution-popover');
        popoverElement.css('left', '0');
        var popoverArrow = popoverElement.find('.arrow');
        popoverArrow.css('left', button.position().left + (button.outerWidth()/2) + 'px');

        // scroll into view if necessary
        thiz.$scrollIntoView(popoverElement);
      }
      else {
        thiz.$removeSolution(exercise);
      }

      // always refocus editor
      editor.focus();
    });
  }
};



// remove a solution for an exercise
Tutor.prototype.$removeSolution = function(exercise) {
  // destory clipboardjs object if we've got one
  var solutionButton = exercise.find('.btn-tutor-copy-solution');
  if (solutionButton.length > 0)
    solutionButton.data('clipboard').destroy();
    
  // destroy popover
  exercise.find('.btn-tutor-solution').popover('destroy');
};



