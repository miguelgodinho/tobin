# (C) Miguel Godinho de Almeida - miguel@datindex.com 2004
package WebArc::AppGraph;

use strict;
use warnings;
use Rapido::TaskAccessor;

sub new {
	my $param	= shift;
	my $self	= shift;
	my $class	= ref( $param ) || $param;

	bless( $self, $class );
	bless( $self->{BRO}, 'WebArc::Broker' );

	$self->{CONST}		= $self->{BRO}->{CONST};
	$self->{CODE}		= $self->{BRO}->{app};
	$self->{MEM}		= $self->{BRO}->{MEM};
	$self->{DBA}		= $self->{MEM}->{DBA};
	$self->{HLP}		= $self->{BRO}->{HLP};
	$self->{USR} 		= $self->{MEM}->{USR};
	$self->{data} 		= $self->{BRO}->getData();
	$self->{errors}		= [];
	$self->{warnings}	= [];
	$self->{VIEWS}		= {};
	$self->{filename}	= '';


	($self->{CODE}		=~ m/^map(\d+)(\D+)([+-z]+)$/ ) || $self->{HLP}->suicide( $self->{CODE} );
	$self->{CHILD}		= $self->{CONST}->{CHILDREN}->{$2};
	$self->{ID}			= $1;
	$self->{TGT}		= $3;
	$self->{TASK_AC}	= undef;

	$self->{MEM}->{USR}	|| $self->{HLP}->suicide();
	$self->{MEM}->entryAccessLvlGet( $self->{CHILD}->{PARENT}, $self->{ID} ) || $self->{HLP}->suicide( "SECURITY FAULT" );

	unless( $self->{data}->{init} ) {
		$self->{data}->{init}		= 1;
		$self->{data}->{lvl}		= 0;
		$self->{data}->{size}		= $self->{CONST}->{GRAPH_TAG_MEDIUM};
		$self->{data}->{generators}	= {};
	}

	$self->processMessages();
	$self->processGraph();

	return $self;
}

sub filesOK {
	my $self		= shift;
	my $filename	= $self->{filename};

	if( $self->{MEM}->fileStatus( "$filename.gif" ) && $self->{MEM}->fileStatus( "$filename.map" ) ) {
		delete( $self->{data}->{generators}->{$filename} );
		return 1;
	}
	else {
#		warn "$filename is not ok";
		return 0;
	}
}

sub getCentralNodeAttribs {
	my $self	= shift;
	my $txt;
	my $lnk;
	my $appendix;
	my $childLink;
	my $labels;

	if( $self->{TGT} =~ m/^(\d+)(([A-z])+)(.+)$/ ) {
		if( ( $self->{CHILD}->{UNCLES}->[0] eq $2 ) && !$self->{CHILD}->{UNCLES}->[1] ) {
			$txt = $self->{MEM}->entryDefsGet( $2, $1, [ 'MAIN' ] );
			$lnk = $self->{MEM}->getLink( $2, $1 );
			$appendix = " ($self->{CHILD}->{LABELS}->[1]= $4)";
		}
		elsif( $childLink = $self->{CONST}->{CHILDREN}->{$2} ) {
			$txt = $self->{MEM}->entryDefsGet( $childLink->{UNCLES}->[0], $1, [ 'MAIN' ] );
			$lnk = $self->{MEM}->getLink( $childLink->{UNCLES}->[0], $1 );
			@{$labels} = split( /,/, $childLink->{LABELS}->[1] );
			$appendix = " ($labels->[$4])";
		}
		else {
			$self->{HLP}->suicide( $self->{TGT} );
		}
	}
	else {
		$self->{HLP}->suicide( $self->{TGT} );
	}

	return( $txt, $lnk, $appendix );
}

