# (C) Miguel Godinho de Almeida - miguel@datindex.com 2004
package WebArc::Display;

use strict;
use warnings;
use vars qw($VERSION @ISA @EXPORT_OK);
use lib "./";
use Exporter;

@ISA       = ( 'Exporter' );
$VERSION   = '1.00';
@EXPORT_OK = qw();

sub new {
	my $param 	= shift;
	my $self 	= shift;
	my $class 	= ref( $param ) || $param;
	bless( $self, $class );
	$self->{CONST}			= $self->{BRO}->{CONST};
	$self->{HLP}			= $self->{BRO}->{HLP};
	$self->{SCR}         	= '';
	$self->{UL}          	= 0;
	$self->{divs}			= {};

	$self->{TAGS}	= {	a		=> {	AUTO	=> 0,
										IDENT	=> 0,
										MULTI	=> 0,
										REQ	=> 'body',
										NESTS	=> {	b	=> 1,
														img	=> 1 },
										OPTIONS => {	href	=> 1 } },
					
						b		=> {	AUTO	=> 0,
										IDENT	=> 0,
										MULTI	=> 0,
										REQ	=> 'body',
										NESTS	=> {},
										OPTIONS	=> {} },
						
						body	=> {	AUTO	=> 0,
										IDENT	=> 0,
										MULTI	=> 0,
										REQ	=> '',
										NESTS	=> {	a		=> 1,
														b		=> 1,
														br		=> 1,
														div		=> 1,
														form	=> 1,
														hr		=> 1,
														table	=> 1,
														ul		=> 1 },
										OPTIONS	=> {} },

						br		=> {	AUTO	=> 1,
										MULTI	=> 0,
										NL	=> 1,
										REQ	=> 'body',
										NESTS	=> {},
										OPTIONS	=> {} },
										
						div		=> {	AUTO	=> 0,
										MULTI	=> 1,
										NL		=> 1,
										REQ		=> 'body',
										NESTS	=> {	table	=> 1, },
										OPTIONS	=> {	id	=> 1 } },

						form	=> {	AUTO	=> 0,
										IDENT	=> 1,
										MULTI	=> 0,
										REQ	=> 'body',
										NESTS	=> {	a	=> 1,
														b	=> 1,
														br	=> 1,
														hr	=> 1,
														input	=> 1,
														table	=> 1 },
									
										OPTIONS	=> { 	action	=> 1,
														method	=> 1 } },

						hr		=> {	AUTO	=> 1,
										MULTI	=> 0,
										NL	=> 1,
										REQ	=> 'body',
										NESTS	=> {},
										OPTIONS	=> {} },

						img		=> {	AUTO	=> 1,
										MULTI	=> 0,
										REQ	=> 'body',
										NESTS	=> {},
										OPTIONS	=> {	alt	=> 1,
														border	=> 1,
														height	=> 1,
														width	=> 1,
														src	=> 1 } },
						
						input	=> {	AUTO 	=> 1,
										MULTI	=> 0,
										REQ	=> 'form',
										NESTS	=> {},
										OPTIONS	=> {	border		=> 1,
														checked		=> 1,
														disabled	=> 1,
														maxlength	=> 1,
														name		=> 1,
														size		=> 1,
														src		=> 1,
														submit		=> 1,
														type		=> 1 } },

						li		=> {	AUTO	=> 1,
										MULTI	=> 1,
										REQ	=> 'ul',
										NESTS	=> {},
										OPTIONS	=> {} },

						option	=> {	AUTO	=> 0,
										MULTI	=> 0,
										REQ	=> 'select',
										NESTS	=> {},
										OPTIONS	=> {	selected	=> 1 } },

						select	=> {	AUTO	=> 0,
										IDENT	=> 0,
										MULTI	=> 0,
										REQ	=> 'form',
										NESTS	=> {	option		=> 1 },
										OPTIONS	=> {	name		=> 1 } },
						
						table	=> {	AUTO	=> 0,
										IDENT	=> 1,
										MULTI	=> 1,
										REQ	=> 'body',
										NESTS	=> {	tr	=> 1 },
										OPTIONS => { 	width	=> 1,
														cellspacing => 1,
														cellpadding => 1,
														bordercolor => 1,
														rules	=> 1,
														frame	=> 1,
														border	=> 1 } },
							
						td		=> {	AUTO	=> 0,
										MULTI	=> 1,
										REQ	=>  'tr',
										NESTS	=> {	a	=> 1,
														b	=> 1,
														br	=> 1,
														div	=> 1,
#														hr	=> 1,
														img	=> 1,
														input	=> 1,
														select	=> 1,
														table	=> 1 },
										OPTIONS => {	align	=> 1,
														bgcolor => 1,
														colspan => 1,
														width	=> 1,
														valign  => 1 } },
			
						tr		=> {	AUTO	=> 0,
										NL	=> 1,
										MULTI	=> 1,
										REQ	=> 'table',
										NESTS	=> { td	=> 1 },
										OPTIONS	=> { 	bordercolor => 1,
														bgcolor	 => 1 } },

						ul		=> {	AUTO	=> 0,
										IDENT	=> 1,
										MULTI	=> 1,
										REQ	=> 'body',
										NESTS	=> { 	a	=> 1,
														li	=> 1,
														ul	=> 1},
										OPTIONS	=> {} }
					};
					
	$self->{prevTags}	= []; #queues unclosed tags as new are called
	$self->{cTag}		= 'body'; #the current tag
	$self->{tagsHash}	= { body => 1 }; #number of open instances
	$self->{prevCols}	= [0]; #queues number of cols for every parent table
	$self->{cols}		= 0; #number of cols for current table
	$self->{cCol}		= 0; #number of closed cols in current row
#	$self->{form}		= ''; #form name, empty if no form is open
	$self->{ident}		= 0;
	$self->{nxtIdent}	= 0;
	$self->{radio_chk}	= {};

	return $self;
}

