#!/usr/bin/env perl

use feature 'switch';
use encoding 'utf8';
use open ':utf8';
use Fcntl qw(:flock);
use CGI;
use CGI::Carp qw(fatalsToBrowser);

BEGIN { require 'common.pl'; }

sub post_html($$$)
{ my ($thread, $post, $fh) = @_;
  if(-f "threads/$thread/posts/$post")
  { my $time = (stat "threads/$thread/posts/$post")[9];
    open my $postfile, '<', "threads/$thread/posts/$post";
    flock $postfile, LOCK_SH;
    my $comment = join '', <$postfile>;
    flock $postfile, LOCK_UN;
    close $postfile;
    my $read = full_path('read');
    my $trip = '';
    if (-e "threads/$thread/posts/.$post.trip")
    { open my $tripfile, '<', "threads/$thread/posts/.$post.trip";
      flock $tripfile, LOCK_SH;
      $trip = '<span class="trip">!' . <$tripfile> . '</span>';
      flock $tripfile, LOCK_UN;
      close $tripfile; }
    $comment =~ s/&/&amp;/g;
    $comment =~ s/</&lt;/g;
    $comment =~ s/>/&gt;/g;
    $comment =~ s/[a-z][a-z0-9+.-]*:[^\s`"<>{}()|\\^~`]*(?:\([^\s"<>{}()|\\^~`]+\)|[^\s"<>{}()|\\^~`.,;])/<a href="$&">$&<\/a>/g;
    $comment =~ s/^(&gt;(?!&gt;).*)$/<blockquote>$1<\/blockquote>/gm;
    $comment =~ s/&gt;&gt;((?:\d*(?:-\d*)?|l\d+)(?:,(?:\d*(?:-\d*)?|l\d+))*)/<a href="$read\/$thread\/$1">&gt;&gt;$1<\/a>/g;
    $comment =~ s/\n/<br>/g;
    $comment =~ s/<\/blockquote>((?:<br>)*)<blockquote>/$1/g;
    print $fh "<div class=\"post\" id=\"${thread}_${post}\"><div class=\"post_",
          "head\">$post ", scalar gmtime $time, $trip, '</div><div class="comm',
          "ent\">$comment</div></div>"; }}

sub range_html($$$$)
{ my ($thread, $start, $end, $fh) = @_;
  $start = 1000 if $start > 1000;
  $end = 1000 if $end > 1000;
  my @posts = $start > $end ? reverse $end..$start : $start..$end;
  post_html($thread, $_, $fh) for @posts; }

sub last_html($$$)
{ my ($thread, $count, $fh) = @_;
  my $thread_length = length glob "threads/$thread/posts/*";
  my $start = 1 + $thread_length - $count;
  $start = 1 if $start < 1;
  range_html($thread, $start, 1000, $fh); }

1;
