#!/usr/bin/perl -I. -w
use strict;
use warnings;
use Tobin::IF;

@ARGV<2&&die("Too few arguments");
my $tobin=new Tobin::IF(1);

my $fbaset=$tobin->fbasetupGet($ARGV[0]);
open(WE, $ARGV[1])||die("Cannot open reversibles file");
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
my $trtf={};
foreach(@{$fbaset->{TFSET}}) {
	defined($skip->{$_->[0]})&&next;
	defined($revhash->{$_->[0]})&&($skip->{$revhash->{$_->[0]}}=1);
	my $tf=$tobin->transformationGet($_->[0]);
	my $excpd={};
	my $intcpd={};
	foreach my $cpd (@{$tf->[2]}) {
		$cpd->{id}==65&&next;
		$cpd->{ext}?($excpd->{$cpd->{id}}=$cpd->{sto}):
		($intcpd->{$cpd->{id}}=$cpd->{sto});
	}
	foreach my $cpd (keys(%{$excpd})) {
		defined($intcpd->{$cpd})&&($trtf->{$_->[0]}=($excpd->{$cpd}<0?-1:1)*$cpd)&&last;
	}
}
my $tfset={};
foreach(keys(%{$trtf})) {
	my $str="";
	my $tf;
	if(defined($revhash->{$_})) {
		if($_<$revhash->{$_}) {
			$str.=$_."/".$revhash->{$_};
			$tf=$_;
		}
		else {
			$str.=$revhash->{$_}."/".$_;
			$tf=$revhash->{$_};
		}
	}
	else {
		$str.=$_;
		$tf=$_;
	}
	my $tfdata=$tobin->transformationGet($tf);
	my $cpd=abs($trtf->{$_});
	$str.="\t".$tfdata->[0]."\t".abs($cpd);
	if(defined($revhash->{$_})) {
		my $sink;
		my $tfs=$tobin->transformationFindByCompounds({$cpd=>1},{});
		foreach my $rea (@{$tfs}) {
			if($tobin->transformationNameGet($rea)=~/^SINK.*\[e\]$/) {
				$sink=$rea;
				$tfset->{$rea}=1;
				last;
			}
		}
		my $source;
		$tfs=$tobin->transformationFindByCompounds({},{$cpd=>1});
		foreach my $rea (@{$tfs}) {
			if($tobin->transformationNameGet($rea)=~/^SOURCE.*\[e\]$/) {
				$source=$rea;
				$tfset->{$rea}=1;
				last;
			}
		}
		$str.="\t";
		defined($sink)&&($str.=$sink);
		$str.="\t";
		defined($source)&&($str.=$source);
	}
	else {
		if($trtf->{$_}>0) {
			my $sink;
			my $tfs=$tobin->transformationFindByCompounds({$cpd=>1},{});
			foreach my $rea (@{$tfs}) {
				if($tobin->transformationNameGet($rea)=~/^SINK.*\[e\]$/) {
					$sink=$rea;
					$tfset->{$rea}=1;
					last;
				}
			}
			defined($sink)&&($str.="\t".$sink);	
		}
		else {
			my $source;
			my $tfs=$tobin->transformationFindByCompounds({},{$cpd=>1});
			foreach my $rea (@{$tfs}) {
				if($tobin->transformationNameGet($rea)=~/^SOURCE.*\[e\]$/) {
					$source=$rea;
					$tfset->{$rea}=1;
					last;
				}
			}
			defined($source)&&($str.="\t\t".$source);
		}
	}
	print($str."\n");
	
}
exit;
my $tftab=[];
foreach(keys(%{$tfset})) {
	push(@{$tftab}, $_);
}
$tobin=new Tobin::IF(1004);
$tobin->transformationsetCreate("62sinsrc",$tftab);
