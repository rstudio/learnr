


Tutor.prototype.$restoreState = function() {
  
  // retreive state from server
  this.$serverRequest("restore_state", null, function(data) {
    
    console.log(data);
      
  });
};

