#!/usr/bin/perl -I/home/jap04/workspace/pseudo/ -w
use strict;
use warnings;
use Tobin::IF;

my $tobin=new Tobin::IF(1);
my $fbaset=$tobin->fbasetupGet($ARGV[0]);
 
 my $mets={};
 foreach(@{$fbaset->{TFSET}}) {
 	my $tf=$tobin->transformationGet($_->[0]);
 	foreach my $met (@{$tf->[2]}) {
 		$mets->{$met->{id}}=1;
 	}
 }
 my $excluded={};
 my $included={};
 foreach(keys(%{$mets})) {
 	my $name=$tobin->compoundNameGet($_);
 	$name=~/mult|div$|^Carbon$|Biomass|Power/?($excluded->{$_}=1):($included->{$_}=1);
 }
 print("Excluded:\n");
 foreach(keys(%{$excluded})) {
 	print($_."\n");
 }
print("Included:\n");
foreach(keys(%{$included})) {
 	print($_."\n");
}
