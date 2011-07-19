#!/usr/bin/perl -w
# READS A LIST OF NAMES ON FILE 1
# EXTRACT THE SEQUENCES FROM FILE 2

use strict;

die if  (@ARGV < 2);

my $in1 = $ARGV[0];
my $in2 = $ARGV[1];
my $out = $in1 . "out.fasta";

open F1, "<$in1" or die "$!";
my %keys;

while (my $line = <F1>)
{
	chomp $line;
	if (index($line, ">") != -1)
	{
		if ($line =~ /^\>(\S+)/)
		{
			$keys{$1}[0] = $line;
			print "\tADDING KEY $1 (",(scalar keys %keys),")\n";
		}
	}
}
close F1;


open F2, "<$in2" or die "$!";
my $currentKey = "";
my $countKeys  = 0;
while (my $line = <F2>)
{
	chomp $line;

	if (index($line, ">") != -1)
	{
		if ($line =~ /^\>(\S+)/)
		{
			$currentKey = $1;
			$countKeys++;
			print "\tCURRENT KEY (#$countKeys): $1\n";
			next;
		} else {
			die "WRONG LINE: $line\n";
		}
	}
	else
	{
		if (exists $keys{$currentKey})
		{
			$keys{$currentKey}[1] .= $line;
		}
	}
}
close F2;

open OUT, ">$out" or die "$!";
foreach my $key (sort keys %keys)
{
	my $header = $keys{$key}[0];
	my $body   = $keys{$key}[1];
	if ((defined $header) && (defined $body))
	{
		print OUT $header, "\n", $body, "\n";
	}
	else
	{
		if ( ! defined $header)
		{
			print STDERR "NO HEADER FOR KEY \"$key\"\n"                        ;
		}
		elsif ( ! defined $body  )
		{
			print STDERR "NO BODY   FOR KEY \"$key\" AND HEADER \"$header\"\n";
		}
	}
}
close OUT;
