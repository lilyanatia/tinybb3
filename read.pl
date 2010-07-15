#!/usr/bin/perl

use strict;
use feature 'switch';
use encoding 'utf8';
use open ':utf8';
use Fcntl qw(:flock);
use CGI;
use CGI::Carp qw(fatalsToBrowser);

die 'invalid request!' unless $ENV{PATH_INFO} =~ /^\/(\d+)(?:\/(.*))?$/;
my ($thread, $selection) = ($1,$2);
die 'thread does not exist!' unless -d "threads/$thread";
open my $titlefile, '<', "threads/$thread/title";
flock $titlefile, LOCK_SH;
my $title = <$titlefile>;
flock $titlefile, LOCK_UN;
close $titlefile;
$title =~ s/&/&amp;/g;
$title =~ s/</&lt;/g;
$title =~ s/>/&gt;/g;
print "Content-type: text/html; charset=utf-8\n\n<!DOCTYPE html>\n<html><head>",
      "<title>$title</title><link rel=\"stylesheet\" type=\"text/css\" href=\"",
      full_path('style.css'), '"><link rel="alternate" type="application/atom+',
      'xml" href=', full_path("atom/$thread"), '</head><body class="thread"><d',
      "iv class=\"thread_head\"><a href=\"read/$thread\">$title</a></div>";
$selection = '' unless $selection =~ /^(?:\d*(?:-\d*)?|l\d+)(?:,(?:\d*(?:-\d*)?|l\d+))*$/;
my @ranges = split /,/, $selection;
if(@ranges)
{ for(@ranges)
  { given($_)
    { when (/^(\d+)$/) { post_html($thread, $1); }
      when (/^-(\d+)$/) { range_html($thread, 1, $1); }
      when (/^(\d+)-$/) { range_html($thread, $1, 1000); }
      when (/^(\d+)-(\d+)$/) { range_html($thread, $1, $2); }
      when (/^l(\d+)$/) { last_html($thread, $1); }
      default { range_html($thread, 1, 1000); }}}}
else { range_html($thread, 1, 1000); }
print '<div class="replyform"><form method="post" action="',
      full_path('post.pl'), '"><input type="hidden" name="thread" value="',
      "$thread\"><input type=\"checkbox\" id=\"sage_$thread\" name=\"sage\" ch",
      "ecked=\"checked\"> <label for=\"sage_$thread\">don't bump thread</label",
      '> <input type="submit" value="reply"><br><textarea name="comment"></tex',
      'tarea></form></div>' if glob("threads/$thread/posts/*") < 1000;
print "</body></html>\n";

sub full_path($)
{ my ($rel) = @_;
  my $full = $ENV{SCRIPT_NAME};
  $full =~ s/\/[^\/]*$/\/$rel/;
  return $full; }

sub post_html($$)
{ my ($thread, $post) = @_;
  if(-f "threads/$thread/posts/$post")
  { my $time = (stat "threads/$thread/posts/$post")[9];
    open my $postfile, '<', "threads/$thread/posts/$post";
    flock $postfile, LOCK_SH;
    my $comment = join '', <$postfile>;
    flock $postfile, LOCK_UN;
    close $postfile;
    my $read = full_path('read');
    $comment =~ s/&/&amp;/g;
    $comment =~ s/</&lt;/g;
    $comment =~ s/>/&gt;/g;
    $comment =~ s/&gt;&gt;((?:\d*(?:-\d*)?|l\d+)(?:,(?:\d*(?:-\d*)?|l\d+))*)/<a href="$read\/$thread\/$1">&gt;&gt;$1<\/a>/g;
    $comment =~ s/\n/<br>/g;
    print "<div class=\"post\" id=\"${thread}_${post}\"><div class=\"post_head",
          "\">$post ", scalar gmtime $time, '</div><div class="comment">',
          "$comment</div></div>"; }}

sub range_html($$$)
{ my ($thread, $start, $end) = @_;
  $start = 1000 if $start > 1000;
  $end = 1000 if $end > 1000;
  my @posts = $start > $end ? reverse $end..$start : $start..$end;
  post_html($thread, $_) for @posts; }

sub last_html($$)
{ my ($thread, $count) = @_;
  my $thread_length = length glob "threads/$thread/posts/*";
  my $start = 1 + $thread_length - $count;
  $start = 1 if $start < 1;
  range_html($thread, $start, 1000); }
