# (C) Miguel Godinho de Almeida - miguel@datindex.com 2005
package WebArc::ViewSearchStoich;

use strict;
use warnings;

sub new {
	my $param	= shift;
	my $self	= shift;
	my $class	= ref( $param ) || $param;
	bless( $self, $class );
	
	$self->{data}			|| $self->{HLP}->suicide();
	$self->{CODE}			|| $self->{HLP}->suicide();
	$self->{CHILD}			|| $self->{HLP}->suicide();
	$self->{lists}			|| $self->{HLP}->suicide();
	$self->{ENTITY}			|| $self->{HLP}->suicide();
	
	$self->{MEM}			= $self->{BRO}->{MEM};
	$self->{DBA}			= $self->{MEM}->{DBA};
	$self->{HLP}			= $self->{BRO}->{HLP};
	$self->{CONST}			= $self->{BRO}->{CONST};
	$self->{stoichFounds0}	= [];
	$self->{stoichFounds1}	= [];
	
	my $data = $self->{data};
	
	if( $data->{INIT} ) {
		( $data->{CODE}	eq $self->{CODE} )	|| $self->{HLP}->suicide();
	}
	else {
		$data->{INIT}				= 1;
		$data->{CODE}				= $self->{CODE};
		$data->{stoichSearch0}		= '';
		$data->{stoichSearch1}		= '';
		$data->{stoichSelection0}	= {};
		$data->{stoichSelection1}	= {};	
	}
	return $self;
}

sub printView {
	my $self				= shift;
	my $scr					= shift;		
	my $mem					= $self->{MEM};
	my $data				= $self->{data};
	my $brother				= $self->{CHILD}->{UNCLES}->[0];
	my $founds0_in			= $self->{stoichFounds0};
	my $founds1_in			= $self->{stoichFounds1};
	my $selection0			= $data->{stoichSelection0};
	my $selection1			= $data->{stoichSelection1};
	my $search0				= $data->{stoichSearch0};
	my $search1				= $data->{stoichSearch1};
	my $limit				= $self->{CONST}->{SEARCH_LIMIT};
	my $founds0				= {};
	my $founds1				= {};
	my $list0				= [];
	my $list1				= [];
	my $truncate0			= 0;
	my $truncate1			= 0;
	my $searchFieldLength;
	my $i;
	my $j;
	my $p;
	my $link;
	my $max;
	my $max0;
	my $max1;
	my $row;
	
	( $self->{CHILD}->{DISPLAY}->[0] =~ m/^0=(\d+)$/ ) || $self->{HLP}->suicide( "@{$self->{CHILD}->{DISPLAY}}" );
	$searchFieldLength = $1;
	
	@{$list0} = keys( %{$selection0} );
	@{$list1} = keys( %{$selection1} );
	$founds0_in	|| ( $founds0_in = [] );
	$founds1_in || ( $founds1_in = [] );

	$i = scalar( @{$founds0_in} );
	$j = $limit;
	while( $i && $j ) { 
		$i--;
		$p = $founds0_in->[ $i ];
		$founds0->{$p} = 1;
		unless( $selection0->{$p} ) {
			push( @{$list0}, $p );
			--$j || ( $truncate0 = 1 );
		}
	}

	$i = scalar( @{$founds1_in} );
	$j = $limit;
	while( $i && $j ) {
		$i--;
		$p = $founds1_in->[ $i ];
		$founds1->{"$p"} = 1; 
		unless( $selection1->{$p} ) {
			push( @{$list1}, $p );
			--$j || ( $truncate1 = 1 );
		}
	}
	
	$list0 = $mem->entitySortList( $brother, $list0 );
	$list1 = $mem->entitySortList( $brother, $list1 );

	$max0 = scalar( @{$list0} );
	$max1 = scalar( @{$list1} );
	( $max0 > $max1 ) ? ( $max = $max0 ) : ( $max = $max1 );

	$scr->openTable( 2, 'border=1' );
	$scr->doCell( 'Reactants' );
	$scr->doCell( 'Products' );

	for ( $i=0; $i <= $max; $i++ ) {
		$scr->openRow();
		if ( $i < $max0 ) {
			$scr->openCell();
			$p = $list0->[$i];
			$scr->openTable( 2 );
			$scr->openCell( 'valign=top' );
			$selection0->{$p} ? $scr->doCheckBox( "$self->{CODE}&stoich0", $p, 1 ) : $scr->doCheckBox( "$self->{CODE}&stoich0", $p, 0 );
			$scr->openCell();
			my $link = '';
			foreach ( @{$mem->entryDefsGet( $brother, $p )} ) {
				if ( $link ) {
					$founds0->{$p} && $scr->doTxt( "\n$_" );
				}
				else {
					( $link = $mem->getLink( $brother, $p ) ) ? $scr->doLink( $link, $_ ) : $scr->doTxt( $_ );
					$link = 'ERROR';
				}
			}
			$scr->closeTable();
		}
		elsif ( ( $i == $max0 ) && $truncate0 ) {
			$scr->openCell( 'align=center' );
			$scr->doTxt( '+++ truncated +++' );
		}
		else {
			$scr->openCell();
		}

		if ( $i < $max1 ) {
			$scr->openCell();
			$p = $list1->[$i];
			$scr->openTable( 2 );
			$scr->openCell( 'valign=top' );
			$selection1->{$p} ? $scr->doCheckBox( "$self->{CODE}&stoich1", $p, 1 ) : $scr->doCheckBox( "$self->{CODE}&stoich1", $p, 0 );
			$scr->openCell();
			my $link = '';
			foreach( @{$mem->entryDefsGet( $brother, $p )} ) {
				if ( $link ) {
					$founds1->{$p} && $scr->doTxt( "\n$_" );
				}
				else {
					( $link = $mem->getLink( $brother, $p ) ) ? $scr->doLink( $link, $_ ) : $scr->doTxt( $_ );
					$link = 'ERROR';
				}
			}
			$scr->closeTable();
		}
		elsif ( ( $i == $max1 ) && $truncate1 ) {
			$scr->openCell( 'align=center' );
			$scr->doTxt( '+++ truncated +++' );
		}
		else {
			$scr->openCell();
		}
	}
	
	
	$scr->openRow();
	$scr->openCell( 'align=center' );
	$scr->doEdit( "$self->{CODE}&stoichSearch&0", $search0, $searchFieldLength );
	$scr->openCell( 'align=center' );
	$scr->doEdit( "$self->{CODE}&stoichSearch&1", $search1, $searchFieldLength );
	$scr->openRow();
	$scr->openCell( 'colspan=2 align=center' );
	$scr->doSubmit( "$self->{CODE}&lookupEntity&".$brother, "Lookup $self->{CHILD}->{LABELS}->[0](s)" );
	$scr->closeCell();
	$scr->openRow();
	$scr->openCell( 'colspan=2 align=center' );
	( ( @{$list0} ) || ( @{$list1} ) || $max0 || $max1 ) ? $scr->doSubmit( "$self->{CODE}&findRelations", "Related $self->{ENTITY}->{NAME}(s)" ) : $scr->doSubmit( '', "Related $self->{ENTITY}->{NAME}(s)", 1 );
	$scr->closeRow();
	$scr->closeTable();
}



