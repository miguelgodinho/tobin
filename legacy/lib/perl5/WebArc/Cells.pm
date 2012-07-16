# (C) Miguel Godinho de Almeida - miguel@datindex.com 2004
package WebArc::Cells;

use strict;
use warnings;

sub new {
	my $param	= shift;
	my $self	= shift;
	my $class	= ref( $param ) || $param;
	bless( $self, $class );
	$self->{MEM} || die;
	$self->{HLP} || die;
	return $self;
}

#sub doSetsSelectionBox {
#	my $self	= shift;
#	my $scr		= shift;
#	my $type	= shift;
#	my $data	= shift;
#	my $code	= shift;
#	my $length	= shift;
#
#	$scr->openTable( 4 );
#	$scr->doCell( 'Set Name', 'align=center' );
#	$scr->doCell( 'User', 'align=center' );
#	$scr->doCell( 'Date', 'align=center' );
#	$scr->doCell( 'Action', 'align=center' );
#	if ( $length ) {
#		$scr->openRow();
#		$scr->openCell();
#		$scr->doEdit( 'set&0&def', '', $length ) ;
#		$scr->openCell();
#		$scr->doSelect( 'set&0&user', [ [ $self->{USR}, $self->{MEM}->userNameGet( $self->{USR} ) ], [ $self->{MEM}->{USER_PUB}, 'pub' ] ], $self->{USR} );
#		$scr->doCell( '-', 'align=center' );
#		$scr->openCell();
#		$scr->doToolBox( $code, 16, [ '', '', '', '', '', 'save' ] );
#	}
#
#	foreach ( @{$data} ) {
#		$scr->openRow();
#		$scr->openCell();
#		$scr->doLink( '?app=edi'.$_->[0].$type, $_->[1] );
#		$scr->doCell( $self->{MEM}->userNameGet( $_->[2] ) );
#		$scr->doCell( $_->[3] );
#		$scr->openCell();
#		$length ? $scr->doToolBox( "$code&".$_->[0], 16, [ '', 'arrowup', '', 'recycle', 'garbage' ] ) : $scr->doToolBox( "$code&".$_->[0], 16, [ '', 'arrowup', '', 'recycle' ] );
#	}
#	$scr->closeTable();
#}

#sub doStoichBox {
#	my $self				= shift;
#	my $scr					= shift;
#	my $searchFieldLength	= shift;
#	my $name				= shift;
#	my $labels				= shift;
#	my $brother				= shift;
#	my $founds0_in			= shift;
#	my $founds1_in			= shift;
#	my $selection0			= shift;
#	my $selection1			= shift;
#	my $search0				= shift;
#	my $search1				= shift;
#	my $limit				= shift;
#	my $mem					= $self->{MEM};
#	my $founds0				= {};
#	my $founds1				= {};
#	my $truncate0			= 0;
#	my $truncate1			= 0;
#	my $list0;
#	my $list1;
#	my $i;
#	my $j;
#	my $p;
#	my $link;
#	my $max;
#	my $max0;
#	my $max1;
#	
#	@{$list0} = ( keys %{$selection0} );
#	@{$list1} = ( keys %{$selection1} );
#	$founds0_in	|| ( $founds0_in = [] );
#	$founds1_in || ( $founds1_in = [] );
#
#	$i = scalar( @{$founds0_in} );
#	$j = $limit;
#	while ( $i && $j ) { 
#		$i--;
#		$p = $founds0_in->[ $i ];
#		$founds0->{"$p"} = 1;
#		unless ( $selection0->{$p} ) {
#			push( @{$list0}, $p );
#			--$j || ( $truncate0 = 1 );
#		}
#	}
#
#	$i = scalar( @{$founds1_in} );
#	$j = $limit;
#	while ( $i && $j ) {
#		$i--;
#		$p = $founds1_in->[ $i ];
#		$founds1->{"$p"} = 1; 
#		unless ( $selection1->{$p} ) {
#			push( @{$list1}, $p );
#			--$j || ( $truncate1 = 1 );
#		}
#	}
#	
#	@{$list0} = $mem->entitySortList( $brother, $list0 );
#	@{$list1} = $mem->entitySortList( $brother, $list1 );
#
#	$max0 = scalar( @{$list0} );
#	$max1 = scalar( @{$list1} );
#	( $max0 > $max1 ) ? ( $max = $max0 ) : ( $max = $max1 );
#
#	$scr->openTable( 2, 'border=1' );
#	$scr->doCell( 'Reactants' );
#	$scr->doCell( 'Products' );
#
#	for ( $i=0; $i <= $max; $i++ ) {
#		$scr->openRow();
#		if ( $i < $max0 ) {
#			$scr->openCell();
#			$p = $list0->[$i];
#			$scr->openTable( 2 );
#			$scr->openCell( 'valign=top' );
#			$selection0->{$p} ? $scr->doCheckBox( 'stoich0', $p, 1 ) : $scr->doCheckBox( 'stoich0', $p, 0 );
#			$scr->openCell();
#			my $link = '';
#			foreach ( $mem->entryDefsGet( $brother, $p ) ) {
#				if ( $link ) {
#					$founds0->{$p} && $scr->doTxt( "\n$_" );
#				}
#				else {
#					( $link = $mem->getLink( $brother, $p ) ) ? $scr->doLink( $link, $_ ) : $scr->doTxt( $_ );
#					$link = 'ERROR';
#				}
#			}
#			$scr->closeTable();
#		}
#		elsif ( ( $i == $max0 ) && $truncate0 ) {
#			$scr->openCell( 'align=center' );
#			$scr->doTxt( '+++ truncated +++' );
#		}
#		else {
#			$scr->openCell();
#		}
#
#		if ( $i < $max1 ) {
#			$scr->openCell();
#			$p = $list1->[$i];
#			$scr->openTable( 2 );
#			$scr->openCell( 'valign=top' );
#			$selection1->{$p} ? $scr->doCheckBox( 'stoich1', $p, 1 ) : $scr->doCheckBox( 'stoich1', $p, 0 );
#			$scr->openCell();
#			my $link = '';
#			foreach ( $mem->entryDefsGet( $brother, $p ) ) {
#				if ( $link ) {
#					$founds1->{$p} && $scr->doTxt( "\n$_" );
#				}
#				else {
#					( $link = $mem->getLink( $brother, $p ) ) ? $scr->doLink( $link, $_ ) : $scr->doTxt( $_ );
#					$link = 'ERROR';
#				}
#			}
#			$scr->closeTable();
#		}
#		elsif ( ( $i == $max1 ) && $truncate1 ) {
#			$scr->openCell( 'align=center' );
#			$scr->doTxt( '+++ truncated +++' );
#		}
#		else {
#			$scr->openCell();
#		}
#	}
#	$scr->openRow();
#	$scr->openCell( 'align=center' );
#	$scr->doEdit( 'stoichSearch&0', $search0, $searchFieldLength );
#	$scr->openCell( 'align=center' );
#	$scr->doEdit( 'stoichSearch&1', $search1, $searchFieldLength );
#	$scr->openRow();
#	$scr->openCell( 'colspan=2 align=center' );
#	$scr->doSubmit( "stoich&".$brother."&lookup;", "Lookup $labels(s)" );
#	$scr->closeCell();
#	$scr->openRow();
#	$scr->openCell( 'colspan=2 align=center' );
#	( ( @{$list0} ) || ( @{$list1} ) || $max0 || $max1 ) ? $scr->doSubmit( 'stoichR', "Related $name(s)" ) : $scr->doSubmit( '', "Related $name(s)", 1 );
#	$scr->closeRow();
#	$scr->closeTable();
#}

