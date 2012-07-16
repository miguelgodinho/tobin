#!/usr/bin/perl -I.. -w
use strict;
use warnings;
use Spreadsheet::WriteExcel;

open(WE, $ARGV[1])||die("Cannot open reversibles file");
my @tab=<WE>;
close(WE);
my $revhash={};
foreach(@tab) {
  chomp;
  my @tab1=split(/\t/,$_);
  (defined($revhash->{$tab1[0]})||defined($revhash->{$tab1[1]}))&&
  die("Problem with reversibles.");
  $revhash->{$tab1[0]}=$tab1[1];
  $revhash->{$tab1[1]}=$tab1[0];
}
my $root=$ARGV[2];
my $wb=Spreadsheet::WriteExcel->new($ARGV[3]);
open(WE,$ARGV[0])||die("Cannot open result file");
@tab=<WE>;
close(WE);
my $aws=$wb->add_worksheet("Analysis");
my $awsrow=2;
my $funcs=[\&serfromgly,\&pyrfromed,\&oaafrompep,\&pyrfrommal,
\&oaafromglx,\&pepfromppp];
my $numarg=[5,3,2,3,4,5];
foreach(@tab) {
  chomp;
  my @tab1=split(/\t/,$_);
  my $ws=$wb->add_worksheet($tab1[0]);
  my $datahash={};
  open(WE,$root.".".$tab1[0].".d.out");
  my @tab2=<WE>;
  close(WE);
  my @tab3=grep(/^Actual values of the variables/..
  /^Actual values of the constraints/,@tab2);
  for my $i (1..(@tab3-3)) {
    chomp($tab3[$i]);
    my @tab4=split(/ +/,$tab3[$i]);
    my $rn=substr($tab4[0],1,4);
    $rn=~s/^0+//;
    $rn=defined($revhash->{$rn})?
    ($rn<$revhash->{$rn}?$rn."/".$revhash->{$rn}:$revhash->{$rn}."/".$rn):$rn;
    $datahash->{$rn}=[];
    push(@{$datahash->{$rn}},$tab4[1]);
  }
  open(WE,$root.".fva.".$tab1[0].".d.out");
  @tab2=<WE>;
  close(WE);
  foreach my $line (@tab2) {
    chomp $line;
    @tab3=split(/\t/,$line);
    $tab3[0]=~s/^0+//;
    $tab3[0]=~s%/0+%/%;
    $tab3[1]=~s/Min: //;
    $tab3[2]=~s/Max: //;
    defined($datahash->{$tab3[0]})||die("No element for $tab3[0]");
    push(@{$datahash->{$tab3[0]}},$tab3[1],$tab3[2]);
  }
  open(WE,$root.".fva.no.".$tab1[0].".d.out")||die("Cannot open: ".$root.".fva.no.".$tab1[0].".d.out");
  @tab2=<WE>;
  close(WE);
  foreach my $line (@tab2) {
    chomp $line;
    @tab3=split(/\t/,$line);
    $tab3[0]=~s/^0+//;
    $tab3[0]=~s%/0+%/%;
    $tab3[1]=~s/Min: //;
    $tab3[2]=~s/Max: //;
    defined($datahash->{$tab3[0]})||die("No element for $tab3[0]");
    push(@{$datahash->{$tab3[0]}},$tab3[1],$tab3[2]);
  }
  open(WE,$root.".".$tab1[0].".u.out")||die("Cannot open: ".$root.".".$tab1[0].".u.out");
  @tab2=<WE>;
  close(WE);
  @tab3=grep(/^Actual values of the variables/..
  /^Actual values of the constraints/,@tab2);
  for my $i (1..(@tab3-3)) {
    chomp($tab3[$i]);
    my @tab4=split(/ +/,$tab3[$i]);
    my $rn=substr($tab4[0],1,4);
    $rn=~s/^0+//;
    $rn=defined($revhash->{$rn})?
    ($rn<$revhash->{$rn}?$rn."/".$revhash->{$rn}:$revhash->{$rn}."/".$rn):$rn;
    defined($datahash->{$rn})||die("No element for $rn");
    push(@{$datahash->{$rn}},$tab4[1]);
  }
  open(WE,$root.".fva.".$tab1[0].".u.out")||die("Cannot open: ".$root.".fva.".$tab1[0].".u.out");
  @tab2=<WE>;
  close(WE);
  foreach my $line (@tab2) {
    chomp $line;
    @tab3=split(/\t/,$line);
    $tab3[0]=~s/^0+//;
    $tab3[0]=~s%/0+%/%;
    $tab3[1]=~s/Min: //;
    $tab3[2]=~s/Max: //;
    defined($datahash->{$tab3[0]})||die("No element for $tab3[0]");
    push(@{$datahash->{$tab3[0]}},$tab3[1],$tab3[2]);
  }
  open(WE,$root.".fva.no.".$tab1[0].".u.out")||die("Cannot open: ".$root.".fva.".$tab1[0].".u.out");
  @tab2=<WE>;
  close(WE);
  foreach my $line (@tab2) {
    chomp $line;
    @tab3=split(/\t/,$line);
    $tab3[0]=~s/^0+//;
    $tab3[0]=~s%/0+%/%;
    $tab3[1]=~s/Min: //;
    $tab3[2]=~s/Max: //;
    defined($datahash->{$tab3[0]})||die("No element for $tab3[0]");
    push(@{$datahash->{$tab3[0]}},$tab3[1],$tab3[2]);
  }

  foreach my $du (0,5) {
    $aws->write($awsrow,0,$tab1[0].($du==0?"-d":"-u")."-"."res");
    foreach my $na (0..5) {
      my $args=[];
      for my $i(1..$numarg->[$na]) {
        push(@{$args},0+$du);
      }
      $aws->write($awsrow,$na+1,$funcs->[$na]->($datahash,$args));
    }
    $awsrow++;
    for my $no (1,3) {
      for my $dir (1,-1) {
        $aws->write($awsrow,0,$tab1[0].($du==0?"-d":"-u").($no==3?"-no":"").($dir<0?"-max":"-min"));
        for my $f (0..5) {
          my $res=$dir*1000;
          for my $comb (0..(2**$numarg->[$f]-1)) {
            my $args=[];
            for my $arg (0..($numarg->[$f]-1)) {
              push(@{$args},(($comb>>$arg)%2)+$du+$no)
            }
            my $r=$funcs->[$f]->($datahash,$args);
            $res=$dir<0&&$r ne "NA"&&$r>$res||$dir>0&&$r ne "NA"&&$r<$res?$r:$res;
          }
          $aws->write($awsrow,$f+1,$res);
        }
        $awsrow++;
      }

    }
  }
  @tab1=keys(%{$datahash});
  $ws->write(0,1,"down");
  $ws->write(0,2,"down-min");
  $ws->write(0,3,"down-max");
  $ws->write(0,4,"down-no-min");
  $ws->write(0,5,"down-no-max");
  $ws->write(0,6,"up");
  $ws->write(0,7,"up-min");
  $ws->write(0,8,"up-max");
  $ws->write(0,9,"up-no-min");
  $ws->write(0,10,"up-no-max");
  for my $i (0..(@tab1-1)) {
    $ws->write($i+1,0,$tab1[$i]);
    for my $j (0..9) {
      $ws->write($i+1,$j+1,$datahash->{$tab1[$i]}->[$j]);
    }
  }

}

