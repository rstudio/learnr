/* global $,Shiny,ace,MathJax,ClipboardJS,YT,Vimeo,performance */

/* Tutorial construction and initialization */
import { TutorialDiagnostics } from './tutorial-diagnostics.mjs'
import { TutorialCompleter } from './tutorial-autocompletion.mjs'

$(document).ready(function () {
  const tutorial = new Tutorial()

  // register autocompletion if available
  if (typeof TutorialCompleter !== 'undefined') {
    tutorial.$completer = new TutorialCompleter(tutorial)
  }

  // register diagnostics if available
  if (typeof TutorialDiagnostics !== 'undefined') {
    tutorial.$diagnostics = new TutorialDiagnostics(tutorial)
  }

  window.tutorial = tutorial
})

// this var lets us know if the Shiny server is ready to handle http requests
let TUTORIAL_IS_SERVER_AVAILABLE = false

function Tutorial () {
  // Alias this
  const thiz = this

  // Init timing log
  this.$initTimingLog()

  // Are we using BS3?
  this.isBS3 = !window.bootstrap

  // API: provide init event
  this.onInit = function (handler) {
    this.$initCallbacks.add(handler)
  }

  // API: provide progress events
  this.onProgress = function (handler) {
    this.$progressCallbacks.add(handler)
  }

  // API: Start the tutorial over
  this.startOver = function () {
    thiz.$removeState(function () {
      thiz.$serverRequest('remove_state', null, function () {
        window.location.replace(
          window.location.origin + window.location.pathname
        )
      })
    })
  }

  // API: Skip a section
  this.skipSection = function (sectionId) {
    // wait for shiny config to be available (required for $serverRequest)
    if (TUTORIAL_IS_SERVER_AVAILABLE) {
      thiz.$serverRequest('section_skipped', { sectionId: sectionId }, null)
    }
  }

  // API: scroll an element into view
  this.scrollIntoView = function (element) {
    element = $(element)
    const rect = element[0].getBoundingClientRect()
    if (rect.top < 0 || rect.bottom > $(window).height()) {
      if (element[0].scrollIntoView) {
        element[0].scrollIntoView(false)
        document.body.scrollTop += 20
      }
    }
  }

  // Initialization
  thiz.$initializeVideos()
  thiz.$initializeExercises()
  thiz.$initializeServer()
}

/* Utilities */

Tutorial.prototype.$initTimingLog = function () {
  try {
    if (performance.mark !== undefined) {
      performance.mark('tutorial-start-mark')
    }
  } catch (e) {
    console.log('Error initializing log timing: ' + e.message)
  }
}

Tutorial.prototype.$logTiming = function (name) {
  try {
    if (
      performance.mark !== undefined &&
      performance.measure !== undefined &&
      performance.getEntriesByName !== undefined &&
      this.queryVar('log-timings') === '1'
    ) {
      performance.mark(name + '-mark')
      performance.measure(name, 'tutorial-start-mark', name + '-mark')
      const entries = performance.getEntriesByName(name)
      console.log(
        '(Timing) ' + name + ': ' + Math.round(entries[0].duration) + 'ms'
      )
    }
  } catch (e) {
    console.log('Error logging timing: ' + e.message)
  }
}

Tutorial.prototype.queryVar = function (name) {
  return decodeURI(
    window.location.search.replace(
      new RegExp(
        '^(?:.*[&\\?]' +
          encodeURI(name).replace(/[.+*]/g, '\\$&') +
          '(?:\\=([^&]*))?)?.*$',
        'i'
      ),
      '$1'
    )
  )
}

Tutorial.prototype.$idSelector = function (id) {
  return '#' + id.replace(/(:|\.|\[|\]|,|=|@)/g, '\\$1')
}

// static method to trigger MathJax
Tutorial.triggerMathJax = function () {
  if (window.MathJax) {
    MathJax.Hub.Queue(['Typeset', MathJax.Hub])
  }
}

/* Init callbacks */
Tutorial.prototype.$initCallbacks = $.Callbacks()

Tutorial.prototype.$fireInit = function () {
  // Alias this
  const thiz = this

  // fire event
  try {
    thiz.$initCallbacks.fire()
  } catch (e) {
    console.log(e)
  }
}

/* Progress callbacks */

Tutorial.prototype.$progressCallbacks = $.Callbacks()

Tutorial.prototype.$progressEvents = []

Tutorial.prototype.$hasCompletedProgressEvent = function (element) {
  const thiz = this
  for (let e = 0; e < thiz.$progressEvents.length; e++) {
    const event = thiz.$progressEvents[e]
    if ($(event.element).is($(element))) {
      if (event.completed) {
        return true
      }
    }
  }
  return false
}

Tutorial.prototype.$fireProgress = function (event) {
  // record it
  this.$progressEvents.push(event)

  // fire event
  try {
    this.$progressCallbacks.fire(event)
  } catch (e) {
    console.log(e)
  }
}

Tutorial.prototype.$fireSectionCompleted = function (element) {
  // Alias this
  const thiz = this

  // helper function to fire section completed
  function fireCompleted (el) {
    const event = {
      element: el,
      event: 'section_completed'
    }
    thiz.$fireProgress(event)
  }

  // find closest containing section (bail if there is none)
  const section = $(element)
    .parent()
    .closest('.section')
  if (section.length === 0) {
    return
  }

  // get all interactive components in the section
  const components = section.find(
    '.tutorial-exercise, .tutorial-question, .tutorial-video'
  )

  // are they all completed?
  let allCompleted = true
  for (let c = 0; c < components.length; c++) {
    const component = components.get(c)
    if (!thiz.$hasCompletedProgressEvent(component)) {
      allCompleted = false
      break
    }
  }

  // if they are then fire event
  if (allCompleted) {
    // fire the event
    fireCompleted($(section).get(0))

    // fire for preceding siblings if they have no interactive components
    const previousSections = section.prevAll('.section')
    previousSections.each(function () {
      const components = $(this).find('.tutorial-exercise, .tutorial-question')
      if (components.length === 0) {
        fireCompleted(this)
      }
    })

    // if there is another section above us then process it
    const parentSection = section.parent().closest('.section')
    if (parentSection.length > 0) {
      this.$fireSectionCompleted(section)
    }
  }
}

Tutorial.prototype.$removeConflictingProgressEvents = function (progressEvent) {
  // Alias this
  const thiz = this
  let event
  // work backwards as to avoid skipping a position caused by removing an element
  for (let i = thiz.$progressEvents.length - 1; i >= 0; i--) {
    event = thiz.$progressEvents[i]
    if (event.event === 'question_submission') {
      if (
        (event.data.label === progressEvent.data.label) &
        (progressEvent.data.label !== undefined)
      ) {
        // remove the item from existing progress events
        thiz.$progressEvents.splice(i, 1)
        return
      }
    }
  }
}

