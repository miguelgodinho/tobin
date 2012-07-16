# (C) Miguel Godinho de Almeida - miguel@datindex.com 2004
package Rapido::Child;

use strict;
use warnings;
use vars qw($VERSION @ISA @EXPORT_OK);
use Exporter;

@ISA = ( 'Exporter');
$VERSION = '1.00';
@EXPORT_OK = qw();

sub new { 
	my $param 	= shift;
	my $self	= shift;
	my $class 	= ref( $param ) || $param;
	bless( $self, $class );
	$self->initTestStructure();

	if( $self->{TYPE} eq 'SINGLE' ) {
		$self->initTypeSingle();
	}
	elsif( $self->{TYPE} eq 'SET' ) {
		$self->initTypeSet();
	}
	elsif( $self->{TYPE} eq 'LINK' ) {
		$self->initTypeLink();
	}
	elsif( $self->{TYPE} eq 'SERIE' ) {
		$self->initTypeSerie();
	}
	elsif( $self->{TYPE} eq 'COMPLEX' ) {#THE ONLY TYPE EVALUATED BY CODE
		$self->initTypeComplex();
	}
	else {
		$self->{HLP}->suicide( "$self->{TYPE} IS NOT SUPPORTED TYPE" );
	}

	$self->{MAIN} && $self->{UNCLES}->[$self->{MAIN}] && $self->{HLP}->suicide();
	$self->{FORK} && $self->initFork(); 
	$self->initAllows();
	$self->initData();

	return $self;
}

sub checkData {
	my $self	= shift;
	my $errors	= [];
	my $entry	= [];
	my $main	= 0;
	
	if( !$self->isFresh ) {
		push( @{$errors}, "$self->{NAME} is outdated, please refresh" );	
	}
	elsif( @{$self->{data}} ) {
		foreach( @{$self->{data}} ) {
			@{$entry} = @{$_};
			$self->testEntry( $entry, $errors );
			$self->{MAIN} && $entry->[$self->{MAIN}] && ( $main ? ( push( @{$errors}, "$self->{NAME} has more than 1 main entry" ) ) : ( $main = 1 ) );
		}

		$self->{MAIN} && ( $main || push( @{$errors}, "$self->{NAME} has no main entry" ) );
	}
	elsif( @{$self->{REQS}} ) {
		( $self->{REQS}->[0] == 0 ) && push( @{$errors}, "$self->{NAME} Requires one value" );
	}
	
	@{$errors} && ( $self->{CONF}->{dataok} = 0 );
	return @{$errors};
}


sub checkLocks {#dies if req lock does not exist
	my $self	= shift;
	my $write	= shift;#input
	my $dba		= $self->{DBA};
	my $hlp		= $self->{HLP};
	
	if( $write ) {
		( $dba->getLock( $self->{CODE} ) == 2 ) || $hlp->suicide( "$self->{CODE} has no write lock" );
		$self->{FLAGS}->{NOLOG} || ( ( $dba->getLock( 'history' ) == 2 ) && ( $dba->getLock( 'history_x' ) == 2 ) ) || $hlp->suicide( "history/history_x has write no lock" );
	}
	else {
		$dba->getLock( $self->{CODE} ) || $hlp->suicide( "$self->{CODE} has no lock" );
		$self->{FLAGS}->{NOLOG} || ( $dba->getLock( 'history' ) && $dba->getLock( 'history_x' ) ) || $hlp->suicide();
	}
	foreach( @{$self->{UNCLES}} ) { $_ && ( $dba->getLock( $_ ) || $hlp->suicide( "$_ has no lock" ) ) };
}

