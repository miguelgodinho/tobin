#!/usr/bin/perl -I. -w
use strict;
use warnings;
use Tobin::IF;

my $tobin= new Tobin::IF(1);
open(WE,$ARGV[0])||die("Cannot open input file");
my @tab=<WE>;
close(WE);

foreach(@tab) {
	chomp;
	my $candidates=$tobin->transformationCandidatesGet($_,'t_e',1);
	my $str=$_."\t";
	foreach my $tf (@{$candidates}) {
		$str.=$tf.", ";
	}
	chop $str;
	print($str."\n");
}
