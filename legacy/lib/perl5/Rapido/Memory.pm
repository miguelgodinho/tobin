# (C) Miguel Godinho de Almeida - miguel@datindex.com 2004
package Rapido::Memory;

use strict;
use warnings;

use vars qw($VERSION @ISA @EXPORT_OK);
use Exporter;
@ISA		= ( 'Exporter');
$VERSION	= '1.00';
@EXPORT_OK	= qw();

use Rapido::DBAccessor;
use Rapido::LogAccessor;
use Rapido::Parent;

sub new {#rev5
	my $param	= shift;
	my $self 	= shift;
	my $class 	= ref( $param ) || $param;
	my $parent;
	my $child;
	bless( $self, $class );
	
	$self->{NOT2SERIALIZE} = { 'Rapido::DBAccessor' => 1, 'Rapido::LogAccessor' => 1, 'Rapido::General' => 1 };
	
	defined( $self->{data} )	|| ( $self->{data} = {} );
	$self->{HLP}				|| ( die "Rapido::Memory requires Rapido::General" );
	$self->{FcnExtLinkGet}		|| $self->{HLP}->suicide();
	$self->{FcnEntityCheck}		|| $self->{HLP}->suicide();
	$self->{FcnEntryDelete}		|| $self->{HLP}->suicide();
	$self->{FcnEntrySave}		|| $self->{HLP}->suicide();
	$self->{FcnEntryRecycle}	|| $self->{HLP}->suicide();
	$self->{FcnChildUpdate}		|| $self->{HLP}->suicide();
	$self->{CONST}				|| $self->{HLP}->suicide();
	 
	$self->{DBA} = new Rapido::DBAccessor( {	CHK		=> $self->{DEBUG},
												DB_HOST => $self->{CONST}->{DB_HOST},
												DB_USER => $self->{CONST}->{DB_USER},
												DB_PASS => $self->{CONST}->{DB_PASS},
												DB_DATA => $self->{CONST}->{DB_DATA} } );
	unless( $self->{data}->{INIT} ) {
		$self->{data}->{INIT}	= 1;
		$self->{data}->{USR}	= 0;
		$self->{data}->{GRP}	= {};
		$self->{data}->{PMODE}	= 1;
	}
	
	$self->userSet( $self->{data}->{USR}, $self->{data}->{GRP} );
	%{$self->{USERS}}	= $self->{DBA}->getHash( "SELECT p, x0 FROM $self->{CONST}->{USER_NICK_CHILD}" );
	$self->{USER_PUB}	= $self->{CONST}->{USER_PUB};
	$self->{LOG}		= new Rapido::LogAccessor( { DBA => $self->{DBA}, USR => $self->{USR} } );
	$self->{PARENTS}	= $self->{CONST}->{PARENTS};
	$self->{CHILDREN}	= $self->{CONST}->{CHILDREN};
	
	return $self;
}

sub appDataDelete {#rev5
	my $self	= shift;
	my $app		= shift;
	
	delete( $self->{data}->{"$app"} ) || $self->{HLP}->suicide( $app );
}

sub appDataGet {#rev5
	my $self 	= shift;
	my $app 	= shift;
	
	$app || $self->{HLP}->suicide("PE");
	$self->{data}->{"$app"} || ( $self->{data}->{"$app"} = {} );
	return $self->{data}->{"$app"};
}

