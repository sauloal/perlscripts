#!/usr/bin/perl -w
use strict;

#TODO: EXPORT TAB TO VIRTUAL PCR
#"FORWARD"	"REVERSE"	"NAME"
#"GTGCATTCCGTAAACGTCATGTAGACG"	"ATGAAGTGGGGGAAGATGATGAAGGT"	"15_234250_237070_G010_235476_235599_P01"
my $printRc = 1; # print reverse complement instead of reverse sequence
use FindBin qw($Bin);
use lib "$Bin";
use fasta;

my $inFile   = $ARGV[0];
die if ! defined $inFile;
die if ! -f $inFile;
die if ! -s $inFile;
die if $inFile !~ /\.html$/;
my $outFolder = (( defined $ARGV[1] ) && ( -d $ARGV[1] )) ? $ARGV[1] : './';
my $fastaArg = $ARGV[2];
my $chromArg = $ARGV[3];

if ( defined $fastaArg )
{
	die if ! -f $fastaArg;
	die if ! -s $fastaArg;
	die if ! defined $chromArg;
}





my %nfo;

&loadHtmlFile($inFile, \%nfo);

my $fastaHtml = $nfo{INPUT};
my $chromHtml = $nfo{CHROM};

#DATA RETRIEVED :: INPUT => /home/saulo/Desktop/blast/Ferry_Genome/Top17None01/clustal/Top17None01.GENES.csv.out.tab_blast_merged_blast_all_gene.xml.tab.fasta.R265_c_neoformans.fasta_supercontig_1.15_of_Cry...ating_protein_(2402_nt)_236889_234488_0.0_FLANK.fasta.clustal.fasta
#DATA RETRIEVED :: CHROM => Cryptococcus_gattii_CBS7750_DN_001_supercontig_1.15_of_Cryptococcus_neoformans_Serotype_B_CBS7750_SOAP_DE_NOVO_4276_233489_237888_233489_237888
#DATA RETRIEVED :: CHROMNAME => Cryptococcus_gattii_CBS7750_DN_001_supercontig_1.15_of_Cryptococcus_neoformans_Serotype_B_CBS7750_SOAP_DE_NOVO_4276_233489_237888_233489_237888_0988_3111_G00
#DATA RETRIEVED :: FRAGMENT => ACTCTGTGCCATTATAACAAAGCACTCCCACTCGTTCCTTCTTCCACCAGCCCCTTCCATTCTACCCTCCATCCATCCATCTTCTCTCTCACTTTCTTTTGACTCAACACCTTTTTGATCCACTGCATAAACACGTCTTCGTCCTCGGGGACAAAGTAGGAAGATAACAGGGAAAGGATTGATTCAAAAGATGCATTTGGTGCGGCAAGAAGGTCTTATTCAGGTCATCAAGTCAGCCACGGGGCTAGAGAGAAAA
#DATA RETRIEVED :: FRAGMENTLENGTH => 2123
#DATA RETRIEVED :: GAPEND => 2111
#DATA RETRIEVED :: GAPNUMBEREND => 0
#DATA RETRIEVED :: GAPNUMBERSTART => 0
#DATA RETRIEVED :: GAPSTART => 1988
#DATA RETRIEVED :: NAME => 0988_3111_G00
#DATA RETRIEVED :: PROBEEND => 3111
#DATA RETRIEVED :: PROBESTART => 988


my $chrom;
my $fastaFile;
if    ( defined $fastaArg  ) { $chrom = $chromArg; $fastaFile = $fastaArg }
elsif ( defined $fastaHtml )
{
	die if ! -f $fastaHtml;
	die if ! -s $fastaHtml;
	die if ! defined $chromHtml;
	$chrom     = $chromHtml;
	$fastaFile = $fastaHtml;
}
else {
	die "NO CHROMOSSOME DEFINED EITHER AS ARGUMENT OR INSIDE FASTA SRC TAG";
}

my $fasta     = fasta->new($fastaFile);
my $stats     = $fasta->getStat();


