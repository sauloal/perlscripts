#!/usr/bin/perl -w
use strict;

my $file = $ARGV[0];
if ( ! $file    ) { die "FILE NOT DEFINED\n"; };
if ( ! -f $file ) { die "FILE $file DOESNT EXISTS\n"; };

open INFILE,  "<$file"       or die "COULD NOT OPEN IN  FILE $file: $!";
open OUTFILE, ">$file.fasta" or die "COULD NOT OPEN OUT FILE $file: $!";
my $count = 1;

while (my $line = <INFILE>)
{
	chomp $line;
	my $seq;
	my $name;
	if ($line =~ /^([A|C|T|G]+)[;|,]([\w|\.|\-]+)/)
	{
		$seq  = $1;
		$name = $2;
	}
	elsif ($line =~ /^([\w|\.|\-]+)[;|,]([A|C|T|G]+)/)
	{
		$seq  = $2;
		$name = $1;
	}
	elsif ($line =~ /^\"([A|C|T|G]+)\"[;|,]\"([\w|\.|\-]+)\"/)
	{
		$seq  = $1;
		$name = $2;
	}
	elsif ($line =~ /^\"([\w|\.|\-]+)\"[;|,]\"([A|C|T|G]+)\"/)
	{
		$seq  = $2;
		$name = $1;
	}
	elsif ($line =~ /^(\d+)\s+([\w|\.|\-]+)\s+([A|C|T|G]+)/)
	{
		$seq  = $3;
		$name = "$1_$2";
	}
	else
	{
		print "$line\n";
		die "LINE DOESNT COMPLY WITH CSV2FASTA STANDARDS";
	}

	if ( ! ($seq && $name))
	{
		print "$line\n";
		die "LINE DOESNT COMPLY WITH CSV2FASTA STANDARDS";
	}

	print OUTFILE ">$count $name\n$seq\n\n";
	$count++;
}

print "$count SEQUENCES GENERATED\n";

close OUTFILE;
close INFILE;

1;
