#!/usr/bin/perl -I. -w
use strict;
use warnings;
use Tobin::IF;

my $tobin=new Tobin::IF(1);
@ARGV||die("TF number missing");
my $tf=$tobin->transformationGet($ARGV[0]);

foreach(@{$tf->[2]}) {
	print($_->{ext}."\t".$_->{id}."\t".$_->{sto}."\n");
}