sub getLastHistoricSerial {
	my $self	= shift;
	
	( caller() eq 'Rapido::Child' ) || $self->{HLP}->suicide();
	if( $self->{SERIAL} && !$self->{FLAGS}->{NOLOG} && $self->{ID} ) {
		return $self->{DBA}->getValue( "SELECT IFNULL(MAX(history_x.v), 0 ) FROM history LEFT JOIN history_x USING(id) WHERE history.c='$self->{CODE}' AND history.p=$self->{ID} AND history_x.x=$self->{SERIAL}" );#IF SERIAL=0, THEN TABLE history NEEDS TO BE CHECKED
	}	
	else {
		return 0;
	}
}

sub getUniques {
	my $self	= shift;
	my $input	= shift;#input, matrix;
	my $output	= shift;#output, hash;
	my $entry;
	my $unique;
	
	( caller() eq 'Rapido::Child' ) || $self->{HLP}->suicide();
	%{$output}						&& $self->{HLP}->suicide();
	
	foreach $entry ( @{$input} ) {
		$self->{SERIAL} && !$entry->[$self->{SERIAL}] && $self->{HLP}->suicide( $self->{CODE} );
		$unique = '';
		foreach ( @{$self->{IDS}} ) { $unique .= lc( $entry->[$_] )."\000" };
		$output->{$unique} ? $self->{HLP}->suicide( "$self->{CODE}.$unique" ) : ( $output->{$unique} = [ @{$entry} ] );
	}
}

sub initAllows {
	my $self	= shift;
	my $value;
	my $pos;
	
	( caller() eq 'Rapido::Child' ) || $self->{HLP}->suicide();
	if( $self->{USR} != 1 ) {
		for( $pos = 0; $pos < scalar( @{$self->{ALLOWS}} ); $pos++ ) {
			foreach $value ( split( /,/, $self->{ALLOWS}->[$pos] ) ) { ( !$value && ( $self->{FIELDS}->[$pos] eq 'USER' ) ) ? ( $self->{ALLOWSHASH}->{"$pos"}->{"$self->{USR}"} = 1 ) : ( $self->{ALLOWSHASH}->{"$pos"}->{"$value"} = 1 ) };
		}
	}
	else {
		#2DO: think what su can and cannot do...	
	}
}

sub initData {
	my $self	= shift;
	my $hlp		= $self->{HLP};
	my $caller	= caller();
	
	if( $caller eq 'Rapido::Child' ) {
		if( $self->{CONF}->{dataloaded} ){
			defined( $self->{data} )	|| $hlp->suicide();	
			defined( $self->{STO} )		|| $hlp->suicide();
		}
		else {
			if( $self->{ID} ) {
				@{$self->{STO}} = $self->unserialize();	
				$self->getLastHistoricSerial();
				$hlp->copyData( $self->{STO}, $self->{data} );
			}
			$self->{CONF}->{dataloaded} = 1;	
		}
	}
	elsif( $caller eq 'Rapido::Parent' ) {
		( defined( $self->{data} ) && defined( $self->{STO} ) ) || $hlp->suicide();
		if( $self->{ID} ) {
			@{$self->{STO}} = $self->unserialize();
			$self->getLastHistoricSerial();
			$hlp->copyData( $self->{STO}, $self->{data} );
		}
		else {
			@{$self->{STO}} && $hlp->suicide();
			@{$self->{data}} = ();	
		}
	}
	else {
		$hlp->suicide();
	}
	
	$self->{SERIAL} && $self->initLastSerial();
	( @{$self->{data}} || !@{$self->{REQS}} ) ? ( $self->{CONF}->{dataok} = 1 ) : ( $self->{CONF}->{dataok} = 0 );
}

sub initFork {
	my $self	= shift;
	my $pos 	= 0;
	
	( caller() eq 'Rapido::Child' ) || $self->{HLP}->suicide();
	$self->{UNCLES}->[$self->{FORK}] && $self->{HLP}->suicide();
	foreach( @{$self->{IDS}} ) { ( $_ eq $self->{FORK} ) && ( $pos ? $self->{HLP}->suicide() : ( $pos = $_ ) ) };
	$pos || $self->{HLP}->suicide();
}