if ( exists $stats->{$chrom} )
{
	print "ANALYZING CHROMOSSOME $chrom\n";
	my $size    = $stats->{$chrom}{size};
	my $gene    = $fasta->readFasta($chrom);
	my $genLeng = scalar @$gene;
	print "  CHROMOSSOME $chrom SIZE $size LENGTH $genLeng\n";
	my $seq = join('', @$gene);

	my $probes = $nfo{primerPairs};
	if (( defined $probes ) && ( @$probes ))
	{
		#$hash->{primerPairs}[$primerPair]{$title}{sequence} = $sequence;
		my $seqPrinted = 0;
		my $fastaOut = substr($fastaFile, rindex($fastaFile, "/")+1);
		open OUTF, ">$outFolder/$fastaOut.chrom.aln.fasta" or die "$!: $outFolder/$fastaOut.chrom.aln.fasta";
		open OUTP, ">$outFolder/$fastaOut.chrom.aln.txt"   or die "$!: $outFolder/$fastaOut.chrom.aln.txt";
		open OUTT, ">$outFolder/$fastaOut.chrom.aln.tab"   or die "$!: $outFolder/$fastaOut.chrom.aln.tab";
		open OUTX, ">$outFolder/$fastaOut.chrom.aln.xml"   or die "$!: $outFolder/$fastaOut.chrom.aln.xml";



		for ( my $p = 0; $p < @$probes; $p++ )
		{
			my $pairs = $probes->[$p];
			next if ! defined $pairs;
			my $fwd   = $pairs->{'Forward primer'};
			my $rev   = $pairs->{'Reverse primer'};
			my $len   = $pairs->{'Product length'};

			my $fwd_sequence = $fwd->{sequence};
			my $fwd_strand   = $fwd->{strand};
			my $fwd_length   = $fwd->{length};
			my $fwd_start    = $fwd->{start};
			my $fwd_stop     = $fwd->{stop};
			my $fwd_tm       = $fwd->{tm};
			my $fwd_gc       = $fwd->{gc};

			my $rev_sequence = $rev->{sequence};
			my $rev_strand   = $rev->{strand};
			my $rev_length   = $rev->{length};
			my $rev_start    = $rev->{start};
			my $rev_stop     = $rev->{stop};
			my $rev_tm       = $rev->{tm};
			my $rev_gc       = $rev->{gc};

			my $len_len      = $len->{length};

			my $pairDesc     = sprintf("PAIR %02d START %05d END %05d LENGHT %05d - %25s %25s", $p, $fwd_start, $rev_start, $len_len, $fwd_sequence, $rev_sequence);
			print '    ', $pairDesc, "\n";
			my $pairDescLen  = length($pairDesc);
			my $probeStart   = exists $nfo{PROBESTART} ? $nfo{PROBESTART} : 0;
			my $space        = $rev_stop - $fwd_start - $fwd_length;

			if ( ! $seqPrinted++ )
			{
				my $seqf = $seq . "\n";
				   $seqf =~ s/(.{60})/$1\n/g;
				   $seqf = ">$chrom\n" . $seqf;
				$pairs->{'Sequence Fasta'} = $seq;
				print OUTF $seqf;
				my $title = substr($chrom, 0, $pairDescLen);
				print OUTP $title , " - " , $seq , "\n";
			}

			#print "SPACE $space\n";
			my $pairDescF = $pairDesc;
			my $pairDescT = $chrom . '_' . $pairDesc;
			$pairDescT =~ s/\s+/\_/g;
			$pairDescT =~ s/\_+/\_/g;

			#DATA RETRIEVED :: PROBESTART => 988

			my $outSeq    = "-"x(($fwd_start-1)+$probeStart) . $fwd_sequence . "-"x($space) . ( $printRc ? &rc($rev_sequence) : $rev_sequence) . "-"x($genLeng - $rev_start - $probeStart);
			$pairs->{'Sequence Spaced'} = $outSeq;
			my $outSeqF   = $outSeq;
			   $outSeqF   =~ s/(.{60})/$1\n/g;
			print OUTF ">", $pairDescF, "\n";
			print OUTF $outSeqF . "\n";
			print OUTP $pairDesc , " - " , $outSeq, "\n";
			#"FORWARD"	"REVERSE"	"NAME"
			#"GTGCATTCCGTAAACGTCATGTAGACG"	"ATGAAGTGGGGGAAGATGATGAAGGT"	"15_234250_237070_G010_235476_235599_P01"
			print OUTT $fwd_sequence , "\t", $rev_sequence, "\t", $pairDescT, "\n";

		}


		my $xml = &printXml(\%nfo);
		print OUTX $xml;

		close OUTF;
		close OUTP;
		close OUTT;
		close OUTX;
	} else {
		print "CHROM $chrom HAS NO PRIMER PAIRS\n";
	}
} else {
	print "CHROM $chrom DOESNT EXISTS ON $fastaFile\n";
}
#&printRef(\%nfo);




#foreach my $chrom (sort keys %$stats)
#{
#	my $size = $stats->{$chrom}{size};
#	my $gene = $fasta->readFasta($chrom);
#	my $genLeng = scalar @$gene;
#	print "CHROMOSSOME $chrom SIZE $size LENGTH $genLeng\n";
#	my $seq = join('', @$gene);
#}

