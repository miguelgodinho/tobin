#!/usr/bin/perl -I. -w
use strict;
use warnings;
use Tobin::IF;

@ARGV<3&&die("Too few arguments");
my $tobin	= new Tobin::IF(1);
my $fba=$tobin->fbasetupGet($ARGV[0]);
open(WE, $ARGV[1])||die("Cannot open reversible file.");
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
my $limval=10000;
open(WE, $ARGV[2])||die("Cannot open blockable file.");
my $blockhash={};
@tab=<WE>;
close(WE);
foreach(@tab) {
	chomp;
	my @tab1=split(/\t/,$_);
	$blockhash->{$tab1[0]}=$tab1[1]?$tab1[1]:10000;
	defined($revhash->{$tab1[0]})&&($blockhash->{$revhash->{$tab1[0]}}=$tab1[1]?$tab1[1]:10000);
}

my $skip={};
my $cpdhash={0=>{},1=>{}};
my $limhash={};
my $free={};
my $primobj={};
foreach(@{$fba->{TFSET}}) {
	defined($skip->{$_->[0]})&&next;
	defined($revhash->{$_->[0]})&&($skip->{$revhash->{$_->[0]}}=1);
	if($_->[1]!=0) {
		$primobj->{$_->[0]}=$_->[0]>0?-1:1;
	}
	$limhash->{$_->[0]}={};
	my $tf=$tobin->transformationGet($_->[0]);
	$_->[2]>0&&($limhash->{$_->[0]}->{min}=$_->[2]);
	defined($_->[3])&&($limhash->{$_->[0]}->{max}=$_->[3]);
	foreach my $cpd(@{$tf->[2]}) {
		defined($cpdhash->{$cpd->{ext}}->{$cpd->{id}})||
		($cpdhash->{$cpd->{ext}}->{$cpd->{id}}={});
		$cpdhash->{$cpd->{ext}}->{$cpd->{id}}->{$_->[0]}=$cpd->{sto};
	}
}

foreach(@{$fba->{TFSET}}) {
	defined($skip->{$_->[0]})||next;
	if($_->[1]!=0) {
		$primobj->{$revhash->{$_->[0]}}=$_->[1]>0?1:-1;
	}
	if($_->[2]>0) {
		if(defined($limhash->{$revhash->{$_->[0]}}->{min})||
		(defined($limhash->{$revhash->{$_->[0]}}->{max})&&
		$limhash->{$revhash->{$_->[0]}}->{max}>0)) {
			die("Tf $_->[0] - inconsistency in limits");
		}
		else {
			$limhash->{$revhash->{$_->[0]}}->{max}=-$_->[2];
		}
	}
	if(defined($_->[3])) {
		if(defined($limhash->{$revhash->{$_->[0]}}->{min})&&
		$limhash->{$revhash->{$_->[0]}}->{min}>0) {
			die("Tf $_->[0] - inconsistency in limits");
		}
		else {
			$limhash->{$revhash->{$_->[0]}}->{min}=-$_->[3];
		}
	}
}
foreach(keys(%{$limhash})) {
	if(defined($revhash->{$_})&&defined($blockhash->{$_})&&$blockhash->{$_}) {
		defined($limhash->{$_}->{min})||($limhash->{$_}->{min}=-$blockhash->{$_});
		defined($limhash->{$_}->{max})||($limhash->{$_}->{max}=$blockhash->{$_});
	}
	elsif(defined($blockhash->{$_})&&$blockhash->{$_}&&(!defined($limhash->{$_}->{max}))) {
		$limhash->{$_}->{max}=$blockhash->{$_};
	}
}
foreach(keys(%{$limhash})) {
	if(defined($revhash->{$_})) {
		defined($limhash->{$_}->{max})&&!defined($limhash->{$_}->{min})&&
		($limhash->{$_}->{min}=-$limval);
		!defined($limhash->{$_}->{min})&&!defined($limhash->{$_}->{max})&&
		($free->{$_}=1);
	}
}
my $tfhash={};
foreach(@{$fba->{TFSET}}) {
	defined($skip->{$_->[0]})&&next;
	$tfhash->{$_->[0]}={};
	my $tf=$tobin->transformationGet($_->[0]);
	foreach my $cpd (@{$tf->[2]}) {
		$tfhash->{$_->[0]}->{($cpd->{ext}?"E":"I")."C".
			sprintf("%05d",$cpd->{id})}=$cpd->{sto};
	}
}
my $realinv={};
my $realrev={};
foreach(keys(%{$limhash})) {
	if(defined($revhash->{$_})&&defined($limhash->{$_}->{min})&&
	$limhash->{$_}->{min}>=0) {
		$realinv->{$_}=1;
	}
	elsif(defined($revhash->{$_})&&(!defined($limhash->{$_}->{min})||$limhash->{$_}->{min}<0)) {
		$realrev->{$_}=1;
	}
	else {
		$realinv->{$_}=1;
	}
}

