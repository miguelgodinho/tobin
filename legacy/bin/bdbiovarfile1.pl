#!/usr/bin/perl -I.. -w
use strict;
use warnings;
use Spreadsheet::WriteExcel;
use Tobin::IF;
use Clone qw(clone);

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
my $fsbits=3;
my $fvasplit=2**$fsbits;
my $lpdata=getfbaset($ARGV[4],$ARGV[5],$ARGV[1]);
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
		my $ival=($tab3[2]-$tab3[1])/($fvasplit-1);
		my $tab4=[$tab3[1]];
		foreach my $iv (1..($fvasplit-1)) {
			push(@{$tab4},$tab4->[0]+$ival*$iv);
		}
		defined($datahash->{$tab3[0]})||die("No element for $tab3[0]");
		push(@{$datahash->{$tab3[0]}},@{$tab4});
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
		my $ival=($tab3[2]-$tab3[1])/($fvasplit-1);
		my $tab4=[$tab3[1]];
		foreach my $iv (1..($fvasplit-1)) {
			push(@{$tab4},$tab4->[0]+$ival*$iv);
		}
		defined($datahash->{$tab3[0]})||die("No element for $tab3[0]");
		push(@{$datahash->{$tab3[0]}},@{$tab4});
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
		my $ival=($tab3[2]-$tab3[1])/($fvasplit-1);
		my $tab4=[$tab3[1]];
		foreach my $iv (1..($fvasplit-1)) {
			push(@{$tab4},$tab4->[0]+$ival*$iv);
		}
		defined($datahash->{$tab3[0]})||die("No element for $tab3[0]");
		push(@{$datahash->{$tab3[0]}},@{$tab4});
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
		my $ival=($tab3[2]-$tab3[1])/($fvasplit-1);
		my $tab4=[$tab3[1]];
		foreach my $iv (1..($fvasplit-1)) {
			push(@{$tab4},$tab4->[0]+$ival*$iv);
		}
		defined($datahash->{$tab3[0]})||die("No element for $tab3[0]");
		push(@{$datahash->{$tab3[0]}},@{$tab4});
	}
	
	foreach my $du (0,2*$fvasplit+1) {
#		$du==0&&next;
		$aws->write($awsrow,0,$tab1[0].($du==0?"-d":"-u")."-"."res");
		foreach my $na (2..2) {
			my $args=[];
			for my $i(1..$numarg->[$na]) {
				push(@{$args},0+$du);
			}
			my $lpcopy=clone($lpdata);
			$aws->write($awsrow,$na+1,$funcs->[$na]->($datahash,$args,$lpcopy,[]));
		}
		$awsrow++;
		for my $no (1,$fvasplit+1) {
			#warn("no: ".$no);
				$aws->write($awsrow,0,$tab1[0].($du==0?"-d":"-u").($no==1?"":"-no")."-min");
				$aws->write($awsrow+1,0,$tab1[0].($du==0?"-d":"-u").($no==1?"":"-no")."-max");
				for my $f (2..2) {
					my $res=[];
					for(my $next=0;$next<$numarg->[$f]-1;$next++) {
						my $extsets=getcomb($numarg->[$f],$next);
						#warn("ext: ".@{$extsets});
#						#warn("fir: ".$extsets->[0]->[0]);
						foreach my $extset(@{$extsets}){
							for my $comb (0..($fvasplit**$numarg->[$f]-1)) {
								my $args=[];
								for my $arg (0..($numarg->[$f]-1)) {
									push(@{$args},(($comb>>($arg*$fsbits))%$fvasplit)+$du+$no)
								}
								my $lpcopy=clone($lpdata);
								my $r=$funcs->[$f]->($datahash,$args,$lpcopy,$extset);
								$r->[0] eq "ERR"&&next;
								foreach my $ri (@{$r}) {
									($ri eq "NA")&&next;
									push(@{$res},$ri);
								}
							}
						}
						if(@{$res}) {
							my @ressorted=sort({$a<=>$b} @{$res});
							$aws->write($awsrow,$f+1,$ressorted[0]);
							$aws->write($awsrow+1,$f+1,$ressorted[@ressorted-1]);
							last;
						}
					}
				}
				$awsrow+=2;
		}
#		last;
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
	my $lpdata=shift;
	my $extset=shift;
	#warn(@{$extset}."\n");
	my $v5=$args->[0];
	my $v6=$args->[1];
	my $v7=$args->[2];
	my $v8=$args->[3];
	my $v9=$args->[4];
	my $tfhash={3001=>$dhash->{"3001/7378"}->[$v5],690=>$dhash->{"690/5067"}->[$v6],
		3769=>$dhash->{"3769/8146"}->[$v7],689=>$dhash->{"689/5066"}->[$v8],
		1018=>$dhash->{"1018/5395"}->[$v9]};
	my $res=checkgrowth($lpdata,$tfhash,$extset);
	$res->[0]||return(["ERR"]);
	my $ratios=[];
	foreach (@{$res->[1]}) {
		my $den=$_->{"3001"}+2*$_->{"690"}-$_->{"3769"}-$_->{"689"};
		push(@{$ratios},$den?2*($_->{"690"}+$_->{"689"}-$_->{"1018"})/$den:"NA");
	}
	#warn(@{$ratios}."\n");
	return $ratios;
}

