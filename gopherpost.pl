#!/usr/bin/env perl

use strict;
use Encode qw(decode);
use open ':utf8';
use Fcntl qw(:flock);

BEGIN { require 'post-common.pl' }

our $gopher;
open my $htaccess, '<', '.htaccess';
flock $htaccess, LOCK_SH;
while(<$htaccess>)
{ our $script_name = "$1/post.pl" if $_ =~ /^RewriteBase\w+(.*)$/; }
flock $htaccess, LOCK_UN;
close $htaccess;
my $thread = 0;
my $title = '';
my $path = `pwd`;
chomp $path;
$path .= $ENV{SELECTOR};
$path =~ s/\/gopherpost\.pl$//;
$path =~ s/\/threads\/\d+\/(?:bump|reply)$//;
chdir $path;
$gopher = 1;

if($ENV{SELECTOR} =~ /\/gopherpost\.pl$/)
{ $title = $ENV{SEARCHREQUEST};
  $thread  = make_thread($title); }
else
{ my $comment = $ENV{SEARCHREQUEST};
  my $sage = 1;
  $ENV{SELECTOR} =~ /\/(\d+)\/(bump|reply)$/;
  $thread = $1;
  open my $titlefile, '<', "threads/$thread/title";
  flock $titlefile, LOCK_SH;
  $title = <$titlefile>;
  flock $titlefile, LOCK_UN;
  close $titlefile;
  chomp $title;
  error('spam filter triggered') if filter_check('spam.txt', $comment);
  $sage = 0 if $2 == 'bump';
  $sage = 1 if filter_check('sage.txt', $comment);
  add_post($thread, $sage, $comment, ''); }
$ENV{SCRIPT_NAME} = $script_name;
my @posts = glob "threads/$thread/posts/*";
my $len = scalar @posts;
$title =~ s/	/    /g;
my $threadpath = $ENV{SELECTOR};
$threadpath =~ s/\/gopherpost\.pl$/\/$thread/;
$threadpath =~ s/\/(?:bump|reply)$//;
print "1$title ($len)	$threadpath	$ENV{SERVER_NAME}	$ENV{SERVER_PORT}\n";
