#!/usr/bin/perl -I. -w
use strict;
use warnings;
use Tobin::IF;

my $tobin	= new Tobin::IF(1);
my $hexcl=(@ARGV&&$ARGV[0]==1)?1:0;

for(my $i=8965;$i<9590;$i++) {
	my $tf=$tobin->transformationGet($i);
	my $subs={};
	my $prods={};
	foreach(@{$tf->[2]}) {
		($_->{sto}<0&&(!$hexcl||$_->{id}!=65))&&($subs->{$_->{id}}=1);
		($_->{sto}>0&&(!$hexcl||$_->{id}!=65))&&($prods->{$_->{id}}=1);
	}
	((!keys(%{$subs}))&&(!keys(%{$prods})))&&next;
#	warn $i;
	my $tflist=$tobin->transformationFindByCompounds($subs,$prods);
#	warn @{$tflist};
	if(@{$tflist}>1) {
		print("Reaction $i - ".$tobin->transformationNameGet($i)."\n");
		foreach(@{$tflist}) {
			if($_>$i) {
				print("$_ - ".$tobin->transformationNameGet($_)."\n")
			}
		}
		print("\n");
	}
}
