package Tobin::family;

use strict;
use warnings;

use Carp qw(confess);
use Readonly;

my $CHILDREN	= {};
my $PARENTS		= {};
Readonly my $TOBIN_INSTANCE => $ENV{'TOBIN_INSTANCE'}
  or confess{'TOBIN_INSTANCE not in ENV'};
Readonly my $DB_HOST => $ENV{'TOBIN_DB_HOST'}
  or confess{'TOBIN_DB_HOST not in ENV'};
Readonly my $DB_DATA => $ENV{'TOBIN_DB_DATA'}
  or confess{'TOBIN_DB_DATA not in ENV'};
Readonly my $DB_USER => $ENV{'TOBIN_DB_USER'}
  or confess('TOBIN_DB_USER not in ENV');
Readonly my $DB_PASS => $ENV{'TOBIN_DB_PASS'}
  or confess('TOBIN_DB_PASS not in ENV');

$PARENTS->{a} = {
  CODE		=> 'a',
  NAME		=> 'FBA Setup',
  PRIORITY	=> '0',
  S			=> '',
  NXT			=> '',
  DEF			=> 'a_def',
  OWNERTBL	=> 'a_u',
  FLAGS		=> { NOLOG => 1 },
  SETUP		=> '',
  MODELS		=> [ 'fba' ]
};

$CHILDREN->{a_def} = {
  PARENT		=> 'a',
  CODE		=> 'a_def',
  NAME		=> 'definition',
  TYPE		=> 'SINGLE',
  FIELDS		=> [ 'VALUE' ],
  IDS			=> [],
  LABELS		=> [ 'Definition' ],
  UNCLES		=> [],
  REQS		=> [ '0' ],
  DISPLAY		=> [ '0=32' ],
  DEFAULTS	=> [],
  SEARCH		=> '1',
  PRIORITY	=> '1',
  ALLOWS		=> [],
  FLAGS		=> { NOLOG => 1 }
};

$PARENTS->{a}->{CHILDREN}->{a_def} = $CHILDREN->{a_def};

$CHILDREN->{a_u} = {
  PARENT		=> 'a',
  CODE		=> 'a_u',
  NAME		=> 'User',
  TYPE		=> 'SINGLE',
  FIELDS		=> [ 'USER' ],
  IDS			=> [],
  LABELS		=> [ 'User' ],
  UNCLES		=> [ 'u' ],
  REQS		=> [ '0' ],
  DISPLAY		=> [ '0' ],
  DEFAULTS	=> [ '999' ],
  SEARCH		=> '0',
  PRIORITY	=> '2',
  ALLOWS		=> [ '0,999' ],
  FLAGS		=> { NOLOG => 1 }
};

$PARENTS->{a}->{CHILDREN}->{a_u} = $CHILDREN->{a_u};

$CHILDREN->{a_type} = {
  PARENT		=> 'a',
  CODE		=> 'a_type',
  NAME		=> 'Optimization Type',
  TYPE		=> 'SINGLE',
  FIELDS		=> [ 'VALUE' ],
  IDS			=> [],
  LABELS		=> [ 'Minimize,Maximize' ],
  UNCLES		=> [],
  REQS		=> [ '0' ],
  DISPLAY		=> [ '0' ],
  DEFAULTS	=> [ '1' ],
  SEARCH		=> '0',
  PRIORITY	=> '4',
  ALLOWS		=> [ '1,2' ],
  FLAGS		=> { NOLOG => 1 }
};

$PARENTS->{a}->{CHILDREN}->{a_type} = $CHILDREN->{a_type};

$CHILDREN->{a_t} = {
  PARENT		=> 'a',
  CODE		=> 'a_t',
  NAME		=> 'Transformations',
  TYPE		=> 'SET',
  FIELDS		=> [ 'VALUE', 'MAIN', 'VALUE', 'VALUE' ],
  IDS			=> [ '0' ],
  LABELS		=> [ 'Transformation', 'Obj', 'Min', 'Max' ],
  UNCLES		=> [ 't' ],
  REQS		=> [ '0' ],
  DISPLAY		=> [ '1', '0=10', '2=6', '3=6' ],
  DEFAULTS	=> [ '', '0', '0' ],
  SEARCH		=> '0',
  PRIORITY	=> '5',
  ALLOWS		=> [ '', '0,1' ],
  FLAGS		=> { PAGE => 1, NOLOG => 1 }
};

$PARENTS->{a}->{CHILDREN}->{a_t} = $CHILDREN->{a_t};


$PARENTS->{u} = {
  CODE		=> 'u',
  NAME		=> 'Users',
  PRIORITY	=> '0',
  S			=> '',
  NXT			=> '',
  DEF			=> 'u_nick',
  OWNERTBL	=> '',
  FLAGS		=> { ADMIN => 1 },
  SETUP		=> '',
  MODELS		=> []
};

$CHILDREN->{u_nick} = {
  PARENT		=> 'u',
  CODE		=> 'u_nick',
  NAME		=> 'Nick',
  TYPE		=> 'SINGLE',
  FIELDS		=> [ 'VALUE' ],
  IDS			=> [],
  LABELS		=> [ 'Nick' ],
  UNCLES		=> [],
  REQS		=> [ '0' ],
  DISPLAY		=> [ '0=10' ],
  DEFAULTS	=> [],
  SEARCH		=> '1',
  PRIORITY	=> '1',
  ALLOWS		=> [],
  FLAGS		=> { NOBLANK => 1, NOLOG => 1 }
};

$PARENTS->{u}->{CHILDREN}->{u_nick} = $CHILDREN->{u_nick};

$CHILDREN->{u_pass} = {
  PARENT		=> 'u',
  CODE		=> 'u_pass',
  NAME		=> 'Password',
  TYPE		=> 'SINGLE',
  FIELDS		=> [ 'VALUE' ],
  IDS			=> [],
  LABELS		=> [ 'Password' ],
  UNCLES		=> [],
  REQS		=> [ '0' ],
  DISPLAY		=> [ '0=10' ],
  DEFAULTS	=> [],
  SEARCH		=> '0',
  PRIORITY	=> '1',
  ALLOWS		=> [],
  FLAGS		=> { NOLOG => 1, NOBLANK => 1 }
};

$PARENTS->{u}->{CHILDREN}->{u_pass} = $CHILDREN->{u_pass};


$PARENTS->{q} = {
  CODE		=> 'q',
  NAME		=> 'ProtSet',
  PRIORITY	=> '0',
  S			=> '',
  NXT			=> '',
  DEF			=> 'q_def',
  OWNERTBL	=> 'q_u',
  FLAGS		=> { NOLOG => 1 },
  SETUP		=> '',
  MODELS		=> []
};

$CHILDREN->{q_date} = {
  PARENT		=> 'q',
  CODE		=> 'q_date',
  NAME		=> 'Date',
  TYPE		=> 'SINGLE',
  FIELDS		=> [ 'VALUE' ],
  IDS			=> [],
  LABELS		=> [ 'Date' ],
  UNCLES		=> [],
  REQS		=> [ '0' ],
  DISPLAY		=> [ '0' ],
  DEFAULTS	=> [],
  SEARCH		=> '0',
  PRIORITY	=> '1',
  ALLOWS		=> [],
  FLAGS		=> { NOLOG => 1, RO => 1 }
};

$PARENTS->{q}->{CHILDREN}->{q_date} = $CHILDREN->{q_date};

$CHILDREN->{q_def} = {
  PARENT		=> 'q',
  CODE		=> 'q_def',
  NAME		=> 'definition',
  TYPE		=> 'SINGLE',
  FIELDS		=> [ 'VALUE' ],
  IDS			=> [],
  LABELS		=> [ 'Definition' ],
  UNCLES		=> [],
  REQS		=> [ '0' ],
  DISPLAY		=> [ '0=32' ],
  DEFAULTS	=> [],
  SEARCH		=> '1',
  PRIORITY	=> '1',
  ALLOWS		=> [],
  FLAGS		=> { NOLOG => 1 }
};

$PARENTS->{q}->{CHILDREN}->{q_def} = $CHILDREN->{q_def};

