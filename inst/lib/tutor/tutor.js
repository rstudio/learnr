
/* Tutor construction and initialization */

$(document).ready(function() {
  window.tutor = new Tutor();
});

function Tutor() {
  
  // Alias this
  var thiz = this;
  
  // API: subscribe to progress events
  this.onProgress = function(handler) {
    this.$progressCallbacks.add(handler);
  };
  
  
  // API: Start the tutorial over
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


/* Progress callbacks */

Tutor.prototype.$progressCallbacks = $.Callbacks();

Tutor.prototype.$progressEvents = [];
  
Tutor.prototype.$fireProgress = function(label, event, correct) {
  
  // Alias this
  var thiz = this;
  
  // find element
  var element = $('.tutor-exercise[data-label="' + label + '"]')
             .add('.quiz[data-label="' + label + '"]');
  
   if (element.length > 0) {
  
    // create event
    var progressEvent = {
      element: element.get(0),
      label: label,
      event: event,
      correct: correct
    };
    
    // record it
    this.$progressEvents.push(progressEvent);
  
    // fire event
    try {
      thiz.$progressCallbacks.fire(progressEvent);
    } catch (e) {
      console.log(e);
    }
    
     // synthesize higher level section completed event
     
  }
  
 
  
  
};  
  
Tutor.prototype.$initializeProgress = function(progress_events) {
 
  // Alias this
  var thiz = this;
  
  // replay progress messages from previous state
  for (var i = 0; i<progress_events.length; i++) {
    var progress = progress_events[i];
    progress.label = progress.label[0];
    progress.event = progress.event[0];
    if (progress.correct !== null)
      progress.correct = progress.correct[0];
    thiz.$fireProgress(progress.label, progress.event, progress.correct);
  }
  
  // handle susequent progress messages
  Shiny.addCustomMessageHandler("tutor.progress_event", function(progress) {
    thiz.$fireProgress(progress.label, progress.event, progress.correct);
  });
}; 
  

/* Shared utility functions */

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

 // Record an event
Tutor.prototype.$recordEvent = function(label, event, data) {
  var params = {
    label: label,
    event: event,
    data: data
  };
  this.$serverRequest("record_event", params, null);
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




/* Videos */

Tutor.prototype.$initializeVideos = function() {
  
  // regexes for video types
  var youtubeRegex = /^.*(youtu.be\/|v\/|u\/\w\/|embed\/|watch\?v=|\&v=)([^#\&\?]*).*/;
  var vimeoRegex = /(?:vimeo)\.com.*(?:videos|video|channels|)\/([\d]+)/i;
  
  // check a url for a video
  function isVideo(src) {
    return src.match(youtubeRegex) || src.match(vimeoRegex);
  }
  
  // function to normalize a video src url (web view -> embed)
  function normalizeVideoSrc(src) {
    
    // youtube
    var youtubeMatch = src.match(youtubeRegex);
    if (youtubeMatch)
      return "https://www.youtube.com/embed/" + youtubeMatch[2];
   
    // vimeo
    var vimeoMatch = src.match(vimeoRegex);
    if (vimeoMatch)
      return "https://player.vimeo.com/video/" + vimeoMatch[1];

    // default to reflecting src back      
    return src;
  }
  
  // function to set the width and height for the container conditioned on
  // any user-specified height and width
  function setContainerSize(container, width, height) {
    
    // default ratio
    var aspectRatio = 9 / 16;
    
    // default width to 100% if not specified
    if (!width)
      width = "100%";
    
    // percentage based width
    if (width.slice(-1) == "%") {
      
      container.css('width', width);
      if (!height) {
        height = 0;
        var paddingBottom = (parseFloat(width) * aspectRatio) + '%';
        container.css('padding-bottom', paddingBottom);
      }
      container.css('height', height);
    }
    // other width unit
    else {
      // add 'px' if necessary
      if ($.isNumeric(width))
        width = width + "px";
      container.css('width', width);
      if (!height)
        height = (parseFloat(width) * aspectRatio) + 'px';
      container.css('height', height);
    }
  }
  
  // inspect all images to see if they contain videos
  $("img").each(function() {
    
    // skip if this isn't a video
    if (!isVideo($(this).attr('src')))
      return;
      
    // hide while we process
    $(this).css('display', 'none');

    // collect various attributes
    var width = $(this).get(0).style.width;
    var height = $(this).get(0).style.height;
    $(this).css('width', '').css('height', '');
    var attrs = {};
    $.each(this.attributes, function(idex, attr) {
      if (attr.nodeName == "width")
        width = String(attr.nodeValue);
      else if (attr.nodeName == "height")
        height = String(attr.nodeValue);
      else if (attr.nodeName == "src")
        attrs.src = normalizeVideoSrc(attr.nodeValue);
      else
        attrs[attr.nodeName] = attr.nodeValue;
    });
    
    // create and initialize iframe
    $(this).replaceWith(function() {
      var iframe = $('<iframe/>', attrs);
      iframe.addClass('tutor-video');
      iframe.attr('allowfullscreen', '');
      iframe.css('display', '');
      var container = $('<div class="tutor-video-container"></div>');
      setContainerSize(container, width, height);
      container.append(iframe);
      return container;
    });
  });
};



/* Exercise initialization and shared utility functions */ 

Tutor.prototype.$initializeExercises = function() {
  
  this.$initializeExerciseEditors();
  this.$initializeExerciseSolutions();
  this.$initializeExerciseEvaluation();
  
};

Tutor.prototype.$exerciseForLabel = function(label) {
  return $('.tutor-exercise[data-label="' + label + '"]');
};

Tutor.prototype.$forEachExercise = function(operation) {
  return $(".tutor-exercise").each(function() {
    var exercise = $(this);
    operation(exercise);
  });
};

Tutor.prototype.$exerciseSupportCode = function(label) {
  var selector = '.tutor-exercise-support[data-label="' + label + '"]';
  var code = $(selector).children('pre').children('code');
  if (code.length > 0)
    return code.text();
  else
    return null;
};

Tutor.prototype.$exerciseSolutionCode = function(label) {
  return this.$exerciseSupportCode(label + "-solution");
};

Tutor.prototype.$exerciseCheckCode = function(label) {
  return this.$exerciseSupportCode(label + "-check");
};

Tutor.prototype.$exerciseHintsCode = function(label) {
  
  // look for a single hint
  var hint = this.$exerciseSupportCode(label + "-hint");
  if (hint !== null)
    return [hint];
    
  // look for a sequence of hints
  var hints = [];
  var index = 1;
  while(true) {
    var hintLabel = label + "-hint-" + index++;
    hint = this.$exerciseSupportCode(hintLabel);
    if (hint !== null)
      hints.push(hint);
    else
      break;
  }
  
  // return what we have (null if empty)
  if (hints.length > 0)
    return hints;
  else
    return null;
};

// get the exercise container of an element
Tutor.prototype.$exerciseContainer = function(el) {
  return $(el).closest(".tutor-exercise");
};

// show progress for exercise
Tutor.prototype.$showExerciseProgress = function(label, button, show) {
  
  // references to various UI elements
  var exercise = this.$exerciseForLabel(label);
  var outputFrame = exercise.children('.tutor-exercise-output-frame');
  var runButtons = exercise.find('.btn-tutor-run');
  
  // if the button is "run" then use the run button
  if (button === "run")
    button = exercise.find('.btn-tutor-run').last();
  
  // show/hide progress UI
  var spinner = 'fa-spinner fa-spin fa-fw';
  if (show) {
    outputFrame.addClass('recalculating');
    runButtons.addClass('disabled');
    if (button !== null) {
      var runIcon = button.children('i');
      runIcon.removeClass(button.attr('data-icon'));
      runIcon.addClass(spinner);
    }
  }
  else {
    outputFrame.removeClass('recalculating');
    runButtons.removeClass('disabled');
    runButtons.each(function() {
      var button = $(this);
      var runIcon = button.children('i');
      runIcon.addClass(button.attr('data-icon'));
      runIcon.removeClass(spinner);
    });
  }
};


// behavior constants
Tutor.prototype.kMinLines = 3;

// edit code within an ace editor
Tutor.prototype.$attachAceEditor = function(target, code) {
  var editor = ace.edit(target);
  editor.setHighlightActiveLine(false);
  editor.setShowPrintMargin(false);
  editor.setShowFoldWidgets(false);
  editor.renderer.setDisplayIndentGuides(false);
  editor.setTheme("ace/theme/textmate");
  editor.$blockScrolling = Infinity;
  editor.session.setMode("ace/mode/r");
  editor.session.getSelection().clearSelection();
  editor.setValue(code, -1);
  return editor;
};


/* Exercise editor */

Tutor.prototype.$exerciseEditor = function(label) {
  return this.$exerciseForLabel(label).find('.tutor-exercise-code-editor');
};

Tutor.prototype.$initializeExerciseEditors = function() {
  
  // alias this
  var thiz = this;

  this.$forEachExercise(function(exercise) {
    
    // capture label and caption
    var label = exercise.attr('data-label');
    var caption = exercise.attr('data-caption');

    // helper to create an id
    function create_id(suffix) {
      return "tutor-exercise-" + label + "-" + suffix;
    } 


    // when we receive focus hide solutions in other exercises
    exercise.on('focusin', function() {
      $('.btn-tutor-solution').each(function() {
        if (exercise.has($(this)).length === 0)
          thiz.$removeSolution(thiz.$exerciseContainer($(this)));
      });
    });
     
    // get all <pre class='text'> elements, get their code, then remove them
    var code = '';
    var code_blocks = exercise.children('pre.text, pre.lang-text');
    code_blocks.each(function() {
      var code_element = $(this).children('code');
      if (code_element.length > 0)
        code = code + code_element.text();
      else 
        code = code + $(this).text();
    });
    code_blocks.remove();
    // ensure a minimum of 3 lines
    var lines = code.split(/\r\n|\r|\n/).length;
    for (var i=lines; i<thiz.kMinLines;i++)
      code = code + "\n";
        
    
    // get the knitr options script block and detach it (will move to input div)
    var options_script = exercise.children('script[data-opts-chunk="1"]').detach();
    
    // wrap the remaining elements in an output frame div
    exercise.wrapInner('<div class="tutor-exercise-output-frame"></div>');
    var output_frame = exercise.children('.tutor-exercise-output-frame');
    
    // create input div
    var input_div = $('<div class="tutor-exercise-input panel panel-default"></div>');
    input_div.attr('id', create_id('input'));

    // creating heading
    var panel_heading = $('<div class="panel-heading tutor-panel-heading"></div>');
    panel_heading.text(caption);
    input_div.append(panel_heading);

    // create body
    var panel_body = $('<div class="panel-body"></div>');
    input_div.append(panel_body);
    
    // function to add a submit button
    function add_submit_button(icon, style, text, check) {
      var button = $('<a class="btn ' + style + ' btn-xs btn-tutor-run ' + 
                       'pull-right"></a>');
      button.append($('<i class="fa ' + icon + '"></i>'));
      button.attr('type', 'button');
      button.append(' ' + text);
      var isMac = navigator.platform.toUpperCase().indexOf('MAC') >= 0;
      var title = text;
      if (!check)
        title = title + " (" + (isMac ? "Cmd" : "Ctrl") + "+Shift+Enter)";
      button.attr('title', title);
      if (check)
        button.attr('data-check', '1');
      button.attr('data-icon', icon);
      button.on('click', function() {
        thiz.$removeSolution(exercise);
        thiz.$showExerciseProgress(label, button, true);
      });
      panel_heading.append(button);
      return button;
    }
    
    // create submit answer button if checks are enabled
    if (thiz.$exerciseCheckCode(label) !== null)
      add_submit_button("fa-check-square-o", "btn-primary", "Submit Answer", true);
    
    // create run button
    var run_button = add_submit_button("fa-play", "btn-success", "Run Code", false);
    
    // create code div and add it to the input div
    var code_div = $('<div class="tutor-exercise-code-editor"></div>');
    var code_id = create_id('code-editor');
    code_div.attr('id', code_id);
    panel_body.append(code_div);
    
    // add the knitr options script to the input div
    panel_body.append(options_script);
    
    // prepend the input div to the exercise container
    exercise.prepend(input_div);
    
    // create an output div and append it to the output_frame
    var output_div = $('<div class="tutor-exercise-output"></div>');
    output_div.attr('id', create_id('output'));
    output_frame.append(output_div);
      
    // activate the ace editor
    var editor = thiz.$attachAceEditor(code_id, code);
    
    // bind execution keys 
    function bindExecutionKey(name, key) {
      var macKey = key.replace("Ctrl+", "Command+");
      editor.commands.addCommand({
        name: name,
        bindKey: {win: key, mac: macKey},
        exec: function(editor) {
          run_button.trigger('click');
        }
      });
    }
    bindExecutionKey("execute1", "Ctrl+Enter");
    bindExecutionKey("execute2", "Ctrl+Shift+Enter");
    
    // re-focus the editor on run button click
    run_button.on('click', function() {
      editor.focus();
    });

    // mange ace height as the document changes
    var updateAceHeight = function()  {
      var lines = exercise.attr('data-lines');
      if (lines && (lines > 0)) {
         editor.setOptions({
            minLines: lines,
            maxLines: lines
         });
      } else {
         editor.setOptions({
            minLines: thiz.kMinLines,
            maxLines: Math.max(Math.min(editor.session.getLength(), 15), 
                               thiz.kMinLines)
         });
      }
     
    };
    updateAceHeight();
    editor.getSession().on('change', updateAceHeight);

    // add solution button if necessary
    thiz.$addSolution(exercise, panel_heading, editor);

  });  
};

/* Exercise solutions */

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

  // solution/hints (in the presence of hints convert solution to last hint)
  var solution = thiz.$exerciseSolutionCode(label);
  var hints = thiz.$exerciseHintsCode(label);
  if (hints !== null && solution !== null) {
    hints.push(solution);
    solution = null;
  }
  
  // helper function to record solution/hint requests
  function recordHintRequest(index) {
    thiz.$recordEvent(label, "exercise_hint", {
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
          if (solution === null && hints.length > 0) {
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


/* Exercise evaluation */

Tutor.prototype.$initializeExerciseEvaluation = function() {
  
  // alias this
  var thiz = this;
  
  // get the current label context of an element
  function exerciseLabel(el) {
    return thiz.$exerciseContainer(el).attr('data-label');
  }
  
  // ensure that the exercise containing this element is fully visible
  function ensureExerciseVisible(el) {
    // convert to containing exercise element
    var exerciseEl = thiz.$exerciseContainer(el)[0];

    // ensure visibility
    thiz.$scrollIntoView(exerciseEl);
  }
  
  // register a shiny input binding for code editors
  var exerciseInputBinding = new Shiny.InputBinding();
  $.extend(exerciseInputBinding, {
    
    find: function(scope) {
      return $(scope).find('.tutor-exercise-code-editor');
    },
    
    getValue: function(el) {
      
      // return null if we haven't been clicked and this isn't a restore
      if (!this.clicked && !this.restore)
        return null;
      
      // value object to return 
      var value = {};
      
      // get the label
      value.label = exerciseLabel(el);
      
      // get the code from the editor
      var editor = ace.edit($(el).attr('id'));
      value.code = editor.getSession().getValue();
      
      // get the preserved chunk options (if any)
      var options_script = thiz.$exerciseContainer(el).find('script[data-opts-chunk="1"]');
      if (options_script.length == 1)
        value.options = JSON.parse(options_script.text());
      else
        value.options = {};
      
      // restore flag
      value.restore = this.restore;

      // get any setup, solution, or check chunks
      
      // setup
      var label = exerciseLabel(el);
      if (value.options["exercise.setup"])
        value.setup = thiz.$exerciseSupportCode(value.options["exercise.setup"]);     
      else
        value.setup = thiz.$exerciseSupportCode(label + "-setup");
        
      // solution
      value.solution = thiz.$exerciseSupportCode(label + "-solution");  
        
      // check
      if (this.check)
        value.check = thiz.$exerciseCheckCode(label);

      // some randomness to ensure we re-execute on button clicks
      value.timestamp = new Date().getTime();
      
      // return the value
      return value;
    },
    
    subscribe: function(el, callback) {
      var binding = this;
      this.runButtons(el).on('click.exerciseInputBinding', function(ev) {
        binding.restore = false;
        binding.clicked = true;
        binding.check = ev.target.hasAttribute('data-check');
        callback(true);
      });
      $(el).on('restore.exerciseInputBinding', function(ev, options) {
        binding.restore = true;
        binding.clicked = false;
        binding.check = options.check;
        callback(true);
      });
    },
    
    unsubscribe: function(el) {
      this.runButtons(el).off('.exerciseInputBinding');
    },
    
    runButtons: function(el) {
      var exercise = thiz.$exerciseContainer(el);
      return exercise.find('.btn-tutor-run');
    },
    
    restore: false,
    clicked: false,
    check: false
  });
  Shiny.inputBindings.register(exerciseInputBinding, 'tutor.exerciseInput');
  
  // register an output binding for exercise output
  var exerciseOutputBinding = new Shiny.OutputBinding();
  $.extend(exerciseOutputBinding, {
    
    find: function find(scope) {
      return $(scope).find('.tutor-exercise-output');
    },
    
    onValueError: function onValueError(el, err) {
     
      Shiny.unbindAll(el);
      this.renderError(el, err);
    },
    
    renderValue: function renderValue(el, data) {
  
      // remove default content (if any)
      this.outputFrame(el).children().not($(el)).remove();
      
      // render the content
      Shiny.renderContent(el, data);
      
      // bind bootstrap tables if necessary
      if (window.bootstrapStylePandocTables)
        window.bootstrapStylePandocTables();
      
      // bind paged tables if necessary
      if (window.PagedTableDoc)
        window.PagedTableDoc.initAll();
      
       // scroll exercise fully into view if we aren't restoring
      var restoring = thiz.$exerciseContainer(el).data('restoring');
      if (!restoring) {
        ensureExerciseVisible(el);
        thiz.$exerciseContainer(el).data('restoring', false);
      }
    },
    
    showProgress: function(el, show) {
      thiz.$showExerciseProgress(exerciseLabel(el), null, show);
    },
    
    outputFrame: function(el) {
      return $(el).closest('.tutor-exercise-output-frame');
    }
  });
  Shiny.outputBindings.register(exerciseOutputBinding, 'tutor.exerciseOutput');
};


/* Storage */

Tutor.prototype.$initializeStorage = function(identifiers, success) {
  
  // alias this
  var thiz = this;
  
  // initialize data store. note that we simply ignore errors for interactions
  // with storage since the entire behavior is a nice-to-have (i.e. we automatically
  // degrade gracefully by either not restoring any state or restoring whatever
  // state we had stored)
  thiz.$store = window.localforage.createInstance({ 
    name: "Tutorial-Storage", 
    storeName: window.btoa(identifiers.tutorial_id + 
                           identifiers.tutorial_version)
  });
  
  // custom message handler to update store
  Shiny.addCustomMessageHandler("tutor.store_object", function(message) {
    thiz.$store.setItem(message.id, message.data);
  });
  
  // retreive the currently stored objects then pass them down to restore_state
  var objects = null;
  thiz.$store.iterate(function(value, key, iterationNumber) {
    objects = objects || {};
    objects[key] = value;
  }).then(function() {
    success(objects);
  });
};


Tutor.prototype.$restoreState = function(objects) {
  
  // alias this
  var thiz = this;
  
  // retreive state from server
  this.$serverRequest("restore_state", objects, function(data) {
    
    // initialize progress
    thiz.$initializeProgress(data.progress_events);
    
    // get submissions
    var submissions = data.submissions;
    
    // work through each piece of state
    for (var i = 0; i < submissions.length; i++) {
      
      var submission = submissions[i];
      var type = submission.type[0];
      var label = submission.id[0];
     
      // exercise submissions
      if (type === "exercise_submission") {
        
        // get code and checked status
        var code = submission.data.code[0];
        var checked = submission.data.checked[0];
      
        // find the editor 
        var editorContainer = thiz.$exerciseEditor(label);
        if (editorContainer.length > 0) {
          
          // restore code
          var editor = ace.edit(editorContainer.attr('id'));
          editor.setValue(code, -1);
          
          // fire restore event on the container (also set
          // restoring flag on the exercise so we don't scroll it
          // into view after restoration)
          thiz.$exerciseForLabel(label).data('restoring', true);
          thiz.$showExerciseProgress(label, 'run', true);
          editorContainer.trigger('restore', {
            check: checked
          });
        }
      }
      
      // quesiton submissions
      else if (type === "question_submission") {
        
        // find the quiz 
        var quiz = $('.quiz[data-label="' + label + '"]');
        
        // if we have answers then restore them
        if (submission.data.answers.length > 0) {
          
          // select answers
          var answers = quiz.find('.answers').children('li');
          for (var a = 0; a < answers.length; a++) {
            var answer = $(answers[a]);
            var answerText = answer.children('label').attr('data-answer');
            if (submission.data.answers.indexOf(answerText) != -1)
              answer.children('input').prop('checked', true); 
          }
          
          // click submit button if we applied an answer
          if (answers.find('input:checked').length > 0) {
            
            // set restoring flag on quiz element
            quiz.data('restoring', true);
            
            // click the button
            var checkAnswer = quiz.find('.checkAnswer'); 
            checkAnswer.trigger('click');
          }
        }
      }
    }
  });
};

Tutor.prototype.$removeState = function(completed) {
  this.$store.clear()
    .then(completed)
    .catch(function(err) {
      console.log(err);
      completed();
    });
};


/* Server initialization */

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



