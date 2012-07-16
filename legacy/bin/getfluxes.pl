#!/usr/bin/perl -I. -w
use strict;
use warnings;
use Tobin::IF;


@ARGV<2&&die("Too few arguments");
my $tobin	= new Tobin::IF(1);
my %fba1=$tobin->fbaresGet($ARGV[0]);
open(WE, $ARGV[1])||die("Cannot open reversibles file");
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
open(WE,$ARGV[2])||die("cannot open excluded reactions file");
@tab=<WE>;
close(WE);
my $excl={};
foreach(@tab) {
	chomp;
	$excl->{$_}=1;
}
if(@ARGV>3) {
	open(WE,$ARGV[3])||die("Cannot open reaction list");
	my @tab=<WE>;
	close(WE);
	foreach(@tab) {
		chomp;
		if(defined($revhash->{$_})) {
			defined($fba1{$_})&&defined($fba1{$revhash->{$_}})?
			print($_."/".$revhash->{$_}."\t".($fba1{$_}?
			$fba1{$_}:($fba1{$revhash->{$_}}?("-".$fba1{$revhash->{$_}}):0))."\n"):
			warn(" One of transformations $_ or $revhash->{$_} not in set.");
		}
		else {
			defined($fba1{$_})?print($_."\t".$fba1{$_}."\n"):
			warn("Transformation $_ not in set.");
		}
	}
}
else {
	my $skip={};
	foreach(keys(%fba1)) {
		defined($skip->{$_})&&next;
		(defined($excl->{$_})||defined($revhash->{$_})
		&&defined($excl->{$revhash->{$_}}))&&next;
		if(defined($revhash->{$_})) {
			$skip->{$revhash->{$_}}=1;
			my $dir=$_<$revhash->{$_}?1:-1;
			my $flux="";
			if($dir>0) {
				$fba1{$_}>0&&($flux.=$fba1{$_}."\t");
				$fba1{$revhash->{$_}}>0&&($flux.=-$fba1{$revhash->{$_}}."\t");
			}
			else {
				$fba1{$revhash->{$_}}>0&&($flux.=$fba1{$revhash->{$_}}."\t");
				$fba1{$_}>0&&($flux.=-$fba1{$_}."\t");
			}
			$flux=~s/\t$//;
			length($flux)||($flux=0);
			print(($dir>0?$_."/".$revhash->{$_}:$revhash->{$_}."/".$_)."\t".$flux."\n");
			
		}
		else {
			print($_."\t".$fba1{$_}."\n");
		}
	}
}
