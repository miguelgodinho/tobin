#!/usr/bin/perl -w -I.
use strict;
use warnings;
use Tobin::IF;
use Rapido::General;
use Rapido::DBAccessor;
use Rapido::Parent;
use Tobin::functions;
use Time::HiRes;

my $tobin=new Tobin::IF(1); 
open(WE, $ARGV[1])||die("Cannot open mcodes");
my @tab=<WE>;
close(WE);
my $mhash={};
foreach(@tab) {
	chomp;
	my @tab1=split(/\t/,$_);
	$mhash->{$tab1[0]}=$tab1[1];
}
open(WE,$ARGV[0])||die("Cannot open input file");
@tab=<WE>;
close(WE);
my $techpow=$tobin->transformationGet(9732);
foreach(@tab) {
	chomp;
	my $errors=[];
	$tobin->transformationModify(9732,$techpow->[0],$techpow->[1],[{id=>9323, sto=>1,ext=>0},{id=>$mhash->{$_},sto=>-1,ext=>0}],$techpow->[3],$errors);
	my $res=runfba(68,1004);
	print($_."\t".$res."\n");
}

sub runfba {

my $setup=shift;
my $uid=shift;
my $startTime	= Time::HiRes::time();
my $CONST		= Tobin::functions::constantsGet();
#my $helper		= new Rapido::General();
#my $dba			= new Rapido::DBAccessor( { DB_HOST => $CONST->{DB_HOST}, DB_DATA => $CONST->{DB_DATA}, DB_USER => $CONST->{DB_USER}, DB_PASS => $CONST->{DB_PASS} } );	
my $args2exec	= "--setup=$setup --user=$uid --bounds=$CONST->{MY_FBASET_TRANSF} --type=$CONST->{MY_FBATYPE} --stoichs=$CONST->{MY_TRANSF_COMP} --db=$CONST->{DB_DATA} --host=$CONST->{DB_HOST} --sqlUser=$CONST->{DB_USER} --sqlPass=$CONST->{DB_PASS}";
my $output		= [];
my $errors		= [];
my $elapsedTime	= 0;
my $results		= 0;
my $logSerial	= 0;
my $serial		= -1;
my $transformation;
#my $record;
my $flux;
my $key;
my $value;
my $lastStatusLine;

@{$output} = `/usr/local/fba/fba3 $args2exec 2>&1`;
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
	
#	$record = new Rapido::Parent( {	HLP			=> $helper,
#									USR			=> $uid,
#									CODE		=> $CONST->{MY_FBARES},
#									ID			=> 0,
#									AUTH		=> 3,
#									DBA			=> $dba,	
#									NAME		=> $CONST->{PARENTS}->{$CONST->{MY_FBARES}}->{NAME},
#									ALLCHILDREN	=> $CONST->{CHILDREN},
#									FLAGS		=> $CONST->{PARENTS}->{$CONST->{MY_FBARES}}->{FLAGS} } );
#	while( ( $key, $value ) = each( %{$data} ) ) {
#		Tobin::functions::childUpdate( $dba, $record->{CHILDREN}->{$key}, $value, $errors, [] );		
#	}
#	
#	if( @{$errors} ) {
#		foreach( @{$errors} ) { warn "FBA CRITICAL ERROR ( results not saved ) $_ " };
#		foreach( @{$log} ) { warn "@{$_}" };
#	}
#	else {
#		Tobin::functions::entrySave( $dba, $record, $errors, [] );
#		foreach( @{$errors} ) { warn "FBA CRITICAL ERROR ( results not saved ) $_ : @{$log}" };
#	}
}
else {
	warn "FBA failed to run using: $args2exec";
}
($lastStatusLine=~m/Primal infeasible/)&&return(0);
($lastStatusLine=~m/objective value ([-]{0,1}[0-9.]+(e[-]{0,1}[0-9]+){0,1})$/)&&return($1<0?0:$1);
return -1;
}
