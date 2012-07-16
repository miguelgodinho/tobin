# (C) Miguel Godinho de Almeida - miguel@datindex.com 2005
package WebArc::ViewSingle;

use strict;
use warnings;

sub new {
	my $param	= shift;
	my $self	= shift;
	my $class	= ref( $param ) || $param;
	bless( $self, $class );
	$self->{EDIT}							= 0;
	$self->{MEM}							= $self->{BRO}->{MEM};
	$self->{DBA}							= $self->{MEM}->{DBA};
	$self->{LOG}							= $self->{MEM}->{LOG};
	$self->{HLP}							= $self->{BRO}->{HLP};
	$self->{CONST}							= $self->{BRO}->{CONST};
	$self->{data}							|| $self->{HLP}->suicide();
	$self->{CODE}							|| $self->{HLP}->suicide();
	$self->{CHILD}							|| $self->{HLP}->suicide();
	
	my $data = $self->{data};
	
	if( $data->{INIT} ) {
		( $data->{CODE}			eq $self->{CODE} )			|| $self->{HLP}->suicide();
		( $data->{CHILDCODE}	eq $self->{CHILD}->{CODE} )	|| $self->{HLP}->suicide();
		( $data->{ID}			eq $self->{CHILD}->{ID} )	|| $self->{HLP}->suicide();
	}
	else {
		$data->{INIT}		= 1;
		$data->{CODE}		= $self->{CODE};
		$data->{CHILDCODE}	= $self->{CHILD}->{CODE};
		$data->{ID}			= $self->{CHILD}->{ID};
		( $self->{CHILD}->{TYPE} eq 'SINGLE' ) || $self->{HLP}->suicide();
	}
	return $self;
}

sub printView {
	my $self	= shift;
	my $scr		= shift;		
	my $child	= $self->{CHILD};
	my $mem		= $self->{MEM};
	my $allows	= [];
	my $length;
	my $value;
	my $default;
	
	
	( $child->{DISPLAY}->[0] =~ m/^0=?(\d*)$/ ) ? ( $length = $1 ) : ( $length = 0 );
	if ( $child->{UNCLES}->[0] ) {
		my $daf = [];
		if ( $self->{EDIT} || !@{$child->{data}} ) {
			$child->{FLAGS}->{RO} && $self->{HLP}->suicide();
			( $child->{data}->[0] && defined( $child->{data}->[0]->[0] ) ) ? ( $value = $child->{data}->[0]->[0] ) : ( $value = $child->{DEFAULTS}->[0] );
			defined( $child->{ALLOWS}->[0] ) && ( @{$allows} = split( /,/, $child->{ALLOWS}->[0] ) );
			@{$allows}	|| ( $allows = undef );#method Memory::entityDefMatrixGet requires that way
			
			foreach ( @{$mem->entityDefMatrixGet( $child->{UNCLES}->[0], $allows )} ) {
				$_->[0] || $self->{HLP}->suicide();
				if ( $_->[0] eq $value ) {
					$default ? $self->{HLP}->suicide() : ( $default = 1 );
					push( @{$daf}, [ $value, 1, $_->[1] ] );
				}
				else {
					push( @{$daf}, [ $_->[0], 0, $_->[1] ] );
				}
			}
			@{$daf} && !@{$child->{REQS}} && ( $default ? ( unshift( @{$daf}, [ 0, 0, '' ] ) ) : ( unshift( @{$daf}, [ 0, 1, '' ] ) ) );
		}
		else {
			$child->{data}->[0]->[0] || warn "$child->{CODE}";
			@{$daf} = ( [ $child->{data}->[0]->[0], 1, @{$mem->entryDefsGet( $child->{UNCLES}->[0], $child->{data}->[0]->[0] )} ] );
		}
		$self->doSingleUncleBox( $scr, $self->{CONST}->{COLOR_BLUE}, $child->{NAME}, $length, $child->{UNCLES}->[0], $child->{data}, $daf );
	}
	elsif ( @{$child->{ALLOWS}} ) {
		$child->{FLAGS}->{RO} && $self->{HLP}->suicide();
		my $allowedValues; 
		my $labels;
		my $matrix;
		my $pos;
		my $value;

		@{$allowedValues} = split( /,/, $child->{ALLOWS}->[0] );
		@{$labels} = split( /,/, $child->{LABELS}->[0] );
		( scalar( @{$allowedValues} ) eq scalar( @{$labels} ) ) || $self->{HLP}->suicide();
		( $child->{data}->[0] && defined( $value = $child->{data}->[0]->[0] ) ) || defined( $value = $child->{DEFAULTS}->[0] ) || ( $value = '' );
		
		for ( $pos = 0; $pos < scalar( @{$allowedValues} ); $pos++ ) {
			$allowedValues->[$pos] || $self->{HLP}->suicide();
			( $allowedValues->[$pos] == $value ) ? ( push( @{$matrix}, [ $allowedValues->[$pos], 1, $labels->[$pos] ] ) ) : ( push( @{$matrix}, [ $allowedValues->[$pos], 0, $labels->[$pos] ] ) );
		}
		$self->doSingleAllowsBox( $scr, $self->{CONST}->{COLOR_BLUE}, $child->{NAME}, $matrix );
	}
	else {
		$self->doSingleBox( $scr, $self->{CONST}->{COLOR_BLUE}, $child->{LABELS}->[0], $length, $child->{data}, $child->{FLAGS}->{RO} );
	}
}



