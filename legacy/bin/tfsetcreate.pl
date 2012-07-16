#!/usr/bin/perl -I. -w
use strict;
use warnings;
use Tobin::IF;

@ARGV<3&&die("too few arguments");
my $tobin	= new Tobin::IF($ARGV[0]);
open(WE,$ARGV[1])||die("Cannot open reactions file");
my @tab=<WE>;
close(WE);
my $tfset=[];
foreach(@tab) {
	chomp;
	push(@{$tfset},$_);
}
$tobin->transformationsetCreate($ARGV[2],$tfset);
