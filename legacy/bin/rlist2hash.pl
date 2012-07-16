#!/usr/bin/perl -I. -w
use strict;
use warnings;

open(WE, $ARGV[0])||die("Canot open input file");
my@tab=<WE>;
close(WE);
my $tfhash={};
foreach(@tab) {
	chomp;
	$tfhash->{$_}=1;
}
print(keys(%{$tfhash})."\n");
foreach(keys(%{$tfhash})) {
	print($_."\n");
}
