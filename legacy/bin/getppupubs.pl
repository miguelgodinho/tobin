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

#`xse -window $id '<FocusIn> Normal Nonlinear'`;
#`xse -window $id '<KeyPress> p' '<KeyRelease> p'`;
#`xse -window $id '<KeyPress> u' '<KeyRelease> u'`;
#`xse -window $id '<KeyPress> t' '<KeyRelease> t'`;
#`xse -window $id '<KeyPress> i' '<KeyRelease> i'`;
#`xse -window $id '<KeyPress> d' '<KeyRelease> d'`;
#`xse -window $id '<KeyPress> a' '<KeyRelease> a'`;

my $url="http://www.scopus.com/scopus/results/results.url?sort=plf-f&src=s&st1=putida&st2=";
my $length=0;
foreach(keys(%{$glist})) {
	system("seamonkey www.scopus.com &");
	sleep(5);
	`xwininfo -name "Scopus - Basic Search - SeaMonkey"`=~m/id: (0x[0-9a-h]+) /;
	my $id=$1;
	`xse -window $id '<FocusIn> Normal Nonlinear'`;
	`xse -window $id '<KeyPress> p' '<KeyRelease> p'`;
	`xse -window $id '<KeyPress> u' '<KeyRelease> u'`;
	`xse -window $id '<KeyPress> t' '<KeyRelease> t'`;
	`xse -window $id '<KeyPress> i' '<KeyRelease> i'`;
	`xse -window $id '<KeyPress> d' '<KeyRelease> d'`;
	`xse -window $id '<KeyPress> a' '<KeyRelease> a'`;
	print($id."\n");
	my $ge=lc;
	print($ge."\n"); 
	`xse -window $id '<FocusIn> Normal Nonlinear' '<KeyPress> Tab' '<KeyRelease> Tab'`; 
	`xse -window $id '<FocusIn> Normal Nonlinear' '<KeyPress> Tab' '<KeyRelease> Tab'`; 
	`xse -window $id '<FocusIn> Normal Nonlinear' '<KeyPress> Tab' '<KeyRelease> Tab'`;
	for(my $i=0;$i<$length;$i++) {
		`xse -window $id '<KeyPress> BackSpace' '<KeyRelease> BackSpace'`;
	}
	$length=length($ge);
	print("aaa\n");
	foreach my $n (1..length($ge)) {
		my $char=substr($ge,$n-1,1);
		`xse -window $id '<KeyPress> $char' '<KeyRelease> $char'`;
	}
	`xse -window $id '<KeyPress> Return' '<KeyRelease> Return'`;
	sleep(5);
	`xse -window $id '<Ctrl> s' '<KeyRelease> s'`;
	foreach my $n (1..length($ge)) {
		my $char=substr($ge,$n-1,1);
		`xse -window $id '<KeyPress> $char' '<KeyRelease> $char'`;
	}
	`xse -window $id '<KeyPress> period' '<KeyRelease> period'`;
	`xse -window $id '<KeyPress> h' '<KeyRelease> h'`;
	`xse -window $id '<KeyPress> t' '<KeyRelease> t'`;
	`xse -window $id '<KeyPress> m' '<KeyRelease> m'`;
	`xse -window $id '<KeyPress> Return' '<KeyRelease> Return'`;
	sleep(5);
	`xkill -id $id`;
}