Tutorial.prototype.$fireProgressEvent = function (event, data) {
  // Alias this
  const thiz = this

  // progress event to fire
  const progressEvent = { event: event, data: data }

  // determine element and completed status
  if (event === 'exercise_submission' || event === 'question_submission') {
    const element = $(
      '.tutorial-exercise[data-label="' + data.label + '"]'
    ).add('.tutorial-question[data-label="' + data.label + '"]')
    if (element.length > 0) {
      progressEvent.element = element
      if (event === 'exercise_submission') {
        // Exercise completion logic is determined by the default exercise_result
        // event handler in the Shiny logic that emits an "exercise_submission" event.
        // If the handler doesn't returned a completed flag, we assume `true`.
        progressEvent.completed =
          typeof data.completed !== 'undefined' ? data.completed : true
      } else {
        // question_submission
        // questions may be reset with "try again", and not in a completed state
        progressEvent.completed = data.answer !== null
      }
    }
  } else if (event === 'section_skipped') {
    const exerciseElement = $(thiz.$idSelector(data.sectionId))
    progressEvent.element = exerciseElement
    progressEvent.completed = false
  } else if (event === 'video_progress') {
    const videoElement = $('iframe[src="' + data.video_url + '"]')
    if (videoElement.length > 0) {
      progressEvent.element = videoElement
      progressEvent.completed = 2 * data.time > data.total_time
    }
  }

  // remove any prior forms of this progressEvent
  this.$removeConflictingProgressEvents(progressEvent)

  // fire it if we found an element
  if (progressEvent.element) {
    // fire event
    this.$fireProgress(progressEvent)

    // synthesize higher level section completed events
    thiz.$fireSectionCompleted(progressEvent.element)
  }
}

Tutorial.prototype.$initializeProgress = function (progressEvents) {
  // Alias this
  const thiz = this

  // replay progress messages from previous state
  for (let i = 0; i < progressEvents.length; i++) {
    // get event
    const progress = progressEvents[i]
    const progressEvent = progress.event

    // determine data
    const progressEventData = {}
    if (progressEvent === 'exercise_submission') {
      progressEventData.label = progress.data.label
      progressEventData.correct = progress.data.correct
    } else if (progressEvent === 'question_submission') {
      progressEventData.label = progress.data.label
      progressEventData.answer = progress.data.answer
    } else if (progressEvent === 'section_skipped') {
      progressEventData.sectionId = progress.data.sectionId
    } else if (progressEvent === 'video_progress') {
      progressEventData.video_url = progress.data.video_url
      progressEventData.time = progress.data.time
      progressEventData.total_time = progress.data.total_time
    }

    thiz.$fireProgressEvent(progressEvent, progressEventData)
  }

  // handle subsequent progress messages
  Shiny.addCustomMessageHandler('tutorial.progress_event', function (progress) {
    thiz.$fireProgressEvent(progress.event, progress.data)
  })
}

/* Shared utility functions */

Tutorial.prototype.$serverRequest = function (type, data, success, error) {
  const { sessionId, workerId } = Shiny.shinyapp.config
  return $.ajax({
    type: 'POST',
    url: `session/${sessionId}/dataobj/${type}?w=${workerId}`,
    contentType: 'application/json',
    data: JSON.stringify(data),
    dataType: 'json',
    success: success,
    error: error
  })
}

// Record an event
Tutorial.prototype.$recordEvent = function (label, event, data) {
  const params = {
    label: label,
    event: event,
    data: data
  }
  this.$serverRequest('record_event', params, null)
}

Tutorial.prototype.$countLines = function (str) {
  return str.split(/\r\n|\r|\n/).length
}

Tutorial.prototype.$injectScript = function (src, onload) {
  const script = document.createElement('script')
  script.src = src
  const firstScriptTag = document.getElementsByTagName('script')[0]
  firstScriptTag.parentNode.insertBefore(script, firstScriptTag)
  $(script).on('load', onload)
}

Tutorial.prototype.$debounce = function (func, wait, immediate) {
  let timeout
  return function () {
    const context = this
    const args = arguments
    const later = function () {
      timeout = null
      if (!immediate) func.apply(context, args)
    }
    const callNow = immediate && !timeout
    clearTimeout(timeout)
    timeout = setTimeout(later, wait)
    if (callNow) func.apply(context, args)
  }
}

/* Videos */

