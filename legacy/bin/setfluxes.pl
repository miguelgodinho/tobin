#!/usr/bin/perl -I. -w
use strict;
use warnings;
use Tobin::IF;

@ARGV<4&&die("Too few arguments");

open(WE, $ARGV[2])||die("Cannot open reversibles file");
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
open(WE,$ARGV[3])||die("Cannot open reactions file");
@tab=<WE>;
close(WE);
my $tfhash={};
foreach(@tab) {
	chomp;
	my @tab1=split(/\t/,$_);
	if(defined($revhash->{$tab1[0]})) {
		if($tab1[1]>=0) {
			$tfhash->{$tab1[0]}=$tab1[1];
			$tfhash->{$revhash->{$tab1[0]}}=0;
		}
		else {
			$tfhash->{$tab1[0]}=0;
			$tfhash->{$revhash->{$tab1[0]}}=-$tab1[1];
		}
	}
	elsif($tab1[1]>=0) {
		$tfhash->{$tab1[0]}=$tab1[1];
	}
	else {
		die("No reverse for reaction $tab1[0]")
	}
}
my $tobin	= new Tobin::IF($ARGV[0]);
my $fbasetup=$tobin->fbasetupGet($ARGV[1]);
foreach(@{$fbasetup->{TFSET}}) {
	if(defined($tfhash->{$_->[0]})) {
		$_->[2]=$tfhash->{$_->[0]};
		$_->[3]=$tfhash->{$_->[0]};
	}
}
if($tobin->fbasetupUpdate($ARGV[1],undef,$fbasetup->{TFSET},undef)) {
 		die("Problem updating database.");
 }
