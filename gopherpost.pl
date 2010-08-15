#!/usr/bin/perl

use strict;
use Encode qw(decode);
use open ':utf8';
use Fcntl qw(:flock);

use constant BUILD_INDEX => './build_index.sh';
use constant HTML_INDEX => 'index.html';
use constant NAME_MAX => 64;
use constant TITLE_MAX => 256;
use constant COMMENT_MAX => 8192;

my $script_name='';
open my $htaccess, '<', '.htaccess';
flock $htaccess, LOCK_SH;
while(<$htaccess>)
{ $script_name = "$1/post.pl" if $_ =~ /^RewriteBase\w+(.*)$/; }
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
  if(filter_check('spam.txt', $comment))
  { print "3spam filter triggered\n";
    exit; }
  $sage = 0 if $2 == 'bump';
  $sage = 1 if filter_check('sage.txt', $comment);
  add_post($thread, $sage, $comment); }
$ENV{SCRIPT_NAME} = $script_name;
system BUILD_INDEX;
my @posts = glob "threads/$thread/posts/*";
my $len = scalar @posts;
$title =~ s/	/    /g;
my $threadpath = $ENV{SELECTOR};
$threadpath =~ s/\/gopherpost\.pl$/\/$thread/;
$threadpath =~ s/\/(?:bump|reply)$//;
print "1$title ($len)	$threadpath	$ENV{SERVER_NAME}	$ENV{SERVER_PORT}\n";

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

sub full_path($)
{ my ($rel) = @_;
  my $full = $script_name;
  $full =~ s!/[^/]*$!/$rel!;
  return $full; }

sub clean_string($)
{ my ($str) = @_;
  $str = decode('utf8', $str);
  $str =~ s/[\x00-\x08\x0b\x0c\x0e-\x1f\x80-\x84]//g;
  $str =~ s/[\x{d800}-\x{dfff}]//g;
  $str =~ s/[\x{202a}-\x{202e}]//g;
  $str =~ s/[\x{fdd0}-\x{fdef}\x{fffe}\x{ffff}\x{1fffe}\x{1ffff}\x{2fffe}\x{2ffff}\x{3fffe}\x{3ffff}\x{4fffe}\x{4ffff}\x{5fffe}\x{5ffff}\x{6fffe}\x{6ffff}\x{7fffe}\x{7ffff}\x{8fffe}\x{8ffff}\x{9fffe}\x{9ffff}\x{afffe}\x{affff}\x{bfffe}\x{bffff}\x{cfffe}\x{cffff}\x{dfffe}\x{dffff}\x{efffe}\x{effff}\x{ffffe}\x{fffff}]//g;
  $str = join('', map{$_ < 0x10fffe ? $_ : ''} split(//, $str));
  return $str; }

sub make_thread($)
{ my ($title) = @_;
  my $thread = time();
  $title = clean_string($title);
  $title =~ s/\r\n/\n/g;
  $title =~ s/[\r\n]/ /g;
  if(!$title)
  { print "3no title entered!\n";
    exit; }
  mkdir "threads/$thread";
  mkdir "threads/$thread/posts";
  open my $titlefile, '>', "threads/$thread/title";
  flock $titlefile, LOCK_EX;
  print $titlefile $title;
  flock $titlefile, LOCK_UN;
  close $titlefile;
  return $thread; }

sub add_post($$$)
{ my ($thread, $sage, $comment) = @_;
  if(!$comment)
  { print "3no comment entered!\n";
    exit; }
  $comment = clean_string($comment);
  $comment =~ s/\r\n/\n/g;
  my @posts = glob("threads/$thread/posts/*");
  my $num = 1 + scalar @posts;
  if($num > 1000)
  { print "3this thread has been closed.\n";
    exit; }
  utime undef, undef, "threads/$thread/title" unless $sage or -f "threads/$thread/permasage";
  open my $postfile, ">", "threads/$thread/posts/$num";
  flock $postfile, LOCK_EX;
  print $postfile "$comment\n";
  flock $postfile, LOCK_UN;
  close $postfile; }