sub closeCell {
	my $self 	= shift;
	
	( $self->{cTag} eq 'td' ) || $self->{HLP}->suicide();
	( $self->{cCol} < $self->{cols} ) || $self->{HLP}->suicide();
	$self->{cCol}++;
	$self->stoTag('/td');
}

sub closeDiv {
	my $self	= shift;
	$self->stoTag( '/div'  );
}

sub closePage {
	my $self	= shift;

	$self->closeTable();
	$self->stoTag('/form');
}

sub closeRow {
	my $self	= shift;

	( $self->{cTag} eq 'td' ) && $self->closeCell();
	while( $self->{cCol} < $self->{cols} ) { $self->doCell('') };
	$self->stoTag('/tr' );
	$self->{cCol} = 0;
}

sub closeTable {
	my $self 	= shift;
	( $self->{cTag} eq 'table' ) || $self->closeRow();
	$self->stoTag('/table');
	$self->{tagsHash}->{table} ? ( $self->{cols} = pop( @{$self->{prevCols}}) ) : ( $self->{cols} = 0 );
	( $self->{cTag} eq 'td' ) && $self->closeCell();
}

sub closeTag {
	my $self	= shift;
	( ( $self->{cTag} eq 'form' ) || ( $self->{cTag} eq 'table' ) || ( $self->{cTag} eq 'tr' ) || ( $self->{cTag} eq 'td' ) ) && $self->{HLP}->suicide( "closetag for $self->{cTag} is not possible, call proper method" );
	
	$self->stoTag("/$self->{cTag}");
}

sub doBar {
	my $self	= shift;
	my $sel		= shift;

	$self->{bar} || $self->{HLP}->suicide();

	if ( defined( $sel ) ) {
		if ( ref( $sel ) eq 'ARRAY' ) {
			$self->stoBar( $sel );
			$sel = $sel->[1];
		}
	}
	else {
		$sel = '';
	}

	$self->openCell( 'align=center' );
	my $spacer = '';
	foreach ( @{$self->{bar}} ) {
		$spacer ? $self->doTxt( '&nbsp;&nbsp;&nbsp;' ) : ( $spacer = 1 );
		( ${$_}[1] eq $sel ) ? ( $self->inTag( 'b', "<${$_}[0]>" ) ) : ( $self->inTag( "a href=?app=${$_}[1]", "|${$_}[0]|" ) );
	}
	$self->closeRow();
	$self->doLine();
}

