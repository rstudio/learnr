"use strict";

/* global $,Shiny,TutorialCompleter,TutorialDiagnostics,ace,MathJax,Clipboard,YT,Vimeo,performance */

/* Tutorial construction and initialization */
$(document).ready(function () {
  var tutorial = new Tutorial(); // register autocompletion if available

  if (typeof TutorialCompleter !== 'undefined') {
    tutorial.$completer = new TutorialCompleter(tutorial);
  } // register diagnostics if available


  if (typeof TutorialDiagnostics !== 'undefined') {
    tutorial.$diagnostics = new TutorialDiagnostics(tutorial);
  }

  window.tutorial = tutorial;
}); // this var lets us know if the Shiny server is ready to handle http requests

var TUTORIAL_IS_SERVER_AVAILABLE = false;

function Tutorial() {
  // Alias this
  var thiz = this; // Init timing log

  this.$initTimingLog(); // API: provide init event

  this.onInit = function (handler) {
    this.$initCallbacks.add(handler);
  }; // API: provide progress events


  this.onProgress = function (handler) {
    this.$progressCallbacks.add(handler);
  }; // API: Start the tutorial over


  this.startOver = function () {
    thiz.$removeState(function () {
      thiz.$serverRequest('remove_state', null, function () {
        window.location.replace(window.location.origin + window.location.pathname);
      });
    });
  }; // API: Skip a section


  this.skipSection = function (sectionId) {
    // wait for shiny config to be available (required for $serverRequest)
    if (TUTORIAL_IS_SERVER_AVAILABLE) {
      thiz.$serverRequest('section_skipped', {
        sectionId: sectionId
      }, null);
    }
  }; // API: scroll an element into view


  this.scrollIntoView = function (element) {
    element = $(element);
    var rect = element[0].getBoundingClientRect();

    if (rect.top < 0 || rect.bottom > $(window).height()) {
      if (element[0].scrollIntoView) {
        element[0].scrollIntoView(false);
        document.body.scrollTop += 20;
      }
    }
  }; // Initialization


  thiz.$initializeVideos();
  thiz.$initializeExercises();
  thiz.$initializeServer();
}
/* Utilities */


Tutorial.prototype.$initTimingLog = function () {
  try {
    if (performance.mark !== undefined) {
      performance.mark('tutorial-start-mark');
    }
  } catch (e) {
    console.log('Error initializing log timing: ' + e.message);
  }
};

Tutorial.prototype.$logTiming = function (name) {
  try {
    if (performance.mark !== undefined && performance.measure !== undefined && performance.getEntriesByName !== undefined && this.queryVar('log-timings') === '1') {
      performance.mark(name + '-mark');
      performance.measure(name, 'tutorial-start-mark', name + '-mark');
      var entries = performance.getEntriesByName(name);
      console.log('(Timing) ' + name + ': ' + Math.round(entries[0].duration) + 'ms');
    }
  } catch (e) {
    console.log('Error logging timing: ' + e.message);
  }
};

Tutorial.prototype.queryVar = function (name) {
  return decodeURI(window.location.search.replace(new RegExp('^(?:.*[&\\?]' + encodeURI(name).replace(/[.+*]/g, '\\$&') + '(?:\\=([^&]*))?)?.*$', 'i'), '$1'));
};

Tutorial.prototype.$idSelector = function (id) {
  return '#' + id.replace(/(:|\.|\[|\]|,|=|@)/g, '\\$1');
}; // static method to trigger MathJax


Tutorial.triggerMathJax = function () {
  if (window.MathJax) {
    MathJax.Hub.Queue(['Typeset', MathJax.Hub]);
  }
};
/* Init callbacks */


Tutorial.prototype.$initCallbacks = $.Callbacks();

Tutorial.prototype.$fireInit = function () {
  // Alias this
  var thiz = this; // fire event

  try {
    thiz.$initCallbacks.fire();
  } catch (e) {
    console.log(e);
  }
};
/* Progress callbacks */


Tutorial.prototype.$progressCallbacks = $.Callbacks();
Tutorial.prototype.$progressEvents = [];

Tutorial.prototype.$hasCompletedProgressEvent = function (element) {
  var thiz = this;

  for (var e = 0; e < thiz.$progressEvents.length; e++) {
    var event = thiz.$progressEvents[e];

    if ($(event.element).is($(element))) {
      if (event.completed) {
        return true;
      }
    }
  }

  return false;
};

Tutorial.prototype.$fireProgress = function (event) {
  // record it
  this.$progressEvents.push(event); // fire event

  try {
    this.$progressCallbacks.fire(event);
  } catch (e) {
    console.log(e);
  }
};

Tutorial.prototype.$fireSectionCompleted = function (element) {
  // Alias this
  var thiz = this; // helper function to fire section completed

  function fireCompleted(el) {
    var event = {
      element: el,
      event: 'section_completed'
    };
    thiz.$fireProgress(event);
  } // find closest containing section (bail if there is none)


  var section = $(element).parent().closest('.section');

  if (section.length === 0) {
    return;
  } // get all interactive components in the section


  var components = section.find('.tutorial-exercise, .tutorial-question, .tutorial-video'); // are they all completed?

  var allCompleted = true;

  for (var c = 0; c < components.length; c++) {
    var component = components.get(c);

    if (!thiz.$hasCompletedProgressEvent(component)) {
      allCompleted = false;
      break;
    }
  } // if they are then fire event


  if (allCompleted) {
    // fire the event
    fireCompleted($(section).get(0)); // fire for preceding siblings if they have no interactive components

    var previousSections = section.prevAll('.section');
    previousSections.each(function () {
      var components = $(this).find('.tutorial-exercise, .tutorial-question');

      if (components.length === 0) {
        fireCompleted(this);
      }
    }); // if there is another section above us then process it

    var parentSection = section.parent().closest('.section');

    if (parentSection.length > 0) {
      this.$fireSectionCompleted(section);
    }
  }
};

Tutorial.prototype.$removeConflictingProgressEvents = function (progressEvent) {
  // Alias this
  var thiz = this;
  var event; // work backwards as to avoid skipping a position caused by removing an element

  for (var i = thiz.$progressEvents.length - 1; i >= 0; i--) {
    event = thiz.$progressEvents[i];

    if (event.event === 'question_submission') {
      if (event.data.label === progressEvent.data.label & progressEvent.data.label !== undefined) {
        // remove the item from existing progress events
        thiz.$progressEvents.splice(i, 1);
        return;
      }
    }
  }
};