sub processForm {
	my $self		= shift;
	my $form		= shift;
	my $submitKey	= shift;
	my $submitValue	= shift;
	my $errors		= shift;#output
	my $warnings	= shift;#output
	my $data		= $self->{data};
	my $mem			= $self->{MEM};
	my $lists		= $self->{lists};
	my $foundsHash	= $lists->{founds};
	my $newFounds;
	my $operation;
	my $tgt;
	
	
	defined( $form->{stoichSearch}->{0} ) ? ( $data->{stoichSearch0} = $form->{stoichSearch}->{0} ) : ( $data->{stoichSearch0} = '' );
	defined( $form->{stoichSearch}->{1} ) ? ( $data->{stoichSearch1} = $form->{stoichSearch}->{1} ) : ( $data->{stoichSearch1} = '' );
	
	%{$data->{stoichSelection0}} = ();
	if( ref( $form->{stoich0} ) ) {
		foreach ( @{$form->{stoich0}} ) { $data->{stoichSelection0}->{$_} = 1 };
	}
	elsif( defined( $form->{stoich0} ) ) {
		$data->{stoichSelection0}->{$form->{stoich0}} = 1;
	}
	
	%{$data->{stoichSelection1}} = ();
	if( ref( $form->{stoich1} ) ) {
		foreach ( @{$form->{stoich1}} ) { $data->{stoichSelection1}->{$_} = 1 };
	}
	elsif( defined( $form->{stoich1} ) ) {
		$data->{stoichSelection1}->{$form->{stoich1}} = 1;
	}

	if( $operation = shift( @{$submitKey} ) ) {
		if( $operation eq 'lookupEntity' ) {
			( $tgt = shift( @{$submitKey} ) ) || $self->{HLP}->suicide( $operation );
			$self->{stoichFounds0} = $mem->entitySearch( $tgt, $data->{stoichSearch0}, '', ( $self->{CONST}->{SEARCH_LIMIT} + 1 ), 'noregex' );
			$self->{stoichFounds1} = $mem->entitySearch( $tgt, $data->{stoichSearch1}, '', ( $self->{CONST}->{SEARCH_LIMIT} + 1 ), 'noregex' );
			
		}
		elsif( $operation eq 'findRelations' ) {
			$lists->{closed}	&& $self->{HLP}->suicide();		
			$lists->{page}		= 0;
			%{$foundsHash} 		= ();
			
			$newFounds = $mem->entitySearchByStoich( $self->{CHILD}->{CODE}, $data->{stoichSelection0}, $data->{stoichSelection1} );
			foreach( @{$newFounds} ) { $foundsHash->{$_} = 1 };
		}
		else {
			$self->{HLP}->suicide( $operation ) ;
		}
	}
	
	return '';
}

1;
