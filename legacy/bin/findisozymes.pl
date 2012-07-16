#!/usr/bin/perl -I. -w
use strict;
use warnings;
use Tobin::IF;


open(WE, $ARGV[1])||die("Cannot open reversibles file");
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

open(WE,$ARGV[2])||die("Cannot open tf anno!");
@tab=<WE>;
close(WE);
my $tfanno={};
my $ecannorev={};
foreach(@tab) {
	chomp;
	my @tab1=split(/\t/,$_);
	my $tf=shift(@tab1);
	$tfanno->{$tf}={};
	foreach my $ec(@tab1) {
		$tfanno->{$tf}->{$ec}=1;
		defined($ecannorev->{$ec})||($ecannorev->{$ec}={});
		$ecannorev->{$ec}->{$tf}=1;
	}
}
open(WE,$ARGV[3])||die("Cannot open ec anno!");
@tab=<WE>;
close (WE);
my $ecanno={};
my $cpannorev={};
foreach(@tab) {
	chomp;
	my @tab1=split(/\t/,$_);
	my $ec=shift(@tab1);
	$ecanno->{$ec}={};
	foreach my $cp (@tab1) {
		$ecanno->{$ec}->{$cp}=1;
		defined($cpannorev->{$cp})||($cpannorev->{$cp}={});
		$cpannorev->{$cp}->{$ec}=1;
	}
}

my $tobin= new Tobin::IF(1);
my $fbaset=$tobin->fbasetupGet($ARGV[0]);
my $skip={};
foreach(@{$fbaset->{TFSET}}) {
	defined($skip->{$_->[0]})&&next;
	defined($revhash->{$_->[0]})&&($skip->{$revhash->{$_->[0]}}=1);
	my $rea=defined($revhash->{$_->[0]})?($_->[0]<$revhash->{$_->[0]}?
	$_->[0]."/".$revhash->{$_->[0]}:$revhash->{$_->[0]}."/".$_->[0]):$_->[0];
	my $str.=$rea."\t";
	foreach my $ec (keys(%{$tfanno->{$rea}})) {
		foreach my $cp (keys(%{$ecanno->{$ec}})) {
			$str.=$cp."\t";
		}
	}
	chop($str);
	print($str."\n");
	
}


