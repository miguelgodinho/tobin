#!/usr/bin/perl -I. -w
use strict;
use warnings;
use Tobin::IF;
my $tobin= new Tobin::IF(1);
open(WE, "mcodes-new.csv")||die("cannot open mcodes");
my @tab=<WE>;
close(WE);
my $mcodes={};
foreach(@tab) {
	chomp;
	my @tab1=split(/\t/,$_);
	defined($mcodes->{$tab1[1]})||($mcodes->{$tab1[1]}={});
	$mcodes->{$tab1[1]}->{$tab1[0]}=1;
}

open(WE, $ARGV[0])||die("Cannot open input file");
@tab=<WE>;
close(WE);

foreach (@tab) {
	chomp;
	my $str=$_."\t".$tobin->compoundNameGet($_)."\t".$tobin->compoundFormulaGet($_).
	"\t".$tobin->compoundChargeGet($_)."\t";
	my $tab1=$tobin->compoundNamesGet($_);
	foreach my $n (@{$tab1}) {
		$str.=$n.", ";
	}
	$str=~s/, $//;
	$str.="\t";
	my $links=$tobin->compoundLinksGet($_);
	$str.=defined($links->{901})?$links->{901}:"";
	$str.="\t";
	if(defined($mcodes->{$_})) {
		foreach my $m (keys(%{$mcodes->{$_}})) {
			$str.=$m.", ";
		}
		$str=~s/, $//;
	}
	print($str."\n");
}