sub serfromgly {
  my $dhash=shift;
  my $args=shift;
  my $v5=$args->[0];
  my $v6=$args->[1];
  my $v7=$args->[2];
  my $v8=$args->[3];
  my $v9=$args->[4];

  my $den=$dhash->{"3001/7378"}->[$v5]+2*$dhash->{"690/5067"}->[$v6]
  -$dhash->{"3769/8146"}->[$v7]-$dhash->{"689/5066"}->[$v8];
  return $den?2*($dhash->{"690/5067"}->[$v6]+$dhash->{"689/5066"}->[$v8]-
  $dhash->{"1018/5395"}->[$v9])/$den:"NA";
}

sub pyrfromed {
  my $dhash=shift;
  my $args=shift;
  my $v5=$args->[0];
  my $v12=$args->[1];
  my $v19=$args->[2];

  my $den=$dhash->{"3001/7378"}->[$v5]
  +$dhash->{"5416"}->[$v12]+$dhash->{"7898"}->[$v12]+$dhash->{"7938"}->[$v12]
  +$dhash->{"7969"}->[$v12]+$dhash->{"3534"}->[$v19];
  return $den?$dhash->{"3001/7378"}->[$v5]/$den:"NA";
}

sub oaafrompep {
  my $dhash=shift;
  my $args=shift;
  my $v18=$args->[0];
  my $v21=$args->[1];

  my $den=$dhash->{"4559"}->[$v21]+$dhash->{"179/4556"}->[$v18];
  return $den?$dhash->{"4559"}->[$v21]/$den:"NA";
}

sub pyrfrommal {
  my $dhash=shift;
  my $args=shift;
  my $v5=$args->[0];
  my $v12=$args->[1];
  my $v19=$args->[2];

  my $den=$dhash->{"3001/7378"}->[$v5]
  +$dhash->{"5416"}->[$v12]+$dhash->{"7898"}->[$v12]+$dhash->{"7938"}->[$v12]
  +$dhash->{"7969"}->[$v12]+$dhash->{"3534"}->[$v19];
  return $den?$dhash->{"3534"}->[$v19]/$den:"NA";
}

sub oaafromglx {
  my $dhash=shift;
  my $args=shift;
  my $v17=$args->[0];
  my $v19=$args->[1];
  my $v21=$args->[2];
  my $v23=$args->[3];

  my $den=$dhash->{"219/4596"}->[$v17]
  -$dhash->{"3534"}->[$v19]+$dhash->{"4559"}->[$v21]+$dhash->{"4615"}->[$v23];
  return $den?$dhash->{"4615"}->[$v23]/$den:"NA";
}

sub pepfromppp {
  my $dhash=shift;
  my $args=shift;
  my $v5=$args->[0];
  my $v6=$args->[1];
  my $v7=$args->[2];
  my $v8=$args->[3];
  my $v9=$args->[4];

  my $den=$dhash->{"3001/7378"}->[$v5]+2*$dhash->{"690/5067"}->[$v6]
  -$dhash->{"3769/8146"}->[$v7]-$dhash->{"689/5066"}->[$v8];
  return $den?(-$dhash->{"3769/8146"}->[$v7]-3*$dhash->{"689/5066"}->[$v8]
  +2*$dhash->{"1018/5395"}->[$v9])/$den:"NA";
}
