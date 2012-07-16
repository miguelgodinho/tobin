# (C) Miguel Godinho de Almeida - miguel@datindex.com 2004
package Rapido::SimulAccessor;

use strict;
use warnings;
use Rapido::TaskAccessor;
use vars qw( @ISA );

@ISA = qw( Rapido::TaskAccessor );

sub simulSchedule {
	my $self		= shift;
	my $app			= shift;
	my $setup		= shift;
	my $owner		= shift;
	my $date		= shift;
	my $dba			= $self->{DBA};
	my $priority	= 2;
	my $model		= $self->{CONST}->{MODELS}->{$app};
	my $dateToStore;
	my $options;
	my $simulationN;
	my $taskN;
	
	$self->{MEM}	|| $self->{HLP}->suicide();
	$model			|| $self->{HLP}->suicide();
	$date ? ( $dateToStore = $date ) : ( $dateToStore = 'NOW()' );
		
	
	$simulationN	= $dba->insertRecord( $model->{RESULT}, undef, [ 'EMPTY' ] );
	$options		= "--setup=$setup --uid=$owner --simul=$simulationN";
	$taskN			= $self->scheduleTask( $date, $priority, $model->{APP}, $options );
	
	return $simulationN;
}

sub setupsAndResults {
	my $self			= shift;
	my $setupEntity		= shift;
	my $mem				= $self->{MEM};
	my $setupOwnerChild	= $setupEntity.'_'.$mem->{CONST}->{USER_PARENT};
	my $setups			= [];
	my $setup;
	my $result;
	my $resultEntity;
	my $model;
	my $tmpData;
	my $setupDef;
	my $resultStatus;
	my $modelName;
	my $pos;
	my $setupData;
	
	$mem	|| $self->{HLP}->suicide( "This method requires object initialized with reference to MEM" );
	
	$pos = 0;
	foreach $setup ( @{$mem->entityList( $setupEntity )} ) {
		$tmpData		= $mem->entryConstDataGet( $setupEntity, $setup );
		$setupDef		= $mem->entryDefsGet( $setupEntity, $setup, [ 'MAIN' ] );
		$setups->[$pos] = {
			ID		=> $setup,
			DEF		=> $setupDef,
			OWNER	=> $tmpData->{$setupOwnerChild}->[0]->[0],
			RESULTS	=> []
		};
		$setupData = $setups->[$pos];
		
		foreach $model ( @{$mem->{CONST}->{PARENTS}->{$setupEntity}->{MODELS}} ) {
			$modelName		= $mem->{CONST}->{MODELS}->{$model}->{NAME};
			$resultEntity	= $mem->{CONST}->{MODELS}->{$model}->{RESULT};		
			foreach $result ( @{$mem->entityList( $resultEntity, 0, $resultEntity.'_'.$setupEntity, $setup )} ) {
				$resultStatus = $mem->entryDefsGet( $resultEntity, $result, [ 'MAIN' ] );
				push( @{$setupData->{RESULTS}}, { MODEL => $model, ID => $result, DATE => '000000', OWNER => '1', STATUS => $resultStatus }  );
			}
		}
		$pos++;	
	}
	return $setups;
}
1;