Tutorial.prototype.$initializeVideos = function () {
  // regexes for video types
  const youtubeRegex = /^.*(youtu.be\/|v\/|u\/\w\/|embed\/|watch\?v=|&v=)([^#&?]*).*/
  const vimeoRegex = /(?:vimeo)\.com.*(?:videos|video|channels|)\/([\d]+)/i

  // check a url for video types
  function isYouTubeVideo (src) {
    return src.match(youtubeRegex)
  }
  function isVimeoVideo (src) {
    return src.match(vimeoRegex)
  }
  function isVideo (src) {
    return isYouTubeVideo(src) || isVimeoVideo(src)
  }

  // function to normalize a video src url (web view -> embed)
  function normalizeVideoSrc (src) {
    // youtube
    const youtubeMatch = src.match(youtubeRegex)
    if (youtubeMatch) {
      return `https://www.youtube.com/embed/${youtubeMatch[2]}?enablejsapi=1`
    }

    // vimeo
    const vimeoMatch = src.match(vimeoRegex)
    if (vimeoMatch) {
      return `https://player.vimeo.com/video/${vimeoMatch[1]}`
    }

    // default to reflecting src back
    return src
  }

  // function to set the width and height for the container conditioned on
  // any user-specified height and width
  function setContainerSize (container, width, height) {
    // default ratio
    const aspectRatio = 9 / 16

    // default width to 100% if not specified
    if (!width) {
      width = '100%'
    }

    // percentage based width
    if (width.slice(-1) === '%') {
      container.css('width', width)
      if (!height) {
        height = 0
        const paddingBottom = parseFloat(width) * aspectRatio + '%'
        container.css('padding-bottom', paddingBottom)
      }
      container.css('height', height)
    } else {
      // or another width unit, adding 'px' if necessary
      if ($.isNumeric(width)) {
        width = width + 'px'
      }
      container.css('width', width)
      if (!height) {
        height = parseFloat(width) * aspectRatio + 'px'
      }
      container.css('height', height)
    }
  }

  // inspect all images to see if they contain videos
  $('img').each(function () {
    // skip if this isn't a video
    const videoSrc = $(this).attr('src')
    if (!isVideo(videoSrc)) {
      return
    }

    // hide while we process
    $(this).css('display', 'none')

    // collect various attributes
    let width = $(this).get(0).style.width
    let height = $(this).get(0).style.height
    $(this)
      .css('width', '')
      .css('height', '')
    const attrs = {}
    $.each(this.attributes, function (idex, attr) {
      switch (attr.nodeName) {
        case 'width': {
          width = String(attr.nodeValue)
          break
        }
        case 'height': {
          height = String(attr.nodeValue)
          break
        }
        case 'src': {
          attrs.src = normalizeVideoSrc(attr.nodeValue)
          break
        }
        default: {
          attrs[attr.nodeName] = attr.nodeValue
        }
      }
    })

    // replace the image with the iframe inside a video container
    $(this).replaceWith(function () {
      const iframe = $('<iframe/>', attrs)
      iframe.addClass('tutorial-video')
      if (isYouTubeVideo(videoSrc)) {
        iframe.addClass('tutorial-video-youtube')
      } else if (isVimeoVideo(videoSrc)) {
        iframe.addClass('tutorial-video-vimeo')
      }
      iframe.attr('allowfullscreen', '')
      iframe.css('display', '')
      const container = $('<div class="tutorial-video-container"></div>')
      setContainerSize(container, width, height)
      container.append(iframe)
      return container
    })
  })

  // we'll initialize video player APIs off of $restoreState
  this.$logTiming('initialized-videos')
}

Tutorial.prototype.$initializeVideoPlayers = function (videoProgress) {
  // don't interact with video player APIs in Qt
  if (/\bQt\//.test(window.navigator.userAgent)) {
    return
  }

  this.$initializeYouTubePlayers(videoProgress)
  this.$initializeVimeoPlayers(videoProgress)
}

Tutorial.prototype.$videoPlayerRestoreTime = function (src, videoProgress) {
  // find a restore time for this video
  for (let v = 0; v < videoProgress.length; v++) {
    const id = videoProgress[v].id
    if (src === id) {
      const time = videoProgress[v].data.time
      const totalTime = videoProgress[v].data.total_time
      // don't return a restore time if we are within 10 seconds of the beginning
      // or the end of the video.
      if (time > 10 && totalTime - time > 10) {
        return time
      }
    }
  }

  // no time to restore, return 0
  return 0
}

Tutorial.prototype.$initializeYouTubePlayers = function (videoProgress) {
  // YouTube JavaScript API
  // https://developers.google.com/youtube/iframe_api_reference

  // alias this
  const thiz = this

  // attach to youtube videos
  const videos = $('iframe.tutorial-video-youtube')
  if (videos.length > 0) {
    this.$injectScript('https://www.youtube.com/iframe_api', function () {
      YT.ready(function () {
        videos.each(function () {
          // video and player
          const video = $(this)
          const videoUrl = video.attr('src')
          let player = null
          let lastState = -1

          // helper to report progress to the server
          function reportProgress () {
            thiz.$reportVideoProgress(
              videoUrl,
              player.getCurrentTime(),
              player.getDuration()
            )
          }

          // helper to restore video time. attempt to restore to 10 seconds prior
          // to the last save point (to recapture frame of reference)
          function restoreTime () {
            const restoreTime = thiz.$videoPlayerRestoreTime(
              videoUrl,
              videoProgress
            )
            if (restoreTime > 0) {
              player.mute()
              player.playVideo()
              setTimeout(function () {
                player.pauseVideo()
                player.seekTo(restoreTime, true)
                player.unMute()
              }, 2000)
            }
          }

          // function to call onReady
          function onReady () {
            restoreTime()
          }

          // function to call on state changed
          function onStateChange () {
            // get current state
            const state = player.getPlayerState()

            const isNotStarted = state === -1
            const isCued = state === YT.PlayerState.CUED
            const isPlaying = state === YT.PlayerState.PLAYING
            const isDuplicate = state === lastState

            // don't report for unstarted & queued
            // otherwise report if playing or non-duplicate state
            if (!(isNotStarted || isCued) && (isPlaying || isDuplicate)) {
              reportProgress()
            }

            // update last state
            lastState = state
          }

          // create the player
          player = new YT.Player(this, {
            events: {
              onReady: onReady,
              onStateChange: onStateChange
            }
          })

          // poll for state change every 5 seconds
          window.setInterval(onStateChange, 5000)
        })
      })
    })
  }
}

Tutorial.prototype.$initializeVimeoPlayers = function (videoProgress) {
  // alias this
  const thiz = this

  // Vimeo JavaScript API
  // https://github.com/vimeo/player.js

  const videos = $('iframe.tutorial-video-vimeo')
  if (videos.length > 0) {
    this.$injectScript('https://player.vimeo.com/api/player.js', function () {
      videos.each(function () {
        // video and player
        const video = $(this)
        const videoUrl = video.attr('src')
        const player = new Vimeo.Player(this)
        let lastReportedTime = null

        // restore time if we can
        player.ready().then(function () {
          const restoreTime = thiz.$videoPlayerRestoreTime(
            videoUrl,
            videoProgress
          )
          if (restoreTime > 0) {
            player.getVolume().then(function (volume) {
              player.setCurrentTime(restoreTime).then(function () {
                player.pause().then(function () {
                  player.setVolume(volume)
                })
              })
            })
          }
        })

        // helper function to report progress
        function reportProgress (data, throttle) {
          // default throttle to false
          if (throttle === undefined) {
            throttle = false
          }

          // if we are throttling then don't report if the last
          // reported time is within 5 seconds
          if (
            throttle &&
            lastReportedTime != null &&
            data.seconds - lastReportedTime < 5
          ) {
            return
          }

          // report progress
          thiz.$reportVideoProgress(videoUrl, data.seconds, data.duration)
          lastReportedTime = data.seconds
        }

        // report progress on various events
        player.on('play', reportProgress)
        player.on('pause', reportProgress)
        player.on('ended', reportProgress)
        player.on('timeupdate', function (data) {
          reportProgress(data, true)
        })
      })
    })
  }
}

Tutorial.prototype.$reportVideoProgress = function (videoUrl, time, totalTime) {
  this.$serverRequest('video_progress', {
    video_url: videoUrl,
    time: time,
    total_time: totalTime
  })
}

/* Exercise initialization and shared utility functions */

Tutorial.prototype.$initializeExercises = function () {
  this.$initializeExerciseEditors()
  this.$initializeExerciseSolutions()
  this.$initializeExerciseEvaluation()

  this.$logTiming('initialized-exercises')
}

Tutorial.prototype.$exerciseForLabel = function (label) {
  return $('.tutorial-exercise[data-label="' + label + '"]')
}

Tutorial.prototype.$forEachExercise = function (operation) {
  return $('.tutorial-exercise').each(function () {
    const exercise = $(this)
    operation(exercise)
  })
}

Tutorial.prototype.$exerciseSupportCode = function (label) {
  const selector = '.tutorial-exercise-support[data-label="' + label + '"]'
  const code = $(selector)
    .children('pre')
    .children('code')
  if (code.length > 0) {
    return code.text()
  } else {
    return null
  }
}

Tutorial.prototype.$exerciseSolutionCode = function (label) {
  return this.$exerciseSupportCode(label + '-solution')
}

Tutorial.prototype.$exerciseHintDiv = function (label) {
  // look for a div w/ hint id
  const id = 'section-' + label + '-hint'
  const hintDiv = $('div#' + id)

  // ensure it isn't a section then return
  if (hintDiv.length > 0 && !hintDiv.hasClass('section')) {
    return hintDiv
  } else {
    return null
  }
}

Tutorial.prototype.$exerciseHintsCode = function (label) {
  // look for a single hint
  let hint = this.$exerciseSupportCode(label + '-hint')
  if (hint !== null) {
    return [hint]
  }

  // look for a sequence of hints
  const hints = []
  let index = 1
  while (true) {
    const hintLabel = label + '-hint-' + index++
    hint = this.$exerciseSupportCode(hintLabel)
    if (hint !== null) {
      hints.push(hint)
    } else {
      break
    }
  }

  // return what we have (null if empty)
  if (hints.length > 0) {
    return hints
  } else {
    return null
  }
}

// get the exercise container of an element
Tutorial.prototype.$exerciseContainer = function (el) {
  return $(el).closest('.tutorial-exercise')
}

// show progress for exercise
Tutorial.prototype.$showExerciseProgress = function (label, button, show) {
  // references to various UI elements
  const exercise = this.$exerciseForLabel(label)
  const outputFrame = exercise.children('.tutorial-exercise-output-frame')
  const runButtons = exercise.find('.btn-tutorial-run')

  // if the button is "run" then use the run button
  if (button === 'run') {
    button = exercise.find('.btn-tutorial-run').last()
  }

  // show/hide progress UI
  const spinner = 'fa-spinner fa-spin fa-fw'
  if (show) {
    outputFrame.addClass('recalculating')
    runButtons.addClass('disabled')
    if (button !== null) {
      const runIcon = button.children('i')
      runIcon.removeClass(button.attr('data-icon'))
      runIcon.addClass(spinner)
    }
  } else {
    outputFrame.removeClass('recalculating')
    runButtons.removeClass('disabled')
    runButtons.each(function () {
      const button = $(this)
      const runIcon = button.children('i')
      runIcon.addClass(button.attr('data-icon'))
      runIcon.removeClass(spinner)
    })
  }
}

// behavior constants
Tutorial.prototype.kMinLines = 3

// edit code within an ace editor
Tutorial.prototype.$attachAceEditor = function (target, code, options) {
  const engineModes = {
    js: 'javascript'
  }
  const optsDefaults = { engine: 'r' }
  options = Object.assign({}, optsDefaults, options)
  options.engine = engineModes[options.engine] || options.engine

  const editor = ace.edit(target)
  editor.setHighlightActiveLine(false)
  editor.setShowPrintMargin(false)
  editor.setShowFoldWidgets(false)
  editor.setBehavioursEnabled(true)
  editor.renderer.setDisplayIndentGuides(false)
  editor.setTheme('ace/theme/textmate')
  editor.$blockScrolling = Infinity
  editor.session.setMode(`ace/mode/${options.engine}`)
  editor.session.getSelection().clearSelection()
  editor.session.setNewLineMode('unix')
  editor.setValue(code, -1)
  editor.setOptions({
    enableBasicAutocompletion: true
  })
  return editor
}

/* Exercise editor */

Tutorial.prototype.$exerciseEditor = function (label) {
  return this.$exerciseForLabel(label).find('.tutorial-exercise-code-editor')
}

Tutorial.prototype.$initializeExerciseEditors = function () {
  // alias this
  const thiz = this

  this.$forEachExercise(function (exercise) {
    // get the knitr options script block and detach it (will move to input div)
    const optsScript = exercise.children('script[data-ui-opts="1"]').detach()

    const optsChunk =
      optsScript.length === 1 ? JSON.parse(optsScript.text()) : {}

    // capture label and caption
    const label = exercise.attr('data-label')
    const caption = optsChunk.caption

    // helper to create an id
    function createId (suffix) {
      return 'tutorial-exercise-' + label + '-' + suffix
    }

    // when we receive focus hide solutions in other exercises
    exercise.on('focusin', function () {
      $('.btn-tutorial-solution').each(function () {
        if (exercise.has($(this)).length === 0) {
          thiz.$removeSolution(thiz.$exerciseContainer($(this)))
        }
      })
    })

    // get all <pre class='text'> elements, get their code, then remove them
    let code = ''
    const codeBlocks = exercise.children('pre.text, pre.lang-text')
    codeBlocks.each(function () {
      const codeElement = $(this).children('code')
      if (codeElement.length > 0) {
        code = code + codeElement.text()
      } else {
        code = code + $(this).text()
      }
    })
    codeBlocks.remove()
    // ensure a minimum of 3 lines
    const lines = code.split(/\r\n|\r|\n/).length
    for (let i = lines; i < thiz.kMinLines; i++) {
      code = code + '\n'
    }

    // wrap the remaining elements in an output frame div
    exercise.wrapInner('<div class="tutorial-exercise-output-frame"></div>')
    const outputFrame = exercise.children('.tutorial-exercise-output-frame')

    // create input div
    const inputDiv = $(
      '<div class="tutorial-exercise-input panel panel-default"></div>'
    )
    inputDiv.attr('id', createId('input'))

    // creating heading
    const panelHeading = $(
      '<div class="panel-heading tutorial-panel-heading"></div>'
    )
    inputDiv.append(panelHeading)
    const panelHeadingLeft = $(
      '<div class="tutorial-panel-heading-left"></div>'
    )
    const panelHeadingRight = $(
      '<div class="tutorial-panel-heading-right"></div>'
    )
    panelHeading.append(panelHeadingLeft)
    panelHeading.append(panelHeadingRight)

    panelHeadingLeft.html(caption)

    // create body
    const panelBody = $('<div class="panel-body"></div>')
    inputDiv.append(panelBody)

    // function to add a submit button
    function addSubmitButton (icon, style, text, check, datai18n) {
      const button = $(
        '<button class="btn ' + style + ' btn-xs btn-tutorial-run"></button>'
      )
      button.append($('<i class="fa ' + icon + '"></i>'))
      button.append(
        ' ' + '<span data-i18n="button.' + datai18n + '">' + text + '</span>'
      )
      const isMac = navigator.platform.toUpperCase().indexOf('MAC') >= 0
      let title = text
      const kbdText = (isMac ? 'Cmd' : 'Ctrl') + '+Shift+Enter'
      if (!check) {
        title = title + ' (' + kbdText + ')'
        button.attr('data-i18n-opts', '{"kbd": "' + kbdText + '"}')
      }
      button.attr('title', title)
      button.attr('data-i18n', '')
      button.attr('data-i18n-attr-title', 'button.' + datai18n + 'title')
      if (check) {
        button.attr('data-check', '1')
      }
      button.attr('data-icon', icon)
      button.on('click', function () {
        thiz.$removeSolution(exercise)
        thiz.$showExerciseProgress(label, button, true)
      })
      panelHeadingRight.append(button)
      return button
    }

    // create run button
    const runButton = addSubmitButton(
      'fa-play',
      'btn-success',
      'Run Code',
      false,
      'runcode'
    )

    // create submit answer button if checks are enabled
    if (optsChunk.has_checker) {
      addSubmitButton(
        'fa-check-square-o',
        'btn-primary',
        'Submit Answer',
        true,
        'submitanswer'
      )
    }

    // create code div and add it to the input div
    const codeDiv = $('<div class="tutorial-exercise-code-editor"></div>')
    const codeDivId = createId('code-editor')
    codeDiv.attr('id', codeDivId)
    panelBody.append(codeDiv)

    // add the knitr options script to the input div
    panelBody.append(optsScript)

    // prepend the input div to the exercise container
    exercise.prepend(inputDiv)

    // create an output div and append it to the output_frame
    const outputDiv = $('<div class="tutorial-exercise-output"></div>')
    outputDiv.attr('id', createId('output'))
    outputFrame.append(outputDiv)

    // activate the ace editor
    const editor = thiz.$attachAceEditor(codeDivId, code, optsChunk)

    // get setup_code (if any)
    const setupCode = null

    // use code completion
    const completion = exercise.attr('data-completion') === '1'
    let diagnostics = exercise.attr('data-diagnostics') === '1'

    // support startover
    const startoverCode = exercise.attr('data-startover') === '1' ? code : null

    // get the engine
    const engine = optsChunk.engine

    if (engine.toLowerCase() !== 'r') {
      // disable ace editor diagnostics if a non-r language engine is set
      diagnostics = null
    }

    // set tutorial options/data
    editor.tutorial = {
      label: label,
      engine: engine,
      setup_code: setupCode,
      completion: completion,
      diagnostics: diagnostics,
      startover_code: startoverCode
    }

    // bind execution keys
    function bindExecutionKey (name, key) {
      const macKey = key.replace('Ctrl+', 'Command+')
      editor.commands.addCommand({
        name: name,
        bindKey: { win: key, mac: macKey },
        exec: function (editor) {
          runButton.trigger('click')
        }
      })
    }
    bindExecutionKey('execute1', 'Ctrl+Enter')
    bindExecutionKey('execute2', 'Ctrl+Shift+Enter')

    function bindInsertKey (name, keys, text) {
      if (typeof keys === 'string') {
        keys = { win: keys, mac: keys.replace('Ctrl+', 'Command+') }
      }
      if (typeof text === 'string') {
        text = { r: text, fallback: text }
      }
      editor.commands.addCommand({
        name: name,
        bindKey: keys,
        exec: function (editor) {
          if (text[editor.tutorial.engine]) {
            editor.insert(text[editor.tutorial.engine])
          } else if (text.fallback) {
            editor.insert(text.fallback)
          }
        }
      })
    }
    bindInsertKey('insertPipe', 'Ctrl+Shift+M', { r: ' %>% ' })
    bindInsertKey('insertArrow', 'Alt+-', { r: ' <- ', fallback: ' = ' })

    // re-focus the editor on run button click
    runButton.on('click', function () {
      editor.focus()
    })

    // Allow users to escape the editor and move to next focusable element
    function toggleTabCommands (enable) {
      const tabCommandKeys = {
        indent: { win: 'Tab', mac: 'Tab' },
        outdent: { win: 'Shift+Tab', mac: 'Shift+Tab' }
      }

      ;['indent', 'outdent'].forEach(function (name) {
        const command = editor.commands.byName[name]
        // turn off tab commands or restore original bindKey
        command.bindKey = enable ? tabCommandKeys[name] : null
        editor.commands.addCommand(command)
      })
      // update class on editor to reflect tab command state
      $(editor.container).toggleClass('ace_indent_off', !enable)
    }

    editor.on('focus', function () {
      toggleTabCommands(true)
    })

    editor.commands.addCommand({
      name: 'escape',
      bindKey: { win: 'Esc', mac: 'Esc' },
      exec: function () {
        toggleTabCommands(false)
      }
    })

    // manage ace height as the document changes
    const updateAceHeight = function () {
      const lines = exercise.attr('data-lines')
      if (lines && lines > 0) {
        editor.setOptions({
          minLines: lines,
          maxLines: lines
        })
      } else {
        editor.setOptions({
          minLines: thiz.kMinLines,
          maxLines: Math.max(
            Math.min(editor.session.getLength(), 15),
            thiz.kMinLines
          )
        })
      }
    }
    updateAceHeight()
    editor.getSession().on('change', updateAceHeight)

    // add hint/solution/startover buttons if necessary
    thiz.$addSolution(exercise, panelHeadingLeft, editor)

    exercise.parents('.section').on('shown', function () {
      editor.resize(true)
    })
  })
}

/* Exercise solutions */

Tutorial.prototype.$initializeExerciseSolutions = function () {
  // alias this
  const thiz = this

  // hide solutions when clicking outside exercises
  $(document).on('mouseup', function (ev) {
    const exercise = thiz.$exerciseContainer(ev.target)
    if (exercise.length === 0) {
      thiz.$forEachExercise(thiz.$removeSolution)
    }
  })
}

// add a solution for the specified exercise label
Tutorial.prototype.$addSolution = function (exercise, panelHeading, editor) {
  // alias this
  const thiz = this

  // get label
  const label = exercise.attr('data-label')

  // solution/hints (in the presence of hints convert solution to last hint)
  let solution = thiz.$exerciseSolutionCode(label)
  const hints = thiz.$exerciseHintsCode(label)
  if (hints !== null && solution !== null) {
    hints.push(solution)
    solution = null
  }
  const hintDiv = thiz.$exerciseHintDiv(label)

  // function to add a helper button
  function addHelperButton (icon, caption, classBtn, datai18n) {
    const button = $(
      '<button class="btn btn-light btn-xs btn-tutorial-solution"></button>'
    )
    button.attr('title', caption)
    button.attr('data-i18n', '')
    button.addClass(classBtn)
    button.append($('<i class="fa ' + icon + '"></i>'))
    if (datai18n) {
      if (typeof datai18n === 'string') {
        datai18n = { key: datai18n }
      }
      button.attr('data-i18n-attr-title', datai18n.key + 'title')
      const buttonText = $(
        `<span class="d-none d-sm-inline-block d-md-none d-lg-inline-block">${caption}</span>`
      )
      buttonText.attr('data-i18n', datai18n.key)
      if (datai18n.opts) {
        buttonText.attr('data-i18n-opts', JSON.stringify(datai18n.opts))
      }
      button.append(document.createTextNode(' '))
      button.append(buttonText)
      if (datai18n.opts) {
        button.attr('data-i18n-opts', JSON.stringify(datai18n.opts))
      }
    } else {
      button.append(' ' + caption)
    }
    panelHeading.append(button)
    return button
  }

  // function to add a hint button
  function addHintButton (caption, datai18n) {
    datai18n = datai18n || 'button.hint'
    return addHelperButton(
      'fa-lightbulb-o',
      caption,
      'btn-tutorial-hint',
      datai18n
    )
  }

  // helper function to record solution/hint requests
  function recordHintRequest (index) {
    thiz.$recordEvent(label, 'exercise_hint', {
      type: solution !== null ? 'solution' : 'hint',
      index: index
    })
  }

  // add a startover button
  if (editor.tutorial.startover_code !== null) {
    const startOverButton = addHelperButton(
      'fa-refresh',
      'Start Over',
      'btn-tutorial-start-over',
      'button.startover'
    )
    startOverButton.on('click', function () {
      editor.setValue(editor.tutorial.startover_code, -1)
      thiz.$clearExerciseOutput(exercise)
    })
  }

  // if we have a hint div
  if (hintDiv != null) {
    // mark the div as a hint and hide it
    hintDiv.addClass('tutorial-hint')
    hintDiv.css('display', 'none')

    // create hint button
    const button = addHintButton('Hint', { key: 'button.hint', count: 1 })

    // handle showing and hiding the hint
    button.on('click', function () {
      // record the request
      recordHintRequest(0)

      // prepend it to the output frame (if a hint isn't already in there)
      const outputFrame = exercise.children('.tutorial-exercise-output-frame')
      if (outputFrame.find('.tutorial-hint').length === 0) {
        const panel = $(
          `<div class="${thiz.isBS3 ? 'panel panel-default' : 'card'} tutorial-hint-panel"></div>`
        )
        const panelBody = $(`<div class="${thiz.isBS3 ? 'panel-body' : 'card-body'}></div>`)
        const hintDivClone = hintDiv
          .clone()
          .attr('id', '')
          .css('display', 'inherit')
        panelBody.append(hintDivClone)
        panel.append(panelBody)
        outputFrame.prepend(panel)
      } else {
        outputFrame.find('.tutorial-hint-panel').remove()
      }
    })
  } else if (solution || hints) {
    // else if we have a solution or hints
    const isSolution = solution !== null

    // determine editor lines
    let editorLines = thiz.kMinLines
    if (solution) {
      editorLines = Math.max(thiz.$countLines(solution), editorLines)
    } else {
      for (let i = 0; i < hints.length; i++) {
        editorLines = Math.max(thiz.$countLines(hints[i]), editorLines)
      }
    }

    // track hint index
    let hintIndex = 0

    // create solution button
    const button = addHintButton(
      isSolution ? 'Solution' : hints.length > 1 ? 'Hints' : 'Hint',
      isSolution
        ? { key: 'button.solution', count: 1 }
        : { key: 'button.hint', opts: { count: hints.length } }
    )

    // handle showing and hiding the popover
    button.on('click', function (ev) {
      // record the request
      recordHintRequest(hintIndex)

      // determine solution text
      const solutionText = solution !== null ? solution : hints[hintIndex]

      const visible = button.parent().find('div.popover:visible').length > 0

      if (visible) {
        console.log('Removing hint popover', ev)
        thiz.$removeSolution(exercise)
        editor.focus()
        return
      }

      console.log('Revealing hint popover', ev)
      const popover = button.popover({
        placement: 'top',
        template:
          '<div class="popover tutorial-solution-popover" role="tooltip">' +
          '<div class="arrow"></div>' +
          '<div class="popover-title tutorial-panel-heading"></div>' +
          '<div class="popover-content"></div>' +
          '</div>',
        content: solutionText,
        container: button.parent(),
        boundary: $('.topics').get(0),
        viewport: $('.topics').get(0)
        // trigger: 'manual'
      })

      let popoverIsInserted = false

      popover.on('inserted.bs.popover', function (ev) {
        if (popoverIsInserted) return
        console.log('Instantiating hint popover', ev)

        // get popover element
        const popoverTip = thiz.isBS3
          ? popover.data('bs.popover').tip()
          : $(window.bootstrap.Popover.getInstance(popover).tip)

        const content = popoverTip.find('.popover-content')

        // adjust editor and container height
        const solutionEditor = thiz.$attachAceEditor(
          content.get(0),
          solutionText // FIXME get exercise engine
        )
        solutionEditor.setReadOnly(true)
        solutionEditor.setOption('minLines', Math.min(editorLines, 10))
        solutionEditor.setOption('maxLines', 10)
        setTimeout(() => {
          // Re-position the popover in the next tick when we know the height.
          // We used to be able to do this by knowing the editor line height
          // but in Ace >= 1.3 that value is populated asyncronously.
          content.parent().css('top', `-${content.parent().height()}px`)
        })

        // get title panel
        const popoverTitle = popoverTip.find('.popover-title')

        // add next hint button if we have > 1 hint
        if (solution === null && hints.length > 1) {
          const nextHintButton = $(
            `<button class="btn btn-light ${thiz.isBS3 ? 'btn-xs' : 'btn-sm'} btn-tutorial-next-hint"></button>`
          )
          nextHintButton.append(
            $('<span data-i18n="button.hintnext">Next Hint</span>')
          )
          nextHintButton.append(' ')
          nextHintButton.append($('<i class="fa fa-angle-double-right"></i>'))
          nextHintButton.on('click', function () {
            hintIndex = hintIndex + 1
            solutionEditor.setValue(hints[hintIndex], -1)
            if (hintIndex === hints.length - 1) {
              nextHintButton.addClass('disabled')
              nextHintButton.prop('disabled', true)
            }
            recordHintRequest(hintIndex)
          })
          if (hintIndex === hints.length - 1) {
            nextHintButton.addClass('disabled')
            nextHintButton.prop('disabled', true)
          }
          popoverTitle.append(nextHintButton)
        }

        // add copy button
        const copyButton = $(
          `<button class="btn btn-info ${thiz.isBS3 ? 'btn-xs' : 'btn-sm'} btn-tutorial-copy-solution pull-right"></button>`
        )
        copyButton.append($('<i class="fa fa-copy"></i>'))
        copyButton.append(' ')
        copyButton.append(
          $('<span data-i18n="button.copyclipboard">Copy to Clipboard</span>')
        )
        popoverTitle.append(copyButton)
        const clipboard = new ClipboardJS(copyButton[0], {
          text: function (trigger) {
            return solutionEditor.getValue()
          }
        })
        clipboard.on('success', function (e) {
          thiz.$removeSolution(exercise)
          editor.focus()
        })
        copyButton.data('clipboard', clipboard)

        // left position of popover and arrow
        popoverTip.css('left', '0')
        const popoverArrow = popoverTip.find('.arrow')
        popoverArrow.css(
          'left',
          button.position().left + button.outerWidth() / 2 + 'px'
        )

        // translate the popover
        popoverTip.trigger('i18n')

        popoverIsInserted = true
      })

      button.on('shown.bs.popover', function () {
        // scroll into view if necessary
        const popoverElement = $('.tutorial-solution-popover')
        thiz.scrollIntoView(popoverElement)

        // resize popover element to fit contents
        if (!thiz.isBS3) {
          window.bootstrap.Popover.getInstance(popover).update()
        }
      })

      button.popover('show')

      // always refocus editor
      editor.focus()
    })
  }
}

// remove a solution for an exercise
Tutorial.prototype.$removeSolution = function (exercise) {
  // destroy clipboardjs object if we've got one
  const solutionButton = exercise.find('.btn-tutorial-copy-solution')
  if (solutionButton.length > 0) {
    solutionButton.data('clipboard').destroy()
  }

  // destroy popover
  // If window.bootstrap is found (>= bs4), use `'dispose'` method name. Otherwise, use `'destroy'` (bs3)
  if (window.bootstrap) {
    const popover = exercise.find('.tutorial-solution-popover')
    if (!popover.length) return
    window.bootstrap.Popover.getInstance(popover.get(0)).dispose()
  } else {
    exercise.find('.tutorial-solution-popover').popover('destroy')
  }
}

/* Exercise evaluation */

Tutorial.prototype.$initializeExerciseEvaluation = function () {
  // alias this
  const thiz = this

  // get the current label context of an element
  function exerciseLabel (el) {
    return thiz.$exerciseContainer(el).attr('data-label')
  }

  // ensure that the exercise containing this element is fully visible
  function ensureExerciseVisible (el) {
    // convert to containing exercise element
    const exerciseEl = thiz.$exerciseContainer(el)[0]

    // ensure visibility
    thiz.scrollIntoView(exerciseEl)
  }

  // register a shiny input binding for code editors
  const exerciseInputBinding = new Shiny.InputBinding()
  $.extend(exerciseInputBinding, {
    find: function (scope) {
      return $(scope).find('.tutorial-exercise-code-editor')
    },

    getValue: function (el) {
      // return null if we haven't been clicked and this isn't a restore
      if (!this.clicked && !this.restore) {
        return null
      }

      // value object to return
      const value = {}

      // get the label
      value.label = exerciseLabel(el)

      // running code or submitting an answer for checking?
      value.should_check = this.should_check

      // get the code from the editor
      const editor = ace.edit($(el).attr('id'))
      value.code = value.should_check
        ? editor.getSession().getValue()
        : editor.getSelectedText() || editor.getSession().getValue()

      // restore flag
      value.restore = this.restore

      // some randomness to ensure we re-execute on button clicks
      value.timestamp = new Date().getTime()

      // return the value
      return value
    },

    setValue: function (el, value) {
      const editor = ace.edit($(el).attr('id'))
      editor.getSession().setValue(value.code)
      // Need to trigger a click for progressive mode.
      this.runButtons(el).trigger('click')
      if (window.shinytest) {
        // remove focus from editor when updating the value in shinyTest
        // to avoid false differences due to the blinking cursor
        setTimeout(function () {
          editor.blur()
        }, 0)
      }
    },

    getType: function (el) {
      return 'learnr.exercise'
    },

    subscribe: function (el, callBack) {
      const binding = this
      this.runButtons(el).on('click.exerciseInputBinding', function (ev) {
        binding.restore = false
        binding.clicked = true
        binding.should_check = ev.delegateTarget.hasAttribute('data-check')
        callBack(true)
      })
      $(el).on('restore.exerciseInputBinding', function (ev, options) {
        binding.restore = true
        binding.clicked = false
        binding.should_check = options.should_check
        callBack(true)
      })
    },

    unsubscribe: function (el) {
      this.runButtons(el).off('.exerciseInputBinding')
    },

    runButtons: function (el) {
      const exercise = thiz.$exerciseContainer(el)
      return exercise.find('.btn-tutorial-run')
    },

    restore: false,
    clicked: false,
    check: false
  })
  Shiny.inputBindings.register(exerciseInputBinding, 'tutorial.exerciseInput')

  // register an output binding for exercise output
  const exerciseOutputBinding = new Shiny.OutputBinding()
  $.extend(exerciseOutputBinding, {
    find: function find (scope) {
      return $(scope).find('.tutorial-exercise-output')
    },

    onValueError: function onValueError (el, err) {
      Shiny.unbindAll(el)
      this.renderError(el, err)
    },

    renderValue: function renderValue (el, data) {
      // See big comment in showProgress method, below.
      thiz.$showExerciseProgress(exerciseLabel(el), null, false)

      // remove default content (if any)
      this.outputFrame(el)
        .children()
        .not($(el))
        .remove()

      // render the content
      Shiny.renderContent(el, data)

      // bind bootstrap tables if necessary
      if (window.bootstrapStylePandocTables) {
        window.bootstrapStylePandocTables()
      }

      // bind paged tables if necessary
      if (window.PagedTableDoc) {
        window.PagedTableDoc.initAll()
      }

      // scroll exercise fully into view if we aren't restoring
      const restoring = thiz.$exerciseContainer(el).data('restoring')
      if (!restoring) {
        ensureExerciseVisible(el)
        thiz.$exerciseContainer(el).data('restoring', false)
      } else {
        thiz.$logTiming('restored-exercise-' + exerciseLabel(el))
      }
    },

    showProgress: function (el, show) {
      if (show) {
        thiz.$showExerciseProgress(exerciseLabel(el), null, show)
      } else {
        // This branch is intentionally empty. You'd expect that we would call
        //     thiz.$showExerciseProgress(exerciseLabel(el), null, show);
        // at this time, but we cannot due to a quirk in Shiny. Shiny assumes
        // that when we receive a new value for one output, then all outputs are
        // done; this is because all outputs are held and flushed together. I
        // (jcheng) don't know enough about learnr to know why this assumption
        // doesn't hold in this case, but it doesn't (issue #348). Instead, we
        // need to use renderValue as a proxy for showProgress(false).
      }
    },

    outputFrame: function (el) {
      return $(el).closest('.tutorial-exercise-output-frame')
    }
  })
  Shiny.outputBindings.register(
    exerciseOutputBinding,
    'tutorial.exerciseOutput'
  )
}

Tutorial.prototype.$clearExerciseOutput = function (exercise) {
  const outputFrame = $(exercise).find('.tutorial-exercise-output-frame')
  const outputDiv = $(outputFrame).children('.tutorial-exercise-output')
  outputFrame
    .children()
    .not(outputDiv)
    .remove()
  outputDiv.empty()
}

/* Storage */
Tutorial.prototype.$initializeStorage = function (identifiers, success) {
  // alias this
  const thiz = this

  if (
    !(
      typeof window.Promise !== 'undefined' &&
      typeof window.indexedDB !== 'undefined'
    )
  ) {
    // can not do db stuff.
    // return early and do not create hooks
    success({})
    return
  }

  // initialize data store. note that we simply ignore errors for interactions
  // with storage since the entire behavior is a nice-to-have (i.e. we automatically
  // degrade gracefully by either not restoring any state or restoring whatever
  // state we had stored)
  const dbName = 'LearnrTutorialProgress'
  // var storeName = "Store_" + btoa(Math.random()).slice(0, 4);
  const storeName =
    'Store_' +
    window.btoa(identifiers.tutorial_id + identifiers.tutorial_version)

  const closeStore = function (store) {
    store._dbp.then(function (db) {
      db.close()
    })
  }

  // Validate that we can actually open a store. Some browsers (e.g. Safari)
  // pass the previous tests but will deny access to the idb store in certain
  // context (such as a cross-origin iframe). This check ensures that we fail
  // fast in such scenarios.
  let storeCreated
  try {
    const testStore = new window.idbKeyval.Store(dbName, storeName)
    closeStore(testStore)
    storeCreated = true
  } catch (error) {
    // Unable to open store.
    storeCreated = false
  }
  if (storeCreated === false) {
    // can not do db stuff.
    // return early and do not create hooks
    success({})
    return
  }

  // tl/dr; Do not keep indexedDB connections around

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
    const idbStoreSet = new window.idbKeyval.Store(dbName, storeName)

    window.idbKeyval
      .set(message.id, message.data, idbStoreSet)
      .catch(function (err) {
        console.error(err)
      })
      .finally(function () {
        closeStore(idbStoreSet)
      })
  })

  // mask prototype to clear out all key/vals
  thiz.$removeState = function (completed) {
    const idbStoreClear = new window.idbKeyval.Store(dbName, storeName)

    window.idbKeyval
      .clear(idbStoreClear)
      .then(completed)
      .catch(function (err) {
        console.error(err)
        completed()
      })
      .finally(function () {
        closeStore(idbStoreClear)
      })
  }

  // retreive the currently stored objects then pass them down to restore_state
  const idbStoreGet = new window.idbKeyval.Store(dbName, storeName)
  window.idbKeyval
    .keys(idbStoreGet)
    .then(function (keys) {
      const getPromises = keys.map(function (key) {
        return window.idbKeyval.get(key, idbStoreGet)
      })
      return Promise.all(getPromises).then(function (vals) {
        const ret = {}
        let i
        for (i = 0; i < keys.length; i++) {
          ret[keys[i]] = vals[i]
        }
        return ret
      })
    })
    .then(function (objs) {
      success(objs)
    })
    .catch(function (err) {
      console.error(err)
      success({})
    })
    // use finally to make sure it attempts to close
    .finally(function () {
      closeStore(idbStoreGet)
    })
}

