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

package Tobin::Models::FBAProblem;
use base qw( Tobin::PooledDBAccessorClient );

use Carp qw( confess );
use Clone qw( clone );
use Data::Dumper;
use IPC::Run qw( run timeout );
use Readonly;

use Tobin::IF;

use Tobin::Models::ReversibilitiesSet;

use Tobin::Models::FBASolution;
use constant Solution => 'Tobin::Models::FBASolution';

use constant RevSet => 'Tobin::Models::ReversibilitiesSet';

use constant LEGACY_MAXIMIZATION => 2;
use constant LEGACY_MINIMIZATION => 1;

use constant SOLVER_TIMEOUT => 10; #seconds for the solver
use constant SOLVER_EXEC => 'lp_solve';

Readonly my $LINE_TERM => ";\n";
Readonly my $DEF_SOLVER_ERR_MSG => 'solver failure';

Readonly::Array my @HAS_MANY => qw( solutions );
Readonly::Array my @DB_CONN_CLIENTS => qw( Tobin::Models::FBASolution );

Readonly::Hash my %MAPPINGS => (
  solution_ids => {
    relation  => 'has_many',
    table => 'fba_a',
    cols  => {
      id => 'x0',
      0 => 'p'
    }
  }
);


# Parameters
sub new {
  my ($class) = @_;

  my $self = { id                => undef,
              revset             => undef,
              header             => undef,
              balances           => undef,
              bounds             => undef,
              free               => undef,
              last_solver_error  => undef,
              solution_ids       => []     };

  bless($self, $class);

  return $self;
}


# Factory
sub load {
  my ($class, $id) = @_;

  confess("a setup id is required") unless $id;

  my $self = $class->new;
  $self->set_id($id);

  my @out = ();
  my $line = '';

  my $revset   = $self->get_revset // confess(Dumper($self));
  my $rev_hash = $revset->to_hashref;

  my $tobin = new Tobin::IF(1);
  my $setup = $tobin->fbasetupGet($id);

  my $skip={};
  my $objective;
  my $cpd_hash={0=>{},1=>{}};
  my $tf_hash={};
  my $free_hash={};

  # check for each reaction if its products are included into the objective function (???jacek)
  foreach(@{$setup->{TFSET}}) {
    defined($skip->{$_->[0]})&&next;
    defined($rev_hash->{$_->[0]})&&($_->[0]<$rev_hash->{$_->[0]}?
    ($skip->{$rev_hash->{$_->[0]}}=1):next);
    $tf_hash->{$_->[0]}={};
    my $tf=$tobin->transformationGet($_->[0]);
    if($_->[1]!=0) {
      $objective = ($setup->{TYPE} == LEGACY_MAXIMIZATION) ? $_->[0] : -$_->[0];
    }
    $_->[2]>0&&($tf_hash->{$_->[0]}->{min}=$_->[2]);
    defined($_->[3])&&($tf_hash->{$_->[0]}->{max}=$_->[3]);
    foreach my $cpd(@{$tf->[2]}) {
      defined($cpd_hash->{$cpd->{ext}}->{$cpd->{id}})||
      ($cpd_hash->{$cpd->{ext}}->{$cpd->{id}}={});
      $cpd_hash->{$cpd->{ext}}->{$cpd->{id}}->{$_->[0]}=$cpd->{sto};
    }
  }

  # checks for minimal & maximal verlocities
  foreach(@{$setup->{TFSET}}) {
    defined($skip->{$_->[0]})||next;
    if($_->[1]!=0) {
      $objective = ($setup->{TYPE} == LEGACY_MAXIMIZATION) ? -$rev_hash->{$_->[0]}
                                                         : $rev_hash->{$_->[0]};
    }
    if($_->[2]>0) {
      if(defined($tf_hash->{$rev_hash->{$_->[0]}}->{min})||
      (defined($tf_hash->{$rev_hash->{$_->[0]}}->{max})&&
      $tf_hash->{$rev_hash->{$_->[0]}}->{max}>0)) {
        die("Tf $_->[0] - inconsistency in limits");
      }
      else {
        $tf_hash->{$rev_hash->{$_->[0]}}->{max}=-$_->[2];
      }
    }
    if(defined($_->[3])) {
      if(defined($tf_hash->{$rev_hash->{$_->[0]}}->{min})&&
      $tf_hash->{$rev_hash->{$_->[0]}}->{min}>0) {
        die("Tf $_->[0] - inconsistency in limits");
      }
      else {
        $tf_hash->{$rev_hash->{$_->[0]}}->{min}=-$_->[3];
      }
    }
  }
  foreach(keys(%{$tf_hash})) {
    if(defined($rev_hash->{$_})) {
      defined($tf_hash->{$_}->{max})&&!defined($tf_hash->{$_}->{min})&&
      ($tf_hash->{$_}->{min}=-1e30);
      !defined($tf_hash->{$_}->{min})&&!defined($tf_hash->{$_}->{max})&&
      ($free_hash->{$_}=1);
    }
  }

  my $header = ($objective<0?"min: ":"")."R".sprintf("%04d",abs($objective));

  my @balances = ();
  foreach my $ext (keys(%{$cpd_hash})) {
    foreach my $cpd (keys(%{$cpd_hash->{$ext}})) {
      my $line = ($ext>0?"EX_":"")."C".sprintf("%04d",$cpd).": ";
      foreach(keys(%{$cpd_hash->{$ext}->{$cpd}})) {
        $line .= (($cpd_hash->{$ext}->{$cpd}->{$_}>0?"+":"").
        $cpd_hash->{$ext}->{$cpd}->{$_}." R".sprintf("%04d",$_)." ");
      }
      $line .= "= 0";
      push(@balances, $line);
    }
  }
  confess(Dumper($self)) unless @balances;


  my @bounds = ();
  foreach(keys(%{$tf_hash})) {
    if(defined($tf_hash->{$_}->{min})) {
      push(@bounds, "R".sprintf("%04d",$_)." >= ".$tf_hash->{$_}->{min});
    }
    if(defined($tf_hash->{$_}->{max})) {
      push(@bounds, "R".sprintf("%04d",$_)." <= ".$tf_hash->{$_}->{max});
    }
  }
  confess(Dumper($self)) unless @bounds;


  my $free = 'free ';
  foreach(keys(%{$free_hash})) {
    $free.="R".sprintf("%04d",$_).",";
  }
  chop($free);


  confess(Dumper($self)) if $self->{header};
  $self->{header} = $header;

  confess(Dumper($self)) if $self->{balances};
  $self->{balances} = \@balances;

  confess(Dumper($self)) if $self->{bounds};
  $self->{bounds} = \@bounds;

  confess(Dumper($self)) if $self->{free};
  $self->{free} = $free;

  return $self;
}



