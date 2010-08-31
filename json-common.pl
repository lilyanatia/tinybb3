#!/usr/bin/env perl

use strict;
use open ':utf8';
use Fcntl qw(:flock);
use JSON;

sub post_json($$$)
{ my ($json_data, $thread, $post) = @_;
  if(-f "threads/$thread/posts/$post")
  { my $time = (stat "threads/$thread/posts/$post")[9];
    open my $postfile, '<', "threads/$thread/posts/$post";
    flock $postfile, LOCK_SH;
    my $comment = join '', <$postfile>;
    flock $postfile, LOCK_UN;
    close $postfile;
    $comment =~ s/\\/\\\\/g;
    $comment =~ s/"/\\"/g;
    chomp $comment;
    $$json_data{$post} = {"name" => "Anonymous", "now" => $time, "com" => $comment}; }}

sub range_json($$$$)
{ my ($json_data, $thread, $start, $end) = @_;
  $start = 1000 if $start > 1000;
  $end = 1000 if $end > 1000;
  my @posts = $start > $end ? reverse $end..$start : $start..$end;
  post_json($json_data, $thread, $_) for @posts; }

sub last_json($$$)
{ my ($json_data, $thread, $count) = @_;
  my $thread_length = length glob "threads/$thread/posts/*";
  my $start = 1 + $thread_length - $count;
  $start = 1 if $start < 1;
  range_json($json_data, $thread, $start, 1000); }

1;
