#!/usr/bin/perl -w
use strict;

my $reConvert       = 1;
my $reExportErrors  = 1;
my %export = (
	split   => 1,
	invert  => 1,
	dup     => 0,
	gap     => 0,
	mis     => 0,
	perfect => 1,
);

my $gapLetter       = "-";
my $dubiousLetter   = "N";
#reset; ./DeNovoLastmaf2assembly.pl denovo/r265_vs_denovo.maf.sort.maf.nopar.maf CBS7750_SOAP_DE_NOVO

my $inMafFile = $ARGV[0];
my $epitope   = defined $ARGV[1] ? $ARGV[1] : 'DeNovo';
die "NO MAF FILE GIVEN"                 if ! defined $inMafFile;
die "MAF FILE $inMafFile DOESNT EXISTS" if ! -f $inMafFile;
my $ouFasFile = "$inMafFile.fasta";
my $ouLogFile = "$inMafFile.log";
my $outFolder = substr($inMafFile, 0, rindex($inMafFile, "/"));
print "IN MAF FILE: $inMafFile\n";
print "OUT LOG    : $ouLogFile\n";
print "OUT FOLDER : $outFolder\n\n";

my %data;
my %chroms;
my %size;
my %qryErrors;
open LOG, ">$ouLogFile" or die "COULD NOT OPEN LOG FILE $ouLogFile: $!";
open IN, "<$inMafFile" or die "COULD NOT OPEN MAF FILE $inMafFile: $!";


my $dataCount = 0;
my %skipped;
while (my $line = <IN>)
{
	chomp $line;
	$dataCount++;
	#print "LINE '$line'\n";
	next if (( ! defined $line ) || ( $line eq "" ));

	my $scoreLine = $line;
	my $refLine   = <IN>;
	my $qryLine   = <IN>;

	chomp $scoreLine;
	chomp $refLine;
	chomp $qryLine;

	#print "  $dataCount SCORE LINE    : ", substr($scoreLine, 0 , 150), "\n";
	#print "  $dataCount REFERENCE LINE: ", substr($refLine,   0 , 150), "\n";
	#print "  $dataCount QUERY LINE    : ", substr($qryLine,   0 , 150), "\n";
	#print "\n";

	die "REFERENCE LINE NOT DEFINED. SCORE LINE $line" if (( ! defined $refLine ) || ( $refLine eq "" ));
	die "QUERY LINE NOT DEFINED. SCORE LINE $line"     if (( ! defined $qryLine ) || ( $refLine eq "" ));

	my $score;
	#a score=18039
	if ( $scoreLine =~ /^a score\=(\d+)/)
	{
		$score = $1;
	} else {
		die "WRONG SCORE LINE FORMAT: \"$scoreLine\"";
	}

	my ( $refChrom, $refStart, $refLength, $refEnd, $refFrame, $refLengthTotal, $refSeq ) = &parseDataLine(\$refLine);
	my ( $qryChrom, $qryStart, $qryLength, $qryEnd, $qryFrame, $qryLengthTotal, $qrySeq ) = &parseDataLine(\$qryLine);

	$chroms{ref}{$refChrom}[$refStart]{name} = $qryChrom;
	$chroms{qry}{$qryChrom}[$qryStart]{name} = $refChrom;

	my @lines = (\$scoreLine, \$refLine, \$qryLine);
	push(@{$chroms{ref}{$refChrom}[$refStart]{lines}}, \@lines);
	push(@{$chroms{qry}{$qryChrom}[$qryStart]{lines}}, \@lines);
	$size{$refChrom} = $refLengthTotal;
	$size{$qryChrom} = $qryLengthTotal;

	if ( length($refSeq) != length($qrySeq) ) { die "SIZES DONT MATCH :: REF $refSeq QRY $qrySeq\n" };

	if ( ! exists $data{$refChrom} )
	{
		$data{$refChrom} = {};
		printLog("PARSING CHROMOSSOME $refChrom");
	}
	my $lData = $data{$refChrom};
	   $lData->{length} = $refLengthTotal;

	push(@{$lData->{scores}},  $score    );
	push(@{$lData->{lengths}}, $refLength);

	if (( exists $lData->{length} ) && ( $lData->{length} != $refLengthTotal ))
	{
		die "LENGTH DOESNT MATCH FOR CHROMOSSOME $refChrom: ", $lData->{length} ," vs ", $refLengthTotal, "\n";
	}

	if ( ! exists $lData->{seqRef} ) { $lData->{seqRef} = []; $lData->{seqRef}[$refLengthTotal] = undef; };
	if ( ! exists $lData->{seqNov} ) { $lData->{seqNov} = []; $lData->{seqNov}[$refLengthTotal] = undef; };
	my $seqRef = $lData->{seqRef};
	my $seqNov = $lData->{seqNov};

	for ( my $pos = 0; $pos < length($refSeq); $pos++ )
	{
		my $relPos = $refStart + $pos;
		$seqRef->[$relPos] .= substr($refSeq, $pos, 1);
		$seqNov->[$relPos] .= substr($qrySeq, $pos, 1);
	}
}
close IN;



