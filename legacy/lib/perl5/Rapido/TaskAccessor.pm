# (C) Miguel Godinho de Almeida - miguel@datindex.com 2004
package Rapido::TaskAccessor;

use strict;
use warnings;

sub new {
  my $param 	= shift;
  my $self 	= shift;
  my $class 	= ref( $param ) || $param;
  bless( $self, $class );

  if( $self->{MEM} ) {
    $self->{HLP}	|| ( $self->{HLP} = $self->{MEM}->{HLP} );
    $self->{DBA}	|| ( $self->{DBA} = $self->{MEM}->{DBA} );
    $self->{CONST}	|| ( $self->{CONST} = $self->{MEM}->{CONST} );
  }
  else {
    $self->{HLP}	|| die( "no helper" );
    $self->{DBA}	|| $self->{HLP}->suicide();
    $self->{CONST}	|| $self->{HLP}->suicide();
  }

  $self->{tasks} = undef;

  return $self;
}

sub checkSlot {
  my $self		= shift;
  my $running		= shift;
  my $priority	= shift;
  my $caller		= shift;
  my $host		= "127.0.0.1";

  if( $priority < 2 ) {
    if( $self->{CONST}->{TASK_MAX_LOW} > $running->{$host}->{1} ) {
      return $host;
    }
    else {
      return '';
    }
  }

  if( ( $self->{CONST}->{TASK_MAX} > $running->{$host}->{0} ) ||
    ( ( $priority > 2  ) && ( ( $self->{CONST}->{TASK_MAX} + $self->{CONST}->{TASK_MAX_HIGH} ) > $running->{$host}->{0} ) ) ) {
    return $host;
  }
  return '';
}

sub fireTask {
  my $self		= shift;
  my $machine		= shift;
  my $caller		= shift;
  my $options		= shift;
  my $start		= $self->{CONST}->{TASK_FORKTRY};
  my $pid;

  defined( $options ) || $self->{HLP}->suicide();
  while( $start > 0 ) {
    $ENV{TEST0} = '0000';
    if( $pid = `$self->{CONST}->{TASK_FORKER} $caller $options` ) {
      return $pid;
    }
    $start--;
  }
  return 0;
}

sub isRunning {
  my $self	= shift;
  my $taskID	= shift;

#	warn "TASK ACCESSSOR";
#	my $key;
#	my $value;
#	while( ( $key, $value ) = each %{$self->{tasks}} ) {
#		warn "TASK: $key - $value";
#	}

  defined( $self->{tasks} ) || $self->refresh();
#	warn "checking for task $taskID";
  return $self->{tasks}->{$taskID};
}

sub getStatus {	#0=not found, 1=terminated, 2=sleeping, 3=waiting, 4=running
  my $self			= shift;
  my $caller			= shift;
  my $options			= shift;
  my $dba				= $self->{DBA};
  my $formatedOpt		= $dba->format( $self->{CONST}->{TASK_TBL}, 'options', $options, [] );
  my $data;

  $self->refresh();
  if( @{$data} = $self->{DBA}->getRow( "SELECT now(), date, epid, priority FROM $self->{CONST}->{TASK_TBL} WHERE caller='$caller' AND options=$formatedOpt" ) ) {
#		warn "@{$data}";
    if( $data->[0] le $data->[1] ) {
      return 2;
    }
    elsif( $data->[3] ) {
#			warn $data->[2];
      if( $data->[2] ) {
        return 4;
      }
      else {
        return 3;
      }
    }
    else {
      return 1;
    }
  }
  else {
    return 0;
  }
}

sub refresh {
  my $self		= shift;
  my $dba			= $self->{DBA};
  my $table		= $self->{CONST}->{TASK_TBL};
  my $running;
  my $tgt;
  my $epid;

  $dba->lockTables( { $table => 'WRITE' } );
  $running = $self->refreshRunningTasks();

  foreach( $dba->getMatrix( "SELECT ipid, priority, caller, options FROM $self->{CONST}->{TASK_TBL} WHERE epid IS NULL AND date<=NOW() ORDER BY priority DESC, date" ) ) {
    if( $tgt = $self->checkSlot( $running, $_->[1] ) ) {
      if( $epid = $self->fireTask( $tgt, $_->[2], $_->[3] ) ) {
        $running->{$tgt}->{0}++;
        $running->{$tgt}->{$_->[1]}++;
        $dba->updateRecord( $table, { ipid => $_->[0] }, { epid => "$tgt:$epid" } );
        $self->{tasks}->{$_->[0]} ? $self->{HLP}->suicide() : ( $self->{tasks}->{$_->[0]} = "$tgt:$epid" );
      }
    }
  }
  $dba->unlockTables();
}


sub refreshRunningTasks { #return hash with number of running tasks by priority
  my $self	= shift;
  my $counts	= { "127.0.0.1" => { 0 => 0, 1 => 0, 2 => 0, 3 => 0 } };
  my $dba		= $self->{DBA};
  my $table	= $self->{CONST}->{TASK_TBL};
  my $ipid;
  my $hpid;
  my $pid;
  my $host;

  %{$self->{tasks}} = ();
#	warn "SELECT priority, epid, ipid FROM $table WHERE priority AND epid IS NOT NULL";
  foreach ( $dba->getMatrix( "SELECT priority, epid, ipid FROM $table WHERE priority AND epid IS NOT NULL" ) ) {
#		warn "@{$_}";
    ( $host, $pid ) = split( /:/, $_->[1] );
    if( $host eq '127.0.0.1' ) {
      if( kill( 0, $pid ) ) {
        $counts->{$host}->{$_->[0]}++;
        $counts->{$host}->{0}++;
        $self->{tasks}->{$_->[2]} = $_->[1];
#				warn "process $pid is running and INSERTING TASK $_->[2], $_->[1]";
      }
      else {
#				warn "task with $pid is not running and sql will be updated";
        $dba->updateRecord( $table, { ipid => $_->[2] }, { priority => 0 } );
      }
    }
    else {
      $self->{HLP}->suicide( "NI" );
    }
  }
#	warn "refreshRunningTasks: $counts were found";
  return $counts;
}

sub scheduleTask {
  my $self		= shift;
  my $date		= shift;
  my $priority	= shift;
  my $caller		= shift;
  my $options		= shift;
  my $dba			= $self->{DBA};
  my $table		= $self->{CONST}->{TASK_TBL};
  my $taskN;

##	warn $options;
  $date		|| ( $date = 'NOW()' );
  $priority	|| ( $priority = '2' );
  $dba->lockTables( { $table => 'WRITE' } );
  $taskN = $dba->insertRecord( $table, { date => $date, priority => $priority, caller => $caller, options => $options } );
#	warn "task was created with code $taskN, checking up:";
  $dba->unlockTables();
#	warn "SELECT caller FROM $table WHERE ipid= $taskN ";
#	my $ipid = $dba->getValue( "SELECT ipid FROM $table WHERE ipid= $taskN " ) ;
#	warn "now refreshing";
  $self->refresh();
  return $taskN;
}
1;
