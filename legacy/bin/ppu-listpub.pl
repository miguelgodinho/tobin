#!/usr/bin/perl -I. -w
use strict;
use warnings;

open(WE, $ARGV[0])||die("Cannot open gene list!");
my @tab=<WE>;
close(WE);
my $glist={};
foreach(@tab) {
	chomp;
	my @tab1=split(/\t/,$_);
	$glist->{$tab1[0]}=$tab1[1];
}

open(WE, $ARGV[1])||die("Cannot open present gene list!");
@tab=<WE>;
close(WE);
my $pglist={};
foreach(@tab) {
	chomp;
	my @tab1=split(/\t/,$_);
	$pglist->{$_}=1;
}

foreach(keys(%{$glist})) {
	defined($pglist->{$glist->{$_}})||next;
	my $ge=lc;
	$ge=~s/-[1-9]$//;
	open(WE, "ppu-genes/".$ge.".htm")||(warn("Cannot open file for $ge!")&&next);
	@tab=<WE>;
	close(WE);
	my $file="";
	foreach my $line (@tab) {
		$file.=$line;
	}
	@tab=($file=~/\n<td[^>]*><span class="txtBoldOnly">(.*\n([^<].*\n)+)/g);
	@tab&&print($_.":".@tab."\n");
	foreach(1..@tab) {
		if($file=~/\n<td[^>]*><span class="txtBoldOnly">(.*\n([^<].*\n)+)/) {
			my $match=$1;
			$file=$';
			$match=~s/\n/ /g;
			$match=~s/&nbsp;//;
			$match=~s/^ //;
			print($match."\n");
		}
	}
}
