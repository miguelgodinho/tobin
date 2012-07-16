#!/usr/bin/perl -I. -w
use strict;
use warnings;
use Tobin::IF;

my $tobin       = new Tobin::IF(1);
@ARGV<2&&die("Too few arguments");

my $fba=$tobin->fbasetupGet($ARGV[0]);
open(WE, $ARGV[1])||die("Cannot open reversible file.");
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
my $skip={};
my $tfhash={};
my $objective;
my $limhash={};
my $cpdhash={};
foreach(@{$fba->{TFSET}}) {
	defined($skip->{$_->[0]})&&next;
	defined($revhash->{$_->[0]})&&($skip->{$revhash->{$_->[0]}}=1);
	$tfhash->{$_->[0]}={};
	$limhash->{$_->[0]}={};
	$_->[2]>0&&($limhash->{$_->[0]}->{min}=$_->[2]);
	defined($_->[3])&&($limhash->{$_->[0]}->{max}=$_->[3]);
	if($_->[1]!=0) {
		$objective=$_->[1]>0?$_->[0]:-$_->[0];
	}
	my $tf=$tobin->transformationGet($_->[0]);
	foreach my $cpd (@{$tf->[2]}) {
		$tfhash->{$_->[0]}->{($cpd->{ext}?"EX_":"")."C".sprintf("%04d",$cpd->{id})}=$cpd->{sto};
		$cpdhash->{($cpd->{ext}?"EX_":"")."C".sprintf("%04d",$cpd->{id})}=1;
	}
}
foreach(@{$fba->{TFSET}}) {
	defined($skip->{$_->[0]})||next;
	if($_->[1]!=0) {
		$objective=$_->[1]>0?-$revhash->{$_->[0]}:$revhash->{$_->[0]};
	}
	if($_->[2]>0) {
		if(defined($limhash->{$revhash->{$_->[0]}}->{min})||
		(defined($limhash->{$revhash->{$_->[0]}}->{max})&&
		$limhash->{$revhash->{$_->[0]}}->{max}>0)) {
			die("Tf $_->[0] - inconsistency in limits");
		}
		else {
			$limhash->{$revhash->{$_->[0]}}->{max}=-$_->[2];
		}
	}
	if(defined($_->[3])) {
		if(defined($limhash->{$revhash->{$_->[0]}}->{min})&&
		$limhash->{$revhash->{$_->[0]}}->{min}>0) {
			die("Tf $_->[0] - inconsistency in limits");
		}
		else {
			$limhash->{$revhash->{$_->[0]}}->{min}=-$_->[2];
		}
	}
}
my $realinv={};
my $realrev={};
foreach(keys(%{$limhash})) {
	if(defined($revhash->{$_})&&defined($limhash->{$_}->{min})&&
	$limhash->{$_}->{min}>=0) {
		$realinv->{$_}=1;
	}
	elsif(defined($revhash->{$_})&&(!defined($limhash->{$_}->{min})||$limhash->{$_}->{min}<0)) {
		$realrev->{$_}=1;
	}
	else {
		$realinv->{$_}=1;
	}
}
print("min: ");
foreach(keys(%{$limhash})) {
	defined($limhash->{$_}->{max})&&$limhash->{$_}->{max}!=0&&
	print("+".$limhash->{$_}->{max}." "."MAXR".sprintf("%04d",$_)." ");
	defined($limhash->{$_}->{min})&&$limhash->{$_}->{min}!=0&&
	print("-".$limhash->{$_}->{min}." "."MINR".sprintf("%04d",$_)." ");
}
print(";");
print("\n\n");
foreach(keys(%{$tfhash})) {
	print("R".sprintf("%04d",$_).": ");
	foreach my $cpd (keys(%{$tfhash->{$_}})) {
		print(($tfhash->{$_}->{$cpd}>0?"+":"").$tfhash->{$_}->{$cpd}." ".$cpd." ");
	}
	defined($limhash->{$_}->{max})&&print("+1 MAXR".sprintf("%04d",$_)." ");
	defined($limhash->{$_}->{min})&&$limhash->{$_}->{min}!=0&&print("-1 MINR".sprintf("%04d",$_)." ");
	print((defined($realinv->{$_})?">":"")."=".(abs($objective)==$_?1:0).";");
	print("\n");
}

print("\nfree ");
my $str="";
foreach(keys(%{$cpdhash})) {
	$str.=$_.", ";
}
chop $str;
chop $str;
print($str.";\n");
