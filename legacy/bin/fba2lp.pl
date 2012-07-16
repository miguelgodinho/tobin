#!/usr/bin/perl -I. -w

# written by Jacek Puchalka
# converts a list of tobin reactions into lp format
# requires a list of reactions as input (output of findrevpairs.pl)

use strict;
use warnings;
use Tobin::IF;

# check for enough input arguments
my $tobin	= new Tobin::IF(1);
@ARGV<2&&die("Too few arguments");

# open & read the reaction list
my $fba=$tobin->fbasetupGet($ARGV[0]);
open(WE, $ARGV[1])||die("Cannot open reversible file.");
my @tab=<WE>;
close(WE);

# check for each reaction if it is reversible or not
my $revhash={};
foreach(@tab) {
	chomp;
	my @tab1=split(/\t/,$_);
	(defined($revhash->{$tab1[0]})||defined($revhash->{$tab1[1]}))&&
	die("Problem with reversibles.");
	$revhash->{$tab1[0]}=$tab1[1];
	$revhash->{$tab1[1]}=$tab1[0];
}

my $skip={};
my $objective;
my $cpdhash={0=>{},1=>{}};
my $tfhash={};
my $free={};

# check for each reaction if its products are included into the objective function (???jacek)
foreach(@{$fba->{TFSET}}) {
	defined($skip->{$_->[0]})&&next;
	defined($revhash->{$_->[0]})&&($_->[0]<$revhash->{$_->[0]}?
	($skip->{$revhash->{$_->[0]}}=1):next);
	$tfhash->{$_->[0]}={};
	my $tf=$tobin->transformationGet($_->[0]);
	if($_->[1]!=0) {
		$objective=$fba->{TYPE}==2?$_->[0]:-$_->[0];
	}
	$_->[2]>0&&($tfhash->{$_->[0]}->{min}=$_->[2]);
	defined($_->[3])&&($tfhash->{$_->[0]}->{max}=$_->[3]);
	foreach my $cpd(@{$tf->[2]}) {
		defined($cpdhash->{$cpd->{ext}}->{$cpd->{id}})||
		($cpdhash->{$cpd->{ext}}->{$cpd->{id}}={});
		$cpdhash->{$cpd->{ext}}->{$cpd->{id}}->{$_->[0]}=$cpd->{sto};
	}
}

# checks for minimal & maximal verlocities
foreach(@{$fba->{TFSET}}) {
	defined($skip->{$_->[0]})||next;
	if($_->[1]!=0) {
		$objective=$fba->{TYPE}==2?-$revhash->{$_->[0]}:$revhash->{$_->[0]};
	}
	if($_->[2]>0) {
		if(defined($tfhash->{$revhash->{$_->[0]}}->{min})||
		(defined($tfhash->{$revhash->{$_->[0]}}->{max})&&
		$tfhash->{$revhash->{$_->[0]}}->{max}>0)) {
			die("Tf $_->[0] - inconsistency in limits");
		}
		else {
			$tfhash->{$revhash->{$_->[0]}}->{max}=-$_->[2];
		}
	}
	if(defined($_->[3])) {
		if(defined($tfhash->{$revhash->{$_->[0]}}->{min})&&
		$tfhash->{$revhash->{$_->[0]}}->{min}>0) {
			die("Tf $_->[0] - inconsistency in limits");
		}
		else {
			$tfhash->{$revhash->{$_->[0]}}->{min}=-$_->[3];
		}
	}
}
foreach(keys(%{$tfhash})) {
	if(defined($revhash->{$_})) {
		defined($tfhash->{$_}->{max})&&!defined($tfhash->{$_}->{min})&&
		($tfhash->{$_}->{min}=-1e30);
		!defined($tfhash->{$_}->{min})&&!defined($tfhash->{$_}->{max})&&
		($free->{$_}=1);
	}
}
print(($objective<0?"min: ":"")."R".sprintf("%04d",abs($objective)).";\n\n");
foreach my $ext (keys(%{$cpdhash})) {
	foreach my $cpd (keys(%{$cpdhash->{$ext}})) {
		print(($ext>0?"EX_":"")."C".sprintf("%04d",$cpd).": ");
		foreach(keys(%{$cpdhash->{$ext}->{$cpd}})) {
			print(($cpdhash->{$ext}->{$cpd}->{$_}>0?"+":"").
			$cpdhash->{$ext}->{$cpd}->{$_}." R".sprintf("%04d",$_)." ");
		}
		print("= 0;\n");
	}
}
print("\n");

# set min & max velocities in the lp set up
foreach(keys(%{$tfhash})) {
	defined($tfhash->{$_}->{min})&&
	print("R".sprintf("%04d",$_)." >= ".$tfhash->{$_}->{min}.";\n");
	defined($tfhash->{$_}->{max})&&
	print("R".sprintf("%04d",$_)." <= ".$tfhash->{$_}->{max}.";\n");
}

# print out the lp format for each reaction
my $str="";
foreach(keys(%{$free})) {
	$str.="R".sprintf("%04d",$_).",";
}
chop($str);
print("\nfree ".$str.";\n");