#sub doComplexBox { #
#	my $self	= shift;
#	my $scr		= shift;
#	my $code	= shift;
#	my $color	= shift;
#	my $uncle	= shift;
#	my $name	= shift;
#	my $labels	= shift;
#	my $search	= shift;
#	my $length	= shift;
#	my $foundsHash	= shift;
#	my $selComplex	= shift;
#	my $lastComplex	= shift;
#	my $data	= shift; #child data
#
#	my $mem = $self->{MEM};
#
#	my $currentComplex	= 0;
#	my $lastComplexes	= {};
#	my $lastValues		= {};
#	my $txt;
#	my $entry;
#	my $entryN		= 1;
#	my $founds;
#	@{$founds} = keys %{$foundsHash};
#
#	$scr->openTable( 2, "bordercolor=#$color border frame=box rules=none" );
#	$scr->openRow( "bgcolor=#$color" );
#	$scr->openCell();
#	$scr->openCell();
#	$scr->doTxt( "Insert $labels->[0]: " );
#	$scr->doEdit( $code.'&SEARCH', $search, $length );
#	$scr->doToolBox( $code, 16, [ '', 'lookup' ] );
#	$scr->doToolBox( 'id', 16, [ '', 'gear' ] );
#	$scr->closeCell();
#
#	foreach $entry ( @{$data} ) {
#		if ( $entry->[1] != $currentComplex ) {
#			if ( $currentComplex && ( $selComplex == $currentComplex ) ) {
#				foreach ( @{$founds} ) {
#					unless ( $lastValues->{$_} ) {
#						$scr->openRow();
#						$scr->openCell( 'width=0' );
#						$scr->doHidden( "$code&VALUE&"."$entryN&1", $currentComplex );
#						$scr->doCheckBox( "$code&VALUE&"."$entryN&0", $_, 0 );
#						$entryN++;
#						$scr->openCell();
#						my $link = '';
#						foreach $txt ( $mem->entryDefsGet( $uncle, $_ ) ) {
#							if ( $link ) {
#								$scr->doTxt( "\n$txt" );
#							}
#							else {
#								( $link = $mem->getLink( $uncle, $_ ) ) ? $scr->doLink( $link, $txt ) : $scr->doTxt( $txt );
#								$link = 'ERROR';
#							}
#						}
#					}
#				}
#				@{$founds} = ();
#			}
#
#			%{$lastComplexes} && $scr->closeTable();
#			$lastComplexes->{$entry->[1]} && $mem->suicide();
#			$lastComplexes->{"$currentComplex"} = 1;
#			$currentComplex = $entry->[1];
#			!$selComplex && ( $currentComplex > $lastComplex ) && ( $selComplex = $currentComplex );
#			$scr->openRow();
#			$scr->openCell( "bgcolor=#$color" );
#			( $selComplex == $currentComplex ) ? $scr->doRadio( "$code&COMPLEX", $currentComplex, 1 ) : $scr->doRadio( "$code&COMPLEX", $currentComplex, 0 );
#			$scr->openCell();
#			$scr->openTable( 2, 'border=1 width=100%' );
#			$scr->openCell( 'width=1' ) ;
#			%{$lastValues} = ();
#		}
#		else {
#			$scr->doTxt( "\n" );
#		}
#
#		if ( %{$lastValues} ) {
#			$lastValues->{$entry->[0]} && $mem->suicide();
#			$scr->openRow();
#			$scr->openCell( 'width=1' );
#		}
#		$lastValues->{"$entry->[0]"} = 1;
#		$scr->doHidden( "$code&VALUE&"."$entryN&1", $currentComplex );
#		$scr->doCheckBox( "$code&VALUE&"."$entryN&0", $entry->[0], 1 );
#		$entryN++;
#		$scr->openCell();
#		my $link = '';
#		foreach $txt ( $mem->entryDefsGet( $uncle, $entry->[0] ) ) {
#			if ( $link ) {
#				( $selComplex == $currentComplex ) && $foundsHash->{$entry->[0]} && $scr->doTxt( "\n$txt " );
#			}
#			else {
#				( $link = $mem->getLink( $uncle, $entry->[0] ) ) ? $scr->doLink( $link, $txt ) : $scr->doTxt( $txt );
#				$link = 'ERROR';
#			}
#		}
#	}
#
#	if ( @{$founds} ) {
#		if ( !$currentComplex || ( $currentComplex != $selComplex ) ) {
#			if ( $currentComplex ) {
#				$scr->closeTable();
#				$lastComplexes->{"$currentComplex"} = 1;
#				$currentComplex = 0;
#				%{$lastValues} = ();
#			}
#			$scr->openRow();
#			$scr->openCell( "bgcolor=#$color" );
#			if ( $selComplex < 1 ) {
#				$scr->doRadio( "$code&COMPLEX", $currentComplex, 1 );
#				$selComplex = -1;
#			}
#			else {
#				$scr->doRadio( "$code&COMPLEX", $currentComplex, 0 );
#			}
#			$scr->openCell();
#			$scr->openTable( 2, 'border=1 width=100%' );
#		}
#
#		foreach $entry ( @{$founds} ) {
#			unless ( $lastValues->{$entry} ) {
#				$scr->openRow();
#				$scr->openCell( 'width=1' );
#				$scr->doHidden( "$code&VALUE&"."$entryN&1", $currentComplex );
#				$scr->doCheckBox( "$code&VALUE&"."$entryN&0",, $entry );
#				$entryN++;
#				$scr->openCell();
#				my $link = '';
#				foreach ( $mem->entryDefsGet( $uncle, $entry ) ) {
#					if ( $link ) {
#						$scr->doTxt( "\n$_" );
#					}
#					else {
#						( $link = $mem->getLink( $uncle, $entry ) ) ? $scr->doLink( $link, $_ ) : $scr->doTxt( $_ );
#						$link = 'ERROR';
#					}
#				}
#			}
#		}
#		$lastComplexes->{"$currentComplex"} = 1;
#	}
#	
#	if ( %{$lastComplexes} ) {
#		$scr->closeTable();
#		$scr->openRow();
#		$scr->openCell( "bgcolor=#$color" );
#		$selComplex ? $scr->doRadio( "$code&COMPLEX", -1, 0 ) : $scr->doRadio( "$code&COMPLEX", -1, 1 );
#		$scr->doCell( "New Complex", "bgcolor=#$color" );
#	}
#	$scr->closeTable();
#}

