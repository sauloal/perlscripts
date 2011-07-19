#!/usr/bin/perl -w
use strict;

my $flanking = 1_000;
my $inFile   = $ARGV[0];

if ( ! defined $inFile ) { print "NO INPUT TAB FILE DEFINED\n";            exit 1 };
if ( ! -f      $inFile ) { print "INPUT TAB FILE $inFile DOESNT EXISTS\n"; exit 2 };

open FI, "<$inFile" or die "COULD NOT OPEN TAB FILE $inFile: $!";
open FO, ">$inFile.out.tab" or die "COULD NOT OPEN OUTPUT FILE $inFile.out.tab: $!";

print "*"x120 , "\n";
print "TAB2MAP :: INFILE '$inFile' FLANKING $flanking\n";
#BLAST
# input_blast/blast_r265Genes_vs_r265.blast.tab
#0                                                      1   2       3       4                                                                                                       5                                                                                       6
#supercontig_1.07_of_Cryptococcus_neoformans_Serotype_B	+	887864	888847	CNBG_3241|Cryptococcus_neoformans_Serotype_B_DNAj_protein_(1993_nt)_887864_888847_0.0	                CNBG_3241|Cryptococcus_neoformans_Serotype_B_DNAj_protein_(1993_nt)	                    rna
#supercontig_1.07_of_Cryptococcus_neoformans_Serotype_B	-	891778	890178	CNBG_3242|Cryptococcus_neoformans_Serotype_B_conserved_hypothetical_protein_(1601_nt)_891778_890178_0.0	CNBG_3242|Cryptococcus_neoformans_Serotype_B_conserved_hypothetical_protein_(1601_nt)	rna

#FAVORITE
#supercontig_1.07_of_Cryptococcus_neoformans_Serotype_B	887441	892036	forward	07_[887441, 892036]_10	DELETION
#0                                                      1       2       3       4                       5

foreach my $line (<FI>)
{
	chomp $line;
	my ($chrom, $preStart, $preEnd, $start, $end, $name, $startF, $endF);

	next if ! $line;
	next if $line =~ /^\>/;
	next if $line =~ /^\=\=\>.*\<\=\=/;
	next if $line !~ /\S+\s+\d+\s+\d+/;

	my @cols  = split(/\t/, $line);
#	print $line, "\tCOLS \"", scalar @cols, "\"\n";

	$chrom    = $cols[0];
	if ( $cols[1] =~ /\d/)
	{
		$preStart = $cols[1];
		$preEnd   = $cols[2];
		$start    = $preStart > $preEnd ? $preEnd   : $preStart;
		$end      = $preStart > $preEnd ? $preStart : $preEnd;
	} else {
		$preStart = $cols[2];
		$preEnd   = $cols[3];
		$start    = $preStart > $preEnd ? $preEnd   : $preStart;
		$end      = $preStart > $preEnd ? $preStart : $preEnd;
	}

	$name     = $cols[4];
	$startF   = ($start - $flanking + 1) >= 0 ? ($start - $flanking + 1) : 0;
	$endF     = ($end   + $flanking - 1);

	printf "    START FLANK %7d START %7d END %7d END FLANK %7d :: UL %7d SL %7d DL %7d FL %7d :: %s\n", 
	$startF, $start, $end, $endF, ($start - $startF + 1), ($end - $start + 1), ($endF - $end + 1), ($endF - $startF + 1), $name;

	print FO $chrom, "\t", $start , "\t", $end  , "\t", $name, ""           , "\n";
	print FO $chrom, "\t", $startF, "\t", $endF , "\t", $name, "_FLANK"     , "\n";
#	print FO $chrom, "\t", $startF, "\t", $start, "\t", $name, "_UPSTREAM"  , "\n";
#	print FO $chrom, "\t", $end   , "\t", $endF , "\t", $name, "_DOWNSTREAM", "\n";
}

close FO;
close FI;

1;
