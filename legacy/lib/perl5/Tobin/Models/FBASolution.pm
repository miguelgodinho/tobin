#   Copyright 2011 Miguel godinho - m@miguelgodinho.com
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.

# Wrapped from a script written by Jacek Puchalka


use strict;
use warnings;

package Tobin::Models::FBASolution;
use base qw( Tobin::PooledDBAccessorClient );

#use Hash::Util qw( lock_hashref_recurse );

use Carp qw( confess );
use Data::Dumper;
use POSIX;
use Readonly;

use Tobin::SQLAccessor;

Readonly my $USER_ID => $ENV{TOBIN_USER_ID};# or confess(Duper(\%ENV));

Readonly my $FLUXES_HEADER_REGEX => qr{\AActual values of the variables:\z};
Readonly my $OBJ_REGEX => qr{\AValue of objective function: ([\d|\.]+)\z};

Readonly::Array my @BELONGS_TO => qw( problem );


Readonly my $IDS_TABLE => 'fba';

Readonly::Hash my %MAPPINGS => (
  wall => {
    table    => 'fba_elapsed',
    relation => 'has_one',
    default  => '0'
  },

  created_at => {
    table    => 'fba_date',
    relation => 'has_one'
  },

  objective  => {
    table    => 'fba_status',
    relation => 'has_one',
    default  => 'pending'
  },

  user_id => {
    table    => 'fba_u',
    relation => 'has_one',
    default  => $USER_ID
  },

  legacy_fluxes => {
    table    => 'fba_fluxes',
    relation => 'has_many',
    cols     => {
      id      => 'p',
      keys    => 'x0',
      values  => 'x1'
    }
  }
);
#lock_hashref_recurse($LEGACY_MAPPINGS);


# Parameters:
# [template] - hash
# [problem] - lazy loaded (based on problem_id), if not passed.
sub new {
  my ($class, $problem, $template) = @_;

  my $self = $template || {};

  confess("a _problem_ obj isn't expec. in the template") if $self->{problem};


  bless($self, $class);
  $self->{problem}       = $problem; # or lazy loaded if undef
  $self->{objective}     //= undef; #takes a float
  $self->{fluxes}        //= undef; #takes a hasharray
  $self->{legacy_fluxes} //= undef; #declared here for the sake of doc
  $self->{id}            //= 0;
  $self->{created_at}    //= POSIX::strftime("%Y-%m/-%d %H:%M:%S", localtime);
  $self->{user_id}       //= $USER_ID;

  $self->_init_problem_id;

  return $self;
}


# problem or problem_id, at least one of them must be defined
sub _init_problem_id {
  my ($self) = @_;

  my $problem = $self->{problem}; # can be undef

  if (my $problem_id = $self->{problem_id}) {
    confess if (defined($problem) && $problem->get_id ne $problem_id);
  } else {
    $self->{problem_id} = $problem->get_id;
  }
}


# Factory
sub load {
  my ($class, $id) = @_;

  #TODO - load legacy_fluxes and convert them rev fluxes
  die 'ni';
}


# Factory
# Parameters:
# * text - a multiline string as generated by lp_solve
sub create_from_lp_solve_output {
  my ($class, $problem, $text) = @_;

  my $result = fn_parse_solver_output($text);

  my $self = $class->new($problem, $result);

  return $self;
}


sub _init_legacy_fluxes {
  my ($self) = @_;

  confess if $self->{legacy_fluxes};
  my $legacy_fluxes = $self->{legacy_fluxes} = {};
  my $fluxes = $self->get_fluxes;
  my @solved_transformation_ids = keys(%{$fluxes});
  foreach my $transformation_id (@solved_transformation_ids) {
    $self->set_legacy_flux_for_transformation_id($transformation_id);
  }
}


# legacy can only have positive fluxes
sub set_legacy_flux_for_transformation_id {
  my ($self, $transformation_id) = @_;

  my $problem        = $self->get_problem            or confess;
  my $revset_hashref = $problem->get_revset_hashref  or confess;
  my $fluxes         = $self->get_fluxes             or confess;
  my $flux           = $fluxes->{$transformation_id} // confess;

  my $legacy_fluxes = $self->{legacy_fluxes} or confess(Dumper($self));

  if ($flux < 0 ) {
    confess($transformation_id) unless $transformation_id ~~ $revset_hashref;
    $legacy_fluxes->{$transformation_id} = 0;
  } else {
    $legacy_fluxes->{$transformation_id} = $flux;
  }

  if (my $rev_transformation_id = $revset_hashref->{$transformation_id}) {
    # the (non-legacy) fluxes should not be assigned to redund. transf.
    confess($rev_transformation_id) if $rev_transformation_id ~~ $fluxes;

    $legacy_fluxes->{$rev_transformation_id} = ($flux > 0 ) ? 0 : -$flux;
  }
}


sub fn_parse_solver_output {
  my ($text) = @_;

  my $out = {objective => undef, fluxes => {}};

  my @lines = split("\n", $text);
  confess($_) if shift(@lines);

  my $obj_line = shift(@lines);
  confess($obj_line) unless $obj_line =~ $OBJ_REGEX;
  $out->{objective} = $1 // confess($obj_line);

  confess($_) if shift(@lines);
  confess($_) unless shift(@lines) =~ $FLUXES_HEADER_REGEX;

  my $fluxes = $out->{fluxes};
  foreach my $flux_txt (@lines) {
    my ($transformation_ac, $flux) = split(' ', $flux_txt);
    $transformation_ac =~ /\AR0*(\d+)\z/ or confess($flux_txt);
    my $transformation_id = $1;
    confess(Dumper($out)) if $transformation_id ~~ $fluxes;
    $fluxes->{$transformation_id} = $flux;
  }

  return $out;
}


sub get {
  my ($self, $attr) = @_;

  # For safety, indirect getters are restricted. May be extended.
  confess unless $attr ~~ %MAPPINGS;

  return $self->{$attr};
}



sub get_fluxes {
  my ($self) = @_;

  return $self->{fluxes};
}

sub get_ids_table {
  my ($class) = @_;

  return $IDS_TABLE;
}


sub get_mappings_ref {
  my ($class) = @_;

  return \%MAPPINGS;
}


sub get_objective_value {
  my ($self) = @_;

  return $self->{objective};
}

sub save {
  my ($self) = @_;

  confess('cannot be updated') if $self->get_id;

  my $problem = $self->get_problem;
  my $problem_id = $problem->get_id;
  confess('problem_id mismatch') if $problem_id ne $self->{problem_id};

  $self->_init_legacy_fluxes;

  my $db = $self->get_db_conn;
  $db->save_entry($self);
}



sub get_problem {
  my ($self) = @_;

  if (my $problem = $self->{problem}) {
    return $problem;
  } elsif (my $problem_id = $self->{problem_id}) {
    #TODO instanciate an object [lazy load]
    confess('ni');
  } else {
    return undef;
  }
}


sub get_id {
  my ($self) = @_;

  return $self->{id};
}


sub set_id {
  my ($self, $id) = @_;

  confess if $self->{id};
  confess($id) unless $id =~ /\A[1-9]\d*\z/;
  $self->{id} = $id;
}

1;