$CHILDREN->{q_set} = {
  PARENT		=> 'q',
  CODE		=> 'q_set',
  NAME		=> 'Proteins',
  TYPE		=> 'SET',
  FIELDS		=> [ 'VALUE' ],
  IDS			=> [ '0' ],
  LABELS		=> [ 'Proteins' ],
  UNCLES		=> [ 'p' ],
  REQS		=> [ '0' ],
  DISPLAY		=> [ '0=10' ],
  DEFAULTS	=> [],
  SEARCH		=> '0',
  PRIORITY	=> '1',
  ALLOWS		=> [],
  FLAGS		=> { NOLOG => 1, PAGE => 1 }
};

$PARENTS->{q}->{CHILDREN}->{q_set} = $CHILDREN->{q_set};

$CHILDREN->{q_u} = {
  PARENT		=> 'q',
  CODE		=> 'q_u',
  NAME		=> 'User',
  TYPE		=> 'SINGLE',
  FIELDS		=> [ 'USER' ],
  IDS			=> [],
  LABELS		=> [ 'User' ],
  UNCLES		=> [ 'u' ],
  REQS		=> [ '0' ],
  DISPLAY		=> [ '0' ],
  DEFAULTS	=> [ '999' ],
  SEARCH		=> '0',
  PRIORITY	=> '1',
  ALLOWS		=> [ '0,999' ],
  FLAGS		=> { NOLOG => 1 }
};

$PARENTS->{q}->{CHILDREN}->{q_u} = $CHILDREN->{q_u};


$PARENTS->{n} = {
  CODE		=> 'n',
  NAME		=> 'GenomeSet',
  PRIORITY	=> '0',
  S			=> '',
  NXT			=> '',
  DEF			=> 'n_def',
  OWNERTBL	=> 'n_u',
  FLAGS		=> { NOLOG => 1 },
  SETUP		=> '',
  MODELS		=> []
};

$CHILDREN->{n_date} = {
  PARENT		=> 'n',
  CODE		=> 'n_date',
  NAME		=> 'Date',
  TYPE		=> 'SINGLE',
  FIELDS		=> [ 'VALUE' ],
  IDS			=> [],
  LABELS		=> [ 'Date' ],
  UNCLES		=> [],
  REQS		=> [ '0' ],
  DISPLAY		=> [ '0' ],
  DEFAULTS	=> [],
  SEARCH		=> '0',
  PRIORITY	=> '1',
  ALLOWS		=> [],
  FLAGS		=> { NOLOG => 1, RO => 1 }
};

$PARENTS->{n}->{CHILDREN}->{n_date} = $CHILDREN->{n_date};

$CHILDREN->{n_def} = {
  PARENT		=> 'n',
  CODE		=> 'n_def',
  NAME		=> 'definition',
  TYPE		=> 'SINGLE',
  FIELDS		=> [ 'VALUE' ],
  IDS			=> [],
  LABELS		=> [ 'Definition' ],
  UNCLES		=> [],
  REQS		=> [ '0' ],
  DISPLAY		=> [ '0=32' ],
  DEFAULTS	=> [],
  SEARCH		=> '1',
  PRIORITY	=> '1',
  ALLOWS		=> [],
  FLAGS		=> { NOLOG => 1 }
};

$PARENTS->{n}->{CHILDREN}->{n_def} = $CHILDREN->{n_def};

$CHILDREN->{n_set} = {
  PARENT		=> 'n',
  CODE		=> 'n_set',
  NAME		=> 'Genomes',
  TYPE		=> 'SET',
  FIELDS		=> [ 'VALUE' ],
  IDS			=> [ '0' ],
  LABELS		=> [ 'Genomes' ],
  UNCLES		=> [ 'o' ],
  REQS		=> [ '0' ],
  DISPLAY		=> [ '0=10' ],
  DEFAULTS	=> [],
  SEARCH		=> '0',
  PRIORITY	=> '1',
  ALLOWS		=> [],
  FLAGS		=> { NOLOG => 1, PAGE => 1 }
};

$PARENTS->{n}->{CHILDREN}->{n_set} = $CHILDREN->{n_set};

$CHILDREN->{n_u} = {
  PARENT		=> 'n',
  CODE		=> 'n_u',
  NAME		=> 'User',
  TYPE		=> 'SINGLE',
  FIELDS		=> [ 'USER' ],
  IDS			=> [],
  LABELS		=> [ 'User' ],
  UNCLES		=> [ 'u' ],
  REQS		=> [ '0' ],
  DISPLAY		=> [ '0' ],
  DEFAULTS	=> [ '999' ],
  SEARCH		=> '0',
  PRIORITY	=> '1',
  ALLOWS		=> [ '0,999' ],
  FLAGS		=> { NOLOG => 1 }
};

$PARENTS->{n}->{CHILDREN}->{n_u} = $CHILDREN->{n_u};


$PARENTS->{h} = {
  CODE		=> 'h',
  NAME		=> 'GeneSet',
  PRIORITY	=> '0',
  S			=> '',
  NXT			=> '',
  DEF			=> 'h_def',
  OWNERTBL	=> 'h_u',
  FLAGS		=> { NOLOG => 1 },
  SETUP		=> '',
  MODELS		=> []
};

$CHILDREN->{h_date} = {
  PARENT		=> 'h',
  CODE		=> 'h_date',
  NAME		=> 'Date',
  TYPE		=> 'SINGLE',
  FIELDS		=> [ 'VALUE' ],
  IDS			=> [],
  LABELS		=> [ 'Date' ],
  UNCLES		=> [],
  REQS		=> [ '0' ],
  DISPLAY		=> [ '0' ],
  DEFAULTS	=> [],
  SEARCH		=> '0',
  PRIORITY	=> '1',
  ALLOWS		=> [],
  FLAGS		=> { NOLOG => 1, RO => 1 }
};

$PARENTS->{h}->{CHILDREN}->{h_date} = $CHILDREN->{h_date};

$CHILDREN->{h_def} = {
  PARENT		=> 'h',
  CODE		=> 'h_def',
  NAME		=> 'definition',
  TYPE		=> 'SINGLE',
  FIELDS		=> [ 'VALUE' ],
  IDS			=> [],
  LABELS		=> [ 'Definition' ],
  UNCLES		=> [],
  REQS		=> [ '0' ],
  DISPLAY		=> [ '0=32' ],
  DEFAULTS	=> [],
  SEARCH		=> '1',
  PRIORITY	=> '1',
  ALLOWS		=> [],
  FLAGS		=> { NOLOG => 1 }
};

$PARENTS->{h}->{CHILDREN}->{h_def} = $CHILDREN->{h_def};

$CHILDREN->{h_set} = {
  PARENT		=> 'h',
  CODE		=> 'h_set',
  NAME		=> 'Genes',
  TYPE		=> 'SET',
  FIELDS		=> [ 'VALUE' ],
  IDS			=> [ '0' ],
  LABELS		=> [ 'Genes' ],
  UNCLES		=> [ 'g' ],
  REQS		=> [ '0' ],
  DISPLAY		=> [ '0=10' ],
  DEFAULTS	=> [],
  SEARCH		=> '0',
  PRIORITY	=> '1',
  ALLOWS		=> [],
  FLAGS		=> { NOLOG => 1, PAGE => 1 }
};

$PARENTS->{h}->{CHILDREN}->{h_set} = $CHILDREN->{h_set};

$CHILDREN->{h_u} = {
  PARENT		=> 'h',
  CODE		=> 'h_u',
  NAME		=> 'User',
  TYPE		=> 'SINGLE',
  FIELDS		=> [ 'USER' ],
  IDS			=> [],
  LABELS		=> [ 'User' ],
  UNCLES		=> [ 'u' ],
  REQS		=> [ '0' ],
  DISPLAY		=> [ '0' ],
  DEFAULTS	=> [ '999' ],
  SEARCH		=> '0',
  PRIORITY	=> '1',
  ALLOWS		=> [ '0,999' ],
  FLAGS		=> { NOLOG => 1 }
};

$PARENTS->{h}->{CHILDREN}->{h_u} = $CHILDREN->{h_u};


