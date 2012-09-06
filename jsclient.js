var sort_functions = { bumped:  function(a, b){ return b.bumped  - a.bumped },
                       created: function(a, b){ return b.created - a.created },
                       updated: function(a, b){ return b.updated - a.updated },
                       title:   function(a, b){ return a.title.localeCompare(b.title) } };
var sort_function = sort_functions.bumped;
var threads = new Array();

$(document).ready(function()
{ $('body').append('<div id="threads"></div>');
  $('#sortfunction').change(sort_threads);
  get_threads(); });

function get_threads()
{ $.getJSON('json/', update_threads); }

function update_threads(data)
{ var old_threads = threads;
  threads = data;
  opened_threads = $.grep(old_threads, function(e) { return e.opened });
  for(var i = 0; i < opened_threads.length; ++i)
  { var thread_match = $.grep(threads, function(e) { return e.id == opened_threads[i].id; });
    if(thread_match.length) thread_match[0].opened = true; }
  show_threads();
  setTimeout(get_threads, 30000); }

function show_threads()
{ threads.sort(sort_function);
  $('#threads').empty();
  for(var i = 0; i < threads.length; ++i)
  { $('#threads').append('<div class="thread" id="' + threads[i].id + '">' +
                         ' <span class="title" ' +
                         ' onclick="toggle_thread(' + threads[i].id + ')">' +
                         threads[i].title + '</span>' +
                         ' <div class="posts"></div>' +
                         '</div>');
    $('#' + threads[i].id + ' > .posts').hide();
    if(threads[i].opened) open_thread(threads[i].id); } }

function sort_threads(e)
{ sort_function = sort_functions[$('#sortfunction').attr('value')];
  if(threads) show_threads(); }

function toggle_thread(id)
{ var thread_match = $.grep(threads, function(e) { return e.id == id });
  if(thread_match.length)
  { var thread = thread_match[0];
    if(thread.opened) close_thread(id);
    else open_thread(id); } }

function open_thread(id)
{ var thread_match = $.grep(threads, function(e) { return e.id == id });
  if(thread_match.length)
  { var thread = thread_match[0];
    thread.opened = true;
    $.getJSON('json/' + id, function(data) { show_thread(id, data) }); } }

function close_thread(id)
{ var thread_match = $.grep(threads, function(e) { return e.id == id });
  if(thread_match.length)
  { var thread = thread_match[0];
    thread.opened = false;
    $('#' + id + ' > .posts').hide(); } }

function show_thread(id, data)
{ var posts_div = $('#' + id + ' > .posts');
  posts_div.empty();
  for(var i in data)
  { var com = data[i].com;
    var proto = 'data|ftp|gopher|http|https|mailto|news|nntp|rtsp|sip|sips|tel|telnet|xmpp|ed2k|irc|ircs|irc6|magnet|mms|rsync|rtmp|ssh|sftp';
    var url = new RegExp('(' + proto + '):[^ "<>{}|\\^~`]*', 'g');
    com = com.replace(/>/g, '&gt;');
    com = com.replace(/</g, '&lt;');
    com = com.replace(/&gt;&gt;([0-9,-]*)/g, '<a href="">&gt;&gt;$1</a>');
    com = com.replace(/\n/g, '<br>');
    com = com.replace(/(^|<br>)(&gt;.*?)(<br>|$)/g, '$1<span class="quote">&gt;$2</span>$3');
    com = com.replace(url, '<a href="$&">$&</a>');
    var name = data[i].name.replace(/^Anonymous/, '');
    posts_div.append('<div class="post"><div class="post_head">' +
                     ' <span class="num">' + i + '</span>' +
                     ' <span class="date">' + new Date(data[i].now * 1000) + '</span>' +
                     ' <span class="name">' + name + '</span>' +
                     '</div><div class="post_body">' + com + '</div></div>'); }
  posts_div.show(); }
