

$(document).ready(function() {

    var titleText = '';
    var currentTopicIndex = -1;
    var docProgressiveReveal = false;
    var docAllowSkip = false;
    var topics = [];

    var scrollLastSectionToView = false;
    var scrollLastSectionPosition = 0;

    // Callbacks that are triggered when setCurrentTopic() is called.
    var setCurrentTopicNotifiers = (function() {
      notifiers = [];

      return {
        add: function(id, callback) {
          notifiers.push({id: id, callback: callback});
        },
        remove: function(id) {
          notifiers = notifiers.filter(function(x) {
            return id !== x.id;
          });
        },
        invoke: function() {
          for(var i = 0; i < notifiers.length; i++) {
            notifiers[i].callback();
          }
        }
      };
    })();

    const range = (start, stop, step = 1) => Array.from({ length: (stop - start) / step + 1}, (_, i) => start + (i * step));

    const updateCssUpper = function(e){
      var pct = $(e.target).data("css-progress");
      $("#progress_upper").css("width", pct + "%")

      if (pct > parseInt(document.querySelector("#progress_middle").style.width)){
        $("#progress_middle").css("width", pct + "%")
      }
    }


    function setCurrentTopic(topicIndex, notify) {
      if (typeof(notify) === "undefined") {
        notify = true;
      }
      if (topics.length === 0) return;

      topicIndex = topicIndex * 1;  // convert strings to a number

      if (topicIndex == currentTopicIndex) return;

      if (currentTopicIndex != -1) {
        var el = $(topics[currentTopicIndex].jqElement);
        el.trigger('hide');
        el.removeClass('current');
        el.trigger('hidden');
        $(topics[currentTopicIndex].jqListElement).removeClass('current');
      }

      var currentEl = $(topics[topicIndex].jqElement);
      currentEl.trigger('show');
      currentEl.addClass('current');
      currentEl.trigger('shown');
      $(topics[topicIndex].jqListElement).addClass('current');
      currentTopicIndex = topicIndex;

      if (notify) {
        setCurrentTopicNotifiers.invoke();
      }

      // always start a topic with a the scroll pos at the top
      // we do this in part to prevent the scroll to view behavior of hash navigation
      setTimeout(function() {$(document).scrollTop(0);}, 0);
    }

    function updateLocation(topicIndex) {
      var baseUrl = window.location.href.replace(window.location.hash,"");
      var href = baseUrl + '#' + topics[topicIndex].id;
      window.location = href;
    }

    // Based on http://detectmobilebrowsers.com/ and https://stackoverflow.com/a/11381730/8236642
    function isMobile() {
      let check = false;
      (function(a) { if (/(android|bb\d+|meego).+mobile|avantgo|bada\/|blackberry|blazer|compal|elaine|fennec|hiptop|iemobile|ip(hone|od)|iris|kindle|lge |maemo|midp|mmp|mobile.+firefox|netfront|opera m(ob|in)i|palm( os)?|phone|p(ixi|re)\/|plucker|pocket|psp|series(4|6)0|symbian|treo|up\.(browser|link)|vodafone|wap|windows ce|xda|xiino/i.test(a) || /1207|6310|6590|3gso|4thp|50[1-6]i|770s|802s|a wa|abac|ac(er|oo|s\-)|ai(ko|rn)|al(av|ca|co)|amoi|an(ex|ny|yw)|aptu|ar(ch|go)|as(te|us)|attw|au(di|\-m|r |s )|avan|be(ck|ll|nq)|bi(lb|rd)|bl(ac|az)|br(e|v)w|bumb|bw\-(n|u)|c55\/|capi|ccwa|cdm\-|cell|chtm|cldc|cmd\-|co(mp|nd)|craw|da(it|ll|ng)|dbte|dc\-s|devi|dica|dmob|do(c|p)o|ds(12|\-d)|el(49|ai)|em(l2|ul)|er(ic|k0)|esl8|ez([4-7]0|os|wa|ze)|fetc|fly(\-|_)|g1 u|g560|gene|gf\-5|g\-mo|go(\.w|od)|gr(ad|un)|haie|hcit|hd\-(m|p|t)|hei\-|hi(pt|ta)|hp( i|ip)|hs\-c|ht(c(\-| |_|a|g|p|s|t)|tp)|hu(aw|tc)|i\-(20|go|ma)|i230|iac( |\-|\/)|ibro|idea|ig01|ikom|im1k|inno|ipaq|iris|ja(t|v)a|jbro|jemu|jigs|kddi|keji|kgt( |\/)|klon|kpt |kwc\-|kyo(c|k)|le(no|xi)|lg( g|\/(k|l|u)|50|54|\-[a-w])|libw|lynx|m1\-w|m3ga|m50\/|ma(te|ui|xo)|mc(01|21|ca)|m\-cr|me(rc|ri)|mi(o8|oa|ts)|mmef|mo(01|02|bi|de|do|t(\-| |o|v)|zz)|mt(50|p1|v )|mwbp|mywa|n10[0-2]|n20[2-3]|n30(0|2)|n50(0|2|5)|n7(0(0|1)|10)|ne((c|m)\-|on|tf|wf|wg|wt)|nok(6|i)|nzph|o2im|op(ti|wv)|oran|owg1|p800|pan(a|d|t)|pdxg|pg(13|\-([1-8]|c))|phil|pire|pl(ay|uc)|pn\-2|po(ck|rt|se)|prox|psio|pt\-g|qa\-a|qc(07|12|21|32|60|\-[2-7]|i\-)|qtek|r380|r600|raks|rim9|ro(ve|zo)|s55\/|sa(ge|ma|mm|ms|ny|va)|sc(01|h\-|oo|p\-)|sdk\/|se(c(\-|0|1)|47|mc|nd|ri)|sgh\-|shar|sie(\-|m)|sk\-0|sl(45|id)|sm(al|ar|b3|it|t5)|so(ft|ny)|sp(01|h\-|v\-|v )|sy(01|mb)|t2(18|50)|t6(00|10|18)|ta(gt|lk)|tcl\-|tdg\-|tel(i|m)|tim\-|t\-mo|to(pl|sh)|ts(70|m\-|m3|m5)|tx\-9|up(\.b|g1|si)|utst|v400|v750|veri|vi(rg|te)|vk(40|5[0-3]|\-v)|vm40|voda|vulc|vx(52|53|60|61|70|80|81|83|85|98)|w3c(\-| )|webc|whit|wi(g |nc|nw)|wmlb|wonu|x700|yas\-|your|zeto|zte\-/i.test(a.substr(0, 4))) check = true; })(navigator.userAgent || navigator.vendor || window.opera);
      return check;
    }

    function handleTopicClick(event) {
      if (isMobile()) {
            $('.topicsList').hide();
            $('.learnr-nav-items').toggleClass('opened');
      } else {
            if (window.innerWidth > 767) {
                $('.topicsList').show();
            } else {
                $('.topicsList').hide();
                $('.learnr-nav-items').toggleClass('opened');
            }
      }
      var topicIndex = parseInt($(event.target).attr("index"));
      var pct = (100 / topics.length - 1) * (topicIndex + 1);
      // $("#progress_upper").css("width", pct + "%")
      hideFloatingTopics();
      updateLocation(this.getAttribute('index'));
    }

    function showFloatingTopics() {
      $('.topicsList').removeClass('hideFloating');
    }

    function hideFloatingTopics() {
      $('.topicsList').addClass('hideFloating');
    }

    function updateVisibilityOfTopicElements(topicIndex) {
      resetSectionVisibilityList();

      var topic = topics[topicIndex];

      if (!topic.progressiveReveal) return;

      var showSection = true;

      var lastVisibleSection = null;

      for (i = 0; i < topic.sections.length; i++ ) {
        var section = topic.sections[i];
        var sectionEl = $(section.jqElement);
        if (showSection) {
          sectionEl.trigger('show');
          sectionEl.removeClass('hide');
          sectionEl.trigger('shown');
          if (section.skipped) {
            sectionEl.removeClass('showSkip');
          }
          else {
            sectionEl.addClass('showSkip');
            lastVisibleSection = sectionEl;
          }
        }
        else {
          sectionEl.trigger('hide');
          sectionEl.addClass('hide');
          sectionEl.trigger('hidden');
        }
        showSection = (showSection && section.skipped);
      }

      if (!topic.progressiveReveal || showSection) { // all sections are visible
        $(topic.jqElement).removeClass('hideActions');
      }
      else {
        $(topic.jqElement).addClass('hideActions');
      }

      if (scrollLastSectionToView && lastVisibleSection) {
        scrollLastSectionPosition = lastVisibleSection.offset().top - 28;
        setTimeout(function() {
          $('html, body').animate({
            scrollTop: scrollLastSectionPosition
          }, 300);
        }, 60)
      }
      scrollLastSectionToView = false;
    }

    function updateTopicProgressBar(topicIndex) {

      var topic = topics[topicIndex];

      var percentToDo;
      if (topic.sections.length == 0) {
        percentToDo = !topic.topicCompleted * 100;
      }
      else {
        percentToDo = (1 - topic.sectionsSkipped/topic.sections.length) * 100;
      }

      // $(topic.jqListElement).css('background-position-y', percentToDo + '%' );

    }

    function handleSkipClick(event) {

      $(this).data('n_clicks', $(this).data('n_clicks') + 1)

      var sectionId = this.getAttribute('data-section-id');
      // get the topic & section indexes
      var topicIndex = -1;
      var sectionIndex = -1;
      var topic;
      var section;
      $.each(topics, function( ti, t) {
        $.each(t.sections, function( si, s) {
          if (sectionId == s.id) {
            topicIndex = ti;
            sectionIndex = si;
            topic = t;
            section = s;
            return false;
          }
        })
        return topicIndex == -1;
      })
      // if the section has exercises and is not complete, don't skip - put up message
      if (section.exercises.length && !section.completed && !section.allowSkip) {
        var exs = section.exercises.length == 1 ? 'exercise' : 'exercises';
        bootbox.alert("You must complete the " + exs + " in this section before continuing.");
      }
      else {
        if (sectionIndex == topic.sections.length - 1) {
          // last section on the page
          if (topicIndex < topics.length - 1) {
            updateLocation(currentTopicIndex + 1);
          }
        }
        else {
          scrollLastSectionToView = true;
        }
        // update UI
        sectionSkipped([section.jqElement]);
        // notify server
        tutorial.skipSection(sectionId);
      }
    }

    function handleNextTopicClick(event) {
      // any sections in this topic? if not, mark it as skipped
      if (topics[currentTopicIndex].sections.length == 0) {
        tutorial.skipSection(topics[currentTopicIndex].id);
      }
      updateLocation(currentTopicIndex + 1);
    }

    function handlePreviousTopicClick(event) {
      updateLocation(currentTopicIndex - 1);
    }

    // build the list of topics in the document
    // and create/adorn the DOM for them as needed
    function buildTopicsList() {
      var topicsList = $('<div id="tutorial-topic" class="topicsList hideFloating"></div>');

      var topicsHeader = $('<div class="topicsHeader"></div>');
      topicsHeader.append($('<h2 class="tutorialTitle">' + titleText + '</h2>'));
      //var topicsCloser = $('<div class="paneCloser"></div>');
      //topicsCloser.on('click', hideFloatingTopics);
      //topicsHeader.append(topicsCloser);
      topicsList.append(topicsHeader);

      $('#doc-metadata').appendTo(topicsList);

      resetSectionVisibilityList();

      var topicsDOM = $('.section.level2');
      topicsDOM.each( function(topicIndex, topicElement) {

        var topic = {};
        topic.id = $(topicElement).attr('id');
        topic.exercisesCompleted = 0;
        topic.sectionsCompleted = 0;
        topic.sectionsSkipped = 0;
        topic.topicCompleted = false; // only relevant if topic has 0 exercises
        topic.jqElement = topicElement;
        topic.jqTitleElement = $(topicElement).children('h2')[0];
        topic.titleText = topic.jqTitleElement.innerText;
        var progressiveAttr = $(topicElement).attr('data-progressive');
        if (typeof progressiveAttr !== typeof undefined && progressiveAttr !== false) {
          topic.progressiveReveal = (progressiveAttr == 'true' || progressiveAttr == 'TRUE');
        }
        else {
          topic.progressiveReveal = docProgressiveReveal;
        }

        jqTopic = $('<div class="topic" index="' + topicIndex + '">' + topic.titleText + '</div>');
        jqTopic.on('click', handleTopicClick);
        topic.jqListElement = jqTopic;
        $(topicsList).append(jqTopic);

        var topicActions = $('<div class="topicActions"></div>');
        if (topicIndex > 0) {
          var prevButton = $('<button class="btn btn-default previous-mover">Previous Topic</button>');
          prevButton.on('click', handlePreviousTopicClick);
          topicActions.append(prevButton);
        }
        if (topicIndex < topicsDOM.length - 1) {
          var nextButton = $('<button class="btn btn-primary progress-mover">Next Topic</button>');
          nextButton.on('click', handleNextTopicClick);
          topicActions.append(nextButton);
        }
        $(topicElement).append(topicActions);

        $(topicElement).on('shown', function() {
          // Some the topic can have the shown event triggered but not actually
          // be visible. This visibility check saves a little effort when it's
          // not actually visible.
          if ($(this).is(":visible")) {
            var sectionsDOM = $(topicElement).children('.section.level3');
            sectionsDOM.each( function(sectionIndex, sectionElement) {
              updateSectionVisibility(sectionElement);
            })
          }
        });

        $(topicElement).on('hidden', function() {
          var sectionsDOM = $(topicElement).children('.section.level3');
          sectionsDOM.each( function(sectionIndex, sectionElement) {
            updateSectionVisibility(sectionElement);
          })
        });

        topic.sections = [];
        var sectionsDOM = $(topicElement).children('.section.level3');
        sectionsDOM.each( function( sectionIndex, sectionElement) {

          if (topic.progressiveReveal) {
            var continueButton = $(
              '<button class="btn btn-default skip progress-mover" id="' +
              'continuebutton-' + sectionElement.id +
              '" data-section-id="' + sectionElement.id + '">Continue</button>'
            );
            continueButton.data('n_clicks', 0);
            continueButton.on('click', handleSkipClick);
            var actions = $('<div class="exerciseActions"></div>');
            actions.append(continueButton);
            $(sectionElement).append(actions);
          }

          $(sectionElement).on('shown', function() {
            // A 'shown' event can be triggered even when this section isn't
            // actually visible. This can happen when the parent topic isn't
            // visible. So we have to check that this section actually is
            // visible.
            updateSectionVisibility(sectionElement);
          });

          $(sectionElement).on('hidden', function() {
            updateSectionVisibility(sectionElement);
          });

          var section = {};
          section.exercises = [];
          var exercisesDOM = $(sectionElement).children('.tutorial-exercise');
          exercisesDOM.each(function(exerciseIndex, exerciseElement) {
            var exercise = {};
            exercise.dataLabel = $(exerciseElement).attr('data-label');
            exercise.completed = false;
            exercise.jqElement = exerciseElement;
            section.exercises.push(exercise);
          });

          var allowSkipAttr = $(sectionElement).attr('data-allow-skip');
          var sectionAllowSkip = docAllowSkip;
          if (typeof allowSkipAttr !== typeof undefined && allowSkipAttr !== false) {
            sectionAllowSkip = (allowSkipAttr == 'true' || allowSkipAttr == 'TRUE');
          }

          section.id = sectionElement.id;
          section.completed = false;
          section.allowSkip = sectionAllowSkip;
          section.skipped = false;
          section.jqElement = sectionElement;
          topic.sections.push(section);

        });

        topics.push(topic);
      });

      var topicsFooter = $('<div class="topicsFooter"></div>');

      var resetButton = $('<span class="resetButton">Start Over</span>');
      resetButton.on('click', function() {
        bootbox.confirm("Are you sure you want to start over? (all exercise progress will be reset)",
                        function(result) {
                          if (result)
                            tutorial.startOver();
                        });
      });
      topicsFooter.append(resetButton);
      topicsList.append(topicsFooter);

      return topicsList;

    }

  // topicMenuInputBinding
  // ------------------------------------------------------------------
  // This keeps tracks of what topic is selected
  var topicMenuInputBinding = new Shiny.InputBinding();
  $.extend(topicMenuInputBinding, {
    find: function(scope) {
      return $(scope).find('.topicsList');
    },
    getValue: function(el) {
      if (currentTopicIndex == -1) return null;
      return topics[currentTopicIndex].id;
    },
    setValue: function(el, value) {
      for (var i = 0; i < topics.length; i++) {
        if (topics[i].id == value) {
          setCurrentTopic(i, false);
          break;
        }
      }
    },
    subscribe: function(el, callback) {
      setCurrentTopicNotifiers.add(el.id, callback);
    },
    unsubscribe: function(el) {
      setCurrentTopicNotifiers.remove(el.id);
    }
  });
  Shiny.inputBindings.register(topicMenuInputBinding, 'learnr.topicMenuInputBinding');

  // continueButtonInputBinding
  // ------------------------------------------------------------------
  // This keeps tracks of what topic is selected
  var continueButtonInputBinding = new Shiny.InputBinding();
  $.extend(continueButtonInputBinding, {
    find: function(scope) {
      return $(scope).find('.exerciseActions > button.skip');
    },
    getId: function(el) {
      return 'continuebutton-' + el.getAttribute('data-section-id');
    },
    getValue: function(el) {
      return $(el).data('n_clicks');
    },
    setValue: function(el, value) {
      var old_value = $(el).data('n_clicks');
      if (value > old_value) {
        $(el).trigger('click');
      }

      // Just in case the click event didn't increment n_clicks to be the same
      // as the `value`, set `n_clicks` to be the same.
      $(el).data('n_clicks', value);
    },
    subscribe: function(el, callback) {
      $(el).on('click.continueButtonInputBinding', function(event) {
        callback(false);
      });
    },
    unsubscribe: function(el) {
      $(el).off('.continueButtonInputBinding');
    }
  });
  Shiny.inputBindings.register(continueButtonInputBinding, 'learnr.continueButtonInputBinding');

  function attachHeadroom(){
    if (typeof Headroom != "undefined") {
      if (isMobile() | window.innerWidth < 767) {
        const headroom = new Headroom(
        document.querySelector("header"), {
            onUnpin: function() {
                    $("header").removeClass("opened");
                    // slideUp only if mobile like
                    if (isMobile() | window.innerWidth < 767) {
                        $("#tutorial-topic").slideUp("300ms");
                    }
                }
            }
        );
    headroom.init();
    }
  }
  }

  // transform the DOM here
  function transformDOM() {

    titleText = $('title')[0].innerText;

    var progAttr = $('meta[name=progressive]').attr("content");
    docProgressiveReveal = (progAttr == 'true' || progAttr == 'TRUE');
    var allowSkipAttr = $('meta[name=allow-skip]').attr("content");
    docAllowSkip = (allowSkipAttr == 'true' || allowSkipAttr == 'TRUE');

    // var tutorialTitle = $('<h2 class="tutorialTitle">' + titleText + '</h2>');
    // tutorialTitle.on('click', showFloatingTopics);

    var tutorialTitle = $(`<header class="learnr-nav-items" onclick="$('.topicsList').toggle(); $(this).toggleClass('opened'); " href="#" style="display: flex; justify-content: space-between;z-index:996"> <h2 class="tutorialTitle" style="border-bottom: none; cursor: auto; padding-right: 1em;"> ${titleText} </h2> <a class="chevron mobile" style="display: flex; align-items: center; justify-content: center; margin-right:1em;"> <svg width="2em" height="2em" viewBox="0 -3 16 16" class="bi bi-chevron-up" fill="#555555" xmlns="http://www.w3.org/2000/svg"> <path fill-rule="evenodd" d="M7.646 4.646a.5.5 0 0 1 .708 0l6 6a.5.5 0 0 1-.708.708L8 5.707l-5.646 5.647a.5.5 0 0 1-.708-.708l6-6z"></path></svg> <svg width="2em" height="2em" viewBox="0 -3 16 16" class="bi bi-chevron-down" fill="#555555" xmlns="http://www.w3.org/2000/svg"> <path fill-rule="evenodd" d="M1.646 4.646a.5.5 0 0 1 .708 0L8 10.293l5.646-5.647a.5.5 0 0 1 .708.708l-6 6a.5.5 0 0 1-.708 0l-6-6a.5.5 0 0 1 0-.708z"></path></svg></a></header>`);

    $('.topics').prepend(tutorialTitle);

    $('.bandContent.topicsListContainer').append(buildTopicsList());

    // initialize visibility of all topics' elements
    for (var t = 0; t < topics.length; t++) {
      updateVisibilityOfTopicElements(t);
    }

    function handleResize() {
        if (!$('header').hasClass('headroom')){
            attachHeadroom();
        }
      $('.topicsList').css("max-height", window.innerHeight);
      // When on a Mobile or width is mobile like, we want to hide the topicList
      // and to pad the sections
      if (isMobile() | window.innerWidth < 767) {
            $('.topicsList').hide();
            $(".section.level2").css("padding-top", $("header").height());
            $("#tutorial-topic").css("padding-top", $("header").height());
      } else {
            $('.learnr-nav-items').removeClass('opened');
            $(".section.level2").css("padding-top", "unset");
            $("#tutorial-topic").css("padding-top", "unset");
            $('.topicsList').show();
            $(".section.level2").css("padding-top", 0)
      }
    }

    handleResize();
    window.addEventListener("resize", handleResize);

  }

  // support bookmarking of topics
  function handleLocationHash() {

    function findTopicIndexFromHash() {
      var hash = window.decodeURIComponent(window.location.hash);
      var topicIndex = 0;
      if (hash.length > 0) {
        $.each(topics, function( ti, t) {
          if ('#' + t.id == hash) {
            topicIndex = ti;
            return false;
          }
        });
      }
      return topicIndex;
    }

    function setProgressBarFromHash(){
      var next_topics = $(".btn.btn-primary.progress-mover");
      var steps = range(0, 100, Math.round(100 / (next_topics.length + 1)));
      var pct = steps[findTopicIndexFromHash()];
      $("#progress_upper").css("width", pct + "%")
      if (pct > parseInt(document.querySelector("#progress_middle").style.width)){
        $("#progress_middle").css("width", pct + "%")
      }
    }
    // select topic from hash on the url
    // Restore the progress bar css

    setCurrentTopic(findTopicIndexFromHash());
    setProgressBarFromHash()
    // navigate to a topic when the history changes
    window.addEventListener("popstate", function(e) {
      setCurrentTopic(findTopicIndexFromHash());
      setProgressBarFromHash()
    });

  }

  // update UI after a section gets completed
  // it might be an exercise or it might be an entire topic
  function sectionCompleted(section) {
    var jqSection = $(section);

    var topicCompleted = jqSection.hasClass('level2');

    var topicId;
    if (topicCompleted) {
      topicId = jqSection.attr('id');
    }
    else {
      topicId = $(jqSection.parents('.section.level2')).attr('id');
    }

    // find the topic in our topics array
    var topicIndex = -1;
    $.each(topics, function(ti, t) {
      if (t.id == topicId) {
        topicIndex = ti;
        return false;
      }
    });
    if (topicIndex == -1) {
      console.log('topic "' + topicId + '" not found');
      return;
    }

    var topic = topics[topicIndex];

    if (topicCompleted) {         // topic completed
      topic.topicCompleted = true;
      updateTopicProgressBar(topicIndex);
    }
    else {                        // exercise completed
      var sectionIndex = -1;
      var sectionId = jqSection.attr('id');
      $.each(topic.sections, function(si, s ) {
        if (s.id == sectionId) {
          sectionIndex = si;
          return false;
        }
      })
      if (sectionIndex == -1) {
        console.log('completed section"' + sectionId + '"not found');
        return;
      }

      // update the UI if the section isn't already marked completed
      var section = topic.sections[sectionIndex];
      if (!section.completed) {
        topic.sectionsCompleted++;

        updateTopicProgressBar(topicIndex);

        // update the exercise
        $(section.jqElement).addClass('done');
        section.completed = true;

        // update visibility of topic's exercises and actions
        updateVisibilityOfTopicElements(topicIndex);
      }
    }
  }

  // Keep track of which sections are currently visible. When this changes
  var visibleSections = [];
  function resetSectionVisibilityList() {
    visibleSections = [];
    sendVisibleSections();
  }

  function updateSectionVisibility(sectionElement) {
    var idx = visibleSections.indexOf(sectionElement.id);

    if ($(sectionElement).is(":visible")) {
      if (idx == -1) {
        visibleSections.push(sectionElement.id);
        sendVisibleSections();
      }
    } else {
      if (idx != -1) {
        visibleSections.splice(idx, 1);
        sendVisibleSections();
      }
    }
  }

  function sendVisibleSections() {
    // This function may be called several times in a tick, which results in
    // many calls to Shiny.setInputValue(). That shouldn't be a problem since
    // those calls are deduped; only the last value gets sent to the server.
    if (Shiny && Shiny.setInputValue) {
      Shiny.setInputValue("tutorial-visible-sections", visibleSections);
    } else {
      $(document).on("shiny:sessioninitialized", function() {
        Shiny.setInputValue("tutorial-visible-sections", visibleSections);
      })
    }
  }


  // update the UI after a section or topic (with 0 sections) gets skipped
  function sectionSkipped(exerciseElement) {
    var sectionSkippedId;
    if (exerciseElement.length) {
      sectionSkippedId = exerciseElement[0].id;
    }
    else {  // error
      console.log('section ' + $(exerciseElement).selector.split('"')[1] +' not found');
      return;
    }


    var topicIndex = -1;
    $.each(topics, function( ti, topic) {
      if (sectionSkippedId == topic.id) {
        topicIndex = ti;
        topic.topicCompleted = true;
        return false;
      }
      $.each(topic.sections, function( si, section) {
        if (sectionSkippedId == section.id) {
          topicIndex = ti;
          section.skipped = true;
          topic.sectionsSkipped++;
          return false;
        }
      })
      return topicIndex == -1;
    })

    // update the progress bar
    updateTopicProgressBar(topicIndex);
    // update visibility of topic's exercises and actions
    updateVisibilityOfTopicElements(topicIndex);
  }


  transformDOM();
  handleLocationHash();
  attachHeadroom();

  // initialize components within tutorial.onInit event
  tutorial.onInit(function() {

    // handle progress events
    tutorial.onProgress(function(progressEvent) {
      if (progressEvent.event === "section_completed")
        sectionCompleted(progressEvent.element);
      else if (progressEvent.event === "section_skipped")
        sectionSkipped(progressEvent.element);
    });

    // We want the css to move 100/(next_topics.length + 1) %
    // When clicking on each "Next Topic" button
    var next_topics = $(".btn.btn-primary.progress-mover");
    // We need to create a range of next_topics.length + 1, so that the
    // first progression is not 0
    var steps = range(0, 100, Math.round(100 / (next_topics.length + 1)));
    var steps_not_shifted = range(0, 100, Math.round(100 / (next_topics.length + 1)));
    steps.shift()
    // adding a data-css-progress attribute to all
    // we start at 1 cause we don't need the 0%
    for( var i = 0; i < next_topics.length; i ++){
      $(next_topics[i]).attr("data-css-progress", steps[i]);
      $(next_topics[i]).click(function(e){updateCssUpper(e)});
    }

    // Same for topics on the left
    var topic = $(".topic");
    for( var i = 0; i < topic.length; i ++){
      $(topic[i]).attr("data-css-progress", steps_not_shifted[i]);
      $(topic[i]).click(function(e){updateCssUpper(e)});
    }

    // Add the css progress amount to previous Topic
    var previous_topic = $(".previous-mover");
    for( var i = 0; i < previous_topic.length; i ++){
      $(previous_topic[i]).attr("data-css-progress", steps_not_shifted[i]);
      $(previous_topic[i]).click(function(e){updateCssUpper(e)});
    }

    // Make the progress bar move on click on Continue button
    // To do that, we need to compute steps between each `Next Topic` buttons
    // In each section level2, Potential Continue buttons. We'll use Next and previous
    // values to compute the range
    var section_2 = $(".section.level2")

    for( var i = 0; i < section_2.length; i ++){
      let current = $(section_2[i]);
      let continue_button = current.find(".btn.btn-default.progress-mover")
      if (continue_button.length > 0){
        // Get the lower range. If none, it's because it's the first topic, so we set it to 0
        let lower_boundary = current.find(".previous-mover").attr("data-css-progress") || 0
        // Get the upper range. If none, it's because it's the last topic, so we set it to 0
        let upper_boundary = current.find(".btn.btn-primary.progress-mover").attr("data-css-progress") || 100
        // build the steps
        let steps = range(lower_boundary, upper_boundary, Math.round(upper_boundary - lower_boundary) / (continue_button.length + 1));
        steps.shift()
        for( var i = 0; i < next_topics.length; i ++){
          $(continue_button[i]).attr("data-css-progress", steps[i]);
          $(continue_button[i]).click(function(e){updateCssUpper(e)});
        }
      }
    }



  });

});