sub doCell {
	my $self	= shift;
	my $txt 	= shift;
	my $options	= shift;
	
	$self->openCell( $options );
	$self->doTxt($txt);
	$self->closeCell();
}

sub doCheckBox {
	my $self	= shift;
	my $code	= shift;
	my $id		= shift;
	my $on		= shift;

#	$on ? $self->stoTag( "input type=checkbox name=$self->{form}&".$code.' checked', $id ) : $self->stoTag( "input type=checkbox name=$self->{form}&".$code, $id );
	$on ? $self->stoTag( "input type=checkbox name=$code checked", $id ) : $self->stoTag( "input type=checkbox name=$code", $id );
}

sub doDiv {
	my $self	= shift;
	my $id		= shift;
	
	$self->openDiv( $id );
	$self->closeDiv();
}

sub doEdit{
	my $self 	= shift;
	my $code	= shift;
	my $value	= shift;
	my $length 	= shift;

	my $size;
	defined( $length ) || ( $length = 0 );
	defined( $value ) || ( $value = '' );
	( $length > $self->{CONST}->{INPUTSIZE} ) ? ( $size = $self->{CONST}->{INPUTSIZE} ) : ( $size = $length );
	
#	$code = $self->{form} . "&" . $code;
	$value =~ s/'/&#39;/g;#'
	$self->stoTag( "input type=edit name=$code maxlength=$length size=$size", $value );
}

sub doLine {
	my $self 	= shift;
	my $line 	= shift;
	my $a_flags	= shift;

	my %flag;
	
	foreach ( @{$a_flags} ) {
		( $_ eq 'BOLD' ) ||
		$self->{HLP}->suicide( "PE" );
		$flag{$_} = 1;
	}

	if ( ( $self->{cTag} eq 'table' ) || ( $self->{cTag} eq 'tr' ) ) {
		( $self->{cTag} eq 'tr' ) && $self->openRow();
		if ( defined( $line ) ) {
			if ( $line =~ m/^\d+$/ ) {
				my $i;
				for ( $i = 0; $i < $line; $i++ ) {
					$self->closeRow();
				}
			}
			else {
				$self->openCell();
				$flag{BOLD} ? ( $self->inTag( 'b', $line ) ) : ( $self->doTxt( $line ) );
			}
		}
		$self->closeRow();
	}
	elsif ( defined( $line ) ) {
		$flag{BOLD} ? ( $self->inTag( 'b', $line ) ) : ( $self->doTxt( $line ) );
		$self->stoTag( 'br' );

	}
	else {
		$self->stoTag( 'hr' );
	}
}

sub doLink {
	my $self	= shift;
	my $link	= shift;
	my $txt		= shift;

	$self->inTag( "a href=$link", $txt );
}

sub doImg {
	my $self	= shift;
	my $img		= shift;
	
	$self->stoTag( "img src=$img border=0" );
}

sub doImgLink {
	my $self	= shift;
	my $link	= shift;
	my $img		= shift;

	$self->stoTag( "a href=$link" );
	$self->stoTag( "img src=$img alt=$img border=0"  );
	$self->stoTag( "/a" );
}

sub doImgSubmit {
	my $self	= shift;
	my $code	= shift;
	my $image	= shift;

	$code = 'submit&'.$code.'&img';
	$self->stoTag( "input type=image border=0 name=$code src=$image" );
}


sub doPassword {
	my $self 	= shift;
	my $code	= shift;
	my $value	= shift;
	my $length 	= shift;

	my $size;
	defined( $length ) || ( $length = 0 );
	defined( $value ) || ( $value = '' );
	( $length > $self->{CONST}->{INPUTSIZE}) ? ( $size = $self->{CONST}->{INPUTSIZE} ) : ( $size = $length );
	
#	$code = $self->{form} . "&" . $code;
	$value =~ s/'/&#39;/g;
	$self->stoTag( "input type=password name=$code maxlength=$length size=$size", $value );#'
}

