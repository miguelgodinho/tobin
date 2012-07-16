#!/usr/bin/perl -I. -w
use strict;
use warnings;

@ARGV<2&&die("Too few arguments");

my $dtree1=bdtree($ARGV[0]);
my $dtree2=bdtree($ARGV[1]);
my $fcoupled1=bfchash($ARGV[0]);
my $fcoupled2=bfchash($ARGV[1]);
my $fmap=mapfcoupled($fcoupled1,$fcoupled2);
#warn(keys(%{$fmap->{cmapf}}));
#warn(keys(%{$fmap->{cmapr}}));
foreach (keys(%{$dtree1})) {
	my $node;
	if($_=~/^C/) {
		defined($fmap->{cmapf}->{$_})&&($node=$fmap->{cmapf}->{$_});
	}
	else {
		$node=$_;
	}
	if(!defined($node)) {
		print("No matching node for forward parent node $_\n");
		print("Splitting:\n");
		foreach my $rtf (keys(%{$fcoupled1->{fcoupled}->{substr($_,1,2)}})) {
#			my $node2=defined($fcoupled2->{nodehash}->{$rtf})?
#			"C".$fcoupled2->{nodehash}->{$rtf}:$rtf;
			my $node2=$rtf;
			foreach my $ctf (keys(%{$dtree1->{$_}})) {
				my $node1;
				if($ctf=~/^C/) {
					defined($fmap->{cmapf}->{$ctf})&&($node1=$fmap->{cmapf}->{$ctf});
				}
				else {
					$node1=$ctf;
				}
				if(!defined($node1)) {
					print("No matching node for forward child  $ctf\n");
					print("Splitting:\n");
					foreach my $cctf 
					(keys(%{$fcoupled1->{fcoupled}->{substr($ctf,1,2)}})) {
#						my $node3=defined($fcoupled2->{nodehash}->{$cctf})?
#						"C".$fcoupled2->{nodehash}->{$cctf}:$cctf;
						my $node3=$cctf;
						if(!defined($dtree2->{$node2}->{$node3})) {
							print("No matching relation for forward  $rtf and $cctf\n")
						}
					}
					print("End Splitting\n");
				}
				elsif (!defined($dtree2->{$node2}->{$node1})) {
					print("No matching relation for forward  $rtf and $node1\n");
				}
			}
		}
		print("End Splitting\n");
		next;
	}
	elsif(!defined($dtree2->{$node})) {
		print("$node has no children in second\n");
		foreach my $tf (keys(%{$dtree1->{$_}})) {
			print("No matching relation for forward  $_ and $tf\n");
		}
		next;
	}
	foreach my $tf (keys(%{$dtree1->{$_}})) {
		my $node1;
		if($tf=~/^C/) {
			defined($fmap->{cmapf}->{$tf})&&($node1=$fmap->{cmapf}->{$tf});
		}
		else {
			$node1=$tf;
		}
		if(!defined($node1)) {
			print("No matching node for forward child  $tf\n");
			print("Splitting:\n");
			foreach my $ctf (keys(%{$fcoupled1->{fcoupled}->{substr($tf,1,2)}})) {
				if(!defined($dtree2->{$node}->{$ctf})) {
					print("No matching relation for forward  $_ and $ctf\n");
				}
			}
			print("End Splitting\n");
			next;
		}
		elsif(!defined($dtree2->{$node}->{$node1})) {
			print("No matching relation for forward  $_ and $tf\n");
		}
	}
	defined($dtree2->{$node})||next;
	foreach my $tf (keys(%{$dtree2->{$node}})) {
		my $node1;
		if($tf=~/^C/) {
			defined($fmap->{cmapr}->{$tf})&&($node1=$fmap->{cmapr}->{$tf});
		}
		else {
			$node1=$tf;
		}
		if(!defined($node1)) {
			print("No matching node for reverse child  $tf\n");
			print("Splitting:\n");
			foreach my $ctf (keys(%{$fcoupled2->{fcoupled}->{substr($tf,1,2)}})) {
				if(!defined($dtree1->{$_}->{$ctf})) {
					print("No matching relation for reverse  $node and $ctf\n");
				}
			}
			print("End Splitting\n");
			next;
		}
		elsif(!defined($dtree1->{$_}->{$node1})) {
			print("No matching relation for reverse  $node and $tf\n");
		}
	}
}
foreach(keys(%{$dtree2})) {
	my $node;
	if($_=~/^C/) {
		defined($fmap->{cmapr}->{$_})&&($node=$fmap->{cmapr}->{$_});
	}
	else {
		$node=$_;
	}
	if(!defined($node)) {
		print("No matching node for reverse parent node $_\n");
		print("Splitting:\n");
		foreach my $rtf (keys(%{$fcoupled2->{fcoupled}->{substr($_,1,2)}})) {
			foreach my $ctf (keys(%{$dtree2->{$_}})) {
				my $node1;
				if($ctf=~/^C/) {
					defined($fmap->{cmapr}->{$ctf})&&($node1=$fmap->{cmapr}->{$ctf});
				}
				else {
					$node1=$ctf;
				}
				if(!defined($node1)) {
					print("No matching node for forward child  $ctf\n");
					print("Splitting:\n");
					foreach my $cctf 
					(keys(%{$fcoupled2->{fcoupled}->{substr($ctf,1,2)}})) {
						if(!defined($dtree1->{$rtf}->{$cctf})) {
							print("No matching relation for forward  $rtf and $cctf\n")
						}
					}
					print("End Splitting\n");
				}
				elsif (!defined($dtree1->{$rtf}->{$node1})) {
					print("No matching relation for forward  $rtf and $node1\n");
				}
			}
		}
		next;
	}
	elsif(!defined($dtree1->{$node})) {
		print("$node has no children in first\n");
		foreach my $tf (keys(%{$dtree2->{$_}})) {
			print("No matching relation for reverse  $_ and $tf\n");
		}
	}
	
}



