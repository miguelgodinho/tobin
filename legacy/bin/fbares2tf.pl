#!/usr/bin/perl -I. -w
use strict;
use warnings;
use Tobin::IF;

my $tobin=new Tobin::IF(1);

my %fbares=$tobin->fbaresGet($ARGV[0]);

$tobin= new Tobin::IF($ARGV[1]);
my $tf=[];
foreach(keys(%fbares)) {
	push(@{$tf},$_);
}

$tobin->transformationsetCreate($ARGV[2],$tf);
