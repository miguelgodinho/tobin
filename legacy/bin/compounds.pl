#!/usr/bin/perl
use strict;
use warnings;
use Exporter; 

my $line;
my $user = 901;
my $MAX_NMS = 254;
my $MAX_FORMULA = 254 ;
my $MAX_LINK = 12;
my $INITIALIZE = 0;
my $link;
my %anames;
my $name;
my $lastname;
my $formula;
my $lastField = '';
my $db;
my $tmp;
my %h_tmp;
my %h_tmp1;
my %skipped;
my $insert;
my $b;
my $s_tmp;
my $s_tmp1;
my $s_tmp2;
my $id;
my @row;
my @row1;
my $found;
my $sql;
my @candidates;
	
Rapido::General::dbInit('localhost', 'compal', 'root', '', $user);

sub whoDelete0{ #return code for the user who deleted the value
	my $table = $_[0];
	my $id = $_[1];
	my $field = $_[2];
	my $value = $_[3];
	my $s_tmp;

	my $fvalue = Rapido::General::sqlFormat($value);
	if($s_tmp = Rapido::General::sqlVal1("SELECT user FROM log WHERE tbl='$table' AND code=$id AND field='$field' AND old='$fvalue'")){
		return $s_tmp;
	}
	else{
		return 0;
	}
}

sub checkDelete0{
	my $table = $_[0];
	my $id = $_[1];
	my $field = $_[2];
	my $s_tmp;
	
	if($s_tmp = Rapido::General::sqlVal1("SELECT MAX(id) FROM log WHERE tbl='$table' AND code=$id AND field='$field' AND old !=''")){
		return Rapido::General::sqlVal1("SELECT old FROM log WHERE id=$s_tmp");
	}
	return '';
}

sub checkDelete1{
	my $table = $_[0];
	my $idfield = $_[1];
	my $id = $_[2];
	my $field = $_[3];
	my $value = $_[4];
	my $s_tmp;
	my @row;
	
	my $fvalue = Rapido::General::sqlFormat($value);
#	print "SELECT code FROM log WHERE tbl='$table' AND field='$idfield' AND old='$id' ORDER BY id DESC\n";
	if(@row = Rapido::General::sqlSel1("SELECT code FROM log WHERE tbl='$table' AND field='$idfield' AND old='$id' ORDER BY id DESC")){
		foreach $s_tmp (@row){
			if(Rapido::General::sqlVal1("SELECT id FROM log WHERE tbl='$table' AND field='$field' AND old='$fvalue' AND code=$s_tmp")){
				return $s_tmp;
			}
		}
	}
	return 0;
}

sub checkDelete2{
	my $table = $_[0];
	my $idfield = $_[1];
	my $field1 = $_[2];
	my $value1 = $_[3];
	my $field2 = $_[4];
	my $value2 = $_[5];

	my $s_tmp;
	
	if($s_tmp = checkDelete1($table, $field1, $value1, $field2, $value2)){
		return  Rapido::General::sqlVal1("SELECT old FROM log WHERE tbl='$table' AND field='$idfield' AND code=$s_tmp");
	}
	return 0;
}
	

sub checkExist1{ #returns id, 0 if not exist
	my $table = $_[0];
	my $idfield = $_[1];
	my $id = $_[2];
	my $field = $_[3];
	my $value = $_[4];
	my $s_tmp;

	my $fvalue = Rapido::General::sqlFormat($value);
	$s_tmp = 0;
	if($s_tmp = Rapido::General::sqlVal1("SELECT id FROM $table WHERE $idfield='$id' AND $field='$fvalue'")){
		return $s_tmp;
	}
	else{
		return 0;
	}
}

sub checkExist2{ #return id, 0 if not exist
	my $table = $_[0];
	my $idfield = $_[1];
	my $field1 = $_[2];
	my $value1 = $_[3];
	my $field2 = $_[4];
	my $value2 = $_[5];
	my $s_tmp;
	
	my $fvalue1 = Rapido::General::sqlFormat($value1);
	my $fvalue2 = Rapido::General::sqlFormat($value2);
#	print "SELECT $idfield FROM $table WHERE $field1='$fvalue1' AND $field2='$fvalue2'\n";
	if($s_tmp = Rapido::General::sqlVal1("SELECT $idfield FROM $table WHERE $field1='$fvalue1' AND $field2='$fvalue2'")){
		return $s_tmp;
	}
	else{
		return 0;
	}
}