sub processForm {
	my $self		= shift;
	my $form		= shift;
	my $submitKey	= shift;
	my $submitValue	= shift;
	my $errors		= shift;#output
	my $warnings	= shift;#output
	my $child		= $self->{CHILD};
	my $newData		= [];
	my $v;
	
	
	if( @{$submitKey} ) {
		if( $submitKey->[0] eq 'edit' ) {	
			$self->{EDIT} = 1;
		}
		elsif( $submitKey->[0] ne 'gear' ) {
			$self->{HLP}->suicide( "@{$submitKey}" );
		}
	}
	
	if( $child->{FLAGS}->{RO} ) {
		$self->{HLP}->copyData( $child->{data}, $newData );
	}
	elsif ( $form->{VALUE}->{1} && defined( $v = $form->{VALUE}->{1}->{0} ) ) {
		@{$newData} = ( [ $v ] );
	}
	elsif ( @{$child->{data}} ) {
		$child->{REQS} && ( @{$newData} = ( [ $child->{data}->[0]->[0] ] ) );
	}
	$self->{MEM}->childObjUpdate( $child, $newData, $errors, $warnings );
	return '';
}

sub doSingleBox {#
	my $self		= shift;
	my $scr			= shift;
	my $color		= shift;
	my $name		= shift;
	my $length		= shift;#length of the search field
	my $data		= shift;
	my $readonly	= shift;

	$scr->openTable( 1, "bordercolor=#$color border frame=box rules=none" );
	$scr->doCell( "$name:", "bgcolor=#$color" );

	my $v = '';
	( $data->[0] && defined( $data->[0]->[0] ) ) && ( $v = $data->[0]->[0] );
	if ( $readonly ) {
		if ( length( $v ) ) {
			$scr->openRow();
			$scr->openCell();
			$scr->doTxt( $v, [ 'MULTILINE40' ] );
		}
	}
	else {
		$length || $self->{HLP}->suicide( "$self->{CODE}, $name" );
		$scr->openRow();
		$scr->openCell();
		$scr->doEdit( "$self->{CODE}&VALUE&1&0", $v, $length );
	}
	$scr->closeTable();
}