sub doRadio {
	my $self	= shift;
	my $code	= shift;
	my $id		= shift;
	my $on		= shift;
	my $chk		= '';

	defined( $code ) || $self->{HLP}->suicide();
	defined( $id )	 || $self->{HLP}->suicide();
	defined( $on )	 || $self->{HLP}->suicide();

	if( $on ) {
		$self->{radio_chk}->{$code} ? $self->{HLP}->suicide( "dual selection on radio $code" ) : ( $self->{radio_chk}->{$code} = 1 );
		$chk = 'checked';
	}
	$self->stoTag( "input type=radio name=$code $chk", $id )
}

sub doRow {
	my $self	= shift;
	$self->{HLP}->suicide();
	my $data	= shift;

	$self->openRow();
	foreach ( @{$data} ) { $self->doCell($_) };
	$self->closeRow();
}

sub doHidden {
	my $self 	= shift;
	my $code	= shift;
	my $value	= shift;
	defined( $value ) || $self->{HLP}->suicide();
#	$code = $self->{form} . "&" . $code;
	$value =~ s/'/&#39;/g;#'
	$self->stoTag( "input type=hidden name=$code", $value );
}

sub doSelect {
	my $self	= shift;
	my $code 	= shift;
	my $options	= shift; # [ [ id, txt] ] || [ [ id, default, txt1, txt2 ... ] ]
	my $default	= shift;
	my $length;
	my $offset;
	my $txt;

	$self->openTag( "select name=$code");
	if ( defined( $default ) ) {
		my $init = 0;
		foreach ( @{$options} ) {
			( $_->[0] =~  m/\s/ ) && $self->{HLP}->suicide();
			if( ( $length = length( $_->[1] ) ) > ( 5 + ( 2 * $self->{CONST}->{SEL_HALF_MAXWIDTH} ) ) ) {
				$offset = ( $length - $self->{CONST}->{SEL_HALF_MAXWIDTH} );
				( $offset < $self->{CONST}->{SEL_HALF_MAXWIDTH} ) && ( $offset = $self->{CONST}->{SEL_HALF_MAXWIDTH} );
				$txt = substr( $_->[1], 0, $self->{CONST}->{SEL_HALF_MAXWIDTH} );
				$txt .= ' ... ';
				$txt .= substr( $_->[1], $offset );
			}
			else {
				$txt = $_->[1];
			}
			( ( !$default && !$init ) || ( $default eq $_->[0]  ) ) ? $self->inTag( "option value=$_->[0] selected", $txt ) : $self->inTag( "option value=$_->[0]", $txt );
			$init = 1;
		}
	}
	else {
		my $pos;
		my $default;

		foreach ( @{$options} ) {
			my $txt;
			for ( $pos = 2; $pos < scalar( @{$_} ); $pos++ ) {
				defined( $txt ) ? ( $txt .= "\n$_->[$pos]" ) : ( $txt .= "$_->[$pos]" );
			}
			defined( $txt ) || $self->{HLP}->suicide();
			if ( $_->[1] ) {
				defined( $default ) && $self->{HLP}->suicide();
				$default = $_->[0];
				$self->inTag( "option value=$default selected", $txt );
			}
			else {
				$self->inTag( "option value=$_->[0]", $txt );
			}
		}
	}

	$self->closeTag( 'select' );
}

sub doSubmit {
	my $self     	= shift;
	my $name     	= shift;
	my $txt  		= shift;
	my $disabled 	= shift;

	( $name =~ m/\s/ ) && $self->{HLP}->suicide( "doSubmit - PE" );
#	$self->{form} || $self->{HLP}->suicide( "doSubmitLine - UE" );

	$disabled ? $self->stoTag( "input type=submit name=submit&".$name." disabled", $txt ) : $self->stoTag( "input type=submit name=submit&".$name, $txt );
}

