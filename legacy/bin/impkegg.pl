#!/usr/bin/perl
use strict;
use warnings;
use Tobin::IF;

my $tobin		= new Tobin::IF(1004);
#my %rlist=$tobin->fbaresGet(620253);
#my $wlink=0;
#my $nlink=0;
#my $linkhash={};
#foreach(keys%rlist) {
#	my $rea=$tobin->transformationGet($_);
#	my $good=undef;;
#	foreach my $lnk (@{$rea->[1]}) {
#		if($lnk->{user}==901) {
#			$good=$lnk->{link};
#			last;
#		}
#	}
#	defined($good)&&($linkhash->{$_}=$good);
#}
#print($wlink."\t".$nlink."\n");

#exit;

@ARGV<2&&die("Too few parameters.");
my $ocode=$ARGV[1];
open(WE,$ARGV[0])||die("Cannot open input file");
my @organism=<WE>;
close(WE);
my $pathway;
my $reactions={};
my $found=0;
my @pathxml;
my $rconf={};
open(WE, "conf-corr.txt");
my @dcorr=<WE>;
close(WE);
my $dircorr={};
foreach(@dcorr) {
	chomp;
	$dircorr->{(split(/\t/,$_))[0]}=(split(/\t/,$_))[1];
}
foreach(@organism) {
	if($_=~/PATH:.*$ocode([0-9]{5})/) {
		$pathway=$1;
		if(open(WE,"map".$pathway.".xml")) {
			@pathxml=<WE>;
			close(WE);
			$found=1;
		}
		else {
			print("Cannot open xml file for pathway $pathway\n");
			$found=0;
		}
	}
	elsif(($_=~/EC:<[^>]+>([0-9]\.[0-9]+\.[0-9]+\.[0-9-]+)/)&&$found) {
		my @enzentry=grep(/entry.*name="ec:$1"/,@pathxml);
		foreach my $enz (@enzentry) {
			if($enz=~/reaction="rn:(R[0-9]{5})"/) {
				my $rea=$1;
				my @reaentry=grep(/<reaction name="rn:$rea"/../<\/reaction>/,@pathxml);
#				(@reaentry!=1)&&die("Bad number of reaction entries for $rea");
				$reaentry[1]=~/substrate name="cpd:(C[0-9]{5})/;
				my $sub=$1;
				$reaentry[0]=~/type="(.*)"/;
#				warn $1;
				if(defined($dircorr->{$rea})) {
					defined($reactions->{$rea})?push(@{$reactions->{$rea}->[1]},$sub):
					($reactions->{$rea}=[$dircorr->{$rea},[$sub]]);
				}
				elsif($1 eq "reversible") {
					(defined($reactions->{$rea})&&$reactions->{$rea}->[0]!=1)?
#					print(WY"Conflict of types for $rea\n"):
					(defined($rconf->{$rea})?push(@{$rconf->{$rea}},$sub):($rconf->{$rea}=[$sub])):
					(defined($reactions->{$rea})?push(@{$reactions->{$rea}->[1]},$sub):
					($reactions->{$rea}=[1,[$sub]]));
				}
				elsif($1 eq "irreversible") {
					defined($reactions->{$rea})&&$reactions->{$rea}->[0]!=0&&
					(defined($rconf->{$rea})?push(@{$rconf->{$rea}},$sub):($rconf->{$rea}=[$sub]));
#					print(WY"Conflict of types for $rea\n");
					defined($reactions->{$rea})?push(@{$reactions->{$rea}->[1]},$sub):
					($reactions->{$rea}=[0,[$sub]]);
				}
				else {
					die("Unknown reaction type");
				}
			}
		}
	}
}
open(WY,">conf.out");
foreach(keys(%{$rconf})) {
	print(WY $_);
	foreach my $rea (@{$_}) {print(WY"\t".$rea)}
	print("\n");
}
close(WY);
#open(WY,">keggrec.csv");

