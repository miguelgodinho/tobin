#!/usr/bin/perl -w

open(WE,$ARGV[0]);
my @g2p=<WE>;
close(WE);
my $glist={};
foreach(@g2p) {
	chomp;
	$glist->{$_}=1;
}


foreach(keys(%{$glist})) {
	my $url="perl -MLWP::Simple -e\'getprint(".
		"\"http://www.prodoric.de/gsearch.php?acc=&gpn=".$_.
		"&short_name=&pname=&aname=&genome=&class=\")\' |";
	open(WE,$url);
	my @page=<WE>;
	close(WE);
	my @links=grep(/href="gene.php?/,@page);
	@links||(warn("Acc not found for $_")&&next);
	@links>1&&warn("Multiple Acc for $_");
	$links[0]=~m/href="(gene.php\?gene_acc=GE[0-9]{8})/||die("Cannot match for $_");
	my $link=$1;
	$url="perl -MLWP::Simple -e\'getprint(".
		"\"http://www.prodoric.de/".$link."\")\' |";
#	warn $url;
	open(WE,$url);
	@page=<WE>;
	close(WE);
	$link=~/(GE[0-9]{8})/;
	@links=grep(/>Expresson Profile</,@page);
#	@links=grep(/>Gene Ontology</,@page);
	@links||(print($_."\t".$1."\n")&&next);
	@links>1&&warn("Multiple Profiles for $_");
	my @hits=($links[0]=~m/Condition [0-9]+<.td><td class="text_white_background">([^<]*)<b>([^<]*)/g);
#	my @hits=($links[0]=~m/(GO:[0-9]{7})<.a>&nbsp; \(([^<]*)\)</g);
#	||warn("Cannot match conditi
	$link=~/(GE[0-9]{8})/;
	print($_."\t".$1."\t");
	for(my $i=0;$i<@hits;$i+=2) {
		$hits[$i]=~s/&nbsp;//;
		$hits[$i+1]=~s/&nbsp;/ /;
		print($hits[$i]."\t".$hits[$i+1]."\t");
	}
	print("\n")
}