sub pyrfromed {
	my $dhash=shift;
	my $args=shift;
	my $lpdata=shift;
	my $extset=shift;
	my $v5=$args->[0];
	my $v12=$args->[1];
	my $v19=$args->[2];
	my $tfhash={3001=>$dhash->{"3001/7378"}->[$v5],7898=>$dhash->{"7898"}->[$v12],
		3534=>$dhash->{"3534"}->[$v19]};
	my $res=checkgrowth($lpdata,$tfhash,$extset);
	$res->[0]||return(["ERR"]);
	my $ratios=[];
	foreach (@{$res->[1]}) {
		my $den=$_->{"3001"}+$_->{"7898"}+$_->{"3534"};
		push(@{$ratios},$den?$_->{"3001"}/$den:"NA");
	}
	#warn(@{$ratios}."\n");
	return $ratios;
}

sub oaafrompep {
	my $dhash=shift;
	my $args=shift;
	my $lpdata=shift;
	my $extset=shift;
	my $v18=$args->[0];
	my $v21=$args->[1];
	
	my $tfhash={4559=>$dhash->{"4559"}->[$v21],179=>$dhash->{"179/4556"}->[$v21]};
	my $res=checkgrowth($lpdata,$tfhash,$extset);
	$res->[0]||return(["ERR"]);
	my $ratios=[];
	foreach (@{$res->[1]}) {
		my $den=$_->{"4559"}+$_->{"179"};
		push(@{$ratios},$den?$_->{"4559"}/$den:"NA");
	}
	#warn(@{$ratios}."\n");
	return $ratios;
}

sub pyrfrommal {
	my $dhash=shift;
	my $args=shift;
	my $lpdata=shift;
	my $extset=shift;
	my $v5=$args->[0];
	my $v12=$args->[1];
	my $v19=$args->[2];
	
	my $tfhash={3001=>$dhash->{"3001/7378"}->[$v5],7898=>$dhash->{"7898"}->[$v12],
		3534=>$dhash->{"3534"}->[$v19]};
	my $res=checkgrowth($lpdata,$tfhash,$extset);
	$res->[0]||return(["ERR"]);
	my $ratios=[];
	foreach (@{$res->[1]}) {
		my $den=$_->{"3001"}+$_->{"7898"}+$_->{"3534"};
		push(@{$ratios},$den?$_->{"3534"}/$den:"NA");
	}
	#warn(@{$ratios}."\n");
	return $ratios;
}

sub oaafromglx {
	my $dhash=shift;
	my $args=shift;
	my $lpdata=shift;
	my $extset=shift;
	my $v17=$args->[0];
	my $v19=$args->[1];
	my $v21=$args->[2];
	my $v23=$args->[3];
	
	my $tfhash={219=>$dhash->{"219/4596"}->[$v17],3534=>$dhash->{"3534"}->[$v19],
		4559=>$dhash->{"4559"}->[$v21],4615=>$dhash->{"4615"}->[$v23]};
	my $res=checkgrowth($lpdata,$tfhash,$extset);
	$res->[0]||return(["ERR"]);
	my $ratios=[];
	foreach (@{$res->[1]}) {
		my $den=$_->{"219"}-$_->{"3534"}+$_->{"4559"}+$_->{"4615"};
		push(@{$ratios},$den?$_->{"4615"}/$den:"NA");
	}
	#warn(@{$ratios}."\n");
	return $ratios;
}

