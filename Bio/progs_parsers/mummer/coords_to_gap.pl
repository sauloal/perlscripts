#!/usr/bin/perl -w
use strict;

# tiling to gap
my $skipWrongSupercontig = 1;
my $exportTelomers       = 0;
my $minLength            = 20;

my $file = $ARGV[0];

if ( ! $ARGV[0] )            { die "NO ARGUMENT PASSED. PLEASE SPECIFY TILING FILE" };
if ( ! -f $file )            { die "TILING FILE $file DOESNT EXISTS" };
if ( ! $file =~ /\.coords/ ) { die "$file ISNT A TILING FILE" };

my $filename = $file;
   $filename =~ s/\.coords/\.gap/;

#print "$0 $file > $filename\n";



my %hash;
my %sizes;
open FILE, "<$file" or die "COULD NOT OPEN FILE $file";
while (my $line = <FILE>)
{
	chomp $line;
	$line =~ s/^\s+//;
	#/home/saulo/Desktop/Genome/progs/MUMmer3.22/seqs/c_neo_r265.fasta /home/saulo/Desktop/Genome/progs/MUMmer3.22/seqs/CBS7750_supercontigs.fasta
	#NUCMER
	#
	#    [S1]     [E1]  |     [S2]     [E2]  |  [LEN 1]  [LEN 2]  |  [% IDY]  |  [LEN R]  [LEN Q]  |  [COV R]  [COV Q]  | [TAGS]
	#===============================================================================================================================
	#       1    18865  |        1    18865  |    18865    18865  |   100.00  |  1510064  1447040  |     1.25     1.30  | supercontig_1.01_of_Cryptococcus_neoformans_Serotype_B_R265	supercontig_1.01_cryptococcus_gattii_CBS7750
	if ( $line =~ /^(\d+)\s+(\d+)\s+\|\s+(\d+)\s+(\d+)\s+\|\s+(\d+)\s+(\d+)\s+\|\s+(\S+)\s+\|\s+(\d+)\s+(\d+)\s+\|\s+(\S+)\s+(\S+)\s+\|\s+(\S+)\s+(\S+)/ )
	#                 s1    e1       |   s2     e2        |   len1   len2      |   id%      |   lenr   lenq      |    covr    covq    |    refname queryname
	#                 1     2            3      4             5      6             7             8     9              10      11           12      13
	{
		my $refStart = $1;
		my $refEnd   = $2;
		my $qryStart = $3;
		my $qryEnd   = $4;
		my $refLen   = $5;
		my $qryLen   = $6;
		my $ident    = $7;
		my $refTLen  = $8;
		my $qryTLen  = $9;
		my $refCov   = $10;
		my $qryCov   = $11;
		my $refName  = $12;
		my $qryName  = $13;

		#print $line, "\n", $refStart, "\t", $refEnd, "\t", $qryStart, "\t", $qryEnd, "\n\n";
		$sizes{$refName} = $refTLen;
		$sizes{$qryName} = $qryTLen;

		if ( $skipWrongSupercontig )
		{
			my $refContig;
			my $qryContig;
			if ($refName =~ /supercontig_1\.(\d+)/) { $refContig = $1; };
			if ($qryName =~ /supercontig_1\.(\d+)/) { $qryContig = $1; };
			if ((defined $refContig) && (defined $qryContig) && ($refContig != $qryContig))
			{
				#print "SKIPPING PAIR $refContig $qryContig\n";
				next;
			}
			else
			{
				#print "$refContig $qryContig ALLOWED\n";
			}
		}


		my $id = 0;
		if ((exists $hash{$refName}) && (exists ${$hash{$refName}}{$qryName}))
		{
			$id = @{$hash{$refName}{$qryName}};
		}

		$hash{$refName}{$qryName}[$id][0] = $refStart;
		$hash{$refName}{$qryName}[$id][1] = $refEnd;
		$hash{$refName}{$qryName}[$id][2] = $qryStart;
		$hash{$refName}{$qryName}[$id][3] = $qryEnd;

		#print "REFNAME $refName QUERYNAME $qryName REFSTART $refStart REFEND $refEnd QRYSTART $qryStart QRYEND $qryEnd REFTLEN $refTLen QRYTLEN $qryTLen\n";

	} else {
		#print "ELSE :: $line\n";
	}
}
close FILE;

