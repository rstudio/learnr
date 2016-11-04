HTMLWidgets.widget({

  name: 'quiz',

  type: 'output',

  factory: function(el, width, height) {

    return {

      renderValue: function(x) {
        
        x.animationCallbacks = {
          checkAnswer: function() {
            
            // add success text to correct answers
            $(el).find('ul.answers').find('li.correct').addClass('text-success');
    
            
            var correctItem = $(el).find('ul.responses').find('li.correct');
            var correct = correctItem.css('display') == 'list-item';
            
            console.log("answer checked: " + correct);  
          }
        };
        
        // initialize slickQuick
        $(el).slickQuiz(x);
        
        // get the correctItem and apply bg-success to it
        var correctItem = $(el).find('ul.responses').find('li.correct');
        correctItem.addClass('alert alert-success');
            
        // get the incorrectItem and apply bg-danger to it
        var incorrectItem = $(el).find('ul.responses').find('li.incorrect');
        incorrectItem.addClass('alert alert-danger');
        
        // make check answer a proper button
        $(el).find(".checkAnswer").addClass('btn btn-info');
      },

      resize: function(width, height) {
        // size is 100% width and flowing height
      }

    };
  }
});