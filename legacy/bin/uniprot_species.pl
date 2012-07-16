#!/usr/bin/perl
#(C) Miguel Godinho de Almeida - miguel@gbf.de - 2004
#
use strict;
use warnings;
use lib "./WebArc";
use Rapido::DBAccessor;
#use WebArc::CompalAccessor;

my $user = 906;
my $taxidUser = 907;
my $INITIALIZE = 1;
my $line;
my $b_tmp;
my $r_tmp;
my $s_tmp;
my $s_tmp1;
my @a_tmp;
my %h_tmp;
my $name;
my %anames;
my $link;
my %organisms; #key=sprot line
my $started = 0;
my $type = '';
my $taxon;
my $id;
my %candidates;
my $sql;
my $insert;
my $tmp;
my %h_tmp1;
my @row;

my $dba = new Rapido::DBAccessor;
$dba->initialize('localhost', 'compal', 'root', '');
#my $compal = new WebArc::CompalAccessor;
#$compal->initialize($user, $dba);


sub doStore(){
	(length($link)) || (die "FATAL ERROR $link is not valid value for link\n");
	($taxon =~ m/^[1-9]+\d*/) || (die "FATAL ERROR $taxon is not valid value for taxid\n");
	(length($name)) || (die "FATAL ERROR $name is not valid value for name\n");
	$insert = 0;
	$id = 0;
	@row = $dba->get1stColumn("SELECT species FROM species_lnk WHERE user=$user AND lnk='$link'");
	my @candidates = ();
	
	if(scalar(@row) == 0){
		$id = 0;
	}
	elsif(scalar(@row) == 1){
		$id = $row[0];
	}
	else{
		$id = 0;
		@candidates = @row;
	}

	if($id < 0){
		print "Record with Link = $link was previously deleted, no update\n";
	}
	elsif($id == 0){
		if($INITIALIZE){
			$insert=1;
		}
		else{
			die "Candidates Lookup not implemented!\n";
#			my %alreadyLinked;
#			if(@candidates){
#				print "Records with same link - @candidates\n";
#				foreach (@candidates){
#					$alreadyLinked{$_} = 1;
#				}
#			}
#			my %myRecords = $compal->getLinksFromUser('o', $user);
#			my %candidatesList;
#			if($name){
#				@row = ();
#				@row = $compal->searchByPriOrSec('o', $name, [], ['nms']);
#				foreach (@row){
#					$candidatesList{$_} = 1;
#				}
#			}
#			if($taxon){
#				@row = ();
#				@row = $compal->searchByPriOrSec('o', $taxon, ['taxid'], []);
#				foreach (@row){
#					$candidatesList{$_} = 1;
#				}
#			}
#			my @candidatesArray;
#			foreach (keys %candidatesList){
#				($myRecords{$_}) || push (@candidates, $_);
#			}
#			$b = 1;
#			while($b){
#				$b = 0;
#				if(@candidates){
#					%h_tmp = ( lc($name) => 1);
#					foreach (keys %anames){
#						$h_tmp{lc($_)} = 1;
#					}
#					foreach (@candidates){
#						print "ORGANISM: $_";
#						($#candidates) || (print " *****");
#						print "\n";
#						@row = ();
#						if(@row = $compal->getMainAndSerieFromID('o', $_, 'nms')){
#							my $name;
#							foreach $name (@row){
#								print "NAME($_): $name";
#								($h_tmp{lc($name)}) && (print " *****");
#								($alreadyLinked{$_}) && (print "SAME LIK");
#								print "\n";
#							}
#						}
#					}
#				}
#				print "INPUT: $link - Please type target organism, new or skip (";
#				($#candidates) || (print "t,");
#				print "#,n,s)\n";
#				$id = <STDIN>;
#				chop($id);
#				if($id eq 'n'){
#					print "REPORT: $link - new entry\n";
#					$insert = 1;				
#				}
#				elsif($id eq 's'){
#					$id = 0;
#					print "REPORT: skipping $link\n";
#				}
#				elsif(($id =~ m/^\d+$/) || (($#candidates == 0) && (($id eq 't') && ($id = $candidates[0])))){
#					if($myRecords{$id}){
#						print "Wrong target code, organism $id already has link assigned\n";
#						$b = 1;
#					}
#					else{
#						if($compal->getPriFieldFromID('o', $id, 'id')){
#							print  $compal->updatePriField('o', $id, 'taxid', $taxon, 0);
#						}
#						else{
#							print "Wrong target code, organism $id does not exist, please retry\n";
#							$b = 1;
#						}
#					}
#				}
#				else{
#					print "Wrong target code, please retry\n";
#					$b = 1;
#				}
#			}
		}
	}

	if($insert){
		$name = $dba->format($name);
		$id = $dba->sqlAutoInsert("INSERT INTO species (name, active) VALUES ('$name', 0)");
	}
	if($id){
		my @matrix = $dba->getMatrix("SELECT id, user, lnk FROM species_lnk WHERE species=$id");
		my $myLinkOk = 0;
		my $taxidOK = 0;
		foreach (@matrix){
			if(${$_}[1] == $user){
				(${$_}[2] eq $link) || $dba->sqlDo("UPDATE species_lnk SET lnk='$link' WHERE id=${$_}[0]");
				$myLinkOk = 1;
			}
			elsif(${$_}[1] == $taxidUser){
				(${$_}[2] eq $taxon) || $dba->sqlDo("UPDATE species_lnk SET lnk='$taxon' WHERE id=${$_}[0]");
				$taxidOK = 1;
			}
		}
		unless($myLinkOk){
			$link = $dba->format($link);
			$dba->sqlDo("INSERT INTO species_lnk (species, lnk, user) VALUES ($id, '$link', $user)");
		}
		($taxidOK) || $dba->sqlDo("INSERT INTO species_lnk (species, lnk, user) VALUES ($id, $taxon, $taxidUser)");
	}
}
	


my $FILENAME = $ARGV[0];
open (FILE, $FILENAME);
while ($line = <FILE>){
	chop($line);
	if($started){
		if($line =~ s/^\s+//){
			$line =~ s/.=//;
			$line =~ s/\s*$//;
			$anames{$line} = 1;
		}
		else{
			if($type eq 'B'){
				doStore();
			}
			if($line =~ m/^-+/){
				$started = 0;
			}
			else{
				$link = $line;
				$link =~ s/\s.*//;
				$link =~ s/\s*$//;
				$type = substr($line, 6, 1);
				$taxon = $line;
				$taxon =~ s/^.{7}\s*//;
				$taxon =~ s/:.*//;
				$taxon =~ s/\s*$//;
				if($taxon =~ m/\?/){
					$taxon = '';
				}
				$name = $line;
				$name =~ s/^.*N=//;
				$name =~ s/\s*$//;
				%anames = ( $link => 1);
			}
		}
	}
	elsif($line =~ m/_____ _ _+/){
		$started = 1;
	}
}
close(FILE);