my %gaps;
my %inserts;
foreach my $refName (sort keys %hash)
{
	my $refSize   = $sizes{$refName};
	foreach my $qryName (sort keys %{$hash{$refName}})
	{
		my $qrySize        = $sizes{$qryName};
		my $positions      = $hash{$refName}{$qryName};
		my $totalPositions = scalar @$positions;
		my $refLastStart   = 0;
		my $refLastEnd     = 0;
		my $qryLastStart   = 0;
		my $qryLastEnd     = 0;

		for (my $p = 0; $p < $totalPositions; $p++)
		{
			my $id       = $positions->[$p];
			my $refStart = $id->[0];
			my $refEnd   = $id->[1];
			my $qryStart = $id->[2];
			my $qryEnd   = $id->[3];

			#    [S1]     [E1]  |     [S2]     [E2]  |  [LEN 1]  [LEN 2]  |  [% IDY]  |  [LEN R]  [LEN Q]  |  [COV R]  [COV Q]  | [TAGS]
			#===============================================================================================================================
			#       1    18865  |        1    18865  |    18865    18865  |   100.00  |  1447040  1510064  |     1.30     1.25  | supercontig_1.01_cryptococcus_gattii_CBS7750	supercontig_1.01_of_Cryptococcus_neoformans_Serotype_B_R265
			#   18866    20898  |    18966    20998  |     2033     2033  |   100.00  |  1447040  1510064  |     0.14     0.13  | supercontig_1.01_cryptococcus_gattii_CBS7750	supercontig_1.01_of_Cryptococcus_neoformans_Serotype_B_R265
			#   20899    23891  |    21114    24106  |     2993     2993  |   100.00  |  1447040  1510064  |     0.21     0.20  | supercontig_1.01_cryptococcus_gattii_CBS7750	supercontig_1.01_of_Cryptococcus_neoformans_Serotype_B_R265

			#REFERENCE GAPS
			#GAP
			#print "P #$p REFSTART $refStart REFEND $refEnd QRYSTART $qryStart QRYEND $qryEnd\n";

			if ($refStart > ($refLastEnd+1))
			{
				my $gapSize = ($refStart-1) - ($refLastEnd+1);

				if ((defined $minLength) && ($gapSize > $minLength))
				{
					push(@{$gaps{$refName}{$qryName}}, [$refLastEnd+1, $refStart-1]);
					#printf "REF GAP :: INS :: REFNAME %s QRYNAME %s LASTEND %07d START %07d END %07d GAPSIZE %07d\n", $refName, $qryName, $refLastEnd, $refStart, $refEnd, $gapSize;
				}

				if (($p == ($totalPositions-1)) && (($refSize-1) > $refEnd) && $exportTelomers)
				{
					my $gapSize = ($refSize-1) - ($refLastEnd+1);
					push(@{$gaps{$refName}{$qryName}}, [$refLastEnd+1, $refSize-1]);
					#printf "REF GAP :: INS [LAST] :: REFNAME %s QRYNAME %s END %07d REFSIZE %07d LASTEND %07d GAPSIZE %07d\n", $refName, $qryName, $refEnd, $refSize, $refLastEnd, $gapSize;
				}
			}


			#QUERY GAPS
			#INS
			if ($qryStart > ($qryLastEnd+1))
			{
				my $gapSize = ($qryStart-1) - ($qryLastEnd+1);

				if ((defined $minLength) && ($gapSize > $minLength))
				{
					push(@{$inserts{$refName}{$qryName}}, [$qryLastEnd+1, $qryStart-1]);
					#printf "QRY GAP :: GAP :: REFNAME %s QRYNAME %s LASTEND %07d START %07d END %07d GAPSIZE %07d\n", $refName, $qryName, $qryLastEnd, $qryStart, $qryEnd, $gapSize;
				}


				if (($p == ($totalPositions-1)) && (($qrySize-1) > $qryEnd) && $exportTelomers)
				{
					my $gapSize = ($qrySize-1) - ($qryEnd+1);
					push(@{$inserts{$refName}{$qryName}}, [$qryEnd+1, $refSize-1]);
					#printf "QRY GAP :: GAP [LAST] :: REFNAME %s QRYNAME %s END %07d QRYSIZE %07d LASTEND %07d GAPSIZE %07d\n", $refName, $qryName, $qryEnd, $qrySize, $qryLastEnd, $gapSize;
				}
			}

			$refLastStart = $refStart;
			$refLastEnd   = $refEnd;
			$qryLastStart = $qryStart;
			$qryLastEnd   = $qryEnd;
		}
	}
}



#print "#"x20, "\nQUERY\n", "#"x20, "\n";
foreach my $refName (sort keys %gaps)
{
	my $qryNames = $gaps{$refName};
	foreach my $qryName (sort keys %$qryNames)
	{
		foreach my $pos (@{$qryNames->{$qryName}})
		{
			my $start  = $pos->[0];
			my $end    = $pos->[1];
			my $length = $end - $start;

#			supercontig_1.16_of_Cryptococcus_neoformans_Serotype_B_R265	560201	561028
#			printf "REFNAME %s QRYNAME %s START %07d END %07d LENGTH %07d\n", $refName, $qryName, $start, $end, $length;
			printf "GAP\t%s\t%s\t%07d\t%07d\t%07d\n",$refName,$qryName,$start,$end, ($end-$start);
		}
	}
}

#print "#"x20, "\nINSERT\n", "#"x20, "\n";
foreach my $refName (sort keys %inserts)
{
	my $qryNames = $inserts{$refName};
	foreach my $qryName (sort keys %$qryNames)
	{
		foreach my $pos (@{$qryNames->{$qryName}})
		{
			my $start  = $pos->[0];
			my $end    = $pos->[1];
			my $length = $end - $start;

#			supercontig_1.16_of_Cryptococcus_neoformans_Serotype_B_R265	560201	561028
#			printf "REFNAME %s QRYNAME %s START %07d END %07d LENGTH %07d\n", $refName, $qryName, $start, $end, $length;
			printf "INS\t%s\t%s\t%07d\t%07d\t%07d\n",$qryName,$refName,$start,$end, ($end-$start);
		}
	}
}

1;