sub getNewApplicationCode {
	my $self			= shift;
	my $x				= shift;
	my $y				= shift;
	my $map				= $self->{MEM}->fileGet( "$self->{filename}.map" );
	my $lnk;
	my $numberOfBoxes;
	my $currentBox;

		( ( $numberOfBoxes = scalar( @{$map} ) ) > 1 ) || $self->{HLP}->suicide();

		for( $currentBox = 1; $currentBox < $numberOfBoxes; $currentBox++ ) {
			( $map->[$currentBox] =~ m/^rect ([+-z]+) (\d+),(\d+) (\d+),(\d+)/ ) || $self->{HLP}->suicide( $map->[$currentBox] );
			if( ( $x >= $2 ) && ( $x <= $4 ) && ( $y >= $3 ) && ( $y <= $5 ) ) {
				$lnk = "map$self->{ID}$self->{CHILD}->{CODE}$1";
				$currentBox = $numberOfBoxes;
			}
		}
		defined( $lnk ) ? ( return( $lnk ) ) : ( return( $self->{CODE} ) );
}

sub getTargetPlotterStyle{
	my $self	= shift;
	my $target;
	my $targetParent;
	my $targetChild;

	if( $self->{TGT} =~ m/^(\d+)(([a-z]|[A-Z]|_)+)([+-z]+)$/ ) {
		if( $targetParent = $self->{CONST}->{PARENTS}->{$2} ) {
			$target = $self->{TGT};
		}
		elsif( $targetChild = $self->{CONST}->{CHILDREN}->{$2} ) {
			( $targetChild->{FIELDS}->[1] eq 'FORK' ) || $self->{HLP}->suicide( "NI" );
			( $targetParent = $self->{CONST}->{PARENTS}->{$targetChild->{UNCLES}->[0]} ) || $self->{HLP}->suicide();
			$target = "$1$targetParent->{CODE}$4";
#			warn $targetParent;
		}
		else {
			$self->{HLP}->suicide( $self->{TGT} );
		}
	}
	else{
		$self->{HLP}->suicide( $self->{TGT} );
	}

	if(	$targetParent->{FLAGS}->{ADMIN} || $targetParent->{OWNERTBL} ) {
		$self->{HLP}->suicide( "Ownership permissions are not implemented for plottable entities" );
	}
#	warn $target;
	return $target;
}

sub printAbortScreen {
	my $self		= shift;
	my $scr			= shift;

	$scr->openPage( $self->{CODE} );
	$scr->stoBar( [ 'logout', $self->{CONST}->{DOMAIN_APP_PUBLIC} ] );
	$scr->stoBar( [ 'Bookmark Manager', "man0b" ] );
	$scr->stoBar( [ 'GraphViewer', $self->{CODE} ] );
	$scr->doBar( $self->{CODE} );

	$scr->doLine();
	$scr->openCell( 'align=center' );
	$scr->doTxt( 'Aborted' );
}

sub printGraphScreen {
	my $self		= shift;
	my $scr			= shift;
	my $filename	= $self->{filename};
	my $strSmall	= $self->{CONST}->{GRAPH_TAG_SMALL};
	my $strMedium	= $self->{CONST}->{GRAPH_TAG_MEDIUM};
	my $strLarge	= $self->{CONST}->{GRAPH_TAG_LARGE};
	my $lvlOptions	= [];
	my $txt;
	my $lnk;
	my $appendix;
	my $i;

	$filename =~ s/.*\/([+-z]+)$/\/graphs\/$1.gif/; # internal path needs to be replaced and extension added

	for( $i = $self->{CONST}->{GRAPH_LVL_MIN}; $i <= $self->{CONST}->{GRAPH_LVL_MAX}; $i++ ) {
		push( @{$lvlOptions}, [ $i, "$i $self->{CHILD}->{LABELS}->[0](s)" ] );
	}

	( $txt, $lnk, $appendix ) = $self->getCentralNodeAttribs();
	$scr->openPage( $self->{CODE} );
	$scr->stoBar( [ 'logout', $self->{CONST}->{DOMAIN_APP_PUBLIC} ] );
	$scr->stoBar( [ 'Bookmark Manager', "man0b" ] );
	$scr->stoBar( [ 'GraphViewer', $self->{CODE} ] );
	$scr->doBar( $self->{CODE} );

	$scr->doLine();
	$scr->openCell( 'align=center' );
	$scr->doTxt( "Centred on: " );
	$lnk ?  $scr->doLink( $lnk, $txt ) : $scr->doTxt( $txt );
	$appendix && $scr->doTxt( $appendix );
	$scr->closeCell();
	$scr->doLine();
	$scr->openCell( 'align=center' );
	$scr->doTxt( "Size: " );
	$scr->doSelect( "$self->{CODE}&size", [ [ $strSmall, $strSmall ], [ $strMedium, $strMedium ], [ $strLarge, $strLarge ] ], $self->{data}->{size} );
	$scr->doTxt( " " );
	$scr->doTxt( "Expansion: " );
	$scr->doSelect( "$self->{CODE}&lvl", $lvlOptions, $self->{data}->{lvl} );
	$scr->closeCell();
	$scr->doLine();
	$scr->doLine();

	$scr->openCell( 'align=center' );
	$scr->doImgSubmit( $self->{CODE}, $filename );
}

