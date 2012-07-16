#!/usr/bin/perl


open(ZR,"./amlist.csv");
my @amlist=<ZR>;
close(ZR);
open(ZR1,"./am1.txt");
my @am1=<ZR1>;
close(ZR1);

foreach my $key (@amlist) {
	my @am2=grep(/$key/,@am1);
	if(!@am2) {
		print($key);
	}	

}
