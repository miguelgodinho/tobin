#!/usr/bin/perl
use strict;
use warnings;
use Tobin::IF;

@ARGV||die("Too few arguments.");

my $tobin		= new Tobin::IF(1);
my $excluded={9324=>1,9355=>1,9356=>1,9357=>1,9360=>1};
my $proxyform={};
open(WE,"proxyform.csv")||die("Cannot open proxyform.");
my @pf=<WE>;
close(WE);
foreach(@pf) {
	chomp;
	my @row=split(/\t/,$_);
	$proxyform->{$row[0]}=[$row[2],$row[3]];
	
}
my $elements={C=>12,H=>1, O=>16,P=>31, S=>32, N=>14};
my $total=0;
my $reaction=$tobin->transformationGet($ARGV[0]);
print("Molar composition\n");
foreach(@{$reaction->[2]}) {
	defined($excluded->{$_->{id}})&&next;
	my $name=$tobin->compoundNameGet(defined($proxyform->{$_->{id}})?
	$proxyform->{$_->{id}}->[1]:$_->{id});
	print($name."\t".((-$_->{sto})*
	(defined($proxyform->{$_->{id}})?1/$proxyform->{$_->{id}}->[0]:1))."\n");
}
print("Mass composition\n");
foreach(@{$reaction->[2]}) {
	my $mass=0;
	defined($excluded->{$_->{id}})&&next;
	my $formula= $tobin->compoundFormulaGet(defined($proxyform->{$_->{id}})?
	$proxyform->{$_->{id}}->[1]:$_->{id});
	($formula=~m/^([A-Z][a-z]{0,1}[0-9]*)+$/)||die($_->{id}." - Bad formula");
	my @atoms= $formula=~m/([A-Z][a-z]{0,1}[0-9]*)/g;
	foreach my $atom (@atoms) {
		$atom=~m/([A-Z][a-z]{0,1})([0-9]*)/;
		defined($elements->{$1})?
		(my $m=($2 ne ""?$2:1)*$elements->{$1}*(-$_->{sto})*
		(defined($proxyform->{$_->{id}})?1/$proxyform->{$_->{id}}->[0]:1)):
		die("No mass found for $1");
		$mass+=$m;
		$total+=$m;
	}
	my $name=$tobin->compoundNameGet(defined($proxyform->{$_->{id}})?
	$proxyform->{$_->{id}}->[1]:$_->{id});
	print($name."\t".$mass."\n");
}
print($total."\n");