sub initLastSerial {
	my $self		= shift;
	my $lastSerial;
	
	( caller() eq 'Rapido::Child' )		|| $self->{HLP}->suicide();
	$self->{UNCLES}->[$self->{SERIAL}]	&& $self->{HLP}->suicide();
	
	unless( $self->{ID} && !$self->{FLAGS}->{NOLOG} && defined( $lastSerial = $self->{CONF}->{lastHistoricSerial} ) ) {
		$lastSerial = 0;
	}
	
	foreach( @{$self->{data}} ) {
		( $_->[$self->{SERIAL}] > $lastSerial ) && ( $lastSerial = $_->[$self->{SERIAL}] );
	}
	$self->{LASTSERIAL} = $lastSerial;
}

sub initTestStructure {
	my $self	= shift;
	my $pos		= shift;
	
	( caller() eq 'Rapido::Child' ) || $self->{HLP}->suicide();
	foreach( keys( %{$self->{FLAGS}} ) ) {
		( $_ eq 'NOLOG'		) ||
		( $_ eq 'RO'   		) ||	
		( $_ eq 'NOREPSCS'	) || #x0 cannot be repeated even if not part of the key 
		( $_ eq 'NOREPSCI'	) || #lc(x0) cannot be repeated even if not part of the key
		( $_ eq 'NOBLANK'	) || #no blank spaces on x0
		( $_ eq 'PAGE' 		) ||
		( $_ eq 'STOICH'	) ||
		( $_ eq 'MAP'		) ||
		$self->{HLP}->suicide( "$self->{CODE} flag $_ is not supported" );
	}
	defined( $self->{LOG} ) || $self->{FLAGS}->{NOLOG} || $self->{HLP}->suicide( "Log is required" );

	( scalar( @{$self->{FIELDS}} ) == ( scalar( @{$self->{LABELS}}	) ) )	|| $self->{HLP}->suicide( $self->{CODE} );
	( scalar( @{$self->{FIELDS}} ) >=  ( scalar( @{$self->{UNCLES}}	) ) )	|| $self->{HLP}->suicide( $self->{CODE} );
	( scalar( @{$self->{FIELDS}} ) >=  ( scalar( @{$self->{IDS}}	) ) )	|| $self->{HLP}->suicide( $self->{CODE} ); 

	for( $pos = scalar( @{$self->{DEFAULTS}} ); $pos < scalar( @{$self->{FIELDS}} ); $pos++ ) { push( @{$self->{DEFAULTS}}, '' ) };
	foreach $pos ( @{$self->{IDS}} ) { $self->{KEYS}->{$pos} ? $self->{HLP}->suicide( $self->{CODE} ) : ( $self->{KEYS}->{$pos} = 1 ) };
}

sub initTypeComplex {
	my $self		= shift;
	
	( caller() eq 'Rapido::Child' ) || $self->{HLP}->suicide();
	( scalar( @{$self->{FIELDS}} ) == 2	) 	|| $self->{HLP}->suicide();	
	( $self->{FIELDS}->[0] eq 'VALUE'	)	|| $self->{HLP}->suicide();
	( $self->{FIELDS}->[1] eq 'SERIAL'	)	|| $self->{HLP}->suicide();
	( scalar( @{$self->{IDS}} )	== 2	)	|| $self->{HLP}->suicide();
	( $self->{IDS}->[0]	== 1			)	|| $self->{HLP}->suicide();
	( $self->{IDS}->[1]	== 0			)	|| $self->{HLP}->suicide();
	$self->{SERIAL} = 1;
}

sub initTypeLink {
	my $self		= shift;
	
	( caller() eq 'Rapido::Child' ) || $self->{HLP}->suicide();
	( "@{$self->{FIELDS}}" eq 'LINK USER' ) || $self->{HLP}->suicide();
	( "@{$self->{IDS}}" eq '1 0' ) || $self->{HLP}->suicide();
	$self->{UNCLES}->[0] && $self->{HLP}->suicide();
	$self->{UNCLES}->[1] || $self->{HLP}->suicide();
}

