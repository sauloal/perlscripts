#!/usr/bin/perl -w
use strict;

#reset; ./info2tab.pl cryptococcus_neoformans_serotype_b_1_genome_summary.txt cryptococcus_neoformans_serotype_b_1_transcripts.gtf
my $usage   = "$0 <SUMMARY FILE> <TRANSCRIPT FILE>\n";
my $epitope = "_of_Cryptococcus_neoformans_Serotype_B";
my $summaryEp = "_genome_summary.txt";

if ( ! @ARGV )   { print $usage; exit 1; };
if ( @ARGV < 2 ) { print $usage; exit 1; };
my $summary      = $ARGV[0];
my $transcr      = $ARGV[1];
my $fetchLastPos = 0;

if ( ! -f $summary ) { print $usage; exit 1; };
if ( ! -f $transcr ) { print $usage; exit 1; };

my $outName = $summary;
$outName    =~ s/$summaryEp//;

my ($sFh,    $tFh)     = &openFiles("<", $summary,              $transcr);
my ($oCdsFh, $oExonFh) = &openFiles(">", $outName . "_cds.tab", $outName . "_exon.tab");

while (my $sLine = <$sFh>)
{
	chomp $sLine;
	my @sCols = split(/\t/, $sLine);
	next if ($sCols[3] =~ /[^\d]/);

	my $locus   = $sCols[0];
	my $length  = $sCols[3];
	my $sStart  = $sCols[4];
	my $sEnd    = $sCols[5];
	my $sStrand = $sCols[6];
	my $sName   = $sCols[7];
	my $sChrom  = $sCols[8];
	print "LOCUS $locus LENGTH $length START $sStart END $sEnd STRAND $sStrand NAME $sName CHROMOSSOME $sChrom\n";

	my $nfo = &fetch($tFh, $sCols[0]);
	die "\tNO EXON" if ( ! @$nfo );

	foreach my $info (@$nfo)
	{
		my $chrom = lc($info->[0]);
		$chrom   .= $epitope;
		$chrom =~ s/(\d{1})\.(\d{1})\_/$1\.0$2\_/;

		my $type    = $info->[2];
		my $start   = $info->[3];
		my $end     = $info->[4];
		my $frame   = $info->[6];
		my $outLine = "$chrom\t$frame\t$start\t$end\t$locus\_$start\_$end\t$type\_$locus\_$sName\trna\n";

		if    ( $type eq "exon"        ) { print $oExonFh $outLine; } #print "\t\t$type" . " "x7 . " | ", $outLine; }
		elsif ( $type eq "CDS"         ) { print $oCdsFh  $outLine; } #print "\t\t$type" . " "x8 . " | ", $outLine; }
		elsif ( $type eq "start_codon" ) { }#print "\t\t$type" . " "x0 . " | ", $outLine; }
		elsif ( $type eq "stop_codon"  ) { }#print "\t\t$type" . " "x1 . " | ", $outLine; }
		else                             { die "$type NOT KNOWN\n"; }
	}
}


&closeFiles($sFh, $tFh, $oCdsFh, $oExonFh);



sub fetch
{
	my $fh    = $_[0];
	my $locus = $_[1];
	my @lines;

	seek($fh, $fetchLastPos, 0);
	my $lastLineNum = $fetchLastPos;
	while (my $line = <$fh>)
	{
		chomp $line;
		my @cols = split(/\t/, $line);
		if ($cols[8] =~ /$locus/)
		{
			push(@lines, \@cols);
			$lastLineNum = tell($fh);
		} else {
			$fetchLastPos = $lastLineNum;
			return \@lines;
		}
	}

	#$stat{$chromo}{pos}  = tell(FILE);
	return \@lines;
}

sub openFiles
{
	my $mode = shift;
	for (my $num = 0; $num < @_; $num++)
	{
		my $fn = $_[$num];
		my $fh;
		open ($fh, "$mode$fn") or die "COULD NOT OPEN FILE $fn: $!";
		$_[$num] = $fh;
	}

	return(@_);
}

