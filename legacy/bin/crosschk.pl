#!/usr/bin/perl -I. -w
use strict;
use warnings;
use Tobin::IF;

my $tobin	= new Tobin::IF(1);

@ARGV<2&&die("Too few arguments.");
my $type=@ARGV==3?$ARGV[2]:0;
my %fba1=$tobin->fbaresGet($ARGV[0]);
my %fba2=$tobin->fbaresGet($ARGV[1]);
foreach(keys(%fba1)) {
	if($type==0) {
		if($fba1{$_}>0&&$fba2{$_}==0) {
			print($_." - ".$tobin->transformationNameGet($_)."\n");
		}
	}
	elsif($type==1) {
		if($fba1{$_}>0&&!defined($fba2{$_})) {
			print($fba1{$_}."\t".$_." - ".$tobin->transformationNameGet($_)."\n");
		}
	}
	elsif($type==2) {
		if(!defined($fba2{$_})) {
			print($_." - ".$tobin->transformationNameGet($_)."\n");
		}
	}
	elsif($type==3) {
		if($fba1{$_}!= $fba2{$_}) {
			print(($fba1{$_}-$fba2{$_})."\t".$_."\t".$tobin->transformationNameGet($_)."\n");
		}
	}
}
