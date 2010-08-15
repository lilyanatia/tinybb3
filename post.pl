#!/usr/bin/perl

use strict;
use Encode qw(decode);
use open ':utf8';
use Fcntl qw(:flock);
use CGI;
use CGI::Carp qw(fatalsToBrowser);

use constant BUILD_INDEX => './build_index.sh';
use constant HTML_INDEX => 'index.html';
use constant NAME_MAX => 64;
use constant TITLE_MAX => 256;
use constant COMMENT_MAX => 8192;

my $query = new CGI;
my $script_name = $query->script_name();
if($query->request_method() == 'POST')
{ my $thread = $query->param('thread');
  my $title = $query->param('title');
  my $sage = $query->param('sage');
  my $comment = $query->param('comment');
  die 'spam filter triggered' if filter_check('spam.txt', $comment);
  $sage = 1 if filter_check('sage.txt', $comment);
  $thread = make_thread($title) unless $thread;
  add_post($thread, $sage, $comment); }
system BUILD_INDEX;
print $query->redirect(-uri => full_path(HTML_INDEX), -status => 303);

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
  die 'no title entered!' unless $title;
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
  die 'no comment entered!' unless $comment;
  die 'thread does not exist!' unless -d "threads/$thread";
  $comment = clean_string($comment);
  $comment =~ s/\r\n/\n/g;
  my @posts = glob("threads/$thread/posts/*");
  my $num = 1 + scalar @posts;
  die 'this thread has been closed.' if $num > 1000;
  utime undef, undef, "threads/$thread/title" unless $sage or -f "threads/$thread/permasage";
  open my $postfile, ">", "threads/$thread/posts/$num";
  flock $postfile, LOCK_EX;
  print $postfile "$comment\n";
  flock $postfile, LOCK_UN;
  close $postfile; }
