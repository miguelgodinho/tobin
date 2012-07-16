#!/usr/bin/perl
#
use strict;
use warnings;

open(WE, "29milp1.txt")||die("Cannot open reaction list");
my @tab=<WE>;
close(WE);
my $str="9095\n";

foreach(@tab) {
	my $sold=$str;
	$str.=$_;
	open(WY, ">29mtest.txt");
	print(WY $str);
	close(WY);
	` ./fba2milp.pl 29 29rev.txt 29mtest.txt R9112 2 > 29lpmt.txt`;
	my @result=`/home/jap04/Software/lp_solve/lp_solve -S4 < 29lpmt.txt`;
	if($result[0]=~/infeasible/) {
		print($_);
		$str=$sold;
	}

}
