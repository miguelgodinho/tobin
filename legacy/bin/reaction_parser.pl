#!/usr/bin/perl
use strict;
use warnings;
use Exporter;
use lib "./MIG";
use Rapido::DBAccessor;


my $dba;
my $compal;
my $user = 901;
my $INITIALIZE = 1;
my $MAX_NMS = 253;
my $MAX_LINK = 6;
my %COMPOUNDS;
my %ENZYMESC;
my $NAME = '';
my %ANAMES = ();
my $DEFINITION = '';
my $LINK;
my $EQUATION = '';
my %storedCompounds = ();
my %storedEnzymes = ();
my %SKIPPED;
my %alienEntries = ();
my %noiCompounds = ();
my %checkedLinks = ();

sub doStore{
	my $insert = 0;
	my $id = 0;
	my %hash;
	my $tmp;
	my $key;
	my $value;
	my $skip;

	$id = $compal->getPriByLink('r', $LINK);

	if($id < 0){
		$tmp = $compal->getDelValue4PriField('r', $id, 'def');
		if($tmp ne $DEFINITION){
			print "WARNING: $LINK - NEW DEFINITION SINCE DELETION\n";
		}
		else{
			%hash = $compal->getDelValues4SecField('r', $id, 'nms');
			unless($hash{$NAME}){
				print "WARNING: $LINK - NEW NAME SINCE DELETION\n";
			}
			foreach (keys %ANAMES){
				unless($hash{$_}){
					print "WARNING: $LINK - NEW NAME SINCE DELETION\n";
				}
			}
		}
	}
	elsif($id == 0){
		if($INITIALIZE){
			$insert = 1;
		}
		else{
			print "No reaction found for $LINK\nPossible candidates:";
			my @candidates = ();
			while(($key, $value) = each %alienEntries){
				if($value){
					$skip = 0;
					#Filtering starts
					%hash = $dba->getHash("SELECT c, 1 FROM r_c WHERE r='$key'");
					foreach $tmp (keys %hash){
						unless($noiCompounds{$tmp}){
							unless($COMPOUNDS{$tmp}){
								$skip = 1;
							}
						}
					}
					foreach $tmp (keys %COMPOUNDS){
						unless($noiCompounds{$tmp}){
							unless($hash{$tmp}){
								$skip = 1;
							}
						}
					}
					#Filtering ends
				}
				unless($skip){
					push(@candidates, $key);
				}
			}
			foreach (@candidates){
				print " $_";
			}
			$id = -1;
			while(($insert != 1) && ($id == -1)){
				print "\nPlease enter target reaction #, n for new or 0 (zero) to skip\n(#,n,0):";
				$tmp = <STDIN>;
				chop($tmp);
				if($tmp eq 'n'){
					$insert = 1;
				}
				elsif($tmp == '0'){
					$id = 0;
				}
				elsif($tmp =~ m/^\d+$/){
					if($alienEntries{$tmp}){
						$id = $tmp;
						$alienEntries{$id} = 0;
						%hash = (	'r' => $id,
								'user' => $user,
								'lnk' => $LINK);
						$compal->insertRecord('r_lnk', 1, \%hash);
					}
					else{
						print "ERROR: Reaction $tmp cannot be used";
					}
				}
			}
		}

		if($insert){
			%hash = (	def => $DEFINITION);
			$id = $compal->insertRecord('r', 1, \%hash);
			%hash = (	'r' => $id,
					'user' => $user,
					'lnk' => $LINK);
			$compal->insertRecord('r_lnk', 1, \%hash);
		}
	}
	
	if($id > 0){
		$ANAMES{$NAME} = 1;
		$checkedLinks{lc($LINK)} = 1;
		$compal->updatePriField('r', $id, 'def', $DEFINITION, 0);
		$compal->updateSerie('r', $id, 'nms', \%ANAMES, 0);
		$compal->updateSecMap('r', $id, 'c', 'i', \%COMPOUNDS, 0);
		$compal->updateComplexesAutoRev('r', $id, 'p', \%ENZYMESC, 0);
	}
	else{
		$SKIPPED{$LINK} = -1; #skip -1 = user skipped
	}
}

