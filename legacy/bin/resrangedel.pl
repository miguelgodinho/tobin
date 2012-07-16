#!/usr/bin/perl -I. -w
use strict;
use warnings;
use Tobin::IF;
@ARGV<3&&die("Too few arguments");
my $tobin	= new Tobin::IF($ARGV[0]);
for(my $i=$ARGV[1];$i<$ARGV[2];$i++) {
	$tobin->fbaresultExists($i)&&$tobin->fbaresultDelete($i);
}