$PARENTS->{fba} = {
  CODE		=> 'fba',
  NAME		=> 'FBA Simulation',
  PRIORITY	=> '0',
  S			=> '',
  NXT			=> '',
  DEF			=> 'fba_status',
  OWNERTBL	=> 'fba_u',
  FLAGS		=> { NOLOG => 1 },
  SETUP		=> 'a',
  MODELS		=> []
};

$CHILDREN->{fba_a} = {
  PARENT		=> 'fba',
  CODE		=> 'fba_a',
  NAME		=> 'Used Setup',
  TYPE		=> 'SINGLE',
  FIELDS		=> [ 'VALUE' ],
  IDS			=> [],
  LABELS		=> [ 'Setup' ],
  UNCLES		=> [ 'a' ],
  REQS		=> [ '0' ],
  DISPLAY		=> [ '0' ],
  DEFAULTS	=> [ '0' ],
  SEARCH		=> '0',
  PRIORITY	=> '1',
  ALLOWS		=> [],
  FLAGS		=> { NOLOG => 1, RO => 1 }
};

$PARENTS->{fba}->{CHILDREN}->{fba_a} = $CHILDREN->{fba_a};

$CHILDREN->{fba_date} = {
  PARENT		=> 'fba',
  CODE		=> 'fba_date',
  NAME		=> 'Last Update',
  TYPE		=> 'SINGLE',
  FIELDS		=> [ 'VALUE' ],
  IDS			=> [],
  LABELS		=> [ 'Date' ],
  UNCLES		=> [],
  REQS		=> [ '0' ],
  DISPLAY		=> [ '0' ],
  DEFAULTS	=> [ 'NOW' ],
  SEARCH		=> '0',
  PRIORITY	=> '1',
  ALLOWS		=> [],
  FLAGS		=> { NOLOG => 1, RO => 1 }
};

$PARENTS->{fba}->{CHILDREN}->{fba_date} = $CHILDREN->{fba_date};

$CHILDREN->{fba_elapsed} = {
  PARENT		=> 'fba',
  CODE		=> 'fba_elapsed',
  NAME		=> 'Simulation Time',
  TYPE		=> 'SINGLE',
  FIELDS		=> [ 'VALUE' ],
  IDS			=> [],
  LABELS		=> [ 'Time' ],
  UNCLES		=> [],
  REQS		=> [ '0' ],
  DISPLAY		=> [ '0' ],
  DEFAULTS	=> [],
  SEARCH		=> '0',
  PRIORITY	=> '1',
  ALLOWS		=> [],
  FLAGS		=> { RO => 1, NOLOG => 1 }
};

$PARENTS->{fba}->{CHILDREN}->{fba_elapsed} = $CHILDREN->{fba_elapsed};

$CHILDREN->{fba_log} = {
  PARENT		=> 'fba',
  CODE		=> 'fba_log',
  NAME		=> 'Simulation Log',
  TYPE		=> 'SERIE',
  FIELDS		=> [ 'VALUE', 'SERIAL' ],
  IDS			=> [ '1' ],
  LABELS		=> [ 'Message', 'Serial' ],
  UNCLES		=> [],
  REQS		=> [],
  DISPLAY		=> [ '', '0=255' ],
  DEFAULTS	=> [ '', '0' ],
  SEARCH		=> '0',
  PRIORITY	=> '1',
  ALLOWS		=> [],
  FLAGS		=> { NOLOG => 1, RO => 1 }
};

$PARENTS->{fba}->{CHILDREN}->{fba_log} = $CHILDREN->{fba_log};

$CHILDREN->{fba_status} = {
  PARENT		=> 'fba',
  CODE		=> 'fba_status',
  NAME		=> 'Simulation Status',
  TYPE		=> 'SINGLE',
  FIELDS		=> [ 'VALUE' ],
  IDS			=> [],
  LABELS		=> [ 'Status' ],
  UNCLES		=> [],
  REQS		=> [ '0' ],
  DISPLAY		=> [ '0=50' ],
  DEFAULTS	=> [],
  SEARCH		=> '0',
  PRIORITY	=> '1',
  ALLOWS		=> [],
  FLAGS		=> { NOLOG => 1 }
};

$PARENTS->{fba}->{CHILDREN}->{fba_status} = $CHILDREN->{fba_status};

$CHILDREN->{fba_u} = {
  PARENT		=> 'fba',
  CODE		=> 'fba_u',
  NAME		=> 'User',
  TYPE		=> 'SINGLE',
  FIELDS		=> [ 'USER' ],
  IDS			=> [],
  LABELS		=> [ 'User' ],
  UNCLES		=> [ 'u' ],
  REQS		=> [ '0' ],
  DISPLAY		=> [ '0' ],
  DEFAULTS	=> [ '999' ],
  SEARCH		=> '0',
  PRIORITY	=> '2',
  ALLOWS		=> [ '0,999' ],
  FLAGS		=> { NOLOG => 1 }
};

$PARENTS->{fba}->{CHILDREN}->{fba_u} = $CHILDREN->{fba_u};

$CHILDREN->{fba_fluxes} = {
  PARENT		=> 'fba',
  CODE		=> 'fba_fluxes',
  NAME		=> 'Fluxes',
  TYPE		=> 'SET',
  FIELDS		=> [ 'VALUE', 'VALUE' ],
  IDS			=> [ '0' ],
  LABELS		=> [ 'Transformation', 'Flux' ],
  UNCLES		=> [ 't' ],
  REQS		=> [ '0' ],
  DISPLAY		=> [ '0=0', '1=0' ],
  DEFAULTS	=> [ '0', '0' ],
  SEARCH		=> '0',
  PRIORITY	=> '5',
  ALLOWS		=> [],
  FLAGS		=> { PAGE => 1, NOLOG => 1, RO => 1, MAP => 1 }
};

$PARENTS->{fba}->{CHILDREN}->{fba_fluxes} = $CHILDREN->{fba_fluxes};


$PARENTS->{f} = {
  CODE		=> 'f',
  NAME		=> 'EnzSet',
  PRIORITY	=> '0',
  S			=> '',
  NXT			=> '',
  DEF			=> 'f_def',
  OWNERTBL	=> 'f_u',
  FLAGS		=> { NOLOG => 1 },
  SETUP		=> '',
  MODELS		=> []
};

$CHILDREN->{f_date} = {
  PARENT		=> 'f',
  CODE		=> 'f_date',
  NAME		=> 'Date',
  TYPE		=> 'SINGLE',
  FIELDS		=> [ 'VALUE' ],
  IDS			=> [],
  LABELS		=> [ 'Date' ],
  UNCLES		=> [],
  REQS		=> [ '0' ],
  DISPLAY		=> [ '0' ],
  DEFAULTS	=> [],
  SEARCH		=> '0',
  PRIORITY	=> '1',
  ALLOWS		=> [],
  FLAGS		=> { NOLOG => 1, RO => 1 }
};

$PARENTS->{f}->{CHILDREN}->{f_date} = $CHILDREN->{f_date};

$CHILDREN->{f_def} = {
  PARENT		=> 'f',
  CODE		=> 'f_def',
  NAME		=> 'definition',
  TYPE		=> 'SINGLE',
  FIELDS		=> [ 'VALUE' ],
  IDS			=> [],
  LABELS		=> [ 'Definition' ],
  UNCLES		=> [],
  REQS		=> [ '0' ],
  DISPLAY		=> [ '0=32' ],
  DEFAULTS	=> [],
  SEARCH		=> '1',
  PRIORITY	=> '1',
  ALLOWS		=> [],
  FLAGS		=> { NOLOG => 1 }
};

$PARENTS->{f}->{CHILDREN}->{f_def} = $CHILDREN->{f_def};

$CHILDREN->{f_set} = {
  PARENT		=> 'f',
  CODE		=> 'f_set',
  NAME		=> 'Enzymes',
  TYPE		=> 'SET',
  FIELDS		=> [ 'VALUE' ],
  IDS			=> [ '0' ],
  LABELS		=> [ 'Enzymes' ],
  UNCLES		=> [ 'e' ],
  REQS		=> [ '0' ],
  DISPLAY		=> [ '0=10' ],
  DEFAULTS	=> [],
  SEARCH		=> '0',
  PRIORITY	=> '1',
  ALLOWS		=> [],
  FLAGS		=> { NOLOG => 1, PAGE => 1 }
};

