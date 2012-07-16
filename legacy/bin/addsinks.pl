#!/usr/bin/perl
use strict;
use warnings;
use Tobin::IF;
my $tobin	= new Tobin::IF(1004);

my $presinks=$tobin->transformationsetGet(148);
my $sinkhash={};
foreach(@{$presinks->{TRANS}}) {
	my $rea=$tobin->transformationGet($_);
	$sinkhash->{$rea->[2]->[0]->{id}}=1;
}
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
foreach(@sinks) {
	chomp;
	my $errors=[];
	defined($mcodes->{$_})||die("Can't find $_");
	defined($sinkhash->{$mcodes->{$_}})||
	$tobin->transformationAdd("SINK: ".$tobin->compoundNameGet($mcodes->{$_})."[e]",
	[{user=>1004,"link"=>$_."sink"}],[{id=>$mcodes->{$_},sto=>-1,ext=>1}],
	["SINK: ".$tobin->compoundNameGet($mcodes->{$_})."[e]"],$errors);
	if(@{$errors}) {
		print($_.":\n");
		foreach my $err (@{$errors}) {
			print($err."\n");
		}
	} 
}
