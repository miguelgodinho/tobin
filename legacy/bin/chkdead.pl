#!/usr/bin/perl -I. -w
use strict;
use warnings;
use Tobin::IF;

@ARGV<2&&die("Too few arguments.");
my $tobin		= new Tobin::IF(1);
open(WE, $ARGV[0])||die("Cannot open reversibles file");
my @tab=<WE>;
close(WE);
my $revhash={};
foreach(@tab) {
	chomp;
	my @tab1=split(/\t/,$_);
	(defined($revhash->{$tab1[0]})||defined($revhash->{$tab1[1]}))&&
	die("Problem with reversibles.");
	$revhash->{$tab1[0]}=$tab1[1];
	$revhash->{$tab1[1]}=$tab1[0];
}
my $compmap=[{}, {}];
my $blcmp={};
my %fbares=$tobin->fbaresGet($ARGV[1]);
my $end;
print(keys(%fbares)."\n");
do {
	$end=0;
$compmap=[{}, {}];
foreach(keys(%fbares)) {
#	($_==9617)&&next;
	my $rea=$tobin->transformationGet($_);
	foreach my $comp(@{$rea->[2]}){
		defined($compmap->[$comp->{ext}]->{$comp->{id}})?
		push(@{$compmap->[$comp->{ext}]->{$comp->{id}}}, $comp->{sto}<0?[1,$_]:[0,$_]):
		($compmap->[$comp->{ext}]->{$comp->{id}}=[$comp->{sto}<0?[1,$_]:[0,$_]]);
	}
	
}
foreach(keys(%{$compmap->[0]})) {
	my $dir=0;
	if(@{$compmap->[0]->{$_}}==2&&defined($revhash->{$compmap->[0]->{$_}->[0]->[1]})&&
	$revhash->{$compmap->[0]->{$_}->[0]->[1]}==$compmap->[0]->{$_}->[1]->[1]) {
#		print($compmap->[0]->{$_}->[0]->[1]."\t".$compmap->[0]->{$_}->[1]->[1]."\n");
		delete($fbares{$compmap->[0]->{$_}->[0]->[1]});
		delete($fbares{$compmap->[0]->{$_}->[1]->[1]});
		$blcmp->{$_}=1;
		$end=1;
	}
	else {
		foreach my $d (@{$compmap->[0]->{$_}}) {$dir+=$d->[0]}
		if(!$dir ||$dir==@{$compmap->[0]->{$_}}) {
			$blcmp->{$_}=1;
			foreach my $rea (@{$compmap->[0]->{$_}}) {
#				print($rea->[1]."\n");
				delete($fbares{$rea->[1]});
				$end=1;
			}
		}
	}
	
	if(!$dir) { print("Internal compound ",$_." - ".$tobin->compoundNameGet($_)." is only produced\n")}
	elsif($dir==@{$compmap->[0]->{$_}}) {
		print("Internal compound ",$_." - ".$tobin->compoundNameGet($_)." is only consumed\n")
	}
}
print(keys(%fbares)."\n");
} while($end);
my $tfset=[];
foreach(keys(%fbares)) {push(@{$tfset},$_)}
#$tobin		= new Tobin::IF(1004);
#$tobin->transformationsetCreate("pek1", $tfset);
foreach(keys(%{$compmap->[1]})) {
	my $dir=0;
	foreach my $d (@{$compmap->[1]->{$_}}) {$dir+=$d->[0]}
	if(!$dir) { print("External compound ",$_." - ".$tobin->compoundNameGet($_)." is only produced\n")}
	elsif($dir==@{$compmap->[1]->{$_}}) {
		print("External compound ",$_." - ".$tobin->compoundNameGet($_)." is only consumed\n")
	}
}
my %fbares1=$tobin->fbaresGet($ARGV[1]);
my $skip={};
print("Active reactions\n");
foreach(@{$tfset}) {
	defined($skip->{$_})&&next;
	if(defined($revhash->{$_})) {
		print(($_< $revhash->{$_}?$_."/".$revhash->{$_}:$revhash->{$_}."/".$_)."\n");
		$skip->{$revhash->{$_}}=1;
	}
	else {
		print("$_\n");
	}
}
print("Blocked reactions\n");
$skip={};
foreach(keys(%fbares1)) {
	defined($skip->{$_})&&next;
	if(!defined($fbares{$_})) {
		if(defined($revhash->{$_})) {
			print(($_< $revhash->{$_}?$_."/".$revhash->{$_}:$revhash->{$_}."/".$_)."\n");
			$skip->{$revhash->{$_}}=1;
		}
		else {
			print("$_\n");
		}	
	}
}
print("Active compounds\n");
foreach(keys(%{$compmap->[0]})) {
	print($_."\n");
}
print("Blocked compounds\n");
foreach(keys(%{$blcmp})) {
	print($_."\n");
}
