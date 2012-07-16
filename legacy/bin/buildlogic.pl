#!/usr/bin/perl -I. -w
use strict;
use warnings;

my $putgenes={};
open(WE,$ARGV[1])||die("Cannot open putative genes list");
my @tab=<WE>;
close(WE);
foreach(@tab) {
	chomp;
	$putgenes->{$_}=1;
}
my $subunits={};
open(WE,$ARGV[2])||die("Cannot open subunits list");
@tab=<WE>;
close(WE);
foreach(@tab) {
	chomp;
	$subunits->{$_}=1;
}
my $logicfull={};
my $logicsure={};
open(WE,$ARGV[0])||die("Cannot open ec anno!");
@tab=<WE>;
close (WE);
foreach(@tab) {
	chomp;
	my @tab1=split(/\t/,$_);
	my $ec=shift(@tab1);
	$logicfull->{$ec}={OR=>{},AND=>{}};
	$logicsure->{$ec}={OR=>{},AND=>{}};
	foreach my $ge (@tab1) {
		$logicfull->{$ec}->{defined($subunits->{$ge})?"AND":"OR"}->{$ge}=1;
		defined($putgenes->{$ge})&&next;
		$logicsure->{$ec}->{defined($subunits->{$ge})?"AND":"OR"}->{$ge}=1;
	}
}
print("Full\n");
foreach(keys(%{$logicfull})) {
	print($_);
	if(keys(%{$logicfull->{$_}->{"AND"}})) {
		my $str="\tAND";
		foreach my $ge(keys(%{$logicfull->{$_}->{"AND"}})) {
			$str.="\t".$ge;
		}
		print($str);
	}
	
	if(keys(%{$logicfull->{$_}->{"OR"}})) {
		my $str="\tOR";
		foreach my $ge(keys(%{$logicfull->{$_}->{"OR"}})) {
			$str.="\t".$ge;
		}
		print($str);
	}
	print("\n");
}
print("Sure\n");
foreach(keys(%{$logicsure})) {
	print($_);
	if(keys(%{$logicsure->{$_}->{"AND"}})) {
		my $str="\tAND";
		foreach my $ge(keys(%{$logicsure->{$_}->{"AND"}})) {
			$str.="\t".$ge;
		}
		print($str);
	}
	
	if(keys(%{$logicsure->{$_}->{"OR"}})) {
		my $str="\tOR";
		foreach my $ge(keys(%{$logicsure->{$_}->{"OR"}})) {
			$str.="\t".$ge;
		}
		print($str);
	}
	print("\n");
}
