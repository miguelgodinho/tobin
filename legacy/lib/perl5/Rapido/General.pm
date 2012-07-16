# (C) Miguel Godinho de Almeida - miguel@datindex.com 2003
package Rapido::General;

use strict;
use warnings;
use Time::HiRes;

sub new {
	my ( $param )	= shift;
	my $self	= {};
	my $class	= ref( $param ) || $param;
	bless( $self, $class );
	return $self;
}



sub checkTreePropagation {
	my $self		= shift;
	my $parents		= shift;
	my $children	= shift;
	my $selection	= shift; #values: 1 for full; 0 for no propagation; -1 for semi-propagated
	my $included	= {};
	my @toExcludeArray;
	my @toIncludeArray;
	my %toExcludeHash;
	my %toIncludeHash;

	my $key;
	my $values;

	while ( ( $key, $values ) = each %{$parents} ) { $selection->{$key} ? ( push ( @toIncludeArray, $key ) ) : ( push ( @toExcludeArray, $key ) ) }

	while ( $key = pop( @toExcludeArray ) ) {
		foreach ( @{$parents->{$key}} ) {
			unless ( $toExcludeHash{$_} ) {
				push( @toExcludeArray, $_ );
				$toExcludeHash{$_} = 1;
			}
		}
	}

	while ( $key = pop( @toIncludeArray ) ) {
		foreach ( @{$parents->{$key}} ) {
			unless ( $toIncludeHash{$_} ) {
				push( @toIncludeArray, $_ );
				$toIncludeHash{$_} = 1;
			}
		}
	}

	foreach ( keys %{$parents} ) { $toIncludeHash{$_} && ( $toExcludeHash{$_} ? ( $included->{$_} = -1 ) : ( $included->{$_} = 1 ) ) };

	return $included;
}

sub compareData { 
	my $self	= shift;
	my $data0	= shift;
	my $data1	= shift;

	my $i;
	my $data0ref;
	my $data1ref;
	my $pack0;
	my $pack1;

	$data0ref = ref( $data0 );
	$data1ref = ref( $data1 );

#	foreach ( @{$data0} ) { warn @{$_} };
#	foreach ( @{$data1} ) { warn @{$_} };
#	die;

	if ( ( $data0ref eq 'ARRAY' ) && ( $data1ref eq 'ARRAY' ) ) {
		( scalar( @{$data0} ) == scalar( @{$data1} ) ) || return 0;
		for ( $i = 0; $i < scalar( @{$data0} ); $i++ ) {
			$data0ref = ref( $data0->[$i] );
			$data1ref = ref( $data1->[$i] );
			( $data0ref eq $data1ref ) ? ( $data0ref ? ( $self->compareData( $data0->[$i], $data1->[$i] ) || return 0 ) : ( ( $data0->[$i] eq $data1->[$i] ) || return 0 ) ) : ( return 0 );
		}
	}
	else {
		 $self->suicide( "Comparison between $data0ref and $data1ref is not implemented" );
	}
	return 1;
}

sub copyData { 
	my $self	= shift;
	my $data	= shift;
	my $target	= shift;
	my $toSkip	= shift;#Classes to be skipped from storage 

	if ( ref( $data ) eq 'ARRAY' ) {
		( ref( $target ) eq 'ARRAY' ) || $self->suicide();
		@{$target} = ();
		$self->stoArray( $target, $data, $toSkip );
	}
	elsif ( ref( $data ) eq 'HASH' ) {
		( ref( $target ) eq 'HASH' ) || $self->suicide();
		%{$target} = ();
		$self->stoHash( $target, $data, $toSkip );
	}
	else {
		$self->suicide( ref( $data ) );
	}
}

sub createTree {
	my $self	= shift;
	my $entries	= shift;
	my $parents	= shift; #empty Hash for output only
	my $children	= shift; #empty hash for output only

	foreach ( @{$entries} ) {
		if ( defined( $parents->{$_->[0]} ) ) {
			push ( @{$parents->{$_->[0]}}, $_->[1] );
			${$children->{"$_->[1]"}}{"$_->[0]"} = $_->[3];
		}
		else {
			if ( $_->[1] ) {
				$parents->{"$_->[0]"} = [ $_->[1] ];
				${$children->{"$_->[1]"}}{"$_->[0]"} = $_->[3];
			}
			else {
				$parents->{"$_->[0]"} = [];
				${$children->{0}}{"$_->[0]"} = $_->[3];
			}
		}
	}
}

sub getHashFromArray {
	my $self	= shift;
	my $data	= shift;
	my $hash	= shift; # where output is stored
	my $keyCol	= shift; # column with keys;
	my $valCol	= shift; # column with values;

#	foreach ( @{$data} ) { warn "@{$_}" };
	foreach ( @{$data} ) {	defined( $_->[$keyCol] ) &&
				defined( $_->[$valCol] ) &&
				( $hash->{"$_->[$keyCol]"} = $_->[$valCol] ) 
	};
}

sub sortHash {
	my $self	= shift;
	my $hash	= shift;
	my $key		= shift;
	
	$key && ( return sort { $hash->{$a}->{$key} cmp $hash->{$b}->{$key} } keys %{$hash} );
	return sort { $hash->{$a} cmp $hash->{$b} } keys %{$hash};
}

