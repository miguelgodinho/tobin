#!/usr/bin/perl -I. -w
use strict;
use warnings;
use Tobin::IF;

@ARGV<2&&die("Too few arguments.");
my $tobin		= new Tobin::IF(1);
open(WE, $ARGV[0])||die("Cannot open reversibles file");
my @tab=<WE>;
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
open(WE, $ARGV[2])||die("Cannot open compound file!");
@tab=<WE>;
close(WE);
my $blcpd=[];
foreach(@tab) {
	chomp;
	push(@{$blcpd},$_);
}
open(WE, $ARGV[3])||die("cannot open reaction file!");
@tab=<WE>;
close(WE);
my $blrea={};
foreach(@tab) {
	chomp;
	$blrea->{$_}=1;
}
my $compmap=[{}, {}];
my $blcmp={};
my %fbares=$tobin->fbaresGet($ARGV[1]);
my $end;
my $deadmap={};
my $ends={};
my $revexclude={};
my $reahash={};
foreach(keys(%fbares)) {
	defined($revexclude->{$_})&&next;
	$reahash->{$_}=[[{},{}],[{},{}]];
	my $rea=$tobin->transformationGet($_);
	foreach my $comp(@{$rea->[2]}){
		my $rev=0;
		if(defined($revhash->{$_})) {
			$revexclude->{$revhash->{$_}}=1;
			$rev=1;
		}
		defined($compmap->[$comp->{ext}]->{$comp->{id}})?
		($compmap->[$comp->{ext}]->{$comp->{id}}->{$_}=$comp->{sto}<0?[1,$rev]:[0,$rev]):
		($compmap->[$comp->{ext}]->{$comp->{id}}={$_=>$comp->{sto}<0?[1,$rev]:[0,$rev]});
		$reahash->{$_}->[$comp->{ext}]->[$comp->{sto}<0?1:0]->{$comp->{id}}=1;
	}
}
foreach(@{$blcpd}) {
	foreach my $rea(keys(%{$compmap->[0]->{$_}})) {
		defined($blrea->{$rea})||print($_."\t".$rea."\n");
	}
}
