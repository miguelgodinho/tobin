#!/usr/bin/perl -I. -w
use strict;
use warnings;
use Tobin::IF;
@ARGV<3&&die("Too few arguments.");

my $tobin		= new Tobin::IF($ARGV[0]);
my $fbasetup=$tobin->fbasetupGet($ARGV[1]);
open(WE,$ARGV[2])||die("Cannot open rection list");
my @tab=<WE>;
close(WE);
my $delhash={};
foreach(@tab) {
	chomp;
	$delhash->{$_}=1;
}
my $tfset=[];
foreach(@{$fbasetup->{TFSET}}) {
	defined($delhash->{$_->[0]})||
	push(@{$tfset},$_);
}
if($tobin->fbasetupUpdate($ARGV[1],undef,$tfset,undef)) {
 			die("Problem updating database.");
}
