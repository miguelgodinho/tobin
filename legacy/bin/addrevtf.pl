#!/usr/bin/perl -I.
use strict;
use warnings;
use Tobin::IF;
my $tobin=new Tobin::IF(1);

open(WE,$ARGV[0])||die("Cannot open input file");
my @tab=<WE>;
close(WE);

foreach(@tab) {
	chomp;
	my $tf=$tobin->transformationGet($_);
	foreach my $cpd (@{$tf->[2]}) {
		$cpd->{sto}=$cpd->{sto}>0?-$cpd->{sto}:abs($cpd->{sto});
	}
	foreach my $nm (@{$tf->[3]}) {
		$nm.=$nm." (R)";
	}
	my $equ="";
	($tf->[0]=~s/^(\[[ce]\] : )//)&&($equ=$1); 
	my @tab1=split(/ --> | <==> /,$tf->[0]);
	$equ.=$tab1[1]." --> ".$tab1[0];
	my $errors=[];
	$tobin->transformationAdd($equ,$tf->[1],$tf->[2],$tf->[3],$errors);
	if(@{$errors}) {
		foreach my $err (@{$errors}) {
			warn($err);
		}
	}
}
