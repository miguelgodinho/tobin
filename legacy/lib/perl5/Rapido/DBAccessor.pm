# (C) Miguel Godinho de Almeida - miguel@datindex.com 2004
package Rapido::DBAccessor;

use strict;
use warnings;

use vars qw($VERSION @ISA @EXPORT_OK);
use Exporter;
@ISA = ( 'Exporter');
$VERSION = '1.00';
@EXPORT_OK = qw();

use DBI;

sub new {
	my $param	= shift;
	my $self	= shift;
	my $class = ref($param) || $param;
	bless($self, $class);
	
	$self->{LASTOP}			= '';
	$self->{TBLLOCKS}		= {}; #0=FREE, 1=READ, 2=WRITE
	$self->{FIELDTYPE}		= {}; #table=>(field => (bool | int | float | txt | datetime))
	$self->{TBLAUTO}		= {}; #table=>field
	$self->{TBLKEYS}		= {}; # table=>(field => [key1, ..., key n])
	$self->{FIELDLIMITS}	= {}; #table=>(field => [$min, $max] || $maxLength)
	$self->{INTTYPES}		= {	tinyint		=> [-128, 127, 255],
								smallint	=> [-32768, 32767, 65535],
								mediumint	=> [-8388608, 8388607, 16777215],
								int			=> [-2147483648, 2147483647, 4294967295],
								bigint		=> [-9223372036854775808, 9223372036854775807, 18446744073709551615] };
	$self->{ARRAYTYPES}		= {	tinytext	=> 255,
								tinyblob	=> 255,
								text		=>	65535,
								blob		=> 65535,
								mediumtext	=> 16777215,
								mediumblob	=> 16777215,
								longtext	=> 4294967295,
								longblob	=> 4294967295 };	
	$self->{FLOATTYPE}		= 38;
	$self->{DOUBLETYPE}		= 308;

	( $self->{DBH} = DBI->connect( "DBI:mysql:$self->{DB_DATA}:$self->{DB_HOST}", $self->{DB_USER}, $self->{DB_PASS} ) ) || $self->suicide( "Connection to SQL Server FAILED" );
	$self->{LASTOP} = 'initialize';
	$self->{DBH} || $self->suicide();
	return $self;
}

sub suicide{
	my $self = shift;
	my $txt = shift;
	my $pack;
	my $file;
	my $line;
	my $i = 0;
	defined( $txt ) || ( $txt = '' );
	while(($pack, $file, $line) = caller($i++)){
		warn "Die - $pack - $file - $line\n";
	}
	die "DBAccessor is dead... $txt\n";
}