sub cachedOrSorted {#rev5
	my $self		= shift;
	my $data		= shift;#input, hash WITH ID as key!
	my $uncles		= shift;#input, uncles ARRAY
	my $criteria	= shift;#input, array, NOTE: Pass Empty Cache W New Criteria
	my $cachedSort	= shift;#input/output, array of IDs by sorting criteria
	my $hlp			= $self->{HLP};
	my $newCriteria	= [ 0 .. $#{$criteria} ];
	my $cachedIDs	= {};
	my $activeIDs	= {};
	my $sorted		= 1;
	my $oldSort		= [];
	my $toSort		= [];
	my $uncle;
	my $value;
	my $key;
	my $pos;
	my $id;
	my $x;
	
	foreach $id ( @{$cachedSort} ) {
		$cachedIDs->{$id} = 1;
		push( @{$oldSort}, $id );
	}
	foreach $id ( keys( %{$data} ) ) {
		$activeIDs->{$id} = 1;
		$sorted && ( $cachedIDs->{$id} || ( $sorted = 0 ) );
	}
	
	@{$cachedSort}	= ();
	if( $sorted ) {
		foreach $id ( @{$oldSort} ) {
			$activeIDs->{$id} && ( push( @{$cachedSort}, $id ) );
		}
	}
	elsif( ( "@{$criteria}" eq '0' ) && ( $uncle = $uncles->[0] ) ) {
		foreach ( @{$self->entityDefMatrixGet( $uncle, $activeIDs )} ) { push( @{$cachedSort}, $_->[0] ) };
	}
	else {
		%{$cachedIDs} = ();
		for( $pos = 0; $pos < scalar( @{$criteria} ); $pos++ ) {
			$x = $criteria->[$pos];
			if( $uncle = $uncles->[$x] ) {
				foreach $id ( keys( %{$data} ) ) {
					$cachedIDs->{$id}->[$pos] = $self->entryDefsGet( $uncle, $id, [ 'MAIN' ] );
				} 
			}
			else {
				while( ( $id, $value ) = each( %{$data} ) ) {
					$cachedIDs->{$id}->[$pos] = $value->[$x];
				}	
			}	
		}
		while( ( $key, $value ) = each %{$cachedIDs} ) {
			push( @{$toSort}, [ $key, @{$value} ] );	
		}
		foreach( $hlp->sortMatrix( $toSort, $newCriteria ) ) {
			push( @{$cachedSort}, $_->[0] );	
		}
	}
	
	if( scalar( @{$cachedSort} ) != keys( %{$activeIDs} ) ) {
		my $tmpHash	= {};
		if( keys( %{$activeIDs} ) > scalar( @{$cachedSort} ) ) {
			foreach( @{$cachedSort} ) { $tmpHash->{$_} = 1 };
			foreach( keys( %{$activeIDs} ) ) {
				$tmpHash->{$_} || warn( "$uncles->[$criteria->[0]] $_ Cannot be indexed" );
			}
		}
		else {
			foreach( @{$cachedSort} ) {
				warn( "$uncles->[$criteria->[0]] $_: Something spooky is going on" );	
			}
		}
	}
}

sub childObjUpdate {
	my $self		= shift;
	my $child		= shift;
	my $newData		= shift;
	my $errors		= shift;
	my $warnings	= shift;
	
	ref( $errors) || $self->{HLP}->suicide();
	return $self->{FcnChildUpdate}->( $self->{DBA}, $child, $newData, $errors, $warnings );
}

sub entityCheck {
	my $self	= shift;
	$self->{HLP}->suicide();
	
}

sub entityAttribGet {#rev5
	my $self	= shift;
	my $parent	= shift;
	my $attrib	= shift;

	if( $attrib ) {
		defined( $self->{PARENTS}->{$parent} ) || $self->{HLP}->suicide();
		defined( $self->{PARENTS}->{$parent}->{$attrib} ) || $self->{HLP}->suicide();
		return $self->{PARENTS}->{$parent}->{$attrib};
	}
	elsif( $parent ) {
		defined( $self->{PARENTS}->{$parent} ) || $self->{HLP}->suicide();
		return %{$self->{PARENTS}->{$parent}};
	}
	else{
		return %{$self->{PARENTS}};
	}
}

sub entityDefAttribsGet {
	my $self	= shift;
	my $parent	= shift;
	
	my $attribs = [ '', 'x0', undef ];#value to show is assumed to be at pos0...
	my $i;
	( $attribs->[0] = $self->{PARENTS}->{$parent}->{DEF} ) || $self->{HLP}->suicide( $parent );
	$i = 0;
	foreach ( @{$self->{CHILDREN}->{$attribs->[0]}->{FIELDS}} ) {
		if ( $_ eq 'MAIN' ) {
			$attribs->[2] && $self->{HLP}->suicide( $parent );
			$i || $self->{HLP}->suicide( "Main cannot take position 0 - $parent " );
			$attribs->[2] = "x$i";
		}
		$i++;
	}
	return @{$attribs};
}

sub entityDefMatrixGet { #case def has main, it will skip over instances with main not set
	my $self			= shift;
	my $parent			= shift;
	my $const_allows	= shift; #VALUE 0 will always be replaced by user id, independently of what the entity is. if allows is not to be taken in account it should be undefined and not an empty array
	my $attribs			= [];
	my $where			= '';
	my $key;
	my $value;
	
	@{$attribs} = $self->entityDefAttribsGet( $parent );
	if ( defined( $const_allows ) && ( ( $self->{USR} != 1 ) || ( $parent ne $self->{CONST}->{USER_PARENT} ) ) ) {
		if( ref( $const_allows ) eq 'ARRAY' ) {
			foreach( @{$const_allows} ) {
				m/^\d+$/ || $self->{HLP}->suicide( "POTENTIAL SECURITY FAULT $_" );
				$_ ? ( $where .= " OR p=$_" ) : ( $where .= " OR p=$self->{USR}" ) };
		}
		else {
			while(( $key, $value ) = each %{$const_allows} ) {
				if( $value ) {
					if( $key =~ m/^[0-9]\d*$/ ) {
						$where .= " OR p=$key";
					}
					elsif( $key ) {
						$self->{HLP}->suicide( "POTENTIAL SECURITY FAULT $key" );	
					}
					else{
						 $where .= " OR p=$self->{USR}";	
					}
				}
			}	
		}
		( $where =~ s/^ OR // ) || ( return [] );
		defined( $attribs->[2] ) ? ( $where = "WHERE $attribs->[2]=1 AND ($where)" ) : ( $where = "WHERE $where" );
	}
	else {
		defined( $attribs->[2] ) && ( $where = "WHERE $attribs->[2]=1" );
	}
	
	$self->{PARENTS}->{$parent}->{OWNERTBL} && ( $self->{USR} != 1 ) && ( $where ? ( $where .= " AND p IN ( SELECT p FROM $self->{PARENTS}->{$parent}->{OWNERTBL} WHERE x0=$self->{USER_PUB} OR x0=$self->{USR} )" ) : ( $where .= "WHERE p IN ( SELECT p FROM $self->{PARENTS}->{$parent}->{OWNERTBL} WHERE x0=$self->{USER_PUB} OR x0=$self->{USR})" ) );
#	warn "SELECT p, $attribs->[1] FROM $attribs->[0] $where ORDER BY $attribs->[1]";

	return $self->{DBA}->getMatrixRef( "SELECT p, $attribs->[1] FROM $attribs->[0] $where ORDER BY $attribs->[1]" );
}

sub entryDefsGet {
	my $self	= shift;
	my $parent	= shift;
	my $id		= shift;
	my $a_flag	= shift;

	my $flag = {};
	foreach ( @{$a_flag} ) {
		( $_ eq 'MAIN' ) || #one string with the definition is returned
		$self->{HLP}->suicide();
		$flag->{"$_"} = 1;
	}

	( $id =~ m/^[1-9]\d*$/ ) || $self->{HLP}->suicide( "$parent - $id" );
	
	my $attribs = [];
	@{$attribs} = $self->entityDefAttribsGet( $parent );

	if ( defined( $attribs->[2] ) ) {
		$flag->{MAIN} ? ( return $self->{DBA}->getValue( "SELECT $attribs->[1] FROM $attribs->[0] WHERE p=$id ORDER BY $attribs->[2] DESC, $attribs->[1] ASC LIMIT 1" ) ) : ( return $self->{DBA}->getColumnRef( "SELECT $attribs->[1] FROM $attribs->[0] WHERE p=$id ORDER BY $attribs->[2] DESC, $attribs->[1] ASC" ) );
	}
	else {
		$flag->{MAIN} ? ( return $self->{DBA}->getValue( "SELECT $attribs->[1] FROM $attribs->[0] WHERE p=$id ORDER BY $attribs->[1] LIMIT 1" ) ) : ( return $self->{DBA}->getColumnRef( "SELECT $attribs->[1] FROM $attribs->[0] WHERE p=$id ORDER BY $attribs->[1]" ) );
	}
}

sub entityRelativesMatrixGet { #returns [ [caption, code] ]
	my $self	= shift;
	my $entity	= shift;
	my $aFlags	= shift;
	
	my %flag;
	foreach ( @{$aFlags} ) {
		( $_ eq 'SEARCH' ) ||
		$self->{HLP}->suicide( "$_ is unkown flag" );
		$flag{"$_"} = 1;
	}

	$entity || $self->{HLP}->suicide( "EntityGetRelativesMatrix - PE" );
	
	my $child;
	my $childData;
	my @relatives;
	my $uncle;
	
	while ( ( $child, $childData ) = each %{$self->{PARENTS}->{$entity}->{CHILDREN}} ) { ( $childData->{SEARCH} || !$flag{SEARCH} ) && ( push( @relatives, [ $childData->{CODE}, $childData->{NAME} ] ) ) };

	while ( ( $child, $childData ) = each %{$self->{CHILDREN}} ) {
		foreach $uncle ( @{$childData->{UNCLES}} ) { ( $uncle eq  $entity ) && ( !$flag{SEARCH} || $childData->{SEARCH} ) && ( push( @relatives,  [ $childData->{PARENT}, $self->{PARENTS}->{$childData->{PARENT}}->{NAME} ] ) ) };
	}

	return @relatives;
}

sub entityList { #returns array, ordered by id
	my $self 	= shift;
	my $entity	= shift;
	my $limit	= shift; #0, undef for unlimited output
	my $criteria	= shift; #name of single child
	my $value	= shift; #exact value for single child

	my $ownerTbl;
	my $sql;

	( $self->{PARENTS}->{$entity} ) || $self->{HLP}->suicide();

	if ( $criteria ) {
		( $self->{PARENTS}->{$entity}->{CHILDREN}->{$criteria} && ( $self->{PARENTS}->{$entity}->{CHILDREN}->{$criteria}->{TYPE} eq 'SINGLE' ) ) || $self->{HLP}->suicide( "$criteria is unkown criteria for $entity" );
		$self->{PARENTS}->{$entity}->{CHILDREN}->{$criteria}->{UNCLES} && ( ( $value =~ m/^[1-9]\d*$/ ) || $self->{HLP}->suicide() );

		if ( $self->{USR} == 1 ) {
			$sql = "SELECT $entity.id FROM $entity LEFT JOIN $criteria ON $criteria.p=$entity.id WHERE $criteria.x0='$value' ORDER BY $entity.id DESC"; 
		}
		else {
			$self->{PARENTS}->{$entity}->{FLAGS}->{ADMIN} && $self->{HLP}->suicide();
			( $ownerTbl = $self->{PARENTS}->{$entity}->{OWNERTBL} ) ? ( $sql = "SELECT $criteria.p FROM $criteria LEFT JOIN $ownerTbl USING( p ) WHERE $criteria.x0='$value' AND ( $ownerTbl.x0=$self->{USR} OR $ownerTbl.x0=$self->{USER_PUB} ) ORDER BY $criteria.p DESC" ) : ( $sql = "SELECT p FROM $criteria WHERE x0='$value' ORDER BY p DESC" );
		}
	}
	elsif ( $self->{USR} == 1 ) {
		$sql = "SELECT id FROM $entity ORDER BY id DESC";
	}
	else {
		$self->{PARENTS}->{$entity}->{FLAGS}->{ADMIN} && $self->{HLP}->suicide();
		( $ownerTbl = $self->{PARENTS}->{$entity}->{OWNERTBL} ) ? ( $sql = "SELECT p FROM $ownerTbl WHERE x0=$self->{USR} OR x0=$self->{USER_PUB} ORDER BY p DESC" ): ( $sql = "SELECT id FROM $entity ORDER BY id DESC" );
	}

	$limit && ( $sql .= " LIMIT $limit" );
	return $self->{DBA}->getColumnRef( $sql );
}

sub entitySearch {
	my $self		= shift;
	my $myEntity	= shift; #string
	my $search		= shift; #string
	my $criteria	= shift; #string
	my $limit		= shift;
	my $noregex		= shift; #if true uses standart mysql wildcards instead of regular expressions
	my $LIKE;
	
	$noregex ? ( $LIKE = 'LIKE' ) : ( $LIKE = 'RLIKE' );

	( defined( $search ) && length( $search ) ) || ( return [] );
	if ( defined( $limit ) && length( $limit) ) {
		( $limit =~ m/^\d*$/ ) || $self->{HLP}->suicide();
		$limit = "LIMIT 0, $limit";
	}
	else {
		$limit = '';
	}

	defined( $self->{PARENTS}->{$myEntity} ) || $self->{HLP}->suicide("entitySearch: $myEntity is unkown entity");

	$self->{PARENTS}->{$myEntity}->{FLAGS}->{ADMIN} && ( ( $self->{USR} == 1 ) || $self->{HLP}->suicide( "NOT IMPLEMENTED" ) );
	
	my $attribs	= $self->{PARENTS}->{$myEntity};
	my $defAttribs	= [];
	my $brothers	= [];
	my $where	= '';
	my $nephew;
	my $brother;
	my $child;
	my $p;
	my $sel;
	my $ownerTbl;
	my $formatedSearch;

	my $type;
	( $type = $attribs->{CODE} ) || $self->{HLP}->suicide();
	@{$defAttribs} = $self->entityDefAttribsGet( $myEntity );


	( length( $search ) > 255 ) && $self->{HLP}->suicide( "entitySearch - possible exploit" );
	
	if( $criteria ) {
		( length( $criteria ) < 64 ) || $self->{HLP}->suicide( "POSSIBLE EXPLOIT" );
		if ( $child = $self->{CHILDREN}->{$criteria} ) {
			( $child->{PARENT} eq $type ) || $self->{HLP}->suicide();
			$child->{SEARCH} || $self->{HLP}->suicide();

			if ( !$child->{UNCLES}->[0] ) {
				$formatedSearch = $self->{DBA}->format( $criteria, 'x0', $search, [ 'NOTEST', 'NOQUOTES' ] );
				$where = "$defAttribs->[0].p IN (SELECT p FROM $criteria WHERE x0 $LIKE( '$formatedSearch' ))";
			}
			elsif ( @{$brothers} = @{$child->{UNCLES}} ) {
				if ( $child->{PARENT} eq $type ) {
					( $brother = $brothers->[0] ) || $self->{HLP}->suicide( "@{$brothers}" );
					$p = 'x0';
				}
				elsif ( $brothers->[0] eq $type ) {
					$brother = $child->{PARENT};
					$p = 'p';
				}
				else {
					$self->{HLP}->suicide();
				}

				( $brother eq $type ) && $self->{HLP}->suicide();
				if ( $self->{USR} != 1 ) {
					$self->{PARENTS}->{$brother}->{FLAGS}->{ADMIN} && $self->{HLP}->suicide( "WARNING: unauthorized search on parent $criteria by user $self->{USR}" );
					( $ownerTbl = $self->{PARENTS}->{$brother}->{OWNERTBL} );
				}
				else {
					$ownerTbl = '';
				}

				foreach $nephew ( values %{$self->{PARENTS}->{$brother}->{CHILDREN}} ) {
					@{$brothers} = @{$nephew->{UNCLES}};
					if ( !$brothers->[0] && $nephew->{SEARCH} ) {
						$formatedSearch = $self->{DBA}->format( $nephew->{CODE}, 'x0', $search, [ 'NOTEST', 'NOQUOTES' ] );
						$ownerTbl ? ( $where .= " OR $p IN ( SELECT $nephew->{CODE}.p FROM $nephew->{CODE} LEFT JOIN $ownerTbl USING(p) WHERE $nephew->{CODE}.x0 $LIKE( '$formatedSearch' ) AND ( $ownerTbl.x0=$self->{USR} OR $ownerTbl.x0=$self->{USER_PUB} ) )" ) : ( $where .= " OR $p IN ( SELECT p FROM $nephew->{CODE} WHERE x0 $LIKE( '$formatedSearch' ) )" );
					}
				}
				$where =~ s/^ OR/WHERE/;
				 ( $p eq $defAttribs->[1] ) ? ( $where = "$defAttribs->[0].p IN ( SELECT p FROM $criteria $where)" ) : ( $where = "$defAttribs->[0].p IN ( SELECT $defAttribs->[1] FROM $criteria $where)" );
			}
			else {
				$self->{HLP}->suicide();
			}
		}
		elsif ( $self->{PARENTS}->{$criteria} ) {
			$self->{PARENTS}->{$criteria}->{FLAGS}->{ADMIN} && ( $self->{USR} != 1 ) && $self->{HLP}->suicide( "WARNING: unauthorized search on parent $criteria by user $self->{USR}" );
			my $linkTable = '';
			foreach $nephew ( values %{$self->{PARENTS}->{$criteria}->{CHILDREN}} ) {
				if ( @{$brothers} = @{$nephew->{UNCLES}} ) {
					if ( $brothers->[0] eq $type ) {
						$linkTable ? $self->{HLP}->suicide() : ( $linkTable = $nephew->{CODE} );
					}
				}
				elsif ( $nephew->{SEARCH} ) {
					$formatedSearch = $self->{DBA}->format( $nephew->{CODE}, $defAttribs->[1], $search, [ 'NOTEST', 'NOQUOTES' ] );
					$where .= " OR p IN ( SELECT p FROM $nephew->{CODE} WHERE $defAttribs->[1] $LIKE( '$formatedSearch' ) )";
				}
			}
			$linkTable || $self->{HLP}->suicide();
			$where =~ s/^ OR/WHERE/;
			$where = "p IN ( SELECT $defAttribs->[1] FROM $linkTable $where)";
		}
		else {
			$self->{HLP}->suicide("criteria $criteria is unkown for type $type");
		}
	}
	else {
		foreach $child ( values %{$self->{PARENTS}->{$myEntity}->{CHILDREN}} ) {
			$formatedSearch = $self->{DBA}->format( $child->{CODE}, $defAttribs->[1], $search, [ 'NOTEST', 'NOQUOTES' ] );
			$child->{SEARCH} && !$child->{UNCLES}->[0] && ( $where .= " OR $defAttribs->[0].p IN ( SELECT p FROM $child->{CODE} WHERE $defAttribs->[1] $LIKE( '$formatedSearch' ) )" );
		 };
		( $where =~ s/^ OR/(/ ) ? ( $where .= ')' ) : ( $where = '(0)' );
	}

	$where || $self->{HLP}->suicide();
	if ( ( $ownerTbl = $self->{PARENTS}->{$myEntity}->{OWNERTBL} ) && ( $self->{USR} != 1 ) ) {
		$defAttribs->[2] ? ( return $self->{DBA}->getColumnRef( "SELECT $defAttribs->[0].p FROM $defAttribs->[0] LEFT JOIN $ownerTbl USING(p) WHERE ( $ownerTbl.x0=$self->{USR} OR $ownerTbl.x0=$self->{USER_PUB} ) AND $defAttribs->[0].$defAttribs->[2]=1 AND $where ORDER BY $defAttribs->[0].$defAttribs->[1] $limit" ) ) : ( return $self->{DBA}->getColumnRef( "SELECT $defAttribs->[0].p FROM $defAttribs->[0] LEFT JOIN $ownerTbl USING(p) WHERE ( $ownerTbl.x0=$self->{USR} OR $ownerTbl.x0=$self->{USER_PUB} ) AND $where ORDER BY $defAttribs->[0].$defAttribs->[1] $limit" ) );
	}
	else {
		$defAttribs->[2] ? ( return $self->{DBA}->getColumnRef( "SELECT p FROM $defAttribs->[0] WHERE $defAttribs->[2]=1 AND $where ORDER BY $defAttribs->[1] $limit" ) ) : ( return $self->{DBA}->getColumnRef( "SELECT p FROM $defAttribs->[0] WHERE $where ORDER BY $defAttribs->[1] $limit" ) );
	}
}

sub entitySearchByStoich {
	my $self		= shift;
	my $stoich		= shift;
	my $reactants	= shift;
	my $products	= shift;
	my $child;

	( $child = $self->{CHILDREN}->{$stoich} ) || $self->{HLP}->suicide( $stoich );
	$self->{PARENTS}->{$child->{PARENT}}->{FLAGS}->{ADMIN} && ( ( $self->{USR} == 1 ) || $self->{HLP}->suicide() );
	$self->{PARENTS}->{$child->{PARENT}}->{OWNERTBL} && $self->{HLP}->suicide( 'not implemented' );

	my $sql = '';
	my $lvl = 0;
	my $comp;
	my $sel;

	while ( ( $comp, $sel ) = each %{$reactants} ) {
		if ( $sel ) {
			$comp =~ m/^\d+$/ || $self->{HLP}->suicide( "POSSIBLE SQL INJECTION" );
			$sql ? ( $sql .= " AND p IN ( SELECT p FROM $child->{CODE} WHERE x0=$comp AND x2<0" ) : ( $sql = "SELECT p FROM $stoich WHERE x0=$comp AND x2<0" );
			$lvl++;
		}
	}
	
	while ( ( $comp, $sel ) = each %{$products} ) {
		if ( $sel ) {
			$comp =~ m/^\d+$/ || $self->{HLP}->suicide( "POSSIBLE SQL INJECTION" );
			$sql ? ( $sql .= " AND p IN ( SELECT p FROM $child->{CODE} WHERE x0=$comp AND x2>0" ) : ( $sql = "SELECT p FROM $stoich WHERE x0=$comp AND x2>0" );
			$lvl++;
		}
	}

	if ( $lvl ) {
		while ( --$lvl ) { $sql .= ')' };
		return $self->{DBA}->getColumnRef( $sql );
	}
	
	return ();
}

sub entitySortList {
	my $self	= shift;
	my $parent	= shift;
	my $list	= shift;

	my $attribs = [];
	@{$attribs} = $self->entityDefAttribsGet( $parent );

	my $where = '';
	foreach ( @{$list} ) { $where .= " OR p=$_" };
	( $where =~ s/^ OR // ) || ( return [] );
	
	defined( $attribs->[2] ) ? ( $where = "WHERE $attribs->[2]=1 AND ($where)" ) : ( $where = "WHERE $where" );
#	warn "SELECT p FROM $attribs->[0] $where ORDER BY $attribs->[1]";
	return $self->{DBA}->getColumnRef( "SELECT p FROM $attribs->[0] $where ORDER BY $attribs->[1]" );
}

sub entryAccessLvlGet {#rev5
	my $self	= shift;
	my $entity	= shift;
	my $id		= shift;
	my $auth	= 0;
	my $owner	= 0;
	my $permit	= 0;
	my $group	= 0;
	my $parent;
	
	( ( length( $id ) < 12 ) && ( $id =~ m/^\d+$/ ) && ( $parent = $self->{PARENTS}->{$entity} ) ) || $self->{HLP}->suicide( "SECURITY FAULT USER $self->{USR} : $entity, $id" );
	$parent->{FLAGS}->{ADMIN} && ( $self->{USR} != 1 ) && $self->{HLP}->suicide( "SECURITY FAULT $self->{USR} FOR $entity" );
	
	if( $auth = $self->{ACCESS}->{$entity}->{$id} ) {
		return $auth;
	}
	elsif( !$id ) {
		$auth = 3;
	}
	elsif( $self->{DBA}->getValue( "SELECT id FROM $entity WHERE id=$id " ) ) {
		if( $self->{USR} == 1 ) {
			$auth = 3;			
		}
		else {
			if( $parent->{OWNERTBL} && ( $owner = $self->{DBA}->getValue( "SELECT x0 FROM $parent->{OWNERTBL} WHERE p=$id" ) ) ) {
				if( ( $owner == $self->{USER_PUB} ) || ( $owner == $self->{USR} ) ) {
					$self->{data}->{PMODE} ? ( $auth = 2 ) : ( $auth = 3 );
				}
				if( $parent->{GROUPTBL} && ( ( $group, $permit ) = $self->{DBA}->getRow( "SELECT x0, x1 FROM $parent->{GROUPTBL} WHERE p=$id" ) ) ) {
					$self->{GRP}->{$group} && ( $permit > $auth ) && ( $auth = $permit );
					$self->{data}->{PMODE} && ( $auth == 3 ) && ( $auth = 2 );
				}
			}
			else {
				$self->{data}->{PMODE} ? ( $auth = 2 ) : ( $auth = 3 );
			}
		}
	}
	else {
		warn "$entity=$id does not exist";
		$auth = -1;
	}
	$self->{ACCESS}->{$entity}->{$id} = $auth;	
	return $auth;
}

sub entryObjDelete {#rev5
	my $self		= shift;
	my $object		= shift;
	my $errors		= shift;
	my $warnings	= shift;
	my $entity		= $object->{CODE};
	my $id			= $object->{ID};
	
	( $entity eq $self->{CONST}->{USER_PARENT} ) && $self->{HLP}->suicide( "USERS CANNOT BE DELETED, CREATE FUNCTION TO DISABLE AND REMOVE ASSOCIATED SESSIONS" );
	$id || $self->{HLP}->suicide();
	if( $self->{FcnEntryDelete}->( $self->{DBA}, $object, $errors, $warnings ) ) {
		$self->{data}->{RECORDS}->{$entity}->{$id} && ( delete( $self->{data}->{RECORDS}->{$entity}->{$id} ) );
		return 1;
	}
	return 0;
}

sub entryConstDataGet {
	my $self	= shift;
	my $entity	= shift;
	my $id		= shift;
	my $data	= {};
	my $child;
	my @fields;
	my $sql;
	my $x;
	
	( $self->entryAccessLvlGet( $entity, $id ) > 0 ) || $self->{HLP}->suicide( "$entity=$id" );
	foreach $child ( values( %{$self->{PARENTS}->{$entity}->{CHILDREN}} ) ) {
		$sql	= 'SELECT';
		$x		= 0;
		foreach( @{$child->{FIELDS}} ) {
			$sql .= " x$x,";	
			$x++;
		};
		$sql =~ s/,$/ FROM $child->{CODE} WHERE p=$id/;
		@{$data->{$child->{CODE}}} = $self->{DBA}->getMatrix( $sql );
	}
	return $data;
}

sub entryObjGet {#rev5
	my $self	= shift;
	my $entity	= shift;
	my $id		= shift;
	my $cache	= shift; #set 1 to keep/retrieve cached (possibly unsaved) version
	my $hlp		= $self->{HLP};
	my $auth	= $self->entryAccessLvlGet( $entity, $id ) || ( $id = 0 );
	my $object;
	my $objectData;
	
	( $entity eq $self->{CONST}->{SIMUL_PARENT} ) && $self->{HLP}->suicide( "Processes should only be accessed by Rapido::SimulAccessor" );
	
	if( $cache ) {
		unless( $objectData = $self->{data}->{RECORDS}->{$entity}->{$id} ) {
			$self->{data}->{RECORDS}->{$entity}->{$id} = {};
			$objectData = $self->{data}->{RECORDS}->{$entity}->{$id};
		}
	}
	$object = new Rapido::Parent( { CODE		=> $entity,
									ID			=> $id,
									DBA			=> $self->{DBA},
									LOG			=> $self->{LOG},
									USR			=> $self->{USR},
									ALLCHILDREN	=> $self->{CHILDREN},
									NAME		=> $self->{PARENTS}->{$entity}->{NAME},
									FLAGS		=> $self->{PARENTS}->{$entity}->{FLAGS},
									HLP			=> $hlp,
									AUTH		=> $auth,
									data		=> $objectData			} );
	return $object;
}

sub entryHistoryGet { 
	my $self		= shift;
	my $parent		= shift;
	my $id			= shift;
	my $values		= [];
	my $chrono		= [];
	my $unchrono	= {};
	my $x;
	my $txt;
	my $row;
	my $date;
	my $user;
	my $logid;
	my $child;
	my $opType;
	my $unique;

	$id || $self->{HLP}->suicide();
	
	foreach $child ( values %{$self->{PARENTS}->{$parent}->{CHILDREN}} ) { 
		my $childIDS = [];
		my $childKeys = {};
		my $childFields = [];
		my $status = {};
		@{$childIDS} = @{$child->{IDS}};
		foreach ( @{$childIDS} ) { $childKeys->{$_} = 1 };
		@{$childFields} = @{$child->{FIELDS}};

		foreach $row ( $self->{DBA}->getMatrix( "SELECT id, d, u, t, x0 FROM history WHERE p=$id AND c='$child->{CODE}'" ) ) {
			( $logid, $date, $user, $opType, @{$values} ) = @{$row};
			if ( scalar( @{$childFields} ) > 1 ) {
				foreach ( $self->{DBA}->getMatrix( "SELECT x, v FROM history_x WHERE id=$logid" ) ) { $values->[$_->[0]] = $_->[1] };
			}
			( scalar( @{$values} ) > scalar( @{$childFields} ) ) && $self->{HLP}->suicide( "$child->{CODE}.$id" );
			( scalar( @{$values} ) < scalar( @{$childFields} ) ) && warn( "CORRUPT LOG: $child->{CODE}.$id has missing information" );
			$txt = '';
			$unique = '';
			foreach $x ( @{$childIDS} ) {
				defined( $values->[$x] ) ? ( $unique .= "$values->[$x]\000" ) : $self->{HLP}->suicide( "$child->{CODE}.$id" );
				$txt && ( $txt .= ', ' );
				$txt .= $self->getHistValTxt( $child->{CODE}, $id, $values, $x );
			}

			$txt ? ( $txt = "$child->{NAME} [ $txt ]" ) : ( $txt = "$child->{NAME}" );
			if ( $opType == 1 ) {
				( $status->{$unique} ) ? warn( "CORRUPT LOG: $child->{CODE}.$id=$unique cannot be inserted twice" ) : ( $status->{"$unique"} = [ @{$values} ] );
				$txt = "Insert $txt";
			}
			elsif ( $opType == 2 ) {
				$status->{$unique} || ( $status->{"$unique"} = [ @{$values} ] );
				$txt = "Update $txt";
			}
			else {
				delete( $status->{$unique} );
				$txt = "Remove $txt" ;
			}

			for ( $x = 0; $x < scalar( @{$values} ); $x++ ) {
				unless ( $childKeys->{$x} ) {
					( $txt =~ m/^]/ ) ? ( $txt .= ": " ) : ( $txt .= ", " );
					$txt .= $self->getHistValTxt( $child->{CODE}, $id, $values, $x );
				}
			}

			$unchrono->{"$logid"} = "$date - " . $self->userNameGet( $user ) . ' - ' . $txt;
		}
	}
	foreach ( sort { $a <=> $b } keys %{$unchrono} ) { push( @{$chrono}, $unchrono->{$_} ) };
	return @{$chrono};
}

sub entryObjRecycle {#rev5
	my $self	= shift;
	my $object	= shift;
	
	$self->{FcnEntryRecycle}->( $self->{DBA}, $object );
	return $object;
}

sub entryObjSave {
	my $self		= shift;
	my $object		= shift;
	my $errors		= shift;
	my $warnings	= shift;
	
	return $self->{FcnEntrySave}->( $self->{DBA}, $object, $errors, $warnings );
}

sub fileGet {
	my $self	= shift;
	my $file	= shift;
	my $output	= [];
	
	if( $file ) {
		open( FH, $file );
		@{$output} = <FH>;
#		while( <FH> ) {
#			chop();
#			warn $_;
#			push( @{$output}, $_ );
#		}
		close( FH );
	}
	return $output;
}

sub fileRemove {
	my $self	= shift;
	my $file	= shift;
	
	if( -w $file ) {
		unlink( $file );
	}
	else {
		$self->{HLP}->suicide();
	}
}

sub fileStatus {
	my $self	= shift;
	my $file	= shift;
	( -e $file ) && ( return( 1 ) );
	return 0;
}

sub getHistValTxt { #subfunction of entryHistoryGet (INTERNAL) 
	my $self		= shift;
	my $childCode	= shift;
	my $childID		= shift;
	my $values		= shift;
	my $x			= shift;
	my $enum		= [];
	my $childFields = [];
	my $childLabels = [];
	my $childUncles = [];
	my $v;
	my $txt;
	my $uncle;
	my $label;
	my $uncleDesc;
	
	@{$childFields} = @{$self->{CHILDREN}->{$childCode}->{FIELDS}};
	@{$childLabels} = @{$self->{CHILDREN}->{$childCode}->{LABELS}};
	@{$childUncles} = @{$self->{CHILDREN}->{$childCode}->{UNCLES}};

	( $label = $childLabels->[$x] ) || $self->{HLP}->suicide( $childCode );
	
	( $label =~ m/^\[/ ) && ( @{$enum} = @{$label} );

	if ( defined( $v = $values->[$x] ) ) {
		if ( @{$enum} ) {
			$childUncles->[$x] && $self->{HLP}->suicide( $childCode );
			defined( $txt = $enum->[$v] ) || $self->{HLP}->suicide( $childCode );
		}
		else {
			if ( $uncle = $childUncles->[$x] ) {
				( $v =~ m/^[1-9]\d*$/ ) || $self->{HLP}->suicide( "$v ($childCode)" );
				if ( $self->{DBA}->getValue( "SELECT id FROM $uncle WHERE id=$v" ) ) {
					$txt = $self->entryDefsGet( $uncle, $v, [ 'MAIN' ] );
				}
				else {
					$txt = undef;
					my( $table, $field, $main ) = $self->entityDefAttribsGet( $uncle );
					if ( $main ) {
						( $main =~ s/^x// ) || $self->{HLP}->suicide();
						( $field eq 'x0' ) || $self->{HLP}->suicide();

						$txt = $self->{DBA}->getValue( "SELECT history.x0 FROM history LEFT JOIN history_x USING(id) WHERE history.c='$table' AND history.p=$v AND history_x.x=$main AND history_x.v=1 ORDER BY history.id DESC LIMIT 1" );
					}
					elsif ( $table ) {
						$txt = $self->{DBA}->getValue( "SELECT x0 FROM history WHERE c='$table' AND p=$v ORDER BY id DESC LIMIT 1" );
					}
				}

				defined( $txt ) ? ( $txt = "$label='$txt'" ) : ( $txt = "$label=NA" );
			}
			elsif ( $v =~ m/^[+|-]?\d+[\.|,]?\d*$/ ){
				$txt = "$label=$v";
			}
			else {
				$txt = "$label='$v'";
			}
		}
	}
	else {
		warn( "CORRUPT LOG: $childCode.$childID.x$x IS NA" );
		return 'LOG CORRUPTION - PLEASE PRINT PAGE AND REPORT';
	}

	return $txt;
}

sub getLink {#rev5
	my $self	= shift;
	my $entity	= shift;
	my $code	= shift;
	my $link	= '';

	( defined( $code ) && length( $code ) ) || return '';
	( $code =~ s/\s/&bnsp;/g );

	if( $entity =~ m/^\d+$/ ) {
		$link = $self->{FcnExtLinkGet}->( $self->{DBA}, $entity, $code );
	}
	elsif( ( $entity ne $self->{CONST}->{USER_PARENT} ) && ( $self->entryAccessLvlGet( $entity, $code ) ) ) {
		$link = "?app=edi$code$entity";
	}
	return $link;
}
sub getSetsOld {#deprecated, to be replaced to a version that reqs. set, otherwise sub listEntity suits
	my $self	= shift;
	my $entity	= shift;
	my $set		= shift; #if not set, returns list of sets

	my $parent;
	
	( $parent = $self->{PARENTS}->{$entity}->{S} ) || $self->{HLP}->suicide();

	if ( defined( $set ) ) { 
		( $set =~ m/^[1-9]+\d*$/ ) || $self->{HLP}->suicide();
		my $link = $parent.'_'.$entity;
		my $attribs = [];
		@{$attribs} = $self->entityDefAttribsGet( $entity );

		$self->{PARENTS}->{$entity}->{FLAGS}->{ADMIN} && ( ( $self->{USR} == 1 ) || $self->{HLP}->suicide() );

		my $owner;
#		( $owner = $self->{DBA}->getValue( "SELECT x0 FROM $parent"."_u WHERE p=$set" ) ) || $self->{HLP}->suicide( $set );
		( $owner = $self->{DBA}->getValue( "SELECT x0 FROM $self->{PARENTS}->{$parent}->{OWNERTBL} WHERE p=$set" ) ) || $self->{HLP}->suicide( $set );
		( $self->{USR} == 1 ) || ( $owner == $self->{USR} ) || ( $owner = $self->{USER_PUB} ) || $self->{HLP}->suicide( "SECURITY FAULT $self->{USR} FOR SET $set" );
		defined( $attribs->[2] ) ? ( return $self->{DBA}->getArray( "SELECT $link.x0 FROM $link LEFT JOIN $attribs->[0] ON $attribs->[0].p=$link.x0 WHERE $link.p=$set AND $attribs->[0].$attribs->[2]=1 ORDER BY $attribs->[0].$attribs->[1]", [ 'COLUMN' ] ) ) : ( return $self->{DBA}->getArray( "SELECT $link.x0 FROM $link LEFT JOIN $attribs->[0] ON $attribs->[0].p=$link.x0 WHERE $link.p=$set ORDER BY $attribs->[0].$attribs->[1]", [ 'COLUMN' ] ) );
	}

	my $sql = '';
	my $user = $parent.'_u';
	my $def = $parent.'_def';
	my $date = $parent.'_date';
	( $self->{USR} != 1 ) && ( $sql = " WHERE $user.x0=$self->{USER_PUB} OR $user.x0=$self->{USR}" );
	return $self->{DBA}->getMatrix( "SELECT $user.p, $def.x0, $user.x0, $date.x0 FROM $user LEFT JOIN $def USING(p) LEFT JOIN $date USING (p) $sql ORDER BY $user.p" );
}

sub getTree {
	my $self	= shift;
	my $myEntity	= shift;
	
	my %flag;

	( $self->{USR} == 1 ) && ( $flag{EDITALL} = 1 );

	$self->{PARENTS}->{$myEntity}->{FLAGS}->{TREE} && $self->{PARENTS}->{$myEntity}->{FLAGS}->{ADMIN} && ( $self->{USR} != 1 ) && $self->{HLP}->suicide( "SECURITY FAIL" );
	
	my $select;
	my $from;
	my $where = '';
	my $key;
	my $value;
	my %table;

	while ( ( $key, $value ) = each %{$self->{PARENTS}->{$myEntity}->{CHILDREN}} ) {
		if ( $value->{NAME} eq 'Parent' ) {
			$table{Parent} ? $self->{HLP}->suicide() : ( $table{Parent} = $key );
		}
		elsif ( $value->{NAME} eq 'Key' ) {
			$table{Key} ? $self->{HLP}->suicide() : ( $table{Key} = $key );
		}
		elsif ( $value->{NAME} eq 'Value' ) {
			$table{Value} ? $self->{HLP}->suicide() : ( $table{Value} = $key );
		}
		elsif ( $value->{NAME} eq 'Owner' ) {
			$table{Owner} ? $self->{HLP}->suicide() : ( $table{Owner} = $key );
		}
#		else {
#			$self->{HLP}->suicide( " $key $value->{NAME} is unkown for tree" );
#		}

	}
	( $table{Key} && $table{Parent} ) || $self->{HLP}->suicide();

	$select = "SELECT $table{Key}.p, IFNULL( $table{Parent}.x0, 0 )";
	$from = "FROM $table{Key} LEFT JOIN $table{Parent} ON $table{Parent}.p=$table{Key}.p";
	if ( $table{Owner} ) {
		$flag{EDITALL} ? ( $select .= ", 1" ) : ( $select .= ", IF($table{Owner}.x0=$self->{USR}, 1, 0 )" );
		$from .= " LEFT JOIN $table{Owner} ON $table{Owner}.p=$table{Key}.p";
		$where = " WHERE $table{Key}.p IN ( SELECT p FROM $table{Owner} WHERE x0=$self->{USER_PUB} OR x0=$self->{USR})";
	}
	else {
		$select .= ', 1';
	}

	$select .= ", $table{Key}.x0";
	if ( $table{Value} ) {
		$select .= ", IFNULL($table{Value}.x0, '' )";
		$from .= " LEFT JOIN $table{Value} ON $table{Value}.p=$table{Key}.p";
	}
	return $self->{DBA}->getMatrix( "$select $from $where" ); 
}


sub setsListGet {
	my $self	= shift;
	my $entity	= shift;
	my $sql		= '';
	my $user	= $entity.'_'.$self->{CONST}->{SETS_USER};
	my $def		= $entity.'_'.$self->{CONST}->{SETS_DEF};
	my $date	= $entity.'_'.$self->{CONST}->{SETS_DATE};
	( $self->{USR} != 1 ) && ( $sql = " WHERE $user.x0=$self->{USER_PUB} OR $user.x0=$self->{USR}" );
	return $self->{DBA}->getMatrixRef( "SELECT $user.p, $def.x0, $user.x0, $date.x0 FROM $user LEFT JOIN $def USING(p) LEFT JOIN $date USING (p) $sql ORDER BY $user.p" );
}	

sub setsValuesGet {
	my $self	= shift;
	my $entity	= shift;
	my $id		= shift;
	my $owner;
	
	( $id =~ m/^\d+$/ ) || $self->{HLP}->suicide( "SECURITY FAULT" );
	$self->{CONST}->{PARENTS}->{$entity} || $self->{HLP}->suicide( "SECURITY FAULT" );
	if( $self->{USR} != 1 ) {
		$self->{CONST}->{PARENTS}->{$entity}->{FLAGS}->{ADMIN} && $self->{HLP}->suicide( "SECURITY FAULT" );
		$owner = $self->{DBA}->getValue( "SELECT x0 FROM $self->{CONST}->{PARENTS}->{$entity}->{OWNERTBL} WHERE p=$id" );
		( $owner eq $self->{USR} ) || ( $owner eq $self->{CONST}->{USER_PUB} ) || $self->{HLP}->suicide();
	}
	return $self->{DBA}->getColumnRef( "SELECT x0 FROM $entity"."_$self->{CONST}->{SETS_DATA} WHERE p=$id" );
	
	
}


sub protectedModeGet {
	my $self	= shift;
	return $self->{data}->{PMODE};
}

sub protectedModeOff {
	my $self	= shift;
	$self->{data}->{PMODE} = 0;
}

sub protectedModeOn {
	my $self	= shift;
	$self->{data}->{PMODE} = 1;
}

sub userGet {#rev5
	my $self	= shift;
	
	return $self->{USR};
}

sub userNameGet {#rev5
	my $self 	= shift;
	my $user 	= shift;
	
	if( defined( $user ) ) {
		if( $self->{USERS}->{$user} ) {
			return $self->{USERS}->{$user};	
		}
		else {
			return 'unkown';
			warn "user $user is not known";
		}
	}
	else {
		return %{$self->{USERS}};
	}
}

sub userSet {#rev5
	my $self 	= shift;
	my $user 	= shift;
	my $grp		= shift;
	
	defined( $grp ) || ( $grp = {} ); 
	( $user =~ m/^\d+$/ ) || $self->{HLP}->suicide();
	%{$grp} && !$user && $self->{HLP}->suicide();
	
	$self->{USR}			= $user;
	$self->{data}->{USR}	= $user;
	%{$self->{GRP}}			= %{$grp};
	%{$self->{data}->{GRP}}	= %{$self->{GRP}};
	%{$self->{ACCESS}}		= ();
	$self->{LOG} && $self->{LOG}->setUser( $user );
}

sub userValidate {#rev5
	my $self	= shift;
	my $nick	= shift;
	my $pass	= shift;
	my $user;
	
	( ( $nick =~ m/\W/ ) || ( $pass =~ m/\W/ ) || ( length( $nick ) > 10 ) || ( length( $pass ) > 10 ) ) && return 0;
	
#	warn( "SELECT $self->{CONST}->{USER_PASS_CHILD}.p FROM $self->{CONST}->{USER_NICK_CHILD} LEFT JOIN $self->{CONST}->{USER_PASS_CHILD} USING(p) WHERE $self->{CONST}->{USER_NICK_CHILD}.x0='$nick' AND $self->{CONST}->{USER_PASS_CHILD}.x0='$pass'" );
	( $user = $self->{DBA}->getValue( "SELECT $self->{CONST}->{USER_PASS_CHILD}.p FROM $self->{CONST}->{USER_NICK_CHILD} LEFT JOIN $self->{CONST}->{USER_PASS_CHILD} USING(p) WHERE $self->{CONST}->{USER_NICK_CHILD}.x0='$nick' AND $self->{CONST}->{USER_PASS_CHILD}.x0='$pass'" ) ) ? $self->userSet( $user ) : $self->userSet( 0 );
#	warn $self->{USR};
	return $self->{USR};
}

#sub stoRelated {
#	my $self	= shift;
#	my $src		= shift;
#	my $tgt		= shift;
#	my $app		= shift;
#	my $selection	= shift;
#
#	my $uncles = [];
#	my $link;
#	my $p = 'p';
#	my $v = 'x0';
#	my $sql = '';
#	my $key;
#	my $value;
#
#	my $data = $self->{data}->{$app}->{selection};
#	%{$data} = (); 
#	foreach ( values %{$self->{PARENTS}->{$tgt}->{CHILDREN}} ) { 
#		if (@{$uncles} = split( /;/, $_->{UNCLES} ) ) {
#			if ( $uncles->[0] eq $src ) {
#				$link ? $self->{HLP}->suicide() : ( $link = $_->{CODE} );
#			}
#		}
#	}
#
#	unless ( $link ) {
#		foreach ( values %{$self->{PARENTS}->{$src}->{CHILDREN}} ) {
#			if ( @{$uncles} = split( /;/, $_->{UNCLES} ) ) {
#				if ( $uncles->[0] eq $tgt ) {
#					$link ? $self->{HLP}->suicide() : ( $link = $_->{CODE} );
#				}
#			}
#		}
#		$link || $self->{HLP}->suicide();
#		$p = 'x0';
#		$v = 'p';
#	}
#
#
#
#	if ( $self->{CHILDREN}->{$link}->{TYPE} eq 'COMPLEX' ) {
#
#	}
#	else {
#		while ( ( $key, $value ) = each %{$selection} ) {
#			$value || $self->{HLP}->suicide();
#			$sql .= " OR $v=$key";
#		}
#		$sql =~ s/^ OR/WHERE/;
#		%{$data} = $self->{DBA}->getHash( "SELECT $p, 1 FROM $link $sql" );
#	}
#}
#

1;
