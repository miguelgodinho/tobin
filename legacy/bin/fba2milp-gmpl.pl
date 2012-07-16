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
my $objective=$ARGV[3];
my $limit=$ARGV[4];
my $skip={};
my $cpdhash={0=>{},1=>{}};
my $limhash={};
my $free={};
my $primobj;
foreach(@{$fba->{TFSET}}) {
	defined($skip->{$_->[0]})&&next;
	defined($revhash->{$_->[0]})&&($skip->{$revhash->{$_->[0]}}=1);
	if($_->[1]!=0) {
		$primobj=$_->[1]>0?$_->[0]:-$_->[0];
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
		$primobj=$_->[1]>0?-$revhash->{$_->[0]}:$revhash->{$_->[0]};
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
		defined($limhash->{$_}->{min})||($limhash->{$_}->{min}=-10000);
		defined($limhash->{$_}->{max})||($limhash->{$_}->{max}=10000);
	}
	elsif(defined($blockhash->{$_})&&(!defined($limhash->{$_}->{max}))) {
		$limhash->{$_}->{max}=10000;
	}
}
foreach(keys(%{$limhash})) {
	if(defined($revhash->{$_})) {
		defined($limhash->{$_}->{max})&&!defined($limhash->{$_}->{min})&&
		($limhash->{$_}->{min}=-10000);
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
		$tfhash->{$_->[0]}->{($cpd->{ext}?"EX_":"")."C".sprintf("%04d",$cpd->{id})}=$cpd->{sto};
		$cdualhash->{($cpd->{ext}?"EX_":"")."C".sprintf("%04d",$cpd->{id})}=1;
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

foreach(keys(%{$realinv})) {
	print("var R".sprintf("%04d",$_)." , >= ".(defined($limhash->{$_}->{min})?
	$limhash->{$_}->{min}:0).(defined($limhash->{$_}->{max})?
	" , <= ".$limhash->{$_}->{max}:"").";\n");
}
foreach(keys(%{$realrev})) {
	print("var R".sprintf("%04d",$_).(defined($limhash->{$_}->{min})?" , >= ".
	$limhash->{$_}->{min}:"").(defined($limhash->{$_}->{max})?
	" , <= ".$limhash->{$_}->{max}:"").";\n");
}
print("\n");
foreach(keys(%{$cdualhash})) {
	print("var $_;\n");
}
print("\n");
foreach(keys(%{$limhash})) {
	defined($limhash->{$_}->{min})&&print("var MINR".sprintf("%04d",$_).", >= 0;\n");
	defined($limhash->{$_}->{max})&&print("var MAXR".sprintf("%04d",$_).", >= 0;\n");
}
print("\n");
foreach(keys(%{$blockhash})) {
	defined($skip->{$_})&&next;
	print("var ACT_R".sprintf("%04d",$_)." , binary;\n");
}
print("\n");
print("maximize obj : $objective;\n");
print("\n");
my $dualobj="";
foreach(keys(%{$limhash})) {
	defined($blockhash->{$_})&&next;
	defined($limhash->{$_}->{max})&&$limhash->{$_}->{max}!=0&&
	($dualobj.="+".$limhash->{$_}->{max}." * "."MAXR".sprintf("%04d",$_)." ");
	defined($limhash->{$_}->{min})&&$limhash->{$_}->{min}!=0&&
	($dualobj.="-".$limhash->{$_}->{min}." * "."MINR".sprintf("%04d",$_)." ");
}

print("s.t. objfeas : ".$dualobj.($primobj>0?"-":"+")."R".
sprintf("%04d",abs($primobj))." , = 0;\n\n");
foreach my $ext (keys(%{$cpdhash})) {
	foreach my $cpd (keys(%{$cpdhash->{$ext}})) {
		my $str="s.t. L".($ext?"EX_":"")."C".sprintf("%04d",$cpd)." : ";
		foreach(keys(%{$cpdhash->{$ext}->{$cpd}})) {
			if($cpdhash->{$ext}->{$cpd}->{$_}==1) {
				$str.=" +";
			}
			elsif($cpdhash->{$ext}->{$cpd}->{$_}==-1) {
				$str.=" -";
			}
			elsif ($cpdhash->{$ext}->{$cpd}->{$_}>0) {
				$str.=" +".$cpdhash->{$ext}->{$cpd}->{$_}." * ";
			}
			else {
				$str.=$cpdhash->{$ext}->{$cpd}->{$_}." * ";
			}
			$str.="R".sprintf("%04d",$_)." ";
		}
		$str.=", = 0;\n";
		print($str);
	}
}
print("\n");
foreach(keys(%{$limhash})) {
	defined($limhash->{$_}->{min})&&defined($blockhash->{$_})&&
	print("s.t. LAMINR".sprintf("%04d",$_)." : ".
	($limhash->{$_}->{min}>0?"+":"").$limhash->{$_}->{min}." * ACT_R".
	sprintf("%04d",$_)." -R".sprintf("%04d",$_)." , <= 0;\n");
	defined($limhash->{$_}->{max})&&defined($blockhash->{$_})&&
	print("s.t. LAMAXR".sprintf("%04d",$_)." : ".
	"+R".sprintf("%04d",$_)." ".($limhash->{$_}->{max}>0?"-":"+").
	abs($limhash->{$_}->{max})." * ACT_R".sprintf("%04d",$_)." , <= 0;\n");
}
foreach(keys(%{$tfhash})) {
	my $str="s.t. LR".sprintf("%04d",$_)." : ";
	foreach my $cpd (keys(%{$tfhash->{$_}})) {
		if($tfhash->{$_}->{$cpd}==1) {
			$str.="+";
		}
		elsif($tfhash->{$_}->{$cpd}==-1) {
			$str.="-";
		}
		elsif($tfhash->{$_}->{$cpd}>0) {
			$str.="+".$tfhash->{$_}->{$cpd}." * ";
		}
		else {
			$str.=$tfhash->{$_}->{$cpd}." * ";
		}
		$str.=$cpd." ";
	}
	defined($limhash->{$_}->{max})&&($str.="+MAXR".sprintf("%04d",$_)." ");
	defined($limhash->{$_}->{min})&&$limhash->{$_}->{min}!=0&&
	($str.="-MINR".sprintf("%04d",$_)." ");
	$str.=", ".(defined($realinv->{$_})?">":"")."=".(abs($primobj)==$_?1:0).";\n";
	print($str);
}
print("\n");
foreach(keys(%{$blockhash})) {
	defined($skip->{$_})&&next;
	print("s.t. MAR".sprintf("%04d",$_)." : ".(defined($limhash->{$_}->{min})?
	(($limhash->{$_}->{min}>0?"+":"").$limhash->{$_}->{min}." * MINR".
	sprintf("%04d",$_)." "):"").($limhash->{$_}->{max}<0?"+":"-").
	abs($limhash->{$_}->{max}). " * MAXR".sprintf("%04d",$_).
	" -10000 * ACT_R".sprintf("%04d",$_).", >= -10000;\n");
}
my $sum=0;
print("\ns.t. DLIM :");
foreach(keys(%{$blockhash})) {
	defined($skip->{$_})&&next;
	print(" +ACT_R".sprintf("%04d",$_));
	$sum++;
}
print(", >=".($sum-$limit).";\n\n");
print("\ndata;\n\nend;\n");
