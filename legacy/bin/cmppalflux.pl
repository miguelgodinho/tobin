#!/usr/bin/perl -I. -w
use strict;
use warnings;
use Tobin::IF;
my $tobin	= new Tobin::IF(1);
open(WE, "simcodes.csv")||die("cannot open simcodes");
my @sc=<WE>;
close(WE);
my $simcodes={};
foreach(@sc) {
	chomp;
	my @cd=split(/\t/,$_);
	$simcodes->{$cd[0]}=(@cd==3?[$cd[1],$cd[2]]:[$cd[1]]);
}
open(WE,"palflux1.txt")||die("cannot open palflux");
@sc=<WE>;
close(WE);
my $p2tf={};
my $p2tr={};
my $pf={};
foreach(@sc) {
	chomp;
	my @cd=split(/\t/,$_);
#	defined($p2tf->{$simcodes->{$cd[0]}->[0]})&&
#	die("$cd[0] - ".$p2tf->{$simcodes->{$cd[0]}." - already in hash.")
#	$p2tf->{$simcodes->{$cd[0]}->[0]}=$cd[0];
#	@{$simcodes->{$cd[0]}}==2&&($p2tr->{$simcodes->{$cd[0]}->[1]}=$cd[0]);
	$pf->{$cd[0]}=$cd[1];
}
my %fba1=$tobin->fbaresGet($ARGV[0]);
#print(keys(%{$simcodes})."\n");
#foreach(keys(%{$simcodes})) {
#	print($_."\t".$simcodes->{$_}->[0]."\n");
#}
foreach(keys(%{$pf})) {
	print($_."\t".$pf->{$_});
	defined($simcodes->{$_})||(print("\t not defined\n")&&next);
	print("\t".$simcodes->{$_}->[0]."\t".$fba1{$simcodes->{$_}->[0]}."\t".(@{$simcodes->{$_}}==2&&
		defined($fba1{$simcodes->{$_}->[1]})?$simcodes->{$_}->[1]."\t".
		$fba1{$simcodes->{$_}->[1]}:"")."\n");
}
