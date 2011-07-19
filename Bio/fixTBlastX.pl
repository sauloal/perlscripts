#!/usr/bin/perl -w
use strict;
use warnings;
# after receiving a fasta file as input, fix the length to be a multiple of 3
# otherwise blastx fails

if ( ! $ARGV[0] ) { print "PLEASE DEFINE THE FILENAME\n"; exit 1; };

my $inputFA = $ARGV[0];

my $on   = 0;
my $chromo;
my $total;
my $current;

if ( ! -f $inputFA ) { die "FILE $inputFA DOESNT EXISTS: $!"; };

open INFILE,  "<$inputFA"      or die "COULD NOT OPEN $inputFA: $!";
open OUTFILE, ">$inputFA.FIXN" or die "COULD NOT OPEN $inputFA.FIXN: $!";
my $pos = 1;

while (<INFILE>)
{
	chomp;

	if (/^>(.*)/)
	{
		if (($pos > 1) && ($pos % 3))
		{
			while ($pos % 3) { print OUTFILE "N"; $pos++; };
			print OUTFILE "\n\n";
		}
		elsif ($pos > 1)
		{
			print OUTFILE "\n\n";
		}

		$on     = 1;
		$pos    = 0;
		$chromo = $1;
		$chromo =~ s/ /\_/g;
		$chromo =~ m/[\_|\|]/g;
		my $position = pos ($chromo) ? (pos ($chromo)-1) : length $chromo;
		my $chromoStart = substr($chromo,0,$position);
		print OUTFILE ">$chromoStart $chromo\n";
	}

	if (($on) && ($_) && ( ! /^>(.*)/))
	{
		print OUTFILE "\n" if ($pos > 1);

		foreach my $nuc (split("",$_))
		{
			print OUTFILE $nuc;
			$pos++;
		}
	}
}
close INFILE;
close OUTFILE;
