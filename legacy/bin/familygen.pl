#!/usr/bin/perl
# (C) Miguel Godinho de Almeida - miguel@datindex.com 2005


use strict;
use warnings;

use Rapido::DBAccessor;
my $database		= $ARGV[0]; #name of the database where definitions are stored
my $domain			= $ARGV[1]; #name of the domain to retrieve definitions from

( $domain =~ m/^([a-z])(.+)/ ) || die( "No domainlication defined" );
my $capitalDomain = $1;
$capitalDomain =~ tr/[a-z]/[A-Z]/;
$capitalDomain .= $2;

my $DB_HOST		= 'localhost';
my $DB_USER		= 'root';
my $DB_PASS		= '';
my $DB_DATA		= $database;
my $parent_tbl	= $domain.'_parent';
my $child_tbl	= $domain.'_child';
my $domain_tbl	= $domain.'_constant';
my $models_tbl	= $domain.'_model';
my $t2			= "\t\t";
my $t3			= "\t\t\t";
my $t4			= "\t\t\t\t";
my $t5			= "\t\t\t\t\t";
my $t6			= "\t\t\t\t\t\t";
my $t7			= "\t\t\t\t\t\t\t";
my $t8			= "\t\t\t\t\t\t\t\t";
my $constants	= {#1=parent, 2=child
	FLAGS	=> {
		TREE		=> ( 1 ),
		FIXED		=> ( 1 ),
		ELINK		=> ( 1 ),
		ILINK		=> ( 1 ),
		ADMIN		=> ( 1 ),
		STOICH		=> ( 1 | 2 ),
		NOCHK		=> ( 1 ),
		NOBLANK		=> ( 2 ),
		NOLOG		=> ( 1 | 2 ),
		PAGE		=> ( 2 ),
		RO			=> ( 1 | 2 ),
		NOREPSCI	=> ( 2 )
	},

#	TYPE	=> {
#		SINGLE		=> 1,
#		SERIE		=> 1,
#		SET			=> 1,
#		LINK		=> 1,
#		COMPLEX		=> 1,
#	}
};
my $PARENTS		= {};
my $CHILDREN	= {};
my $MODELS		= {};
my $CONST		= {};
my $sortedKeys	= [];
my $tableDesc	= [];
my $sqlTypes	= {};#{ table => {field => type, ... }, ... }
my $myType;
my $key;
my $value;
my $parent;
my $child;
my $model;
my $found;
my $fieldType;
my $pos;
my @matrix;
my $row;
my $readonly;


my $dba = new Rapido::DBAccessor(	{
	CHK		=> 1,
	DB_HOST => $DB_HOST,
	DB_USER => $DB_USER,
	DB_PASS => $DB_PASS,
	DB_DATA => $DB_DATA
} );
								
@matrix = $dba->getMatrix( "DESCRIBE domain" );
foreach $row ( @matrix ) {
	$CONST->{$row->[0]} && die( $row->[0] );
	$value = $dba->getValue( "SELECT $row->[0] FROM domain WHERE DOMAIN='$domain'" );
	length( $value ) ? ( $CONST->{$row->[0]} = $value ) : ( $CONST->{$row->[0]} = '' );	
}

@matrix = $dba->getMatrix( "SELECT const_key, const_value FROM $domain_tbl" );
foreach $row ( @matrix ) {
	$CONST->{$row->[0]} && die( $row->[0] );
	$value = $row->[1];
	length( $value ) ? ( $CONST->{$row->[0]} = $value ) : ( $CONST->{$row->[0]} = '' );	
}
( $CONST->{SEL_HALF_MAXWIDTH} > 4 ) || die();

my $domainDBA	= new Rapido::DBAccessor( {
	CHK		=> 1,
	DB_HOST	=> $CONST->{DB_HOST},
	DB_USER	=> $CONST->{DB_USER},
	DB_PASS	=> $CONST->{DB_PASS},
	DB_DATA	=> $CONST->{DB_DATA} 
} );
									
