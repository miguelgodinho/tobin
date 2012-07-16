#!/usr/bin/perl
use strict;
use warnings;
use Tobin::IF;

my $tobin		= new Tobin::IF(1);

$ARGV[0]&&(open(WE, $ARGV[1])||die("Cannot open scodes"));
my @tab=<WE>;
close(WE);
my $shash={};
foreach(@tab) {
	chomp;
	my @tab1=split(/\t/,$_);
	$shash->{$tab1[0]}=$tab1[1];
}

open(WE,$ARGV[2])||die("Cannot open mcodes");
@tab=<WE>;
close(WE);
my $mhash={};
foreach(@tab) {
	chomp;
	my @tab1=split(/\t/,$_);
	$mhash->{$tab1[0]}=$tab1[1];
}

open(WE, $ARGV[0])||die("Cannot open input file");
@tab=<WE>;
close(WE);
foreach (@tab) {
	my $equhashsim={c=>{},e=>{}};
	my $equhashtob={c=>{},e=>{}};
	chomp;
	my @tab1=split(/\t/,$_);
	my $ext;
	$tab1[1]=~/^\[([ce])\] : /&&($ext=$1);
	$tab1[1]=~s/^\[[ce]\] : //;
	my @tab2=split(/ <==> | --> /,$tab1[1]);
	my @subs=split(/ \+ /,$tab2[0]);
	my @prods=split(/ \+ /,$tab2[1]);
	foreach my $sub (@subs) {
		my $sto=-1;
		if($sub=~/^\(([0-9.]+)\) /) {
			$sto=-$1;
			$sub=~s/^\([0-9.]+\) //;
		}
		$sub=~/\[([ce])\]$/&&($ext=$1);
		$sub=~s/\[[ce]\]$//;
		defined($equhashsim->{$ext}->{$mhash->{$sub}})?
		($equhashsim->{$ext}->{$mhash->{$sub}}+=$sto):
		($equhashsim->{$ext}->{$mhash->{$sub}}=$sto);
	}
	foreach my $sub (@prods) {
		my $sto=1;
		if($sub=~/^\(([0-9.]+)\) /) {
			$sto=$1;
			$sub=~s/^\([0-9.]+\) //;
		}
		$sub=~/\[([ce])\]$/&&($ext=$1);
		$sub=~s/\[[ce]\]$//;
		defined($equhashsim->{$ext}->{$mhash->{$sub}})?
		($equhashsim->{$ext}->{$mhash->{$sub}}+=$sto):
		($equhashsim->{$ext}->{$mhash->{$sub}}=$sto);
	}
	my $tf=$tobin->transformationGet($shash->{$tab1[0]});
	foreach my $cpd(@{$tf->[2]}) {
		$equhashtob->{$cpd->{ext}?"e":"c"}->{$cpd->{id}}=$cpd->{sto};
	}
	foreach my $ext ("c","e") {
		foreach my $cpd (keys(%{$equhashsim->{$ext}})) {
			defined($equhashtob->{$ext}->{$cpd})||
			(print("$tab1[0] - Compound $cpd\[$ext\] not defined in tobin equation\n")&&next);
			$equhashtob->{$ext}->{$cpd}==$equhashsim->{$ext}->{$cpd}||
			print("$tab1[0] - Compound $cpd\[$ext\] inequal stoichiometry: ".
			$equhashtob->{$ext}->{$cpd}." ".$equhashsim->{$ext}->{$cpd}."\n");
		}
		foreach my $cpd (keys(%{$equhashtob->{$ext}})) {
			defined($equhashsim->{$ext}->{$cpd})||
			print("$tab1[0] - Compound $cpd\[$ext\] not defined in simpheny equation\n");
		}
	}
}
