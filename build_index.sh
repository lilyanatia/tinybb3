#!/bin/sh

basename=$(echo $SCRIPT_NAME | sed 's/[^\/]*$//')
read=${basename}read

# build shiichan-compatible subject.txt
(
 for title in $(ls -t threads/*/title)
 do
  thread=$(echo $title | cut -d/ -f2)
  echo "$(sed 's/&/\&amp;/g;s/</\&lt;/g;s/>/\&gt;/g' $title)<>Anonymous<><>$thread<>$(echo $(ls threads/$thread/posts | wc -l))<>Anonymous<>$(stat -f %m threads/$thread/posts)"
 done
) > subject.txt

# build subback.html
(
 echo '<!DOCTYPE html>'
 echo '<html><head><title>all threads</title>'
 echo '<link rel="stylesheet" type="text/css" href="style.css">'
 echo '</head><body class="subback"><table>'
 echo '<tr><th>title</th><th>posts</th><th>last post</th></tr>'
 for title in $(ls -t threads/*/title)
 do
  thread=$(echo $title | cut -d/ -f2)
  echo "<tr><td>$(sed 's/&/\&amp;/g;s/</\&lt;/g;s/>/\&gt;/g' $title)</td><td>$(ls threads/$thread/posts | wc -l)</td><td>$(stat -f %m threads/$thread/posts)</td></tr>"
 done
 echo '</table></body></html>'
) > subback.html

