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
