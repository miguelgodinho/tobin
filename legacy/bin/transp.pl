#!/usr/bin/perl
	use strict;
	use warnings;
	open(ZR,"./transport.csv");
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
		if(@temparr!=77) {
			print("Improper number of elements in row $i in vds file\n");
			exit();
		}
		$tempreactpao={};
		$tempgenespao={};
		$tempreactppu={};
		$tempgenesppu={};
		for(my $j=0;$j<12;$j++) {
			if(length($temparr[5+$j])||length($temparr[17+$j])) {
				if(length($temparr[5+$j])&&$temparr[29+$j] eq "1") {
					@temploci=grep(/$temparr[5+$j]/,@loci);
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
					$tempgenespao->{$temparr[5+$j]}=[$temploci[0],$temparr[17+$j]];
					$tempgenesppu->{$temparr[5+$j]}=[$temparr[53+$j],$temparr[17+$j]];
				}
				elsif(length($temparr[17+$j])&&$temparr[41+$j] eq "1") {
					@temploci=grep(/$temparr[17+$j]/,@loci);
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
					$tempgenespao->{$temparr[17+$j]}=[$temploci[0],$temparr[5+$j]];
					$tempgenesppu->{$temparr[17+$j]}=[$temparr[53+$j],$temparr[5+$j]];
				}
				elsif(length($temparr[5+$j])) {
					$tempgenespao->{$temparr[5+$j]}=["0",$temparr[17+$j]];
					$tempgenesppu->{$temparr[5+$j]}=[$temparr[53+$j],$temparr[18+$j]];
				}
				else {
					$tempgenespao->{$temparr[17+$j]}=["0",""];
					$tempgenesppu->{$temparr[17+$j]}=[$temparr[53+$j],$temparr[5+$j]];
				}
			}
		}
		if(length($temparr[2])) {
			$tempreactpao->{"Reaction"}=$temparr[2];
			$tempreactppu->{"Reaction"}=$temparr[2];
		}
		if(length($temparr[1])) {
			$tempreactpao->{"Compound"}=$temparr[1];
			$tempreactppu->{"Compound"}=$temparr[1];
		}
		$tempreactpao->{"Present"}=$temparr[4];
		$tempreactppu->{"Present"}=$temparr[3];
		$tempreactpao->{"Genes"}=$tempgenespao;
		$tempreactppu->{"Genes"}=$tempgenesppu;
		$vdsdatapao->{$temparr[0]}=$tempreactpao;
		$vdsdatappu->{$temparr[0]}=$tempreactppu;
	}
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
		$paodata->{$temparr[0]}=$tempreactpao;
		
	}
	my $paognames = {};
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
		$ppudata->{$temparr[0]}=$tempreactpao;
		
	}
	my $ppugnames = {};
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
	}
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
				if($gkeys eq "") {
					print("epty key\n");
				}
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
					print("No loci for aa$gkeys"."aa");
					if(defined($gvals->[1])&&($gvals->[1] ne "")) {
						print(" aka $gvals->[1]")
					}
					print("!\n");
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
