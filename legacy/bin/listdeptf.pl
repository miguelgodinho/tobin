#!/usr/bin/perl -I. -w
use strict;
use warnings;
use Tobin::IF;
use Clone qw(clone);

@ARGV<4&&die("Too few arguments!");


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
my $cpanno={};
my $geannorev={};
open(WE,$ARGV[2])||die("Cannot open cp anno!");
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
		defined($geannorev->{$ge})||($geannorev->{$ge}={});
		$geannorev->{$ge}->{$cp}=1;
	}
}
open(WE,$ARGV[1])||die("Cannot open ec anno!");
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
open(WE,$ARGV[4])||die("Cannot open reaction list");
@tab=<WE>;
close(WE);
my $tfhash={};
foreach(@tab) {
	chomp;
	$tfhash->{$_}=1;
}
open(WE,$ARGV[3])||die("Cannot open deletions list");
@tab=<WE>;
close(WE);

foreach(@tab) {
	chomp;
	my $str=$_;
	foreach my $cp (keys(%{$geannorev->{$_}})) {
		foreach my $ec (keys(%{$cpannorev->{$cp}})) {
			foreach my $tf (keys(%{$ecannorev->{$ec}})) {
				defined($tfhash->{$tf})&&($str.="\t".$tf);
			}
		}
	}
	print($str."\n");
}
