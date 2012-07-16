#!/usr/bin/perl -I.
use strict;
use warnings;
use Tobin::IF;
@ARGV||die("Too few arguments");
my $tobin		= new Tobin::IF(1);
my $fbaset=$tobin->fbasetupGet($ARGV[0]);
my $fpath="/home/jap04/MetabNets/pseudomonasy/ppu-kegg/ppu-kegg/";
my @tab;
my @tab1;
open(WE,"ppu-keggcodes.txt")||die("Cannot open keggcodes");
@tab=<WE>;
close(WE);
my $keggcodes={};
foreach(@tab) {
	chomp;
	@tab1=split(/\t/,$_);
	$keggcodes->{$tab1[0]}= $tab1[1];
}
foreach(@{$fbaset->{TFSET}}) {
	my $tf=$tobin->transformationGet($_->[0]);
	my $link;
	if(defined($keggcodes->{$_->[0]})) {
		$link=$keggcodes->{$_->[0]};
	}
	else {
		foreach my $lnk(@{$tf->[1]}) {
			if($lnk->{user}==901) {
				$link=$lnk->{link};
				last;
			}
		}
	}
	$_->[0]==6875&& warn $link;
	if(defined($link)) {
		if(!open(WE,$fpath.$link.".htm")) {
			`wget -O $fpath$link.htm http://www.genome.jp/dbget-bin/www_bget?rn+$link`;
			open(WE,$fpath.$link.".htm")||
			die("Cannot open reaction $link");
		}
		@tab=<WE>;
		close(WE);
		my @tab1=grep(/www_bget[?]enzyme/,@tab);
		@tab1||(print("Reaction: $_->[0] - no EC\n")&&next);
		my @ecn=($tab1[0]=~/>([0-9]+\.[0-9]+\.[0-9]+\.[0-9\-]+)</g);
		print("Reaction: $_->[0]");
		$_->[0]==6875&& warn @ecn;
		foreach my $ecnum(@ecn) {
			$_->[0]==6875&& warn $ecnum;
			if(!open(WE,$fpath."EC-".$ecnum.".htm")) {
				my $file=$fpath."EC-".$ecnum.".htm";
				`wget -O $file http://www.genome.jp/dbget-bin/www_bget?enzyme+$ecnum`;
				open(WE,$fpath."EC-".$ecnum.".htm")||
				die("Cannot open enzyme file $ecnum");
			}
			@tab=<WE>;
			close(WE);
			@tab1=grep(/^PPU:/,@tab);
			print("\tEC: $ecnum\t");
			if(@tab1) {
				my @genes=($tab1[0]=~m/>PP_([0-9]{4})</g);
				foreach my $gene(@genes) {
					print(" PP$gene");
				}
			}
			elsif($ecnum=~/[0-9]+\.[0-9]+\.[0-9]+\.\-/) {
				if(!open(WE,$fpath."link-EC-".$ecnum.".htm")) {
					my $linukurl="perl -MLWP::Simple -e\'getprint(".
					"\"http://www.genome.ad.jp/dbget-bin/get_linkdb?enzyme+".
					$ecnum."\")\' |";
					open(WE1,$linukurl)||die("Cannot get dblink.");
					@tab=<WE1>;
					close(WE1);
					my @linkstab=grep(/>PPU/,@tab);
					@linkstab||warn $ecnum;
					$linkstab[0]=~/HREF=([^>]*)>/||next;
					my $linkfile=$fpath."link-EC-".$ecnum.".htm";
					`wget -O $linkfile http://www.genome.jp/$1`;
					open(WE,$fpath."link-EC-".$ecnum.".htm")||die("Cannot get linkfile");
				}
				@tab=<WE>;
				close(WE);
				@tab1=grep(/>PP_[0-9]{4}</,@tab);
				foreach my $gene (@tab1) {
					$gene=~/>PP_([0-9]{4})</;
					print(" PP$1");
				}
			}
		}
		print("\n");
	}
}
