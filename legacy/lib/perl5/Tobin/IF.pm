package Tobin::IF;

use strict;
use warnings;
use Rapido::General;
use Rapido::Memory;
use Tobin::functions;

sub new {
  my $param	= shift;
  my $user	= shift;
  my $self 	= {};
  my $class 	= ref( $param ) || $param;
  bless( $self, $class );

  ( defined( $user ) ) || ( $user = 0 );
  $self->{DEBUG} || ( $self->{DEBUG} = 0 );
  $self->{USR}	= $user;
  $self->{CONST}	= Tobin::functions::constantsGet();
  $self->{HLP} 	= new Rapido::General( {	DEBUG			=> $self->{DEBUG}	} );
  $self->{MEM} 	= new Rapido::Memory(	{	DEBUG			=> $self->{DEBUG},
                      HLP				=> $self->{HLP},
                      CONST			=> $self->{CONST},
                      FcnChildUpdate	=> \&Tobin::functions::childUpdate,
                      FcnEntityCheck	=> \&Tobin::functions::entityCheck,
                      FcnEntryDelete	=> \&Tobin::functions::entryDelete,
                      FcnEntryRecycle	=> \&Tobin::functions::entryRecycle,
                      FcnEntrySave	=> \&Tobin::functions::entrySave,
                      FcnExtLinkGet	=> \&Tobin::functions::extLinkGet } );
  $user && $self->{MEM}->userSet( $user );
  return $self;
}

sub compoundAdd {
  my $self	= shift;
  my $names	= shift;
  my $links	= shift;
  my $formula	= shift;
  my $charge  = shift;
  my $errors	= shift;
  my $lnk_to_store;
  my $nms_to_store;
  my $warnings=[];

  @{$links}||die("At least one link required");
  foreach(@{$links}) {
    push( @{$lnk_to_store}, [ $_->{link}, $_->{user} ] );
  }
  @{$names}||die("At least one name required");
  foreach(@{$names}) {
    push( @{$nms_to_store}, [ $_, 0, 0 ] );
  }
  defined($formula)||die("Formula is required");

  my $new_comp=$self->{MEM}->entryObjGet($self->{CONST}->{MY_COMP},0);
  $self->{MEM}->childObjUpdate(
    $new_comp->{CHILDREN}->{'c_nms'},
    $nms_to_store,
    $errors,
    $warnings
  );
  $self->{MEM}->childObjUpdate(
    $new_comp->{CHILDREN}->{'c_lnk'},
    $lnk_to_store,
    $errors,
    $warnings
  );
  $self->{MEM}->childObjUpdate(
    $new_comp->{CHILDREN}->{'c_formula'},
    [[$formula]],
    $errors,
    $warnings
  );
  defined($charge)&&
  $self->{MEM}->childObjUpdate(
    $new_comp->{CHILDREN}->{'c_charge'},
    [[$charge]],
    $errors,
    $warnings
  );
  if( @{$errors} ) {
    foreach( @{$errors} ) {
      warn $_;
    }
    $self->{HLP}->suicide( "Cannot proceed with errors" );
  }

  foreach( @{$warnings} ) {
    warn $_;
  }
  $self->{MEM}->entryObjSave( $new_comp, $errors, $warnings );
}

sub compoundCandidatesGet { #returns ref to array with IDs of all possible candidated
  my $self	= shift;
  my $desc	= shift;
  my $type	= shift;
  defined($type)||($type=0);
  my $field=$type?$self->{CONST}->{MY_COMP_LINKS}:$self->{CONST}->{MY_COMP_NAMES};
  my $noregex	= shift;#if true uses standard mysql wildcards instead of regular expressions

  ( $desc && ( length( $desc ) < 255 ) ) || $self->{HLP}->suicide();

  return $self->{MEM}->entitySearch( $self->{CONST}->{MY_COMP}, $desc,$field , '', $noregex );
}

sub compoundFormulaGet { #returns string with formula
  my $self	= shift;
  my $id		= shift;

  ( $id =~ m/^\d+$/ ) || $self->{HLP}->suicide();
  $self->{MEM}->entryAccessLvlGet( $self->{CONST}->{MY_COMP}, $id ) || $self->{HLP}->suicide( $id );

  return $self->{MEM}->{DBA}->getValue( "SELECT x0 FROM $self->{CONST}->{MY_COMP_FORMULA} WHERE p=$id" );
}

sub compoundChargeGet { #returns string with formula
  my $self	= shift;
  my $id		= shift;

  ( $id =~ m/^\d+$/ ) || $self->{HLP}->suicide();
  $self->{MEM}->entryAccessLvlGet( $self->{CONST}->{MY_COMP}, $id ) || $self->{HLP}->suicide( $id );
#	warn(keys(%{$self->{CONST}}));
#	return 1;

  return $self->{MEM}->{DBA}->getValue( "SELECT x0 FROM $self->{CONST}->{MY_COMP_CHARGE} WHERE p=$id" );
}

