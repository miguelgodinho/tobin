#!/usr/bin/perl -I. -w
use strict;
use warnings;
use Tobin::IF;

@ARGV<2&&die("Too few arguments");
my $tobin	= new Tobin::IF(1);
my $tfset=[];
my $limits={};
my $annotation={};

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
if($ARGV[0]) {
	my $fbaset=$tobin->fbasetupGet($ARGV[1]);
	foreach(@{$fbaset->{TFSET}}) {
		push(@{$tfset},$_->[0]);
		$limits->{$_->[0]}=[$_->[2],$_->[3]];
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
my $cpdhash=[{},{}];
foreach(@{$tfset}) {
	defined($exchash->{$_})&&next;
	defined($assigned->{$_})&&next;
	defined($revhash->{$_})&&($assigned->{$revhash->{$_}}=1);
	my $tf=$tobin->transformationGet($_);
	foreach my $cpd (@{$tf->[2]}) {
		$cpdhash->[$cpd->{ext}]->{$cpd->{id}}=1; 
	}
	
	
}
warn(keys(%{$cpdhash->[0]})."\n");
#foreach(keys(%{$cpdhash->[0]})) {
#	warn $_;
#}
warn(keys(%{$cpdhash->[1]})."\n");

foreach my $ext (1,0) {
	foreach (keys(%{$cpdhash->[$ext]})) {
		my $charge=$tobin->compoundChargeGet($_);
		defined($charge)||($charge=0);
		print(($ext?"EC":"IC").sprintf("%05d",$_).
		"\t".$tobin->compoundNameGet($_).($ext?"[e]":"")."\n");
	}
}
$assigned={};
my $exctf={};
foreach(@{$tfset}) {
	defined($exchash->{$_})&&next;
	defined($assigned->{$_})&&next;
	defined($revhash->{$_})&&($assigned->{$revhash->{$_}}=1);
	my $tf=$tobin->transformationGet($_);
	if($tf->[3]->[0]=~/^SOURCE|^SINK/) {
		$exctf->{$_}=1;
		next;
	}
	my $rev=defined($revhash->{$_});
	my $min=$rev?(defined($limits->{$revhash->{$_}}->[1])?
	-$limits->{$revhash->{$_}}->[1]:-999999):$limits->{$_}->[0];
	my $max=defined($limits->{$_}->[1])?$limits->{$_}->[1]:999999;
	my $reac={};
	my $prod={};
	foreach my $cpd (@{$tf->[2]}) {
		$cpd->{sto}<0?($reac->{($cpd->{ext}?"EC":"IC").sprintf("%05d",$cpd->{id})}=
		-$cpd->{sto}):($prod->{($cpd->{ext}?"EC":"IC").sprintf("%05d",$cpd->{id})}=
		$cpd->{sto});
	}
	my $name=$tobin->transformationNameGet($_);
	$name=~s/>/&gt;/g;
	$name=~s/</&lt;/g;
	print(($rev?"RR":"IR").sprintf("%05d",$_)."\t".$name);
	my $equa="";
	foreach my $cpd (keys(%{$reac})) {
		$equa.=($reac->{$cpd}!=1?$reac->{$cpd}." ":"").$cpd." + ";
	}
	$equa=substr($equa, 0, -3);
	$equa.=$rev?" <==> ":" --> ";
	foreach my $cpd (keys(%{$prod})) {
		$equa.=($prod->{$cpd}!=1?$prod->{$cpd}." ":"").$cpd." + ";
	}
	$equa=substr($equa, 0, -3);
	print("\t".$equa."\n");
}


