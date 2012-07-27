#!/usr/bin/perl

use strict;
use encoding 'utf8';
use open ':utf8';
use Fcntl ':flock';
use JSON;
use CGI;
use CGI::Carp qw(fatalsToBrowser);

my $query = new CGI;
my $jsonp = $query->param('jsonp');

print "Content-type: application/json; charset=utf-8\nAccess-Control: allow <*>\nAccess-Control-Allow-Origin: *\n\n";

my @tripfiles = glob('threads/*/posts/.*.trip');

my $json_data = {};
for (@tripfiles)
{ open my $fh, '<', $_;
  flock $fh, LOCK_SH;
  my $trip = <$fh>;
  flock $fh, LOCK_UN;
  close $fh;
  my ($thread,$post) = $_=~/^threads\/([0-9]+)\/posts\/\.([0-9]+)\.trip$/;
  $json_data->{"$thread/$post"} = $trip; }

my $json = new JSON;
my $json_string = $json->encode($json_data);
$json_string = "$jsonp($json_string)" if $jsonp;
print "$json_string\n";
