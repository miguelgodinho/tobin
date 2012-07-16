# (C) Miguel Godinho de Almeida - miguel@datindex.com 2005
package WebArc::ViewComplex;

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
		$data->{founds}		= {};
		$data->{lstComplex}	= 0;
		$data->{search}		= '';
	}
	return $self;
}

sub printView {
	my $self			= shift;
	my $scr				= shift;
	my $mem				= $self->{MEM};
	my $child			= $self->{CHILD};
	my $search			= $self->{data}->{search};
	my $foundsHash		= $self->{founds};
	my $selComplex		= $self->{complex};
	my $lstComplex		= $self->{data}->{lstComplex};
	my $code			= $self->{CODE};
	my $color			= $self->{CONST}->{COLOR_BLUE};
	my $name			= $child->{NAME};
	my $labels			= $child->{LABELS};
	my $data			= $child->{data};
	my $uncle			= $child->{UNCLES}->[0];	
	my $lastValues		= {};
	my $lastComplexes	= {};
	my $currentComplex	= 0;
	my $entryN			= 1;
	my $searchSize;
	my $link;
	my $txt;
	my $entry;
	my $founds;
	
	#2 REVIEW
	$child->{FLAGS}->{RO} && $self->{HLP}->suicide();
	( "@{$child->{DISPLAY}}" =~ m/^0=(\d+)$/ ) || $self->{HLP}->suicide();
	$searchSize = $1;
	#END
	
	defined( $search )		|| ( $search = '' );
	defined( $selComplex )	|| ( $selComplex = 0 );

	@{$founds} = keys %{$foundsHash};

	$scr->openTable( 2, "bordercolor=#$color border frame=box rules=none" );
	$scr->openRow( "bgcolor=#$color" );
	$scr->openCell();
	$scr->openCell();
	$scr->doTxt( "Insert $labels->[0]: " );
	$scr->doEdit( "$code&SEARCH", $search, $searchSize );
	$scr->doToolBox( $code, 16, [ '', 'lookup', '', 'gear' ] );
	$scr->closeCell();

	foreach $entry ( @{$data} ) {
		if ( $entry->[1] != $currentComplex ) {
			if ( $currentComplex && ( $selComplex == $currentComplex ) ) {
				foreach ( @{$founds} ) {
					unless ( $lastValues->{$_} ) {
						$scr->openRow();
						$scr->openCell( 'width=0' );
						$scr->doHidden( "$code&VALUE&"."$entryN&1", $currentComplex );
						$scr->doCheckBox( "$code&VALUE&"."$entryN&0", $_, 0 );
						$entryN++;
						$scr->openCell();
						my $link = '';
						foreach $txt ( @{$mem->entryDefsGet( $uncle, $_ )} ) {
							if ( $link ) {
								$scr->doTxt( "\n$txt" );
							}
							else {
								( $link = $mem->getLink( $uncle, $_ ) ) ? $scr->doLink( $link, $txt ) : $scr->doTxt( $txt );
								$link = 'ERROR';
							}
						}
					}
				}
				@{$founds} = ();
			}

			%{$lastComplexes} && $scr->closeTable();
			$lastComplexes->{$entry->[1]} && $mem->suicide();
			$lastComplexes->{$currentComplex} = 1;
			$currentComplex = $entry->[1];
			!$selComplex && ( $currentComplex > $lstComplex ) && ( $selComplex = $currentComplex );
			$scr->openRow();
			$scr->openCell( "bgcolor=#$color" );
			( $selComplex == $currentComplex ) ? $scr->doRadio( "$code&COMPLEX", $currentComplex, 1 ) : $scr->doRadio( "$code&COMPLEX", $currentComplex, 0 );
			$scr->openCell();
			$scr->openTable( 2, 'border=1 width=100%' );
			$scr->openCell( 'width=1' ) ;
			%{$lastValues} = ();
		}
		else {
			$scr->doTxt( "\n" );
		}

		if ( %{$lastValues} ) {
			$lastValues->{$entry->[0]} && $mem->suicide();
			$scr->openRow();
			$scr->openCell( 'width=1' );
		}
		$lastValues->{"$entry->[0]"} = 1;
		$scr->doHidden( "$code&VALUE&"."$entryN&1", $currentComplex );
		$scr->doCheckBox( "$code&VALUE&"."$entryN&0", $entry->[0], 1 );
		$entryN++;
		$scr->openCell();
		$link = '';
		foreach $txt ( @{$mem->entryDefsGet( $uncle, $entry->[0] )} ) {
			if ( $link ) {
				( $selComplex == $currentComplex ) && $foundsHash->{$entry->[0]} && $scr->doTxt( "\n$txt " );
			}
			else {
				( $link = $mem->getLink( $uncle, $entry->[0] ) ) ? $scr->doLink( $link, $txt ) : $scr->doTxt( $txt );
				$link = 'ERROR';
			}
		}
	}

	if ( @{$founds} ) {
		if ( !$currentComplex || ( $currentComplex != $selComplex ) ) {
			if ( $currentComplex ) {
				$scr->closeTable();
				$lastComplexes->{"$currentComplex"} = 1;
				$currentComplex = 0;
				%{$lastValues} = ();
			}
			$scr->openRow();
			$scr->openCell( "bgcolor=#$color" );
			if ( $selComplex < 1 ) {
				$scr->doRadio( "$code&COMPLEX", $currentComplex, 1 );
				$selComplex = -1;
			}
			else {
				$scr->doRadio( "$code&COMPLEX", $currentComplex, 0 );
			}
			$scr->openCell();
			$scr->openTable( 2, 'border=1 width=100%' );
		}

		foreach $entry ( @{$founds} ) {
			unless ( $lastValues->{$entry} ) {
				$scr->openRow();
				$scr->openCell( 'width=1' );
				$scr->doHidden( "$code&VALUE&"."$entryN&1", $currentComplex );
				$scr->doCheckBox( "$code&VALUE&"."$entryN&0",, $entry );
				$entryN++;
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
			}
		}
		$lastComplexes->{"$currentComplex"} = 1;
	}
	
	if ( %{$lastComplexes} ) {
		$scr->closeTable();
		$scr->openRow();
		$scr->openCell( "bgcolor=#$color" );
		$selComplex ? $scr->doRadio( "$code&COMPLEX", -1, 0 ) : $scr->doRadio( "$code&COMPLEX", -1, 1 );
		$scr->doCell( "New Complex", "bgcolor=#$color" );
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
	my $founds		= [];
	my $tgt			= '';
	my $operation;
	my $uncle;
	my $key;
	my $x;
	my $v;
	
	$self->{complex} = $form->{COMPLEX};
	defined( $self->{data}->{search} = $form->{SEARCH} ) || ( $self->{data}->{search} = '' );
	
	( $operation = shift( @{$submitKey} ) ) || ( $operation = '' );
		
	if( $operation eq 'lookup' ) {
		if( $tgt ) {
			$self->{HLP}->suicide( $tgt );
#				my $pos;
#				for( $pos = 0; $pos < scalar( @{$child->{LABELS}} ); $pos++ ) {
#					if( $1 eq $child->{LABELS}->[$pos] ) {
#						$uncle && $self->{HLP}->suicide( "@{$child->{LABELS}}" );
#						( $uncle = $child->{UNCLES}->[$pos] ) || $self->{HLP}->suicide();
#					}
#				}
		}
		else {
			foreach( @{$child->{UNCLES}} ) { $_ && ( $uncle ? $self->{HLP}->suicide() : ( $uncle = $_ ) ) };
		}
			
		$uncle || $self->{HLP}->suicide();
		$founds = $self->{MEM}->entitySearch( $uncle, $self->{data}->{search}, '', $self->{CONST}->{SEARCH_LIMIT}, 'noregex' );
		( scalar( @{$founds} ) >= $self->{CONST}->{SEARCH_LIMIT} ) && ( push( @{$warnings}, "$child->{NAME}: Please Narrow Query Key" ) );
		foreach( @{$founds} ) { $self->{founds}->{$_} = 1 };
	}
	
	if( $child->{FLAGS}->{RO} ) {
		$self->{HLP}->copyData( $child->{data}, $newData );
	}
	else {
		foreach $key ( keys %{$form->{VALUE}} ) {
			@{$entry} = @{$child->{DEFAULTS}};
			while ( ( $x, $v ) = each %{$form->{VALUE}->{$key}} ) {
				$entry->[$x] = $v;
				( $x == 1 ) && ( $v > $self->{data}->{lstComplex} ) && ( $self->{data}->{lstComplex} = $v );
			}
			push( @{$newData}, [ @{$entry} ] );
		}	
	}
	$self->{MEM}->childObjUpdate( $child, $newData, $errors );
	return "";
}

1;
