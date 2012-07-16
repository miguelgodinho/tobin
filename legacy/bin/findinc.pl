#!/usr/bin/perl

use strict;
use warnings;

open(INP, "./rdvds2.txt");
my @data=<INP>;
close(INP);
open(INC, "./inclist1.txt");
my @inclist=<INC>;
close(INC);

my $inpstring="";

foreach my $key (@inclist) {
	foreach (@data) {
		if(/^$key/../^\n/) {
			print;
		}
	}
}