sub compoundNameGet { #returns string with compound main name
  my $self	= shift;
  my $id		= shift;

  return $self->{MEM}->entryDefsGet( $self->{CONST}->{MY_COMP}, $id, [ 'MAIN' ] );
}

sub compoundNamesGet { #returns ref to array of strings with main name taking the first position
  my $self	= shift;
  my $id		= shift;

  return $self->{MEM}->entryDefsGet( $self->{CONST}->{MY_COMP}, $id );
}

sub compoundLinksGet {
  my $self	= shift;
  my $id		= shift;

  my $comp_data		=	$self->{MEM}->entryConstDataGet($self->{CONST}->{MY_COMP},$id,);
  my $linktb = $comp_data->{$self->{CONST}->{MY_COMP_LINKS}};
  my $links={};
  foreach(@{$linktb}) {
    $links->{$_->[1]}=$_->[0];
  }
  return $links;
}

sub compoundFormulaUpdate {
  my $self	= shift;
  my $id		= shift;
  my $new_formula = shift;

  my $errors=[];
  my $warnings=[];
  my $compobj=$self->{MEM}->entryObjGet($self->{CONST}->{MY_COMP},$id,);
  $self->{MEM}->childObjUpdate($compobj->{CHILDREN}->{$self->{CONST}->{MY_COMP_FORMULA}},
  [[$new_formula],],$errors,$warnings);
  if( @{$errors} ) {
    foreach( @{$errors} ) {
      warn $_;
    }
    $self->{HLP}->suicide( "Cannot proceed with errors" );
  }
  foreach( @{$warnings} ) {
    warn $_;
  }
  $self->{MEM}->entryObjSave( $compobj, $errors, $warnings );

}

sub compoundChargeUpdate {
  my $self	= shift;
  my $id		= shift;
  my $new_charge = shift;

  my $errors=[];
  my $warnings=[];

  my $compobj=$self->{MEM}->entryObjGet($self->{CONST}->{MY_COMP},$id,);
  $self->{MEM}->childObjUpdate($compobj->{CHILDREN}->{$self->{CONST}->{MY_COMP_CHARGE}},
  [[$new_charge],],$errors,$warnings);
  if( @{$errors} ) {
    foreach( @{$errors} ) {
      warn $_;
    }
    $self->{HLP}->suicide( "Cannot proceed with errors" );
  }
  foreach( @{$warnings} ) {
    warn $_;
  }
  $self->{MEM}->entryObjSave( $compobj, $errors, $warnings );
}

