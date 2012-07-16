#!/usr/bin/perl -I. -w
use strict;
use warnings;

@ARGV<3&&die("too few arguments");
open(WE,$ARGV[0])||die("Cannot open input file");
my @tfset=<WE>;
close(WE);
open(WE,$ARGV[1])||die("Cannot open fcf file");
my @tab=<WE>;
close(WE);
my @tab1=grep(/^Fully/../^Partially/,@tab);
my $nodehash={};
for(1..(@tab1-2)) {
	chomp($tab1[$_]);
	my @tab2=split(/: /,$tab1[$_]);
	my @tab3=split(/, /,$tab2[1]);
	$tab2[0]==67&&warn(@tab3." ");
	foreach my $tf (@tab3) {
		$nodehash->{$tf}=$tab2[0];
		$tab2[0]==67&&warn "bbb".$tf."aaa";
	}
}
@tab1=grep(/^Partially/../^digraph/,@tab);
for(1..(@tab1-2)) {
	chomp($tab1[$_]);
	my @tab2=split(/: /,$tab1[$_]);
	my @tab3=split(/, /,$tab2[1]);
	foreach my $tf (@tab3) {
		$nodehash->{$tf}=$tab2[0];
	}
}
warn(defined($nodehash->{3001}));
open(WE, $ARGV[2])||die("Cannot open reversibles file");
@tab=<WE>;
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

my $coupled={};
my $uncoupled={};
foreach(@tfset) {
	chomp;
	my $clust;
	if(defined($nodehash->{$_})) {
		$clust=$nodehash->{$_};
	}
	elsif(defined($revhash->{$_})&&defined($nodehash->{$revhash->{$_}})) {
		$clust=$nodehash->{$revhash->{$_}};
	}
	else {
		$uncoupled->{$_}=1;
	}
	if(defined($clust)) {
		defined($coupled->{$clust})||($coupled->{$clust}={});
		$coupled->{$clust}->{$_}=1;
	}
}
foreach(keys(%{$coupled})) {
	my $str=$_."\t";
	foreach my $tf(keys(%{$coupled->{$_}})) {
		$str.=$tf.", ";
	}
	$str=~s/, $//;
	print($str."\n");
	
}
foreach(keys(%{$uncoupled})) {
	print($_."\n");
}
