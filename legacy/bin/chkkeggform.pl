#!/usr/bin/perl
use strict;
use warnings;
use Tobin::IF;

my $tobin		= new Tobin::IF(1);

for(my $i=1;$i<=9365;$i++) {
	my $links=$tobin->compoundLinksGet($i);
	my $cname=$tobin->compoundNameGet($i);
	if(!defined($links->{'901'})) {
		print("No kegg link for compound $i  - $cname.\n");
	} 
	else {
		my $url="perl -MLWP::Simple -e\'getprint(".
		"\"http://www.genome.jp/dbget-bin/www_bget?compound+".$links->{901}."\")\' |";
#		warn $url;
		open(WE, $url) || die("Problem with webpage.");
		my@page=<WE>;
		close(WE);
		my $end=0;
		for (my $j=0;$j<@page-1;$j++){
			if($page[$j]=~m%<code>Formula</code>%) {
				$end=$j+1;
				last;
			}
		}
		if(!$end) {
			next;
		}
		my $kform={};
		my $katoms=[];
		if(!(@{$katoms}=$page[$end]=~m/([A-Z][a-z]*[0-9]*)/g)) {
			print("Compound: ".$i." - ".$cname." - cannnot find formula on the webpage.\n");
			next;
		}
		my @tatoms=$tobin->compoundFormulaGet($i)=~m/([A-Z][a-z]*[0-9]*)/g;
		my $update=0;
		if(@{$katoms}!=@tatoms) {
			print("Compound: ".$i." - ".$cname." - formulas differ.\n");
			$update=1;
			next;
		}
		my $khash={};
		foreach my $atom (@{$katoms}) {
			$atom=~m/([A-Z][a-z]*)/;
			my $value=$1;
			$khash->{$value}=($atom=~m/([0-9]+)/)?$1:1;
		}
		foreach my $atom (@tatoms) {
			$atom=~m/([A-Z][a-z]*)/;
			my $value=$1;
			if($khash->{$value}!=(($atom=~m/([0-9]+)/)?$1:1)) {
				print("Compound: ".$i." - ".$cname." - formulas differ.\n");
				$update=1;
				last;
			}
		}
		if($update) {
			$page[$end]=~m/(([A-Z][a-z]*[0-9]*)+)/;
			$tobin->compoundFormulaUpdate($i,$1);
		}
		
	}
}
