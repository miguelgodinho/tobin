#!/usr/bin/perl
use strict;
use warnings;

my $pid;
my $app = shift( @ARGV );
my $args;
$SIG{CHLD} = 'IGNORE';
$app || exit;
if ( $pid = fork( ) ) {
  print "$pid";
  exit 0;
}
elsif ( defined( $pid ) ) {
  close ( STDOUT );
  exec( $app, @ARGV );
  exit 0;
}
else {
  exit 1;
}
