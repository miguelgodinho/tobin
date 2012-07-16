#!/usr/bin/perl -I. -w
use strict;
use warnings;
use Tobin::IF;

my $tobin	= new Tobin::IF(1);
my $tfset=[];
if($ARGV[0]) {
	my $fbaset=$tobin->fbasetupGet($ARGV[1]);
	foreach(@{$fbaset->{TFSET}}) {
		push(@{$tfset},$_->[0]);
	}
}
else {
	open(WE, $ARGV[1])||die("Cannot open reaction list");
	my @tab=<WE>;
	close(WE);
	foreach(@tab) {
		chomp;
		push(@{$tfset},$_);
	}
}

open(WE, $ARGV[2])||die("Cannot open reversible file.");
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
my $assigned={};
my $fintf=[];
my $cpdhash=[{},{}];
foreach(@{$tfset}) {
	defined($assigned->{$_})&&next;
	my $tf=$tobin->transformationGet($_);
	foreach my $cpd (@{$tf->[2]}) {
		defined($cpdhash->[$cpd->{ext}]->{$cpd->{id}})||
		($cpdhash->[$cpd->{ext}]->{$cpd->{id}}={});
		$cpdhash->[$cpd->{ext}]->{$cpd->{id}}->{$_}=$cpd->{sto};
	}
	$assigned->{$_}=1;
	push(@{$fintf},$_);
	if(defined($revhash->{$_})) {
		$assigned->{$revhash->{$_}}=1;
	}
}
foreach(@{$fintf}) {
	print("\tR".sprintf("%04d",$_));
}
print("\n");
foreach my $ext (0,1) {
	foreach my $cpd (keys(%{$cpdhash->[$ext]})) {
		my $str=($ext?"EX":"").sprintf("%04d",$cpd)."\t";
		foreach my $tf (@{$fintf}) {
			$str.=defined($cpdhash->[$ext]->{$cpd}->{$tf})?
			$cpdhash->[$ext]->{$cpd}->{$tf}:0;
			$str.="\t";
		}
		chop $str;
		print($str."\n");
	}
}
