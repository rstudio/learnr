


Tutor.prototype.$restoreState = function() {
  
  // alias this
  var thiz = this;
  
  // retreive state from server
  this.$serverRequest("restore_state", null, function(data) {
    
    // work through each piece of state
    for (var i = 0; i < data.length; i++) {
      var state = data[i];
      
      // exercise submissions
      if (data[i].type[0] === "exercise_submission") {
        
        // get submission data
        var exercise = data[i].data;
        var code = exercise.code[0];
      
        // find the editor
        var label = data[i].id[0];
        var editorContainer = thiz.$exerciseEditor(label);
        if (editorContainer.length > 0) {
          
          // restore code
          var editor = ace.edit(editorContainer.attr('id'));
          editor.setValue(code, -1);
          
          // TODO: trigger output via firing 'restore' event on container
          
          // TODO: ensure we don't scrollIntoView for restored output
        }
        
      }
      
    }
      
  });
};

