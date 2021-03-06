#!/usr/bin/perl -I. -w
use strict;
use warnings;
use Tobin::IF;
@ARGV<2&&die("Too few arguments.");

my $uhash={9509=>1,9513=>1,9514=>1,9516=>1,9518=>1,9521=>1,9522=>1,9525=>1,9530=>1,
	9531=>1,9532=>1,9533=>1,9539=>1,9544=>1,9550=>1,9552=>1,9554=>1,9557=>1,9563=>1,
	9564=>1,9566=>1,9569=>1,9571=>1,9508=>1,9517=>1,9520=>1,9526=>1,9536=>1,9540=>1,
	9541=>1,9543=>1,9546=>1,9547=>1,9549=>1,9553=>1,9555=>1,9559=>1,9562=>1,9567=>1,
	9573=>1,9574=>1,9511=>1,9515=>1,9523=>1,9524=>1,9534=>1,9537=>1,9538=>1,9542=>1,
	9545=>1,9551=>1,9556=>1,9560=>1,9561=>1,9565=>1,9568=>1,9570=>1,9575=>1,9576=>1,
	9397=>1,9510=>1,9512=>1,9519=>1,9528=>1,9535=>1,9548=>1,9558=>1,9577=>1,9216=>1,
	9580=>1,9581=>1,9583=>1};
my $lhash={9579=>1,9372=>1};

my $tobin		= new Tobin::IF($ARGV[0]);
my $fbasetup=$tobin->fbasetupGet($ARGV[1]);
foreach(@{$fbasetup->{TFSET}}) {
	if(defined($uhash->{$_->[0]})) {
		$_->[3]=undef;
#		warn $_->[0]
	}
	elsif(defined($lhash->{$_->[0]})) {
		$_->[3]=0;
	}
}
if($tobin->fbasetupUpdate($ARGV[1],undef,$fbasetup->{TFSET},undef)) {
 			die("Problem updating database.");
}
