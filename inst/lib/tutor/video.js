

Tutor.prototype.$initializeVideos = function() {
  
  // regexes for video types
  var youtubeRegex = /^.*(youtu.be\/|v\/|u\/\w\/|embed\/|watch\?v=|\&v=)([^#\&\?]*).*/;
  var vimeoRegex = /(?:vimeo)\.com.*(?:videos|video|channels|)\/([\d]+)/i;
  
  // check a url for a video
  function isVideo(src) {
    return src.match(youtubeRegex) || src.match(vimeoRegex);
  }
  
  // function to normalize a video src url (web view -> embed)
  function normalizeVideoSrc(src) {
    
    // youtube
    var youtubeMatch = src.match(youtubeRegex);
    if (youtubeMatch)
      return "https://www.youtube.com/embed/" + youtubeMatch[2];
   
    // vimeo
    var vimeoMatch = src.match(vimeoRegex);
    if (vimeoMatch)
      return "https://player.vimeo.com/video/" + vimeoMatch[1];

    // default to reflecting src back      
    return src;
  }
  
  // function to set the width and height for the container conditioned on
  // any user-specified height and width
  function setContainerSize(container, width, height) {
    
    // default ratio
    var aspectRatio = 9 / 16;
    
    // default width to 100% if not specified
    if (!width)
      width = "100%";
    
    // percentage based width
    if (width.slice(-1) == "%") {
      
      container.css('width', width);
      if (!height) {
        height = 0;
        var paddingBottom = (parseFloat(width) * aspectRatio) + '%';
        container.css('padding-bottom', paddingBottom);
      }
      container.css('height', height);
    }
    // other width unit
    else {
      // add 'px' if necessary
      if ($.isNumeric(width))
        width = width + "px";
      container.css('width', width);
      if (!height)
        height = (parseFloat(width) * aspectRatio) + 'px';
      container.css('height', height);
    }
  }
  
  // inspect all images to see if they contain videos
  $("img").each(function() {
    
    // skip if this isn't a video
    if (!isVideo($(this).attr('src')))
      return;
      
    // hide while we process
    $(this).css('display', 'none');

    // collect various attributes
    var width = $(this).get(0).style.width;
    var height = $(this).get(0).style.height;
    $(this).css('width', '').css('height', '');
    var attrs = {};
    $.each(this.attributes, function(idex, attr) {
      if (attr.nodeName == "width")
        width = String(attr.nodeValue);
      else if (attr.nodeName == "height")
        height = String(attr.nodeValue);
      else if (attr.nodeName == "src")
        attrs.src = normalizeVideoSrc(attr.nodeValue);
      else
        attrs[attr.nodeName] = attr.nodeValue;
    });
    
    // create and initialize iframe
    $(this).replaceWith(function() {
      var iframe = $('<iframe/>', attrs);
      iframe.addClass('tutor-video');
      iframe.attr('allowfullscreen', '');
      iframe.css('display', '');
      var container = $('<div class="tutor-video-container"></div>');
      setContainerSize(container, width, height);
      container.append(iframe);
      return container;
    });
  });
};