foreach my $src ( keys %chroms )
{
	if (( -d "$outFolder/$src" ) && ( $reConvert ))
	{
		`rm -rf "$outFolder/$src"`;
	}

	mkdir("$outFolder/$src");
	unlink("$outFolder/index_$src.html") if ( -f "$outFolder/index_$src.html" );
	open HTML, ">$outFolder/index_$src.html" or die "COULD NOT OPEN $outFolder/index_$src.html: $!";
	print HTML
"<!DOCTYPE html>
<html>
	<body>
		<style type=\"text/css\">
			td  {
				vertical-align: top;
				width: 50%;
			}

			table {
				width: 100%
			}

			.break {
				page-break-before: auto;
			}
		</style>
		<table>
			<thead>
				<tr class=\"header\">
					<th colspan=\"2\">$src</th>
				</tr>
			<thead>
			<tr class=\"image\">
				<td colspan=\"2\"><hr/></td>
			</tr>
			<tr class=\"image\">\n";

	my $countCols = 0;

	print "SOURCE $src OUTPUTING AT $outFolder\n";
	my $chromSrcs = $chroms{$src};

	foreach my $chromSrc ( sort keys %$chromSrcs )
	{
		print "\tCHROM $chromSrc\n";
		my $bp        = $size{$chromSrc};

		open SRC, ">$outFolder/$src/$chromSrc.maf" or die "COULD NOT OPEN $outFolder/$src/$chromSrc.maf: $!";
		my $chromDess = $chromSrcs->{$chromSrc};

		if ( $src eq 'qry' )
		{
			&getQryCoverage($chromSrc, $chromDess);
		}

		for ( my $d = 0; $d < @$chromDess; $d++ )
		{
			my $chromDes = $chromDess->[$d];
			next if ! defined $chromDes;
			my $name  = $chromDes->{name};
			my $lines = $chromDes->{lines};
			my $sum   = scalar @$lines;
			#print "\t\tPART $name [$sum]\n";
			foreach my $group ( @$lines )
			{
				foreach my $line ( @$group )
				{
					print SRC $$line, "\n";
				}
				print SRC "\n";
			}

		}
		close SRC;

		if (( -f "$outFolder/$src/$chromSrc.maf.tab" ) && ( $reConvert ))
		{
			print `scripts/maf-sort.sh         $outFolder/$src/$chromSrc.maf            $outFolder/$src/$chromSrc.maf.sort.maf`;
			print `scripts/maf-convert.py  tab $outFolder/$src/$chromSrc.maf.sort.maf > $outFolder/$src/$chromSrc.maf.sort.maf.tab`;

		}
		if (( -f "$outFolder/$src/$chromSrc.maf.tab.png" ) && ( $reConvert ))
		{
			print `scripts/last-dotplot.py     $outFolder/$src/$chromSrc.maf.sort.maf.tab $outFolder/$src/$chromSrc.maf.sort.maf.tab.png`;
			print `./tab2chrom.sh $outFolder/$src/$chromSrc.maf.sort.maf.tab`;
		}


		if ( -f "$outFolder/$src/$chromSrc.maf.tab.png" )
		{
			print HTML "				<td>$chromSrc: $bp - <a href=\"$src/$chromSrc.maf.tab.png\" target=\"_blank\"><img src=\"$src/$chromSrc.maf.tab.png\" width=\"650\"/></a></td>\n";
			#
			# valign=\"top\" style=\"width=50%\"
			# width=\"350\" height=\"350\"
		} else {
			print HTML "				<td>$chromSrc: $bp - none</td>\n";
		}

		if ( ++$countCols == 2 )
		{
			print HTML
"			</tr>
			<tr class=\"break\">
				<td colspan=\"2\"><hr/></td>
			</tr>
			<tr class=\"image\">\n";
			$countCols = 0;
		}
	}

	print HTML
"			</tr>
		</table>
	</body>
</html>\n";

	close HTML;
}





