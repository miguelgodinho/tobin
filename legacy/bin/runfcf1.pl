#!/usr/bin/perl -I. -w
use strict;
use warnings;
use Tobin::IF;
use Clone qw(clone);

@ARGV<3&&die("Too few arguments");
my $debug=@ARGV>3?$ARGV[3]:0;
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
my $tobin=new Tobin::IF(1);
my $fbaset=$tobin->fbasetupGet($ARGV[0]);
my $tflist={};
foreach(@{$fbaset->{TFSET}}) {
	my $tf=$_->[0];
	(defined($excluded->{$tf})||
	(defined($revhash->{$tf})&&defined($excluded->{$revhash->{$tf}})))&&next;
	$tflist->{defined($revhash->{$tf})?($tf<$revhash->{$tf}?$tf:$revhash->{$tf}):$tf}=1;
}
my $blocked={};
my $lpdata=getfbaset($fbaset,$revhash,$tobin);
foreach(keys(%{$tflist})) {
	my $res=0;
	my $str=$_."\t";
	$lpdata->{objective}=-$_;
	my $file=writelp($lpdata);
	
	for(my $i=1;$i<8;$i++) {
		my @result=`echo "$file"|~/Software/lp_solve/lp_solve -timeout 30 -S1 -s$i`;
		if(@result>1&&$result[1]=~/Value of objective function: (.*)$/) {
			$res|=$1;
			$str.=$1;
			last;
		}
		elsif($result[0]=~/unbounded/){
			$res=1;
			$str.="i";
			last;
		}
		elsif($result[0]=~/infeasible/) {
				$str.=0;
				last;
		}
		else {
			warn("$_ - min strange result");
			my $out="";
			foreach my $line (@result) {
				$out.=$line;
			}
			warn($out);
		}
	}
	$lpdata->{objective}=$_;
	$file=writelp($lpdata);
	$str.="\t";
	for(my $i=1;$i<8;$i++) {
		my @result=`echo "$file"|~/Software/lp_solve/lp_solve -timeout 30 -S1 -s$i`;
		if(@result>1&&$result[1]=~/Value of objective function: (.*)$/) {
			$res|=$1;
			$str.=$1;
			last;
		}
		elsif($result[0]=~/unbounded/){
			$res=1;
			$str.="i";
			last;
		}
		elsif($result[0]=~/infeasible/){$str.=0}
		else {
			warn("$_ - max strange result");
			my $out="";
			foreach my $line (@result) {
				$out.=$line;
			}	
			warn($out);
		}
	}
	$res||($blocked->{$_}=1);
	$debug&&print($str."\n");
}
my $ccount=1;
my $dcoupled={};
my $fcoupled={};
my $pcoupled={};
my $tftab=[];
my $coupled={};

