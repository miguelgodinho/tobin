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
	$tfhash->{$tab1[0]}=1;
	defined($revhash->{$tab1[0]})&&($tfhash->{$revhash->{$tab1[0]}}=1);
}
my $tobin	= new Tobin::IF($ARGV[0]);
my $fbasetup=$tobin->fbasetupGet($ARGV[1]);
foreach(@{$fbasetup->{TFSET}}) {
	if(defined($tfhash->{$_->[0]})) {
		$_->[2]=0;
		$_->[3]=undef;
	}
}
if($tobin->fbasetupUpdate($ARGV[1],undef,$fbasetup->{TFSET},undef)) {
 		die("Problem updating database.");
 }
