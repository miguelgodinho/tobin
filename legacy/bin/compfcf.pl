#!/usr/bin/perl -I. -w
use strict;
use warnings;

@ARGV<2&&die("Too few arguments");
open(WE,$ARGV[0])||die("Cannot open first input file");
my @tab=<WE>;
close(WE);
my @tab1=grep(/^Directionally/../^Fully/,@tab);
my $dcoupled1={};
for(1..(@tab1-2)) {
	chomp($tab1[$_]);
	my @tab2=split(/\t/,$tab1[$_]);
	my @tab3=split(/, /,$tab2[1]);
	$dcoupled1->{$tab2[0]}={};
	foreach my $tf (@tab3) {
		$dcoupled1->{$tab2[0]}->{$tf}=1;
	}
}
my $fcoupled1={};
my $nodehash1={};
@tab1=grep(/^Fully/../^Partially/,@tab);
for(1..(@tab1-2)) {
	chomp($tab1[$_]);
	my @tab2=split(/: /,$tab1[$_]);
	my @tab3=split(/, /,$tab2[1]);
	$fcoupled1->{$tab2[0]}={};
	foreach my $tf (@tab3) {
		$nodehash1->{$tf}=$tab2[0];
		$fcoupled1->{$tab2[0]}->{$tf}=1;
	}
}
@tab1=grep(/^Partially/../^digraph/,@tab);
for(1..(@tab1-2)) {
	chomp($tab1[$_]);
	my @tab2=split(/: /,$tab1[$_]);
	my @tab3=split(/, /,$tab2[1]);
	defined($fcoupled1->{$tab2[0]})||($fcoupled1->{$tab2[0]}={});
	foreach my $tf (@tab3) {
		$nodehash1->{$tf}=$tab2[0];
		$fcoupled1->{$tab2[0]}->{$tf}=1;
	}
}

open(WE,$ARGV[1])||die("Cannot open second input file");
@tab=<WE>;
close(WE);
@tab1=grep(/^Directionally/../^Fully/,@tab);
my $dcoupled2={};
for(1..(@tab1-2)) {
	chomp($tab1[$_]);
	my @tab2=split(/\t/,$tab1[$_]);
	my @tab3=split(/, /,$tab2[1]);
	$dcoupled2->{$tab2[0]}={};
	foreach my $tf (@tab3) {
		$dcoupled2->{$tab2[0]}->{$tf}=1;
	}
}
my $fcoupled2={};
my $nodehash2={};
@tab1=grep(/^Fully/../^Partially/,@tab);
for(1..(@tab1-2)) {
	chomp($tab1[$_]);
	my @tab2=split(/: /,$tab1[$_]);
	my @tab3=split(/, /,$tab2[1]);
	$fcoupled2->{$tab2[0]}={};
	foreach my $tf (@tab3) {
		$nodehash2->{$tf}=$tab2[0];
		$fcoupled2->{$tab2[0]}->{$tf}=1;
	}
}
@tab1=grep(/^Partially/../^digraph/,@tab);
for(1..(@tab1-2)) {
	chomp($tab1[$_]);
	my @tab2=split(/: /,$tab1[$_]);
	my @tab3=split(/, /,$tab2[1]);
	defined($fcoupled2->{$tab2[0]})||($fcoupled2->{$tab2[0]}={});
	foreach my $tf (@tab3) {
		$nodehash2->{$tf}=$tab2[0];
		$fcoupled2->{$tab2[0]}->{$tf}=1;
	}
}
print("Directionally coupled:\n");
foreach(keys(%{$dcoupled1})) {
	print("$_");
	if(defined($dcoupled2->{$_})) {
		my $add1={};
		my $add2={};
		foreach my $tf (keys(%{$dcoupled1->{$_}})) {
			defined($dcoupled2->{$_}->{$tf})||($add1->{$tf}=1);
		}
		foreach my $tf (keys(%{$dcoupled2->{$_}})) {
			defined($dcoupled1->{$_}->{$tf})||($add2->{$tf}=1);
		}
		if(!keys(%{$add1})&&!keys(%{$add2})) {
			print("\tEqual");
		}
		else { 
			if (keys(%{$add1})) {
				my $str="\tFirst: ";
				foreach my $tf (keys(%{$add1})) {
					$str.=$tf.", ";
				}
				$str=~s/, $//;
				print($str);
			}
			if (keys(%{$add2})) {
				my $str="\tSecond: ";
				foreach my $tf (keys(%{$add2})) {
					$str.=$tf.", ";
				}
				$str=~s/, $//;
				print($str);
			}
		}
		
	}
	else {
		print("\tOnly in first");
	}
	print("\n");
}
foreach(keys(%{$dcoupled2})) {
	defined($dcoupled1->{$_})&&next;
	print("$_\tOnly in second\n");
}

print("Parially/directionally coupled:\n");
my $cmap={};
my $assigned1={};
my $assigned2={};
foreach(keys(%{$fcoupled1})) {
	my $cmap1={};
	foreach my $tf (keys(%{$fcoupled1->{$_}})) {
#		$_==24&&warn($nodehash2->{$tf});
		if(defined($nodehash2->{$tf})) {
			defined($cmap1->{$nodehash2->{$tf}})||($cmap1->{$nodehash2->{$tf}}=0);
			$cmap1->{$nodehash2->{$tf}}++;
		}
		else {
			defined($cmap1->{0})||($cmap1->{0}=0);
			$cmap1->{0}++;
		}
	}
	if(keys(%{$cmap1})==1&&(keys(%{$cmap1}))[0]) {
		if(keys(%{$fcoupled1->{$_}})==keys(%{$fcoupled2->{(keys(%{$cmap1}))[0]}})) {
			$assigned2->{(keys(%{$cmap1}))[0]}=1;
			$assigned1->{$_}=1;
			$cmap->{$_}=(keys(%{$cmap1}))[0];
			print($_." equal to ".(keys(%{$cmap1}))[0]."\n");
		}
		else {
			print($_." subset of ".(keys(%{$cmap1}))[0]."\n");
			$assigned1->{$_}=1;
			$assigned2->{(keys(%{$cmap1}))[0]}=1;
		}
		
	}
}
foreach(keys(%{$fcoupled2})) {
	defined($assigned2->{$_})&&next;
	my $cmap1={};
	foreach my $tf (keys(%{$fcoupled2->{$_}})) {
#		$_==24&&warn($nodehash2->{$tf});
		if(defined($nodehash1->{$tf})) {
			defined($cmap1->{$nodehash1->{$tf}})||($cmap1->{$nodehash1->{$tf}}=0);
			$cmap1->{$nodehash1->{$tf}}++;
		}
		else {
			defined($cmap1->{0})||($cmap1->{0}=0);
			$cmap1->{0}++;
		}
	}
	if(keys(%{$cmap1})==1&&(keys(%{$cmap1}))[0]) {
			print((keys(%{$cmap1}))[0]." superset of ".$_."\n");
			$assigned2->{$_}=1;
			$assigned1->{(keys(%{$cmap1}))[0]}=1;
	}
}
print("Unassigned - first:\n");
foreach(keys(%{$fcoupled1})) {
	defined($assigned1->{$_})&&next;
	print($_."\n");
}
print("Unassigned - second:\n");
foreach(keys(%{$fcoupled2})) {
	defined($assigned2->{$_})&&next;
	print($_."\n");
}
