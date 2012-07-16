#!/usr/bin/perl
use strict;
use warnings;
use Tobin::IF;

my $tobin		= new Tobin::IF(1);

my %fba=$tobin->fbaresGet($ARGV[0]);
open(WE,$ARGV[1])||die("cannot open scodes file");
my @tab=<WE>;
close(WE);
my $shash={};
foreach (@tab) {
	chomp;
	my @tab1=split(/\t/,$_);
	if(@tab1==2) {
		defined($fba{$tab1[1]})||warn($tab1[0]);
		print($tab1[1]."\t".$tab1[0]."\t".$fba{$tab1[1]}."\n");
	}
	else {
		$fba{$tab1[1]}&&$fba{$tab1[2]}&&die("Problem with reversibles in $tab1[0]");
		print(($tab1[1]<$tab1[2]?$tab1[1]."/".$tab1[2]:$tab1[2]."/".$tab1[1])."\t".
		$tab1[0]."\t".($fba{$tab1[2]}>0?-$fba{$tab1[2]}:$fba{$tab1[1]})."\n");
	}
}
