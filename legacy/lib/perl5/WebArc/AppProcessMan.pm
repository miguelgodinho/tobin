# (C) Miguel Godinho de Almeida - miguel@datindex.com 2004
package WebArc::AppProcessMan;

use strict;
use warnings;
use vars qw($VERSION @ISA @EXPORT_OK);
use lib "./";
use Rapido::SimulAccessor;
use Exporter;

@ISA = ( 'Exporter');
$VERSION = '1.00';
@EXPORT_OK = qw();

sub new {#rev5
	my $param	= shift;
	my $self	= shift;;
	my $class	= ref( $param ) || $param;
	bless( $self, $class );
	bless( $self->{BRO}, 'WebArc::Broker' );
	$self->{CODE}	= $self->{BRO}->{app};
	$self->{MEM}	= $self->{BRO}->{MEM};
	$self->{DBA}	= $self->{MEM}->{DBA};
	$self->{LOG}	= $self->{MEM}->{LOG};
	$self->{HLP}	= $self->{BRO}->{HLP};
	$self->{USR}	= $self->{MEM}->{USR};
	$self->{CONST}	= $self->{BRO}->{CONST};
	$self->{CELL}	= $self->{BRO}->{CELL};
	$self->{CPU} = new Rapido::SimulAccessor( {	} );
	return $self;
}

sub processForm {
	my $self 	= shift;
	my $form	= shift;

	return '';
}

sub run {
	my $self 	= shift;
	my $mem		= $self->{MEM};
	my $cpu		= $self->{CPU};
	my $scr		= $self->{SCR};
	my $form	= $self->{BRO}->getForm();
	my $nxtApp;

	@{$form->{submitKey}} && ( $nxtApp = $self->processForm( $form ) ) && ( return $nxtApp );
	
	my $ENTITY			= $self->{CONST}->{PROC_PARENT};
	my $APP				= $self->{CONST}->{PROC_APP};
	my $PROC_USR		= $self->{CONST}->{PROC_USER};
	my $PROC_DATE		= $self->{CONST}->{PROC_DATE};
	my $cell			= $self->{CELL};
	my $lastProcess		= [];
	my $thingsToShow	= [];
	my $attribs;
	my $process;
	my $parent;
	my $txt;
	my $lnk;

	$cpu->refresh();
	$scr->openPage( $self->{CODE} );
	$scr->stoBar( [ 'logout', $self->{CONST}->{DOMAIN_APP_PUBLIC} ] );	
	$scr->stoBar( [ 'Bookmark Manager', 'man0b' ] );
	$scr->stoBar( [ 'Process Manager', 'pman' ] );
	$scr->doBar( 'pman' );
	$scr->openRow();
	$scr->openCell( 'align=center' );
	$scr->openTable( 6, 'cellpadding=5' );
	$scr->doCell( 'Application', 'align=center' );
	$scr->doCell( 'Process', 'align=center' );
	$scr->doCell( 'User', 'align=center' );
	$scr->doCell( 'Status', 'align=center' );
	$scr->doCell( 'Date', 'align=center' );
#	@{$thingsToShow} = $mem->entityList( $ENTITY );
#	foreach( @{$thingsToShow} ) {
	foreach( @{$mem->entityList( $ENTITY ) } ) {
#		$process = $mem->entryConstDataGet( $ENTITY, $_ );
#		$scr->openRow();
#		defined( $txt = $process->{$APP}->[0]->[0] ) || ( $txt = 'no app !!!' );
#		$scr->doCell( $txt );
#		if( defined( $lnk = $process->{$DEF_LNK}->[0]->[0] ) ) {
#			defined( $txt = $process->{$DEF}->[0]->[0] ) || $self->{HLP}->suicide();
#			$scr->openCell();
#			$scr->doLink( $lnk, $txt );
#		}
#		elsif( defined( $txt = $process->{$DEF}->[0]->[0] ) ) {
#			$scr->doCell( $txt );
#		}
#		else{
#			$scr->doCell( 'no definiton !!!' );
#		}
#		defined( $txt = $process->{$PROC_USR}->[0]->[0] ) || ( $txt = 'no user !!!' );
#		$scr->doCell( $mem->userNameGet( $txt ) );
#		if ( defined( $lnk = $process->{$STATUS_LNK}->[0]->[0] ) ) {
#			defined( $txt = $process->{$STATUS}->[0]->[0] ) || $self->{HLP}->suicide();
#			$scr->openCell();
#			$scr->doLink( $lnk, $txt );
#		}
#		elsif ( defined( $txt = $process->{$STATUS}->[0]->[0] ) ) {
#			( $txt eq 'Running:' ) && ( $txt = "$txt ( ". $self->{DBA}->getValue( "SELECT TIMEDIFF( NOW(), '$process->{$PROC_DATE}->[0]->[0]')" ). " )" );
#			$scr->doCell( $txt );
#		}
#		else {
#			$scr->doCell( 'no status !!!' );
#		}
#			
#		defined( $txt = $process->{$PROC_DATE}->[0]->[0] ) || ( $txt = 'no date !!!' );
#		$scr->doCell( $txt );
#		$scr->doCell( 'toolbox' );
	}
	$scr->closeTable();
	$scr->closePage();
	return '';
}
1;
