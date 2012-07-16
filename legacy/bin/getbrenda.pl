#!/usr/bin/perl -w
use strict;
use warnings;

@ARGV<2&&die("Too few arguments");

open(WE,$ARGV[0])||die("Cannot open input file");
my @tab=<WE>;
close(WE);
my $echash={};
foreach(@tab) {
	chomp;
	$echash->{$_}=1;
}
print(keys(%{$echash})."\n");
my $url1="http://www.brenda.uni-koeln.de/php/flat_result.php4?ecno=";
my $url2="&organism_list=&Suchword=";
foreach(keys(%{$echash})) {
	my $url=$url1.$_.$url2;
	`wget -O $ARGV[1]/$_.htm "$url"`;
	sleep 5;
}
