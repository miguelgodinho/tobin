# (C) Miguel Godinho de Almeida - miguel@datindex.com 2005
package WebArc::ViewPage;

use strict;
use warnings;

use WebArc::ViewSetsMng;
use WebArc::RowPageSelector;

sub new {
	my $param	= shift;
	my $self	= shift;
	my $class	= ref( $param ) || $param;
	bless( $self, $class );
	
	$self->{data}					|| $self->{HLP}->suicide();
	$self->{CODE}					|| $self->{HLP}->suicide();
	$self->{CHILD}					|| $self->{HLP}->suicide();
	$self->{CHILD}->{FLAGS}->{PAGE}	|| $self->{HLP}->suicide();
	$self->{MEM}					= $self->{BRO}->{MEM};
	$self->{DBA}					= $self->{MEM}->{DBA};
	$self->{LOG}					= $self->{MEM}->{LOG};
	$self->{HLP}					= $self->{BRO}->{HLP};
	$self->{CONST}					= $self->{BRO}->{CONST};
	$self->{RECORDS_PP}				= $self->{CONST}->{SEARCH_LIMIT};
	$self->{entriesNfounds}			= {};
	
	$self->{CHILD}->{FLAGS}->{MAP} ? ( $self->{COLUMNS} = scalar( @{$self->{CHILD}->{DISPLAY}} + 1 ) ) : ( $self->{COLUMNS} = scalar( @{$self->{CHILD}->{DISPLAY}} ) );
	
	my $data	= $self->{data};
	my $pos		= 0;

	if( $data->{INIT} ) {
		( $data->{CODE}			eq $self->{CODE} )			|| $self->{HLP}->suicide();
		( $data->{CHILDCODE}	eq $self->{CHILD}->{CODE} )	|| $self->{HLP}->suicide();
		( $data->{ID}			eq $self->{CHILD}->{ID} )	|| $self->{HLP}->suicide();
	}
	else {
		$data->{INIT}			= 1;
		$data->{CODE}			= $self->{CODE};
		$data->{CHILDCODE}		= $self->{CHILD}->{CODE};
		$data->{ID}				= $self->{CHILD}->{ID};
		$data->{valuesIdx}		= [];
		$data->{listed}			= {};
		$data->{search}			= '';
		$self->{data}->{lists}	= {	entries		=> {},
									founds		=> {},
									closed		=> 0,
									page		=> 0 };
									
		
		( "@{$self->{CHILD}->{IDS}}" eq '0' )	|| $self->{HLP}->suicide();
	}
	
	foreach( @{$self->{CHILD}->{DISPLAY}} ) {
		if( m/^(\d+)=(\d+)$/ ) {
			( $1 >= $pos ) ? ( $pos = $1 ) : $self->{HLP}->suicide( "$self->{CODE} has invalid DISPLAY format" );
			$2 && ( $self->{LENGTHS}->{$1} = $2 );#if length=0 then it is assumed that field is Not Searchable or RO
		}
		elsif( !m/^\d+$/ ) {
			$self->{HLP}->suicide( "$self->{CHILD}->{CODE} has invalid DISPLAY format: $_" );
		}
	}
	
	
	$self->{PAGE_SEL} = new WebArc::RowPageSelector( {
								BRO			=> $self->{BRO},
								CODE		=> "$self->{CODE}&PAGE_SEL",
								COLUMNS		=> $self->{COLUMNS},
								BGCOLOR		=> $self->{CONST}->{COLOR_BLUE} } );
	
	if(	!$self->{CHILD}->{FLAGS}->{RO} &&
		( $self->{UNCLE} = $self->{CHILD}->{UNCLES}->[0] ) &&
		( $self->{UNCLE} ne $self->{CHILD}->{PARENT} ) &&
		( $self->{setsParent} = $self->{MEM}->entityAttribGet( $self->{UNCLE}, 'S' ) ) ) {
			
		defined( $self->{data}->{VIEW_SETS} ) || ( $self->{data}->{VIEW_SETS} = {} );
		$self->{VIEW_SETS} = new WebArc::ViewSetsMng( {
									expanded	=> 0,
									data		=> $self->{data}->{VIEW_SETS},
									SAVE		=> 0,
									CODE		=> "$self->{CODE}&VIEW_SETS",
									MEM			=> $self->{MEM},
									BRO			=> $self->{BRO},
									lists		=> $self->{data}->{lists},
									ENTITY		=> $self->{CONST}->{PARENTS}->{$self->{setsParent}} } );
	}
	
	return $self;
}

