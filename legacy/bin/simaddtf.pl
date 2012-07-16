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
foreach(@tab) {
	chomp;
	push(@{$fbasetup->{TFSET}},[$_,0,0,undef]);
}
if($tobin->fbasetupUpdate($ARGV[1],undef,$fbasetup->{TFSET},undef)) {
 			die("Problem updating database.");
}
