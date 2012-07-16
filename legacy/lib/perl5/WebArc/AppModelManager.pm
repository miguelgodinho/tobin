# (C) Miguel Godinho de Almeida - miguel@igbf.de 2005
package WebArc::AppModelManager;

use strict;
use warnings;
use Rapido::SimulAccessor;
use WebArc::ViewModelSelection;

sub new {
	my $param	= shift;
	my $self	= shift;;
	my $class	= ref( $param ) || $param;
	bless( $self, $class );
	
	$self->{CODE}		= $self->{BRO}->{app};
	( $self->{CODE}		=~ m/^\w+0(\w+)$/ )							|| $self->{HLP}->suicide( $self->{CODE} );
	$self->{TYPE}		= $1;
	$self->{HLP}		= $self->{BRO}->{HLP};
	$self->{MEM}		= $self->{BRO}->{MEM};
	$self->{CONST}		= $self->{MEM}->{CONST};
	$self->{CELL}		= $self->{BRO}->{CELL};
	$self->{DBA}		= $self->{MEM}->{DBA};
	$self->{PARENTS}	= $self->{CONST}->{PARENTS};
	$self->{USER_PUB}	= $self->{CONST}->{USER_PUB};
	$self->{USR}		= $self->{MEM}->{USR};
	$self->{PARENT}		= $self->{PARENTS}->{$self->{TYPE}};
	$self->{CHILDREN}	= $self->{PARENT}->{CHILDREN};
	$self->{VIEW}		= new WebArc::ViewModelSelection( { BRO		=> $self->{BRO},
															CODE	=> $self->{CODE} } );
	
	if( $self->{USR} != 1 ) {
		$self->{USR}										|| $self->{HLP}->suicide();
		$self->{PARENTS}->{$self->{TYPE}}->{FLAGS}->{ADMIN}	&& $self->{HLP}->suicide( "SECURITY FAULT" );
	}
	
#	unless ( $self->{data}->{INIT} ) {
#		$self->{data}->{INIT}	= 1;
#	}
		
	return $self;
}

sub processForm {
	my $self 	= shift;
	my $form 	= shift;
	my $type	= $self->{TYPE};
	my $data 	= $self->{data};
	my $mem		= $self->{MEM};
	my $errors	= [];
	my $action;
	my $setup;
	my $tgt;

	( $action = $form->{submitKey}->[0] ) || ( $action = 'refresh' );
	
	if( $action eq 'run' ) {
#		foreach( keys( %{$form} ) ) { warn $_ };
#		warn "@{$form->{submitKey}}";
#		warn $form->{submitValue};
#		warn $form->{sel};
		if( ( $tgt = $form->{submitKey}->[1] ) && ( $setup = $form->{sel} ) ) {
			my $cpu = new Rapido::SimulAccessor( {	CONST		=> $self->{CONST},
			 										USR			=> $self->{USR},
			 										DBA			=> $mem->{DBA},
			 										HLP			=> $self->{HLP},
			 										MEM			=> $self->{MEM}	} );
			$cpu->simulSchedule( $tgt, $setup, $self->{USR} );	
			sleep 1;	
		}
	}
	elsif( $action ne 'refresh' ) {
		$self->{HLP}->suicide( "@{$form->{submitKey}}" );
	}

	return '';
}

sub run {
	my $self 		= shift;
	my $hlp			= $self->{HLP};	
	my $mem			= $self->{MEM};
	my $scr			= $self->{SCR};
	my $data		= $self->{data};
	my $form		= $self->{BRO}->getForm();
	my $parent		= $self->{PARENT};
	my $cell		= $self->{CELL};
	my $simuls		= new Rapido::SimulAccessor( { MEM => $mem, HLP => $hlp } );
	my $setParent	= $self->{TYPE};
	my $setups;
	my $nxtApp;
	
	@{$form->{submitKey}} && ( $nxtApp = $self->processForm( $form ) ) && ( return $nxtApp );

	$scr->openPage( "$self->{CODE}" );
	$scr->stoBar( [ 'logout', $self->{CONST}->{DOMAIN_APP_PUBLIC} ] );	
	$scr->stoBar( [ "Bookmark Manager", "man0b" ] );
	$scr->stoBar( [ "$parent->{NAME} Manager", $self->{CODE} ] );
	$scr->stoBar( [ "Edit New $parent->{NAME}", "edi0$setParent" ] );
	$scr->doBar( $self->{CODE});
	$scr->doLine();
	$scr->openCell( 'align=center' );
	$setups = $simuls->setupsAndResults( $setParent ); 
	$self->{VIEW}->printView( $scr, $setParent, $setups );
	$self->{SCR}->closePage();
	return '';
}

1;
