#!/usr/bin/perl -I.
use strict;
use warnings;
use Tobin::IF;
@ARGV<3&&die("Too few arguments.");
my $numbers={};
if(open(WE,"simcodes.csv")) {
	my @simcodes=<WE>;
	close(WE);
	foreach(@simcodes) {
		chomp($_);
		my @cols=split(/\t/,$_);
		$numbers->{$cols[0]}=(@cols==2?[$cols[1]]:[$cols[1],$cols[2]]);
	}
}

open(WE, $ARGV[2])||die("Cannot open reversible file.");
my @tab=<WE>;
close(WE);
my $revhash={};
foreach(@tab) {
	chomp;
	my @tab1=split(/\t/,$_);
	(defined($revhash->{$tab1[0]})||defined($revhash->{$tab1[1]}))&&
	die("Problem with reversibles.");
	$revhash->{$tab1[0]}=$tab1[1];
	$revhash->{$tab1[1]}=$tab1[0];
}

open(WE,$ARGV[0])||die("Cannot open reaction list.");
my @rlist=<WE>;
close(WE);
my $gmap={};
my $rmap={};
my $ecmap={};
foreach (@rlist) {
	chomp($_);
	my @row=split(/\t/,$_);
	if(defined($numbers->{$row[0]})) {
		$rmap->{$row[0]}=$row[1]?[$numbers->{$row[0]}->[0],$numbers->{$row[0]}->[1]]:
		[$numbers->{$row[0]}->[0]];
		if(@row>3) {
			my @grow=split(/, /,$row[3]);
			$gmap->{$row[0]}=\@grow;
			($row[2] ne "")&&($ecmap->{$row[0]}= $row[2]);
#			warn @{$gmap->{$row[0]}};
		}
	}
	else {
		print($row[0]."\n");
	}	
}
my $tfmap={};
foreach(keys(%{$gmap})) {
	if(defined($tfmap->{$rmap->{$_}->[0]})) {
		push(@{$tfmap->{$rmap->{$_}->[0]}},$_); 
	}
	else {
		$tfmap->{$rmap->{$_}->[0]}=[$_];
	}
	if(@{$rmap->{$_}}==2) {
		if(defined($tfmap->{$rmap->{$_}->[1]})) {
			push(@{$tfmap->{$rmap->{$_}->[1]}},$_); 
		}
		else {
			$tfmap->{$rmap->{$_}->[1]}=[$_];
		}	
	}
}
my $tobin		= new Tobin::IF(1);
my $fbaset=$tobin->fbasetupGet($ARGV[1]);
my $skip={};
foreach(@{$fbaset->{TFSET}}) {
	defined($skip->{$_->[0]})&&next;
	if(defined($tfmap->{$_->[0]})) {
		my $ghash={};
		my $ecnum;
		foreach my $code(@{$tfmap->{$_->[0]}}) {
			if(defined($ecmap->{$code})) {
				defined($ghash->{$ecmap->{$code}})||($ghash->{$ecmap->{$code}}={});
				$ecnum=$ecmap->{$code};
			}
			else {
				defined($ghash->{NoEC})||($ghash->{NoEC}={});
				$ecnum="NoEC"
			}
			foreach my $orf(@{$gmap->{$code}}) {
				$ghash->{$ecnum}->{$orf}=1;
			}
		}
		if(defined($revhash->{$_->[0]})) {
			$skip->{$revhash->{$_->[0]}}=1;
			print($_->[0]<$revhash->{$_->[0]}?$_->[0]."/".$revhash->{$_->[0]}:
			$revhash->{$_->[0]}."/".$_->[0]);
		}
		else {
			print($_->[0]);
		}
		foreach my $ecnum (keys(%{$ghash})) {
				print("\t$ecnum\t");
				foreach my $orf(keys(%{$ghash->{$ecnum}})) {
					print("$orf, ")
				}
			}
		print("\n");
	}
}
