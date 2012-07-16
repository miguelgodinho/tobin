#!/usr/bin/perl
use strict;
use warnings;
use Exporter; 
use Rapido::DBAccessor;

my $line;
my $user = 902;
my $UNIPROT = 906;
my $MAX_NMS = 254;
my $MAX_LINK = 12;
my $INITIALIZE = 0;
my $link;
my $lastname;
my $db;
my $tmp;
my $i;
my $j;
my $ii;
my $ij;
my $ji;
my $jj;
my %h_tmp;
my %h_tmp1;
my %deleted;
my $insert;
my $b;
my $s_tmp;
my $s_tmp1;
my $s_tmp2;
my $id;
my @row;
my @row1;
my @a_tmp;
my $found;
my $sql;
my @candidates;
my $complex;
my $ID;
my $DE;
my %AN;
my %CF;
my %DR;
my %DRnames;
my @CFs;
my %protComplexes;
my %compounds;
my %DRlist;
my %DRactiveSpecies;
my %validLnks;
my $key;
my $value;
my $dba;
my $compal;

sub doStore{
	$insert = 0;
	$link = $ID;

	$AN{"$link"} = 1;
	$AN{"EC $link"} = 1;
	$validLnks{lc($link)} = 1;
	$id = $compal->getPriFromLink('e', $link);
	if($id > 0){
		$compal->updateMainAndSerie('e', $id, 'nms', $DE, \%AN, 0);
		$compal->updateComplexes('e', $id, 'cof', \%CF, 0);
		$compal->updateComplexes('e', $id, 'p', \%protComplexes, 0, 1);
	}
	elsif($id < 0){
		%h_tmp = $compal->getDelValues4SecondaryField('e', $id, 'nms');
		unless($h_tmp{$DE}){
			print "WARNING: $link NEW DE SINCE DELETION\n";
		}
		foreach $s_tmp (keys %AN){
			unless($h_tmp{$s_tmp}){
				print "WARNING: NAME FROM $link CHANGED SINCE DELETION\n";
			}
		}
	}
	else{
		%h_tmp = (	action => '');
		$id = $compal->insertRecord('e', 1, \%h_tmp);
		%h_tmp = (	e => $id,
				lnk => $link,
				user => $user);
		$compal->insertRecord('e_lnk', 1, \%h_tmp);
		%h_tmp = (	e => $id,
				nms => $DE,
				main => 1);
		$compal->insertRecord('e_nms', 1, \%h_tmp);
		foreach $s_tmp (keys %AN){
			if(lc($s_tmp) ne lc($DE)){
				%h_tmp = (	e => $id,
						nms => $s_tmp,
						main => 0);
				$compal->insertRecord('e_nms', 1, \%h_tmp);
			}
		}
		while(($key, $value) = each %CF){;
			foreach $s_tmp (@{$value}){
				%h_tmp = (	e => $id,
						cof => $s_tmp,
						complex => $key);
				$compal->insertRecord('e_cof', 1, \%h_tmp);
			}
		}
		while(($key, $value) = each  %protComplexes){
			foreach $s_tmp (@{$value}){
				%h_tmp = (	e => $id,
						p => $s_tmp,
						complex => $key);
				$compal->insertRecord('p_e', 1, \%h_tmp);
			}
		}
	}
}


$dba = new Rapido::DBAccessor;
$dba->initialize('localhost', 'compal', 'root', '');
	
$dba->sqlDo('TRUNCATE enzymec_xfers');

%DRlist = $dba->getHash("SELECT lnk, p FROM p_lnk WHERE user=$UNIPROT");

