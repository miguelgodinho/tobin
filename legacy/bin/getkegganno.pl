#!/usr/bin/perl -I.
use strict;
use warnings;
use Tobin::IF;
my $tobin		= new Tobin::IF(1);

@ARGV||die("Too few arguments!");
open(WE, $ARGV[0])||die("Cannot open reaction list");
my @tab=<WE>;
close(WE);
my $path=@ARGV>1?$ARGV[1]:".";
my $rurl="http://www.genome.jp/dbget-bin/www_bget?rn+";
my $eurl="http://www.genome.jp/dbget-bin/www_bget?enzyme+";
foreach(@tab) {
	chomp;
	$_=~m%^([0-9]+)%;
	my $num=$1;
	my $tf=$tobin->transformationGet($num);
	my $code;
	foreach my $lnk (@{$tf->[1]}) {
		$lnk->{user}==901&&($code=$lnk->{link})&&last;
	}
	defined($code)||print($_."\tno KEGG code\n")&&next;
	if(!open(WE, $path."/".$code.".htm")) {
		`wget -O $path/$code.htm $rurl$code`;
		open(WE, $path."/".$code.".htm")||
		die("Problems with file for reaction $code!");
	}
	my @tab1=<WE>;
	close(WE);
	my @tab2=grep(/enzyme\+/,@tab1);
	@tab2||next;
	my @ecs=($tab2[0]=~/>([0-9]+\.[0-9-]+\.[0-9-]+\.[0-9-]+)</g);
	my $outstr=$_."\t";
	foreach my $ec (@ecs) {
		if(!open(WE, $path."/EC-".$ec.".htm")) {
			`wget -O $path/EC-$ec.htm $eurl$ec`;
			open(WE, $path."/EC-".$ec.".htm")||
			die("Problems with file for ec $ec!");
		}
		@tab1=<WE>;
		close(WE);
		@tab2=grep(/^PPU:/,@tab1);
		my @genes;
		@tab2||next;
		@genes=($tab2[0]=~/>PP_([0-9]{4})</g);
		$outstr.="EC-".$ec."\t";
		foreach my $gene (@genes) {
			$outstr.="PP".$gene.",";
		}
		$outstr=~s/,$//;
		$outstr.="\t";	
	}
	print($outstr."\n");
	
	
}
