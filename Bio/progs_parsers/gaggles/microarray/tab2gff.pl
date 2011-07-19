#!/usr/bin/perl -w
use strict;

foreach my $file (@ARGV)
{
	if ( ! -f $file )
	{
		print "FILE $file NOT FOUND\n";
		next;
	}

	my $out = $file . ".gff2";

	open IN, "<$file" or die "COULD NOT OPEN FILE $file : $!";
	open OU, ">$out"  or die "COULD NOT OPEN FILE $out : $!";


	while (my $line = <IN>)
	{
		#0                                                     1        2       3       4                5           6
		#sequence                                              strand   start   end     unique name      commom name gene type
		#supercontig_1.01_of_Cryptococcus_neoformans_Serotype_B	+       15400   15400   DEL_15400_15400  del [1]     DEL
		next if (index($line, "#") == 0);
		my @fields = split(/\t/, $line);
		print OU "$fields[0]\t$file\t$fields[6]\t$fields[2]\t$fields[3]\t.\t$fields[1]\t.\t$fields[5]\n";
	}

	close OU;
	close IN;
}


1;
