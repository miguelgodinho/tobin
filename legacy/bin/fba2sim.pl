#!/usr/bin/perl -I. -w
use strict;
use warnings;
use Tobin::IF;

my $tobin	= new Tobin::IF(1);
my $tfset=[];
my %fbares;
if(!$ARGV[0]) {
	my $fbaset=$tobin->fbasetupGet($ARGV[1]);
	foreach(@{$fbaset->{TFSET}}) {
		push(@{$tfset},$_->[0]);
	}
}
elsif($ARGV[0]==1) {
	%fbares=$tobin->fbaresGet($ARGV[1]);
	foreach(keys(%fbares)) {
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
open(WE,$ARGV[3])||die("cannot open excluded reactions file");
@tab=<WE>;
close(WE);
my $excl={};
foreach(@tab) {
	chomp;
	$excl->{$_}=1;
}
open(WE, "simcodes-new.csv");
@tab=<WE>;
close(WE);
my $simcodes={};
#foreach(@tab) {
#	chomp($_);
#	my @react=split(/\t/,$_);
#	$simcodes->{$react[1]}=$react[0];
#}
open(WE, "mcodes-new.csv")||die("No mcodes.");
@tab=<WE>;
close(WE);
my $mcodes={};
foreach(@tab) {
	chomp($_);
	my @mets1=split(/\t/,$_);
	$mcodes->{$mets1[1]}=$mets1[0];
}
my $skip={};
my $misscpd={};
my $simequ={};
my $expand=(@ARGV>4&&$ARGV[4])?1:0;
if($expand) {
	open(WE, $ARGV[5])||die("Cannot open equations file!");
	@tab=<WE>;
	close(WE);
	foreach(@tab) {
		chomp;
		my @tab1=split(/\t/,$_);
		$simequ->{$tab1[0]}=$tab1[1];
	}
}
my $stochm={};
foreach(@{$tfset}) {
	defined($excl->{$_})&&next;
	defined($skip->{$_})&&next;
	defined($revhash->{$_})&&($skip->{$revhash->{$_}}=1);
	print(defined($revhash->{$_})?
	($_<$revhash->{$_}?$_."/".$revhash->{$_}:$revhash->{$_}."/".$_):$_);
	if(defined($simcodes->{$_})) {
		if($expand) {
			my $equ=$simequ->{$simcodes->{$_}};
			defined($revhash->{$_})?
			($equ=~s/-->/<==>/):
			($equ=~s/<==>/-->/);
			print("\t$equ");
		}
		else {
			print("\t".$simcodes->{$_});
#			print((defined($revhash->{$_})?"(R)":"(I)"));
		}
	}
	elsif(defined($revhash->{$_})&&defined($simcodes->{$revhash->{$_}})) {
		if($expand) {
			my $equ=$simequ->{$simcodes->{$revhash->{$_}}};
			$equ=~s/-->/<==>/;
			print("\t$equ");
		}
		else {
			print("\t".$simcodes->{$revhash->{$_}}."(R)");
		}
	}
	else {
		my $tf=$tobin->transformationGet($_);
#		my $good=1;
		my $subs={0=>{},1=>{}};
		my $prods={0=>{},1=>{}};
		foreach my $cpd (@{$tf->[2]}) {
#			defined($mcodes->{$cpd->{id}})||($good=0);
			$cpd->{sto}<0?($subs->{$cpd->{ext}}->{$cpd->{id}}=abs($cpd->{sto})):
			($prods->{$cpd->{ext}}->{$cpd->{id}}=$cpd->{sto});
		}
		my $ie;
		my $iet=["c","e"];
		(keys(%{$subs->{0}})||keys(%{$prods->{0}}))||($ie='e');
		(keys(%{$subs->{1}})||keys(%{$prods->{1}}))||($ie='c');
		print("\t");
		defined($ie)&&print("[$ie] :");
		my $str="";
		foreach my $ext(0,1) {
			foreach my $cpd (keys(%{$subs->{$ext}})) {
				$subs->{$ext}->{$cpd}!=1&&($str.=" ($subs->{$ext}->{$cpd})");
#				$str.=defined($mcodes->{$cpd})?" $mcodes->{$cpd}":(" C".sprintf("%04d",$cpd));
				$str.=" ".$tobin->compoundNameGet($cpd);
				defined($ie)||($str.="[$iet->[$ext]]");
				$str.=" +";
#				defined($mcodes->{$cpd})||($misscpd->{$cpd}=1);
			}
		}
		chop($str);
		chop($str);
		$str.=defined($revhash->{$_})?" <==>":" -->";
		foreach my $ext(0,1) {
			foreach my $cpd (keys(%{$prods->{$ext}})) {
				$prods->{$ext}->{$cpd}!=1&&($str.=" ($prods->{$ext}->{$cpd})");
#				$str.=defined($mcodes->{$cpd})?" $mcodes->{$cpd}":(" C".sprintf("%04d",$cpd));
				$str.=" ".$tobin->compoundNameGet($cpd);
				defined($ie)||($str.="[$iet->[$ext]]");
				$str.=" +";
#				defined($mcodes->{$cpd})||($misscpd->{$cpd}=1);
			}
		}
		chop($str);
		chop($str);
		print($str);
	}
	if($ARGV[0]==1) {
		print("\t".((defined($revhash->{$_})&&$fbares{$revhash->{$_}}>0)?
		"-".$fbares{$revhash->{$_}}:$fbares{$_}));
	}
	print("\n");
}
foreach(keys(%{$misscpd})) {
	print("C".sprintf("%04d",$_)."\t".$tobin->compoundNameGet($_).
	(defined($mcodes->{$_})&&"\t".$mcodes->{$_})."\n");
}