# build json index
(
 echo -n '['
 (
  for title in $(ls -t threads/*/title)
  do
   thread=$(echo $title | cut -d/ -f2)
   echo -n ',{"id":"'$thread'","title":"'$(cat $title|sed -E 's/(\\|")/\\\1/g')'","created":"'$(stat -f %m threads/$thread/posts/1)'","length":"'$(echo $(ls threads/$thread/posts | wc -l))'","updated":"'$(stat -f %m threads/$thread/posts)'","bumped":"'$(stat -f %m $title)'"}'
  done
 ) | tail -c+2
 echo -n ']'
) > json/index.json

# build gophermap in threads/
(
 echo anonymous bbs
 echo
 for title in $(ls -t threads/*/title)
 do
  thread=$(echo $title | cut -d/ -f2)
  length=$(echo $(ls threads/$thread/posts | wc -l))
  echo '1'$(cat $title | sed 's/	/    /g')' ('$length')	'$thread
 done
) > threads/gophermap

# build
#  json in json/
#  html in read/
#  atom in atom/
#  gophermaps in threads/
stylesheet=${basename}style.css
for thread in $(ls threads | grep -Fv gophermap)
do
 title=$(cat threads/$thread/title)
 if [ ! -e json/$thread -o json/$thread -ot threads/$thread/posts ]
 then
  PATH_INFO=/$thread ./json.pl | tail -n+3 > json/$thread
 fi
 if [ ! -e read/$thread -o read/$thread -ot threads/$thread/posts ]
 then
  PATH_INFO=/$thread ./read.pl | tail -n+3 > read/$thread
 fi
 if [ ! -e atom/$thread -o atom/$thread -ot threads/$thread/posts ]
 then
 (
  echo '<?xml version="1.0" encoding="utf-8"?>'
  echo '<feed xmlns="http://www.w3.org/2005/Atom">'
  echo ' <title>'$title'</title>'
  echo ' <author><name>anonymous</name></author>'
  echo ' <link href="'${basename}atom/$thread'" rel="self"/>'
  echo ' <link href="'${basename}read/$thread'"/>'
  echo ' <updated>'$(TZ=Z stat -f %Sm -t %FT%TZ threads/$thread/posts)'</updated>'
  echo ' <id>'${basename}read/$thread'</id>'
  for post in $(ls -t threads/$thread/posts)
  do
   comment=$(sed -E 's/&/\&amp;/g;s/</\&lt;/g;s/>/\&gt;/g;s/&gt;&gt;(([0-9]*(-[0-9]*)?|l[0-9]*)(,([0-9]*(-[0-9]*)?|l[0-9]*))*)/<a href="'$(echo $read | sed 's/\//\\\//g')'\/'$thread'\/\1">\&gt;\&gt;\1<\/a>/g;s/^/<br\/>/' threads/$thread/posts/$post | tail -c+6)
   echo ' <entry>'
   echo '  <title>'$title' : '$post'</title>'
   echo '  <link href="'$read/$thread/$post'"/>'
   echo '  <id>'$read/$thread/$post'</id>'
   echo '  <updated>'$(TZ=Z stat -f %Sm -t %FT%TZ threads/$thread/posts/$post)'</updated>'
   echo '  <content type="xhtml"><div xmlns="http://www.w3.org/1999/xhtml">'$comment'</div></content>'
   echo ' </entry>'
  done
  echo '</feed>'
 ) > atom/$thread
 fi
 if [ ! -e threads/$thread/gophermap -o threads/$thread/gophermap -ot threads/$thread/posts ]
 then
 (
  echo $title | sed 's/	/    /g' | fold -w 67
  for post in $(ls -t threads/$thread/posts)
  do
   echo
   echo 0$post'	'posts/$post
   cat threads/$thread/posts/$post | sed 's/	/    /g' | fold -w 67
  done
 ) > threads/$thread/gophermap
 fi
done

# build index.html
threads=$(ls -t threads/*/title | cut -d/ -f2)
(
 echo '<!DOCTYPE html>'
 echo '<html><head><title>anonymous bbs</title>'
 echo '<link rel="stylesheet" type="text/css" href="style.css">'
 echo '</head><body class="mainpage">'
 echo '<div class="thread_list"><ol>'
 for thread in $threads
 do
  title=$(cat threads/$thread/title)
  echo '<li><a href="#'$thread'">'$title'</a></li>'
 done
 echo '</ol><div class="threadlinks">'
 echo '<a href="#threadform">new thread</a> |'
 echo '<a href="subback.html">all threads</a>'
 echo '</div></div>'
 for thread in $threads
 do
  title=$(cat threads/$thread/title)
  echo '<div class="thread" id="'$thread'">'
  echo '<div class="thread_head"><a href="read/'$thread'">'$title'</a></div>'
  posts=$(ls -tr threads/$thread/posts)
  if [ $(echo $posts | wc -w) -gt 10 ]
  then
   posts=$(ls -tr threads/$thread/posts | head -n1) $(ls -tr threads/$thread/posts | tail -n9)
  fi
  for post in $posts
  do
   comment=$(sed -E 's/&/\&amp;/g;s/</\&lt;/g;s/>/\&gt;/g;s/&gt;&gt;(([0-9]*(-[0-9]*)?|l[0-9]*)(,([0-9]*(-[0-9]*)?|l[0-9]*))*)/<a href="'$(echo $read | sed 's/\//\\\//g')'\/'$thread'\/\1">\&gt;\&gt;\1<\/a>/g;s/^/<br>/' threads/$thread/posts/$post | tail -c+5)
   time=$(TZ=Z stat -f %Sm -t '%a %b %e %T %Y' threads/$thread/posts/$post)
   echo '<div class="post" id="'$thread'_'$post'">'
   echo '<div class="post_head">'$post $time'</div>'
   echo '<div class="comment">'$comment'</div></div>'
  done
  if [ $(ls threads/$thread/posts | wc -l) -lt 1000 ]
  then
   echo '<div class="replyform"><form method="post" action="post.pl">'
   echo '<input type="hidden" name="thread" value="'$thread'">'
   echo '<input type="checkbox" id="sage_'$thread'" name="sage" checked="checked">'
   echo '<label for="sage_'$thread'">don'\''t bump thread</label>'
   echo '<input type="submit" value="reply"><br>'
   echo '<textarea name="comment"></textarea></form></div>'
  fi
  echo '</div>'
 done
 echo '<div id="threadform"><form method="post" action="post.pl">'
 echo 'title: <input type="text" name="title">'
 echo '<input type="submit" value="create new thread"><br>'
 echo '<textarea name="comment"></textarea></form></div>'
 echo '</body></html>'
) > index.html