sub printWaitScreen {
	my $self		= shift;
	my $scr			= shift;

	$self->{BRO}->setRefreshTime( 3 );
	$scr->openPage( $self->{CODE} );
	$scr->stoBar( [ "Bookmark Manager", "man0b" ] );
	$scr->stoBar( [ "Loading Graph", $self->{CODE} ] );
	$scr->doBar( );
	$scr->doLine( 3 );
	$scr->openCell( 'align=center' );
	$scr->doTxt( "Graph Being Processed, Please Wait..." );
}

sub processGraph {
	my $self		= shift;

  my $GRAPH_PATH = $self->{CONST}->{GRAPH_PATH};

  mkdir $GRAPH_PATH unless (-e $GRAPH_PATH);

	my $filename	= "$GRAPH_PATH/$self->{CODE}$self->{data}->{size}$self->{data}->{lvl}";
	my $target;
	my $targetParent;
	my $targetChild;
	my $tskA;
	my $task;
	my $options;

	$self->{filename} = $filename;

	unless( $self->filesOK() ) {
#		warn "so we need to create the files";
		unless( $tskA = $self->{TASK_AC} ) {
#			warn "creating the task accessor ( from processGraph )";
			$self->{TASK_AC} = new Rapido::TaskAccessor( { MEM => $self->{MEM} } );
			$tskA = $self->{TASK_AC};
		}

		$target = $self->getTargetPlotterStyle();
		$options = "--output=$filename --id=$self->{ID} --target=$target --level=$self->{data}->{lvl} --size=$self->{data}->{size}";
#		warn "CALLING TASK: $self->{CONST}->{GRAPH_APP} $options";
		if( $tskA->getStatus( $self->{CONST}->{GRAPH_APP}, $options ) < 3 ) {
			$task = $tskA->scheduleTask( '', 3, $self->{CONST}->{GRAPH_APP}, $options );
#			warn "process graph will 1st check is task $task is already executed";
			$tskA->isRunning( $task );
			$self->{data}->{generators}->{$filename} = $task;
#			warn "!!!!!!!!!!!!!!!!";
			sleep( 1 );
		}
		else {
			warn "didn't get the status, whatever it means";
		}

	}
}

sub processMessages {
	my $self		= shift;
	my $messages	= $self->{BRO}->messagesGet();
	my $subject;
	my $message;
	my $value;

	if( $messages ) {
		foreach $message ( values( %{$messages} ) ) {
			while( ( $subject, $value ) = each( %{$message} ) ) {
				if( $subject eq 'setSize' ) {
					if( ( $value eq $self->{CONST}->{GRAPH_TAG_LARGE} ) || ( $value eq $self->{CONST}->{GRAPH_TAG_MEDIUM} ) || ( $value eq $self->{CONST}->{GRAPH_TAG_SMALL} ) ) {
						$self->{data}->{size} = $value;
					}
					else {
						$self->{HLP}->suicide( "$value is invalid value for $subject" );
					}
				}
				elsif( $subject eq 'setLvl' ) {
					if( ( $value =~ m/^\d+$/ ) && ( $value >= $self->{CONST}->{GRAPH_LVL_MIN} ) && ( $value <= $self->{CONST}->{GRAPH_LVL_MAX} ) ) {
						$self->{data}->{lvl} = $value;
					}
					else {
						$self->{HLP}->suicide( "$value is invalid value for $subject" );
					}
				}
				else {
					$self->{HLP}->suicide( "$subject is unreconized subject" );
				}
			}
		}
		$self->{BRO}->messagesClear();
	}
}

