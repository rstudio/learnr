

Tutor.prototype.$initializeStorage = function(identifiers, success) {
  
  // alias this
  var thiz = this;
  
  // initialize data store. note that we simply ignore errors for interactions
  // with storage since the entire behavior is a nice-to-have (i.e. we automatically
  // degrade gracefully by either not restoring any state or restoring whatever
  // state we had stored)
  thiz.$store = localforage.createInstance({ 
    name: "Tutorial-Storage", 
    storeName: window.btoa(identifiers.tutorial_id + 
                           identifiers.tutorial_version + 
                           identifiers.user_id)
  });
  
  // custom message handler to update store
  Shiny.addCustomMessageHandler("tutor.store_object", function(message) {
    thiz.$store.setItem(message.id, message.data);
  });
  
  // retreive the currently stored objects then pass them down to restore_state
  var objects = null;
  thiz.$store.iterate(function(value, key, iterationNumber) {
    objects = objects || {};
    objects[key] = value;
  }).then(function() {
    success(objects);
  });
};


Tutor.prototype.$restoreState = function(objects) {
  
  // alias this
  var thiz = this;
  
  // retreive state from server
  this.$serverRequest("restore_state", objects, function(data) {
    
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

Tutor.prototype.$removeState = function(completed) {
  this.$store.clear()
    .then(completed)
    .catch(function(err) {
      console.log(err);
      completed();
    });
};

