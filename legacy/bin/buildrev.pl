#!/usr/bin/perl -w
use strict;
use warnings;

open(WE, $ARGV[1])||die("Cannot open reversible file.");
my @tab=<WE>;
close(WE);
my $revhash={};
foreach(@tab) {
	chomp;
	my @tab1=split(/\t/,$_);
	(defined($revhash->{$tab1[0]})||defined($revhash->{$tab1[1]}))&&
	die("Problem with reversibles.");
	$revhash->{$tab1[0]}=$tab1[1];
	$revhash->{$tab1[1]}=$tab1[0];
}

open(WE,$ARGV[0])||die("cannot open reactions list");
@tab=<WE>;
close(WE);
my $skip={};
foreach(@tab) {
	chomp;
	defined($skip->{$_})&&next;
	if(defined($revhash->{$_})) {
		print(($_<$revhash->{$_}?$_."/".$revhash->{$_}:$revhash->{$_}."/".$_)."\n");
		$skip->{$revhash->{$_}}=1;
	}
	else {
		print($_."\n");
	}
}