sub bdtree {
	my $file=shift;
	open(WE,$file)||die("Cannot open input file - $file");
	my @tab=<WE>;
	close(WE);

	my @tab1=grep(/^Directionally/../^Fully/,@tab);
	my $dcoupled={};
	for(1..(@tab1-2)) {
		chomp($tab1[$_]);
		my @tab2=split(/\t/,$tab1[$_]);
		my @tab3=split(/, /,$tab2[1]);
		$dcoupled->{$tab2[0]}={};
		foreach my $tf (@tab3) {
			$dcoupled->{$tab2[0]}->{$tf}=1;
		}
	}

	@tab1=grep(/^Fully/../^Partially/,@tab);
	my $nodehash={};
	for(1..(@tab1-2)) {
		chomp($tab1[$_]);
		my @tab2=split(/: /,$tab1[$_]);
		my @tab3=split(/, /,$tab2[1]);
		foreach my $tf (@tab3) {
			$nodehash->{$tf}=$tab2[0];
		}
	}
	@tab1=grep(/^Partially/../^digraph/,@tab);
	for(1..(@tab1-2)) {
		chomp($tab1[$_]);
		my @tab2=split(/: /,$tab1[$_]);
		my @tab3=split(/, /,$tab2[1]);
		foreach my $tf (@tab3) {
			$nodehash->{$tf}=$tab2[0];
		}
	}

	my $dtree={};
	my $rooted={};
	my $newroots={};
	foreach(keys(%{$dcoupled})) {
	#	defined($dtree->{$_})&&next;
		my $bad=0;
		foreach my $rtf (keys(%{$dcoupled})) {
	#		defined($dtree->{$rtf})&&next;
			foreach my $tf(keys(%{$dcoupled->{$rtf}})) {
				$tf==$_&&($bad=1)&&last;
			}
			$bad&&last;
		}
		if(!$bad) {
			$newroots->{$_}=1;
		}
	}
#	warn(keys(%{$newroots})."\n");
	do {
		my $nextroots={};
#		warn("Round");
		foreach(keys(%{$newroots})) {
			$rooted->{$_}=1;
			my $node;
			if(defined($nodehash->{$_})) {
				defined($dtree->{"C".$nodehash->{$_}})&&next;
				$node="C".sprintf("%02d",$nodehash->{$_});
			}
			else {
				$node=sprintf("%04d",$_);
			}
			$dtree->{$node}={};
			foreach my $ctf (keys(%{$dcoupled->{$_}})) {
				my $bad=0;
				foreach my $rtf (keys(%{$dcoupled})) {
					defined($rooted->{$_})&&next;
#					defined($newroots->{$rtf})&&next;
					foreach my $tf(keys(%{$dcoupled->{$rtf}})) {
						$tf==$ctf&&($bad=1)&&last;
					}
					$bad&&last;
				}
				if(!$bad) {
					my $node1;
					if(defined($nodehash->{$ctf})) {
						$node1="C".sprintf("%02d",$nodehash->{$ctf});
					}
					else {
						$node1=sprintf("%04d",$ctf);
					}
					$nextroots->{$ctf}=1;
					$dtree->{$node}->{$node1}=1;
				}
			}
		}
		$newroots=$nextroots;
#		warn(keys(%{$newroots})."\n");
	} while(keys(%{$newroots}));
	return $dtree;
}
sub bfchash {
	my $file=shift;
	open(WE,$file)||die("Cannot open input file - $file");
	my @tab=<WE>;
	close(WE);
	my $fcoupled1={};
	my $nodehash1={};
	my @tab1=grep(/^Fully/../^Partially/,@tab);
	for(1..(@tab1-2)) {
		chomp($tab1[$_]);
		my @tab2=split(/: /,$tab1[$_]);
		my @tab3=split(/, /,$tab2[1]);
		$fcoupled1->{$tab2[0]}={};
		foreach my $tf (@tab3) {
			$nodehash1->{$tf}=$tab2[0];
			$fcoupled1->{$tab2[0]}->{$tf}=1;
		}
	}
	@tab1=grep(/^Partially/../^digraph/,@tab);
	for(1..(@tab1-2)) {
		chomp($tab1[$_]);
		my @tab2=split(/: /,$tab1[$_]);
		my @tab3=split(/, /,$tab2[1]);
		defined($fcoupled1->{$tab2[0]})||($fcoupled1->{$tab2[0]}={});
		foreach my $tf (@tab3) {
			$nodehash1->{$tf}=$tab2[0];
			$fcoupled1->{$tab2[0]}->{$tf}=1;
		}
	}
	return({nodehash=>$nodehash1,fcoupled=>$fcoupled1});
}