sub get_last_solver_error {
  my ($self) = @_;

  return clone($self->{last_solver_error});
}


sub get_revset {
  my ($self) = @_;

  unless ($self->{revset}) {
    my $fba_setup_id = $self->get_id or confess(Dumper($self));
    my $revset = RevSet->create_from_fba_setup($fba_setup_id);
    $self->{revset} = $revset;
  }
}



sub set_id {
  my ($self, $id) = @_;

  confess(Dumper($self)) if $self->{id};
  $self->{id} = $id;
}


sub get_id {
  my ($self) = @_;

  return $self->{id};
}


sub get_revset_hashref {
  my ($self) = @_;

  if (my $revset = $self->get_revset) {
    return $revset->to_hashref;
  } else {
    return {};
  }
}


sub register_solution {
  my ($self, $solution) = @_;

  my $solution_ids = $self->{solution_ids} or confess(Dumper($self));
  my $solution_id   = $solution->get_id     or confess(Dumper($solution));
  confess(Dumper($self)) if $solution_id ~~ $solution_ids;

  push(@{$solution_ids}, $solution_id);

  my $id = $self->get_id or confess(Dumper($self));
  my $attr_properties = $MAPPINGS{solution_ids} or confess(Dumper(\%MAPPINGS));
  my $table = $attr_properties->{table};
  my $cols  = $attr_properties->{cols};

  my $db = $self->get_db_conn;
  $db->insert_single($id, $solution_id, $table, $cols);
}


sub solve {
  my ($self) = @_;

  my $revset = $self->{revset} // confess(Dumper($self));

  my $in = $self->to_lp();
  my $out = '';
  my $err = '';


  my $ok = run [SOLVER_EXEC], \$in, \$out, \$err, timeout(SOLVER_TIMEOUT);

  if ($err) {
    warn(Dumper($err));
    $self->{last_solver_error} = $err;
    $self->{last_solver_solution} = undef;
  } elsif ($ok) {
    warn(Dumper($err)) if $err;
    $self->{last_solver_error} = $err;

    my $solution = Solution->create_from_lp_solve_output($self, $out);
    $self->{last_solver_solution} = $solution;
    $solution->save;
    $self->register_solution($solution);

  } else {
    $out ||= $DEF_SOLVER_ERR_MSG;
    $self->{last_solver_error} = $out;
    $self->{last_solver_solution} = undef
  }

  return $self->{last_solver_solution};
}


sub to_lp {
  my ($self) = @_;

  my $header   = $self->{header}   // confess(Dumper($self));
  my $balances = $self->{balances} // confess(Dumper($self));
  my $bounds   = $self->{bounds}   // confess(Dumper($self));
  my $free     = $self->{free}     // confess(Dumper($self));


  my $out = $header . $LINE_TERM;
  $out .= "\n"; # separates blocks, just formatting
  $out .= join($LINE_TERM, @{$balances}, ''); #empty str to terminate last el
  $out .= "\n"; # separates blocks, just formatting
  $out .= join($LINE_TERM, @{$bounds}, ''); #empty str to terminate last el
  $out .= "\n"; # separates blocks, just formatting
  $out .= $free . $LINE_TERM;

  return $out;
}


1;
