#!/usr/bin/perl -I.
use strict;
use warnings;
use Tobin::IF;
@ARGV<4&&die("Too few parameters.");
my $tobin		= new Tobin::IF(1);
my $tf=$tobin->transformationGet($ARGV[0]);
my $errs=[];
$tf->[2]->[0]->{sto}=$tf->[2]->[0]->{sto}<0?$tf->[2]->[0]->{sto}-1:$tf->[2]->[0]->{sto}+1;
$tobin->transformationAdd(@ARGV==5?$ARGV[4]:$ARGV[1],
[{user=>$ARGV[2],link=>$ARGV[3]}],$tf->[2],[$ARGV[1]],$errs);