$PARENTS->{f}->{CHILDREN}->{f_set} = $CHILDREN->{f_set};

$CHILDREN->{f_u} = {
  PARENT		=> 'f',
  CODE		=> 'f_u',
  NAME		=> 'User',
  TYPE		=> 'SINGLE',
  FIELDS		=> [ 'USER' ],
  IDS			=> [],
  LABELS		=> [ 'User' ],
  UNCLES		=> [ 'u' ],
  REQS		=> [ '0' ],
  DISPLAY		=> [ '0' ],
  DEFAULTS	=> [ '999' ],
  SEARCH		=> '0',
  PRIORITY	=> '1',
  ALLOWS		=> [ '0,999' ],
  FLAGS		=> { NOLOG => 1 }
};

$PARENTS->{f}->{CHILDREN}->{f_u} = $CHILDREN->{f_u};


$PARENTS->{b} = {
  CODE		=> 'b',
  NAME		=> 'Bookmark',
  PRIORITY	=> '0',
  S			=> '',
  NXT			=> '',
  DEF			=> 'b_key',
  OWNERTBL	=> 'b_u',
  FLAGS		=> { TREE => 1, FIXED => 1, ELINK => 1, NOLOG => 1 },
  SETUP		=> '',
  MODELS		=> []
};

$CHILDREN->{b_u} = {
  PARENT		=> 'b',
  CODE		=> 'b_u',
  NAME		=> 'Owner',
  TYPE		=> 'SINGLE',
  FIELDS		=> [ 'USER' ],
  IDS			=> [],
  LABELS		=> [ 'Owner' ],
  UNCLES		=> [ 'u' ],
  REQS		=> [ '0' ],
  DISPLAY		=> [ '0' ],
  DEFAULTS	=> [ '0' ],
  SEARCH		=> '0',
  PRIORITY	=> '1',
  ALLOWS		=> [ '0' ],
  FLAGS		=> { NOLOG => 1 }
};

$PARENTS->{b}->{CHILDREN}->{b_u} = $CHILDREN->{b_u};

$CHILDREN->{b_parent} = {
  PARENT		=> 'b',
  CODE		=> 'b_parent',
  NAME		=> 'Parent',
  TYPE		=> 'SET',
  FIELDS		=> [ 'VALUE' ],
  IDS			=> [ '0' ],
  LABELS		=> [ 'Parent' ],
  UNCLES		=> [ 'b' ],
  REQS		=> [],
  DISPLAY		=> [ '0' ],
  DEFAULTS	=> [ '0' ],
  SEARCH		=> '0',
  PRIORITY	=> '2',
  ALLOWS		=> [],
  FLAGS		=> { NOLOG => 1 }
};

$PARENTS->{b}->{CHILDREN}->{b_parent} = $CHILDREN->{b_parent};

$CHILDREN->{b_key} = {
  PARENT		=> 'b',
  CODE		=> 'b_key',
  NAME		=> 'Key',
  TYPE		=> 'SINGLE',
  FIELDS		=> [ 'VALUE' ],
  IDS			=> [],
  LABELS		=> [ 'Caption' ],
  UNCLES		=> [],
  REQS		=> [ '0' ],
  DISPLAY		=> [ '0=75' ],
  DEFAULTS	=> [],
  SEARCH		=> '0',
  PRIORITY	=> '3',
  ALLOWS		=> [],
  FLAGS		=> { NOLOG => 1 }
};

$PARENTS->{b}->{CHILDREN}->{b_key} = $CHILDREN->{b_key};

$CHILDREN->{b_value} = {
  PARENT		=> 'b',
  CODE		=> 'b_value',
  NAME		=> 'Value',
  TYPE		=> 'SINGLE',
  FIELDS		=> [ 'VALUE' ],
  IDS			=> [],
  LABELS		=> [ 'Hyperlink' ],
  UNCLES		=> [],
  REQS		=> [],
  DISPLAY		=> [ '0=100' ],
  DEFAULTS	=> [],
  SEARCH		=> '0',
  PRIORITY	=> '4',
  ALLOWS		=> [],
  FLAGS		=> { NOBLANK => 1, NOLOG => 1 }
};

$PARENTS->{b}->{CHILDREN}->{b_value} = $CHILDREN->{b_value};


$PARENTS->{v} = {
  CODE		=> 'v',
  NAME		=> 'Transf. Set',
  PRIORITY	=> '0',
  S			=> '',
  NXT			=> '',
  DEF			=> 'v_def',
  OWNERTBL	=> 'v_u',
  FLAGS		=> { NOLOG => 1 },
  SETUP		=> '',
  MODELS		=> []
};

$CHILDREN->{v_date} = {
  PARENT		=> 'v',
  CODE		=> 'v_date',
  NAME		=> 'Date',
  TYPE		=> 'SINGLE',
  FIELDS		=> [ 'VALUE' ],
  IDS			=> [],
  LABELS		=> [ 'Date' ],
  UNCLES		=> [],
  REQS		=> [ '0' ],
  DISPLAY		=> [ '0' ],
  DEFAULTS	=> [],
  SEARCH		=> '0',
  PRIORITY	=> '1',
  ALLOWS		=> [],
  FLAGS		=> { NOLOG => 1, RO => 1 }
};

$PARENTS->{v}->{CHILDREN}->{v_date} = $CHILDREN->{v_date};

$CHILDREN->{v_def} = {
  PARENT		=> 'v',
  CODE		=> 'v_def',
  NAME		=> 'definition',
  TYPE		=> 'SINGLE',
  FIELDS		=> [ 'VALUE' ],
  IDS			=> [],
  LABELS		=> [ 'Definition' ],
  UNCLES		=> [],
  REQS		=> [ '0' ],
  DISPLAY		=> [ '0=32' ],
  DEFAULTS	=> [],
  SEARCH		=> '1',
  PRIORITY	=> '1',
  ALLOWS		=> [],
  FLAGS		=> { NOLOG => 1 }
};

$PARENTS->{v}->{CHILDREN}->{v_def} = $CHILDREN->{v_def};

$CHILDREN->{v_set} = {
  PARENT		=> 'v',
  CODE		=> 'v_set',
  NAME		=> 'Transformations',
  TYPE		=> 'SET',
  FIELDS		=> [ 'VALUE' ],
  IDS			=> [ '0' ],
  LABELS		=> [ 'Transformations' ],
  UNCLES		=> [ 't' ],
  REQS		=> [ '0' ],
  DISPLAY		=> [ '0=10' ],
  DEFAULTS	=> [],
  SEARCH		=> '0',
  PRIORITY	=> '1',
  ALLOWS		=> [],
  FLAGS		=> { NOLOG => 1, PAGE => 1 }
};

$PARENTS->{v}->{CHILDREN}->{v_set} = $CHILDREN->{v_set};

$CHILDREN->{v_u} = {
  PARENT		=> 'v',
  CODE		=> 'v_u',
  NAME		=> 'User',
  TYPE		=> 'SINGLE',
  FIELDS		=> [ 'USER' ],
  IDS			=> [],
  LABELS		=> [ 'User' ],
  UNCLES		=> [ 'u' ],
  REQS		=> [ '0' ],
  DISPLAY		=> [ '0' ],
  DEFAULTS	=> [ '999' ],
  SEARCH		=> '0',
  PRIORITY	=> '1',
  ALLOWS		=> [ '0,999' ],
  FLAGS		=> { NOLOG => 1 }
};

$PARENTS->{v}->{CHILDREN}->{v_u} = $CHILDREN->{v_u};


$PARENTS->{d} = {
  CODE		=> 'd',
  NAME		=> 'Data Test',
  PRIORITY	=> '0',
  S			=> '',
  NXT			=> '',
  DEF			=> 'd_def',
  OWNERTBL	=> 'd_u',
  FLAGS		=> { NOCHK => 1, NOLOG => 1 },
  SETUP		=> '',
  MODELS		=> []
};