#sub doTree {
#	my $self	= shift;
#	my $code	= shift;
#	my $ilink	= shift;
#	my $set		= shift; #bool, 1 to enable node selection by checkboxes
#	my $parents	= shift; #hash of arrays, key=node, value=array of parents, key=0 for root
#	my $children	= shift; #hash of arrays, key=node, value=array of children
#	my $expansion	= shift; #hash of bools, key=node, value=expanded
#	my $selection	= shift; #hash of bools, key=node, value=selected; only used if set=1
#	my $edits	= shift; #hash of bools, key=node, value=editable [optional]
#	my $values	= shift; #hash of strings, key=node, value=txt [optional]
#	my $flags	= shift;
#
#	my %flag;
#	foreach ( split(/;/, $flags ) ) {
#		( $_ eq '' ) ||
#		( $_ eq 'TREE' ) ||
#		( $_ eq 'FIXED' ) ||
#		( $_ eq 'ELINK' ) ||
#		( $_ eq 'ILINK' ) ||
#		$self->{HLP}->suicide( "PE $_" );
#		$_ && ( $flag{"$_"} = 1 );
#	}
#
#	my $sortedBranches = $self->{HLP}->sortTree( $children );
#	my %expandedBranches = $self->{HLP}->checkTreePropagation( $parents, $children, $expansion );
#	my %selectedBranches = $self->{HLP}->checkTreePropagation( $parents, $children, $selection );
#
#	my $fixed;
#	my $i;
#	my $child;
#	my $checked;
#	my %currentChild;
#	my @currentArray;
#	my %currentHash;
#	my $lvl= 0;
#	my $parent = 0;
#	my $run = 0;
#
#	if ( $sortedBranches->{0} ) {
#		$lvl = 1;
#		%currentChild = ( 0 => 0 );
#		@currentArray = ();
#		%currentHash = ();
#	}
#
##	$code = $self->{form} . "&$code"; 
#
#	while ( $lvl ) {
#		$child = $sortedBranches->{$parent}->[$currentChild{$parent}];
#		$currentHash{$child} && $self->{HLP}->suicide();
#		for ( $i = 1; $i < $lvl; $i++ ) { $self->doTxt( '&nbsp;&nbsp;&nbsp;' ) };
#		
#		if ( $set ) {
#			$selection->{$child} ? ( $checked = 'checked' ) : ( $checked = '' );
#			$self->stoTag( "input type=hidden name=$code&VisibleNodes", $child );
#			$self->stoTag( "input type=checkbox name=$code&SelectedNodes $checked", $child );
#		}
#
#		( scalar( @{$parents->{$child}} ) > 1 ) && $self->inTag( 'b', ' !' );
#
#		if ( $flag{ELINK} ) {
#			( defined( $values->{$child} ) && length( $values->{$child} ) ) ? $self->inTag( "a href=$values->{$child}", "$children->{$parent}->{$child}" ) : $self->doTxt( "$children->{$parent}->{$child}") ;
#			if ( $edits->{$child} ) {
#				( $ilink =~ s/\d+/$child/ ) || $self->{HLP}->suicide();
#				$self->doTxt( "&nbsp;&nbsp;&nbsp;" );
##				$self->inTag( "a href=?app=$ilink", '.');
#				$self->stoTag( "a href=?app=$ilink" );
#				$self->stoTag( "img src=images/preferences.png alt=edit border=0" );
#				$self->stoTag( "/a" );
#			}
#		}
#		elsif ( $flag{ILINK} ) {
#			( $edits->{$child} && ( $ilink =~ s/\d+/$child/ ) ) ? $self->inTag( "a href=?app=$ilink", " $children->{$parent}->{$child}" ) : $self->doTxt( "$children->{$parent}->{$child}" );
#			
#			defined( $values->{$child} ) && $self->doTxt( " = $values->{$child}" );
#		}
#		else {
#			$self->doTxt( "$children->{$parent}->{$child}" );
#			defined( $values->{$child} ) && $self->doTxt( " = $values->{$child}" );
#		}
#		
#		if ( !$flag{FIXED} && $sortedBranches->{$child} && @{$sortedBranches->{$child}} ) {
#			my $toolbox = [];
#			if ( $expansion->{$child} ) {
#				( $expandedBranches{$child} && ( $expandedBranches{$child} > 0 ) ) ? ( @{$toolbox} = ( '', 'right', '', 'down' ) ) : ( @{$toolbox} = ( '', 'right', '', 'up' ) );
#			}
#			else {
#				$toolbox = [ '', 'left', '', 'up' ] 
#			}
#			if ( $set ) {
#				if ( $selectedBranches{$child} ) {
#					( $selectedBranches{$child} == 1 ) ? ( push( @{$toolbox}, ( '', 'box4' ) ) ) : ( push( @{$toolbox}, ( '', 'box2' ) ) );
#				}
#				else {
#					push( @{$toolbox}, ( '', 'box' ) );
#				}
#			}
#			$self->doToolBox( "tree&".$child, 8, $toolbox );
#		}
#
#		$self->stoTag( 'br' );
#		
#		if ( $sortedBranches->{$child} && @{$sortedBranches->{$child}}  && ( $expansion->{$child} || $flag{FIXED} ) ) {
#			$lvl++;
#			push( @currentArray, $parent );
#			$currentHash{"$parent"} = 1;
#			$parent = $child;
#			$currentChild{"$parent"} = 0;
#		}
#		else {
#			while ( $lvl && ( $currentChild{$parent} == $#{$sortedBranches->{$parent}} ) )  {
#				$lvl--;
#				$currentHash{$parent} = 0;
#				$currentChild{$parent} = 0;
#				$parent = pop( @currentArray );
#			}			
#			defined( $parent ) && $currentChild{"$parent"}++;
#		}
#	}
#}

