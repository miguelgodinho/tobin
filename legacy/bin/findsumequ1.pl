#!/usr/bin/perl
use strict;
use warnings;
use Tobin::IF;

my $tobin		= new Tobin::IF(1);

$ARGV[0]&&(open(WE, $ARGV[2])||die("Cannot open scodes"));
my @tab=<WE>;
close(WE);
my $shash={};
my $equhash={0=>{},1=>{}};
foreach(@tab) {
	chomp;
	my @tab1=split(/\t/,$_);
	$shash->{$tab1[0]}=$tab1[1];
}
open(WE, $ARGV[1])||die("Cannot open reaction list");
@tab=<WE>;
close(WE);
foreach(@tab) {
	chomp;
	my $tfnum;
	my $flux;
	my @tab1=split(/\t/,$_);
	if($ARGV[0]) {
		$tfnum=$shash->{$tab1[0]};
		$flux=$tab1[3];
	}
	else {
		$tfnum=$tab1[0];
		$flux=$tab1[1];
	}
	my $tf=$tobin->transformationGet($tfnum);
	foreach my $cpd (@{$tf->[2]}) {
		defined($equhash->{$cpd->{ext}}->{$cpd->{id}})?
		($equhash->{$cpd->{ext}}->{$cpd->{id}}+=$cpd->{sto}*$flux):
		($equhash->{$cpd->{ext}}->{$cpd->{id}}=$cpd->{sto}*$flux)
	}
	
}
foreach my $ext (0,1) {
	foreach (keys(%{$equhash->{$ext}})) {
		print($tobin->compoundNameGet($_)."[".($ext eq 0?"c":"e")."]\t".$equhash->{$ext}->{$_}."\n");
	}
}
	