my $countBases      = 0;
my $countGaps       = 0;
my $countDups       = 0;
my $countDupsDubius = 0;
my $countDupsSolved = 0;
my $countChroms     = 0;
my $countLengths    = 0;

&exportErrors();
exit;


open OU, ">$ouFasFile" or die "COULD NOT OPEN $ouFasFile: $!";
foreach my $chrom (sort keys %data)
{
	printLog("CHROMOSSOME $chrom");
	$countChroms++;
	my $lData      = $data{$chrom};
	my $length     = $lData->{length};
	my $lengths    = $lData->{lengths};
	my $scores     = $lData->{scores};
	my $seqRef     = $lData->{seqRef};
	my $seqNov     = $lData->{seqNov};
	$countLengths += $length;

	my $sumScore   = &sumArray($scores);
	my $lengthCov  = &sumArray($lengths);
	my $identity   = (int(( $sumScore  / $length ) * 1000)) / 10;
	my $lengthProp = (int(( $lengthCov / $length ) * 1000)) / 10;

	printLog("  LENGTH     = $length
  LENGTH COV = $lengthCov
  LENGTH %   = $lengthProp %
  SCORE      = $sumScore
  IDENTITY   = $identity %
  REF LENGTH = ".(scalar @$seqRef)."
  NOV LENGTH = ".(scalar @$seqNov));
	my $seq;
	for (my $pos = 0; $pos < $length; $pos++)
	{
		if ( ! (( $pos + 1) % 60)) { $seq .= "\n" };

		my $char = $seqRef->[$pos];
		if ( ! defined $char )
		{
			$countGaps++;
			$seq .= $gapLetter;
		} else {
			if ( length $char > 1 )
			{
				$countDups++;
				my %seen;
				map { $seen{$_} = '' } split(//, $char);
				if (( scalar keys %seen ) == 1)
				{
					$countDupsSolved++;
					$seq .= substr($char, 0, 1);
				} else {
					$countDupsDubius++;
					print "DUBIOUS AT POS $pos '$char' || '", join(":", (sort keys %seen)), "'\n";
					$seq .= $dubiousLetter;
				}
			} else {
				$countBases++;
				$seq .= $char;
			}
		}
	}
	print OU ">$chrom\_$epitope\n";
	printLog("EXPORTING >$chrom\_$epitope\n");
	print OU $seq, "\n";

}
close OU;

printLog("SUMMARY:
CHROMS        : " . (sprintf("%8d", $countChroms    )) . "
LENGTH        : " . (sprintf("%8d", $countLengths   )) . "
  BASES       : " . (sprintf("%8d", $countBases     )) . "
  GAPS        : " . (sprintf("%8d", $countGaps      )) . "
  DUPLICATIONS: " . (sprintf("%8d", $countDups      )) . "
    SOLVED    : " . (sprintf("%8d", $countDupsSolved)) . "
    UNSOLVED  : " . (sprintf("%8d", $countDupsDubius)) . "
  TOTAL       : " . (sprintf("%8d", ($countBases+$countGaps+$countDups))) . "
");

close LOG;



sub exportErrors
{
	print "EXPORTING ERRORS\n";
	if ( ! -d "$outFolder/err" )
	{
		mkdir("$outFolder/err");
	}

	if ( $reExportErrors )
	{
		`rm -rf $outFolder/err/*.maf`;
		`rm -rf $outFolder/err/*.list`;
	}

	#push(@{$qryErrors{$qryChrom}{split}},   $qryPosArr);
	#push(@{$qryErrors{$qryChrom}{invert}},  $qryPosArr);
	#push(@{$qryErrors{$qryChrom}{dup}},     $qryPosArr);
	#push(@{$qryErrors{$qryChrom}{gap}},     $qryPosArr);
	#push(@{$qryErrors{$qryChrom}{mis}},     $qryPosArr);
	#push(@{$qryErrors{$qryChrom}{perfect}}, $qryPosArr);
	my %errors;

	foreach my $qryChrom (sort keys %qryErrors)
	{
		print "\tQUERY CONTIG: $qryChrom\n";

		my $problems = $qryErrors{$qryChrom};
		foreach my $problem ( sort keys %$problems )
		{
			$errors{$problem}++;
			print "\t\tPROBLEM: $problem\n";
			open FH, ">>$outFolder/err/$problem.maf" or die "could not open err/$problem.maf: $!";
			my $refs = $problems->{$problem};

			foreach my $chromDess ( @$refs )
			{
				for ( my $d = 0; $d < @$chromDess; $d++ )
				{
					my $chromDes = $chromDess->[$d];
					next if ! defined $chromDes;
					my $name  = $chromDes->{name};
					my $lines = $chromDes->{lines};
					my $sum   = scalar @$lines;
					#print "\t\tPART $name [$sum]\n";
					foreach my $group ( @$lines )
					{
						foreach my $line ( @$group )
						{
							print FH $$line, "\n";
						}
						print FH "\n";
					}
				}
			}
			close FH;
		}
	}

	foreach my $type (sort keys %chroms)
	{
		my $names = $chroms{$type};
		my $count = scalar keys %$names;
		print "\tTYPE " . uc($type) . " == $count\n";
		print join(", ", (sort keys %$names)), "\n";
	}

	foreach my $problem (sort keys %errors)
	{
		my $eCount = $errors{$problem};
		print "\tERROR $problem FOUND $eCount\n";
		#print
		`scripts/maf-convert.py  tab $outFolder/err/$problem.maf   > $outFolder/err/$problem.maf.tab 2>/dev/null` if ( ( ! -f "$outFolder/err/$problem.maf.tab"));
		#print
		`scripts/last-dotplot.py     $outFolder/err/$problem.maf.tab $outFolder/err/$problem.maf.tab.png 2>/dev/null` if ( ( ! -f "$outFolder/err/$problem.maf.tab.png"));
		my $tabCMD = "./tab2chrom.sh $outFolder/err/$problem.maf.tab";
		print $tabCMD, "\n";
		print `$tabCMD`;
	}
}


sub parseDataLine
{
	my $line = $_[0];
	my @resp;
	#s supercontig_1.01_of_Cryptococcus_neoformans_Serotype_B 760 18105 + 1510064 TGGTTGGTGACTGCACCTTCACCAACAAGTTATTAACTGGCATATCCAG

	if ( $$line =~ /^s\s+(\S+)\s+(\d+)\s+(\d+)\s+(\S)\s+(\d+)\s+(\S+)/ )
	{
		#my ( $refChrom, $refStart, $refLength, $refEnd, $refFrame, $refLengthTotal, $refSeq ) = &parseDataLine(\$refLine);
		#     1          2          3           4        5          6                7
		$resp[0] = $1;
		$resp[1] = $2;
		$resp[2] = $3;
		$resp[3] = $2 + $3;
		$resp[4] = $4;
		$resp[5] = $5;
		$resp[6] = $6;
		#print "CHROM $refChrom START $refStart END $refEnd LENGTH $refLength FRAME $refFrame LENGTH TOTAL $refLengthTotal SEQ ", substr($refSeq, 0, 50),"\n";
	} else {
		die "WRONG REFERENCE LINE FORMAT: \"".$$line."\"";
	}

	return @resp;
}


sub getQryCoverage
{
	my $qryChrom  = $_[0];
	my $qryPosArr = $_[1];
	my $size      = $size{$qryChrom};
	print "\t\t\tCHECKING QUERY COVERAGE :: $qryChrom [$size bp]\n";

	#&getQryCoverage($chromSrc, $chromDess);
	#$chroms{qry}{$qryChrom}[$qryStart]{name} = $refChrom;
	#
	#my @lines = (\$scoreLine, \$refLine, \$qryLine);
	#push(@{$chroms{qry}{$qryChrom}[$qryStart]{lines}}, \@lines);

	my %foundDest;
	my @gStarts;

	for ( my $d = 0; $d < @$qryPosArr; $d++ )
	{
		my $chromDes = $qryPosArr->[$d];
		next if ! defined $chromDes;

		my $name  = $chromDes->{name};
		my $lines = $chromDes->{lines};
		my %seenDes;

		my $sum   = scalar @$lines;
		$foundDest{$name}{counts}++;
		$foundDest{$name}{fragms} = $sum;
		#print "\t\t\t\tPART $name POS $d [$sum]\n";

		foreach my $group ( @$lines )
		{
			my $line = $group->[2];
			#print $$line, "\n";
			my ( $qryChrom, $qryStart, $qryLength, $qryEnd, $qryFrame, $qryLengthTotal, $qrySeq ) = &parseDataLine($line);
			push(@{$foundDest{$name}{starts}}, [$qryStart, $qryEnd, $qryLength]);
			push(@gStarts, [$qryStart, $qryEnd, $qryLength]);
			$foundDest{$name}{frames}{$qryFrame}++;
			#print "\n";
		}
	}

	my $dests = ( scalar keys %foundDest );
	if ( $dests > 1 )
	{
		print "\t\t\t\t"   . "*"x10 . "FOUND SPLIT [$dests]" . "*"x10 . "\n";
		print "\t\t\t\t\t" . join(", ", keys %foundDest ) . "\n";
		push(@{$qryErrors{$qryChrom}{split}}, $qryPosArr) if $export{split};
	}

	foreach my $dest ( keys %foundDest )
	{
		print "\t\t\t\tDEST $dest\n";
		#my $counts = $foundDest{$dest}{counts};
		my $frames = $foundDest{$dest}{frames};
		my $fragms = $foundDest{$dest}{fragms};
		my $starts = $foundDest{$dest}{starts};

		my $frameCount = ( scalar keys %$frames );
		if ( $frameCount > 1 )
		{
			print "\t\t\t\t\t" . "*"x10 . "FOUND INVERT [$frameCount]" . "*"x10 . "\n";
			push(@{$qryErrors{$qryChrom}{invert}}, $qryPosArr) if $export{invert};
		}

		if ( $fragms > 1 )
		{
			print "\t\t\t\t\t" . "*"x10 . "FOUND DUPLICATION [$fragms]" . "*"x10 . "\n";
			push(@{$qryErrors{$qryChrom}{dup}}, $qryPosArr) if $export{dup};
		}

		my $gaps = @$starts;
		if ( $gaps > 1 )
		{
			print "\t\t\t\t\t" . "*"x10 . "FOUND GAP [$gaps]" . "*"x10 . "\n";
			push(@{$qryErrors{$qryChrom}{gap}}, $qryPosArr) if $export{gap};
		}

		for ( my $p = 0; $p < @$starts; $p++ )
		{
			last if ( scalar @$starts == 1 );
			my $cPair  = $starts->[$p];
			my $cStart = $cPair->[0];
			my $cEnd   = $cPair->[1];
			my $cLen   = $cPair->[2];

			my $nPair  = $starts->[$p+1];
			last if ( ! defined $nPair );
			my $nStart = $nPair->[0];
			my $nEnd   = $nPair->[1];
			my $nLen   = $nPair->[2];

			if ( $cEnd > $nStart )
			{
				print "\t\t\t\t\t" . "*"x10 . "FOUND MISASSEMBLY [$cEnd $nStart]" . "*"x10 . "\n";
				push(@{$qryErrors{$qryChrom}{mis}}, $qryPosArr) if $export{mis};
				last;
			}

			#print "\t\t\t\t\tSTART $cStart END $cEnd LENGTH $cLen LENG $size\n";
		}
	}

	if ( ! exists $qryErrors{$qryChrom} )
	{
		push(@{$qryErrors{$qryChrom}{perfect}}, $qryPosArr);
	}
}


sub sumArray
{
	my $array = $_[0];
	my $sum = 0;
	foreach my $value (@$array)
	{
		$sum += $value;
	}

	return $sum;
}

sub printLog
{
	print LOG join(" ", @_), "\n";
	print     join(" ", @_), "\n";
}

#a score=18039
#s supercontig_1.01_of_Cryptococcus_neoformans_Serotype_B 760 18105 + 1510064 TGGTTGGTGACTGCACCTTCACCAACAAGTTATTAACTGGCATATCCAG
#s scaffold250                                              0 18099 -   78247 TGGTTGGTGACTGCACCTTCACCAACAAGTTATTAACTGGCATATCCAG



#18039	supercontig_1.01_of_Cryptococcus_neoformans_Serotype_B	760	18105	+	1510064	scaffold250	0	18099	-	78247	13308,0:1,863,2:0,300,1:0,165,1:0,2092,3:0,1370
#2019	supercontig_1.01_of_Cryptococcus_neoformans_Serotype_B	18965	2033	+	1510064	scaffold250	18117	2034	-	78247	2022,0:1,11

1;
