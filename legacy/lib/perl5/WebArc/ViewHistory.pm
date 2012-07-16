# (C) Miguel Godinho de Almeida - miguel@datindex.com 2005
package WebArc::ViewHistory;

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
	$self->{PARENT}							|| $self->{HLP}->suicide();
	$self->{CODE}							|| $self->{HLP}->suicide();
	
	return $self;
}

sub printView {
	my $self	= shift;
	my $scr		= shift;
	my $mem		= $self->{MEM};
	my $color	= $self->{CONST}->{COLOR_YELLOW};
	my $history	= [];
	
	
	if ( $self->{PARENT}->{ID} && ( @{$history} = $mem->entryHistoryGet( $self->{PARENT}->{CODE}, $self->{PARENT}->{ID} ) ) ) {
		warn "here";
		$scr->doLine();
		$scr->openCell();
		$scr->openDiv( "history_view" );
		
		
#		$scr->openTable( 1, "bordercolor=#$color border frame=box rules=none" );
#		$scr->doCell( "History Log:", "bgcolor=#$color" );
#		foreach ( @{$history} ) { $scr->doLine( $_ ) };
#		$scr->closeTable();
		
		$scr->closeDiv();
		$scr->closeRow();
	}
}
1;
