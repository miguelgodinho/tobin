#!/usr/bin/perl -I. -w
use strict;
use warnings;

@ARGV||die("Too few arguments");

my $fcoupled=bfchash($ARGV[0]);
my $expdtree=bfullexp($ARGV[0],$ARGV[1],$fcoupled);
foreach(keys(%{$expdtree})) {
	foreach my $ctf (keys(%{$expdtree->{$_}})) {
		print("$_\t$ctf\n");
	}
}
warn(keys(%{$expdtree})."\n");

sub bfullexp {
	my $file=shift;
	my $exclfile=shift;
	my $fcoupled=shift;
	open(WE,$exclfile)||die("Cannot open excluded file");
	my @tab=<WE>;
	close (WE);
	my $excluded={};
	foreach(@tab) {
		chomp;
		my @tab1=split(/\t/,$_);
		defined($excluded->{$tab1[0]})||($excluded->{$tab1[0]}={});
		$excluded->{$tab1[0]}->{$tab1[1]}=1;
	}
	open(WE,$file)||die("Cannot open input file - $file");
	@tab=<WE>;
	close(WE);
	my @tab1=grep(/^Directionally/../^Fully/,@tab);
	my $dcoupled={};
	for(1..(@tab1-2)) {
		chomp($tab1[$_]);
		my @tab2=split(/\t/,$tab1[$_]);
		my @tab3=split(/, /,$tab2[1]);
		$dcoupled->{$tab2[0]}={};
		foreach my $tf (@tab3) {
			defined($excluded->{$tab2[0]}->{$tf})||
			($dcoupled->{$tab2[0]}->{$tf}=1);
		}
	}
	warn(keys(%{$dcoupled})."\n");
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
	foreach(keys(%{$dcoupled})) {
		if(defined($fcoupled->{nodehash}->{$_})) {
			foreach my $tf (keys(%{$fcoupled->{fcoupled}->{$fcoupled->{nodehash}->{$_}}})) {
				defined($dcoupled->{$tf})||($dcoupled->{$tf}={});
				foreach my $ctf (keys(%{$dcoupled->{$_}})) {
					if(defined($fcoupled->{nodehash}->{$ctf})) {
						foreach my $cctf(keys(%{$fcoupled->{fcoupled}->{$fcoupled->{nodehash}->{$ctf}}})) {
							$dcoupled->{$tf}->{$cctf}=1;
						}
					}
					$dcoupled->{$tf}->{$ctf}=1;
				}
			}	
		}
		else {
			foreach my $ctf (keys(%{$dcoupled->{$_}})) {
				defined($fcoupled->{nodehash}->{$ctf})||next;
				foreach my $cctf(keys(%{$fcoupled->{fcoupled}->{$fcoupled->{nodehash}->{$ctf}}})) {
					$dcoupled->{$_}->{$cctf}=1;
				}
			}
			
		}
	}
	return($dcoupled);
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
	print(keys(%{$dcoupled})."\n");
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
	warn(keys(%{$newroots})."\n");
	do {
		my $nextroots={};
#		warn("Round");
		foreach(keys(%{$newroots})) {
			$rooted->{$_}=1;
			my $node;
			if(defined($nodehash->{$_})) {
				$node="C".sprintf("%02d",$nodehash->{$_});
			}
			else {
				$node=sprintf("%04d",$_);
			}
			defined($dtree->{$node})&&next;
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
		warn(keys(%{$newroots})."\n");
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

sub bdexpdtree {
	my $dtree=shift;
	my $fcoupled=shift;
	 
	my $expdtree={};
	foreach(keys(%{$dtree})) {
		if($_=~/^C/) {
#			warn(keys(%{$fcoupled->{fcoupled}->{substr($_,1,2)}})." ");
			foreach my $rtf (keys(%{$fcoupled->{fcoupled}->{substr($_,1,2)}})) {
				defined($expdtree->{$rtf})||($expdtree->{$rtf}={});
				pushchildren($expdtree->{$rtf},$dtree->{$_},$fcoupled);
			}
		}
		else {
			defined($expdtree->{$_})||($expdtree->{$_}={});
			pushchildren($expdtree->{$_},$dtree->{$_},$fcoupled);
		}
	}
	return($expdtree);
}
sub pushchildren {
	my $parent=shift;
	my $children=shift;
	my $fcoupled=shift;
	foreach (keys(%{$children})) {
		if($_=~/^C/) {
			pushchildren($parent, $fcoupled->{fcoupled}->{substr($_,1,2)},$fcoupled);
		}
		 else {
			$parent->{$_}=1;
		 }
	}
}

sub fullexp {
	my $expdtree=shift;
	my $parent=shift;
	my $child=shift;
	foreach(keys(%{$expdtree->{$child}})) {
		$expdtree->{$parent}->{$_}=1;
		defined($expdtree->{$_})&&
		fullexp($expdtree,$parent,$_);
	}
}
