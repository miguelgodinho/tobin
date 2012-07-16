#!/usr/bin/perl -I. -w
use strict;
use warnings;
use Tobin::IF;

my $tobin=new Tobin::IF(1);

for(my $i=$ARGV[0];$i<$ARGV[1];$i++) {
	$tobin->transformationDelete($i);
}
