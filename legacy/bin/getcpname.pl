#!/usr/bin/perl -I. -w
use strict;
use warnings;
use Tobin::IF;

my $tobin=new Tobin::IF(1);
open(WE,$ARGV[0])||die("Cannot open input file");
my @tab=<WE>;
close(WE);
foreach(@tab) {
	chomp;
	print("C".sprintf("%04d",$_)."\t".$tobin->compoundNameGet($_)."\n");
}
