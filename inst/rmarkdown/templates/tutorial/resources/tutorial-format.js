

$(document).ready(function() {

    var titleText = '';
    var currentTopicIndex = -1;
    var progressiveExerciseReveal = true;
    var topics = [];

    function setCurrentTopic(topicIndex) {
      topicIndex = topicIndex * 1;  // convert strings to a number

      if (topicIndex == currentTopicIndex) return;

      if (currentTopicIndex != -1) {
        $(topics[currentTopicIndex].jqElement).removeClass('current');
        $(topics[currentTopicIndex].jqListElement).removeClass('current');
      }

      $(topics[topicIndex].jqElement).addClass('current');
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
      if (!progressiveExerciseReveal) return;

      var topic = topics[topicIndex];

      var showExercise = true;

      for (i = 0; i < topic.exercises.length; i++ ) {
        var exercise = topic.exercises[i];

        if (showExercise) {
          $(exercise.jqElement).removeClass('hide');
          if (exercise.completed || exercise.skipped) {
            $(exercise.jqElement).removeClass('showSkip');
          }
          else {
            $(exercise.jqElement).addClass('showSkip');
          }
        }
        else {
          $(exercise.jqElement).addClass('hide');
        }
        showExercise = (showExercise && (exercise.completed || exercise.skipped));
      }

      if (!progressiveExerciseReveal || showExercise) { // all exercises are either completed or skipped
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

    function exerciseCompleted(topicIndex, exerciseIndex) {
      // update the topic's progress Bar
      var topic = topics[topicIndex];
      topic.exercisesCompleted++;

      updateTopicProgressBar(topicIndex);

      // update the exercise
      $(topic.exercises[exerciseIndex].jqElement).addClass('done');
      topic.exercises[exerciseIndex].completed = true;

      // update visibility of topic's exercises and actions
      updateVisibilityOfTopicElements(topicIndex);
    }

    function exerciseSkipped(topicIndex, exerciseIndex) {
      var topic = topics[topicIndex];
      topic.exercises[exerciseIndex].skipped = true;

      // update visibility of topic's exercises and actions
      updateVisibilityOfTopicElements(topicIndex);
    }

    function handleSkipClick(event) {
      exerciseSkipped(this.getAttribute('topic-index'), this.getAttribute('index'));
    }

    function handleNextTopicClick(event) {
      var topic = topics[currentTopicIndex];
      topic.topicCompleted = true;
      updateTopicProgressBar(currentTopicIndex);
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
      topicsDOM.each( function(topicIndex, element) {

        var topic = {};
        topic.exercisesCompleted = 0;
        topic.topicCompleted = false; // set by pressing Next Topic button and only relevant if topic has 0 exercises
        topic.jqElement = element;
        topic.jqTitleElement = $(element).children('h2')[0];
        topic.titleText = topic.jqTitleElement.innerText;
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
        $(element).append(topicActions);

        topic.exercises = [];
        var exercisesDOM = $(element).children('.section.level3');
        exercisesDOM.each( function( exerciseIndex, element) {
          // add skip button as needed
          if ($(element).attr('allow-skip')) {
            var skipButton = $('<button class="btn btn-default skip" topic-index="' + topicIndex + '" index="' + exerciseIndex + '">Skip</button>');
            skipButton.on('click', handleSkipClick);
            var actions = $('<div class="exerciseActions"></div>');
            actions.append(skipButton);
            $(element).append(actions);
          }

          var exercise = {};
          exercise.completed = false;
          exercise.skipped = false;
          exercise.jqElement = element;
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

    // transform the DOM here, e.g.
    var container = $('<div class="pageContent band"><div class="bandContent page"><div class="topics"></div></div></div>');
    $(document.body).wrapInner(container);

    titleText = $('title')[0].innerText;
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


  // update navigation w/ progress
  function showProgress(section) {


  }

  // initialize components within tutor.onInit event
  tutor.onInit(function() {

    // show progress for section completed events
    tutor.onProgress(function(progressEvent) {
      if (progressEvent.event === "section_completed")
        showProgress($(progressEvent.element));
    });

  });

});
