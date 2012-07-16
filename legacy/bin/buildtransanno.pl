#!/usr/bin/perl -I. -w
use strict;
use warnings;

open(WE, $ARGV[0])||die("Cannot open input file");
my @tab=<WE>;
close(WE);

my $tfanno={};
my $tcanno={};
foreach(@tab) {
	chomp;
	my @tab1=split(/\t/,$_);
	if($tab1[2]=~/,/) {
		my @tab2=split(/,/,$tab1[2]);
		foreach my $tf (@tab2) {
			defined($tfanno->{$tf})||($tfanno->{$tf}={});
			$tfanno->{$tf}->{$tab1[1]}=1;
		}
	}
	else {
		defined($tfanno->{$tab1[2]})||($tfanno->{$tab1[2]}={});
		$tfanno->{$tab1[2]}->{$tab1[1]}=1;
	}
	defined($tcanno->{$tab1[1]})||($tcanno->{$tab1[1]}=[]);
	push(@{$tcanno->{$tab1[1]}},$tab1[0]);
}
foreach(keys(%{$tfanno})) {
	my $str=$_;
	foreach my $tc (keys(%{$tfanno->{$_}})) {
		$str.="\t".$tc;
	}
	print($str."\n");
}
print("\n");
foreach(keys(%{$tcanno})) {
	my $str=$_;
	foreach my $ge (sort(@{$tcanno->{$_}})) {
		$str.="\t".$ge;
	}
	print($str."\n");
}
