#!/usr/bin/perl
use strict;
use warnings;
use Tobin::IF;

@ARGV||die("Too few arguments.");

my $tobin		= new Tobin::IF(1);
my $excluded={9324=>1,9355=>1,9356=>1,9357=>1,9360=>1,9361=>1};
my $proxyform={};
open(WE,"proxyform.csv")||die("Cannot open proxyform.");
my @pf=<WE>;
close(WE);
foreach(@pf) {
	chomp;
	my @row=split(/\t/,$_);
	$proxyform->{$row[0]}=[$row[2],$row[3]];
	
}
my $mass=0;
my $elements={C=>12,H=>1, O=>16,P=>31, S=>32, N=>14, Fe=>56};
my $elmass={C=>0,H=>0, O=>0,P=>0, S=>0, N=>0, Fe=>0};
my $reaction=$tobin->transformationGet($ARGV[0]);
print($reaction->[3]->[0]."\n");
#open(WY, ">bcfom.txt");
foreach(@{$reaction->[2]}) {
	defined($excluded->{$_->{id}})&&next;
	my $formula= $tobin->compoundFormulaGet(defined($proxyform->{$_->{id}})?
	$proxyform->{$_->{id}}->[1]:$_->{id});
#	print(WY$_->{id}."\t".$formula."\t".$_->{sto}."\n");
#	warn $formula;
	($formula=~m/^([A-Z][a-z]{0,1}[0-9]*)+$/)||die($_->{id}." - Bad formula");
	my @atoms= $formula=~m/([A-Z][a-z]{0,1}[0-9]*)/g;
	foreach my $atom (@atoms) {
		$atom=~m/([A-Z][a-z]{0,1})([0-9]*)/;
		defined($elements->{$1})?
		(my $m=($2 ne ""?$2:1)*$elements->{$1}*(-$_->{sto})*
		(defined($proxyform->{$_->{id}})?1/$proxyform->{$_->{id}}->[0]:1)):
		die("No mass found for $1");
		$mass+=$m;
		$elmass->{$1}+=$m;
	}
}
#foreach(keys(%{$elements})) {
#	print("$_\n");
#}
#close(WY);
print("Total mass\t".$mass."\n");
foreach(keys(%{$elmass})) {
	print($_."\t".$elmass->{$_}."\n");
}
my $divider=$elmass->{C}/12;
print("Chemical formula\n");
foreach(keys(%{$elmass})) {
	print($_."\t".($elmass->{$_}/$elements->{$_}/$divider)."\n");
}
