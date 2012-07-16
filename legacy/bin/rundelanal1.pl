#!/usr/bin/perl -I. -w
use strict;
use warnings;
use Tobin::IF;
use Clone qw(clone);

@ARGV<6&&die("Too few arguments!");


open(WE,$ARGV[3])||die("Cannot open tf anno!");
my @tab=<WE>;
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

open(WE,$ARGV[4])||die("Cannot open ec anno!");
@tab=<WE>;
close (WE);
my $ecanno={};
my $geannorev={};
foreach(@tab) {
	chomp;
	my @tab1=split(/\t/,$_);
	@tab1||next;
	my $ec=shift(@tab1);
	shift(@tab1);
	$ecanno->{$ec}={};
	my $logic=shift(@tab1);
	while(@tab1) {
		my $ge=shift(@tab1);
		($ge=~/PP[0-9]{4}/)||(($logic=$ge)&&next);
		$ecanno->{$ec}->{$ge}=$logic;
		defined($geannorev->{$ge})||($geannorev->{$ge}={});
		$geannorev->{$ge}->{$ec}=$logic;
	}
}

open(WE,$ARGV[5])||die("Cannot open deletions list");
@tab=<WE>;
close(WE);
my $lpdata;
$ARGV[0]&&($lpdata=getfbaset($ARGV[0],$ARGV[1],$ARGV[2]));
foreach(@tab) {
	chomp;
	my @tab1=split(/\t/,$_);
	my $eacopy=clone($ecanno);
	my $earcopy=clone($ecannorev);
	my $tacopy=clone($tfanno);
	my $garcopy=clone($geannorev);
	my $ec2check={};
	my $delhash={};
	foreach my $gene (@tab1) {
		$delhash->{$gene}=1;
		foreach my $ec (keys(%{$garcopy->{$gene}})) {
			$ec2check->{$ec}=1;
		}
	}
	my $ecinact={};
	foreach my $ec (keys(%{$ec2check})) {
		my $resor=1;
		my $resand=0;
		my $andpres=0;
		foreach my $ge (keys(%{$eacopy->{$ec}})) {
			if(!$resand&&$eacopy->{$ec}->{$ge} eq "AND") {
				($resand|=defined($delhash->{$ge}));
				$andpres=1;
			}
			$eacopy->{$ec}->{$ge} eq "OR"&&($resor&=defined($delhash->{$ge}));
		}
		$andpres&&($resor&=$resand);
		$resor&&($ecinact->{$ec}=1);
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
			$res&=defined($ecinact->{$ec});
		}
		$res&&($tfinact->{$tf}=1);
	}
	my $str="";
	foreach my $gene (@tab1) {
		$str.=$gene.",";
	}
	chop($str);
	print($str."\t");
	if($ARGV[0]) {
		keys(%{$tfinact})||(print("No affected TFs\n")&&next);
		my $lpcopy=clone($lpdata);
		foreach my $tf (keys(%{$tfinact})) {
			$tf=~s%/.*$%%;
			defined($lpcopy->{tfhash}->{$tf}->{min})&&
			delete($lpcopy->{tfhash}->{$tf}->{min});
			defined($lpcopy->{tfhash}->{$tf})||
			($lpcopy->{tfhash}->{$tf}={});
			$lpcopy->{tfhash}->{$tf}->{max}=0;
			defined($lpcopy->{free}->{$tf})&&
			delete($lpcopy->{free}->{$tf});
		}
		my $file=writelp($lpcopy);
		my @result=`echo "$file" |~/Software/lp_solve/lp_solve -S1`;
		if(@result>1) {
			$result[1]=~/Value of objective function: (.*)$/;
			print($1."\n");
		}
		else {
			print($result[0]);
		}
		
	}
	else {
		my $str1="";
		foreach my $tf(keys(%{$tfinact})) {
			$str1.=$tf.", ";
		}
		$str1=~s/, $//;
		print((length($str1)?$str1:"No affected TFs")."\n");
	}
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


