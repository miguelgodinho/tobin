# (C) Miguel Godinho de Almeida - miguel@datindex.com 2004
package WebArc::AppManager;

use strict;
use warnings;

sub new {
	my $param	= shift;
	my $self	= shift;;
	my $class	= ref( $param ) || $param;
	bless( $self, $class );
	
	$self->{HLP}		= $self->{BRO}->{HLP};
	$self->{MEM}		= $self->{BRO}->{MEM};
	$self->{CODE}		= $self->{BRO}->{app};
	$self->{CONST}		= $self->{MEM}->{CONST};
	$self->{DBA}		= $self->{MEM}->{DBA};
	$self->{PARENTS}	= $self->{CONST}->{PARENTS};
	( $self->{USR}		= $self->{MEM}->{USR} )						|| $self->{HLP}->suicide( "SECURITY FAULT" );
	( $self->{CODE}		=~ m/^\w+0(\w+)$/ )							|| $self->{HLP}->suicide( $self->{CODE} );
	$self->{TYPE}		= $1;
	$self->{ENTITY}		= $self->{PARENTS}->{$self->{TYPE}};
	$self->{CHILDREN}	= $self->{ENTITY}->{CHILDREN};
	$self->{data} 		= $self->{BRO}->getData();
	
	$self->{PARENTS}->{$self->{TYPE}}->{FLAGS}->{ADMIN}	&& ( ( $self->{USR} == 1 ) || $self->{HLP}->suicide( "SECURITY FAULT" ) );
	
	unless( $self->{data}->{init} ) {
		$self->{data}->{init}		= 1;
		$self->{data}->{VIEW_LIST}	= {};
		$self->{data}->{lists}		= {	entries	=> {},
										founds	=> {},
										page	=> 0,
										closed	=> 0 };
		
		unless( $self->{ENTITY}->{FLAGS}->{TREE} ) {
			$self->{data}->{VIEW_SEARCH_ENTITY} = {};
			
			if( $self->{ENTITY}->{FLAGS}->{STOICH} ) {
				foreach( values %{$self->{CHILDREN}} ) {
					if( $_->{FLAGS}->{STOICH} ) {
						$self->{data}->{stoichChildCode} 	&& $self->{HLP}->suicide( "Just supports 1 child with flag stoich" );
						$self->{data}->{stoichChildCode}	= $_->{CODE};
						$self->{data}->{VIEW_SEARCH_STOICH}	= {};
					}
				}
			}
		}
	}
	
	$self->createViews();
			
	return $self;
}

sub createViews {
	my $self			= shift;
#	my $saveFieldLength	= 0;
	my $setEntityCode	= '';
	
	if( $self->{PARENTS}->{$self->{TYPE}}->{FLAGS}->{TREE} ) {
		require WebArc::ViewTree;
		$self->{views}->{VIEW_LIST} = new WebArc::ViewTree( {	BRO		=> $self->{BRO},
																CODE	=> "$self->{CODE}&VIEW_LIST",
																data	=> $self->{data}->{VIEW_LIST},
																ENTITY	=> $self->{ENTITY},
																lists	=> $self->{data}->{lists} } );
	}
	else {
		require WebArc::ViewSearchEntity;
		$self->{views}->{VIEW_SEARCH_ENTITY} = new WebArc::ViewSearchEntity( {	BRO		=> $self->{BRO},
																				CODE	=> "$self->{CODE}&VIEW_SEARCH_ENTITY",
																				data	=> $self->{data}->{VIEW_SEARCH_ENTITY},
																				ENTITY	=> $self->{ENTITY},
																				lists	=> $self->{data}->{lists} } );
		
		if( $self->{ENTITY}->{FLAGS}->{STOICH} ) {
			require WebArc::ViewSearchStoich;
			$self->{views}->{VIEW_SEARCH_STOICH} = new WebArc::ViewSearchStoich( {	BRO		=> $self->{BRO},
																					CODE	=> "$self->{CODE}&VIEW_SEARCH_STOICH",
																					data	=> $self->{data}->{VIEW_SEARCH_STOICH},
																					ENTITY	=> $self->{ENTITY},
																					CHILD	=> $self->{CHILDREN}->{$self->{data}->{stoichChildCode}},
																					lists	=> $self->{data}->{lists} } );
		}
		
		require WebArc::ViewEntriesPage;
		$self->{views}->{VIEW_LIST} = new WebArc::ViewEntriesPage( {	BRO		=> $self->{BRO},
																		CODE	=> "$self->{CODE}&VIEW_LIST",
																		data	=> $self->{data}->{VIEW_LIST},
																		ENTITY	=> $self->{ENTITY},
																		lists	=> $self->{data}->{lists}	} );
	}
	
	if( $setEntityCode = $self->{ENTITY}->{S} ) {
		require WebArc::ViewSetsMng;
		
		defined( $self->{data}->{VIEW_SETS} ) || ( $self->{data}->{VIEW_SETS} = {} );
		
		$self->{views}->{VIEW_SETS} = new WebArc::ViewSetsMng( {
									data		=> $self->{data}->{VIEW_SETS},
									SAVE		=> 1,
									CODE		=> "$self->{CODE}&VIEW_SETS",
									MEM			=> $self->{MEM},
									BRO			=> $self->{BRO},
									ENTITY		=> $self->{PARENTS}->{$setEntityCode},
									lists		=> $self->{data}->{lists} } );
	}
}

