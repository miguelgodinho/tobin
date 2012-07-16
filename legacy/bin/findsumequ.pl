#!/usr/bin/perl -I.
use strict;
use warnings;

open(WE, $ARGV[0])||die("Cannot open input file");
my @tab=<WE>;
close(WE);
my $equhash={c=>{},e=>{}};
foreach (@tab) {
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
		defined($equhash->{$ext}->{$sub})?
		($equhash->{$ext}->{$sub}+=$sto*$tab1[2]):
		($equhash->{$ext}->{$sub}=$sto*$tab1[2]);
	}
	foreach my $sub (@prods) {
		my $sto=1;
		if($sub=~/^\(([0-9.]+)\) /) {
			$sto=$1;
			$sub=~s/^\([0-9.]+\) //;
		}
		$sub=~/\[([ce])\]$/&&($ext=$1);
		$sub=~s/\[[ce]\]$//;
		defined($equhash->{$ext}->{$sub})?
		($equhash->{$ext}->{$sub}+=$sto*$tab1[2]):
		($equhash->{$ext}->{$sub}=$sto*$tab1[2]);
	}
}

foreach my $ext ("e","c") {
	foreach (keys(%{$equhash->{$ext}})){
		print($_."[".$ext."]"."\t".$equhash->{$ext}->{$_}."\n");
	}
}
