#!/usr/bin/perl -I/home/jap04/workspace/pseudo/ -w
use strict;
use warnings;
use Tobin::IF;
use Clone qw(clone);

my $tobin=new Tobin::IF(1);

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
open(WE, $ARGV[2])||die("Cannot open blockable file.");
my $blockhash={};
@tab=<WE>;
close(WE);
foreach(@tab) {
	chomp;
	$blockhash->{defined($revhash->{$_})?($_<$revhash->{$_}?$_:$revhash->{$_}):$_}=1;
}
open(WE,$ARGV[3])||die("Cannot open unblockable file");
my $unblockhash={};
@tab=<WE>;
close(WE);
foreach(@tab) {
	chomp;
	$unblockhash->{defined($revhash->{$_})?($_<$revhash->{$_}?$_:$revhash->{$_}):$_}=1;
}
my $fbaset=$tobin->fbasetupGet($ARGV[0]);
my $lpdata=getfbaset($fbaset,$revhash,$tobin);
my $filelist={};
for(7..(@ARGV-1)) {
	warn $_;
	open(WE, $ARGV[$_])||die("Cannot open results file $ARGV[$_]");
	my @tab1=<WE>;
	close(WE);
	$filelist->{$ARGV[$_]}=\@tab1;
}
my $obj=$ARGV[4];
my $fvatf=$ARGV[5];
my $type=$ARGV[6];
foreach(keys(%{$filelist})) {
	my $lpcopy=clone($lpdata);
	foreach my $tf (keys(%{$blockhash})) {
		my $mstr="ACTR".sprintf("%04d",$tf);
		if(!$type&&!grep(/$mstr/,@{$filelist->{$_}})||
		$type==1&&grep(/^$mstr +\. +\./,@{$filelist->{$_}})) {
			defined($lpcopy->{tfhash}->{$tf})||($lpcopy->{tfhash}->{$tf}={});
			$lpcopy->{tfhash}->{$tf}->{min}=0;
			$lpcopy->{tfhash}->{$tf}->{max}=0;
			defined($lpcopy->{free}->{$tf})&&delete($lpcopy->{free}->{$tf});
		}
	}
	foreach my $tf (keys(%{$unblockhash})) {
		my $mstr="ACTR".sprintf("%04d",$tf);
		if(!$type&&!grep(/$mstr/,@{$filelist->{$_}})||
		$type==1&&grep(/^$mstr +\. +\./,@{$filelist->{$_}})) {
			defined($lpcopy->{tfhash}->{$tf})||($lpcopy->{tfhash}->{$tf}={});
			$lpcopy->{tfhash}->{$tf}->{min}=0;
			$lpcopy->{tfhash}->{$tf}->{max}=0;
			defined($lpcopy->{free}->{$tf})&&delete($lpcopy->{free}->{$tf});
		}
	}
	my $aobj=abs($obj);
	my $mstr;
	my $mstr1;
	warn $type;
	if($type==0) {
		$mstr="^.{8}R".sprintf("%04d",$aobj);
		$mstr1.=$mstr."[ ]+([0-9.]+) ";
	}
	elsif($type==1) {
		$mstr="^R".sprintf("%04d",$aobj);
		$mstr1="^R".sprintf("%04d",$aobj)." +[-0-9.INF]+ +([-0-9.]+)";
	}
	(grep(/$mstr/,@{$filelist->{$_}}))[0]=~/$mstr1/;
	my $objval=$1*0.999;
	defined($lpcopy->{tfhash}->{$aobj})||($lpcopy->{tfhash}->{$aobj}={});
	$lpcopy->{tfhash}->{$aobj}->{$obj>0?"min":"max"}=$objval;
	defined($lpcopy->{free}->{$aobj})&&delete($lpcopy->{free}->{$aobj});
	$lpcopy->{objective}=-$fvatf;
	my $file=writelp($lpcopy);
#	open(WY, ">60fbatest.txt");
#	print(WY $file);
#	close(WY);
	my @result=`echo "$file"|~/Software/lp_solve/lp_solve -S1 -s0`;
	my $str="$_\tMin: ";
	if(@result>1) {
		$result[1]=~/Value of objective function: (.*)$/;
		$str.=$1;
	}
	else {
		$result[0]=~/(unbounded|infeasible)/;
		$str.=$1;
	}
	$str.="\tMax: ";
	$lpcopy->{objective}=$fvatf;
	$file=writelp($lpcopy);
	open(WY, ">fbatest.lp");
	print(WY $file);
	close(WY);
	@result=`echo "$file"|~/Software/lp_solve/lp_solve -S1 -s0`;
	if(@result>1) {
		$result[1]=~/Value of objective function: (.*)$/;
		$str.=$1;
	}
	else {
		$result[0]=~/(unbounded|infeasible)/;
		$str.=$1;
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
