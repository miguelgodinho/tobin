#!/usr/bin/perl
#(C) Miguel Godinho de Almeida - miguel@gbf.de - 2004
#
use strict;
use warnings;
use Rapido::DBAccessor;
use WebArc::Parent;
use WebArc::LogAccessor;


my $SPECIES = 10; #  KT  !!!!!!!!!!!!!!!!!!!!!!!!!Make sure is ok! 
my $GENOME = 2;
#my $SPECIES = 1630; #K12
#my $SPECIES = 1629; #ecoli h
#my $SPECIES = 1632; #PAU
my $user = 909;
my $dba = new Rapido::DBAccessor;
$dba->initialize('localhost', 'compal2', 'root', '');
my $log = new WebArc::LogAccessor($dba, $user);





my $line;
my @row;
my $str;
my $key;
my $value;
my $bof = 0;
my $eof = 0;
my $last = '';
my $spacer = '';
my $geneCount = 0;
my $cdsCount = 0;
my %geneData = ();
my %cdsData = ();
my $h_data;
my $field;
my $genPosA;
my $genPosB;
my $genPosC;
my $genPosD;
my $cdsPosA;
my $cdsPosB;
my $cdsPosC;
my $cdsPosD;

my $FILENAME = $ARGV[0];
open (FILE, $FILENAME);
while ($line = <FILE>){
	chop($line);
	if($line =~ m/^(\w+)/){#1
		if($1 eq 'FEATURES'){#1.1
			($bof) ? (die 'UE1.1') : ($bof = 1);
		}
		elsif($1 eq 'ORIGIN'){#1.2
			($bof) ? ($bof = 0) : (die 'UE1.2');
		}
		elsif($1 eq '\/\/'){#1.3
			($bof) && (die 'UE1.3.1');
			($eof) ? (die 'UE1.3.2') : ($eof = 1);
		}
	}
	elsif($bof && !$eof){#2
		if($last){#2.1
			($line =~ m/^\s{21}([^"]*)("?)$/) || die 'UE2.1';
			if($last eq 'skip'){}
			elsif($field eq 'cds'){#2.1.1
				(${$cdsData{$cdsCount}}{$last}) || die 'UE2.1.1';
				${$cdsData{$cdsCount}}{$last} .= $spacer.$1;
			}
			elsif($field eq 'gene'){#2.1.2
				if($last eq 'synonyms'){
					($line =~ m/^([^;]*);?.*$/) || die 'UE2.1.2';
					$str = $1;
					if(@{${$geneData{$geneCount}}{synonyms}}){
						@row = @{${$geneData{$geneCount}}{synonyms}};
						unless($row[$#row] =~ s/,$//){
							$str = (pop(@row)).$str;
						}
						@{${$geneData{$geneCount}}{synonyms}} = @row;
					}
					@row = split(/, /, $str);
					(${$geneData{$geneCount}}{gene}) || die 'UE2.1.2.2';
					(scalar(@row)) && (push(@{${$geneData{$geneCount}}{synonyms}}, @row));
					($line =~ m/;/) && ($last = 'skip');
				}
				else{
					(${$geneData{$geneCount}}{$last}) || die 'UE2.1.2';
					${$geneData{$geneCount}}{$last} .= $spacer.$1;
				}
			}
			else{#2.1.5
				die "UE2.1.5";
			}
			
			if($line =~ m/"$/){#2.1.6
				$last = '';
				$spacer = '';
			}
		}
		elsif($line =~ s/^\s{21}\///){#2.2
			if($field eq 'cds'){#2.2.1
				($cdsData{$cdsCount}) || (%{$cdsData{$cdsCount}} = (gene => $geneCount));
				$h_data = $cdsData{$cdsCount};
				if($line =~ m/^product="([^"]+)"?$/){
					(${$h_data}{product}) && die 'UE2.2.1.1';
					${$h_data}{product} = $1;
					($line =~ m/"$/) ? ($last = '') : ($last = 'product');
				}
				elsif($line =~ m/^translation="([^"]+)"?$/){
					(${$h_data}{translation}) && die 'UE2.2.1.2';
					${$h_data}{translation} = $1;
					($line =~ m/"$/) ? ($last = '') : ($last = 'translation');
				}
				elsif($line =~ m/^note="([^"]+)"?$/){
					(${$h_data}{note}) && die 'UE2.2.1.3';
					${$h_data}{note} = $1;
					($line =~ m/"$/) ? ($last = '') : ($last = 'note');
				}
				elsif($line =~ m/^gene="(.*)"$/){
					if($1 ne ${$geneData{$geneCount}}{gene}){
						if($1 ne ${$geneData{$geneCount}}{locus}){
							$str = 0;
							foreach (@{${$geneData{$geneCount}}{synonyms}}){
								($_ eq $1) && ($str = 1);
							}
							($str) || die "UE2.2.1.4";
						}
					}
				}
				elsif($line =~ m/^locus_tag="(.*)"$/){
					($1 ne ${$geneData{$geneCount}}{locus}) && die "UE2.2.1.5";
				}
				elsif($line =~ m/^codon_start=(\d+)$/){

				}
				elsif($line =~ m/^transl_table=(\d+)$/){

				}
				elsif($line =~ m/^protein_id="(.*)"$/){
					(${$h_data}{pid}) && die "UE2.2.1.6";
					${$h_data}{pid} = $1;
				}
				elsif($line =~ m/^db_xref=".*$/){
					if($line =~ m/^db_xref="GeneID:(.+)"/){
						(${$geneData{$geneCount}}{link} == $1) || die 'UE2.2.1.7';
					}
					elsif($line =~ m/^db_xref="UniProt\/[^:]+:(.+)"/){
						${$h_data}{uniprot} = $1;
					}
				}
				elsif($line =~ m/^EC_number="(\d+\..*)"$/){}
				elsif($line =~ m/^exception="(.*)"$/){}
				elsif($line =~ m/^function="([^"]+)"?$/){
					(${$h_data}{function}) ? (${$h_data}{function} .= "; $1") : (${$h_data}{function} = $1);
					($line =~ m/"$/) ? ($last = '') : ($last = 'function');
				}
				elsif($line =~ m/^pseudo$/){
					(${$h_data}{pseudo}) && die 'UE2.2.1.8';
					${$h_data}{pseudo} = 1;
				}
				elsif($line =~ m/^selenocysteine$/){}
				elsif($line =~ m/^transl_except=\(.*\)$/){}
				elsif($line =~ m/^evidence=(not_)?experimental$/){}
				else{
					die "UE 2.2.1 cds - $line";
				}
			}
			elsif($field eq 'gene'){#2.2.2
				$h_data = $geneData{$geneCount};
				if($line =~ m/^gene="(.*)"$/){
					(${$h_data}{gene}) && die 'UE2.2.2.1';
					${$h_data}{gene} = $1;
				}
				elsif($line =~ m/^locus_tag="(.*)"$/){
					(${$h_data}{locus}) && die 'UE2.2.2.2';
					${$h_data}{locus} = $1;
				}
				elsif($line =~ m/^note="synonym[s]?: ([^;"]+);?([^"]*)"?$/){
					@row = split(/, /, $1);
					unless($line =~ m/"$/){
						($line =~ m/;/) ? ($last = 'skip') : ($last = 'synonyms');
					}
					(${$h_data}{gene}) || (${$h_data}{gene} = shift(@row));
					(scalar(@row)) && (@{${$h_data}{synonyms}} = @row);
				}
				elsif($line =~ m/^note="([^"]+)"?$/){
					(${$h_data}{note}) && die 'UE2.2.2.4';
					${$h_data}{note} = $1;
					if($line =~ m/"$/){
						$last = '';
					}
					else{
						$spacer = ' ';
						$last = 'note';
					}
				}
				elsif($line =~ m/^db_xref=".*"$/){
					if($line =~ m/^db_xref="GeneID:(\d+)"/){
						(${$h_data}{link}) && die 'UE2.2.2.5';
						${$h_data}{link} = $1;
					}
				}
				elsif($line =~ m/^pseudo$/){}
				elsif($line =~ m/^operon="(.*)"$/){}
				else{
					die "UE2.2.2 gene - $line";
				}
			}
			elsif(($field eq 'misc') || ($field eq 'skip')){#2.2.3
				($line =~ m/.*".*[^"]$/) && ($last = 'skip');
			}
		}
		elsif($line =~ m/^\s{5}(\S+)\s+(.*)$/){#2.3
			if($1 eq 'CDS'){#2.3.1
				$field = 'cds';
				$cdsCount++;
			}
			elsif($1 eq 'gene'){#2.3.2
				$field = 'gene';
				$geneCount++;
				%{$geneData{$geneCount}} = ();
			}
			elsif(	($1 eq 'rRNA') ||#2.3.3
				($1 eq 'tRNA') ||
				($1 eq 'repeat_region') ||
				($1 eq 'repeat_unit') ||
				($1 eq 'misc_RNA') ||
				($1 eq 'misc_feature') ||
				($1 eq 'rep_origin') ||
				($1 eq 'operon') ||
				($1 eq 'RBS') ||
				($1 eq 'stem_loop') ||
				($1 eq 'oriT') ||
				($1 eq 'source')){
				$field = 'misc';
			}
			else{
				die "UE2.3";
			}
			
			$line = $2;
			if($field eq 'gene'){ 
				if($line =~ m/^<?(\d+)\.\.>?(\d+)$/){
					$genPosA = $1;
					$genPosB = $2;
					$genPosC = 0;
					$genPosD = 0;
					($genPosA < $genPosB) || die "UE2.4.1";
				}
				elsif($line =~ m/^complement\(<?(\d+)\.\.>?(\d+)\)$/){
					$genPosA = $1;
					$genPosB = $2;
					$genPosC = 0;
					$genPosD = 0;
					($genPosA < $genPosB) || die "UE2.4.2";
				}
				elsif($line =~ m/^join\((\d+)\.\.(\d+),(\d+)\.\.(\d+)\)$/){
					$genPosA = $1;
					$genPosB = $2;
					$genPosC = $3;
					$genPosD = $4;
					(($genPosA < $genPosB) && ($genPosC < $genPosD)) || die "UE2.4.3";
				}
				elsif($line =~ m/^complement\(join\((\d+)\.\.(\d+),(\d+)\.\.(\d+)\)\)$/){
					$genPosA = $1;
					$genPosB = $2;
					$genPosC = $3;
					$genPosD = $4;
					(($genPosA < $genPosB) && ($genPosC < $genPosD)) || die "UE2.4.4";
				}
				else{
					die "UE2.4.1$line\n";
				}
			}
			elsif($field eq 'cds'){
				if($line =~ m/^<?(\d+)\.\.>?(\d+)$/){
					$cdsPosA = $1;
					$cdsPosB = $2;
					$cdsPosC = 0;
					$cdsPosD = 0;
					($cdsPosA < $cdsPosB) || die "UE2.5.1";
				}
				elsif($line =~ m/^complement\(<?(\d+)\.\.>?(\d+)\)$/){
					$cdsPosA = $1;
					$cdsPosB = $2;
					$cdsPosC = 0;
					$cdsPosD = 0;
					($cdsPosA < $cdsPosB) || die "UE2.5.2";
				}
				elsif($line =~ m/^join\((\d+)\.\.(\d+),(\d+)\.\.(\d+)\)$/){
					$cdsPosA = $1;
					$cdsPosB = $2;
					$cdsPosC = $3;
					$cdsPosD = $4;
					(($cdsPosA < $cdsPosB) && ($cdsPosC < $cdsPosD)) || die "UE2.5.3";
				}
				elsif($line =~ m/^complement\(join\((\d+)\.\.(\d+),(\d+)\.\.(\d+)\)\)$/){
					$cdsPosA = $1;
					$cdsPosB = $2;
					$cdsPosC = $3;
					$cdsPosD = $4;
					(($cdsPosA < $cdsPosB) && ($cdsPosC < $cdsPosD)) || die "UE2.5.4";
				}
				else{
					die "UE2.5.1$line\n";
				}
				(($genPosA && $genPosB) && ($cdsPosA >= $genPosA) && ($cdsPosB <= $genPosB)) || ($field = 'skip');
			}
		}
		else{
			die "UE2.4-$field-$line";
		}
	}
	elsif($eof && !$bof){
		print "parsing $FILENAME ok";
	}
}
close(FILE);

