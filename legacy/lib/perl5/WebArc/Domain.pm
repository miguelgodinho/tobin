# (C) Miguel Godinho de Almeida - miguel@gbf.de 2004
package WebArc::Domain;

use strict;
use warnings;

use WebArc::Display;
use WebArc::Broker;
use Rapido::General;
use CGI;
use CGI::Session qw/-api3/;
use Apache2::RequestRec();
use Apache2::RequestIO();

eval {
  use Apache2::Const -compile => qw(OK DECLINED DIR_MAGIC_TYPE DONE);
};
if( $@ ) {
  die "Module is not installed\n";
}

sub new {
  my $param	= shift;
  my $self 	= shift;;
  my $class 	= ref( $param ) || $param;
  my $app;
  my $fcns;
  my $memData;

  bless( $self, $class );

  $self->{CONST}->{DEBUG}		|| ( $self->{DEBUG} = 0 );
  $self->{HLP}				= new Rapido::General(	{ DEBUG => $self->{DEBUG}	} );
  $self->{APX} 				? ( $self->{CGI} = new CGI( $self->{APX} ) ) : ( $self->{CGI} = new CGI() );
  $self->{SESSION}			= new CGI::Session( undef, $self->{CGI}, { Directory=> "$self->{CONST}->{SESSID_PATH}" } );

  $self->{closed}				= 0;
  $self->{frm}				= {};
  $self->{apps}				= {};

  $self->{FcnChildUpdate}		|| $self->{HLP}->suicide();
  $self->{FcnEntityCheck}		|| $self->{HLP}->suicide();
  $self->{FcnEntryDelete}		|| $self->{HLP}->suicide();
  $self->{FcnEntryRecycle}	|| $self->{HLP}->suicide();
  $self->{FcnEntrySave}		|| $self->{HLP}->suicide();
  $self->{FcnExtLinkGet}		|| $self->{HLP}->suicide();


  if( ( $app = $self->_processForm() ) || ( $app = $self->{SESSION}->param( 'lastapp' ) ) ) {
    $self->headersPlusCookiePrint();
    $self->{MEM} = $self->memoryObjGet();
    if( $self->{MEM}->{USR} ) {
      $self->{SESSION}->param( 'lastapp', $app );
    }
    else {
      $app = $self->{CONST}->{DOMAIN_APP_PUBLIC};
    }
  }
  else {
    $app = $self->{CONST}->{DOMAIN_APP_PUBLIC};
    $self->headersNoCookiePrint();
    $self->{MEM} = undef;
  }

  $self->{BRO}	= new WebArc::Broker(	{	HLP		=> $self->{HLP},
                        MEM		=> $self->{MEM},
                        CONST	=> $self->{CONST},
                        frm		=> $self->{frm},
                        app		=> $app				} );
  $self->{SCR}	= new WebArc::Display(	{ BRO => $self->{BRO}			} );

  return $self;
}

sub headersNoCookiePrint {
  my $self	= shift;

  if( $self->{APX} ) {
    $self->{APX}->content_type( 'text/html' );
  }
  else {
    print "Content-Type: text/html\n\n";
  }
}

sub headersPlusCookiePrint {
  my $self	= shift;
  my $cookie 	= $self->{CGI}->cookie( CGISESSID => $self->{SESSION}->id() );

  if ( $self->{APX} ) {
    $self->{APX}->headers_out->set( "Set-Cookie" => $cookie );
    $self->{APX}->content_type( "text/html" );
  }
  else {
    print $self->{CGI}->header( -type=>'text/html', -cookie=>$cookie );
  }
}

sub memoryObjGet {
  my $self	= shift;
  my $memData;
  my $mem;

  require Rapido::Memory;

  unless( $memData = $self->{SESSION}->param( 'mem_data' ) ) {
    $self->{SESSION}->param( 'mem_data', {} );
    $memData = $self->{SESSION}->param( 'mem_data' );
  }

  $mem = new Rapido::Memory(	{	data			=> $memData,
                  DEBUG			=> $self->{DEBUG},
                  HLP				=> $self->{HLP},
                  CONST			=> $self->{CONST},
                  FcnChildUpdate	=> $self->{FcnChildUpdate},
                  FcnEntityCheck	=> $self->{FcnEntityCheck},
                  FcnEntryDelete	=> $self->{FcnEntryDelete},
                  FcnEntryRecycle	=> $self->{FcnEntryRecycle},
                  FcnEntrySave	=> $self->{FcnEntrySave},
                  FcnExtLinkGet	=> $self->{FcnExtLinkGet} } );
  return $mem;
}

sub _printString {
  my $self	= shift;
  my $string	= shift;

  $self->{APX} ? $self->{APX}->print( $string ) : print( $string );
}

