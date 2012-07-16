# (C) Miguel Godinho de Almeida - miguel@gbf.de 2004
package Tobin::Domain;

use strict;
use warnings;
use vars qw( @ISA );
use Tobin::functions;
use WebArc::Domain;
@ISA = qw( WebArc::Domain );

my $OK         = Apache2::Const::OK // confess;
my $DECLINED   = Apache2::Const::DECLINED // confess;
my $DONE       = Apache2::Const::DONE // confess;


sub handler {
  my $r			= shift;
  my $constants	= Tobin::functions::constantsGet();
  my $domain;



  ( $r && $ENV{MOD_PERL} ) || ( return $DECLINED );


  # Turn itself into an object ( by calling base class constructor )
  $domain	= new Tobin::Domain( {	APX				=> $r,
                  CONST			=> $constants,
                  FcnChildUpdate	=> \&Tobin::functions::childUpdate,
                  FcnEntityCheck	=> \&Tobin::functions::entityCheck,
                  FcnEntryDelete	=> \&Tobin::functions::entryDelete,
                  FcnEntryRecycle	=> \&Tobin::functions::entryRecycle,
                  FcnEntrySave	=> \&Tobin::functions::entrySave,
                  FcnExtLinkGet	=> \&Tobin::functions::extLinkGet 		} );

    # Run the application
    $domain->run() && return( $OK );

  return $DONE;
}

sub appGet {
  my $self	= shift;
  my $code	= shift;
  my $app;

  $self->{BRO}->{app} = $code;
  if( $code eq 'valid' ) {
    require WebArc::Valid;
    $app = new WebArc::Valid(			{ BRO => $self->{BRO}, SCR => $self->{SCR} } );
  }
  elsif( $code eq 'pman' ) {
    require WebArc::AppProcessMan;
    $app = new WebArc::AppProcessMan(	{ BRO => $self->{BRO}, SCR => $self->{SCR} } );
  }
  elsif( $code =~ m/^man0(a|fba)$/ ) {
    $self->{BRO}->{app} = 'mman0a';
    require WebArc::AppModelManager;
    $app = new WebArc::AppModelManager(	{ BRO => $self->{BRO}, SCR => $self->{SCR} } );
  }
  elsif( $code =~ m/^mman/ ) {
    require WebArc::AppModelManager;
    $app = new WebArc::AppModelManager(	{ BRO => $self->{BRO}, SCR => $self->{SCR} } );
  }
  elsif( $code =~ m/^edi/ ) {
    require WebArc::AppEditor;
    $app = new WebArc::AppEditor(		{ BRO => $self->{BRO}, SCR => $self->{SCR} } );
  }
  elsif( $code =~ m/^man/ ) {
    require WebArc::AppManager;
    $app = new WebArc::AppManager(		{ BRO => $self->{BRO}, SCR => $self->{SCR} } );
  }
  elsif( $code =~ m/^map\d/ ) {
    require WebArc::AppGraph;
    $app = new WebArc::AppGraph(		{ BRO => $self->{BRO}, SCR => $self->{SCR} } );
  }
  else {
    require WebArc::AppInitial;
    $self->{BRO}->{app} = $self->{CONST}->{DOMAIN_APP_PUBLIC};
    $app = new WebArc::AppInitial(		{ BRO => $self->{BRO}, SCR => $self->{SCR} } );
  }
  return $app;
}

1;
