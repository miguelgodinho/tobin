#!/usr/bin/perl -I. -w
use strict;
use warnings;
use Tobin::IF;

my $tobin=new Tobin::IF(1);

open(WE,$ARGV[0])||die("Cannot open mcodes");
my @tab=<WE>;
close(WE);
my $mhash={};
foreach(@tab) {
	chomp;
	my @tab1=split(/\t/,$_);
	$mhash->{$tab1[0]}=$tab1[1];
}
open(WE, $ARGV[1])||die("Cannot open compound list");
@tab=<WE>;
foreach (@tab) {
	chomp;
	my @tab1=split(/\t/,$_);
	defined($mhash->{$tab1[0]})||print("No number for $tab1[0]")&&next;
	my @tatoms=($tobin->compoundFormulaGet($mhash->{$tab1[0]})=~m/([A-Z][a-z]*[0-9]*)/g);
	my $thash={};
	foreach my $atom (@tatoms) {
		my $value;
		($atom=~m/([0-9]+)/)?($value=$1):($value=1);
#		print $value."\n";
		$atom=~/([A-Z][a-z]*)/;
		$thash->{$1}=$value;
	}
	my $shash={};
	my @satoms=$tab1[1]=~m/([A-Z][a-z]*[0-9]*)/g;
	my $charge=$tobin->compoundChargeGet($mhash->{$tab1[0]});
	defined($charge)||($charge=0);
	my $chdiff=0;
	my $fdiff=0;
	$charge==$tab1[2]||
	print($mhash->{$tab1[0]}."\t$tab1[0]\tdifference in charge\t$charge\t$tab1[2]\n")
	&&($chdiff=1);
	foreach my $atom (@satoms) {
		my $value;
		($atom=~m/([0-9]+)/)?($value=$1):($value=1);
		$atom=~/([A-Z][a-z]*)/;
		$shash->{$1}=$value;
	}
	foreach my $atom (keys(%{$thash})) {
		defined($shash->{$atom})||print("$mhash->{$tab1[0]}\t$tab1[0]\tNo element $atom in simpheny formul\n")
		&&($fdiff=1)&&next;
		$thash->{$atom}==$shash->{$atom}||print("$mhash->{$tab1[0]}\t$tab1[0]\tUneqal numbers of element $atom\t".
		$thash->{$atom}."\t".$shash->{$atom}."\n")&&($fdiff=1);
	}
	foreach my $atom (keys(%{$shash})) {
		defined($thash->{$atom})||print("$mhash->{$tab1[0]}\t$tab1[0]\tNo element $atom in tobin formula\n")
		&&($fdiff=1);
	}
	if($chdiff){
		print("Correct charge?: ");
		my $ans=<STDIN>;
		if($ans=~/^y$/) {
			$tobin->compoundChargeUpdate($mhash->{$tab1[0]},$tab1[2]);
		
		}
	}
	if($fdiff) {
		print("Correct formula?: ");
		my $ans=<STDIN>;
		if($ans=~/^y$/) {
			my $formula="";
			foreach my $atom (sort((keys(%{$shash})))) {
				$formula.=$atom.($shash->{$atom}==1?"":$shash->{$atom});
				$tobin->compoundFormulaUpdate($mhash->{$tab1[0]},$formula);
			}
		}
	}
	
	
	
}