$CHILDREN->{d_def} = {
  PARENT		=> 'd',
  CODE		=> 'd_def',
  NAME		=> 'definition',
  TYPE		=> 'SINGLE',
  FIELDS		=> [ 'VALUE' ],
  IDS			=> [],
  LABELS		=> [ 'Definition' ],
  UNCLES		=> [],
  REQS		=> [ '0' ],
  DISPLAY		=> [ '0=32' ],
  DEFAULTS	=> [],
  SEARCH		=> '1',
  PRIORITY	=> '1',
  ALLOWS		=> [],
  FLAGS		=> { NOLOG => 1 }
};

$PARENTS->{d}->{CHILDREN}->{d_def} = $CHILDREN->{d_def};

$CHILDREN->{d_entity} = {
  PARENT		=> 'd',
  CODE		=> 'd_entity',
  NAME		=> 'Entity',
  TYPE		=> 'SINGLE',
  FIELDS		=> [ 'VALUE' ],
  IDS			=> [],
  LABELS		=> [ 'Definition' ],
  UNCLES		=> [],
  REQS		=> [ '0' ],
  DISPLAY		=> [ '0=8' ],
  DEFAULTS	=> [],
  SEARCH		=> '0',
  PRIORITY	=> '1',
  ALLOWS		=> [],
  FLAGS		=> { NOLOG => 1 }
};

$PARENTS->{d}->{CHILDREN}->{d_entity} = $CHILDREN->{d_entity};

$CHILDREN->{d_errors} = {
  PARENT		=> 'd',
  CODE		=> 'd_errors',
  NAME		=> 'Errors',
  TYPE		=> 'SERIE',
  FIELDS		=> [ 'VALUE', 'SERIAL' ],
  IDS			=> [ '1' ],
  LABELS		=> [ 'Error Message', 'Serial' ],
  UNCLES		=> [],
  REQS		=> [],
  DISPLAY		=> [ '0=128' ],
  DEFAULTS	=> [],
  SEARCH		=> '0',
  PRIORITY	=> '1',
  ALLOWS		=> [],
  FLAGS		=> { NOLOG => 1 }
};

$PARENTS->{d}->{CHILDREN}->{d_errors} = $CHILDREN->{d_errors};

$CHILDREN->{d_u} = {
  PARENT		=> 'd',
  CODE		=> 'd_u',
  NAME		=> 'Owner',
  TYPE		=> 'SINGLE',
  FIELDS		=> [ 'USER' ],
  IDS			=> [],
  LABELS		=> [ 'Owner' ],
  UNCLES		=> [ 'u' ],
  REQS		=> [ '0' ],
  DISPLAY		=> [ '0' ],
  DEFAULTS	=> [ '0' ],
  SEARCH		=> '0',
  PRIORITY	=> '1',
  ALLOWS		=> [ '0' ],
  FLAGS		=> { NOLOG => 1 }
};

$PARENTS->{d}->{CHILDREN}->{d_u} = $CHILDREN->{d_u};

$CHILDREN->{d_date} = {
  PARENT		=> 'd',
  CODE		=> 'd_date',
  NAME		=> 'Date',
  TYPE		=> 'SINGLE',
  FIELDS		=> [ 'VALUE' ],
  IDS			=> [],
  LABELS		=> [ 'Date' ],
  UNCLES		=> [],
  REQS		=> [ '0' ],
  DISPLAY		=> [ '0=19' ],
  DEFAULTS	=> [ 'NOW()' ],
  SEARCH		=> '0',
  PRIORITY	=> '3',
  ALLOWS		=> [],
  FLAGS		=> { NOLOG => 1 }
};

$PARENTS->{d}->{CHILDREN}->{d_date} = $CHILDREN->{d_date};


$PARENTS->{s} = {
  CODE		=> 's',
  NAME		=> 'Species',
  PRIORITY	=> '10',
  S			=> '',
  NXT			=> 'o',
  DEF			=> 's_name',
  OWNERTBL	=> '',
  FLAGS		=> {},
  SETUP		=> '',
  MODELS		=> []
};

$CHILDREN->{s_name} = {
  PARENT		=> 's',
  CODE		=> 's_name',
  NAME		=> 'Name',
  TYPE		=> 'SINGLE',
  FIELDS		=> [ 'VALUE' ],
  IDS			=> [],
  LABELS		=> [ 'Name' ],
  UNCLES		=> [],
  REQS		=> [ '0' ],
  DISPLAY		=> [ '0=50' ],
  DEFAULTS	=> [],
  SEARCH		=> '1',
  PRIORITY	=> '1',
  ALLOWS		=> [],
  FLAGS		=> {}
};

$PARENTS->{s}->{CHILDREN}->{s_name} = $CHILDREN->{s_name};

$CHILDREN->{s_lnk} = {
  PARENT		=> 's',
  CODE		=> 's_lnk',
  NAME		=> 'Link',
  TYPE		=> 'LINK',
  FIELDS		=> [ 'LINK', 'USER' ],
  IDS			=> [ '1', '0' ],
  LABELS		=> [ 'Accession', 'User' ],
  UNCLES		=> [ '', 'u' ],
  REQS		=> [ '0', '1' ],
  DISPLAY		=> [ '0=10' ],
  DEFAULTS	=> [ '', '0' ],
  SEARCH		=> '1',
  PRIORITY	=> '2',
  ALLOWS		=> [ '', '0,901,907' ],
  FLAGS		=> { NOBLANK => 1 }
};

$PARENTS->{s}->{CHILDREN}->{s_lnk} = $CHILDREN->{s_lnk};


$PARENTS->{o} = {
  CODE		=> 'o',
  NAME		=> 'Genome',
  PRIORITY	=> '20',
  S			=> 'n',
  NXT			=> 'g',
  DEF			=> 'o_def',
  OWNERTBL	=> '',
  FLAGS		=> {},
  SETUP		=> '',
  MODELS		=> []
};

$CHILDREN->{o_def} = {
  PARENT		=> 'o',
  CODE		=> 'o_def',
  NAME		=> 'Definition',
  TYPE		=> 'SINGLE',
  FIELDS		=> [ 'VALUE' ],
  IDS			=> [],
  LABELS		=> [ 'Definition' ],
  UNCLES		=> [],
  REQS		=> [ '0' ],
  DISPLAY		=> [ '0=127' ],
  DEFAULTS	=> [],
  SEARCH		=> '1',
  PRIORITY	=> '1',
  ALLOWS		=> [],
  FLAGS		=> {}
};

$PARENTS->{o}->{CHILDREN}->{o_def} = $CHILDREN->{o_def};

$CHILDREN->{o_s} = {
  PARENT		=> 'o',
  CODE		=> 'o_s',
  NAME		=> 'Species',
  TYPE		=> 'SINGLE',
  FIELDS		=> [ 'VALUE' ],
  IDS			=> [],
  LABELS		=> [ 'Species' ],
  UNCLES		=> [ 's' ],
  REQS		=> [ '0' ],
  DISPLAY		=> [ '0' ],
  DEFAULTS	=> [],
  SEARCH		=> '1',
  PRIORITY	=> '1',
  ALLOWS		=> [],
  FLAGS		=> {}
};

$PARENTS->{o}->{CHILDREN}->{o_s} = $CHILDREN->{o_s};

$CHILDREN->{o_lnk} = {
  PARENT		=> 'o',
  CODE		=> 'o_lnk',
  NAME		=> 'Link',
  TYPE		=> 'LINK',
  FIELDS		=> [ 'LINK', 'USER' ],
  IDS			=> [ '1', '0' ],
  LABELS		=> [ 'Accession', 'User' ],
  UNCLES		=> [ '', 'u' ],
  REQS		=> [ '0', '1' ],
  DISPLAY		=> [ '0=10' ],
  DEFAULTS	=> [ '', '0' ],
  SEARCH		=> '1',
  PRIORITY	=> '2',
  ALLOWS		=> [ '', '0,907,901,903,904,906,905' ],
  FLAGS		=> { NOBLANK => 1 }
};