$dba = new Rapido::DBAccessor;
$dba->initialize('localhost', 'compal', 'root', '');
$compal = new Rapido::CompalAccessor;
$compal->initialize($user, $dba);


my $lastField = '';
my $line;
my $lastname = '';
my $lastcomment = '';
my $skip = 0;
my @row;
my @row1;
my @class;
my $lhs;
my $rhs;
my $key;
my $value;
my $tmp;
my %enzymes;
my %hash;
my $i;
my $j;
my $complex;
my $s_tmp;

%storedCompounds = $dba->getHash("SELECT LOWER(lnk), c FROM c_lnk WHERE user=$user");

$s_tmp = 0;
if($s_tmp = $dba->get1Value("SELECT id FROM c WHERE formula='H'")){
	$noiCompounds{$s_tmp} = 1;
}
else{
	die "FATAL ERROR: Compound H not found\n";
}

%alienEntries = $compal->getAliens('r');

open (FILE, $ARGV[0]);
while ($line = <FILE>){
	chop($line);
	if($lastField eq 'ENZYME'){
		if($line =~ s/^\s+//){
			foreach (split(/\s+/, $line)){
				$enzymes{$_} = 1;
			}
		}
		else{
			$lastField = '';
		}
	}
	elsif($lastField eq 'EQUATION'){
		if($line =~ s/^\s+//){
			$EQUATION .= $line;
		}
		else{
			$lastField = '';
		}
	}
	elsif($lastField eq 'NAME'){
		if($line =~ s/^\s+\$//){
			$lastname .= $line;
		}
		else{
			if(length($lastname) > $MAX_NMS){
				die "FATAL ERROR: $LINK - MAX NMS\n";
			}
			
			if($NAME){
				$ANAMES{$lastname} = 1;
			}
			else{
				$NAME = $lastname;
			}
			
			if($line =~ s/^\s+//){
				$lastname = $line;
			}
			else{
				$lastField = '';
			}
		}
	}
	elsif($lastField eq 'DEFINITION'){
		if($line =~ s/^\s+//){
			$DEFINITION .= $line;
		}
		else{
			$lastField = '';
		}
	}
	elsif($lastField eq 'COMMENT'){
		if($line =~ s/^\s+//){
			$lastcomment .= $line;
		}
		else{
			$lastField = '';
		}
	}
	
	if($line =~ m/^\/\/\//){
		unless($NAME){
			$NAME = substr($DEFINITION, 0, $MAX_NMS);
		}

		if($lastcomment =~ m/incomplete reaction$/){
			if($LINK eq 'R01530'){
				
				print "$lastcomment - here\n";
			}
			$skip = 1;
		}
		
		if($EQUATION){
			@row = split(/ <=> /, $EQUATION);
			$lhs = $row[0];
			$rhs = $row[1];
			@row = split(/\+/, $lhs);
			foreach $tmp (@row){
				$tmp =~ s/^\s*//;
				$tmp =~ s/\s*$//;
				$key = $tmp;
				$key =~ s/^\d+\s+//;
				$value = $tmp;
				$value =~ s/\s*C.*$//;
				unless($value){
					$value = 1;
				}
				$tmp = 0;
				if($tmp = $storedCompounds{lc($key)}){
					if($COMPOUNDS{$tmp}){
						$skip = 3; #skip 3 = compound on both lhs and rhs
					}
					else{
						$COMPOUNDS{$tmp} = -$value;
					}
				}
				else{
					$skip = 1;
				}
			}
			@row = split(/\+/, $rhs);
			foreach $tmp (@row){
				$tmp =~ s/^\s*//;
				$tmp =~ s/\s*$//;
				$key = $tmp;
				$key =~ s/^.*\s+//;
				$value = $tmp;
				$value =~ s/\s*C.*$//;
				unless($value){
					$value = 1;
				}
				$tmp = 0;
				if($tmp = $storedCompounds{lc($key)}){
					if($COMPOUNDS{$tmp}){
						$skip = 3; #skip 3 = compound on both lhs and rhs
					}
					else{
						$COMPOUNDS{$tmp} = $value;
					}
				}
				else{
					if($LINK eq 'R01849'){
						print "Compound $key is not found\n";
					}
					$skip = 2; #skip 2 = at least one compound is not found
				}
			}
		}
		else{
			$skip = 1;
		}

		unless(%COMPOUNDS){
			$skip = 1;
		}
	

		if(%enzymes){
			%hash = ();
			foreach $tmp (keys %enzymes){
				@row = split(/\./, $tmp);
				$key = "$row[0].$row[1]";
				$value = '';
				if($value = $dba->get1Value("SELECT p FROM p_lnk WHERE lnk='$tmp' GROUP BY p")){#stored enzyme is not being used, someday it may give trouble...
					unless ($key && $value){
						
						print "$LINK - key: $key -- value:$value\n";
						die "here\n";
					}
					if($hash{$key}){
						@row = @{$hash{$key}};
						push(@row, $value);
						$hash{$key} = [@row];
					}
					else{
						$hash{$key} = [$value];
					}
				}
				else{
					$skip = 4; #skip 4 = unknown enzyme
				}
			}
			@class = ();
			if(@class = (values %hash)){
				@row = ();
				$complex = 1;
				foreach $s_tmp (@class){
					push(@row, 0);
				}
				while($complex){
					@row1 = ();
					for ($i = 0; $i <= $#row; $i++){
						$j = $row[$i];
						push(@row1, ($class[$i][$j]));
					}
					if(@row1){
						$ENZYMESC{$complex} = [@row1];
						$complex++;
					}
					$i--;
					$j++;
					$row[$i] = $j;
					while($row[$i] > $#{$class[$i]}){
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
		}
		
		if($skip){
			if($LINK eq 'R01849' || $LINK eq 'R01530'){
				print "$LINK skipped $skip\n";
			}
			$SKIPPED{$LINK} = $skip;
		}
		else{
			doStore();
		}
		
		%ANAMES = ();
		$NAME = '';
		$DEFINITION = '';
		$EQUATION = '';
		%COMPOUNDS = ();
		%ENZYMESC = ();
		$lastField = '';
		$skip = 0;
		%enzymes = ();
		$lastcomment = '';
	}
	elsif($line =~ s/^ENTRY\s+//){
		$LINK = $line;
		$LINK =~ s/\s.*$//;
		if(length($LINK) > $MAX_LINK){
			die "FATAL ERROR: $LINK - MAX LINK SIZE\n";
		}
	}
	elsif($line =~ s/^NAME\s+//){
		$lastField = 'NAME';
		$lastname = $line;
	}
	elsif($line =~ s/^DEFINITION\s+//){
		$lastField = 'DEFINITION';
		$DEFINITION = $line;
	}
	elsif($line =~ s/^EQUATION\s+//){
		$lastField = 'EQUATION';
		$EQUATION = $line;
	}
	elsif($line =~ s/^COMMENT\s+//){
		$lastField = 'COMMENT';
		$lastcomment = $line;
	}
	elsif($line =~ s/ENZYME\s+//){
		$lastField = 'ENZYME';
		foreach (split(/\s+/, $line)){
			$enzymes{$_} = 1;
		}
	}
}
close(FILE);

%hash = $dba->getHash("SELECT r, LOWER(lnk) FROM r_lnk WHERE user='$user'");
while(($key, $value) = each %hash){
	unless($checkedLinks{$value}){
		@row = ();
		if(@row = $dba->get1stColumn("SELECT lnk FROM r_lnk WHERE r=$key AND user != $user")){
			$value = $dba->format($value);
			$dba->get1Value("SELECT id FROM r_lnk WHERE r=$key AND lnk='$value'");
			$compal->del('r_lnk', $_);
		}
		else{
			$compal->del('r', $key);
		}
	}
}

