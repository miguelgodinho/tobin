#!/usr/bin/perl -w
use strict;
use warnings;
use Tobin::IF;
my $tobin		= new Tobin::IF(1);
my $fbaset=$tobin->fbasetupGet($ARGV[0]);

@ARGV<4&&die("Too few arguments");
my @tab;
my @tab1;
open(WE,$ARGV[1])||die("Cannot open reaction list");
@tab=<WE>;
close(WE);
my $keggcd={};
foreach(@tab) {
	chomp;
	@tab1=split(/\t/,$_);
	$keggcd->{$tab1[0]}=$tab1[1];
}
my $tfhash={};
my $nolink={};
foreach(@{$fbaset->{TFSET}}) {
	my $link;
	if(defined($keggcd->{$_->[0]})) {
		$link=$keggcd->{$_->[0]}
	}
	else {
		my $tf=$tobin->transformationGet($_->[0]);
		foreach my $lnk(@{$tf->[1]}) {
			if($lnk->{user}==901) {
				$link=$lnk->{link};
				last;
			}
		}
	}
	if(defined($link)) {
		if(defined($tfhash->{$link})) {
			$tfhash->{$link}->[0]<$_->[0]?
			push(@{$tfhash->{$link}},$_->[0]):
			unshift(@{$tfhash->{$link}},$_->[0]);
#			warn $keggcd->{$tab1[1]}->[1];
		}
		else {
			$tfhash->{$link}=[];
			push(@{$tfhash->{$link}},$_->[0]);
		}
	}
	else {
		$nolink->{$_->[0]}=1;
	}
	
}
open(WE,$ARGV[2])||die("Cannot open genes file");
my @gfile=<WE>;
close(WE);
open(WE,$ARGV[3])||die("Cannot open pathway list");
@tab=<WE>;
close(WE);
my $plist={};
foreach(@tab) {
	chomp;
	$_=~/([0-9]{5})/;
	$plist->{$1}=$_;
}
my $result={};
foreach(keys(%{$plist})) {
	open(WE, $plist->{$_})||die("Cannot open pathway file $_");
	@tab=<WE>;
	close(WE);
	@tab1=grep(/entry.*rn:/,@tab);
	my $regex=$_.".*PATH";
	my @tab2=grep(/$regex/.../PATH/,@gfile);
	foreach my $entry (@tab1) {
		chomp $entry;
		$entry=~/rn:(R[0-9]{5})/;
		my $tf=$1;
		defined($tfhash->{$tf})||next;
		$entry=~/name="([^"]+)"/;
		my $name=$1;
		$name=~/^(ec:|ko:)(.*)$/||next;
		my $vtype=$1 eq "ec:"?"EC-":"KO-";
		my $value=$2;
#		warn $value;
		my @tab3=grep(/$value/,@tab2);
		@tab3||next;
		my $kstr=$tfhash->{$tf}->[0].(@{$tfhash->{$tf}}==2?"/".$tfhash->{$tf}->[1]:"").
		"\t".$tf;
#		print($tfhash->{$tf}->[0]);
#		@{$tfhash->{$tf}}==2&&print("/".$tfhash->{$tf}->[1]);
#		print("\t".$tf."\t".$value."\t");
		my $vstr=$vtype.$value;
		my $ghash={};
		foreach my $gene (@tab3) {
			$gene=~/PA([0-9]{4})/&&
			($ghash->{"PA".$1}=1);
#			($vstr=$vstr."PP".$1.",");
		}
#		$vstr=~s/,$//;
#		print("\n");
		defined($result->{$kstr})||($result->{$kstr}={});
		defined($result->{$kstr}->{$vstr})||($result->{$kstr}->{$vstr}={});
#		push(@{$result->{$kstr}},$vstr);
		foreach my $gene (keys(%{$ghash})) {
			$result->{$kstr}->{$vstr}->{$gene}=1;
		}
	}
}
print(keys(%{$result})."\n");
foreach(keys(%{$result})) {
	print($_);
	foreach my $ec(keys(%{$result->{$_}})) {
		print("\t".$ec."\t");
		foreach my $gene (keys(%{$result->{$_}->{$ec}})) {
			print($gene.",");
		}
	}
#	if(@{$result->{$_}}>1) {
#		foreach my $val (1..(@{$result->{$_}}-1)) {
#			print("\t".$result->{$_}->[$val]);
#		}
	print("\n");
}
open(WE, $ARGV[4])||die("Cannot open reversible file.");
@tab=<WE>;
close(WE);
my $revhash={};
foreach(@tab) {
	chomp;
	@tab1=split(/\t/,$_);
	(defined($revhash->{$tab1[0]})||defined($revhash->{$tab1[1]}))&&
	die("Problem with reversibles.");
	$revhash->{$tab1[0]}=$tab1[1];
	$revhash->{$tab1[1]}=$tab1[0];
}
my $linkskip={};
foreach(keys(%{$nolink})) {
	defined($linkskip->{$_})&&next;
	defined($revhash->{$_})&&($linkskip->{$revhash->{$_}}=1);
	defined($revhash->{$_})?
	print($_<$revhash->{$_}?$_."/".$revhash->{$_}:$revhash->{$_}."/".$_):
	print($_);
	print("\n");
}
