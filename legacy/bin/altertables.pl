#!/usr/bin/perl

use strict;
use warnings;
use Rapido::DBAccessor;

my $dba = new Rapido::DBAccessor( { DB_DATA => "tobin", DB_USER => "root", DB_HOST => "localhost", DB_PASS => '' } );
my @tables = $dba->getColumn( "SHOW TABLES" );
my $field;
my $table;

foreach $table ( @tables ) {
	$dba->do( "ALTER TABLE `$table` DEFAULT CHARACTER SET latin1 COLLATE latin1_swedish_ci" );
	$dba->do( "ALTER TABLE `$table` CONVERT TO CHARACTER SET latin1 COLLATE latin1_swedish_ci" );
	my @fields = $dba->getMatrix( "SHOW FIELDS FROM $table" );
#	foreach $field ( @fields ) {
#		print "@{$field}\n";
#		print $table.".".$field->[0]."\n";
#	}
	print "$table CONVERTED\n";
}
print "OK\n";
