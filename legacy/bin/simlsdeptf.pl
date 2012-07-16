#!/usr/bin/perl -I. -w
use strict;
use warnings;
use Tobin::IF;
use Clone qw(clone);

my $tfanno={};
my $geanno={};


open(WE, "imo1056scodes.2.csv")||die("cannot open scodes");
my @tab=<WE>;
close(WE);
my $scodes={};
foreach(@tab) {
	chomp;
	my @tab1=split(/\t/,$_);
	$scodes->{$tab1[0]}=@tab1==2?$tab1[1]:($tab1[1]<$tab1[2]?$tab1[1]."/".$tab1[2]:
	$tab1[2]."/".$tab1[1]);
}
open(WE, $ARGV[0])||die("Cannot open gprs");
@tab=<WE>;
close(WE);
foreach(@tab) {
	chomp;
	my @tab1=split(/\t/,$_);
	my $sco=shift(@tab1);
	my $tf=$scodes->{$sco};
	defined($tf)||next;
	my $ind=0;
	foreach my $cp (@tab1) {
		$tfanno->{$tf}->{$ind}={};
		my @tab2=split(/,/,$cp);
		foreach my $ge (@tab2) {
			defined($geanno->{$ge})||($geanno->{$ge}={});
			$geanno->{$ge}->{$tf}=1;
		}
		$ind++;
	}
}
foreach(keys(%{$geanno})) {
	my $str=$_;
	foreach my $tf (keys(%{$geanno->{$_}})) {
		$str.="\t".$tf;
	}
	print($str."\n");
}