my $gene;
my $link;
my $name;
my $locus;
my %hash;
my %dataGenes;
my %dataName;
my %dataLocus;
my %dataLinks;
my %anames;
my $gid;
my $pid;
my $ok;
my $i = 0;
my $sprots = 0;

my %storedLinks = ();
#my %storedLinks = $dba->getHash("SELECT g_lnk.lnk, g_lnk.g FROM g LEFT JOIN g_lnk ON g_lnk.g=g.id WHERE g.genome=$SPECIES AND g_lnk.lnk IS NOT NULL");
#($dba->get1stValue("SELECT 1 FROM g LEFT JOIN g_lnk ON g_lnk.g=g.id WHERE g.genome=$SPECIES AND g_lnk.lnk IS NULL")) && die "UE3.0";
#my %storedLocus = $dba->getHash("SELECT id, locus FROM g WHERE genome=$SPECIES AND locus IS NOT NULL");
#my %storedProtSeqs = $dba->getHash("SELECT seq, p FROM p_seq");
#my %storedProtLinks = $dba->getHash("SELECT p_lnk.lnk, p_lnk.p FROM g LEFT JOIN g_p ON g_p.g=g.id LEFT JOIN p_lnk ON p_lnk.p=g_p.p WHERE g.genome=$SPECIES AND p_lnk.user=$GBK");
#my %storedGeneProts = $dba->getHashArray("SELECT g_p.g, g_p.p FROM g LEFT JOIN g_p ON g_p.g=g.id WHERE g.genome=$SPECIES AND g_p.g IS NOT NULL");

