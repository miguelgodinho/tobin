# (C) Miguel Godinho de Almeida - miguel@datindex.com 2005
package WebArc::ViewSetsMng;

use strict;
use warnings;

sub new {
	my $param	= shift;
	my $self	= shift;
	my $class	= ref( $param ) || $param;
	bless( $self, $class );
	
	$self->{CODE}		|| $self->{HLP}->suicide();
	$self->{ENTITY}		|| $self->{HLP}->suicide();
	$self->{data}		|| $self->{HLP}->suicide();
	$self->{lists}		|| $self->{HLP}->suicide();
	
	$self->{MEM}		= $self->{BRO}->{MEM};
	$self->{DBA}		= $self->{MEM}->{DBA};
	$self->{LOG}		= $self->{MEM}->{LOG};
	$self->{HLP}		= $self->{BRO}->{HLP};
	$self->{CONST}		= $self->{BRO}->{CONST};
	$self->{USR}		= $self->{MEM}->userGet();
	$self->{SET_DEF}	= $self->{CONST}->{CHILDREN}->{$self->{ENTITY}->{CODE}.'_'.$self->{CONST}->{SETS_DEF}};
	( $self->{expanded} || !defined( $self->{data}->{showSets} ) ) && ( $self->{data}->{showSets} = 1 );
	
	return $self;
}

sub openView {
	my $scr		= shift;
	
}

sub printView {
	my $self	= shift;
	my $scr		= shift;
	my $mem		= $self->{MEM};
	my $length	= 0;
	my $code	= $self->{CODE};
	my $lnk;
	my $show;
	
	$self->{SETS} = $self->{MEM}->setsListGet( $self->{ENTITY}->{CODE} );
	
	$self->openView( $scr );
	
	if( defined( $self->{expanded} ) ) {
		@{$self->{SETS}} || return '';
		$scr->openTable( 4, "bordercolor=#$self->{CONST}->{COLOR_BLUE} border frame=box rules=none" );
		$scr->openRow( "bgcolor=#$self->{CONST}->{COLOR_BLUE}" );
		$scr->openCell( "align=left" );
		$scr->openCell( "colspan=2" );
		$scr->doTxt( "$self->{ENTITY}->{NAME}(s)" );
		$scr->openCell( "align=right" );
		if( $self->{data}->{showSets} ) {
			$scr->doToolBox( $code, 16, [ '', 'redx' ] );
		}
		else {
			$scr->doToolBox( $code, 16, [ '', 'loadset' ] );	
		}
		$scr->closeRow();
	}
	else {
		$scr->openTable( 4, "bordercolor=#$self->{CONST}->{COLOR_BLUE} border frame=box rules=none" );
	}
	
	if( $self->{data}->{showSets} ) {
		$scr->openRow( "bgcolor=#$self->{CONST}->{COLOR_BLUE}" );
		$scr->doCell( 'Set Name', 'align=center' );
		$scr->doCell( 'User', 'align=center' );
		$scr->doCell( 'Date', 'align=center' );
		$scr->doCell( 'Action', 'align=center' );
		
		if ( $self->{SAVE} ) {
			( $self->{SET_DEF}->{DISPLAY}->[0] =~ m/^0=(\d+)$/ ) || $self->{HLP}->suicide();
			$length = $1;	
			
			$scr->openRow();
			$scr->openCell();
			$scr->doEdit( "$code&def", '', $length ) ;
			$scr->openCell();
			$scr->doSelect( "$code&user", [ [ $self->{USR}, $self->{MEM}->userNameGet( $self->{USR} ) ], [ $self->{MEM}->{USER_PUB}, 'pub' ] ], $self->{USR} );
			$scr->doCell( '-', 'align=center' );
			$scr->openCell();
			$scr->doToolBox( $code, 16, [ '', '', '', '', '', 'save' ] );
		}
	
		foreach ( @{$self->{SETS}} ) {
			( $lnk = $mem->getLink( $self->{ENTITY}->{CODE}, $_->[0] ) ) || $self->{HLP}->suicide();
			$scr->openRow();
			$scr->openCell();
			$scr->doLink( $lnk, $_->[1] );
			$scr->doCell( $self->{MEM}->userNameGet( $_->[2] ) );
			$scr->doCell( $_->[3] );
			$scr->openCell();
			$self->{SAVE} ? $scr->doToolBox( "$code&".$_->[0], 16, [ '', 'arrowup', '', 'recycle', '', 'garbage' ] ) : $scr->doToolBox( "$code&".$_->[0], 16, [ '', 'arrowup', '', 'recycle' ] );
		}
	}
	$scr->closeTable();	
}

