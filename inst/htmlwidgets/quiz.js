HTMLWidgets.widget({

  name: 'quiz',

  type: 'output',

  factory: function(el, width, height) {

    
    return {

      renderValue: function(x) {

        $(el).slickQuiz({json: x.quiz});
      },

      resize: function(width, height) {

        // TODO: code to re-render the widget with a new size

      }

    };
  }
});