#sub doErrorsBox {#
#	my $self	= shift;
#	my $scr		= shift;
#	my $color	= shift;
#	my $errors	= shift;
#
#	if ( @{$errors} ) {
#		$scr->openTable( 1, "bordercolor=#$color border frame=box rules=none width=100%" );
#		$scr->doCell( "Errors:", "bgcolor=#$color" );
#		foreach ( @{$errors} ) { $scr->doLine( "$_", [ 'BOLD' ] ) }; 
#		$scr->closeTable();
#		return 1;
#	}
#	return 0;
#}

#sub doHistoryBox {#
#	my $self	= shift;
#	my $scr		= shift;
#	my $color	= shift;
#	my $history	= shift;
#
#	if ( @{$history} ) {
#		$scr->openTable( 1, "bordercolor=#$color border frame=box rules=none" );
#		$scr->doCell( "History Log:", "bgcolor=#$color" );
#		foreach ( @{$history} ) { $scr->doLine( $_ ) };
#		$scr->closeTable();
#		return 1;
#	}
#	return 0;
#}

#sub doIDCell {#
#	my $self	= shift;
#	my $scr		= shift;
#	my $color	= shift;
#	my $id		= shift;
#	my $name	= shift;
#	my $saved	= shift;
#
#	$scr->openCell( "align=left valign=middle bgcolor=#$color" );
#	if ( $id ) {
#		$scr->doTxt( "$name $id" );
#		$scr->doToolBox( 'id', 16, [ '', 'gear', '', 'recycle', '', 'save', '', 'garbage' ] );
#		$saved || $scr->doTxt( ' ** unsaved changes **' );
#	}
#	else {
#		$scr->doTxt( "[ Unsaved $name ]" );
#		$scr->doToolBox( 'id', 16, [ '', 'gear', '', '', 'save' ] );
#	}
#	$scr->closeCell();
#	return 1;
#}

#sub doLinkBox { #
#	my $self	= shift;
#	my $scr		= shift;
#	my $code	= shift;
#	my $color	= shift;
#	my $name	= shift;
#	my $labels	= shift;
#	my $length	= shift;
#	my $options	= shift; # [ [ id, user ] , ]
#	my $default	= shift;
#	my $data	= shift; # [ [ link, uid, username ] , ]
#
#
#	$scr->openTable( 3, "bordercolor=#$color border frame=box rules=none" );
#	$scr->openRow( "bgcolor=#$color" );
#	$scr->openCell( 'colspan=3' );
#	if ( @{$options} ) {
#		my $total = scalar( @{$data} );
#		$scr->doTxt( "$total $name:" );
#		$scr->closeCell();
#		$scr->openRow();
#		$scr->openCell();
#		$scr->doCell( $labels->[1], 'align=center' );
#		$scr->doCell( $labels->[0], 'align=center' );
#		$scr->closeRow();
#		if ( @{$data} ) {
#			$scr->openRow( "bgcolor=#$color" );
#			$scr->openCell( 'colspan=3' );
#			$scr->closeRow();
#			my $link;
#			my $pos = 0;
#			foreach ( @{$data} ) {
#				$pos++;
#				$scr->openRow();
#				$scr->openCell();
#				$scr->doCheckBox( $code.'&VALUE&'."$pos&0", $_->[0], 1 );
#				$scr->openCell();
#				$scr->doHidden( $code.'&VALUE&'."$pos&1", $_->[1] );
#				$scr->doTxt( $_->[2] );
#				$scr->openCell();
#				( $link = $self->{MEM}->getLink( $_->[1], $_->[0] ) ) ? $scr->doLink( $link, $_->[0] ) : $scr->doTxt( $_->[0] );
#			}
#		}
#		$scr->closeRow();
#		$scr->openRow( "bgcolor=#$color" );
#		$scr->openCell( 'colspan=3' );
#		$scr->closeRow();
#		$scr->openCell();
#		$scr->doToolBox( 'id', 16, [ 'gear' ] );
#		$scr->openCell();
#		$scr->doSelect( $code."&VALUE&0&1", $options, $default );
#		$scr->openCell();
#		$scr->doEdit( $code."&VALUE&0&0", '', $length ); 
#	}
#	else {
#		$scr->doTxt( " No Users to Assign $name" );
#	}
#	$scr->closeTable();
#}