Tutorial.prototype.$restoreState = function (objects) {
  // alias this
  const thiz = this

  // retrieve state from server
  thiz.$logTiming('restoring-state')
  this.$serverRequest('restore_state', objects, function (data) {
    thiz.$logTiming('state-received')

    // initialize client state
    thiz.$initializeClientState(data.client_state)

    // fire init event
    thiz.$fireInit()

    // initialize progress
    thiz.$initializeProgress(data.progress_events)

    // restore exercise and question submissions
    thiz.$restoreSubmissions(data.submissions)

    // initialize video players
    thiz.$initializeVideoPlayers(data.video_progress)
  })
}

Tutorial.prototype.$restoreSubmissions = function (submissions) {
  // alias this
  const thiz = this

  for (let i = 0; i < submissions.length; i++) {
    const submission = submissions[i]
    const type = submission.type
    const id = submission.id

    // exercise submissions
    if (type === 'exercise_submission') {
      // get code and checked status
      const label = id
      const code = submission.data.code
      const checked = submission.data.checked

      thiz.$logTiming('restoring-exercise-' + label)

      // find the editor
      const editorContainer = thiz.$exerciseEditor(label)
      if (editorContainer.length > 0) {
        // restore code
        const editor = ace.edit(editorContainer.attr('id'))
        editor.setValue(code, -1)
        if (window.shinytest) {
          setTimeout(function () {
            editor.blur()
          }, 0)
        }

        // fire restore event on the container (also set
        // restoring flag on the exercise so we don't scroll it
        // into view after restoration)
        thiz.$exerciseForLabel(label).data('restoring', true)
        thiz.$showExerciseProgress(label, 'run', true)
        editorContainer.trigger('restore', {
          should_check: checked
        })
      }
    }
    // question_submission's are done with shiny directly
  }
}

