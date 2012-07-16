# (C) Miguel Godinho de Almeida - miguel@datindex.com 2005
package WebArc::ViewSet;

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
		$data->{search}		= '';
	}
	$self->{founds} = {};
	return $self;
}

sub printView {
	my $self			= shift;
	my $scr				= shift;
	my $mem				= $self->{MEM};
	my $child			= $self->{CHILD};
	my $definitions 	= {};
	my $sortedData		= [];
	my $unsortedData	= [];
	my $options			= [];
	my $uncle;
	my $length;
	my $txt;
	
	
	$child->{FLAGS}->{RO} && $self->{HLP}->suicide();
	( $child->{DISPLAY}->[0] =~ m/^0=?(\d*)$/ ) || $self->{HLP}->suicide();
	if ( $child->{FORK} ) {
		$self->doSetForkBox( $scr );
	}
	else {
		if ( $uncle = $child->{UNCLES}->[0] ) {
#			$1 && $self->{HLP}->suicide( "not implemented, try pagedchildren" );
			if ( $child->{ALLOWS}->[0] ) {
				$options = $mem->entityDefMatrixGet( $uncle, split( /,/, $child->{ALLOWS}->[0] ) );
			}
			else {
				$options = $mem->entityDefMatrixGet( $uncle );
			}
			
			foreach( @{$options} ) {
				$definitions->{$_->[0]} ? $self->{HLP}->suicide() : ( $definitions->{$_->[0]} = $_->[1] );
			}
			
			foreach( @{$child->{data}} ) {
				defined( $definitions->{$_->[0]} ) || $self->{HLP}->suicide( "$child->{CODE} - $child->{ID} - $_->[0]" );
				push( @{$unsortedData}, [ $_->[0], $definitions->{$_->[0]} ] );
			}
			
			@{$sortedData} = $self->{HLP}->sortMatrix( $unsortedData, [ 1 ] );
			unshift( @{$options}, [ 0, '' ] );
			$self->doSetUncleBox( $scr, $self->{CONST}->{COLOR_BLUE}, $child->{LABELS}->[0], $uncle, $options, $sortedData );
		}
		else {
			( $length = $1 ) || $self->{HLP}->suicide();
			$child->{FLAGS}->{RO} && $self->{HLP}->suicide();
			$self->doSetBox( $scr, $self->{CONST}->{COLOR_BLUE}, $child->{LABELS}->[0], $length, $child->{data} );
		}
	}
}

sub doSetBox { #
	my $self	= shift;
	my $scr		= shift;
	my $color	= shift;
	my $name	= shift;
	my $length	= shift;
	my $data	= shift;#child data 

	$scr->openTable( 2, "bordercolor=#$color border frame=box rules=none" );
	my $total = scalar( @{$data} );
	$scr->doCell( "$total $name", "bgcolor=#$color colspan=2" );
	my $serieN = 0;
	foreach ( @{$data} ) {
		$serieN++;
		$scr->openRow();
		warn $scr->{cCol};
		$scr->openCell();
		warn $scr->{cCol};
		$scr->doCheckBox( $self->{CODE}.'&VALUE&'."$serieN&0", $data->[0]->[0], 1 );
		warn $scr->{cCol};
		warn $scr->{cTag};
		$scr->doCell( $data->[0]->[0] );
	}
	$scr->openRow();
	$scr->openCell();
	$scr->doToolBox( 'id', 16, [ 'gear' ] );
	$scr->openCell();
	$scr->doEdit( "$self->{CODE}&VALUE&0&0", '', $length );
	$scr->closeTable();
}

