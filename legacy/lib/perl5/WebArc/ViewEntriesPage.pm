# (C) Miguel Godinho de Almeida - miguel@datindex.com 2005
package WebArc::ViewEntriesPage;

use strict;
use warnings;

use WebArc::RowPageSelector;

sub new {
	my $param	= shift;
	my $self	= shift;
	my $class	= ref( $param ) || $param;
	bless( $self, $class );
	
	$self->{CODE}			|| $self->{HLP}->suicide();
	$self->{ENTITY}			|| $self->{HLP}->suicide();
	$self->{data}			|| $self->{HLP}->suicide();
	$self->{lists}			|| $self->{HLP}->suicide();
	
	$self->{MEM}			= $self->{BRO}->{MEM};
	$self->{DBA}			= $self->{MEM}->{DBA};
	$self->{LOG}			= $self->{MEM}->{LOG};
	$self->{HLP}			= $self->{BRO}->{HLP};
	$self->{CONST}			= $self->{BRO}->{CONST};
	$self->{RECORDS_PP}		= $self->{CONST}->{SEARCH_LIMIT};
	$self->{entriesNfounds}	= {};
	
	if( $self->{data}->{INIT} ) {
		( $self->{data}->{CODE}	eq $self->{CODE} ) || $self->{HLP}->suicide();
	}
	else {
		$self->{data}->{INIT}		= 1;
		$self->{data}->{CODE}		= $self->{CODE};
		$self->{data}->{valuesIdx}	= [];
		$self->{data}->{listed}		= {};
	}
	
	$self->{PAGE_SEL} = new WebArc::RowPageSelector( {
									BRO			=> $self->{BRO},
									CODE		=> "$self->{CODE}&PAGE_SEL",
									COLUMNS		=> 2,
									BGCOLOR		=> $self->{CONST}->{COLOR_BLUE} } );
		
	return $self;
}

sub printPageHeader {
	my $self		= shift;
	my $scr			= shift;
	my $page		= shift;
	my $code		= $self->{CODE};
	my $data		= $self->{data};
	my $shown		= keys( %{$data->{listed}} );
	my $total		= keys( %{$self->{entriesNfounds}} );
	my $totalSel	= keys( %{$self->{lists}->{entries}} );
	my $toolbox		= [];
	
	$scr->openCell( "bgcolor=#$self->{CONST}->{COLOR_BLUE} colspan=2" );
	
	if( $shown == $total ) {
		$scr->doTxt( "$shown $self->{ENTITY}->{NAME}(s) - $totalSel Selected" );
	}
	else { 
		$scr->doTxt( "$shown $self->{ENTITY}->{NAME}(s) [$page->{first}..$page->{last}] of $total - $page->{selected}/$totalSel Selected" );
	}
	
	if( $total ) {
		if( ( $page->{first} > 1 ) || ( $page->{last} != $total ) ) {
			 @{$toolbox} = ( '', 'gear', '', 'boxa', 'greencheckbox', '', 'boxb', 'greenbox4' );
		}
		else {
			 @{$toolbox} = ( '', 'gear', '', 'boxb', 'greenbox4', '', '', '' );
		}
	
		if( $page->{first} > 1 ) {
			( $page->{last} == $total ) ? ( push( @{$toolbox}, ( '', 'left', '', '' ) ) ) : ( push( @{$toolbox}, ( '', 'left', '', 'right' ) ) );
		}
		else {
			( $page->{last} != $total ) && ( push( @{$toolbox}, ( '', '', '', 'right' ) ) );
		}
	
		@{$toolbox} && $scr->doToolBox( $code, 16, $toolbox );
	}
}

sub printRecords {
	my $self		= shift;
	my $scr			= shift;
	my $records		= shift;
	my $mem			= $self->{MEM};
	my $entityCode	= $self->{ENTITY}->{CODE};
	my $lists		= $self->{lists};
	my $lstEntries	= $self->{lists}->{entries};
	my $lstFounds	= $self->{lists}->{founds};
	my $id;
	my $link;
	my $txt;
	
	( caller() eq 'WebArc::ViewEntriesPage' )	|| $self->{HLP}->suicide();
	
	foreach $id ( @{$records} ) {
		$scr->openRow();
		$scr->openCell();
		$scr->doCheckBox( "$self->{CODE}&VALUE&".$id, 1, $lstEntries->{$id} );
		$txt = $mem->entryDefsGet( $entityCode, $id, [ 'MAIN' ] );
		( $link = $self->{MEM}->getLink( $entityCode, $id ) ) || $self->{HLP}->suicide();
		$scr->doLink( $link, $txt );
		$lstFounds && $scr->doImg( 'images/icons2/target-16.gif' );
	}
}

sub printView {
	my $self			= shift;
	my $scr				= shift;
	my $page;
	my $totalRecords;
	
	$self->sortData();
	
	$page			= $self->processPage();
	$totalRecords	= keys( %{$self->{entriesNfounds}} );
		
	$scr->openTable( 2, "bordercolor=#$self->{CONST}->{COLOR_BLUE} border frame=box rules=none width=100%" );
	$self->printPageHeader( $scr, $page );
	$self->printRecords( $scr, $page->{records} );
	$self->{PAGE_SEL}->printRow( $scr, $page->{currentPN}, $page->{totalPN} );
	$scr->closeTable();	
}	
	