Tutorial.prototype.$fireProgressEvent = function (event, data) {
  // Alias this
  var thiz = this; // progress event to fire

  var progressEvent = {
    event: event,
    data: data
  }; // determine element and completed status

  if (event === 'exercise_submission' || event === 'question_submission') {
    var element = $('.tutorial-exercise[data-label="' + data.label + '"]').add('.tutorial-question[data-label="' + data.label + '"]');

    if (element.length > 0) {
      progressEvent.element = element;

      if (event === 'exercise_submission') {
        // Exercise completion logic is determined by the default exercise_result
        // event handler in the Shiny logic that emits an "exercise_submission" event.
        // If the handler doesn't returned a completed flag, we assume `true`.
        progressEvent.completed = typeof data.completed !== 'undefined' ? data.completed : true;
      } else {
        // question_submission
        // questions may be reset with "try again", and not in a completed state
        progressEvent.completed = data.answer !== null;
      }
    }
  } else if (event === 'section_skipped') {
    var exerciseElement = $(thiz.$idSelector(data.sectionId));
    progressEvent.element = exerciseElement;
    progressEvent.completed = false;
  } else if (event === 'video_progress') {
    var videoElement = $('iframe[src="' + data.video_url + '"]');

    if (videoElement.length > 0) {
      progressEvent.element = videoElement;
      progressEvent.completed = 2 * data.time > data.total_time;
    }
  } // remove any prior forms of this progressEvent


  this.$removeConflictingProgressEvents(progressEvent); // fire it if we found an element

  if (progressEvent.element) {
    // fire event
    this.$fireProgress(progressEvent); // synthesize higher level section completed events

    thiz.$fireSectionCompleted(progressEvent.element);
  }
};

Tutorial.prototype.$initializeProgress = function (progressEvents) {
  // Alias this
  var thiz = this; // replay progress messages from previous state

  for (var i = 0; i < progressEvents.length; i++) {
    // get event
    var progress = progressEvents[i];
    var progressEvent = progress.event; // determine data

    var progressEventData = {};

    if (progressEvent === 'exercise_submission') {
      progressEventData.label = progress.data.label;
      progressEventData.correct = progress.data.correct;
    } else if (progressEvent === 'question_submission') {
      progressEventData.label = progress.data.label;
      progressEventData.answer = progress.data.answer;
    } else if (progressEvent === 'section_skipped') {
      progressEventData.sectionId = progress.data.sectionId;
    } else if (progressEvent === 'video_progress') {
      progressEventData.video_url = progress.data.video_url;
      progressEventData.time = progress.data.time;
      progressEventData.total_time = progress.data.total_time;
    }

    thiz.$fireProgressEvent(progressEvent, progressEventData);
  } // handle subsequent progress messages


  Shiny.addCustomMessageHandler('tutorial.progress_event', function (progress) {
    thiz.$fireProgressEvent(progress.event, progress.data);
  });
};
/* Shared utility functions */


Tutorial.prototype.$serverRequest = function (type, data, success, error) {
  var _Shiny$shinyapp$confi = Shiny.shinyapp.config,
      sessionId = _Shiny$shinyapp$confi.sessionId,
      workerId = _Shiny$shinyapp$confi.workerId;
  return $.ajax({
    type: 'POST',
    url: "session/".concat(sessionId, "/dataobj/").concat(type, "?w=").concat(workerId),
    contentType: 'application/json',
    data: JSON.stringify(data),
    dataType: 'json',
    success: success,
    error: error
  });
}; // Record an event


Tutorial.prototype.$recordEvent = function (label, event, data) {
  var params = {
    label: label,
    event: event,
    data: data
  };
  this.$serverRequest('record_event', params, null);
};

Tutorial.prototype.$countLines = function (str) {
  return str.split(/\r\n|\r|\n/).length;
};

Tutorial.prototype.$injectScript = function (src, onload) {
  var script = document.createElement('script');
  script.src = src;
  var firstScriptTag = document.getElementsByTagName('script')[0];
  firstScriptTag.parentNode.insertBefore(script, firstScriptTag);
  $(script).on('load', onload);
};

Tutorial.prototype.$debounce = function (func, wait, immediate) {
  var timeout;
  return function () {
    var context = this;
    var args = arguments;

    var later = function later() {
      timeout = null;
      if (!immediate) func.apply(context, args);
    };

    var callNow = immediate && !timeout;
    clearTimeout(timeout);
    timeout = setTimeout(later, wait);
    if (callNow) func.apply(context, args);
  };
};
/* Videos */


