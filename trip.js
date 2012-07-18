function init()
{ var base = '<!--#echo var="base" encoding="url"-->';
  var sexp = document.createElement('script');
  var bbc = document.createElement('script');
  var gplus = document.createElement('script');
  var fb = document.createElement('script');
  var fbdiv = document.createElement('div');
  fbdiv.id = 'fb-root';
  document.body.insertBefore(fbdiv, document.body.firstChild);
  bbc.type = sexp.type = gplus.type = fb.type = 'text/javascript';
  sexp.src = base + '/sexp.js';
  bbc.src = base + '/bbcode.js';
  gplus.src = 'https://apis.google.com/js/plusone.js';
  fb.src = 'http://connect.facebook.net/en_US/all.js#xfbml=1';
  document.getElementsByTagName('head')[0].appendChild(sexp);
  document.getElementsByTagName('head')[0].appendChild(bbc);
  document.getElementsByTagName('head')[0].appendChild(fb);
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
  { if(divs[i].className == 'post' || divs[i].className == 'thread')
    { (function()
      { var head = divs[i].firstChild;
        var parts = divs[i].id.split('_');
        var thread = parts[0];
        var post = parts[1];
        if(post)
        { var comment = divs[i].lastChild;
          var html_link = document.createElement('a');
          var sexp_link = document.createElement('a');
          var bbc_link = document.createElement('a');
          html_link.href = 'javascript:(function(){var post=document.getElementById("' + divs[i].id + '");var comment=post.lastChild;comment.innerHTML=comment.innerText;post.removeChild(post.firstChild);return true})()';
          sexp_link.href = 'javascript:(function(){var post=document.getElementById("' + divs[i].id + '");var comment=post.lastChild;comment.innerHTML=parser(comment.innerText);post.removeChild(post.firstChild);return true})()';
          bbc_link.href = 'javascript:(function(){var post=document.getElementById("' + divs[i].id + '");var comment=post.lastChild;comment.innerHTML=render(parse(tokenize(comment.innerText)));post.removeChild(post.firstChild);return true})()';
          html_link.appendChild(document.createTextNode('html'));
          sexp_link.appendChild(document.createTextNode('sexpcode'));
          bbc_link.appendChild(document.createTextNode('bbcode'));
          format_div = document.createElement('div');
          format_div.style.fontSize = 'xx-small';
          format_div.appendChild(document.createTextNode('formatting: '));
          format_div.appendChild(html_link);
          format_div.appendChild(document.createTextNode(' '));
          format_div.appendChild(sexp_link);
          format_div.appendChild(document.createTextNode(' '));
          format_div.appendChild(bbc_link);
          divs[i].insertBefore(format_div, divs[i].firstChild);
          head.onclick = function(e)
          { var form = document.getElementById('sage_'+thread).parentNode;
            var textarea = form.getElementsByTagName('textarea')[0];
            textarea.focus();
            if(textarea.value != '' && textarea.value.substr(-1) != '\n')
              textarea.value += '\n';
            textarea.value += '>>' + post + '\n'; };
          if(head.getElementsByTagName('span').length)
          { var span = head.getElementsByTagName('span')[0];
            try
            { var x = new XMLHttpRequest();
              x.span = span;
              x.onreadystatechange = function()
              { if(this.readyState == 4 && this.status == 200)
                { this.span.appendChild(document.createTextNode(' !' + this.responseText)); }};
              x.open('GET', base + '/threads/' + thread + '/posts/.' + post + '.trip', true);
              x.send(); }
            catch(e) { }}};
        var url = base + '/' + thread + (post ? '/' + post : '');
        var plus = document.createElement('div');
        plus.className = 'g-plusone';
        plus.style.display = 'inline';
        plus.setAttribute('data-size', 'small');
        plus.setAttribute('data-href', url);
        head.appendChild(document.createTextNode(' '));
        head.appendChild(plus);
        var like = document.createElement('div');
        like.className = 'fb-like';
        like.setAttribute('data-href', url);
        like.setAttribute('data-send', 'false');
        like.setAttribute('data-layout', 'button_count');
        like.setAttribute('data-width', '450');
        like.setAttribute('data-show-faces', 'false');
        head.appendChild(document.createTextNode(' '));
        head.appendChild(like); })();}}

  document.getElementsByTagName('head')[0].appendChild(gplus);
  if(document.createTreeWalker)
  { var proto = 'data|ftp|gopher|http|https|mailto|news|nntp|rtsp|sip|sips|tel|telnet|xmpp|ed2k|irc|ircs|irc6|magnet|mms|rsync|rtmp|ssh|sftp';
    var url = new RegExp('(' + proto + '):[^ "<>{}|\\^~`]*', 'g');
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
      var t = n.nodeValue;
      t = t.replace(/</g, '&lt;');
      t = t.replace(/>/g, '&gt;');
      s.innerHTML = t.replace(url, '<a href="$&">$&</a>');
      n.parentNode.replaceChild(s, n); }}}
