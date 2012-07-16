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
	my $main=shift(@tab1);
	foreach my $num (@tab1) {
		$equivhash->{$num}=$main;
	}
}
open(WE,$ARGV[1])||die("Cannot open codes");
@tab=<WE>;
close(WE);
foreach(@tab) {
	chomp;
	@tab1=split(/\t/,$_);
	print($tab1[0]."\t".(defined($equivhash->{$tab1[1]})?$equivhash->{$tab1[1]}:$tab1[1])."\n");
}