sub analizeTable{
	my $self = shift;
	my $table = shift;
	my $a_flags = shift;
	my %flag;
	foreach (@{$a_flags}) {
		$_ eq 'REFRESH'
		|| ($self->suicide("analizeTable: $_ is unkown flag"));
		$flag{$_} = 1;
	}
	${$self->{FIELDTYPE}}{$table} && !$flag{REFRESH} && return;
	($table =~ m/^[a-z]+_{0,1}[a-z]*$/) || ($self->suicide("analizeTable: '$table' is invalid string for table name"));
#	%{$self->{TBLLOCKS}} && ($self->suicide("analizeTable - not possible with table locks"));
	my $tdesc = {};
	(%{$tdesc} = $self->getHashArray("DESCRIBE $table")) || ($self->suicide("analizeTable - cannot describe $table"));

	my $field;
	my $a_tmp;
	my $str;
	while ( ( $field, $a_tmp ) = each( %{$tdesc} ) ) {
		if ( ( $a_tmp->[0] =~ m/^(\w*int)\((\d+)\)( unsigned)?/ ) && $self->{INTTYPES}->{$1} ) {
			if( $1 eq 'tinyint') {
				if ( ( $2 == 1 ) && !$3 ) {
					$self->{FIELDTYPE}->{"$table"}->{"$field"} = 'bool';
					$self->{FIELDLIMITS}->{"$table"}->{"$field"} = [ 0, 1 ];
				}
				elsif ( ( $2 == 2 ) && !$3 ) {
					$self->{FIELDTYPE}->{"$table"}->{"$field"} = 'int';
					$self->{FIELDLIMITS}->{"$table"}->{"$field"} = [ 0, 99 ];
				}
				elsif ( $2 == 3 ) {
					$self->{FIELDTYPE}->{"$table"}->{"$field"} = 'int';
					$3 ? ( $self->{FIELDLIMITS}->{"$table"}->{"$field"} = [ 0, 255 ] ) : ( $self->{FIELDLIMITS}->{"$table"}->{"$field"} = [ -99, 127 ] );
				}
				elsif ( ($2 == 4) && !$3 ) {
					$self->{FIELDTYPE}->{"$table"}->{"$field"} = 'int';
					$self->{FIELDLIMITS}->{"$table"}->{"$field"} = [ $self->{INTTYPES}->{$1}->[0], $self->{INTTYPES}->{$1}->[1] ];
				}
				else{
					$self->suicide("analizeTable: $table.$field has unkown type");
				}
			}
			else{
				$self->{FIELDTYPE}->{"$table"}->{"$field"} = 'int';
				$3 ? ( $self->{FIELDLIMITS}->{"$table"}->{"$field"} = [ 0, $self->{INTTYPES}->{$1}->[ 2 ] ] ) : ( $self->{FIELDLIMITS}->{"$table"}->{"$field"} = [ $self->{INTTYPES}->{$1}->[ 0 ], $self->{INTTYPES}->{$1}->[ 1 ] ] );
			}
		}
		elsif ( $a_tmp->[0]  =~ m/^float( unsigned)?/ ) {
			$self->{FIELDTYPE}->{"$table"}->{"$field"} = 'float';
			$1 ? ( $self->{FIELDLIMITS}->{"$table"}->{"$field"} = [ 24, 0 ]) : ( $self->{FIELDLIMITS}->{"$table"}->{"$field"} = [ 24, -1 ] );
		}
		elsif ( $a_tmp->[0] =~ m/^(var)?char\((\d+)\)$/ ) {
			$self->{FIELDTYPE}->{"$table"}->{"$field"} = 'txt';
			$self->{FIELDLIMITS}->{"$table"}->{"$field"} = $2;
		}
		elsif ( $a_tmp->[0] eq 'datetime' ) {
			$self->{FIELDTYPE}->{"$table"}->{"$field"} = 'datetime'
		}
		elsif ( ( $a_tmp->[0] =~ m/^(\w*text)$/ ) && $self->{ARRAYTYPES}->{$1} ) {
			$self->{FIELDTYPE}->{"$table"}->{"$field"} = 'txt';
			$self->{FIELDLIMITS}->{"$table"}->{"$field"} = $self->{ARRAYTYPES}->{$1};
		}
		elsif ( $a_tmp->[0] =~ m/^enum\(([^\)]+)\)$/ ) {
			$self->{FIELDTYPE}->{"$table"}->{"$field"} = 'enum';
			$str = $1;
			$str =~ s/'//g;
			@{$self->{FIELDLIMITS}->{"$table"}->{"$field"}} = split( /,/, $str );
		}
		else{
			$self->suicide("analizeTable: $table.$field has unkown type");
		}
		( $a_tmp->[2] eq 'PRI' ) && ( push( @{$self->{TBLKEYS}->{"$table"}}, $field ) );
		( $a_tmp->[4] eq 'auto_increment' ) && ( $self->{TBLAUTO}->{"$table"} = $field );
	}
	$self->{TBLAUTO}->{"$table"} || ( $self->{TBLAUTO}->{"$table"} = '' );
	#2do: 'show index from test and identify fields with unique
	#2do: for auto value, test max and change limits, implement a warning if it is close to limit... think about it
}

sub do {
	my $self	= shift;
	my $sql		= shift;
	$self->{DBH}->do( $sql );
}

sub deleteRecord {
	my $self = shift;
	my $table = shift;
	my $h_ids = shift;
	my $a_flags = shift;
	my %flag;
	foreach (@{$a_flags}){
		($_ eq 'MULTI')
		|| ($_ eq 'NOFULLKEY')
		|| ($self->suicide("delete: $_ is unkown flag"));
		$flag{$_} = 1;
	}
	$flag{MULTI} && ($flag{NOFULLKEY} = 1);
	${$self->{FIELDTYPE}}{$table} || ($self->suicide("delete: $table is unkown or not analized"));
	foreach (@{${$self->{TBLKEYS}}{$table}}){ defined( $h_ids->{$_} ) || $flag{'NOFULLKEY'} || ($self->suicide("delete: key '$_' is missing from record identification"))};
	my $query;
	my $field;
	my $value;
	while(($field, $value) = each %{$h_ids}){
		$value = $self->format($table, $field, $value, []);
		($query) ? ($query .= " AND $field=$value") : ($query = "WHERE ($field=$value");
	}
	$query .= ')';
	($self->getLock($table) == 2) || ($self->suicide("delete: cannot update in table unlocked for write $table"));
	my $records = $self->getValue("SELECT COUNT(*) FROM $table $query");
	if($records){
		($records > 1) && ($flag{MULTI} || ($self->suicide("delete: more than one record matches query, try MULTI: $query")));
		$self->{DBH}->do("DELETE FROM $table $query");
		$self->{LASTOP} = 'delete';
		return $records;
	}
	return 0;
}

