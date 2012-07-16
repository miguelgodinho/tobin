#!/usr/bin/perl -I. -w
#
use strict;
use warnings;
use Tobin::IF;

@ARGV<3&&die("Too few arguments");
my $tobin=new Tobin::IF(1);
open(WE,$ARGV[0])||die("Cannot open equivalent list");
my @tab=<WE>;
close(WE);
my @tab1;
my $equivhash={};
foreach(@tab) {
	chomp;
	@tab1=split(/\t/,$_);
	my $main=shift(@tab1);
	foreach my $num (@tab1) {
		$equivhash->{$num}=$main;
	}
}
my $tflist=[];
if(!$ARGV[1]) {
	open(WE, $ARGV[2])||die("cannot open transformation list");
	@tab=<WE>;
	close(WE);
	foreach(@tab){
		chomp;
		push(@{$tflist},$_)
	}
}
elsif($ARGV[1]==1) {
	my $fbaset=$tobin->fbasetupGet($ARGV[2]);
	foreach (@{$fbaset->{TFSET}}) {
		push(@{$tflist},$_->[0]);
	}
}

foreach(@{$tflist}) {
	my $tf=$tobin->transformationGet($_);
	my $bad=0;
	foreach my $cpd (@{$tf->[2]}) {
		defined($equivhash->{$cpd->{id}})&&($bad=1)&&last;
	}
	$bad||next;
	my $prods={};
	my $subs={};
	foreach my $cpd (@{$tf->[2]}) {
		$cpd->{sto}<0?($subs->{defined($equivhash->{$cpd->{id}})?$equivhash->{$cpd->{id}}:$cpd->{id}}=1):($prods->{defined($equivhash->{$cpd->{id}})?$equivhash->{$cpd->{id}}:$cpd->{id}}=1);
	}
	my $suggtf=$tobin->transformationFindByCompounds($subs,$prods);
	if(@{$suggtf}) {
		print($_);
		foreach my $rea (@{$suggtf}) {
			print("\t".$rea);
		}
		print("\n");
	}
	else {
		print($_."\tno\n");
	}
}
#
