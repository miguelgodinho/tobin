#!/usr/bin/perl -I. -w
use strict;
use warnings;
use Tobin::IF;

@ARGV<2&&die("Too few arguments.");
my $tobin		= new Tobin::IF(1);
open(WE, $ARGV[0])||die("Cannot open reversibles file");
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
my $compmap=[{}, {}];
my $blcmp={};
my %fbares=$tobin->fbaresGet($ARGV[1]);
my $end;
my $deadmap={};
my $ends={};
my $revexclude={};
my $reahash={};
foreach(keys(%fbares)) {
	defined($revexclude->{$_})&&next;
	$reahash->{$_}=[[{},{}],[{},{}]];
	my $rea=$tobin->transformationGet($_);
	foreach my $comp(@{$rea->[2]}){
		my $rev=0;
		if(defined($revhash->{$_})) {
			$revexclude->{$revhash->{$_}}=1;
			$rev=1;
		}
		defined($compmap->[$comp->{ext}]->{$comp->{id}})?
		($compmap->[$comp->{ext}]->{$comp->{id}}->{$_}=$comp->{sto}<0?[1,$rev]:[0,$rev]):
		($compmap->[$comp->{ext}]->{$comp->{id}}={$_=>$comp->{sto}<0?[1,$rev]:[0,$rev]});
		$reahash->{$_}->[$comp->{ext}]->[$comp->{sto}<0?1:0]->{$comp->{id}}=1;
	}
}
print(keys(%{$reahash})."\n");
print(keys(%{$compmap->[0]})."\n");
print(keys(%{$compmap->[1]})."\n");
foreach(keys(%{$compmap->[0]})) {
	print($_."\t".$tobin->compoundNameGet($_)."\n");
}
print("EXT\n");
foreach(keys(%{$compmap->[1]})) {
	print($_."\t".$tobin->compoundNameGet($_)."\n");
}

