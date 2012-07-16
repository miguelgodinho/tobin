#!/usr/bin/perl -I. -w
use strict;
use warnings;
use Tobin::IF;
@ARGV<4&&die("Too few arguments.");
my $tobin	= new Tobin::IF(1);
my %fba=$tobin->fbaresGet($ARGV[0]);
my $fhash={};
foreach(keys(%fba)) {
	my $rea=$tobin->transformationGet($_);
	foreach my $row (@{$rea->[2]}) {
		if($row->{id}==$ARGV[1]&&$row->{ext}==$ARGV[2]&&$fba{$_}) {
			$fhash->{$_}=$fba{$_}*$row->{sto};
		}
	}
}

open(WE,$ARGV[3])||die("Cannot open simcodes");
my @tab=<WE>;
close(WE);
foreach(@tab) {
	chomp;
	my @tab1=split(/\t/,$_);
	defined($fhash->{$tab1[1]})&&
	print($tab1[0]."\t".$tab1[1]."\t".$fhash->{$tab1[1]}."\n");
	@tab1==3&&defined($fhash->{$tab1[2]})&&
	print($tab1[0]."\t".$tab1[2]."\t".$fhash->{$tab1[2]}."\n");
}
