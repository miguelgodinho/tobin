#!/usr/bin/perl
use strict;
use warnings;

@ARGV<2&&die("Too few arguments.");
#print(@ARGV."\n");
my $summary={};
open(WE, "glist.txt")||die("Cannot open gene list.");
my @glist=<WE>;
close(WE);
foreach(@glist) {
	chomp($_);
	$summary->{$_}=0;
}
my $length=0;
for(my $i=1;$i<@ARGV;$i++) {
	open(WE,$ARGV[$i])||die("Cannot open file $ARGV[$i].");
	my @data=<WE>;
	close(WE);
	$length+=@data;
	foreach(@data) {
		chomp($_);
		my @genes=split(/\t/,$_);
		foreach my $gene(@genes) {
			if(!defined($summary->{$gene})) {
				die("Unknown gene.");
			}
			$summary->{$gene}++;
		}
	}
}
open(WY, ">".$ARGV[0]);
foreach(keys(%{$summary})) {
	print(WY $_."\t".$summary->{$_}/$length."\n");
}
close(WY);
