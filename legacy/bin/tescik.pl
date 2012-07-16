#!/usr/bin/perl
#
#


use strict;
use warnings;

my $tab1=[1,2,3,4];
my $tab2=[5,6,7,8];
push(@{$tab1},@{$tab2});
print(@{$tab1}."\n");
