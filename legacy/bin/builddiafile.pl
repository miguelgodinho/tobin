#!/usr/bin/perl -I/home/jap04/workspace/pseudo -w
use strict;
use warnings;
use Tobin::IF;

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

open(WE, $ARGV[0])||die("Cannot open input file");
@tab=<WE>;
close(WE);


my $tobin=new Tobin::IF(1);
my $excpd={1=>1,65=>1,3=>1,4=>1,6=>1,5=>1,2=>1,8=>1,
	18=>1,9=>1,957=>1,13=>1,234=>1,12=>1};
my $multcpd={11=>0,31=>0,38=>0,15=>0,964=>0,10=>0,85=>0,193=>0,340=>0};
my $edges=[];
my $cpdnodes={};
my $tfnodes={};
foreach(@tab) {
	chomp;
	my @tab1=split(/\t/,$_);
	my $num=shift(@tab1);
	my $rea=$tobin->transformationGet($num);
	my $drawrea=0;
	foreach my $cpd (@{$rea->[2]}) {
		defined($excpd->{$cpd->{id}})&&next;
		$drawrea++;
		my $kname=($cpd->{ext}?"EX":"")."C".sprintf("%04d",$cpd->{id}).
		(defined($multcpd->{$cpd->{id}})?("-".$multcpd->{$cpd->{id}}++):"");
		$cpdnodes->{$kname}=$tobin->compoundNameGet($cpd->{id}).
		($cpd->{ext}?"(e)":"");
		push(@{$edges},[$kname,$num,$cpd->{sto}<0?-1:1,
		defined($revhash->{$num})?1:0]);
	}
	if($drawrea>1) {
		my $str="";
		foreach my $line (@tab1) {
			$str.=$line."\\r";
		}
		$tfnodes->{$num}=$str;
	}
	$drawrea==1&&pop(@{$edges});
}

open(WY,">$ARGV[2]")||die("Cannot open output file");
print(WY "digraph \"plot\" {\n");
foreach (keys(%{$cpdnodes})) {
	my $len=length($cpdnodes->{$_})*0.12;
	print(WY "\t\"".$_.
	"\" [\n\t\tlabel = \"".$cpdnodes->{$_}."\"\n");
	print(WY "\t\tfontname = \"Fixed\"\n\t\tfontcolor = \"black\"\n");
	print(WY"\t\twidth = $len\n\t\theight = 0.2\n");
	print(WY"\t\tfixedsize=true\n");
	print(WY "\t\tshape = \"box\"\n");
	print(WY"\n\t]\n");

}

foreach (keys(%{$tfnodes})) {
	print(WY"\t\"R".sprintf("%04d",$_)."\" [\n\t\tlabel = \"".
	$tfnodes->{$_}."\"\n");
	print(WY "\t\tfontsize = \"12\"\n");
	print(WY "\t\tcolor = \"black\"\n");
	print(WY "\t\tshape = \"ellipse\"\n");
	print(WY"\t\tfixedsize=true\n");
	print(WY "\t\theight = \"0.03\"\n\t\twidth = \"0.03\"\n\t]\n");
}
foreach(@{$edges}) {
	if($_->[2] <0) {
		print(WY "\"".$_->[0]."\" -> \"R".
		sprintf("%04d",$_->[1])."\" [\n");
		print(WY"\t\ttailport = \"s\"\n");
		print(WY"\t\theadport = \"n\"\n");
		print(WY"\t\tarrowhead = \"none\"\n");
#		$_->[3]&&print(WY "\t\tarrowtail = \"normal\"\n");
		print(WY"\t]\n");
	}
	else {
		print(WY "\"R".sprintf("%04d",$_->[1])."\" -> ".
		"\"".$_->[0]."\" [\n");
		print(WY"\t\ttailport = \"s\"\n");
		print(WY"\t\theadport = \"n\"\n");
		print(WY"\t\tarrowhead = \"normal\"\n");
		print(WY"\t]\n");
	}
}

print(WY "}\n");

close(WY);
