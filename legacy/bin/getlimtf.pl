#!/usr/bin/perl -I. -w
use strict;
use warnings;
use Tobin::IF;
@ARGV||die("Too few arguments.");
my $tobin		= new Tobin::IF(1);
 my $fbasetup=$tobin->fbasetupGet($ARGV[0]);
 print("TOP:\n");
 foreach(@{$fbasetup->{TFSET}}) {
 	if(defined($_->[3])) {
 		print($_->[0]."\t".$tobin->transformationGet($_->[0])->[3]->[0]."\t".$_->[3]."\n");
 	}
 }
 print("BOTTOM:\n");
 foreach(@{$fbasetup->{TFSET}}) {
 	if($_->[2]!=0) {
 		print($_->[0]."\t".$tobin->transformationGet($_->[0])->[3]->[0]."\t".$_->[2]."\n");
 	}
 }
