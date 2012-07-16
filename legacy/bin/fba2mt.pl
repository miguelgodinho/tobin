#!/usr/bin/perl -I. -w
use strict;
use warnings;
use Tobin::IF;

@ARGV<6&&die("Too few arguments");
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
my $exthash={0=>{},1=>{}};
if($ARGV[3]) {
	open(WE, $ARGV[3])||die("Cannot open external file.");
	@tab=<WE>;
	close(WE);
	foreach(@tab) {
		chomp;
		my @tab1=split(/\t/,$_);
		$exthash->{$tab1[1]}->{$tab1[0]}=1;
	}
}
open(LOG,">$ARGV[5]");
my $irhash={};
my $rrhash={};
my $assigned={};
my $ichash={};
my $echash={};
foreach(@{$tfset}) {
	defined($assigned->{$_})&&next;
	my $tf=$tobin->transformationGet($_);
	if($tf->[3]->[0]=~/^SOURCE|^SINK/) {
		print(LOG "Excluded reaction: $_ - $tf->[3]->[0]\n");
		next;
	}
	my $cpdhash={prod=>{0=>{},1=>{}},subs=>{0=>{},1=>{}}};
	foreach my $cpd (@{$tf->[2]}) {
		$cpdhash->{($cpd->{sto}<0?"subs":"prod")}
		->{$cpd->{ext}}->{$cpd->{id}}=abs($cpd->{sto});
		$cpd->{ext}&&!$ARGV[3]&&($exthash->{1}->{$cpd->{id}}=1);
	}
	my $equ="";
	foreach my $cp("subs","prod") {
		foreach my $ext(0,1) {
			foreach my $id(keys(%{$cpdhash->{$cp}->{$ext}})) {
				my $cpdname=($ext?"EX":"")."C".sprintf("%04d",$id);
				defined($exthash->{$ext}->{$id})?$echash->{$cpdname}=1:
				$ichash->{$cpdname}=1;
				$equ=$equ.$cpdhash->{$cp}->{$ext}->{$id}." ".$cpdname." + ";
			}
		}
		$equ=~s/ \+ $//;
		$equ=$equ." = ";
	}
	$equ=~s/ = $//;
	$equ=$equ." .\n";
	if(defined($revhash->{$_})) {
		$rrhash->{"RR".sprintf("%04d",$_)}=$equ;
		$assigned->{$_}=1;
		$assigned->{$revhash->{$_}}=1;
	}
	else {
		$irhash->{"IR".sprintf("%04d",$_)}=$equ;
		$assigned->{$_}=1;
	}
}
open(WY, ">$ARGV[4]");
print(WY "-ENZREV\n");
foreach(keys(%{$rrhash})) {
	print(WY $_." ");
}
print(WY "\n\n-ENZIRREV\n");
foreach(keys(%{$irhash})) {
	print(WY $_." ");
}
print(WY "\n\n-METINT\n");
foreach(keys(%{$ichash})) {
	print(WY $_." ");
}
print(WY "\n\n-METEXT\n");
foreach(keys(%{$echash})) {
	print(WY $_." ");
}
print(WY "\n\n-CAT\n");
foreach(keys(%{$irhash})) {
	print(WY $_." : ".$irhash->{$_});
}
foreach(keys(%{$rrhash})) {
	print(WY $_." : ".$rrhash->{$_});
}
close(WY);
close(LOG);
