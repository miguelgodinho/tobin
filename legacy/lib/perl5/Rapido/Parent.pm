# (C) Miguel Godinho de Almeida - miguel@datindex.com 2004
package Rapido::Parent;

use strict;
use warnings;
use Rapido::Child;

sub new {#rev5
  my ( $param )	= shift;
  my $self	= shift;
  my $class	= ref( $param ) || $param;
  bless( $self, $class );
  my $member;
  my $parent;
  my $pos;

  defined( $self->{HLP} )								|| die( "NO HELPER" );
  defined( $self->{USR} )								|| $self->{HLP}->suicide();
  defined( $self->{CODE}	)							|| $self->{HLP}->suicide();
  defined( $self->{ID} )								|| $self->{HLP}->suicide();
  defined( $self->{DBA} )								|| $self->{HLP}->suicide();
  defined( $self->{NAME} )							|| $self->{HLP}->suicide();
  defined( $self->{ALLCHILDREN} )						|| $self->{HLP}->suicide();
  defined( $self->{FLAGS} )							|| $self->{HLP}->suicide();
  $self->{AUTH}										|| $self->{HLP}->suicide( "User $self->{USR} has no auth to access $self->{CODE}" );
  $self->{FLAGS}->{ADMIN} && ( ( $self->{USR} == 1 )	|| $self->{HLP}->suicide( "SECURITY FAULT" ) );
  if( $self->{FLAGS}->{NOLOG} ) {
    $self->{LOG} = undef;
  }
  else {
    ( $self->{USR} eq $self->{LOG}->{USR} )			|| $self->{HLP}->suicide();
  }

  $self->{data} || ( $self->{data} = {} );
  defined( $self->{data}->{SAVED} ) || ( $self->{data}->{SAVED} = $self->{ID} );

  foreach $member ( values( %{$self->{ALLCHILDREN}} ) ) {
    if( $member->{PARENT} eq $self->{CODE} ) {
      my $child		= {};
      my $code		= $member->{CODE};
      $self->{HLP}->copyData( $member, $child );
      if( defined( $self->{data}->{$code}->{CONF} ) ) {
        defined( $self->{data}->{$code}->{data} ) || $self->{HLP}->suicide();
        defined( $self->{data}->{$code}->{STO} ) || $self->{HLP}->suicide();
      }
      else {
        $self->{data}->{$code}->{CONF}	= {};
        $self->{data}->{$code}->{data}	= [];
        $self->{data}->{$code}->{STO}	= [];
      }
      $child->{ID}	= $self->{ID};
      $child->{DBA}	= $self->{DBA};
      $child->{LOG}	= $self->{LOG};
      $child->{USR}	= $self->{USR};
      $child->{HLP}	= $self->{HLP};
      $child->{AUTH}	= $self->{AUTH};
      $child->{data}	= $self->{data}->{$code}->{data};
      $child->{CONF}	= $self->{data}->{$code}->{CONF};
      $child->{STO}	= $self->{data}->{$code}->{STO};
      $self->{CHILDREN}->{$child->{CODE}} = new Rapido::Child( $child );
    }

    $pos = 0;
    foreach $parent ( @{$member->{UNCLES}} ) {
      ( $parent eq $self->{CODE} ) && ( $self->{NEPHEWS}->{$member->{CODE}} = [ $member->{PARENT}, $pos ] );
      $pos++;
    }
  }
  return $self;
}

sub checkData {
  my $self	= shift;
  my $save	= shift;
  my $errors	= [];
  my $childCode;
  my $child;

  $self->{FLAGS}->{NOCHK} && $self->{HLP}->suicide();
  $self->{FLAGS}->{ADMIN} && ( $self->{USR} != 1 ) && $self->{HLP}->suicide();
  #ToDo - verify ownership
  foreach $childCode ( $self->{HLP}->sortHash( $self->{CHILDREN}, 'PRIORITY' ) ) {
    $child = $self->{CHILDREN}->{$childCode};
    $child->checkLocks( $save );
    foreach( $child->checkData() ) { push( @{$errors}, "$child->{NAME}: $_" ) };
   }
  return @{$errors};
}

sub findRelations {
  my $self		= shift;
  my $relative	= shift;
  my $a_flags		= shift;
  my $brothers	= {};
  my $code;
  my $attribs;

  my $flag = {};
  foreach ( @{$a_flags} ) {
    ( $_ eq 'FIRSTEXT' ) ||
    ( $_ eq 'BROTHERS' ) ||
    ( $_ eq 'EXTERNAL' ) ||
    ( $_ eq 'FIRST' ) ||
    $self->{HLP}->suicide( $_ );
    $flag->{"$_"} = 1;
  }

  if ( $flag->{FIRSTEXT} ) {
    while ( ( $code, $attribs ) = each %{$self->{NEPHEWS}} ) {
      $self->{DBA}->getValue( "SELECT p FROM $code WHERE x$attribs->[1]=$self->{ID}", [ 'FIRSTROW' ] ) && return 1;
    }
  }
  elsif ( $flag->{BROTHERS} ) {
    while ( ( $code, $attribs ) = each %{$self->{NEPHEWS}} ) {
      $brothers->{$attribs->[0]} ? $self->{HLP}->suicide( 'rethink about it!' ) : ( $brothers->{$attribs->[0]} = $code );
    }
    return %{$brothers};
  }
  else {
    $self->{HLP}->suicide();
  }
  return 0;
}

