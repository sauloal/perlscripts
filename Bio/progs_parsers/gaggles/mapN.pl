#!/usr/bin/perl -w
use strict;
use fasta;

die "NO INPUT FASTA" if ( ! @ARGV );
my $inFasta    = $ARGV[0];
my $renameFrom = $ARGV[1];
my $renameTo   = $ARGV[2];
#./mapN.pl cbs7750_DE_NOVO_LAST.fasta Serotype_B_CBS7750_SOAP_DE_NOVO Serotype_B

die "INPUT FASTA $inFasta DOESNT EXISTS" if ( ! -f $inFasta );


print "GENERATING CHROMOSSOMES TABLE...\n";
my $fasta  = fasta->new($inFasta);
print "GENERATING CHROMOSSOMES TABLE...done\n";
my $stats = $fasta->getStat();
open FO, ">$inFasta\_NONE.tab" or die "COULD NOT OPEN $inFasta\_NONE.tab: $!";

print "READING CHROMOSSOMES\n";
my $gTotal;
my $gCount;
my $gSize;
foreach my $chrom ( sort keys %$stats )
{
	my $gene    = join('', @{$fasta->readFasta($chrom)});
	my $genLeng = length $gene;
	my $size    = $stats->{$chrom}{size};
	print "\tCHROMOSSOME $chrom SIZE $size\n";
	my $total = 0;
	my $count = 0;

	while ( $gene =~ m/N+/gi)
	{
		$total++;
		$gTotal++;
		my $posEnd   = pos($gene);
		my $match    = $&;
		my $mLeng    = length($match);
		my $posStart = $posEnd - $mLeng;
		my $name     = "NONE_$gTotal\_$posStart\_$posEnd\_$mLeng";
		$count      += $mLeng;
		my $chrom2 = $chrom;
		if (( defined $renameFrom ) && (defined $renameTo ))
		{
			$chrom2 =~ s/$renameFrom/$renameTo/;
		}
		print FO "$chrom2\t+\t$posStart\t$posEnd\t$name\t$name\trna\n";
		#print "FOUND '$match' AT POSITION [$posStart - $posEnd : $mLeng]\n";
		#print "      '", substr($gene, $posStart, $mLeng), "'\n\n";
	}
	print "\t\tTOTAL $total SUMMING $count [",((int(($count/$size)*1000))/10)," %]\n";
	$gCount += $count;
	$gSize  += $size;
}

print "TOTAL $gTotal SUMMING $gCount [",((int(($gCount/$gSize)*1000))/10)," %]\n";


close FO;

1;
