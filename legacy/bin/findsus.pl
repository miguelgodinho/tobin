#!/usr/bin/perl -I. -w
use strict;
use warnings;
use Tobin::IF;
my $tobin	= new Tobin::IF(1);
my %fba1=$tobin->fbaresGet($ARGV[0]);
my %fba2=$tobin->fbaresGet($ARGV[1]);
open(WE, "balrea.txt");
my @rlist=<WE>;
close(WE);
my $rhash={};
foreach(@rlist) {
	chomp($_);
	my @dat=split(/\t/,$_);
	defined($rhash->{$dat[0]})||($rhash->{$dat[0]}=$dat[1]);
}

foreach(keys(%{$rhash})) {
	defined($fba1{$_})&&defined($fba2{$_})&&($fba1{$_}||$fba2{$_})&&
	print("$_\t".$fba1{$_}."\t".($fba1{$_}*$rhash->{$_}).
	"\t".$fba2{$_}."\t".($fba2{$_}*$rhash->{$_})."\n");
}
