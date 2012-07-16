#!/usr/bin/perl
use strict;
use warnings;


open(WE, $ARGV[0])||die("Cannot open scodes");
my @tab=<WE>;
close(WE);
my $thash={};
foreach(@tab) {
	chomp;
	my @tab1=split(/\t/,$_);
	defined($thash->{$tab1[1]})?print("$tab1[0] and ".$thash->{$tab1[1]}." may overlap\n"):
	($thash->{$tab1[1]}=$tab1[0]);
	@tab1==3||next;
	defined($thash->{$tab1[2]})?print("$tab1[0] and ".$thash->{$tab1[2]}." may overlap\n"):
	($thash->{$tab1[2]}=$tab1[0]);
	
}
