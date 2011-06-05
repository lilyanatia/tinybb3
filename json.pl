#!/usr/bin/env perl

use strict;
use feature 'switch';
use open ':utf8';
use Fcntl qw(:flock);
use CGI;
use CGI::Carp qw(fatalsToBrowser);

BEGIN { require 'json-common.pl'; }

my $query = new CGI;
my $jsonp = $query->param('jsonp');

print "Content-type: application/json; charset=utf-8\nAccess-Control: allow <*>\nAccess-Control-Allow-Origin: *\n\n";

if($ENV{PATH_INFO} and $ENV{PATH_INFO} !~ /^\/+$/)
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
  my $json_string = $json->encode($json_data);
  $json_string = "$jsonp($json_string)" if $jsonp;
  print "$json_string\n"; }
else
{ my @threads = map { substr $_, 8 } sort { (stat "$b/title")[9] <=> (stat "$a/title")[9] } glob 'threads/{1,2,3,4,5,6,7,8,9,0}*';
  my $json = new JSON;
  my @json_data = map { open my $titlefile, '<', "threads/$_/title";
                        flock $titlefile, LOCK_SH;
                        my $title = <$titlefile>;
                        flock $titlefile, LOCK_UN;
                        close $titlefile;
                        my @posts = glob "threads/$_/posts/*";
                        { 'id' => $_, 'title' => $title,
                          'created' => (stat "threads/$_/posts/1")[9],
                          'length' => scalar @posts,
                          'updated' => (stat "threads/$_/posts")[9],
                          'bumped' => (stat "threads/$_/title")[9] } } @threads;
  my $json_string = $json->encode(\@json_data);
  $json_string = "$jsonp($json_string)" if $jsonp;
  print "$json_string\n"; }