sub isSaved {#rev5
  my $self	= shift;
  my $hlp		= $self->{HLP};
  my $conserved;
  my $ref;
  my $code;

  if( $conserved = $self->{data}->{SAVED} ) {
    return $conserved;
  }
  elsif( $conserved = $self->{ID} ) {
    while ( $conserved && ( ( $code, $ref ) = each( %{$self->{CHILDREN}} ) ) ) { $hlp->compareData( $ref->{STO}, $ref->{data} ) || ( $conserved = 0 ) };
    return ( $self->{data}->{SAVED} = $conserved );
  }
  else {
    return 0;
  }
}

sub recycle {
  my $self	= shift;

  foreach( values( %{$self->{CHILDREN}} ) ) {
    $_->checkLocks();
    $_->initData();
  }

  $self->{data}->{SAVED} = $self->{ID};
}

sub save {
  my $self		= shift;
  my $a_errors	= shift;
  my $dba			= $self->{DBA};
  my $hlp			= $self->{HLP};
  my $allOK		= 1;
  my $child;
  my $childCode;

  scalar( @{$a_errors} )											&& $hlp->suicide( "update: errors array must be empty" );
  ( $self->{AUTH} > 1 )											|| $hlp->suicide();
  ( $dba->getLock( $self->{CODE} ) == 2 )							|| $hlp->suicide( "NO WRITE LOCK TO DELETE $self->{CODE}=$self->{ID}" );
  foreach( keys( %{$self->{NEPHEWS}} ) ) { $dba->getLock( $_ )	|| $hlp->suicide( "NO READ LOCK TO NEPHEW $_" ) };
  foreach ( $self->checkData( 'SAVE' ) ) {
    $allOK = 0;
    push( @{$a_errors}, $_ );
   }

   if( $allOK ) {
     if( $self->{ID} ) {
      foreach $childCode( $self->{HLP}->sortHash( $self->{CHILDREN}, 'PRIORITY' ) ) {
        $child = $self->{CHILDREN}->{$childCode};
        $child->serialize();
      }
     }
     else {
      $self->{ID} = $self->{DBA}->insertRecord( $self->{CODE}, undef, [ 'EMPTY' ] );
      foreach $childCode( $self->{HLP}->sortHash( $self->{CHILDREN}, 'PRIORITY' ) ) {
        $child = $self->{CHILDREN}->{$childCode};
        $child->setID( $self->{ID} );
        $child->serialize();
      }
     }
     $self->{data}->{SAVED} = $self->{ID};
   }
   else {
     $self->{data}->{SAVED} = 0;
   }

   return $self->{data}->{SAVED};
}

sub delete {#bool
  my $self		= shift;
  my $a_errors	= shift;
  my $a_warnings	= shift;
  my $dba			= $self->{DBA};
  my $hlp			= $self->{HLP};
  my $allEmpty	= 1;
  my $child;
  my $childCode;

  #warn Dumper($a_errors);
  #scalar( @{$a_errors} )					&& $hlp->suicide( "update: errors array is not empty: @{$a_errors}" );
  $self->{ID}								|| $hlp->suicide( "CANNOT DELTE $self->{CODE} WITHOUT ID" );
  ( $self->{AUTH} > 1 )					|| $hlp->suicide();
  ( $dba->getLock( $self->{CODE} ) ==  2)	|| $hlp->suicide( "NO WRITE LOCK TO DELETE $self->{CODE}=$self->{ID}" );
  foreach( keys( %{$self->{NEPHEWS}} ) ) {
    $dba->getLock( $_ )						|| $hlp->suicide( "NO READ LOCK TO NEPHEW $_" );
  }
  foreach( values( %{$self->{CHILDREN}} ) ) {
    $_->checkLocks( 1 );
  }

  if( $self->findRelations( '', [ 'FIRSTEXT' ] ) ) {
    push(@{$a_errors}, "Cannot delete while external relations persist" );
    $allEmpty = 0;
  }
  else {
    foreach $childCode ( $self->{HLP}->sortHash( $self->{CHILDREN}, 'PRIORITY' ) ) {
      $child = $self->{CHILDREN}->{$childCode};
      $child->update( [], 1, $a_errors, $a_warnings );
      foreach( @{$a_errors} ) { warn $_ };
      $child->serialize();
      $allEmpty && @{$child->{data}} && ( $allEmpty = 0 );
    }
  }

  if( $allEmpty ) {
    $self->{LOG} && $self->{LOG}->logIt( $self->{CODE}, $self->{ID}, [], 0 );
    $self->{DBA}->deleteRecord( $self->{CODE}, { id => $self->{ID} } );
    while( ( $childCode, $child ) = each( %{$self->{CHILDREN}} ) ) {
      $child->{ID}	= undef;
      $child->{STO}	= undef;
      $child->{data}	= undef;
      delete( $self->{CHILDREN}->{$childCode} );
    }
    $self->{data}	= undef;
    $self->{ID}		= undef;

    return 1;
  }
  return 0;
}

1;
