#!/usr/bin/perl -I. -w
use strict;
use warnings;

my $set=[0];
my $results=[];
permute($set,[],$results);
print(@{$results}."\n");
print("@{$results->[0]}\n");

sub permute {
    my @items = @{ $_[0] };
    my @perms = @{ $_[1] };
    my $res=$_[2];
    unless (@items) {
        push(@{$res},\@perms);
    } else {
        my(@newitems,@newperms,$i);
        foreach $i (0 .. $#items) {
            @newitems = @items;
            @newperms = @perms;
            unshift(@newperms, splice(@newitems, $i, 1));
            permute([@newitems], [@newperms],$res);
        }
    }
}
