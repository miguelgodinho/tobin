#!/usr/bin/perl
# (C) Miguel Godinho de Almeida - miguel@gbf.de - 2003

use strict;
use warnings;
use Rapido::DBAccessor;

my $dba;
my $compal;
my $user = 902;


$dba = new Rapido::DBAccessor;
$dba->initialize('localhost', 'compal', 'root', '');

my $line;
my $initialized = 0;
my $eof = 0;
my @classes;
my @newline;
my $link;
my $name;
my $lastEC1 = 0;
my $lastEC1txt = '';
my $lastEC2 = 0;
my $lastEC2txt = '';
my $lastEC3 = 0;
my $lastEC3txt = '';
my $i;
my @row;
my $text;
my %hash;
my $MAX_TXT = 254;
my %anames = ();

sub doStore{
  %anames = ();
  $name =~ s/\s*$//;
  if(length($name) > 254){
    die "FATAL ERROR: name too long $name\n";
  }
  else{
    $anames{"$link"} = 1;
    $anames{"EC $link"} = 1;
    $i = $compal->getPriFromLink('e', $link);
    if($i > 0){
      $compal->updateMainAndSerie('e', $i, 'nms', $name, \%anames, 1);
    }
    else{
      %hash = (	action => '');
      $i = $compal->insertRecord('e', 1, \%hash);
      %hash = (	e => $i,
          lnk => $link,
          user => $user);
      $compal->insertRecord('e_lnk', 1, \%hash);
      %hash = (	e => $i,
          nms => $name,
          main => 1);
      $compal->insertRecord('e_nms', 1, \%hash);
    }
  }
}


open (FFILE, $ARGV[0]) or die "File not open";
while($line = <FFILE>){
  chomp $line;
  $text = $line;
  $text =~ s/\s*$//;
  $text =~ s/\.$//;
  if(($text =~ s/^\d+\..+\..+\.-\s*//) && !$eof){
    if($initialized){
      doStore();
    }
    else{
      $initialized = 1;
    }
    @row = split(/\./, $line);
    if($row[0] ne "$lastEC1"){
      $lastEC1 = $row[0];
      $lastEC1txt = $text;
      $lastEC2 = '-';
      $lastEC2txt = '';
      $lastEC3 = '-';
      $lastEC3txt = '';
      $i = 1;
    }
    elsif($row[1] ne "$lastEC2"){
      $lastEC2 = $row[1];
      $lastEC2txt = $text;
      $lastEC3 = $row[2];
      $lastEC3txt = '';
      $i = 2;
    }
    else{
      $lastEC3 = $row[2];
      $lastEC3txt = $text;
      $i = 3;
    }
    $link = "$lastEC1.$lastEC2.$lastEC3.-";
    $link =~ s/ //g;
    $name = "$lastEC1txt $lastEC2txt $lastEC3txt";
  }
  elsif($initialized && !$eof && $line =~ m/--------/){
    doStore();
    $eof = 1;
  }
  elsif($initialized && !$eof){
    $text =~ s/\s*//;
    if($i == 1){
        $lastEC1txt .= $text;
    }
    elsif($i == 2){
      $lastEC2txt .= $text;
    }
    else{
      $lastEC3txt .= $text;
    }
    $name = "$lastEC1txt $lastEC2txt $lastEC3txt";
  }
}