sub initTypeSerie {
	my $self		= shift;
	my $pos;
	
	( caller() eq 'Rapido::Child' ) || $self->{HLP}->suicide();
	for( $pos = 0; $pos < scalar( @{$self->{FIELDS}} ); $pos++ ) {
		if( $self->{FIELDS}->[$pos] eq 'SERIAL' ) {
			$pos || $self->{HLP}->suicide();
			$self->{SERIAL} ? $self->{HLP}->suicide() : ( $self->{SERIAL} = $pos );
		}
		elsif( $self->{FIELDS}->[$pos] eq 'MAIN' ) {
			$pos || $self->{HLP}->suicide();
			$self->{MAIN} ? $self->{HLP}->suicide() : ( $self->{MAIN} = $pos );
		}
		elsif( $self->{FIELDS}->[$pos] ne 'VALUE' ) {
			$self->{HLP}->suicide();
		}
	}
	$self->{SERIAL} || $self->{HLP}->suicide( "@{$self->{FIELDS}}" );
	( scalar( @{$self->{IDS}} ) == 1 ) || $self->{HLP}->suicide();
	( $self->{IDS}->[0] eq $self->{SERIAL} ) || $self->{HLP}->suicide();
}

sub initTypeSet {
	my $self		= shift;
	my $pos;
	
	( caller() eq 'Rapido::Child' ) || $self->{HLP}->suicide();
	( $self->{IDS}->[0] == 0 ) || $self->{HLP}->suicide();
	for( $pos = 0; $pos < scalar( @{$self->{FIELDS}} ); $pos++ ) {
		if ( $self->{FIELDS}->[$pos] eq 'MAIN' ) {
			$pos || $self->{HLP}->suicide();
			$self->{MAIN} ? $self->{HLP}->suicide() : ( $self->{MAIN} = $pos );
		}
		elsif ( $self->{FIELDS}->[$pos] eq 'FORK' ) {
			$pos || $self->{HLP}->suicide();
			$self->{FORK} ? $self->{HLP}->suicide( 'not implemented' ) : ( $self->{FORK} = $pos );
		}
		elsif ( $self->{FIELDS}->[$pos] eq 'STOICH' ) {
			$pos						|| $self->{HLP}->suicide();
			$self->{FLAGS}->{STOICH}	|| $self->{HLP}->suicide();
			$self->{FORK}				|| $self->{HLP}->suicide();
			$self->{STOICH}				= $pos;
		}
		elsif ( $self->{FIELDS}->[$pos] ne 'VALUE' ) {
			$self->{HLP}->suicide();
		}
	}
}

sub initTypeSingle {
	my $self		= shift;
	
	( caller() eq 'Rapido::Child' ) || $self->{HLP}->suicide();
	@{$self->{IDS}} && $self->{HLP}->suicide();
	( scalar( @{$self->{FIELDS}} ) == 1 ) || $self->{HLP}->suicide();
	if( $self->{FIELDS}->[0] eq 'USER' ) {
		$self->{UNCLES}->[0] || $self->{HLP}->suicide();	
	}
	elsif( $self->{FIELDS}->[0] ne 'VALUE' ) {
		$self->{HLP}->suicide();	
	}
}

sub isFresh {
	my $self	= shift;
	
	if( !$self->{ID} || $self->{HLP}->compareData( [ $self->unserialize() ], $self->{STO} ) ) {
		return 1;
	}
	else {
		$self->{CONF}->{dataok} = 0;
		return 0;
	}
}

sub refreshMainInData {
	my $self	= shift;
	my $data	= shift;
	my $main	= 0;

	( caller() eq 'Rapido::Child' ) || $self->{HLP}->suicide( $self->{CODE} );	
	if( @{$data} ) {
		foreach( @{$data} ) { ( $_->[$self->{MAIN}] ) && ( $main ? ( $_->[$self->{MAIN}] = 0 ) : ( $main = 1 ) ) };
		$main || ( $data->[0]->[$self->{MAIN}] = 1 );
	}
}

