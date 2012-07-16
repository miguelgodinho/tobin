# (C) Miguel Godinho de Almeida - miguel@datindex.com 2005
package WebArc::ViewID;

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
	$self->{MEM}			= $self->{BRO}->{MEM};
	$self->{DBA}			= $self->{MEM}->{DBA};
	$self->{LOG}			= $self->{MEM}->{LOG};
	$self->{HLP}			= $self->{BRO}->{HLP};
	$self->{CONST}			= $self->{BRO}->{CONST};
	$self->{CELL}			= $self->{BRO}->{CELL};
	$self->{CODE}			|| $self->{HLP}->suicide();
	$self->{PARENT}			|| $self->{HLP}->suicide();
	
	return $self;
}

sub printView {
	my $self	= shift;
	my $scr		= shift;
	my $mem		= $self->{MEM};
	my $color	= $self->{CONST}->{COLOR_GREEN};
	my $id		= $self->{PARENT}->{ID};
	my $name	= $self->{PARENT}->{NAME};
	my $saved	= $self->{PARENT}->isSaved();

	$scr->openCell( "align=left valign=middle bgcolor=#$color" );
	if ( $id ) {
		$scr->doTxt( "$name $id" );
		$scr->doToolBox( $self->{CODE}, 16, [ '', 'gear', '', 'recycle', '', 'save', '', 'garbage' ] );
		$saved || $scr->doTxt( ' ** unsaved changes **' );
	}
	else {
		$scr->doTxt( "[ Unsaved $name ]" );
		$scr->doToolBox( $self->{CODE}, 16, [ '', 'gear', '', '', 'save' ] );
	}
	$scr->closeCell();
}

sub processForm {
	my $self		= shift;
	my $form		= shift;
	my $submitKey	= shift;
	my $submitValue	= shift;
	my $errors		= shift;
	my $warnings	= shift;
	my $mem			= $self->{MEM};
	my $parentCode	= $self->{PARENT}->{CODE};
	my $parentID	= $self->{PARENT}->{ID};
	my $operation	= shift( @{$submitKey} );
	my $childCode;
		
	if( $operation eq 'recycle' ) {
		@{$errors} = ();
		$mem->entryObjRecycle( $self->{PARENT} );
		return '';
	}
	elsif( $operation eq 'garbage' ) {
		if( $mem->entryObjDelete( $self->{PARENT}, $errors, $warnings ) ) {
			return "man0$parentCode";
		}
		else {
			 return '';
		}
	}
	elsif( $operation eq 'save' ) {
		if( !@{$errors} && $mem->entryObjSave( $self->{PARENT}, $errors, $warnings ) ) {
			if( @{$warnings} ) {
				return '';
			}
			else {
				# there is no need to delete, but make lighter sessions
				delete( $mem->{data}->{RECORDS}->{$parentCode}->{$parentID} );
				return "man0$parentCode";	
			}
		}
		else {
			return '';	
		}	
	}
	elsif( $operation ne 'gear' ) {
		$self->{HLP}->suicide( $operation );
	}
	return '';
}

1;
