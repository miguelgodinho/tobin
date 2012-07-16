# (C) Miguel Godinho de Almeida - miguel@datindex.com 2005
package WebArc::Broker;

use strict;
use warnings;

sub new {
	my $param	= shift;
	my $self	= shift;
	my $class	= ref( $param ) || $param;
	bless( $self, $class );

	$self->{HLP}	|| die();
#	$self->{MEM}	|| $self->{HLP}->suicide();
	$self->{CONST}	|| $self->{HLP}->suicide();
	$self->{app}	|| $self->{HLP}->suicide();
	$self->{frm}	|| $self->{HLP}->suicide();
	
	$self->{views}		= {};
	$self->{mailbox}	= {};
	$self->{scripts}	= {};
	
	return $self;
}

sub getData {
	my $self	= shift;
	
	return $self->{MEM}->appDataGet( $self->{app} );
}

sub getForm {
	my $self	= shift;
	
	if( $self->{frm}->{$self->{app}} ) {
		return( $self->{frm}->{$self->{app}} );
	}
	else {
		return( { submitKey => [], submitValue => '' } );
	}
}

sub messagesClear {
	my $self	= shift;
	delete( $self->{mailbox}->{$self->{app}} );
}

sub messagesGet {
	my $self	= shift;
	return $self->{mailbox}->{$self->{app}};
}

sub messageSend {
	my $self	= shift;
	my $to		= shift;
	my $subject	= shift;
	my $msg		= shift;
	my $from	= $self->{app};
	my $msgType	= ref( $msg );
	
	$self->{mailbox}->{$to}->{$from}->{$subject} && $self->{HLP}->suicide( "Message to:$to with subject:$subject has already been sent" );
	if( !$msgType ) {
		$self->{mailbox}->{$to}->{$from}->{$subject} = $msg;
#		warn( "$to; $from; $subject" );
	}
	elsif( ref( $msg ) eq 'ARRAY' ) {
		$self->{HLP}->stoArray( $self->{mailbox}->{$to}->{$from}->{$subject}, $msg );
	}
	elsif( ref( $msg ) eq 'HASH' ) {
		$self->{HLP}->stoHash( $self->{mailbox}->{$to}->{$from}->{$subject}, $msg );
	}
	else {
		$self->{HLP}->suicide( $msgType );
	}
}

sub getRefreshTime {
	my $self	= shift;
	
	$self->{refresh_time} ? return( $self->{refresh_time} ) : return( 0 );	
}

sub setRefreshTime {
	my $self	= shift;
	my $seconds	= shift;
	
	if ( !$self->{refresh_time} || ( $self->{refresh_time} > $seconds ) ) {
		$self->{refresh_time} = $seconds;
	}
}

sub registerView {
	my $self	= shift;
	my $code	= shift;
	my $type	= shift;
	
	$self->{views}->{$code} && $self->{HLP}->suicide();
	$self->{views}->{$code} = $type;
	$self->setScript( $type );
}	

sub setScript {
	my $self	= shift;
	my $code	= shift;
	
	$self->{scripts}->{$code} = 1;
}

1;
