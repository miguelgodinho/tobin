#!/usr/bin/perl -I. -w
use strict;
use warnings;

@ARGV<2&&die("Too few arguments");

use Tobin::Models::ReversibilitiesSet;
use constant RevSet => 'Tobin::Models::ReversibilitiesSet';

my $rev_set = undef;

if($ARGV[0]==0) {
  my $fba_setup_id = $ARGV[1];
  $rev_set = RevSet->create_from_fba_setup($fba_setup_id);
} elsif($ARGV[0]==1) {
  my $filepath = $ARGV[1];
  $rev_set = RevSet->create_from_reactions_file($filepath);
}

$rev_set->fetch_table_rows( sub {
  my ($col0, $col1) = @_;
  print "$col0\t$col1\n";
});
