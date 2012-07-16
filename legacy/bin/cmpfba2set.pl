#!/usr/bin/perl -I. -w
use strict;
use warnings;
use Tobin::IF;
use vdsxls::readvds;

@ARGV<2&&die("too few arguments");
my $tobin		= new Tobin::IF(1);
my $fbaset=$tobin->fbasetupGet($ARGV[0]);
my $tfset=$tobin->transformationsetGet($ARGV[1]);
my $fbahash={};
foreach(@{$fbaset->{TFSET}}) {
	$fbahash->{$_->[0]}=1;
}
my $tfhash={};
foreach(@{$tfset->{TRANS}}) {
	$tfhash->{$_}=1;
}
print("Present in first - not present in second:\n");
foreach(keys(%{$fbahash})) {
	defined($tfhash->{$_})||print("$_ - ".$tobin->transformationNameGet($_)."\n");
}
print("Present in second - not present in first:\n");
foreach(@{$tfset->{TRANS}}) {
	defined($fbahash->{$_})||print("$_- ".$tobin->transformationNameGet($_)."\n");
}
