#!/usr/bin/perl -w
use strict;
#my $firstDataCol = "max";
#my $stSppCol     = 4;
#$stSppCol--; #convert to base 0

my $inFile = $ARGV[0] || die "NO ARGUMENTS GIVEN";
die "INPUT FILE $inFile DOESNT EXISTS" if ( ! -f $inFile );

open FILE, "<$inFile" or die "COULD NOT OPEN INPUT FILE $inFile: $!";
my $lineCount = 0;
my $totalCols = 0;
my @headers;
my %data;
#my $dataCol   = 0;
while (my $line = <FILE>)
{
	chomp $line;
	if ( ! $lineCount++ ) # first line
	{
		@headers   = split("\t", $line);
		$totalCols = @headers;
		for (my $h = 0; $h < $totalCols; $h++)
		{
			$headers[$h] =~ s/\s+/ /g;
			$headers[$h] =~ s/\s+$//g;
			$headers[$h] =~ s/\r//g;
			$headers[$h] =~ s/\"//g;
			$headers[$h] = "" if ($headers[$h] eq " ");
			#print "$h => $headers[$h]\n";
		}
	}
	else
	{
		my @values = split("\t", $line);
		#$totalCols = @values;
		die "FIELD HAS WRONG NUMBER OF COLUMNS: ", scalar(@values), " - $totalCols EXPECTED\n$line\n\n" if (@values != $totalCols);
		for (my $h = 0; $h < $totalCols; $h++)
		{
			$values[$h] =~ s/\,/\./g;
			$values[$h] =~ s/\r//g;
			$values[$h] =~ s/\"//g;
			$values[$h] = "" if ($values[$h] eq " ");
			#print "$values[0] :: $h ";
			#print "$headers[$h] => ";
			#print "$values[$h]\n";
		}

		$data{$values[0]} = \@values;
	}
}

close FILE;
my $totalHeaders = @headers;


open FILE, ">$inFile.xml" or die "COULD NOT OPEN $inFile.xml: $!";
print FILE '<?xml version="1.0" encoding="ISO-8859-1"?>' . "\n";
print FILE "<probes id=\"$inFile\">\n";
foreach my $key (sort keys %data)
{
	my $array = $data{$key};
	print FILE "\t<probe id=\"$key\">\n";
	for (my $info = 1; $info < $totalHeaders; $info++)
	{
		my $header = $headers[$info];
		my $value  = $array->[$info];
		next if (( ! defined $header ) || ( $header eq "") );
		next if (( ! defined $value  ) || ( $value  eq "") );
		print FILE "\t\t<$header>$value</$header>\n"
	}
	print FILE "\t</probe>\n";
}
print FILE "</probes>\n";
close FILE;

1;