@matrix = $dba->getMatrix( "SELECT	p,
									name,
									priority,
									s,
									nxt,
									def,
									ownertbl,
									flags,
									setup,
#									result,
									models FROM $parent_tbl ORDER BY priority" );

open( FILE, ">$domain.cfg" );
print( FILE "package ".$capitalDomain."::family;\n\n" );
print( FILE "use strict;\n" );
print( FILE "use warnings;\n\n" );
print( FILE "my \$CHILDREN\t= {};\n" );
print( FILE "my \$PARENTS\t\t= {};\n" );

foreach $parent ( @matrix ) {

	print( FILE "\n".'$PARENTS->{'.$parent->[0]."} = {" );
	$PARENTS->{$parent->[0]}->{CODE}		= $parent->[0];
	print( FILE "\n\t"."CODE$t2=> '$parent->[0]'" );
	$PARENTS->{$parent->[0]}->{NAME}		= $parent->[1];
	print( FILE ",\n\t"."NAME$t2=> '$parent->[1]'" );
	$PARENTS->{$parent->[0]}->{PRIORITY}	= $parent->[2];
	print( FILE ",\n\t"."PRIORITY\t=> '$parent->[2]'" );
	$PARENTS->{$parent->[0]}->{S}			= $parent->[3];
	print( FILE ",\n\t"."S$t3=> '$parent->[3]'" );
	$PARENTS->{$parent->[0]}->{NXT}			= $parent->[4];
	print( FILE ",\n\t"."NXT$t3=> '$parent->[4]'" );
	$PARENTS->{$parent->[0]}->{DEF}			= $parent->[5];
	print( FILE ",\n\t"."DEF$t3=> '$parent->[5]'" );
	$PARENTS->{$parent->[0]}->{OWNERTBL}	= $parent->[6];
	print( FILE ",\n\t"."OWNERTBL\t=> '$parent->[6]'" );
	print( FILE "," );
	doHash( 'FLAGS', $parent->[7], $PARENTS->{$parent->[0]} );
	$PARENTS->{$parent->[0]}->{SETUP}		= $parent->[8];
	print( FILE ",\n\t"."SETUP$t2=> '$parent->[8]'" );
	print( FILE "," );
	doArray( 'MODELS', $parent->[9], $PARENTS->{$parent->[0]} );
	print( FILE "\n};\n" );
		
	foreach $child ( $dba->getMatrix( "SELECT parent, child, name, type, fieldtype, ids, labels, uncles, required, display, defaults, search, priority, allows, flags FROM $child_tbl WHERE parent='$parent->[0]' ORDER BY priority" ) ) {
		$CHILDREN->{$child->[1]} ? ( die () ) : ( $CHILDREN->{$child->[1]} = {} );
		print( FILE "\n\$CHILDREN->{$child->[1]} = {" );
		$CHILDREN->{$child->[1]}->{PARENT}	= $child->[0];
		print( FILE "\n\t"."PARENT		=> '$child->[0]'" );
		$CHILDREN->{$child->[1]}->{CODE} = $child->[1];
		print( FILE ",\n\t"."CODE		=> '$child->[1]'" );
		$CHILDREN->{$child->[1]}->{NAME} = $child->[2];
		print( FILE ",\n\t"."NAME		=> '$child->[2]'" );
		$CHILDREN->{$child->[1]}->{TYPE} = $child->[3];
		print( FILE ",\n\t"."TYPE		=> '$child->[3]'" );
		print( FILE ',' );
		doArray( 'FIELDS', $child->[4], $CHILDREN->{$child->[1]} );
		print( FILE ',' );
		doArray( 'IDS', $child->[5], $CHILDREN->{$child->[1]} );
		print( FILE ',' );
		doArray( 'LABELS', $child->[6], $CHILDREN->{$child->[1]} );
		print( FILE ',' );
		doArray( 'UNCLES', $child->[7], $CHILDREN->{$child->[1]} );
		print( FILE ',' );
		doArray( 'REQS', $child->[8], $CHILDREN->{$child->[1]} );
		print( FILE ',' );
		doArray( 'DISPLAY', $child->[9], $CHILDREN->{$child->[1]} );
		print( FILE ',' );
		doArray( 'DEFAULTS', $child->[10], $CHILDREN->{$child->[1]}  );
		$CHILDREN->{$child->[1]}->{SEARCH} = $child->[11];
		print( FILE ",\n\t"."SEARCH		=> '$child->[11]'" );
		$CHILDREN->{$child->[1]}->{PRIORITY} = $child->[12];
		print( FILE ",\n\t"."PRIORITY	=> '$child->[12]'" );
		print( FILE ',' );
		doArray( 'ALLOWS', $child->[13], $CHILDREN->{$child->[1]} );
		print( FILE ',' );
		doHash( 'FLAGS', $child->[14], $CHILDREN->{$child->[1]} );
		print( FILE "\n};\n" );
		print( FILE "\n".'$PARENTS->{'.$child->[0].'}->{CHILDREN}->{'.$child->[1].'} = $CHILDREN->{'.$child->[1]."};\n" );
		$PARENTS->{$parent->[0]}->{CHILDREN}->{$child->[1]} = $CHILDREN->{$child->[1]};
	}
	print( FILE "\n" );
} 

print( FILE "my \$MODELS = {" );
foreach $model ( $dba->getMatrix( "SELECT code, name, app, result, options FROM $models_tbl" ) ) {
	if( %{$MODELS} ) {
		print( FILE "," );
	}
	
	$MODELS->{$model->[0]}->{CODE}	= $model->[0];
	print( FILE "\n\t$model->[0]\t=> {" );
	print( FILE "\n\t\tCODE\t\t=> '$model->[0]'" );
	$MODELS->{$model->[0]}->{NAME}	= $model->[1];
	print( FILE ",\n\t\tNAME\t\t=> '$model->[1]'" );
	$MODELS->{$model->[0]}->{APP}	= $model->[2];
	print( FILE ",\n\t\tAPP\t\t=> '$model->[2]'" );
	$MODELS->{$model->[0]}->{RESULT} = $model->[3];
	print( FILE ",\n\t\tRESULT\t=> '$model->[3]'" );
	$MODELS->{$model->[0]}->{OPTIONS} = $model->[4];
	print( FILE ",\n\t\tOPTIONS\t=> '$model->[4]'" );
	print( FILE "\n\t}" );
}
print( FILE "\n};\n\n" );

print( FILE "my \$CONST	= {" );
print( FILE "\n\tPARENTS\t\t\t\t=> \$PARENTS" );
print( FILE ",\n\tCHILDREN\t\t\t=> \$CHILDREN" );
print( FILE ",\n\tMODELS\t\t\t\t=> \$MODELS" );
foreach $key ( sort( keys %{$CONST} ) ) {
	if( length( $key ) < 4 ) {
		print( FILE ",\n\t$key$t5=> " );
	}
	elsif( length( $key ) < 8 ) {
		print( FILE ",\n\t$key$t4=> " );
	}
	elsif( length( $key ) < 12 ) {
		print( FILE ",\n\t$key$t3=> " );
	}
	elsif( length( $key ) < 16 ) {
		print( FILE ",\n\t$key$t2=> " );
	}
	else { 
		print( FILE ",\n\t$key\t=> " );
	}
	
	$value = $CONST->{$key};
	if( $value =~ m/^\d+$/ ) {
		print( FILE "$value" );	
	}
	elsif( length( $value ) ) {
		print( FILE "'$value'" );	
	}
	else {
		print( FILE "''" );	
	}
}
print( FILE "\n};\n\n" );
print( FILE "sub constantsGet { return \$CONST };\n1;" );

foreach $parent ( values %{$PARENTS} ) {
	( @{$tableDesc} = $domainDBA->getMatrix( "DESCRIBE $parent->{CODE}" ) ) || die( $parent->{CODE} );
	( scalar( @{$tableDesc} ) == 1 ) || die( $parent->{CODE} );
	( $tableDesc->[0]->[0] eq 'id' ) || die( $parent->{CODE} );
	$sqlTypes->{$parent->{CODE}}->{$tableDesc->[0]->[0]} = $tableDesc->[0]->[1];
	( $tableDesc->[0]->[1] =~ m/int\(\d+\) unsigned$/ ) || die( $parent->{CODE} );
	$tableDesc->[0]->[2] && die( $parent->{CODE} );
	( $tableDesc->[0]->[3] eq 'PRI' ) || die( $parent->{CODE} );
	( $tableDesc->[0]->[5] eq 'auto_increment' ) || die( $parent->{CODE} );
	
	length( $parent->{NAME} ) || die( "$parent->{CODE}" );
	if( $value = $parent->{S} ) {
		$PARENTS->{$value} || die( "$parent->{CODE}" );
		#check if it realy is a set
	}
	
	if( $value = $parent->{NXT} ) {
		$PARENTS->{$value} || die( "$parent->{CODE}" );
		#check if there is a link table
	}
	
	if( $value = $parent->{SETUP} ) {
		$PARENTS->{$value}	|| die( $parent->{CODE} );
		@{$PARENTS->{$value}->{MODELS}} || die( $parent->{CODE} );
		
		$child = $parent->{CODE}."_".$value;
		defined( $CHILDREN->{$child} ) || die( "$parent->{CODE}" );
		( $CHILDREN->{$child}->{PARENT} eq $parent->{CODE} ) || die( "$parent->{CODE}" );
		( $CHILDREN->{$child}->{UNCLES}->[0] eq $value ) 	|| die( "$parent->{CODE}" );
		
		$child = $parent->{CODE}."_date";
		defined( $CHILDREN->{$child} ) || die( "$parent->{CODE}" );
		( $CHILDREN->{$child}->{PARENT} eq $parent->{CODE} ) || die( $parent->{CODE} );
		
		$child = $parent->{CODE}."_log";
		defined( $CHILDREN->{$child} ) || die( "$parent->{CODE}" );
		( $CHILDREN->{$child}->{PARENT} eq $parent->{CODE} ) || die( $parent->{CODE} );
		
		$child = $parent->{CODE}."_status";
		defined( $CHILDREN->{$child} ) || die( "$parent->{CODE}" );
		( $CHILDREN->{$child}->{PARENT} eq $parent->{CODE} ) || die( $parent->{CODE} );
		
		$child = $parent->{CODE}."_".$CONST->{USER_PARENT};
		defined( $CHILDREN->{$child} ) || die( "$parent->{CODE}" );
		( $CHILDREN->{$child}->{PARENT} eq $parent->{CODE} ) || die( $parent->{CODE} );	
		( $CHILDREN->{$child}->{UNCLES}->[0] eq $CONST->{USER_PARENT} ) || die( $parent->{CODE} );
		
		$child	= $parent->{CODE}."_elapsed";
		defined( $CHILDREN->{$child} ) || die( "$parent->{CODE}" );
		( $CHILDREN->{$child}->{PARENT} eq $parent->{CODE} ) || die( $parent->{CODE} );
		
		foreach $child ( values( %{$parent->{CHILDREN}} ) ) {
			$child->{FLAGS}->{NOLOG} || die( "model results should not be logged ($child->{CODE})" );	
		}
	}
		
	if( @{$parent->{MODELS}} ) {
		foreach $model ( @{$parent->{MODELS}} ) {
			$MODELS->{$model} || die( $parent->{CODE} );
		}
		$parent->{SETUP}	&& die( "$parent->{CODE} cannot have both setup and result" );
		$child = $parent->{CODE}."_def";
		defined( $CHILDREN->{$child} ) || die( "$parent->{CODE}" );
		( $CHILDREN->{$child}->{PARENT} eq $parent->{CODE} ) || die( $parent->{CODE} );
		$child = $parent->{CODE}."_".$CONST->{USER_PARENT};
		defined( $CHILDREN->{$child} ) || die( "$parent->{CODE}" );
		( $CHILDREN->{$child}->{PARENT} eq $parent->{CODE} ) || die( $parent->{CODE} );
		( $CHILDREN->{$child}->{UNCLES}->[0] eq $CONST->{USER_PARENT} ) || die( $parent->{CODE} );
	}
	
	if( $value = $parent->{DEF} ) {
		$CHILDREN->{$value} || die( "$parent->{CODE}" );
		#check if child is ok to accept definitions		
	}
	else {
		die( $parent->{CODE} );
	}
	
	if( $value = $parent->{OWNERTBL} ) {
		$CHILDREN->{$value}	|| die( "$parent->{CODE}" );
		( $CHILDREN->{$value}->{PARENT} eq $parent->{CODE} ) || die( "$value is invalid ownership table for $parent->{CODE}" );
		#check if child is ok to accept ownerships
	}
	
	foreach $value ( keys %{$parent->{FLAGS}} ) {
		$constants->{FLAGS}->{$value}			|| die( $value );
		( $constants->{FLAGS}->{$value} & 1 )	|| die( "$parent->{CODE}" );
		if( $value eq 'FIXED' ) {
			$parent->{FLAGS}->{TREE} || die( "$parent->{CODE}" );
		}
		if( $value eq 'ELINK' ) {
			$parent->{FLAGS}->{TREE} || die( "$parent->{CODE}" );
			$parent->{FLAGS}->{ILINK} && die( "$parent->{CODE}" );
		}
		if( $value eq 'ILINK' ) {
			$parent->{FLAGS}->{TREE} || die( "$parent->{CODE}" );
			$parent->{FLAGS}->{ELINK} && die( "$parent->{CODE}" );
		}
		if( $value eq 'STOICH' ) {
			$found = 0;
			foreach( values %{$parent->{CHILDREN}} ) {
				$_->{FLAGS}->{STOICH} && ( $found ? die( "$parent->{CODE}" ) : ( $found = 1 ) );
			}
			$found || die( "$parent->{CODE}" )
		}
		if( $value eq 'RO' ) {
			foreach( values( %{$parent->{CHILDREN}} ) ) {
				$_->{FLAGS}->{RO} || die( "$_->{CODE} is not RO" );		
			}	
		}
	}
	
	unless( $parent->{FLAGS}->{RO} ) {
		$readonly = 1;
		foreach( values( %{$parent->{CHILDREN}} ) ) {
			$readonly && !$_->{FLAGS}->{RO} && ( $readonly = 0 ); 
		}
		$readonly && die( "$parent->{CODE} is not RO" );
	}
}
		
foreach $child ( values %{$CHILDREN} ) {
	$PARENTS->{$child->{PARENT}} || die( $child->{CODE} );
	length( $child->{NAME} ) || die( $child->{CODE} );
	!$child->{FLAGS}->{NOLOG} && $PARENTS->{$child->{PARENT}}->{FLAGS}->{NOLOG} && die( $child->{CODE} );
	
	( @{$tableDesc} = $domainDBA->getMatrix( "DESCRIBE $child->{CODE}" ) ) || die( $child->{CODE} );
	foreach( @{$tableDesc} ) {
		$sqlTypes->{$child->{CODE}}->{$_->[0]} = $_->[1];
		$_->[5] && die( $child->{CODE} );
	}
	$sqlTypes->{$child->{CODE}}->{p} || die( $child->{CODE} );
	( $sqlTypes->{$child->{CODE}}->{p} eq $sqlTypes->{$child->{PARENT}}->{id} ) || die( $child->{CODE} );
	
	( keys( %{$sqlTypes->{$child->{CODE}}} ) == ( scalar( @{$child->{FIELDS}} ) + 1 ) ) || die( $child->{CODE} );
	( scalar( @{$child->{FIELDS}} ) == scalar( @{$child->{LABELS}} ) ) || die( $child->{CODE} ); 
	for ( $pos=0; $pos < scalar( @{$child->{FIELDS}} ); $pos++ ) {
		( $myType = $sqlTypes->{$child->{CODE}}->{"x$pos"} ) || die( $child->{CODE} );	
		$fieldType = $child->{FIELDS}->[$pos];
		if( $fieldType eq 'VALUE' ) {
			
		}
		elsif( $fieldType eq 'SERIAL' ) {
			( $myType =~ m/int\(\d+\) unsigned/ ) || die( $child->{CODE} );
		}
		elsif( $fieldType eq 'USER' ) {
			( $myType =~ m/int\(\d+\) unsigned$/ ) || die( $child->{CODE} );
			( $child->{UNCLES}->[$pos] eq $CONST->{USER_PARENT} ) || die( $child->{CODE} );				
		}
		elsif( $fieldType eq 'MAIN' ) {
			( $myType eq 'tinyint(1)' ) || die( $child->{CODE} );
		}
		elsif( $fieldType eq 'LINK' ) {
			( $myType =~ m/char\(\d+\)$/ ) || die( $child->{CODE} );	
		}
		elsif( $fieldType eq 'FORK' ) {
			( $myType eq 'tinyint(3) unsigned' ) || die( $child->{CODE} );	
		}
		elsif( $fieldType eq 'STOICH' ) {
			( $myType eq 'smallint(6)' ) || die( $child->{CODE} );	
		}
		else {
			die( "$child->{CODE} has unkown field $fieldType" );
		}
	}
	
	for( $pos=0; $pos < scalar( @{$child->{UNCLES}} ); $pos++ ) {
		
		if( length( $value = $child->{UNCLES}->[$pos] ) ) {
			$PARENTS->{$value} || die( "$child->{CODE}" );
			( $sqlTypes->{$child->{CODE}}->{"x$pos"} eq $sqlTypes->{$value}->{id} ) || die( "$child->{CODE}.x$pos has different type from $value.id" );
			
			if( $child->{FIELDS}->[$pos] eq 'USER' ) {
				( $value eq $CONST->{USER_PARENT} ) || die( $child->{CODE} );
			}
			elsif( $child->{FIELDS}->[$pos] ne 'VALUE' ) {
				die( $child->{CODE} );
			}
		}	
		elsif( $pos >= scalar( @{$child->{FIELDS}} ) ) {
			die( $child->{CODE} );
		}
	}	
	
	if( $child->{TYPE} eq 'SINGLE' ) {
		@{$child->{IDS}}						&& die( $child->{CODE} );
		( scalar( @{$child->{FIELDS}} ) == 1 )	|| die( $child->{CODE} );
		( $child->{FIELDS}->[0] eq 'USER' )		||
		( $child->{FIELDS}->[0] eq 'VALUE' )	|| die( $child->{CODE} );
		
	}
	elsif( $child->{TYPE} eq 'SERIE' ) {
		( "@{$child->{IDS}}" eq '1' ) || die( $child->{CODE} );
		( ( $child->{FIELDS}->[0] eq 'VALUE' ) && ( $child->{FIELDS}->[1] eq 'SERIAL' ) ) || die( $child->{CODE} );
		if( scalar( @{$child->{FIELDS}} ) == 3 ) {
			( $child->{FIELDS}->[2] eq 'MAIN' )	|| die( $child->{CODE} );	
		}
		elsif( scalar( @{$child->{FIELDS}} ) != 2 ) {
			die( $child->{CODE} );
		}
	}
	elsif( $child->{TYPE} eq 'SET' ) {
		( $child->{IDS}->[0] eq '0' ) || die( $child->{CODE} );
		( $child->{FIELDS}->[0] eq 'VALUE' )	|| die( $child->{CODE} );
		
		if( scalar( @{$child->{FIELDS}} ) == 4 ) {
			( "@{$child->{IDS}}" eq '0' )		|| die( $child->{CODE} );
			( ( $child->{FIELDS}->[1] eq 'MAIN' ) && ( $child->{FIELDS}->[2] eq 'VALUE' ) && ( $child->{FIELDS}->[3] eq 'VALUE' ) ) || die( $child->{CODE} );
		}
		elsif( scalar( @{$child->{FIELDS}} ) == 3 ) {
			( "@{$child->{IDS}}" eq '0 1' )		|| die( $child->{CODE} );
			( ( $child->{FIELDS}->[1] eq 'FORK' ) && ( $child->{FIELDS}->[2] eq 'STOICH' ) ) || die( $child->{CODE} );	
		}
		elsif( scalar( @{$child->{FIELDS}} ) == 2 ) {
			( "@{$child->{IDS}}" eq '0' )		|| die( $child->{CODE} );
			( $child->{FIELDS}->[1] eq 'VALUE' ) || die( $child->{CODE} );
		}
		elsif( scalar( @{$child->{FIELDS}} ) != 1 ) {
			die( $child->{CODE} );	
		}
	}
	elsif( $child->{TYPE} eq 'LINK' ) {
		( "@{$child->{IDS}}" eq '1 0' )			|| die( $child->{CODE} );
		( scalar( @{$child->{FIELDS}} ) ==	2 ) || die( $child->{CODE} );
		( ( $child->{FIELDS}->[0] eq 'LINK' ) && ( $child->{FIELDS}->[1] eq 'USER' ) ) || die( $child->{CODE} );
	}
	elsif( $child->{TYPE} eq 'COMPLEX' ) {
		( "@{$child->{IDS}}" eq '1 0' )			|| die( $child->{CODE} );
		( scalar( @{$child->{FIELDS}} ) == 2 ) || die( $child->{CODE} );
		( ( $child->{FIELDS}->[0] eq 'VALUE' ) && ( $child->{FIELDS}->[1] eq 'SERIAL' ) ) || die( $child->{CODE} );	
	}
	else {
		die( $child->{CODE} );
	}
}

foreach $model ( values( %{$MODELS} ) ) {
	$value = $model->{RESULT};
	$PARENTS->{$value} || die( "Model $model->{CODE}" );
	$PARENTS->{$value}->{SETUP}	|| die( "Model $model->{CODE}: No setup for result data ($value) " );	
}

close( FILE );

sub doHash {
	my $txt			= shift;
	my $flagString	= shift;
	my $tgtHash		= shift;
	if( length( $txt ) < 4 ) {
		print( FILE "\n\t$txt$t3=> {" );
	}
	elsif( length( $txt ) < 7 ) {
		print( FILE "\n\t$txt$t2=> {" );
	}
	else { 
		print( FILE "\n\t$txt\t=> {" );
	}
	my $flag;
	my $display = 0;
	my @flagArray = split( /;/, $flagString );
	foreach $flag ( @flagArray ) {
		if( length( $flag ) ) {
			$tgtHash->{$txt}->{$flag} = 1;
			if( $display ) {
				print( FILE ", $flag => 1" );
			}
			else {
				$display = 1;
				print( FILE " $flag => 1" );
			}
		}
	}
	$display && ( print( FILE ' ' ) );
	print( FILE '}' );
}

sub doArray {
	my $txt				= shift;
	my $valuesString	= shift;
	my $tgtHash			= shift;
	my $tgtArray		= shift;
	my @valuesArray		= split( /;/, $valuesString );
	my $display			= 0;
	my $value;
	
	if( length( $txt ) < 4 ) {
		print( FILE "\n\t$txt$t3=> [" );
	}
	elsif( length( $txt ) < 8 ) {
		print( FILE "\n\t$txt$t2=> [" );
	}
	else { 
		print( FILE "\n\t$txt\t=> [" );
	}
	$tgtHash->{$txt} ? die() : ( $tgtHash->{$txt} = [] );
	$tgtArray = $tgtHash->{$txt};
	foreach $value ( @valuesArray ) {
		push( @{$tgtArray}, $value );
		if( $display ) {
			length( $value ) ? ( print( FILE ", '$value'" ) ) : ( print( FILE ", ''" ) );
		}
		else {
			$display = 1;
			length( $value ) ? ( print( FILE " '$value'" ) ) : ( print( FILE " ''" ) );
		}
	}
	$display && ( print( FILE ' ' ) );
	print( FILE ']' );
}