#sub doSerieBox { #
#	my $self	= shift;
#	my $scr		= shift;
#	my $code	= shift;
#	my $color	= shift;
#	my $name	= shift;
#	my $length	= shift;
#	my $serial	= shift;
#	my $main	= shift;
#	my $data	= shift; #child->{data} 
#
#	my $cols;
#	$main ? ( $cols = 2 ) : ( $cols = 1 ); 
#	$scr->openTable( $cols, "bordercolor=#$color border frame=box rules=none" );
#	$scr->openRow( "bgcolor=#$color" );
#	my $total = scalar( @{$data} );
#	$cols ? $scr->doCell( "$total $name:", "colspan=$cols" ) : $scr->doCell( "$total $name: " );
#	my $serieN = 0;
#	my $noMain = 1;
#	foreach ( @{$data} ) {
#		$serieN++;
#		$scr->openRow();
#		$scr->openCell();
#		if ( $main ) {
#			$_->[$main] && ( $noMain ? ( $noMain = 0 ) : $self->{MEM}->suicide() );
#			$scr->doRadio( $code."&MAIN", $_->[$serial], $_->[$main] );
#			$scr->openCell();
#		}
#		$scr->doHidden( $code.'&VALUE&'."$serieN&".$serial, $_->[$serial] );
#		$scr->doEdit( $code.'&VALUE&'."$serieN&0", $_->[0], $length );
#	}
#	$scr->openRow();
#	$scr->openCell();
#	if ( $main ) {
#		$scr->doRadio( $code."&MAIN", 0, $noMain );
#		$scr->openCell();
#	}
#	$scr->doHidden( $code.'&VALUE&0&'.$serial, 0);
#	$scr->doEdit( $code.'&VALUE&0&0', '', $length );
#	$scr->closeTable();
#}

#sub doSetBox { #
#	my $self	= shift;
#	my $scr		= shift;
#	my $code	= shift;
#	my $color	= shift;
#	my $name	= shift;
#	my $length	= shift;
#	my $data	= shift;#child data 
#
#	$scr->openTable( 2, "bordercolor=#$color border frame=box rules=none" );
#	my $total = scalar( @{$data} );
#	$scr->doCell( "$total $name", "bgcolor=#$color colspan=2" );
#	my $serieN = 0;
#	foreach ( @{$data} ) {
#		$serieN++;
#		$scr->openRow();
#		warn $scr->{cCol};
#		$scr->openCell();
#		warn $scr->{cCol};
#		$scr->doCheckBox( $code.'&VALUE&'."$serieN&0", $data->[0]->[0], 1 );
#		warn $scr->{cCol};
#		warn $scr->{cTag};
#		$scr->doCell( $data->[0]->[0] );
#	}
#	$scr->openRow();
#	$scr->openCell();
#	$scr->doToolBox( 'id', 16, [ 'gear' ] );
#	$scr->openCell();
#	$scr->doEdit( $code.'&VALUE&0&0', '', $length );
#	$scr->closeTable();
#}