sub sortMatrix {#WARNING: returns array And NOT Pointer to array!
	my $self		= shift;
	my $data		= shift;
	my $criteria	= shift;
	
	return sort {
		foreach( @{$criteria} ) {
			if( ( $a->[$_] =~ m/^\d+$/ ) && ( $b->[$_] =~ m/^\d+$/ ) ) {
				( $a->[$_] < $b->[$_] ) && ( return -1 );
				( $a->[$_] > $b->[$_] ) && ( return 1 );
			}
			else {
				( $a->[$_] lt $b->[$_] ) && ( return -1 );
				( $a->[$_] gt $b->[$_] ) && ( return 1 );
			}
		}
	} @{$data};
}

sub sortTree {
	my $self			= shift;
	my $data			= shift;
	my $sortedChildren	= {};
	my @arrayA;
	my @arrayB;
	my $lhs1;
	my $rhs1;
	my $lhs2;
	my $rhs2;
	my $lhs3;
	my $rhs3;
	my $lhs4;
	my $rhs4;
	my $lhsTrail;
	my $rhsTrail;

	while ( my( $parent, $children ) = each %{$data} ) {
		@{$sortedChildren->{$parent}} = sort { 
			if ( ( $children->{$a} =~ m/^-?\d+\.?\d*$/ ) && ( $children->{$b} =~ m/^-?\d+\.?\d*$/ ) ) {
				$children->{$a} <=> $children->{$b};

			}
			elsif ( ( $children->{$a} =~ m/^(\d+\.[\d|-]+\.[\d|-]+\.[\d|-]+)(.*)/ ) ) {
				$lhs1 = $1;
				$lhsTrail = $2;
				$lhs1 =~ s/-/0/g;
				( $lhs1, $lhs2, $lhs3, $lhs4 ) = split ( /\./, $lhs1 );

				if ( ( $children->{$b} =~ m/^(\d+\.[\d|-]+\.[\d|-]+\.[\d|-]+)(.*)/ ) ) {
					$rhs1 = $1;
					$rhsTrail = $2;
					$rhs1 =~ s/-/0/g;
					( $rhs1, $rhs2, $rhs3, $rhs4 ) = split ( /\./, $rhs1 );
					$lhs1 <=> $rhs1 ||
					$lhs2 <=> $rhs2 ||
					$lhs3 <=> $rhs3 ||
					$lhs4 <=> $rhs4 ||
					$lhsTrail cmp $rhsTrail;
				}
				else {
					$children->{$a} cmp $children->{$b};
				}
			}
			else {
				$children->{$a} cmp $children->{$b};
			}
		} keys %{$children}
	}

	return $sortedChildren;
}

sub stoArray { #used by copyData
	my $self	= shift;
	my $tgt		= shift;
	my $array	= shift;
	my $toSkip	= shift;

	my $ref;

	foreach ( @{$array} ) {
		if ( $ref = ref($_) ) {
			if ( $ref eq 'ARRAY' ) {
				$self->stoArray( $tgt->[ push( @$tgt, [] ) -1 ], $_, $toSkip );
			}
			else { #assumes hash ( or object )
				push( @$tgt, [] );
				$self->stoHash( $tgt->[$#{$tgt}], $_, $toSkip );
			}
		}
		else {
			defined( $_ ) ? ( push( @$tgt, "$_" ) ) : ( push( @$tgt, undef ) );
		}
	}
}

sub stoHash { #used by copyData
	my $self	= shift;
	my $tgt		= shift;
	my $hash	= shift;
	my $toSkip	= shift;
	
	my $ref;
	my $key;
	my $value;

	while ( ( $key, $value ) = each %$hash ) {
		if ( $ref = ref( $value ) ) {
			if ( $ref eq 'ARRAY' ) {
				$tgt->{$key} = [];
				$self->stoArray( $tgt->{$key}, $value );
			}
			elsif ( !$toSkip->{$ref} ) {
				$tgt->{$key} = {};
				$self->stoHash( $tgt->{$key}, $value );
			}
		}
		else {
			defined($value) ? ( $tgt->{$key} = "$value" ) : ( $tgt->{$key} = undef );
		}
	}
}

sub treePropagate {
	my $self	= shift;
	my $value	= shift; #string to be set as value in output hash
	my $node	= shift; #initial node;
	my $tree	= shift; #hash of hashes, key1=parentnode, key2=childnode, value2=childvalue
	my $output	= shift; #hash, key=node and value will be changed
	my $flags	= shift;

	my %flag;
	foreach ( @{$flags} ) {
		( $_ eq 'NOINIT' ) || #do not change initial node
		$self->suicide();
		$flag{$_} = 1;
	}

	my @queueArray	= ( $node );
	my %queueHash	= ( $node => 1 );
	$flag{NOINIT} || ( $output->{"$node"} = $value );

	while ( $node = pop( @queueArray ) ) {
		foreach ( keys %{$tree->{$node}} ) {
			unless ( $queueHash{$_} ) {
				$output->{"$_"} = $value;
				$queueHash{"$_"} = 1;
				push( @queueArray, "$_" );
			}
		}
	}
}

sub suicide {
	my $self	= shift;
	my $txt		= shift;
	my $pack;
	my $file;
	my $line;
	my $i = 0;
	defined( $txt ) || ( $txt = '' );
	while(($pack, $file, $line) = caller($i++)){ warn "Die - $pack - $file - $line\n" };
	die "Rapido::General is dead... $txt\n";
}
1;
