# (C) Miguel Godinho de Almeida - miguel@gbf.de 2005
package Tobin::functions;

use strict;
use warnings;
use Tobin::family;

my $CONST	= Tobin::family::constantsGet();
				
sub constantsGet {
	return $CONST;
}

sub extLinkGet {#should get info from sql  one day... some day..
	my $user	= shift;
	my $code	= shift;
	my $link	= '';
	
	if ( $user == 901 ) { #KEGG
		if ( $code =~ m/^C/ ) {
			$link = "http://www.genome.jp/dbget-bin/www_bget?cpd:$code";
		}
		elsif ( $code =~ m/^R/ ) {
			$link = "http://www.genome.jp/dbget-bin/www_bget?rn+$code";
		}
		elsif ( $code =~ m/^\d+\./ ) {
			$link = "http://www.genome.jp/dbget-bin/www_bget?enzyme+$code";
		}
	}
	elsif ( $user == 902 ) { #EXPASY
		if ( $code =~ m/^\d+\.\d+\.\d+\.\d+$/ ) {
			$link = "http://www.expasy.org/cgi-bin/nicezyme.pl?$code";
		}
	}
	elsif ( $user == 903 ) { #SPROT
		$link = "http://ca.expasy.org/cgi-bin/niceprot.pl?$code";
	}
	elsif ( $user == 904 ) { #TREMBL
		$link = "http://ca.expasy.org/cgi-bin/niceprot.pl?$code";
	}
	elsif ( $user == 906 ) { #UNIPROT
		if ( $code =~ m/^\d+$/ ) {

		}
		elsif ( $code =~ m/^[A-Z]\w{4}$/ ) {
			#UNIPROT ORGANISM CODE... DUNNO WHAT TO DO
		}
		else {
			$link = "http://ca.expasy.org/cgi-bin/niceprot.pl?$code";
		}
	}
	elsif ( $user == 907 ) { #TAXID
		if ( $code =~ m/^\d+$/ ) {
			$link = "http://www.ncbi.nlm.nih.gov/Taxonomy/Browser/wwwtax.cgi?lvl=0&id=$code";
		}
	}
	elsif ( $user == 908 ) { #EMBL

	}
	elsif ( $user == 909 ) { #GBK
		if ( $code =~ m/^\d+$/ ) {
			$link = "http://www.ncbi.nlm.nih.gov/entrez/query.fcgi?db=gene&cmd=Retrieve&dopt=Graphics&list_uids=$code";
		}
		elsif ( $code =~ m/^(NC_\d+).*$/ ) {
			$link =	"http://www.ncbi.nlm.nih.gov/entrez/viewer.fcgi?val=$1"; 
		}
	}
	return $link;
}

sub childUpdate {#returns bool
	my $dba			= shift;
	my $child		= shift;
	my $newData		= shift;
	my $errors		= shift;
	my $warnings	= shift;
	
	if( ( $child->{CODE} eq $CONST->{MY_FBASET_TRANSF} ) ) {
		if( $child->update( $newData, 0, $errors, $warnings ) ) {
			updateFbaTransformationSet( $dba, $child, $newData, $errors, $warnings );
		}
	}
	elsif( $child->{PARENT} eq $CONST->{SIMUL_PARENT} ) {
		suicide( "simulations should be directly accessed" );	
	}

	$child->update( $newData, 0, $errors, $warnings );
	@{$errors} ? ( return 0 ) : ( return 1 );
}

sub entityCheck {
	my $dba		= shift;
	my $parent	= shift;
	my $user	= shift;
	my $errors	= shift;
	suicide( "NI" );
}

sub entryDelete {
	my $dba			= shift;
	my $obj			= shift;
	my $errors		= shift;
	my $warnings	= shift;
	my $locks		= {};
	my $child;
	my $result;
	
	foreach( keys( %{$obj->{NEPHEWS}} ) ) { $locks->{$_} = 'READ' };	
	foreach $child ( values( %{$obj->{CHILDREN}} ) ) {
		foreach( @{$child->{UNCLES}} ) { $_ && ( $locks->{$_} = 'READ' ) };
	}
	
	$locks->{$obj->{CODE}} = 'WRITE';
	if( $obj->{LOG} ) {
		$locks->{history}	= 'WRITE';
		$locks->{history_x}	= 'WRITE';
	}
	
	foreach $child ( values( %{$obj->{CHILDREN}} ) ) {
		$locks->{$child->{CODE}} = 'WRITE';	
	}
	
	
	$dba->lockTables( $locks );
	$result = $obj->delete( $errors, $warnings  );
	$dba->unlockTables();
	return $result;
}

sub entryRecycle {
	my $dba		= shift;
	my $obj		= shift;
	my $locks	= { $obj->{CODE} => 'READ' };
	my $child;

	if( $obj->{LOG} ) {
		$locks->{history}	= 'READ';
		$locks->{history_x}	= 'READ';
	}
	
	foreach $child ( values( %{$obj->{CHILDREN}} ) ) {
		$locks->{$child->{CODE}} = 'READ';
		foreach( @{$child->{UNCLES}} ) {
			$_ && ( $locks->{$_} = 'READ' );
		}
	}
	
		
	$dba->lockTables( $locks );
	$obj->recycle();	
	$dba->unlockTables( $locks );
}