sub processForm {
	my $self		= shift;
	my $form		= shift;
	my $submitValue	= shift;
	my $lists		= $self->{lists};
	my $operation;
	my $tgt;
	
	
	if( $lists->{closed} ) {
		( $submitValue->[0] eq 'save' ) && $form->{def} && $self->setSave( $form->{def}, $form->{user} ); 
	}
	elsif( $operation = $submitValue->[0] ) {
		if( $operation eq 'redx' ) {
			$self->{data}->{showSets} = 0;	
		}
		elsif( $operation eq 'loadset' ) {
			$self->{data}->{showSets} = 1;
		}
		elsif( $operation =~ m/^\d+$/ ) {
			$tgt = $operation;
			( $operation = $submitValue->[1] ) || $self->{HLP}->suicide();
			
			if( $operation eq 'arrowup' ) {
				$lists->{founds}	= ();
				$lists->{page}		= 0;
				
				foreach( @{$self->{MEM}->setsValuesGet( $self->{ENTITY}->{CODE} , $tgt )} ) { $lists->{founds}->{$_} = 1 };
			}
			elsif( $operation eq 'recycle' ) {
				%{$lists->{founds}}		= ();
				%{$lists->{entries}}	= ();
				$lists->{page}			= 0;
				$lists->{closed}		= 1;
				
				foreach( @{$self->{MEM}->setsValuesGet( $self->{ENTITY}->{CODE} , $tgt )} ) { $lists->{founds}->{$_} = 1 };
			}
			elsif( $operation eq 'garbage' ) {
				$self->setDelete( $tgt );
			}
			else {
				$self->{HLP}->suicide( $operation );
			}
		}
		elsif( $operation ne 'save' ) {
			$self->{HLP}->suicide( $operation );
		}
	}
	
	return '';
}

sub setSave {
	my $self		= shift;
	my $name		= shift;
	my $usr			= shift;
	my $list		= $self->{lists}->{entries};
	my $mem			= $self->{MEM};
	my $log			= $mem->{LOG};
	my $newSet		= $mem->entryObjGet( $self->{ENTITY}->{CODE}, 0 );
	my $children	= $newSet->{CHILDREN};
	my $entityCode	= $self->{ENTITY}->{CODE};
	my $errors		= [];
	my $warnings	= [];
	my $newData;
	my $child;
	
	( length( $name ) < 255 ) || $self->{HLP}->suicide();
	
	if( %{$list} ) {
		$child		= $children->{$self->{SET_DEF}->{CODE}};
		$newData	= [ [ $name ] ];
		$mem->childObjUpdate( $child, $newData, $errors, $warnings );
		@{$errors} && $self->{HLP}->suicide( "@{$errors}" );
		
		$child		= $children->{$entityCode.'_'.$self->{CONST}->{SETS_DATE}};
		$newData	= [ [ 'NOW()' ] ];
		$mem->childObjUpdate( $child, $newData, $errors, $warnings );
		@{$errors} && $self->{HLP}->suicide( "@{$errors}" );
	
		$child		= $children->{$entityCode.'_'.$self->{CONST}->{SETS_USER}};
		$newData	= [ [ $usr ] ];
		$mem->childObjUpdate( $child, $newData, $errors, $warnings );
		@{$errors} && $self->{HLP}->suicide( "@{$errors}" );
	
		$child		= $children->{$entityCode.'_'.$self->{CONST}->{SETS_DATA}};
		$newData	= []; 
		foreach( keys( %{$list} ) ) {
			push( @{$newData}, [ $_ ] );
		}
		$mem->childObjUpdate( $child, $newData, $errors, $warnings );
		@{$errors} && $self->{HLP}->suicide( "@{$errors}" );
		
		$mem->entryObjSave( $newSet, $errors, $warnings );
		foreach ( @{$errors} )		{ warn "FATAL ERROR $_" };
		foreach ( @{$warnings} )	{ warn "WARNING $_"		};
	}
}

sub setDelete {
	my $self	= shift;
	my $tgt		= shift;
	my $mem		= $self->{MEM};
	my $errors	= [];
	my $newSet	= $mem->entryObjGet( $self->{ENTITY}->{CODE}, $tgt );
	
	$self->{USR}	|| $self->{HLP}->suicide();
	$tgt			|| $self->{HLP}->suicide( 'CRITICAL' );
	
	$mem->entryObjDelete( $newSet, $errors );
}
1;
