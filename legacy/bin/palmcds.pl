#!/usr/bin/perl -I.
use strict;
use warnings;
use Tobin::IF;

@ARGV<3&&die("Too few arguments.");
my $tobin		= new Tobin::IF(1);
open(WE, $ARGV[2])||die("Cannot open mcodes");
my @mets=<WE>;
close(WE);
my $codes={};
foreach(@mets) {
	chomp($_);
	my @mets1=split(/\t/,$_);
	$codes->{$mets1[0]}=$mets1[1];
}
my $blad={};
if($ARGV[0]==0) {
	open(WE, $ARGV[1])||die("Cannot open input file.");
	@mets=<WE>;
	close(WE);
	foreach(@mets) {
		chomp($_);
		if(!defined($codes->{$_})&&!defined($blad->{$_})) {
			my $search=length($_)>10?substr($_,0,10):$_;
			$search=~s/[\(\)\[\[]/./g;
			my $comps=$tobin->compoundCandidatesGet($search,0);
			if(@{$comps}==1) {
				$codes->{$_}=$comps->[0];
			}
			elsif(@{$comps}>1) {
				print($_.": Possible codes:");
				foreach my $comp (@{$comps}) {
					print("\t".$comp);
					print("\t".$tobin->compoundNameGet($comp));
				}
				print("\n");
				$blad->{$_}=1;
			}
			else {
				print($_.": No metabolite\n");
				$blad->{$_}=0;
			}
		}
	}
}
elsif($ARGV[0]==1) {
	open(WE,$ARGV[1])||die("Cannot open input file.");
	@mets=<WE>;
	close(WE);
	foreach(@mets) {
		chomp($_);
		my$equ=(split(/\t/,$_))[2];
		$equ=~s/^\[[ce]\] : |\([0-9.]+\) |\[[ce]\]//g;
		my @mets1=split(/ <==> | --> | \+ | -->| \+/,$equ);
		foreach my $met (@mets1) {
			if(!defined($codes->{$met})&&!defined($blad->{$met})) {
			my $search=length($met)>10?substr($met,0,10):$met;
				$search=~s/[\(\)]/./g;
				my $comps=$tobin->compoundCandidatesGet($search,1);
				if(@{$comps}==1) {
					$codes->{$met}=$comps->[0];
					warn "Accepted ".$comps->[0]."as $met";
				}
				elsif(@{$comps}>1) {
					print($met.": Possible codes:");
					foreach my $comp (@{$comps}) {
						print(" ".$comp);
					}
					print("\n");
					$blad->{$met}=1;
				}
				else {
					print($met.": No metabolite.\n");
					$blad->{$met}=0;
				}			
			}
		}
	}
}
else {
	die("Bad mode.");
}
if(@ARGV>3&&$ARGV[3]==1) {
	@ARGV<6&&die("Too few metabolites");
	open(WE, $ARGV[4])||die("Cannot open metabolites list");
	my @tab=<WE>;
	close(WE);
	my $mattcpd={};
	foreach(@tab) {
		chomp;
		my @tab1=split(/\t/,$_);
		$mattcpd->{$tab1[0]}=[$tab1[1],$tab1[2],$tab1[4]];
	}
	foreach(keys(%{$blad})) {
		$blad->{$_}&&next;
		if(defined($mattcpd->{$_})) {
			print("Add metabolite $_ - $mattcpd->{$_}->[0]? ");
			my $ans;
			read(STDIN,$ans,2);
			($ans=~/y\n/)||next;
			my $errors=[];
			$tobin->compoundAdd([$mattcpd->{$_}->[0]],[{user=>$ARGV[5],
				link=>(length($_)>10?substr($_,0,10):$_)}],
			$mattcpd->{$_}->[1],$mattcpd->{$_}->[2],$errors);
			if(@{$errors}) {
				foreach my $err (@{$errors}) {
					warn $err;
					die();
				}
			}
			print($_."\tAdded to tobin.\n");
			my $search=length($_)>10?substr($_,0,10):$_;
			$search=~s/[\(\)]/./g;
			my $comps=$tobin->compoundCandidatesGet($search,1);
			if(@{$comps}==1) {
				$codes->{$_}=$comps->[0];
				warn "Accepted ".$comps->[0]."as $_";
			}
			elsif(@{$comps}>1) {
				print($_.": Possible codes:");
				foreach my $comp (@{$comps}) {
					print(" ".$comp);
				}
				print("\n");
			}
		}
	}
}
open(WY, ">".$ARGV[2]);
foreach(keys(%{$codes})) {
	print(WY $_."\t".$codes->{$_}."\n");
}
close(WY);

	
