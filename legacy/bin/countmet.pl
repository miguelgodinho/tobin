#!/usr/bin/perl -I.. -w
use strict;
use warnings;
use Tobin::IF;
my $tobin=new Tobin::IF(1);
open(WE,$ARGV[0])||die("Cannot open input file!");
my @tab=<WE>;
close(WE);
my $ext={};
my $int={};
foreach(@tab) {
	chomp;
	$_=~s%/.*$%%;
	my $rea=$tobin->transformationGet($_);
	foreach my $cpd (@{$rea->[2]}) {
		$cpd->{ext}?($ext->{$cpd->{id}}=1):($int->{$cpd->{id}}=1);
	}
}
print(keys(%{$int})."\n");
print(keys(%{$ext})."\n");
