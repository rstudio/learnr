


Tutor.prototype.$restoreState = function() {
  
  // alias this
  var thiz = this;
  
  // retreive state from server
  this.$serverRequest("restore_state", null, function(data) {
    
    // work through each piece of state
    for (var i = 0; i < data.length; i++) {
      
      var state = data[i];
      var label = state.id[0];
      var submission = state.data;
     
      // exercise submissions
      if (data[i].type[0] === "exercise_submission") {
        
        // get code
        var code = submission.code[0];
      
        // find the editor 
        var editorContainer = thiz.$exerciseEditor(label);
        if (editorContainer.length > 0) {
          
          // restore code
          var editor = ace.edit(editorContainer.attr('id'));
          editor.setValue(code, -1);
          
          // fire restore event on the container (this will restore the output)
          editorContainer.trigger('restore');
        }
      }
      
      // quesiton submissions
      if (data[i].type[0] == "question_submission") {
        
        // find the quiz 
        var quiz = $('.quiz[data-label="' + label + '"]');
        
        // if we have answers then restore them
        if (submission.answers.length > 0) {
          
          // select answers
          var answers = quiz.find('.answers').children('li');
          for (var a = 0; a < answers.length; a++) {
            var answer = $(answers[a]);
            var answerLabel = answer.children('label').text();
            if (submission.answers.indexOf(answerLabel) != -1)
              answer.children('input').prop('checked', true); 
          }
          
          // set restoring flag on quiz element
          quiz.data('restoring', true);
          
          // click submit button 
          var checkAnswer = quiz.find('.checkAnswer'); 
          checkAnswer.trigger('click');
        }
      }
    }
  });
};