$PARENTS->{o}->{CHILDREN}->{o_lnk} = $CHILDREN->{o_lnk};


$PARENTS->{g} = {
  CODE		=> 'g',
  NAME		=> 'Gene',
  PRIORITY	=> '30',
  S			=> 'h',
  NXT			=> 'p',
  DEF			=> 'g_nms',
  OWNERTBL	=> '',
  FLAGS		=> {},
  SETUP		=> '',
  MODELS		=> []
};

$CHILDREN->{g_locus} = {
  PARENT		=> 'g',
  CODE		=> 'g_locus',
  NAME		=> 'Locus',
  TYPE		=> 'SINGLE',
  FIELDS		=> [ 'VALUE' ],
  IDS			=> [],
  LABELS		=> [ 'Locus' ],
  UNCLES		=> [],
  REQS		=> [ '0' ],
  DISPLAY		=> [ '0=8' ],
  DEFAULTS	=> [],
  SEARCH		=> '1',
  PRIORITY	=> '1',
  ALLOWS		=> [],
  FLAGS		=> { NOBLANK => 1 }
};

$PARENTS->{g}->{CHILDREN}->{g_locus} = $CHILDREN->{g_locus};

$CHILDREN->{g_o} = {
  PARENT		=> 'g',
  CODE		=> 'g_o',
  NAME		=> 'Genome',
  TYPE		=> 'SINGLE',
  FIELDS		=> [ 'VALUE' ],
  IDS			=> [],
  LABELS		=> [ 'Genome' ],
  UNCLES		=> [ 'o' ],
  REQS		=> [],
  DISPLAY		=> [ '0' ],
  DEFAULTS	=> [],
  SEARCH		=> '1',
  PRIORITY	=> '2',
  ALLOWS		=> [],
  FLAGS		=> {}
};

$PARENTS->{g}->{CHILDREN}->{g_o} = $CHILDREN->{g_o};

$CHILDREN->{g_nms} = {
  PARENT		=> 'g',
  CODE		=> 'g_nms',
  NAME		=> 'Name',
  TYPE		=> 'SERIE',
  FIELDS		=> [ 'VALUE', 'SERIAL', 'MAIN' ],
  IDS			=> [ '1' ],
  LABELS		=> [ 'Name', 'Serial', 'Main' ],
  UNCLES		=> [],
  REQS		=> [ '0', '1', '2' ],
  DISPLAY		=> [ '2', '0=11' ],
  DEFAULTS	=> [ '', '0', '0' ],
  SEARCH		=> '1',
  PRIORITY	=> '3',
  ALLOWS		=> [ '', '', '0,1' ],
  FLAGS		=> { NOREPSCI => 1 }
};

$PARENTS->{g}->{CHILDREN}->{g_nms} = $CHILDREN->{g_nms};

$CHILDREN->{g_lnk} = {
  PARENT		=> 'g',
  CODE		=> 'g_lnk',
  NAME		=> 'Link',
  TYPE		=> 'LINK',
  FIELDS		=> [ 'LINK', 'USER' ],
  IDS			=> [ '1', '0' ],
  LABELS		=> [ 'Accession', 'User' ],
  UNCLES		=> [ '', 'u' ],
  REQS		=> [ '0', '1' ],
  DISPLAY		=> [ '0=10' ],
  DEFAULTS	=> [ '', '0' ],
  SEARCH		=> '1',
  PRIORITY	=> '4',
  ALLOWS		=> [ '', '0,901,903,904,905,906,908,909,910' ],
  FLAGS		=> { NOBLANK => 1 }
};

$PARENTS->{g}->{CHILDREN}->{g_lnk} = $CHILDREN->{g_lnk};

$CHILDREN->{g_p} = {
  PARENT		=> 'g',
  CODE		=> 'g_p',
  NAME		=> 'Protein',
  TYPE		=> 'SET',
  FIELDS		=> [ 'VALUE' ],
  IDS			=> [ '0' ],
  LABELS		=> [ 'Protein' ],
  UNCLES		=> [ 'p' ],
  REQS		=> [],
  DISPLAY		=> [ '0=10' ],
  DEFAULTS	=> [],
  SEARCH		=> '1',
  PRIORITY	=> '5',
  ALLOWS		=> [],
  FLAGS		=> { PAGE => 1 }
};

$PARENTS->{g}->{CHILDREN}->{g_p} = $CHILDREN->{g_p};


$PARENTS->{p} = {
  CODE		=> 'p',
  NAME		=> 'Protein',
  PRIORITY	=> '40',
  S			=> 'q',
  NXT			=> 'e',
  DEF			=> 'p_nms',
  OWNERTBL	=> '',
  FLAGS		=> {},
  SETUP		=> '',
  MODELS		=> []
};

$CHILDREN->{p_sname} = {
  PARENT		=> 'p',
  CODE		=> 'p_sname',
  NAME		=> 'Short name',
  TYPE		=> 'SINGLE',
  FIELDS		=> [ 'VALUE' ],
  IDS			=> [],
  LABELS		=> [ 'Short name' ],
  UNCLES		=> [],
  REQS		=> [ '0' ],
  DISPLAY		=> [ '0=9' ],
  DEFAULTS	=> [],
  SEARCH		=> '1',
  PRIORITY	=> '1',
  ALLOWS		=> [],
  FLAGS		=> { NOBLANK => 1 }
};

$PARENTS->{p}->{CHILDREN}->{p_sname} = $CHILDREN->{p_sname};

$CHILDREN->{p_nms} = {
  PARENT		=> 'p',
  CODE		=> 'p_nms',
  NAME		=> 'Name',
  TYPE		=> 'SERIE',
  FIELDS		=> [ 'VALUE', 'SERIAL', 'MAIN' ],
  IDS			=> [ '1' ],
  LABELS		=> [ 'Name', 'Serial', 'Main' ],
  UNCLES		=> [],
  REQS		=> [ '0', '1', '2' ],
  DISPLAY		=> [ '2', '0=255' ],
  DEFAULTS	=> [ '', '0', '0' ],
  SEARCH		=> '1',
  PRIORITY	=> '2',
  ALLOWS		=> [ '', '', '0,1' ],
  FLAGS		=> { NOREPSCI => 1 }
};

$PARENTS->{p}->{CHILDREN}->{p_nms} = $CHILDREN->{p_nms};

$CHILDREN->{p_lnk} = {
  PARENT		=> 'p',
  CODE		=> 'p_lnk',
  NAME		=> 'Link',
  TYPE		=> 'LINK',
  FIELDS		=> [ 'LINK', 'USER' ],
  IDS			=> [ '1', '0' ],
  LABELS		=> [ 'Accession', 'User' ],
  UNCLES		=> [ '', 'u' ],
  REQS		=> [ '0', '1' ],
  DISPLAY		=> [ '0=10' ],
  DEFAULTS	=> [ '', '0' ],
  SEARCH		=> '1',
  PRIORITY	=> '3',
  ALLOWS		=> [ '', '0,901,906,903,904,905' ],
  FLAGS		=> { NOBLANK => 1 }
};

$PARENTS->{p}->{CHILDREN}->{p_lnk} = $CHILDREN->{p_lnk};

$CHILDREN->{p_seq} = {
  PARENT		=> 'p',
  CODE		=> 'p_seq',
  NAME		=> 'Seq',
  TYPE		=> 'SINGLE',
  FIELDS		=> [ 'VALUE' ],
  IDS			=> [],
  LABELS		=> [ 'Sequence' ],
  UNCLES		=> [],
  REQS		=> [],
  DISPLAY		=> [ '0' ],
  DEFAULTS	=> [],
  SEARCH		=> '0',
  PRIORITY	=> '4',
  ALLOWS		=> [],
  FLAGS		=> { NOLOG => 1, RO => 1, NOBLANK => 1 }
};

$PARENTS->{p}->{CHILDREN}->{p_seq} = $CHILDREN->{p_seq};