sub doToolBox {
	my $self	= shift;
	my $code	= shift;
	my $size	= shift;
	my $options	= shift;
	my $disabled	= shift;

	$code = 'submit&'.$code.'&';
	my $i = 0;
	foreach ( @{$options} ) {
		if ( $_ eq '' ) {
			$self->stoTag( 'img src=images/icons2/empty-16.gif' );
		}
		else {
			m/\s/ && $self->{HLP}->suicide( $_ );
			$disabled->{$i} ? $self->stoTag( 'img src=images/icons2/'.$_.'-'.$size.'.gif' ) : $self->stoTag( 'input type=image border=0 name='.$code.$_.' src=images/icons2/'.$_.'-'.$size.'.gif' );
		}
		$i++;
	}
}

sub inTag {
	my $self	= shift;
	my $tag		= shift;
	my $txt		= shift;
	my $suf		= shift;

	$self->openTag( $tag );
	$self->doTxt( $txt );
	$self->closeTag();
	defined( $suf ) && $self->doTxt( $suf );
}

sub openCell {
	my $self	= shift;
	my $options	= shift;

	( $self->{cTag} eq 'td' ) && $self->closeCell();
	( $self->{cTag} eq 'table' ) && $self->openRow();
	( $self->{cCol} < $self->{cols} ) || $self->{HLP}->suicide( "just $self->{cols} cols" );
	$options ? ( $self->stoTag( "td $options" ) ) : ( $self->stoTag( "td" ) );
}

#sub openForm {
#	my $self	= shift;
#	my $app		= shift;
#
#	$self->{form} && $self->{HLP}->suicide("openForm - UE");
#	$app || $self->{HLP}->suicide("PE");
#	$self->stoTag( "input type=hidden name=app", $app );
#	$self->{form}   = $app;
#}

sub openDiv {
	my $self	= shift;
	my $id		= shift;
	
	$self->{divs}->{$id} && $self->{HLP}->suicide( "DIV $id is already set" );
	$self->{divs}->{$id} = 1;
	$self->stoTag( "div id=$id" );
}

sub openPage {
	my $self	= shift;
	
	defined( $self->{submits} ) &&  $self->{HLP}->suicide( "openForm - More than 1 form/screen is not supported");
	
	$self->{submits} = 0;
	%{$self->{SUBMIT_data}} = ();
	
	$self->stoTag( "form action=? method=post" );
	$self->openTable( 1, 'width=100%' );
}

