#!/usr/bin/perl
use strict;
use warnings;

use Tobin::IF;
use Visual::DotGen;

my $tobin		= new Tobin::IF();
my $dotgen		= new Visual::DotGen(	{	TOBIN => $tobin } );
my $dataMatrix	= $tobin->transformationsetGet( 11 );

$dotgen->createDot( $dataMatrix,"", "dummy.dot",['c',27,0,0],['SHOWFBA']);