sub transformationAdd {	# returns 0 if successful,
            # returns	-1 if error,
            # returns N ( positive int, transf. code ) if dup

  my $self		= shift;
  my $description	= shift;# String
  my $links		= shift;# [ { user, link }, ... ]
  my $stoich		= shift;# [ { id, sto, ext }, ... ]
  my $names		= shift;# [ main_Name, name, name, ... ]
  my $errors		= shift;# [], will be populated with error messages

  my $MULTI_STOICH_ERR_MSG	= 'Compound cannot be given more than once'
    . ' for each compartment';
  my $TRANSFORMATION_ENTITY	= $self->{CONST}->{MY_TRANSF};
  my $TRANSFORMATION_LINKS	= 't_lnk';
  my $TRANSFORMATION_NAMES	= 't_nms';
  my $TRANSFORMATION_STOICH	= 't_c';
  my $TRANSFORMATION_DEF		= 't_def';


  my $warnings				= [];
  my $reactants				= {};
  my $products				= {};
  my $internals				= {};
  my $externals				= {};
  my $names_to_store			= [];
  my $links_to_store			= [];
  my $stoich_to_store			= [];

  my $compound;
  my $comparison_factor;
  my $compound_id;
  my $compound_ext;
  my $compound_stoich;
  my $transformation_data;
  my $transformation_id;
  my $new_transformation_obj;
  my $link;
  my $name;

  # Data validation and initialization;
  @{$links}
    || $self->{HLP}->suicide( "Link is req" );
  foreach $link ( @{$links} ) {
    push( @{$links_to_store}, [ $link->{link}, $link->{user} ] );
  }

  length( $description )
    || $self->{HLP}->suicide( "Description is req" );

  @{$names}
    || $self->{HLP}->suicide( "Name is req" );
  foreach $name ( @{$names} ) {
    push( @{$names_to_store}, [ $name, 0, 0 ] );
  }

  ref( $errors ) eq 'ARRAY'
    || $self->{HLP}->suicide( "Errors array is req" );

  foreach $compound ( @{$stoich} ) {
    $compound_id		= $compound->{id};
    $compound_ext		= $compound->{ext};
    $compound_stoich	= $compound->{sto};

    $self->compoundNameGet( $compound_id ) || $self->{HLP}->suicide(
      "Unexpected error w/ compound $compound_id" );

    if ( $compound_stoich > 0 ) {
      $products->{$compound_id} = 1;
    }
    elsif ( $compound_stoich < 0 ) {
      $reactants->{$compound_id} = 1;
    }
    else {
      $self->{HLP}->suicide( "Stoichiometry reqs not null value" );
    }

    if ( $compound_ext == 0 ) {
      if ( $internals->{$compound_id} ) {
        $self->{HLP}->suicide( $MULTI_STOICH_ERR_MSG );
      }
      else {
        $internals->{$compound_id} = $compound;
      }
    }
    elsif ( $compound->{ext} == 1 ) {
      if ( $externals->{$compound_id} ) {
        $self->{HLP}->suicide( $MULTI_STOICH_ERR_MSG );
      }
      else {
        $externals->{$compound_id} = $compound;
      }
    }
    else {
      $self->{HLP}->suicide( "Compound 'ext' reqs boolean" );
    }

    push( @{$stoich_to_store},	[
                    $compound_id,
                    $compound_ext,
                    $compound_stoich
                   ]
    );
  }

#	%{$products}
#		|| $self->{HLP}->suicide("At least one compound for product is req");

#	%{$reactants}
#		|| $self->{HLP}->suicide("At least one compound for reactant is req");

  # End


  # Looks for dup transformations
  CHECK_TRANSFORMATION: foreach $transformation_id (
    @{$self->transformationFindByCompounds( $reactants, $products )}
    ){
    $transformation_data = $self->{MEM}->entryConstDataGet(
                  $TRANSFORMATION_ENTITY,
                  $transformation_id
                )->{$self->{CONST}->{MY_TRANSF_COMP}};
    if( scalar( @{$transformation_data} ) == scalar( @{$stoich} ) ) {
      $comparison_factor = 0;

      COMPARE_PAIRWISE: foreach ( @{$transformation_data} ) {
      $_->[2] || $self->{HLP}->suicide(
              'Transformation '
              . $transformation_id
              . ' is invalid'
            );

        if( $_->[1] ) {# Case compound is external
          $compound = $externals->{$_->[0]};
        }
        else {# Case compound is internal
          $compound = $internals->{$_->[0]};
        }

        $compound || last( COMPARE_PAIRWISE );
        if( $comparison_factor ) {
          if ( $compound->{sto} * $comparison_factor != $_->[2] ) {
            $comparison_factor = 0;
            last( COMPARE_PAIRWISE );
          }
        }
        else {
          $comparison_factor = $_->[2] / $compound->{sto};
        }
      }

      if( $comparison_factor ) {
#				$self->{HLP}->suicide( 'Transformation is clone of '
#					. $transformation_id
#				);
        warn('Transformation is clone of '.$transformation_id);
        return;
      }
    }
  }

  # End

  # Tries to store transformation
  $new_transformation_obj =	$self->{MEM}->entryObjGet(
                  $TRANSFORMATION_ENTITY,
                  0
                );
  $self->{MEM}->childObjUpdate(
    $new_transformation_obj->{CHILDREN}->{$TRANSFORMATION_DEF},
    [ [ $description ] ],
    $errors,
    $warnings
  );
  $self->{MEM}->childObjUpdate(
    $new_transformation_obj->{CHILDREN}->{$TRANSFORMATION_LINKS},
    $links_to_store,
    $errors,
    $warnings
  );

  $self->{MEM}->childObjUpdate(
    $new_transformation_obj->{CHILDREN}->{$TRANSFORMATION_NAMES},
    $names_to_store,
    $errors,
    $warnings
  );

  $self->{MEM}->childObjUpdate(
    $new_transformation_obj->{CHILDREN}->{$TRANSFORMATION_STOICH},
    $stoich_to_store,
    $errors,
    $warnings
  );

  if( @{$errors} ) {
    foreach( @{$errors} ) {
      warn $_;
    }
    $self->{HLP}->suicide( "Cannot proceed with errors" );
  }

  foreach( @{$warnings} ) {
    warn $_;
  }

  return $self->{MEM}->entryObjSave( $new_transformation_obj, $errors, $warnings );
  # End
}


sub transformationCandidatesGet { #returns ref to array with IDs of all possible candidates
  my $self	= shift;
  my $desc	= shift;
  my $field	= shift;
  my $noregex	= shift;#if true uses standard mysql wildcards instead of regular expressions

  ( $desc && ( length( $desc ) < 255 ) ) || $self->{HLP}->suicide();
  if(!defined($field)) {
    $field='t_nms';
  }

  return $self->{MEM}->entitySearch( $self->{CONST}->{MY_TRANSF}, $desc, $field, '', $noregex );
}

