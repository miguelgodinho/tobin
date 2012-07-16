#!/usr/bin/perl -I. -w
use strict;
use warnings;
use Tobin::IF;

@ARGV||die("Too few arguments");
open(WE,$ARGV[0])||die("Cannot open input file");
my @bltab=<WE>;
close(WE);
$ARGV[0]=~/(.*)\.([^.]+)$/;
my $froot=$1;
my $ext=$2;
open(CO,">$froot.co.$ext");
open(DC,">$froot.dc.$ext");
open(MX,">$froot.mx.$ext");
open(PR,">$froot.prod.$ext");
open(CS,">$froot.cons.$ext");
open(BI,">$froot.both.$ext");
open(IS,">$froot.isol.$ext");
my $tobin = new Tobin::IF(1);
my $count=0;
do {
	my $block=[];
	do {
		push(@{$block},$bltab[$count]);
		$count+=1;
	} while($count<@bltab&&$bltab[$count]!~/^C/);
	$block->[0]=~/^C[0]*([1-9][0-9]*)/;
	my $cpd=$1;
	if(grep(/\*\n$/,@{$block})==@{$block}) {
		foreach(@{$block}) {
			print(CO $_);
		}
#		print($block->[0]);
#		print($cpd."\n");
		if($block->[0]=~/-->/) {
			print(CS $cpd." - ".$tobin->compoundNameGet($cpd)."\n");
		}
		elsif($block->[0]=~/<--/) {
			print(PR $cpd." - ".$tobin->compoundNameGet($cpd)."\n");
		}
		else {
			print(BI $cpd." - ".$tobin->compoundNameGet($cpd)."\n");
		}
		
	}
	elsif(grep(/\*\n$/,@{$block})==0) {
		foreach(@{$block}) {
			print(DC $_);
		}
		$block->[0]=~/([1-9][0-9]*)\n$/;
		my $cpd1=$1;
		if($block->[0]=~/-->/) {
			print(IS $cpd." - ".$tobin->compoundNameGet($cpd)." --> ".
			$tobin->compoundNameGet($cpd1)." - $cpd1"."\n");
		}
		elsif($block->[0]=~/<--/) {
			print(IS $cpd." - ".$tobin->compoundNameGet($cpd)." <-- ".
			$tobin->compoundNameGet($cpd1)." - $cpd1"."\n");
		}
		else {
			print(IS $cpd." - ".$tobin->compoundNameGet($cpd)." <-> ".
			$tobin->compoundNameGet($cpd1)." - $cpd1"."\n");
		}
	}
	else {
		foreach(@{$block}) {
			print(MX $_);
		}
	}
	
}while($count<@bltab);
close(CO);
close(DC);
close(MX);
close(PR);
close(CS);
close(BI);
close(IS);
