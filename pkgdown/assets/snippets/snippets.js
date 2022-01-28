

function loadSnippet(snippet, mode) {
  mode = mode || "r";
  $("#" + snippet).addClass("snippet");
  var editor = ace.edit(snippet);
  editor.setHighlightActiveLine(false);
  editor.setShowPrintMargin(false);
  editor.setReadOnly(true);
  editor.setShowFoldWidgets(false);
  editor.renderer.setDisplayIndentGuides(false);
  editor.renderer.setShowGutter(true);
  editor.renderer.setOption('showLineNumbers', true);
  editor.setTheme("ace/theme/textmate");
  editor.$blockScrolling = Infinity;
  editor.session.setMode("ace/mode/" + mode);
  editor.session.getSelection().clearSelection();

  // create element to hold the snippet for screen readers
  const pre = document.createElement('pre')
  pre.classList = 'markdown sr-only'
  const code = document.createElement('code')
  pre.appendChild(code)

  var root = document.querySelector('meta[name="pkgdown-site-root"]').content
  $.get(root + "snippets/" + snippet + ".md", function(data) {
    // Write the snippet into the editor
    editor.setValue(data, -1);
    editor.setOptions({
      maxLines: editor.session.getLength()
    });

    // and write the snippet into the screen reader element
    code.innerHTML = data;
    editor.container.insertBefore(pre, editor.container.firstChild);
  });
}
