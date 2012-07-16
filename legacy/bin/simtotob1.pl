#!/usr/bin/perl -I.
use strict;
use warnings;
use Tobin::IF;

my $tobin		= new Tobin::IF(1);
if(!@ARGV) {
	die("No input file\n");
}
open(WE,$ARGV[0])||die("Cannot open the file: ".$ARGV[0]."!\n");
my @rlist=<WE>;
close(WE);
open(WE, $ARGV[1])||die("Cannot open mcodes.");
my @mets=<WE>;
close(WE);
my $mcodes={};
foreach(@mets) {
	chomp($_);
	my @mets1=split(/\t/,$_);
	$mcodes->{$mets1[0]}=$mets1[1];
}
my $numbers={};
if(open(WE,$ARGV[2])) {
	my @simcodes=<WE>;
	close(WE);
	foreach(@simcodes) {
		chomp($_);
		my @cols=split(/\t/,$_);
		$numbers->{$cols[0]}=(@cols==2?[$cols[1]]:[$cols[1],$cols[2]]);
	}
}
my $problematic={};
foreach(@rlist) {
	chomp($_);
	my @cols=split(/\t/,$_);
	my $reacts=$tobin->transformationCandidatesGet($cols[0],'t_lnk',1);
	if(defined($numbers->{$cols[0]})&&@{$numbers->{$cols[0]}}>$cols[1]) {
		next;
	}
	if(@{$reacts}==1&&$cols[1]==0) {
		my $check=checkdir($tobin->transformationGet($reacts->[0]),$cols[2],$mcodes);
		if($check==1) {
			checkcomps($tobin->transformationGet($reacts->[0]),$cols[2],$mcodes,0);
			if(checkcomps($tobin->transformationGet($reacts->[0]),$cols[2],$mcodes,0)) {
				$problematic->{$cols[0]}=4;
			}
			elsif(checkstoch($tobin->transformationGet($reacts->[0]),$cols[2],$mcodes,0)) {
				$problematic->{$cols[0]}=5;
			}
			else {
				$numbers->{$cols[0]}=[$reacts->[0]];
			}
		}
		elsif($check==-1) {
			$problematic->{$cols[0]}=2;
		}
		else {
			$problematic->{$cols[0]}=0;
		}
	}
	elsif(@{$reacts}==1&&$cols[1]==1) {
		warn($cols[0]."\t".$reacts->[0]);
		my $check=checkdir($tobin->transformationGet($reacts->[0]),$cols[2],$mcodes);
		if($check==1){
			$problematic->{$cols[0]}=1;
		}
		elsif($check==-1) {
			$problematic->{$cols[0]}=2;
		}
		else {
			$problematic->{$cols[0]}=0;
		}
	}
	elsif(@{$reacts}>1) {
		my $forward=-1;
		my $reverse=-1;
		my $mfor=[];
		my $mrev=[];
		foreach(@{$reacts}) {
			my $check=checkdir($tobin->transformationGet($_),$cols[2],$mcodes);
			if($check==1) {
				if($forward>-1) {
					push(@{$mfor},$forward,$_);
					$forward=-2;
				}
				elsif($forward==-1) {
					$forward=$_;
				}
				else {
					push(@{$mfor},$_);
				}
			}
			elsif($check==-1) {
				if($reverse>-1) {
					push(@{$mrev},$reverse,$_);
					$reverse=-2;
				}
				elsif($reverse==-1) {
					$reverse=$_;
				}
				else {
					push(@{$mrev},$_);
				}
			} 
		}
		if($cols[1]==0) {
			if($forward>-1) {
				if(checkcomps($tobin->transformationGet($forward),$cols[2],$mcodes,0)||
				(($reverse>-1)?
				checkcomps($tobin->transformationGet($reverse),$cols[2],$mcodes,1):0)) {
					$problematic->{$cols[0]}=4;
				}
				elsif(checkstoch($tobin->transformationGet($forward),$cols[2],$mcodes,0)||
				(($reverse>-1)?
				checkstoch($tobin->transformationGet($reverse),$cols[2],$mcodes,1):0)) {
					$problematic->{$cols[0]}=5;
				}
				else {
					$numbers->{$cols[0]}=(($reverse>-1)?([$forward,$reverse]):([$forward]));
				}
			}
			elsif($reverse>-1) {
				$problematic->{$cols[0]}=2;
			}
			else {
				$problematic->{$cols[0]}=0;
			}
		}
		else {
			if($forward>-1&&$reverse>-1) {
				if(checkcomps($tobin->transformationGet($forward),$cols[2],$mcodes,0)||
				checkcomps($tobin->transformationGet($reverse),$cols[2],$mcodes,1)) {
					$problematic->{$cols[0]}=4;
				}
				elsif(checkstoch($tobin->transformationGet($forward),$cols[2],$mcodes,0)||
				checkstoch($tobin->transformationGet($reverse),$cols[2],$mcodes,1)) {
					$problematic->{$cols[0]}=5;
				}
				else {
					$numbers->{$cols[0]}=[$forward,$reverse];
				}
			}
			elsif($forward==-2) {
				if(@{$mfor}==2){
					my $check1=checktrans($tobin->transformationGet($mfor->[0]),
					$tobin->transformationGet($mfor->[1]),$cols[2],$mcodes);
					if($check1) {
						if($check1>0?(checkstoch($tobin->transformationGet($mfor->[0]),
						$cols[2],$mcodes,0)||
						checkstoch($tobin->transformationGet($mfor->[1]),$cols[2],$mcodes,1)):
						(checkstoch($tobin->transformationGet($mfor->[0]),
						$cols[2],$mcodes,1)||
						checkstoch($tobin->transformationGet($mfor->[1]),$cols[2],$mcodes,0))) {
							$problematic->{$cols[0]}=5;
						}
						else {
							$numbers->{$cols[0]}=($check1>0?[$mfor->[0],$mfor->[1]]:
						[$mfor->[1],$mfor->[0]]);
						}
					}
					else {
						$problematic->{$cols[0]}=3;
					}
				}
				else {
					$problematic->{$cols[0]}=3;
				}
			}
			elsif($reverse==-2) {
				$problematic->{$cols[0]}=6;
			}
			elsif($forward>-1) {
				$problematic->{$cols[0]}=1;
			}
			elsif($reverse>-1){
				$problematic->{$cols[0]}=2;
			}
			else {
				$problematic->{$cols[0]}=0;
			}
		}
		
	}
	elsif(@{$reacts}==0) {
		my $reactions=findByComps($cols[2],$mcodes,$tobin);
		print($cols[0]." - suggested reactions, for:");
		foreach(@{$reactions->[0]}) {
			print(" $_");
		}
		print(" rev:");
		foreach(@{$reactions->[1]}) {
			print(" $_");
		}
		print("\n");
		print("Add reaction? ");
		my $ans=<STDIN>;
		if($ans=~/^y$/) {
			print("Add numbers or create new one? ");
			$ans=<STDIN>;
			if($ans=~/^n$/) {
				print("Code for forward: ");
				my $for=<STDIN>;
				chomp($for);
				my $rev;
				if($cols[1]) {
					print("Code for reverse: ");
					$rev=<STDIN>;
				}
				$numbers->{$cols[0]}=($cols[1]?[$for,$rev]:[$for]);
				
			}
			elsif($ans=~/^c$/) {
				my $tfs=createTfs(\@cols,$mcodes,$tobin);
				(ref($tfs) eq "ARRAY")?
				($numbers->{$cols[0]}=$tfs):
				($problematic->{$cols[0]}=7);
			}
			else {
				print("Bad answer!");
				$problematic->{$cols[0]}=7;
			}
		}
		else {
			$problematic->{$cols[0]}=7;
		}
	}
	else {
		print("Strange - ".$cols[0]."\n");
	}
}
my $problems={0 => "no reaction present",1=>"only forward reaction",2=>"only reverse reaction",
	3=>"multiple forward reactions",4=>"compartments not in agreement",
	5=>"stoichiometry not in agreement",6=>"multiple reverse reactions",7=>"no code present"};
