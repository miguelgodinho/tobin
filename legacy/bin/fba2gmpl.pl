#!/usr/bin/perl -I. -w
use strict;
use warnings;
use Tobin::IF;

my $tobin	= new Tobin::IF(1);
@ARGV<2&&die("Too few arguments");

my $fba=$tobin->fbasetupGet($ARGV[0]);
open(WE, $ARGV[1])||die("Cannot open reversible file.");
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
my $skip={};
my $objective;
my $cpdhash={0=>{},1=>{}};
my $tfhash={};
my $free={};
foreach(@{$fba->{TFSET}}) {
	defined($skip->{$_->[0]})&&next;
	defined($revhash->{$_->[0]})&&($skip->{$revhash->{$_->[0]}}=1);
	$tfhash->{$_->[0]}={};
	my $tf=$tobin->transformationGet($_->[0]);
	if($_->[1]!=0) {
		$objective=$_->[1]>0?$_->[0]:-$_->[0];
	}
	$_->[2]>0&&($tfhash->{$_->[0]}->{min}=$_->[2]);
	defined($_->[3])&&($tfhash->{$_->[0]}->{max}=$_->[3]);
	foreach my $cpd(@{$tf->[2]}) {
		defined($cpdhash->{$cpd->{ext}}->{$cpd->{id}})||
		($cpdhash->{$cpd->{ext}}->{$cpd->{id}}={});
		$cpdhash->{$cpd->{ext}}->{$cpd->{id}}->{$_->[0]}=$cpd->{sto};
	}
}
foreach(@{$fba->{TFSET}}) {
	defined($skip->{$_->[0]})||next;
	if($_->[1]!=0) {
		$objective=$_->[1]>0?-$revhash->{$_->[0]}:$revhash->{$_->[0]};
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
			$tfhash->{$revhash->{$_->[0]}}->{min}=-$_->[2];
		}
	}
}

my $realinv={};
my $realrev={};
foreach(keys(%{$tfhash})) {
	if(defined($revhash->{$_})&&defined($tfhash->{$_}->{min})&&
	$tfhash->{$_}->{min}>=0) {
		$realinv->{$_}=1;
	}
	elsif(defined($revhash->{$_})&&(!defined($tfhash->{$_}->{min})||$tfhash->{$_}->{min}<0)) {
		$realrev->{$_}=1;
	}
	else {
		$realinv->{$_}=1;
	}
}


foreach(keys(%{$realinv})) {
	print("var R".sprintf("%04d",$_)." , >= ".(defined($tfhash->{$_}->{min})?$tfhash->{$_}->{min}:0).(defined($tfhash->{$_}->{max})?
	" , <= ".$tfhash->{$_}->{max}:"").";\n");
}
foreach(keys(%{$realrev})) {
	print("var R".sprintf("%04d",$_).(defined($tfhash->{$_}->{min})?" , >= ".
	$tfhash->{$_}->{min}:"").(defined($tfhash->{$_}->{max})?
	" , <= ".$tfhash->{$_}->{max}:"").";\n");
}
print("\nmaximize obj : ".($objective<0?"-1 * ":"")."R".
sprintf("%04d",abs($objective)).";\n");
foreach my $ext (0,1) {
	foreach my $cpd (keys(%{$cpdhash->{$ext}})) {
		my $str="s.t. ".($ext?"EX_":"")."C".sprintf("%04d",$cpd)." : ";
		foreach(keys(%{$cpdhash->{$ext}->{$cpd}})) {
			if($cpdhash->{$ext}->{$cpd}->{$_}==1) {
				$str.=" +";
			}
			elsif($cpdhash->{$ext}->{$cpd}->{$_}==-1) {
				$str.=" -";
			}
			elsif ($cpdhash->{$ext}->{$cpd}->{$_}>0) {
				$str.=" +".$cpdhash->{$ext}->{$cpd}->{$_}." * ";
			}
			else {
				$str.=$cpdhash->{$ext}->{$cpd}->{$_}." * ";
			}
			$str.="R".sprintf("%04d",$_)." ";
		}
		$str.=", = 0;\n";
		print($str);
	}
}
print("data;\n\nend;\n")
