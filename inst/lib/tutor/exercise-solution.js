

Tutor.prototype.$initializeExerciseSolutions = function() {
  
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

  // see if there is a single solution or hint for this exercise
  var solution = thiz.$exerciseSolutionCode(label);
  var hints = thiz.$exerciseHintsCode(label);
  
  // helper function to record solution/hint requests
  function recordHintRequest(index) {
    tutor.record(label, "exercise_hint", {
      type: solution !== null ? "solution" : "hint",
      index: hintIndex
    });
  }

  // if we have a solution or a hint
  if (solution || hints) {
    
    // determine caption
    var caption = null;
    if (solution) {
      caption = "Solution";
    }
    else {
      if (hints.length > 1)
        caption = "Hints";
      else 
        caption = "Hint";
    }
    
    // determine editor lines
    var editorLines = thiz.kMinLines;
    if (solution)
      editorLines = Math.max(thiz.$countLines(solution), editorLines);
    else {
      for (var i = 0; i<hints.length; i++)
        editorLines = Math.max(thiz.$countLines(hints[i]), editorLines);
    }
    
    // track hint index
    var hintIndex = 0;
    
    // create solution buttion
    var button = $('<a class="btn btn-light btn-xs btn-tutor-solution"></a>');
    button.attr('role', 'button');
    button.attr('title', caption);
    button.append($('<i class="fa fa-lightbulb-o"></i>'));
    button.append(' ' + caption); 
    panel_heading.append(button);      
    
    // handle showing and hiding the popover
    button.on('click', function() {
      
      // record the request
      recordHintRequest(hintIndex);
      
      // determine solution text
      var solutionText = solution !== null ? solution : hints[hintIndex];
 
      var visible = button.next('div.popover:visible').length > 0;
      if (!visible) {
        var popover = button.popover({
          placement: 'top',
          template: '<div class="popover tutor-solution-popover" role="tooltip">' + 
                    '<div class="arrow"></div>' + 
                    '<div class="popover-title tutor-panel-heading"></div>' + 
                    '<div class="popover-content"></div>' + 
                    '</div>',
          content: solutionText,
          trigger: "manual"
        });
        popover.on('inserted.bs.popover', function() {
          
          // get popover element
          var dataPopover = popover.data('bs.popover');
          var popoverTip = dataPopover.tip();
          var content = popoverTip.find('.popover-content');
          
          // adjust editor and container height
          var solutionEditor = thiz.$attachAceEditor(content.get(0), solutionText);
          solutionEditor.setReadOnly(true);
          solutionEditor.setOptions({
            minLines: editorLines
          });
          var height = editorLines * solutionEditor.renderer.lineHeight;
          content.css('height', height + 'px');
          
          // get title panel
          var popoverTitle = popoverTip.find('.popover-title');
          
          // add hints button if we have > 1 hint
          if (hints.length > 0) {
            var nextHintButton = $('<a class="btn btn-light btn-xs btn-tutor-next-hint"></a>');
            nextHintButton.append("Next Hint ");
            nextHintButton.append($('<i class="fa fa-angle-double-right"></i>'));
            nextHintButton.on('click', function() {
              hintIndex = hintIndex + 1;
              solutionEditor.setValue(hints[hintIndex], -1);
              if (hintIndex == (hints.length-1))
                nextHintButton.addClass('disabled');
              recordHintRequest(hintIndex);
            });
            if (hintIndex == (hints.length-1))
              nextHintButton.addClass('disabled');
            popoverTitle.append(nextHintButton);
          }
          
          // add copy button
          var copyButton = $('<a class="btn btn-info btn-xs ' + 
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