#sub doSetForkBox { #
#	my $self	= shift;
#	my $scr		= shift;
#	my $code	= shift;
#	my $color	= shift;
#	my $name	= shift;
#	my $uncles	= shift;
#	my $size0	= shift;
#	my $size2	= shift;
#	my $labels	= shift;
#	my $forkPos	= shift;
#	my $allows	= shift;
#	my $search	= shift;
#	my $founds	= shift;
#	my $data	= shift;
#	
#	my $entryN = 1;
#	my $currentValue = 0;
#	my $lastValues = {};
#	my $forkLabels;
#	my $entry;
#	my $pos;
#	my $link;
#	my $fork;
#	my $i;
#	my $uncle;
#	my $mem	= $self->{MEM};
#
#	@{$forkLabels} = split(/,/, $labels->[$forkPos] );
#	$fork = scalar( @{$forkLabels} );
#	$pos = 0;
#	$i = 0;
#	foreach $entry ( @{$allows} ) {
#		if ( $pos == $forkPos ) {
#			foreach ( split( /,/, $entry ) ) {
#				( $_ eq $i ) || $mem->suicide();
#				$i++;
#			}
#		}
#		else {
#			length( $entry ) && $mem->suicide( 'not implemented' );
#		}
#		$pos++;
#	}
#	( ( $fork ) == $i ) || $mem->suicide( "$fork - $i - $code" );
#	( $uncle = $uncles->[0] ) || $mem->suicide(); 
#
#	$scr->openTable( 2, "bordercolor=#$color border frame=box rules=none" );
#	$scr->openRow( "bgcolor=#$color" );
#	$scr->openCell( 'colspan=2 align=center' );
#	$scr->doTxt( "Insert $labels->[0]: " );
#	$scr->doEdit( "$code&SEARCH", $search, $size0 ); 
#	$scr->doToolBox( $code, 16, [ '', 'lookup' ] );
#	$scr->doToolBox( 'id', 16, [ '', 'gear' ] );
#
#	foreach $entry ( @{$data} ) {
#		if ( $currentValue != $entry->[0] ) {
#			while ( $fork < scalar( @{$forkLabels} ) ) {
#				$fork && $scr->doTxt( "\n" );
#				$scr->doHidden( "$code&VALUE&"."$entryN&0", $currentValue );
#				$scr->doHidden( "$code&VALUE&"."$entryN&1", $fork );
#				$scr->doEdit( "$code&VALUE&"."$entryN&2", '0', $size2 );
#				$entryN++;
#				$scr->doTxt( $forkLabels->[$fork] );
#				$fork++;
#			}
#			$fork = 0;
#			$lastValues->{$entry->[0]} && $mem->suicide();
#			$currentValue = $entry->[0];
#			$lastValues->{"$currentValue"} = 1;
#			$scr->openRow();
#			$scr->openCell();
#			$link = '';
#			foreach ( $mem->entryDefsGet( $uncle, $entry->[0] ) ) {
#				if ( $link ) {
#					$founds->{$entry->[0] } && $scr->doTxt( "\n$_" );
#				}
#				else {
#					( $link = $mem->getLink( $uncle, $entry->[0] ) ) ? $scr->doLink( $link, $_ ) : $scr->doTxt( $_ );
#					$link = 'ERROR';
#				}
#			}
#			$scr->openCell();
#		}
#		while ( $fork < $entry->[1] ) {
#			$fork && $scr->doTxt( "\n" );
#			$scr->doHidden( "$code&VALUE&"."$entryN&0", $currentValue );
#			$scr->doHidden( "$code&VALUE&"."$entryN&1", $fork );
#			$scr->doEdit( "$code&VALUE&"."$entryN&2", 0, $size2 );
#			$entryN++;
#			$scr->doTxt( "$forkLabels->[$fork]" );
#			$fork++;
#		}
#		
#		$fork && $scr->doTxt( "\n" );
#		$scr->doHidden( "$code&VALUE&"."$entryN&0", $currentValue );
#		$scr->doHidden( "$code&VALUE&"."$entryN&1", $fork );
#		$scr->doEdit( "$code&VALUE&"."$entryN&2", $entry->[2], $size2 );
#		$entryN++;
#		$scr->doTxt( "$forkLabels->[$fork]" );
#		$fork++;
#	}
#		
#	while ( $fork < scalar( @{$forkLabels} ) ) {
#		$fork && $scr->doTxt( "\n" );
#		$scr->doHidden( "$code&VALUE&"."$entryN&0", $currentValue );
#		$scr->doHidden( "$code&VALUE&"."$entryN&1", $fork );
#		$scr->doEdit( "$code&VALUE&"."$entryN&2", '0', $size2 );
#		$entryN++;
#		$scr->doTxt( $forkLabels->[$fork] );
#		$fork++;
#	}
#
#	foreach $entry ( keys %{$founds} ) {
#		if ( !$lastValues->{$entry} ) {
#			$scr->openRow();
#			$scr->openCell();
#			$link = '';
#			foreach ( $mem->entryDefsGet( $uncle, $entry ) ) {
#				if ( $link ) {
#					$scr->doTxt( "\n$_" );
#				}
#				else {
#					( $link = $mem->getLink( $uncle, $entry ) ) ? $scr->doLink( $link, $_ ) : $scr->doTxt( $_ );
#					$link = 'ERROR';
#				}
#			}
#			$scr->openCell();
#			for ( $pos = 0; $pos < scalar( @{$forkLabels} ); $pos++ ) {
#				$pos && $scr->doTxt( "\n" );
#				$scr->doHidden( "$code&VALUE&"."$entryN&0", $entry );
#				$scr->doHidden( "$code&VALUE&"."$entryN&1", $pos );
#				$scr->doEdit( "$code&VALUE&"."$entryN&2", '', $size2 );
#				$entryN++;
#				$scr->doTxt( "$forkLabels->[$pos]" );
#			}
#		}
#	}
#	$scr->closeTable();
#}

#sub doSetPageLinkBox { #
#	my $self	= shift;
#	my $scr		= shift;
#	my $code	= shift;
#	my $color	= shift;
#	my $cols	= shift;
#	my $name	= shift;
#	my $uncle	= shift;
#	my $initial	= shift;
#	my $last	= shift;
#	my $total	= shift;
#	my $data	= shift; # [ [ id, ... ] ]
#	my $a_flags	= shift;
#	
#	my $mem = $self->{MEM};
#	my $flag;
#	
#	foreach ( @{$a_flags} ) {
#		( $_ eq 'NOCARDINAL' ) ||
#		( $_ eq 'PROCESS' ) ||
#		$mem->suicide( $_ );
#		$flag->{"$_"} = 1;
#	}
#
#	my $entry;
#
#	my $link;
#	my $txt;
#	my $i = ( $initial + 1 );
#
#	my $shown = scalar ( @{$data} );
#	$scr->openTable( $cols, "bordercolor=#$color border frame=box rules=none" );
#	$scr->openCell( "bgcolor=#$color colspan=$cols" );
#	if ( $flag->{NOCARDINAL} ) {
#		$scr->doTxt( "$name" );
#	}
#	else {
#		( $shown == $total ) ? $scr->doTxt( "$total $name" ) : $scr->doTxt( "$shown $name [$i..$last] of $total" );
#	}
#	if ( $initial ) {
#		( $last == $total ) ? $scr->doToolBox( $code, 16, [ '', 'left', '', '' ] ) : $scr->doToolBox( $code, 16, [ '', 'left', '', 'right' ] );
#	}
#	else {
#		( $last == $total ) || $scr->doToolBox( $code, 16, [ '', '', '', 'right' ] );
#	}
#
#	$flag->{PROCESS} && $scr->doToolBox( $code, 16, [ '', 'gear' ] );
#
#	foreach $entry ( @{$data} ) {
#		$txt = undef;;
#		$scr->openRow();
#		foreach ( @{$entry} ) {
#			if ( defined ( $txt ) ) {
#				$scr->doCell( $_ );
#			}
#			else {
#				$scr->openCell();
#				( defined ( $txt = $mem->entryDefsGet( $uncle, $_, [ 'MAIN' ] ) ) && length( $txt ) ) || ( $txt = $_ );
#	
#				( $link = $mem->getLink( $uncle, $_ ) ) ? $scr->doLink( $link, $txt ) : $scr->doTxt( $txt );
#			}
#		}
#	}
#	$scr->closeTable();
#}

