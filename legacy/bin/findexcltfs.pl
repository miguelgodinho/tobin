#!/usr/bin/perl -I/home/jap04/workspace/pseudo/ -w
use strict;
use warnings;
use Tobin::IF;

my $tobin=new Tobin::IF(1);

my $fbaset=$tobin->fbasetupGet($ARGV[0]);
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
my $excluded={};
my $included={};
foreach(@{$fbaset->{TFSET}}) {
	my $name=$tobin->transformationNameGet($_->[0]);
	$name=~/^SOURCE|^SINK|joining|multiplication|^carbon|^power|Biomass/?
	($excluded->{$_->[0]}=1):($included->{$_->[0]}=1);
}
print("Excluded:\n");
my $skip={};
foreach(keys(%{$excluded})) {
	defined($skip->{$_})&&next;
	if(defined($revhash->{$_})) {
		print(($_<$revhash->{$_}?$_."/".$revhash->{$_}:$revhash->{$_}."/".$_)."\n");
		$skip->{$revhash->{$_}}=1;
	}
	else {
		print($_."\n");
	}
}
print("Included:\n");
$skip={};
foreach(keys(%{$included})) {
	defined($skip->{$_})&&next;
	if(defined($revhash->{$_})) {
		print(($_<$revhash->{$_}?$_."/".$revhash->{$_}:$revhash->{$_}."/".$_)."\n");
		$skip->{$revhash->{$_}}=1;
	}
	else {
		print($_."\n");
	}
}