sub mapfcoupled {
	my $res1=shift;
	my $res2=shift;
	my $cmapf={};
	my $cmapr={};
	my $assigned1={};
	my $assigned2={};
	foreach(keys(%{$res1->{fcoupled}})) {
		my $cmap1={};
		foreach my $tf (keys(%{$res1->{fcoupled}->{$_}})) {
#			$_==24&&warn($nodehash2->{$tf});
			if(defined($res2->{nodehash}->{$tf})) {
				defined($cmap1->{$res2->{nodehash}->{$tf}})||($cmap1->{$res2->{nodehash}->{$tf}}=0);
				$cmap1->{$res2->{nodehash}->{$tf}}++;
			}
		}
		if(keys(%{$cmap1})==1) {
			if(keys(%{$res1->{fcoupled}->{$_}})==keys(%{$res2->{fcoupled}->{(keys(%{$cmap1}))[0]}})) {
				$assigned2->{(keys(%{$cmap1}))[0]}=1;
				$assigned1->{$_}=1;
				$cmapf->{"C".sprintf("%02d",$_)}="C".sprintf("%02d",(keys(%{$cmap1}))[0]);
				$cmapr->{"C".sprintf("%02d",(keys(%{$cmap1}))[0])}="C".sprintf("%02d",$_);
			}
#			else {
#				$assigned2->{(keys(%{$cmap1}))[0]}=1;
#				$assigned1->{$_}=1;
#				$cmapf->{"C".sprintf("%02d",$_)}="C".sprintf("%02d",(keys(%{$cmap1}))[0]);
#				$cmapr->{"C".sprintf("%02d",(keys(%{$cmap1}))[0])}="C".sprintf("%02d",$_);
#			}
		}
	}
	my $unassigned1={};
	foreach(keys(%{$res1->{fcoupled}})) {
			defined($assigned1->{$_})&&next;
			$unassigned1->{"C".sprintf("%02d",$_)}=1;
	}
	my $unassigned2={};
	foreach(keys(%{$res2->{fcoupled}})) {
			defined($assigned2->{$_})&&next;
			$unassigned2->{"C".sprintf("%02d",$_)}=1;
	}
	return({cmapf=>$cmapf,cmapr=>$cmapr, unass1=>$unassigned1,unass2=>$unassigned2});
}
