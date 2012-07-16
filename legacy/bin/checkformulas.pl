#!/usr/bin/perl
use strict;
use warnings;
use Tobin::IF;

my $tobin		= new Tobin::IF(1);

open(WE, "mcodes.csv")||die("Cannot open mcodes");
my @mets=<WE>;
close(WE);
my $mcodes={};
foreach(@mets) {
	chomp($_);
	my @mets1=split(/\t/,$_);
	$mcodes->{$mets1[0]}=$mets1[1];
}

open(WE,"simcomps1.csv")||die("Cannot open simcomps\n");
my$simcomps;
@{$simcomps}=<WE>;
close(WE);
my $simformulas={};
foreach(@{$simcomps}) {
	chomp($_);
	my @simcomps1=split(/\t/,$_);
	$simformulas->{$simcomps1[0]}=$simcomps1[1];
}

foreach(keys(%{$mcodes})) {
	if(!defined($simformulas->{$_})) {
#		print("No simpheny formula for compound: ".$_.".\n");
	}
	else{
		my @tatoms=$tobin->compoundFormulaGet($mcodes->{$_})=~m/([A-Z][a-z]*[0-9]*)/g;
		my @satoms=$simformulas->{$_}=~m/([A-Z][a-z]*[0-9]*)/g;
		if(@satoms!=@tatoms) {
			print("Compound: ".$_." - formulas differ.\n");
			next;
		}
		my $thash={};
		my $shash={};
		foreach my $atom (@satoms) {
			$atom=~m/([A-Z][a-z]*)/;
			my $value=$1;
			$shash->{$value}=($atom=~m/([0-9]+)/)?$1:1;
		}
		foreach my $atom (@tatoms) {
			$atom=~m/([A-Z][a-z]*)/;
			my $value=$1;
			if($shash->{$value}!=(($atom=~m/([0-9]+)/)?$1:1)) {
				print("Compound: ".$_." - formulas differ.\n");
				next;
			}
		}
	}
}

foreach(keys(%{$simformulas})) {
	if(!defined($mcodes->{$_})) {
		print("No compound found for code: ".$_."\n");
	}
}
