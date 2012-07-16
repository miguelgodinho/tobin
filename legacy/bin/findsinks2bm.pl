#!/usr/bin/perl -I. -w
use strict;
use warnings;
use Tobin::IF;

@ARGV||die("Too few arguments");
my $tobin=new Tobin::IF(1);


my $bm=$tobin->transformationGet($ARGV[0]);
open(WE, "proxyform.csv")||die("Cannot open proxy formulas");
my @tab=<WE>;
close(WE);
my $proxyform={};
foreach(@tab) {
	chomp;
	my @tab1=split(/\t/,$_);
	$proxyform->{$tab1[0]}=$tab1[3];
}

my $excluded={12=>1,9355=>1,9356=>1,9357=>1,9360=>1,9324=>1};
my $sinks={};
foreach(@{$bm->[2]}) {
	defined($excluded->{$_->{id}})&&next;
	my $comp=defined($proxyform->{$_->{id}})?$proxyform->{$_->{id}}:$_->{id};
	my $candid=$tobin->transformationFindByCompounds({$comp=>1},{});
	foreach my $rea (@{$candid}) {
		if($tobin->transformationNameGet($rea)=~/^SINK.*\[i\]$/) {
			$sinks->{$comp}=$rea;
			last;
		}
	}
}
foreach(@{$bm->[2]}) {
	defined($excluded->{$_->{id}})&&next;
	my $comp=defined($proxyform->{$_->{id}})?$proxyform->{$_->{id}}:$_->{id};
	print($comp."\t".(defined($sinks->{$comp})?$sinks->{$comp}:0)."\n")
}
my $tfset=[];
foreach(values(%{$sinks})) {
	push(@{$tfset},$_);
}
$tobin=new Tobin::IF(1004);
$tobin->transformationsetCreate("bmsinks",$tfset);
