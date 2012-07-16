#!/usr/bin/perl -I. -w
use strict;
use warnings;

open(WE, $ARGV[0])||die("Cannot open input file.");
my @tab=<WE>;
close(WE);
foreach(@tab) {
	chomp;
	my @result=`./fb2milp-mps.pl 62 62rev.txt $_ 3527 1 |~/Software/lp_solve/lp_solve -mps -S1`;
	($result[0]=~/infeasible/)&&print($_."\n");
}
