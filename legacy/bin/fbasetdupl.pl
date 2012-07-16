#!/usr/bin/perl -I. -w
use strict;
use warnings;
use Tobin::IF;

@ARGV<3&&die("Too few arguments");
my $tobin	= new Tobin::IF(1);
my $fbaset=$tobin->fbasetupGet($ARGV[0]);
$tobin=new Tobin::IF($ARGV[1]);
$tobin->fbasetupCreate($ARGV[2],$fbaset->{TFSET},$fbaset->{TYPE});
