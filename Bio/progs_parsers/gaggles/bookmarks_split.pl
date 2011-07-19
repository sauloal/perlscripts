#!/usr/bin/perl -w
use strict;
my $inFile = $ARGV[0];
die "NO INPUT FILE" if ! defined $inFile;
die "INPUT FILE $inFile DOESNT EXISTS" if ! -f $inFile;

open IN, "<$inFile" or die "COULD NOT OPEN INPUT FILE $inFile: $!";
my @files = (undef)x10;

for (my $i = 0; $i < @files; $i+=3)
{
	my $fn = sprintf("%s_%02d",$inFile, $i);
	my $fh;
	open($fh, ">$fn") or die "COULD NOT OPEN $fn: $!";
	$files[$i]   = $fh;
	$files[$i+1] = $fh;
	$files[$i+2] = $fh;
}

while (<IN>)
{
	chomp;
	if (/\]_(\d+)/)
	{
		print $1, "\t", $_, "\n";
		my $fh = $files[$1];
		print $fh $_, "\n";
	}
}

close IN;

1;