open(WY,">".$ARGV[2]);
foreach(keys(%{$numbers})) {
	print(WY $_."\t".$numbers->{$_}->[0].(@{$numbers->{$_}}==2?
	("\t".$numbers->{$_}->[1]):"")."\n");
}
close(WY);
print("Problematic reactions:\n");
foreach(keys(%{$problematic})) {
		print($_." - ".$problems->{$problematic->{$_}}.".\n");
	}

sub checkdir {
	my $rdata=shift;
	my $equation=shift;
	my $mlist=shift;
	my $eqmod=$equation;
	$eqmod=~s/^\[[ce]\] : |\([0-9.]+\) |\[[ce]\]//g;
	my @subs=split(/ \+ /,(split(/ <==> | --> /,$eqmod))[0]);
	my @prods=split(/ \+ /,(split(/ <==> | --> /,$eqmod))[1]);
	my $subsr={};
	my $prodsr={};
	foreach(@{$rdata->[2]}) {
		if($_->{sto} < 0) {
			$subsr->{$_->{id}}=1;
		}
		else {
			$prodsr->{$_->{id}}=1;
		}
	}
	if(!((@prods==keys(%{$prodsr})&&@subs==keys(%{$subsr}))||
	(@prods==keys(%{$subsr})&&@subs==keys(%{$prodsr})))) {
		return(0);
	}
	my $corr=1;
	foreach(@subs) {
		if(!defined($subsr->{$mlist->{$_}})) {
			$corr=0;
		}
	}
	if($corr) {
		foreach(@prods) {
			if(!defined($prodsr->{$mlist->{$_}})) {
				$corr=0;
			}
		}
		if($corr) {
			return(1);
		}
		else {
			return(0);
		}
	}
	else {
		$corr=1;
		foreach(@subs) {
			if(!defined($prodsr->{$mlist->{$_}})) {
				$corr=0;
			}
		}
		if($corr) {
			foreach(@prods) {
				if(!defined($subsr->{$mlist->{$_}})) {
					$corr=0;
				}
			}
			if($corr) {
				return(-1);
			}
			else {
				return(0);
			}
		}
		else {
			return(0);
		}
	}
	
}

