#!/usr/bin/perl
	use strict;
	use warnings;
	open(ZR,"./reakcje1.csv");
	my @reactions=<ZR>;
	close(ZR);
	open(ZR,"./loci.csv");
	my @loci=<ZR>;
	close(ZR);
	my $vdsdatapao={};
	my $vdsdatappu={};
	my @temploci;
	my $tempgenespao={};
	my $tempgenesppu={};
	my $tempreactpao={};
	my $tempreactppu={};
	my @temparr;
	for(my $i=0;$i<@reactions;$i++) {
		@temparr=split(/\t/,$reactions[$i]);
		if(@temparr!=78) {
			print("Improper number of elements in row $i\n in vds file");
			exit();
		}
		$tempreactpao={};
		$tempgenespao={};
		$tempreactppu={};
		$tempgenesppu={};
		for(my $j=0;$j<12;$j++) {
			if(length($temparr[6+$j])||length($temparr[18+$j])) {
				if(length($temparr[6+$j])&&$temparr[30+$j] eq "1") {
					@temploci=grep(/$temparr[6+$j]/,@loci);
					if(@temploci==1) {
						@temploci=split(/\t/,$temploci[0]);
					}
					elsif (!@temploci) {
#						print($temparr[0]." none \n");
						$temploci[0]="0";
					}
					else {
#						print($temparr[0]." ".$temparr[6+$j]." many \n");
#						foreach(@temploci) {
#							print("$_");
#						}
						$temploci[0]="0"
					}
					$tempgenespao->{$temparr[6+$j]}=[$temploci[0],$temparr[18+$j]];
					$tempgenesppu->{$temparr[6+$j]}=[$temparr[54+$j],$temparr[18+$j]];
				}
				elsif(length($temparr[18+$j])&&$temparr[42+$j] eq "1") {
					@temploci=grep(/$temparr[18+$j]/,@loci);
					if(@temploci==1) {
						@temploci=split(/\t/,$temploci[0]);
					}
					elsif (!@temploci) {
#						print($temparr[0]." none \n");
						$temploci[0]="0";
					}
					else {
#						print($temparr[0]." ".$temparr[18+$j]." many \n");
#						foreach(@temploci) {
#							print("$_");
#						}
						$temploci[0]="0"
					}
					$tempgenespao->{$temparr[18+$j]}=[$temploci[0],$temparr[6+$j]];
					$tempgenesppu->{$temparr[18+$j]}=[$temparr[54+$j],$temparr[6+$j]];
				}
				elsif(length($temparr[6+$j])) {
					$tempgenespao->{$temparr[6+$j]}=["0",$temparr[18+$j]];
					$tempgenesppu->{$temparr[6+$j]}=[$temparr[54+$j],$temparr[18+$j]];
				}
				else {
					$tempgenespao->{$temparr[18+$j]}=["0",""];
					$tempgenesppu->{$temparr[18+$j]}=[$temparr[54+$j],$temparr[6+$j]];
				}
			}
		}
		if(length($temparr[3])) {
			$tempreactpao->{"ECNumber"}=$temparr[3];
			$tempreactppu->{"ECNumber"}=$temparr[3];
		}
		if(length($temparr[2])) {
			$tempreactpao->{"Reaction"}=$temparr[2];
			$tempreactppu->{"Reaction"}=$temparr[2];
		}
		if(length($temparr[1])) {
			$tempreactpao->{"Enzyme"}=$temparr[1];
			$tempreactppu->{"Enzyme"}=$temparr[1];
		}
		$tempreactpao->{"Present"}=$temparr[5];
		$tempreactppu->{"Present"}=$temparr[4];
		$tempreactpao->{"Genes"}=$tempgenespao;
		$tempreactppu->{"Genes"}=$tempgenesppu;
		$vdsdatapao->{$temparr[0]}=$tempreactpao;
		$vdsdatappu->{$temparr[0]}=$tempreactppu;
	}