sub checkEverExist1{
	my $table = $_[0];
	my $idfield = $_[1];
	my $id = $_[2];
	my $field = $_[3];
	my $value = $_[4];
	if(checkExist1($table, $idfield, $id, $field, $value)){
		return 1;
	}
	else{
		if(checkDelete1($table, $idfield, $id, $field, $value)){
			return 1;
		}
	}
	return 0;
}

sub checkOwner0{
	my $table = $_[0];
	my $id = $_[1];
	my $field = $_[2];

	my $s_tmp;
	my $s_tmp1;
	
	if($s_tmp = Rapido::General::sqlVal1("SELECT MAX(id) FROM log WHERE tbl='$table' AND code='$id' AND field='$field'")){
		if($s_tmp1 = Rapido::General::sqlVal1("SELECT user FROM log WHERE id='$s_tmp'")){
			return $s_tmp1;
		}
	}
	else{
		if($s_tmp1 = Rapido::General::sqlVal1("SELECT user FROM log WHERE tbl='$table' AND code='$id' AND field='' AND old=''")){
			return $s_tmp1;
		}
	}
	return 0;
}

sub getMyRecords1{
	my $table = $_[0];
	my $field = $_[1];
	my $idfield = $_[2];
	my $id = $_[3];
	
	return Rapido::General::sqlSelHash("SELECT $table.$field, $table.id FROM $table LEFT JOIN log ON log.code=$table.id WHERE $table.$idfield=$id AND log.user=$user AND log.tbl='$table' AND field='' AND old=''");
}

sub getDelFields1{
	my $table = $_[0];
	my $idfield = $_[1];
	my $id = $_[2];
	my $field = $_[3];

	my @row;
	my $s_tmp;
	my $s_tmp1;
	my %h_tmp;

	if(@row = Rapido::General::sqlSel1("SELECT code FROM log WHERE tbl='$table' AND field='$idfield' AND old=$id GROUP BY code")){
		foreach $s_tmp (@row){
			$s_tmp1 = Rapido::General::sqlVal1("SELECT old FROM log WHERE tbl='$table' AND field='$field' AND code=$s_tmp");
			$h_tmp{$s_tmp1} = 1;
		}
	}
	return %h_tmp;
}