sub printXml
{
	my $ref = $_[0];
	my $tab = defined $_[1] ? $_[1] : 1;
	my $str;
	if ( ! defined $_[1] )
	{
		$str .= "<?xml version='1.0' encoding='UTF-8'?>\n";
		$str .= "<primers>\n";
	}

	if ( defined $ref )
	{
		#print ref $ref, " [$ref]\n";
		if ( (ref $ref) eq "HASH" )
		{
			foreach my $key (sort keys %$ref)
			{
				my $valueH = $ref->{$key};
				next if ! defined $valueH;
				my $lKey  = $key;
				$lKey =~ s/ /\_/g;
				$str .= "  "x$tab . "<" . $lKey . ">";
				if ((defined $valueH ) && (( ref $valueH eq 'HASH') || ( ref $valueH eq 'ARRAY'))) { $str .= "\n" };
				$str .= " " . &printXml($valueH, $tab+1) . " ";
				if ((defined $valueH ) && (( ref $valueH eq 'HASH') || ( ref $valueH eq 'ARRAY'))) { $str .= "  "x$tab };
				$str .= "</" . $lKey . ">\n";
			}
		}
		elsif ( (ref $ref) eq "ARRAY" )
		{
			for ( my $r = 0; $r < @$ref; $r++ )
			{
				my $valueA = ${$ref}[$r];
				next if ! defined $valueA;
				$str .= "  "x$tab . "<el id=\"" . $r . "\"> ";
				if ((defined $valueA ) && (( ref $valueA eq 'HASH') || ( ref $valueA eq 'ARRAY'))) { $str .= "\n" };
				$str .= " " . &printXml($valueA, $tab+1) . " ";
				if ((defined $valueA ) && (( ref $valueA eq 'HASH') || ( ref $valueA eq 'ARRAY'))) { $str .= "  "x$tab };
				$str .=  "</el>\n";
			}
		}
		else
		{
			$str .= $ref;
		}
	} else {
		$str .= "'undef'";
	}

	if ( ! defined $_[1] )
	{
		$str .= "</primers>\n";
	}
	return $str;
}



sub printRef
{
	my $ref = $_[0];
	my $tab = defined $_[1] ? $_[1] : 0;

	if ( defined $ref )
	{
		#print ref $ref, " [$ref]\n";
		if ( (ref $ref) eq "HASH" )
		{
			foreach my $key (sort keys %$ref)
			{
				my $valueH = $ref->{$key};
				next if ! defined $valueH;
				print "  "x$tab, $key, "\n";
				&printRef($valueH, $tab+1);
			}
		}
		elsif ( (ref $ref) eq "ARRAY" )
		{
			for ( my $r = 0; $r < @$ref; $r++ )
			{
				my $valueA = ${$ref}[$r];
				next if ! defined $valueA;
				print "  "x$tab, $r, "\n";
				&printRef($valueA, $tab+1);
			}
		}
		else
		{
			print "  "x$tab, $ref, "\n";
		}
	} else {
		print "  "x$tab, "'undef'\n";
	}
	return;
}

