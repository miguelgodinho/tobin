# (C) Miguel Godinho de Almeida - miguel@datindex.com 2005
package WebArc::ViewStub;

use strict;
use warnings;

sub new {
	my $param	= shift;
	my $self	= shift;
	my $class	= ref( $param ) || $param;
	bless( $self, $class );
	
	$self->{MEM}	= $self->{BRO}->{MEM};
	$self->{DBA}	= $self->{MEM}->{DBA};
	$self->{HLP}	= $self->{BRO}->{HLP};
	$self->{CONST}	= $self->{BRO}->{CONST};
	$self->{data}	|| $self->{HLP}->suicide();
	$self->{CODE}	|| $self->{HLP}->suicide();
	
	my $data = $self->{data};
	
	if( $data->{INIT} ) {
		( $data->{CODE}	eq $self->{CODE} )	|| $self->{HLP}->suicide();
	}
	else {
		$data->{INIT}	= 1;
		$data->{CODE}	= $self->{CODE};
	}
	return $self;
}

sub printView {
	my $self	= shift;
	my $scr		= shift;		

}



sub processForm {
	my $self		= shift;
	my $form		= shift;
	my $submitKey	= shift;
	my $submitValue	= shift;
	my $errors		= shift;#output
	my $warnings	= shift;#output
	

	return '';
}

1;
