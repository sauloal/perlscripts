
echo EXTRACTING THE CHROMOSSOME SIZES
#cat R265_c_neoformans.fasta | perl -ne 'BEGIN{ my %chroms; my $last; } END{
#	foreach my $chrom (sort keys %chroms)
#	{
#		print $chrom, "\t", $chroms{$chrom}, "\n";
#	}
#}
#if (/^>(\S+)/)
#{
#	$last = $1;
#} else {
##print $last, "\t", length($_), "\n";
#$chroms{$last} += length($_);
#}
#' > R265_c_neoformans.count
#

echo EXTRACTING HETEROGENUOUS POSITIONS
cat s_2_1en2_sorted.pileup* | grep -v "Reads" | gawk '{print $1"\t"$2}' | sort | perl -ne '
my %max;
BEGIN
{
	use strict;
	use warnings;
	my %chroms;

	open FI, "R265_c_neoformans.count";
	while (my $ln = <FI>)
	{
		chomp $ln;
		my @line = split("\t", $ln);
		$max{$line[0]} = $line[1];
		#print "\"", $line[0], "\"\t", $max{$line[0]}, "\n";
	}
	close FI;
}

chomp;
my @line = split("\t", $_);
#print $line[0], " POS ", $line[1], "\n";
$chroms{$line[0]}{$line[1]} = 1;

END
{
	print "MAX    KEYS ", scalar (keys %max),    "\n";
	print "CHROMS KEYS ", scalar (keys %chroms), "\n";
	foreach my $chrom (sort keys %chroms)
	{
		die if ( ! exists $max{$chrom} );
		my $mx = $max{$chrom};
		#print "\"$chrom\"\tMAX\t$mx\n";
        unlink("snpspos.$chrom.tab");
		open EX, ">snpspos.$chrom.tab";
		for (my $p = 0; $p < $mx; $p++)
		{

			if ( exists ${$chroms{$chrom}}{$p} )
			     { print EX "$p\t1\n"; }
			else { print EX "$p\t0\n"; }
		}
		close EX;
	}
}
'

echo EXPORTING IMAGES
for file in snpspos.*.tab
do
rm $file.png 2>/dev/null

PLOT='set title "SNPs distribution - '$file'"
set xlabel "position"
#set xrange [0:$xSize]
set yrange [0:1]
set bars small

set style line 3 lt rgb '"'"'red'"'"'   lw 1

set grid
set palette model RGB
set pointsize 0.005

set terminal png size 1024,768 large font "/usr/share/fonts/default/ghostscript/putr.pfa,12"
set output '"'"''$file'.png'"'"'

plot '"'"''$file''"'"' using 2 smooth frequency notitle ls 3
 #with steps

exit
'


echo "$PLOT" | gnuplot
done



echo DONE
