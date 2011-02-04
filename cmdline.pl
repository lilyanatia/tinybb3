#!/usr/bin/env perl

use strict;
use open ':utf8';
use Fcntl qw(:flock);
use POSIX qw(strftime);

BEGIN { require 'post-common.pl'; }

our $cmdline;
open my $htaccess, '<', '.htaccess';
flock $htaccess, LOCK_SH;
while(<$htaccess>)
{ our $script_name = "$1post.pl" if $_ =~ /^RewriteBase\s+(.*)$/; }
flock $htaccess, LOCK_UN;
close $htaccess;

use constant MAIN_MENU => { 'r' => { desc => 'read threads',
                                     func => 'show_threads()' },
                            'n' => { desc => 'new thread',
                                     func => 'new_thread()' },
                            'q' => { desc => 'quit',
                                     func => '0' }};

$cmdline = 1;
1 while do_menu(MAIN_MENU);

sub prompt($)
{ print shift;
  my $line = <STDIN>;
  chomp $line;
  print "\n";
  $line; }

sub do_menu($)
{ my $menu = shift;
  print "[$_] $menu->{$_}->{desc}\n" for sort { $a <=> $b } keys %$menu;
  my $sel = prompt('? ');
  $menu->{$sel} ? eval $menu->{$sel}->{func} : 1; }

sub show_threads()
{ my $i = 0;
  my @threads = sort { (stat "$b/title")[9] <=> (stat "$a/title")[9] }
                     glob 'threads/*';
  my %threadmenu = ();
  for (@threads)
  { ++$i;
    open my $titlefile, '<', "$_/title";
    flock $titlefile, LOCK_SH;
    my $title = <$titlefile>;
    flock $titlefile, LOCK_UN;
    close $titlefile;
    my @posts = glob "$_/posts/*";
    my $length = scalar @posts;
    $threadmenu{$i} = { desc => "$title ($length)",
                        func => 'show_thread(' . substr($_, 8) . ')' }; }
  do_menu(\%threadmenu);
  1; }

sub show_thread($)
{ my $thread = shift;
  open my $titlefile, '<', "threads/$thread/title";
  flock $titlefile, LOCK_SH;
  print <$titlefile>, "\n\n";
  flock $titlefile, LOCK_UN;
  close $titlefile;
  for (sort { (stat $a)[9] <=> (stat $b)[9] } glob "threads/$thread/posts/*")
  { m!threads/[0-9]+/posts/([0-9]+)!;
    return 1 unless show_post($thread, $1); }
  print "end of thread.\n\n";
  do_menu({ 'r' => { desc => 'reply', func => "reply($thread)" }}); }

sub show_post($$)
{ my ($thread, $post) = @_;
  print "$post: ", strftime('%FT%TZ',
                            gmtime((stat "threads/$thread/posts/$post")[9])),
        "\n";
  open my $postfile, '<', "threads/$thread/posts/$post";
  flock $postfile, LOCK_SH;
  print join('', <$postfile>), "\n";
  flock $postfile, LOCK_UN;
  close $postfile;
  do_menu({ 'r' => { desc => 'reply', func => "reply($thread)" }}); }

sub read_comment()
{ my $comment = '';
  print 'enter comment. "." (without the quotation marks) on a line by itself ',
        "ends input.\n";
  while(<STDIN>)
  { last if /^.$/;
    $comment .= $_; }
  return $comment; }

sub reply($)
{ my $thread = shift;
  my $sage = 0;
  my $comment = read_comment();
  chomp $comment;
  $sage = prompt('bump thread (y/N)? ') =~ /^y$/i if $comment;
  add_post($thread, $sage, $comment, '');
  0; }

sub new_thread()
{ my $title = prompt('title? ');
  if($title)
  { my $comment = read_comment();
    chomp $comment;
    add_post(make_thread($title), 0, $comment, ''); }
  print "\n";
  1; }
