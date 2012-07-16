#!/usr/bin/perl -I. -w
use strict;
use warnings;

open(WE, $ARGV[0])||die("Cannot open title list!");
my @tab=<WE>;
close(WE);
my $tlist={};
system("kwrite --encoding utf-8 ".$ARGV[0]." &");
sleep(5);
`xwininfo -name "kwrite"`=~m/id: (0x[0-9a-h]+) /;
my $edid=$1;
`xse -window $edid '<KeyPress> F10' '<KeyRelease> F10'`;
foreach(1..@tab) {
	`xse -window $edid '<FocusIn> Normal Nonlinear'`;
	`xse -window $edid '<Shift> End' '<KeyRelease> End'`;
	`xse -window $edid '<Ctrl> c' '<KeyRelease> c'`;
	`xse -window $edid '<KeyPress> Down' '<KeyRelease> Down'`;
	`xse -window $edid '<KeyPress> Home' '<KeyRelease> Home'`;
	system("seamonkey www.scopus.com &");
	sleep(5);
	`xwininfo -name "Scopus - Basic Search - SeaMonkey"`=~m/id: (0x[0-9a-h]+) /;
	my $id=$1;
	`xse -window $id '<FocusIn> Normal Nonlinear'`;
	`xse -window $id '<Ctrl> v' '<KeyRelease> v'`;
	`xse -window $id '<KeyPress> Return' '<KeyRelease> Return'`;
	sleep(5);
	for my $n(1..10) {
		`xse -window $id '<KeyPress> Tab' '<KeyRelease> Tab'`;
	}
	`xse -window $id '<KeyPress> Return' '<KeyRelease> Return'`;
	sleep(5);
	`xse -window $id '<Ctrl> s' '<KeyRelease> s'`;
	`xse -window $id '<KeyPress> s' '<KeyRelease> s'`;
	`xse -window $id '<KeyPress> e' '<KeyRelease> e'`;
	`xse -window $id '<KeyPress> l' '<KeyRelease> l'`;
	`xse -window $id '<KeyPress> slash' '<KeyRelease> slash'`;
	`xse -window $id '<KeyPress> 1' '<KeyRelease> s'`;
	my $d1=$_%10;
	my $d2=$_-10*$d1;
	`xse -window $id '<KeyPress> $d1' '<KeyRelease> $d1'`;
	`xse -window $id '<KeyPress> $d2' '<KeyRelease> $d2'`;
	`xse -window $id '<KeyPress> period' '<KeyRelease> period'`;
	`xse -window $id '<KeyPress> h' '<KeyRelease> h'`;
	`xse -window $id '<KeyPress> t' '<KeyRelease> t'`;
	`xse -window $id '<KeyPress> m' '<KeyRelease> m'`;
	`xse -window $id '<KeyPress> Return' '<KeyRelease> Return'`;
	sleep(5);
	`xkill -id $id`;
}