my %protBySec = $dba->getHash("SELECT p_seq.v, p_seq.p FROM p_s LEFT JOIN p_seq ON p_seq.p=p_s.protein WHERE p_s.species=$SPECIES", ['MULTI']);

foreach $h_data (values %cdsData){
	($gene = ${$h_data}{gene}) || die "UE3.1";
	if((${$h_data}{product}) && (${$h_data}{product} =~ m/^hypothetical protein/)){
		(${$h_data}{uniprot}) || ($gene = '');
	}
	
	if($gene){
		$ok = 1;
		if(${$h_data}{pid}){
			if(${$geneData{$gene}}{link}){
				unless(${$geneData{$gene}}{gene}){
					($locus = ${$geneData{$gene}}{locus}) ? (${$geneData{$gene}}{gene} = $locus) : ($ok = 0);
				}
			}
			else{
				$ok = 0;
			}
		}
		else{
			(${$h_data}{pseudo}) ? ($gene = '') : ($ok = 0);
		}
	
		unless($ok){
			(${$geneData{$gene}}{link}) ? (print "ATT link:${$geneData{$gene}}{link}, ") : (print "ATT no link, ");
			(${$geneData{$gene}}{gene}) ? (print "gene:${$geneData{$gene}}{gene}, ") : (print "no gene, ");
			(${$h_data}{pid}) ? (print "pid:${$h_data}{pid}\n") : (print "no pid\n");
			$gene = '';
		}
	}
	
	if($gene){
		$i++;
		$name = '';
		$locus = '';
		$gid = 0;
		%anames = ();
		($gid = $dataGenes{$gene}) && (die "gene $link codes for more than 1 prot");
		($link = ${$geneData{$gene}}{link}) || (die "UE3.6 - this should never happen");
		($name = ${$geneData{$gene}}{gene}) || die "UE3.3 ${$h_data}{pid}";
		($dataLinks{$link}) ? (die "UE3.7 $link") : ($dataLinks{$link} = 1);
		if($locus = ${$geneData{$gene}}{locus}){
			($dataLocus{$locus}) ? (die "UE3.5 $locus") : ($dataLocus{$locus} = $locus);
		}
		else{
			($locus = '');
		}
		
		($name && (length($name) < 15)) || (die "UE3.6 - wrong value for name - $name");
		(($locus && (length($locus) < 10)) || !($locus)) || (die "UE3.6 - wrong value for locus - $locus");
		foreach (@{${$geneData{gene}}{synonyms}}){
			($1 && (length($1) < 10)) ? ($anames{$1} = 1) : (die "UE3.6 - max size exceeded - $1");
		}
		($name ne $locus) && ($anames{$locus} = 1);
		($gid = $storedLinks{$link}) && (die "there should be no stored genes");
		my @prots;
		my $prot = 0;
		if($_ = ${$h_data}{uniprot}){
			($prot = $dba->getValue("SELECT p FROM p_lnk WHERE n=906 and v='$_'")) || die "link not found $_";
			if($_ = ${$h_data}{translation}){
				($dba->getValue("SELECT v FROM p_seq WHERE p=$prot") eq $_) || die "prot $_ seq is diff";
				@prots = ([$prot]);
			}
		}
		elsif($_ = ${$h_data}{translation}){
			if($prot = $protBySec{$_}){
				@{$prot} || ($sprots++);
				foreach (@{$prot}){
					push(@prots, [$_]);
				}
			}
			else{
				$sprots++;
			}
		}
		else{
			while(($key, $value) = each %{$h_data}){
				print "::::$key - $value\n";
			}
			while(($key, $value) = each %{$geneData{$gene}}){
				print "$key - $value\n";
			}
			die "no way to identify prot";
		}
		
		my $entry = new WebArc::Parent('g', 0, $dba, $log, $user);
		my $name;
		unless($name = ${$geneData{$gene}}{gene}){
			die "$gene";
		}

		my @names = [$name, 1, 1];
		my $ncount = 2;
		foreach (@{${$geneData{$gene}}{synonyms}}){
			push(@names, [$_, $ncount++, 0]);
		}
		my %data = (	g_lnk => [[$link, $user]],
				g_locus => [[$locus]],
				g_nms => \@names,
				g_o => [[$GENOME]]);
		@prots && ($data{g_p} = \@prots);

		my @errors;
		$entry->process(\%data, \@errors, ['SAVE']);
		foreach (@errors){
			print "ERR $_\n";
		}
	}
}
#while(($key, $value) = each %storedLinks){
#	unless($dataLinks{$key}){
#		$dba->sqlDo("DELETE FROM g WHERE id=$value");
#		$dba->sqlDo("DELETE FROM g_lnk WHERE g=$value");
#		$dba->sqlDo("DELETE FROM g_nms WHERE g=$value");
#		print "delete $value\n";
#	}
#}




