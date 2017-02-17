
/*

To Do
- Optional Skip Exercise
- Next/Previous Topic buttons
- Start over button

*/

$(document).ready(function() {

  var titleText = '';
  var currentTopicIndex = -1;
  var progressiveExerciseReveal = true;
  var topics = [];

  function setCurrentTopic(topicIndex) {
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
    _.forEach(topic.exercises, function (exercise, i) {
      if (showExercise) {
        $(exercise.jqElement).removeClass('hide');
      }
      else {
        $(exercise.jqElement).addClass('hide');
      }
      showExercise = (showExercise && (exercise.completed || exercise.skipped));
    });

    if (showExercise) { // all exercises are either completed or skipped, so show topic actions

    }
  }

  function exerciseCompleted(topicIndex, exerciseIndex) {
    // update the topic's progress Bar
    var topic = topics[topicIndex];
    topic.exercisesCompleted++;

    $(topic.jqListElement).css('background-position-y', (1 - topic.exercisesCompleted/topic.exercises.length) * 100 + '%' );

    // update the exercise
    $(topic.exercises[exerciseIndex].jqElement).addClass('done');
    topic.exercises[exerciseIndex].completed = true;

    // update visibility of topic's exercises and actions
    updateVisibilityOfTopicElements(topicIndex);
  }

  function buildTopicsList() {
    var topicsList = $('<div class="topicsList hideFloating"></div>');

    var topicsHeader = $('<div class="topicsHeader"></div>');
    topicsHeader.append($('<div class="tutorialTitle">' + titleText + '</div>'));
    var topicsCloser = $('<div class="paneCloser"></div>');
    topicsCloser.on('click', hideFloatingTopics);
    topicsHeader.append(topicsCloser);
    topicsList.append(topicsHeader);

    var topicsDOM = $('.section.level2');
    topicsDOM.each( function(i, element) {

      var topic = {};
      topic.exercisesCompleted = 0;
      topic.jqElement = element;
      topic.jqTitleElement = $(element).children('h2')[0];
      topic.titleText = topic.jqTitleElement.innerText;
      jqTopic = $('<div class="topic" index="' + i + '">' + topic.titleText + '</div>');
      jqTopic.on('click', handleTopicClick);
      topic.jqListElement = jqTopic;
      $(topicsList).append(jqTopic);

      topic.exercises = [];
      var exercisesDOM = $(element).children('.section.level3');
      exercisesDOM.each( function( i, element) {
        var exercise = {};
        exercise.completed = false;
        exercise.skipped = false;
        exercise.jqElement = element;
        topic.exercises.push(exercise);
      });

      topics.push(topic);
    });

    console.log(topics);

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
  var tutorialTitle = $('<div class="tutorialTitle">' + titleText + '</div>');
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

  // TEMP - complete some exercises
  window.setTimeout(function() {
    exerciseCompleted(0, 0);
    exerciseCompleted(0, 1);
    exerciseCompleted(0, 2);
    exerciseCompleted(0, 3);
    exerciseCompleted(0, 4);
    exerciseCompleted(0, 5);
    exerciseCompleted(0, 6);
    exerciseCompleted(1, 0);
    exerciseCompleted(1, 1);
  }, 10);

});
