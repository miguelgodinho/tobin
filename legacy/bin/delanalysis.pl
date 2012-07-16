#!/usr/bin/perl -I. -w
use strict;
use warnings;
use Clone qw(clone);
use Tobin::IF;

open(WE,$ARGV[2])||die("Cannot open annotation file");
my @tab=<WE>;
close(WE);
my $echash={};
my $genehash={};
my $tfhashrev={};
my $echashrev={};
foreach(@tab) {
  chomp;
  my @tab1=split(/\t/,$_);
  defined($tfhashrev->{$tab1[0]})||($tfhashrev->{$tab1[0]}={});
  for(my $i=1;$i<@tab1;$i+=2) {
    $tab1[$i]=~s/EC-//;
    $tfhashrev->{$tab1[0]}->{$tab1[$i]}=1;
    defined($echash->{$tab1[$i]})||($echash->{$tab1[$i]}={});
    $echash->{$tab1[$i]}->{$tab1[0]}=1;
    defined($echashrev->{$tab1[$i]})||($echashrev->{$tab1[$i]}={});
    my @tab2=split(/,/,$tab1[$i+1]);
    foreach my $gene (@tab2) {
      $echashrev->{$tab1[$i]}->{$gene}=1;
      defined($genehash->{$gene})||($genehash->{$gene}={});
      $genehash->{$gene}->{$tab1[$i]}=1;
    }

  }

}
open(WE,$ARGV[3])||die("Cannot open deletions file!");
my $logic=$ARGV[4];
my @deletions=<WE>;
close(WE);
foreach(@deletions) {
  chomp;
  my $dlist=[];
  my $ehrcopy=clone($echashrev);
  my $thrcopy=clone($tfhashrev);
  $_=~/,/?($dlist=\split(/,/,$_)):push(@{$dlist},$_);
  my $ecinact={};
  my $tfinact={};
  if($logic) {
    foreach my $gene (@{$dlist}) {
      foreach my $ecs (keys(%{$genehash->{$gene}})) {
        $ecinact->{$ecs}=1;
      }
    }
  }
  else {
    my $ecaff={};
    foreach my $gene (@{$dlist}) {
      foreach my $ecs (keys(%{$genehash->{$gene}})) {
        $ecaff->{$ecs}=1;
        delete($ehrcopy->{$ecs}->{$gene});
      }
      foreach my $ecs (keys(%{$ecaff})) {
        keys(%{$ehrcopy->{$ecs}})||($ecinact->{$ecs}=1);
      }
    }
  }
  my $tfaff={};
  foreach my $ecs (keys(%{$ecinact})) {
    foreach my $tf (keys(%{$echash->{$ecs}})) {
      delete($thrcopy->{$tf}->{$ecs});
      $tfaff->{$tf}=1;
    }
  }
  foreach my $tf (keys(%{$tfaff})) {
    keys(%{$thrcopy->{$tf}})||($tfinact->{$tf}=1);
  }
  foreach my $tf (keys(%{$tfinact})) {
    print($tf.", ");
  }
  print("\n");
}
