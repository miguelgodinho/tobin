#!/usr/bin/perl -I. -w
use strict;
use warnings;
use Tobin::IF;
use Clone qw(clone);

open(WE, $ARGV[1])||die("Cannot open reversibles file");
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
open(WE,$ARGV[2])||die("Cannot open excluded file");
@tab=<WE>;
close(WE);
my $excluded={};
foreach(@tab) {
	chomp;
	$excluded->{$_}=1;
}
my $tobin= new Tobin::IF(1);
my $fbaset=$tobin->fbasetupGet($ARGV[0]);
my $lpdata=getfbaset($fbaset,$revhash,$tobin);
my $skip={};
foreach(@{$fbaset->{TFSET}}) {
	defined($skip->{$_->[0]})&&next;
	(defined($excluded->{$_->[0]})||
	defined($revhash->{$_->[0]})&&defined($excluded->{$revhash->{$_->[0]}}))&&next;
	defined($revhash->{$_->[0]})&&($skip->{$revhash->{$_->[0]}}=1);
	my $lpcopy=clone($lpdata);
	my $rea=defined($revhash->{$_->[0]})&&$_->[0]>$revhash->{$_->[0]}?
	$revhash->{$_->[0]}:$_->[0];
	$lpcopy->{tfhash}->{$rea}->{min}=0;
	$lpcopy->{tfhash}->{$rea}->{max}=0;
	defined($lpcopy->{free}->{$rea})&&delete($lpcopy->{free}->{$rea});
	my $file=writelp($lpcopy);
	if($_->[0]==1826) {
		open(WY, ">fba-test1.txt");
		print(WY $file);
		close(WY);
	}
	my $str=defined($revhash->{$_->[0]})?($_->[0]<$revhash->{$_->[0]}?
	$_->[0]."/".$revhash->{$_->[0]}:$revhash->{$_->[0]}."/".$_->[0]):$_->[0];
	$str.="\t";
	for(my $i=0;$i<8;$i++) {
		my @result=`echo "$file"|~/Software/lp_solve/lp_solve -S1 -timeout 30 -s$i`;
		if(@result>1&&$result[1]=~/Value of objective function: (.*)$/) {
			$str.=$1;
			last;
		}
		elsif($result[0]=~/(infeasible)/) {
			$str.=$1;
			last;
		}
	}
	print($str."\n");
}


sub getfbaset {
	my $fba=shift;
	my $revhash=shift;
	my $tobin=shift;
my $skip={};
my $objective;
my $cpdhash={0=>{},1=>{}};
my $tfhash={};
my $free={};
foreach(@{$fba->{TFSET}}) {
	defined($skip->{$_->[0]})&&next;
	defined($revhash->{$_->[0]})&&($_->[0]<$revhash->{$_->[0]}?
	($skip->{$revhash->{$_->[0]}}=1):next);
	$tfhash->{$_->[0]}={};
	my $tf=$tobin->transformationGet($_->[0]);
	if($_->[1]!=0) {
		$objective=$_->[1]>0?$_->[0]:-$_->[0];
	}
	$_->[2]>0&&($tfhash->{$_->[0]}->{min}=$_->[2]);
	defined($_->[3])&&($tfhash->{$_->[0]}->{max}=$_->[3]);
	foreach my $cpd(@{$tf->[2]}) {
		defined($cpdhash->{$cpd->{ext}}->{$cpd->{id}})||
		($cpdhash->{$cpd->{ext}}->{$cpd->{id}}={});
		$cpdhash->{$cpd->{ext}}->{$cpd->{id}}->{$_->[0]}=$cpd->{sto};
	}
}
foreach(@{$fba->{TFSET}}) {
	defined($skip->{$_->[0]})||next;
	if($_->[1]!=0) {
		$objective=$_->[1]>0?-$revhash->{$_->[0]}:$revhash->{$_->[0]};
	}
	if($_->[2]>0) {
		if(defined($tfhash->{$revhash->{$_->[0]}}->{min})||
		(defined($tfhash->{$revhash->{$_->[0]}}->{max})&&
		$tfhash->{$revhash->{$_->[0]}}->{max}>0)) {
			die("Tf $_->[0] - inconsistency in limits");
		}
		else {
			$tfhash->{$revhash->{$_->[0]}}->{max}=-$_->[2];
		}
	}
	if(defined($_->[3])) {
		if(defined($tfhash->{$revhash->{$_->[0]}}->{min})&&
		$tfhash->{$revhash->{$_->[0]}}->{min}>0) {
			die("Tf $_->[0] - inconsistency in limits");
		}
		else {
			$tfhash->{$revhash->{$_->[0]}}->{min}=-$_->[3];
		}
	}
}
foreach(keys(%{$tfhash})) {
	if(defined($revhash->{$_})) {
		defined($tfhash->{$_}->{max})&&!defined($tfhash->{$_}->{min})&&
		($tfhash->{$_}->{min}=-1e30);
		!defined($tfhash->{$_}->{min})&&!defined($tfhash->{$_}->{max})&&
		($free->{$_}=1);
	}
}

my $ouput={cpdhash=>$cpdhash, tfhash=>$tfhash, free=>$free, objective=>$objective};
return $ouput;
}

sub writelp {
	my $lpdata=shift;
	my $objective=$lpdata->{objective};
	my $cpdhash=$lpdata->{cpdhash};
	my $tfhash=$lpdata->{tfhash};
	my $free=$lpdata->{free};
	
	my $output="";
	$output.=($objective<0?"min: ":"")."R".sprintf("%04d",abs($objective)).";\n\n";
	foreach my $ext (keys(%{$cpdhash})) {
		foreach my $cpd (keys(%{$cpdhash->{$ext}})) {
			$output.=($ext>0?"EX_":"")."C".sprintf("%04d",$cpd).": ";
			foreach(keys(%{$cpdhash->{$ext}->{$cpd}})) {
				$output.=($cpdhash->{$ext}->{$cpd}->{$_}>0?"+":"").
				$cpdhash->{$ext}->{$cpd}->{$_}." R".sprintf("%04d",$_)." ";
			}
			$output.="= 0;\n";
		}
	}
	$output.="\n";
	foreach(keys(%{$tfhash})) {
		defined($tfhash->{$_}->{min})&&
		($output.="R".sprintf("%04d",$_)." >= ".$tfhash->{$_}->{min}.";\n");
		defined($tfhash->{$_}->{max})&&
		($output.="R".sprintf("%04d",$_)." <= ".$tfhash->{$_}->{max}.";\n");
	}
	$output.="\nfree ";
	foreach(keys(%{$free})) {
		$output.="R".sprintf("%04d",$_).",";
	}
	chop($output);
	$output.=";\n";
}
