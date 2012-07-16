#!/usr/bin/perl -I. -w
use strict;
use warnings;


@ARGV<2&&die("Too few arguments");

open(WE, $ARGV[0])||die("Cannot open reversibles file");
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
my $tfhash={};
open(WE, $ARGV[1])||die("Cannot open reactions file");
@tab=<WE>;
close(WE);
foreach(@tab) {
	chomp;
	$tfhash->{$_}=1;
}
my $rev={};
foreach(keys(%{$revhash})) {
	if(defined($tfhash->{$_})&&defined($tfhash->{$revhash->{$_}})) {
		delete($tfhash->{$revhash->{$_}});
		delete($tfhash->{$_});
		$rev->{$_}=1;
	}
}
print(keys(%{$tfhash})."\n");
print(keys(%{$rev})."\n");
