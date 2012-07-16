#!/usr/bin/perl -I. -w
use strict;
use warnings;
use Tobin::IF;

@ARGV<2&&die("Too few arguments");
my $tobin		= new Tobin::IF(1);
my $tfset=[];
if($ARGV[0]==0 ){
	my $set=$tobin->transformationsetGet($ARGV[1]);
	foreach(@{$set->{TRANS}}) {
		push(@{$tfset},$_);
	}
}
elsif($ARGV[0]==1) {
	my $fba=$tobin->fbasetupGet($ARGV[1]);
	print(@{$fba->{TFSET}}."\n");
	foreach(@{$fba->{TFSET}}) {
		push(@{$tfset},$_->[0]);
	}
}
my $errors=[];
my $warnings=[];
foreach(@{$tfset}) {
	$tobin->transformationNameGet($_)=~/^SINK|^SOURCE/&&next;
	my $atoms={};
	my $charge=0;
	my $transf=$tobin->transformationGet($_);
	my $exclude=0;
	foreach my $row (@{$transf->[2]}) {
		my $ccharge=$tobin->compoundChargeGet($row->{id});
		$ccharge=(defined($ccharge)?$ccharge:0);
		$charge+=$row->{sto}*$ccharge;
		my $formula=$tobin->compoundFormulaGet($row->{id});
		if($formula!~m/^([A-Z][a-z]{0,1}[0-9]*)+$/) {
			print("$_ - excluded\n");
			$exclude=1;
			last;
		}
		my @catoms=$formula=~m/([A-Z][a-z]*[0-9]*)/g;
		foreach my $atom (@catoms) {
			my $value;
#			print($atom."\n");
			($atom=~m/([0-9]+)/)?($value=$1):($value=1);
#			print $value."\n";
			$atom=~/([A-Z][a-z]*)/;
			defined($atoms->{$1})?
			($atoms->{$1}+=$row->{sto}*$value):
				($atoms->{$1}=$row->{sto}*$value);
		}
	}
	my $corr=-1;
	if(!$exclude){
	if($charge) {
		print("Reaction : ".$_." is not charge-balanced.\n");
	}
#	print(keys(%{$atoms})."\n");
	foreach my $atom(keys(%{$atoms})) {
		if($atoms->{$atom}) {
			$corr=1;
			print("Reaction : ".$_." is not atom-balanced on ".$atom.": ".$atoms->{$atom}.".\n");
			if($atom ne 'H') {$corr=0}
		}
	}
	if($corr>0&&$atoms->{H}==$charge) {
		($_==8898||$_==8901)&&next;
		print("Reaction : ".$_." H inconsistence - corrected.\n");
		my $hpres=0;
		my $ext=0;
		my $hdel=0;
		foreach my $row (@{$transf->[2]}) {
			$row->{ext}==1&&($ext=1)&&last;
			$row->{id}==65&&($hpres=1)&&($row->{sto}==$atoms->{H}?($hdel=1):
			($row->{sto}-=$atoms->{H}));
		}
		if(!$ext) {
			my $stoich=[];
			foreach my $row (@{$transf->[2]}) {
				if($hdel&&$row->{id}==65) {next}
				push(@{$stoich},$row);
			}
			if(!$hpres) {
				push(@{$stoich},{id=>65, sto=>-$atoms->{H},ext=>0});
			}
			$tobin->transformationModify($_,undef,undef,$stoich,undef,$errors);
		}
	}
	}
	
}
