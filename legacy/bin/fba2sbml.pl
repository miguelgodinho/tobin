#!/usr/bin/perl -I. -w
use strict;
use warnings;
use Tobin::IF;

@ARGV<7&&die("Too few arguments");
my $tobin	= new Tobin::IF(1);
my $tfset=[];
if($ARGV[0]) {
	my $fbaset=$tobin->fbasetupGet($ARGV[1]);
	foreach(@{$fbaset->{TFSET}}) {
		push(@{$tfset},$_->[0]);
	}
}
else {
	open(WE, $ARGV[1])||die("Cannot open reaction list");
	my @tab=<WE>;
	close(WE);
	foreach(@tab) {
		chomp;
		push(@{$tfset},$_);
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
open(WE, $ARGV[3])||die("Cannot open external file.");
@tab=<WE>;
close(WE);
my $exthash={0=>{},1=>{}};
foreach(@tab) {
	chomp;
	my @tab1=split(/\t/,$_);
	$exthash->{$tab1[1]}->{$tab1[0]}=$tab1[2];
	warn($exthash->{$tab1[1]}->{$tab1[0]});
}
open(LOG,">$ARGV[5]");
my $irhash={};
my $rrhash={};
my $assigned={};
my $ichash={};
my $echash={};
foreach(@{$tfset}) {
	defined($assigned->{$_})&&next;
	my $tf=$tobin->transformationGet($_);
	if($tf->[3]->[0]=~/^SOURCE|^SINK/) {
		print(LOG "Excluded reaction: $_ - $tf->[3]->[0]\n");
		next;
	}
	my $cpdhash={prod=>{0=>{},1=>{}},subs=>{0=>{},1=>{}}};
	foreach my $cpd (@{$tf->[2]}) {
		$cpdhash->{($cpd->{sto}<0?"subs":"prod")}
		->{$cpd->{ext}}->{$cpd->{id}}=abs($cpd->{sto});
	}
	my $met={subs=>{},prod=>{}};
	foreach my $cp("subs","prod") {
		foreach my $ext(0,1) {
			foreach my $id(keys(%{$cpdhash->{$cp}->{$ext}})) {
				my $cpdname=($ext?"EX":"")."C".sprintf("%04d",$id);
				defined($exthash->{$ext}->{$id})?($echash->{$cpdname}=$exthash->{$ext}->{$id}):
				($ichash->{$cpdname}=1);
		#		defined($exthash->{$ext}->{$id})&&warn("$cpdname\t".$echash->{$cpdname});
				$met->{$cp}->{$cpdname}=$cpdhash->{$cp}->{$ext}->{$id};
			}
		}
	}
	if(defined($revhash->{$_})) {
		$rrhash->{"RR".sprintf("%04d",$_)}=$met;
		$assigned->{$_}=1;
		$assigned->{$revhash->{$_}}=1;
	}
	else {
		$irhash->{"IR".sprintf("%04d",$_)}=$met;
		$assigned->{$_}=1;
	}
}
open(WY, ">$ARGV[4]");
print(WY "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n");
print(WY "<sbml xmlns=\"http://www.sbml.org/sbml/level2\"". 
" xmlns:sbml=\"http://www.sbml.org/sbml/level2\" version=\"1\" level=\"2\"\n");
print(WY"xmlns:html=\"http://www.w3.org/1999/xhtml\">\n");
print(WY"<model id=\"$ARGV[6]\" name=\"$ARGV[6]\" >\n");
print(WY"<listOfCompartments>\n".
"<compartment id=\"System\" spatialDimensions=\"3\" name=\"System\" />\n".
"</listOfCompartments>\n<listOfSpecies>\n");
foreach(keys(%{$echash})) {
	print(WY"<species id=\"".$_."\" initialAmount=\"10.0\" boundaryCondition=\"true\"".
	" name=\"".$_."\" />\n");
}
foreach(keys(%{$ichash})) {
	print(WY"<species id=\"".$_."\" initialAmount=\"10.0\" name=\"".$_."\" />\n");
}
print(WY "</listOfSpecies>\n<listOfReactions>\n");
foreach(keys(%{$rrhash})) {
	print(WY "<reaction id=\"".$_."\" name=\"".$_."\" >\n");
	print(WY"<listOfReactants>\n");
	foreach my $cpd(keys(%{$rrhash->{$_}->{subs}})) {
		print(WY"<speciesReference species=\"".$cpd."\"");
		$rrhash->{$_}->{subs}->{$cpd}>1&&
		print(WY" stoichiometry=\"".$rrhash->{$_}->{subs}->{$cpd}."\"");
		print(WY" >\n</speciesReference>\n");
	}
	print(WY"</listOfReactants>\n<listOfProducts>\n");
	foreach my $cpd(keys(%{$rrhash->{$_}->{prod}})) {
		print(WY"<speciesReference species=\"".$cpd."\"");
		$rrhash->{$_}->{prod}->{$cpd}>1&&
		print(WY" stoichiometry=\"".$rrhash->{$_}->{prod}->{$cpd}."\"");
		print(WY" >\n</speciesReference>\n");
	}
	print(WY "</listOfProducts>\n</reaction>\n");
}
foreach(keys(%{$irhash})) {
	print(WY "<reaction id=\"".$_."\" reversible=\"false\" name=\"".$_."\" >\n");
	print(WY"<listOfReactants>\n");
	foreach my $cpd(keys(%{$irhash->{$_}->{subs}})) {
		print(WY"<speciesReference species=\"".$cpd."\"");
		$irhash->{$_}->{subs}->{$cpd}>1&&
		print(WY" stoichiometry=\"".$irhash->{$_}->{subs}->{$cpd}."\"");
		print(WY" >\n</speciesReference>\n");
	}
	print(WY"</listOfReactants>\n<listOfProducts>\n");
	foreach my $cpd(keys(%{$irhash->{$_}->{prod}})) {
		print(WY"<speciesReference species=\"".$cpd."\"");
		$irhash->{$_}->{prod}->{$cpd}>1&&
		print(WY" stoichiometry=\"".$irhash->{$_}->{prod}->{$cpd}."\"");
		print(WY" >\n</speciesReference>\n");
	}
	print(WY "</listOfProducts>\n</reaction>\n");
}
print(WY"</listOfReactions>\n</model>\n</sbml>\n");
close(WY);
