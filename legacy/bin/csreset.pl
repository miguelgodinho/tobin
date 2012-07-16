#!/usr/bin/perl -I.
use strict;
use warnings;
use Tobin::IF;

@ARGV<2&&die("Too few arguments.");

my $tobin		= new Tobin::IF($ARGV[0]);
open(WE, "GPR-gene.csv")||die("Cannot open protein anno.");
my @prot=<WE>;
close(WE);

my $protanno = {};

foreach(@prot) {
	chomp($_);
	my @anno=split(/\t/,$_);
	my $glist=[];
	for(my $i=1;$i<@anno;$i++) {
		if($anno[$i]=~m/(b[0-9]{4})/) {
			push(@{$glist},$1);
		}
		else {
			print("Problem with blattner name for $anno[$i].\n");
		}
	}
	$protanno->{$anno[0]}=$glist;
}
 open(WE, "GPR-rea.csv")||die("Cannot open reaction anno.");
 my @rea=<WE>;
 close(WE);
 
 my $reaanno={};
 foreach(@rea) {
 	chomp($_);
 	my @anno=split(/\t/,$_);
 	my $glist=[];
 	for(my $i=1;$i<@anno;$i++) {
 		if(!defined($protanno->{$anno[$i]})) {
 			print("Problem with protein name for $anno[$i].\n");
 			next;
 		}
 		push(@{$glist},@{$protanno->{$anno[$i]}});		
 	}
 	if(defined($reaanno->{$anno[0]})) {
 		push(@{$reaanno->{$anno[0]}},$glist);
 	}
 	else {
 		$reaanno->{$anno[0]}=[$glist];
 	}
 }
 my $genehash={};
 foreach(keys(%{$reaanno})) {
 	foreach my $glist (@{$reaanno->{$_}}) {
 		foreach my $gene (@{$glist}) {
	 		if(defined($genehash->{$gene})) {
 				push(@{$genehash->{$gene}},$_);
 			}
 			else {
 				$genehash->{$gene}=[$_];
 			}
 		}
 	}
 }
 print (keys(%{$genehash})."\n");
 open(WE,"iJ904-mod.csv")||die("Cannot open reaction list.");
my @rlist=<WE>;
close(WE);
open(WE, "simcodes.csv");
my @simcodes=<WE>;
close(WE);
my $reacts={};
foreach(@simcodes) {
	chomp($_);
	my @react=split(/\t/,$_);
	$reacts->{$react[0]}=(@react==2?[$react[1]]:[$react[1],$react[2]]);
}
my $fbacodes={};
foreach(@rlist) {
	chomp($_);
	my @react=split(/\t/,$_);
	$fbacodes->{$react[0]}=($react[1])?
	[$reacts->{$react[0]}->[0],$reacts->{$react[0]}->[1]]:
	[$reacts->{$react[0]}->[0]];
}
 my $genelist;
 @{$genelist}=sort(keys(%{$genehash}));
 my $fbasetup=$tobin->fbasetupGet($ARGV[1]);
 my $fbamap={};
 for(my $i=0;$i<@{$fbasetup->{TFSET}};$i++) {
 	$fbamap->{$fbasetup->{TFSET}->[$i]->[0]}=$i;
 }
 foreach(keys(%{$reaanno})) {
 	if(!defined($fbacodes->{$_}->[0])) {
 		print($_."\n");
 	}
 }
 foreach(keys(%{$reaanno})) {
 	$fbasetup->{TFSET}->[$fbamap->{$fbacodes->{$_}->[0]}]->[3]=undef;
	@{$fbacodes->{$_}}==2&&
	($fbasetup->{TFSET}->[$fbamap->{$fbacodes->{$_}->[1]}]->[3]=undef);
 }
 if($tobin->fbasetupUpdate($ARGV[1],undef,$fbasetup->{TFSET},undef)) {
 		die("Problem updating database.");
 }