sub closeFiles
{
	foreach my $fh (@_)
	{
		close $fh;
	}
}
##summary
##0          1      2       3       4       5       6       7                               8           9           10
#LOCUS       SYMBOL SYNOYM	LENGTH	START   STOP    STRAND  NAME                            CHROMOSOME	ANNOTATION	ANNOTATION NAME
#CNBG_0001                  3769     2143    5911   -       conserved hypothetical protein  1
#CNBG_0002                  1898     6686    8583   -       conserved hypothetical protein  1
#CNBG_0003                  2936     8858   11793   -       conserved hypothetical protein  1
#CNBG_0004                  1611    13250   14860   +       conserved hypothetical protein  1

##transcript
##chromossome		source					type		start	end		?	strand
##																				?	annotation
##0                 1                       2           3       4       5   6   7   8
#Supercontig_1.1    CNB1_FINAL_CALLGENES_3  start_codon	5909	5911	.	-	0	gene_id "CNBG_0001"; transcript_id "CNBG_0001T0";
#Supercontig_1.1    CNB1_FINAL_CALLGENES_3  stop_codon	2143	2145	.	-	0	gene_id "CNBG_0001"; transcript_id "CNBG_0001T0";
#Supercontig_1.1    CNB1_FINAL_CALLGENES_3  exon		5907	5911	.	-	.	gene_id "CNBG_0001"; transcript_id "CNBG_0001T0";
#Supercontig_1.1    CNB1_FINAL_CALLGENES_3  CDS			5907	5911	.	-	0	gene_id "CNBG_0001"; transcript_id "CNBG_0001T0";
#Supercontig_1.1    CNB1_FINAL_CALLGENES_3  exon		5713	5838	.	-	.	gene_id "CNBG_0001"; transcript_id "CNBG_0001T0";
#Supercontig_1.1    CNB1_FINAL_CALLGENES_3  CDS			5713	5838	.	-	1	gene_id "CNBG_0001"; transcript_id "CNBG_0001T0";
#Supercontig_1.1    CNB1_FINAL_CALLGENES_3  exon		5562	5653	.	-	.	gene_id "CNBG_0001"; transcript_id "CNBG_0001T0";
#Supercontig_1.1    CNB1_FINAL_CALLGENES_3  exon		2143	2184	.	-	.	gene_id "CNBG_0001"; transcript_id "CNBG_0001T0";
#Supercontig_1.1    CNB1_FINAL_CALLGENES_3	CDS			2146	2184	.	-	0	gene_id "CNBG_0001"; transcript_id "CNBG_0001T0";
#Supercontig_1.1    CNB1_FINAL_CALLGENES_3	start_codon	8546	8548	.	-	0	gene_id "CNBG_0002"; transcript_id "CNBG_0002T0";
#Supercontig_1.1    CNB1_FINAL_CALLGENES_3	stop_codon	6686	6688	.	-	0	gene_id "CNBG_0002"; transcript_id "CNBG_0002T0";
#Supercontig_1.1    CNB1_FINAL_CALLGENES_3	exon		8442	8583	.	-	.	gene_id "CNBG_0002"; transcript_id "CNBG_0002T0";
#Supercontig_1.1    CNB1_FINAL_CALLGENES_3	CDS			8442	8548	.	-	0	gene_id "CNBG_0002"; transcript_id "CNBG_0002T0";
#Supercontig_1.1    CNB1_FINAL_CALLGENES_3	exon		8263	8336	.	-	.	gene_id "CNBG_0002"; transcript_id "CNBG_0002T0";
#Supercontig_1.1    CNB1_FINAL_CALLGENES_3	CDS			8263	8336	.	-	1	gene_id "CNBG_0002"; transcript_id "CNBG_0002T0";

##tab
##chromossome                                           strand  end  unique name                                    name                                                   type
##                                                         start
##0                                                     1  2    3    4                                              5                                                      6
#supercontig_1.25_of_Cryptococcus_neoformans_Serotype_B +  611  667  53437GE_CneoSBc25_30001_34790_s_PSO-60-0314	53437GE_CneoSBc25_30001_34790_s_PSO-60-0314|DIFF:-0.77 rna
