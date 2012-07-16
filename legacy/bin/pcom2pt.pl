#!/usr/bin/perl -w
use strict;
use warnings;

@ARGV<2&&die("too few arguments");

open(WE,$ARGV[0])||die("Cannot open input file");
my @tab=<WE>;
close(WE);

open(WY, ">".$ARGV[1])||die("Cannot open output file");
shift(@tab);
foreach(@tab) {
	chomp;
	my @tab1=split(/","/,$_);
	print(WY "ID\t$tab1[1]\n");
	print(WY "STARTBASE\t$tab1[8]\n");
	print(WY "ENDBASE\t$tab1[9]\n");
	print(WY "DBLINK\tPID:g$tab1[12]\n");
	print(WY "PRODUCT-TYPE\tP\n");
	length($tab1[5])&&print(WY"NAME\t$tab1[5]\n");
	length($tab1[6])&&print(WY"FUNCTION\t$tab1[6]\n");
	if(length($tab1[24])) {
		$tab1[24]=~s/ ;$//;
		my @tab2=split(/ ;/,$tab1[24]);
		foreach my$ec (@tab2) {
			print(WY"EC\t$ec\n");
		}
	}
	print(WY"//\n\n");
}
close(WY);
