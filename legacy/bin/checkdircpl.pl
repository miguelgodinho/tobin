#!/usr/bin/perl -I. -w
use strict;
use warnings;
use Tobin::IF;
use Clone qw(clone);

@ARGV<3&&die("Too few arguments");
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
open(WE,$ARGV[2])||die("Cannot open reaction list");
@tab=<WE>;
close(WE);
my $tocheck={};
foreach(@tab) {
	chomp;
	my @tab1=split(/\t/,$_);
	defined($tocheck->{$tab1[0]})||($tocheck->{$tab1[0]}={});
	$tocheck->{$tab1[0]}->{$tab1[1]}=1;
}
my $tobin=new Tobin::IF(1);
my $fbaset=$tobin->fbasetupGet($ARGV[0]);
my $lpdata=getfbaset($fbaset,$tobin);
foreach(keys(%{$tocheck})) {
	my $lpcopy=clone($lpdata);
	defined($lpcopy->{tfhash}->{$_})||($lpcopy->{tfhash}->{$_}={});
	$lpcopy->{tfhash}->{$_}->{min}=10;
	$lpcopy->{tfhash}->{$_}->{max}=10;
	if(defined($revhash->{$_})) {
		defined($lpcopy->{tfhash}->{$revhash->{$_}})||
		($lpcopy->{tfhash}->{$revhash->{$_}}={});
		$lpcopy->{tfhash}->{$revhash->{$_}}->{max}=0;
		$lpcopy->{tfhash}->{$revhash->{$_}}->{min}=0;
		
	}
	defined($lpcopy->{free}->{$_})&&delete($lpcopy->{free}->{$_});
	foreach my $ctf (keys(%{$tocheck->{$_}})) {
		my $lpcopy1=clone($lpcopy);
		if(defined($revhash->{$ctf})) {
			defined($lpcopy1->{tfhash}->{$revhash->{$ctf}})||($lpcopy1->{tfhash}->{$revhash->{$ctf}}={});
			$lpcopy1->{tfhash}->{$revhash->{$ctf}}->{min}=0;
			$lpcopy1->{tfhash}->{$revhash->{$ctf}}->{max}=0;
		}
		$lpcopy1->{objective}=-$ctf;
		my $file=writelp($lpcopy1);
#		if($_==244) {
#			open(WY,">dcpltest.lp.txt");
#			print(WY $file);
#			close(WY);
#		}
		my $min;
		for(my $k=1;$k<8;$k++) {	
			my @result=`echo "$file"|~/Software/lp_solve/lp_solve -timeout 30 -S1 -s$k`;
			if(@result>1&&$result[1]=~/Value of objective function: (.*)$/) {
				$min=$1;
				last;
			}
			elsif($result[0]=~/unbounded/){
				$min='i';
				last;
			}
			elsif($result[0]=~/infeasible/)
			{
				$min=0;
				last;
			}
			else {
				my $str=$ctf."\t".$_.", min strange result:\n";
				foreach my $line (@result) {
					$str.=$line;
				}
				warn($str);
				if(defined($revhash->{$_})){
					$min='c';
				}
			}
			
		}
		$lpcopy1->{objective}=$ctf;
		$file=writelp($lpcopy1);
		my $max;
		for(my $k=1;$k<8;$k++) {
			my @result=`echo "$file"|~/Software/lp_solve/lp_solve -timeout 30 -S1 -s$k`;
			if(@result>1&&$result[1]=~/Value of objective function: (.*)$/) {
				$max=$1;
				last;
			}
			elsif($result[0]=~/unbounded/){
				$max='i';
				last;
			}
			elsif($result[0]=~/infeasible/)
			{
				$max=0;
				last;
			}
			else {
				my $str=$ctf."\t".$_.", max strange result:\n";
				foreach my $line (@result) {
					$str.=$line;
				}
				warn($str);
				if($min eq 'c') {
					$max=$min=0;
				}
			}
		}
		if($min ne 'i'&&$min>0&&$max eq 'i'||$max ne 'i'&&$max<0&&$min eq 'i') {
			print ($_."->".$ctf."\n");
			print ($_."\t".$ctf."\t".$min."\t".$max."\n");
		}
		else {
			print ($_."\t".$ctf."\t".$min."\t".$max."\n");
			my $lpcopy2=clone($lpdata);
			defined($lpcopy2->{tfhash}->{$ctf})||($lpcopy2->{tfhash}->{$ctf}={});
			$lpcopy2->{tfhash}->{$ctf}->{min}=10;
			$lpcopy2->{tfhash}->{$ctf}->{max}=10;
			if(defined($revhash->{$ctf})) {
				defined($lpcopy2->{tfhash}->{$revhash->{$ctf}})||
				($lpcopy2->{tfhash}->{$revhash->{$ctf}}={});
				$lpcopy2->{tfhash}->{$revhash->{$ctf}}->{min}=0;
				$lpcopy2->{tfhash}->{$revhash->{$ctf}}->{max}=0;
			}
			if(defined($revhash->{$_})) {
				defined($lpcopy2->{tfhash}->{$revhash->{$_}})||
				($lpcopy2->{tfhash}->{$revhash->{$_}}={});
				$lpcopy2->{tfhash}->{$revhash->{$_}}->{min}=0;
				$lpcopy2->{tfhash}->{$revhash->{$_}}->{max}=0;
			}
			$lpcopy2->{objective}=-$_;
			my $file1=writelp($lpcopy2);
			my $min1;
			for(my $k=1;$k<8;$k++) {	
				my @result=`echo "$file1"|~/Software/lp_solve/lp_solve -timeout 30 -S1 -s$k`;
				if(@result>1&&$result[1]=~/Value of objective function: (.*)$/) {
					$min1=$1;
					last;
				}
				elsif($result[0]=~/unbounded/){
					$min1='i';
					last;
				}
				elsif($result[0]=~/infeasible/)
				{
					$min1=0;
					last;
				}
				else {
					my $str=$_."\t".$_.", min strange result:\n";
					foreach my $line (@result) {
						$str.=$line;
					}
					warn($str);
				}	
			}
			$lpcopy2->{objective}=$_;
			$file1=writelp($lpcopy2);
			my $max1;
#			if($_==9082) {
#			open(WY,">dcpltest.lp.txt");
#			print(WY $file1);
#			close(WY);
#		}
			for(my $k=1;$k<8;$k++) {
				my @result=`echo "$file1"|~/Software/lp_solve/lp_solve -timeout 30 -S1 -s$k`;
				if(@result>1&&$result[1]=~/Value of objective function: (.*)$/) {
					$max1=$1;
					last;
				}
				elsif($result[0]=~/unbounded/){
					$max1='i';
					last;
				}
				elsif($result[0]=~/infeasible/)
				{
					$max1=0;
					last;
				}
				else {
					my $str=$ctf."\t".$_.", max strange result:\n";
					foreach my $line (@result) {
						$str.=$line;
					}
					warn($str);
				}
			}
			if($min1 ne 'i'&&$min1==0&&$max1 ne 'i' &&$max1>0) {
				print ($_."->".$ctf."\n");
				print ($_."\t".$ctf."\t".$min1."\t".$max1."\n");
			}
			else {
				print ($_."\t".$ctf."\t".$min."\t".$max."\n");
			}
		}
	}
}

sub getfbaset {
	my $fba=shift;
	my $tobin=shift;
my $skip={};
my $objective;
my $cpdhash={0=>{},1=>{}};
my $tfhash={};
my $free={};
foreach(@{$fba->{TFSET}}) {
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
return {cpdhash=>$cpdhash, tfhash=>$tfhash, free=>$free, objective=>$objective};
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
