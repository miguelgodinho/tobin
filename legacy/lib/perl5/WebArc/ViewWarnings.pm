# (C) Miguel Godinho de Almeida - miguel@datindex.com 2005
package WebArc::ViewWarnings;

use strict;
use warnings;
use vars qw($VERSION @ISA @EXPORT_OK);
use Exporter;

@ISA = ( 'Exporter' );
$VERSION = '1.00';
@EXPORT_OK = qw();

sub new {
	my $param	= shift;
	my $self	= shift;
	my $class	= ref( $param ) || $param;
	bless( $self, $class );
	$self->{MEM}							= $self->{BRO}->{MEM};
	$self->{DBA}							= $self->{MEM}->{DBA};
	$self->{LOG}							= $self->{MEM}->{LOG};
	$self->{HLP}							= $self->{BRO}->{HLP};
	$self->{CONST}							= $self->{BRO}->{CONST};
	$self->{CELL}							= $self->{BRO}->{CELL};
	$self->{CODE}							|| $self->{HLP}->suicide();
	
	return $self;
}

sub printView {
	my $self	= shift;
	my $scr		= shift;
	my $errors	= shift;
	my $color	= $self->{CONST}->{COLOR_YELLOW};
	my $i		= 0;

	if ( @{$errors} ) {
		$scr->openRow();
		$scr->openCell();
		$scr->openTable( 1, "bordercolor=#$color border frame=box rules=none width=100%" );
		$scr->doCell( "Warnings:", "bgcolor=#$color" );
		foreach ( @{$errors} ) {
			$i++;
			$scr->doLine( "($i) $_" );
		} 
		$scr->closeTable();
		return 1;
	}
}

1;