#sub doSetPageMainBox { #
#	my $self	= shift;
#	my $scr		= shift;
#	my $code	= shift;#usually 'child&xxx0y'
#	my $color	= shift;
#	my $name	= shift;
#	my $labels	= shift;
#	my $fields	= shift;
#	my $display	= shift;
#	my $uncle	= shift;
#	my $setsP	= shift;
#	my $setsD	= shift;
#	my $initial	= shift;
#	my $last	= shift;
#	my $total	= shift;
#	my $mainID	= shift;
#	my $data	= shift; # [ [ x0, x1, ... ] ... ]
#	
#	my $mem = $self->{MEM};
#	my $mainPos = '';
#	my $entry;
#	my $length = {};
#	my $orderedFields = [];
#	foreach ( @{$display} ) {
#		if ( m/^(\d)$/ ) {
#			if ( $1 ) {
#				( $fields->[$1] eq 'MAIN' ) ? ( $mainPos = $1 ) : $mem->suicide();
#			}
#			else {
#				push( @{$orderedFields}, 0 );
#			}
#		}
#		elsif( m/^(\d+)=(\d+)$/ ) {
#			( $1 && ( $fields->[$1] eq 'VALUE' ) ) || $mem->suicide();
#			$length->{"$1"} = $2;
#			push( @{$orderedFields}, $1 );
#		}
#		else {
#			$self->{HLP}->suicide( $_ );
#		}
#	}
#	( $mainPos && ( $display->[0] eq $mainPos ) ) || $mem->suicide();
#
#	my $cols = scalar( @{$orderedFields} ) + 1;
#	my $shown = scalar( @{$data} );
#	my $i = ( $initial + 1 );
#
#	$scr->openTable( $cols, "bordercolor=#$color border frame=box rules=none" );
#	$scr->openCell( "bgcolor=#$color colspan=$cols" );
#	( $shown == $total ) ? $scr->doTxt( "$total $name" ) : $scr->doTxt( "$shown $name [$i..$last] of $total" );
#		
#	if ( $initial ) {
#		( $last == $total ) ? $scr->doToolBox( $code, 16, [ '', 'left', '', '' ] ) : $scr->doToolBox( $code, 16, [ '', 'left', '', 'right' ] );
#	}
#	else {
#		( $last == $total ) || $scr->doToolBox( $code, 16, [ '', '', '', 'right' ] );
#	}
#
#
#	if ( @{$data} ) {
#		$scr->openRow();
#		$scr->doCell( $labels->[$mainPos], 'align=center' );
#		foreach ( @{$orderedFields} ) { $scr->doCell( $labels->[$_], 'align=center' ) };
#
#		my $pos;
#		my $link;
#		my $txt;
#		my $serialN = 0;
#		foreach ( @{$data} ) {
#			$serialN++;
#			$scr->openRow();
#			$scr->openCell();
#			$scr->doRadio( "$code&MAIN", $serialN, $_->[$mainPos] );
#			foreach $pos ( @{$orderedFields} ) {
#				$scr->openCell( 'align=left' );
#				if ( $pos ) {
#					$scr->doEdit( "$code&VALUE&"."$serialN&".$pos, $_->[$pos], $length->{$pos} );
#				}
#				else {
#					$scr->doHidden( "$code&VALUE&"."$serialN&0", $_->[0] );
#					$txt = $mem->entryDefsGet( $uncle, $_->[0], [ 'MAIN' ] );
#					( $link = $mem->getLink( $uncle, $_->[0] ) ) ? $scr->doLink( $link, $txt ) : $scr->doTxt( $txt );
#				}
#			}
#		}
#		if ( $shown != $total ) {
#			$scr->openRow( "bgcolor=#$color" );
#			$scr->openCell( "align=center colspan=$cols" );
#			$scr->doTxt( "Go to 1, ..." );
#			$mainID || $scr->doTxt( ", $labels->[$mainPos]" );
#		}
#	}
#
#	if ( $setsP ) {
#		if ( @{$setsD} ) {
#			$scr->openRow();
#			$scr->openRow( "bgcolor=#$color" );
#			$scr->openCell( "align=right colspan=$cols" );
#			$scr->doToolBox( $code, 16, [ 'redx' ] );
#			$scr->openRow();
#			$scr->openCell( "colspan=$cols" );
#			$self->doSetsSelectionBox( $scr, $setsP, $setsD, "$code&sets&".$uncle, 0 );
#		}
#		else {
#			$scr->openRow();
#			$scr->openRow( "bgcolor=#$color" );
#			$scr->openCell( "align=right colspan=$cols" );
#			$scr->doToolBox( $code, 16, [ 'loadset' ] );
#		}
#	}
#	$scr->closeTable();
#}