sub pepfromppp {
	my $dhash=shift;
	my $args=shift;
	my $lpdata=shift;
	my $extset=shift;
	my $v5=$args->[0];
	my $v6=$args->[1];
	my $v7=$args->[2];
	my $v8=$args->[3];
	my $v9=$args->[4];
	
	my $tfhash={3001=>$dhash->{"3001/7378"}->[$v5],690=>$dhash->{"690/5067"}->[$v6],
		3769=>$dhash->{"3769/8146"}->[$v7],689=>$dhash->{"689/5066"}->[$v8],
		1018=>$dhash->{"1018/5395"}->[$v9]};
	my $res=checkgrowth($lpdata,$tfhash,$extset);
	$res->[0]||return(["ERR"]);
	my $ratios=[];
	foreach (@{$res->[1]}) {
		my $den=$_->{"3001"}+2*$_->{"690"}-$_->{"3769"}-$_->{"689"};
		push(@{$ratios},$den?(-$_->{"3769"}-3*$_->{"689"}+2*$_->{"1018"})/$den:"NA");
	}
	#warn(@{$ratios}."\n");
	return $ratios;
}

sub checkgrowth {
	my $lpdata=shift;
	my $tfhash=shift;
	my $extset=shift;
	my @klucze=sort({$a<=>$b} (keys(%{$tfhash})));
	my $excluded={};
	#warn(@{$extset}."\n");
	foreach(@{$extset}) {
		$excluded->{$klucze[$_]}=1;
	}
	foreach(keys(%{$tfhash})) {
		defined($excluded->{$_})&&next;
		defined($lpdata->{tfhash}->{$_})||($lpdata->{tfhash}->{$_}={});
		$lpdata->{tfhash}->{$_}->{min}=($tfhash->{$_}>0?0.999:1.001)*$tfhash->{$_};
		$lpdata->{tfhash}->{$_}->{max}=($tfhash->{$_}>0?1.001:0.999)*$tfhash->{$_};
		defined($lpdata->{free}->{$_})&&delete($lpdata->{free}->{$_});
	}
	my $file=writelp($lpdata);
	my $res=-1;
	my $fluxhash={};
	for(my $i=-1;$i<8;$i++) {
		my @result=$i<0?`echo "$file"|~/Software/lp_solve/lp_solve -S2 -timeout 30`:
		`echo "$file"|~/Software/lp_solve/lp_solve -S2 -s$i -timeout 30`;
		if(@result>1&&$result[1]=~/Value of objective function: (.*)$/) {
			$res=$1;
			#warn("aaaa");
			$res<0.78&&return([0]);
			defined($lpdata->{tfhash}->{abs($lpdata->{objective})})||
			($lpdata->{tfhash}->{abs($lpdata->{objective})}={});
			$lpdata->{tfhash}->{abs($lpdata->{objective})}
			->{$lpdata->{objective}>0?"min":"max"}=0.999*$res;
			my $fluxtab=[];
			if(keys(%{$excluded})) {
				my $extab=[(keys(%{$excluded}))];
				my $extperm=[];
				permute($extab,[],$extperm);
#				warn(@{$extperm}." ");
				foreach(@{$extperm}) {
					fvachain($lpdata,$_,0,$fluxtab);
				}
			}
			else {
				$fluxtab=[{}];
			}
#			warn("flpre: ".@{$fluxtab});
			foreach(keys(%{$tfhash})) {
				defined($excluded->{$_})&&next;
				my $rpat="^R".sprintf("%04d",$_);
				my @rline=grep(/$rpat/,@result);
				@rline>1&&warn("Ambigous reaction for $_");
				@rline||warn("No reaction for $_ $rpat");
				$rline[0]=~m/$rpat +(.*)$/;
				foreach my $ft (@{$fluxtab}) {
					$ft->{$_}=$1;
				}
			}
#			warn("flaft: ".@{$fluxtab});
			return [$res,$fluxtab];
		}
	}
	return([0]);
}