sub serialize { 
	my $self		= shift;
	my $auth		= 0;
	my $newUniques	= {};
	my $oldUniques	= {};
	my $unique;
	my $entry;
	my $i;
	
	( caller() eq 'Rapido::Parent' )	|| $self->{HLP}->suicide( $self->{CODE} );
	$self->{CONF}->{dataok}				|| $self->{HLP}->suicide( $self->{CODE} );
	$self->{ID}							|| $self->{HLP}->suicide( $self->{CODE} );
	$self->isFresh()					|| $self->{HLP}->suicide( $self->{CODE} );
	$self->checkLocks( 1 );

	$self->getUniques( $self->{STO}, $oldUniques );
	foreach $entry ( @{$self->{data}} ) { 
		$unique = '';
		foreach( @{$self->{IDS}} ) { $unique .= lc( $entry->[$_] )."\000" };
		$newUniques->{"$unique"} = [ @{$entry} ];

		if( defined( $oldUniques->{$unique} ) ) { 
			unless( $self->{HLP}->compareData( $entry, $oldUniques->{$unique} ) ) {
				my $recordKeys = { p => $self->{ID} };
				my $recordValues = {};
				
				for( $i = 0; $i < scalar( @{$entry} ); $i++ ) { $self->{KEYS}->{$i} ? ( $recordKeys->{"x$i"} = $entry->[$i] ) : ( $recordValues->{"x$i"} = $entry->[$i] ) };
				$self->{FLAGS}->{NOLOG} || $self->{LOG}->logIt( $self->{CODE}, $self->{ID}, $entry, 2 );
				$self->{DBA}->updateRecord( $self->{CODE}, $recordKeys, $recordValues );
			}
		}
		else {
			my $newEntry = { p => $self->{ID} };
			for( $i = 0; $i < scalar( @{$entry} ); $i++ ) { $newEntry->{"x$i"} = $entry->[$i] };
			$self->{FLAGS}->{NOLOG} || $self->{LOG}->logIt( $self->{CODE}, $self->{ID}, $entry, 1 );
			$self->{DBA}->insertRecord( $self->{CODE}, $newEntry );
		}
	}

	foreach $unique ( keys( %{$oldUniques} ) ) {
		unless( defined( $newUniques->{$unique} ) ) {
			$self->{FLAGS}->{NOLOG} || $self->{LOG}->logIt( $self->{CODE}, $self->{ID}, $oldUniques->{$unique}, 0 );
			my $recordID = { p => $self->{ID} };
			foreach( @{$self->{IDS}} ) { $recordID->{"x$_"} = $oldUniques->{$unique}->[$_] };
			$self->{DBA}->deleteRecord( $self->{CODE}, $recordID );
		}
	}

#	the simple way:
	$self->{HLP}->copyData( $self->{data}, $self->{STO} );
#	or the safe way:
#	@{$self->{STO}} = $self->unserialize();
#	$self->{HLP}->copyData( $self->{STO}, $self->{data} );
}

sub setID { 
	my $self	= shift;
	my $id		= shift;

	$self->{ID}					&& $self->{HLP}->suicide( $self->{CODE} );
	( $id =~ m/^[1-9]\d*$/ )	|| $self->{HLP}->suicide( $self->{CODE} );
	$self->{ID} = $id;
}

