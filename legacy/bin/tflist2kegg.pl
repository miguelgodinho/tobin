#!/usr/bin/perl -I. -w
use strict;
use warnings;
use Tobin::IF;

my $tobin	= new Tobin::IF(1);
open(WE,$ARGV[0])||die("Cannot open reactions file!");
my @tflist=<WE>;
close(WE);
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
open(WE,$ARGV[2])||die("cannot open excluded reactions file");
@tab=<WE>;
close(WE);
my $excl={};
foreach(@tab) {
	chomp;
	$excl->{$_}=1;
}

my $kegghash={};
open(WE,$ARGV[3])||die("Cannot open keggfile");
@tab=<WE>;
close(WE);
foreach(@tab) {
	chomp;
	my @tab1=split(/\t/,$_);
	defined($kegghash->{$tab1[0]})&&$kegghash->{$tab1[0]}==$tab1[1]&&
	warn("double reaction for $tab1[0]: $tab1[1]".$kegghash->{$tab1[0]}."\n");
	$kegghash->{$tab1[0]}=$tab1[1];	
}
my $map={};
my $skip={};
foreach(@tflist) {
	chomp;
	defined($skip->{$_})&&next;
	defined($revhash->{$_})&&($skip->{$revhash->{$_}}=1);
	my $tf=$tobin->transformationGet($_);
	my $lnk;
	foreach my $links (@{$tf->[1]}) {
		($links->{user}==901)&&($lnk=$links->{link})&&last;
	}
	my $lnk1;
	defined($kegghash->{$_})?($lnk1=$kegghash->{$_}):
	(defined($revhash->{$_})&&defined($kegghash->{$revhash->{$_}})&&
	($lnk1=$kegghash->{$revhash->{$_}}));
	if(defined($lnk)&&defined($lnk1)) {
		$lnk eq $lnk1?($map->{$_}=$lnk):
		warn("Inconsistent numbers for $_: ".$lnk."\t".$lnk1);
	}
	elsif(defined($lnk)) {
		$map->{$_}=$lnk;
	}
	elsif(defined($lnk1)) {
		$map->{$_}=$lnk1;
	}
	else {
		$map->{$_}=0;
	}
	
}

foreach(keys(%{$map})) {
	print((defined($revhash->{$_})?
	($_<$revhash->{$_}?$_."/".$revhash->{$_}:$revhash->{$_}."/".$_):$_).
	"\t".$map->{$_}."\n");
}