sub fvachain {
	my $lpdata=shift;
	my $tftab=shift;
	my $count=shift;
	my $results=shift;
	my $fvares=runfva($lpdata,$tftab->[$count]);
	if($count<(@{$tftab}-1)) {
		defined($lpdata->{tfhash}->{$tftab->[$count]})||
		($lpdata->{tfhash}->{$tftab->[$count]}={});
		$lpdata->{tfhash}->{$tftab->[$count]}->{min}=$fvares->[0]-0.01*abs($fvares->[0]);
		$lpdata->{tfhash}->{$tftab->[$count]}->{max}=$fvares->[0]+0.01*abs($fvares->[0]);
		fvachain($lpdata,$tftab,$count+1,$results);
		$lpdata->{tfhash}->{$tftab->[$count]}->{min}=$fvares->[0]-0.01*abs($fvares->[0]);
		$lpdata->{tfhash}->{$tftab->[$count]}->{max}=$fvares->[0]+0.01*abs($fvares->[0]);
		fvachain($lpdata,$tftab,$count+1,$results);
	}
	else {
		my $pos=@{$results};
		push(@{$results},{});
		push(@{$results},{});
		for(0..(@{$tftab}-2)) {
			$results->[$pos+1]->{$tftab->[$_]}=$results->[$pos]->{$tftab->[$_]}=
			$lpdata->{tfhash}->{$tftab->[$_]}->{min}+
			0.01*abs($lpdata->{tfhash}->{$tftab->[$_]}->{min});
		}
		$results->[$pos]->{$tftab->[$count]}=$fvares->[0];
		$results->[$pos+1]->{$tftab->[$count]}=$fvares->[1];
		#warn("res: ".@{$results});
		
	}
		
}
sub getfbaset {
	my $setup=shift;
	my $uid=shift;
	my $revfile=shift;
	#!/usr/bin/perl -I. -w
	
	my $tobin	= new Tobin::IF($uid);
	my $fba=$tobin->fbasetupGet($setup);
open(WE, $revfile)||die("Cannot open reversible file.");
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
my $skip={};
my $objective;
my $cpdhash={0=>{},1=>{}};
my $tfhash={};
my $free={};
foreach(@{$fba->{TFSET}}) {
	defined($skip->{$_->[0]})&&next;
	defined($revhash->{$_->[0]})&&($_->[0]<$revhash->{$_->[0]}?
	($skip->{$revhash->{$_->[0]}}=1):next);
	$tfhash->{$_->[0]}={};
	my $tf=$tobin->transformationGet($_->[0]);
	if($_->[1]!=0) {
		$objective=$_->[1]>0?$_->[0]:-$_->[0];
	}
	$_->[2]>0&&($tfhash->{$_->[0]}->{min}=$_->[2]);
	defined($_->[3])&&($tfhash->{$_->[0]}->{max}=$_->[3]);
	foreach my $cpd(@{$tf->[2]}) {
		defined($cpdhash->{$cpd->{ext}}->{$cpd->{id}})||
		($cpdhash->{$cpd->{ext}}->{$cpd->{id}}={});
		$cpdhash->{$cpd->{ext}}->{$cpd->{id}}->{$_->[0]}=$cpd->{sto};
	}
}
foreach(@{$fba->{TFSET}}) {
	defined($skip->{$_->[0]})||next;
	if($_->[1]!=0) {
		$objective=$_->[1]>0?-$revhash->{$_->[0]}:$revhash->{$_->[0]};
	}
	if($_->[2]>0) {
		if(defined($tfhash->{$revhash->{$_->[0]}}->{min})||
		(defined($tfhash->{$revhash->{$_->[0]}}->{max})&&
		$tfhash->{$revhash->{$_->[0]}}->{max}>0)) {
			die("Tf $_->[0] - inconsistency in limits");
		}
		else {
			$tfhash->{$revhash->{$_->[0]}}->{max}=-$_->[2];
		}
	}
	if(defined($_->[3])) {
		if(defined($tfhash->{$revhash->{$_->[0]}}->{min})&&
		$tfhash->{$revhash->{$_->[0]}}->{min}>0) {
			die("Tf $_->[0] - inconsistency in limits");
		}
		else {
			$tfhash->{$revhash->{$_->[0]}}->{min}=-$_->[3];
		}
	}
}
foreach(keys(%{$tfhash})) {
	if(defined($revhash->{$_})) {
		defined($tfhash->{$_}->{max})&&!defined($tfhash->{$_}->{min})&&
		($tfhash->{$_}->{min}=-1e30);
		!defined($tfhash->{$_}->{min})&&!defined($tfhash->{$_}->{max})&&
		($free->{$_}=1);
	}
}

my $ouput={cpdhash=>$cpdhash, tfhash=>$tfhash, free=>$free, objective=>$objective};
return $ouput;
}

