HTMLWidgets.widget({

  name: 'quiz',

  type: 'output',

  factory: function(el, width, height) {

    return {

      renderValue: function(x) {
        
        // helper function to record an answer
        function recordAnswer(correct) {
          if (window.tutor && x.label) {
            var answers = [];
            var checkedInputs = $(el).find('.answers').find('input:checked');
            checkedInputs.each(function() {
              var label = $("label[for='"+$(this).attr("id")+"']");
              answers.push(label.text());
            });
            // notify server of question submission
            tutor.questionSubmission(x.label, x.question, answers, correct);
          }
        }
        
        // provide callback for providing answer feedback and recording it
        x.animationCallbacks = {
          checkAnswer: function() {
        
            // add checked and text-success class to correct answers
            $(el).find('ul.answers').find('li.correct').addClass('checked text-success');
            
            // check whether the answer is correct
            var correct = correctItem.css('display') == 'list-item';
            
            // look for custom messages
            var msg_class = correct ? '.correct' : '.incorrect';
            var message = $(el).find('.responses').children(msg_class).text();
            var messages = $(el).find('.answers').children(msg_class + '[data-message]');
            messages.each(function() {
              if ($(this).children('input').is(':checked')) {
                 var data_message = $(this).attr('data-message');
                 message = message + ' ' + data_message;
              }
            });
            
            // display custom messages
            $(el).find('.responses').children(msg_class).html(message);
            
            // render mathjax
            if (window.MathJax)
              window.MathJax.Hub.Queue(["Typeset",MathJax.Hub,el]);
              
            // record answer
            recordAnswer(correct);
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
        var checkAnswer = $(el).find(".checkAnswer");
        checkAnswer.addClass('btn btn-primary btn-md');
      },

      resize: function(width, height) {
        // size is 100% width and flowing height
      }

    };
  }
});