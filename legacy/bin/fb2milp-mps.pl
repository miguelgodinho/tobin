#!/usr/bin/perl -I. -w
use strict;
use warnings;
use Tobin::IF;

@ARGV<5&&die("Too few arguments");
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
open(WE, $ARGV[2])||die("Cannot open blockable file.");
my $blockhash={};
@tab=<WE>;
close(WE);
foreach(@tab) {
	chomp;
	$blockhash->{$_}=1;
	defined($revhash->{$_})&&($blockhash->{$revhash->{$_}}=1);
}
#$blockhash->{$ARGV[2]}=1;
#defined($revhash->{$ARGV[2]})&&($blockhash->{$revhash->{$ARGV[2]}}=1);
my $objective={}; 
$objective->{$ARGV[3]}=1;
my $limit=$ARGV[4];
my $skip={};
my $cpdhash={0=>{},1=>{}};
my $limhash={};
my $free={};
my $primobj={};
my $limval=10000;
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
			$limhash->{$revhash->{$_->[0]}}->{min}=-$_->[2];
		}
	}
}
foreach(keys(%{$limhash})) {
	if(defined($revhash->{$_})&&defined($blockhash->{$_})) {
		defined($limhash->{$_}->{min})||($limhash->{$_}->{min}=-$limval);
		defined($limhash->{$_}->{max})||($limhash->{$_}->{max}=$limval);
	}
	elsif(defined($blockhash->{$_})&&(!defined($limhash->{$_}->{max}))) {
		$limhash->{$_}->{max}=$limval;
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
my $cdualhash={};
foreach(@{$fba->{TFSET}}) {
	defined($skip->{$_->[0]})&&next;
	$tfhash->{$_->[0]}={};
	my $tf=$tobin->transformationGet($_->[0]);
	foreach my $cpd (@{$tf->[2]}) {
		$tfhash->{$_->[0]}->{($cpd->{ext}?"E":"I")."C".sprintf("%04d",$cpd->{id})}=$cpd->{sto};
		$cdualhash->{($cpd->{ext}?"E":"I")."C".sprintf("%04d",$cpd->{id})}=1;
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
print(" E  OBJFEAS\n");
foreach my $ext (keys(%{$cpdhash})) {
	foreach my $cpd (keys(%{$cpdhash->{$ext}})) {
		print(" E  L".($ext?"E":"I")."C".sprintf("%04d",$cpd)."\n");
	}
}
foreach(keys(%{$limhash})) {
	defined($limhash->{$_}->{min})&&defined($blockhash->{$_})&&
	print(" L  LAIR".sprintf("%04d",$_)."\n");
	defined($limhash->{$_}->{max})&&defined($blockhash->{$_})&&
	print(" L  LAAR".sprintf("%04d",$_)."\n");
}
foreach(keys(%{$tfhash})) {
	print(" ".(defined($realinv->{$_})?"G":"E")."  LR".sprintf("%04d",$_)."\n");
}
foreach(keys(%{$blockhash})) {
	defined($skip->{$_})&&next;
	print(" G  MAR".sprintf("%04d",$_)."\n");
}
print(" G  DLIM\n");
print("COLUMNS");
foreach(keys(%{$tfhash})) {
	my $count=0;
	foreach my $lim (keys(%{$tfhash->{$_}})) {
		($count%2)||print("\n    R".sprintf("%04d",$_)."     ");
		my $numst=sprintf("%f",$tfhash->{$_}->{$lim});
		$numst.=sprintf("%0*d",(12-length($numst)),"0");
		print("L".$lim."   ".
		$numst."   ");
		$count++;
	}
	if(defined($primobj->{$_})) {
		($count%2)||print("\n    R".sprintf("%04d",$_)."     ");
		my $numst=sprintf("%f",$primobj->{$_});
		$numst.=sprintf("%0*d",(12-length($numst)),"0");
		print("OBJFEAS   ".$numst."   ");
		$count++;
	}
	if(defined($objective->{$_})) {
		($count%2)||print("\n    R".sprintf("%04d",$_)."     ");
		my $numst=sprintf("%f",$objective->{$_});
		$numst.=sprintf("%0*d",(12-length($numst)),"0");
		print("OBJ       ".$numst."   ");
		$count++;
	}
	
	if(defined($limhash->{$_}->{min})&&defined($blockhash->{$_})) {
		($count%2)||print("\n    R".sprintf("%04d",$_)."     ");
		print("LAIR".sprintf("%04d",$_)."  "."-1.000000000"."   ");
		$count++;
	}
	if(defined($limhash->{$_}->{max})&&defined($blockhash->{$_})) {
		($count%2)||print("\n    R".sprintf("%04d",$_)."     ");
		print("LAAR".sprintf("%04d",$_)."  "."1.0000000000"."   ");
		$count++;
	}
	
}
foreach my $ext (keys(%{$cpdhash})) {
	foreach my $cpd (keys(%{$cpdhash->{$ext}})) {
		my $count=0;
		foreach (keys(%{$cpdhash->{$ext}->{$cpd}})) {
			($count%2)||print("\n    ".($ext?"E":"I")."C".sprintf("%04d",$cpd)."    ");
			my $numst=sprintf("%f",$cpdhash->{$ext}->{$cpd}->{$_});
			$numst.=sprintf("%0*d",(12-length($numst)),"0");
			print("LR".sprintf("%04d",$_)."    ".$numst."   ");
			$count++;
		}
	}
}
foreach(keys(%{$limhash})) {
	if(defined($limhash->{$_}->{min})&&$limhash->{$_}->{min}!=0) {
		print("\n    MINR".sprintf("%04d",$_)."  LR".sprintf("%04d",$_)."    ".
		"-1.000000000"."   ");
		if(defined($blockhash->{$_})) {
			print("MAR".sprintf("%04d",$_)."   "."-10000.00000   ");
		}
		elsif($limhash->{$_}->{min}!=0) {
			my $numst=sprintf("%f",-$limhash->{$_}->{min});
			$numst.=sprintf("%0*d",(12-length($numst)),"0");
			print("OBJFEAS   ".$numst."   ");
		}
		
	}
	if(defined($limhash->{$_}->{max})) {
		print("\n    MAXR".sprintf("%04d",$_)."  LR".sprintf("%04d",$_)."    ".
		"1.0000000000"."   ");
		if(defined($blockhash->{$_})) {
			print("MAR".sprintf("%04d",$_)."   "."-10000.00000   ");
		}
		elsif($limhash->{$_}->{max}!=0) {
			my $numst=sprintf("%f",$limhash->{$_}->{max});
			$numst.=sprintf("%0*d",(12-length($numst)),"0");
			print("OBJFEAS   ".$numst."   ");
		}
	}
}
print("\n    MARK00    'MARKER'                 'INTORG'");
foreach(keys(%{$blockhash})) {
	defined($skip->{$_})&&next;
	print("\n    ACTR".sprintf("%04d",$_)."  MAR".
	sprintf("%04d",$_)."   -10000.00000   "."DLIM      1.0000000000   ");
	print("\n    ACTR".sprintf("%04d",$_)."  LAAR".sprintf("%04d",$_).
	"  -10000.00000   ");
	defined($revhash->{$_})&&print("LAIR".sprintf("%04d",$_)."  -10000.00000   "); 	
}
print("\n    MARK00    'MARKER'                 'INTEND'");
print("\nRHS");
my $count=0;
foreach(keys(%{$primobj})) {
	($count%2)||print("\n    RHS       ");
	my $numst=sprintf("%f",-$primobj->{$_});
	$numst.=sprintf("%0*d",(12-length($numst)),"0");
	print("LR".sprintf("%04d",$_)."    ".$numst."   ");
	$count++;
}
foreach(keys(%{$blockhash})) {
	defined($skip->{$_})&&next;
	($count%2)||print("\n    RHS       ");
	print("MAR".sprintf("%04d",$_)."   -10000.00000   ");
	$count++;
}
($count%2)||print("\n    RHS       ");
my $numst=sprintf("%f",$limit);
$numst.=sprintf("%0*d",(12-length($numst)),"0");
print("DLIM      ".$numst);
print("\nBOUNDS\n");
foreach(keys(%{$realinv})) {
	if(defined($limhash->{$_}->{min})&&$limhash->{$_}->{min}!=0) {
		my $numst=sprintf("%f",$limhash->{$_}->{min});
		$numst.=sprintf("%0*d",(12-length($numst)),"0");
		$numst=length($numst)>12?substr($numst,0,12):$numst;
		print(" LO BND       R".sprintf("%04d",$_)."     ".$numst."\n");
	}
	if(defined($limhash->{$_}->{max})) {
		my $numst=sprintf("%f",$limhash->{$_}->{max});
		$numst.=sprintf("%0*d",(12-length($numst)),"0");
		$numst=length($numst)>12?substr($numst,0,12):$numst;
		print(" UP BND       R".sprintf("%04d",$_)."     ".$numst."\n");
	}
}
foreach(keys(%{$realrev})) {
	if(keys(%{$limhash->{$_}})) {
		if(defined($limhash->{$_}->{min})) {
			my $numst=sprintf("%12f",$limhash->{$_}->{min});
			$numst.=sprintf("%0*d",(12-length($numst)),"0");
			$numst=length($numst)>12?substr($numst,0,12):$numst;
			print(" LO BND       R".sprintf("%04d",$_)."     ".$numst."\n");
		}
		if(defined($limhash->{$_}->{max})) {
			my $numst=sprintf("%12f",$limhash->{$_}->{max});
			$numst.=sprintf("%0*d",(12-length($numst)),"0");
			$numst=length($numst)>12?substr($numst,0,12):$numst;
			print(" UP BND       R".sprintf("%04d",$_)."     ".$numst."\n");
		}
	}
	else {
		print(" FR BND       R".sprintf("%04d",$_)."\n");
	}
}
foreach(keys(%{$cdualhash})) {
	print(" FR BND       ".$_."\n");
}
foreach(keys(%{$blockhash})) {
	defined($skip->{$_})&&next;
	print(" BV BND       ACTR".sprintf("%04d",$_)."\n");
}
print("ENDATA\n");

