#!/usr/bin/perl -I. -w
use strict;
use warnings;

@ARGV<2&&die("Too few arguments");
my $uselist=0;
my $fcflist={};
if($ARGV[0]) {
	$uselist=1;
	open(WE,$ARGV[0])||die("Cannot open set list");
	my @tab=<WE>;
	close(WE);
	foreach(@tab) {
		chomp;
		$fcflist->{$_}=1;
	}
}
open(WE,$ARGV[1])||die("Cannot open results file");
my @tab=<WE>;
close(WE);
my $fcoupled1={};
my $nodehash1={};
my @tab1=grep(/^Fully/../^Partially/,@tab);
for(1..(@tab1-2)) {
	chomp($tab1[$_]);
	my @tab2=split(/: /,$tab1[$_]);
	$uselist&&!defined($fcflist->{$tab2[2]})&&next;
	my @tab3=split(/, /,$tab2[1]);
	$fcoupled1->{$tab2[0]}={};
	foreach my $tf (@tab3) {
		$nodehash1->{$tf}=$tab2[0];
		$fcoupled1->{$tab2[0]}->{$tf}=1;
	}
}
@tab1=grep(/^Partially/../^digraph/,@tab);
for(1..(@tab1-2)) {
	chomp($tab1[$_]);
	my @tab2=split(/: /,$tab1[$_]);
	$uselist&&!defined($fcflist->{$tab2[2]})&&next;
	my @tab3=split(/, /,$tab2[1]);
	defined($fcoupled1->{$tab2[0]})||($fcoupled1->{$tab2[0]}={});
	foreach my $tf (@tab3) {
		$nodehash1->{$tf}=$tab2[0];
		$fcoupled1->{$tab2[0]}->{$tf}=1;
	}
}

open(WE, $ARGV[2])||die("Cannot open reaction mapping");
@tab=<WE>;
close(WE);
my $pathhash={};
foreach(@tab) {
	chomp;
	my @tab1=split(/\t/,$_);
	$pathhash->{$tab1[0]}=[];
	for my $i(1..(@tab1-1)) {
		push(@{$pathhash->{$tab1[0]}},$tab1[$i]);
	}
}
foreach(keys(%{$fcoupled1})) {
	print($_.":\n");
	foreach my $tf (keys(%{$fcoupled1->{$_}})) {
		my $str=$tf;
		foreach my $path(@{$pathhash->{$tf}}) {
			$str.="\t".$path;
		}
		print($str."\n");
	}
}

