#!/usr/bin/perl -I. -w
use strict;
use warnings;
use Tobin::IF;
use Clone qw(clone);

@ARGV<3&&die("Too few arguments!");

open(WE,$ARGV[0])||die("Cannot open tf anno!");
my @tab=<WE>;
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
my $exgenes={};
open(WE,$ARGV[2])||die("Cannot open excluded gene list");
@tab=<WE>;
close(WE);
foreach(@tab) {
	chomp;
	$exgenes->{$_}=1;
}

open(WE,$ARGV[1])||die("Cannot open ec anno!");
@tab=<WE>;
close (WE);
my $ecanno={};
my $geannorev={};
foreach(@tab) {
	chomp;
	my @tab1=split(/\t/,$_);
	my $ec=shift(@tab1);
	$ecanno->{$ec}={};
	foreach my $ge (@tab1) {
		defined($exgenes->{$ge})&&next;
		$ecanno->{$ec}->{$ge}=1;
		defined($geannorev->{$ge})||($geannorev->{$ge}={});
		$geannorev->{$ge}->{$ec}=1;
	}
}
my $putec={};
foreach(keys(%{$ecanno})) {
	if(!keys(%{$ecanno->{$_}})) {
		$putec->{$_}=1;
		print($_."\n");
	}
}
foreach(keys(%{$putec})) {
	foreach my $tf (keys(%{$ecannorev->{$_}})) {
		delete($tfanno->{$tf}->{$_});
	}
}
foreach(keys(%{$tfanno})) {
	keys(%{$tfanno->{$_}})||print($_."\n");
}
