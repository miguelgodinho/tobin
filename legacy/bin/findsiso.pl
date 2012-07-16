#!/usr/bin/perl -I.
use strict;
use warnings;
use Tobin::IF;

my $tobin=new Tobin::IF(1);
open(WE, $ARGV[1])||die("Cannot open mcodes");
my @tab=<WE>;
close(WE);
my $mhash={};
foreach(@tab) {
	chomp;
	my @tab1=split(/\t/,$_);
	$mhash->{$tab1[0]}=$tab1[1];
}
open(WE, $ARGV[0])||die("Cannot open input file");
my @clist=<WE>;
close(WE);
my $sisohash={};
foreach (@clist) {
	chomp;
	defined($mhash->{$_})||die("No code for $_");
	my $sicand=$tobin->transformationFindByCompounds({$mhash->{$_}=>1},{});
	foreach my $cand (@{$sicand}) {
		my $tf=$tobin->transformationGet($cand);
		if(@{$tf->[2]}==1&&$tf->[2]->[0]->{ext}==1) {
			$sisohash->{$_}->{sink}=$cand;
			last;
		}
	}
	if(!defined($sisohash->{$_}->{sink})) {
		my $errors=[];
		$sisohash->{$_}->{sink}=$tobin->transformationAdd("SINK: ".$tobin->compoundNameGet($mhash->{$_})."[e]",
		[{user=>1004,"link"=>$_."sink"}],[{id=>$mhash->{$_},sto=>-1,ext=>1}],
		["SINK: ".$tobin->compoundNameGet($mhash->{$_})."[e]"],$errors);
		if(@{$errors}) {
			print($_.":\n");
			foreach my $err (@{$errors}) {
				print($err."\n");
			}
		}
	}
	my $socand=$tobin->transformationFindByCompounds({},{$mhash->{$_}=>1});
	foreach my $cand (@{$socand}) {
		my $tf=$tobin->transformationGet($cand);
		if(@{$tf->[2]}==1&&$tf->[2]->[0]->{ext}==1) {
			$sisohash->{$_}->{source}=$cand;
			last;
		}
	}
	if(!defined($sisohash->{$_}->{source})) {
		my $errors=[];
		$sisohash->{$_}->{source}=$tobin->transformationAdd("SOURCE: ".$tobin->compoundNameGet($mhash->{$_})."[e]",
		[{user=>1004,"link"=>$_."src"}],[{id=>$mhash->{$_},sto=>1,ext=>1}],
		["SOURCE: ".$tobin->compoundNameGet($mhash->{$_})."[e]"],$errors);
		if(@{$errors}) {
			print($_.":\n");
			foreach my $err (@{$errors}) {
				print($err."\n");
			}
		}
	}
}
foreach(@clist) {
	print($_);
	defined($sisohash->{$_})||print("\n")&&next;
	print("\t");
	defined($sisohash->{$_}->{source})&&print($sisohash->{$_}->{source});
	print("\t");
	defined($sisohash->{$_}->{sink})&&print($sisohash->{$_}->{sink});
	print("\n");
}