print("NAME           mod\n");
print("ROWS\n");
print(" N  OBJ\n");
foreach my $ext (keys(%{$cpdhash})) {
	foreach my $cpd (keys(%{$cpdhash->{$ext}})) {
		print(" E  L".($ext?"E":"I")."C".sprintf("%05d",$cpd)."\n");
	}
}
foreach(keys(%{$limhash})) {
	defined($limhash->{$_}->{min})&&defined($blockhash->{$_})&&$blockhash->{$_}
	&&print(" L  LAIR".sprintf("%05d",$_)."\n");
	defined($limhash->{$_}->{max})&&defined($blockhash->{$_})&&$blockhash->{$_}
	&&print(" L  LAAR".sprintf("%05d",$_)."\n");
	
}
print("COLUMNS");
foreach(keys(%{$tfhash})) {
	my $count=0;
	foreach my $lim (keys(%{$tfhash->{$_}})) {
		($count%2)||print("\n    R".sprintf("%05d",$_)."    ");
		my $numst=sprintf("%f",$tfhash->{$_}->{$lim});
		length($numst)<12?($numst.=sprintf("%0*d",(12-length($numst)),"0")):
		($numst=substr($numst,0,12));
		print("L".$lim."   ".
		$numst."   ");
		$count++;
	}
	if(defined($limhash->{$_}->{min})&&defined($blockhash->{$_})&&$blockhash->{$_}) {
		($count%2)||print("\n    R".sprintf("%05d",$_)."    ");
		print("LAIR".sprintf("%05d",$_)." "."-1.000000000"."   ");
		$count++;
	}
	if(defined($limhash->{$_}->{max})&&defined($blockhash->{$_})&&$blockhash->{$_}) {
		($count%2)||print("\n    R".sprintf("%05d",$_)."    ");
		print("LAAR".sprintf("%05d",$_)." "."1.0000000000"."   ");
		$count++;
	}	
}
print("\n    MARK00    'MARKER'                 'INTORG'");
foreach(keys(%{$blockhash})) {
	defined($skip->{$_})&&next;
	$blockhash->{$_}||next;
	my $numst=sprintf("%f",-$blockhash->{$_});
	length($numst)<12?($numst.=sprintf("%0*d",(12-length($numst)),"0")):
	($numst=substr($numst,0,12));
	print("\n    ACTR".sprintf("%05d",$_)." OBJ       1.0000000000   ".
	"LAAR".sprintf("%05d",$_)." ".$numst."   ");
	defined($revhash->{$_})&&print("\n    ACTR".sprintf("%05d",$_).
	" LAIR".sprintf("%05d",$_)." ".$numst."   "); 	
}
print("\n    MARK00    'MARKER'                 'INTEND'");
print("\nRHS");
print("\nBOUNDS\n");
foreach(keys(%{$realinv})) {
	if(defined($limhash->{$_}->{min})&&$limhash->{$_}->{min}!=0) {
		my $numst=sprintf("%f",$limhash->{$_}->{min});
		$numst.=sprintf("%0*d",(12-length($numst)),"0");
		$numst=length($numst)>12?substr($numst,0,12):$numst;
		print(" LO BND       R".sprintf("%05d",$_)."    ".$numst."\n");
	}
	if(defined($limhash->{$_}->{max})) {
		my $numst=sprintf("%f",$limhash->{$_}->{max});
		$numst.=sprintf("%0*d",(12-length($numst)),"0");
		$numst=length($numst)>12?substr($numst,0,12):$numst;
		print(" UP BND       R".sprintf("%05d",$_)."    ".$numst."\n");
	}
}
foreach(keys(%{$realrev})) {
	if(keys(%{$limhash->{$_}})) {
		if(defined($limhash->{$_}->{min})) {
			my $numst=sprintf("%f",$limhash->{$_}->{min});
			$numst.=sprintf("%0*d",(12-length($numst)),"0");
			$numst=length($numst)>12?substr($numst,0,12):$numst;
			print(" LO BND       R".sprintf("%05d",$_)."    ".$numst."\n");
		}
		if(defined($limhash->{$_}->{max})) {
			my $numst=sprintf("%f",$limhash->{$_}->{max});
			$numst.=sprintf("%0*d",(12-length($numst)),"0");
			$numst=length($numst)>12?substr($numst,0,12):$numst;
			print(" UP BND       R".sprintf("%05d",$_)."    ".$numst."\n");
		}
	}
	else {
		print(" FR BND       R".sprintf("%05d",$_)."\n");
	}
}
foreach(keys(%{$blockhash})) {
	defined($skip->{$_})&&next;
	$blockhash->{$_}||next;
	print(" BV BND       ACTR".sprintf("%05d",$_)."\n");
}
print("ENDATA\n");