sub transformationFindByCompounds {#returns ref to array of possible candidates
  my $self		= shift;
  my $reactants	= shift;#hash with ids of required reactants
  my $products	= shift;#hash with ids of required products

  return $self->{MEM}->entitySearchByStoich( $self->{CONST}->{MY_TRANSF_COMP}, $reactants, $products );
}

sub transformationFluxGet {
  my $self	= shift;
  my $Trid	= shift;

  return $self->{fluxes}->{$Trid};
}

sub transformationGet {	# returns /[
            #				(string) Definition,
            #				[ { user, link }, ... ],
            #				[ { id, sto, ext }, ... ],
            #				[ main_Name, name, name, ... ]
            #			]
  my $self				= shift;
  my $transformation_id	= shift;

  my $TRANSFORMATION_ENTITY	= $self->{CONST}->{MY_TRANSF};
  my $TRANSFORMATION_DEF		= 't_def';
  my $TRANSFORMATION_LINKS	= 't_lnk';
  my $TRANSFORMATION_STOICH	= 't_c';
  my $TRANSFORMATION_NAMES	= 't_nms';

  my $output					= [];
  my $main_name				= 0;

  my $transformation_data		=	$self->{MEM}->entryConstDataGet(
                    $TRANSFORMATION_ENTITY,
                    $transformation_id,
                  );

  my $child;
  my $current_record;
  my $new_record;

  $child = $transformation_data->{$TRANSFORMATION_DEF};
  push( @{$output}, $child->[0]->[0] );

  $child = $transformation_data->{$TRANSFORMATION_LINKS};
  push( @{$output}, [] );
  $new_record = $output->[$#{$output}];

  foreach $current_record ( @{$child} ) {
    push( @{$new_record},	{	user => $current_record->[1],
                  link => $current_record->[0],
                }
    );
  }


  $child = $transformation_data->{$TRANSFORMATION_STOICH};
  push( @{$output}, [] );
  $new_record = $output->[$#{$output}];

  foreach $current_record ( @{$child} ) {
    push( @{$new_record},	{	id	=> $current_record->[0],
                  ext	=> $current_record->[1],
                  sto	=> $current_record->[2],
                }
    );
  }

  $child = $transformation_data->{$TRANSFORMATION_NAMES};
  push( @{$output}, [] );
  $new_record = $output->[$#{$output}];

  foreach $current_record ( @{$child} ) {
    if( $current_record->[2] ) {
      $main_name ? $self->{HLP}->suicide( 'UE' ) : ( $main_name = 1 );
    }
    push( @{$new_record},	$current_record->[0] );
  }

  return $output
}
sub transformationDefinitionGet { #returns string with transformation description
  my $self	= shift;
  my $id		= shift;
  ( $id =~ m/^\d+$/ ) || $self->{HLP}->suicide();
  $self->{MEM}->entryAccessLvlGet( $self->{CONST}->{MY_TRANSF}, $id ) || $self->{HLP}->suicide( $id );

  return $self->{MEM}->{DBA}->getValue( "SELECT x0 FROM $self->{CONST}->{MY_TRANSF_DEF} WHERE p=$id" );
}

sub transformationDelete {
  my $self		= shift;
  my $id			= shift;
  my $warnings	= [];
  my $errors		= [];
  my $ToDelete	= $self->{MEM}->entryObjGet($self->{CONST}->{MY_TRANSF},$id);
  $self->{MEM}->entryObjDelete($ToDelete,$errors,$warnings);
  @{$errors} && $self->{HLP}->suicide( "@{$errors}" );
}


sub transformationModify {
  my $self		= shift;
  my $id			= shift;
  my $description	= shift;# String
  my $links		= shift;# [ { user, link }, ... ]
  my $stoich		= shift;# [ { id, sto, ext }, ... ]
  my $names		= shift;# [ main_Name, name, name, ... ]
  my $errors		= shift;# [], will be populated with error messages

  my $MULTI_STOICH_ERR_MSG	= 'Compound cannot be given more than once'
    . ' for each compartment';
  my $TRANSFORMATION_ENTITY	= $self->{CONST}->{MY_TRANSF};
  my $TRANSFORMATION_LINKS	= 't_lnk';
  my $TRANSFORMATION_NAMES	= 't_nms';
  my $TRANSFORMATION_STOICH	= 't_c';
  my $TRANSFORMATION_DEF		= 't_def';

  my $warnings				= [];
  my $reactants				= {};
  my $products				= {};
  my $internals				= {};
  my $externals				= {};
  my $names_to_store			= [];
  my $links_to_store			= [];
  my $stoich_to_store			= [];

  my $compound;
  my $comparison_factor;
  my $compound_id;
  my $compound_ext;
  my $compound_stoich;
  my $transformation_data;
  my $transformation_id;
  my $new_transformation_obj;
  my $link;
  my $name;

  # Data validation and initialization;
  if(defined($links)) {
    foreach $link ( @{$links} ) {
      push( @{$links_to_store}, [ $link->{link}, $link->{user} ] );
    }
  }

  if(defined($names)) {
    foreach $name ( @{$names} ) {
      push( @{$names_to_store}, [ $name, 0, 0 ] );
    }
  }

  ref( $errors ) eq 'ARRAY'
    || $self->{HLP}->suicide( "Errors array is req" );

  if(defined($stoich)) {
    foreach $compound ( @{$stoich} ) {
      $compound_id		= $compound->{id};
      $compound_ext		= $compound->{ext};
      $compound_stoich	= $compound->{sto};

      $self->compoundNameGet( $compound_id ) || $self->{HLP}->suicide(
        "Unexpected error w/ compound $compound_id" );

      if ( $compound_stoich > 0 ) {
        $products->{$compound_id} = 1;
      }
      elsif ( $compound_stoich < 0 ) {
        $reactants->{$compound_id} = 1;
      }
      else {
        $self->{HLP}->suicide( "Stoichiometry reqs not null value" );
      }

      if ( $compound_ext == 0 ) {
        if ( $internals->{$compound_id} ) {
          $self->{HLP}->suicide( $MULTI_STOICH_ERR_MSG );
        }
        else {
          $internals->{$compound_id} = $compound;
        }
      }
      elsif ( $compound->{ext} == 1 ) {
        if ( $externals->{$compound_id} ) {
          $self->{HLP}->suicide( $MULTI_STOICH_ERR_MSG );
        }
        else {
          $externals->{$compound_id} = $compound;
        }
      }
      else {
        $self->{HLP}->suicide( "Compound 'ext' reqs boolean" );
      }

      push( @{$stoich_to_store},	[
                      $compound_id,
                      $compound_ext,
                      $compound_stoich
                     ]
      );
    }

#	%{$products}
#		|| $self->{HLP}->suicide("At least one compound for product is req");

#	%{$reactants}
#		|| $self->{HLP}->suicide("At least one compound for reactant is req");

  # End


  # Looks for dup transformations
#		CHECK_TRANSFORMATION: foreach $transformation_id (
#			@{$self->transformationFindByCompounds( $reactants, $products )}
#			){
#			$transformation_data = $self->{MEM}->entryConstDataGet(
#										$TRANSFORMATION_ENTITY,
#										$transformation_id
#									)->{$self->{CONST}->{MY_TRANSF_COMP}};
#			if( scalar( @{$transformation_data} ) == scalar( @{$stoich} ) ) {
#				$comparison_factor = 0;
#
#				COMPARE_PAIRWISE: foreach ( @{$transformation_data} ) {
#				$_->[2] || $self->{HLP}->suicide(
#								'Transformation '
#								. $transformation_id
#								. ' is invalid'
#							);
#
#					if( $_->[1] ) {# Case compound is external
#						$compound = $externals->{$_->[0]};
#					}
#					else {# Case compound is internal
#						$compound = $internals->{$_->[0]};
#					}
#
#					$compound || last( COMPARE_PAIRWISE );
#					if( $comparison_factor ) {
#						if ( $compound->{sto} * $comparison_factor != $_->[2] ) {
#							$comparison_factor = 0;
#							last( COMPARE_PAIRWISE );
#						}
#					}
#					else {
#						$comparison_factor = $_->[2] / $compound->{sto};
#					}
#				}
#
#				if( $comparison_factor ) {
##				$self->{HLP}->suicide( 'Transformation is clone of '
##					. $transformation_id
##				);
#					warn('Transformation is clone of '.$transformation_id);
##					return;
#				}
#			}
#		}
  }

  # End

  # Tries to store transformation
  $new_transformation_obj =	$self->{MEM}->entryObjGet(
                  $TRANSFORMATION_ENTITY,
                  $id
                  );
  if(defined($description)) {
    $self->{MEM}->childObjUpdate(
      $new_transformation_obj->{CHILDREN}->{$TRANSFORMATION_DEF},
      [ [ $description ] ],
      $errors,
      $warnings
    );
  }

  if(defined($links)) {
    $self->{MEM}->childObjUpdate(
      $new_transformation_obj->{CHILDREN}->{$TRANSFORMATION_LINKS},
      $links_to_store,
      $errors,
      $warnings
    );
  }

  if(defined($names)) {
    $self->{MEM}->childObjUpdate(
      $new_transformation_obj->{CHILDREN}->{$TRANSFORMATION_NAMES},
      $names_to_store,
      $errors,
      $warnings
    );
  }

  if(defined($stoich)) {
    $self->{MEM}->childObjUpdate(
      $new_transformation_obj->{CHILDREN}->{$TRANSFORMATION_STOICH},
      $stoich_to_store,
      $errors,
      $warnings
    );
  }

  if( @{$errors} ) {
    foreach( @{$errors} ) {
      warn $_;
    }
    $self->{HLP}->suicide( "Cannot proceed with errors" );
  }

  foreach( @{$warnings} ) {
    warn $_;
  }

  $self->{MEM}->entryObjSave( $new_transformation_obj, $errors, $warnings );
  # End

}
sub transformationNameGet { #returns string with transformation main name
  my $self	= shift;
  my $id		= shift;	#string Tobin Reaction ID

  return $self->{MEM}->entryDefsGet( $self->{CONST}->{MY_TRANSF}, $id, [ 'MAIN' ] );
}

sub transformationNamesGet {#returns array with all possible transformation names, main name in position 0
  my $self	= shift;
  my $id		= shift;

  return $self->{MEM}->entryDefsGet( $self->{CONST}->{MY_TRANSF}, $id );
}

sub transformationsetCreate {
  my $self		= shift;
  my $name		= shift; #string; definition
  my $set			= shift; # ref to array of transformation IDs, requires one or more elements
  my $entityCode	= $self->{CONST}->{PARENTS}->{$self->{CONST}->{MY_TRANSF}}->{S};
  my $entityDef	= $self->{CONST}->{CHILDREN}->{$entityCode.'_'.$self->{CONST}->{SETS_DEF}};
  my $mem			= $self->{MEM};
  my $log			= $mem->{LOG};
  my $newSet		= $mem->entryObjGet( $entityCode, 0 );
  my $children	= $newSet->{CHILDREN};
  my $errors		= [];
  my $warnings	= [];
  my $newData;
  my $child;

  $self->{USR} || $self->{HLP}->suicide( "this method requires the object to be constructed with an user code as argument" );
  ( length( $name ) < 255 ) || $self->{HLP}->suicide();

  if( @{$set} ) {
    $child		= $children->{$entityDef->{CODE}};
    $newData	= [ [ $name ] ];
    $mem->childObjUpdate( $child, $newData, $errors, $warnings );
    @{$errors} && $self->{HLP}->suicide( "@{$errors}" );

    $child		= $children->{$entityCode.'_'.$self->{CONST}->{SETS_DATE}};
    $newData	= [ [ 'NOW()' ] ];
    $mem->childObjUpdate( $child, $newData, $errors, $warnings );
    @{$errors} && $self->{HLP}->suicide( "@{$errors}" );

    $child		= $children->{$entityCode.'_'.$self->{CONST}->{SETS_USER}};
    $newData	= [ [ $self->{USR} ] ];
    $mem->childObjUpdate( $child, $newData, $errors, $warnings );
    @{$errors} && $self->{HLP}->suicide( "@{$errors}" );

    $child		= $children->{$entityCode.'_'.$self->{CONST}->{SETS_DATA}};
    $newData	= [];
    foreach( @{$set} ) { push( @{$newData}, [ $_ ] ) };
    $mem->childObjUpdate( $child, $newData, $errors, $warnings );
    @{$errors} && $self->{HLP}->suicide( "@{$errors}" );

    $mem->entryObjSave( $newSet, $errors, $warnings );
    foreach ( @{$errors} )		{ warn "FATAL ERROR $_" };
    foreach ( @{$warnings} )	{ warn "WARNING $_"		};
  }
  else {
    $self->{HLP}->suicide( "Set cannot be empty" );
  }
}

sub fbasetGet { #returns ref to matrix = [ [ transf, comp, external, stoich ], ... ]
  my $self		= shift;
  my $set			= shift;
  my $fluxesTbl	= $self->{CONST}->{MY_FBARES_FLUXES};
  my $stoichTbl	= $self->{CONST}->{MY_TRANSF_COMP};
  my $data		= [];

  foreach ( $self->{MEM}->{DBA}->getMatrix( "SELECT $stoichTbl.p, $stoichTbl.x0, $stoichTbl.x1, $stoichTbl.x2 FROM $fluxesTbl LEFT JOIN $stoichTbl ON $stoichTbl.p=$fluxesTbl.x0 WHERE $fluxesTbl.p=$set ORDER BY $stoichTbl.p", $data ) ) {
    push ( @{$data}, [ @{$_} ] );
  }
  %{$self->{fluxes}} = $self->{MEM}->{DBA}->getHash( "SELECT x0, x1 FROM $fluxesTbl WHERE p=$set" );

  return $data;
}

sub fbaresGet { #returns ref to matrix = [ [ transf, comp, external, stoich ], ... ]
  my $self		= shift;
  my $set			= shift;
  my $fluxesTbl	= $self->{CONST}->{MY_FBARES_FLUXES};
  my %data;

  %data= $self->{MEM}->{DBA}->getHash( "SELECT x0, x1 FROM $fluxesTbl WHERE p=$set" );

  return %data;
}


sub transformationsetGet {
  my $self		= shift;
  my $set			= shift;
  my $transformationSet_data = $self->{MEM}->entryConstDataGet( 'v', $set );
  my $child_that_matters = $transformationSet_data->{v_set};
  my $output={};
  my $TransList=[];

  foreach ( @{$child_that_matters} ) {
    push( @{$TransList}, $_->[0]);
  }

  $output->{NAME}=$transformationSet_data->{v_def}->[0]->[0];
  $output->{TRANS}=$TransList;
  return $output;

}

sub userlistGet {
  my $self		= shift;
  my $entityCode	= $self->{CONST}->{USER_PARENT};

  my $users=$self->{MEM}->entityList($entityCode);
  return $users;
}

sub userGet {
  my $self		= shift;
  my $user		= shift;
  my $entityCode	= $self->{CONST}->{USER_PARENT};
  my $nickcode	= $self->{CONST}->{USER_NICK_CHILD};
  my $passcode	= $self->{CONST}->{USER_PASS_CHILD};

  my $userdata = $self->{MEM}->entryConstDataGet($entityCode,$user);
  my $usernick = $userdata->{$nickcode};
  my $userpass = $userdata->{$passcode};
  my $output = {NICK=>(defined($usernick->[0]->[0])?$usernick->[0]->[0]:"###"),
        PASS=>(defined($userpass->[0]->[0])?$userpass->[0]->[0]:"###")};
  return $output;
}

sub userpassUpdate {
  my $self		= shift;
  my $id			= shift;
  my $pass		= shift;
  my $entityCode	= $self->{CONST}->{USER_PARENT};
  my $user		= $self->{MEM}->entryObjGet($entityCode,$id);
  my $new_data	= [[ $pass ]];
  my $errors=[];
  my $warnings=[];
  $self->{MEM}->childObjUpdate($user->{CHILDREN}->{'u_pass'},$new_data,$errors, $warnings );
  @{$errors} && $self->{HLP}->suicide( "@{$errors}" );
  $self->{MEM}->entryObjSave($user,$errors, $warnings );
  foreach ( @{$errors} )		{ warn "FATAL ERROR $_" };
  foreach ( @{$warnings} )	{ warn "WARNING $_"		};
}

sub fbaresultDelete {
  my $self		= shift;
  my $id			= shift;
  my $warnings	= [];
  my $errors		= [];
  my $ToDelete	= $self->{MEM}->entryObjGet($self->{CONST}->{MY_FBARES},$id);
  $self->{MEM}->entryObjDelete($ToDelete,$errors,$warnings);
  @{$errors} && $self->{HLP}->suicide( "@{$errors}" );
}

sub fbaresultExists {
  my $self = shift;
  my $id = shift;
  my $entity = $self->{CONST}->{MY_FBARES};
  $self->{MEM}->{DBA}->getValue( "SELECT id FROM $entity WHERE id=$id " )&&return(1);
  return(0);
}

sub fbasetupCreate {
  my $self		= shift;
  my $name		= shift;
  my $TfSet		= shift;
  my $OpType		= shift;
  my $entityCode	= $self->{CONST}->{MY_FBASET};
  my $userCode	= 'a_u';
  my $nameCode	= 'a_def';
  my $tfCode		= $self->{CONST}->{MY_FBASET_TRANSF};
  my $typeCode	= $self->{CONST}->{MY_FBATYPE};
  my $mem			= $self->{MEM};
  my $newSetup	= $mem->entryObjGet( $entityCode, 0 );
  my $children	= $newSetup->{CHILDREN};
  my $errors		= [];
  my $warnings	= [];
  my $newData;
  my $child;

  $self->{USR} || $self->{HLP}->suicide( "this method requires the object to be constructed with an user code as argument" );
  ( length( $name ) < 255 ) || $self->{HLP}->suicide();

  if(@{$TfSet}) {
    $child		= $children->{$nameCode};
    $newData	= [ [ $name ] ];
    $mem->childObjUpdate( $child, $newData, $errors, $warnings );
    @{$errors} && $self->{HLP}->suicide( "@{$errors}" );

    $child		= $children->{$typeCode};
    $newData	= [ [ $OpType ] ];
    $mem->childObjUpdate( $child, $newData, $errors, $warnings );
    @{$errors} && $self->{HLP}->suicide( "@{$errors}" );

    $child		= $children->{$tfCode};
    $newData	= [];
    foreach(@{$TfSet}) {
      my $TfRow=[];
      for(my $i=0;$i<4;$i++) {
        if(defined($_->[$i])) {
          push(@{$TfRow},$_->[$i]);
        }
        elsif($i==3) {
          push(@{$TfRow},"");
        }
      }
      push(@{$newData},$TfRow);
    }
    $mem->childObjUpdate( $child, $newData, $errors, $warnings );
    @{$errors} && $self->{HLP}->suicide( "@{$errors}" );

    $child		= $children->{$userCode};
    $newData	= [ [ $self->{USR} ] ];
    $mem->childObjUpdate( $child, $newData, $errors, $warnings );
    @{$errors} && $self->{HLP}->suicide( "@{$errors}" );

    $mem->entryObjSave( $newSetup, $errors, $warnings );
    foreach ( @{$errors} )		{ warn "FATAL ERROR $_" };
    foreach ( @{$warnings} )	{ warn "WARNING $_"		};
  }
  else {
    $self->{HLP}->suicide( "FBA setup cannot be empty" );
  }




}

sub fbasetupUpdate {
  my $self		= shift;
  my $id			= shift;
  my $name		= shift;
  my $TfSet		= shift;
  my $OpType		= shift;
  my $entityCode	= $self->{CONST}->{MY_FBASET};
  my $userCode	= 'a_u';
  my $nameCode	= 'a_def';
  my $tfCode		= $self->{CONST}->{MY_FBASET_TRANSF};
  my $typeCode	= $self->{CONST}->{MY_FBATYPE};
  my $mem			= $self->{MEM};
  my $newSetup	= $mem->entryObjGet( $entityCode, $id );
  my $children	= $newSetup->{CHILDREN};
  my $errors		= [];
  my $warnings	= [];
  my $newData;
  my $child;

  $self->{USR} || $self->{HLP}->suicide( "this method requires the object to be constructed with an user code as argument" );

  if(defined($name)) {
    ( length( $name ) < 255 ) || $self->{HLP}->suicide();
    $child		= $children->{$nameCode};
    $newData	= [ [ $name ] ];
    $mem->childObjUpdate( $child, $newData, $errors, $warnings );
    @{$errors} && $self->{HLP}->suicide( "@{$errors}" );
  }
  if(defined($OpType)) {
    $child		= $children->{$typeCode};
    $newData	= [ [ $OpType ] ];
    $mem->childObjUpdate( $child, $newData, $errors, $warnings );
    @{$errors} && $self->{HLP}->suicide( "@{$errors}" );
  }
  if(defined($TfSet)) {
    $child		= $children->{$tfCode};
    $newData	= [];
    foreach(@{$TfSet}) {
      my $TfRow=[];
      for(my $i=0;$i<4;$i++) {
        if(defined($_->[$i])) {
          push(@{$TfRow},$_->[$i]);
        }
        elsif($i==3) {
          push(@{$TfRow},"");
        }
      }
      push(@{$newData},$TfRow);
    }
    $mem->childObjUpdate( $child, $newData, $errors, $warnings );
    @{$errors} && $self->{HLP}->suicide( "@{$errors}" );
  }

#		$child		= $children->{$userCode};
#		$newData	= [ [ $self->{USR} ] ];
#		$mem->childObjUpdate( $child, $newData, $errors, $warnings );
#		@{$errors} && $self->{HLP}->suicide( "@{$errors}" );
#
    $mem->entryObjSave( $newSetup, $errors, $warnings );
    foreach ( @{$errors} )		{ warn "FATAL ERROR $_" };
    foreach ( @{$warnings} )	{ warn "WARNING $_"		};
    return 0;

}

sub fbasetupGet {
  my $self		= shift;
  my $id			= shift;
  my $entityCode	= $self->{CONST}->{MY_FBASET};
  my $userCode	= 'a_u';
  my $nameCode	= 'a_def';
  my $tfCode		= $self->{CONST}->{MY_FBASET_TRANSF};
  my $typeCode	= $self->{CONST}->{MY_FBATYPE};

  my $fbasetupData = $self->{MEM}->entryConstDataGet($entityCode,$id);
  my $tfSet=[];
  foreach(@{$fbasetupData->{$tfCode}}) {
    push(@{$tfSet}, [$_->[0],$_->[1],$_->[2],$_->[3]]);
  }
  my $output = {NAME=>$fbasetupData->{$nameCode}->[0]->[0],USER=>$fbasetupData->{$userCode}->[0]->[0],
    TYPE=>$fbasetupData->{$typeCode}->[0]->[0], TFSET=>$tfSet };
  return $output;
}



1;

