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
	my $tf=$tobin->transformationGet($_);
	foreach my $cpd (@{$tf->[2]}) {
		$cpd->{id}==$ARGV[1]&&print($_."\t".$tobin->transformationNameGet($_)."\n");
	}
}
