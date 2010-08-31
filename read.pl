#!/usr/bin/env perl

use feature 'switch';
use encoding 'utf8';
use open ':utf8';
use Fcntl qw(:flock);
use CGI;
use CGI::Carp qw(fatalsToBrowser);

BEGIN { require 'html-common.pl'; }

die 'invalid request!' unless $ENV{PATH_INFO} =~ /^\/(\d+)(?:\/(.*))?$/;
our $script_name = $ENV{SCRIPT_NAME};
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
    { when (/^(\d+)$/) { post_html($thread, $1, STDOUT); }
      when (/^-(\d+)$/) { range_html($thread, 1, $1, STDOUT); }
      when (/^(\d+)-$/) { range_html($thread, $1, 1000, STDOUT); }
      when (/^(\d+)-(\d+)$/) { range_html($thread, $1, $2, STDOUT); }
      when (/^l(\d+)$/) { last_html($thread, $1, STDOUT); }
      default { range_html($thread, 1, 1000, STDOUT); }}}}
else { range_html($thread, 1, 1000, STDOUT); }
print '<div class="replyform"><form method="post" action="',
      full_path('post.pl'), '"><input type="hidden" name="thread" value="',
      "$thread\"><input type=\"checkbox\" id=\"sage_$thread\" name=\"sage\" ch",
      "ecked=\"checked\"> <label for=\"sage_$thread\">don't bump thread</label",
      '> <input type="submit" value="reply"><br><textarea name="comment"></tex',
      'tarea></form></div>' if glob("threads/$thread/posts/*") < 1000;
print "</body></html>\n";
