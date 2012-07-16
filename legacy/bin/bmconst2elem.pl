#!/usr/bin/perl -I. -w
use strict;
use warnings;
use Tobin::IF;

my $tobin=new Tobin::IF(1);
my $elem={C=>9463,H=>9464,N=>9465,O=>9466,P=>9467,S=>9468};
open(WE,$ARGV[0])||die("Cannot sinks file!");
my @tab=<WE>;
close(WE);
my $excluded={};
foreach (@tab) {
	chomp;
	my $tf=$tobin->transformationGet($_);
	my $cpd=$tf->[2]->[0]->{id};
	my $formula=$tobin->compoundFormulaGet($cpd);
	my $react=[{id=>$cpd,sto=>-1,ext=>0}];
	my @atoms=$formula=~m/([A-Z][a-z]*[0-9]*)/g;
	my $fstr="";
	foreach my $at(@atoms) {
		$at=~m/([A-Z][a-z]*)/;
		defined($elem->{$1})||next;
		my $id=$1;
		my $sto=($at=~m/([0-9]+)/?$1:1);
		$fstr.=($sto!=1?$sto." ":"").$id." + ";
		push(@{$react},{id=>$elem->{$id},sto=>$sto,ext=>0});
	}
	@{$react}>1||next;
	$fstr=~s/ \+ $//;
	$fstr=(values(%{$tobin->compoundLinksGet($cpd)}))[0]." -> ".$fstr;
	my $errors=[];
	$tobin->transformationAdd($fstr,[{user=>1004,link=>$cpd."toelem"}],$react,
	[$tobin->compoundNameGet($cpd)." to elements"],$errors);
	foreach my $err (@{$errors}) {
		warn($err);
	}
	
}
