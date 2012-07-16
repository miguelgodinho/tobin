#!/usr/bin/env perl

# based on a script written by Jacek Puchalka

use strict;
use warnings;

use Carp;
use Data::Dumper;
use Readonly;

BEGIN {
  $ENV{'TOBIN_USER_ID'} = 1;
  $ENV{TOBIN_INSTANCE} //= 'tobinju';
  $ENV{TOBIN_DB_HOST} //= 'localhost';
  $ENV{TOBIN_DB_DATA} //= 'tobinju';
  $ENV{TOBIN_DB_USER} //= 'tobin';
  $ENV{TOBIN_DB_PASS} //= 'tobin007gbf';
  $ENV{PATH}          .= ":/opt/local/bin";
}


use lib '/opt/tobin/lib/perl5';

use Tobin::Models::FBAProblem;

my $setup_id = $ARGV[0] or confess ('setup id is req arg');

if ($setup_id =~ /\A--setup=(\d+)/) {
  $setup_id = $1;
}

my $DEBUG = ('--debug' ~~ @ARGV);

my $fba = Tobin::Models::FBAProblem->load($setup_id);

if (my $solution = $fba->solve) {
  print $DEBUG ? Dumper($solution) : $solution->get_objective_value;
} else {
  warn $fba->get_last_solver_error
}
