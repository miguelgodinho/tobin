#!/usr/bin/perl -I. -w
use strict;
use warnings;

open(WE,$ARGV[0])||die("Cannot open input file");
my @tab=<WE>;
close(WE);
foreach(@tab) {
	chomp;
	my @tab1=split(/\t/,$_);
	my $str=shift(@tab1)."\t";
	my $pathhash={};
	foreach my $ec(@tab1) {
		$ec=~/^EC-[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/||next;
		if(!open(WE,"/home/jap04/MetabNets/pseudomonasy/ppu-kegg/ppu-kegg/".$ec.".htm")) {
			my $rurl="http://www.genome.jp/dbget-bin/www_bget?enzyme+";
			my $ecnum=substr($ec,3);
		 	`wget -O /home/jap04/MetabNets/pseudomonasy/ppu-kegg/ppu-kegg/$ec.htm $rurl$ecnum`;
		 	open(WE,"/home/jap04/MetabNets/pseudomonasy/ppu-kegg/ppu-kegg/".$ec.".htm")||
		 	next;
		}
		my @tab2=<WE>;
		close(WE);
		my @tab3=grep(/PATH:/,@tab2);
		foreach my $line(@tab3) {
			$line=~m%map([0-9]{5})</a>\&nbsp;\&nbsp;([^<]*)<%;
			$pathhash->{$2}=1;
		}
	}
	foreach my $path (keys(%{$pathhash})) {
		$str.=$path.",";
	}
	chop($str);
	print($str."\n");
}
