#!/usr/bin/perl -I. -w
use strict;
use warnings;
open(WE,$ARGV[0])||die("Cannot open gene list");
my @tab=<WE>;
close(WE);
my $spec=$ARGV[1];
my $path=$ARGV[2];
my $url="http://www.genome.jp/dbget-bin/www_bget?";
my $pathhash={};
foreach(@tab) {
	chomp;
	if(!open(WE,$path."/".$_.".htm")) {
		`wget -O $path/$_.htm "$url$spec+$_"`;
		open(WE,$path."/".$_.".htm")||die("Problem with gene file");
	}
	my @tab1=<WE>;
	close(WE);
	my @tab2=grep(/PATH:/,@tab1);
	foreach my $line(@tab2) {
		$line=~m%(pae[0-9]{5})</a>\&nbsp;\&nbsp%;
		defined($pathhash->{$_})||($pathhash->{$_}=[]);
		push(@{$pathhash->{$_}},$1);

	}
}

foreach(keys(%{$pathhash})) {
	my $str=$_;
	foreach my $path (@{$pathhash->{$_}}) {
		$str.="\t".$path;
	}
	print($str."\n")
}
