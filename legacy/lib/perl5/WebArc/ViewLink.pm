# (C) Miguel Godinho de Almeida - miguel@datindex.com 2005
package WebArc::ViewLink;

use strict;
use warnings;
use vars qw($VERSION @ISA @EXPORT_OK);
use Exporter;

@ISA = ( 'Exporter' );
$VERSION = '1.00';
@EXPORT_OK = qw();

sub new {
	my $param	= shift;
	my $self	= shift;
	my $class	= ref( $param ) || $param;
	bless( $self, $class );
	$self->{MEM}							= $self->{BRO}->{MEM};
	$self->{DBA}							= $self->{MEM}->{DBA};
	$self->{LOG}							= $self->{MEM}->{LOG};
	$self->{HLP}							= $self->{BRO}->{HLP};
	$self->{CONST}							= $self->{BRO}->{CONST};
	$self->{data}							|| $self->{HLP}->suicide();
	$self->{CODE}							|| $self->{HLP}->suicide();
	$self->{CHILD}							|| $self->{HLP}->suicide();
	
	my $data = $self->{data};
	
	if( $data->{INIT} ) {
		( $data->{CODE}			eq $self->{CODE} )			|| $self->{HLP}->suicide();
		( $data->{CHILDCODE}	eq $self->{CHILD}->{CODE} )	|| $self->{HLP}->suicide();
		( $data->{ID}			eq $self->{CHILD}->{ID} )	|| $self->{HLP}->suicide();
	}
	else {
		$data->{INIT}		= 1;
		$data->{CODE}		= $self->{CODE};
		$data->{CHILDCODE}	= $self->{CHILD}->{CODE};
		$data->{ID}			= $self->{CHILD}->{ID};
	}
	return $self;
}

sub printView {
	my $self			= shift;
	my $scr				= shift;
	my $mem				= $self->{MEM};
	my $child			= $self->{CHILD};
	my $options			= [];
	my $definitions		= {};
	my $sortedData		= [];
	my $unsortedData	= [];
	my $length;
	
	$child->{FLAGS}->{RO} && $self->{HLP}->suicide();
	( $child->{DISPLAY}->[0] =~ m/^0=(\d+)$/ ) || $self->{HLP}->suicide();
	( $length = $1 ) || $self->{HLP}->suicide();
	
	if( $child->{ALLOWS}->[1] ) {
		@{$options} = split( /,/, $child->{ALLOWS}->[1] );
		$options	= $mem->entityDefMatrixGet( $child->{UNCLES}->[1], $options );
	}
	else {
		$options	= $mem->entityDefMatrixGet( $child->{UNCLES}->[1] );
	}
	
	foreach( @{$options} ) { $definitions->{$_->[0]} ? $self->{HLP}->suicide() : ( $definitions->{$_->[0]} = $_->[1] ) };
	foreach( @{$child->{data}} ) {
#		defined( $definitions->{$_->[1]} ) || $self->{HLP}->suicide( "$_->[1] is not a allowed user for $child->{NAME}" );
		push ( @{$unsortedData}, [ $_->[0], $_->[1], $definitions->{$_->[1]} ] );
	}
	
	@{$sortedData} = $self->{HLP}->sortMatrix( $unsortedData, [ 2, 0 ] );
	$self->doLinkBox( $scr, $self->{CODE}, $self->{CONST}->{COLOR_BLUE}, $child->{NAME}, $child->{LABELS}, $length, $options, $child->{DEFAULTS}->[1], $sortedData );
}

sub doLinkBox { #
	my $self	= shift;
	my $scr		= shift;
	my $code	= shift;
	my $color	= shift;
	my $name	= shift;
	my $labels	= shift;
	my $length	= shift;
	my $options	= shift; # [ [ id, user ] , ]
	my $default	= shift;
	my $data	= shift; # [ [ link, uid, username ] , ]


	$scr->openTable( 3, "bordercolor=#$color border frame=box rules=none" );
	$scr->openRow( "bgcolor=#$color" );
	$scr->openCell( 'colspan=3' );
	if ( @{$options} ) {
		my $total = scalar( @{$data} );
		$scr->doTxt( "$total $name:" );
		$scr->closeCell();
		$scr->openRow();
		$scr->openCell();
		$scr->doCell( $labels->[1], 'align=center' );
		$scr->doCell( $labels->[0], 'align=center' );
		$scr->closeRow();
		if ( @{$data} ) {
			$scr->openRow( "bgcolor=#$color" );
			$scr->openCell( 'colspan=3' );
			$scr->closeRow();
			my $link;
			my $pos = 0;
			foreach ( @{$data} ) {
				$pos++;
				$scr->openRow();
				$scr->openCell();
				
				if( defined( $_->[2] ) ) {
					$scr->doCheckBox( $code.'&VALUE&'."$pos&0", $_->[0], 1 );
					$scr->doHidden( $code.'&VALUE&'."$pos&1", $_->[1] );
					$scr->openCell();
					$scr->doTxt( $_->[2] );
				}
				elsif( defined( $_->[1] ) ) {
					$scr->openCell();
					$scr->doTxt( $self->{MEM}->userNameGet( $_->[1] ) );	
				}
				else {
					$self->{MEM}->suicide( "Link requires user code" );
				}
				
				$scr->openCell();
				( $link = $self->{MEM}->getLink( $_->[1], $_->[0] ) ) ? $scr->doLink( $link, $_->[0] ) : $scr->doTxt( $_->[0] );
			}
		}
		$scr->closeRow();
		$scr->openRow( "bgcolor=#$color" );
		$scr->openCell( 'colspan=3' );
		$scr->closeRow();
		$scr->openCell();
		$scr->doToolBox( 'id', 16, [ 'gear' ] );
		$scr->openCell();
		$scr->doSelect( $code."&VALUE&0&1", $options, $default );
		$scr->openCell();
		$scr->doEdit( "$code&VALUE&0&0", '', $length ); 
	}
	else {
		$scr->doTxt( " No Users to Assign $name" );
	}
	$scr->closeTable();
}

sub processForm {
	my $self		= shift;
	my $form		= shift;
	my $submitKey	= shift;
	my $submitValue	= shift;
	my $errors		= shift;#output
	my $warnings	= shift;#output
	my $child		= $self->{CHILD};
	my $tgt			= '';
	my $operation	= '';
	my $entry		= [];
	my $newData		= [];
	my $key;
	my $x;
	my $v;
		
	ref( $errors ) || $self->{HLP}->suicide();
	if( $submitValue =~ m/&(\w+);\d+;\d+$/ ) {
		$tgt		= $`;
		$operation	= $1;
	}
	elsif( $submitValue =~ m/^(\w+);\d+;\d+$/ ) {
		$tgt		= '';
		$operation	= $1;
	}
	
	if( $child->{FLAGS}->{RO} ) {
		$self->{HLP}->copyData( $child->{data}, $newData );
	}
	else {
		foreach $key ( keys %{$form->{VALUE}} ) {
			@{$entry} = @{$child->{DEFAULTS}};
			while ( ( $x, $v ) = each  %{$form->{VALUE}->{"$key"}} ) {
				$entry->[$x] = $v;
			}
			push( @{$newData}, [ @{$entry} ] );
		}
	}
	$self->{MEM}->childObjUpdate( $child, $newData, $errors, $warnings );	
	return '';
}

1;
