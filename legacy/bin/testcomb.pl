#!/usr/bin/perl -I. -w
use strict;
use warnings;

my $pt=getcomb(6,$ARGV[0]);
print(@{$pt}."\n");
print(@{$pt->[0]}."\n");
for (1..@{$pt}) {
	my $str="";
	for my $i (@{$pt->[$_-1]}) {
		$str.=$i.",";
	}
	chop $str;
	print($str."\n");
}

sub getcomb {
	my $size=shift;
	my $ext=shift;
	my $permtable=[[]];
	getcomb1($permtable,0,$size-$ext,0,$size);
	my $result=[];
	foreach(@{$permtable}) {
		push(@{$result},[]);
		foreach my $e (0..($size-1)) {
			$_->[$e]&&push(@{$result->[@{$result}-1]},$e);
		}
	}
	return $result
}

sub getcomb1 {
	my $permtable=shift;
	my $counter=shift;
	my $max=shift;
	my $pos=shift;
	my $maxlen=shift;
	if($max-$counter<$maxlen-@{$permtable->[$pos]}&&
	$counter<$max) {
		push(@{$permtable},[]);
		foreach(@{$permtable->[$pos]}) {
			push(@{$permtable->[@{$permtable}-1]},$_);
		}
		push(@{$permtable->[@{$permtable}-1]},1);
		getcomb1($permtable,$counter+1,$max,@{$permtable}-1,$maxlen);
		push(@{$permtable->[$pos]},0);
		getcomb1($permtable,$counter,$max,$pos,$maxlen);
	}
	elsif($counter==$max) {
		for(1..($maxlen-@{$permtable->[$pos]})) {
			push(@{$permtable->[$pos]},0)
		}
	}
	else {
		for(1..($maxlen-@{$permtable->[$pos]})) {
			push(@{$permtable->[$pos]},1)
		}
	}
}
