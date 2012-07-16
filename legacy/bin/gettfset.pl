#!/usr/bin/perl -I. -w
use strict;
use warnings;
use Tobin::IF;

my $tobin=new Tobin::IF(1);
my $set=$tobin->transformationsetGet($ARGV[0]);

foreach(@{$set->{TRANS}}) {
	print($_."\n");
}