sub processForm {
	my $self	 	= shift;
	my $form	 	= shift;
	my $type		= $self->{TYPE};
	my $mem			= $self->{MEM};
	my $data	 	= $self->{data};
	my $tgt			= shift( @{$form->{submitKey}} );
	my $saveSet		= 0;
	my $setsView	= undef; #VIEW_SETS may need to be reprocessed at the end, if is target and operation is save
	my $initialTime;
	my $view;
	my $elapsedTime;
	
	$data->{lists}->{closed} = 0;
	
	if( $tgt eq 'VIEW_SEARCH_ENTITY' ) {
		$initialTime	= Time::HiRes::time();
		$self->{views}->{VIEW_SEARCH_ENTITY}->processForm(	$form->{VIEW_SEARCH_ENTITY}, $form->{submitKey} );
		$elapsedTime	= Time::HiRes::time() - $initialTime;
	}
	elsif( $tgt eq 'VIEW_SEARCH_STOICH' ) {
		$initialTime	= Time::HiRes::time();
		$self->{views}->{VIEW_SEARCH_STOICH}->processForm( $form->{VIEW_SEARCH_STOICH}, $form->{submitKey} );
		$elapsedTime	= Time::HiRes::time() - $initialTime;
	}
	elsif( $tgt eq 'VIEW_LIST' ) {
			$self->{views}->{VIEW_LIST}->processForm( $form->{VIEW_LIST}, $form->{submitKey} );
	}
	elsif( $tgt eq 'VIEW_SETS' ) {
		$setsView = $self->{views}->{VIEW_SETS};
		$setsView->processForm( $form->{VIEW_SETS}, $form->{submitKey} ); 
	}
	else {
		warn $tgt;
	}
	
	if( ( $tgt ne 'VIEW_SEARCH_ENTITY' ) && ( $view = $self->{views}->{VIEW_SEARCH_ENTITY} ) ) {
		$view->processForm( $form->{VIEW_SEARCH_ENTITY} );	
	}
	
	if( ( $tgt ne 'VIEW_SEARCH_STOICH' ) && ( $view = $self->{views}->{VIEW_SEARCH_STOICH} ) ) {
		$view->processForm( $form->{VIEW_SEARCH_STOICH} );
	}
	
	if( $view = $self->{views}->{VIEW_LIST} ) {
		$data->{lists}->{closed} || $view->processForm( $form->{VIEW_LIST} );
	}
	
	$setsView && $setsView->processForm( $form->{VIEW_SETS}, $form->{submitKey} );
	
	return '';
}

sub run {
	my $self 	= shift;
	my $scr		= $self->{SCR};
	my $frm		= $self->{BRO}->getForm();
	my $type	= $self->{TYPE};
	my $nxtApp;
	my $view;

	$self->{USR} || $self->{HLP}->suicide( "SECURITY FAULT ????????????????" );

	@{$frm->{submitKey}} && ( $nxtApp = $self->processForm( $frm ) ) && ( return $nxtApp );

	$scr->openPage( $self->{CODE} );
	$scr->stoBar( [ 'logout', $self->{CONST}->{DOMAIN_APP_PUBLIC} ] );
	( $type eq 'b' ) || $scr->stoBar( [ "Bookmark Manager", "man0b" ] );
	$scr->stoBar( [ "$self->{ENTITY}->{NAME} Manager", "man0$self->{ENTITY}->{CODE}" ] );
	$scr->stoBar( [ "Edit New $self->{ENTITY}->{NAME}", "edi0$type" ] );
	$scr->doBar( "man0$type" );
	
	if( $view = $self->{views}->{VIEW_SEARCH_ENTITY} ) {
		$scr->doLine( );	
		$scr->openRow();
		$scr->openCell( 'align=center' );
		$view->printView( $scr );
	}
	
	if( $view = $self->{views}->{VIEW_SEARCH_STOICH} ) {
		$scr->doLine( );	
		$scr->openRow();
		$scr->openCell( 'align=center' );
		$view->printView( $scr );
	}
	
	if( $view = $self->{views}->{VIEW_LIST} ) {
		$scr->doLine( );	
		$scr->openRow();
		$scr->openCell( 'align=left' );
		$view->printView( $scr );
	}
	 
	if( $view = $self->{views}->{VIEW_SETS} ) {
		$scr->doLine( );	
		$scr->openRow();
		$scr->openCell( 'align=center' );
		$view->printView( $scr );
	}
	
	$self->{SCR}->closePage();
	return '';
}

1;