sub testEntry {#internal # if entry was elimitated then return 0, otherwise returns positive even with errors
	my $self				= shift;
	my $data				= shift;
	my $a_errors			= shift;
	my $n_errors			= scalar( @{$a_errors} );
	my $error;
	my $i;

	( caller() eq 'Rapido::Child' )							|| $self->{HLP}->suicide( "$self->{CODE}" );
	( scalar( @{$data} ) ==  scalar( @{$self->{FIELDS}} ) ) || $self->{HLP}->suicide( "$self->{CODE}" );
		
	$self->{STOICH} && ( $data->[$self->{STOICH}] =~ m/^-?0*$/ ) && ( @{$data} = () );
	( defined( $data->[0] ) && length( $data->[0] ) && ( !$self->{UNCLES}->[0] || $data->[0] ) ) || ( return ( @{$data} = () ) );

	for( $i = 0; $i < scalar( @{$data} ); $i++ ) {
		ref( $data->[$i] ) && $self->{HLP}->suicide( $self->{CODE} );
		( $data->[$i] =~ m/\000/ ) && $self->{HLP}->suicide( $self->{CODE} );
		$self->{FLAGS}->{NOBLANK} && ( $data->[$i] =~ m/\s/ ) && ( push( @{$a_errors}, "$self->{NAME} does not allow blank spaces on $self->{LABELS}->[$i]" ) );
		( $error = $self->{DBA}->getFormatError( $self->{CODE}, "x$i", $data->[$i], [ 'NOQUOTES', 'NOESCAPE' ] ) ) && ( push( @{$a_errors}, "$self->{NAME} with $self->{LABELS}->[$i]='$data->[$i]' " . $self->{DBA}->getErrorFromCode( $self->{CODE}, "x$i", $error ) ) );
		$self->{UNCLE}->[$i] && ( $self->{DBA}->getValue( "SELECT 1 FROM $self->{UNCLE}->[$i] WHERE id='$data->[$i]'" ) || $self->{HLP}->suicide( "$self->{CODE} testEntry: identity $self->{UNCLE}->[$i] = $data->[$i] does not exist" ) );
	}
	if( @{$self->{REQS}} && ( !$self->{REQS}->[0] || defined( $data->[ $self->{REQS}->[0] - 1 ] ) ) ) {
		foreach( @{$self->{REQS}} ) { defined( $data->[$_] ) || push( @{$a_errors}, "$self->{NAME}, $self->{LABELS}->[$_] requires a value" ) };
	}
	( scalar( @{$a_errors} ) ne $n_errors ) && ( $self->{CONF}->{dataok} = 0 );
	return scalar( @{$data} );
}

sub tryDeletions {#only owned data can be deleted
	my $self		= shift;
	my $oldUniques	= shift;
	my $newUniques	= shift;
	my $data		= shift;
	my $superWrite	= shift;
	my $warnings	= shift;
	my $keyArray	= [];
	my $unique;
	my $entry;
	my $i;
	
	( caller() eq 'Rapido::Child' ) || $self->{HLP}->suicide();
	
	if( !$superWrite || ( $self->{TYPE} eq 'LINK' ) ) {
		while( ( $unique, $entry ) = each %{$oldUniques} ) {
			unless( $newUniques->{$unique} ) {
				
				@{$keyArray} = ();
				for( $i = 0; $i < scalar( @{$entry} ); $i++ ) {
					if( $self->{KEYS}->{$i} && ( ( $self->{TYPE} ne 'COMPLEX' ) || $i ) ) {
						 push( @{$keyArray}, $entry->[$i] );
					}
					else {
						 push( @{$keyArray}, undef );
					}
				}
				
				if( ( $self->{TYPE} ne 'LINK' ) || $self->tryLinkDeletion( $entry, $data ) ) {
					unless ( $self->{LOG}->isOwner( $self->{CODE}, $self->{ID}, $keyArray ) ) {
						push( @{$data}, [ @{$entry} ] );
						push( @{$warnings}, "$self->{NAME}:$self->{ID}: Some data was not deleted (no auth)" );
					}
				}
			}
		}	
	}
}

