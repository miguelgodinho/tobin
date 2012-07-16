#!/usr/bin/perl
use strict;
use warnings;
use Tobin::IF;
@ARGV<4&&die("Too few arguments");
my $tobin		= new Tobin::IF($ARGV[0]);
open(WE,$ARGV[1])||die("Cannot open the file: ".$ARGV[1]."!\n");
my @rlist=<WE>;
close(WE);
open(WE, $ARGV[2])||die("Cannot open simcodes");
my @simcodes=<WE>;
close(WE);
my $reacts={};
foreach(@simcodes) {
	chomp($_);
	my @react=split(/\t/,$_);
	$reacts->{$react[0]}=(@react==2?[$react[1]]:[$react[1],$react[2]]);
}
my $fbalist=[];
foreach(@rlist) {
	chomp($_);
	my @react=split(/\t/,$_);
	defined($reacts->{$react[0]})?push(@{$fbalist},$reacts->{$react[0]}->[0]):
	die("Can't find reaction: ".$react[0]);
	($reacts->{$react[0]}->[0]eq"")&&warn($react[0]);
	if($react[1]) {
		@{$reacts->{$react[0]}}==2?push(@{$fbalist},$reacts->{$react[0]}->[1]):
		die("Cant find reverse of reaction: ".$react[0]);
		($reacts->{$react[0]}->[1]eq"")&&warn($react[0]);
	}
}
#foreach(@{$fbalist}) {
#	print($_."\n");
#}
#exit;
my $tmphash={};
foreach(@{$fbalist}) {
	$tmphash->{$_}=1;
}
foreach(keys(%{$tmphash})) {
	my $tf=$tobin->transformationGet($_);
}
print(@{$fbalist}."\t".keys(%{$tmphash})."\n");
#exit;
$tobin->transformationsetCreate($ARGV[3],[(keys(%{$tmphash}))]);
