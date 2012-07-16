#!/usr/bin/perl
use strict;
use warnings;
use Tobin::IF;
use Rapido::General;
use Rapido::DBAccessor;
use Rapido::Parent;
use Tobin::functions;
use Time::HiRes;

my $tobin		= new Tobin::IF(1008);

open(WE, "GPR-gene.csv")||die("Cannot open protein anno.");
my @prot=<WE>;
close(WE);

my $protanno = {};

foreach(@prot) {
	chomp($_);
	my @anno=split(/\t/,$_);
	my $glist=[];
	for(my $i=1;$i<@anno;$i++) {
		if($anno[$i]=~m/(b[0-9]{4})/) {
			push(@{$glist},$1);
		}
		else {
			print("Problem with blattner name for $anno[$i].\n");
		}
	}
	$protanno->{$anno[0]}=$glist;
}
 open(WE, "GPR-rea.csv")||die("Cannot open reaction anno.");
 my @rea=<WE>;
 close(WE);
 
 my $reaanno={};
 foreach(@rea) {
 	chomp($_);
 	my @anno=split(/\t/,$_);
 	my $glist=[];
 	for(my $i=1;$i<@anno;$i++) {
 		if(!defined($protanno->{$anno[$i]})) {
 			print("Problem with protein name for $anno[$i].\n");
 			next;
 		}
 		push(@{$glist},@{$protanno->{$anno[$i]}});		
 	}
 	if(defined($reaanno->{$anno[0]})) {
 		push(@{$reaanno->{$anno[0]}},$glist);
 	}
 	else {
 		$reaanno->{$anno[0]}=[$glist];
 	}
 }
 my $genehash={};
 foreach(keys(%{$reaanno})) {
 	foreach my $glist (@{$reaanno->{$_}}) {
 		foreach my $gene (@{$glist}) {
	 		if(defined($genehash->{$gene})) {
 				push(@{$genehash->{$gene}},$_);
 			}
 			else {
 				$genehash->{$gene}=[$_];
 			}
 		}
 	}
 }
 print (keys(%{$genehash})."\n");
 open(WE,"iJ904-mod.csv")||die("Cannot open reaction list.");
my @rlist=<WE>;
close(WE);
open(WE, "simcodes.csv");
my @simcodes=<WE>;
close(WE);
my $reacts={};
foreach(@simcodes) {
	chomp($_);
	my @react=split(/\t/,$_);
	$reacts->{$react[0]}=(@react==2?[$react[1]]:[$react[1],$react[2]]);
}
my $fbacodes={};
foreach(@rlist) {
	chomp($_);
	my @react=split(/\t/,$_);
	$fbacodes->{$react[0]}=($react[1])?
	[$reacts->{$react[0]}->[0],$reacts->{$react[0]}->[1]]:
	[$reacts->{$react[0]}->[0]];
}
 my $genelist;
 @{$genelist}=sort(keys(%{$genehash}));
 my $fbasetup=$tobin->fbasetupGet(32);
 my $fbamap={};
 for(my $i=0;$i<@{$fbasetup->{TFSET}};$i++) {
 	$fbamap->{$fbasetup->{TFSET}->[$i]->[0]}=$i;
 }
 foreach(keys(%{$reaanno})) {
 	if(!defined($fbacodes->{$_}->[0])) {
 		print($_."\n");
 	}
 }