sub tryInsertion {
	my $self			= shift;
	my $a_data			= shift;
	my $data			= shift;
	my $entry			= shift;
	my $lastX0s			= shift;
	my $oldValues		= shift;
	my $newValues		= shift;
	my $xferComplexes	= shift;
	my $superWrite		= shift;
	my $warnings		= shift;
	my $keyArray		= [];
	my $pos2skip		= {};#to be used by isInsertable with serie
	my $unique			= '';
	my $ok;
	my $i;
	my $x0;
	
	( caller() eq 'Rapido::Child' ) || $self->{HLP}->suicide();
	foreach ( @{$self->{IDS}} ) { $unique .= lc( $entry->[$_] )."\000" };
	$self->{FLAGS}->{NOREPSCS} ? ( $x0 = $entry->[0] ) : ( $self->{FLAGS}->{NOREPSCI} ? ( $x0 = lc( $entry->[0] ) ) : ( $x0 = '' ) );
	unless( $newValues->{$unique} || $lastX0s->{$x0} ) {
		$self->{SERIAL} && ( $self->{TYPE} ne 'COMPLEX' ) && ( $pos2skip->{"$self->{SERIAL}"} = 1 );
		for ( $i = 0; $i < scalar( @{$entry} ); $i++ ) { ( $self->{KEYS}->{$i} && ( ( $self->{TYPE} ne 'COMPLEX' ) || $i ) ) ? ( push( @{$keyArray}, $entry->[$i] ) ) : ( push( @{$keyArray}, undef ) ) };
		length( $x0 ) && ( $lastX0s->{$x0} = 1 );
		$newValues->{$unique} = [ @{$entry} ];
		if( $oldValues->{$unique} ) {
			if( $self->{HLP}->compareData( $entry, $oldValues->{$unique} ) ) {
				push( @{$data}, [ @{$entry} ] );
			}
			elsif( !$self->{ID} || $superWrite || ( $self->{LOG}->isOwner( $self->{CODE}, $self->{ID}, $keyArray ) && $self->{LOG}->isInsertable( $self->{CODE}, $self->{ID}, $a_data, $keyArray, $pos2skip ) ) ) {
				#this situation will never happen with complexes as all values are part of the key. It may be simplified... 
				$ok = 1;
				$i = 0;
				foreach( @{$entry} ) {
					$self->{ALLOWSHASH}->{$i} && !$self->{ALLOWSHASH}->{$i}->{$_} && ( $ok = 0 );
					$i++;
				}
				$ok ? ( push( @{$data}, [ @{$entry} ] ) ) : ( warn "UNAUTHORIZED OPERATION!!!!" );
			}
			else {
				push( @{$data}, [ @{$oldValues->{$unique}} ] );
				push( @{$warnings},  "No authorization to insert or modify value for $self->{NAME}" );
			}
		}
		elsif( !$self->{ID} || $superWrite || $self->{LOG}->isInsertable( $self->{CODE}, $self->{ID}, $a_data, $keyArray, $pos2skip ) ) {
			if( $self->{SERIAL} && ( $entry->[$self->{SERIAL}] < 1 ) ) {
				if( $xferComplexes->{$entry->[$self->{SERIAL}]} ) {
					 ( $self->{TYPE} eq 'COMPLEX' ) || $self->{HLP}->suicide( $self->{CODE} );
				}
				else {
					 $xferComplexes->{"$entry->[$self->{SERIAL}]"} = ++$self->{LASTSERIAL};
				}
				$entry->[$self->{SERIAL}] = $xferComplexes->{$entry->[$self->{SERIAL}]};
			}
			$ok = 1;
			$i = 0;
			foreach( @{$entry} ) { $self->{ALLOWSHASH}->{$i} && !$self->{ALLOWSHASH}->{$i}->{$_} && ( $ok = 0 );
				$i++;
			}
			$ok ? ( push( @{$data}, [ @{$entry} ] ) ) : ( warn "UNATHORIZED OPERATION!!!!" );
		}
		else {
			push( @{$warnings}, "$self->{NAME}: Unauthorized data was deleted" );
		}
	}
}