sub format{ #return input string formated to be used as a value on a sql statement
	my $self = shift;
	my $p1 = shift;
	my $p2 = shift;
	my $p3 = shift;
	my $a_flags = shift;
	if($p2){
		my $table = $p1;
		my $field = $p2;
		my $value = $p3;
		my %flag;
		my $type;
#		(defined($field) && defined($a_flags) && (ref($a_flags) eq 'ARRAY')) || ($self->suicide("format: PE"));
		(defined($field)) || ($self->suicide("format: PE"));
	
		foreach (@{$a_flags}){
			($_ eq 'NOQUOTES')
			|| ($_ eq 'NOESCAPE')
			|| ($_ eq 'NOTRIM')
			|| ($_ eq 'NOTEST')
			|| ($_ eq 'TRUNCATE')
			|| ($self->suicide("format: $_ is unkown flag"));
			$flag{$_} = 1;
		}
		${$self->{FIELDTYPE}}{$table} || ($self->analizeTable($table));
#		${$self->{FIELDTYPE}}{$table} || ($self->suicide("format: $table is unkown or not analized"));
		($type = ${${$self->{FIELDTYPE}}{$table}}{$field}) || ($self->suicide("format: $table.$field has unknown field type"));

		my $str = $value;
		unless($flag{NOTRIM}){
			$str =~ s/^\s*//;
			$str =~ s/\s*$//;
		}
	
		if($type eq 'bool'){
			length( $str ) || ( $str = 'NULL' );
			$flag{NOQUOTES} = 1;
		}
		elsif($type eq 'int'){
#			(m/^\+/) && (print "TESTING $_\n");
			$str =~ s/^\+//;
			length( $str ) || ( $str = 'NULL' );
			$flag{NOQUOTES} = 1;
		}
		elsif($type eq 'float'){
			$str =~ s/^\+//;
			$str =~ s/^-\./-0./;
			$str =~ s/^\./0./;
			( $str =~ m/\./ ) && ( ( $str =~ s/\.$// ) || ( $str =~ s/0+$// ) );
			length( $str ) || ( $str = 'NULL' );
			$flag{NOQUOTES} = 1;
		}
		if($type eq 'txt'){
			unless($flag{NOESCAPE}){
				$str =~ s/\(/\\\(/g;
				$str =~ s/\)/\\\)/g;
				$str =~ s/\'/\\\'/g;#'
			}
		}	
		elsif($type eq 'datetime'){
			($str eq 'NOW') && ($str = 'NOW()');
			($str eq 'NOW()') && ($flag{NOQUOTES} = 1);
		}

		if($flag{TRUNCATE}){
			#2do: 	test for size
			#	if too long
			#		ask for size limit
			#		truncate
			#	endif
			$self->suicide("format->truncate is not implemented");
		}
		$flag{NOTEST} || (($self->getFormatError($table, $field, $str, ['NOQUOTES'])) && ($self->suicide("format: test fails: $table.$field=$str")));
		( $flag{NOQUOTES} && length( $str ) ) ? ( return $str ) : ( return "'$str'" );
	}
	else{
		($p3 || $a_flags) && ($self->suicide("format: PE"));
		my $str = $p1;
		$str =~ s/\(/\\\(/g;
		$str =~ s/\)/\\\)/g;
		$str =~ s/\'/\\\'/g;
		return $str;
		#($str =~ m/^\'/) || ($str = "'$str");
		#($str =~ m/[^\\]\'$/) || ($str .= "'");
	}
}

sub insertRecord{
	my $self = shift;
	my $table = shift;
	my $h_data = shift;
	my $a_flags = shift;
	my %flag;
	my $auto;
	my $sql;
	my $key;
	my $value;
	my @values;
	my $type;
	
	foreach (@{$a_flags}) {
		($_ eq 'EMPTY')
		|| ($self->suicide("insertRecord: $_ is unkown flag"));
		$flag{$_} = 1;
	}
	((ref($h_data) eq 'HASH') && %{$h_data} && !$flag{EMPTY}) || ($flag{EMPTY} && !$h_data) || ($self->suicide("insertRecord - PE"));
	$self->{FIELDTYPE}->{$table} || $self->analizeTable( $table );
	${$self->{FIELDTYPE}}{$table} || ($self->suicide("insertRecord: $table is unkown or not analized"));
	($auto = ${$self->{TBLAUTO}}{$table}) || ($auto = '');
	$flag{EMPTY} && ($auto || ($self->suicide("insertRecord: empty requires auto")));
	foreach (@{${$self->{TBLKEYS}}{$table}}){
		(defined(${$h_data}{$_})) ? (($_ eq $auto) && ($auto = '')) : (($_ eq $auto) || ($self->suicide("insert record: key '$_' is missing")));
	}

	$sql = '';	
	while ( ( $key, $value ) = each %{$h_data} ) {
		$sql ? ( $sql .= ", $key" ) : ( $sql = "INSERT INTO $table ($key" );
		$value = $self->format( $table, $key, $value );#formated and tested, better than new
		@values ? ( push( @values, ", $value" ) ) : ( push( @values, "$value" ) );
	}
	$sql ? ( $sql .= ") VALUES (" ) : ( $sql = "INSERT INTO $table () VALUES (" );
	foreach ( @values ) { $sql .= $_ };
	$sql .= ")";
	$self->{DBH}->do($sql) || ($self->suicide("insertRecord: SQL Fail - '$sql'"));
	if($auto){
		$self->{LASTOP} = 'insertRecord (auto)';
		return $self->getLastInsertionID();
	}
	else{
		$self->{LASTOP} = 'insertRecord (not auto)';
		return -1;
	}
}

sub getColumn { #to replace getArray
	my $self	= shift;
	my $sql		= shift;

	my @result;
	my @row;
	$self->{STH} = $self->{DBH}->prepare( $sql );
	$self->{LASTOP} = "getColumn";
	$self->{STH}->execute() || $self->suicide( "getColumn: SQL Fail - '$sql'" );
	while( @row = $self->{STH}->fetchrow_array() ) { push( @result, $row[0] ) };
	return @result;
}

sub getColumnRef {
	my $self	= shift;
	my $sql		= shift;
	my $result	= [];
	my @row;
	
	$self->{STH} = $self->{DBH}->prepare( $sql );
	$self->{LASTOP} = "getColumnRef";
	$self->{STH}->execute() || $self->suicide( "getColumnRef: SQL Fail - '$sql'" );
	while( @row = $self->{STH}->fetchrow_array() ) { push( @{$result}, $row[0] ) };
	return $result;
}

sub getRow {
	my $self	= shift;
	my $sql		= shift;

	$self->{STH} = $self->{DBH}->prepare( $sql );
	$self->{LASTOP} = "getRow";
	$self->{STH}->execute() || $self->suicide( "getRow: SQL Fail - '$sql'" );
	return $self->{STH}->fetchrow_array();
}

sub getArray{ #deprecated, use getColumn/Row instead
	my $self = shift;
	my $sql = shift;
	my $a_flags = shift;
	my %flag;
	my @result;
	my @row;
	foreach (@{$a_flags}){
		($_ eq 'COLUMN')
		|| ($_ eq 'ROW')
		|| ($_ eq 'FIRST')
		|| ($self->suicide("getArray: $_ is unkown flag"));
		$flag{$_} = 1;
	}
	($sql && !(ref($sql)) && ($flag{COLUMN} || $flag{ROW})) || ($self->suicide("getArray: PE"));
	$self->{STH} = $self->{DBH}->prepare($sql);
	$self->{LASTOP} = "getArray";
	$self->{STH}->execute() || ($self->suicide("getArray: SQL Fail - '$sql'"));
	if($flag{COLUMN}){
		while(@row = $self->{STH}->fetchrow_array()){
			($#row && !$flag{FIRST}) && ($self->suicide("getArray: query '$sql' returns more than one column"));
			push(@result, $row[0]);
		}
	}
	else{
		(@result = $self->{STH}->fetchrow_array()) || (return);
		($self->{STH}->fetchrow_array() && !$flag{FIRST}) && ($self->suicide("getArray: query '$sql' returns more than one record"));
	}
	return @result;
}

#sub getAutoInc{
#	my $self = shift;
#	my $table = shift;
#	${$self->{FIELDTYPE}}{$table} || ($self->suicide("getAutoInc: $table is unkown or not analized"));
#	(${$self->{TBLAUTO}}{$table}) ? (return ${$self->{TBLAUTO}}{$table}) : (return '');
#}
#
#sub getCheckDataStatus{
#	my $self = shift;
#	return $self->{CHK};
#}

sub getErrorFromCode{
	my $self = shift;
	my $table = shift;
	my $field = shift;
	my $code = shift;
	my $a_flags = shift;
	my %flag;
	foreach (@{$a_flags}){
		($_ eq 'NODIE')
		|| ($self->suicide("getErrorFromCode: $_ is unkown flag"));
		$flag{$_} = 1;
	}
	($code eq '0') && (return '');	
	($code eq '1') && (return 'has wrong format');
	($code eq '2') && (return 'is too long');
	($code eq '3') && (return 'has invalid chars');
	($code eq '4') && (return 'has leading spaces');
	($code eq '5') && (return 'has trailing spaces');
	($code eq '6') && (return 'is out of min limit');
	($code eq '7') && (return 'is out of max limit');
	($code eq '8') && (return 'is not unique');
	($code eq '9') && (return 'null not supported');
	($code eq '10') && (return 'field is autoincrement');
	($code eq '11') && (return 'is out of precision limit');
	($code eq '12') && (return 'is not quoted');
	
	($flag{NODIE}) ? (return '') : ($self->suicide("getErrorFromCode - invalid error code - $code"));
}

sub getFieldSize{
	my $self = shift;
	my $table = shift;
	my $field = shift;
	my $a_flags = shift;
	my %flag;
	foreach (@{$a_flags}){
		($self->suicide("getFieldSize: $_ is unkown flag"));
		$flag{$_} = 1;
	}
	my $type = $self->getFieldType($table, $field, []);
	if($type eq 'bool'){
		return 1;
	}
	elsif($type eq 'int'){
		(${${${$self->{FIELDLIMITS}}{$table}}{$field}}[0]) ? (return (length(${${${$self->{FIELDLIMITS}}{$table}}{$field}}[1]) + 1)) : (return length(${${${$self->{FIELDLIMITS}}{$table}}{$field}}[1]));
	}
	elsif($type eq 'float'){
		(${${${$self->{FIELDLIMITS}}{$table}}{$field}}[1]) ? (return (${${${$self->{FIELDLIMITS}}{$table}}{$field}}[0] + 1)) : (return ${${${$self->{FIELDLIMITS}}{$table}}{$field}}[0]);
	}
	elsif($type eq 'datetime'){
		return 19;
	}
	elsif($type eq 'txt'){
		return ${${$self->{FIELDLIMITS}}{$table}}{$field};
	}
	$self->suicide("getFieldType: $table.$field has unkown type ($type)");
}

sub getFieldType{
	my $self = shift;
	my $table = shift;
	my $field = shift;
	my $a_flags = shift;
	my %flag;
	foreach (@{$a_flags}){
		($self->suicide("getFieldType: $_ is unkown flag"));
		$flag{$_} = 1;
	}
	${$self->{FIELDTYPE}}{$table} || ($self->suicide("getFieldType: $table is unkown or not analized"));
	(${${$self->{FIELDTYPE}}{$table}}{$field}) ? (return ${${$self->{FIELDTYPE}}{$table}}{$field}) : ($self->suicide("getFieldType: $table.$field does not exist"));
}

sub getFormatError{
	my $self = shift;
	my $table = shift;
	my $field = shift;
	my $value = shift;
	my $a_flags = shift;
	my %flag;
	my $type;
	my $str;
	
	foreach (@{$a_flags}){
		($_ eq 'NOQUOTESOK')#does not fail if text is not quoted
		|| ($_ eq 'NOQUOTES')#assure that txt is not quoted
		|| ($_ eq 'INT')#assure that value is an int indep. of field type
		|| ($_ eq 'UINT')#assure that value is an unsigned int indep. of field type
		|| ($_ eq 'FLOAT')#assure that value is float indep. of field type
		|| ($_ eq 'UFLOAT')#assure that value is unsigned float indep. of field type
		|| ($_ eq 'NOESCAPE')#does not test if all special chars are escapes, excluding quotes
		|| ($self->suicide("getFormatError: $_ is unkown flag"));
		$flag{$_} = 1;
	}
	$flag{INT} && ($flag{UINT} || $flag{FLOAT} || $flag{UFLOAT}) && ($self->suicide("getFormatError: PE"));
	$flag{UINT} && ($flag{INT} || $flag{FLOAT} || $flag{UFLOAT}) && ($self->suicide("getFormatError: PE"));
	$flag{FLOAT} && ($flag{UINT} || $flag{INT} || $flag{UFLOAT}) && ($self->suicide("getFormatError: PE"));
	$flag{UFLOAT} && ($flag{UINT} || $flag{FLOAT} || $flag{INT}) && ($self->suicide("getFormatError: PE"));
	(!(defined($value)) || ref($field) || ref($value)) && ($self->suicide("getFormatError: PE $table - $field"));

	$self->{FIELDTYPE}->{$table} || $self->analizeTable( $table );
	( $type = $self->{FIELDTYPE}->{$table}->{$field} ) || $self->suicide("getFormatError - $table.$field is unkown field");
	
	$str = $value;

	if($type eq 'bool'){
		(($str eq '0') || ($str eq '1')) || (return 1);
	}
	elsif($type eq 'int'){
		($str =~ m/^[-]{0,1}\d*$/) || ( $str eq 'NULL' ) || (return 1);
		($str < ${${${$self->{FIELDLIMITS}}{$table}}{$field}}[0]) && (return 6);
		($str > ${${${$self->{FIELDLIMITS}}{$table}}{$field}}[1]) && (return 7);
	}
	elsif( $type eq 'float' ) {
		if( $str =~ m/^[-]{0,1}\d*[\.]{0,1}\d*$/ ) {
			( length($str) > $self->{FIELDLIMITS}->{$table}->{$field}->[0] ) && ( return 11 );
		}
		elsif( $str =~ m/^(-?)\d[\.]{0,1}\d*e[\+|-](\d+)$/ ) {
			if( $1 ) {
				( $2 >= $self->{FLOATTYPE} ) && ( return 6 );
			}
			else {
				( $2 >= $self->{FLOATTYPE} ) && ( return 7 );	
			}
			( length($str) > $self->{FIELDLIMITS}->{$table}->{$field}->[0] ) && ( return 11 );
		}
		elsif( $str ne 'NULL' ) {
			return 1;
		}
	}
	elsif($type eq 'datetime'){
#		($str =~ m/^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$/) && ($self->suicide("getFormatError: datetime value not implemented"));
		( $str =~ m/^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$/ ) || ( $str eq 'NOW()' ) || ( return 1 );
	}
	elsif($type eq 'txt'){
		if($str =~ m/^\'/){
			($str =~ m/[^\\]\'$/) || $flag{NOESCAPE} || (return 12);
			($str =~ m/^\'\s/) && (return 4);
			($str =~ m/\s\'$/) && ($flag{NOESCAPE} || (return 5));
			if($str =~ m/\\/){
				($self->getValue("SELECT LENGTH($str)") > ${${$self->{FIELDLIMITS}}{$table}}{$field}) && (return 2);
			}
			else{
				(length($str) > (${${$self->{FIELDLIMITS}}{$table}}{$field} + 2)) && (return 2);
			}
		}
		else{
			($flag{NOQUOTES}) || ($flag{NOQUOTESOK}) || (return 12);
			($str =~ m/[^\\]\'$/) && ($flag{NOESCAPE} || (return 1));
			($str =~ m/^\s/) && (return 4);
			($str =~ m/\s$/) && (return 5);
			if($str =~ m/\\/){
				($self->getValue("SELECT LENGTH('$str')") > ${${$self->{FIELDLIMITS}}{$table}}{$field}) && (return 2);
			}
			else{
				(length($str) > ${${$self->{FIELDLIMITS}}{$table}}{$field}) && (return 2);
			}
		}
		
		unless($flag{NOESCAPE}){
			$value = $str;
			(($value =~ m/^\'/) && ($value =~ m/[^\\]\'$/)) && (($value =~ s/^\'//) && ($value =~ s/\'$//));
			($value =~ m/([^\\]|^|\\\\)('|\(|\))/) && (return 3);
		}
	}
	else{
		$self->suicide("getFormatError: $type is not supported");
	}
	$flag{INT} && (($str =~ m/^[-]{0,1}\d+$/) || ($str =~ m/^\'[-]{0,1}\d+\'$/) || (return 1));
	$flag{UINT} && (($str =~ m/^\d+$/) || ($str =~ m/^\'\d+\'$/) || (return 1));
	$flag{FLOAT} && (($str =~ m/^[-]{0,1}\d+(\.\d+)?$/) || ($str =~ m/^\'[-]{0,1}\d+(\.\d+)?\'$/) || (return 1));
	$flag{UFLOAT} && (($str =~ m/^\d+(\.\d+)?$/) || ($str =~ m/^\'\d+(\.\d+)?\'$/) || (return 1));
	$flag{NOQUOTES} && (($str =~ m/^\'/) || (($str =~ m/[^\\]\'$/) && !$flag{NOESCAPE})) && (return 1);
	return 0;#error code 0 - no errors!
}

sub getHash{
	my $self = shift;
	my $sql = shift;
	my $a_flags = shift;
	my %flag;
	my $str;
	foreach (@{$a_flags}){
		($_ eq 'MULTI')
		|| ($_ eq 'ARRAY')
		|| ($_ eq 'MATRIX')
		|| ($self->suicide("getHash: $_ is unkown flag"));
		$flag{$_} = 1;
	}
	( 	( $flag{MULTI} && $flag{ARRAY} ) ||
		( $flag{ARRAY} && $flag{MATRIX} ) ||
		( $flag{MATRIX} && $flag{MULTI} ) ) && 
	($self->suicide("getHash: ARRAY, MATRIX, MULTI cannot coexist"));
	($sql && !ref($sql)) || ($self->suicide("getHash: PE"));
	$self->{DBH} || $self->suicide();
	$self->{STH} = $self->{DBH}->prepare($sql);
	$self->{LASTOP} = "getHash";
	$self->{STH}->execute() || ($self->suicide("getHash: SQL Fail - $sql"));
	my %hash;
	my @row = ();
	
	if ( $flag{ARRAY} ) {
		while ( @row = $self->{STH}->fetchrow_array() ) {
			( scalar( @row ) < 3 ) && ( $self->suicide( "getHash: $sql returns less than 3 columns - invalid for ARRAY" ) );
			$str = shift( @row );
			defined( $str ) || $self->suicide( "@row" );
			$hash{$str} ? $self->suicide( "getHash: '$sql' - duplicate value for key - $str" ) : ( $hash{$str} = [ @row ] );
		}
	}
	elsif ( $flag{MULTI} ) {
		while ( @row = $self->{STH}->fetchrow_array() ) {
			( scalar( @row ) == 2 ) || ( $self->suicide( "getHash: '$sql' number of columns is not 2" ) );
			$hash{$row[0]} ? ( push( @{$hash{$row[0]}}, $row[1] ) ) : ( $hash{$row[0]} = [ $row[1] ] );
		}
	}
	elsif ( $flag{MATRIX} ) {
		while ( @row = $self->{STH}->fetchrow_array() ) {
			$str = shift( @row );
			defined( $str ) || $self->suicide();
			$hash{$str} ? ( push( @{$hash{$str}}, [ @row ] ) ) : ( $hash{$str} = [ [ @row ] ] );
		}
	}
	else{
		while(@row = $self->{STH}->fetchrow_array()){
			(scalar(@row) == 2) || ($self->suicide("getHash: '$sql' number of columns is not 2"));
			($hash{$row[0]}) && ($self->suicide("sqlHash - duplicate pair('$row[0]', '$row[1]') - $sql"));
			($hash{$row[0]} = $row[1]);
		}
	}
	return %hash;
}

sub getHashArray{
	my $self = shift;
	my $sql = shift;
	return $self->getHash($sql, ['ARRAY']);
}

sub getLastInsertionID{
	my $self = shift;
	my $a_flags = shift;
	my %flag;
	foreach (@{$a_flags}){
		($_ eq 'REPEATOK')
		|| ($self->suicide("getLastInsertionID: $_ is unkown flag"));
		$flag{$_} = 1;
	}
	($self->{LASTOP} eq 'insertRecord (auto)') || (($self->{LASTOP} eq 'getLastInsertID') ? ($self->suicide("getLastInsertionID: already retrieved, try REPEATOK flag for recurrent queries")) : ($self->suicide("getLastInsertionID: not possible with last operation = $self->{LASTOP}")));
	$self->{STH} = $self->{DBH}->prepare("SELECT LAST_INSERT_ID()");
	$self->{STH}->execute() || ($self->suicide("getLastInsertionID: Fail"));
	$flag{REPEATOK} || ($self->{LASTOP} = 'getLastInsertID');
	return ($self->{STH}->fetchrow_array())[0];
}

sub getLock{
	my $self = shift;
	my $table = shift;
	my $a_flags = shift;
	my %flag;
	foreach (@{$a_flags}){
		($_ eq 'ALL')
		|| ($_ eq 'PRINT')
		|| ($self->suicide("getLock: $_ is unkown flag"));
		$flag{$_} = 1;
	}

	$flag{PRINT} && ($flag{ALL} || $self->suicide("getLock: PRINT w/o ALL"));
	if($flag{ALL}){
		my $tbl;
		my $lock;
		my $totalLocks = 0;
		while(($tbl, $lock) = each %{$self->{TBLLOCKS}}){
			if($lock){
				$totalLocks++;
				$flag{PRINT} && (($lock == 1) ? (print "$tbl:READ\n") : (print "$tbl:WRITE\n"));
			}
			else{
				$flag{PRINT} && (print "$tbl:NO LOCK\n");
			}
		}
		if($totalLocks){
			return -1;
		}
		else{
			$flag{PRINT} && (print "NO LOCKS\n");
			return 0;
		}
	}
	else{
#		${$self->{FIELDTYPE}}{$table} || ($self->suicide("getLock: $table is unkown or not analized"));
		(${$self->{TBLLOCKS}}{$table}) ? (return ${$self->{TBLLOCKS}}{$table}) : (return 0);
	}
	$self->suicide("getLock: UE");
}

sub getMatrix {
	my $self	= shift;
	my $sql		= shift;
	my @matrix;
	my @row;
	
	( $sql && !ref( $sql ) ) || $self->suicide( "getMatrix: PE" );
	$self->{LASTOP} = 'getMatrix';
	$self->{STH} = $self->{DBH}->prepare( $sql );
	$self->{STH}->execute() || $self->suicide( "getMatrix: query '$sql' is not valid" );
	while( @row = $self->{STH}->fetchrow_array() ) { push( @matrix, [ @row ] ) };
	return @matrix;
}

sub getMatrixRef {
	my $self	= shift;
	my $sql		= shift;
	my $matrix	= [];
	my @row;
	
	( $sql && !ref( $sql ) ) || $self->suicide( "getMatrix: PE" );
	$self->{LASTOP} = 'getMatrix';
	$self->{STH} = $self->{DBH}->prepare( $sql );
	$self->{STH}->execute() || $self->suicide( "getMatrix: query '$sql' is not valid" );
	while( @row = $self->{STH}->fetchrow_array() ) { push( @{$matrix}, [ @row ] ) };
	return $matrix;
}

sub getValue{
	my $self = shift;
	my $sql = shift;
	my $a_flags = shift;
	my %flag;
	my @result;
	foreach (@{$a_flags}){
		($_ eq 'FIRSTCOL')
		|| ($_ eq 'FIRSTROW')
		|| ($_ eq 'EMPTY')
		|| ($self->suicide("getValue: $_ is unkown flag"));
		$flag{$_} = 1
	};
	
	($sql && !(ref($sql))) || ($self->suicide("getValue: PE"));
	$self->{STH} = $self->{DBH}->prepare($sql);
	$self->{LASTOP} = 'getValue';
	$self->{STH}->execute() || ($self->suicide("getValue: SQL Fail - '$sql'"));
	(@result = $self->{STH}->fetchrow_array()) || (($flag{EMPTY}) ? (return '') : (return undef));
	($#result) && (($flag{FIRSTCOL}) || ($self->suicide("getValue: query '$sql' produces more than one column")));
	($self->{STH}->fetchrow_array()) && (($flag{FIRSTROW}) || ($self->suicide("getValue: query '$sql' produces more than one row")));
	return $result[0];
}

sub lockTables {
	my $self	= shift;
	my $h_locks	= shift;
	my $table;
	my $lock;
	my $sql;
	my $alias;
	
	%{$h_locks} || $self->suicide( "lockTables: no data" );
	%{$self->{TBLLOCKS}} && $self->suicide( "lockTables: there are tables still locked" );

	while( ( $table, $lock ) = each %{$h_locks} ) {
		( $table =~ m/^(\w+) AS \w+$/ ) ? ( $self->analizeTable( $1 ) ) : ( $self->analizeTable( $table ) );
		if( $lock eq 'WRITE' ) {
			$self->{TBLLOCKS}->{$table} = 2;
		}
		elsif($lock eq 'READ'){
			$self->{TBLLOCKS}->{$table} = 1;
		}
		else {
			$self->suicide( "lockTables: '$lock' is unkown lock type" );
		}
		$sql ? ( $sql .= ", $table $lock" ) : ( $sql .= "LOCK TABLE $table $lock" );
	}

	$self->{LASTOP} = 'lockTables';
	$self->{DBH}->do( $sql );
}

#sub setCheckData{
#	my $self = shift;
#	my $status = shift;
#
#	if($status eq '1'){
#		$self->{CHK} = 1;
#	}
#	elsif($status eq '0'){
#		$self->{CHK} = 0;
#	}
#	else{
#		$self->suicide("setCheckDAta: $status is not valid value");
#	}
#
#}

#sub testRecord{
#	my $self = shift;
#	my $table = shift;
#	my $h_data = shift;
#	my $h_errors = shift;
#	my $a_flags = shift;
#	my %flag;
#	my $str;
#	
#	foreach (@{$a_flags}){
#		($self->suicide("testRecord: $_ is unkown flag"));
#		$flag{$_} = 1;
#	}
#	((ref($h_errors) eq 'HASH') && !%{$h_errors}) || ($self->suicide("testRecord: PE"));
#	(%{$h_data}) || ($self->suicide("testRecord - no data"));
#
#	my $field;
#	my $value;
#	while(($field, $value) = each %{$h_data}){
#		($str = $self->getFormatError($table, $field, $value)) && (${$h_errors}{$field} = $str);
#	}
#	#2do: check keys and uniqueness
#	(%{$h_errors}) && (return 0);
#	return 1;
#}

sub unlockTables{
	my $self = shift;
	
	$self->{DBH}->do("UNLOCK TABLES");
	$self->{LASTOP} = 'unlockTables';
	%{$self->{TBLLOCKS}} = ();
}

sub updateRecord{
	my $self = shift;
	my $table = shift;
	my $h_ids = shift;
	my $h_values = shift;
	my $a_flags = shift;
	my %flag;
	foreach (@{$a_flags}){
		($_ eq 'NODIE')
		|| ($_ eq 'MULTI')
		|| ($_ eq 'UPDATEKEY')
		|| ($_ eq 'NOFULLKEYS')
		|| ($_ eq 'NOLOCKS')
		|| ($self->suicide("updateRecord: $_ is unkown flag"));
		$flag{$_} = 1;
	}
	${$self->{FIELDTYPE}}{$table} || ($self->suicide("updateRecord: $table is unkown or not analized"));
	foreach (@{${$self->{TBLKEYS}}{$table}}){
		defined(${$h_ids}{$_}) || $flag{NOFULLKEYS} || ($self->suicide("updateRecord: key '$_' is missing from record identification"));
		defined(${$h_values}{$_}) && ($flag{UPDATEKEY} || ($self->suicide("updateRecord: key '$_' cannot be updated")));
	}
	my $query;
	my $changes;
	my $field;
	my $value;
	while(($field, $value) = each %{$h_ids}){
		$value = $self->format($table, $field, $value, []);
		($query) ? ($query .= " AND $field=$value") : ($query = "WHERE ($field=$value");
	}
	$query .= ')';
	while(($field, $value) = each %{$h_values}){
		$value = $self->format($table, $field, $value, []);
		($changes) ? ($changes .= ", $field=$value") : ($changes = "SET $field=$value");
	}	
	($self->getLock($table) == 2) || $flag{NOLOCKS} || ($self->suicide("updateRecord: cannot update in table unlocked for write"));
	my $records = $self->getValue("SELECT COUNT(*) FROM $table $query");
	if($records){
		($records > 1) && (($flag{MULTI} || (($flag{NODIE}) ? (return 0) : ($self->suicide("updateRecord: more than one record matches query, try MULTI: $query")))));
		$self->{DBH}->do("UPDATE $table $changes $query");
		$self->{LASTOP} = 'updateRecord';
		return $records;
	}
	return 0;
	
	#2do: test for uniqueness of updated values! (if required)
}

sub DESTROY {
	my $self = shift;
	$self->{DBH} && $self->unlockTables();
}
1;
