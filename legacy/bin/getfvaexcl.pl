#!/usr/bin/perl -I. -w
use strict;
use warnings;
use Tobin::IF;
 @ARGV||die("Too few arguments.");
 my $tobin	= new Tobin::IF(1);
my $fbaset=$tobin->fbasetupGet($ARGV[0]);
my $excluded={};
foreach(@{$fbaset->{TFSET}}) {
	my $tf=$tobin->transformationGet($_->[0]);
	($tf->[3]->[0]=~/^SINK|^SOURCE|joining|multiplication|^Biomass|^power/)&&
	($excluded->{$_->[0]}=1);
}
foreach(keys(%{$excluded})) {
	print($_."\n");
}
