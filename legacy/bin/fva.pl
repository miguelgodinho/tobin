#!/usr/bin/perl -w -I../pseudo2/
use strict;
use warnings;
use Tobin::IF;
use Rapido::General;
use Rapido::DBAccessor;
use Rapido::Parent;
use Tobin::functions;
use Time::HiRes;

@ARGV<7&&die("Too few parameters");

my $tobin= new Tobin::IF($ARGV[0]);
my $fvacpd=9376;
my $fvasink=9615;
my $fvasource=9616;
my $fva={};
open(WE,$ARGV[2])||die("cannot open excluded reactions file");
my @tab=<WE>;
close(WE);
my $excl={};
foreach(@tab) {
	chomp;
	$excl->{$_}=1;
}
open(WE,$ARGV[3])||die("cannot open limits file");
@tab=<WE>;
close(WE);
my $limits={};
foreach(@tab) {
	chomp;
	my @tab1=split(/\t/,$_);
	$limits->{$tab1[0]}=[$tab1[1],$tab1[2]];
}
open(WE, $ARGV[4])||die("Cannot open reversibles file");
@tab=<WE>;
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
my $fbasetup=$tobin->fbasetupGet($ARGV[1]);
my $fvasinkpos;
my $reamap={};
for(my $i=0;$i<@{$fbasetup->{TFSET}};$i++) {
	$fbasetup->{TFSET}->[$i]->[1]=0;
	$reamap->{$fbasetup->{TFSET}->[$i]->[0]}=$i;
	if($fbasetup->{TFSET}->[$i]->[0]==$fvasink) {
		$fvasinkpos=$i;
		$fbasetup->{TFSET}->[$i]->[1]=1;
	}
	if(defined($limits->{$fbasetup->{TFSET}->[$i]->[0]})) {
		if(!$limits->{$fbasetup->{TFSET}->[$i]->[0]}->[1]) {
			$fbasetup->{TFSET}->[$i]->[2]=0.99*$limits->{$fbasetup->{TFSET}->[$i]->[0]}->[0];
			$fbasetup->{TFSET}->[$i]->[3]=1.01*$limits->{$fbasetup->{TFSET}->[$i]->[0]}->[0];
		}
		elsif($limits->{$fbasetup->{TFSET}->[$i]->[0]}->[1]==1) {
			$fbasetup->{TFSET}->[$i]->[2]=$limits->{$fbasetup->{TFSET}->[$i]->[0]}->[0];
			$fbasetup->{TFSET}->[$i]->[3]=$limits->{$fbasetup->{TFSET}->[$i]->[0]}->[0];
		}
		elsif($limits->{$fbasetup->{TFSET}->[$i]->[0]}->[1]==2) {
			$fbasetup->{TFSET}->[$i]->[2]=$limits->{$fbasetup->{TFSET}->[$i]->[0]}->[0];
		}
	}
	elsif(!defined($excl->{$fbasetup->{TFSET}->[$i]->[0]})) {
		$fbasetup->{TFSET}->[$i]->[3]=1000;
	}
}
defined($fvasinkpos)||die("No fvasink in fbasetup");
$tobin->fbasetupUpdate($ARGV[1],undef,$fbasetup->{TFSET},undef)&&
die("Problem updating database.");
#my $counter=0;
my $coorect={5080=>1,703=>1,179=>1,4556=>1};
foreach(@{$fbasetup->{TFSET}}) {
#	$counter<10||last;
#	$counter++;
#	print($_->[0]."\n");
	defined($coorect->{$_->[0]})||next;
	defined($excl->{$_->[0]})&&next;
	if(defined($revhash->{$_->[0]})) {
		$fbasetup->{TFSET}->[$reamap->{$revhash->{$_->[0]}}]->[3]=0;
		$tobin->fbasetupUpdate($ARGV[1],undef,$fbasetup->{TFSET},1)&&
		die("Problem updating database.");
	}
	else {
		$tobin->fbasetupUpdate($ARGV[1],undef,undef,1)&&
		die("Problem updating database.");
	}
	my $tf=$tobin->transformationGet($_->[0]);
	push(@{$tf->[2]},{id=>$fvacpd,sto=>1, ext=>0});
	my $errors=[];	
	$tobin->transformationModify($_->[0],undef,undef,$tf->[2],undef,$errors);
	if(@{$errors}) {
		foreach my $err (@{$errors}) {
			warn($err);
		}
		die("Cannot modify transformation $_->[0]");
	}
	my $fbaresult0=runfba($ARGV[1],$ARGV[0],$ARGV[5]);
	$fbaresult0->[0]<0&&
	warn("Problem running fba for transformation $_->[0] - maximization");
	$tobin->fbasetupUpdate($ARGV[1],undef,undef,2)&&
	die("Problem updating database.");
	my $fbaresult1=runfba($ARGV[1],$ARGV[0],$ARGV[5]);
	$fbaresult1->[0]<0&&
	warn("Problem running fba for transformation $_->[0] - minimization");
	pop(@{$tf->[2]});
	$tobin->transformationModify($_->[0],undef,undef,$tf->[2],undef,$errors);
	if(@{$errors}) {
		foreach my $err (@{$errors}) {
			warn($err);
		}
		die("Cannot modify transformation $_->[0]");
	}
	if(defined($revhash->{$_->[0]})) {
		$fbasetup->{TFSET}->[$reamap->{$revhash->{$_->[0]}}]->[3]=1000;
		$tobin->fbasetupUpdate($ARGV[1],undef,$fbasetup->{TFSET},undef)&&
		die("Problem updating database.");
	}
	$fva->{$_->[0]}=[$fbaresult0,$fbaresult1];
}
foreach(@{$fbasetup->{TFSET}}) {
	if(defined($limits->{$_->[0]})) {
		$_->[2]=0;
		$_->[3]=undef;
	}
	elsif(!defined($excl->{$_->[0]})) {
		$_->[3]=undef;
	}
	
}
$tobin->fbasetupUpdate($ARGV[1],undef,$fbasetup->{TFSET},undef)&&
warn("Problem updating database.");
my $printexcl={};
open(WY,">$ARGV[6]")||die("cannot open output file");
foreach(keys(%{$fva})) {
	defined($printexcl->{$_})&&next;
#	if($_==5080||defined($revhash->{$_})&&$revhash->{$_}==5080) {
#		print($_."\t".$fva->{$_}->[0]->[0]."\t".$fva->{$_}->[1]->[0].
#		$fva->{$_}->[0]->[1]."\t".$fva->{$_}->[1]->[1]."\n");
#		print($revhash->{$_}."\t".$fva->{$revhash->{$_}}->[0]->[0]."\t".$fva->{$revhash->{$_}}->[1]->[0].
#		$fva->{$revhash->{$_}}->[0]->[1]."\t".$fva->{$revhash->{$_}}->[1]->[1]."\n");
#	}
	if(defined($revhash->{$_})) {
		print(WY $_."/".$revhash->{$_}."\t");
		$printexcl->{$revhash->{$_}}=1;
		if($fva->{$_}->[1]->[0]>0) {
			if($fva->{$_}->[0]->[0]>0||$fva->{$revhash->{$_}}->[1]->[0]<=0) {
				print(WY $fva->{$_}->[0]->[0]."\t".$fva->{$_}->[1]->[0]);
				$ARGV[5]&&print(WY "\t".$fva->{$_}->[0]->[1]."\t".$fva->{$_}->[1]->[1]);
			}
			else {
				print(WY"-".$fva->{$revhash->{$_}}->[1]->[0]."\t".
				$fva->{$_}->[1]->[0]);
				$ARGV[5]&&print(WY "\t".$fva->{$revhash->{$_}}->[1]->[1].
				"\t".$fva->{$_}->[1]->[1]);
			}
		}
		else {
			print(WY "-".$fva->{$revhash->{$_}}->[1]->[0]."\t".
			($fva->{$revhash->{$_}}->[0]->[0]>0?"-":"").
			$fva->{$revhash->{$_}}->[0]->[0]);
			$ARGV[5]&&print(WY "\t".$fva->{$revhash->{$_}}->[1]->[1].
			"\t".$fva->{$revhash->{$_}}->[0]->[1]);
		}
	}
	else {
		print(WY $_."\t".$fva->{$_}->[0]->[0]."\t".$fva->{$_}->[1]->[0]);
		$ARGV[5]&&print(WY "\t".$fva->{$_}->[0]->[1]."\t".$fva->{$_}->[1]->[1]);
	}
	print(WY"\n");
}
close(WY);


sub runfba {

my $setup=shift;
my $uid=shift;
my $save=shift;
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
	if($save) {
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
}
else {
	warn "FBA failed to run using: $args2exec";
}
($lastStatusLine=~m/Primal infeasible|Dual infeasible/)&&return([0,0]);
($lastStatusLine=~m/objective value ([-]{0,1}[0-9.]+(e[-]{0,1}[0-9]+){0,1})$/)&&return([$1<0?0:$1,$save?$record->{ID}:0]);
return [-1,0];
}