#sub doSetPageBox { #
#	my $self		= shift;
#	my $scr			= shift;
#	my $code		= shift;#usually 'child&xxx0y'
#	my $color		= shift;
#	my $name		= shift;
#	my $display		= shift;
#	my $uncles		= shift;
#	my $search		= shift;
#	my $setsP		= shift;
#	my $setsD		= shift;
#	my $initial		= shift;
#	my $last		= shift;
#	my $total		= shift;
#	my $pageSel		= shift;
#	my $totalSel	= shift;
#	my $data		= shift; # [ [ sel, found, x0, ... ], ]
#	my $mem 		= $self->{MEM};
#	my $shown 		= scalar( @{$data} );
#	my $i 			= ( $initial + 1 );
#	my $lengths		= {};
#	my $curField	= 0;
#	my $columns		= scalar( @{$display} );
#	my $serialN		= 0;
#	my $link;
#	my $txt;
#	my $x;
#	my $entry;
#	my $uncle;
#	my $length;
#	
#	foreach( @{$display} ) {
#		m/^(\d+)=(\d+)$/	|| $self->{HLP}->suicide( "$code has wrong format for dispaly: $_" );
#		( $1 == $curField++ ) || $self->{HLP}->suicide( "$code has non-sequencial display" );
#		$1 && ( $lengths->{$0} = $1 );#if length=0 then it is assumed that field is Not Searchable or RO
#	}
#	
#	$lengths->{0} && ( $uncles->[0] ) && ( $columns++ ); 
#	$scr->openTable( $columns, "bordercolor=#$color border frame=box rules=none" );
#	$scr->openCell( "bgcolor=#$color colspan=2" );
#	( $shown == $total ) ? $scr->doTxt( "$total $name - $totalSel Selected - Insert New: " ) : $scr->doTxt( "$shown $name [$i..$last] of $total - $pageSel/$totalSel Selected - " );
#	
#	if( $uncles->[0] && $lengths->{0} ) {
#		$scr->doEdit( $code.'&SEARCH', $search, $lengths->{0} );
#		$scr->doToolBox( $code, 16, [ '', 'lookup', ] );
#	}
#	
#	$scr->doToolBox( 'id', 16, [ '', 'gear' ] );
#	
#	if ( $initial ) {
#		( $last == $total ) ? $scr->doToolBox( $code, 16, [ '', 'left', '', '' ] ) : $scr->doToolBox( $code, 16, [ '', 'left', '', 'right' ] );
#	}
#	else {
#		( $last == $total ) || $scr->doToolBox( $code, 16, [ '', '', '', 'right' ] );
#	}
#	
#	foreach $entry ( @{$data} ) {
#		$serialN++;
#		$scr->openRow();
#		if( $uncle = $uncles->[0] ) {
#			if( $lengths->{0} ) {
#				$scr->openCell();
#				$scr->doCheckBox( "$code&VALUE&"."$serialN&0", $entry->[2], $entry->[0] );
#			}
#			else {
#				$scr->openCell();
#				$scr->doHidden( "$code&VALUE&"."$serialN&0", $entry->[2] );
#			}
#			$txt = $mem->entryDefsGet( $uncle, $entry->[2], [ 'MAIN' ] );
#			( $link = $self->{MEM}->getLink( $uncle, $entry->[2] ) ) ? $scr->doLink( $link, $txt ) : $scr->doTxt( $txt );
#			$entry->[1] && $scr->doImg( 'images/icons2/target-16.gif' );
#		}
#		else {
#			$scr->openCell();
#			$self->{HLP}->suicide( "NI: just do an edit field" );
#		}
#		for( $x = 1; $x < scalar( @{$display} ); $x++ ) {
#			if( $uncle = $uncles->[$x] ) {
#				$length->{$x} && $self->{hlp}->suicide( "NI: for now only the first uncle is editable" );
#				$txt = $mem->entryDefsGet( $uncle, $entry->[$x], [ 'MAIN' ] );
#				( $link = $self->{MEM}->getLink( $uncle, $entry->[$x] ) ) ? scr->doLink( $link, $txt ) : $scr->doTxt( $txt );
#			}
#			elsif( $length = $lengths->{$x} ) {
#				$scr->openCell();
#				$scr->doEdit( $data->[$x + 2 ], "$code&VALUE&"."$serialN&".$x, $length );	
#			}
#			else {
#				$scr->doCell( $data->[$x + 2 ] );
#			}
#		}
#	}
#
#	if ( $shown != $total ) {
#		#select page
#		#
#		$scr->openRow( "bgcolor=#$color" );
#		$scr->openCell( "align=center colspan=2" );
#	}
#
#	if ( $setsP ) {
#		if ( @{$setsD} ) {
#			$scr->openRow();
#			$scr->openRow( "bgcolor=#$color" );
#			$scr->openCell( "align=right colspan=2" );
#			$scr->doToolBox( $code, 16, [ 'redx' ] );
#			$scr->openRow();
#			$scr->openCell( "colspan=2" );
#			$self->doSetsSelectionBox( $scr, $setsP, $setsD, "$code&sets&".$uncle, 0 );
#		}
#		else {
#			$scr->openRow();
#			$scr->openRow( "bgcolor=#$color" );
#			$scr->openCell( "align=right colspan=2" );
#			$scr->doToolBox( $code, 16, [ 'loadset' ] );
#		}
#	}
#	$scr->closeTable();
#}


	
#sub doSetUncleBox { #
#	my $self	= shift;
#	my $scr		= shift;
#	my $code	= shift;
#	my $color	= shift;
#	my $name	= shift;
#	my $uncle	= shift;
#	my $options	= shift; # [ [ id, name ] , ]
#	my $data	= shift; # [ [ id, name ] , ]
#
#
#	$scr->openTable( 2, "bordercolor=#$color border frame=box rules=none" );
#	$scr->openCell( "bgcolor=#$color colspan=2" );
#	if ( @{$options} ) {
#		my $total = scalar( @{$data} );
#		$total ? $scr->doTxt( "$name: ( $total )" ) : $scr->doTxt( "$name" );
#		$scr->closeCell();
#		my $link;
#		my $pos = 1;
#		foreach ( @{$data} ) {
#			$scr->openRow();
#			$scr->openCell();
#			$scr->doCheckBox( $code.'&VALUE&'."$pos&0", $_->[0], 1 );
#			$pos++;
#			$scr->openCell();
#			( $link = $self->{MEM}->getLink( $uncle, $_->[0] ) ) ? $scr->doLink( $link, $_->[1] ) : $scr->doTxt( $_->[1] );
#		}
#		$scr->closeRow();
#		$scr->openCell();
#		$scr->doToolBox( $code, 16, [ 'gear' ] );
#		$scr->openCell();
#		$scr->doSelect( $code."&VALUE&0&0", $options, 0 );
#	}
#	else {
#		$scr->doTxt( " no values to select from" );
#	}
#	$scr->closeTable();
#}

