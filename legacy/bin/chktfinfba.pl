#!/usr/bin/perl -I. -w
use strict;
use warnings;
use Tobin::IF;

my $tobin	= new Tobin::IF(1);
@ARGV<2&&die("too few arguments!");

open(WE, $ARGV[0])||die("Cannot open reactions list!");
my @tab=<WE>;
close(WE);
my %fba=$tobin->fbaresGet($ARGV[1]);
foreach(@tab) {
	chomp;
	defined($fba{$_})||print("$_\n");
}
