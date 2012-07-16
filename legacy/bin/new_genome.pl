#!/usr/bin/perl
use strict;
use warnings;
use Rapido::DBAccessor;
use WebArc::LogAccessor;
use WebArc::Parent;

my $dba = new Rapido::DBAccessor;
$dba->initialize('localhost', 'compal2', 'root', '');
my $log = new WebArc::LogAccessor($dba, '1');

my $genome = new WebArc::Parent('o', 0, $dba, $log, 1);
my %data = (	o_def => [['Escherichia coli K12']],
		o_lnk => [['NC_000913.2', 909]],
		o_s => [[10]]
	);
#my %data = (	o_def => [['Pseudomonas putida (strain KT2440) - TIGR']],
#		o_lnk => [['NC_002947.3', 909]],
#		o_s => [[11]]
#	);

my @errors;
	
$genome->process(\%data, \@errors, ['SAVE']);
foreach (@errors){
	print "$_\n";
}