Tutorial.prototype.$initializeVideos = function () {
  // regexes for video types
  var youtubeRegex = /^.*(youtu.be\/|v\/|u\/\w\/|embed\/|watch\?v=|&v=)([^#&?]*).*/;
  var vimeoRegex = /(?:vimeo)\.com.*(?:videos|video|channels|)\/([\d]+)/i; // check a url for video types

  function isYouTubeVideo(src) {
    return src.match(youtubeRegex);
  }

  function isVimeoVideo(src) {
    return src.match(vimeoRegex);
  }

  function isVideo(src) {
    return isYouTubeVideo(src) || isVimeoVideo(src);
  } // function to normalize a video src url (web view -> embed)


  function normalizeVideoSrc(src) {
    // youtube
    var youtubeMatch = src.match(youtubeRegex);

    if (youtubeMatch) {
      return "https://www.youtube.com/embed/".concat(youtubeMatch[2], "?enablejsapi=1");
    } // vimeo


    var vimeoMatch = src.match(vimeoRegex);

    if (vimeoMatch) {
      return "https://player.vimeo.com/video/".concat(vimeoMatch[1]);
    } // default to reflecting src back


    return src;
  } // function to set the width and height for the container conditioned on
  // any user-specified height and width


  function setContainerSize(container, width, height) {
    // default ratio
    var aspectRatio = 9 / 16; // default width to 100% if not specified

    if (!width) {
      width = '100%';
    } // percentage based width


    if (width.slice(-1) === '%') {
      container.css('width', width);

      if (!height) {
        height = 0;
        var paddingBottom = parseFloat(width) * aspectRatio + '%';
        container.css('padding-bottom', paddingBottom);
      }

      container.css('height', height);
    } else {
      // or another width unit, adding 'px' if necessary
      if ($.isNumeric(width)) {
        width = width + 'px';
      }

      container.css('width', width);

      if (!height) {
        height = parseFloat(width) * aspectRatio + 'px';
      }

      container.css('height', height);
    }
  } // inspect all images to see if they contain videos


  $('img').each(function () {
    // skip if this isn't a video
    var videoSrc = $(this).attr('src');

    if (!isVideo(videoSrc)) {
      return;
    } // hide while we process


    $(this).css('display', 'none'); // collect various attributes

    var width = $(this).get(0).style.width;
    var height = $(this).get(0).style.height;
    $(this).css('width', '').css('height', '');
    var attrs = {};
    $.each(this.attributes, function (idex, attr) {
      switch (attr.nodeName) {
        case 'width':
          {
            width = String(attr.nodeValue);
            break;
          }

        case 'height':
          {
            height = String(attr.nodeValue);
            break;
          }

        case 'src':
          {
            attrs.src = normalizeVideoSrc(attr.nodeValue);
            break;
          }

        default:
          {
            attrs[attr.nodeName] = attr.nodeValue;
          }
      }
    }); // replace the image with the iframe inside a video container

    $(this).replaceWith(function () {
      var iframe = $('<iframe/>', attrs);
      iframe.addClass('tutorial-video');

      if (isYouTubeVideo(videoSrc)) {
        iframe.addClass('tutorial-video-youtube');
      } else if (isVimeoVideo(videoSrc)) {
        iframe.addClass('tutorial-video-vimeo');
      }

      iframe.attr('allowfullscreen', '');
      iframe.css('display', '');
      var container = $('<div class="tutorial-video-container"></div>');
      setContainerSize(container, width, height);
      container.append(iframe);
      return container;
    });
  }); // we'll initialize video player APIs off of $restoreState

  this.$logTiming('initialized-videos');
};

Tutorial.prototype.$initializeVideoPlayers = function (videoProgress) {
  // don't interact with video player APIs in Qt
  if (/\bQt\//.test(window.navigator.userAgent)) {
    return;
  }

  this.$initializeYouTubePlayers(videoProgress);
  this.$initializeVimeoPlayers(videoProgress);
};

Tutorial.prototype.$videoPlayerRestoreTime = function (src, videoProgress) {
  // find a restore time for this video
  for (var v = 0; v < videoProgress.length; v++) {
    var id = videoProgress[v].id;

    if (src === id) {
      var time = videoProgress[v].data.time;
      var totalTime = videoProgress[v].data.total_time; // don't return a restore time if we are within 10 seconds of the beginning
      // or the end of the video.

      if (time > 10 && totalTime - time > 10) {
        return time;
      }
    }
  } // no time to restore, return 0


  return 0;
};

Tutorial.prototype.$initializeYouTubePlayers = function (videoProgress) {
  // YouTube JavaScript API
  // https://developers.google.com/youtube/iframe_api_reference
  // alias this
  var thiz = this; // attach to youtube videos

  var videos = $('iframe.tutorial-video-youtube');

  if (videos.length > 0) {
    this.$injectScript('https://www.youtube.com/iframe_api', function () {
      YT.ready(function () {
        videos.each(function () {
          // video and player
          var video = $(this);
          var videoUrl = video.attr('src');
          var player = null;
          var lastState = -1; // helper to report progress to the server

          function reportProgress() {
            thiz.$reportVideoProgress(videoUrl, player.getCurrentTime(), player.getDuration());
          } // helper to restore video time. attempt to restore to 10 seconds prior
          // to the last save point (to recapture frame of reference)


          function restoreTime() {
            var restoreTime = thiz.$videoPlayerRestoreTime(videoUrl, videoProgress);

            if (restoreTime > 0) {
              player.mute();
              player.playVideo();
              setTimeout(function () {
                player.pauseVideo();
                player.seekTo(restoreTime, true);
                player.unMute();
              }, 2000);
            }
          } // function to call onReady


          function onReady() {
            restoreTime();
          } // function to call on state changed


          function onStateChange() {
            // get current state
            var state = player.getPlayerState();
            var isNotStarted = state === -1;
            var isCued = state === YT.PlayerState.CUED;
            var isPlaying = state === YT.PlayerState.PLAYING;
            var isDuplicate = state === lastState; // don't report for unstarted & queued
            // otherwise report if playing or non-duplicate state

            if (!(isNotStarted || isCued) && (isPlaying || isDuplicate)) {
              reportProgress();
            } // update last state


            lastState = state;
          } // create the player


          player = new YT.Player(this, {
            events: {
              onReady: onReady,
              onStateChange: onStateChange
            }
          }); // poll for state change every 5 seconds

          window.setInterval(onStateChange, 5000);
        });
      });
    });
  }
};

Tutorial.prototype.$initializeVimeoPlayers = function (videoProgress) {
  // alias this
  var thiz = this; // Vimeo JavaScript API
  // https://github.com/vimeo/player.js

  var videos = $('iframe.tutorial-video-vimeo');

  if (videos.length > 0) {
    this.$injectScript('https://player.vimeo.com/api/player.js', function () {
      videos.each(function () {
        // video and player
        var video = $(this);
        var videoUrl = video.attr('src');
        var player = new Vimeo.Player(this);
        var lastReportedTime = null; // restore time if we can

        player.ready().then(function () {
          var restoreTime = thiz.$videoPlayerRestoreTime(videoUrl, videoProgress);

          if (restoreTime > 0) {
            player.getVolume().then(function (volume) {
              player.setCurrentTime(restoreTime).then(function () {
                player.pause().then(function () {
                  player.setVolume(volume);
                });
              });
            });
          }
        }); // helper function to report progress

        function reportProgress(data, throttle) {
          // default throttle to false
          if (throttle === undefined) {
            throttle = false;
          } // if we are throttling then don't report if the last
          // reported time is within 5 seconds


          if (throttle && lastReportedTime != null && data.seconds - lastReportedTime < 5) {
            return;
          } // report progress


          thiz.$reportVideoProgress(videoUrl, data.seconds, data.duration);
          lastReportedTime = data.seconds;
        } // report progress on various events


        player.on('play', reportProgress);
        player.on('pause', reportProgress);
        player.on('ended', reportProgress);
        player.on('timeupdate', function (data) {
          reportProgress(data, true);
        });
      });
    });
  }
};

Tutorial.prototype.$reportVideoProgress = function (videoUrl, time, totalTime) {
  this.$serverRequest('video_progress', {
    video_url: videoUrl,
    time: time,
    total_time: totalTime
  });
};
/* Exercise initialization and shared utility functions */


Tutorial.prototype.$initializeExercises = function () {
  this.$initializeExerciseEditors();
  this.$initializeExerciseSolutions();
  this.$initializeExerciseEvaluation();
  this.$logTiming('initialized-exercises');
};

Tutorial.prototype.$exerciseForLabel = function (label) {
  return $('.tutorial-exercise[data-label="' + label + '"]');
};

Tutorial.prototype.$forEachExercise = function (operation) {
  return $('.tutorial-exercise').each(function () {
    var exercise = $(this);
    operation(exercise);
  });
};

Tutorial.prototype.$exerciseSupportCode = function (label) {
  var selector = '.tutorial-exercise-support[data-label="' + label + '"]';
  var code = $(selector).children('pre').children('code');

  if (code.length > 0) {
    return code.text();
  } else {
    return null;
  }
};

Tutorial.prototype.$exerciseSolutionCode = function (label) {
  return this.$exerciseSupportCode(label + '-solution');
};

Tutorial.prototype.$exerciseHintDiv = function (label) {
  // look for a div w/ hint id
  var id = 'section-' + label + '-hint';
  var hintDiv = $('div#' + id); // ensure it isn't a section then return

  if (hintDiv.length > 0 && !hintDiv.hasClass('section')) {
    return hintDiv;
  } else {
    return null;
  }
};

Tutorial.prototype.$exerciseHintsCode = function (label) {
  // look for a single hint
  var hint = this.$exerciseSupportCode(label + '-hint');

  if (hint !== null) {
    return [hint];
  } // look for a sequence of hints


  var hints = [];
  var index = 1;

  while (true) {
    var hintLabel = label + '-hint-' + index++;
    hint = this.$exerciseSupportCode(hintLabel);

    if (hint !== null) {
      hints.push(hint);
    } else {
      break;
    }
  } // return what we have (null if empty)


  if (hints.length > 0) {
    return hints;
  } else {
    return null;
  }
}; // get the exercise container of an element


Tutorial.prototype.$exerciseContainer = function (el) {
  return $(el).closest('.tutorial-exercise');
}; // show progress for exercise


Tutorial.prototype.$showExerciseProgress = function (label, button, show) {
  // references to various UI elements
  var exercise = this.$exerciseForLabel(label);
  var outputFrame = exercise.children('.tutorial-exercise-output-frame');
  var runButtons = exercise.find('.btn-tutorial-run'); // if the button is "run" then use the run button

  if (button === 'run') {
    button = exercise.find('.btn-tutorial-run').last();
  } // show/hide progress UI


  var spinner = 'fa-spinner fa-spin fa-fw';

  if (show) {
    outputFrame.addClass('recalculating');
    runButtons.addClass('disabled');

    if (button !== null) {
      var runIcon = button.children('i');
      runIcon.removeClass(button.attr('data-icon'));
      runIcon.addClass(spinner);
    }
  } else {
    outputFrame.removeClass('recalculating');
    runButtons.removeClass('disabled');
    runButtons.each(function () {
      var button = $(this);
      var runIcon = button.children('i');
      runIcon.addClass(button.attr('data-icon'));
      runIcon.removeClass(spinner);
    });
  }
}; // behavior constants


Tutorial.prototype.kMinLines = 3; // edit code within an ace editor

Tutorial.prototype.$attachAceEditor = function (target, code) {
  var editor = ace.edit(target);
  editor.setHighlightActiveLine(false);
  editor.setShowPrintMargin(false);
  editor.setShowFoldWidgets(false);
  editor.setBehavioursEnabled(true);
  editor.renderer.setDisplayIndentGuides(false);
  editor.setTheme('ace/theme/textmate');
  editor.$blockScrolling = Infinity;
  editor.session.setMode('ace/mode/r');
  editor.session.getSelection().clearSelection();
  editor.setValue(code, -1);
  return editor;
};
/* Exercise editor */


Tutorial.prototype.$exerciseEditor = function (label) {
  return this.$exerciseForLabel(label).find('.tutorial-exercise-code-editor');
};

Tutorial.prototype.$initializeExerciseEditors = function () {
  // alias this
  var thiz = this;
  this.$forEachExercise(function (exercise) {
    // get the knitr options script block and detach it (will move to input div)
    var optsScript = exercise.children('script[data-ui-opts="1"]').detach();
    var optsChunk = optsScript.length === 1 ? JSON.parse(optsScript.text()) : {}; // capture label and caption

    var label = exercise.attr('data-label');
    var caption = optsChunk.caption; // helper to create an id

    function createId(suffix) {
      return 'tutorial-exercise-' + label + '-' + suffix;
    } // when we receive focus hide solutions in other exercises


    exercise.on('focusin', function () {
      $('.btn-tutorial-solution').each(function () {
        if (exercise.has($(this)).length === 0) {
          thiz.$removeSolution(thiz.$exerciseContainer($(this)));
        }
      });
    }); // get all <pre class='text'> elements, get their code, then remove them

    var code = '';
    var codeBlocks = exercise.children('pre.text, pre.lang-text');
    codeBlocks.each(function () {
      var codeElement = $(this).children('code');

      if (codeElement.length > 0) {
        code = code + codeElement.text();
      } else {
        code = code + $(this).text();
      }
    });
    codeBlocks.remove(); // ensure a minimum of 3 lines

    var lines = code.split(/\r\n|\r|\n/).length;

    for (var i = lines; i < thiz.kMinLines; i++) {
      code = code + '\n';
    } // wrap the remaining elements in an output frame div


    exercise.wrapInner('<div class="tutorial-exercise-output-frame"></div>');
    var outputFrame = exercise.children('.tutorial-exercise-output-frame'); // create input div

    var inputDiv = $('<div class="tutorial-exercise-input panel panel-default"></div>');
    inputDiv.attr('id', createId('input')); // creating heading

    var panelHeading = $('<div class="panel-heading tutorial-panel-heading"></div>');
    inputDiv.append(panelHeading);
    var panelHeadingLeft = $('<div class="tutorial-panel-heading-left"></div>');
    var panelHeadingRight = $('<div class="tutorial-panel-heading-right"></div>');
    panelHeading.append(panelHeadingLeft);
    panelHeading.append(panelHeadingRight);
    panelHeadingLeft.html(caption); // create body

    var panelBody = $('<div class="panel-body"></div>');
    inputDiv.append(panelBody); // function to add a submit button

    function addSubmitButton(icon, style, text, check, datai18n) {
      var button = $('<button class="btn ' + style + ' btn-xs btn-tutorial-run"></button>');
      button.append($('<i class="fa ' + icon + '"></i>'));
      button.append(' ' + '<span data-i18n="button.' + datai18n + '">' + text + '</span>');
      var isMac = navigator.platform.toUpperCase().indexOf('MAC') >= 0;
      var title = text;
      var kbdText = (isMac ? 'Cmd' : 'Ctrl') + '+Shift+Enter';

      if (!check) {
        title = title + ' (' + kbdText + ')';
        button.attr('data-i18n-opts', '{"kbd": "' + kbdText + '"}');
      }

      button.attr('title', title);
      button.attr('data-i18n', '');
      button.attr('data-i18n-attr-title', 'button.' + datai18n + 'title');

      if (check) {
        button.attr('data-check', '1');
      }

      button.attr('data-icon', icon);
      button.on('click', function () {
        thiz.$removeSolution(exercise);
        thiz.$showExerciseProgress(label, button, true);
      });
      panelHeadingRight.append(button);
      return button;
    } // create run button


    var runButton = addSubmitButton('fa-play', 'btn-success', 'Run Code', false, 'runcode'); // create submit answer button if checks are enabled

    if (optsChunk.has_checker) {
      addSubmitButton('fa-check-square-o', 'btn-primary', 'Submit Answer', true, 'submitanswer');
    } // create code div and add it to the input div


    var codeDiv = $('<div class="tutorial-exercise-code-editor"></div>');
    var codeDivId = createId('code-editor');
    codeDiv.attr('id', codeDivId);
    panelBody.append(codeDiv); // add the knitr options script to the input div

    panelBody.append(optsScript); // prepend the input div to the exercise container

    exercise.prepend(inputDiv); // create an output div and append it to the output_frame

    var outputDiv = $('<div class="tutorial-exercise-output"></div>');
    outputDiv.attr('id', createId('output'));
    outputFrame.append(outputDiv); // activate the ace editor

    var editor = thiz.$attachAceEditor(codeDivId, code); // get setup_code (if any)

    var setupCode = null; // use code completion

    var completion = exercise.attr('data-completion') === '1';
    var diagnostics = exercise.attr('data-diagnostics') === '1'; // support startover

    var startoverCode = exercise.attr('data-startover') === '1' ? code : null; // get the engine

    var engine = optsChunk.engine;

    if (engine.toLowerCase() !== 'r') {
      // disable ace editor diagnostics if a non-r language engine is set
      diagnostics = null;
    } // set tutorial options/data


    editor.tutorial = {
      label: label,
      engine: engine,
      setup_code: setupCode,
      completion: completion,
      diagnostics: diagnostics,
      startover_code: startoverCode
    }; // bind execution keys

    function bindExecutionKey(name, key) {
      var macKey = key.replace('Ctrl+', 'Command+');
      editor.commands.addCommand({
        name: name,
        bindKey: {
          win: key,
          mac: macKey
        },
        exec: function exec(editor) {
          runButton.trigger('click');
        }
      });
    }

    bindExecutionKey('execute1', 'Ctrl+Enter');
    bindExecutionKey('execute2', 'Ctrl+Shift+Enter');

    function bindInsertKey(name, keys, text) {
      if (typeof keys === 'string') {
        keys = {
          win: keys,
          mac: keys.replace('Ctrl+', 'Command+')
        };
      }

      if (typeof text === 'string') {
        text = {
          r: text,
          fallback: text
        };
      }

      editor.commands.addCommand({
        name: name,
        bindKey: keys,
        exec: function exec(editor) {
          if (text[editor.tutorial.engine]) {
            editor.insert(text[editor.tutorial.engine]);
          } else if (text.fallback) {
            editor.insert(text.fallback);
          }
        }
      });
    }

    bindInsertKey('insertPipe', 'Ctrl+Shift+M', {
      r: ' %>% '
    });
    bindInsertKey('insertArrow', 'Alt+-', {
      r: ' <- ',
      fallback: ' = '
    }); // re-focus the editor on run button click

    runButton.on('click', function () {
      editor.focus();
    }); // Allow users to escape the editor and move to next focusable element

    function toggleTabCommands(enable) {
      var tabCommandKeys = {
        indent: {
          win: 'Tab',
          mac: 'Tab'
        },
        outdent: {
          win: 'Shift+Tab',
          mac: 'Shift+Tab'
        }
      };
      ['indent', 'outdent'].forEach(function (name) {
        var command = editor.commands.byName[name]; // turn off tab commands or restore original bindKey

        command.bindKey = enable ? tabCommandKeys[name] : null;
        editor.commands.addCommand(command);
      }); // update class on editor to reflect tab command state

      $(editor.container).toggleClass('ace_indent_off', !enable);
    }

    editor.on('focus', function () {
      toggleTabCommands(true);
    });
    editor.commands.addCommand({
      name: 'escape',
      bindKey: {
        win: 'Esc',
        mac: 'Esc'
      },
      exec: function exec() {
        toggleTabCommands(false);
      }
    }); // manage ace height as the document changes

    var updateAceHeight = function updateAceHeight() {
      var lines = exercise.attr('data-lines');

      if (lines && lines > 0) {
        editor.setOptions({
          minLines: lines,
          maxLines: lines
        });
      } else {
        editor.setOptions({
          minLines: thiz.kMinLines,
          maxLines: Math.max(Math.min(editor.session.getLength(), 15), thiz.kMinLines)
        });
      }
    };

    updateAceHeight();
    editor.getSession().on('change', updateAceHeight); // add hint/solution/startover buttons if necessary

    thiz.$addSolution(exercise, panelHeadingLeft, editor);
    exercise.parents('.section').on('shown', function () {
      editor.resize(true);
    });
  });
};
/* Exercise solutions */


Tutorial.prototype.$initializeExerciseSolutions = function () {
  // alias this
  var thiz = this; // hide solutions when clicking outside exercises

  $(document).on('mouseup', function (ev) {
    var exercise = thiz.$exerciseContainer(ev.target);

    if (exercise.length === 0) {
      thiz.$forEachExercise(thiz.$removeSolution);
    }
  });
}; // add a solution for the specified exercise label


Tutorial.prototype.$addSolution = function (exercise, panelHeading, editor) {
  // alias this
  var thiz = this; // get label

  var label = exercise.attr('data-label'); // solution/hints (in the presence of hints convert solution to last hint)

  var solution = thiz.$exerciseSolutionCode(label);
  var hints = thiz.$exerciseHintsCode(label);

  if (hints !== null && solution !== null) {
    hints.push(solution);
    solution = null;
  }

  var hintDiv = thiz.$exerciseHintDiv(label); // function to add a helper button

  function addHelperButton(icon, caption, classBtn, datai18n) {
    var button = $('<button class="btn btn-light btn-xs btn-tutorial-solution"></button>');
    button.attr('title', caption);
    button.attr('data-i18n', '');
    button.addClass(classBtn);
    button.append($('<i class="fa ' + icon + '"></i>'));

    if (datai18n) {
      if (typeof datai18n === 'string') {
        datai18n = {
          key: datai18n
        };
      }

      button.attr('data-i18n-attr-title', datai18n.key + 'title');
      var buttonText = $('<span>' + caption + '</span>');
      buttonText.attr('data-i18n', datai18n.key);

      if (datai18n.opts) {
        buttonText.attr('data-i18n-opts', JSON.stringify(datai18n.opts));
      }

      button.append(document.createTextNode(' '));
      button.append(buttonText);

      if (datai18n.opts) {
        button.attr('data-i18n-opts', JSON.stringify(datai18n.opts));
      }
    } else {
      button.append(' ' + caption);
    }

    panelHeading.append(button);
    return button;
  } // function to add a hint button


  function addHintButton(caption, datai18n) {
    datai18n = datai18n || 'button.hint';
    return addHelperButton('fa-lightbulb-o', caption, 'btn-tutorial-hint', datai18n);
  } // helper function to record solution/hint requests


  function recordHintRequest(index) {
    thiz.$recordEvent(label, 'exercise_hint', {
      type: solution !== null ? 'solution' : 'hint',
      index: index
    });
  } // add a startover button


  if (editor.tutorial.startover_code !== null) {
    var startOverButton = addHelperButton('fa-refresh', 'Start Over', 'btn-tutorial-start-over', 'button.startover');
    startOverButton.on('click', function () {
      editor.setValue(editor.tutorial.startover_code, -1);
      thiz.$clearExerciseOutput(exercise);
    });
  } // if we have a hint div


  if (hintDiv != null) {
    // mark the div as a hint and hide it
    hintDiv.addClass('tutorial-hint');
    hintDiv.css('display', 'none'); // create hint button

    var button = addHintButton('Hint', {
      key: 'button.hint',
      count: 1
    }); // handle showing and hiding the hint

    button.on('click', function () {
      // record the request
      recordHintRequest(0); // prepend it to the output frame (if a hint isn't already in there)

      var outputFrame = exercise.children('.tutorial-exercise-output-frame');

      if (outputFrame.find('.tutorial-hint').length === 0) {
        var panel = $('<div class="panel panel-default tutorial-hint-panel"></div>');
        var panelBody = $('<div class="panel-body"></div>');
        var hintDivClone = hintDiv.clone().attr('id', '').css('display', 'inherit');
        panelBody.append(hintDivClone);
        panel.append(panelBody);
        outputFrame.prepend(panel);
      } else {
        outputFrame.find('.tutorial-hint-panel').remove();
      }
    });
  } else if (solution || hints) {
    // else if we have a solution or hints
    var isSolution = solution !== null; // determine editor lines

    var editorLines = thiz.kMinLines;

    if (solution) {
      editorLines = Math.max(thiz.$countLines(solution), editorLines);
    } else {
      for (var i = 0; i < hints.length; i++) {
        editorLines = Math.max(thiz.$countLines(hints[i]), editorLines);
      }
    } // track hint index


    var hintIndex = 0; // create solution button

    var _button = addHintButton(isSolution ? 'Solution' : hints.length > 1 ? 'Hints' : 'Hint', isSolution ? {
      key: 'button.solution',
      count: 1
    } : {
      key: 'button.hint',
      opts: {
        count: hints.length
      }
    }); // handle showing and hiding the popover


    _button.on('click', function () {
      // record the request
      recordHintRequest(hintIndex); // determine solution text

      var solutionText = solution !== null ? solution : hints[hintIndex];
      var visible = _button.next('div.popover:visible').length > 0;

      if (!visible) {
        var popover = _button.popover({
          placement: 'top',
          template: '<div class="popover tutorial-solution-popover" role="tooltip">' + '<div class="arrow"></div>' + '<div class="popover-title tutorial-panel-heading"></div>' + '<div class="popover-content"></div>' + '</div>',
          content: solutionText,
          trigger: 'manual'
        });

        popover.on('inserted.bs.popover', function () {
          // get popover element
          var dataPopover = popover.data('bs.popover');
          var popoverTip = dataPopover.tip();
          var content = popoverTip.find('.popover-content'); // adjust editor and container height

          var solutionEditor = thiz.$attachAceEditor(content.get(0), solutionText);
          solutionEditor.setReadOnly(true);
          solutionEditor.setOptions({
            minLines: editorLines
          });
          var height = editorLines * solutionEditor.renderer.lineHeight;
          content.css('height', height + 'px'); // get title panel

          var popoverTitle = popoverTip.find('.popover-title'); // add next hint button if we have > 1 hint

          if (solution === null && hints.length > 1) {
            var nextHintButton = $('<button class="btn btn-light btn-xs btn-tutorial-next-hint"></button>');
            nextHintButton.append($('<span data-i18n="button.hintnext">Next Hint</span>'));
            nextHintButton.append(' ');
            nextHintButton.append($('<i class="fa fa-angle-double-right"></i>'));
            nextHintButton.on('click', function () {
              hintIndex = hintIndex + 1;
              solutionEditor.setValue(hints[hintIndex], -1);

              if (hintIndex === hints.length - 1) {
                nextHintButton.addClass('disabled');
              }

              recordHintRequest(hintIndex);
            });

            if (hintIndex === hints.length - 1) {
              nextHintButton.addClass('disabled');
            }

            popoverTitle.append(nextHintButton);
          } // add copy button


          var copyButton = $('<button class="btn btn-info btn-xs ' + 'btn-tutorial-copy-solution pull-right"></button>');
          copyButton.append($('<i class="fa fa-copy"></i>'));
          copyButton.append(' ');
          copyButton.append($('<span data-i18n="button.copyclipboard">Copy to Clipboard</span>'));
          popoverTitle.append(copyButton);
          var clipboard = new Clipboard(copyButton[0], {
            text: function text(trigger) {
              return solutionEditor.getValue();
            }
          });
          clipboard.on('success', function (e) {
            thiz.$removeSolution(exercise);
            editor.focus();
          });
          copyButton.data('clipboard', clipboard);
        });

        _button.popover('show'); // left position of popover and arrow


        var popoverElement = exercise.find('.tutorial-solution-popover');
        popoverElement.css('left', '0');
        var popoverArrow = popoverElement.find('.arrow');
        popoverArrow.css('left', _button.position().left + _button.outerWidth() / 2 + 'px'); // scroll into view if necessary

        thiz.scrollIntoView(popoverElement); // translate the popover

        popoverElement.trigger('i18n');
      } else {
        thiz.$removeSolution(exercise);
      } // always refocus editor


      editor.focus();
    });
  }
}; // remove a solution for an exercise


Tutorial.prototype.$removeSolution = function (exercise) {
  // destroy clipboardjs object if we've got one
  var solutionButton = exercise.find('.btn-tutorial-copy-solution');

  if (solutionButton.length > 0) {
    solutionButton.data('clipboard').destroy();
  } // destroy popover
  // If window.bootstrap is found (>= bs4), use `'dispose'` method name. Otherwise, use `'destroy'` (bs3)


  exercise.find('.btn-tutorial-solution').popover(window.bootstrap ? 'dispose' : 'destroy');
};
/* Exercise evaluation */


Tutorial.prototype.$initializeExerciseEvaluation = function () {
  // alias this
  var thiz = this; // get the current label context of an element

  function exerciseLabel(el) {
    return thiz.$exerciseContainer(el).attr('data-label');
  } // ensure that the exercise containing this element is fully visible


  function ensureExerciseVisible(el) {
    // convert to containing exercise element
    var exerciseEl = thiz.$exerciseContainer(el)[0]; // ensure visibility

    thiz.scrollIntoView(exerciseEl);
  } // register a shiny input binding for code editors


  var exerciseInputBinding = new Shiny.InputBinding();
  $.extend(exerciseInputBinding, {
    find: function find(scope) {
      return $(scope).find('.tutorial-exercise-code-editor');
    },
    getValue: function getValue(el) {
      // return null if we haven't been clicked and this isn't a restore
      if (!this.clicked && !this.restore) {
        return null;
      } // value object to return


      var value = {}; // get the label

      value.label = exerciseLabel(el); // running code or submitting an answer for checking?

      value.should_check = this.should_check; // get the code from the editor

      var editor = ace.edit($(el).attr('id'));
      value.code = value.should_check ? editor.getSession().getValue() : editor.getSelectedText() || editor.getSession().getValue(); // restore flag

      value.restore = this.restore; // some randomness to ensure we re-execute on button clicks

      value.timestamp = new Date().getTime(); // return the value

      return value;
    },
    setValue: function setValue(el, value) {
      var editor = ace.edit($(el).attr('id'));
      editor.getSession().setValue(value.code); // Need to trigger a click for progressive mode.

      this.runButtons(el).trigger('click');

      if (window.shinytest) {
        // remove focus from editor when updating the value in shinyTest
        // to avoid false differences due to the blinking cursor
        setTimeout(function () {
          editor.blur();
        }, 0);
      }
    },
    getType: function getType(el) {
      return 'learnr.exercise';
    },
    subscribe: function subscribe(el, callBack) {
      var binding = this;
      this.runButtons(el).on('click.exerciseInputBinding', function (ev) {
        binding.restore = false;
        binding.clicked = true;
        binding.should_check = ev.delegateTarget.hasAttribute('data-check');
        callBack(true);
      });
      $(el).on('restore.exerciseInputBinding', function (ev, options) {
        binding.restore = true;
        binding.clicked = false;
        binding.should_check = options.should_check;
        callBack(true);
      });
    },
    unsubscribe: function unsubscribe(el) {
      this.runButtons(el).off('.exerciseInputBinding');
    },
    runButtons: function runButtons(el) {
      var exercise = thiz.$exerciseContainer(el);
      return exercise.find('.btn-tutorial-run');
    },
    restore: false,
    clicked: false,
    check: false
  });
  Shiny.inputBindings.register(exerciseInputBinding, 'tutorial.exerciseInput'); // register an output binding for exercise output

  var exerciseOutputBinding = new Shiny.OutputBinding();
  $.extend(exerciseOutputBinding, {
    find: function find(scope) {
      return $(scope).find('.tutorial-exercise-output');
    },
    onValueError: function onValueError(el, err) {
      Shiny.unbindAll(el);
      this.renderError(el, err);
    },
    renderValue: function renderValue(el, data) {
      // See big comment in showProgress method, below.
      thiz.$showExerciseProgress(exerciseLabel(el), null, false); // remove default content (if any)

      this.outputFrame(el).children().not($(el)).remove(); // render the content

      Shiny.renderContent(el, data); // bind bootstrap tables if necessary

      if (window.bootstrapStylePandocTables) {
        window.bootstrapStylePandocTables();
      } // bind paged tables if necessary


      if (window.PagedTableDoc) {
        window.PagedTableDoc.initAll();
      } // scroll exercise fully into view if we aren't restoring


      var restoring = thiz.$exerciseContainer(el).data('restoring');

      if (!restoring) {
        ensureExerciseVisible(el);
        thiz.$exerciseContainer(el).data('restoring', false);
      } else {
        thiz.$logTiming('restored-exercise-' + exerciseLabel(el));
      }
    },
    showProgress: function showProgress(el, show) {
      if (show) {
        thiz.$showExerciseProgress(exerciseLabel(el), null, show);
      } else {// This branch is intentionally empty. You'd expect that we would call
        //     thiz.$showExerciseProgress(exerciseLabel(el), null, show);
        // at this time, but we cannot due to a quirk in Shiny. Shiny assumes
        // that when we receive a new value for one output, then all outputs are
        // done; this is because all outputs are held and flushed together. I
        // (jcheng) don't know enough about learnr to know why this assumption
        // doesn't hold in this case, but it doesn't (issue #348). Instead, we
        // need to use renderValue as a proxy for showProgress(false).
      }
    },
    outputFrame: function outputFrame(el) {
      return $(el).closest('.tutorial-exercise-output-frame');
    }
  });
  Shiny.outputBindings.register(exerciseOutputBinding, 'tutorial.exerciseOutput');
};

Tutorial.prototype.$clearExerciseOutput = function (exercise) {
  var outputFrame = $(exercise).find('.tutorial-exercise-output-frame');
  var outputDiv = $(outputFrame).children('.tutorial-exercise-output');
  outputFrame.children().not(outputDiv).remove();
  outputDiv.empty();
};
/* Storage */


Tutorial.prototype.$initializeStorage = function (identifiers, success) {
  // alias this
  var thiz = this;

  if (!(typeof window.Promise !== 'undefined' && typeof window.indexedDB !== 'undefined')) {
    // can not do db stuff.
    // return early and do not create hooks
    success({});
    return;
  } // initialize data store. note that we simply ignore errors for interactions
  // with storage since the entire behavior is a nice-to-have (i.e. we automatically
  // degrade gracefully by either not restoring any state or restoring whatever
  // state we had stored)


  var dbName = 'LearnrTutorialProgress'; // var storeName = "Store_" + btoa(Math.random()).slice(0, 4);

  var storeName = 'Store_' + window.btoa(identifiers.tutorial_id + identifiers.tutorial_version);

  var closeStore = function closeStore(store) {
    store._dbp.then(function (db) {
      db.close();
    });
  }; // Validate that we can actually open a store. Some browsers (e.g. Safari)
  // pass the previous tests but will deny access to the idb store in certain
  // context (such as a cross-origin iframe). This check ensures that we fail
  // fast in such scenarios.


  var storeCreated;

  try {
    var testStore = new window.idbKeyval.Store(dbName, storeName);
    closeStore(testStore);
    storeCreated = true;
  } catch (error) {
    // Unable to open store.
    storeCreated = false;
  }

  if (storeCreated === false) {
    // can not do db stuff.
    // return early and do not create hooks
    success({});
    return;
  } // tl/dr; Do not keep indexedDB connections around
  // All interactions must:
  //   1. open the object store.
  //   2. do the transaction on the object store.
  //   3. close the object store.
  // Known store interactions:
  // * set answer
  // * clear all existing keys
  // * get all existing keys
  // Problem (if connections are kept alive):
  //   * If a new object store is to be added, this can only be done by opening a db connection with a higher version.
  //   * The "higher version" connection can not be opened until all other tabs have released their "older version" connection.
  // Approach:
  //   * By using the indexedDB in a "open, do, close" manor, all interactions will not be blocking all other tabs if a new object store is added.
  // Example:
  //   * If a tab connects, reads, disconnects...
  //   * Then another tab bumps the version...
  //   * Then, when the original tab wants to read the db, it can connect (db-version-less) and not have any issues
  // Notes:
  //   * indexedDB db version management is handled within idb-keyval
  // custom message handler to update store


  Shiny.addCustomMessageHandler('tutorial.store_object', function (message) {
    var idbStoreSet = new window.idbKeyval.Store(dbName, storeName);
    window.idbKeyval.set(message.id, message.data, idbStoreSet).catch(function (err) {
      console.error(err);
    }).finally(function () {
      closeStore(idbStoreSet);
    });
  }); // mask prototype to clear out all key/vals

  thiz.$removeState = function (completed) {
    var idbStoreClear = new window.idbKeyval.Store(dbName, storeName);
    window.idbKeyval.clear(idbStoreClear).then(completed).catch(function (err) {
      console.error(err);
      completed();
    }).finally(function () {
      closeStore(idbStoreClear);
    });
  }; // retreive the currently stored objects then pass them down to restore_state


  var idbStoreGet = new window.idbKeyval.Store(dbName, storeName);
  window.idbKeyval.keys(idbStoreGet).then(function (keys) {
    var getPromises = keys.map(function (key) {
      return window.idbKeyval.get(key, idbStoreGet);
    });
    return Promise.all(getPromises).then(function (vals) {
      var ret = {};
      var i;

      for (i = 0; i < keys.length; i++) {
        ret[keys[i]] = vals[i];
      }

      return ret;
    });
  }).then(function (objs) {
    success(objs);
  }).catch(function (err) {
    console.error(err);
    success({});
  }) // use finally to make sure it attempts to close
  .finally(function () {
    closeStore(idbStoreGet);
  });
};

Tutorial.prototype.$restoreState = function (objects) {
  // alias this
  var thiz = this; // retrieve state from server

  thiz.$logTiming('restoring-state');
  this.$serverRequest('restore_state', objects, function (data) {
    thiz.$logTiming('state-received'); // initialize client state

    thiz.$initializeClientState(data.client_state); // fire init event

    thiz.$fireInit(); // initialize progress

    thiz.$initializeProgress(data.progress_events); // restore exercise and question submissions

    thiz.$restoreSubmissions(data.submissions); // initialize video players

    thiz.$initializeVideoPlayers(data.video_progress);
  });
};

Tutorial.prototype.$restoreSubmissions = function (submissions) {
  // alias this
  var thiz = this;

  for (var i = 0; i < submissions.length; i++) {
    var submission = submissions[i];
    var type = submission.type;
    var id = submission.id; // exercise submissions

    if (type === 'exercise_submission') {
      // get code and checked status
      var label = id;
      var code = submission.data.code;
      var checked = submission.data.checked;
      thiz.$logTiming('restoring-exercise-' + label); // find the editor

      var editorContainer = thiz.$exerciseEditor(label);

      if (editorContainer.length > 0) {
        (function () {
          // restore code
          var editor = ace.edit(editorContainer.attr('id'));
          editor.setValue(code, -1);

          if (window.shinytest) {
            setTimeout(function () {
              editor.blur();
            }, 0);
          } // fire restore event on the container (also set
          // restoring flag on the exercise so we don't scroll it
          // into view after restoration)


          thiz.$exerciseForLabel(label).data('restoring', true);
          thiz.$showExerciseProgress(label, 'run', true);
          editorContainer.trigger('restore', {
            should_check: checked
          });
        })();
      }
    } // question_submission's are done with shiny directly

  }
};

Tutorial.prototype.$removeState = function (completed) {
  completed();
};

Tutorial.prototype.$initializeClientState = function (clientState) {
  // alias this
  var thiz = this; // client state object

  var clientStateLast = {
    scroll_position: 0,
    hash: ''
  }; // debounced checker for scroll position

  var maybePersistClientState = this.$debounce(function () {
    // get current client state
    var clientStateCurrent = {
      scroll_position: $(window).scrollTop(),
      hash: window.location.hash
    }; // if it changed then persist it and update last

    if (clientStateCurrent.scroll_position !== clientStateLast.scroll_position || clientStateCurrent.hash !== clientStateLast.hash) {
      thiz.$serverRequest('set_client_state', clientStateCurrent, null);
      clientStateLast = clientStateCurrent;
    }
  }, 1000); // check for client state on scroll position changed and hash changed

  $(window).scroll(maybePersistClientState);
  window.addEventListener('popstate', maybePersistClientState); // restore hash if there wasn't a hash already

  if (!window.location.hash && clientState.hash) {
    window.location.hash = clientState.hash;
  } // restore scroll position (don't do this for now as it ends up being
  // kind of janky)
  // if (client_state.scroll_position)
  //  $(window).scrollTop(client_state.scroll_position);

};
/* Server initialization */
// once we receive this message from the R side, we know that
// `register_http_handlers()` has been run, indicating that the
// Shiny server is ready to handle http requests


Shiny.addCustomMessageHandler('tutorial_isServerAvailable', function (message) {
  TUTORIAL_IS_SERVER_AVAILABLE = true;
});

Tutorial.prototype.$initializeServer = function () {
  // one-shot function to initialize server (wait for Shiny.shinyapp
  // to be available before attempting to call server)
  var thiz = this;
  thiz.$logTiming('wait-server-available');

  function initializeServer() {
    // retry after a delay
    function retry(delay) {
      setTimeout(function () {
        initializeServer();
      }, delay);
    } // wait for shiny config to be available (required for $serverRequest)


    if (TUTORIAL_IS_SERVER_AVAILABLE) {
      thiz.$logTiming('server-available');
      thiz.$serverRequest('initialize', {
        location: window.location
      }, function (response) {
        thiz.$logTiming('server-initialized'); // initialize storage then restore state

        thiz.$initializeStorage(response.identifiers, function (objects) {
          thiz.$logTiming('storage-initialized');
          thiz.$restoreState(objects);
        });
      });
    } else {
      retry(250);
    }
  } // call initialize function


  initializeServer();
};