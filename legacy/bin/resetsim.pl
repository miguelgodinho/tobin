#!/usr/bin/perl
use strict;
use warnings;
use Tobin::IF;


@ARGV<2&&exit;
my $tobin		= new Tobin::IF($ARGV[0]);
my $fbasetup=$tobin->fbasetupGet($ARGV[1]);
foreach(@{$fbasetup->{TFSET}}) {
	$_->[2]=0;
	$_->[3]=undef;
}
$tobin->fbasetupUpdate($ARGV[1],undef,$fbasetup->{TFSET},undef)&&
die("Cannot update FBA setup.");