$PARENTS->{e} = {
  CODE		=> 'e',
  NAME		=> 'Enzyme',
  PRIORITY	=> '50',
  S			=> 'f',
  NXT			=> 't',
  DEF			=> 'e_key',
  OWNERTBL	=> '',
  FLAGS		=> { TREE => 1, ILINK => 1 },
  SETUP		=> '',
  MODELS		=> []
};

$CHILDREN->{e_key} = {
  PARENT		=> 'e',
  CODE		=> 'e_key',
  NAME		=> 'Key',
  TYPE		=> 'SINGLE',
  FIELDS		=> [ 'VALUE' ],
  IDS			=> [],
  LABELS		=> [ 'Main Name' ],
  UNCLES		=> [],
  REQS		=> [ '0' ],
  DISPLAY		=> [ '0=254' ],
  DEFAULTS	=> [],
  SEARCH		=> '1',
  PRIORITY	=> '0',
  ALLOWS		=> [],
  FLAGS		=> {}
};

$PARENTS->{e}->{CHILDREN}->{e_key} = $CHILDREN->{e_key};

$CHILDREN->{e_parent} = {
  PARENT		=> 'e',
  CODE		=> 'e_parent',
  NAME		=> 'Parent',
  TYPE		=> 'SET',
  FIELDS		=> [ 'VALUE' ],
  IDS			=> [ '0' ],
  LABELS		=> [ 'Parent' ],
  UNCLES		=> [ 'e' ],
  REQS		=> [],
  DISPLAY		=> [ '0=10' ],
  DEFAULTS	=> [],
  SEARCH		=> '0',
  PRIORITY	=> '0',
  ALLOWS		=> [],
  FLAGS		=> { PAGE => 1 }
};

$PARENTS->{e}->{CHILDREN}->{e_parent} = $CHILDREN->{e_parent};

$CHILDREN->{e_nms} = {
  PARENT		=> 'e',
  CODE		=> 'e_nms',
  NAME		=> 'Name',
  TYPE		=> 'SERIE',
  FIELDS		=> [ 'VALUE', 'SERIAL' ],
  IDS			=> [ '1' ],
  LABELS		=> [ 'Name', 'Serial' ],
  UNCLES		=> [],
  REQS		=> [ '0', '1' ],
  DISPLAY		=> [ '', '0=255' ],
  DEFAULTS	=> [ '', '0' ],
  SEARCH		=> '1',
  PRIORITY	=> '1',
  ALLOWS		=> [],
  FLAGS		=> { NOREPSCI => 1 }
};

$PARENTS->{e}->{CHILDREN}->{e_nms} = $CHILDREN->{e_nms};

$CHILDREN->{e_lnk} = {
  PARENT		=> 'e',
  CODE		=> 'e_lnk',
  NAME		=> 'Link',
  TYPE		=> 'LINK',
  FIELDS		=> [ 'LINK', 'USER' ],
  IDS			=> [ '1', '0' ],
  LABELS		=> [ 'Accession', 'User' ],
  UNCLES		=> [ '', 'u' ],
  REQS		=> [ '0', '1' ],
  DISPLAY		=> [ '0=10' ],
  DEFAULTS	=> [ '', '0' ],
  SEARCH		=> '1',
  PRIORITY	=> '2',
  ALLOWS		=> [ '', '0,902,905' ],
  FLAGS		=> { NOBLANK => 1 }
};

$PARENTS->{e}->{CHILDREN}->{e_lnk} = $CHILDREN->{e_lnk};

$CHILDREN->{e_p} = {
  PARENT		=> 'e',
  CODE		=> 'e_p',
  NAME		=> 'Protein Complex',
  TYPE		=> 'COMPLEX',
  FIELDS		=> [ 'VALUE', 'SERIAL' ],
  IDS			=> [ '1', '0' ],
  LABELS		=> [ 'Protein', 'Complex' ],
  UNCLES		=> [ 'p' ],
  REQS		=> [],
  DISPLAY		=> [ '0=15' ],
  DEFAULTS	=> [ '', '0' ],
  SEARCH		=> '1',
  PRIORITY	=> '3',
  ALLOWS		=> [],
  FLAGS		=> {}
};

$PARENTS->{e}->{CHILDREN}->{e_p} = $CHILDREN->{e_p};


$PARENTS->{t} = {
  CODE		=> 't',
  NAME		=> 'Transformation',
  PRIORITY	=> '60',
  S			=> 'v',
  NXT			=> '',
  DEF			=> 't_nms',
  OWNERTBL	=> '',
  FLAGS		=> { STOICH => 1 },
  SETUP		=> '',
  MODELS		=> []
};

$CHILDREN->{t_def} = {
  PARENT		=> 't',
  CODE		=> 't_def',
  NAME		=> 'Definition',
  TYPE		=> 'SINGLE',
  FIELDS		=> [ 'VALUE' ],
  IDS			=> [],
  LABELS		=> [ 'Definition' ],
  UNCLES		=> [],
  REQS		=> [ '0' ],
  DISPLAY		=> [ '0=512' ],
  DEFAULTS	=> [],
  SEARCH		=> '1',
  PRIORITY	=> '1',
  ALLOWS		=> [],
  FLAGS		=> {}
};

$PARENTS->{t}->{CHILDREN}->{t_def} = $CHILDREN->{t_def};

$CHILDREN->{t_nms} = {
  PARENT		=> 't',
  CODE		=> 't_nms',
  NAME		=> 'Name',
  TYPE		=> 'SERIE',
  FIELDS		=> [ 'VALUE', 'SERIAL', 'MAIN' ],
  IDS			=> [ '1' ],
  LABELS		=> [ 'Name', 'Serial', 'Main' ],
  UNCLES		=> [],
  REQS		=> [ '0', '1', '2' ],
  DISPLAY		=> [ '2', '0=255' ],
  DEFAULTS	=> [ '', '0', '0' ],
  SEARCH		=> '1',
  PRIORITY	=> '2',
  ALLOWS		=> [ '', '', '0,1' ],
  FLAGS		=> { NOREPSCI => 1 }
};

$PARENTS->{t}->{CHILDREN}->{t_nms} = $CHILDREN->{t_nms};

$CHILDREN->{t_lnk} = {
  PARENT		=> 't',
  CODE		=> 't_lnk',
  NAME		=> 'Link',
  TYPE		=> 'LINK',
  FIELDS		=> [ 'LINK', 'USER' ],
  IDS			=> [ '1', '0' ],
  LABELS		=> [ 'Accession', 'User' ],
  UNCLES		=> [ '', 'u' ],
  REQS		=> [ '0', '1' ],
  DISPLAY		=> [ '0=10' ],
  DEFAULTS	=> [ '', '0' ],
  SEARCH		=> '1',
  PRIORITY	=> '3',
  ALLOWS		=> [ '', '0,901,905' ],
  FLAGS		=> { NOBLANK => 1 }
};

$PARENTS->{t}->{CHILDREN}->{t_lnk} = $CHILDREN->{t_lnk};

$CHILDREN->{t_e} = {
  PARENT		=> 't',
  CODE		=> 't_e',
  NAME		=> 'Enzyme Complex',
  TYPE		=> 'COMPLEX',
  FIELDS		=> [ 'VALUE', 'SERIAL' ],
  IDS			=> [ '1', '0' ],
  LABELS		=> [ 'Enzyme', 'Complex' ],
  UNCLES		=> [ 'e' ],
  REQS		=> [],
  DISPLAY		=> [ '0=20' ],
  DEFAULTS	=> [ '', '0' ],
  SEARCH		=> '1',
  PRIORITY	=> '4',
  ALLOWS		=> [],
  FLAGS		=> {}
};

$PARENTS->{t}->{CHILDREN}->{t_e} = $CHILDREN->{t_e};

$CHILDREN->{t_c} = {
  PARENT		=> 't',
  CODE		=> 't_c',
  NAME		=> 'Stoichiometry',
  TYPE		=> 'SET',
  FIELDS		=> [ 'VALUE', 'FORK', 'STOICH' ],
  IDS			=> [ '0', '1' ],
  LABELS		=> [ 'Compound', 'I,E', 'Stoich' ],
  UNCLES		=> [ 'c' ],
  REQS		=> [ '0', '1', '2' ],
  DISPLAY		=> [ '0=15', '1', '2=8' ],
  DEFAULTS	=> [ '', '0', '0' ],
  SEARCH		=> '0',
  PRIORITY	=> '5',
  ALLOWS		=> [ '', '0,1' ],
  FLAGS		=> { NOBLANK => 1, STOICH => 1 }
};