sub checkcomps {
	my $rdata=shift;
	my $equation=shift;
	my $mlist=shift;
	my $rev=shift;
	if($equation=~/^\[c\]/){
		my $check=1;
		foreach(@{$rdata->[2]}) {
			if($_->{ext}) {
				$check=0;
			}
		}
		if($check) {
			return(0);
		}
		else {
			return(1);
		}		
	}
	elsif($equation=~/^\[e\]/){
		my $check=1;
		foreach(@{$rdata->[2]}) {
			if(!$_->{ext}) {
				$check=0;
			}
		}
		if($check) {
			return(0);
		}
		else {
			return(1);
		}
	}
	else{
		my $eqmod=$equation;
		$eqmod=~s/\([0-9.]+\) //g;
		my @subs=split(/ \+ /,(split(/ <==> | --> /,$eqmod))[0]);
		my @prods=split(/ \+ /,(split(/ <==> | --> /,$eqmod))[1]);
		my $subsr={};
		my $prodsr={};
		foreach(@{$rdata->[2]}) {
			if($_->{sto} < 0) {
				if($rev) {
					$prodsr->{$_->{id}}=$_->{ext}; 
				}
				else {
					$subsr->{$_->{id}}=$_->{ext};
				}
			}
			else {
				if($rev) {
					$subsr->{$_->{id}}=$_->{ext};
				}
				else {
					$prodsr->{$_->{id}}=$_->{ext};
				}
			}
		}
		my $check=1;
		foreach(@subs) {
			$_=~m/(.*)(\[[ce]\])/;
			if($subsr->{$mlist->{$1}}!=(($_=~/\[e\]$/)?1:0)) {
				$check=0;
			}
		}
		foreach(@prods) {
			$_=~m/(.*)(\[[ce]\])/;
			if($prodsr->{$mlist->{$1}}!=(($_=~/\[e\]$/)?1:0)) {
				$check=0;
			}
		}
		if($check) {
			return(0);
		}
		return(1);
	}
}
sub checktrans {
	my $rdata=shift;
	my $rdata1=shift;
	my $equation=shift;
	my $mlist=shift;
	my $eqmod=$equation;
	$eqmod=~s/\([0-9.]+\) //g;
	my @subs=split(/ \+ /,(split(/ <==> | --> /,$eqmod))[0]);
	my @prods=split(/ \+ /,(split(/ <==> | --> /,$eqmod))[1]);
	if(@subs!=@prods) {
		return(0);
	}
	my $subsr={};
	my $prodsr={};
	foreach(@{$rdata->[2]}) {
		if($_->{sto} < 0) {
			$subsr->{$_->{id}}=$_->{ext};
		}
		else {
			$prodsr->{$_->{id}}=$_->{ext};
		}
	}
	my $subsr1={};
	my $prodsr1={};
	foreach(@{$rdata1->[2]}) {
		if($_->{sto} < 0) {
			$subsr1->{$_->{id}}=$_->{ext};
		}
		else {
			$prodsr1->{$_->{id}}=$_->{ext};
		}
	}
	if(keys(%{$subsr})!=keys(%{$prodsr1})||keys(%{$prodsr})!=keys(%{$subsr1})) {
		return(0);
	}
	my $check=1;
	foreach(keys(%{$subsr})) {
		if(!defined($prodsr1->{$_})||$subsr->{$_}!=$prodsr1->{$_}) {
			$check=0;
		}
	}
	if(!$check) {
		return(0);
	}
	foreach(keys(%{$prodsr})) {
		if(!defined($subsr1->{$_})||$prodsr->{$_}!=$subsr1->{$_}) {
			$check=0;
		}
	}
	if(!$check) {
		return(0);
	}
	$subs[0]=~/(.*)(\[)([ec])(\])/;
	if($subsr->{$mlist->{$1}}==(($3 eq 'c')?0:1)) {
		return(1);
	}
	else {
		return(-1);
	}
}

