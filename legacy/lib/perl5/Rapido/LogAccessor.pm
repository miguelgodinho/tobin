# (C) Miguel Godinho de Almeida - miguel@datindex.com 2004
# 0 - delete
# 1 - create
# 2 - change
package Rapido::LogAccessor;

use strict;
use warnings;

use vars qw($VERSION @ISA @EXPORT_OK);
use Exporter;
@ISA = ( 'Exporter');
$VERSION = '1.00';
@EXPORT_OK = qw();

use Rapido::DBAccessor;

sub new {
	my $param	= shift;
	my $self	= shift;
	my $class 	= ref( $param ) || $param;
	bless( $self, $class );
	bless( $self->{DBA}, 'Rapido::DBAccessor' );
	$self->{DBA}->analizeTable( 'history' );
	$self->{DBA}->analizeTable( 'history_x' );
	return $self;
}

sub suicide {
	my $self	= shift;
	my $txt		= shift;
	my $pack;
	my $file;
	my $line;
	my $i = 0;
	while( ( $pack, $file, $line ) = caller( $i++ ) ) {
		warn "DIE! - $pack - $file - $line";
	}
	die( "LogAccessor is dead... $txt\n" );
}

sub isInsertable { #review code and create cache for complexes ()!!!!
	my $self	= shift;
	my $c		= shift;
	my $p		= shift;
	my $data	= shift; # matrix
	my $constants	= shift;
	my $variable	= shift; #position of the serial field

	return 1;

#	( $p && ( $p =~ m/^\d+$/ ) ) || $self->suicide();
#	$variable && ( ( $variable =~ m/^[1-9]\d*$/ ) || $self->suicide() );
#
#	my $row;
#	my $value;
#	my $candidates = {};
#	my $sql;
#	my $init = 0;
#	my $column;
#	my $owner;
#	
#	foreach $row ( @{$data} ) {
#		( ref( $row ) eq 'ARRAY' ) || $self->suicide();
#		$sql = "SELECT id FROM history WHERE c='$c' AND p=$p";
#		foreach $column ( keys %{$constants} ) {
#			( $column =~ m/^\d+$/ ) || $self->suicide();
#			defined( $value = $row->[$column] ) || $self->suicide();
#			$column ? ( $sql = "SELECT id FROM history_x WHERE x=$column AND v='$value' AND p IN ( $sql )" ) : ( $sql = "SELECT id FROM history WHERE v='$value' AND p IN ( $sql )" );
#		}
#		if ( $variable ) {
#			$sql = "SELECT v, 1 FROM history_x WHERE x=$variable AND id IN ( $sql ) GROUP BY v";
#			if ( $init ) {
#				my %results = $self->{DBA}->getHash( $sql );
#				foreach ( keys %{$candidates} ) { $results{$_} || delete( $candidates->{$_} ) };
#			}
#			else {
#				%{$candidates} = $self->{DBA}->getHash( $sql );
#				$init = 1;
#			}
#		}
#	}
#
#	if ( $variable ) {
#		foreach ( keys %{$candidates} ) {
#			( $_ && m/^\d+$/ ) || $self->suicide();
#			( $self->{USR} != $self->{DBA}->getValue( "SELECT history.u FROM history_x LEFT JOIN history USING(id) WHERE history.c='$c' AND history.p=$p AND history_x.x=$variable AND history_x.v=$_ ORDER BY history.id DESC LIMIT 1" ) ) && return 0;
#		}
#	}
#	else {
#		scalar( @{$data} == 1 ) || $self->suicide();
#		( $owner = $self->{DBA}->getValue( "SELECT u FROM history WHERE id IN ( $sql ) ORDER BY id DESC LIMIT 1" ) ) && ( $owner != $self->{USR} ) && ( return 0 );
#	}
#	return 1;
}


sub isOwner {
	my $self	= shift;
	my $c		= shift;
	my $p		= shift;
	my $key 	= shift; #array that can be empty (single) or have undef values

	( $p =~ m/^[1-9]\d*$/ ) || $self->suicide();

	my $sql = "SELECT id FROM history WHERE c='$c' AND p=$p";
	my $x = 0;
	foreach ( @{$key} ) {
		defined ( $_ ) && ( $x ? ( $sql = "SELECT id FROM history_x WHERE x=$x AND v='$_' AND id IN ($sql)" ) : ( $sql .= " AND x0='$key->[0]'" ) );
		$x++;
	}
	$sql .= " ORDER BY id DESC LIMIT 1";

	my $id;
	( $id = $self->{DBA}->getValue( $sql ) ) && ( ( $self->{DBA}->getValue( "SELECT u FROM history WHERE id=$id" ) == $self->{USR} ) ? ( return 1 ) : ( return 0 ) );

	return 1;
}

sub logIt {
	my $self	= shift;
	my $child	= shift;
	my $p		= shift;
	my $data	= shift;
	my $type	= shift;#0->delete, 1->create, 2->change

	my $user = $self->{USR};
	( $p && ( $p =~ m/^\d+$/ ) ) || $self->suicide();
	( ref( $data ) eq 'ARRAY' ) || $self->suicide();
	( $type eq '0' ) || ( $type eq '1' ) || ( $type eq '2' ) || $self->suicide();

	my $record = { d => 'NOW()', u => $user, c => $child, p => $p, t => $type };
	
	if ( defined( $data->[0] ) ) {
			( ref( $data->[0] ) eq ''  ) || $self->suicide( "WARNING - not logged for $child.id=$p" );
		$record->{x0} = $data->[0];
	}
	elsif ( $type ) {
		$self->suicide( "WARNING - not logged for $child.id=$p" );
	}

	my $id = $self->{DBA}->insertRecord( 'history', $record );

	my $x;
	for ( $x = 1; $x < scalar( @{$data} ); $x++ ) { $self->{DBA}->insertRecord( 'history_x', { id => $id, x => $x, v => $data->[$x] } ) };
}

sub setUser{
	my $self = shift;
	my $user = shift;
	( $user =~ m/^\d+$/ ) || $self->suicide("setUser: PE ($user)");
	$self->{USR} = "$user";
	return $user;
}
1;
