#!/usr/bin/perl -w -I../pseudo2/
use strict;
use warnings;
use Tobin::IF;

my $tobin=new Tobin::IF(1);


open(WE,$ARGV[0])||die("Cannot open compound list");
my @tab=<WE>;
close(WE);
my $errors=[];
foreach(@tab) {
	chomp;
	my @tab1=split(/\t/,$_);
	$tobin->compoundAdd([$tab1[3]],[{link=>$tab1[0],user=>1004}],$tab1[1],$tab1[2],$errors);
}
