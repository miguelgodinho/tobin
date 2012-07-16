#!/usr/bin/perl -I. -w
use strict;
use warnings;
use Tobin::IF;

@ARGV<4&&die("Too few arguments");
my $tobin=new Tobin::IF(1);
my $fbaset=$tobin->fbasetupGet($ARGV[1]);
open(WE, $ARGV[2])||die("Cannot open reversibles file");
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
open(WE, $ARGV[3])||die("Cannot open blockable file.");
my $blockhash={};
@tab=<WE>;
close(WE);
foreach(@tab) {
	chomp;
	$blockhash->{defined($revhash->{$_})?
		($_<$revhash->{$_}?$_:$revhash->{$_}):$_}=0;
}

open(WE,$ARGV[0])||die("Cannot open result file");
@tab=<WE>;
close(WE);
my $reshash={};
foreach (@{$fbaset->{TFSET}}) {
#	print($_->[0]."\n");
	$reshash->{defined($revhash->{$_->[0]})?
		($_->[0]<$revhash->{$_->[0]}?$_->[0]:$revhash->{$_->[0]}):$_->[0]}=0;
}
foreach(@tab) {
	chomp;
	if($_=~/ R([0-9]{4})[ ]+([-0-9\.e]+)/) {
		my $num=$1;
		my $val=$2;
		$num=~s/^0+//;
		if(defined($reshash->{$num})) {
			$reshash->{$num}=$val;
		}
		elsif(defined($revhash->{$num}&&defined($reshash->{$revhash->{$num}}))) {
			$reshash->{$revhash->{$num}}=-$val;
		}
		else {
			die("Unknown reaction number (flux) - $num");
		}
		
	}
	elsif($_=~/ ACTR([0-9]{4})/) {
		my $num=$1;
		$num=~s/^0+//;
		if(defined($blockhash->{$num})) {
			$blockhash->{$num}=1;
		}
		elsif(defined($revhash->{$num}&&defined($blockhash->{$revhash->{$num}}))) {
			$blockhash->{$revhash->{$num}}=1;
		}
		else {
			die("Unknown reaction number (activity) - $num");
		}
	}
	
}
print("Fluxes:\n");
foreach(keys(%{$reshash})) {
	my $str=$_;
	defined($revhash->{$_})&&($str.="/".$revhash->{$_});
	$str.="\t".$reshash->{$_};
	print($str."\n");
}
print("Activity:\n");
foreach(keys(%{$blockhash})) {
	my $str=$_;
	defined($revhash->{$_})&&($str.="/".$revhash->{$_});
	$str.="\t".$blockhash->{$_};
	print($str."\n");
}
