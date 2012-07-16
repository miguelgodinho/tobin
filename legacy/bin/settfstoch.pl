#!/usr/bin/perl -I. -w
use strict;
use warnings;
use Tobin::IF;

@ARGV<2&&die("Too few arguments");
my $tobin=new Tobin::IF(1);
my $tf=$tobin->transformationGet($ARGV[0]);

open(WE, $ARGV[1])||di("Cannot open input file");
my @tab=<WE>;
close(WE);
my $newstoch=[{},{}];
foreach(@tab) {
	chomp;
	my @tab1=split(/\t/,$_);
	$newstoch->[$tab1[0]]->{$tab1[1]}=$tab1[2];
}
foreach (@{$tf->[2]}) {
	defined($newstoch->[$_->{ext}]->{$_->{id}})&&
	($_->{sto}=$newstoch->[$_->{ext}]->{$_->{id}});
}
my $errors=[];
$tobin->transformationModify($ARGV[0],undef,undef,$tf->[2],undef,$errors);
