#!/usr/bin/perl -I. -w
use strict;
use warnings;
use Tobin::IF;
use Clone qw(clone);

@ARGV<5&&die("Too few arguments!");

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

open(WE,$ARGV[2])||die("Cannot open tf anno!");
@tab=<WE>;
close(WE);
my $tfanno={};
my $ecannorev={};
foreach(@tab) {
	chomp;
	my @tab1=split(/\t/,$_);
	my $tf=shift(@tab1);
	$tfanno->{$tf}={};
	foreach my $ec(@tab1) {
		$tfanno->{$tf}->{$ec}=1;
		defined($ecannorev->{$ec})||($ecannorev->{$ec}={});
		$ecannorev->{$ec}->{$tf}=1;
	}
}
my $exctf={};
if(@ARGV>6) {
	open(WE,$ARGV[6])||die("Cannot open excluded reaction list");
	@tab=<WE>;
	close(WE);
	foreach(@tab) {
		chomp;
		$exctf->{$_}=1;
	}
}
my $cpanno={};
my $geannorev={};
open(WE,$ARGV[4])||die("Cannot open cp anno!");
@tab=<WE>;
close(WE);
foreach(@tab) {
	chomp;
	my @tab1=split(/\t/,$_);
	my $cp=shift(@tab1);
	$cpanno->{$cp}={};
	foreach my $ge (@tab1) {
#		defined($exgenes->{$ge})&&next;
		$cpanno->{$cp}->{$ge}=1;
		defined($geannorev->{$ge})||($geannorev->{$ge}={});
		$geannorev->{$ge}->{$cp}=1;
	}
}
open(WE,$ARGV[3])||die("Cannot open ec anno!");
@tab=<WE>;
close (WE);
my $ecanno={};
my $cpannorev={};
foreach(@tab) {
	chomp;
	my @tab1=split(/\t/,$_);
	my $ec=shift(@tab1);
	$ecanno->{$ec}={};
	foreach my $cp (@tab1) {
		$ecanno->{$ec}->{$cp}=1;
		defined($cpannorev->{$cp})||($cpannorev->{$cp}={});
		$cpannorev->{$cp}->{$ec}=1;
	}
}
open(WE,$ARGV[5])||die("Cannot open deletions list");
@tab=<WE>;
close(WE);
my $tobin;
my $pointhash={};
my $lpdata;
if($ARGV[0]) {
	$tobin= new Tobin::IF(1);
	my $fbaset=$tobin->fbasetupGet($ARGV[0]);
	$lpdata=getfbaset($fbaset,$revhash,$tobin);
}
foreach(@tab) {
	chomp;
	my @tab1=split(/\t/,$_);
	my $eacopy=clone($ecanno);
	my $earcopy=clone($ecannorev);
	my $tacopy=clone($tfanno);
	my $carcopy=clone($cpannorev);
	my $cacopy=clone($cpanno);
	my $garcopy=clone($geannorev);
	my $cpinact={};
	my $ec2check={};
	my $delhash={};
	foreach my $gene (@tab1) {
		$delhash->{$gene}=1;
		foreach my $cp (keys(%{$garcopy->{$gene}})) {
			$cpinact->{$cp}=1;
		}
	}
	foreach my $cp (keys(%{$cpinact})) {
		foreach my $ec (keys(%{$carcopy->{$cp}})) {
			$ec2check->{$ec}=1;
		}
	}
	my $ecinact={};
	foreach my $ec (keys(%{$ec2check})) {
		my $res=1;
		foreach my $cp (keys(%{$eacopy->{$ec}})) {
			$res&=defined($cpinact->{$cp})
		}
		$res&&($ecinact->{$ec}=1);
	}
	my $tf2check={};
	foreach my $ec (keys(%{$ecinact})) {
		foreach my $tf (keys(%{$earcopy->{$ec}})) {
			$tf2check->{$tf}=1;
		}
	}
	my $tfinact={};
	foreach my $tf (keys(%{$tf2check})) {
		my $res=1;
		foreach my $ec (keys(%{$tacopy->{$tf}})) {
			$res&=!defined($ecanno->{$ec})||defined($ecinact->{$ec});
		}
		$res&&($tfinact->{$tf}=1);
	}
	if($ARGV[0]) {
		my $str="";
		foreach my $gene (@tab1) {
			$str.=$gene.",";
		}
		chop($str);
		$str.="\t";
		keys(%{$tfinact})||(print($str."No affected TFs\n")&&next);
		my $fbacopy=clone($lpdata);
		foreach my $tf (keys(%{$tfinact})) {
			defined($exctf->{$tf})&&next;
#			print($tf."\n");
			my $rea;
			if($tf=~m%/%) {
				$tf=~m%(.*)/(.*)%;
				$revhash->{$1}==$2||die("Inconsistency in reversibility for $1 and $2");
				$rea=$1<$2?$1:$2;
			}
			else {
				$rea=$tf;
			}
			$fbacopy->{tfhash}->{$rea}->{min}=0;
			$fbacopy->{tfhash}->{$rea}->{max}=0;
			defined($fbacopy->{free}->{$rea})&&delete($fbacopy->{free}->{$rea});
		}
		my $file=writelp($fbacopy);
#		open(WY, ">fbadump.txt");
#				print(WY $file);
#				close(WY);
		for(my $i=1;$i<8;$i++) {
			my @result=`echo "$file"|~/Software/lp_solve/lp_solve -S1 -s$i`;
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
	else {
		my $str="";
		foreach my $gene (@tab1) {
			$str.=$gene.",";
		}
		$str=~s/,$//;
		$str.="\t";
		foreach my $tf(keys(%{$tfinact})) {
			$str.=$tf.", ";
		}
		$str=~s/, $//;
		length($str)&&print($str."\n");
	}
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
