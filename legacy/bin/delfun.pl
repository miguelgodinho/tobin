#!/usr/bin/perl -I. -w
use strict;
use warnings;
for(my $i=0;$i<73;$i++) {
`cat ppu-joost-exc2.1.txt |sed -e '\$d' > ppu-joost-exc2.2.txt`;
`mv ppu-joost-exc2.2.txt ppu-joost-exc2.1.txt`;
`./listaffgenes.pl 62 62rev.txt ppu-tf.csv ppu-ecnhcf.csv ppu-cpnhcf.csv ppu-joost-inact1.csv ppu-joost-exc2.1.txt>>delfun.out`;

}