#	print($vdsdata->{"GLK1"}->{"ECNumber"}."\n");
#	print($vdsdata->{"GLK1"}->{"Enzyme"}."\n");
#	print($vdsdata->{"GLK1"}->{"Reaction"}."\n");
#	print($vdsdata->{"GLK1"}->{"Present"}->[1]."\n");
#	foreach my $g (values(%{$vdsdata->{"GLK1"}->{"Genes"}})) {
#		print(@{$g}."\n");
#		foreach(@{$g}) {
#			print($_."\n");
#		}
#	}	
	my $paodata={};
	open(ZR, "./pao.csv");
	@reactions=<ZR>;
	close(ZR);
	my @tempaltn;
	my $tempgnames=[];
 	for(my $i=1;$i<@reactions;$i++) {
		@temparr=split(/\t/,$reactions[$i]);
		if(@temparr!=6) {
			print("Improper number of elements in row $i\n in pao file");
			exit();
		}
		$tempgnames=[];
		$tempreactpao={};
		length($temparr[1])?push(@{$tempgnames},$temparr[1]):0;
		if(length($temparr[2])) {
			@tempaltn=split(/ ;/,$temparr[2]);
			for(my $j=0;$j<@tempaltn;$j++) {
				if($tempaltn[$j] ne "") {
					push(@{$tempgnames},$tempaltn[$j]);
				}
			}
		}
#		length($temparr[4])?push(@{$tempgnames},$temparr[4]):0;
		if(@{$tempgnames}) {
			$tempreactpao->{"Genes"}=$tempgnames;
		}
		$tempreactpao->{"Seq"}=$temparr[5];
		$tempgnames=[];
		if(length($temparr[3])) {
			@tempaltn=split(/ ;/,$temparr[3]);
			for(my $j=0;$j<@tempaltn;$j++) {
				if($tempaltn[$j] ne "") {
					push(@{$tempgnames},$tempaltn[$j]);
				}
			}
			$tempreactpao->{"ECNumber"}=$tempgnames;
		}
		$paodata->{$temparr[0]}=$tempreactpao;
		
	}
	my $paognames = {};
	my $paoec = {};
	foreach  my $pkeys (keys(%{$paodata})) {
		if(defined($paodata->{$pkeys}->{"Genes"})) {
			foreach (@{$paodata->{$pkeys}->{"Genes"}}) {
				if(!defined($paognames->{$_})) {
					$paognames->{$_}=[$pkeys];
				}
				elsif($paognames->{$_} ne $pkeys)   {
					$paognames->{$_}=[@{$paognames->{$_}},$pkeys];
				}
			}
		}
		if(defined($paodata->{$pkeys}->{"ECNumber"})) {
			foreach(@{$paodata->{$pkeys}->{"ECNumber"}}) {
				$paoec->{$_}=defined($paoec->{$_})?[@{$paoec->{$_}}, $pkeys]:[$pkeys];
			}
		}
	}
	open(ZR, "./ppu.csv");
	@reactions=<ZR>;
	close(ZR);
	my $ppudata={};
 	for(my $i=1;$i<@reactions;$i++) {
		@temparr=split(/\t/,$reactions[$i]);
		if(@temparr!=6) {
			print("Improper number of elements in row $i\n in pao file");
			exit();
		}
		$tempgnames=[];
		$tempreactpao={};
		length($temparr[1])?push(@{$tempgnames},$temparr[1]):0;
		if(length($temparr[2])) {
			@tempaltn=split(/ ;/,$temparr[2]);
			for(my $j=0;$j<@tempaltn;$j++) {
				if($tempaltn[$j] ne "") {
					push(@{$tempgnames},$tempaltn[$j]);
				}
			}
		}
#		length($temparr[4])?push(@{$tempgnames},$temparr[4]):0;
		if(@{$tempgnames}) {
			$tempreactpao->{"Genes"}=$tempgnames;
		}
		$tempreactpao->{"Seq"}=$temparr[5];
		$tempgnames=[];
		if(length($temparr[3])) {
			@tempaltn=split(/ ;/,$temparr[3]);
			for(my $j=0;$j<@tempaltn;$j++) {
				if($tempaltn[$j] ne "") {
					push(@{$tempgnames},$tempaltn[$j]);
				}
			}
			$tempreactpao->{"ECNumber"}=$tempgnames;
		}
		$ppudata->{$temparr[0]}=$tempreactpao;
		
	}
	my $ppugnames = {};
	my $ppuec = {};
	foreach  my $pkeys (keys(%{$ppudata})) {
		if(defined($ppudata->{$pkeys}->{"Genes"})) {
			foreach (@{$ppudata->{$pkeys}->{"Genes"}}) {
				if(!defined($ppugnames->{$_})) {
					$ppugnames->{$_}=[$pkeys];
				}
				elsif($ppugnames->{$_} ne $pkeys)   {
					$ppugnames->{$_}=[@{$ppugnames->{$_}},$pkeys];
				}
			}
		}
		if(defined($ppudata->{$pkeys}->{"ECNumber"})) {
			foreach(@{$ppudata->{$pkeys}->{"ECNumber"}}) {
				$ppuec->{$_}=defined($ppuec->{$_})?[@{$ppuec->{$_}}, $pkeys]:[$pkeys];
			}
		}
	}
	my $paocorr={};
	my $paofull={};
	my $kon=1;
	
	for(my $i=0;$kon;$i++) {
	$kon=0;
	print("round $i\n");
	foreach my $rkeys (keys(%{$vdsdatapao})) {
		if(($vdsdatapao->{$rkeys}->{"Present"} eq "1")&&!defined($paofull->{$rkeys})) {
			my $rvals=$vdsdatapao->{$rkeys};
			my $correct=0;
			print("\n\n$rkeys\n");
			if(!keys(%{$rvals->{"Genes"}})) {
				print("No gene associated to reaction!\n");
			}
			foreach my $gkeys (keys(%{$rvals->{"Genes"}})) {
				my $gvals=$rvals->{"Genes"}->{$gkeys};
				my @tmpcomp0;
				my @tmpcomp1;
				if($gvals->[0] ne "0") {
					if(defined($paodata->{$gvals->[0]})) {
						@tmpcomp0 = grep(/$gkeys/,@{$paodata->{$gvals->[0]}->{"Genes"}});
						@tmpcomp1 = grep(/$gvals->[1]/,@{$paodata->{$gvals->[0]}->{"Genes"}});
						if((@tmpcomp0&&($tmpcomp0[0] eq $gkeys))||(@tmpcomp1&&($tmpcomp1[0] eq $gvals->[1]))) {
							print("Gene names correct for $gkeys \n");
						}
						else {
							print("Gene names incorrect for $gkeys \n");
							print($gkeys." ".$gvals->[1]."\n");
							foreach(@{$paodata->{$gvals->[0]}->{"Genes"}}) {
								print($_.", ");
							}
							print("\n");
							$correct|=2;
						}
						if(defined($rvals->{"ECNumber"})&&defined($paodata->{$gvals->[0]}->{"ECNumber"})) {
							@tmpcomp0=grep(/$rvals->{"ECNumber"}/,@{$paodata->{$gvals->[0]}->{"ECNumber"}});
							if(@tmpcomp0) {
								print("ECNumbers correct for $gkeys\n");
								if(@{$paodata->{$gvals->[0]}->{"ECNumber"}}>1) {
									print("Multiple EC numbers! One assumed correct!\n");
								}
							}
							else {
								print("ECNumbers incorrect for $gkeys\n");
								print($rvals->{"ECNumber"}."\n");
								foreach(@{$paodata->{$gvals->[0]}->{"ECNumber"}}) {
									print("$_ ");
								}
								print("\n");
								$correct|=4;
							}
						}
						elsif(defined($rvals->{"ECNumber"})) {
							print("No EC in psd, vds assumed correct\n");
							$paodata->{$gvals->[0]}->{"ECNumber"}=[$rvals->{"ECNumber"}];
							$kon=1;
						}
						elsif(defined($paodata->{$gvals->[0]}->{"ECNumber"})&&@{$paodata->{$gvals->[0]}->{"ECNumber"}}==1) {
							print("No EC in vds, psd assumed correct\n");
							$rvals->{"ECNumber"}=$paodata->{$gvals->[0]}->{"ECNumber"};
							$kon=1;
						}
						elsif(defined($paodata->{$gvals->[0]}->{"ECNumber"})) {
							print("No EC in vds, multiple EC in psd, check manually\n");
							$correct|=4;
						}
					}
					else {
					 print("Bad loci $gvals->[0] for gene $gkeys. Doing nothing.\n");
					 $correct|=32;
					}
				}
				elsif((defined($paognames->{$gkeys})&&@{$paognames->{$gkeys}}==1&&!defined($paognames->{$gvals->[1]}))) {
					print("No loci in vds for $gkeys. Assuming value $paognames->{$gkeys}->[0] from psd.\n");
					$gvals->[0]=$paognames->{$gkeys}->[0];
					$kon=1;
					$correct|=8;
				}
				elsif((defined($paognames->{$gvals->[1]})&&@{$paognames->{$gvals->[1]}}==1&&!defined($paognames->{$gkeys}))) {
					print("No loci in vds for $gkeys. Assuming value $paognames->{$gvals->[1]}->[0] from psd.\n");
					$gvals->[0]=$paognames->{$gvals->[1]}->[0];
					$kon=1;
					$correct|=8;
				}
				elsif(defined($paognames->{$gkeys})||defined($paognames->{$gvals->[1]})) {
					print("Multiple possible loci assignments for $gkeys, choose one: ");
					if(defined($paognames->{$gkeys})) {
						foreach(@{$paognames->{$gkeys}}) {
							print("$_ ");
						}
					}
					if(defined($paognames->{$gvals->[1]})) {
						foreach(@{$paognames->{$gvals->[1]}}) {
							print("$_ ");
						}
					}
					$correct|=8;
				}
				else {
					print("No loci for $gkeys");
					if(defined($gvals->[1])&&($gvals->[1] ne "")) {
						print(" aka $gvals->[1]")
					}
					print("!\n");
					if(defined($rvals->{"ECNumber"})&&defined($paoec->{$rvals->{"ECNumber"}})) {
						print("According to psd following genes take part in reaction with EC ".$rvals->{"ECNumber"}.":\n");
						foreach(@{$paoec->{$rvals->{"ECNumber"}}}) {
							print($_." ")
						}
						print("\n");
					}
					$correct|=16;
				}
			}
			if(!$correct) {
				$paofull->{$rkeys}=$rvals;
			}
		}
	}
	}
	my $counter=0;
	foreach(values(%{$vdsdatapao})) {
		if($_->{"Present"} eq "1") {
			$counter++;
		}
	}
	print(keys(%{$vdsdatapao})." ".$counter." ".keys(%{$paofull})."\n");
	print("\n PUTIDA\n");
	my $ppufull={};
	$kon=1;
	
	for(my $i=0;$kon;$i++) {
	$kon=0;
	print("round $i\n");
	foreach my $rkeys (keys(%{$vdsdatappu})) {
		if(($vdsdatappu->{$rkeys}->{"Present"} eq "1")&&!defined($ppufull->{$rkeys})) {
			my $rvals=$vdsdatappu->{$rkeys};
			my $correct=0;
			print("\n\n$rkeys\n");
			if(!keys(%{$rvals->{"Genes"}})) {
				print("No gene associated to reaction!\n");
			}
			foreach my $gkeys (keys(%{$rvals->{"Genes"}})) {
				my $gvals=$rvals->{"Genes"}->{$gkeys};
				my @tmpcomp0;
				my @tmpcomp1;
				if($gvals->[0] ne "0"&&$gvals->[0] ne "1") {
					if(defined($ppudata->{$gvals->[0]})) {
						@tmpcomp0 = grep(/$gkeys/,@{$ppudata->{$gvals->[0]}->{"Genes"}});
						@tmpcomp1 = grep(/$gvals->[1]/,@{$ppudata->{$gvals->[0]}->{"Genes"}});
						if((@tmpcomp0&&($tmpcomp0[0] eq $gkeys))||(@tmpcomp1&&($tmpcomp1[0] eq $gvals->[1]))) {
							print("Gene names correct for $gkeys \n");
						}
						else {
							print("Gene names incorrect for $gkeys \n");
							print($gkeys." ".$gvals->[1]."\n");
							foreach(@{$ppudata->{$gvals->[0]}->{"Genes"}}) {
								print($_.", ");
							}
							print("\n");
							$correct|=2;
						}
						if(defined($rvals->{"ECNumber"})&&defined($ppudata->{$gvals->[0]}->{"ECNumber"})) {
							@tmpcomp0=grep(/$rvals->{"ECNumber"}/,@{$ppudata->{$gvals->[0]}->{"ECNumber"}});
							if(@tmpcomp0) {
								print("ECNumbers correct for $gkeys\n");
								if(@{$ppudata->{$gvals->[0]}->{"ECNumber"}}>1) {
									print("Multiple EC numbers! One assumed correct!\n");
								}
							}
							else {
								print("ECNumbers incorrect for $gkeys\n");
								print($rvals->{"ECNumber"}."\n");
								foreach(@{$ppudata->{$gvals->[0]}->{"ECNumber"}}) {
									print("$_ ");
								}
								print("\n");
								$correct|=4;
							}
						}
						elsif(defined($rvals->{"ECNumber"})) {
							print("No EC in ppu, vds assumed correct\n");
							$ppudata->{$gvals->[0]}->{"ECNumber"}=[$rvals->{"ECNumber"}];
							$kon=1;
						}
						elsif(defined($ppudata->{$gvals->[0]}->{"ECNumber"})&&@{$ppudata->{$gvals->[0]}->{"ECNumber"}}==1) {
							print("No EC in vds, ppu assumed correct\n");
							$rvals->{"ECNumber"}=$ppudata->{$gvals->[0]}->{"ECNumber"};
							$kon=1;
						}
						elsif(defined($ppudata->{$gvals->[0]}->{"ECNumber"})) {
							print("No EC in vds, multiple EC in ppu, check manually\n");
							$correct|=4;
						}
					}
					else {
					 print("Bad loci $gvals->[0] for gene $gkeys. Doing nothing.\n");
					 $correct|=32;
					}
				}
				elsif((defined($ppugnames->{$gkeys})&&@{$ppugnames->{$gkeys}}==1&&!defined($ppugnames->{$gvals->[1]}))) {
					print("No loci in vds for $gkeys. Assuming value $ppugnames->{$gkeys}->[0] from ppu.\n");
					$gvals->[0]=$ppugnames->{$gkeys}->[0];
					$kon=1;
					$correct|=8;
				}
				elsif((defined($ppugnames->{$gvals->[1]})&&@{$ppugnames->{$gvals->[1]}}==1&&!defined($ppugnames->{$gkeys}))) {
					print("No loci in vds for $gkeys. Assuming value $ppugnames->{$gvals->[1]}->[0] from ppu.\n");
					$gvals->[0]=$ppugnames->{$gvals->[1]}->[0];
					$kon=1;
					$correct|=8;
				}
				elsif(defined($ppugnames->{$gkeys})||defined($ppugnames->{$gvals->[1]})) {
					print("Multiple possible loci assignments for $gkeys, choose one: ");
					if(defined($ppugnames->{$gkeys})) {
						foreach(@{$ppugnames->{$gkeys}}) {
							print("$_ ");
						}
					}
					if(defined($ppugnames->{$gvals->[1]})) {
						foreach(@{$ppugnames->{$gvals->[1]}}) {
							print("$_ ");
						}
					}
					print("\n");
					$correct|=8;
				}
				else {
					print("No loci for $gkeys");
					if(defined($gvals->[1])&&($gvals->[1] ne "")) {
						print(" aka $gvals->[1]")
					}
					print("!\n");
					if(defined($rvals->{"ECNumber"})&&defined($ppuec->{$rvals->{"ECNumber"}})) {
						print("According to ppu following genes take part in reaction with EC ".$rvals->{"ECNumber"}.":\n");
						foreach(@{$ppuec->{$rvals->{"ECNumber"}}}) {
							print($_." ")
						}
						print("\n");
					}
					$correct|=16;
				}
			}
			if(!$correct) {
				$ppufull->{$rkeys}=$rvals;
			}
		}
	}
	}
	$counter=0;
	foreach(values(%{$vdsdatappu})) {
		if($_->{"Present"} eq "1") {
			$counter++;
		}
	}
	print(keys(%{$vdsdatappu})." ".$counter." ".keys(%{$ppufull})."\n");
