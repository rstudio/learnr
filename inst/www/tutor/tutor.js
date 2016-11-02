

// jquery plugin to change element type
(function($) {
  $.fn.changeElementType = function(newType) {
    var attrs = {};
    
    $.each(this[0].attributes, function(idx, attr) {
      attrs[attr.nodeName] = attr.nodeValue;
    });
    
    return this.replaceWith(function() {
      return $("<" + newType + "/>", attrs).append($(this).contents());
    });
  };
})(jQuery);

(function () {

  var $ = jQuery;

  // platform check
  var isMac = navigator.platform.toUpperCase().indexOf('MAC') >= 0;

  // get the exercise container of an element
  function exerciseContainer(el) {
    return $(el).closest(".tutor-exercise");
  }

  // get the current label context of an element
  function exerciseLabel(el) {
    return exerciseContainer(el).attr('data-label');
  }
  
  // ensure that the exercise containing this element is fully visible
  function ensureExerciseVisible(el) {
    // convert to containing exercise element
    var exerciseEl = exerciseContainer(el)[0];

    // ensure visibility
    var rect = exerciseEl.getBoundingClientRect();
    if (rect.top < 0 || rect.bottom > $(window).height()) {
      if (exerciseEl.scrollIntoView) {
        exerciseEl.scrollIntoView(true);
        document.body.scrollTop -= 40;
      } 
    }
  }
  
  // initialize videos
  function initializeVideos() {
    
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
  }

  // initialize exercises
  function initializeExercises() {
    
    $(".tutor-exercise").each(function() {
      
      // alias exercise
      var exercise = $(this);
       
      // helper to create an id
      function create_id(suffix) {
        return "tutor-exercise-" + exercise.attr('data-label') + "-" + suffix;
      }
      
      // get all <pre class='text'> elements, get their code, then remove them
      var code = '';
      var code_blocks = exercise.children('pre.text, pre.lang-text');
      code_blocks.each(function() {
        var code_element = $(this).children('code');
        if (code_element.length > 0)
          code = code + code_element.text() + "\n";
        else 
          code = code + $(this).text();
      });
      code_blocks.remove();
      
      // get the knitr options script block and detach it (will move to input div)
      var options_script = exercise.children('script[data-opts-chunk="1"]').detach();
      
      // wrap the remaining elements in an output frame div
      exercise.wrapInner('<div class="tutor-exercise-output-frame"></div>');
      var output_frame = exercise.children('.tutor-exercise-output-frame');
      
      // create input div
      var input_div = $('<div class="tutor-exercise-input"></div>');
      input_div.attr('id', create_id('input'));
      
      // create action button
      var run_button = $('<button class="btn btn-success btn-xs ' + 
                         'tutor-exercise-run action-button"></button>');
      run_button.attr('type', 'button');
      run_button.text('Run Code');
      run_button.attr('id', create_id('button'));
      var title = "Run code (" + (isMac ? "Cmd" : "Ctrl") + "+Shift+Enter)";
      run_button.attr('title', title);
      run_button.on('click', function() {
        output_frame.addClass('recalculating');
      });
      input_div.append(run_button);
      
      // create code div and add it to the input div
      var code_div = $('<div class="tutor-exercise-code-editor"></div>');
      var code_id = create_id('code-editor');
      code_div.attr('id', code_id);
      input_div.append(code_div);
      
      // add the knitr options script to the input div
      input_div.append(options_script);
      
      // prepend the input div to the exercise container
      exercise.prepend(input_div);
      
      // create an output div and append it to the output_frame
      var output_div = $('<div class="tutor-exercise-output"></div>');
      output_div.attr('id', create_id('output'));
      output_frame.append(output_div);
        
      // activate the ace editor
      var editor = ace.edit(code_id);
      editor.setHighlightActiveLine(false);
      editor.setShowPrintMargin(false);
      editor.setShowFoldWidgets(false);
      editor.renderer.setDisplayIndentGuides(false);
      editor.setTheme("ace/theme/textmate");
      editor.$blockScrolling = Infinity;
      editor.session.setMode("ace/mode/r");
      editor.session.getSelection().clearSelection();
      editor.setValue(code, -1);
      
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
      bindExecutionKey("execute3", "Ctrl+R");
      
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
              minLines: 2,
              maxLines: Math.max(Math.min(editor.session.getLength(), 15), 2)
           });
        }
       
      };
      updateAceHeight();
      editor.getSession().on('change', updateAceHeight);
    });
  }


  function registerShinyBindings() {
    
    // register a shiny input binding for code editors
    var exerciseInputBinding = new Shiny.InputBinding();
    $.extend(exerciseInputBinding, {
      
      find: function(scope) {
        return $(scope).find('.tutor-exercise-code-editor');
      },
      
      getValue: function(el) {
        
        // value object to return 
        var value = {};
        
        // get the code from the editor
        var editor = ace.edit($(el).attr('id'));
        value.code = editor.getSession().getValue();
        
        // get any setup or check chunks
        var label = exerciseLabel(el);
        function supportingCode(name) {
          var selector = '.tutor-exercise-support[data-label="' + label + '-' + name + '"]';
          var code = $(selector).children('pre').children('code');
          if (code.length > 0)
            return code.text();
          else
            return null;
        }
        value.setup = supportingCode("setup");
        value.check = supportingCode("check");
        
        // get the preserved chunk options (if any)
        var options_script = exerciseContainer(el).find('script[data-opts-chunk="1"]');
        if (options_script.length == 1)
          value.options = JSON.parse(options_script.text());
        else
          value.options = {};
        
        // return the value
        return value;
      },
      
      subscribe: function(el, callback) {
        this.executeButton(el).on('click.exerciseInputBinding', function() {
          callback(true);
        });
      },
      
      unsubscribe: function(el) {
        this.executeButton(el).off('.exerciseInputBinding');
      },
      
      executeButton: function(el) {
        var label = exerciseLabel(el);
        return $("#tutor-exercise-" + label + "-button");
      }
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
        
        // scroll exercise fully into view if necessary
        ensureExerciseVisible(el);
      },
      
      showProgress: function (el, show) {
        var RECALCULATING = 'recalculating';
        var outputFrame = this.outputFrame(el);
        if (show) {
          outputFrame.addClass(RECALCULATING);
        }
        else {
          outputFrame.removeClass(RECALCULATING);
        }
      },
      
      outputFrame: function(el) {
        return $(el).closest('.tutor-exercise-output-frame');
      }
    });
    Shiny.outputBindings.register(exerciseOutputBinding, 'tutor.exerciseOutput');
  }

  $(document).ready(function() {
    
    initializeVideos();
    
    initializeExercises();
    
    registerShinyBindings();
    
  });

})();
