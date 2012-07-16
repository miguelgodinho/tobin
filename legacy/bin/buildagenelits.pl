#!/usr/bin/perl -I. -w
use strict;
use warnings;
@ARGV||die("Too few arguments");
open(WE,$ARGV[0])||die("Cannot open ec anno!");
my @tab=<WE>;
close (WE);
my $glist={};
foreach(@tab) {
	chomp;
	my @tab1=split(/\t/,$_);
	shift(@tab1);
	foreach my $ge (@tab1) {
		$glist->{$ge}=1;
	}
}
foreach(keys(%{$glist})) {
	print($_."\n");
}