sub pagePrint {
  my $self				= shift;
  my $body				= $self->{SCR}->{SCR};
  my $refresh				= $self->{BRO}->getRefreshTime();
  my $ext_scripts_str		= '';
  my $inline_script_str	= "<script type='text/javascript'>\n<!--";
  my $refresh_str			= "<meta http-equiv='refresh' content='$refresh'>";
  my $no_cache_str		= "<meta http-equiv='Pragma' content='no-cache'>";
  my $expire_str			= "<meta http-equiv='Expires' CONTENT='0'>";
  my $code;
  my $script;

  $self->{SCR}->validate();

  # Create tags to include js libs
  foreach ( keys( %{$self->{BRO}->{scripts}} ) ) {
    $ext_scripts_str .=	"<script type='text/javascript' src='$_'>"
              ."</script>";
  };

  # Create tags to call the inline script corresponding to each view
  while ( ( $code, $script ) = each %{$self->{BRO}->{views}} ) {
    $inline_script_str .= "\n$script"."_run('$code')";
  }
  $inline_script_str .= "//-->\n</script>\n";

  # Print the html
  $self->_printString(	"<html><head>"
              .$no_cache_str
              .$expire_str
  );
  $refresh && ( $self->_printString( $refresh_str ) );
  $self->_printString(	"<title>"
              .$self->{CONST}->{DOMAIN_TITLE}
              ."</title>"
              .$ext_scripts_str
              ."</head><body>"
              .$body
              ."\n"
              .$inline_script_str
              ."</body></html>\n"
  );

  # Close the page
  $self->{closed}	? $self->{HLP}->suicide()
          : ( $self->{closed} = $self->{MEM}->{USR} );
}

sub _processForm {
  my $self 	= shift;
  my $form	= $self->{frm};
  my $app		= '';
  my $code;
  my $row;
  my $id;
  my $param;
  my $submitValue;
  my $ref;
  my $i;
  my $j;
  my $key;
  my $value;

  foreach $param ( $self->{CGI}->param() ) {
    @{$row} = split( /&/, $param );
    $key = shift( @{$row} );
    if( $key eq 'app' ) {
      if( !$submitValue ) { # submit has priority determining the nxt app to url or hidden
        $value = $self->{CGI}->param( 'app' );
        ( $value =~ m/^(\w+)(\d*)(\w{0,1})$/ ) || $self->{HLP}->suicide( "processCGI - wrong format for value app - $code" );
        $app = $value;
        unless( $form->{$app} ) {
          $form->{$app}					= {};
          $form->{$app}->{submitKey}		= [];
          $form->{$app}->{submitValue}	= '';
        }
      }
    }
    elsif( $key eq 'submit' ) {
      unless( $submitValue ) {
#				warn "@{$row}";
        ( $app = shift( @{$row} ) ) || $self->{HLP}->suicide();
        if( $param =~ s/(\w+)\.(x|y)$/$1/ ) { # if submit is mapped image, then get coords
          $row->[$#{$row}] = $1;
          $submitValue = $self->{CGI}->param( $param.'.x' ).';'.$self->{CGI}->param( $param.'.y' );
        }
        else {
          $submitValue = 1;
        }

        $form->{$app}->{submitKey}		= [ @{$row} ];
        $form->{$app}->{submitValue}	= $submitValue;
      }
    }
    else {
      ( $key =~ m/^submit/ ) && $self->{HLP}->suicide( "submits are reserved keywords" );

      unless( $ref = $form->{$key} ) {
        $form->{$key}					= {};
        $form->{$key}->{submitKey}		= [];
        $form->{$key}->{submitValue}	= '';
        $ref							= $form->{$key};
      }

      $j = ( scalar( @{$row} ) - 1 );
      for( $i = 0; $i < $j; $i++ ) {
        ( $key =~ m/^submit/ ) && $self->{HLP}->suicide( "submits are reserved keywords" );
        $ref->{$row->[$i]} || ( $ref->{$row->[$i]} = {} );
        $ref = $ref->{$row->[$i]};
      }

      foreach( $self->{CGI}->param( $param ) ) {
        if( length() ) { #that that is is that that is not is not, or not?
          ( m/\000/ ) && $self->{HLP}->suicide( "NULL BYTE EXPLOIT!!! $self->{USR}" );
          if( defined( $ref->{$row->[$j]} ) ) {
            ref( $ref->{$row->[$j]} ) ? ( push( @{$ref->{$row->[$j]}}, $_ ) ) : ( $ref->{$row->[$j]} = [ $ref->{$row->[$j]}, $_ ] );
          }
          else {
            $ref->{$row->[$j]} = $_;
          }
        }
      }
    }
  }
  return $app;
}

sub run {
  my $self	= shift;
  my $app		= undef;
  my $appCode;
  my $newCode;

  $self->{CONST}->{BENCHMARK} && ( warn "BENCHMARK:OPEN:".time() );

  while( $appCode = $self->{BRO}->{app} ) {
    $app = $self->appGet( $appCode );
    $newCode = $app->run();
    ( $newCode eq $appCode ) && $self->{HLP}->suicide();
    $self->{BRO}->{app} = $newCode;
  }

  $self->pagePrint();
  return 1;
}

sub DESTROY {
  my $self	= shift;
  if ( $self->{SESSION} ) {
    $self->{closed} ? $self->{SESSION}->flush() : $self->{SESSION}->delete();
  }
}

1;
