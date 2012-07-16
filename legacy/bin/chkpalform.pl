#!/usr/bin/perl
use strict;
use warnings;
use Tobin::IF;

my $tobin		= new Tobin::IF(1);
open(WE, "mcodes.csv");
my @mets=<WE>;
close(WE);
my $codes={};
foreach(@mets) {
	chomp($_);
	my @mets1=split(/\t/,$_);
	$codes->{$mets1[0]}=$mets1[1];
}

open(WE, "pformulas.csv");
my @forms=<WE>;
close(WE);
my $formulas={};
foreach(@forms) {
	chomp($_);
	my @form=split(/\t/,$_);
	$formulas->{$form[0]}=[$form[1],$form[2]];
}
foreach(keys(%{$codes})) {
	if(!defined($formulas->{$_})) {
		print("No formula for: ".$_."\n");
		next;
	}
	my $update=0;
	my @patoms=$formulas->{$_}->[0]=~m/([A-Z][a-z]*[0-9]*)/g;
	my $tform=$tobin->compoundFormulaGet($codes->{$_});
	my @tatoms=($tform=~m/([A-Z][a-z]*[0-9]*)/g);
	if(@patoms!=@tatoms) {
			print("Compound: ".$_." - formulas differ:".$tform." - ".$formulas->{$_}->[0].".\n");
			$update=1;
			next;
		}
	my $phash={};
	foreach my $atom (@patoms) {
		$atom=~m/([A-Z][a-z]*)/;
		my $value=$1;
		$phash->{$value}=($atom=~m/([0-9]+)/)?$1:1;
	}
	foreach my $atom (@tatoms) {
		$atom=~m/([A-Z][a-z]*)/;
		my $value=$1;
		if($phash->{$value}!=(($atom=~m/([0-9]+)/)?$1:1)) {
			print("Compound: ".$_." - formulas differ:".$tform." - ".$formulas->{$_}->[0].".\n");
			$update=1;
			last;
		}
	}
	my $tcharge=$tobin->compoundChargeGet($codes->{$_});
	if((defined($tcharge)&&$tcharge!=$formulas->{$_}->[1])||
	(!defined($tcharge)&&$formulas->{$_}->[1]!=0)) {
		print("Compound: ".$_." - charges differ.\n");
	}
	if($update) {
		$tobin->compoundFormulaUpdate($codes->{$_},$formulas->{$_}->[0]);
	}
}
