#!/usr/bin/perl -I. -w
use strict;
use warnings;
use Tobin::IF;
@ARGV<3&&die("Too few arguments.");
my $tobin	= new Tobin::IF(1);
my %fba=$tobin->fbaresGet($ARGV[0]);
foreach(keys(%fba)) {
	my $rea=$tobin->transformationGet($_);
	foreach my $row (@{$rea->[2]}) {
		if($row->{id}==$ARGV[1]&&$row->{ext}==$ARGV[2]) {
			print(($fba{$_}*$row->{sto})." - $_ - ".
			$tobin->transformationNameGet($_)."\n");
		}
	}
}
