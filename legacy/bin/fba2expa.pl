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
open(WE, $ARGV[3])||die("Cannot open external file.");
@tab=<WE>;
close(WE);
my $exthash={0=>{},1=>{}};
foreach(@tab) {
	chomp;
	my @tab1=split(/\t/,$_);
	$exthash->{$tab1[1]}->{$tab1[0]}=$tab1[2];
	warn($exthash->{$tab1[1]}->{$tab1[0]});
}
open(WE, "simcodes-new.csv");
@tab=<WE>;
close(WE);
my $simcodes={};
foreach(@tab) {
	chomp($_);
	my @react=split(/\t/,$_);
	$simcodes->{$react[1]}=$react[0];
}
open(WE, "mcodes-new.csv")||die("No mcodes.");
@tab=<WE>;
close(WE);
my $mcodes={};
foreach(@tab) {
	chomp($_);
	my @mets1=split(/\t/,$_);
	$mcodes->{$mets1[1]}=$mets1[0];
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
		->{$cpd->{ext}}->{$cpd->{id}}=$cpd->{sto};
	}
	my $equ="";
	if(defined($revhash->{$_})&&!defined($simcodes->{$_})&&
	defined($simcodes->{$revhash->{$_}})) {
		foreach my $cp("prod","subs") {
			foreach my $ext(0,1) {
				foreach my $id(keys(%{$cpdhash->{$cp}->{$ext}})) {
					my $cpdname=(defined($mcodes->{$id})?$mcodes->{$id}:
					"C".sprintf("%04d",$id)).($ext?"[e]":"");
		#		my $cpdname=($ext?"EX":"")."C".sprintf("%04d",$id);
					defined($exthash->{$ext}->{$id})?($echash->{$cpdname}=$exthash->{$ext}->{$id}):
					($ichash->{$cpdname}=1);
		#			defined($exthash->{$ext}->{$id})&&warn("$cpdname\t".$echash->{$cpdname});
					$equ=$equ."\t".-$cpdhash->{$cp}->{$ext}->{$id}."\t".$cpdname;
				}
			}
		}
	}
	else {
		foreach my $cp("subs","prod") {
			foreach my $ext(0,1) {
				foreach my $id(keys(%{$cpdhash->{$cp}->{$ext}})) {
					my $cpdname=(defined($mcodes->{$id})?$mcodes->{$id}:
					"C".sprintf("%04d",$id)).($ext?"[e]":"");
		#			my $cpdname=($ext?"EX":"")."C".sprintf("%04d",$id);
					defined($exthash->{$ext}->{$id})?($echash->{$cpdname}=$exthash->{$ext}->{$id}):
					($ichash->{$cpdname}=1);
			#		defined($exthash->{$ext}->{$id})&&warn("$cpdname\t".$echash->{$cpdname});
					$equ=$equ."\t".$cpdhash->{$cp}->{$ext}->{$id}."\t".$cpdname;
				}
			}
		}
	}
	$equ=$equ."\n";
	if(defined($revhash->{$_})) {
		my $rname=defined($simcodes->{$_})?
			$simcodes->{$_}:(defined($simcodes->{$revhash->{$_}})?
			$simcodes->{$revhash->{$_}}:("R".sprintf("%04d",$_)));
		$rrhash->{$rname}=$equ;
		$assigned->{$_}=1;
		$assigned->{$revhash->{$_}}=1;
	}
	else {
		$irhash->{defined($simcodes->{$_})?
			$simcodes->{$_}:("R".sprintf("%04d",$_))}=$equ;
		$assigned->{$_}=1;
	}
}
open(WY, ">$ARGV[4]");
print(WY"(Internal fluxes)\n");
foreach(keys(%{$rrhash})) {
	print(WY $_."\tR".$rrhash->{$_});
}
foreach(keys(%{$irhash})) {
	print(WY $_."\tI".$irhash->{$_});
}
print(WY"(External fluxes)\n");
foreach(keys(%{$echash})) {
	print(WY$_."\t");
	if($echash->{$_}==1) {
		print(WY"Output")
	}
	elsif($echash->{$_}==-1) {
		print(WY"Input")
	}
	elsif(!$echash->{$_}) {
		print(WY"Free")
	}
	else {
		die("Bad mode for ".$echash->{$_});
	}
	print(WY"\n");
}
close(WY);