sub entrySave {
	my $dba			= shift;
	my $obj			= shift;
	my $errors		= shift;
	my $warnings	= shift;
	my $locks		= {};
	my $child;
	my $result;
	
	foreach( keys( %{$obj->{NEPHEWS}} ) ) { $locks->{$_} = 'READ' };	
	foreach $child ( values( %{$obj->{CHILDREN}} ) ) {
		foreach( @{$child->{UNCLES}} ) { $_ && ( $locks->{$_} = 'READ' ) };
	}
	
	$locks->{$obj->{CODE}} = 'WRITE';
	
	if( $obj->{LOG} ) {
		$locks->{history}	= 'WRITE';
		$locks->{history_x}	= 'WRITE';
	}
	
	foreach $child ( values( %{$obj->{CHILDREN}} ) ) { $locks->{$child->{CODE}} = 'WRITE' };
	
	$dba->lockTables( $locks );
	$result = $obj->save( $errors, $warnings  );
	$dba->unlockTables();
	return $result;
}

sub updateFbaTransformationSet {
	my $dba					= shift;
	my $child				= shift;
	my $newData				= shift;
	my $errors				= shift;
	my $warnings			= shift;
	my $transf2Chk			= {};
	my $sources				= {};
	my $sinks				= {};
	my $lb					= {};
	my $ub					= {};
	my $stoich				= [];
	my $objectiveTransf		= 0;
	my $objectiveCompound	= 0;
	my $objectiveLocal		= 0;
	my $objSource;
	my $objSink;
	my $transf;
	my $compoundName;
	
	( caller() eq 'Tobin::functions' )		|| suicide( 'private function' );
	( $child->{MAIN} == 1 )					|| suicide( "x1 should be main..." );
	
	foreach $transf ( @{$child->{data}} ) {
		$transf2Chk->{$transf->[0]} && suicide();
		if( $transf->[1] ) {
			$objectiveTransf ? ( suicide() ) : ( $objectiveTransf = $transf->[0] );
		}
		else {
			$transf2Chk->{$transf->[0]} = 1;
		}
		
		if( $transf->[2] ) {
			( $transf->[2] < 0 ) ? ( push( @{$errors}, $CONST->{FBA_OUT_BOUNDS} ) ) : ( $lb->{$transf->[0]} = $transf->[2] );
			length( $transf->[3] ) && ( $transf->[3] < $transf->[2] ) && push( @{$errors}, [ $CONST->{FBA_INV_BOUNDS}, $CONST->{MY_TRANSF}, $transf->[0] ] );
		}
		
		( length( $transf->[3] ) ) && ( ( $transf->[3] < 0 ) ? ( push( @{$errors}, $CONST->{FBA_OUT_BOUNDS} ) ) : ( $ub->{$transf->[0]} = $transf->[3] ) );
	}
	

	@{$stoich} = $dba->getMatrix( "SELECT x0, x1, x2 FROM $CONST->{MY_TRANSF_COMP} WHERE p=$objectiveTransf" );
	if( scalar( @{$stoich} ) == 1 ) { 
		$objectiveCompound	= $stoich->[0]->[0];	
		$objectiveLocal		= $stoich->[0]->[1];
		if( $stoich->[0]->[2] > 0 ) {
			$sources->{$objectiveCompound}->{$objectiveLocal} = $objectiveTransf;
		}
		else {
			$sinks->{$objectiveCompound}->{$objectiveLocal} = $objectiveTransf;
		}
	}
	else {
		push( @{$errors}, $CONST->{FBA_ERROR_NO_SRC_SNK} );
	}
	
	foreach $transf ( keys( %{$transf2Chk} ) ) {
		@{$stoich} = $dba->getMatrix( "SELECT x0, x1, x2 FROM $CONST->{MY_TRANSF_COMP} WHERE p=$transf" );
		if( scalar( @{$stoich} ) == 1 ) {
			if( $stoich->[0]->[2] > 0 ) {
				if( $sources->{$stoich->[0]->[0]}->{$stoich->[0]->[1]} ) {
					( $compoundName = $dba->getValue( "SELECT x0 FROM $CONST->{MY_COMP_NAMES} WHERE p=$stoich->[0]->[0] AND x1=1" ) ) || ( $compoundName = $CONST->{MY_UNKOWN} );
					push( @{$errors}, "$CONST->{MY_MULTIPLE_SRC} $compoundName" );
					warn "FBA: Multiple Sources: $transf";
					warn "FBA: Multiple Sources: $sources->{$stoich->[0]->[0]}->{$stoich->[0]->[1]}";
				}
				else {
					$sources->{$stoich->[0]->[0]}->{$stoich->[0]->[1]} = $transf;	
				}
			}
			else {
				if( $sinks->{$stoich->[0]->[0]}->{$stoich->[0]->[1]} ) {
					( $compoundName = $dba->getValue( "SELECT x0 FROM $CONST->{MY_COMP_NAMES} WHERE p=$stoich->[0]->[0] AND x1=1" ) ) || ( $compoundName = $CONST->{MY_UNKOWN} );
					push( @{$errors}, "$CONST->{MY_MULTIPLE_SINK} $compoundName" );
					warn "FBA: Multiple Sinks: $transf";
					warn "FBA: Multiple Sinks: $sinks->{$stoich->[0]->[0]}->{$stoich->[0]->[1]}";
				}
				else {
					$sinks->{$stoich->[0]->[0]}->{$stoich->[0]->[1]} = $transf; 
				}
			}
		}
	}
	
	if( ( $objSource = $sources->{$objectiveCompound}->{$objectiveLocal} ) && ( $objSink = $sinks->{$objectiveCompound}->{$objectiveLocal} ) ) {
		(	$lb->{$objSource}				|| 
			$lb->{$objSink}					||
			defined( $ub->{$objSource} )	||
			defined( $ub->{$objSink} ) )	&& push( @{$errors}, $CONST->{FBA_ERROR_OBJ_BOUNDS} ) ;
	}
	else {
		push( @{$errors}, $CONST->{FBA_ERROR_SRC_AND_SNK} );	
	}	
}

sub suicide {
	my $msg	= shift;
	defined( $msg ) || ( $msg = '' );
	die( $msg );	
}
1;
