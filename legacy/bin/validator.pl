#!/usr/bin/perl
use strict;
use warnings;
use lib "/usr/local/lib/site-perl/";
use Rapido::DBAccessor;
use Rapido::Parent;
use Rapido::SimulAccessor;
use Rapido::General;
use Time::HiRes;

my $pid = $$;
my $arguments = {};
foreach ( @ARGV ) {
	m/^--([^=]+)=(.*)$/ || die $_;
	$arguments->{"$1"} = $2;
}

my $startTime = Time::HiRes::time();
my $dba = new Rapido::DBAccessor(	{	CHK		=> 1,
										DB_HOST => $arguments->{sqlhost},
										DB_USER => $arguments->{sqluser}, 
										DB_PASS => $arguments->{sqlpass},
										DB_DATA => $arguments->{db} } );
my $log = new Rapido::LogAccessor(	{	DBA => $dba,
										USR => $arguments->{uid} } );
my $helper = new Rapido::General();
my $cpu = new Rapido::SimulAccessor( { DBA => $dba, HLP => $helper, EPID => $pid, USR => $arguments->{uid} } );
$cpu->procStatusChange( "Running:" );
die();
my $ipid = $cpu->{IPID};
warn "$ipid";

###################################################################################

my $entitiesToCheck = [];
my $parentAttribs = { flags => {} };
foreach ( split( /;/, $dba->getValue( "SELECT flags FROM parents WHERE p='$arguments->{parent}'" ) ) ) { $_ && ( $parentAttribs->{flags}->{"$_"} = 1 ) };
if ( $arguments->{uid} != 1 ) {
	$parentAttribs->{flags}->{ADMIN} && die( "FATAL ERROR - $arguments->{parent} IS PROTECTED" );
	$parentAttribs->{ownerTbl} = $dba->getValue( "SELECT ownertbl FROM parents where p='$arguments->{parent}'" );
}

my $errors = [];
my $entity;
my $totalErrors;
my $reportData = { d_date => [ [ 'NOW()' ] ], d_def => [ [ 'Running' ] ], d_entity => [ [ $arguments->{parent} ] ], d_u => [ [ $arguments->{uid} ] ] };
my $report = new Rapido::Parent( { HLP => $helper, LOG => $log, CODE => 'd', ID => 0, DBA => $dba } );
$report->process( $reportData, $errors, [ 'AUTH' ] );
$parentAttribs->{ownerTbl} ? ( @{$entitiesToCheck} = $dba->getColumn( "SELECT id FROM $arguments->{parent} LEFT JOIN $parentAttribs->{ownerTbl} ON $parentAttribs->{ownerTbl}.p=$arguments->{parent}.id WHERE ( $parentAttribs->{ownerTbl}.x0=$arguments->{uid} OR $parentAttribs->{ownerTbl}.x0=999 )" ) ) : ( @{$entitiesToCheck} = $dba->getColumn( "SELECT id FROM $arguments->{parent}" ) );

@{$errors} = ();
foreach $entity ( @{$entitiesToCheck} ) { 
	print "$entity\n";
	my $record = new Rapido::Parent( { HLP => $helper, LOG => $log, CODE => $arguments->{parent}, ID => $entity, DBA => $dba } );
	foreach ( $record->checkData() ) { push( @{$errors}, "$entity:$_" ) };
}

if ( $totalErrors = scalar( @{$errors} ) ) {
	my $pos = 0;
	while ( $pos < $totalErrors ) { push( @{$reportData->{d_errors}}, [ $errors->[$pos], ++$pos ] ) };
	$reportData->{d_def} = [ [ "$totalErrors Error(s) Found" ] ];
}
else {
	$reportData->{d_def} = [ [ "No Errors Found" ] ];
}

@{$errors} = ();
$report->process( $reportData, $errors, [ 'AUTH' ] );

########################################################################################

my $elapsedTime = Time::HiRes::time() - $startTime;
$elapsedTime =~ m/^([^\.]*\..{2})/;
$cpu->procStatusChange( "Complete: ($1 s)" );
$cpu->procStatusChangeLnk( "?app=valid" );
$cpu->checkAndFire();
exit;
