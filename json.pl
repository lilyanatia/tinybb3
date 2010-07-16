#!/usr/bin/perl

use strict;
use feature 'switch';
use encoding 'utf8';
use open ':utf8';
use Fcntl qw(:flock);
use CGI;
use CGI::Carp qw(fatalsToBrowser);
use JSON;

if($ENV{PATH_INFO})
{ die 'invalid request!' unless $ENV{PATH_INFO} =~ /^\/(\d+)(?:\/(.*))?$/;
  my ($thread, $selection) = ($1,$2);
  open my $titlefile, '<', "threads/$thread/title";
  flock $titlefile, LOCK_SH;
  my $title = <$titlefile>;
  flock $titlefile, LOCK_UN;
  close $titlefile;
  $title =~ s/&/&amp;/g;
  $title =~ s/</&lt;/g;
  $title =~ s/>/&gt;/g;
  print "Content-type: application/json; charset=utf-8\n\n";
  $selection = '' unless $selection =~ /^(?:\d*(?:-\d*)?|l\d+)(?:,(?:\d*(?:-\d*)?|l\d+))*$/;
  my @ranges = split /,/, $selection;
  my $json = new JSON;
  my $json_data = {};
  if(@ranges)
  { for(@ranges)
    { given($_)
      { when (/^(\d+)$/) { post_json($json_data,$thread, $1); }
        when (/^-(\d+)$/) { range_json($json_data, $thread, 1, $1); }
        when (/^(\d+)-$/) { range_json($json_data, $thread, $1, 1000); }
        when (/^(\d+)-(\d+)$/) { range_json($json_data, $thread, $1, $2); }
        when (/^l(\d+)$/) { last_json($json_data, $thread, $1); }
        default { range_json($json_data, $thread, 1, 1000); }}}}
  else { range_json($json_data, $thread, 1, 1000); }
  print $json->encode($json_data), "\n"; }
else
{ my @threads = map { substr $_, 8 } sort { (stat "$b/title")[9] <=> (stat "$a/title")[9] } glob 'threads/{1,2,3,4,5,6,7,8,9,0}*';
  my $json = new JSON;
  my @json_data = map { open my $titlefile, '<', "threads/$_/title";
        flock $titlefile, LOCK_SH;
        my $title = <$titlefile>;
        flock $titlefile, LOCK_UN;
        close $titlefile;
        { 'id' => $_, 'title' => $title, 'created' => (stat "threads/$_/posts/1")[9], 'length' => length(glob "threads/$_/posts/*"), 'updated' => (stat "threads/$_/posts")[9], 'bumped' => (stat "threads/$_/title")[9]} } @threads;
  print $json->encode(\@json_data), "\n"; }

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
