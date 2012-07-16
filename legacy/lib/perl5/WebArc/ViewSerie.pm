# (C) Miguel Godinho de Almeida - miguel@datindex.com 2005
package WebArc::ViewSerie;

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
	$self->{CELL}							= $self->{BRO}->{CELL};
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
	my $self	= shift;
	my $scr		= shift;
	my $mem		= $self->{MEM};
	my $child	= $self->{CHILD};
	my $cell	= $self->{CELL};
	my $main = '';
	my $code	= $self->{CODE};
	my $color	= $self->{CONST}->{COLOR_BLUE};
	my $name	= $child->{NAME};
	my $serial	= $child->{SERIAL};
	my $data	= $child->{data}; 
	my $cols;
	
#	$child->{FLAGS}->{RO} && $self->{HLP}->suicide();
	( $main = $child->{DISPLAY}->[0] ) && ( ( $main == $child->{MAIN} ) || $self->{HLP}->suicide() );
	( $child->{DISPLAY}->[1] =~ m/^0=(\d+)$/ ) || $self->{HLP}->suicide();
	my $length = $1;
	@{$child->{UNCLES}} && $self->{HLP}->suicide( 'not yet implemented' );
#	$cell->doSerieBox( $scr, $child->{CODE}, $self->{CONST}->{COLOR_BLUE},
#$child->{NAME}, $length, $child->{SERIAL}, $child->{MAIN}, $child->{data} );

	$main ? ( $cols = 2 ) : ( $cols = 1 ); 
	$scr->openTable( $cols, "bordercolor=#$color border frame=box rules=none" );
	$scr->openRow( "bgcolor=#$color" );
	my $total = scalar( @{$data} );
	$cols ? $scr->doCell( "$total $name(s):", "colspan=$cols" ) : $scr->doCell( "$total $name: " );
	my $serieN = 0;
	my $noMain = 1;
	if( $child->{FLAGS}->{RO} ) {
		foreach( @{$data} ) {
			$scr->openRow();
			$main && $_->[$main] && $scr->doRadio( '', '', 1 ) ;
			$scr->doCell( $_->[0] );
		}	
	}
	else {
		foreach( @{$data} ) {
			$serieN++;
			$scr->openRow();
			$scr->openCell();
			if( $main ) {
				$_->[$main] && ( $noMain ? ( $noMain = 0 ) : $self->{MEM}->suicide() );
				$scr->doRadio( $code."&MAIN", $_->[$serial], $_->[$main] );
				$scr->openCell();
			}
			$scr->doHidden( $code.'&VALUE&'."$serieN&".$serial, $_->[$serial] );
			$scr->doEdit( "$code&VALUE&"."$serieN&0", $_->[0], $length );
		}
		$scr->openRow();
		$scr->openCell();
		if ( $main ) {
			$scr->doRadio( $code."&MAIN", 0, $noMain );
			$scr->openCell();
		}
		$scr->doHidden( "$code&VALUE&0&".$serial, 0);
		$scr->doEdit( "$code&VALUE&0&0", '', $length );
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
		
	if( $submitValue ) {
		if( $submitValue =~ m/&(\w+);\d+;\d+$/ ) {
			$tgt		= $`;
			$operation	= $1;
		}
		elsif( $submitValue =~ m/^(\w+);\d+;\d+$/ ) {
			$tgt		= '';
			$operation	= $1;
		}
		else {
			$self->{HLP}->suicide( $submitValue );
		}
		
		$self->{HLP}->suicide( $operation );
	}
	
	if( $child->{FLAGS}->{RO} ) {
		$self->{HLP}->copyData( $child->{data}, $newData );
	}
	else {
		foreach $key ( keys %{$form->{VALUE}} ) {
			@{$entry} = @{$child->{DEFAULTS}};
			while ( ( $x, $v ) = each  %{$form->{VALUE}->{"$key"}} ) { $entry->[$x] = $v };
			defined( $form->{MAIN} ) && ( $form->{MAIN} == $key ) && ( $entry->[$child->{MAIN}] = 1 );
			push( @{$newData}, [ @{$entry} ] );
		}
	}
	$self->{MEM}->childObjUpdate( $child, $newData, $errors, $warnings );
	return '';
}
1;
