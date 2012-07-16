#!/usr/bin/perl -I. -w
use strict;
use warnings;

@ARGV||die("too few arguments");
my $path="/home/jap04/MetabNets/pseudomonasy/ppu-kegg/brenda/";
open(WE, $ARGV[0])||die("Cannot open EC-list.");
my @tab=<WE>;
close(WE);
my $echash={};
foreach(@tab) {
	chomp;
	$echash->{$_}=1;
}
print(keys(%{$echash})."\n");
foreach(keys(%{$echash})) {
	if(!open(WE,$path.$_.".htm")){
		my $url1="http://www.brenda.uni-koeln.de/php/flat_result.php4?ecno=";
		my $url2="&organism_list=&Suchword=";
		my $url=$url1.$_.$url2;
		`wget -O $path$_.htm "$url"`;
		open(WE,$path.$_.".htm")||die("cannot find EC-file. for $_");
	}
	
	@tab=<WE>;
	close(WE);
	my @subs=grep(m%"SUBSTRATE">SUBSTRATE%..m%</table>%,@tab);
	my @rev=grep(m%Pseudomonas putida.*<td>r</td></tr>$%,@subs);
	my @irev=grep(m%Pseudomonas putida.*<td>ir</td></tr>$%,@subs);
	if(@rev xor @irev) {
		@rev?print($_."\tr\n"):print($_."\ti\n");
		delete($echash->{$_});
	}
	elsif(@rev&&@irev) {
		print($_."\tinconsitency in reversibility\n");
	}
	else {
		@rev=grep(m%Escherichia coli.*<td>r</td></tr>$%,@subs);
		@irev=grep(m%Escherichia coli.*<td>ir</td></tr>$%,@subs);
		if(@rev xor @irev) {
			@rev?print($_."\tre\n"):print($_."\tie\n");
			delete($echash->{$_});
		}
		elsif(@rev&&@irev) {
			print($_."\tinconsitency in reversibility for E.coli\n");
		}
	}
	
	
}
print(keys(%{$echash})."\n");
foreach(keys(%{$echash})) {
	open(WE,$path.$_.".htm");
	@tab=<WE>;
	close(WE);
	my @subs=grep(m%"SUBSTRATE">SUBSTRATE%..m%</table>%,@tab);
	my @rev=grep(m%<td>r</td></tr>$%,@subs);
	my @irev=grep(m%<td>ir</td></tr>$%,@subs);
	if(@rev xor @irev) {
		@rev?print($_."\trg\n"):print($_."\tig\n");
		delete($echash->{$_});
	}
	elsif(@rev&&@irev) {
		print($_."\tinconsitency in general reversibility\n");
	}
}
print(keys(%{$echash})."\n");
