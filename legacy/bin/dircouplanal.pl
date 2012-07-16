#!/usr/bin/perl -I. -w
use strict;
use warnings;

@ARGV||die("Too few arguments");

open(WE,$ARGV[0])||die("Cannot open input file");
my @tab=<WE>;
close(WE);

my @tab1=grep(/^Directionally/../^Fully/,@tab);
my $dcoupled={};
for(1..(@tab1-2)) {
	chomp($tab1[$_]);
	my @tab2=split(/\t/,$tab1[$_]);
	my @tab3=split(/, /,$tab2[1]);
	$dcoupled->{$tab2[0]}={};
	foreach my $tf (@tab3) {
		$dcoupled->{$tab2[0]}->{$tf}=1;
	}
}


@tab1=grep(/^Fully/../^Partially/,@tab);
my $nodehash={};
for(1..(@tab1-2)) {
	chomp($tab1[$_]);
	my @tab2=split(/: /,$tab1[$_]);
	my @tab3=split(/, /,$tab2[1]);
	foreach my $tf (@tab3) {
		$nodehash->{$tf}=$tab2[0];
	}
}
@tab1=grep(/^Partially/../^digraph/,@tab);
for(1..(@tab1-2)) {
	chomp($tab1[$_]);
	my @tab2=split(/: /,$tab1[$_]);
	my @tab3=split(/, /,$tab2[1]);
	foreach my $tf (@tab3) {
		$nodehash->{$tf}=$tab2[0];
	}
}

my $dtree={};
my $rooted={};
my $newroots={};
foreach(keys(%{$dcoupled})) {
#	defined($dtree->{$_})&&next;
	my $bad=0;
	foreach my $rtf (keys(%{$dcoupled})) {
#		defined($dtree->{$rtf})&&next;
		foreach my $tf(keys(%{$dcoupled->{$rtf}})) {
			$tf==$_&&($bad=1)&&last;
		}
		$bad&&last;
	}
	if(!$bad) {
		$newroots->{$_}=1;
	}
}
warn(keys(%{$newroots})."\n");
do {
	my $nextroots={};
	warn("Round");
	foreach(keys(%{$newroots})) {
		$rooted->{$_}=1;
		my $node;
		if(defined($nodehash->{$_})) {
			defined($dtree->{"C".$nodehash->{$_}})&&next;
			$node="C".sprintf("%02d",$nodehash->{$_});
		}
		else {
			$node=sprintf("%04d",$_);
		}
		$dtree->{$node}={};
		foreach my $ctf (keys(%{$dcoupled->{$_}})) {
			my $bad=0;
			foreach my $rtf (keys(%{$dcoupled})) {
				defined($rooted->{$_})&&next;
#				defined($newroots->{$rtf})&&next;
				foreach my $tf(keys(%{$dcoupled->{$rtf}})) {
					$tf==$ctf&&($bad=1)&&last;
				}
				$bad&&last;
			}
			if(!$bad) {
				my $node1;
				if(defined($nodehash->{$ctf})) {
					$node1="C".sprintf("%02d",$nodehash->{$ctf});
				}
				else {
					$node1=sprintf("%04d",$ctf);
				}
				$nextroots->{$ctf}=1;
				$dtree->{$node}->{$node1}=1;
			}
		}
	}
	$newroots=$nextroots;
	warn(keys(%{$newroots})."\n");
} while(keys(%{$newroots}));

print("digraph \"if\" {\n\tgraph [\n\t\tfontsize = \"14\"\n".
"\t\tfontname = \"Times-Roman\"\n\t\tfontcolor = \"black\"\n\t]\n");
foreach(keys(%{$dtree})) {
	foreach my $node (keys(%{$dtree->{$_}})) {
		print($_." -> ".$node.";\n");
	}
}
print("}\n");
