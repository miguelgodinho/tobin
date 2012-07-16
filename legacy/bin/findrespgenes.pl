#!/usr/bin/perl -I. -w
use strict;
use warnings;

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

open(WE,$ARGV[1])||die("Cannot open tf anno!");
@tab=<WE>;
close(WE);
my $tfanno={};
foreach(@tab) {
	chomp;
	my @tab1=split(/\t/,$_);
	my $tf=shift(@tab1);
	$tfanno->{$tf}={};
	foreach my $ec(@tab1) {
		$tfanno->{$tf}->{$ec}=1;
	}
}

my $cpanno={};
open(WE,$ARGV[3])||die("Cannot open cp anno!");
@tab=<WE>;
close(WE);
foreach(@tab) {
	chomp;
	my @tab1=split(/\t/,$_);
	my $cp=shift(@tab1);
	$cpanno->{$cp}={};
	foreach my $ge (@tab1) {
#		defined($exgenes->{$ge})&&next;
		$cpanno->{$cp}->{$ge}=1;
	}
}
open(WE,$ARGV[2])||die("Cannot open ec anno!");
@tab=<WE>;
close (WE);
my $ecanno={};
foreach(@tab) {
	chomp;
	my @tab1=split(/\t/,$_);
	my $ec=shift(@tab1);
	$ecanno->{$ec}={};
	foreach my $cp (@tab1) {
		$ecanno->{$ec}->{$cp}=1;
	}
}
foreach(4..(@ARGV-1)) {
	my $gelist=[];
	my $cphash={};
	my $tf=(defined($revhash->{$ARGV[$_]}))?($ARGV[$_]<$revhash->{$ARGV[$_]}?
	$ARGV[$_]."/".$revhash->{$ARGV[$_]}:$revhash->{$ARGV[$_]}."/".$ARGV[$_]):
	$ARGV[$_];
	foreach my $ec (keys(%{$tfanno->{$tf}})) {
		foreach my $cp (keys(%{$ecanno->{$ec}})) {
			$cphash->{$cp}=1;
		}
	}
	print($tf);
	foreach my $cp (keys(%{$cphash})) {
		print("\t");
		my $str="";
		foreach my $ge (keys(%{$cpanno->{$cp}})) {
			$str.=$ge.",";
		}
		chop($str);
		print($str)
	}
	print("\n");
}