my $rea2del={};
foreach(keys(%{$compmap->[0]})) {
	my $dir=0;
	my $rev=0;
	foreach my $d (values(%{$compmap->[0]->{$_}})) {
		$dir+=$d->[1]?0:$d->[0];
		$rev+=$d->[1];
	}
#	$_==67&&print(keys(%{$compmap->[0]->{$_}})."\n");
#	$_==67&&print($dir."\t".$rev."\n");
	if(!$rev&&(!$dir ||$dir==keys(%{$compmap->[0]->{$_}}))||
	$rev==1&&keys(%{$compmap->[0]->{$_}})==1) {
		$blcmp->{$_}=1;
		foreach my $rea (keys(%{$compmap->[0]->{$_}})) {
			defined($deadmap->{$rea})||
			($deadmap->{$rea}=[{},$compmap->[0]->{$_}->{$rea}->[1],{}]);
			$deadmap->{$rea}->[0]->{$_}=$dir?1:0;
			$ends->{$rea}=$_;
			$rea2del->{$rea}=1;
		}
	}
#	$_==67&&print(keys(%{$compmap->[0]->{$_}})."\n");
}
foreach my $rea(keys(%{$rea2del})) 
{
	foreach my $comp (keys(%{$reahash->{$rea}->[0]->[0]}),
	keys(%{$reahash->{$rea}->[0]->[1]})) {
		delete($compmap->[0]->{$comp}->{$rea});	
	}
}
#print(keys(%{$compmap->[0]->{67}})."\n");
do {
	$end=0;
	my $cpd2del={};
	my $rea2del={};
	foreach(keys(%{$compmap->[0]})) {
		keys(%{$compmap->[0]->{$_}})||(($cpd2del->{$_}=1)&&next);
		my $dir=0;
		my $rev=0;
		foreach my $d (values(%{$compmap->[0]->{$_}})) {
			$dir+=$d->[1]?0:$d->[0];
			$rev+=$d->[1];
		}
		if(!$rev&&(!$dir ||$dir==keys(%{$compmap->[0]->{$_}}))||
		$rev==1&&keys(%{$compmap->[0]->{$_}})==1) {
			$blcmp->{$_}=1;
			foreach my $rea (keys(%{$compmap->[0]->{$_}})) {
				foreach my $rel(keys(%{$deadmap})) {
					$rel==$rea&&next;
					if($deadmap->{$rel}->[1]||$compmap->[0]->{$_}->{$rea}->[1]) {
						(defined($reahash->{$rel}->[0]->[0]->{$_})||
						defined($reahash->{$rel}->[0]->[1]->{$_}))&&
						($deadmap->{$rel}->[2]->{$rea}=$_);
					}
					elsif(defined($reahash->{$rel}->[0]->[$dir?0:1]->{$_})) {
						$deadmap->{$rel}->[2]->{$rea}=$_;
					}
				}
				defined($deadmap->{$rea})||
				($deadmap->{$rea}=[{},$compmap->[0]->{$_}->{$rea}->[1],{}]);
				$deadmap->{$rea}->[0]->{$_}=$dir?1:0;
				$end=1;
				$rea2del->{$rea}=1;
			}
		}
#		$_==67&&print(keys(%{$compmap->[0]->{$_}})."\n");
	}
	foreach my $rea(keys(%{$rea2del})) 
	{
		foreach my $comp (keys(%{$reahash->{$rea}->[0]->[0]}),
		keys(%{$reahash->{$rea}->[0]->[1]})) {
			delete($compmap->[0]->{$comp}->{$rea});	
		}
	}
#	print(keys(%{$compmap->[0]->{67}})."\n");
	foreach(keys(%{$cpd2del}))
	{delete($compmap->[0]->{$_})}
} while($end);
print(keys(%{$reahash})."\n");
print(keys(%{$compmap->[0]})."\n");
print(keys(%{$compmap->[1]})."\n");
foreach(keys(%{$compmap->[0]})) {
	print($_."\t".$tobin->compoundNameGet($_)."\n");
}
#print(keys(%{$deadmap->{8277}->[2]}));
#print("\n");
#print(values(%{$deadmap->{8277}->[2]}));
#print("\n");
#print($deadmap->{8277}->[1]."\n");
#exit;
foreach(keys(%{$ends})) {
	my $dir=$deadmap->{$_}->[1]?"0":(defined($reahash->{$_}->[0]->[0]->{$ends->{$_}})?"-1":"1");
	print("C".sprintf("%04d",$ends->{$_}).($dir==1?"-->":($dir==-1?"<--":"<->")));
	print("R".sprintf("%04d",$_));
	my $start=1;
	foreach my $nrea(keys(%{$deadmap->{$_}->[2]})) {
		if($start) {
			print($dir==1?"-->":($dir==-1?"<--":"<->"));
			$start=0;
		}
		else {
			print("             ".($dir==1?"\\->":($dir==-1?"^--":"^->")));
		}
		print("C".sprintf("%04d",$deadmap->{$_}->[2]->{$nrea}));
		prnexttf($nrea,$deadmap->{$_}->[2]->{$nrea},1);
#		print("\n");
	}
	if(!keys(%{$deadmap->{$_}->[2]})) {
		my $attach=0;
		foreach my $cpd(keys(%{$reahash->{$_}->[0]->
		[defined($reahash->{$_}->[0]->[0]->{$ends->{$_}})?1:0]})){
			defined($compmap->[0]->{$cpd})||(!($attach=$cpd)||last);
		}
		print($attach?($dir==1?"-->":($dir==-1?"<--":"<->"))."C".$attach:"*");
		print("\n");
	}
}

sub prnexttf {
my $top=shift;
my $jcpd=shift;
my $level=shift;
my $dir=$deadmap->{$top}->[1]?"0":
(defined($reahash->{$top}->[0]->[0]->{$jcpd})?"-1":"1");
my $start=1;
print(($dir==1?"-->":($dir==-1?"<--":"<->"))."R".sprintf("%04d",$top));
foreach(keys(%{$deadmap->{$top}->[2]})) {
	if($start) {
		print($dir==1?"-->":($dir==-1?"<--":"<->"));
		$start=0;
	}
	else {
		print("             ");
		for(my $i=0;$i<$level;$i++) {
			print("|               ");
		}
		print($dir==1?"\\->":($dir==-1?"^--":"^->"));
		}
	print("C".sprintf("%04d",$deadmap->{$top}->[2]->{$_}));
#	if($level<10) {
		prnexttf($_,$deadmap->{$top}->[2]->{$_},$level+1)
#	}
#	else {
#		print("\n");
#	}
}
if(!keys(%{$deadmap->{$top}->[2]})) {
	my $attach=0;
	foreach(keys(%{$reahash->{$top}->[0]->
	[defined($reahash->{$top}->[0]->[0]->{$jcpd})?1:0]})){
		defined($compmap->[0]->{$_})||(!($attach=$_)||last);
	}
	print($attach?($dir==1?"-->":($dir==-1?"<--":"<->"))."C".$attach:"*");
	print("\n");
}	
}