sub refreshData {
	my $self			= shift;
	my $child			= $self->{CHILD};
	my $data			= $self->{data};
	my $lists			= $data->{lists};
	my $entries			= $lists->{entries};
	my $founds			= $lists->{founds};
	my $entriesNfounds	= $self->{entriesNfounds};
	my $id;
	my $entry;
	
	%{$entries}			= ();
	%{$entriesNfounds}	= ();
	
	foreach $entry ( @{$child->{data}} ) {
		$id						= $entry->[0];
		$entries->{$id}			= 1;
		$entriesNfounds->{$id}	= [ @{$entry} ];
	}
	
	@{$entry} = @{$child->{DEFAULTS}};
	foreach $id ( keys( %{$founds} ) ) {
		unless( $entries->{$id} ) {
			$entry->[0]				= $id;
			$founds->{$id}			= 1;
			$entriesNfounds->{$id}	= [ @{$entry} ];
		}
	}
	
	$self->{MEM}->cachedOrSorted( $self->{entriesNfounds}, $self->{CHILD}->{UNCLES}, [ 0 ], $self->{data}->{valuesIdx} );	
}

sub processPage {
	my $self			= shift;
	my $data			= $self->{data};
	my $lists			= $data->{lists};
	my $lstEntries		= $lists->{entries};
	my $lstFounds		= $lists->{founds};
	my $entriesNfounds	= $self->{entriesNfounds};
	my $recordsTop		= [];
	my $records			= [];
	my $totalRecords	= keys( %{$self->{entriesNfounds}} );
	my $fltTotalP		= ( $totalRecords / ( $self->{RECORDS_PP} ) );
	my $intTotalP		= int( $fltTotalP );
	my $page			= { records => [] };
	my $pageSelected	= 0;
	my $i;
	my $j;
	my $l;
	my $pos;
	my $id;
	my $entry;
	
	( keys( %{$entriesNfounds} ) == scalar( @{$data->{valuesIdx}} ) ) || $self->{HLP}->suicide();
	
	( $intTotalP == $fltTotalP ) || ( $intTotalP++ );
	
#	foreach $id ( keys( %{$lstFounds} ) ) { warn "FOUNDS $id" };
#	foreach $id ( keys( %{$lstEntries} ) ) { warn "ENTRIES $id" };
	
	foreach $id ( @{$data->{valuesIdx}} ) {
		$lstFounds->{$id} ? ( push( @{$recordsTop}, [ @{$entriesNfounds->{$id}} ] ) ) : ( push( @{$records}, [ @{$entriesNfounds->{$id}} ] ) );
	}
	@{$records} = ( @{$recordsTop}, @{$records} );
	
	if( $j = scalar( @{$records} ) ) {
		if( ( $lists->{page} < 0 ) || ( $j <= ( $i = ( $self->{RECORDS_PP} * $lists->{page} ) ) ) ) {
			$i				= 0;
			$lists->{page}	= 0;
			
		}
		( ( $i + $self->{RECORDS_PP} ) < $j ) ? ( $l = $i + $self->{CONST}->{SEARCH_LIMIT} ) : ( $l = $j );
	}
	else {
		$i = 0;
		$l = 0;
	}
	
	%{$data->{listed}} = ();
	for( $pos = $i; $pos < $l; $pos++ ) {
		$entry = $records->[$pos];
		$id	= $entry->[0];
		push( @{$page->{records}}, [ @{$entry} ] );
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

sub printPageHeader {
	my $self		= shift;
	my $scr			= shift;
	my $page		= shift;
	my $code		= $self->{CODE};
	my $data		= $self->{data};
	my $lists		= $data->{lists};
	my $child		= $self->{CHILD};
	my $shown		= keys( %{$data->{listed}} );
	my $total		= keys %{$self->{entriesNfounds}};
	my $totalSel	= keys( %{$lists->{entries}} );
	my $toolbox		= [];
	my $length;
	
	$scr->openCell( "bgcolor=#$self->{CONST}->{COLOR_BLUE} colspan=$self->{COLUMNS}" );
	
	if( $shown == $total ) {
		$scr->doTxt( "$shown $child->{NAME}(s) - $totalSel Selected - Insert New: " );
	}
	else { 
		$scr->doTxt( "$shown $child->{NAME}(s) [$page->{first}..$page->{last}] of $total - $page->{selected}/$totalSel Selected - " );
	}
	
	if( $self->{UNCLE} && ( $length = $self->{CONST}->{SEARCH_FIELD_LENGTH} ) ) {
		$scr->doEdit( "$code&SEARCH", $data->{search}, $length );
		if( $page->{totalPN} > 1 ) {
			 @{$toolbox} = ( '', 'lookup', '', 'boxa', 'greencheckbox', '', 'boxb', 'greenbox4' );
		}
		else {
			 @{$toolbox} = ( '', 'lookup', '', 'boxb', 'greenbox4', '', '', '' );
		}
	}
	
	if( $page->{currentPN} ) {
		( ( $page->{currentPN} + 1 ) < $page->{totalPN} ) ? ( push( @{$toolbox}, ( '', 'left', '', 'right' ) ) ) : ( push( @{$toolbox}, ( '', 'left' ) ) );
	}
	else {
		( $page->{totalPN} > 1 ) && ( push( @{$toolbox}, ( '', '', '', 'right' ) ) );
	}
	@{$toolbox} && $scr->doToolBox( $code, 16, $toolbox );
}

sub printView {
	my $self		= shift;
	my $scr			= shift;
	my $page;
	
	$self->refreshData();
	
	$page = $self->processPage();
	
	$scr->openTable( $self->{COLUMNS}, "bordercolor=#$self->{CONST}->{COLOR_BLUE} border frame=box rules=none" );
	$self->printPageHeader( $scr, $page, $self->{COLUMNS} );
	$self->printRecords( $scr, $page->{records} );
	$self->{PAGE_SEL}->printRow( $scr, $page->{currentPN}, $page->{totalPN} );
	
	if( $self->{VIEW_SETS} ) {
		@{$page->{records}} || ( $self->{VIEW_SETS}->{expanded} = 1 );
		$scr->openRow();
		$scr->openRow( "bgcolor=#$self->{CONST}->{COLOR_BLUE}" );
		$scr->openCell( "colspan=$self->{COLUMNS}" );
		$self->{VIEW_SETS}->printView( $scr );
	}

	$scr->closeTable();	
}	
	
sub printRecords {
	my $self		= shift;
	my $scr			= shift;
	my $records		= shift;
	my $mem			= $self->{MEM};
	my $uncles		= $self->{CHILD}->{UNCLES};
	my $lengths		= $self->{LENGTHS};
	my $child		= $self->{CHILD};
	my $lists		= $self->{data}->{lists};
	my $selection	= $lists->{entries};
	my $founds		= $lists->{founds};
	my $serialN		= 0;
	my $entry;
	my $uncle;
	my $length;
	my $x;
	my $link;
	my $txt;
	
	( caller() eq 'WebArc::ViewPage' )	|| $self->{HLP}->suicide();
	( "@{$child->{IDS}}" eq '0' ) 		|| $self->{HLP}->suicide( "NI" );
	
	foreach $entry ( @{$records} ) {
		$serialN++;
		$scr->openRow();
		
		foreach ( @{$child->{DISPLAY}} ) {
			m/^(\d+)/ || $self->{HLP}->suicide();
			$x = $1;
			$scr->openCell();
			if( $uncle = $uncles->[$x] ) {
				if( $lengths->{0} ) {
					$x && $self->{HLP}->suicide( "NI" );
					$scr->doCheckBox( "$self->{CODE}&VALUE&"."$serialN&0", $entry->[0], $selection->{$entry->[0]} );
					$scr->doHidden( "$self->{CODE}&X0&"."$serialN", $entry->[0] );
				}
				else {
					$scr->doHidden( "$self->{CODE}&VALUE&"."$serialN&0", $entry->[0] );
				}
				$txt = $mem->entryDefsGet( $uncle, $entry->[$x], [ 'MAIN' ] );
				( $link = $self->{MEM}->getLink( $uncle, $entry->[$x] ) ) ? $scr->doLink( $link, $txt ) : $scr->doTxt( $txt );
			}
			elsif( $length = $lengths->{$x} ) {
				$scr->doEdit( "$self->{CODE}&VALUE&"."$serialN&".$x, $entry->[$x], $length );	
			}
			elsif( defined( $child->{MAIN} ) && ( $child->{MAIN} == $x ) ) {
				$scr->doRadio( "$self->{CODE}&MAIN", $serialN, $entry->[$x] );	
			}
			else {
				$scr->doTxt( $entry->[$x] );
			}
		}
		
		$lists->{founds}->{$entry->[0]} && $scr->doImg( 'images/icons2/target-16.gif' );
		if( $child->{FLAGS}->{MAP} ) {
			$scr->openCell();
			if( $self->{CONST}->{PARENTS}->{$child->{PARENT}}->{FLAGS}->{RO} ) {
				die( "NI" );
			}
			else {
				$scr->doToolBox( $self->{CODE}.'&MAP&'."$entry->[0]$child->{UNCLES}->[0]$entry->[1]", 16, [ 's' ] );
			}
		}
	}
}

sub processForm {
	my $self	= shift;
	my $form		= shift;
	my $submitKey	= shift;
	my $submitValue	= shift;
	my $errors		= shift;#output
	my $warnings	= shift;#output
	my $child		= $self->{CHILD};
	my $data		= $self->{data};
	my $lists		= $data->{lists};
	my $entry		= [];
	my $newData		= [];
	my $main		= 0;
	my $operation;
	my $uncle;
	my $key;
	my $x;
	my $v;
	
	defined( $data->{search} = $form->{SEARCH} ) || ( $data->{search} = '' );
	$submitKey && ( ( $operation = shift( @{$submitKey} ) ) || ( $operation = '' ) );
		
	$lists->{closed} = 0;
	
	
	if( $operation eq 'VIEW_SETS' ) {
		$self->{VIEW_SETS} || $self->{HLP}->suicide();
		$self->{VIEW_SETS}->processForm( $form->{VIEW_SETS}, $submitKey ); 
	}
	elsif( $operation eq 'lookup' ) {
		( $uncle = $self->{CHILD}->{UNCLES}->[0] ) || $self->{HLP}->suicide();
		%{$lists->{founds}} = ();
		foreach( @{$self->{MEM}->entitySearch( $uncle, $data->{search}, '', $self->{CONST}->{SEARCH_LIMIT} )} ) { $lists->{founds}->{$_} = 1 };
		
		!%{$lists->{founds}} || ( $self->{CONST}->{SEARCH_LIMIT} < keys( %{$lists->{founds}} ) ) || ( push( @{$warnings}, "$child->{NAME}: Please Narrow Query Key" ) );
	}
	elsif( $operation eq 'left' ) {
		$lists->{page}--;
	}
	elsif( $operation eq 'right' ) {
		$lists->{page}++;
	}
	elsif( $operation eq 'boxb' ) {
		$lists->{closed} = 1;
	}
	elsif( $operation eq 'PAGE_SEL' ) {
		$key = $self->{PAGE_SEL}->processForm( $submitKey );
		
		if( $key eq '+1' ) {
			$lists->{page}++;	
		}
		elsif( $key eq '-1' ) {
			$lists->{page}--;	
		}
		else {
			$lists->{page} = $key;	
		}
	}
	
	if( $child->{FLAGS}->{RO} ) {
		$self->{HLP}->copyData( $child->{data}, $newData );
	}
	elsif( !$lists->{closed} ) {
		
		if( $operation ne 'boxa' ) {
			foreach $key ( keys %{$form->{VALUE}} ) {
				@{$entry} = @{$child->{DEFAULTS}};
				while ( ( $x, $v ) = each %{$form->{VALUE}->{$key}} ) {
					$entry->[$x] = $v;
				}
				
				if( $entry->[0] ) {
#					$lists->{entries}->{$entry->[0]} || $lists->{founds}->{$entry->[0]} || $self->{HLP}->suicide( $entry->[0] );
					if( ( $v = $form->{MAIN} ) && ( $v == $key ) ) {
						$main = $entry->[0];
						$entry->[$child->{MAIN}] = 1;
					} 
					push( @{$newData}, [ @{$entry} ] );
				}
				elsif( ( $operation eq 'greenbox4' ) || ( $operation eq 'greencheckbox' ) ) {
					( $entry->[0] = $form->{X0}->{$key} ) ? ( push( @{$newData}, [ @{$entry} ] ) ) : $self->{HLP}->suicide();
					$lists->{entries}->{$entry->[0]} = 1;
				}
			}
		}
		
		if( $operation eq 'greenbox4' ) {
			@{$entry} = @{$child->{DEFAULTS}};
			foreach( keys( %{$lists->{founds}} ) ) {
				$entry->[0] = $_;
				push( @{$newData}, [ @{$entry} ] );	
				$lists->{entries}->{$entry->[0]} = 1;
			}
			%{$lists->{founds}} = ();
		}
				
		foreach $entry ( @{$child->{data}} ) {
			unless( $data->{listed}->{$entry->[0]} ) {
				$main && ( $entry->[$child->{MAIN}] = 0 );
				push( @{$newData}, [ @{$entry} ] );
			}
		}
	}
	
	$self->{MEM}->childObjUpdate( $child, $newData, $errors, $warnings );
	
	if( $operation eq 'MAP' ) {
		return "map$child->{ID}$child->{CODE}$submitKey->[0]";
	}
	
	return '';
}
1;
