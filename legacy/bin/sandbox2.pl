#!/usr/bin/perl
use strict;
use warnings;
use Tobin::IF;
use vdsxls::readvds;

my $tobin		= new Tobin::IF(1004);
#my $set1=[9026,9027,9038,9032,9033,9030,9031,9012,9013,9014,9015,9024,9025,9036,9016,9020,9021,9018,
#9019,9022,9010,9011,9046,9045,9034,9035,9373,9374,9028,9029,9009,9299,9040,9039,9041];
#$tobin->transformationsetCreate("ecorepl", $set1);
#open(WE, "/home/jap04/MetabNets/ABo/c3a.out");
#@set=<WE>;
#close(WE);
#$set1 = [];
#foreach(@set) {
#	chomp $_;
#	push(@{$set1},$_);
#}
# $tobin->transformationsetCreate("AboC3", $set1);

#my $fbaset=$tobin->fbasetupGet(29);
#my %fbares=$tobin->fbaresGet(3256);
#foreach(@{$fbaset->{TFSET}}) {
#	if(!defined($fbares{$_->[0]})) {
#		print($_->[0]."\n");
#	}
#}
my $fbaset=$tobin->fbasetupGet(48);
 #$tobin		= new Tobin::IF(1004);
$tobin->fbasetupCreate("eco-csaba-1",$fbaset->{TFSET},$fbaset->{TYPE})
