#!/usr/bin/perl
use strict;
use warnings;
use Tobin::IF;

my $tobin		= new Tobin::IF(1);
@ARGV<2&&die("too few arguments");
my $tfs=[];
if($ARGV[0]==0) {
	open(WE,$ARGV[1])||die("Cannot open the file: ".$ARGV[0]."!\n");
	my @rlist=<WE>;
	close(WE);
	foreach(@rlist) {
		chomp;
		push(@{$tfs},$_);
	}
}
elsif($ARGV[0]==1) {
	warn $ARGV[1];
	my $fbaset=$tobin->fbasetupGet($ARGV[1]);
	open(WE,$ARGV[2])||die("Cannot open excluded file");
	my @rlist=<WE>;
	close(WE);
	my $excluded={};
	foreach(@rlist) {
		chomp;
		$excluded->{$_}=1;
	}
	foreach(@{$fbaset->{TFSET}}) {
		defined($excluded->{$_->[0]})&&next;
		push(@{$tfs},$_->[0]);
	}
}
elsif($ARGV[0]==2) {
	for(my $i=1;$i<@ARGV;$i++) {
		push(@{$tfs},$ARGV[$i]);
	}
}
else {
	die("Bad mode");
}
my $problematic={};
foreach(@{$tfs}) {
	chomp($_);
	my $atoms={};
	my $charge=0;
	my $transf=$tobin->transformationGet($_);
	foreach my $row (@{$transf->[2]}) {
		my $ccharge=$tobin->compoundChargeGet($row->{id});
		$ccharge=(defined($ccharge)?$ccharge:0);
		$charge+=$row->{sto}*$ccharge;
		my @catoms=$tobin->compoundFormulaGet($row->{id})=~m/([A-Z][a-z]*[0-9]*)/g;
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
	if($charge) {
		print("Reaction : ".$_." is not charge-balanced.\n");
		$problematic->{$_}=1;
	}
#	print(keys(%{$atoms})."\n");
	foreach my $atom(keys(%{$atoms})) {
		if($atoms->{$atom}) {
			print("Reaction : ".$_." is not atom-balanced on ".$atom.": ".$atoms->{$atom}.".\n");
			$problematic->{$_}=1;
		}
	}
}
#print(keys(%{$problematic})."\n");
foreach(keys(%{$problematic})) {
	print($_."\n");
}