sub processForm {
	my $self			= shift;
	my $form			= shift;
	my $submitKey		= shift;
	my $data			= $self->{data};
	my $lists			= $self->{lists};
	my $pageNumber		= $data->{page};
	my $pgdEntries		= $data->{listed};
	my $chkEntries		= $lists->{entries};
	my $entriesNfounds	= $self->{entriesNfounds};
	my $operation		= '';
	my $tgt;
	
	$lists->{closed} ? $self->{HLP}->suicide() : ( $lists->{closed} = 1 );
	
	%{$entriesNfounds} = %{$lists->{entries}};
	foreach( keys( %{$lists->{founds}} ) ) { $entriesNfounds->{$_} = 1 };
	
	foreach( values( %{$pgdEntries} ) ) { $form->{VALUE}->{$_} || delete( $chkEntries->{$_} ) };
	
	foreach( keys( %{$form->{VALUE}} ) ) { $chkEntries->{$_} = 1 };
	
	if( $submitKey ) {
		$operation = shift( @{$submitKey} );
		
		if( $operation eq 'right' ) {
			$lists->{page}++;
		}
		elsif( $operation eq 'left' ) {
			$lists->{page}--;
		}
		elsif( $operation eq 'PAGE_SEL' ) {
			$tgt = $self->{PAGE_SEL}->processForm( $submitKey );
			if( $tgt eq '+1' ) {
				$lists->{page}++;	
			}
			elsif( $tgt eq '-1' ) {
				$lists->{page}--;	
			}
			else {
				$lists->{page} = $tgt;	
			}
		}
		elsif( $operation eq 'greenbox4' ) {
			foreach( keys( %{$entriesNfounds} ) ) { $chkEntries->{$_} = 1 };
		}
		elsif( $operation eq 'greencheckbox' ) {
			foreach( keys( %{$pgdEntries} ) ) { $chkEntries->{$_} = 1 };
		}
		elsif( $operation eq 'boxa' ) {
			foreach( keys( %{$pgdEntries} ) ) { delete( $chkEntries->{$_} ) };
		}
		elsif( $operation eq 'boxb' ) {
			%{$chkEntries} = ();
		}
		elsif( $operation ne 'gear' ) {
			$self->{HLP}->suicide( $operation );
		}
	}
		
	return '';
}

sub processPage {
	my $self			= shift;
	my $data			= $self->{data};
	my $lists			= $self->{lists};
	my $lstFounds		= $lists->{founds};
	my $lstEntries		= $lists->{entries};
	my $recordsTop		= [];
	my $records			= [];
	my $pageSelected	= 0;
	my $totalRecords	= keys( %{$self->{entriesNfounds}} );
	my $fltTotalP		= ( $totalRecords / ( $self->{RECORDS_PP} ) );
	my $intTotalP		= int( $fltTotalP );
	my $page			= { records => [] };
	my $pos;
	my $i;
	my $j;
	my $l;
	my $id;
	
	
	( keys( %{$self->{entriesNfounds}} ) != scalar( @{$data->{valuesIdx}} ) ) && $self->{HLP}->suicide( "Fatal error sorting entities" );
	
	( $intTotalP == $fltTotalP ) || ( $intTotalP++ );
	
	foreach( @{$data->{valuesIdx}} ) {
		$lstFounds->{$_} ? ( push( @{$recordsTop}, $_ ) ) : ( push( @{$records}, $_ ) );
	}
	@{$records} = ( @{$recordsTop}, @{$records} );
	
	if( $j = scalar( @{$records} ) ) {
		if( ( $lists->{page} < 0 ) || ( $j <= ( $i = ( $self->{RECORDS_PP} * $lists->{page} ) ) ) ) {
			$i				= 0;
			$lists->{page}	= 0;
		}
	 	( ( $i + $self->{RECORDS_PP} ) < $j ) ? ( $l = $i + $self->{RECORDS_PP} ) : ( $l = $j );
	}
	else {
		$i = 0;
		$l = 0;
	}
	
	%{$data->{listed}} = ();
	for( $pos = $i; $pos < $l; $pos++ ) {
		$id = $records->[$pos];
		push( @{$page->{records}}, $id );
		$lstEntries->{$id} && $pageSelected++;
		$data->{listed}->{$id} = 1;
	}
	
	$page->{first}		= ( $i + 1 );
	$page->{last}		= $l;
	$page->{selected}	= $pageSelected;
	$page->{currentPN}	= $lists->{page};
	$page->{totalPN}	= $intTotalP;
	
	return $page;
}

sub sortData {
	my $self			= shift;
	my $data			= $self->{data};
	my $entriesNfounds	= $self->{entriesNfounds};
	my $dataOK			= 1;
	my $id;
	
	( caller() eq 'WebArc::ViewEntriesPage' ) || $self->{HLP}->suicide();
	
	%{$entriesNfounds} = %{$self->{lists}->{entries}};
	foreach( keys( %{$self->{lists}->{founds}} ) ) {
		$entriesNfounds->{$_} = 1;	
	}
	
	$self->{MEM}->cachedOrSorted( $entriesNfounds, [ $self->{ENTITY}->{CODE} ], [ 0 ], $data->{valuesIdx} );
}
1;
