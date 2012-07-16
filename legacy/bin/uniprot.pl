#!/usr/bin/perl
# (C) Miguel Godinho de Almeida - miguel@gbf.de 2004
use strict;
use warnings;

use Rapido::DBAccessor;
#use WebArc::CompalAccessor;
use WebArc::LogAccessor;
use WebArc::Parent;

use SWISS::Entry;
use SWISS::IDs;
use SWISS::ACs;
use SWISS::OXs;
use SWISS::SQs;

my $user = 906;
my $sprot = 903;
my $FILENAME = $ARGV[0];
($FILENAME =~ m/uniprot_sprot/) || ($sprot = 0);
($FILENAME =~ m/uniprot_/) || die "FATAL ERROR - wrong file name";
my $TAXIDUSER = 907;
my $MAX_GENOMEDESC = 254;
my $dba = new Rapido::DBAccessor;
my $log = new WebArc::LogAccessor($dba, $user);
$dba->initialize('localhost', 'compal2', 'root', '');
my $accProts = 0;
my $totProts = 0;
my $insProts = 0;
my $delProts = 0;

my %activeSpecies = $dba->getHash("SELECT v, p FROM s_lnk WHERE n=$TAXIDUSER");
my %storedLinks = $dba->getHash("SELECT v, p FROM p_lnk WHERE n=$user");
my %seqByProt = $dba->getHash("SELECT p, v FROM p_seq");
#%enzByProt = $dba->getHash("SELECT e_p.v, e_p.p FROM p_lnk LEFT JOIN e_p ON e_p.v=p_lnk.p WHERE p_lnk.n=$user AND e_p.v IS NOT NULL");
my %checkedLinks;
$dba->analizeTable('p_s');

sub doStore{
	my $link = shift;
	my $a_ACs = shift;
	my $sname = shift;
	my $seq = shift;
	my $a_species = shift;
	my $a_names = shift;
	my $id;
	my $tmp;


	my $ref;
	($id = $storedLinks{$link}) ? ($ref = new WebArc::Parent('p', $id, $dba, $log, $user)) : ($ref = new Rapido::Parent('p', 0, $dba, $log, $user));
	
	my @errors;
	my %data = (	p_sname => [[$sname]],
			p_lnk => [[$link, $user]],
			p_seq => [[$seq]],
			p_nms => $a_names);
	$ref->process(\%data, \@errors, ['SAVE']);
	foreach (@errors){
		print "ERR: $_\n";
		die;
	}
	$id = $ref->{ID};
	foreach (@{$a_species}){
		$dba->insertRecord('p_s', {protein => $id, species => $_}, ['NOREPEAT']);
	}
	#update p_s
	$accProts++;
}


$/ = "\n//\n";
open (FILE, $FILENAME);
while(<FILE>){
	my @speciesList = ();
	my $a_tmp;
	my $entry = SWISS::Entry->fromText($_);
	my $sname = $entry->ID;
	my $link = $entry->ACs->head;
	($checkedLinks{$link}) ? (die "FE $link shows twice") : ($checkedLinks{$link} = 1);
	my @ACs = $entry->ACs->tail;
	($sname =~ s/_.*//) || ($sname = '');
	(($sprot) && !($sname)) && (die "UE1 - ID is missing - $link");
	(!($sprot) && ($sname)) && (die "UE2 - ID should not exist - $link");
	foreach ($entry->OXs->NCBI_TaxID()->elements){
		($a_tmp = $activeSpecies{$_->text}) && (push(@speciesList, $a_tmp));
	}
	my $seq = $entry->SQ;
	my $name = $entry->DEs->head->toText();
	$name =~ s/^\s*//;
	$name =~ s/\s*$//;
	my $aname;
	($name =~ s/^'//) && ($name =~ s/'$//);
	my @anames = ([$name, 1, 1]);
	my $serie = 2;
	foreach $aname ($entry->DEs->tail){
		$aname = $aname->toText();
		$aname =~ s/^\s*//;
		$aname =~ s/\s*$//;
		($aname =~ s/^'//) && ($name =~ s/'$//);
	
		push(@anames, [$aname, $serie, 0]);
		$serie++;
	}
	$totProts++;

	(@speciesList) && doStore($link, \@ACs, $sname, $seq, \@speciesList, \@anames);
}

#foreach (keys %links){
#	($validLinks{$_}) || $compal->delByLink('g', $user, $_, 0);
#}
print "Accounted proteins: $accProts of $totProts\nInserted proteins: $insProts\nDelete proteins: $delProts\n";
my $protID;
my $a_enzIDs;
if($sprot){
#	while(($protID, $a_enzIDs) = each %enzByProt){
#		($a_enzIDs) && (print "Protein $protID has been moved, please check enzymes: @{$a_enzIDs}\n");
#	}
}
close(FILE);
