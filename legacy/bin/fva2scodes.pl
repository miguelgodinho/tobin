#!/usr/bin/perl -I.
use strict;
use warnings;


open(WE,$ARGV[1])||die("Cannot open FVA results");
my @tab=<WE>;
close(WE);
my $fvahash={};
foreach(@tab) {
	chomp;
	my @tab1=split(/\t/,$_);
	$fvahash->{$tab1[0]}=[$tab1[1],$tab1[2]];
}
open(WE, $ARGV[0])||die("Cannot open scodes");
@tab=<WE>;
close(WE);
foreach(@tab) {
	chomp;
	my @tab1=split(/\t/,$_);
	my $key=@tab1==2?$tab1[1]:
	($tab1[1]<$tab1[2]?$tab1[1]."/".$tab1[2]:$tab1[2]."/".$tab1[1]);
	if($key!~m%/%&&!defined($fvahash->{$key})) {
		my @keys;
		if(@keys=grep("^".$key."/",(keys(%{$fvahash})))) {
			print($tab1[0]."\t".($fvahash->{$keys[0]}->[0])."\t".
			($fvahash->{$keys[0]}->[1])."\n");
		}
		elsif(@keys=grep("/".$key."\$",(keys(%{$fvahash})))) {
			print($tab1[0]."\t".(-$fvahash->{$keys[0]}->[1])."\t".
			(-$fvahash->{$keys[0]}->[0])."\n");
		}
	}
	else {
		my $rev=(@tab1==3&&$tab1[2]<$tab1[1])?1:0;
	print($tab1[0]."\t".($rev?-$fvahash->{$key}->[1]:$fvahash->{$key}->[0])."\t".
	($rev?-$fvahash->{$key}->[0]:$fvahash->{$key}->[1])."\n");
	}
	
}
