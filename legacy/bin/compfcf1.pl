#!/usr/bin/perl -I. -w
use strict;
use warnings;

@ARGV<2&&die("Too few arguments");
open(WE,$ARGV[1])||die("Cannot open first excluded file");
my @tab=<WE>;
close(WE);
my $excluded1={};
foreach(@tab) {
	chomp;
	$excluded1->{$_}=1;
}
open(WE,$ARGV[0])||die("Cannot open first input file");
@tab=<WE>;
close(WE);

my $fcoupled1={};
my $nodehash1={};
my @tab1=grep(/^Fully/../^Partially/,@tab);
for(1..(@tab1-2)) {
	chomp($tab1[$_]);
	my @tab2=split(/: /,$tab1[$_]);
	my @tab3=split(/, /,$tab2[1]);
	$fcoupled1->{$tab2[0]}={};
	foreach my $tf (@tab3) {
		defined($excluded1->{$tf})&&next;
		$nodehash1->{$tf}=$tab2[0];
		$fcoupled1->{$tab2[0]}->{$tf}=1;
	}
}
@tab1=grep(/^Partially/../^digraph/,@tab);
for(1..(@tab1-2)) {
	chomp($tab1[$_]);
	my @tab2=split(/: /,$tab1[$_]);
	my @tab3=split(/, /,$tab2[1]);
	defined($fcoupled1->{$tab2[0]})||($fcoupled1->{$tab2[0]}={});
	foreach my $tf (@tab3) {
		$nodehash1->{$tf}=$tab2[0];
		$fcoupled1->{$tab2[0]}->{$tf}=1;
	}
}

open(WE,$ARGV[3])||die("Cannot open second excluded file");
@tab=<WE>;
close(WE);
my $excluded2={};
foreach(@tab) {
	chomp;
	$excluded2->{$_}=1;
}

open(WE,$ARGV[2])||die("Cannot open second input file");
@tab=<WE>;
close(WE);

my $fcoupled2={};
my $nodehash2={};
@tab1=grep(/^Fully/../^Partially/,@tab);
for(1..(@tab1-2)) {
	chomp($tab1[$_]);
	my @tab2=split(/: /,$tab1[$_]);
	my @tab3=split(/, /,$tab2[1]);
	$fcoupled2->{$tab2[0]}={};
	foreach my $tf (@tab3) {
		defined($excluded2->{$tf})&&next;
		$nodehash2->{$tf}=$tab2[0];
		$fcoupled2->{$tab2[0]}->{$tf}=1;
	}
}
@tab1=grep(/^Partially/../^digraph/,@tab);
for(1..(@tab1-2)) {
	chomp($tab1[$_]);
	my @tab2=split(/: /,$tab1[$_]);
	my @tab3=split(/, /,$tab2[1]);
	defined($fcoupled2->{$tab2[0]})||($fcoupled2->{$tab2[0]}={});
	foreach my $tf (@tab3) {
		$nodehash2->{$tf}=$tab2[0];
		$fcoupled2->{$tab2[0]}->{$tf}=1;
	}
}

my $cmap={};
my $assigned1={};
my $assigned2={};
foreach(keys(%{$fcoupled1})) {
	my $cmap1={};
	foreach my $tf (keys(%{$fcoupled1->{$_}})) {
#		$_==24&&warn($nodehash2->{$tf});
		if(defined($nodehash2->{$tf})) {
			defined($cmap1->{$nodehash2->{$tf}})||($cmap1->{$nodehash2->{$tf}}=0);
			$cmap1->{$nodehash2->{$tf}}++;
		}
		else {
			defined($cmap1->{0})||($cmap1->{0}=0);
			$cmap1->{0}++;
		}
	}
	if(keys(%{$cmap1})==1&&(keys(%{$cmap1}))[0]) {
		if(keys(%{$fcoupled1->{$_}})==keys(%{$fcoupled2->{(keys(%{$cmap1}))[0]}})) {
			$assigned2->{(keys(%{$cmap1}))[0]}=1;
			$assigned1->{$_}=1;
			$cmap->{$_}=(keys(%{$cmap1}))[0];
			print($_." equal to ".(keys(%{$cmap1}))[0]."\n");
		}
		else {
			print($_." subset of ".(keys(%{$cmap1}))[0]."\n");
			$assigned1->{$_}=1;
			$assigned2->{(keys(%{$cmap1}))[0]}=1;
		}
		
	}
}
foreach(keys(%{$fcoupled2})) {
	defined($assigned2->{$_})&&next;
	my $cmap1={};
	foreach my $tf (keys(%{$fcoupled2->{$_}})) {
#		$_==24&&warn($nodehash2->{$tf});
		if(defined($nodehash1->{$tf})) {
			defined($cmap1->{$nodehash1->{$tf}})||($cmap1->{$nodehash1->{$tf}}=0);
			$cmap1->{$nodehash1->{$tf}}++;
		}
		else {
			defined($cmap1->{0})||($cmap1->{0}=0);
			$cmap1->{0}++;
		}
	}
	if(keys(%{$cmap1})==1&&(keys(%{$cmap1}))[0]) {
			print((keys(%{$cmap1}))[0]." superset of ".$_."\n");
			$assigned2->{$_}=1;
			$assigned1->{(keys(%{$cmap1}))[0]}=1;
	}
}
print("Unassigned - first:\n");
foreach(keys(%{$fcoupled1})) {
	defined($assigned1->{$_})&&next;
	print($_."\n");
}
print("Unassigned - second:\n");
foreach(keys(%{$fcoupled2})) {
	defined($assigned2->{$_})&&next;
	print($_."\n");
}

