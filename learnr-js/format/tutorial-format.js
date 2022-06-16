/* global $,tutorial,Shiny,i18next,bootbox */

$(document).ready(function () {
  let titleText = ''
  let currentTopicIndex = -1
  let docProgressiveReveal = false
  let docAllowSkip = false
  const topics = []

  let scrollLastSectionToView = false
  let scrollLastSectionPosition = 0

  // Callbacks that are triggered when setCurrentTopic() is called.
  const setCurrentTopicNotifiers = (function () {
    let notifiers = []

    return {
      add: function (id, callback) {
        notifiers.push({ id: id, callback: callback })
      },
      remove: function (id) {
        notifiers = notifiers.filter(function (x) {
          return id !== x.id
        })
      },
      invoke: function () {
        for (let i = 0; i < notifiers.length; i++) {
          notifiers[i].callback()
        }
      }
    }
  })()

  function setCurrentTopic (topicIndex, notify) {
    if (typeof notify === 'undefined') {
      notify = true
    }
    if (topics.length === 0) return

    topicIndex = topicIndex * 1 // convert strings to a number

    if (topicIndex === currentTopicIndex) return

    if (currentTopicIndex !== -1) {
      const el = $(topics[currentTopicIndex].jqElement)
      el.trigger('hide')
      el.removeClass('current')
      el.trigger('hidden')
      $(topics[currentTopicIndex].jqListElement).removeClass('current')
    }

    const currentEl = $(topics[topicIndex].jqElement)
    currentEl.trigger('show')
    currentEl.addClass('current')
    currentEl.trigger('shown')
    $(topics[topicIndex].jqListElement).addClass('current')
    currentTopicIndex = topicIndex

    if (notify) {
      setCurrentTopicNotifiers.invoke()
    }

    // always start a topic with a the scroll pos at the top
    // we do this in part to prevent the scroll to view behavior of hash navigation
    setTimeout(function () {
      $(document).scrollTop(0)
    }, 0)
  }

  function updateLocation (topicIndex) {
    const baseUrl = window.location.href.replace(window.location.hash, '')
    window.location = `${baseUrl}#${topics[topicIndex].id}`
  }

  function handleTopicClick (event) {
    hideFloatingTopics()
    updateLocation(this.getAttribute('index'))
  }

  function showFloatingTopics () {
    $('.topicsList').removeClass('hideFloating')
  }

  function hideFloatingTopics () {
    $('.topicsList').addClass('hideFloating')
  }

  function updateVisibilityOfTopicElements (topicIndex) {
    resetSectionVisibilityList()

    const topic = topics[topicIndex]

    if (!topic.progressiveReveal) return

    let showSection = true
    let lastVisibleSection = null

    for (let i = 0; i < topic.sections.length; i++) {
      const section = topic.sections[i]
      const sectionEl = $(section.jqElement)
      if (showSection) {
        sectionEl.trigger('show')
        sectionEl.removeClass('hide')
        sectionEl.trigger('shown')
        if (section.skipped) {
          sectionEl.removeClass('showSkip')
        } else {
          sectionEl.addClass('showSkip')
          lastVisibleSection = sectionEl
        }
      } else {
        sectionEl.trigger('hide')
        sectionEl.addClass('hide')
        sectionEl.trigger('hidden')
      }
      showSection = showSection && section.skipped
    }

    if (!topic.progressiveReveal || showSection) {
      // all sections are visible
      $(topic.jqElement).removeClass('hideActions')
    } else {
      $(topic.jqElement).addClass('hideActions')
    }

    if (scrollLastSectionToView && lastVisibleSection) {
      scrollLastSectionPosition = lastVisibleSection.offset().top - 28
      setTimeout(function () {
        $('html, body').animate(
          {
            scrollTop: scrollLastSectionPosition
          },
          300
        )
      }, 60)
    }
    scrollLastSectionToView = false
  }

  function updateTopicProgressBar (topicIndex) {
    const topic = topics[topicIndex]

    const percentToDo = topic.sections.length === 0
      ? !topic.topicCompleted * 100
      : (1 - topic.sectionsSkipped / topic.sections.length) * 100

    $(topic.jqListElement).css('background-position-y', percentToDo + '%')
  }

  function i18nextLang (fallbackLng) {
    return (
      i18next.language || window.localStorage.i18nextLng || fallbackLng || 'en'
    )
  }

  function handleSkipClick (event) {
    $(this).data('n_clicks', $(this).data('n_clicks') + 1)

    const sectionId = this.getAttribute('data-section-id')
    // get the topic & section indexes
    let topicIndex = -1
    let sectionIndex = -1
    let topic, section
    $.each(topics, function (ti, t) {
      $.each(t.sections, function (si, s) {
        if (sectionId === s.id) {
          topicIndex = ti
          sectionIndex = si
          topic = t
          section = s
          return false
        }
      })
      return topicIndex === -1
    })
    // if the section has exercises and is not complete, don't skip - put up message
    if (section.exercises.length && !section.completed && !section.allowSkip) {
      const exs = i18next.t(['text.exercise', 'exercise'], {
        count: section.exercises.length,
        lngs: [i18nextLang(), 'en']
      })
      const youmustcomplete = i18next.t([
        'text.youmustcomplete',
        'You must complete the'
      ])
      const inthissection = i18next.t([
        'text.inthissection',
        'in this section before continuing.'
      ])

      bootbox.setLocale(i18nextLang())
      bootbox.alert(youmustcomplete + ' ' + exs + ' ' + inthissection)
    } else {
      if (sectionIndex === topic.sections.length - 1) {
        // last section on the page
        if (topicIndex < topics.length - 1) {
          updateLocation(currentTopicIndex + 1)
        }
      } else {
        scrollLastSectionToView = true
      }
      // update UI
      sectionSkipped([section.jqElement])
      // notify server
      tutorial.skipSection(sectionId)
    }
  }

  function handleNextTopicClick (event) {
    // any sections in this topic? if not, mark it as skipped
    if (topics[currentTopicIndex].sections.length === 0) {
      tutorial.skipSection(topics[currentTopicIndex].id)
    }
    updateLocation(currentTopicIndex + 1)
  }

  function handlePreviousTopicClick (event) {
    updateLocation(currentTopicIndex - 1)
  }

  // build the list of topics in the document
  // and create/adorn the DOM for them as needed
  function buildTopicsList () {
    const topicsList = $(
      '<div id="tutorial-topic" class="topicsList hideFloating"></div>'
    )

    const topicsHeader = $('<div class="topicsHeader"></div>')
    topicsHeader.append($('<h2 class="tutorialTitle">' + titleText + '</h2>'))
    const topicsCloser = $('<div class="paneCloser"></div>')
    topicsCloser.on('click', hideFloatingTopics)
    topicsHeader.append(topicsCloser)
    topicsList.append(topicsHeader)

    $('#doc-metadata').appendTo(topicsList)

    resetSectionVisibilityList()

    const topicsDOM = $('.section.level2')
    topicsDOM.each(function (topicIndex, topicElement) {
      const topic = {}
      topic.id = $(topicElement).attr('id')
      topic.exercisesCompleted = 0
      topic.sectionsCompleted = 0
      topic.sectionsSkipped = 0
      topic.topicCompleted = false // only relevant if topic has 0 exercises
      topic.jqElement = topicElement
      topic.jqTitleElement = $(topicElement).children('h2')[0]
      topic.titleText = topic.jqTitleElement.innerText
      const progressiveAttr = $(topicElement).attr('data-progressive')
      if (
        typeof progressiveAttr !== typeof undefined &&
        progressiveAttr !== false
      ) {
        topic.progressiveReveal =
          progressiveAttr === 'true' || progressiveAttr === 'TRUE'
      } else {
        topic.progressiveReveal = docProgressiveReveal
      }

      const jqTopic = $(
        '<div class="topic" index="' +
          topicIndex +
          '">' +
          topic.titleText +
          '</div>'
      )
      jqTopic.on('click', handleTopicClick)
      topic.jqListElement = jqTopic
      $(topicsList).append(jqTopic)

      const topicActions = $('<div class="topicActions"></div>')
      if (topicIndex > 0) {
        const prevButton = $(
          '<button class="btn btn-default" data-i18n="button.previoustopic">Previous Topic</button>'
        )
        prevButton.on('click', handlePreviousTopicClick)
        topicActions.append(prevButton)
      }
      if (topicIndex < topicsDOM.length - 1) {
        const nextButton = $(
          '<button class="btn btn-primary" data-i18n="button.nexttopic">Next Topic</button>'
        )
        nextButton.on('click', handleNextTopicClick)
        topicActions.append(nextButton)
      }
      $(topicElement).append(topicActions)

      $(topicElement).on('shown', function () {
        // Some the topic can have the shown event triggered but not actually
        // be visible. This visibility check saves a little effort when it's
        // not actually visible.
        if ($(this).is(':visible')) {
          const sectionsDOM = $(topicElement).children('.section.level3')
          sectionsDOM.each(function (sectionIndex, sectionElement) {
            updateSectionVisibility(sectionElement)
          })
        }
      })

      $(topicElement).on('hidden', function () {
        const sectionsDOM = $(topicElement).children('.section.level3')
        sectionsDOM.each(function (sectionIndex, sectionElement) {
          updateSectionVisibility(sectionElement)
        })
      })

      topic.sections = []
      const sectionsDOM = $(topicElement).children('.section.level3')
      sectionsDOM.each(function (sectionIndex, sectionElement) {
        if (topic.progressiveReveal) {
          const continueButton = $(
            '<button class="btn btn-default skip" id="' +
              'continuebutton-' +
              sectionElement.id +
              '" data-section-id="' +
              sectionElement.id +
              '" data-i18n="button.continue">Continue</button>'
          )
          continueButton.data('n_clicks', 0)
          continueButton.on('click', handleSkipClick)
          const actions = $('<div class="exerciseActions"></div>')
          actions.append(continueButton)
          $(sectionElement).append(actions)
        }

        $(sectionElement).on('shown', function () {
          // A 'shown' event can be triggered even when this section isn't
          // actually visible. This can happen when the parent topic isn't
          // visible. So we have to check that this section actually is
          // visible.
          updateSectionVisibility(sectionElement)
        })

        $(sectionElement).on('hidden', function () {
          updateSectionVisibility(sectionElement)
        })

        const section = {}
        section.exercises = []
        const exercisesDOM = $(sectionElement).children('.tutorial-exercise')
        exercisesDOM.each(function (exerciseIndex, exerciseElement) {
          const exercise = {}
          exercise.dataLabel = $(exerciseElement).attr('data-label')
          exercise.completed = false
          exercise.jqElement = exerciseElement
          section.exercises.push(exercise)
        })

        let allowSkipAttr = $(sectionElement).attr('data-allow-skip')
        let sectionAllowSkip = docAllowSkip
        if (
          typeof allowSkipAttr !== typeof undefined &&
          allowSkipAttr !== false
        ) {
          sectionAllowSkip = allowSkipAttr = 'true' || allowSkipAttr === 'TRUE'
        }

        section.id = sectionElement.id
        section.completed = false
        section.allowSkip = sectionAllowSkip
        section.skipped = false
        section.jqElement = sectionElement
        topic.sections.push(section)
      })

      topics.push(topic)
    })

    const topicsFooter = $('<div class="topicsFooter"></div>')

    const resetButton = $(
      '<span class="resetButton" data-i18n="text.startover">Start Over</span>'
    )
    resetButton.on('click', function () {
      const areyousure = i18next.t([
        'text.areyousure',
        'Are you sure you want to start over? (all exercise progress will be reset)'
      ])

      bootbox.setLocale(i18nextLang())
      bootbox.confirm(areyousure, function (result) {
        result && tutorial.startOver()
      })
    })
    topicsFooter.append(resetButton)
    topicsList.append(topicsFooter)

    return topicsList
  }

  // topicMenuInputBinding
  // ------------------------------------------------------------------
  // This keeps tracks of what topic is selected
  const topicMenuInputBinding = new Shiny.InputBinding()
  $.extend(topicMenuInputBinding, {
    find: function (scope) {
      return $(scope).find('.topicsList')
    },
    getValue: function (el) {
      if (currentTopicIndex === -1) return null
      return topics[currentTopicIndex].id
    },
    setValue: function (el, value) {
      for (let i = 0; i < topics.length; i++) {
        if (topics[i].id === value) {
          setCurrentTopic(i, false)
          break
        }
      }
    },
    subscribe: function (el, callback) {
      setCurrentTopicNotifiers.add(el.id, callback)
    },
    unsubscribe: function (el) {
      setCurrentTopicNotifiers.remove(el.id)
    }
  })
  Shiny.inputBindings.register(
    topicMenuInputBinding,
    'learnr.topicMenuInputBinding'
  )

  // continueButtonInputBinding
  // ------------------------------------------------------------------
  // This keeps tracks of what topic is selected
  const continueButtonInputBinding = new Shiny.InputBinding()
  $.extend(continueButtonInputBinding, {
    find: function (scope) {
      return $(scope).find('.exerciseActions > button.skip')
    },
    getId: function (el) {
      return 'continuebutton-' + el.getAttribute('data-section-id')
    },
    getValue: function (el) {
      return $(el).data('n_clicks')
    },
    setValue: function (el, value) {
      const valueCurrent = $(el).data('n_clicks')
      if (value > valueCurrent) {
        $(el).trigger('click')
      }

      // Just in case the click event didn't increment n_clicks to be the same
      // as the `value`, set `n_clicks` to be the same.
      $(el).data('n_clicks', value)
    },
    subscribe: function (el, callBack) {
      $(el).on('click.continueButtonInputBinding', function (event) {
        callBack(false)
      })
    },
    unsubscribe: function (el) {
      $(el).off('.continueButtonInputBinding')
    }
  })
  Shiny.inputBindings.register(
    continueButtonInputBinding,
    'learnr.continueButtonInputBinding'
  )

  // transform the DOM here
  function transformDOM () {
    titleText = $('title')[0].innerText

    const progAttr = $('meta[name=progressive]').attr('content')
    docProgressiveReveal = progAttr === 'true' || progAttr === 'TRUE'
    const allowSkipAttr = $('meta[name=allow-skip]').attr('content')
    docAllowSkip = allowSkipAttr === 'true' || allowSkipAttr === 'TRUE'

    const tutorialTitle = $(`<h2 class="tutorialTitle">${titleText}</h2>`)
    tutorialTitle.on('click', showFloatingTopics)
    $('.topics').prepend(tutorialTitle)

    $('.bandContent.topicsListContainer').append(buildTopicsList())

    // initialize visibility of all topics' elements
    for (let t = 0; t < topics.length; t++) {
      updateVisibilityOfTopicElements(t)
    }

    function handleResize () {
      $('.topicsList').css('max-height', window.innerHeight)
    }

    handleResize()
    window.addEventListener('resize', handleResize)
  }

  function isBS3 () {
    // from https://github.com/rstudio/shiny/blob/474f14/srcts/src/utils/index.ts#L373-L376
    return !window.bootstrap
  }

  function preTransformDOMMigrateFromBS3 () {
    if (isBS3()) return

    const panelMigration = {
      panel: 'card',
      'panel-default': '',
      'panel-heading': 'card-header',
      'panel-title': 'card-title',
      'panel-body': 'card-body',
      'panel-footer': 'card-footer'
    }

    const tutorialMigratePanels = document.querySelectorAll('.tutorial-question-container')
    if (tutorialMigratePanels.length === 0) return

    tutorialMigratePanels.forEach(elPanel => {
      Object.keys(panelMigration).forEach(classOrig => {
        const els = [elPanel, ...elPanel.querySelectorAll(`.${classOrig}`)]
        if (!els.length) return
        const classNew = panelMigration[classOrig]
        els.forEach(el => {
          if (!el.classList.contains(classOrig)) return
          el.classList.remove(classOrig)
          if (classNew !== '') {
            el.classList.add(classNew)
          }
        })
      })
    })
  }

  // support bookmarking of topics
  function handleLocationHash () {
    function findTopicIndexFromHash () {
      const hash = window.decodeURIComponent(window.location.hash)
      let topicIndex = 0
      if (hash.length > 0) {
        $.each(topics, function (ti, t) {
          if ('#' + t.id === hash) {
            topicIndex = ti
            return false
          }
        })
      }
      return topicIndex
    }

    // select topic from hash on the url
    setCurrentTopic(findTopicIndexFromHash())

    // navigate to a topic when the history changes
    window.addEventListener('popstate', function (e) {
      setCurrentTopic(findTopicIndexFromHash())
    })
  }

  // update UI after a section gets completed
  // it might be an exercise or it might be an entire topic
  function sectionCompleted (section) {
    const jqSection = $(section)

    const topicCompleted = jqSection.hasClass('level2')

    let topicId
    if (topicCompleted) {
      topicId = jqSection.attr('id')
    } else {
      topicId = $(jqSection.parents('.section.level2')).attr('id')
    }

    // find the topic in our topics array
    let topicIndex = -1
    $.each(topics, function (ti, t) {
      if (t.id === topicId) {
        topicIndex = ti
        return false
      }
    })
    if (topicIndex === -1) {
      console.log('topic "' + topicId + '" not found')
      return
    }

    const topic = topics[topicIndex]

    if (topicCompleted) {
      // topic completed
      topic.topicCompleted = true
      updateTopicProgressBar(topicIndex)
    } else {
      // exercise completed
      let sectionIndex = -1
      const sectionId = jqSection.attr('id')
      $.each(topic.sections, function (si, s) {
        if (s.id === sectionId) {
          sectionIndex = si
          return false
        }
      })
      if (sectionIndex === -1) {
        console.log('completed section"' + sectionId + '"not found')
        return
      }

      // update the UI if the section isn't already marked completed
      const section = topic.sections[sectionIndex]
      if (!section.completed) {
        topic.sectionsCompleted++

        updateTopicProgressBar(topicIndex)

        // update the exercise
        $(section.jqElement).addClass('done')
        section.completed = true

        // update visibility of topic's exercises and actions
        updateVisibilityOfTopicElements(topicIndex)
      }
    }
  }

  // Keep track of which sections are currently visible. When this changes
  const visibleSections = []
  function resetSectionVisibilityList () {
    visibleSections.splice(0, visibleSections.length)
    sendVisibleSections()
  }

  function updateSectionVisibility (sectionElement) {
    const idx = visibleSections.indexOf(sectionElement.id)

    if ($(sectionElement).is(':visible')) {
      if (idx === -1) {
        visibleSections.push(sectionElement.id)
        sendVisibleSections()
      }
    } else {
      if (idx !== -1) {
        visibleSections.splice(idx, 1)
        sendVisibleSections()
      }
    }
  }

  function sendVisibleSections () {
    // This function may be called several times in a tick, which results in
    // many calls to Shiny.setInputValue(). That shouldn't be a problem since
    // those calls are deduped; only the last value gets sent to the server.
    if (Shiny && Shiny.setInputValue) {
      Shiny.setInputValue('tutorial-visible-sections', visibleSections)
    } else {
      $(document).on('shiny:sessioninitialized', function () {
        Shiny.setInputValue('tutorial-visible-sections', visibleSections)
      })
    }
  }

  // update the UI after a section or topic (with 0 sections) gets skipped
  function sectionSkipped (exerciseElement) {
    let sectionSkippedId
    if (exerciseElement.length) {
      sectionSkippedId = exerciseElement[0].id
    } else {
      // error
      console.log(
        'section ' + $(exerciseElement).selector.split('"')[1] + ' not found'
      )
      return
    }

    let topicIndex = -1
    $.each(topics, function (ti, topic) {
      if (sectionSkippedId === topic.id) {
        topicIndex = ti
        topic.topicCompleted = true
        return false
      }
      $.each(topic.sections, function (si, section) {
        if (sectionSkippedId === section.id) {
          topicIndex = ti
          section.skipped = true
          topic.sectionsSkipped++
          return false
        }
      })
      return topicIndex === -1
    })

    // update the progress bar
    updateTopicProgressBar(topicIndex)
    // update visibility of topic's exercises and actions
    updateVisibilityOfTopicElements(topicIndex)
  }

  preTransformDOMMigrateFromBS3()
  transformDOM()
  handleLocationHash()

  // initialize components within tutorial.onInit event
  tutorial.onInit(function () {
    // handle progress events
    tutorial.onProgress(function (progressEvent) {
      if (progressEvent.event === 'section_completed') {
        sectionCompleted(progressEvent.element)
      } else if (progressEvent.event === 'section_skipped') {
        sectionSkipped(progressEvent.element)
      }
    })
  })
})
