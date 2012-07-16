#!/usr/bin/perl -I. -w
use strict;
use warnings;
use Tobin::IF;

my $tobin=new Tobin::IF(1);
my $lpdata=getfbaset($ARGV[0],$ARGV[1],$ARGV[2]);
$lpdata->{tfhash}->{0}={};
$lpdata->{tfhash}->{0}->{max}=10;
open(WE,$ARGV[3])||die("Cannot open souces list");
my @srclist=<WE>;
close(WE);
foreach(@srclist) {
	chomp;
	my $str=$_."\t".$tobin->compoundNameGet($_)."\t";
	if(!defined($lpdata->{cpdhash}->{1}->{$_})) {
		$str.="NIS";
	}
	else {
		$lpdata->{cpdhash}->{1}->{$_}->{0}=1;
		my $file=writelp($lpdata);
#	open(WY, ">fba-test.txt");
#	print(WY $file);
#	close(WY);
#	exit;
		my @result=`echo "$file"|~/Software/lp_solve/lp_solve -S1 -s0`;
		if(@result>1) {
			$result[1]=~/Value of objective function: (.*)$/;
			$str.=$1;
		}
		else {
			$result[0]=~/(unbounded|infeasible)/;
			$str.=$1;
		}
		delete($lpdata->{cpdhash}->{1}->{$_}->{0});
	}
	$str.="\t";
	if(!defined($lpdata->{cpdhash}->{0}->{$_})) {
		$str.="NIS";
	}
	else {
		$lpdata->{cpdhash}->{0}->{$_}->{0}=1;
		my $file=writelp($lpdata);
#	open(WY, ">fba-test.txt");
#	print(WY $file);
#	close(WY);
#	exit;
		my @result=`echo "$file"|~/Software/lp_solve/lp_solve -S1 -s0`;
		if(@result>1) {
			$result[1]=~/Value of objective function: (.*)$/;
			$str.=$1;
		}
		else {
			$result[0]=~/(unbounded|infeasible)/;
			$str.=$1;
		}
		delete($lpdata->{cpdhash}->{0}->{$_}->{0});
	}
	print($str."\n");
	
}

sub getfbaset {
	my $setup=shift;
	my $uid=shift;
	my $revfile=shift;
	#!/usr/bin/perl -I. -w
	
	my $tobin	= new Tobin::IF($uid);
	my $fba=$tobin->fbasetupGet($setup);
open(WE, $revfile)||die("Cannot open reversible file.");
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
