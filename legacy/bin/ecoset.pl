#!/usr/bin/perl
use strict;
use warnings;
use Tobin::IF;

if(@ARGV!=2) {
	exit()
}
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
open(WE, "ptob.txt");
my @tab=<WE>;
my $numbers={};
close(WE);
foreach(@tab) {
	chomp($_);
	my @tab1=split(/\t/,$_);
	$numbers->{$tab1[0]}=((@tab1==2)?[$tab1[1]]:[$tab1[1],$tab1[2]]);
}
open(WE,$ARGV[0]);
@tab=<WE>;
close(WE);
my $rlist=[];
my $nnew={};
foreach(@tab) {
	chomp($_);
	my @tab1=split(/\t/,$_);
	if(defined($numbers->{$tab1[0]})) {
		if($tab1[1]) {
			if(@{$numbers->{$tab1[0]}}==2) {
				push(@{$rlist},$numbers->{$tab1[0]}->[0],$numbers->{$tab1[0]}->[1]);
			}
			else {
				print($tab1[0]." - Problem with reverse.\n");
			}
		}
		else {
			push(@{$rlist},$numbers->{$tab1[0]}->[0]);
		}
	}
	else {
		my @mets1=split(/ <==> | --> | -->/,$tab1[2]);
		my @subs=split(/ \+ | \+/,$mets1[0]);
		my @prods=split(/ \+ | \+/,$mets1[1]);
		my $blad=0;
		my $scodes={};
		my $pcodes={};
		foreach my $met(@subs){
			defined($codes->{$met})?($scodes->{$codes->{$met}}=1):($blad=1);
		}
		foreach my $met(@prods){
			defined($codes->{$met})?($pcodes->{$codes->{$met}}=1):($blad=1);
		}
		if(!$blad) {
			if($tab1[1]) {
				my $reacts=$tobin->transformationFindByCompounds($scodes,$pcodes);
				my $reacts1=$tobin->transformationFindByCompounds($pcodes,$scodes);
				if(@{$reacts}==1&&@{$reacts1}==1) {
					push(@{$rlist},$reacts->[0],$reacts1->[0]);
					$nnew->{$tab1[0]}=[$reacts->[0],$reacts1->[0]];
				}
				else {
					print($tab1[0]." Problem finding reactions, for:");
					foreach my $rea (@{$reacts}) {
						print(" ".$rea);
					}
					print(", rev:");
					foreach my $rea (@{$reacts1}) {
						print(" ".$rea);
					}
					print("\n");
				}
			}
			else {
				my $reacts=$tobin->transformationFindByCompounds($scodes,$pcodes);
				if(@{$reacts}==1) {
					push(@{$rlist},$reacts->[0]);
					$nnew->{$tab1[0]}=[$reacts->[0]];
				}
				else {
					print($tab1[0]." Problem finding reactions:");
					foreach my $rea (@{$reacts}) {
						print(" ".$rea);
					}
					print("\n");
				}
			}
		}
		else{
			print($tab1[0]." Problem finding compounds\n");
		}
	}
}
open(WY,">nnew.csv");
foreach (keys(%{$nnew})) {
	print(WY $_."\t".$nnew->{$_}->[0].((@{$nnew->{$_}}==2)?("\t".$nnew->{$_}->[1]):"")."\n");
}

print("Add the set to the platform? ");
my $answer;
read(STDIN,$answer,1);
if($answer eq 'y') {
	print($ARGV[1]."\n");
	$tobin->transformationsetCreate($ARGV[1],$rlist);
} 