sub checkstoch {
	my $rdata=shift;
	my $equation=shift;
	my $mlist=shift;
	my $rev=shift;
	my $eqmod=$equation;
	$eqmod=~s/^\[[ce]\] : |\[[ce]\]//g;
	my @subs=split(/ \+ /,(split(/ <==> | --> /,$eqmod))[0]);
	my @prods=split(/ \+ /,(split(/ <==> | --> /,$eqmod))[1]);
	my $subsr={};
	my $prodsr={};
	foreach(@{$rdata->[2]}) {
		if($_->{sto} < 0) {
			if($rev) {
				$prodsr->{$_->{id}}=-$_->{sto}; 
			}
			else {
				$subsr->{$_->{id}}=-$_->{sto};
			}
		}
		else {
			if($rev) {
				$subsr->{$_->{id}}=$_->{sto};
			}
			else {
				$prodsr->{$_->{id}}=$_->{sto};
			}
		}
	}
	my $check=1;
	my $scoef={};
	foreach(@subs) {
		if($_=~/^\(([0-9.]+)\) (.*)$/) {
			$scoef->{$2}=$1;
		}
		else {
			$scoef->{$_}=1;
		}
	}
	my $pcoef={};
	foreach(@prods) {
		if($_=~/^\(([0-9.]+)\) (.*)$/) {
			$pcoef->{$2}=$1;
		}
		else {
			$pcoef->{$_}=1;
		}
	}
	my $div=1;
	if(grep(/[0-9]\.[0-9]+/,values(%{$scoef}))||grep(/[0-9]\.[0-9]+/,values(%{$pcoef}))) {
		$div=0;
		do {
			foreach(keys(%{$scoef})) {
				$scoef->{$_}*=10;
			}
			foreach(keys(%{$pcoef})) {
				$pcoef->{$_}*=10;
			}
		}
		while(grep(/[0-9]\.[0-9]+/,values(%{$scoef}))||grep(/[0-9]\.[0-9]+/,values(%{$pcoef})));
		foreach(values(%{$scoef})) {
			$div=gcd1($div,$_);
		}
		foreach(values(%{$pcoef})) {
			$div=gcd1($div,$_);
		}
		print $div."\n";
		foreach(keys(%{$scoef})) {
			$scoef->{$_}=$scoef->{$_}/$div;
		}
		foreach(keys(%{$pcoef})) {
			$pcoef->{$_}=$pcoef->{$_}/$div;
		}
	}
	use integer;
	foreach(keys(%{$scoef})) {
		if($subsr->{$mlist->{$_}}!=$scoef->{$_}) {
			$check=0;
#			print("Coefs: ".$_."\t".$subsr->{$mlist->{$_}}."\t".$scoef->{$_}."\n");
		}
	}
	if(!$check) {
		return(1);
	}
	foreach(keys(%{$pcoef})) {
		if($prodsr->{$mlist->{$_}}!=$pcoef->{$_}) {
			$check=0;
			print("Coefs: ".$_."\t".$prodsr->{$mlist->{$_}}."\t".$pcoef->{$_}."\n");
		}
	}
	if(!$check) {
		return(1);
	}
	no integer;
	return(0);
}

sub gcd1 {
	my $u=shift;
	my $v=shift;
	my $k = 0;
    if ($u == 0) {
		return $v;
    }
	if ($v == 0) {
		return $u;
	}
	while (($u & 1) == 0  &&  ($v & 1) == 0) {
		$u >>= 1;
		$v >>= 1;
		$k++;
	}
	do {
		if (($u & 1) == 0) {
			$u >>= 1;
		}
		elsif (($v & 1) == 0) {
			$v >>= 1;
		}
		elsif ($u >= $v) {
             $u = ($u-$v) >> 1;
		}
		else {
			$v = ($v-$u) >> 1;
		}
	} while ($u > 0);
	no integer;
	return $v << $k;
}