sub openRow{
	my $self	= shift;
	my $options	= shift;

	( $self->{cTag} eq 'td' ) && $self->closeCell();
	( $self->{cTag} eq 'tr' ) && $self->closeRow();
	( $self->{cTag} eq 'table' ) || $self->{HLP}->suicide();
	$options ? $self->stoTag( "tr $options" ) : $self->stoTag( "tr" );
}

sub openTable {
	my $self	= shift;
	my $cols	= shift;
	my $opt		= shift;
	
	defined($opt) || ($opt = '');
	( ( $cols =~ m/^[1-9]+$/ ) && ( ref($opt) eq '' ) ) || $self->{HLP}->suicide("Display::openTable - PE\n");
	( $self->{cTag} eq 'table') && $self->openCell();
	$self->{cols} && ( push( @{$self->{prevCols}} , $self->{cols} ) );
	$self->{cols} = $cols;
	$self->{cCol} = 0;
	$self->stoTag("table $opt");
}

sub openTag {
	my $self	= shift;
	my $tag		= shift;

	if ( $tag =~ m/^option ([value]*)value=([^\s]+)\s*(.*)$/ ) {
		
		$tag = 'option';
		length( $1 ) && ( $tag = "$tag $1" );
		length( $3 ) && ( $tag = "$tag $3" );
		$self->stoTag( "$tag", "$2" );
	}
	elsif ( ( $tag eq 'form' ) || ( $tag eq 'table' ) || ( $tag eq 'tr' ) || ( $tag eq 'td' ) ) {
		$self->{HLP}->suicide( "opentag for $tag is not possible, call proper method" );
	}
	else {
		$self->stoTag($tag);
	}
}

sub validate {
	my $self	= shift;
	scalar( @{$self->{prevTags}} ) && $self->{HLP}->suicide();
	$self->{tagsHash}->{body} = 0;
	foreach ( keys %{$self->{tagsHash}} ) { $self->{tagsHash}->{$_} && $self->{HLP}->suicide( $_ ) };
	return 1;
}

sub stoBar {
	my $self	= shift;

	my $bar	= shift;
	push ( @{$self->{bar}}, [ @{$bar} ] );
}

