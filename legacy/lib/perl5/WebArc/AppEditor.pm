# (C) Miguel Godinho de Almeida - miguel@datindex.com 2004
package WebArc::AppEditor;

use strict;
use warnings;

use WebArc::ViewID;
use WebArc::ViewErrors;
use WebArc::ViewWarnings;
use WebArc::ViewPage;
use WebArc::ViewSingle;
use WebArc::ViewSerie;
use WebArc::ViewLink;
use WebArc::ViewSet;
use WebArc::ViewComplex;
use WebArc::ViewHistory;

sub new {
	my $param	= shift;
	my $self	= shift;
	my $class	= ref( $param ) || $param;
	bless( $self, $class );
	bless( $self->{BRO}, 'WebArc::Broker' );
	$self->{CODE}		= $self->{BRO}->{app};
	$self->{MEM}		= $self->{BRO}->{MEM};
	$self->{DBA}		= $self->{MEM}->{DBA};
	$self->{HLP}		= $self->{BRO}->{HLP};
	$self->{CONST}		= $self->{BRO}->{CONST};
	$self->{CODE}		=~ m/^(edi)(\d+)(\w+)$/ || $self->{HLP}->suicide();
	$self->{ID}			= $2;
	$self->{TYPE}		= $3;
	$self->{USR} 		= $self->{MEM}->{USR};
	$self->{PARENT}		= $self->{MEM}->entryObjGet( $self->{TYPE}, $self->{ID}, 1 );
	$self->{CHILDREN}	= $self->{PARENT}->{CHILDREN};
	$self->{data} 		= $self->{BRO}->getData();
	$self->{errors}		= [];
	$self->{warnings}	= [];
	$self->{VIEWS}		= {};
	
	unless ( $self->{data}->{INIT} ) {
		$self->{data}->{INIT}	= 1;
		my %relatives = $self->{PARENT}->findRelations( '', [ 'BROTHERS' ] );
		foreach ( keys %relatives ) {
			 $self->{data}->{blpage}->{"$_"} = 0;
		}
		foreach ( values %{$self->{CHILDREN}} ) {
			(	( $_->{CODE} eq 'id'		) ||	
				( $_->{CODE} eq 'errors'	) ||
				( $_->{CODE} eq 'warnings'	) ||
				( $_->{CODE} eq 'history'	)	) && $self->{HLP}->suicide( "$_->{CODE} is a reserved keyword" ); 
			$self->{data}->{$_->{CODE}} = {};
		}
	}
	
	$self->{VIEWS}->{id}		= new WebArc::ViewID( {			BRO		=> $self->{BRO},
																CODE	=> "$self->{CODE}&id",
																PARENT	=> $self->{PARENT} } );
																
	$self->{VIEWS}->{errors}	= new WebArc::ViewErrors( {		BRO		=> $self->{BRO},
																CODE	=> "$self->{CODE}&errors" } );
									
	$self->{VIEWS}->{warnings}	= new WebArc::ViewWarnings( {	BRO		=> $self->{BRO},
																CODE	=> "$self->{CODE}&warnings" } );
																
	$self->{VIEWS}->{history}	= new WebArc::ViewHistory( {	BRO		=> $self->{BRO},
																CODE	=> "$self->{CODE}&history",
																PARENT	=> $self->{PARENT} } );
	foreach( values %{$self->{CHILDREN}} ) {
		if( $_->{FLAGS}->{PAGE} ) {
			$self->{VIEWS}->{$_->{CODE}} = new WebArc::ViewPage( {		BRO		=> $self->{BRO},	
																		data	=> $self->{data}->{$_->{CODE}},
																		CODE	=> $self->{CODE}.'&'.$_->{CODE},
																		CHILD	=> $_ } );
		}
		elsif( $_->{TYPE} eq 'SINGLE' ) {
			$self->{VIEWS}->{$_->{CODE}} = new WebArc::ViewSingle( {	BRO		=> $self->{BRO},
																		data	=> $self->{data}->{$_->{CODE}},
																		CODE	=> $self->{CODE}.'&'.$_->{CODE},
																		CHILD	=> $_ } );
		}
		elsif( $_->{TYPE} eq 'SERIE' ) {
			$self->{VIEWS}->{$_->{CODE}} = new WebArc::ViewSerie( {		BRO		=> $self->{BRO},
																		data	=> $self->{data}->{$_->{CODE}},
																		CODE	=> $self->{CODE}.'&'.$_->{CODE},
																		CHILD	=> $_ } );
		}
		elsif( $_->{TYPE} eq 'LINK' ) {
			$self->{VIEWS}->{$_->{CODE}} = new WebArc::ViewLink( {		BRO		=> $self->{BRO},
																		data	=> $self->{data}->{$_->{CODE}},
																		CODE	=> $self->{CODE}.'&'.$_->{CODE},
																		CHILD	=> $_ } );
		}
		elsif( $_->{TYPE} eq 'SET' ) {
			$self->{VIEWS}->{$_->{CODE}} = new WebArc::ViewSet( {		BRO		=> $self->{BRO},
																		data	=> $self->{data}->{$_->{CODE}},
																		CODE	=> $self->{CODE}.'&'.$_->{CODE},
																		CHILD	=> $_ } );
		}
		elsif( $_->{TYPE} eq 'COMPLEX' ) {
			$self->{VIEWS}->{$_->{CODE}} = new WebArc::ViewComplex( {	BRO		=> $self->{BRO},
																		data	=> $self->{data}->{$_->{CODE}},
																		CODE	=> $self->{CODE}.'&'.$_->{CODE},
																		CHILD	=> $_ } );
		}
		else {
			$self->{HLP}->suicide( "$_->{TYPE} has no associated view" );	
		}
	}
	return $self;
}

