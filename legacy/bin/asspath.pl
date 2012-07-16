#!/usr/bin/perl -I. -w
use strict;
use warnings;
use Tobin::IF;

open(WE, $ARGV[4])||die("Cannot open reaction mapping");
my @tab=<WE>;
close(WE);
my $tfhash={};
my $pathhash={};
my $pathlist={};
foreach(@tab) {
	chomp;
	my @tab1=split(/\t/,$_);
	$tab1[1]||next;
	if($tab1[0]=~m%/%) {
		my @tab2=split(m%/%,$tab1[0]);
		$tfhash->{$tab2[0]}=$tab1[1];
		$tfhash->{$tab2[1]}=$tab1[1];	
	}
	else {
		$tfhash->{$tab1[0]}=$tab1[1];
	}
	defined($pathhash->{$tab1[1]})&&next;
	if(!open(WE,"/home/jap04/MetabNets/pseudomonasy/ppu-kegg/ppu-kegg/".$tab1[1].".htm")) {
		my $rurl="http://www.genome.jp/dbget-bin/www_bget?rn+";
		 `wget -O /home/jap04/MetabNets/pseudomonasy/ppu-kegg/ppu-kegg/$tab1[1].htm $rurl$tab1[1]`;
		 open(WE,"/home/jap04/MetabNets/pseudomonasy/ppu-kegg/ppu-kegg/".$tab1[1].".htm")||
		 die("Cannot open reaction file for $tab1[1]");
	 }
	my @tab2=<WE>;
	my @tab3=grep(/PATH:/,@tab2);
	foreach my $line(@tab3) {
		$line=~m%rn([0-9]{5})</a>\&nbsp;\&nbsp;([^<]*)<%;
		defined($pathhash->{$tab1[1]})||($pathhash->{$tab1[1]}=[]);
		push(@{$pathhash->{$tab1[1]}},$2);
		$pathlist->{$2}=$1;

	}

}
#
#foreach(values(%{$pathhash})) {
#	foreach my $path (@{$_}) {
#		$pathlist->{$path}=1;
#	}
#}
foreach(keys(%{$pathlist})) {
	print($_."\t".$pathlist->{$_}."\n");
}
exit;
open(WE, $ARGV[2])||die("Cannot open reversibles file");
@tab=<WE>;
close(WE);
my $revhash={};
foreach(@tab) {
	chomp;
	my @tab1=split(/\t/,$_);
	(defined($revhash->{$tab1[0]})||defined($revhash->{$tab1[1]}))&&
	die("Problem with reversibles.");
	$revhash->{$tab1[0]}=$tab1[1];
	$revhash->{$tab1[1]}=$tab1[0];
}
open(WE, $ARGV[3])||die("Cannot open excluded rections file");
@tab=<WE>;
close(WE);
my $excluded={};
foreach(@tab) {
	chomp;
	$excluded->{$_}=1;
}
my $tflist=[];
if($ARGV[0]) {
	open(WE,$ARGV[1])||die("Cannot open input file");
	@tab=<WE>;
	close(WE);
	foreach(@tab) {
		chomp;
		push(@{$tflist},$_);
	}
}
else {
	my $tobin=new Tobin::IF(1);
	my $fbaset=$tobin->fbasetupGet($ARGV[1]);
	foreach(@{$fbaset->{TFSET}}) {
		push(@{$tflist},$_->[0]);
	}
}

my $tfpath={};
my $skip={};
foreach(@{$tflist}) {
	defined($skip->{$_})&&next;
	defined($excluded->{$_})&&next;
	my $str=$_;
	if(defined($revhash->{$_})) {
		$skip->{$revhash->{$_}}=1;
		$str=$_<$revhash->{$_}?$_."/".$revhash->{$_}:$revhash->{$_}."/".$_;
	}
	if(defined($tfhash->{$_})) {
		if(defined($pathhash->{$tfhash->{$_}})) {
			foreach my $path (@{$pathhash->{$tfhash->{$_}}}) {
				$str.="\t".$path;
			}
		}
		else {
			$str.="\tNo path for reaction in KEGG";
		}
	}
	else {
		$str.="\tNo KEGG number for reaction";
	}
	print($str."\n");
}