sub doSingleUncleBox {#
	my $self	= shift;
	my $scr		= shift;
	my $color	= shift;
	my $name	= shift;
	my $length	= shift;#length of the search field
	my $uncle	= shift;
	my $data	= shift;#[ [ id, selection, name1, name2, ... ] ]
	my $options	= shift;

	my $pos;
	my $link;
	my $v = '';
	( $data->[0] && defined( $data->[0]->[0] ) ) && ( $v = $data->[0]->[0] );
	if( $self->{CHILD}->{FLAGS}->{RO} ) {
		$scr->openTable( 1, "bordercolor=#$color border frame=box rules=none" );
		$scr->openCell( "bgcolor=#$color" );
		$scr->doTxt( "$name:" );
		$scr->closeRow();
		$scr->openCell();
		if( $v ) {
			( $link = $self->{MEM}->getLink( $uncle, $v ) ) ? $scr->doLink( $link, $options->[0]->[2] ) : $scr->doTxt( $options->[0]->[2] );
		}
		else{
			$scr->doTxt( "-" );
		}
		$scr->closeTable();
	}
	elsif ( $self->{EDIT} || !length( $v ) ) {
		if ( $length ) {
			my $entry;
			$scr->openTable( 2, "bordercolor=#$color border frame=box rules=none" );
			$scr->doCell( "$name:", "bgcolor=#$color colspan=2" );
			$scr->doToolBox( $self->{CODE}, 16, [ '', 'lookup', 'gear' ] ); 
			foreach $entry ( @{$options} ) {
				$scr->openRow();
				$scr->openCell();
				if ( $entry->[0] == $v ) {
					$scr->doRadio( "$self->{CODE}&VALUE&1&0", $entry->[0], 1 );
				}
				elsif ( !$entry->[1] ) {
					$scr->doRadio( "$self->{CODE}&VALUE&1&0", $entry->[0], 0 );
				}
				else {
					$self->{HLP}->suicide();
				}

				$scr->openCell();
				( $link = $self->{MEM}->getLink( $uncle, $entry->[0] ) ) ? $scr->doLink( $link, $entry->[2] ) : $scr->doTxt( $entry->[2] );
				for ( $pos = 3; $pos < scalar( @{$entry} ); $pos++ ) {
					$scr->doTxt( "\n$entry->[$pos]" );
				}
			}
			$scr->closeTable();
		}
		elsif ( @{$options} ) {
			$scr->openTable( 1, "bordercolor=#$color border frame=box rules=none" );
			$scr->openCell( "bgcolor=#$color" );
			$scr->doTxt( "$name:" );
			$scr->doToolBox( $self->{CODE}, 16, [ '', 'gear' ] );
			$scr->closeRow();
			$scr->openCell();
			$scr->doSelect( "$self->{CODE}&VALUE&1&0", $options );
			$scr->closeTable();
		}
		else {
			$scr->openTable( 1, "bordercolor=#$color border frame=box rules=none" );
			$scr->doCell( "$name - No Values to Select From", "bgcolor=#$color" );
			$scr->closeTable();
		}
	}
	else {
		( scalar( @{$options} ) == 1 ) || $self->{HLP}->suicide();
		( scalar( @{$options->[0]} ) > 2 ) || $self->{HLP}->suicide();
		( $options->[0]->[0] == $v) || $self->{HLP}->suicide();
		$scr->openTable( 1, "bordercolor=#$color border frame=box rules=none" );
		$scr->openCell( "bgcolor=#$color" );
		$scr->doTxt( "$name:" );
		$scr->doToolBox( $self->{CODE}, 16, [ '', 'edit' ] );
		$scr->closeRow();
		$scr->openCell();
		$scr->doHidden( "$self->{CODE}&VALUE&1&0", $v );
		( $link = $self->{MEM}->getLink( $uncle, $v ) ) ? $scr->doLink( $link, $options->[0]->[2] ) : $scr->doTxt( $options->[0]->[2] );
		for ( $pos = 3; $pos < scalar( @{$options->[0]} ); $pos++ ) {
			$scr->doTxt( "\n$options->[0]->[$pos]" );
		}
		$scr->closeTable();
	}
}
sub doSingleAllowsBox {#
	my $self	= shift;
	my $scr		= shift;
	my $color	= shift;
	my $name	= shift;
	my $options	= shift;
	
	$scr->openTable( 1, "bordercolor=#$color border frame=box rules=none" );
	$scr->openCell( "bgcolor=#$color" );
	$scr->doTxt( "$name:" );
	$scr->closeRow();
	$scr->openCell();
	$scr->doSelect( "$self->{CODE}&VALUE&1&0", $options );
	$scr->closeTable();
}
1;
