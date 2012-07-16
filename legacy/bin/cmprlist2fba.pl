#!/usr/bin/perl -I.
use strict;
use warnings;
use Tobin::IF;

@ARGV<3&&die("Too few arguments.");
open(WE,$ARGV[0])||die("Cannot open the file: ".$ARGV[0]."!\n");
my @rlist=<WE>;
close(WE);
open(WE, "simcodes.csv");
my @simcodes=<WE>;
close(WE);
my $reacts={};
foreach(@simcodes) {
	chomp($_);
	my @react=split(/\t/,$_);
	$reacts->{$react[0]}=(@react==2?[$react[1]]:[$react[1],$react[2]]);
}
my $tobin		= new Tobin::IF(1);
my $fbaset=$tobin->fbasetupGet($ARGV[1]);
my $rmap={};
if(!$ARGV[2]) {
	foreach(@{$fbaset->{TFSET}}) {
		$rmap->{$_->[0]}=1;
	}
	foreach(@rlist) {
		chomp($_);
		my @react=split(/\t/,$_);
		defined($reacts->{$react[0]})||die("Can't find reaction: ".$react[0]);
		defined($rmap->{$reacts->{$react[0]}->[0]})||
		print($reacts->{$react[0]}->[0]." - ".$react[0]. " - ".
		$tobin->transformationNameGet($reacts->{$react[0]}->[0])."\n");
		if($react[1]) {
			@{$reacts->{$react[0]}}==2||die("Cant find reverse of reaction: ".$react[0]);
			defined($rmap->{$reacts->{$react[0]}->[1]})||
			print($reacts->{$react[0]}->[1]." - ".$react[0]. " - ".
			$tobin->transformationNameGet($reacts->{$react[0]}->[1])."\n");
		}
	}
}
else {
	foreach(@rlist) {
		chomp($_);
		my @react=split(/\t/,$_);
		defined($reacts->{$react[0]})||die("Can't find reaction: ".$react[0]);
		$rmap->{$reacts->{$react[0]}->[0]}=1;
		if($react[1]) {
			@{$reacts->{$react[0]}}==2||die("Cant find reverse of reaction: ".$react[0]);
			$rmap->{$reacts->{$react[0]}->[1]}=1;
		}
	}
	my $excluded={};
	@ARGV>3&&(open(WE, $ARGV[3])||die("Cannot open excluded file"));
	my @tab=<WE>;
	close(WE);
	foreach (@tab) {
		chomp;
		$excluded->{$_}=1;
	}
	foreach(@{$fbaset->{TFSET}}) {
		defined($excluded->{$_->[0]})&&next;
		defined($rmap->{$_->[0]})||print($_->[0]."\t".$tobin->transformationNameGet($_->[0])."\n");
	}
}
