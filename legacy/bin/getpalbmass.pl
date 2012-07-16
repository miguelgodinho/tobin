#!/usr/bin/perl -w
use strict;
use warnings;

open(WE,"palmetequ.csv");
my @tab=<WE>;
close(WE);
my $methash={};
foreach(@tab) {
	chomp;
	my @tab1=split(/\t/,$_);
	$methash->{$tab1[0]}=$tab1[1]
}
my $elements={C=>12,H=>1, O=>16,P=>31, S=>32, N=>14};
my $elmass={C=>0,H=>0, O=>0,P=>0, S=>0, N=>0};
my $relmass={C=>0,H=>0, O=>0,P=>0, S=>0, N=>0};
open(WE,"biomeq.txt");
@tab=<WE>;
close(WE);
my $mass=0;
my $rmass=0;
my $left=1;;
foreach(@tab) {
	chomp;
	if($_ eq "--") {
		$left=0;
		next;
	}
	my @tab1=split(/ /,$_);
	defined($methash->{$tab1[1]})||die("canot find compound $tab1[1]");
	my $formula=$methash->{$tab1[1]};
#	warn $formula;
	($formula=~m/^([A-Z][a-z]{0,1}[0-9]*)+$/)||die($tab1[1]." - Bad formula");
	my @atoms= $formula=~m/([A-Z][a-z]{0,1}[0-9]*)/g;
	foreach my $atom (@atoms) {
		$atom=~m/([A-Z][a-z]{0,1})([0-9]*)/;
		defined($elements->{$1})?
		(my $m=($2 ne ""?$2:1)*$elements->{$1}*($tab1[0])):
		die("No mass found for $1");
		if($left) {
			$mass+=$m;
			$elmass->{$1}+=$m;
		}
		else {
			$rmass+=$m;
			$relmass->{$1}+=$m;
		}
	}
}

print("$mass\t$rmass\n");
foreach(keys(%{$elmass})) {
	print($_."\t".$elmass->{$_}."\n");
}
print("--\n");
foreach(keys(%{$relmass})) {
	print($_."\t".$relmass->{$_}."\n");
}
print("--\n");
foreach(keys(%{$elmass})) {
	print($_."\t".($elmass->{$_}-$relmass->{$_})."\n");
}
