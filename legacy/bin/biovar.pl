#!/usr/bin/perl -I.. -w
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
my $proxyform={};
open(WE,$ARGV[3])||die("Cannot open proxyform.");
@tab=<WE>;
close(WE);
foreach(@tab) {
	chomp;
	my @row=split(/\t/,$_);
	$proxyform->{$row[0]}=[$row[2],$row[3]];	
}
#open(WE,$ARGV[3])||die("Cannot open excluded file");
#@tab=<WE>;
#close(WE);
#my $excluded={};
#foreach(@tab) {
#	chomp;
#	$excluded->{$_}=1;
#}
my $excluded={9324=>1,9355=>1,9356=>1,9357=>1,9360=>1,9361=>1,12=>1,1=>1};
my $ppprod={2=>1,38=>1,51=>1,60=>1,113=>1,233=>1,351=>1,352=>1};
my $wacont={23=>1,33=>1,35=>1,39=>1,41=>1,50=>1,52=>1,53=>1,58=>1,64=>1,67=>1,
	                82=>1,105=>1,117=>1,126=>1,129=>1,151=>1,156=>1,317=>1,63=>1};
my $tobin=new Tobin::IF(1);
my $fbaset=$tobin->fbasetupGet($ARGV[0]);
my $tflist={};
foreach(@{$fbaset->{TFSET}}) {
	my $tf=$_->[0];
	$tflist->{defined($revhash->{$tf})?($tf<$revhash->{$tf}?$tf:$revhash->{$tf}):$tf}=1;
}
my $biotf=$tobin->transformationGet($ARGV[2]);
my $biomass=bmmas($biotf);
warn($biomass);
my $lpdata=getfbaset($fbaset,$revhash,$tobin);
for (0..(@{$biotf->[2]}-1)) {
	$biotf->[2]->[$_]->{id}==35||next;
	defined($excluded->{$biotf->[2]->[$_]->{id}})&&next;
	my $bm=clone($biotf);
	$bm->[2]->[$_]->{sto}*=0.8;
	my $m=bmmas($bm);
	my $lpcopy=clone($lpdata);
	my $ppsto=0;
	my $wasto=0;
	foreach my $cpd (@{$bm->[2]}) {
		defined($excluded->{$cpd->{id}})&&next;
		$lpcopy->{cpdhash}->{$cpd->{ext}}->{$cpd->{id}}->{$ARGV[2]}=$biomass/$m*$cpd->{sto};
		defined($ppprod->{$cpd->{id}})&&($ppsto+=$cpd->{sto}/
		(defined($proxyform->{$cpd->{id}})?$proxyform->{$cpd->{id}}->[0]:1));
		 defined($wacont->{$cpd->{id}})&&($wasto+=$cpd->{sto});
	}
	$lpcopy->{cpdhash}->{0}->{12}->{$ARGV[2]}=-$biomass/$m*$ppsto;
	$lpcopy->{cpdhash}->{0}->{1}->{$ARGV[2]}=-$biomass/$m*$wasto;
	my $file=writelp($lpcopy);
	my $str.=$biotf->[2]->[$_]->{id}."\t\tMin: ";
	for(my $i=-1;$i<8;$i++) {
		my @result=$i<0?`echo "$file"|~/Software/lp_solve/lp_solve -S1 -timeout 30`:
		`echo "$file"|~/Software/lp_solve/lp_solve -S1 -s$i`;
		if(@result>1&&$result[1]=~/Value of objective function: (.*)$/) {
			$str.=$1;
			my $opt=$1;
			@result=`echo "$file"|~/Software/lp_solve/lp_solve -S4 -s$i`;
			open(WY, ">".$ARGV[0]."biovar.".$biotf->[2]->[$_]->{id}.".d.out");
			print(WY (@result));
			close(WY);
			my $lpcopy1=clone($lpcopy);
			defined($lpcopy1->{tfhash}->{abs($lpcopy1->{objective})})||
			($lpcopy1->{tfhash}->{abs($lpcopy1->{objective})}={});
			$lpcopy1->{tfhash}->{abs($lpcopy1->{objective})}
			->{$lpcopy1->{objective}>0?"min":"max"}=0.99999*$opt;
			defined($lpcopy1->{free}->{abs($lpcopy1->{objective})})&&
			delete($lpcopy1->{free}->{abs($lpcopy1->{objective})});
			my $fva=runfva($lpcopy1,$tflist);
			open(WY,">".$ARGV[0]."biovar.fva.".$biotf->[2]->[$_]->{id}.".d.out" );
			print(WY $fva);
			close(WY);
			$lpcopy1=clone($lpcopy);
			defined($lpcopy1->{tfhash}->{abs($lpcopy1->{objective})})||
			($lpcopy1->{tfhash}->{abs($lpcopy1->{objective})}={});
			$lpcopy1->{tfhash}->{abs($lpcopy1->{objective})}
			->{$lpcopy1->{objective}>0?"min":"max"}=0.9*$opt;
			$fva=runfva($lpcopy1,$tflist);
			open(WY,">".$ARGV[0]."biovar.fva.no.".$biotf->[2]->[$_]->{id}.".d.out" );
			print(WY $fva);
			close(WY);
			last;
		}
	}
	$bm=clone($biotf);
	$bm->[2]->[$_]->{sto}*=1.2;
	$m=bmmas($bm);
	$lpcopy=clone($lpdata);
	$ppsto=0;
	$wasto=0;
	foreach my $cpd (@{$bm->[2]}) {
		defined($excluded->{$cpd->{id}})&&next;
		$lpcopy->{cpdhash}->{$cpd->{ext}}->{$cpd->{id}}->{$ARGV[2]}=$biomass/$m*$cpd->{sto};
		defined($ppprod->{$cpd->{id}})&&($ppsto+=$cpd->{sto}/
		(defined($proxyform->{$cpd->{id}})?$proxyform->{$cpd->{id}}->[0]:1));
		defined($wacont->{$cpd->{id}})&&($wasto+=$cpd->{sto});
	}
	$lpcopy->{cpdhash}->{0}->{12}->{$ARGV[2]}=-$biomass/$m*$ppsto;
	$lpcopy->{cpdhash}->{0}->{1}->{$ARGV[2]}=-$biomass/$m*$wasto;
	$file=writelp($lpcopy);
	open(WY,">biovar.lp");
	print(WY $file);
	close(WY);
	$str.="\tMax: ";
	for(my $i=-1;$i<8;$i++) {
		my @result=$i<0?`echo "$file"|~/Software/lp_solve/lp_solve -S1 -timeout 30`:
		`echo "$file"|~/Software/lp_solve/lp_solve -S1 -s$i`;
		if(@result>1&&$result[1]=~/Value of objective function: (.*)$/) {
			$str.=$1;
			my $opt=$1;
			@result=`echo "$file"|~/Software/lp_solve/lp_solve -S4 -s$i`;
			open(WY, ">".$ARGV[0]."biovar.".$biotf->[2]->[$_]->{id}.".u.out");
			print(WY (@result));
			close(WY);
			my $lpcopy1=clone($lpcopy);
			defined($lpcopy1->{tfhash}->{abs($lpcopy1->{objective})})||
			($lpcopy1->{tfhash}->{abs($lpcopy1->{objective})}={});
			$lpcopy1->{tfhash}->{abs($lpcopy1->{objective})}
			->{$lpcopy1->{objective}>0?"min":"max"}=0.99999*$opt;
			defined($lpcopy1->{free}->{abs($lpcopy1->{objective})})&&
			delete($lpcopy1->{free}->{abs($lpcopy1->{objective})});
			my $fva=runfva($lpcopy1,$tflist);
			open(WY,">".$ARGV[0]."biovar.fva.".$biotf->[2]->[$_]->{id}.".u.out" );
			print(WY $fva);
			close(WY);
			$lpcopy1=clone($lpcopy);
			defined($lpcopy1->{tfhash}->{abs($lpcopy1->{objective})})||
			($lpcopy1->{tfhash}->{abs($lpcopy1->{objective})}={});
			$lpcopy1->{tfhash}->{abs($lpcopy1->{objective})}
			->{$lpcopy1->{objective}>0?"min":"max"}=0.9*$opt;
			$fva=runfva($lpcopy1,$tflist);
			open(WY,">".$ARGV[0]."biovar.fva.no.".$biotf->[2]->[$_]->{id}.".u.out" );
			print(WY $fva);
			close(WY);
			last;
		}
#		elsif($result[0]=~/(unbounded|infeasible)/) {
#			$str.=$1;
#			open(WY,">biovar.lp");
#			print(WY $file);
#			close(WY);
#			print($str."\n");
#			exit;
#			last;
#		}
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

sub bmmas {
	my $reaction=shift;
	my $excluded={9324=>1,9355=>1,9356=>1,9357=>1,9360=>1,9361=>1};
	my $proxyform={};
	open(WE,$ARGV[3])||die("Cannot open proxyform.");
	my @pf=<WE>;
	close(WE);
	foreach(@pf) {
		chomp;
		my @row=split(/\t/,$_);
		$proxyform->{$row[0]}=[$row[2],$row[3]];	
	}
	my $mass=0;
	my $wcont={23=>1,33=>1,35=>1,39=>1,41=>1,50=>1,52=>1,53=>1,58=>1,64=>1,67=>1,
		82=>1,105=>1,117=>1,126=>1,129=>1,151=>1,156=>1,317=>1,9347=>1};
	my $wmass=0;
	my $elements={C=>12,H=>1, O=>16,P=>31, S=>32, N=>14};
	my $elmass={C=>0,H=>0, O=>0,P=>0, S=>0, N=>0};
	foreach(@{$reaction->[2]}) {
		defined($excluded->{$_->{id}})&&next;
		defined($wcont->{$_->{id}})&&($wmass+=$_->{sto}/(defined($proxyform->{$_->{id}})?$proxyform->{$_->{id}}->[0]:1));
		my $formula= $tobin->compoundFormulaGet(defined($proxyform->{$_->{id}})?
		$proxyform->{$_->{id}}->[1]:$_->{id});
		($formula=~m/^([A-Z][a-z]{0,1}[0-9]*)+$/)||die($_->{id}." - Bad formula");
		my @atoms= $formula=~m/([A-Z][a-z]{0,1}[0-9]*)/g;
		foreach my $atom (@atoms) {
			$atom=~m/([A-Z][a-z]{0,1})([0-9]*)/;
			defined($elements->{$1})?
			(my $m=($2 ne ""?$2:1)*$elements->{$1}*(-$_->{sto})*
			(defined($proxyform->{$_->{id}})?1/$proxyform->{$_->{id}}->[0]:1)):
			die("No mass found for $1");
			$mass+=$m;
			$elmass->{$1}+=$m;
		}
	}
#	$mass+=18*$wmass;
	return $mass;
}

sub runfva {
	my $lpdata=shift;
	my $fvalist=shift;
	my $str="";
	foreach(keys(%{$fvalist})) {
		$lpdata->{objective}=-$_;
		my $file=writelp($lpdata);
#		open(WY, ">fvatest.txt");
#		print(WY $file);
#		close(WY);
#		exit;
		$str.=sprintf("%04d",$_);
		defined($revhash->{$_})&&($str.="/".$revhash->{$_});
		$str.="\tMin: ";
		for(my $i=-1;$i<8;$i++) {
			my @result=$i<0?`echo "$file"|~/Software/lp_solve/lp_solve -S1`:
			`echo "$file"|~/Software/lp_solve/lp_solve -S1 -s$i`;
			if(@result>1&&$result[1]=~/Value of objective function: (.*)$/) {
				$str.=$1;
				last;
			}
			if($i==7) {
				open(WY,">biovar.lp");
				print(WY $file);
				close(WY);
				die("Cannot compute min fva for $_");
			}
		}
		$str.="\tMax: ";
		$lpdata->{objective}=$_;
		$file=writelp($lpdata);
		for(my $i=-1;$i<8;$i++) {
			
			my @result=$i<0?`echo "$file"|~/Software/lp_solve/lp_solve -S1`:
			`echo "$file"|~/Software/lp_solve/lp_solve -S1 -s$i`;
			if(@result>1&&$result[1]=~/Value of objective function: (.*)$/) {
				$str.=$1;
				last;
			}
#			elsif($result[0]=~/(unbounded|infeasible)/) {
#				$str.=$1;
#				last;
#			}
			$i==7&&die("Cannot compute max fva for $_");			
		}
		$str.="\n";
	}
	return $str;
}
