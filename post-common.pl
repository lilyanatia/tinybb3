#!/usr/bin/env perl

use strict;
use Encode qw(encode decode);
use open ':utf8';
use Fcntl qw(:flock);
use POSIX qw(strftime);
use Cwd qw(abs_path);
use JSON;

BEGIN
{ require 'config.pl';
  require 'html-common.pl';
  require 'json-common.pl'; }

our $gopher;

sub filter_check($$)
{ my ($file, $comment) = @_;
  my $match = 0;
  open my $filterfile, '<', $file;
  flock $filterfile, LOCK_SH;
  while(<$filterfile>)
  { chomp;
    last if $_ and ($match = $comment =~ /$_/); }
  flock $filterfile, LOCK_UN;
  close $filterfile;
  return $match; }

sub clean_string($)
{ my ($str) = @_;
  $str = decode('utf8', $str);
  $str =~ s/[\x00-\x08\x0b\x0c\x0e-\x1f\x80-\x84]//g;
  $str =~ s/[\x{d800}-\x{dfff}]//g;
  $str =~ s/[\x{202a}-\x{202e}]//g;
  $str =~ s/[\x{fdd0}-\x{fdef}\x{fffe}\x{ffff}\x{1fffe}\x{1ffff}\x{2fffe}\x{2ffff}\x{3fffe}\x{3ffff}\x{4fffe}\x{4ffff}\x{5fffe}\x{5ffff}\x{6fffe}\x{6ffff}\x{7fffe}\x{7ffff}\x{8fffe}\x{8ffff}\x{9fffe}\x{9ffff}\x{afffe}\x{affff}\x{bfffe}\x{bffff}\x{cfffe}\x{cffff}\x{dfffe}\x{dffff}\x{efffe}\x{effff}\x{ffffe}\x{fffff}]//g;
  return join('', map{$_ < 0x10fffe ? $_ : ''} split(//, $str)); }

sub do_trip($)
{ my ($pass) = @_;
  $pass = encode 'sjis', $pass, 0x0200;
  $pass = clean_string($pass);
  my $salt = substr $pass.'H..', 1, 2;
  $salt =~ s/[^\.-z]/./g;
  $salt =~ tr/:;<=>?@[\\]^_`/ABCDEFGabcdef/;
  return substr crypt($pass, $salt), -10; }

sub make_thread($)
{ my ($title) = @_;
  my $thread = time();
  $title = clean_string($title);
  $title =~ s/\r\n/\n/g;
  $title =~ s/[\r\n]/ /g;
  error('no title entered!') unless $title;
  mkdir "threads/$thread";
  mkdir "threads/$thread/posts";
  open my $titlefile, '>', "threads/$thread/title";
  flock $titlefile, LOCK_EX;
  print $titlefile $title;
  flock $titlefile, LOCK_UN;
  close $titlefile;
  build_index($thread) if $gopher;
  return $thread; }

sub add_post($$$$)
{ my ($thread, $sage, $comment, $pass) = @_;
  error('no comment entered!') unless $comment;
  error('thread does not exist!') unless -d "threads/$thread";
  $comment = clean_string($comment);
  $comment =~ s/\r\n/\n/g;
  my @posts = glob("threads/$thread/posts/*");
  my $num = 1 + scalar @posts;
  error('this thread has been closed.') if $num > 1000;
  utime undef, undef, "threads/$thread/title" unless $sage or -f "threads/$thread/permasage";
  open my $postfile, ">", "threads/$thread/posts/$num";
  flock $postfile, LOCK_EX;
  print $postfile "$comment\n";
  flock $postfile, LOCK_UN;
  close $postfile;
  if($pass)
  { open my $tripfile, '>', "threads/$thread/posts/.$num.trip";
    flock $tripfile, LOCK_EX;
    print $tripfile do_trip($pass);
    flock $tripfile, LOCK_UN;
    close $tripfile; }
  build_index($thread); }

sub build_index($)
{ my ($thread) = @_;
  open my $titlefile, '<', "threads/$thread/title";
  flock $titlefile, LOCK_SH;
  my $title = <$titlefile>;
  flock $titlefile, LOCK_UN;
  close $titlefile;
  my $updated = (stat "threads/$thread/posts")[9];

  # build json/$thread
  my $json = new JSON;
  my $json_data = {};
  range_json($json_data, $thread, 1, 1000);
  open my $jsonfile, '>', "json/$thread";
  flock $jsonfile, LOCK_EX;
  print $jsonfile $json->encode($json_data);
  flock $jsonfile, LOCK_UN;
  close $jsonfile;

  # build read/$thread
  open my $htmlfile, '>', "read/$thread";
  flock $htmlfile, LOCK_EX;
  print $htmlfile "<!DOCTYPE html>\n<html><head><title>$title</title><link rel",
                  "=\"stylesheet\" type=\"text/css\" href=\"",
                  full_path('style.css'), '"><link rel="alternate" type="appli',
                  'cation/atom+xml" href=', full_path("atom/$thread"), '<scrip',
                  't type="text/javascript" src="', full_path('trip.js'), '"><',
                  '/script></head><body class="thread" onload="init()"><div cl',
                  "ass=\"thread_head\"><a href=\"read/$thread\">$title</a></di",
                  'v>';
  range_html($thread, 1, 1000, $htmlfile);
  my @posts = glob "threads/$thread/posts/*";
  print $htmlfile '<div class="replyform"><form method="post" action="',
                   full_path('post.pl'), '"><input type="hidden" name="thread"',
                   " value=\"$thread\"><input type=\"checkbox\" id=\"sage_",
                   "$thread\" name=\"sage\" checked=\"checked\"> <label for=\"",
                   "sage_$thread\">don't bump thread</label> <input type=\"sub",
                   'mit" value="reply"><br><textarea name="comment"></textarea',
                   '></form></div>' if scalar @posts < 1000;
  flock $htmlfile, LOCK_UN;
  close $htmlfile;

  # build atom/$thread and threads/$thread/gophermap
  my $gophertitle = $title;
  $gophertitle =~ s/	/    /g;
  $gophertitle =~ s/(.{67})/$1\n/g;
  open my $threadgophermapfile, '>', "threads/$thread/gophermap";
  flock $threadgophermapfile, LOCK_EX;
  print $threadgophermapfile "$gophertitle\n";
  open my $atomfile, '>', "atom/$thread";
  flock $atomfile, LOCK_EX;
  print $atomfile "<?xml version=\"1.0\" encoding=\"utf-8\">\n<feed xmlns=\"ht",
                  "tp://www.w3.org/2005/Atom\"><title>$title</title><author><n",
                  'ame>anonymous</name></author><link href="',
                  full_path("atom/$thread"), '" rel="self"/><link href="',
                  full_path("read/$thread"), '"/><updated>',
                  strftime('%FT%TZ', gmtime $updated), '</updated><id>',
                  full_path("read/$thread"), '</id>';
  my $read = full_path('read/');
  my @posts = glob "threads/$thread/posts/*";
  for my $post (1..scalar @posts)
  { open my $postfile, '<', "threads/$thread/posts/$post";
    flock $postfile, LOCK_SH;
    my $comment = join '', <$postfile>;
    flock $postfile, LOCK_UN;
    close $postfile;
    my $gophercomment = $comment;
    $gophercomment =~ s/	/    /g;
    $gophercomment =~ s/(.{67})/$1\n/g;
    chomp $gophercomment;
    print $threadgophermapfile "\n0$post	posts/$post\n$gophercomment\n";
    my $posttime = (stat "threads/$thread/posts/$post")[9];
    $comment =~ s/&/&amp;/g;
    $comment =~ s/</&lt;/g;
    $comment =~ s/>/&gt;/g;
    $comment =~ s/&gt;&gt;((?:[0-9]*(?:-[0-9]*)?|l[0-9]*)(?:,([0-9]*(?:-[0-9]*)?|l[0-9]*))*)/<a href="$read$thread\/$1">&gt;&gt;$1<\/a>/g;
    $comment =~ s/\n/<br\/>/g;
    $comment =~ s/^(?:<br\/>)+//s;
    $comment =~ s/(?:<br\/>)+$//s;
    print $atomfile "<entry><title>$title : $post</title><link href=\"$read",
                    "$thread/$post\"/><id>$read$thread/$post</id><updated>",
                    strftime('%FT%TZ', gmtime $posttime), '</updated><content ',
                    'type="xhtml"><div xmlns="http://www.w3.org/1999/xhtml">',
                    "$comment</div></content></entry>"; }
  print $threadgophermapfile "\n7reply	reply\n7bump	bump\n";
  flock $threadgophermapfile, LOCK_UN;
  close $threadgophermapfile;
  print $atomfile "</feed>\n";
  flock $atomfile, LOCK_UN;
  close $atomfile;
  symlink abs_path('gopherpost.pl'), "threads/$thread/reply" unless -e "threads/$thread/reply";
  symlink abs_path('gopherpost.pl'), "threads/$thread/bump" unless -e "threads/$thread/bump";

  # build subject.txt, json/index.json, gophermap, subback.html
  my $json = new JSON;
  my @jsonindex_data = ();
  open my $subjecttxtfile, '>', 'subject.txt';
  open my $jsonindexfile, '>', 'json/index.json';
  open my $gophermapfile, '>', 'gophermap';
  open my $subbackfile, '>', 'subback.html';
  flock $subjecttxtfile, LOCK_EX;
  flock $jsonindexfile, LOCK_EX;
  flock $gophermapfile, LOCK_EX;
  flock $subbackfile, LOCK_EX;
  print $subbackfile "<!DOCTYPE html>\n<html><head><title>all threads</title><",
                     'link rel="stylesheet" type="text/css" href="',
                     full_path('style.css'), '"></head><body class="subback"><',
                     'table><tr><th>title</th><th>posts</th><th>last post</th>',
                     '</tr>';
  print $gophermapfile "anonymous bbs\n\n";
  for $thread (sort { (stat "$b/title")[9] <=> (stat "$a/title")[9] } (glob 'threads/*'))
  { $thread =~ s/^.*\/([^\/]+)$/$1/;
    my @posts = glob "threads/$thread/posts/*";
    my $posts = scalar @posts;
    open my $titlefile, '<', "threads/$thread/title";
    flock $titlefile, LOCK_SH;
    $title = <$titlefile>;
    flock $titlefile, LOCK_UN;
    close $titlefile;
    $updated = (stat "threads/$thread/posts")[9];
    print $subjecttxtfile "$title<>Anonymous<><>$thread<>$posts<>Anonymous<>",
                          "$updated\n";
    $gophertitle = $title;
    $gophertitle =~ s/	/    /g;
    $gophertitle =~ s/(.{67})/$1\n/g;
    chomp $gophertitle;
    print $gophermapfile "1$gophertitle	threads/$thread\n";
    push @jsonindex_data, { 'id' => $thread, 'title' => $title, 'created' =>
                            $thread, 'updated' => $updated, 'length' => $posts,
                            'bumped' => (stat "threads/$thread/title")[9] };
    $title =~ s/&/&amp;/g;
    $title =~ s/</&lt;/g;
    $title =~ s/>/&gt;/g;
    print $subbackfile '<tr><td><a href="', full_path("read/$thread"), '">',
                       "$title</a></td><td>$posts</td><td>$updated</td></tr>"; }
  flock $subjecttxtfile, LOCK_UN;
  flock $gophermapfile, LOCK_UN;
  close $subjecttxtfile;
  close $gophermapfile;
  print $subbackfile "</table></body></html>\n";
  flock $subbackfile, LOCK_UN;
  close $subbackfile;
  print $jsonindexfile $json->encode(\@jsonindex_data), "\n";
  flock $jsonindexfile, LOCK_UN;
  close $jsonindexfile;

  # build index.html
  my @all = sort { (stat $b)[9] <=> (stat $a)[9] } glob 'threads/*/title';
  my $last_thread = (scalar @all) > 9 ? 9 : (scalar @all) - 1;
  my @threads = map { substr $_, 8, -6 } @all[0..$last_thread];
  my @titles = map { open $titlefile, '<', "threads/$_/title";
                     flock $titlefile, LOCK_SH;
                     $title = <$titlefile>;
                     flock $titlefile, LOCK_UN;
                     close $titlefile;
                     $title } @threads;
  my @lengths = map { my @p = glob "threads/$_/posts/*"; scalar @p } @threads;
  open my $indexfile, '>', 'index.html';
  flock $indexfile, LOCK_EX;
  print $indexfile "<!DOCTYPE html>\n<html><head><title>anonymous bbs</title><",
                  'link rel="stylesheet" type="text/css" href="',
                  full_path('style.css'), '"><script type="text/javascript" sr',
                  'c="', full_path('trip.js'), '"></script></head><body class=',
                  '"mainpage" onload="init()"><div class="thread_list"><ol>';
  for (0..$last_thread)
  { print $indexfile "<li><a href=\"#$threads[$_]\">$titles[$_] ($lengths[$_])",
                     '</a></li>'; }
  print $indexfile '</ol><div class="threadlinks"><a href="#threadform">new th',
                   'read</a> | <a href="subback.html">all threads</a></div></d',
                   'iv>';
  for (0..$last_thread)
  { print $indexfile "<div class=\"thread\" id=\"$threads[$_]\"><div class=\"t",
                     'hread_head"><a href="', full_path("read/$threads[$_]"), '">',
                     "$titles[$_] ($lengths[$_])</a></div>";
    post_html($threads[$_], 1, $indexfile);
    range_html($threads[$_], $lengths[$_] > 10 ? $lengths[$_] - 8 : 2 ,
               $lengths[$_], $indexfile) if $lengths[$_] > 1;
    print $indexfile '<div class="replyform"><form method="post" action="',
                     full_path('post.pl'), '"><input type="hidden" name="threa',
                     "d\" value=\"$threads[$_]\"><input type=\"checkbox\" id=",
                     "\"sage_$threads[$_]\" name=\"sage\" checked=\"checked\">",
                     " <label for=\"sage_$threads[$_]\">don't bump thread</lab",
                     'el> <input type="submit" value="reply"><br><textarea nam',
                     'e="comment"></textarea></form></div>' if $lengths[$_] <
                     1000;
    print $indexfile '</div>'; }
  print $indexfile '<div id="threadform"><form method="post" action="',
                   full_path('post.pl'), '">title: <input type="text" name="ti',
                   'tle"> <input type="submit" value="create new thread"><br><',
                   'textarea name="comment"></textarea></form></div></body></h',
                   "tml>\n";
  flock $indexfile, LOCK_UN;
  close $indexfile; }

1;
