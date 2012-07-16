#!/usr/bin/perl -I.. -w
use strict;
use warnings;

open(WE, $ARGV[2])||die("Cannot open HCF file!");
my @tab=<WE>;
close(WE);
my $hcfhash={};
foreach(@tab) {
	chomp;
	$hcfhash->{$_}=1;
}
open(WE, $ARGV[0])||die("Cannot open complex annotation file!");
@tab=<WE>;
close(WE);
my $cphash={};
foreach(@tab) {
	chomp;
	my @tab1=split(/\t/,$_);
	for my $i (2..(@tab1-1)) {
		!$tab1[0]&&defined($hcfhash->{$tab1[$i]})&&next;
		defined($cphash->{$tab1[1]})||($cphash->{$tab1[1]}=[]);
		push(@{$cphash->{$tab1[1]}},$tab1[$i]);
	}
}

open(WE, $ARGV[1])||die("Cannot open ec annotation file");
@tab=<WE>;
close(WE);
my $echash={};
foreach(@tab) {
	chomp;
	my @tab1=split(/\t/,$_);
	for my $i(2..(@tab1-1)) {
		defined($cphash->{$tab1[$i]})||length($tab1[1])||next;
		defined($echash->{$tab1[0]})||($echash->{$tab1[0]}=[]);
		push(@{$echash->{$tab1[0]}},$tab1[$i]);
	}
}

foreach(keys(%{$cphash})) {
	print($_);
	foreach my $el (@{$cphash->{$_}}) {
		print("\t$el");
	}
	print("\n");
}

foreach(keys(%{$echash})) {
	print($_);
	foreach my $el (@{$echash->{$_}}) {
		print("\t$el");
	}
	print("\n");
}