sub processForm {
	my $self		= shift;
	my $frm		 	= shift;
	my $return		= '';
	my $submitArray	= [];
	my $submitKey	= shift( @{$frm->{submitKey}} );
	my $childCode;
	my $nxtPage;
	
	ref( $self->{errors} ) || $self->{HLP}->suicide();
	foreach $childCode ( $self->{HLP}->sortHash( $self->{CHILDREN}, 'PRIORITY' ) ) {
		if( $submitKey eq $childCode ) {
			$nxtPage = $self->{VIEWS}->{$childCode}->processForm(	$frm->{$childCode},
																	$frm->{submitKey},
																	$frm->{submitValue},
																	$self->{errors},
																	$self->{warnings} 	);
		}
		elsif( $self->{VIEWS}->{$childCode}->processForm(			$frm->{$childCode},
																	[],
																	'',
																	$self->{errors},
																	$self->{warnings}	) ) {
			$self->{HLP}->suicide( "Only the submitted view can return" );
		}
	}
	
	if( $submitKey eq 'id' ) {
		$nxtPage && $self->{HLP}->suicide( "Only the submitted view can return" );
	 	$nxtPage = $self->{VIEWS}->{id}->processForm( 				$frm->{id},
	 																$frm->{submitKey},
																	$frm->{submitValue},
																	$self->{errors},
																	$self->{warnings} );
	} 
	
	return $nxtPage;
}

sub run {
	my $self 	= shift;
	my $scr		= $self->{SCR};
	my $mem		= $self->{MEM};
	my $data	= $self->{data};
	my $frm		= $self->{BRO}->getForm();
	my $nxtApp;

	$self->{USR} || $self->{HLP}->suicide( "SECURITY FAULT ????????????????" );

	@{$frm->{submitKey}} && ( $nxtApp = $self->processForm( $frm ) ) && ( return $nxtApp );

	my $history = [];
	my $child;
	my $length;
	my $search;
	my $uncle;
	my $childCode;

	$scr->openPage( $self->{CODE} );
	$scr->stoBar( [ 'logout', $self->{CONST}->{DOMAIN_APP_PUBLIC} ] );
	$scr->stoBar( [ "Bookmark Manager", "man0b" ] );
	$scr->stoBar( [ "$self->{PARENT}->{NAME} Manager", "man0$self->{PARENT}->{CODE}" ] );
	$scr->stoBar( [ "$self->{PARENT}->{NAME} Editor", "edi0$self->{PARENT}->{CODE}" ] );
	$scr->doBar( "edi0$self->{PARENT}->{CODE}" );

	$scr->doLine( 2 );
	$self->{VIEWS}->{id}->printView( $scr );
	$scr->doLine();
	$self->{VIEWS}->{errors}->printView( $scr, $self->{errors} );
	$self->{VIEWS}->{warnings}->printView( $scr, $self->{warnings} );
	@{$self->{errors}} = ();
	
	foreach $childCode ( $self->{HLP}->sortHash( $self->{CHILDREN}, 'PRIORITY' ) ) {
		$scr->doLine( 1 );
		$self->{VIEWS}->{$childCode}->printView( $scr );
	}
	
	$self->{VIEWS}->{history}->printView( $scr );
	$scr->closePage();
	return '';
}
1;
