#!/usr/bin/perl -I. -w
use strict;
use warnings;

open(WE, "g2id.csv");
my @tab=<WE>;
close(WE);
my $idhash={};
foreach(@tab) {
	chomp;
	my @tab1=split(/\t/,$_);
	$idhash->{$tab1[0]}=$tab1[1];
}
open(WE, "Protein Clusters.txt");
@tab=<WE>;
close(WE);
open(WY, ">pc3.txt");
foreach(@tab) {
	print(WY $_);
	if($_=~m/^Alias = (PA[0-9]{4})/) {
		warn $1;
		print(WY "LocusLink ID = ".$idhash->{$1}."\n");
	}
}
