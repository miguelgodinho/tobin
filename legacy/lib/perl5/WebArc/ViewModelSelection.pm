# (C) Miguel Godinho de Almeida - miguel@gbf.de 2005
package WebArc::ViewModelSelection;

use strict;
use warnings;

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
	$self->{CODE}							|| $self->{HLP}->suicide();
	
	return $self;
}

sub printView {
	my $self			= shift;
	my $scr				= shift;
	my $setParent		= shift;
	my $results			= shift;
	my $mem				= $self->{MEM};
	my $setup;
	my $result;
	my $model;
	my $modelName;
	my $lnk;
	my $zeroSetups = 1;
	
	$scr->openTable( 5 );
	foreach $setup ( @{$results} ) {
		$scr->openRow();
		$scr->openCell();
#		warn $self->{CODE};
		$scr->doRadio( $self->{CODE}.'&sel', $setup->{ID}, $zeroSetups );
		$zeroSetups && ( $zeroSetups = 0 );
		if( $lnk = $mem->getLink( $setParent, $setup->{ID} ) ) {
			$scr->openCell();
			$scr->doLink( $lnk, $setup->{DEF} );
		}
		else {
			$scr->doCell( $setup->{DEF} );	
		}
		$scr->doCell( '' );
		$scr->doCell( $mem->userNameGet( $setup->{OWNER} ) );
		foreach $result( @{$setup->{RESULTS}} ) {
			$scr->openRow();
			$scr->doCell( '' );
			if( $lnk = $mem->getLink( $result->{MODEL}, $result->{ID} ) ) {
				$scr->openCell();
				$scr->doLink( $lnk, $result->{STATUS} );
			}
			else {
				$scr->doCell( $result->{STATUS} );
			}	
			$scr->doCell( $result->{DATE} );
			$scr->doCell( $mem->userNameGet( $result->{OWNER} ) );
		}
	}
	$scr->openRow();
	foreach $model ( @{$mem->{CONST}->{PARENTS}->{$setParent}->{MODELS}} ) {
		$modelName = $mem->{CONST}->{MODELS}->{$model}->{NAME};
		$scr->openRow();
		$scr->openCell( 'colspan=5 align=center' );
		$zeroSetups ? $scr->doSubmit( $self->{CODE}.'&run&'.$model, "Run $modelName", 1 ) : $scr->doSubmit( $self->{CODE}.'&run&'.$model, "Run $modelName" );
	}
	
	$scr->closeTable();
}

sub processForm {
	my $self		= shift;
	my $form		= shift;
	my $submitValue	= shift;
	my $errors		= shift;#output
	my $warnings	= shift;#output
	
	return "";
}

1;