# exit;
for(my $i=0;$i<50;$i++) {
	foreach(keys(%{$reaanno})) {
		$fbasetup->{TFSET}->[$fbamap->{$fbacodes->{$_}->[0]}]->[3]=undef;
 		if(@{$fbacodes->{$_}}==2) {
 			$fbasetup->{TFSET}->[$fbamap->{$fbacodes->{$_}->[1]}]->[3]=undef;
 		}
	}
	if($tobin->fbasetupUpdate(32,undef,$fbasetup->{TFSET},undef)) {
 		die("Problem updating database.");
 	}
 	my $fbares=runfba(32,1008);
 	if($fbares->[0]==-1||!$fbares->[1]) {
 		die("Problem running initial fba.");
 	}
 	my $lastflux=$fbares->[0];
	my $geneactive={};
	foreach(keys(%{$genehash})) {
		$geneactive->{$_}=1;
	}
	my $reaactive={};
	foreach(keys(%{$reaanno})) {
		$reaactive->{$_}=1;
	}
 	my $todel=[];
 	my $deleted=[];
 	my $lastrem;
	my $fbalist=[];
 	print($genehash->{"b1210"}->[0]."\n");
 	for(my $j=0;$j<keys(%{$genehash});$j++) {
 		push(@{$todel},$j);
 	}
 	do {
 		my $rem=int(rand(@{$todel}));
		$lastrem=$todel->[$rem];
 		for(my $j=$rem;$j<@{$todel}-1;$j++) {
 			$todel->[$j]=$todel->[$j+1];
 		}
 		pop(@{$todel});
 		$geneactive->{$genelist->[$lastrem]}=0;
 		foreach (@{$genehash->{$genelist->[$lastrem]}}) {
 			if((!recompreact($_,$reaanno,$geneactive))&&$reaactive->{$_}) {
 				$reaactive->{$_}=0;
 				$fbasetup->{TFSET}->[$fbamap->{$fbacodes->{$_}->[0]}]->[3]=0;
 				if(@{$fbacodes->{$_}}==2) {
 					$fbasetup->{TFSET}->[$fbamap->{$fbacodes->{$_}->[1]}]->[3]=0;
 				}
 			}
 		}
 		if($tobin->fbasetupUpdate(32,undef,$fbasetup->{TFSET},undef)) {
 			die("Problem updating database.");
 		}
 		my $fbares=runfba(32,1008);
 		if($fbares->[0]==-1) {
 			die("Problem running fba.");
 		}
 		elsif($fbares->[0]<0.99*$lastflux) {
 			$geneactive->{$genelist->[$lastrem]}=1;
 			foreach (@{$genehash->{$genelist->[$lastrem]}}) {
 				if(recompreact($_,$reaanno,$geneactive)&&(!$reaactive->{$_})) {
 					$reaactive->{$_}=1;
 					$fbasetup->{TFSET}->[$fbamap->{$fbacodes->{$_}->[0]}]->[3]=undef;
 					if(@{$fbacodes->{$_}}==2) {
 						$fbasetup->{TFSET}->[$fbamap->{$fbacodes->{$_}->[1]}]->[3]=undef;
 					}
 				}
 			}
 		}
 		else {
 			$lastflux=$fbares->[0];
 		}
		$fbares->[1]?push(@{$fbalist},$fbares->[1]):0;
 	} while(@{$todel});
	open(WY,">>fbalist1.out");
	foreach(@{$fbalist}) {
		print(WY $_."\t");
	}
	print(WY "\n");
	close(WY);
	open(WY,">>reaactive1.out");
 	foreach(keys(%{$reaactive})) {
 		if($reaactive->{$_}==1) {
 			print(WY $_."\t");
 		}
 	}
	print(WY "\n");
	close(WY);
	open(WY,">>geneactive1.out");
	foreach(keys(%{$geneactive})) {
		if($geneactive->{$_}==1) {
			print(WY $_."\t");
		}
	}
	print(WY "\n");
	close(WY);
 }
 
 sub recompreact {
 	my $react = shift;
 	my $ranno = shift;
 	my $gactive = shift;
 	my $result=0;
 	foreach my $complex (@{$ranno->{$react}}) {
 		my $cres=1;
 		foreach(@{$complex}){
 			$cres&&=$gactive->{$_};
 		}
 		$result||=$cres;
 	}
 	return $result;
 }
 
 sub runfba {

my $setup=shift;
my $uid=shift;
my $startTime	= Time::HiRes::time();
my $CONST		= Tobin::functions::constantsGet();
my $helper		= new Rapido::General();
my $dba			= new Rapido::DBAccessor( { DB_HOST => $CONST->{DB_HOST}, DB_DATA => $CONST->{DB_DATA}, DB_USER => $CONST->{DB_USER}, DB_PASS => $CONST->{DB_PASS} } );	
my $args2exec	= "--setup=$setup --user=$uid --bounds=$CONST->{MY_FBASET_TRANSF} --type=$CONST->{MY_FBATYPE} --stoichs=$CONST->{MY_TRANSF_COMP} --db=$CONST->{DB_DATA} --host=$CONST->{DB_HOST} --sqlUser=$CONST->{DB_USER} --sqlPass=$CONST->{DB_PASS}";
my $output		= [];
my $errors		= [];
my $elapsedTime	= 0;
my $results		= 0;
my $logSerial	= 0;
my $serial		= -1;
my $transformation;
my $record;
my $flux;
my $key;
my $value;
my $lastStatusLine;

@{$output} = `/home/jap04/pseudo1/fba/fba3 $args2exec 2>&1`;
$elapsedTime = Time::HiRes::time() - $startTime;
$elapsedTime =~ m/^([^\.]*\..{2})/;
$elapsedTime = $1;
my $data	= {	"$CONST->{MY_FBARES}_$CONST->{USER_PARENT}"	=> [ [ $uid ] ],
				"$CONST->{MY_FBARES}_date"					=> [ [ 'NOW()' ] ],
				"$CONST->{MY_FBARES}_elapsed"				=> [ [ "$elapsedTime s" ] ],
				"$CONST->{MY_FBARES}_log"					=> [],
				"$CONST->{MY_FBARES}_status"				=> [ [ "Failed: No output" ] ],
				$CONST->{MY_FBARES_SETUP}					=> [ [ $setup ] ],
				$CONST->{MY_FBARES_FLUXES}					=> [] };
my $log	= $data->{"$CONST->{MY_FBARES}_log"};

if( @{$output} ) {
	foreach ( @{$output} ) {
		chop();
		
		if( $results ) {
			( $transformation, $flux ) = split( /:/ );
			push( @{$data->{$CONST->{MY_FBARES_FLUXES}}}, [ $transformation, $flux ] );
		}
		else {
			s/\s*$//;
			if( $_ =~ m/^OK:/ ) {
				 $results = 1;
			}
			else {
				push( @{$log}, [$_, ++$logSerial ] );
				$lastStatusLine = $_;
			}
		}
	}
	
	if( $lastStatusLine ) {
		( $data->{"$CONST->{MY_FBARES}_status"}->[0]->[0] = $lastStatusLine );
	}
	else {
		warn "fbal.pl failed using: $args2exec";
	}
	
	$record = new Rapido::Parent( {	HLP			=> $helper,
									USR			=> $uid,
									CODE		=> $CONST->{MY_FBARES},
									ID			=> 0,
									AUTH		=> 3,
									DBA			=> $dba,	
									NAME		=> $CONST->{PARENTS}->{$CONST->{MY_FBARES}}->{NAME},
									ALLCHILDREN	=> $CONST->{CHILDREN},
									FLAGS		=> $CONST->{PARENTS}->{$CONST->{MY_FBARES}}->{FLAGS} } );
	while( ( $key, $value ) = each( %{$data} ) ) {
		Tobin::functions::childUpdate( $dba, $record->{CHILDREN}->{$key}, $value, $errors, [] );		
	}
	
	if( @{$errors} ) {
		foreach( @{$errors} ) { warn "FBA CRITICAL ERROR ( results not saved ) $_ " };
		foreach( @{$log} ) { warn "@{$_}" };
	}
	else {
		Tobin::functions::entrySave( $dba, $record, $errors, [] );
		foreach( @{$errors} ) { warn "FBA CRITICAL ERROR ( results not saved ) $_ : @{$log}" };
	}
}
else {
	warn "FBA failed to run using: $args2exec";
}

if($lastStatusLine=~m/objective value [-]{0,1}([0-9.]+)$/) {
	return [$1,$record->{ID}];
}
elsif($lastStatusLine=~m/Primal infeasible/) {
	return [0,0];
}
return [-1,0];
}
 