sub findByComps {
	my $equation=shift;
	my $mlist=shift;
	my $tobin=shift;
	$equation=~s/^\[[ce]\] : |\([0-9.]+\) |\[[ce]\]//g;
	my @subs=split(/ \+ /,(split(/ <==> | --> /,$equation))[0]);
	my @prods=split(/ \+ /,(split(/ <==> | --> /,$equation))[1]);
	my $subsh={};
	my $prodsh={};
	foreach(@subs){
		if(!defined($mlist->{$_})) {
			print($_."- compound not found\n");
			return([[],[]]);
		}
		$mlist->{$_}==65||$mlist->{$_}==957||($subsh->{$mlist->{$_}}=1);
	}
	foreach(@prods) {
		if(!defined($mlist->{$_})) {
			print($_."- compound not found\n");
			return([[],[]]);
		}
		$mlist->{$_}==65||$mlist->{$_}==957||($prodsh->{$mlist->{$_}}=1);
	}
	return [$tobin->transformationFindByCompounds($subsh,$prodsh),
	$tobin->transformationFindByCompounds($prodsh,$subsh)];
}

sub createTfs {
	my $cols=shift;
	my $mcodes=shift;
	my $tobin=shift;
	my $equation=$cols->[2];
	my $stoich;
	my $ext;
	if($equation=~/^\[([ce])\] : /) {
		$ext=($1 eq 'e')?1:0; 
		$equation=~s/^\[[ce]\] : //;
	}
	my @subs=split(/ \+ /,(split(/ <==> | --> /,$equation))[0]);
	my @prods=split(/ \+ /,(split(/ <==> | --> /,$equation))[1]);
	foreach(@subs) {
		my $sto=-1;
		if($_=~/^\(([0-9.]+)\) /) {
			$sto=-$1;
			$_=~s/^\([0-9.]+\) //;
		}
		if($_=~/\[([ce])\]$/) {
			$ext=($1 eq 'e')?1:0;
			$_=~s/\[[ce]\]$//;
		}
		if(!defined($mcodes->{$_})) {
			print("No code found for $_\n");
			return(-1);
		}
		push(@{$stoich},{sto=>$sto,id=>$mcodes->{$_},ext=>$ext});
	}
	foreach(@prods) {
		my $sto=1;
		if($_=~/^\(([0-9.]+)\) /) {
			$sto=$1;
			$_=~s/^\([0-9.]+\) //;
		}
		if($_=~/\[([ce])\]$/) {
			$ext=($1 eq 'e')?1:0;
			$_=~s/\[[ce]\]$//;
		}
		if(!defined($mcodes->{$_})) {
			print("No code found for $_\n");
			return(-1);
		}
		push(@{$stoich},{sto=>$sto,id=>$mcodes->{$_},ext=>$ext});
	}
	my $lnk=$cols->[0];
	length($lnk)>10&&($lnk=substr($lnk,0,10));
	my $links=[{user=>$ARGV[3], link=>$lnk}];
	my $corr;
	my $mul=1;
	do {
		$corr=0;
		foreach(@{$stoich}) {
			if($_->{sto}=~/[0-9]\.[0-9]/) {
				$corr=1;
				last;
			}
		}
		if($corr) {
			foreach(@{$stoich}) {
				$_->{sto}*=10;
			}
			$mul*=10;
		}
	} while($corr);
	if($mul>1) {
		my $div=0;
		foreach(@{$stoich}) {
			$div=gcd1($div,abs($_->{sto}));
		}
		foreach(@{$stoich}) {
			$_->{sto}/=$div
		}
		
	}
	my $errors=[];
	my $res=$tobin->transformationAdd($cols->[2],$links,$stoich,[$cols->[3]],$errors);
	if(@{$errors}) {
		foreach(@{$errors}) {
			warn $_;
		}
		die();
	}
	my $codes=[$res];
	if($cols->[1]) {
		foreach(@{$stoich}) {
			$_->{sto}=-$_->{sto};
		}
		my $eqtmp=$cols->[2];
		my $equation="";
		if($eqtmp=~/(^\[[ce]\] : )/) {
			$equation=$1;
			$eqtmp=~s/^\[[ce]\] : //;
		}
		$equation=$equation.(split(/ <==> /,$eqtmp))[1]." <==> ".
		(split(/ <==> /,$eqtmp))[0];	
		$errors=[];
		$res=$tobin->transformationAdd($equation,$links,$stoich,[$cols->[3]." (R)"],$errors);
		if(@{$errors}) {
			foreach(@{$errors}) {
				warn $_;
			}
			die();
		}
		push(@{$codes},$res);
	
	}
	return $codes;
}
