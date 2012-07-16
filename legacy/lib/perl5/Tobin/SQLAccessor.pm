#   Copyright 2011 Miguel godinho - m@miguelgodinho.com
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.

use strict;
use warnings;

package Tobin::DBAccessor;

use Carp qw( confess );
use Data::Dumper;
use Readonly;

use constant CONN_TIMEOUT        => 9999;
use constant CONN_AUTO_RECONNECT => 1;

Readonly::Hash my %DEFAULT_COL_PROPERTIES => {
  single => { id => 'p', 0 => 'x0' },
};

sub new {
  my ($class, $host, $data, $user, $pass) = @_;

  my $self = { HOST => $host,
               DATA => $data,
               USER => $user,
               PASS => $pass,
               conn => undef,
               on_transaction => 0
             };

  bless($self, $class);

  return $self;
}


sub start_transaction {
  my ($self, $keep_ok) = @_;

  my $conn = $self->get_conn;

  if ($self->{on_transaction}) {

  #TODO activate with InnoDB
 #   confess if $conn->{AutoCommit};
    confess unless $keep_ok;
    return 1;
  } else {
    confess unless $conn->{AutoCommit};
    $conn->{AutoCommit} = 0;
    $self->{on_transaction} = 1;
    return 0;
  }
}


sub commit_transaction {
  my ($self) = @_;


  confess unless $self->{on_transaction};
  my $conn = $self->get_conn;

  #TODO activate with InnoDB
#  confess if $conn->{AutoCommit};
  $conn->{AutoCommit} = 1;
  $self->{on_transaction} = 0;
}


sub save_entry {
  my ($self, $entry) = @_;

  my $mappings = $entry->get_mappings_ref;

  my $conn = $self->get_conn;

  #confess if $conn->{'AutoCommit'};

  $self->start_transaction;
  $self->start_transaction(1);

  my $entry_id = $entry->get_id || $self->generate_entry_id($entry, $conn);

  while (my ($attr_name, $attr_properties) = each %{$mappings}) {
    my $attr_data = $entry->get($attr_name) // $attr_properties->{default};

    if (defined($attr_data)) {
      $self->_save_attribute($entry_id, $attr_data, $attr_properties);
    } else {
      confess("no nulls for: $attr_name") unless $attr_properties->{null_ok};
    }
  }

  $self->commit_transaction;
}


sub _save_attribute {
  my ($self, $entry_id, $data, $properties) = @_;

  confess(Dumper("invalid entry_id: $entry_id")) unless $entry_id;
  confess('no data')                             unless defined($data);

  my $table     = $properties->{table}    or confess(Dumper($properties));
  my $relation  = $properties->{relation} or confess(Dumper($properties));
  my $col_props = $properties->{cols}; # only req. for some relation types

  if ($relation eq 'has_one') {
     $self->insert_single($entry_id, $data, $table, $col_props);
  } elsif ($relation eq 'has_many') {
     $self->insert_in_associated_list($entry_id, $data, $table, $col_props);
  } else {
     confess("unknown relation: $relation");
  }
}


sub insert_in_associated_list {
  my ($self, $entry_id, $data, $table, $col_props) = @_;

  my $data_reftype = ref($data);

  if ($data_reftype eq 'ARRAY') {
    $self->insert_array_in_associated_list($entry_id, $data, $table, $col_props);
  } elsif ($data_reftype eq 'HASH') {
    $self->insert_hash_in_associated_list($entry_id, $data, $table, $col_props);
  } else {
    confess("invalid ref for data: " . Dumper($data));
  }
}



sub fn_prepare_insert_rows_sql {
  my ($table, @labels) = @_;

  my $cols_str         = join(',', @labels);
  my $placeholders_str = join(',', map {'?'} @labels);

  return "INSERT INTO `$table` ($cols_str) VALUES ($placeholders_str)";
}


sub _prepare_insert_rows_fn {
  my ($self, $table, @labels) = @_;

  my $sql = fn_prepare_insert_rows_sql($table, @labels);
  my $conn = $self->get_conn;

  my $sth = $conn->prepare($sql) or confess($DBI::errstr);


  my $insert_fn = sub {
    $sth->execute(@_) or confess($DBI::errstr);
  };

  return $insert_fn;
}

sub insert_hash_in_associated_list {
  my ($self, $entry_id, $data, $table, $col_props) = @_;

  my $id_col_label     = $col_props->{id}     or confess(Dumper($col_props));
  my $keys_col_label   = $col_props->{keys}   or confess(Dumper($col_props));
  my $values_col_label = $col_props->{values} or confess(Dumper($col_props));

  my @col_labels = ($id_col_label, $keys_col_label, $values_col_label);

  my $skip_commit = $self->start_transaction(1);
  my $insert_fn = $self->_prepare_insert_rows_fn($table, @col_labels);
  while (my ($key, $value) = each %{$data}) {
    $insert_fn->($entry_id, $key, $value);
  }
  $self->commit_transaction unless $skip_commit;
}


sub insert_array_in_associated_list {
  my ($self, $entry_id, $data, $table, $col_props) = @_;

  my $total_data_cols   = @{$data} - 1; # 1 col is not data, just assoc (id)
  my $last_data_col_idx = $total_data_cols - 1;

  my @col_keys   = ('id', (0..$last_data_col_idx));
  my @col_labels = map { $col_props->{$_} } @col_keys;

  my $skip_commit = $self->start_transaction(1);
  my $insert_fn = $self->_prepare_insert_rows_fn($table, @col_labels);
  foreach my $row (@{$data}) {
    my @row = ref($row) ? @{$row} : ($row);
    confess($data) unless scalar(@row) == $total_data_cols;
    $insert_fn->($entry_id, @row);
  }
  $self->commit_transaction unless $skip_commit;
}



sub insert_single {
  my ($self, $entry_id, $data, $table, $col_props) = @_;

  confess(Dumper($data)) if ref($data);

  $col_props //= $DEFAULT_COL_PROPERTIES{single};
  my @col_labels = map {$col_props->{$_}} qw( id 0 );

  my $sql = fn_prepare_insert_rows_sql($table, @col_labels);
  my $conn = $self->get_conn;
  my $skip_commit = $self->start_transaction(1);
  $conn->do($sql, undef, $entry_id, $data) or confess($DBI::errstr);
  $self->commit_transaction unless $skip_commit;
}



sub generate_entry_id {
  my ($self, $entry, $conn) = @_;

  $conn //= $self->get_conn;

  my $table = $entry->get_ids_table;

  confess(Dumper($entry)) if $entry->get_id;

  my $skip_commit = $self->start_transaction(1);
  $conn->do("INSERT INTO `$table` VALUES ()") or confess($DBI::errstr);
  my $new_id = $conn->{'mysql_insertid'} or confess($table);
  $self->commit_transaction unless $skip_commit;
  $entry->set_id($new_id);

  return $new_id;
}


sub get_dsn {
  my ($self) = @_;

  my $dsn = "DBI:mysql:"
          . "database=$self->{DATA};"
          . "host=$self->{HOST};"
          . "mysql_connect_timeout=" . CONN_TIMEOUT;

  return $dsn;
}


sub get_conn {
  my ($self) = @_;

  my $conn;

  unless ($conn = $self->{conn}) {
    my $dsn  = $self->get_dsn;

    $conn = DBI->connect(
      $dsn,
      $self->{USER},
      $self->{PASS},
      {
        AutoCommit           => 1,
        RaiseError           => 0,
        mysql_auto_reconnect => CONN_AUTO_RECONNECT
      }
    );
  }

  return $conn;
}

1;
