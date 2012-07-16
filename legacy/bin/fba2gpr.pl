#!/usr/bin/perl -I. -w
use strict;
use warnings;
use Tobin::IF;

@ARGV<4&&die("Too few arguments");
my $tobin	= new Tobin::IF(1);
my $tfset=[];
open(WE,$ARGV[4])||die("Cannot open tf anno!");
my @tab=<WE>;
close(WE);
my $tfanno={};
foreach(@tab) {
        chomp;
        my @tab1=split(/\t/,$_);
        my $tf=shift(@tab1);
        $tfanno->{$tf}={};
        foreach my $ec(@tab1) {
                $tfanno->{$tf}->{$ec}=1;
        }
}

my $cpanno={};
open(WE,$ARGV[6])||die("Cannot open cp anno!");
@tab=<WE>;
close(WE);
foreach(@tab) {
        chomp;
        my @tab1=split(/\t/,$_);
        my $cp=shift(@tab1);
        $cpanno->{$cp}={};
        foreach my $ge (@tab1) {
#               defined($exgenes->{$ge})&&next;
                $cpanno->{$cp}->{$ge}=1;
        }
}
open(WE,$ARGV[5])||die("Cannot open ec anno!");
@tab=<WE>;
close (WE);
my $ecanno={};
foreach(@tab) {
        chomp;
        my @tab1=split(/\t/,$_);
        my $ec=shift(@tab1);
        $ecanno->{$ec}={};
        foreach my $cp (@tab1) {
                $ecanno->{$ec}->{$cp}=1;
        }
}
open(WE, $ARGV[2])||die("Cannot open reversible file.");
@tab=<WE>;
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
open(WE, $ARGV[3])||die("Cannot open excluded file.");
@tab=<WE>;
close(WE);
my $exchash={};
foreach(@tab) {
	chomp;
	$exchash->{$_}=1;
}
my $assigned={};
foreach(@{$tfset}) {
	defined($exchash->{$_})&&next;
	defined($assigned->{$_})&&next;
	defined($revhash->{$_})&&($assigned->{$revhash->{$_}}=1);
	my $tf=$tobin->transformationGet($_);
	my $anotkey=defined($revhash->{$_})?($_< $revhash->{$_}?$_."/".$revhash->{$_}:
	$revhash->{$_}."/".$_):$_;
	if(!defined($tfanno->{$anotkey})) {
		print($anotkey."\n");
		next;
	}
	my $cplist={};
	my $annot="(";
	foreach my $ec (keys(%{$tfanno->{$anotkey}})) {
		foreach my $cp (keys(%{$ecanno->{$ec}})) {
			$cplist->{$cp}=1;
		}
	}
	foreach my $cp (keys(%{$cplist})) {
		$annot.=" (";
		foreach my $ge (keys(%{$cpanno->{$cp}})) {
			$annot.=" $ge and"
		}
		$annot=~s/and$//;
		$annot.=") or";
	}
	$annot=~s/or$//;
	$annot.=")";
	if($annot!~/and|or/) {
		$annot=~s/\( \(//;
		$annot=~s/\) \)//;
	}
	if($annot=~/and/&&$annot!~/or/||$annot!~/and/&&$annot=~/or/) {
		$annot=~s/\( \(/(/;
		$annot=~s/\) \)/)/;
	}
	print($anotkey."\t".$annot."\n");
	
}
