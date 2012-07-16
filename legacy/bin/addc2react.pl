#!/usr/bin/perl -w -I.
use strict;
use warnings;
use Tobin::IF;

@ARGV||die("Too few arguments");
my $tobin		= new Tobin::IF(1004);
open(WE,$ARGV[0])||die("Cannot open $ARGV[0].");
my @clist=<WE>;
close(WE);
my $compounds={};
open(WY, ">c2add.out");
foreach(@clist) {
	chomp;
	if($_=~/\t([0-9]+)$/) {
		$compounds->{$1}=0;
		next;
	}
	my $csugg=$tobin->compoundCandidatesGet("^".$_."\$");
	if(!@{$csugg}) {
		print(WY"Cannot find $_\n");
	}
	elsif(@{$csugg}==1) {
		print(WY"Accepted $csugg->[0] - ".$tobin->compoundNameGet($csugg->[0])." as $_\n");
		$compounds->{$csugg->[0]}=0;
	}
	else {
		print(WY"Multiple compounds for $_:");
		foreach my $c (@{$csugg}) {
			print(WY"\t$c");
		}
		print(WY"\n");
	}
	
}
foreach(keys(%{$compounds})) {
	my $form=$tobin->compoundFormulaGet($_);
	my $cnum;
	my $errors=[];
	warn $form;
	$cnum=($form=~/C([0-9]+)/)?$1:1;
	warn -$cnum;
	$tobin->transformationAdd("carbon[e] -> ".$tobin->compoundNameGet($_)."[i]",
	[{user=>1004,"link"=>"c2".$_."i"}],[{id=>9371, sto=>-$cnum,ext=>1},{id=>$_, sto=>1,ext=>0}],
	["carbon to ".$tobin->compoundNameGet($_)."[i]"],$errors);
	if(@{$errors}) {
		print($_.":\n");
		foreach my $err (@{$errors}) {
			print($err."\n");
		}
	}
	
}
close(WY);
