#!/usr/bin/perl -w
#
use strict;
use warnings;


@ARGV<2&&die("Too few arguments");

open(WE, $ARGV[0])||die("Cannot open input file");
my @input=<WE>;
close(WE);
my $rrhash={};
my $irhash={};
my $imet={};
my $emet={};
my $ext=0;
foreach(@input) {
	chomp;
	length||next;
	($_=~m%^//%)&&next;
	($_=~/\(External fluxes\)|\(Exchange Fluxes\)/)&&($ext=1)&&next;
	$ext||next;
	my @tab=split(/\s+/,$_);
	if($tab[1] eq "Free") {
		$emet->{$tab[0]}=0;
	}
	elsif($tab[1] eq "Input") {
		$emet->{$tab[0]}=-1;
	}
	elsif($tab[1] eq "Output") {
		$emet->{$tab[0]}=1;
	}
	else {
		die($tab[0]." - bad echange type");
	}
}
#shift(@input);
foreach(@input) {
	 length||next;
	 ($_=~m%^//%)&&next;
	 ($_=~/\(Internal Reactions\)|\(Internal Fluxes\)/)&&next;
	 $_=~/\(External fluxes\)|\(Exchange Fluxes\)/&&last;
	 my @tab=split(/\s+/,$_);
	 my $subs={};
	 my $prod={};
	 for(my $i=2;$i<@tab;$i+=2) {
		 $tab[$i]<0?($subs->{$tab[$i+1]}=abs($tab[$i])):($prod->{$tab[$i+1]}=$tab[$i]);
		 defined($emet->{$tab[$i+1]})||($imet->{$tab[$i+1]}=1);
	 }
	 my $equ="";
	 foreach my $cpd (keys(%{$subs})) {
		 $equ=$equ." ".$subs->{$cpd}." ".$cpd." +";
	 }
	 $equ=~s/\+$/=/;
	 foreach my $cpd (keys(%{$prod})) {
		  $equ=$equ." ".$prod->{$cpd}." ".$cpd." +";
	  }
	  $equ=~s/\+$/./;
	  ($tab[1] eq "I")?($irhash->{$tab[0]}=$equ):($rrhash->{$tab[0]}=$equ);
}
open(WY,">".$ARGV[1])||die("Cannot open output file");
foreach(keys(%{$emet})) {
	if(defined($imet->{"EX".$_})) {
		die("Duplicate mets");
	}
	else {
		$imet->{$_}=1;
	}
}
foreach(keys(%{$emet})) {
	(defined($irhash->{"EXF".$_})||defined($rrhash->{"EXF".$_}))&&
	die("Duplicate tfs");
}
my $emet1={};
foreach(keys(%{$emet})) {
	$emet1->{"EX".$_}=1;
	if(!$emet->{$_}) {
		$rrhash->{"EXF".$_}=" $_ = EX$_ .";
	}
	else {
		$irhash->{"EXF".$_}=($emet->{$_}>0?" $_ = EX$_ .":" EX$_ = $_ .");
	}
}
print(WY "-ENZREV\n");
foreach(keys(%{$rrhash})) {
	print(WY $_." ");
}
print(WY "\n\n-ENZIRREV\n");
foreach(keys(%{$irhash})) {
        print(WY $_." ");
}
print(WY "\n\n-METINT\n");
foreach(keys(%{$imet})) {
        print(WY $_." ");
}
print(WY "\n\n-METEXT\n");
foreach(keys(%{$emet1})) {
        print(WY $_." ");
}
print(WY "\n\n-CAT\n");
foreach(keys(%{$irhash})) {
	print(WY $_." :".$irhash->{$_}."\n");
}
foreach(keys(%{$rrhash})) {
	print(WY $_." :".$rrhash->{$_}."\n");
}
