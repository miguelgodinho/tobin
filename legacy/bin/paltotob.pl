#!/usr/bin/perl
use strict;
use warnings;
use Tobin::IF;

my $tobin		= new Tobin::IF(1);
open(WE,"/home/jap04/MetabNets/paltotob.csv");
my @codes=<WE>;
close(WE);
my $numbers={};
foreach(@codes) {
	chomp($_);
	my @cols=split(/\t/,$_);
	my $reacts=$tobin->transformationCandidatesGet($cols[0],'t_lnk',1);
	if(@{$reacts}==1) {
		$numbers->{$cols[0]}=[$reacts->[0]];
	}
	elsif(@{$reacts}==2) {
		my $react1=$tobin->transformationGet($reacts->[0]);
		my  $react2=$tobin->transformationGet($reacts->[1]);
		if($react1->[3]->[0]=~/\(R\)$/) {
			$numbers->{$cols[0]}=[$reacts->[1],$reacts->[0]];
		}
		elsif($react2->[3]->[0]=~/\(R\)$/) {
			$numbers->{$cols[0]}=[$reacts->[0],$reacts->[1]];
		}
		else {
			print("problem with reverses ".$react1->[3]->[0]." ".$react2->[3]->[0]."\n");
		}
	}
	elsif(@{$reacts}==0) {
		print("No reaction with code: ".$cols[0]."\n");
	}
	else {
		print("Following reactions fit to code ".$cols[0].":");
		foreach my $el(@{$reacts}) {
			print(" ".$el);
		}
		print("\n");
	}
}
open(WY, ">ptob.txt");
foreach(keys(%{$numbers})) {
	print(WY $_."\t".$numbers->{$_}->[0].((@{$numbers->{$_}}==2)?("\t".$numbers->{$_}->[1]):"")."\n");
}
close(WY);
