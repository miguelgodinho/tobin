#!/usr/bin/perl -I. -w
use strict;
use warnings;

open(WE, $ARGV[0])||die("Cannot open gene list!");
my @tab=<WE>;
close(WE);
my $glist={};
foreach(@tab) {
	chomp;
	$glist->{$_}=1;
}

foreach(keys(%{$glist})) {
	my $ge=lc;
	open(WE, "ppu-genes/".$ge.".htm")||(warn("Cannot open file for $ge!")&&next);
	@tab=<WE>;
	close(WE);
	my $file="";
	foreach my $line (@tab) {
		$file.=$line;
	}
	@tab=($file=~/\n<td[^>]*><span class="txtBoldOnly">(.*\n([^<].*\n)+)/g);
	print($_.":".@tab."\n");
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
#	$file=~m/\n<td.*\n([^<].*)\n/g;
#	print($_.":".@-." ".@+."\n");
#	foreach my $match(1..@-) {
#		print(substr($file,$-[$match-1],$+[$match-1]-$-[$match-1])."\n");
#		print("aaa\n");
#	}
}
