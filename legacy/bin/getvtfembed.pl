#!/usr/bin/perl -I. -w
use strict;
use warnings;

my $start=$ARGV[1];

while($start<9800) {
	`$ARGV[0] $start $ARGV[2]`;
	open(WE,$ARGV[2]);
	my @tab=<WE>;
	close(WE);
	$start=$tab[@tab-1];
	chomp($start);
	$start+=2;
}

