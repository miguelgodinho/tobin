# (C) Miguel Godinho de Almeida - miguel@datindex.com 2004
package WebArc::Valid;

use strict;
use warnings;
use vars qw($VERSION @ISA @EXPORT_OK);
use Exporter;

use Rapido::SimulAccessor;

@ISA = ( 'Exporter');
$VERSION = '1.00';
@EXPORT_OK = qw();

sub new {
	my $param	= shift;
	my $self	= shift;;
	my $class	= ref( $param ) || $param;
	bless( $self, $class );
	bless ( $self->{BRO}, 'WebArc::Broker' );
	$self->{MEM}	= $self->{BRO}->{MEM};
	$self->{DBA}	= $self->{MEM}->{DBA};
	$self->{LOG}	= $self->{MEM}->{LOG};
	$self->{HLP}	= $self->{BRO}->{HLP};
	$self->{USR}	= $self->{MEM}->{USR};
	$self->{CONST}	= $self->{BRO}->{CONST};
	$self->{CELL}	= $self->{BRO}->{CELL};
	$self->{CODE}	= $self->{BRO}->{app};
	die();
	$self->{CPU} = new Rapido::SimulAccessor( {	CONST		=> $self->{CONST},
		 									USR			=> $self->{USR},
		 									DBA			=> $self->{DBA},
		 									HLP			=> $self->{HLP},
		 									LOG			=> $self->{LOG}				} );
	$self->{CPU}->checkAndFire();
	%{$self->{PARENTS}} = $self->{MEM}->entityAttribGet();
	return $self;
}

sub processForm {
	my $self 	= shift;
	my $form	= shift;

	my $p;
	if ( $p = $form->{submitKey} ) {
		my $errors	= [];
		$self->{HLP}->suicide( "simulSchedule call has to start using setups!" );
		my $ipid	= $self->{CPU}->simulSchedule( $errors, $self->{CONST}->{VALIDATOR_APP}, ";parent=$p;", "Check $p", "", $self->{USR} );
		warn $ipid;
	}
	return '';

}

sub run {
	my $self 	= shift;
	my $mem		= $self->{MEM};
	my $cpu		= $self->{CPU};
	my $scr		= $self->{SCR};
	my $cell	= $self->{CELL};
	my $form	= $self->{BRO}->getForm();

	if ( $form->{submitKey} ) {
		my $nxtApp;
		( $nxtApp = $self->processForm( $form ) ) && ( return $nxtApp );
	}

	$scr->openPage( $self->{CODE} );
	$scr->stoBar( [ 'Bookmark Manager', 'man0b' ] );
	$scr->stoBar( [ 'Data Validator', 'valid' ] );
	$scr->doBar( 'valid' );

	my $parent;
	my $attribs;
	my $lastProcess;

	foreach $parent ( sort ( keys %{$self->{PARENTS}} ) ) { #display alphabetically
		$attribs = $self->{PARENTS}->{$parent};
		if ( !( $attribs->{FLAGS} =~ m/;NOCHK;/ ) && ( ( $self->{USR} == 1 ) || !( $attribs->{FLAGS} =~ m/;ADMIN;/ ) ) ) {
			$scr->openRow();
			$scr->openRow();
			$scr->openCell();
			
			if ( $lastProcess = $cpu->procGetLast( $self->{CONST}->{VALIDATOR_APP}, "Check $parent" ) ) {
				my $status = $cpu->procGetStatus( $lastProcess );
				if ( ( $status =~ m/^Running/ ) || ( $status =~ m/^Fired/ ) ) {
					$cell->doSetPageLinkBox( $scr, $parent, $self->{CONST}->{COLOR_SILVER}, 2, "$attribs->{NAME} ( running )", $parent, 0, 0, 0, [], [ 'NOCARDINAL' ] );
				}
				elsif ( $status =~ m/^Complete/ ) {
					my @logs = @{$mem->entityList( 'd', 1, 'd_entity', "$parent" )};
					$logs[0] || $self->{HLP}->suicide();
					my $lastLog = $mem->entryConstDataGet( 'd', $logs[0] );
					if ( $lastLog->{d_def}->[0]->[0] =~ m/^Running/ ) {
						$self->{HLP}->suicide();
					}
					elsif ( @{$lastLog->{d_errors}} ) {
						my $errors = [];
						foreach ( @{$lastLog->{d_errors}} ) {
							( $_->[0] =~ m/^(\d+):(.*)/ ) || $self->{HLP}->suicide();
							push( @{$errors}, [ $1, $2 ] );
						}
						$cell->doSetPageLinkBox( $scr, $parent, $self->{CONST}->{COLOR_RED}, 2, "$attribs->{NAME} ???", $parent, 0, 0, 0, $errors, [ 'NOCARDINAL' ] );
					}
					else {
						$cell->doSetPageLinkBox( $scr, $parent, $self->{CONST}->{COLOR_GREEN}, 2, "$attribs->{NAME} OK ( last checked on $lastLog->{d_date}->[0]->[0]", $parent, 0, 0, 0, [], [ 'NOCARDINAL', 'PROCESS' ] );
					} 
				}
				elsif ( $status =~ m/^Found Dead/ ) {
					$cell->doSetPageLinkBox( $scr, $parent, $self->{CONST}->{COLOR_YELLOW}, 2, "Check $attribs->{NAME} ( last check failed )", $parent, 0, 0, 0, [], [ 'NOCARDINAL', 'PROCESS' ] );
				}
				else {
					$self->{HLP}->suicide( $status );
				}
			}
			else {
				$cell->doSetPageLinkBox( $scr, $parent, $self->{CONST}->{COLOR_YELLOW}, 2, "Check $attribs->{NAME} ( never checked )", $parent, 0, 0, 0, [], [ 'NOCARDINAL', 'PROCESS' ] );
			}
		}
	}
	$scr->closePage();
	return '';
}
1;
