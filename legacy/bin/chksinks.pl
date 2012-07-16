#!/usr/bin/perl
use strict;
use warnings;
use Tobin::IF;
my $tobin	= new Tobin::IF(1004);
open(WE, "mcodes.csv");
my @mets=<WE>;
close(WE);
my $mcodes={};
foreach(@mets) {
	chomp($_);
	my @mets1=split(/\t/,$_);
	$mcodes->{$mets1[0]}=$mets1[1];
}
open(WE,"exfl.txt");
my @sinks=<WE>;
close(WE);
my $sinkhash={};
foreach(@sinks) {
	chomp;
	$sinkhash->{$mcodes->{$_}}=1;
}
my $presinks=$tobin->transformationsetGet(148);
foreach(@{$presinks->{TRANS}}) {
	my $rea=$tobin->transformationGet($_);
	defined($sinkhash->{$rea->[2]->[0]->{id}})||print($rea->[2]->[0]->{id}."\n");
}