my $comphash={};
foreach(keys(%{$reactions})) {
#	my $rsugg=$tobin->transformationCandidatesGet($_,'t_lnk');
#	if(@{$rsugg}) {
#		push(@{$tfset},$rsugg->[0]);
#		$reactions->{$_}&&push(@{$tfset},$rsugg->[1]);
#		print(WY $_."\t".$reactions->{$_});
#		foreach my $rea (@{$rsugg}) {
#			print(WY "\t".$rea);
#		defined($linkhash->{$rea})?print(WY "\t".$linkhash->{$rea}):
#		print(WY"\tnolink");
#		}
#	}
#	else {
#		my $url="perl -MLWP::Simple -e\'getprint(".
#		"\"http://www.genome.jp/dbget-bin/www_bget?rn:".$_."\")\' |";
#		open(WE, $url) || die("Problem with webpage.");
#		my@page=<WE>;
#		close(WE);
#		print(WY $_."\t".$reactions->{$_}."\t");
#		my @def=grep(/Definition/../Equation/,@page);
#		$def[1]=~m%<code>(.*)<br>|<code>(.*)</code>%;
#		print(WY defined($1)?$1:$2);
#		for(my $i=2;$i<@def-1;$i++) {
#			$def[$i]=~m%^(.*)<br>|^(.*)</code>%;
#			print(WY defined($1)?$1:$2);
#		}
#	}
#	print(WY"\n");
#	my $url1="\"http://www.genome.jp/dbget-bin/www_bget?rn:".$_."\"";
#	`wget -O ppu-kegg/$_.htm $url1`;
#	next;
	if(!open(WE,"ppu-kegg/".$_.".htm")){
		my $url1="\"http://www.genome.jp/dbget-bin/www_bget?rn:".$_."\"";
		`wget -O ppu-kegg/$_.htm $url1`;
		open(WE,"ppu-kegg/".$_.".htm")||die("Cannot download file for $_");
	}
	
	my @comp=<WE>;
	close(WE);
	my @equ=grep(/Equation/.../<.tr>/,@comp);
	@equ>1||die("Bad length of equ.");
	chomp($equ[1]);
	if(@equ==3) {
		chomp($equ[2]);
		$equ[1]=$equ[1]." ".$equ[2];
	}
	$equ[1]=~s/<[^>]*>//g;
	$equ[1]=~s/^[2-9n] //;
	$equ[1]=~s/ [2-9n] / /g;
	$equ[1]=~s/\(n\+{0,1}1{0,1}\)//g;
#	($_ eq "R05225")&&warn($equ[1]);
	my @equ1=split(/ &lt;=> /,$equ[1]);
	my @reacts=split(/ \+ /,$equ1[0]);
	my @prods=split(/ \+ /,$equ1[1]);
	foreach my $spec ((@reacts,@prods)) {
		if(!defined($comphash->{$spec})) {
			my $csugg=$tobin->compoundCandidatesGet($spec,1);
			if(!@{$csugg}) {
#				warn("No compounds for $spec");
				$comphash->{$spec}=0;
			}
			elsif(@{$csugg}>1) {
#				warn("Multiple compounds for $spec.");
				$comphash->{$spec}=0;
			}
			else {
				$comphash->{$spec}=$csugg->[0];
			}
		}
	}
	$reactions->{$_}=[$reactions->{$_}->[0],$reactions->{$_}->[1],\@reacts,\@prods];
	
}
open(WE, "comp-corr.txt");
my @ccorr=<WE>;
close(WE);
foreach(@ccorr) {
	chomp;
	$comphash->{(split(/\t/,$_))[0]}=(split(/\t/,$_))[1];	
}

