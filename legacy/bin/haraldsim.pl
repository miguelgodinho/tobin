#!/usr/bin/perl -w -I.
use strict;
use warnings;
use Tobin::IF;

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
my $tobin=new Tobin::IF(1);
my $fbaset=$tobin->fbasetupGet($ARGV[0]);
my $csrc=[];
open(WE,$ARGV[2])||die("Cannot open c-sources reaction list!");
@tab=<WE>;
close(WE);
foreach(@tab) {
	chomp;
	push(@{$csrc},$_);
}
my $size=@{$csrc};
my $lpdata=getfbaset($fbaset,$revhash,$tobin);
my $combinations=getcomb($size,$ARGV[3]);
#warn(@{$combinations}." ");
foreach my $set (@{$combinations}) {
#	warn(@{$set}." ");
	foreach (@{$set}) {
		delete($lpdata->{tfhash}->{$csrc->[$_]}->{max});
	}
	my $file=writelp($lpdata);
	my $res;
	for(my $i=-1;$i<8;$i++) {
		
		my @result=$i<0?`echo "$file"|~/Software/lp_solve/lp_solve -S1 -timeout 30`:
		`echo "$file"|~/Software/lp_solve/lp_solve -S1 -s$i -timeout 30`;
		if(@result>1&&$result[1]=~/Value of objective function: (.*)$/) {
			$res=$1;
			@result=$i<0?`echo "$file"|~/Software/lp_solve/lp_solve -S2 -timeout 30`:
			`echo "$file"|~/Software/lp_solve/lp_solve -S2 -s$i -timeout 30`;
			foreach(@{$set}) {
				my $patt="^R".$csrc->[$_]." +[0-9-.eE]+\$";
				my @match=grep(/$patt/,@result);
				@match!=1&&warn("Too many/few matches for $csrc->[$_]");
				$match[0]=~/ +([0-9-.eE]+)$/;
				$res.="\t".$1;
			}
			last;
		}
	}
	foreach (@{$set}) {
		$lpdata->{tfhash}->{$csrc->[$_]}->{max}=0;
		print($csrc->[$_]."\t");
	}
	print($res."\n");
	
}

sub getcomb {
	my $size=shift;
	my $ext=shift;
	my $permtable=[[]];
	getcomb1($permtable,0,$size-$ext,0,$size);
	my $result=[];
	foreach(@{$permtable}) {
		push(@{$result},[]);
		foreach my $e (0..($size-1)) {
			$_->[$e]||push(@{$result->[@{$result}-1]},$e);
		}
	}
	return $result
}

sub getcomb1 {
	my $permtable=shift;
	my $counter=shift;
	my $max=shift;
	my $pos=shift;
	my $maxlen=shift;
	if($max-$counter<$maxlen-@{$permtable->[$pos]}&&
	$counter<$max) {
		push(@{$permtable},[]);
		foreach(@{$permtable->[$pos]}) {
			push(@{$permtable->[@{$permtable}-1]},$_);
		}
		push(@{$permtable->[@{$permtable}-1]},1);
		getcomb1($permtable,$counter+1,$max,@{$permtable}-1,$maxlen);
		push(@{$permtable->[$pos]},0);
		getcomb1($permtable,$counter,$max,$pos,$maxlen);
	}
	elsif($counter==$max) {
		for(1..($maxlen-@{$permtable->[$pos]})) {
			push(@{$permtable->[$pos]},0)
		}
	}
	else {
		for(1..($maxlen-@{$permtable->[$pos]})) {
			push(@{$permtable->[$pos]},1)
		}
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
