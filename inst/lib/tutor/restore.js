


Tutor.prototype.$restoreState = function() {
  
  // alias this
  var thiz = this;
  
  // retreive state from server
  this.$serverRequest("restore_state", null, function(data) {
    
    // get submissions
    var submissions = data.submissions;
    
    // work through each piece of state
    for (var i = 0; i < submissions.length; i++) {
      
      var submission = submissions[i];
      var type = submission.type[0];
      var label = submission.id[0];
     
      // exercise submissions
      if (type === "exercise_submission") {
        
        // get code
        var code = submission.data.code[0];
      
        // find the editor 
        var editorContainer = thiz.$exerciseEditor(label);
        if (editorContainer.length > 0) {
          
          // restore code
          var editor = ace.edit(editorContainer.attr('id'));
          editor.setValue(code, -1);
          
          // fire restore event on the container (also set
          // restoring flag on the exercise so we don't scroll it
          // into view after restoration)
          thiz.$exerciseForLabel(label).data('restoring', true);
          editorContainer.trigger('restore');
        }
      }
      
      // quesiton submissions
      else if (type === "question_submission") {
        
        // find the quiz 
        var quiz = $('.quiz[data-label="' + label + '"]');
        
        // if we have answers then restore them
        if (submission.data.answers.length > 0) {
          
          // select answers
          var answers = quiz.find('.answers').children('li');
          for (var a = 0; a < answers.length; a++) {
            var answer = $(answers[a]);
            var answerText = answer.children('label').attr('data-answer');
            if (submission.data.answers.indexOf(answerText) != -1)
              answer.children('input').prop('checked', true); 
          }
          
          // click submit button if we applied an answer
          if (answers.find('input:checked').length > 0) {
            
            // set restoring flag on quiz element
            quiz.data('restoring', true);
            
            // click the button
            var checkAnswer = quiz.find('.checkAnswer'); 
            checkAnswer.trigger('click');
          }
        }
      }
    }
  });
};

