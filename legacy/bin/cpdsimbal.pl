#!/usr/bin/perl
use strict;
use warnings;

open(WE, $ARGV[0])||die("Cannot open input file");
my @tab=<WE>;
close(WE);

foreach (@tab) {
	chomp;
	my @tab1=split(/\t/,$_);
	my $str=$ARGV[1]."[[ ]";
	$tab1[1]=~/ $str|^$str|$ARGV[1]$/||next;
	my $sto;
	if($tab1[1]=~/^\[([ce])\] : /) {
		if($1 ne $ARGV[2]) {
			next;
		}
		else {
			$sto=$tab1[1]=~/\(([0-9.]+)\) $ARGV[1]/?$1:1;
			$tab1[1]=~/$ARGV[1].*>/&&($sto=-$sto);
		}
	}
	elsif($tab1[1]=~/$ARGV[1]\[$ARGV[2]\]/) {
		$sto=$tab1[1]=~/\(([0-9.]+)\) $ARGV[1]\[$ARGV[2]\]/?$1:1;
		$tab1[1]=~/$ARGV[1]\[$ARGV[2]\].*>/&&($sto=-$sto);
		
	}
	defined($sto)&&$tab1[2]!=0&&print($tab1[0]."\t".($sto*$tab1[2])."\n");
}
	