sub loadHtmlFile
{
	my $file = $_[0];
	my $hash = $_[1];

	my $tr  = '<tr>';
	my $th  = '<th>';
	my $td  = '<td>';
	my $trt = '</tr>';
	my $tht = '</th>';
	my $tdt = '</td>';

	open FILE, "<$file" or die "$!";
	my $lastLine = '';
	while ( my $line = <FILE> )
	{
		#print $line;
		if ( $line =~ /\<src\>(.+)\<\/src\>/ )
		{
			chomp $line;
			my $src = $1;
			die if ! defined $src;

			my @cells = split(/\:\;\:/, $src);
			foreach my $cell ( @cells )
			{
				my ($k,$v) = split(/:/, $cell);
				$hash->{$k}   = $v;
				print "  DATA RETRIEVED :: $k => ", substr($v, 0, 256), "\n";
			}

			$hash->{src}   = $src;
		}
		elsif ( ( $line =~ /\<div class\=\"prPairInfo\"\>/ ) || ( $lastLine =~ /\<div class\=\"prPairInfo\"\>/ ) )
		{
			#print "    DIV $line | $lastLine\n";
			my $primerPair;
			while ( my $dLine = <FILE> )
			{
				#print $dLine;
				if ( $dLine =~ /\<\/div\>/ )
				{
					#print "    DIV END $dLine\n";
					$lastLine = $dLine;
					last;
				}

				if (( $dLine =~ /\<h2\>.+(\d+)\<\/h2\>/ ) || ( $line =~ /\<h2\>.+(\d+)\<\/h2\>/ ))
				{
					$primerPair = $1;
					#print "  PRIMER PAIR $primerPair\n";
				}

				if ( $dLine =~ /<table>/ )
				{
					#print "      TABLE $dLine\n";
					die if ( ! defined $primerPair );

					while ( my $tLine = <FILE> )
					{
						if ( $tLine =~ /\<\/table\>/ )
						{
							#print "      TABLE END $tLine\n";
							$lastLine = $tLine;
							last;
						}
						#print $tLine;
						if ( $tLine =~ /Forward|Reverse/ )
						{
							#                     title       sequence     strand        length      start       stop        tm           GC
							if ( $tLine =~ /$tr$th(.+?)$tht$td(\S+?)$tdt$td(\S+?)$tdt$td(\S+?)$tdt$td(\d+)$tdt$td(\d+)$tdt$td(\S+?)$tdt$td(\S+?)$tdt$trt/ )
							{
								my $title    = defined $1 ? $1 : die;
								my $sequence = defined $2 ? $2 : die;
								my $strand   = defined $3 ? $3 : die;
								my $length   = defined $4 ? $4 : die;
								my $start    = defined $5 ? $5 : die;
								my $stop     = defined $6 ? $6 : die;
								my $tm       = defined $7 ? $7 : die;
								my $gc       = defined $8 ? $8 : die;
								printf "    INFO :: TITLE %s SEQUENCE %-25s STRAND %-6s LENGTH %4d START %4d STOP %4d TM %s GC %s\n", $title, $sequence, $strand, $length, $start, $stop, $tm, $gc;
								$hash->{primerPairs}[$primerPair]{$title}{sequence} = $sequence;
								$hash->{primerPairs}[$primerPair]{$title}{strand}   = $strand;
								$hash->{primerPairs}[$primerPair]{$title}{length}   = $length;
								$hash->{primerPairs}[$primerPair]{$title}{start}    = $start;
								$hash->{primerPairs}[$primerPair]{$title}{stop}     = $stop;
								$hash->{primerPairs}[$primerPair]{$title}{tm}       = $tm;
								$hash->{primerPairs}[$primerPair]{$title}{gc}       = $gc;
							} else {
								die "INVALID INPUT: $tLine\n";
							}
						}
						elsif ( $tLine =~ /Product/ )
						{
							if ( $tLine =~ /$tr$th(.+?)$tht\<td.+?\>(\d+?)$tdt$trt/ )
							{
								my $title    = defined $1 ? $1 : die;
								my $length   = defined $2 ? $2 : die;
								#printf "    INFO :: TITLE %s LENGTH %4d\n", $title, $length;
								$hash->{primerPairs}[$primerPair]{$title}{length} = $length;
							} else {
								die "INVALID INPUT: $tLine\n";
							}
						}
					}
				}
			}
		}
	}
	#SRC: <src>Top17None02.GENES.csv.out.tab_blast_merged_blast_all_gene.xml.tab.fasta.R265_c_neoformans.fasta_supercontig_1.08_of_Cry...rotein_kinase_(4079_nt)_630100_634178_0.0_FLANK.fasta.clustal.fasta.consensus.fasta:;:Top17None02.GENES.R265_c_neo.fasta_scontig_1.08_of_Cry...rotein_kinase_(4079_nt)_630100_634178_0.0_FLANK.clustal_consensus_99.95</src><br/>

	#<div class="prPairInfo">
	#	<h2>Primer pair 1</h2>
	#	<table>
	#			<tr><th></th><th>Sequence (5'->3')</th><th>Strand on template</th><th>Length</th><th>Start</th><th>Stop</th><th>Tm</th><th>GC%</th></tr>
	#		<tr><th>Forward primer</th><td>AAACCTCCCTTCAGAGGCGCAAC</td><td>Plus</td><td>23</td><td>3441</td><td>3463</td><td>59.38</td><td>56.52%</td></tr>
	#
	#		<tr><th>Reverse primer</th><td>GCACTCCCACTTCCACCAGTTCC</td><td>Minus</td><td>23</td><td>4211</td><td>4189</td><td>59.38</td><td>60.87%</td></tr>
	#		<tr><th>Product length</th><td colspan="6">771</td></tr>
	#	</table>
	#</div>

	#if (( length $chrom > 150 ) && ( $shortName ))
	#{
	#	$chrom =~ s/csv\.out\.tab_blast_merged_blast_all_gene\.xml\.tab\.fasta\.//g;
	#	$chrom =~ s/neoformans/neo/g;
	#	$chrom =~ s/fasta\.clustal\.fasta_consensus/clustal_consensus/g;
	#	$chrom =~ s/supercontig/scontig/g;
	#}
}

sub rc
{
	my $seq = $_[0];
	$seq =~ tr/ACGT/TGCA/;
	$seq = reverse $seq;
	return $seq;
}

1;
