#!/usr/bin/perl -I. -w
use strict;
use warnings;
use Tobin::IF;
my $tobin	= new Tobin::IF(1);

open(WE, $ARGV[0])||die("Cannot open starting list");
my @tab=<WE>;
close(WE);
my $comphash={};
my $chroot={};
my @tab1;
foreach(@tab) {
	chomp $_;
	@tab1=split(/\t/,$_);
	$chroot->{$tab1[1]}={name=>$tab1[0],formula=>{},children=>{}};
	$comphash->{$tab1[1]}=1;
	my @catoms=$tobin->compoundFormulaGet($tab1[1])=~m/([A-Z][a-z]*[0-9]*)/g;
	foreach my $atom (@catoms) {
#		($atom eq"H")&&next;
		my $value;
#		print($atom."\n");
		($atom=~m/([0-9]+)/)?($value=$1):($value=1);
#			print $value."\n";
		$atom=~/([A-Z][a-z]*)/;
		$chroot->{$tab1[1]}->{formula}->{$1}=$value;
	}
	
}
open(WE, $ARGV[1])||die("Cannot open compound list");
my @clist=<WE>;
close(WE);
foreach(@clist) {
	chomp;
	defined($comphash->{$_})&&next;
	my $found=[];
	foreach my $root(keys(%{$chroot})) {
		my $cnames=$tobin->compoundNamesGet($_);
		foreach my $name (@{$cnames}) {
			($name=~/$chroot->{$root}->{name}/i)&&push(@{$found},$root)&&last;
		}
	}
#	$_==713 && warn @{$found};
	@{$found}||next;
	my $formula={};
	my @catoms=$tobin->compoundFormulaGet($_)=~m/([A-Z][a-z]*[0-9]*)/g;
	foreach my $atom (@catoms) {
		my $value;
#		print($atom."\n");
		($atom=~m/([0-9]+)/)?($value=$1):($value=1);
#		print $value."\n";
		$atom=~/([A-Z][a-z]*)/;
		$formula->{$1}=$value;
	}
	my $good;
	foreach my $root (@{$found}) {
		$good=1;
		if(keys(%{$formula})==keys(%{$chroot->{$root}->{formula}})) {
			foreach my $atom(keys(%{$formula})) {
				($atom eq"H")&&next;
				(defined($chroot->{$root}->{formula}->{$atom})&&
				($chroot->{$root}->{formula}->{$atom}==$formula->{$atom}))||
				(($good=0)||last);
			}	
		}
		else {
			$good=0;
		}
		if($good) {
			$comphash->{$_}=1;
			$chroot->{$root}->{children}->{$_}=1;
#			$_==700 && warn $root;
			last;
		}
			
	}
	if(!$good) {
		$chroot->{$_}={name=>$chroot->{$found->[0]}->{name},
			formula=>$formula,children=>{}};
		$comphash->{$_}=1;
	}
}
foreach (keys(%{$chroot})){
	print($_." - ".$tobin->compoundNameGet($_));
	foreach my $dupl(keys(%{$chroot->{$_}->{children}})) {
		print("\t".$dupl." - ".$tobin->compoundNameGet($dupl));
	}
	print("\n");
	
}	