sub tryLinkDeletion {
	my $self	= shift;
	my $entry	= shift;
	my $data	= shift;
	my $lnkUsr	= $entry->[1];
	
	( caller() eq 'Rapido::Child' )		|| $self->{HLP}->suicide();
	( $self->{TYPE} eq 'LINK' ) 		|| $self->{HLP}->suicide();
	
	if( (	$self->{USR} != 1 ) ||
		(	$lnkUsr != $self->{USR} ) ||
			!$self->{ALLOWSHASH}->{1}->{$lnkUsr} ) {
			push( @{$data}, [ @{$entry} ] );
			return 0;
	}
	return 1;
}

sub update {#returns bool
	my $self				= shift;	
	my $a_data				= shift;#input/output
	my $delete				= shift;#input, bool, if update is for deletion
	my $a_errors			= shift;#output, appends
	my $a_warnings			= shift;
	my $data				= [];
	my $lastX0s				= {};
	my $oldValues			= {};
	my $newValues			= {};
	my $xferComplexes		= {};
	my $initErrorsNumber	= scalar ( @{$a_errors} );
	my $hlp					= $self->{HLP};
	my $superWrite			= 0;
	
	ref( $a_errors ) || $self->{HLP}->suicide();
	if( $self->{AUTH} < 2 ) {
		$hlp->compareData( $a_data, $self->{STO} ) || $hlp->suicide( 'NO AUTH TO CHANGE RECORD $self->{CODE}=$self->{ID}');	
		return 1;
	}
	elsif( !$self->isFresh() ) {
		push( @{$a_errors}, "Info for $self->{NAME} is outdated - please reload" );
		return 0;
	}
	elsif( ( $self->{AUTH} == 3 ) || $self->{FLAGS}->{NOLOG} ) {
		$superWrite = 1;	
	}
	$self->{CONF}->{dataok}	= 0;
	
	( $self->{TYPE} eq 'SINGLE' ) && ( scalar( @{$a_data} ) > 1 ) && $hlp->suicide( $self->{CODE} );

	$self->getUniques( $self->{data}, $oldValues );

	if( !$delete ) {
		foreach( @{$a_data} ) {
			if( $self->testEntry( $_, $a_errors ) ) {
				$self->tryInsertion( $a_data, $data, $_, $lastX0s, $oldValues, $newValues, $xferComplexes, $superWrite, $a_warnings );	
			}
		}
	}

	$self->{ID} && $self->tryDeletions( $oldValues, $newValues, $data, $superWrite, $a_warnings );
	if( @{$data} ) {
		@{$data} = $self->{HLP}->sortMatrix( $data, $self->{IDS} );
		$self->{MAIN} && $self->refreshMainInData( $data );
		$self->{HLP}->copyData( $data, $self->{data} );
		$self->{HLP}->copyData( $data, $a_data );
	}
	else{
		!$delete && @{$self->{REQS}} && ( $self->{REQS}->[0] == 0 ) && push( @{$a_errors}, "$self->{NAME}: Value is required" );
		@{$self->{data}}	= ();
		@{$a_data}			= ();
	}

	( $initErrorsNumber == scalar( @{$a_errors} ) ) ? ( $self->{CONF}->{dataok} = 1 ) : ( $self->{CONF}->{dataok} = 0 );
	return $self->{CONF}->{dataok};
}

sub unserialize {
	my $self = shift;
	my $sql = 'SELECT x0';
	my $order = '';
	my $i;
	
	( caller() eq 'Rapido::Child' ) || $self->{HLP}->suicide();
	$self->{ID} || $self->{HLP}->suicide( $self->{CODE} );
	
	for ( $i = 1; $i < scalar( @{$self->{FIELDS}} ); $i++ ) { $sql .= ", IFNULL(x$i, '' )" };
	$sql .= " FROM $self->{CODE} WHERE p=$self->{ID}";
	foreach ( @{$self->{IDS}} ) { $order ? ( $order .= ", x$_" ) : ( $order = "ORDER BY x$_" ) };
	return $self->{DBA}->getMatrix( "$sql $order");
}

1;
