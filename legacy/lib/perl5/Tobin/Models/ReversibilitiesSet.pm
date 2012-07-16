# Parts of the code are from a script by Jacek Puchalka

use strict;
use warnings;

package Tobin::Models::ReversibilitiesSet;

use Carp qw(confess);
use Clone qw(clone);

use Tobin::IF;

sub new {
  my ($class) = @_;

  my $self = { pairs => {} };
  bless($self, $class);

  return $self;
}


# Factory Method
sub create_from_fba_setup {
  my ($class, $fba_setup_id) = @_;

  my $tobin = new Tobin::IF(1);
  my $rtab=[];

  my $fba_setup_data = $tobin->fbasetupGet($fba_setup_id);
  foreach my $code (@{$fba_setup_data->{TFSET}}) {
    my $tf=$tobin->transformationGet($code->[0]);
    push(@{$rtab}, {prod=>{0=>{},1=>{}},subs=>{0=>{},1=>{}},code=>$code->[0]});
    foreach(@{$tf->[2]}) {
#     warn ($_->{sto}<0?"subs":"prods");
      $rtab->[@{$rtab}-1]->{($_->{sto}<0?"subs":"prod")}
      ->{$_->{ext}}->{$_->{id}}=abs($_->{sto});
    }
  }

  my $self = $class->new();
  $self->_process_rtab($rtab);
  return $self;
}


# Factory Method
sub create_from_reactions_file {
  my ($class, $filepath) = @_;

  my $tobin = new Tobin::IF(1);
  my $rtab = [];

  open(WE, $filepath) or die("Cannot open reaction file");
  my @tab=<WE>;
  close(WE);
  foreach my $rea (@tab) {
    chomp($rea);
    my $tf=$tobin->transformationGet($rea);
    push(@{$rtab}, {prod=>{0=>{},1=>{}},subs=>{0=>{},1=>{}},code=>$rea});
    foreach(@{$tf->[2]}) {
#     warn ($_->{sto}<0?"subs":"prods");
      ($_->{ext}!=0||($_->{id}!=65&&$_->{id}!=957&&$_->{id}!=13))&&
      ($rtab->[@{$rtab}-1]->{($_->{sto}<0?"subs":"prod")}
      ->{$_->{ext}}->{$_->{id}}=abs($_->{sto}));
    }
  }

  my $self = $class->new();
  $self->_process_rtab($rtab);
  return $self;
}



# Factory Method
sub create_from_revs_file {
  my ($class, $filepath) = @_;

  open(FH, $filepath) or die("Cannot open reversible file: $filepath");
  my @lines = <FH>;
  close(FH);

  my $self = $class->new();

  # check for each reaction if it is reversible or not
  foreach(@lines) {
    chomp;
    my @pair = split(/\t/,$_);
    confess(@pair) if scalar(@pair) != 2;

    $self->load_pair(@pair);
  }

  return $self;
}


sub load_pair {
  my ($self, $first_reaction, $second_reaction) = @_;

  confess($first_reaction)  unless $first_reaction;
  confess($second_reaction) unless $second_reaction;

  my $pairs = $self->{pairs} // confess;

  confess($first_reaction) if $first_reaction ~~ $pairs;
  $pairs->{$first_reaction} = $second_reaction;

  confess($second_reaction) if $second_reaction ~~ $pairs;
  $pairs->{$second_reaction} = $first_reaction;
}


sub _process_rtab {
  my ($self, $rtab) = @_;

  my $assigned={};
  for(my $i=0;$i<@{$rtab}-1;$i++) {
    defined($assigned->{$rtab->[$i]->{code}})&&next;
    my $copy=[];
    my $rev =[];
    for(my $j=$i+1;$j<@{$rtab};$j++) {
      defined($assigned->{$rtab->[$j]->{code}})&&next;
      if(keys(%{$rtab->[$i]->{subs}->{0}})==keys(%{$rtab->[$j]->{subs}->{0}})&&
      keys(%{$rtab->[$i]->{subs}->{1}})==keys(%{$rtab->[$j]->{subs}->{1}})&&
      keys(%{$rtab->[$i]->{prod}->{0}})==keys(%{$rtab->[$j]->{prod}->{0}})&&
      keys(%{$rtab->[$i]->{prod}->{1}})==keys(%{$rtab->[$j]->{prod}->{1}})) {
        my $good=1;
  #     my $check=0;
  #     ($rtab->[$i]->{code}==5395&&$rtab->[$j]->{code}==8962||
  #     $rtab->[$j]->{code}==5395&&$rtab->[$i]->{code}==8962)&&($check=1);
        foreach my $cp ("subs","prod") {
          foreach my $ext (0,1) {
            foreach my $id (keys(%{$rtab->[$i]->{$cp}->{$ext}})) {
  #           $check&&print("$id\n");
              defined($rtab->[$j]->{$cp}->{$ext}->{$id})||($good=0)||last;
  #           $check&&print("$id\n");
              $rtab->[$i]->{$cp}->{$ext}->{$id}==$rtab->[$i]->{$cp}->{$ext}->{$id}||
              ($good=0)||last;
            }
            $good||last;
          }
          $good||last;
        }
        $good&&push(@{$copy},$rtab->[$j]->{code})&&
        ($assigned->{$rtab->[$j]->{code}}=1);
      }
      if(keys(%{$rtab->[$i]->{subs}->{0}})==keys(%{$rtab->[$j]->{prod}->{0}})&&
      keys(%{$rtab->[$i]->{subs}->{1}})==keys(%{$rtab->[$j]->{prod}->{1}})&&
      keys(%{$rtab->[$i]->{prod}->{0}})==keys(%{$rtab->[$j]->{subs}->{0}})&&
      keys(%{$rtab->[$i]->{prod}->{1}})==keys(%{$rtab->[$j]->{subs}->{1}})) {
        my $pstab=["subs","prod"];
        my $good=1;
        foreach my $cp (0,1) {
          foreach my $ext (0,1) {
            foreach my $id (keys(%{$rtab->[$i]->{$pstab->[$cp]}->{$ext}})) {
              defined($rtab->[$j]->{$pstab->[!$cp]}->{$ext}->{$id})||
              ($good=0)||last;
              $rtab->[$i]->{$pstab->[$cp]}->{$ext}->{$id}==
              $rtab->[$j]->{$pstab->[!$cp]}->{$ext}->{$id}||
              ($good=0)||last;
            }
            $good||last;
          }
          $good||last;
        }
        $good&&push(@{$rev},$rtab->[$j]->{code})&&
        ($assigned->{$rtab->[$j]->{code}}=1);
      }
    }

    $self->load_pair($rtab->[$i]->{code}, $rev->[0]) if @{$rev};
  }
}


# Yields each pair.
# Each element of a pair is yielded only once.
sub fetch_table_rows {
  my ($self, $cb) = @_;

  my $pairs = $self->{pairs};
  my $pairs_table   = [];
  my $included_keys = {};

  while (my ($k, $v) = each %{$pairs} ) {
    next if $v ~~ $included_keys;
    $cb->($k, $v);
    $included_keys->{$k} = 1;
  }
}


sub to_hashref {
  my ($self) = @_;

  my $pairs = $self->{pairs} // confess;

  confess unless ref($pairs) eq 'HASH';
  return clone($pairs);
}


1;