sub doSetForkBox { #
	my $self	= shift;
	my $scr		= shift;
	my $mem		= $self->{MEM};
	my $child	= $self->{CHILD};
	my $color	= $self->{CONST}->{COLOR_BLUE};
	my $name	= $child->{NAME};
	my $uncles	= $child->{UNCLES};
	my $labels	= $child->{LABELS};
	my $forkPos	= $child->{FORK};
	my $allows	= $child->{ALLOWS};
	my $data	= $self->{CHILD}->{data};
	my $entryN	= 1;
	my $currentValue = 0;
	my $lastValues = {};
	my $forkLabels;
	my $entry;
	my $pos;
	my $link;
	my $fork;
	my $i;
	my $row;
	my $uncle;
	my $size0;
	my $size2;

	( "@{$child->{DISPLAY}}" =~ m/^0=(\d+) 1 2=(\d+)/ ) || $self->{HLP}->suicide();
	$size0	= $1;
	$size2	= $2;
	
	@{$forkLabels} = split(/,/, $labels->[$forkPos] );
	$fork = scalar( @{$forkLabels} );
	$pos = 0;
	$i = 0;
	foreach $entry ( @{$allows} ) {
		if ( $pos == $forkPos ) {
			foreach ( split( /,/, $entry ) ) {
				( $_ eq $i ) || $mem->suicide();
				$i++;
			}
		}
		else {
			length( $entry ) && $mem->suicide( 'not implemented' );
		}
		$pos++;
	}
	( ( $fork ) == $i ) || $mem->suicide( "$fork - $i - $self->{CODE}" );
	( $uncle = $uncles->[0] ) || $mem->suicide(); 

	$scr->openTable( 2, "bordercolor=#$color border frame=box rules=none" );
	$scr->openRow( "bgcolor=#$color" );
	$scr->openCell( 'colspan=2 align=center' );
	$scr->doTxt( "Insert $labels->[0]: " );
	$scr->doEdit( "$self->{CODE}&SEARCH", $self->{data}->{search}, $size0 ); 
	$scr->doToolBox( $self->{CODE}, 16, [ '', 'lookup' ] );
	$scr->doToolBox( 'id', 16, [ '', 'gear' ] );

	foreach $entry ( @{$data} ) {
		if ( $currentValue != $entry->[0] ) {
			while ( $fork < scalar( @{$forkLabels} ) ) {
				$fork && $scr->doTxt( "\n" );
				$scr->doHidden( "$self->{CODE}&VALUE&"."$entryN&0", $currentValue );
				$scr->doHidden( "$self->{CODE}&VALUE&"."$entryN&1", $fork );
				$scr->doEdit( "$self->{CODE}&VALUE&"."$entryN&2", '0', $size2 );
				$entryN++;
				$scr->doTxt( $forkLabels->[$fork] );
				$fork++;
			}
			$fork = 0;
			$lastValues->{$entry->[0]} && $mem->suicide();
			$currentValue = $entry->[0];
			$lastValues->{"$currentValue"} = 1;
			$scr->openRow();
			$scr->openCell();
			$link = '';
			foreach ( @{$mem->entryDefsGet( $uncle, $entry->[0] )} ) {
				if ( $link ) {
					$self->{founds}->{$entry->[0] } && $scr->doTxt( "\n$_" );
				}
				else {
					( $link = $mem->getLink( $uncle, $entry->[0] ) ) ? $scr->doLink( $link, $_ ) : $scr->doTxt( $_ );
					$link = 'ERROR';
				}
			}
			$scr->openCell();
		}
		while ( $fork < $entry->[1] ) {
			$fork && $scr->doTxt( "\n" );
			$scr->doHidden( "$self->{CODE}&VALUE&"."$entryN&0", $currentValue );
			$scr->doHidden( "$self->{CODE}&VALUE&"."$entryN&1", $fork );
			$scr->doEdit( "$self->{CODE}&VALUE&"."$entryN&2", 0, $size2 );
			$entryN++;
			$scr->doTxt( "$forkLabels->[$fork]" );
			$fork++;
		}
		
		$fork && $scr->doTxt( "\n" );
		$scr->doHidden( "$self->{CODE}&VALUE&"."$entryN&0", $currentValue );
		$scr->doHidden( "$self->{CODE}&VALUE&"."$entryN&1", $fork );
		$scr->doEdit( "$self->{CODE}&VALUE&"."$entryN&2", $entry->[2], $size2 );
		$entryN++;
		$scr->doTxt( "$forkLabels->[$fork]" );
		$fork++;
	}
		
	while ( $fork < scalar( @{$forkLabels} ) ) {
		$fork && $scr->doTxt( "\n" );
		$scr->doHidden( "$self->{CODE}&VALUE&"."$entryN&0", $currentValue );
		$scr->doHidden( "$self->{CODE}&VALUE&"."$entryN&1", $fork );
		$scr->doEdit( "$self->{CODE}&VALUE&"."$entryN&2", '0', $size2 );
		$entryN++;
		$scr->doTxt( $forkLabels->[$fork] );
		$fork++;
	}

	foreach $entry ( keys %{$self->{founds}} ) {
		if ( !$lastValues->{$entry} ) {
			$scr->openRow();
			$scr->openCell();
			$link = '';
			foreach( @{$mem->entryDefsGet( $uncle, $entry )} ) {
				if ( $link ) {
					$scr->doTxt( "\n$_" );
				}
				else {
					( $link = $mem->getLink( $uncle, $entry ) ) ? $scr->doLink( $link, $_ ) : $scr->doTxt( $_ );
					$link = 'ERROR';
				}
			}
			$scr->openCell();
			for ( $pos = 0; $pos < scalar( @{$forkLabels} ); $pos++ ) {
				$pos && $scr->doTxt( "\n" );
				$scr->doHidden( "$self->{CODE}&VALUE&"."$entryN&0", $entry );
				$scr->doHidden( "$self->{CODE}&VALUE&"."$entryN&1", $pos );
				$scr->doEdit( "$self->{CODE}&VALUE&"."$entryN&2", '', $size2 );
				$entryN++;
				$scr->doTxt( "$forkLabels->[$pos]" );
			}
		}
	}
	$scr->closeTable();
}