sub doStore{
	$insert = 0;
	$name =~ s/\s+$//;
	$formula =~ s/\s+$//;
	$link =~ s/\s+$//;

	$id = 0;
	if($id = checkExist2('c_lnk', 'c', 'user', $user, 'lnk', $link)){
		$tmp = '';
		$tmp = Rapido::General::sqlVal1("SELECT formula FROM c WHERE id='$id'");
		if($tmp ne $formula){
			if(checkOwner0('c', $id, 'formula') == $user){
				Rapido::General::dbChangeRecord('c', $id, 'formula', $formula);
			}
			else{
				unless(whoDelete0('c', $id, 'formula', $formula)){
					print "WARNING: NEW FORMULA FOR $link - NOT UPDATED\n";
				}
			}
		}

		%h_tmp = Rapido::General::sqlSelHash("SELECT LOWER(nms) AS c_name, 1 FROM c_nms WHERE c=$id GROUP BY c_name");
		unless($h_tmp{lc($name)}){
			unless(checkDelete1('c_nms', 'c', $id, 'nms', $name)){
				print "REPORT: $link updated - new name inserted\n";
				%h_tmp1 = (	c => $id,
						nms => $name,
						main => 0);
				Rapido::General::dbInsertRecord('c_nms', 1, \%h_tmp1);
			}
		}
		foreach $s_tmp (keys %anames){
			unless($h_tmp{lc($s_tmp)}){
				unless(checkDelete1('c_nms', 'c', $id, 'nms', $s_tmp)){
					print "REPORT: $link updated - new name inserted\n";
					%h_tmp1 = (	c => $id,
							nms => $s_tmp,
							main => 0);
					Rapido::General::dbInsertRecord('c_nms', 1, \%h_tmp1);
				}
			}			
		}
		
		%h_tmp = getMyRecords1('c_nms', 'nms', 'c', $id);
		foreach $tmp (keys %h_tmp){
			unless($tmp eq $name){
				unless($anames{$tmp}){
					unless(Rapido::General::sqlVal1("SELECT COUNT(*) FROM c_nms WHERE c=$id")){
						die "FATAL ERROR: $link NEEDS AT LEAST 1 NAME - CANNOT DELETE NAME\n";
					}
					
					print "REPORT: $link - deleted name id $h_tmp{$tmp} - does not exist on parsed file\n";
					if(Rapido::General::sqlVal1("SELECT main FROM c_nms WHERE id=$h_tmp{$tmp}")){
						print "WARNING: $link - deleted main name, NEW MAIN NAME IS ARBITARY\n";
						$s_tmp = Rapido::General::sqlVal1("SELECT MIN(id) FROM c_nms WHERE c=$id and main=0");
						Rapido::General::dbChangeRecord('c_nms', $s_tmp, 'main', 1);
					}
					Rapido::General::dbDel('c_nms', $h_tmp{$tmp});
				}
			}
		}
	}
	else{
		$id = 0;
		if($id = checkDelete2('c_lnk', 'c', 'lnk', $link, 'user', $user)){
			$tmp = checkDelete0('c', $id, 'formula');
			if($tmp ne $formula){
				print "WARNING: FORMULA FROM $link CHANGED SINCE DELETION\n";
			}
			
			%h_tmp = getDelFields1('c_nms', 'c', $id, 'nms');
			unless($h_tmp{$name}){
				print "WARNING: $link NEW NAME SINCE DELETION\n";
			}
			foreach $s_tmp (keys %anames){
				unless($h_tmp{$name}){
					print "WARNING: NAME FROM $link CHANGED SINCE DELETION\n";
				}
			}
		}
		else{
			if($INITIALIZE){
				$insert = 1;
			}
			else{
				if($name){
					$s_tmp = Rapido::General::sqlFormat($name);
					$sql = "nms='$s_tmp'";
					foreach $s_tmp (keys %anames){
						$s_tmp = Rapido::General::sqlFormat($name);
						$sql .= " OR nms='$s_tmp'";
					}
					%h_tmp = Rapido::General::sqlSelHash("SELECT c FROM c_nms WHERE $sql GROUP by c");
				}
				if($formula){
					$s_tmp = Rapido::General::sqlFormat($formula);
					%h_tmp = (%h_tmp, Rapido::General::sqlSelHash("SELECT id FROM c WHERE formula='$s_tmp' GROUP BY id"));
				}
				@candidates = ();
				foreach $s_tmp (keys %h_tmp){
					unless(Rapido::General::sqlVal1("SELECT id FROM c_lnk WHERE c=$s_tmp AND user=$user")){
						push (@candidates, $s_tmp);
					}
				}
				$b = 1;
				while($b){
					$b = 0;
					if(@candidates){
						%h_tmp = ( lc($name) => 1);
						foreach $s_tmp (keys %anames){
							$h_tmp{lc($s_tmp)} = 1;
						}
						foreach $s_tmp (@candidates){
							print "COMPOUND: $s_tmp";
							if($#candidates == 0){
								print " *****";
							}
							print "\n";
							@row = ();
							if(@row = Rapido::General::sqlSel1("SELECT nms FROM c_nms WHERE c=$s_tmp")){
								foreach $s_tmp1 (@row){
									print "NAME($s_tmp): $s_tmp1";
									if($h_tmp{lc($s_tmp1)}){
										print " *****";
									}
									print "\n";
								}
							}
						}
					}
					print "INPUT: $link - Please type target compound, new or skip (";
					if($#candidates == 0){
						print "t,";
					}
					print "#,n,s)\n";
					$id = <STDIN>;
					chop($id);
					if($id eq 'n'){
						print "REPORT: $link - new entry\n";
						$insert = 1;				
					}
					elsif($id eq 's'){
						print "REPORT: skipping $link\n";
					}
					elsif(($id =~ m/^\d+$/) || (($#candidates == 0) && ($id eq 't'))){
						if($id eq 't'){
							$id = $candidates[0];
						}
						unless(Rapido::General::sqlVal1("SELECT id FROM c_lnk WHERE c=$id AND user=$user")){
							@row = ();
							if(@row = Rapido::General::sqlRow1("SELECT 1, formula FROM c WHERE id=$id")){
								if($row[1] ne $formula){
									print "INPUT: replace formula '$row[1]' with '$formula' (y/n)\n";
									$s_tmp = <STDIN>;
									chop($s_tmp);
									if($s_tmp eq 'y'){
										Rapido::General::dbChangeRecord('c', $id, 'formula', $formula);
										print "REPORT - $link - formula updated\n";
									}
									else{
										print "REPORT - $link - formula not updated\n";
									}
								}
								unless(checkEverExist1('c_nms', 'c', $id, 'nms', $name)){
									%h_tmp = (	c => $id,
											nms => $name,
											main => 0);
									Rapido::General::dbInsertRecord('c_nms', 1, \%h_tmp);
								}
								foreach $s_tmp (keys %anames){
									unless(checkEverExist1('c_nms', 'c', $id, 'nms', $s_tmp)){
										%h_tmp = (	c => $id,
												nms => $s_tmp,
												main => 0);
											Rapido::General::dbInsertRecord('c_nms', 1, \%h_tmp);
									}
								}
								%h_tmp = (	c => $id,
										user => $user,
										lnk => $link);
								Rapido::General::dbInsertRecord('c_lnk', 1, \%h_tmp);
							}
							else{
								print "Wrong target code, compound $id does not exist, please retry\n";
								$b = 1;
							}
						}
						else{
							print "Wrong target code, compound $id already has link assigned\n";
							$b = 1;
						}
					}
					else{
						print "Wrong target code, please retry\n";
						$b = 1;
					}
				}
			}
		}
	}
	
	if($insert){
#		print "inserting $link\n";
		%h_tmp = (formula => $formula);
		$id = Rapido::General::dbInsertRecord('c', 1, \%h_tmp);
		%h_tmp = (	c => $id,
				lnk => $link,
				user => $user);
		Rapido::General::dbInsertRecord('c_lnk', 1, \%h_tmp);
		%h_tmp = (	c => $id,
				nms => $name,
				main => 1);
		Rapido::General::dbInsertRecord('c_nms', 1, \%h_tmp);
		foreach $tmp (keys %anames){
			%h_tmp = (	c => $id,
				nms => $tmp,
				main => 0);
			Rapido::General::dbInsertRecord('c_nms', 1, \%h_tmp);
		}
	}
}
		
$name = '';
$lastField = '';
open (FILE, $ARGV[0]);
while ($line = <FILE>){
	chop($line);
	if($lastField eq 'NAME'){
		if($line =~ s/^\s+\$//){
			$lastname .= $line;
		}
		else{
			if(length($lastname) > $MAX_NMS){
				die "FATAL ERROR: $link - MAX NMS\n";
			}
			
			if($name){
				$anames{$lastname} = 1;
			}
			else{
				$name = $lastname;
			}
			
			if($line =~ s/^\s+//){
				$lastname = $line;
			}
			else{
				$lastField = '';
			}
		}
	}
	if($line =~ m/^\/\/\//){
		if($formula){
			if($formula =~ m/\)n/){
				$skipped{$link} = 1;
			}
			else{
				if($formula =~ m/R/){
					$skipped{$link} = 1;
				}
				else{
					doStore();
				}
			}
		}
		else{
			$skipped{$link} = 1;
		}
		%anames = ();
		$name = '';
		$formula = '';
		$lastField = '';
	}
	elsif($line =~ s/^ENTRY\s+//){
		$link = $line;
		$link =~ s/\s.*$//;
		if(length($link) > $MAX_LINK){
			die "FATAL ERROR: $link - MAX LINK SIZE\n";
		}
	}
	elsif($line =~ s/^NAME\s+//){
		$lastField = 'NAME';
		$lastname = $line;
	}
	elsif($line =~ s/^FORMULA\s+//){
		$formula = $line;
		if($formula eq '"H+"'){#EXCEPTION
			$formula = 'H';
		}#END OF EXCEPTION
		elsif($formula =~ m/"/){#EXCEPTION TRAP
			die "FATAL ERROR: $link WITH INVALID FORMULA\n";
		}#END OF EXCEPTION TRAP
		if(length($formula) > $MAX_FORMULA){
			die "FATAL ERROR: $link - MAX FORMULA SIZE\n";
		}
	}
}
close(FILE);
foreach $s_tmp (keys %skipped){
	$s_tmp1 = '';
#	print "WARNING: $s_tmp Skipped\n";
	$s_tmp1 = Rapido::General::sqlVal1("SELECT c FROM c_lnk WHERE lnk='$s_tmp' AND user=$user");
	if($s_tmp1){
		print "ERROR: link exists on database - c: $s_tmp1\n";
	}
}
