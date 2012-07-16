#!/usr/bin/perl -I.

use strict;
use warnings;
use Tobin::IF;

my $tobin		= new Tobin::IF(1);

my $keggcodes={};
open(WE,$ARGV[1])||die("Cannot open codes list");
my @tab=<WE>;
close(WE);
foreach(@tab) {
	chomp;
	my @tab1=split(/\t/,$_);
	$keggcodes->{$tab1[0]}=$tab1[1];
}
my $tocheck={};
open(WE, $ARGV[0])||die("Cannot open input file");
@tab=<WE>;
close(WE);
foreach(@tab) {
	chomp;
	if(defined($keggcodes->{$_})) {
		$tocheck->{$keggcodes->{$_}}=1;
	}
	else {
		my $link;
		my $tf=$tobin->transformationGet($_);
		foreach my $lnk(@{$tf->[1]}) {
			if($lnk->{user}==901) {
				$link=$lnk->{link};
				last;
			}
		}
		defined($link)?($tocheck->{$link}=1):warn("No kegg link for $_");
	}
}
my $path="/home/jap04/MetabNets/pseudomonasy/ppu-kegg/ppu-kegg/";
foreach(keys(%{$tocheck})) {
	if(!open(WE,$path.$_.".htm")) {
		my $url1="\"http://www.genome.jp/dbget-bin/www_bget?rn:".$_."\"";
		`wget -O $path$_.htm $url1`;
		open(WE,$path.$_.".htm")||die("Cannot download file for $_")||
		die("Problem with reaction $_");
	}
	@tab=<WE>;
	close(WE);
	print("\n".$_);
	my @tab1=grep(m%Enzyme%...m%</tr>%,@tab);
	defined($tab1[1])||next;
	my @EC=($tab1[1]=~/>([0-9]\.[0-9]+\.[0-9-]+\.[0-9-]+)</);
	foreach my $ecnum(@EC) {
		if(!open(WE,$path."EC-".$ecnum.".htm")) {
			my $file=$path."EC-".$ecnum.".htm";
			`wget -O $file http://www.genome.jp/dbget-bin/www_bget?enzyme+$ecnum`;
			open(WE,$path."EC-".$ecnum.".htm")||
				die("Cannot open enzyme file $ecnum");
		}
		@tab1=<WE>;
		close(WE);
		my @genes=grep(/^PAE/,@tab1);
		print("\t$ecnum");
		if(defined($genes[0])) {
			my @genes1=($genes[0]=~/>(PA[0-9]{4})</);
			print("\t");
			foreach my $gene (@genes1) {
				print($gene.",");
			}
		}
	}
}
print("\n");		