#sub doSingleBox {#
#	my $self	= shift;
#	my $scr		= shift;
#	my $code	= shift;#usually 'child&xxx0y'
#	my $color	= shift;
#	my $name	= shift;
#	my $length	= shift;#length of the search field
#	my $data	= shift;
#	my $readonly	= shift;
#
#	$scr->openTable( 1, "bordercolor=#$color border frame=box rules=none" );
#	$scr->doCell( "$name:", "bgcolor=#$color" );
#
#	my $v = '';
#	( $data->[0] && defined( $data->[0]->[0] ) ) && ( $v = $data->[0]->[0] );
#	if ( $readonly ) {
#		if ( length( $v ) ) {
#			$scr->openRow();
#			$scr->openCell();
#			$scr->doTxt( $v, [ 'MULTILINE40' ] );
#		}
#	}
#	else {
#		$length || $self->{HLP}->suicide( "$code, $name" );
#		$scr->openRow();
#		$scr->openCell();
#		$scr->doEdit( $code.'&VALUE&1&0', $v, $length );
#	}
#	$scr->closeTable();
#}

#sub doSingleAllowsBox {#
#	my $self	= shift;
#	my $scr		= shift;
#	my $code	= shift;
#	my $color	= shift;
#	my $name	= shift;
#	my $options	= shift;
#	
#	$scr->openTable( 1, "bordercolor=#$color border frame=box rules=none" );
#	$scr->openCell( "bgcolor=#$color" );
#	$scr->doTxt( "$name:" );
#	$scr->closeRow();
#	$scr->openCell();
#	$scr->doSelect( $code."&VALUE&1&0", $options );
#	$scr->closeTable();
#}

#sub doSingleUncleBox {#
#	my $self	= shift;
#	my $scr		= shift;
#	my $code	= shift;#usually 'child&xxx0y'
#	my $color	= shift;
#	my $name	= shift;
#	my $length	= shift;#length of the search field
#	my $uncle	= shift;
#	my $edit	= shift;
#	my $data	= shift;#[ [ id, selection, name1, name2, ... ] ]
#	my $options	= shift;
#
#	my $pos;
#	my $link;
#	my $v = '';
#	( $data->[0] && defined( $data->[0]->[0] ) ) && ( $v = $data->[0]->[0] );
#	if ( $edit || !length( $v ) ) {
#		if ( $length ) {
#			my $entry;
#			$scr->openTable( 2, "bordercolor=#$color border frame=box rules=none" );
#			$scr->doCell( "$name:", "bgcolor=#$color colspan=2" );
#			$scr->doToolBox( 'id', 16, [ '', 'lookup', 'gear' ] ); 
#			foreach $entry ( @{$options} ) {
#				$scr->openRow();
#				$scr->openCell();
#				if ( $entry->[0] == $v ) {
#					$scr->doRadio( $code."&VALUE&1&0", $entry->[0], 1 );
#				}
#				elsif ( !$entry->[1] ) {
#					$scr->doRadio( $code."&VALUE&1&0", $entry->[0], 0 );
#				}
#				else {
#					$self->{HLP}->suicide();
#				}
#
#				$scr->openCell();
#				( $link = $self->{MEM}->getLink( $uncle, $entry->[0] ) ) ? $scr->doLink( $link, $entry->[2] ) : $scr->doTxt( $entry->[2] );
#				for ( $pos = 3; $pos < scalar( @{$entry} ); $pos++ ) {
#					$scr->doTxt( "\n$entry->[$pos]" );
#				}
#			}
#			$scr->closeTable();
#		}
#		elsif ( @{$options} ) {
#			$scr->openTable( 1, "bordercolor=#$color border frame=box rules=none" );
#			$scr->openCell( "bgcolor=#$color" );
#			$scr->doTxt( "$name:" );
#			$scr->doToolBox( 'id', 16, [ '', 'gear' ] );
#			$scr->closeRow();
#			$scr->openCell();
#			$scr->doSelect( $code."&VALUE&1&0", $options );
#			$scr->closeTable();
#		}
#		else {
#			$scr->openTable( 1, "bordercolor=#$color border frame=box rules=none" );
#			$scr->doCell( "$name - No Values to Select From", "bgcolor=#$color" );
#			$scr->closeTable();
#		}
#	}
#	else {
#		( scalar( @{$options} ) == 1 ) || $self->{HLP}->suicide();
#		( scalar( @{$options->[0]} ) > 2 ) || $self->{HLP}->suicide();
#		( $options->[0]->[0] == $v) || $self->{HLP}->suicide();
#		$scr->openTable( 1, "bordercolor=#$color border frame=box rules=none" );
#		$scr->openCell( "bgcolor=#$color" );
#		$scr->doTxt( "$name:" );
#		$scr->doToolBox( $code, 16, [ '', 'edit' ] );
#		$scr->closeRow();
#		$scr->openCell();
#		$scr->doHidden( $code."&VALUE&1&0", $v );
#		( $link = $self->{MEM}->getLink( $uncle, $v ) ) ? $scr->doLink( $link, $options->[0]->[2] ) : $scr->doTxt( $options->[0]->[2] );
#		for ( $pos = 3; $pos < scalar( @{$options->[0]} ); $pos++ ) {
#			$scr->doTxt( "\n$options->[0]->[$pos]" );
#		}
#		$scr->closeTable();
#	}
#}


1;