sub writelp {
	my $lpdata=shift;
	my $objective=$lpdata->{objective};
	my $cpdhash=$lpdata->{cpdhash};
	my $tfhash=$lpdata->{tfhash};
	my $free=$lpdata->{free};
	
	my $output="";
	$output.=($objective<0?"min: ":"")."R".sprintf("%04d",abs($objective)).";\n\n";
	foreach my $ext (keys(%{$cpdhash})) {
		foreach my $cpd (keys(%{$cpdhash->{$ext}})) {
			$output.=($ext>0?"EX_":"")."C".sprintf("%04d",$cpd).": ";
			foreach(keys(%{$cpdhash->{$ext}->{$cpd}})) {
				$output.=($cpdhash->{$ext}->{$cpd}->{$_}>0?"+":"").
				$cpdhash->{$ext}->{$cpd}->{$_}." R".sprintf("%04d",$_)." ";
			}
			$output.="= 0;\n";
		}
	}
	$output.="\n";
	foreach(keys(%{$tfhash})) {
		defined($tfhash->{$_}->{min})&&
		($output.="R".sprintf("%04d",$_)." >= ".$tfhash->{$_}->{min}.";\n");
		defined($tfhash->{$_}->{max})&&
		($output.="R".sprintf("%04d",$_)." <= ".$tfhash->{$_}->{max}.";\n");
	}
	$output.="\nfree ";
	foreach(keys(%{$free})) {
		$output.="R".sprintf("%04d",$_).",";
	}
	chop($output);
	$output.=";\n";
}

sub getcomb {
	my $size=shift;
	my $ext=shift;
	my $permtable=[[]];
	getcomb1($permtable,0,$size-$ext,0,$size);
	my $result=[];
	foreach(@{$permtable}) {
		push(@{$result},[]);
		foreach my $e (0..($size-1)) {
			$_->[$e]||push(@{$result->[@{$result}-1]},$e);
		}
	}
	return $result
}

sub getcomb1 {
	my $permtable=shift;
	my $counter=shift;
	my $max=shift;
	my $pos=shift;
	my $maxlen=shift;
	if($max-$counter<$maxlen-@{$permtable->[$pos]}&&
	$counter<$max) {
		push(@{$permtable},[]);
		foreach(@{$permtable->[$pos]}) {
			push(@{$permtable->[@{$permtable}-1]},$_);
		}
		push(@{$permtable->[@{$permtable}-1]},1);
		getcomb1($permtable,$counter+1,$max,@{$permtable}-1,$maxlen);
		push(@{$permtable->[$pos]},0);
		getcomb1($permtable,$counter,$max,$pos,$maxlen);
	}
	elsif($counter==$max) {
		for(1..($maxlen-@{$permtable->[$pos]})) {
			push(@{$permtable->[$pos]},0)
		}
	}
	else {
		for(1..($maxlen-@{$permtable->[$pos]})) {
			push(@{$permtable->[$pos]},1)
		}
	}
}

sub runfva {
	my $lpdata=shift;
	my $fvatf=shift;
	my $str="";
	$lpdata->{objective}=-$fvatf;
	my $file=writelp($lpdata);
	my $min;
	my $max;
	defined($revhash->{$fvatf})&&($str.="/".$revhash->{$fvatf});
	for(my $i=-1;$i<8;$i++) {
		my @result=$i<0?`echo "$file"|~/Software/lp_solve/lp_solve -S1 -timeout 30`:
		`echo "$file"|~/Software/lp_solve/lp_solve -S1 -s$i -timeout 30`;
		if(@result>1&&$result[1]=~/Value of objective function: (.*)$/) {
			$min=$1;
			last;
		}
	}
	$lpdata->{objective}=$fvatf;
	$file=writelp($lpdata);
#	if($fvatf==4615) {
#		open(WY, ">fbatest.lp");
#		print(WY $file);
#		close(WY);
#	}
	for(my $i=-1;$i<8;$i++) {
		
		my @result=$i<0?`echo "$file"|~/Software/lp_solve/lp_solve -S1 -timeout 30`:
		`echo "$file"|~/Software/lp_solve/lp_solve -S1 -s$i -timeout 30`;
		if(@result>1&&$result[1]=~/Value of objective function: (.*)$/) {
			$max=$1;
			last;
		}
	}
	defined($min)||warn("Min not defined");
	defined($max)||warn("Max not defined");
	return [$min,$max];
}

sub permute {
    my @items = @{ $_[0] };
    my @perms = @{ $_[1] };
    my $res=$_[2];
    unless (@items) {
        push(@{$res},\@perms);
    } else {
        my(@newitems,@newperms,$i);
        foreach $i (0 .. $#items) {
            @newitems = @items;
            @newperms = @perms;
            unshift(@newperms, splice(@newitems, $i, 1));
            permute([@newitems], [@newperms],$res);
        }
    }
}