Tutorial.prototype.$removeState = function (completed) {
  completed()
}

Tutorial.prototype.$initializeClientState = function (clientState) {
  // alias this
  const thiz = this

  // client state object
  let clientStateLast = {
    scroll_position: 0,
    hash: ''
  }

  // debounced checker for scroll position
  const maybePersistClientState = this.$debounce(function () {
    // get current client state
    const clientStateCurrent = {
      scroll_position: $(window).scrollTop(),
      hash: window.location.hash
    }

    // if it changed then persist it and update last
    if (
      clientStateCurrent.scroll_position !== clientStateLast.scroll_position ||
      clientStateCurrent.hash !== clientStateLast.hash
    ) {
      thiz.$serverRequest('set_client_state', clientStateCurrent, null)
      clientStateLast = clientStateCurrent
    }
  }, 1000)

  // check for client state on scroll position changed and hash changed
  $(window).scroll(maybePersistClientState)
  window.addEventListener('popstate', maybePersistClientState)

  // restore hash if there wasn't a hash already
  if (!window.location.hash && clientState.hash) {
    window.location.hash = clientState.hash
  }

  // restore scroll position (don't do this for now as it ends up being
  // kind of janky)
  // if (client_state.scroll_position)
  //  $(window).scrollTop(client_state.scroll_position);
}

