#!/usr/bin/perl
use strict;
use warnings;

use lib "/usr/local/tobin/lib";

use Tobin::IF;
use Visual::DotGen;
use Time::HiRes;

my $pid			= $$;
my $arguments	= {};

foreach( @ARGV ) {
	m/^--([^=]+)=(.*)$/ || die $_;
	$arguments->{$1} = $2;
}

defined( $arguments->{output} )	|| die();
defined( $arguments->{target} )	|| die();
defined( $arguments->{id} )		|| die();
defined( $arguments->{level} )	|| die();
defined( $arguments->{size} )	|| ( $arguments->{size} = "medium" );

my $size;
#my $startTime	= Time::HiRes::time();
my $tobin		= new Tobin::IF();
my $dotgen		= new Visual::DotGen(	{	TOBIN => $tobin } );
my $dataMatrix	= $tobin->transformationsetGet( $arguments->{id} );
my $elapsedTime;
my $target;

if( $arguments->{size} eq 'large' ) {
	$size = "24,18";
}
elsif( $arguments->{size} eq 'small' ) {
	$size = "4,3";
}
else {
	$size = "8,6";
}

if( $arguments->{target} =~ m/^(\d+)([A-Z|a-z|_]+)([+-z]+)$/ ) {
	if( $2 eq $tobin->{CONST}->{MY_TRANSF} ) {
		$target = [ 't', $1 ];
	}
	elsif( $2 eq $tobin->{CONST}->{MY_COMP} ) {
		$target = [ 'c', $1, $3 ];
	}
	else{
		$tobin->{HLP}->suicide( "$arguments->{target}" );
	}
}
else {
	$tobin->{HLP}->suicide( "$arguments->{target}" );
}
#warn "@{$target}";


$dotgen->createDot( $dataMatrix, "$arguments->{output}.dot", [ @{$target}, $arguments->{level} ], [ 'SHOWFBA' ] );

system( "/usr/local/bin/dot -Gsize=$size -Tgif	-o$arguments->{output}.gif $arguments->{output}.dot" );
system( "/usr/local/bin/dot -Gsize=$size -Timap_np	-o$arguments->{output}.map $arguments->{output}.dot" );
unlink( "arguments->{path}/$arguments->{output}.dot" );