foreach(keys(%{$tflist})) {
	defined($blocked->{$_})&&next;
	push(@{$tftab},$_);
}
warn("Setsize: ".@{$tftab});
for(my $i=0;$i<(@{$tftab}-1);$i++) {
	defined($coupled->{$tftab->[$i]})&&next;
	warn("round: ".$i);
	for(my $j=$i+1;$j<@{$tftab};$j++) {
		my $lpcopy=clone($lpdata);
		defined($lpcopy->{tfhash}->{$tftab->[$j]})||
		($lpcopy->{tfhash}->{$tftab->[$j]}={});
		$lpcopy->{tfhash}->{$tftab->[$j]}->{min}=0.99999999;
		$lpcopy->{tfhash}->{$tftab->[$j]}->{max}=1;
		defined($lpcopy->{free}->{$tftab->[$j]})&&delete($lpcopy->{free}->{$tftab->[$j]});
		$lpcopy->{objective}=-$tftab->[$i];
		my $file=writelp($lpcopy);
		if($tftab->[$i]==9682&&$tftab->[$j]==114) {
			open(WY, ">63lptest.txt");
			$debug&&print(WY $file);
			close(WY);
		}
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
				my $str=$tftab->[$i]."\t".$tftab->[$j].", min strange result:\n";
				foreach my $line (@result) {
					$str.=$line;
				}
				warn($str);
				if(defined($revhash->{$tftab->[$j]})){
					$min='c';
				}
			}
		}
		$lpcopy->{objective}=$tftab->[$i];
		$file=writelp($lpcopy);
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
				my $str=$tftab->[$i]."\t".$tftab->[$j].", max strange result:\n";
				foreach my $line (@result) {
					$str.=$line;
				}
				warn($str);
				if($min eq 'c') {
					$max=$min=0;
				}
			}
		}
		$debug&&print($tftab->[$i]."\t".$tftab->[$j]."\t".$min."\t".$max."\n");
		if(!defined($min)||!defined($max)||$min eq 'c') {
			warn($tftab->[$i]."\t".$tftab->[$j]." - excluded");
			next;
		}
		elsif($min ne 'i'&&$min==0&&$max ne 'i'&&$max>0||
		$max ne 'i'&&$max==0&&$min ne 'i'&&$min<0||
		$max ne 'i'&&$max>0&&$min ne 'i'&&$min<0) {
			defined($dcoupled->{$tftab->[$i]})||($dcoupled->{$tftab->[$i]}={});
			$dcoupled->{$tftab->[$i]}->{$tftab->[$j]}=1;
		}
		elsif ($min ne 'i'&&$min>0&&$max ne 'i'&&$max>0||
		$min ne 'i'&&$min<0&&$max ne 'i'&&$max<0) {
			if($max-$min>0) {
				if(defined($coupled->{$tftab->[$i]})) {
#					$coupled->{$tftab->[$j]}=$coupled->{$tftab->[$i]};
					defined($pcoupled->{$coupled->{$tftab->[$i]}})||
					($pcoupled->{$coupled->{$tftab->[$i]}}={});
					$pcoupled->{$coupled->{$tftab->[$i]}}->{$tftab->[$j]}=1;
				}
				else {
					$coupled->{$tftab->[$i]}=$ccount;
#					$coupled->{$tftab->[$j]}=$ccount;
					$pcoupled->{$ccount}={};
					$pcoupled->{$ccount}->{$tftab->[$i]}=1;
					$pcoupled->{$ccount}->{$tftab->[$j]}=1;
					$debug&&print("Added new chain: ".$ccount."\n");
					$ccount++;
				}
				$debug&&print("Pcoupled: ".$tftab->[$i]."\t".$tftab->[$j]."\n");
			}
			elsif($max-$min==0) {
				if(defined($coupled->{$tftab->[$i]})) {
					$coupled->{$tftab->[$j]}=$coupled->{$tftab->[$i]};
					defined($fcoupled->{$coupled->{$tftab->[$i]}})||
					($fcoupled->{$coupled->{$tftab->[$i]}}={});
					$fcoupled->{$coupled->{$tftab->[$i]}}->{$tftab->[$j]}=1;
				}
				else {
					$coupled->{$tftab->[$i]}=$ccount;
					$coupled->{$tftab->[$j]}=$ccount;
					$fcoupled->{$ccount}={};
					$fcoupled->{$ccount}->{$tftab->[$i]}=1;
					$fcoupled->{$ccount}->{$tftab->[$j]}=1;
					$debug&&print("Added new chain: ".$ccount."\n");
					$ccount++;
				}
				$debug&&print("Fcoupled: ".$tftab->[$i]."\t".$tftab->[$j]."\n");
			}
		}
		elsif($min ne 'i'&&$min>0&&$max eq 'i') {
			defined($dcoupled->{$tftab->[$j]})||($dcoupled->{$tftab->[$j]}={});
			$dcoupled->{$tftab->[$j]}->{$tftab->[$i]}=1;
		}
		elsif(defined($revhash->{$tftab->[$j]})&&$min eq 0&&$max eq 0) {
			foreach my $ext (keys(%{$lpcopy->{cpdhash}})) {
				foreach(keys(%{$lpcopy->{cpdhash}->{$ext}})) {
					defined($lpcopy->{cpdhash}->{$ext}->{$_}->{$tftab->[$j]})&&
					($lpcopy->{cpdhash}->{$ext}->{$_}->{$tftab->[$j]}=-$lpcopy->{cpdhash}->{$ext}->{$_}->{$tftab->[$j]});
				}
			}
			$lpcopy->{objective}=-$tftab->[$i];
			my $file=writelp($lpcopy);
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
					my $str=$tftab->[$i]."\t".$tftab->[$j].", min strange result:\n";
					foreach my $line (@result) {
						$str.=$line;
					}
					warn($str);
				}
			}
			$lpcopy->{objective}=$tftab->[$i];
			$file=writelp($lpcopy);
			my $max;
			for(my $k=1;$k<8;$k++) {
				my @result=`echo "$file"|~/Software/lp_solve/lp_solve -timeout 30 -S1 -s0`;
				if(@result>1&&$result[1]=~/Value of objective function: (.*)$/) {
					$max=$1;
				}
				elsif($result[0]=~/unbounded/){
					$max='i';
				}
				elsif($result[0]=~/infeasible/)
				{
					$max=0;
				}
				else {
					my $str=$tftab->[$i]."\t".$tftab->[$j].", max strange result:\n";
					foreach my $line (@result) {
						$str.=$line;
					}
					warn($str);
				}
			}
			if(!defined($min)||!defined($max)) {
				warn($tftab->[$i]."\t".$tftab->[$j]." - excluded");
				next;
			}
			$debug&&print($tftab->[$i]."\t".$tftab->[$j]."\t".$min."\t".$max."\n");
			if($min ne 'i'&&$min==0&&$max ne 'i'&&$max>0||
			$max ne 'i'&&$max==0&&$min ne 'i'&&$min<0||
			$max ne 'i'&&$max>0&&$min ne 'i'&&$min<0) {
				defined($dcoupled->{$tftab->[$i]})||($dcoupled->{$tftab->[$i]}={});
				$dcoupled->{$tftab->[$i]}->{$tftab->[$j]}=1;
			}
			elsif ($min ne 'i'&&$min>0&&$max ne 'i'&&$max>0||
			$min ne 'i'&&$min<0&&$max ne 'i'&&$max<0) {
				if($max-$min>0) {
					if(defined($coupled->{$tftab->[$i]})) {
#						$coupled->{$tftab->[$j]}=$coupled->{$tftab->[$i]};
						defined($pcoupled->{$coupled->{$tftab->[$i]}})||
						($pcoupled->{$coupled->{$tftab->[$i]}}={});
						$pcoupled->{$coupled->{$tftab->[$i]}}->{$tftab->[$j]}=1;
					}
					else {
						$coupled->{$tftab->[$i]}=$ccount;
#						$coupled->{$tftab->[$j]}=$ccount;
						$pcoupled->{$ccount}={};
						$pcoupled->{$ccount}->{$tftab->[$i]}=1;
						$pcoupled->{$ccount}->{$tftab->[$j]}=1;
						$debug&&print("Added new chain: ".$ccount."\n");
						$ccount++;
					}
					$debug&&print("Pcoupled: ".$tftab->[$i]."\t".$tftab->[$j]."\n");
				}
				elsif($max-$min==0) {
					if(defined($coupled->{$tftab->[$i]})) {
						$coupled->{$tftab->[$j]}=$coupled->{$tftab->[$i]};
						defined($fcoupled->{$coupled->{$tftab->[$i]}})||
						($fcoupled->{$coupled->{$tftab->[$i]}}={});
						$fcoupled->{$coupled->{$tftab->[$i]}}->{$tftab->[$j]}=1;
					}
					else {
						$coupled->{$tftab->[$i]}=$ccount;
						$coupled->{$tftab->[$j]}=$ccount;
						$fcoupled->{$ccount}={};
						$fcoupled->{$ccount}->{$tftab->[$i]}=1;
						$fcoupled->{$ccount}->{$tftab->[$j]}=1;
						$debug&&print("Added new chain: ".$ccount."\n");
						$ccount++;
					}
					$debug&&print("Fcoupled: ".$tftab->[$i]."\t".$tftab->[$j]."\n");
				}
			}
			elsif($min ne 'i'&&$min>0&&$max eq 'i') {
				defined($dcoupled->{$tftab->[$j]})||($dcoupled->{$tftab->[$j]}={});
				$dcoupled->{$tftab->[$j]}->{$tftab->[$i]}=1;
			}
		}
	}
}
my $nodehash={};
print("Directionally coupled:\n");
foreach(keys(%{$dcoupled})) {
	print($_."\t");
	my $str="";
	foreach my $tf (keys(%{$dcoupled->{$_}})) {
		$str.=$tf.", ";
	}
	$str=~s/, $//;
	print($str."\n");
	
}
print("Fully coupled:\n");
foreach (keys(%{$fcoupled})) {
	my $str=$_.": ";
	$nodehash->{$_}=1;
	foreach my $tf (keys(%{$fcoupled->{$_}})) {
		$str.=$tf.", ";
		$nodehash->{$tf}=$_;
	}
	$str=~s/, $//;
	print($str."\n");
	
}

