#!/usr/bin/perl -I.. -w
use strict;
use warnings;
use Tobin::IF;
my $tobin=new Tobin::IF(1);
open(WE,$ARGV[0])||die("Cannot open input file!");
my @tab=<WE>;
close(WE);

my $int={};
foreach(@tab) {
	chomp;
	$_=~s%/.*$%%;
	my $rea=$tobin->transformationGet($_);
	foreach my $cpd (@{$rea->[2]}) {
		$cpd->{ext}&&next;
		defined($int->{$cpd->{id}})||($int->{$cpd->{id}}={});
		$int->{$cpd->{id}}->{$_}=1;
	}
}
open(WE,$ARGV[1])||die("Cannot open blocked file!");
@tab=<WE>;
close(WE);
foreach(@tab) {
	chomp;
	$_=~s%/.*$%%;
	my $rea=$tobin->transformationGet($_);
	foreach my $cpd (@{$rea->[2]}) {
		$cpd->{ext}&&next;
		delete($int->{$cpd->{id}}->{$_});
	}
}
my $count=0;
foreach(values(%{$int})) {
	keys(%{$_})||($count++);
}
print($count."\n");
