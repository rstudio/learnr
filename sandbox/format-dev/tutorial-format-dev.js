

$(document).ready(function() {

  var titleText = '';
  var currentTopicIndex = -1;
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
      topic.jqElement = element;
      topic.jqTitleElement = $(element).children('h2')[0];
      topic.titleText = topic.jqTitleElement.innerText;
      jqTopic = $('<div class="topic" index="' + i + '">' + topic.titleText + '</div>');
      jqTopic.on('click', handleTopicClick);
      topic.jqListElement = jqTopic;
      $(topicsList).append(jqTopic);
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

  titleText = $('head > title')[0].innerText;
  var tutorialTitle = $('<div class="tutorialTitle">' + titleText + '</div>');
  tutorialTitle.on('click', showFloatingTopics);
  $('.topics').prepend(tutorialTitle);

  $('.bandContent').append(buildTopicsList());

  setCurrentTopic(0);

  function handleResize() {
    $('.topicsList').css("max-height", window.innerHeight - 30);
  }

  handleResize();
  window.addEventListener("resize", handleResize);

});
