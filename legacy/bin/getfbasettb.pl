#!/usr/bin/perl -I.
use strict;
use warnings;
use Tobin::IF;
@ARGV||die("Too few arguments");
my $tobin		= new Tobin::IF(1);
my $fbaset=$tobin->fbasetupGet($ARGV[0]);

foreach(@{$fbaset->{TFSET}}) {
	my $tf=$tobin->transformationGet($_->[0]);
	print($_->[0]."\t".$tf->[3]->[0]."\t".$tf->[0]."\n");
}
