# (C) Miguel Godinho de Almeida - miguel@datindex.com 2005
package WebArc::ViewSearchEntity;

use strict;
use warnings;

sub new {
	my $param	= shift;
	my $self	= shift;
	my $class	= ref( $param ) || $param;
	bless( $self, $class );
	
	$self->{MEM}	= $self->{BRO}->{MEM};
	$self->{DBA}	= $self->{MEM}->{DBA};
	$self->{HLP}	= $self->{BRO}->{HLP};
	$self->{CONST}	= $self->{BRO}->{CONST};
	$self->{CODE}	|| $self->{HLP}->suicide();
	$self->{ENTITY}	|| $self->{HLP}->suicide();
	$self->{data}	|| $self->{HLP}->suicide();
	$self->{lists}	|| $self->{HLP}->suicide();
	
	my $data = $self->{data};
	
	if( $data->{init} ) {
		( $data->{CODE}	eq $self->{CODE} )	|| $self->{HLP}->suicide();
	}
	else {
		$data->{init}		= 1;
		$data->{CODE}		= $self->{CODE};
		$data->{criteria}	= '';
		$data->{value}		= '';
	}
	return $self;
}

sub printView {
	my $self	= shift;
	my $scr		= shift;		
	my @criteria = $self->{MEM}->entityRelativesMatrixGet( $self->{ENTITY}->{CODE}, [ 'SEARCH' ] );
	
	$scr->openTable( 1 );
	$scr->openCell( 'align=center' );
	$scr->doSelect( "$self->{CODE}&criteria", \@criteria, $self->{data}->{criteria} );
	$scr->doTxt( ' = ' );
	$scr->doEdit( "$self->{CODE}&value", $self->{data}->{value}, $self->{CONST}->{SEARCH_FIELD_LENGTH} );
	$scr->doToolBox( $self->{CODE}, 16, [ '', 'lookup' ] );
	$scr->closeTable();
}

sub processForm {
	my $self		= shift;
	my $form		= shift;
	my $submitKey	= shift;
	my $data		= $self->{data};
	my $lists		= $self->{lists};
	my $foundsHash	= $lists->{founds};
	my $newFounds;
	
	if( $submitKey ) {
		$lists->{closed}		&& $self->{HLP}->suicide();
		$data->{value}			= $form->{value};
		$data->{criteria}		= $form->{criteria};
		$self->{lists}->{page}	= 0;
		%{$foundsHash}			= ();
		
		if( defined( $form->{value} ) ) {
			$newFounds = $self->{MEM}->entitySearch( $self->{ENTITY}->{CODE}, $form->{value}, $form->{criteria}, undef, 'noregex' );
			foreach( @{$newFounds} ) { $foundsHash->{$_} = 1 };
		}
	}

	return [];
}

1;
