

$(document).ready(function() {
  
  // find interactive code blocks
  $(".tutor-interactive").each(function() {
    
    // get code then remove the code element
    var code_element = $(this).children('pre').children('code');
    var code = code_element.text()  + "\n";
    code_element.parent().remove();
    
    // add div with id in it's place
    var code_div = $('<div></div>');
    var code_id = $(this).attr('data-label') + "-code";
    code_div.attr('id', code_id);
    code_div.addClass('tutor-interactive-editor');
    $(this).prepend(code_div);
    
  
    // edit it
    var editor = ace.edit(code_id);
    editor.setHighlightActiveLine(false);
    editor.setShowPrintMargin(false);
    editor.setShowFoldWidgets(false);
    editor.renderer.setDisplayIndentGuides(false);
    editor.setTheme("ace/theme/textmate");
    editor.$blockScrolling = Infinity;
    editor.session.setMode("ace/mode/r");
    editor.session.getSelection().clearSelection();
    editor.setValue(code, -1);
    editor.setOptions({
      minLines: 2,
      maxLines: Math.max(editor.session.getLength(), 2)
    });
  });
  
});