sub stoTag {
	my $self	= shift;
	my $str		= shift;
	my $data	= shift;

	( $str =~ m/\n/ ) && $self->{HLP}->suicide( "tags cannot have newline char" );
	( $str =~ m/['|"|<|>]/ ) && $self->{HLP}->suicide( "'$str' contains invalid chars" );

	my @options 	= split(/ /, $str );
	my $nTag	= shift( @options );
	my $cTagData	= $self->{TAGS}->{$self->{cTag}};
	my $nTagData;
	my $key;
	my $value;

	defined( $data ) &&  ( ( $nTag eq 'input' )  || ( $nTag eq 'tr' ) || ( $nTag eq 'td' ) || ( $nTag eq 'option' ) || $self->{HLP}->suicide( "$nTag cannot accept data param" ) );
	if( $nTag =~ s/^\/// ) {
		( $self->{cTag} eq $nTag ) || $self->{HLP}->suicide("cannot close $nTag while $self->{cTag}");
		if ( $cTagData->{IDENT} ) {
			$self->{SCR} .= "\n";
			$self->{ident}--;
			$self->{nxtIdent} = $self->{ident};
		}

		while ( $self->{nxtIdent} ) {
			$self->{SCR} .= "\t";
			$self->{nxtIdent}--;
		}

		$self->{SCR} .= "</$nTag>";

		if ( $nTagData->{NL} || $nTagData->{IDENT} ) {
			$nTagData->{NL} && $nTagData->{IDENT} && $self->{HLP}->suicide();
			$self->{SCR} .= "\n";
			$self->{nxtIdent} = $self->{ident};
		}

		$self->{tagsHash}->{$nTag}--;
		$self->{cTag} = pop( @{$self->{tagsArray}} );
	}
	else{
		( $nTagData = $self->{TAGS}->{$nTag} ) || $self->{HLP}->suicide( "$nTag is unkown tag" );
		( $self->{tagsHash}->{$nTagData->{REQ}} ) || $self->{HLP}->suicide( "$nTag req. fail ($nTagData->{REQ})" );
		$cTagData->{NESTS}->{$nTag} || $self->{HLP}->suicide( "$self->{cTag} cannot hold $nTag" );
		$self->{tagsHash}->{$nTag} && ( $nTagData->{MULTI} || $self->{HLP}->suicide("Tag $nTag cannot accept multiple open instances") );

		if ( $nTagData->{NL} || $nTagData->{IDENT} ) {
			unless ( $self->{nxtIdent} ) {
				$self->{SCR} .= "\n";
				$self->{nxtIdent} = $self->{ident};
			}
		}

		while( $self->{nxtIdent} ) {
			$self->{SCR} .= "\t";
			$self->{nxtIdent}--;
		}

		$self->{SCR} .= "<$nTag";

		defined( $data ) && ( $self->{SCR} .= " value='" ) && $self->doTxt( $data ) && ( $self->{SCR} .= "'" );
		foreach ( @options ) {
			if ( m/^(\w+)=([^']*)$/ ) {
				$key	= $1;
				$value	= $2;
				if ( lc( $key ) eq 'colspan' ) {
					( ( $self->{cCol} += ( $value - 1 ) ) < $self->{cols} ) || $self->{HLP}->suicide( "not enough cols" );
				}
				
				#	( $key eq 'type' ) && ( defined( $data ) || $self->{HLP}->suicide( "input reqs data param" ) );
			}
			elsif ( m/^(\w+)$/ ) {
				$key = $_;
				$value = undef;
			}
			else {
				$self->{HLP}->suicide( "$_ is invalid option for $nTag - @options" );
			}

			if ( $nTagData->{OPTIONS}->{$key} ) {
				defined( $value ) ? ( $self->{SCR} .= " $key='$value'" ) : ( $self->{SCR} .= " $key" );
			}
			else {
				warn "FATAL ERROR $key is invalid option for $nTag - @options" ;
			}
			$key = undef;
		}

		unless ( $nTagData->{AUTO} ) {
			push( @{$self->{tagsArray}}, $self->{cTag} );
			$self->{cTag} = $nTag;
			$self->{tagsHash}->{$nTag}++;
		}
	
		$self->{SCR} .= ">";

		if ( $nTagData->{IDENT} ) {
			$self->{SCR} .= "\n";
			$self->{ident}++;
			$self->{nxtIdent} = $self->{ident};
		}
		elsif ( $nTagData->{AUTO} && $nTagData->{NL} ) {
			$self->{nxtIdent} && $self->{HLP}->suicide();
			$self->{SCR} .= "\n";
			$self->{nxtIdent} = $self->{ident};
		}
	}
}

sub doTxt {
	my $self	= shift;
	my $txt		= shift;
	my $flags	= shift;

	my $flag = {};
	foreach ( @{$flags} ) {
		( $_ eq 'MULTILINE40' ) || $self->{HLP}->suicide();
		$flag->{"$_"} = 1;
	}

	while ( $self->{nxtIdent} ) {
		$self->{nxtIdent}--;
		$self->{SCR} .= "\t";
	}

	defined( $txt ) || $self->{HLP}->suicide( "text to store is not defined" );
	$txt =~ s/'/&#39;/g;
	$txt =~ s/"/&quot;/g;
	$txt =~ s/</&lt;/g;
	$txt =~ s/>/&gt;/g;
	if ( $txt =~ s/\n/<br>\n/g ) {
		$self->{TAGS}->{$self->{cTag}}->{NESTS}->{br} || $self->{HLP}->suicide( $self->{cTag} );
		( $self->{cTag} eq 'ul' ) && ( $txt =~ s/<br>\n$/\n/ );
		$self->{nxtIdent} = $self->{ident};
	}
	elsif ( $flag->{MULTILINE40} ) {
		my $pos;
		for( $pos = 0; $pos < length( $txt ); $pos += 40 ) {
			$self->{SCR} .= substr( $txt, $pos, 40 );
			$self->{SCR} .= '<br>';
		}
		return;
	}
	$self->{SCR} .= $txt;
}

1;
