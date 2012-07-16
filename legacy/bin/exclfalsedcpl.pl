#!/usr/bin/perl -I. -w
use strict;
use warnings;

@ARGV||die("Too few arguments");

my $fcoupled=bfchash($ARGV[0]);
my $expdtree=bfullexp($ARGV[0],$ARGV[1],$fcoupled);
open(WE,$ARGV[2])||die("Cannot open check file.");
my @tab=<WE>;
close(WE);
foreach(@tab) {
	my @tab1=split(/\t|->/,$_);
	if(defined($expdtree->{$tab1[0]}->{$tab1[1]})) {
		$_=~/>/&&print($tab1[0]."\t".$tab1[1]."- False negative\n");
	}
	else {
		if($_=~/>/) {
			print($_);
		}
		else {
			print($tab1[0]."\t".$tab1[1]." - False positive\n");
		}
	}
}

sub bfullexp {
	my $file=shift;
	my $exclfile=shift;
	my $fcoupled=shift;
	open(WE,$exclfile)||die("Cannot open excluded file");
	my @tab=<WE>;
	close (WE);
	my $excluded={};
	foreach(@tab) {
		chomp;
		my @tab1=split(/\t/,$_);
		defined($excluded->{$tab1[0]})||($excluded->{$tab1[0]}={});
		$excluded->{$tab1[0]}->{$tab1[1]}=1;
	}
	open(WE,$file)||die("Cannot open input file - $file");
	@tab=<WE>;
	close(WE);
	my @tab1=grep(/^Directionally/../^Fully/,@tab);
	my $dcoupled={};
	for(1..(@tab1-2)) {
		chomp($tab1[$_]);
		my @tab2=split(/\t/,$tab1[$_]);
		my @tab3=split(/, /,$tab2[1]);
		$dcoupled->{$tab2[0]}={};
		foreach my $tf (@tab3) {
			defined($excluded->{$tab2[0]}->{$tf})&&
			($dcoupled->{$tab2[0]}->{$tf}=1);
		}
	}
	warn(keys(%{$dcoupled})."\n");
	@tab1=grep(/^Fully/../^Partially/,@tab);
	my $nodehash={};
	for(1..(@tab1-2)) {
		chomp($tab1[$_]);
		my @tab2=split(/: /,$tab1[$_]);
		my @tab3=split(/, /,$tab2[1]);
		foreach my $tf (@tab3) {
			$nodehash->{$tf}=$tab2[0];
		}
	}
	foreach(keys(%{$dcoupled})) {
		if(defined($fcoupled->{nodehash}->{$_})) {
			foreach my $tf (keys(%{$fcoupled->{fcoupled}->{$fcoupled->{nodehash}->{$_}}})) {
				defined($dcoupled->{$tf})||($dcoupled->{$tf}={});
				foreach my $ctf (keys(%{$dcoupled->{$_}})) {
					if(defined($fcoupled->{nodehash}->{$ctf})) {
						foreach my $cctf(keys(%{$fcoupled->{fcoupled}->{$fcoupled->{nodehash}->{$ctf}}})) {
							$dcoupled->{$tf}->{$cctf}=1;
						}
					}
					$dcoupled->{$tf}->{$ctf}=1;
				}
			}	
		}
		else {
			foreach my $ctf (keys(%{$dcoupled->{$_}})) {
				defined($fcoupled->{nodehash}->{$ctf})||next;
				foreach my $cctf(keys(%{$fcoupled->{fcoupled}->{$fcoupled->{nodehash}->{$ctf}}})) {
					$dcoupled->{$_}->{$cctf}=1;
				}
			}
			
		}
	}
	return($dcoupled);
}

sub bfchash {
	my $file=shift;
	open(WE,$file)||die("Cannot open input file - $file");
	my @tab=<WE>;
	close(WE);
	my $fcoupled1={};
	my $nodehash1={};
	my @tab1=grep(/^Fully/../^Partially/,@tab);
	for(1..(@tab1-2)) {
		chomp($tab1[$_]);
		my @tab2=split(/: /,$tab1[$_]);
		my @tab3=split(/, /,$tab2[1]);
		$fcoupled1->{$tab2[0]}={};
		foreach my $tf (@tab3) {
			$nodehash1->{$tf}=$tab2[0];
			$fcoupled1->{$tab2[0]}->{$tf}=1;
		}
	}
	@tab1=grep(/^Partially/../^digraph/,@tab);
	for(1..(@tab1-2)) {
		chomp($tab1[$_]);
		my @tab2=split(/: /,$tab1[$_]);
		my @tab3=split(/, /,$tab2[1]);
		defined($fcoupled1->{$tab2[0]})||($fcoupled1->{$tab2[0]}={});
		foreach my $tf (@tab3) {
			$nodehash1->{$tf}=$tab2[0];
			$fcoupled1->{$tab2[0]}->{$tf}=1;
		}
	}
	return({nodehash=>$nodehash1,fcoupled=>$fcoupled1});
}