#		
#		foreach my $rkeys (keys(%{$paocorr})) {
#			my $rvals=$vdsdatapao->{$rkeys};
#			if($paocorr->{$rkeys}&4) {
#				foreach my $gkeys (keys(%{$rvals->{"Genes"}})) {
#					my $gvals=$rvals->{"Genes"}->{$gkeys};
#					if(defined($rvals->{"ECNumber"})&&defined($paodata->{$gvals->[0]}->{"ECNumber"})) {
#						print("Different EC numbers  for reaction $rkeys and gene $gkeys!\n");
#						print("vds: ".$rvals->{"ECNumber"}."\npsd: ");
#						foreach(@{$paodata->{$gvals->[0]}->{"ECNumber"}}) {
#							print("$_ ");
#						}
#						print("\n");
#					}
#				}
#			}
#		}

	open(ZR,"./metabolites.csv");
	my @metabolites=<ZR>;
	close(ZR);
	my $Metamap = {};
	foreach(@metabolites) {
		$Metamap->{(split(/\t/,$_))[0]}=(split(/\t/,$_))[1]
	}
	my @RString;
	my $Compnames = {};
	my $compmap = {};
	foreach my $rkey (keys(%{$paofull})) {
		$Compnames={};
		if(length($paofull->{$rkey}->{"Reaction"})) {
			@RString=split(/[^0-9A-Za-z]/,$paofull->{$rkey}->{"Reaction"});
			foreach(@RString) {
				if(!defined($Metamap->{$_})) {
					print("No metabolite for code $_ in reaction $rkey!\n");
				}
				else {
					$Compnames->{$Metamap->{$_}}=1;
				}
				if(length(keys(%{$Compnames}))) {
					$paofull->{$rkey}->{"Compounds"}=$Compnames;
				}
			}
		}		
	}
