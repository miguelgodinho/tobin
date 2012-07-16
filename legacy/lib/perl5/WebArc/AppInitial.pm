# (C) Miguel Godinho de Almeida - miguel@datindex.com 2004
package WebArc::AppInitial;

use strict;
use warnings;

sub new {
	my $param	= shift;
	my $self	= shift;
	my $class	= ref( $param ) || $param;
	bless( $self, $class );
	
	$self->{CONST}		= $self->{BRO}->{CONST};
	$self->{CODE}		= $self->{BRO}->{app};
	$self->{MEM}		= $self->{BRO}->{MEM};
	$self->{HLP}		= $self->{BRO}->{HLP};
	
	return $self;
}

sub processForm {
	my $self	= shift;
	my $form    = shift;
#	warn "POSTRUN";
	my $mem     = $self->{MEM};
    
	( $form->{pass} && $form->{user} ) || ( return( '' ) );
	if( $mem->userValidate( $form->{user}, $form->{pass} ) ) {
		$mem->protectedModeOff();
		$mem->{DBA}->insertRecord( 'log', {id => 0, app => 'login', user => "$mem->{USR}", msg => 'Login', date => 'NOW()'} );
		return $self->{CONST}->{DOMAIN_APP_PRIVATE};  
	}
	else { 
		$mem->{DBA}->insertRecord( 'log', {id => 0, app => 'login', msg => 'Invalid username or password format', date => 'NOW()'} );
		return '';  
	} 
}

sub run {
	my $self    = shift;
	my $scr     = $self->{SCR};
	my $mem     = $self->{MEM};
	my $form    = $self->{BRO}->getForm();
	my $newApp;
	
	$form->{submitValue} && ( $newApp = $self->processForm( $form ) ) && ( return $newApp );
	$mem->{USR} && $mem->{DBA}->insertRecord( 'log', { id => 0, app => 'login', user => "$mem->{USR}", msg => "logout", date => "NOW()" } ) && $mem->userSet( 0 );
	$scr->openPage();
	$scr->doLine( 'please login:' );
	$scr->openTable(2);
	$scr->doCell( 'username' );
	$scr->openCell();
	$scr->doEdit( "$self->{CODE}&user", '', 10 );
	$scr->openRow();
	$scr->doCell( 'password' );
	$scr->openCell();
	$scr->doPassword( "$self->{CODE}&pass", '', 10 );
	$scr->openRow();
	$scr->openCell();
	$scr->doSubmit( "$self->{CODE}&login", 'login' );
	$scr->closeTable();
	$scr->closePage();
	return '';
}
1;