open(WY, ">comps-kegg.txt");
foreach(keys(%{$comphash})) {
#	my $url1="\"http://www.genome.jp/dbget-bin/www_bget?compound+".$_."\"";
#	$comphash->{$_}||`wget -Oppu-kegg/$_.htm $url1`
	if(!$comphash->{$_}) {
		if(!open(WE,"ppu-kegg/$_.htm")) {
			my $url1="\"http://www.genome.jp/dbget-bin/www_bget?compound+".$_."\"";
			`wget -Oppu-kegg/$_.htm $url1`;
			open(WE,"ppu-kegg/$_.htm")||die("Cannot download file for $_");
		}
		my @comp=<WE>;
		close(WE);
		my @names=grep(/Name/.../<.tr>/,@comp);
		chomp($names[1]);
		$names[1]=~s/<[^>]*>//g;
		$names[1]=~s/;//;
		$names[1]=~s/\[/./g;
		$names[1]=~s/\]/./g;
		my $csugg=$tobin->compoundCandidatesGet($names[1],0);
		if(!@{$csugg}) {
			print(WY"No compounds for $_- ".$names[1]."\n");
		}
		elsif(@{$csugg}==1) {
			print(WY"Accepted ".$tobin->compoundNameGet($csugg->[0])." as  $_ - $names[1]\n");
			$comphash->{$_}=$csugg->[0];
		}
		else {
			print(WY"Multiple compounds for $_- ".$names[1]."\n");
		}
	}
}
close(WY);
open(WE,"rea-corr.txt");
my @rcorr=<WE>;
close(WE);
my $rcorrect={};
foreach(@rcorr) {
	chomp($_);
	my @row=split(/\t/,$_);
	$rcorrect->{$row[0]}=[$row[1],$row[2]];
}
open(WE,"dir-corr.txt");
@rcorr=<WE>;
close(WE);
my $dcorrect={};
foreach(@rcorr) {
	chomp;
	$dcorrect->{(split(/\t/,$_))[0]}=(split(/\t/,$_))[1];
}
open(WY, ">ppu-tob.txt");
foreach(keys(%{$reactions})) {
	my $reacts={};
	my $prods={};
	foreach my $spec (@{$reactions->{$_}->[2]}) {
		($comphash->{$spec}>0)?($reacts->{$comphash->{$spec}}=1):last;
	}
	foreach my $spec (@{$reactions->{$_}->[3]}) {
		($comphash->{$spec}>0)?($prods->{$comphash->{$spec}}=1):last;
	}
	if(@{$reactions->{$_}->[2]}==keys(%{$reacts})&&
	@{$reactions->{$_}->[3]}==keys(%{$prods})) {
		if(!$reactions->{$_}->[0]) {
			my $rev=0;
			if(defined($dcorrect->{$_})) {
				$rev=$dcorrect->{$_};
			}
			else {
				my $revt=[];
				foreach my $revel (@{$reactions->{$_}->[1]}) {
					if(defined($reacts->{$comphash->{$revel}})) {push(@{$revt},0)}
					elsif(defined($prods->{$comphash->{$revel}})) {push(@{$revt},1)}
					else{die("Cannot find direction for $_")}
				}
				foreach my $sum (@{$revt}) {$rev+=$sum}
				if(!$rev||$rev==@{$reactions->{$_}->[1]}) {push(@{$reactions->{$_}},$rev)}
				else {
					print(WY"Reaction $_ - inconsistent directionality.\n");
					next;
				}
			}
			if($rev) {
				if(!defined($rcorrect->{$_})||$rcorrect->{$_}->[1]==0) {
					my $rsugg=$tobin->transformationFindByCompounds($prods,$reacts);
					if(!@{$rsugg}) {
						print(WY"No reactions for reverse $_\n");
					}
					elsif(@{$rsugg}==1) {
						print(WY"Accepted reaction $rsugg->[0] for reverse $_\n"); 
						defined($rcorrect->{$_})?($rcorrect->{$_}->[1]=$rsugg->[0]):
						($rcorrect->{$_}=[0,$rsugg->[0]]);
					}
					else {
						print(WY"Multiple reactions for reverse $_:");
						foreach my $sugg (@{$rsugg}){
							print(WY" $sugg");
						}
						print(WY"\n");
					}
				}
			}
			else {
				if(!defined($rcorrect->{$_})||$rcorrect->{$_}->[0]==0) {
					my $rsugg=$tobin->transformationFindByCompounds($reacts,$prods);
					if(!@{$rsugg}) {
						print(WY"No reactions for $_\n");
					}
					elsif(@{$rsugg}==1) {
						print(WY"Accepted reaction $rsugg->[0] for $_\n"); 
						defined($rcorrect->{$_})?($rcorrect->{$_}->[0]=$rsugg->[0]):
						($rcorrect->{$_}=[$rsugg->[0],0]);
					}
					else {
						print(WY"Multiple reactions for $_:");
						foreach my $sugg (@{$rsugg}){
							print(WY" $sugg");
						}
						print(WY"\n");
					}
				}
			}
		}
		else {
			if(!defined($rcorrect->{$_})||$rcorrect->{$_}->[0]==0) {
				my $rsugg=$tobin->transformationFindByCompounds($reacts,$prods);
				if(!@{$rsugg}) {
					print(WY"No reactions for reverse $_\n");
				}
				elsif(@{$rsugg}==1) {
					print(WY"Accepted reaction $rsugg->[0] for reverse $_\n"); 
					defined($rcorrect->{$_})?($rcorrect->{$_}->[0]=$rsugg->[0]):
					($rcorrect->{$_}=[$rsugg->[0],0]);
				}
				else {
					print(WY"Multiple reactions for reverse $_:");
					foreach my $sugg (@{$rsugg}){
						print(WY" $sugg");
					}
					print(WY"\n");
				}
			}
			if(!defined($rcorrect->{$_})||$rcorrect->{$_}->[1]==0) {
				my $rsugg=$tobin->transformationFindByCompounds($prods,$reacts);
				if(!@{$rsugg}) {
					print(WY"No reactions for $_\n");
				}
				elsif(@{$rsugg}==1) {
					print(WY"Accepted reaction $rsugg->[0] for $_\n"); 
					defined($rcorrect->{$_})?($rcorrect->{$_}->[1]=$rsugg->[0]):
					($rcorrect->{$_}=[0,$rsugg->[0]]);
				}
				else {
					print(WY"Multiple reactions for $_:");
					foreach my $sugg (@{$rsugg}){
						print(WY" $sugg");
					}
					print(WY"\n");
				}
			}
		}
	}
}
close(WY);
my $tfset=[];
foreach(keys(%{$reactions})) {
	if(defined($rcorrect->{$_})) {
		($reactions->{$_}->[0]&&$rcorrect->{$_}->[0]!=0&&$rcorrect->{$_}->[1]!=0)&&
		push(@{$tfset},$rcorrect->{$_}->[0],$rcorrect->{$_}->[1]);
		$reactions->{$_}->[4]&&!$reactions->{$_}->[0]&&$rcorrect->{$_}->[1]!=0&&
		push(@{$tfset},$rcorrect->{$_}->[1]);
		!$reactions->{$_}->[4]&&!$reactions->{$_}->[0]&&$rcorrect->{$_}->[0]!=0&&
		push(@{$tfset},$rcorrect->{$_}->[0]);
	}
}
my $keggcodes={};
foreach(keys(%{$rcorrect})) {
	if($rcorrect->{$_}->[0]) {
		defined($keggcodes->{$rcorrect->{$_}->[0]})&&die("Multiple kegg codes for ".$rcorrect->{$_}->[0]);
		$keggcodes->{$rcorrect->{$_}->[0]}=$_;
	}
	if(@{$rcorrect->{$_}}==2&&$rcorrect->{$_}->[1]) {
		defined($keggcodes->{$rcorrect->{$_}->[1]})&&die("Multiple kegg codes for ".$rcorrect->{$_}->[1]);
		$keggcodes->{$rcorrect->{$_}->[1]}=$_;
	}
}

foreach(keys(%{$keggcodes})) {
	print("$_\t$keggcodes->{$_}\n");
}
#print(@{$tfset}."\n");
#my %fba1=$tobin->fbaresGet(620376);
#my $count=0;
#foreach(@{$tfset}) {
#	defined($fba1{$_})||$count++;
#}
#print("$count\n");

#print(@{$tfset}."\n");
#my $prev=$tobin->transformationsetGet(152);
#my $prevhash={};
#foreach(@{$prev->{TRANS}}) {
#	$prevhash->{$_}=1;
#}
#my $diff=[];
#foreach(@{$tfset}) {
#	defined($prevhash->{$_})||push(@{$diff},$_);
#}
#print(@{$diff}."\n");
#my $tfset1=[];
#foreach(101 .. 200) {
#	push(@{$tfset1},$tfset->[$_-1]);
#	if(!($_%10)) {
#		$tobin->transformationsetCreate("ppu-kegg1.2.".(($_-100)/10),$tfset1);
#		$tfset1=[];
#	}
#}
#$tobin->transformationsetCreate("ppu-kegg1.".(int(@{$tfset}/100)+1),$tfset1);
#$tobin->transformationsetCreate("ppu-kegg3",$diff);

