#!/usr/bin/perl -I. -w
use strict;
use warnings;
my $errs=0;
open(WE,$ARGV[0])||die("Cannot open first annotation file");
my @tab=<WE>;
close(WE);
my $tfhashrev1={};
my $echashrev1={};
my $tf2gene1={};
foreach(@tab) {
	chomp;
	my @tab1=split(/\t/,$_);
	defined($tfhashrev1->{$tab1[0]})||($tfhashrev1->{$tab1[0]}={});
	defined($tf2gene1->{$tab1[0]})||($tf2gene1->{$tab1[0]}={});
	for(my $i=1;$i<@tab1;$i+=2) {
		$tfhashrev1->{$tab1[0]}->{$tab1[$i]}=1;
		if($tab1[$i]=~/[0-9]+(\.[0-9]+){3}/) {
			my $old=1;
			if(!defined($echashrev1->{$tab1[$i]})) {
				$echashrev1->{$tab1[$i]}={};
				$old=0;
			}
			my @tab2=split(/,/,$tab1[$i+1]);
			foreach my $gene (@tab2) {
				$old&&!defined($echashrev1->{$tab1[$i]}->{$gene})?
				(print("Different genes for ".$tab1[$i]." in first anno!\n")&&($errs=1)):
				($echashrev1->{$tab1[$i]}->{$gene}=1);
				$tf2gene1->{$tab1[0]}->{$gene}=1;
			}
		}
		else {
			my @tab2=split(/,/,$tab1[$i+1]);
			foreach my $gene (@tab2) {
				$tf2gene1->{$tab1[0]}->{$gene}=1;
			}
		}
		
	}
	keys(%{$tfhashrev1->{$tab1[0]}})||delete($tfhashrev1->{$tab1[0]});
	keys(%{$tf2gene1->{$tab1[0]}})||delete($tf2gene1->{$tab1[0]});	
}