sub processForm {
	my $self		 	= shift;
	my $form		 	= shift;
	my $refresh			= 0;
	my $lnk;
	my $x;
	my $y;
	my $value;

	if( $form->{submitKey}->[0] && ( ( $x, $y ) = split( /;/, $form->{submitValue} ) ) ) {
		$lnk = $self->getNewApplicationCode( $x, $y );

		if( ( defined( $value = $form->{lvl} ) ) && ( $value != $self->{data}->{lvl} ) ) {
			$refresh = 1;
			( $value =~ m/^\d+$/ ) || $self->{HLP}->suicide( "FORM EXPLOIT!!!!" );
			( ( $value >= $self->{CONST}->{GRAPH_LVL_MIN} ) && ( $value <= $self->{CONST}->{GRAPH_LVL_MAX} ) ) || $self->{HLP}->suicide( "FORM EXPLOIT!!!" );
			$self->{data}->{lvl} = $value;
		}

		if( ( $value = $form->{size} ) && ( $value ne $self->{data}->{size} ) ) {
			$refresh = 1;
			( length( $value ) > 10 ) && $self->{HLP}->suicide( "FORM EXPLOIT!!!" );
			( $value eq $self->{CONST}->{GRAPH_TAG_LARGE} ) || ( $value eq $self->{CONST}->{GRAPH_TAG_MEDIUM} ) || ( $value eq $self->{CONST}->{GRAPH_TAG_SMALL} ) || $self->{HLP}->suicide( "FORM EXPLOIT!!!" );
			$self->{data}->{size} = $value;
		}
	}

	$refresh && $self->processGraph();

	if( $lnk eq $self->{CODE} ) {
		return( '' );
	}
	else{
		$self->{BRO}->messageSend( $lnk, 'setSize', $self->{data}->{size} );
		$self->{BRO}->messageSend( $lnk, 'setLvl', $self->{data}->{lvl} );
		return( $lnk );
	}
}

sub run {
	my $self 		= shift;
	my $scr			= $self->{SCR};
	my $frm			= $self->{BRO}->getForm();
	my $nxtApp;
	my $tskA;
	my $task;

	$self->{USR} || $self->{HLP}->suicide( "SECURITY FAULT ????????????????" );

	@{$frm->{submitKey}} && ( $nxtApp = $self->processForm( $frm ) ) && ( return $nxtApp );

#	warn "checking if files ok $self->{filename}";
#	warn "the generators are:";
#	foreach( keys( %{$self->{data}->{generators}} ) ) {
#		warn $_;
#	}

	if( $self->filesOK() ) {
#		warn "they were ok";
		$self->printGraphScreen( $scr );
	}
	elsif( $task = $self->{data}->{generators}->{$self->{filename}} ) {
#		warn "they were not ok, but task was there with code $task";
		unless( $tskA = $self->{TASK_AC} ) {
#			warn "creating the task accessor (from run)";
			$self->{TASK_AC} = new Rapido::TaskAccessor( { MEM => $self->{MEM} } );
			$tskA = $self->{TASK_AC};
		}

#		warn "calling is Running for task $task";
		if( $tskA->isRunning( $task ) ) {
			$self->printWaitScreen( $scr );
		}
		elsif( $self->filesOK() ) { #in meanwhile things may have happened
#			warn "task is not running but in the meanwhile they got ok";
			$self->printGraphScreen( $scr );
		}
		else{
#			warn "everything got fucked up";
			delete( $self->{data}->{generators}->{$self->{filename}} );
			$self->printAbortScreen( $scr );
		}
	}
	else {
		$self->{HLP}->suicide();
	}

	$scr->closePage();
	return '';
}
1;