print "$geneCount genes\n$cdsCount CDS\n$i proteins\n";
print "skipped prots $sprots\n";
#my $g;
#my %p_g;
#my %g_p;
#my $p;
#my $complex;
#my %hash;
#my $dataGene;
#my $dataProt;
#my $dataTrans;
#my $dataProd;
#my $dataLocus;
#my $dataNotes;
#my %locus;
#my $lastGene;
#my %names;
#my @syns;
#my $lastgene;
#my %storedLocus = $dba->getHash("SELECT locus, id FROM g WHERE genome=$SPECIES");
#my %storedLocusByID = $dba->getHash("SELECT id, locus FROM g WHERE genome=$SPECIES");
#my %storedNames = $dba->getHash("SELECT sname, id FROM g WHERE genome=$SPECIES");
#my %storedNamesByID = $dba->getHash("SELECT id, sname FROM g WHERE genome=$SPECIES");
#my %storedTrans = $dba->getHash("SELECT trans, p FROM p_trans");
#my $storedTransByID = $dba->getHash("SELECT p, trans FROM p_trans");
#my @matrix = $dba->getMatrix("SELECT p, g, complex FROM p_g");
#foreach (@matrix){
#	$p = ${$_}[0];
#	$g = ${$_}[1];
#	$complex = ${$_}[2];
#	($p_g{$p}) || (%{$p_g{$p}} = ());
#	(${$p_g{$p}{$complex}}) || (@{${$p_g{$p}}{$complex}} = ());
#	push(@{${$p_g{$p}}{$complex}}, $g);
#	($g_p{$g}) || (%{$g_p{$g}} = ());
#	${$g_p{$g}}{$p} = 1;
#}
#my %storedPByLnk = $dba->getHash("SELECT lnk, p FROM p_lnk WHERE user=$GBK");
#my %storedLnkByP = $dba->getHashArray("SELECT p, lnk FROM p_lnk WHERE user=$GBK");

