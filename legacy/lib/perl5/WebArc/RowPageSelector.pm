# (C) Miguel Godinho de Almeida - miguel@datindex.com 2005
package WebArc::RowPageSelector;

use strict;
use warnings;

sub new {
	my $param	= shift;
	my $self	= shift;
	my $class	= ref( $param ) || $param;
	bless( $self, $class );
	
	$self->{HLP}								= $self->{BRO}->{HLP};
	$self->{CODE}								|| $self->{HLP}->suicide();
	$self->{COLUMNS}							|| $self->{HLP}->suicide();
	$self->{BGCOLOR}							|| $self->{HLP}->suicide();
	
	return $self;
}

sub printRow {
	my $self		= shift;
	my $scr			= shift;	
	my $pn			= shift;
	my $total		= shift;
	my $code		= $self->{CODE};
	my $pos;
	my $limit;
	my $lastButton;
	
	if( ( $total > 1 ) ) {
		$scr->openRow( "bgcolor=#$self->{BGCOLOR}" );		
		$scr->openCell( "colspan=$self->{COLUMNS} align=center" );
		
		if( $pn ) {
			$scr->doToolBox( $code, 16, [ 'left', '' ] );	
			if( ( $pos = $pn - 9 ) > 0 ) {
				$scr->doSubmit( "$code&goto&1", "1" );	
			}
			else {
				$pos = 0;
			}
			while( $pos < $pn ) {
				$pos++;
				$scr->doSubmit( "$code&goto&".$pos, "$pos" );	
			}
		}
		else {
			$pn && $self->{HLP}->suicide();
		}
		
		$pos = $pn + 1;
		$scr->doSubmit( "$code&goto&".$pos, "$pos", 1 );
		
		if( $pos < $total ) {
			$limit = 0;
			if( ( $lastButton = $pn + 10 ) < $total ) {
				$limit = 1;	
			}
			else {
				$lastButton = $total;
			}
			
			while( $pos < $lastButton ) {
				$pos++;
				$scr->doSubmit( "$code&goto&".$pos, "$pos" );
			}
			
			$limit && $scr->doSubmit( "$code&goto&".$total, $total );
			$scr->doToolBox( $code, 16, [ '', 'right' ] );
		}
		else {
			( ( $total -1 ) == $pn ) || $self->{HLP}->suicide( "$total : $pn" );
		}
	}
}

sub processForm {
	my $self		= shift;
	my $submitKey	= shift;
	
	if( $submitKey->[0] eq 'goto' ) {
		return ( $submitKey->[1] - 1 );
	}
	elsif( $submitKey->[0] eq 'right' ) {
		return "+1";
	}
	elsif( $submitKey->[0] eq 'left' ) {
		return "-1";
	}
	else {
		$self->{HLP}->suicide( $submitKey->[0] );	
	}
}

1;
