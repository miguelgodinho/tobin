#!/usr/bin/perl -I.
use strict;
use warnings;

open(WE,$ARGV[0])||die("Cannot open formulas");
my @tab=<WE>;
close(WE);

my $mhash={};
foreach(@tab) {
	chomp;
	my @tab1=split(/\t/,$_);
	my @atoms=($tab1[1]=~m/([A-Z][a-z]*[0-9]*)/g);
	my $ahash={};
	foreach my $atom (@atoms) {
			my $value;
#			print($atom."\n");
			($atom=~m/([0-9]+)/)?($value=$1):($value=1);
#			print $value."\n";
			$atom=~/([A-Z][a-z]*)/;
			$ahash->{$1}=$value
		}
	$mhash->{$tab1[0]}=[$ahash,$tab1[2]];
}

open(WE, $ARGV[1])||die("Cannot open equations");
@tab=<WE>;
close(WE);

foreach (@tab) {
	chomp;
	my $atoms={};
	my $charge=0;
	my @tab1=split(/\t/,$_);
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
		$sub=~s/\[[ce]\]$//;
		foreach my $elem (keys(%{$mhash->{$sub}->[0]})) {
			defined($atoms->{$elem})?
			($atoms->{$elem}+=$sto*$mhash->{$sub}->[0]->{$elem}):
			($atoms->{$elem}=$sto*$mhash->{$sub}->[0]->{$elem});
		}
		$charge+=$sto*$mhash->{$sub}->[1];
	}
#	warn %{$atoms};
	foreach my $sub (@prods) {
		my $sto=1;
		if($sub=~/^\(([0-9.]+)\) /) {
			$sto=$1;
			$sub=~s/^\([0-9.]+\) //;
		}
		$sub=~s/\[[ce]\]$//;
		foreach my $elem (keys(%{$mhash->{$sub}->[0]})) {
			defined($atoms->{$elem})?
			($atoms->{$elem}+=$sto*$mhash->{$sub}->[0]->{$elem}):
			($atoms->{$elem}=$sto*$mhash->{$sub}->[0]->{$elem});
		}
		$charge+=$sto*$mhash->{$sub}->[1];
	}
	my $str=$tab1[0]."\t";
	$charge&&($str.="charge: $charge\t");
	foreach my $elem(keys(%{$atoms})) {
		$atoms->{$elem}&&($str.="$elem: $atoms->{$elem}, ");
	}
	$str=~s/, $//;
	($str eq  $tab1[0]."\t")||print($str."\n");
	
}