#foreach (@data){
#	@syns = ();
#	($dataProt = ${$_}{prot}) || ($dataProt = '');#ATT - gene can exist without protein
#	if($dataProt){
#		($dataNotes = ${$_}{note}) || ($dataNotes = '');
#		if($dataNotes =~ s/^synonym(s{0,1}): //){# || die "UE9 - $dataNotes";
#			my @syns = split(/, /, $dataNotes);
#			(${$_}{Pgene}) || (${$_}{Pgene} = pop(@syns));
#			($parsed_genes{${$_}{Pgene}}) ? (die "UE5.1") : ($parsed_genes{${$_}{Pgene}} = 1);
#		}
#		($dataLocus = ${$_}{locus}) || die "UE5.2.1 $dataGene";
#		unless($dataGene = ${$_}{Pgene}){
#			$dataGene = $dataLocus;
#			($parsed_genes{$dataGene}) ? (die "UE5.2.2") : ($parsed_genes{$dataGene} = 1);
#		}
#		$lastGene = $dataGene;
#		($dataTrans = ${$_}{trans} || !$dataProt) || die "UE5.3";
#		
##		($dataLocus = ${$_}{note}) || ($dataLocus = $dataGene);
##		($dataLocus =~ m/^\w+\d+$/) || die "UE13 $dataLocus";
#		(length($dataGene) < 10) || die "UE5.4 $dataGene is too long";
#		($names{$dataGene}) && die "UE5.5 $dataGene";
#		$names{$dataGene} = 1;
#		(length($dataLocus) < 10) || die "UE5.6 $dataLocus is too long";
#		($locus{$dataLocus}) && die "UE5.7 $dataLocus";
#		$locus{$dataLocus} = 1;
#		if($g = $storedLocus{$dataLocus}){
#	
#		}
#		elsif($g = $storedNames{$dataGene}){
#			die "UE5.8 - $dataGene";
#		}
#		elsif($g = $storedPByLnk{$dataProt}){
#			die "UE5.9 - $dataProt";
#		}
#		elsif($g = $storedTrans{$dataTrans}){
#			die "UE5.10 - $dataTrans";
#		}
##		print "$dataGene\n";
#		%hash = (	sname => $dataGene,
#				genome => $SPECIES,
#				locus => $dataLocus);
#		%hash = (	lnk => $dataProt,
#				user => $GBK,
#			g => $g);
##		$dba->recordInsert('g_lnk', \%hash);
#		%hash = (	g => $g,
#			trans => $dataTrans);
##		$dba->recordInsert('g_trans', \%hash);
#	}	}
#}
