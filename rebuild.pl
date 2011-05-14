#!/usr/bin/env perl

use strict;
use Encode qw(decode);
use open ':utf8';
use Fcntl qw(:flock);
use CGI;
use CGI::Carp qw(fatalsToBrowser);

BEGIN { require 'post-common.pl'; }

my $query = new CGI;
our $script_name = $query->script_name();
print "Content-Type: text/plain\n\nrebuilding caches...";
build_index(substr $_, 8) for glob 'threads/*';
print "done.\n";
