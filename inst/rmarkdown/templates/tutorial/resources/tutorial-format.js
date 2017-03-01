

$(document).ready(function() {

    var titleText = '';
    var currentTopicIndex = -1;
    var docProgressiveReveal = false;
    var docAllowSkip = false;
    var topics = [];

    function setCurrentTopic(topicIndex) {
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
    }

    function handleTopicClick(event) {
      setCurrentTopic(this.getAttribute('index'));
      hideFloatingTopics();
    }

    function showFloatingTopics() {
      $('.topicsList').removeClass('hideFloating');
    }

    function hideFloatingTopics() {
      $('.topicsList').addClass('hideFloating');
    }

    function updateVisibilityOfTopicElements(topicIndex) {
      var topic = topics[topicIndex];

      if (!topic.progressiveReveal) return;

      var showExercise = true;

      for (i = 0; i < topic.exercises.length; i++ ) {
        var exercise = topic.exercises[i];
        var exerciseEl = $(exercise.jqElement);
        if (showExercise) {
          var exerciseEl =
          exerciseEl.trigger('show');
          exerciseEl.removeClass('hide');
          exerciseEl.trigger('shown');
          if (exercise.completed || exercise.skipped) {
            exerciseEl.removeClass('showSkip');
          }
          else {
            exerciseEl.addClass('showSkip');
          }
        }
        else {
          exerciseEl.trigger('hide');
          exerciseEl.addClass('hide');
          exerciseEl.trigger('hidden');
        }
        showExercise = (showExercise && (exercise.completed || exercise.skipped));
      }

      if (!topic.progressiveReveal || showExercise) { // all exercises are either completed or skipped
        $(topic.jqElement).removeClass('hideActions');
      }
      else {
        $(topic.jqElement).addClass('hideActions');
      }
    }

    function updateTopicProgressBar(topicIndex) {
      var topic = topics[topicIndex];

      var percentToDo;
      if (topic.exercises.length == 0) {
        percentToDo = !topic.topicCompleted * 100;
      }
      else {
        percentToDo = (1 - topic.exercisesCompleted/topic.exercises.length) * 100;
      }

      $(topic.jqListElement).css('background-position-y', percentToDo + '%' );


    }

    function handleSkipClick(event) {
    //  exerciseSkipped(this.getAttribute('topic-index'), this.getAttribute('index'));

      tutor.skipExercise(this.getAttribute('exercise-data-label'));
    }

    function handleNextTopicClick(event) {
      setCurrentTopic(currentTopicIndex + 1);
    }

    function handlePreviousTopicClick(event) {
      setCurrentTopic(currentTopicIndex - 1);
    }

    // build the list of topics in the document
    // and create/adorn the DOM for them as needed
    function buildTopicsList() {
      var topicsList = $('<div class="topicsList hideFloating"></div>');

      var topicsHeader = $('<div class="topicsHeader"></div>');
      topicsHeader.append($('<h2 class="tutorialTitle">' + titleText + '</h2>'));
      var topicsCloser = $('<div class="paneCloser"></div>');
      topicsCloser.on('click', hideFloatingTopics);
      topicsHeader.append(topicsCloser);
      topicsList.append(topicsHeader);

      var topicsDOM = $('.section.level2');
      topicsDOM.each( function(topicIndex, topicElement) {

        var topic = {};
        topic.id = $(topicElement).attr('id');
        topic.exercisesCompleted = 0;
        topic.topicCompleted = false; // only relevant if topic has 0 exercises
        topic.jqElement = topicElement;
        topic.jqTitleElement = $(topicElement).children('h2')[0];
        topic.titleText = topic.jqTitleElement.innerText;
        var progressiveAttr = $(topicElement).attr('progressive');
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
          var prevButton = $('<button class="btn btn-default">Previous Topic</button>');
          prevButton.on('click', handlePreviousTopicClick);
          topicActions.append(prevButton);
        }
        if (topicIndex < topicsDOM.length - 1) {
          var nextButton = $('<button class="btn btn-primary">Next Topic</button>');
          nextButton.on('click', handleNextTopicClick);
          topicActions.append(nextButton);
        }
        $(topicElement).append(topicActions);

        topic.exercises = [];
        var exercisesDOM = $(topicElement).children('.section.level3');
        exercisesDOM.each( function( exerciseIndex, exerciseElement) {
          // find the actual exercise element within the exercise section
          var actualExerciseElement = $(exerciseElement).children('.tutor-exercise');
          var exerciseDataLabel = $(actualExerciseElement).attr('data-label');

          // add skip button as needed
          var allowSkipAttr = $(exerciseElement).attr('allow-skip');
          var addSkipThisExerciseButton = docAllowSkip;
          if (typeof allowSkipAttr !== typeof undefined && allowSkipAttr !== false) {
            addSkipThisExerciseButton = (allowSkipAttr == 'true' || allowSkipAttr == 'TRUE');
          }

          if (addSkipThisExerciseButton) {
            var skipButton = $('<button class="btn btn-default skip" exercise-data-label="' + exerciseDataLabel + '">Skip</button>');
            skipButton.on('click', handleSkipClick);
            var actions = $('<div class="exerciseActions"></div>');
            actions.append(skipButton);
            $(exerciseElement).append(actions);
          }

          var exercise = {};
          exercise.id = $(exerciseElement).attr('id');
          exercise.dataLabel = exerciseDataLabel;
          exercise.completed = false;
          exercise.skipped = false;
          exercise.jqElement = exerciseElement;
          topic.exercises.push(exercise);
        });

        topics.push(topic);
      });

      var bandContent = $('<div class="bandContent"></div>');
      bandContent.append(topicsList);

      var band = $('<div class="band"></div>');
      band.append(bandContent);

      var topicsPositioner = $('<div class="topicsPositioner"></div>');
      topicsPositioner.append(band);

      var topicsContainer = $('<div class="topicsContainer"></div>');
      topicsContainer.append(topicsPositioner);

      return topicsContainer;

    }

    // transform the DOM here
  function transformDOM() {
    var container = $('<div class="pageContent band"><div class="bandContent page"><div class="topics"></div></div></div>');
    $(document.body).wrapInner(container);

    titleText = $('title')[0].innerText;

    var progAttr = $('meta[name=progressive]').attr("content");
    docProgressiveReveal = (progAttr == 'true' || progAttr == 'TRUE');
    var allowSkipAttr = $('meta[name=allow-skip]').attr("content");
    docAllowSkip = (allowSkipAttr == 'true' || allowSkipAttr == 'TRUE');

    var tutorialTitle = $('<h2 class="tutorialTitle">' + titleText + '</h2>');
    tutorialTitle.on('click', showFloatingTopics);
    $('.topics').prepend(tutorialTitle);

    $('.bandContent').append(buildTopicsList());

    // initialize visibility of all topics' elements
    for (var t = 0; t < topics.length; t++) {
      updateVisibilityOfTopicElements(t);
    }

    setCurrentTopic(0);

    function handleResize() {
      $('.topicsList').css("max-height", window.innerHeight - 30);
    }

    handleResize();
    window.addEventListener("resize", handleResize);

  }

  transformDOM();

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
      var exerciseIndex = -1;
      var exerciseId = jqSection.attr('id');
      $.each(topic.exercises, function(ei, e ) {
        if (e.id == exerciseId) {
          exerciseIndex = ei;
          return false;
        }
      })
      if (exerciseIndex == -1) {
        console.log('completed exercise"' + exerciseId + '"not found');
        return;
      }

      // update the UI if the exercise isn't already marked completed
      var exercise = topic.exercises[exerciseIndex];
      if (!exercise.completed) {
        topic.exercisesCompleted++;

        updateTopicProgressBar(topicIndex);

        // update the exercise
        $(exercise.jqElement).addClass('done');
        exercise.completed = true;

        // update visibility of topic's exercises and actions
        updateVisibilityOfTopicElements(topicIndex);
      }

    }

  }

  // update the UI after an exercise gets skipped
  function exerciseSkipped(exerciseElement) {

    var exerciseSkippedLabel = exerciseElement.attr('data-label')

    var topicIndex = -1;
    var exerciseIndex = -1;
    $.each(topics, function( ti, t) {
      $.each(t.exercises, function( ei, e) {
        if (exerciseSkippedLabel == e.dataLabel) {
          topicIndex = ti;
          exerciseIndex = ei;
          return false;
        }
      })
      return topicIndex == -1;
    })

    if (topicIndex == -1 || exerciseIndex == -1) {
      console.log('skipped exercise not found');
      return;
    }

    topics[topicIndex].exercises[exerciseIndex].skipped = true;

    // update visibility of topic's exercises and actions
    updateVisibilityOfTopicElements(topicIndex);
  }


  // initialize components within tutor.onInit event
  tutor.onInit(function() {

    // handle progress events
    tutor.onProgress(function(progressEvent) {
      if (progressEvent.event === "section_completed")
        sectionCompleted(progressEvent.element);
      else if (progressEvent.event === "exercise_skipped")
        exerciseSkipped($(progressEvent.element));
    });

  });

});
