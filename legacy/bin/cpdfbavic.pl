#!/usr/bin/perl -I. -w
use strict;
use warnings;
use Tobin::IF;
@ARGV<4&&die("Too few arguments.");
open(WE, $ARGV[1])||die("Cannot open reversible file.");
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
my $prod={};
my $cons={};
my $rev={};
my $tobin	= new Tobin::IF(1);
my %fba=$tobin->fbaresGet($ARGV[0]);
my $skip={};
foreach(keys(%fba)) {
	defined($skip->{$_})&&next;
	my $rea=$tobin->transformationGet($_);
	foreach my $row (@{$rea->[2]}) {
		if($row->{id}==$ARGV[2]&&$row->{ext}==$ARGV[3]) {
			if(defined($revhash->{$_})) {
				$skip->{$revhash->{$_}}=1;
				my $dir=$_<$revhash->{$_}?1:-1;
				$rev->{$dir>0?$_."/".$revhash->{$_}:$revhash->{$_}."/".$_}=
				($fba{$_}>0?$dir*$fba{$_}:-$dir*$fba{$revhash->{$_}});
			}
			elsif($row->{sto}<0) {
				$cons->{$_}=$fba{$_};
			}
			else {
				$prod->{$_}=$fba{$_};
			}
		}
	}
}
print("Consumed:\n");
foreach(keys(%{$cons})) {
	print($_."\t".$cons->{$_}."\n");
}
print("Produced:\n");
foreach(keys(%{$prod})) {
	print($_."\t".$prod->{$_}."\n");
}
print("Both:\n");
foreach(keys(%{$rev})) {
	print($_."\t".$rev->{$_}."\n");
}