/* Server initialization */

// once we receive this message from the R side, we know that
// `register_http_handlers()` has been run, indicating that the
// Shiny server is ready to handle http requests
Shiny.addCustomMessageHandler('tutorial_isServerAvailable', function (message) {
  TUTORIAL_IS_SERVER_AVAILABLE = true
})

Tutorial.prototype.$initializeServer = function () {
  // one-shot function to initialize server (wait for Shiny.shinyapp
  // to be available before attempting to call server)
  const thiz = this
  thiz.$logTiming('wait-server-available')
  function initializeServer () {
    // retry after a delay
    function retry (delay) {
      setTimeout(function () {
        initializeServer()
      }, delay)
    }

    // wait for shiny config to be available (required for $serverRequest)
    if (TUTORIAL_IS_SERVER_AVAILABLE) {
      thiz.$logTiming('server-available')
      thiz.$serverRequest(
        'initialize',
        { location: window.location },
        function (response) {
          thiz.$logTiming('server-initialized')
          // initialize storage then restore state
          thiz.$initializeStorage(response.identifiers, function (objects) {
            thiz.$logTiming('storage-initialized')
            thiz.$restoreState(objects)
          })
        }
      )
    } else {
      retry(250)
    }
  }

  // call initialize function
  initializeServer()
}

window.Tutorial = Tutorial