%DRactiveSpecies = $dba->getHash("SELECT lnk, species FROM species LEFT JOIN species_lnk ON species_lnk.species=species.id WHERE active=1 AND user=$UNIPROT");

	
$DE = '';
$lastname = '';
open (FILE, $ARGV[0]);
while ($line = <FILE>){
	chop($line);
	if($line =~ m/^\/\//){
		if($ID){
			(length($ID) > $MAX_LINK) && die "FATAL ERROR: - $ID is too big\n";
			($DE) || die "FATAL ERROR: - $ID has no name\n";

			if($DE =~ m/^Deleted entry/){
				$deleted{$ID} = 1;
			}
			elsif($DE =~ s/^Transferred entry:\s*//){
				$DE =~ s/ and/,/g;
				@row = split(/, /, $DE);
				foreach $s_tmp (@row){
					$dba->sqlDo("INSERT INTO enzymec_xfers (from_e, to_e) VALUES ('$ID', '$s_tmp')");
				}
				$deleted{$ID} = 1;
			}
			else{
				#CFs contains n vectors each with alternative compounds, a cofactor complex needs one element of each vector. here the possible combinations will be store on a hash
				if(@CFs){
					@row = ();
					$complex = 1;
					foreach $s_tmp (@CFs){
						push(@row, 0);
					}
					while($complex){
						@row1 = ();
						for ($i = 0; $i <= $#row; $i++){
							$j = $row[$i];
							$s_tmp = lc($CFs[$i][$j]);
							$s_tmp1 = undef;
							$s_tmp1 = $compounds{$s_tmp};
							unless(defined($s_tmp1)){
								unless($s_tmp1 = $dba->get1Value("SELECT c FROM c_nms WHERE main=1 and nms LIKE('$s_tmp')")){
									@a_tmp = ();
									@a_tmp = $dba->get1stColumn("SELECT c FROM c_nms WHERE nms LIKE('$s_tmp') group by c");
									if($#a_tmp == 0){
										$s_tmp1 = $a_tmp[0];
									}
									else{
										print "No compound found for $s_tmp\nPossible candidates:";
										foreach $s_tmp2 (@a_tmp){
											print " $s_tmp";
										}
										print "\nPlease enter target compound # or 0 (zero) to skip\n(Compound name will NOT be auto updated on database)\nCompound #:";
										$s_tmp1 = <STDIN>;
										chop($s_tmp1);
										unless($s_tmp1 =~ m/^\d+$/){
											$s_tmp1 = 0;
										}
									}
								}
								$compounds{$s_tmp} = $s_tmp1;
							}
							if($s_tmp1){
								push(@row1, $s_tmp1);
							}
						}
						if(@row1){
							$CF{$complex} = [@row1];
#							print "$ID : $complex - @row1\n";
							$complex++;
						}
						$i--;
						$j++;
						$row[$i] = $j;
						while($row[$i] > $#{$CFs[$i]}){
							$row[$i] = 0;
							if($i > 0){
								$i--;
								$j = $row[$i];
								$j++;
								$row[$i] = $j;
							}
							else{
								$complex = 0;
							}
						}
					}
				}

				%protComplexes = ();
				if(%DR){
					my $species;
					my $a_ref;
					my $p;
					my $protComplex = 0;
					while(($species, $a_ref) = each %DR){
						$protComplex++;
						foreach (@{$a_ref}){
							$p = 0;
							unless($p = $DRlist{$_}){
								%h_tmp = ('sname' => $DRnames{$_});
								$p = $compal->insertRecord('p', 1, \%h_tmp);
								$DRlist{$_} = $p;
								%h_tmp = (	'p' => $p,
										user => $UNIPROT,
										lnk => $_);
								$compal->insertRecord('p_lnk', 1, \%h_tmp);
							}
							push(@{$protComplexes{$protComplex}}, $p);
						}
					}
				}
				doStore();
			}
		}
		$lastname = '';
		$ID = '';
		$DE = '';
		%AN = ();
		%CF = ();
		%DR = ();
		@CFs = ();
	}
	elsif($line =~ s/^ID\s+//){
		$ID = $line;
		$ID =~ s/^\s*//;
		$ID =~ s/\s.*$//;
	}
	elsif($line =~ s/^DE\s+//){
		if($DE){
			if($DE =~ m/-$/){
				$DE .= $line;
			}
			else{
				$DE = "$DE $line";
			}
			if(length($DE) > $MAX_NMS){
				die "FATAL ERROR: $ID - DE > MAX LENGTH\n";
			}
		}
		else{
			($line =~ m/^\s*(.*)$/) || die "FATAL ERROR - DE - $line";
			$DE = $1;
		}
		$DE =~ s/\.$//;
		$DE =~ s/\s*$//;
	}
	elsif($line =~ s/^AN\s+//){
		if($lastname){
			if($lastname =~ m/-$/){
				$lastname .= $line;
			}
			else{
				$lastname = "$lastname $line";
			}
		}
		else{
			$lastname = $line;
		}
		if($lastname =~ m/\.$/){
			if(length($lastname) > $MAX_NMS){
				die "FATAL ERROR: $ID - AN > MAX LENGTH\n";
			}
			else{
				$lastname =~ s/\.$//;
				$lastname =~ s/^\s*//;
				$lastname =~ s/\s*$//;
				(lc($lastname) ne lc($DE)) && ($AN{$lastname} = 1);
			}
			$lastname = '';
		}
	}
	elsif($line =~ s/^CF\s+//){
		$line =~ s/\.$//;
		$line =~ s/ and /; /g;
		@row = split(/; /, $line);
		foreach $s_tmp (@row){
			@row1 = split(/ or /, $s_tmp);
			push(@CFs, [@row1]);
		}
	}
	elsif($line =~ s/^DR\s+//){
		#it is assumed that for enzymes that are related to more than one protein (DR) belonging to the same organism (Uniprot ID suffix) the enzyme is a complex of the related proteins for the same organism
		@row = split(/;/, $line);
		foreach $s_tmp (@row){
			($s_tmp =~ m/^\s*([^,]+), ([^_]+)_([^_]+)$/) || die "FATAL ERROR: $s_tmp";
			my $uniprotAC = $1;
			my $uniprotProtein = $2;
			my $uniprotOrganism = $3;
			my $species;
			my $a_ref;
			if($species = $DRactiveSpecies{$uniprotOrganism}){
				if($a_ref = $DR{$species}){
					push(@{$a_ref}, $uniprotAC);
				}
				else{
					@{$DR{$species}} = ($uniprotAC);
				}
				($DRnames{$uniprotAC}) || ($DRnames{$uniprotAC} = $uniprotProtein);
			}
		}
	}
}
close(FILE);
%h_tmp = $dba->getHash("SELECT LOWER(lnk), e FROM e_lnk WHERE user=$user");
while(($key, $value) = each %h_tmp){
	unless(($validLnks{$key}) || ($key =~ m/-/)){
		@row = ();
		if(@row = $dba->get1stColumn("SELECT r FROM e_r WHERE e=$value")){
			print "ERROR: EC $key does not exist anymore (please check if transfered or deleted)\nPlease manually edit links from following reactions:\n";
			foreach (@row){
				print "R$_\n";
			}
		}
		elsif(@row = $dba->get1stColumn("SELECT t FROM e_t WHERE e=$value")){
			print "ERROR: EC $key does not exist anymore (please chekc if transfered or deleted)\nPlease manually edit links from following transporters:\n";
			foreach (@row){
				print "T$_\n";
			}
		}
		else{
			@row = ();
			if(@row = $dba->get1stColumn("SELECT lnk FROM e_lnk WHERE e=$value and user != $user")){
				print "ERROR: EC $key does not exist anymore (please check if transfered or deleted)\nPlease manually delete other user links\n";
			}
			else{
				$compal->del('e', $value);
			}
		}
	}
}
