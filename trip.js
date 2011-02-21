function init()
{ var base = '<!--#echo var="base" encoding="url"-->';
  var forms = document.getElementsByTagName('form');
  for(var i = 0; i < forms.length; ++i)
  { var label = document.createElement('label');
    label.for = 'pass' + i;
    label.appendChild(document.createTextNode('tripcode (optional): '));
    var input = document.createElement('input');
    input.type = 'text';
    input.id = 'pass' + i;
    input.name = 'pass';
    var br = document.createElement('br');
    forms[i].insertBefore(br, forms[i].firstChild);
    forms[i].insertBefore(input, forms[i].firstChild);
    forms[i].insertBefore(label, forms[i].firstChild); }
  var divs = document.getElementsByTagName('div');
  for(var i = 0; i < divs.length; ++i)
  { if(divs[i].className == 'post')
    { (function()
      { var head = divs[i].firstChild;
        var parts = divs[i].id.split('_');
        var thread = parts[0];
        var post = parts[1];
        head.onclick = function(e)
        { var span = document.createElement('span');
          span.className = 'trip';
          var x = new XMLHttpRequest();
          x.open('GET', base + '/threads/' + thread + '/posts/.' + post + '.trip', false);
          x.send();
          if(x.status == 200)
          { var span = document.createElement('span');
            span.className = 'trip';
            span.appendChild(document.createTextNode(' !' + x.responseText));
            head.appendChild(span);
            head.onclick = null; }}})();}}

  if(document.createTreeWalker)
  { var proto = 'data|ftp|gopher|http|https|mailto|news|nntp|rtsp|sip|sips|tel|telnet|xmpp|ed2k|irc|ircs|irc6|magnet|mms|rsync|rtmp|ssh|sftp';
    var url = new RegExp();
    url.compile('(' + proto + '):[^ "<>{}|\\^~`]*');
    var tw = document.createTreeWalker(
               document.body,
               NodeFilter.SHOW_TEXT,
               function(n) { return  n.parentNode.className == 'comment' ?
                                    NodeFilter.FILTER_ACCEPT :
                                    NodeFilter.FILTER_SKIP; },
               false);
    var nodes = [];
    while(tw.nextNode())
      nodes.push(tw.currentNode);
    var n;
    for(var i = 0; n = nodes[i]; ++i)
    { var s = document.createElement('span');
      s.innerHTML = n.data.replace(url, '<a href="$&">$&</a>');
      n.parentNode.replaceChild(s, n); }}}
