# (C) Miguel Godinho de Almeida - miguel@datindex.com 2005
package WebArc::ViewTree;

use strict;
use warnings;

sub new {
	my $param	= shift;
	my $self	= shift;
	my $class	= ref( $param ) || $param;
	bless( $self, $class );
	
	
	$self->{ENTITY}	|| $self->{HLP}->suicide();
	$self->{CODE}	|| $self->{HLP}->suicide();
	$self->{data}	|| $self->{HLP}->suicide();
	$self->{lists}	|| $self->{HLP}->suicide();
	
	$self->{MEM}	= $self->{BRO}->{MEM};
	$self->{DBA}	= $self->{MEM}->{DBA};
	$self->{HLP}	= $self->{BRO}->{HLP};
	$self->{CONST}	= $self->{BRO}->{CONST};
	$self->{TYPE}	= $self->{ENTITY}->{CODE};
	$self->{ILINK}	= $self->{MEM}->getLink( $self->{TYPE}, 0 );
	
	my $data = $self->{data};
	if( $data->{init} ) {
		( $data->{CODE}	eq $self->{CODE} )	|| $self->{HLP}->suicide();
	}
	else {
		$data->{init}			= 1;
		$data->{CODE}			= $self->{CODE};
		$data->{expansion}		= {};
		$data->{visibleNodes}	= {};
	}
	
	$self->{SET}			= $self->{ENTITY}->{S};
	$self->{treeEdits}		= {};
	$self->{treeValues}		= {};
	$self->{treeParents}	= {};
	$self->{treeChildren}	= {};
	@{$self->{treeData}}	= $self->{MEM}->getTree( $self->{TYPE} );
	$self->{HLP}->getHashFromArray( $self->{treeData}, $self->{treeEdits}, 0, 2 );
	$self->{HLP}->getHashFromArray( $self->{treeData}, $self->{treeValues}, 0, 4 );
	$self->{HLP}->createTree( $self->{treeData}, $self->{treeParents}, $self->{treeChildren} );
	
	return $self;
}

sub printBranch {
	my $self		= shift;
	my $scr			= shift;
	my $children	= shift;
	my $parent		= shift;
	my $child		= shift;
	my $flags		= $self->{ENTITY}->{FLAGS};
	my $edits		= $self->{treeEdits}; #hash of bools, key=node, value=editable [optional]
	my $values		= $self->{treeValues}; #hash of strings, key=node, value=txt [optional]
	my $ilink		= $self->{ILINK};
	
	if ( $flags->{ELINK} ) {
		( defined( $values->{$child} ) && length( $values->{$child} ) ) ? $scr->inTag( "a href=$values->{$child}", "$children->{$parent}->{$child}" ) : $scr->doTxt( "$children->{$parent}->{$child}") ;
		if ( $edits->{$child} ) {
			( $ilink =~ s/\d+/$child/ ) || $self->{HLP}->suicide();
			$scr->doTxt( "&nbsp;&nbsp;&nbsp;" );
			$scr->doImgLink( $ilink, 'images/icons2/edit-16.gif' );
		}
	}
	elsif ( $flags->{ILINK} ) {
		( $edits->{$child} && ( $ilink =~ s/\d+/$child/ ) ) ? $scr->inTag( "a href=$ilink", " $children->{$parent}->{$child}" ) : $scr->doTxt( "$children->{$parent}->{$child}" );#
		defined( $values->{$child} ) && $scr->doTxt( " = $values->{$child}" );
	}
	else {
		$scr->doTxt( "$children->{$parent}->{$child}" );
		defined( $values->{$child} ) && $scr->doTxt( " = $values->{$child}" );
	}	
}

sub printSelector {
	my $self		= shift;
	my $scr			= shift;
	my $selection	= shift;
	my $child		= shift;
	
	$self->{data}->{visibleNodes}->{$child}	= 1;
	$selection->{$child} ? $scr->doCheckBox( "$self->{CODE}&SelectedNodes", $child, 1 ) : $scr->doCheckBox( "$self->{CODE}&SelectedNodes", $child, 0 );
}

sub printToolbox {
	my $self				= shift;
	my $scr					= shift;
	my $child				= shift;
	my $expandedBranches	= shift;
	my $selectedBranches	= shift;
	my $expansion			= $self->{data}->{expansion};
	my $toolbox				= [];
	
	if ( $expansion->{$child} ) {
		( $expandedBranches->{$child} && ( $expandedBranches->{$child} > 0 ) ) ? ( @{$toolbox} = ( '', 'right', '', 'down' ) ) : ( @{$toolbox} = ( '', 'right', '', 'up' ) );
	}
	else {
		$toolbox = [ '', 'left', '', 'up' ] 
	}
	
	if ( $self->{SET} ) {
		if ( $selectedBranches->{$child} ) {
			( $selectedBranches->{$child} == 1 ) ? ( push( @{$toolbox}, ( '', 'box4' ) ) ) : ( push( @{$toolbox}, ( '', 'box2' ) ) );
		}
		else {
			push( @{$toolbox}, ( '', 'box' ) );
		}
	}
	$scr->doToolBox( "$self->{CODE}&".$child, 8, $toolbox );
}

