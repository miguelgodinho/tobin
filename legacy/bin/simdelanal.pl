#!/usr/bin/perl -I. -w
use strict;
use warnings;
use Tobin::IF;
use Clone qw(clone);

my $tfanno={};
my $geanno={};

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
open(WE, "imo1056scodes.2.csv")||die("cannot open scodes");
@tab=<WE>;
close(WE);
my $scodes={};
foreach(@tab) {
	chomp;
	my @tab1=split(/\t/,$_);
	$scodes->{$tab1[0]}= $tab1[1];
}
open(WE, $ARGV[2])||die("Cannot open gprs");
@tab=<WE>;
close(WE);
foreach(@tab) {
	chomp;
	my @tab1=split(/\t/,$_);
	my $sco=shift(@tab1);
	my $tf=$scodes->{$sco};
	defined($tf)||next;
	$tfanno->{$tf}={};
	my $ind=0;
	foreach my $cp (@tab1) {
		$tfanno->{$tf}->{$ind}={};
		my @tab2=split(/,/,$cp);
		foreach my $ge (@tab2) {
			$tfanno->{$tf}->{$ind}->{$ge}=1;
			defined($geanno->{$ge})||($geanno->{$ge}={});
			$geanno->{$ge}->{$tf}=1;
		}
		$ind++;
	}
}
#warn(keys(%{$geanno->{PA0005}})." ");
my $tobin;
my $lpdata;
if($ARGV[0]) {
	$tobin= new Tobin::IF(1);
	my $fbaset=$tobin->fbasetupGet($ARGV[0]);
	$lpdata=getfbaset($fbaset,$revhash,$tobin);
}
open(WE,$ARGV[3])||die("Cannot open deletion list");
@tab=<WE>;
close(WE);
foreach(@tab) {
	chomp;
	my $afftf={};
	my @tab1=split(/,/,$_);
	foreach my $ge (@tab1) {
		foreach my $tf (keys(%{$geanno->{$ge}})) {
			$afftf->{$tf}=clone($tfanno->{$tf});
		}
	}
	if(!keys(%{$afftf})) {
		print($_."\tNo affected TFs\n");
		next;
	}
#	warn(keys(%{$afftf})." ");
	foreach my $tf (keys(%{$afftf})) {
#		warn(keys(%{$afftf->{$tf}})."");
		foreach my $ind (keys(%{$afftf->{$tf}})) {
			foreach my $ge (@tab1) {
#				warn($ge);
				defined($afftf->{$tf}->{$ind}->{$ge})&&
				delete($afftf->{$tf}->{$ind});
			}
#			keys(%{$afftf->{$tf}->{$ind}})||delete($afftf->{$tf}->{$ind});
		}
	}
	my $aff=0;
	foreach my $tf (keys(%{$afftf})) {
		keys(%{$afftf->{$tf}})||(($aff=1)&&last);
	}
	if(!$aff) {
		print($_."\tNo affected TFs\n");
#		warn("aaa");
		next;
		
	}
	if($ARGV[0]) {
		my $lpcopy=clone($lpdata);
		foreach my $tf (keys(%{$afftf})) {
			keys(%{$afftf->{$tf}})&&next;
			my $rea=defined($revhash->{$tf})?
			($tf<$revhash->{$tf}?$tf:$revhash->{$tf}):$tf;
			$lpcopy->{tfhash}->{$rea}->{min}=0;
			$lpcopy->{tfhash}->{$rea}->{max}=0;
			defined($lpcopy->{free}->{$rea})&&delete($lpcopy->{free}->{$rea});
			
		}
		my $file=writelp($lpcopy);
		my $res="";
		for(my $i=-1;$i<8;$i++) {	
			my @result=$i<0?`echo "$file"|~/Software/lp_solve/lp_solve -S1 -timeout 30`:
			`echo "$file"|~/Software/lp_solve/lp_solve -S1 -s$i -timeout 30`;
			if(@result>1&&$result[1]=~/Value of objective function: (.*)$/) {
				$res=$1;
				last;
			}
		}
		print($_."\t".$res."\n");
	}
	else {
		my $str="";
		foreach my $tf (keys(%{$afftf})) {
			keys(%{$afftf->{$tf}})&&next;
			my $rea=defined($revhash->{$tf})?
			($tf<$revhash->{$tf}?$tf."/".$revhash->{$tf}:$revhash->{$tf}."/".$tf):
			$tf;
			$str.=$rea.",";
		}
		chop($str);
		print($_."\t".$str."\n");
		
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



