#!/usr/bin/perl -I. -w
use strict;
use warnings;


open(WE,$ARGV[1])||die("Cannot open mapping");
my @tab=<WE>;
close(WE);
my $mapping={};
foreach(@tab) {
	chomp;
	my @tab1=split(/\t/,$_);
	$mapping->{$tab1[0]}=$tab1[1];
}
open(WE,$ARGV[0])||die("cannot open gpr file");
@tab=<WE>;
close(WE);
my $patten=$ARGV[2];
foreach(@tab) {
	while($_=~/($patten)/) {
		my $newpat=$1;
		my $subs=defined($mapping->{$newpat})?$mapping->{$newpat}:"NONE";
		$_=~s/$newpat/$subs/g;
	}
	print($_);
}
