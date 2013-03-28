function BBCodeTag(start, end, unparsed)
{ this.start = start;
  this.end = end;
  this.unparsed = unparsed; }

var tags = { 'aa': new BBCodeTag('<span class="aa">', '</span>'),
             'b': new BBCodeTag('<b>', '</b>'),
             'code': new BBCodeTag('<code>', '</code>', true),
             'i': new BBCodeTag('<i>', '</i>'),
             'tt': new BBCodeTag('<tt>', '</tt>'),
             'o': new BBCodeTag('<span class="o">', '</span>'),
             'quote': new BBCodeTag('<blockquote>', '</blockquote>'),
             'del': new BBCodeTag('<del>', '</del>'),
             'spoiler': new BBCodeTag('<span class="spoiler">', '</span>'),
             'sub': new BBCodeTag('<sub>', '</sub>'),
             'sup': new BBCodeTag('<sup>', '</sup>'),
             'u': new BBCodeTag('<u>', '</u>'),
             '#': new BBCodeTag('', '', true) };

function parseBBCode(text)
{ var tag_re = /^(.*?)\[([a-z#]+)\](.*)\[\/\2\](.*)$/m;
  var match = tag_re.exec(text);
  if(!match) return text.replace('[br]', '\n', 'gim');
  var before = match[1];
  var tag = match[2];
  var start = '[' + tag + ']';
  var end = '[/' + tag + ']';
  var inside = match[3];
  var after = match[4];
  if(!tags[tag] || !tags[tag].unparsed) inside = parseBBCode(inside);
  if(tags[tag])
  { start = tags[tag].start;
    end = tags[tag].end; }
  return before + start + inside + end + after; }

function getPlainText(node)
{ var out = '';
  for(var i = 0; i < node.childNodes.length; ++i)
  { if(node.childNodes[i].nodeName=='BR') out += '\n';
    else out += node.childNodes[i].textContent; }
  return out; }

function make_format_link(div, label, format_function)
{ var link = document.createElement('a');
  link.href = 'javascript:(function(){var post=document.getElementById("' + div.id + '");var comment=post.lastChild;comment.innerHTML=' + format_function + '(getPlainText(comment));post.removeChild(post.firstChild);})()';
  link.appendChild(document.createTextNode(label));
  return link; }

function init()
{ var base = '<!--#echo var="base" encoding="url"-->';
  var bbc = document.createElement('script');
  bbc.type = 'text/javascript';
  bbc.src = base + '/bbcode.js';
  document.getElementsByTagName('head')[0].appendChild(bbc);
  var forms = document.getElementsByTagName('form');
  var divs = document.getElementsByTagName('div');
  for(var i = 0; i < divs.length; ++i)
  { if(divs[i].className == 'post')
    { (function()
      { var head = divs[i].firstChild;
        var parts = divs[i].id.split('_');
        var thread = parts[0];
        var post = parts[1];
        format_div = document.createElement('div');
        format_div.style.fontSize = 'xx-small';
        format_div.appendChild(document.createTextNode('formatting: '));
        format_div.appendChild(make_format_link(divs[i], 'html', ''));
        format_div.appendChild(document.createTextNode(' '));
        format_div.appendChild(make_format_link(divs[i], 'bbcode', 'parseBBCode'));
        divs[i].insertBefore(format_div, divs[i].firstChild);
        head.onclick = function(e)
        { var form = document.getElementById('sage_'+thread).parentNode;
          var textarea = form.getElementsByTagName('textarea')[0];
          textarea.focus();
          if(textarea.value != '' && textarea.value.substr(-1) != '\n')
            textarea.value += '\n';
          textarea.value += '>>' + post + '\n'; }; })();}}

  if(document.createTreeWalker)
  { var url = new RegExp(
      '[a-z][a-z0-9+.-]*:[^\\s`"<>{}()|\\^~`]*(?:\\([^\\s"<>{}()|\\^~`]+\\)|[^\\s"<>{}()|\\^~`.,;])',
      'g');
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
      if(t.match(/^>/)) s.className='quote';
      t = t.replace(/</g, '&lt;');
      t = t.replace(/>/g, '&gt;');
      s.innerHTML = t.replace(url, '<a href="$&">$&</a>');
      n.parentNode.replaceChild(s, n); }}}
