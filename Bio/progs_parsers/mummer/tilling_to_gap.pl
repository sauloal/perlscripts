#!/usr/bin/perl -w
# tiling to gap

my $file = $ARGV[0];

if ( ! $ARGV[0] )            { die "NO ARGUMENT PASSED. PLEASE SPECIFY TILING FILE" };
if ( ! -f $file )            { die "TILING FILE $file DOESNT EXISTS" };
if ( ! $file =~ /\.tiling/ ) { die "$file ISNT A TILING FILE" };

my $filename = $file;
   $filename =~ s/\.tiling/\.gap/;

$minSize = 1;

print "./$0 $file > $filename\n";


# >supercontig_1.25_of_Cryptococcus_neoformans_Serotype_B 34790 bases
# -51	1475	52	1527	95.55	99.66	+	NODE_372_length_1501_cov_19.901400
# 1528	5012	275	3485	100.00	99.91	+	NODE_53_length_3459_cov_20.484821
# 5288	5729	-22	442		100.00	100.00	-	NODE_292_length_416_cov_26.187500
# 5708	5939	73	232		100.00	100.00	-	NODE_1291_length_206_cov_24.742718
# 6013	6410	450	398		100.00	99.50	+	NODE_36_length_372_cov_15.534946
# |		|		|	|		|		|		|	|-> CONTIG ID
# |		|		|	|		|		|		|-----> CONTIG ORIENTATION
# |		|		|	|		|		|-------------> AVERAGE PERCENT IDENTITY OF THIS CONTIG
# |		|		|	|		|---------------------> ALIGNMENT COVERAGE OF THIS CONTIG
# |		|		|	|-----------------------------> LENGTH OF THIS CONTIG
# |		|		|---------------------------------> GAP BETWEEN THIS CONTIG AND THE NEXT
# |		|-----------------------------------------> END IN THE REFERENCE
# |-----------------------------------------------> START IN THE REFERENCE

#>supercontig_1.26_of_Cryptococcus_neoformans_Serotype_B_R265 15500 bases
#610	15500	0	14891	100.00	100.00	+	supercontig_1.26_cryptococcus_gattii_CBS7750

open FILE, "<$file" or die "COULD NOT OPEN TILING FILE $file: $!";
my %hash;
my $current    = "";
my $count      = 0;
my $totalDel   = 0;
my $totalWrong = 0;
while (<FILE>)
{
	chomp;
	print "$_\n";
	if (( ! $_ ) || (/^\>/)) { $current = "" };

	if (($current ne "") && (/(\S+)\s*(\S+)\s+(\S+)/))
#                              start   end    gapSize
	{
		my $start   = $1;
		my $end     = $2;
		my $gapSize = $3;
# 		print "$1 $2 $3\n";
		if (($gapSize > $minSize) && ($start > 0) && ($end > 0))
		{
			$count++;
			$hash{$current}{$count}{"contigStart"} = $start;
			$hash{$current}{$count}{"contigEnd"}   = $end;
			$hash{$current}{$count}{"contigGap"}   = $gapSize;
			$hash{$current}{$count}{"GapStart"}    = $end+1;
			$hash{$current}{$count}{"GapEnd"}      = $end+$gapSize;
			print "CURRENT $current COUNT $count START $start END $end GAP $gapSize GAPSTART ",($end+1)," GAPEND ",($end+$gapSize),"\n";
			$totalDel += $gapSize;
		}
		else
		{
			$totalWrong += $gapSize;
			print "CURRENT $current COUNT $count START $start END $end GAP $3 GAPSTART ",($2+1)," GAPEND ",($2+$3)," - WRONG\n";
		}
	}

	if (/^\>(\S+)\s*(\d+)/)
	{
		$current = $1;
# 		print "CURRENT $current\n";
	}
}
close FILE;

open FILE, ">$filename" or die "COULD NOT SAVE OUTPUT FILE: $filename";
foreach my $contig (sort keys %hash)
{
# 	print "$contig\t";
	foreach my $count (sort {$a <=> $b} keys %{$hash{$contig}})
	{
		my $gapStart = $hash{$contig}{$count}{"GapStart"};
		my $gapEnd   = $hash{$contig}{$count}{"GapEnd"};
		my $gapSize  = $hash{$contig}{$count}{"contigGap"};
		print FILE "$contig\t$gapStart\t$gapEnd\n";
	}
}
close FILE;

print " TOTAL        $count\n";
print " TOTAL    DEL $totalDel\ bp\n";
print " AVG SIZE DEL " . (int(($totalDel/($count||1))*100)/100) . " \ bp\n";
print " TOTAL  WRONG $totalWrong\ bp\n";

1;
