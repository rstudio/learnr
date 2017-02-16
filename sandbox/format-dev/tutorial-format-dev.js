

$(document).ready(function() {
  
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
  }
  
  function buildTopicsList() {
    var topicsList = $('<div class="topicsList"></div>');
    
    var titleText = $('head > title')[0].innerText;
    topicsList.append($('<div class="tutorialTitle">' + titleText + '</div>'));
    
    $(topicsList).append($())
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
    
    return topicsList;
  }

  // transform the DOM here, e.g.
  var container = $('<div class="page-container"><div class="topics"></div></div>');
  $(document.body).wrapInner(container);

  $('.page-container').append(buildTopicsList());
  
  setCurrentTopic(0);
  
});