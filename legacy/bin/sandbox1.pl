#!/usr/bin/perl
use strict;
use warnings;
use Tobin::IF;
use vdsxls::readvds;

my $tobin		= new Tobin::IF(1);

my $tf=$tobin->transformationGet(9042);
my $errs=[];
$tf->[2]->[0]->{sto}=3;
$tobin->transformationAdd("Biomass paleco",[{user=>1004,link=>"bmpe"}],$tf->[2],["Biomass paleco"],$errs);
#if(@{$errs}) {
#	print("bledy\n!");
#}
#my %fbasetup=$tobin->fbaresGet(680);
#$tobin->fbasetupCreate("Coli1",$fbasetup->{TFSET},$fbasetup->{TYPE});
#my @klucze=keys(%fbasetup);
#my @wartosci=values(%fbasetup);
#my @zeros;
#foreach(keys(%fbasetup)) {
#	if($fbasetup{$_}==0) {
#		push(@zeros,$_);
#	}
#}
#print(@zeros."\n");
#
#my %fbasetup=$tobin->fbaresGet(3197);
#my %fbasetup1=$tobin->fbaresGet(3199);
#open(WY, ">fba-gc1.txt");
#foreach (keys(%fbasetup)) {
#	print(WY $_."\t".$tobin->transformationNameGet($_)."\t".$fbasetup{$_}."\t".$fbasetup1{$_}."\n");
#}
#close(WY);
#%fbasetup=$tobin->fbaresGet(3191);
#open(WY, ">fba2.txt");
#foreach (keys(%fbasetup)) {
#	print(WY $_."\t".$fbasetup{$_}."\n");
#}
#close(WY);
#
#open(WE,"/home/jap04/MetabNets/ABo/c1a.txt");
#my @class1=<WE>;
#close(WE);
#open(WY,">/home/jap04/MetabNets/ABo/c1a.out");
#open(PR,">/home/jap04/MetabNets/ABo/c1a.man");
#print(@class1."\n");
#my $count=0;
#my $count1=0;
#foreach(@class1) {
#	$count1++;
#	$count=0;
#	chomp($_);
#	my @cols=split(/,/,$_);
#	my $reacts=$tobin->transformationCandidatesGet($cols[0],1);
#	if($cols[1]==0) {
#		if(@{$reacts}==0) {
#			print(PR "Reaction $cols[0] - no reactions\n");
#			$count=1;
#		}
#		elsif(@{$reacts}==1) {
#			print(WY $reacts->[0]."\n");
#			$count=1;
#		}
#		elsif(@{$reacts}==2) {
#			my $rev=$tobin->transformationCandidatesGet($cols[0].".*R");
#			if(@{$rev}==1&&($rev->[0]==$reacts->[0]||$rev->[0]==$reacts->[1])) {
#				if($rev->[0]==$reacts->[0]) {
#					print(WY $reacts->[1]."\n");
#					$count=1;
#				}
#				else {
#					print(WY $reacts->[0]."\n");
#					$count=1;
#				}
#			}
#			else {
#				print(PR $cols[0]." - $reacts->[0] $reacts->[1]\n");
#				$count=1;
#			}
#		}
#		else {
#			print(PR $cols[0]." - $cols[1]");
#			$count=1;
#			foreach my $re (@{$reacts}) {
#				print(PR " ".$re);
#			}
#			print(PR "\n");
#		}
#	}
#	else {
#		if(@{$reacts}==0) {
#			print(PR "Reaction $cols[0] - no reactions\n");
#			$count=1;
#		}
#		elsif(@{$reacts}==1) {
#			my $reacts1=$tobin->transformationCandidatesGet($cols[0]." (R)",1);
#			if(@{$reacts1}==1) {
#				print(WY $reacts->[0]."\n".$reacts1->[0]."\n");
#			}
#			else {
#				print(PR "Reaction $cols[0] - not enough reactions: $reacts->[0]\n");
#			}
#			$count=1;
#		}
#		elsif(@{$reacts}==2) {
#			print(WY $reacts->[0]."\n".$reacts->[1]."\n");
#			$count=1;
#			$count=1;
#		}
#		else {
#			print(PR $cols[1]." - $cols[0]");
#			$count=1;
#			foreach my $re (@{$reacts}) {
#				print(PR " ".$re);
#			}
#			print(PR"\n");
#		}
#	}
#	if(!$count) { print($cols[0]." ".$cols[1]." ".@{$reacts}."\n");}
#}
#close(WY);
#close(PR);
#print($count." ".$count1."\n");
