#!/usr/bin/perl -w
use strict;

my $f1 = $ARGV[0];
my $f2 = $ARGV[1];


open F1, "<$f1";
open F2, "<$f2";

my @f1 = split("", <F1>);
my @f2 = split("", <F2>);

my $maxNameL = length $f1  > length $f2 ? length $f1  : length $f2;

my $max      = scalar @f1 > scalar @f2 ? scalar @f1 : scalar @f2;
my $maxL     = length($max);

print "MAX $max\n";
print "$f1 :: ", scalar @f1, "\n";
print "$f2 :: ", scalar @f2, "\n";

while (@f1 > @f2) { push(@f2, "-") };
while (@f2 > @f1) { push(@f1, "-") };

print "$f1 :: ", scalar @f1, "\n";
print "$f2 :: ", scalar @f2, "\n";

for (my $f = 0; $f < $max-1; $f+=60)
{
	my $maxF = $f+60 > $max-1 ? $max-1 : $f+60;

	printf "%".$maxNameL."s %".$maxL."d %-60s %".$maxL."d\n", $f1, $f+1, join("",@f1[$f..$maxF-1]), $maxF;
	printf "%".$maxNameL."s %".$maxL."d %-60s %".$maxL."d\n", $f2, $f+1, join("",@f2[$f..$maxF-1]), $maxF;
	print "\n";
}


close F1;
close F2;

1;