sub printView {
	my $self				= shift;
	my $scr					= shift;		
	my $type				= $self->{ENTITY}->{CODE};
	my $flags				= $self->{ENTITY}->{FLAGS};
	my $mem					= $self->{MEM};
	my $data				= $self->{data};
	my $expansion			= $data->{expansion};
	my $selection			= $self->{lists}->{entries}; #hash of bools, key=node, value=selected; only used if set=1
	my $children			= $self->{treeChildren}; #hash of arrays, key=node, value=array of children
	my $parents				= $self->{treeParents}; #hash of arrays, key=node, value=array of parents, key=0 for root
	my $currentChild		= {};
	my $currentHash			= {};
	my $currentArray		= [];
	my $lvl					= 0;
	my $parent				= 0;
	my $i;
	my $child;
	my $sortedBranches;
	my $expandedBranches;
	my $selectedBranches;
	
	%{$data->{visibleNodes}} = ();
	foreach( keys( %{$self->{lists}->{founds}} ) ) { $self->{lists}->{entries}->{$_} = 1 };
	%{$self->{lists}->{founds}} = ();
	
	$sortedBranches		= $self->{HLP}->sortTree( $children );
	$expandedBranches	= $self->{HLP}->checkTreePropagation( $parents, $children, $expansion );
	$selectedBranches	= $self->{HLP}->checkTreePropagation( $parents, $children, $selection );
	
	$scr->openTable( 1 );
	$scr->openCell();

	if ( $sortedBranches->{0} ) {
		$lvl = 1;
		%{$currentChild}	= ( 0 => 0 );
		@{$currentArray}	= ();
		%{$currentHash} 	= ();
	}

	while ( $lvl ) {
		$child = $sortedBranches->{$parent}->[$currentChild->{$parent}];
		$currentHash->{$child} && $self->{HLP}->suicide();
		for ( $i = 1; $i < $lvl; $i++ ) { $scr->doTxt( '&nbsp;&nbsp;&nbsp;' ) };
		$self->{SET} && $self->printSelector( $scr, $selection, $child );
		( scalar( @{$parents->{$child}} ) > 1 ) && $scr->inTag( 'b', ' !' );####
		$self->printBranch( $scr, $children, $parent, $child );
		!$flags->{FIXED} && $sortedBranches->{$child} && @{$sortedBranches->{$child}} && $self->printToolbox( $scr, $child, $expandedBranches, $selectedBranches );

		$scr->stoTag( 'br' );#
		
		if ( $sortedBranches->{$child} && @{$sortedBranches->{$child}}  && ( $expansion->{$child} || $flags->{FIXED} ) ) {
			$lvl++;
			push( @{$currentArray}, $parent );
			$currentHash->{$parent}		= 1;
			$parent						= $child;
			$currentChild->{$parent} 	= 0;
		}
		else {
			while ( $lvl && ( $currentChild->{$parent} == $#{$sortedBranches->{$parent}} ) )  {
				$lvl--;
				$currentHash->{$parent}		= 0;
				$currentChild->{$parent}	= 0;
				$parent						= pop( @{$currentArray} );
			}			
			defined( $parent ) && $currentChild->{$parent}++;
		}
	}
	$scr->closeTable();
}

sub processForm {
	my $self		= shift;
	my $form		= shift;
	my $submitKey	= shift;
	my $data		= $self->{data};
	my $lists		= $self->{lists};
	my $tgt;
	my $operation;
	
	$lists->{closed} ? $self->{HLP}->suicide() : ( $lists->{closed} = 1 );
	
	foreach( keys( %{$data->{visibleNodes}} ) ) { delete( $lists->{entries}->{$_} ) };
	foreach( keys( %{$self->{lists}->{founds}} ) ) { $self->{lists}->{entries}->{$_} = 1 };
	%{$self->{lists}->{founds}} = ();
	
	if( ref( $form->{SelectedNodes} ) ) {
		foreach( @{$form->{SelectedNodes}} ) { $lists->{entries}->{$_} = 1 };
	}
	elsif( defined( $form->{SelectedNodes} ) ) {
		$lists->{entries}->{$form->{SelectedNodes}} = 1;
	}
	
	if( $submitKey ) {
		$tgt		= $submitKey->[0];
		$operation	= $submitKey->[1];
		
		( $tgt =~ m/^\d+$/ ) || $self->{HLP}->suicide( $tgt );
		
		if ( $operation eq 'left' ) {
			$data->{expansion}->{$tgt} = 1;
		}
		elsif ( $operation eq 'right' ) {
			$data->{expansion}->{$tgt} = 0;
		}
		elsif ( $operation eq 'up' ) {
			$self->{HLP}->treePropagate( 1, $tgt, $self->{treeChildren}, $data->{expansion} );
		}
		elsif ( $operation eq 'down' ) {
			$self->{HLP}->treePropagate( 0, $tgt, $self->{treeChildren}, $data->{expansion} );
		}
		elsif ( $operation eq 'box' ) {
			$self->{HLP}->treePropagate( 1, $tgt, $self->{treeChildren}, $lists->{entries} );
		}
		elsif ( $operation eq 'box2' ) {
			$self->{HLP}->treePropagate( 0, $tgt, $self->{treeChildren}, $lists->{entries} );
		}
		elsif ( $operation eq 'box4' ) {
			$self->{HLP}->treePropagate( 0, $tgt, $self->{treeChildren}, $lists->{entries} );
		}
		else {
			$self->{HLP}->suicide( $operation );
		}
	}
	return '';
}

1;
