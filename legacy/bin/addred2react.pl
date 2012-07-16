#!/usr/bin/perl -w -I.
use strict;
use warnings;
use Tobin::IF;

@ARGV||die("Too few arguments");
my $tobin		= new Tobin::IF(1004);
open(WE,$ARGV[0])||die("Cannot open $ARGV[0].");
my @clist=<WE>;
close(WE);
foreach(@clist) {
	chomp;
	my $errors=[];
	my @tab=split(/\t/,$_);
	$tobin->transformationAdd("red[e] -> ".$tobin->compoundNameGet($tab[0])."[e]",
	[{user=>1004,"link"=>"r2".$tab[0]."e"}],[{id=>9565, sto=>-$tab[1],ext=>1},{id=>$tab[0], sto=>1,ext=>1}],
	["reduction to ".$tobin->compoundNameGet($tab[0])."[e]"],$errors);
	if(@{$errors}) {
		print($_.":\n");
		foreach my $err (@{$errors}) {
			print($err."\n");
		}
	}
	
}
