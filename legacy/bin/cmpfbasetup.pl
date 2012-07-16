#!/usr/bin/perl -I.
use strict;
use warnings;
use Tobin::IF;
use vdsxls::readvds;

@ARGV<2&&die("too few arguments");
my $tobin		= new Tobin::IF(1);
my $fbaset1=$tobin->fbasetupGet($ARGV[0]);
my $fbaset2=$tobin->fbasetupGet($ARGV[1]);
my $fbahash1={};
my $fbahash2={};
foreach(@{$fbaset1->{TFSET}}) {
	$fbahash1->{$_->[0]}=1;
}
foreach(@{$fbaset2->{TFSET}}) {
	$fbahash2->{$_->[0]}=1;
}

print("Present in first - not present in second:\n");
foreach(keys(%{$fbahash1})) {
	defined($fbahash2->{$_})||print("$_ - ".$tobin->transformationNameGet($_)."\n");
}
print("Present in second - not present in first:\n");
foreach(keys(%{$fbahash2})) {
	defined($fbahash1->{$_})||print("$_- ".$tobin->transformationNameGet($_)."\n");
}