$PARENTS->{t}->{CHILDREN}->{t_c} = $CHILDREN->{t_c};


$PARENTS->{c} = {
  CODE		=> 'c',
  NAME		=> 'Compound',
  PRIORITY	=> '70',
  S			=> '',
  NXT			=> '',
  DEF			=> 'c_nms',
  OWNERTBL	=> '',
  FLAGS		=> {},
  SETUP		=> '',
  MODELS		=> []
};

$CHILDREN->{c_formula} = {
  PARENT		=> 'c',
  CODE		=> 'c_formula',
  NAME		=> 'Formula',
  TYPE		=> 'SINGLE',
  FIELDS		=> [ 'VALUE' ],
  IDS			=> [],
  LABELS		=> [ 'Formula' ],
  UNCLES		=> [],
  REQS		=> [ '0' ],
  DISPLAY		=> [ '0=30' ],
  DEFAULTS	=> [],
  SEARCH		=> '1',
  PRIORITY	=> '1',
  ALLOWS		=> [],
  FLAGS		=> { NOBLANK => 1 }
};

$PARENTS->{c}->{CHILDREN}->{c_formula} = $CHILDREN->{c_formula};

$CHILDREN->{c_nms} = {
  PARENT		=> 'c',
  CODE		=> 'c_nms',
  NAME		=> 'Name',
  TYPE		=> 'SERIE',
  FIELDS		=> [ 'VALUE', 'SERIAL', 'MAIN' ],
  IDS			=> [ '1' ],
  LABELS		=> [ 'Name', 'Serial', 'Main' ],
  UNCLES		=> [],
  REQS		=> [ '0', '1', '2' ],
  DISPLAY		=> [ '2', '0=255' ],
  DEFAULTS	=> [ '', '0', '0' ],
  SEARCH		=> '1',
  PRIORITY	=> '2',
  ALLOWS		=> [ '', '', '0,1' ],
  FLAGS		=> { NOREPSCI => 1 }
};

$PARENTS->{c}->{CHILDREN}->{c_nms} = $CHILDREN->{c_nms};

$CHILDREN->{c_lnk} = {
  PARENT		=> 'c',
  CODE		=> 'c_lnk',
  NAME		=> 'Link',
  TYPE		=> 'LINK',
  FIELDS		=> [ 'LINK', 'USER' ],
  IDS			=> [ '1', '0' ],
  LABELS		=> [ 'Accession', 'User' ],
  UNCLES		=> [ '', 'u' ],
  REQS		=> [ '0', '1' ],
  DISPLAY		=> [ '0=10' ],
  DEFAULTS	=> [ '', '0' ],
  SEARCH		=> '1',
  PRIORITY	=> '3',
  ALLOWS		=> [ '', '0,901,905' ],
  FLAGS		=> { NOBLANK => 1 }
};

$PARENTS->{c}->{CHILDREN}->{c_lnk} = $CHILDREN->{c_lnk};

$CHILDREN->{c_charge} = {
  PARENT		=> 'c',
  CODE		=> 'c_charge',
  NAME		=> 'Charge',
  TYPE		=> 'SINGLE',
  FIELDS		=> [ 'VALUE' ],
  IDS			=> [],
  LABELS		=> [ 'Charge' ],
  UNCLES		=> [],
  REQS		=> [],
  DISPLAY		=> [ '0=4' ],
  DEFAULTS	=> [],
  SEARCH		=> '0',
  PRIORITY	=> '4',
  ALLOWS		=> [],
  FLAGS		=> { NOBLANK => 1 }
};

$PARENTS->{c}->{CHILDREN}->{c_charge} = $CHILDREN->{c_charge};

my $MODELS = {
   fba	=> {
    CODE		=> 'fba',
    NAME		=> 'FBA',
    APP		=> '/opt/tobin/bin/fba-2011.pl',
    RESULT	=> 'fba',
    OPTIONS	=> ''
  }
};

my $CONST	= {
  PARENTS				=> $PARENTS,
  CHILDREN			=> $CHILDREN,
  MODELS				=> $MODELS,
  BENCHMARK			=> 0,
  BGCOLOR				=> '',
  COLOR_BLUE			=> 'e5ecf9',
  COLOR_GREEN			=> 'c9e78f',
  COLOR_RED			=> 'ff2c21',
  COLOR_SILVER		=> 'c0c0c0',
  COLOR_YELLOW		=> 'fffb8e',
  DB_DATA				=> $DB_DATA,#LEGACY
  DB_HOST				=> $DB_HOST,#LEGACY
  DB_PASS				=> $DB_PASS,#LEGACY
  DB_USER				=> $DB_USER,#LEGACY
  DEBUG				=> 0,
  DOMAIN				=> $TOBIN_INSTANCE,#LEGACY
  DOMAIN_APP_PRIVATE	=> 'man0b',
  DOMAIN_APP_PUBLIC	=> 'tob0',
  DOMAIN_ICON			=> '/icons2/tobin-12.ico',
  DOMAIN_TITLE		=> 'ToBiN',
  FBA_ERROR_NO_SRC_SNK	=> 'Only Sources or Sinks can be objective function',
  FBA_ERROR_OBJ_BOUNDS	=> 'Objective Source/Sink cannot be upper bounded',
  FBA_ERROR_SRC_AND_SNK	=> 'Objective compound requires both source and sink',
  FBA_INV_BOUNDS		=> '$ has inverted bounds',
  GRAPH_APP			=> '/opt/tobin/bin/plotter.pl',
  GRAPH_LVL_MAX		=> 9,
  GRAPH_LVL_MIN		=> 0,
  GRAPH_PATH			=> "/tmp/$TOBIN_INSTANCE",
  GRAPH_TAG_LARGE		=> 'large',
  GRAPH_TAG_MEDIUM	=> 'medium',
  GRAPH_TAG_SMALL		=> 'small',
  INPUTSIZE			=> 99,
  LNCOLOR				=> '',
  MY_COMP				=> 'c',
        MY_COMP_NAMES           => 'c_nms',
  MY_FBARES			=> 'fba',
  MY_FBARES_FLUXES	=> 'fba_fluxes',
  MY_FBARES_SETUP		=> 'fba_a',
  MY_FBASET			=> 'a',
  MY_FBASET_TRANSF	=> 'a_t',
  MY_FBATYPE			=> 'a_type',
  MY_TRANSF			=> 't',
  MY_TRANSF_COMP		=> 't_c',
  SEARCH_FIELD_LENGTH	=> 20,
  SEARCH_LIMIT		=> 25,
  SEL_HALF_MAXWIDTH	=> 45,
  SESSID_PATH			=> '/tmp',
  SETS_DATA			=> 'set',
  SETS_DATE			=> 'date',
  SETS_DEF			=> 'def',
  SETS_USER			=> 'u',
  SIMUL_APP			=> 'proc_app',
  SIMUL_PARENT		=> 'proc',
  SIMUL_SETUP			=> 'proc_setup',
  SIMUL_TASK			=> 'proc_pid',
  SIMUL_USER			=> 'proc_u',
  TASK_FORKER			=> '/opt/tobin/bin/forker.pl',
  TASK_FORKTRY		=> 1,
  TASK_MAX			=> 2,
  TASK_MAX_HIGH		=> 1,
  TASK_MAX_LOW		=> 1,
  TASK_TBL			=> 'tasks',
  TXCOLOR				=> '',
  USER_NICK_CHILD		=> 'u_nick',
  USER_PARENT			=> 'u',
  USER_PASS_CHILD		=> 'u_pass',
  USER_PUB			=> 999,
  VALIDATOR			=> 'validator',
  VLCOLOR				=> ''
};
1;

sub constantsGet { return $CONST };
1;
