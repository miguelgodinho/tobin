#!/usr/bin/perl
use strict;
use warnings;

# open(ZR,"./ecs/rlist");
# my @tlist=<ZR>;
# close(ZR);
# open(WY, ">./pcom5.csv");
# foreach my $file (@tlist) {
#	chomp($file);
#	open(ZR1,"./ecs/".$file);
#	my @kegg=<ZR1>;
#	my @knew=grep(/\[RN:/,@kegg);
#	if(@knew) {
#		$knew[0]=~s/^.*href="//;
#		$knew[0]=~s/".*$//;
#		chomp($knew[0]);
#		# "
#		$file=~s/kegg\.1\.htm/rea.1.htm/;
#	print(WY "wget -O ./ecs/".$file." \"www.genome.jp".$knew[0]."\"\n");
#	}
	
#}
open(ZR, "./pcom.csv");
my @data=<ZR>;
close(ZR);
open(WY,">./pcom8.csv");
foreach my $ec (@data) {
	chomp($ec);
	print(WY $ec);
 	if(open(ZR1, "<./ecs/".$ec."kegg.1.htm")||open(ZR1, "<./ecs/".$ec."kegg.htm")) {
 		print(WY "\t");
		my @kegg=<ZR1>;
		my $next=0;
		foreach my $line (@kegg) {
			if(!$next&&$line=~/Reaction/) {
				$next=1;
			}
			elsif($next) {
				chomp($line);
				$line=~s/[<][^<]+[>]//g;
				print(WY $line);
				if($line!~/=$/){
					$next=0;
				}
			}
		}
		my @path=grep(/PATH:/,@kegg);
		print(WY "\t");
		foreach(@path) {
			$_=~s/^.*nbsp;//;
			$_=~s/[<][^>]+[>]//g;
			chomp($_);
			print(WY $_.", ");
		}
# 		while (<ZR1>) {
# 			if(/.*Definition.*/ ... /.*Equation.*/) {
# 				if($_!~/Definition/&&$_!~/Equation/) {
# 				$_=~s/[<][^>]+[>]//g;
# 				$_=~s/&lt;/</;
# 				chomp($_);
#				print(WY $_);
#				}
# 			}
# 		}
 	}
 	print(WY "\n");
 	close(ZR1);
 }
 close(WY);
