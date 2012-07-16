#!/usr/bin/perl -w
#
use strict;
use warnings;

open(WE,$ARGV[0])||die("Cannot open equivalent list");
my @tab=<WE>;
close(WE);
my @tab1;
my $equivhash={};
foreach(@tab) {
	chomp;
	@tab1=split(/\t/,$_);
	$equivhash->{$tab1[0]}=$tab1[1];
}
open(WE,$ARGV[1])||die("Cannot open codes");
@tab=<WE>;
close(WE);
foreach(@tab) {
	chomp;
	@tab1=split(/\t/,$_);
	print($tab1[0]."\t".
	(defined($equivhash->{$tab1[1]})?$equivhash->{$tab1[1]}:$tab1[1]));
	@tab1==3&&
	print("\t".
	(defined($equivhash->{$tab1[2]})?$equivhash->{$tab1[2]}:$tab1[2]));
	print("\n");
	
}