open(WE,$ARGV[1])||die("Cannot open second annotation file");
@tab=<WE>;
close(WE);
my $tfhashrev2={};
my $echashrev2={};
my $tf2gene2={};
foreach(@tab) {
	chomp;
	my @tab1=split(/\t/,$_);
	defined($tfhashrev2->{$tab1[0]})||($tfhashrev2->{$tab1[0]}={});
	defined($tf2gene2->{$tab1[0]})||($tf2gene2->{$tab1[0]}={});
	for(my $i=1;$i<@tab1;$i+=2) {
		$tfhashrev2->{$tab1[0]}->{$tab1[$i]}=1;
		if($tab1[$i]=~/[0-9]+(\.[0-9]+){3}/) {
			my $old=1;
			if(!defined($echashrev2->{$tab1[$i]})) {
				$echashrev2->{$tab1[$i]}={};
				$old=0;
			}
			my @tab2=split(/,/,$tab1[$i+1]);
			foreach my $gene (@tab2) {
				$old&&!defined($echashrev2->{$tab1[$i]}->{$gene})?
				(print("Different genes for ".$tab1[$i]." in second anno $gene!\n")&&($errs=1)):
				($echashrev2->{$tab1[$i]}->{$gene}=1);
				$tf2gene2->{$tab1[0]}->{$gene}=1;
			}
		}
		else {
			my @tab2=split(/,/,$tab1[$i+1]);
			foreach my $gene (@tab2) {
				$tf2gene2->{$tab1[0]}->{$gene}=1;
			}
		}
		
	}
	keys(%{$tfhashrev2->{$tab1[0]}})||delete($tfhashrev2->{$tab1[0]});
	keys(%{$tf2gene2->{$tab1[0]}})||delete($tf2gene2->{$tab1[0]});
	
}
$errs&&exit;
my $skip={};
print("Present in first -  absent in second:\n");
foreach(keys(%{$tfhashrev1})) {
	if(!defined($tfhashrev2->{$_})) {
		$skip->{$_}=1;
		my $str="";
		foreach my $ec (keys(%{$tfhashrev1->{$_}})) {
			$str.=$ec.", "
		}
		$str=~s/, $//;
		$str.="\t";
		foreach my $gene (keys(%{$tf2gene1->{$_}})) {
			$str.=$gene.", "
		}
		$str=~s/, $//;
		print($_."\t".$str."\n");
	}
}
print("Present in second - absent in first:\n");
foreach(keys(%{$tfhashrev2})) {
	if(!defined($tfhashrev1->{$_})) {
		$skip->{$_}=1;
		my $str="";
		foreach my $ec (keys(%{$tfhashrev2->{$_}})) {
			$str.=$ec.", "
		}
		$str=~s/, $//;
		$str.="\t";
		foreach my $gene (keys(%{$tf2gene2->{$_}})) {
			$str.=$gene.", "
		}
		$str=~s/, $//;
		print($_."\t".$str."\n");
	}
}
print("Comparison - EC numbers:\n");
foreach(keys(%{$tfhashrev1})) {
	defined($skip->{$_})&&next;
	print($_);
	my $diffec={};
	my $commec={};
	foreach my $ec (keys(%{$tfhashrev1->{$_}})) {
		defined($tfhashrev2->{$_}->{$ec})?($commec->{$ec}=1):($diffec->{$ec}=1);	
	}
	if(keys(%{$tfhashrev1->{$_}})!=keys(%{$tfhashrev2->{$_}})||keys(%{$diffec})) {
		foreach my $ec (keys(%{$tfhashrev2->{$_}})) {
			defined($tfhashrev1->{$_}->{$ec})||($diffec->{$ec}=-1);	
		}
	}
	if(keys(%{$diffec})) {
		my $str="";
		foreach my $ec (keys(%{$commec})) {
			$str.=$ec.", ";
		}
		$str=~s/ ,$//;
		print("\t".$str);
		$str="";
		my $str1="";
		foreach my $ec (keys(%{$diffec})) {
			$diffec->{$ec}>0?($str.=$ec.", "):($str1.=$ec.", ");
		}
		$str=~s/, $//;
		$str1=~s/, $//;
		print("\t".$str);
		print("\t".$str1);
		
	}
	else {
		print("\tOK");
		my $str="";
		foreach my $ec (keys(%{$commec})) {
			$str.=$ec.", ";
		}
		$str=~s/, $//;
		print("\t".$str);
		
	}
	print("\n");
}
print("Comparison - genes:\n");
foreach(keys(%{$tf2gene1})) {
	defined($skip->{$_})&&next;
	print($_);
	my $diffge={};
	my $commge={};
#	($_ eq "3636/8013")&&print((keys(%{$tf2gene1->{$_}})).(keys(%{$tf2gene2->{$_}}))."\n");
	foreach my $gene (keys(%{$tf2gene1->{$_}})) {
		defined($tf2gene2->{$_}->{$gene})?($commge->{$gene}=1):($diffge->{$gene}=1);	
	}
	if(keys(%{$tf2gene1->{$_}})!=keys(%{$tf2gene2->{$_}})||keys(%{$diffge})) {
		foreach my $gene (keys(%{$tf2gene2->{$_}})) {
			defined($tfhashrev1->{$_}->{$gene})||($diffge->{$gene}=-1);	
		}
	}
#	($_ eq "3636/8013")&&print(keys(%{$diffge})."\n");
	if(keys(%{$diffge})) {
		my $str="";
		foreach my $gene (keys(%{$commge})) {
			$str.=$gene.", ";
		}
		$str=~s/, $//;
		print("\t".$str);
		$str="";
		my $str1="";
		foreach my $gene (keys(%{$diffge})) {
			$diffge->{$gene}>0?($str.=$gene.", "):($str1.=$gene.", ");
		}
		$str=~s/, $//;
		$str1=~s/, $//;
		print("\t".$str);
		print("\t".$str1);
	}
	else {
		print("\tOK");
		my $str="";
		foreach my $gene (keys(%{$commge})) {
			$str.=$gene.", ";
		}
		$str=~s/, $//;
		print("\t".$str);
		
	}
	print("\n");
}
$skip={};
print("ECs present in first - absent in second:\n");
foreach(keys(%{$echashrev1})) {
	if(!defined($echashrev2->{$_})) {
		$skip->{$_}=1;
		my $str="";
		foreach my $gene (keys(%{$echashrev1->{$_}})) {
			$str.=$gene.", "
		}
		$str=~s/, $//;
		print($_."\t".$str."\n");
	}
}
print("ECs present in second - absent in first:\n");
foreach(keys(%{$echashrev2})) {
	if(!defined($echashrev1->{$_})) {
		$skip->{$_}=1;
		my $str="";
		foreach my $gene (keys(%{$echashrev2->{$_}})) {
			$str.=$gene.", "
		}
		$str=~s/, $//;
		print($_."\t".$str."\n");
	}
}
print("Comparison:\n");
foreach(keys(%{$echashrev1})) {
	defined($skip->{$_})&&next;
	print($_);
	my $diffge={};
	my $commge={};
	foreach my $gene (keys(%{$echashrev1->{$_}})) {
		defined($echashrev2->{$_}->{$gene})?($commge->{$gene}=1):($diffge->{$gene}=1);
	}
	if(keys(%{$echashrev1->{$_}})!=keys(%{$echashrev2->{$_}})||keys(%{$diffge})) {
		foreach my $gene (keys(%{$echashrev2->{$_}})) {
			defined($echashrev1->{$_}->{$gene})||($diffge->{$gene}=-1);
		}
	}
	if(keys(%{$diffge})) {
		my $str="";
		foreach my $gene (keys(%{$commge})) {
			$str.=$gene.", ";
		}
		$str=~s/, $//;
		print("\t".$str);
		$str="";
		my $str1="";
		foreach my $gene (keys(%{$diffge})) {
			$diffge->{$gene}>0?($str.=$gene.", "):($str1.=$gene.", ");
		}
		$str=~s/, $//;
		$str1=~s/, $//;
		print("\t".$str);
		print("\t".$str1);
	}
	else {
		print("\tOK");
		my $str="";
		foreach my $gene (keys(%{$commge})) {
			$str.=$gene.", ";
		}
		$str=~s/, $//;
		print("\t".$str);
	}
	print("\n");
}
