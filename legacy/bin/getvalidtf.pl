#!/usr/bin/perl -I. -w
use strict;
use warnings;
use Tobin::IF;

my $tobin		= new Tobin::IF(1);
open(WY,">>".$ARGV[1]);
for(my $i=$ARGV[0];$i<9800;$i++) {
	my $tf=$tobin->transformationGet($i);
	syswrite(WY, $i."\n");
}
close(WY);
