#!/usr/bin/env perl

use strict;

our $gopher = 0;
our $script_name;

sub full_path($)
{ my ($rel) = @_;
  my $full = $script_name;
  $full =~ s!/[^/]*$!/$rel!;
  return $full; }

sub error($)
{ my ($message) = @_;
  die $message unless $gopher;
  print "3$message\n";
  exit; }

1;