print("Partially coupled:\n");
foreach (keys(%{$pcoupled})) {
	my $str=$_.": ";
	foreach my $tf (keys(%{$pcoupled->{$_}})) {
		$str.=$tf.", ";
		defined($nodehash->{$tf})&&($nodehash->{$tf}!=$_)&&
		warn("Tf $tf in two sets $nodehash->{$tf} and $_");
		$nodehash->{$tf}=$_;
	}
	$str=~s/, $//;
	print($str."\n");
	
}
my $dtree={};
my $newroots={};
foreach(keys(%{$dcoupled})) {
	defined($dtree->{$_})&&next;
	my $bad=0;
	foreach my $rtf (keys(%{$dcoupled})) {
		defined($dtree->{$rtf})&&next;
		foreach my $tf(keys(%{$dcoupled->{$rtf}})) {
			$tf==$_&&($bad=1)&&last;
		}
		$bad&&last;
	}
	if(!$bad) {
		$newroots->{$_}=1;
	}
}
do {
	my $nextroots={};
	foreach(keys(%{$newroots})) {
		my $node;
		if(defined($nodehash->{$_})) {
			defined($dtree->{"C".$nodehash->{$_}})&&next;
			$node="C".sprintf("%02d",$nodehash->{$_});
		}
		else {
			$node=sprintf("%04d",$_);
		}
		$dtree->{$node}={};
		foreach my $ctf (keys(%{$dcoupled->{$_}})) {
			my $bad=0;
			foreach my $rtf (keys(%{$dcoupled})) {
				defined($dtree->{$rtf})&&next;
				defined($newroots->{$rtf})&&next;
				foreach my $tf(keys(%{$dcoupled->{$rtf}})) {
					$tf==$ctf&&($bad=1)&&last;
				}
				$bad&&last;
			}
			if(!$bad) {
				my $node1;
				if(defined($nodehash->{$ctf})) {
					$node1="C".sprintf("%02d",$nodehash->{$ctf});
				}
				else {
					$node1=sprintf("%04d",$ctf);
				}
				$nextroots->{$ctf}=1;
				$dtree->{$node}->{$node1}=1;
			}
		}
	}
	$newroots=$nextroots;
} while(keys(%{$newroots}));

print("digraph \"if\" {\n\tgraph [\n\t\tfontsize = \"14\"\n".
"\t\tfontname = \"Times-Roman\"\n\t\tfontcolor = \"black\"\n\t]\n");
foreach(keys(%{$dtree})) {
	foreach my $node (keys(%{$dtree->{$_}})) {
		print($_." -> ".$node.";\n");
	}
}
print("}\n");

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