sub doSetUncleBox { #
	my $self	= shift;
	my $scr		= shift;
	my $color	= shift;
	my $name	= shift;
	my $uncle	= shift;
	my $options	= shift; # [ [ id, name ] , ]
	my $data	= shift; # [ [ id, name ] , ]


	$scr->openTable( 2, "bordercolor=#$color border frame=box rules=none" );
	$scr->openCell( "bgcolor=#$color colspan=2" );
	if ( @{$options} ) {
		my $total = scalar( @{$data} );
		$total ? $scr->doTxt( "$name: ( $total )" ) : $scr->doTxt( "$name" );
		$scr->closeCell();
		my $link;
		my $pos = 1;
		foreach ( @{$data} ) {
			$scr->openRow();
			$scr->openCell();
			$scr->doCheckBox( $self->{CODE}.'&VALUE&'."$pos&0", $_->[0], 1 );
			$pos++;
			$scr->openCell();
			( $link = $self->{MEM}->getLink( $uncle, $_->[0] ) ) ? $scr->doLink( $link, $_->[1] ) : $scr->doTxt( $_->[1] );
		}
		$scr->closeRow();
		$scr->openCell();
		$scr->doToolBox( 'id', 16, [ 'gear' ] );
		$scr->openCell();
		$scr->doSelect( "$self->{CODE}&VALUE&0&0", $options, 0 );
	}
	else {
		$scr->doTxt( " no values to select from" );
	}
	$scr->closeTable();
}

sub processForm {
	my $self		= shift;
	my $form		= shift;
	my $submitKey	= shift;
	my $submitValue	= shift;
	my $errors		= shift;#output
	my $warnings	= shift;#output
	my $child		= $self->{CHILD};
	my $entry		= [];
	my $newData		= [];
	my $operation;
	my $tgt;
	my $searchResults;
	my $key;
	my $uncle;
	my $x;
	my $v;
	
	( $operation = shift( @{$submitKey} ) ) || ( $operation = '' );
	
	if( $operation eq 'lookup' ) {
		foreach( @{$child->{UNCLES}} ) { $_ && ( $uncle ? $self->{HLP}->suicide() : ( $uncle = $_ ) ) };
		$uncle || $self->{HLP}->suicide();
		$self->{data}->{search} = $form->{SEARCH};
		$searchResults = $self->{MEM}->entitySearch( $uncle, $self->{data}->{search}, '', $self->{CONST}->{SEARCH_LIMIT}, 'noregex' );
		foreach( @{$searchResults} ) { $self->{founds}->{$_} = 1 };
		( keys( %{$self->{founds}} ) >= $self->{CONST}->{SEARCH_LIMIT} ) && ( push( @{$warnings}, "$child->{NAME}: Please Narrow Query Key" ) );
	}
	elsif( $operation ) {
		$self->{HLP}->suicide( "$operation in not valid operation" );
	}
	
	if( $child->{FLAGS}->{RO} ) {
		$self->{HLP}->copyData( $child->{data}, $newData );
	}
	else {
		foreach $key ( keys %{$form->{VALUE}} ) {
			@{$entry} = @{$child->{DEFAULTS}};
			while ( ( $x, $v ) = each  %{$form->{VALUE}->{"$key"}} ) {
				$entry->[$x] = $v;
			}
			$form->{MAIN} && ( $form->{MAIN} == $key ) && ( $entry->[$child->{MAIN}] = 1 );
			push( @{$newData}, [ @{$entry} ] );
		}	
	}
	$self->{MEM}->childObjUpdate( $child, $newData, $errors, $warnings );
	return '';
}

1;
