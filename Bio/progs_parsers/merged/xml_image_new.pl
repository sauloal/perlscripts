#!/usr/bin/perl -w
use strict;
use fasta;
use mem;
#reset; ./xml_image_new.pl xmlPos/XMLpos_supercontig_1.24_of_Cryptococcus_neoformans_Serotype_B.xml seq.fasta contig.fasta
 #load XML
 #load ref fasta
 #load qry fasta

my $lineSize             = 100; #line size for alignment
my $outDir               = "img";
my $printGeneratingArray = 0;




my %expectedKeys;
my $x    = 'x';
my $dash = '-';
my $dez;
my $one;
my %lanesKeys;
my %lanesValues;
my %lArrayPos;
my %insertNumbers;
my %numbersInsert;
my $maxLineSize   = 0;
my $maxNumberSize = 7;
my %lines;

&setup();

my $inputFile  = $ARGV[0];
my $fastaFile  = $ARGV[1];
my $contigFile = $ARGV[2];

die "NOT ENOUGHT ARGUMENTS"                if @ARGV < 3;
die "NO INPUT FILE"                        if ! defined $inputFile;
die "NO FASTA FILE"                        if ! defined $fastaFile;
die "NO CONTIG FILE"                       if ! defined $contigFile;
die "INPUT FILE DONT EXISTS: $inputFile"   if ! -f      $inputFile;
die "FASTA FILE DONT EXISTS: $fastaFile"   if ! -f      $fastaFile;
die "CONTIG FILE DONT EXISTS: $contigFile" if ! -f      $contigFile;


my $mem       = mem->new();
$mem->add("BEGIN");
my $xmlHash   = &loadXML($inputFile);
$mem->add("XML END");
my $fastaM    = fasta->new($fastaFile);
$mem->add("FASTA END");
my $contigM   = fasta->new($contigFile);
$mem->add("CONTIG END");
my %lanes;

foreach my $chrom (sort keys %$xmlHash)
{
	print "\tCHROM $chrom\n";
	$mem->add("CHROM BEFORE $chrom");
	my $poses              = $xmlHash->{$chrom};
	my $currFastaChrom     = $fastaM->readFasta($chrom);
	my $currFastaChromLen  = scalar @$currFastaChrom;
	my $currContigChrom    = $contigM->readFasta($chrom);
	my $currContigChromLen = scalar @$currContigChrom;
	my $max                = $currContigChromLen > $currFastaChromLen ? $currContigChromLen : $currFastaChromLen;

	my $chromArray         = &generateArray($poses, $chrom, $fastaM, $contigM, $max);
	&applyInsertions($chromArray, $max);
	&exportAlignmentRichSingle($chromArray, $inputFile, $chrom, $max);

	#$lanes{$chrom}         = $chromArray;
	$mem->add("CHROM AFTER  $chrom");
	#last;
}
$mem->add("ARRAY END");
#&exportAlignmentRich(\%lanes, $fastaM, $contigM, $inputFile);

$mem->add("END");
$mem->get();








sub exportAlignmentRich
{
	my $lanesDb   = $_[0];
	my $in        = $_[1];

	foreach my $contig ( sort keys %$lanesDb )
	{
		my $cLanes          = $lanesDb->{$contig};
		&exportAlignmentRichSingle($cLanes, $in, $contig)
	}

}



sub exportAlignmentRichSingle
{
	my $cLanes    = $_[0];
	my $in        = $_[1];
	my $contig    = $_[2];
	my $max       = $_[3];

	my $outA  = "$in.$contig.aln";
	my $outS  = "$in.$contig.short.aln";
	my $outF  = "$in.$contig.flanking.csv";

	print "PRINTING ALIGNMENT: ",uc($contig),"\n";

	open  OUTA, ">$outA" or die "COULD NOT OPEN $outA :$!\n";
	open  OUTS, ">$outS" or die "COULD NOT OPEN $outS :$!\n";
	open  OUTF, ">$outF" or die "COULD NOT OPEN $outF :$!\n";

	print OUTF 	"\"count\",\"chrom\",".
				"\"refStart\",\"refEnd\",\"refSize\","                .
				"\"refSeq\",\"refSeqUpstream\",\"refSeqDownstream\"," .
				"\"qryStart\",\"qryEnd\",\"qrySize\","                .
				"\"qrySeq\",\"qrySeqUpstream\",\"qrySeqDownstream\""  .
				"\n";

	print OUTA "INPUT: $in\n";
	print OUTS "INPUT: $in\n";
	print      "INPUT: $in\n";

	my $format  = "%".$maxLineSize."s : %".$maxNumberSize."d %-s %".$maxNumberSize."d\n";

				#%expectedKeys = (
				#	'microarray' => [\&parseMicro, [['micro', 0]]],
				#	'blast'      => [\&parseBlast, [['gene' , 1]]],
				#	'ndMap'      => [\&parseMap,   [['nd'   , 2],
				#	|				|				['event', 3],
				#	|				|				['snp'  , 4],
				#	|				|				['ins'  , 5],
				#	|				|				['qual' , 6]]]
				#	|				|				  |		  |
				#	|				|				  |		  LANE TO SAVE
				#	|               |                 FIELDS YIELD
				#	|               PARSER OF GROUP
				#	GROUP FROM XML
				#%lines{      micro => '',
				#	          gene  => '' }
				#%lanesKeys { 0     => micro
				#			  1     => gene
				#			  2     => nd
				#			  3     => event }
				#%lanesValue {micro => 0
				#			  gene  => 1
				#			  nd    => 2
				#			  event => 3
				#}

	print OUTA "CONTIG $contig\n";
	print OUTS "CONTIG $contig\n";
	print "\tCONTIG $contig HAS ",scalar @$cLanes," LANES\n";

	#$hash->{$tableName}[$currId][$poses[$tableCount][$currId] - 1]{$key} = $value;

	#for (my $l = 0; $l < @$cLanes; $l++)
	#{
	#	my $lane = $cLanes->[$l];
	#	for (my $p = 0; $p < @$lane; $p++)
	#	{
	#		my $nfo = $lane->[$p];
	#		my $s   = $nfo->[0];
	#		my $e   = $nfo->[1];
	#		my $d   = $nfo->[2];
	#		my $n   = $nfo->[3];
	#		foreach my $k (keys %$n)
	#		{
	#			my $v = $n->{$k};
	#			print "L $l P $p S $s E $e D ",$$d," K $k V $v\n";
	#		}
	#	}
	#}

	for (my $pos = 0; $pos < $max; $pos += $lineSize)
	{
		#print "\t\tPOS $pos\n";
			#$lanes{$chrom}         =
				#$array[$lane][$p] = $value;
					#$value[0][0]   = $start;
					#$value[0][1]   = $end;
					#$value[0][2]   = $desc;
					#$value[0][3]   = $nfo;
			#$lanes{$chrom}[$lane][$pos][0] start
			#$lanes{$chrom}[$lane][$pos][1] end
			#$lanes{$chrom}[$lane][$pos][2] desc
			#$lanes{$chrom}[$lane][$pos][3] nfo
		my $posE = ($pos+$lineSize-1);
		if ( $posE >= $max ) { $posE = $max-1; };

		my %pLanes;
		foreach my $laneNum (sort {$a <=> $b} keys %lanesKeys)
		{
			my $laneName = $lanesKeys{$laneNum};
			my $lane     = $cLanes->[$laneNum];
			next if ! defined $lane;
			my @frags   = @{$lane}[$pos..$posE];
			#print "\t\t\tLANE NAME $laneName NUM $laneNum POS $pos SIZE ",scalar @$lane, " FRAG ", scalar @frags,"\n";
			if ( $laneNum > 1 )
			{
				foreach my $frag (@frags)
				{
						#my $value = $_ ? ${$_->[2]} : '-';
						my $value = $frag ? substr(${$frag->[2]}, 0, 1) : '-';
						$pLanes{$laneName} .= $value;
						#print "\t\t\t\tLANE NAME $laneName NUMBER $laneNum VALUE $value\n";
				}
			} else
			{
				foreach my $frag (@frags)
				{
					my $value = $frag ? $frag : '-';
					$pLanes{$laneName} .= $value;
				}
			}
		}



		my $posSs = $pos  + 1;
		my $posEs = $posE + 1;


		print OUTS $dez . $one;
		print OUTA $dez . $one;
		#print      $dez . $one;
		foreach my $laneNum (sort {$a <=> $b} keys %lanesKeys)
		{
			my $laneName = $lanesKeys{$laneNum};
			my $lane     = $cLanes->[$laneNum];
			next if ! defined $lane;
			#print "\tKEY \'$lKey\'\n";
			my $line = sprintf($format , uc($laneName) , $posSs , $pLanes{$laneName} , $posEs);
			print OUTS $line;
			print OUTA $line;
			#print      $line;
		}
		print OUTS "\n\n";
		print OUTA "\n\n";
	}

		#
		#			my $sizeF = $size;
		#			while ($pos+$sizeF >= @$currContigChrom) { $sizeF--; };
		#
		#			my $posS  = $pos;
		#			my $posE  = $pos+$sizeF-1;
		#			#print "\tSTART $posS END $posE MAX ", scalar @$currContigChrom,"\n";
		#			#print "\t\tCONTIG :", scalar @{$lines{contigLine}}, " => ",@{$lines{contigLine}}[$posS..$posE],"\n";
		#			#print "\t\tFASTA  :", scalar @{$lines{fastaLine}} , " => ",@{$lines{fastaLine}}[$posS..$posE] ,"\n";
		#			#print "\t\tTEST   :", scalar @{$lines{testLine}}  , " => ",@{$lines{testLine}}[$posS..$posE]  ,"\n";
		#			#print "\t\tTAG    :", scalar @{$lines{tagLine}}   , " => ",@{$lines{tagLine}}[$posS..$posE]   ,"\n";
		#			#print "\t\tND     :", scalar @{$lines{ndLine}}    , " => ",@{$lines{ndLine}}[$posS..$posE]    ,"\n";
		#			#print "\t\tEVENT  :", scalar @{$lines{eventLine}} , " => ",@{$lines{eventLine}}[$posS..$posE] ,"\n";
		#			my $cLine = join('', @{$lines{contigLine}}[$posS..$posE]);
		#			my $fLine = join('', @{$lines{fastaLine}}[$posS..$posE]);
		#			my $oLine = join('', @{$lines{testLine}}[$posS..$posE]);
		#			my $tLine = join('', @{$lines{tagLine}}[$posS..$posE]);
		#			my $nLine = join('', @{$lines{ndLine}}[$posS..$posE]);
		#			my $eLine = join('', @{$lines{eventLine}}[$posS..$posE]);
		#
		#
		##die;
		#			my $line = $dez . $one .
		#					sprintf($format , "CONTIG" , $pos , $cLine , $posE) .
		#					sprintf($format , "FASTA"  , $pos , $fLine , $posE) .
		#					sprintf($format , "FASTAO" , $pos , $oLine , $posE) .
		#					sprintf($format , "TAG"    , $pos , $tLine , $posE) .
		#					sprintf($format , "ND"     , $pos , $nLine , $posE) .
		#					sprintf($format , "EVENT"  , $pos , $eLine , $posE);
		#
		#			if ((index($lines{ndLine},"x") != -1) || ($lines{tagLine} =~ /[^\-]/) || ($lines{eventLine} =~ /[^\-]/))
		#			{
		#				print OUTA $line, "\n";
		#				print OUTS $line, "\n";
		#			} else {
		#				print OUTA $line, "\n";
		#			}

				#last if $s >= 300;
				#die;

	close OUTA;
	close OUTS;
	close OUTF;

	print "PRINT ALIGNMENT...DONE\n";
}




sub generateArray
{
	print "GENERATING ARRAY\n";
	my ( $poses, $chrom, $fastaMap, $contigMap, $max ) = @_;
	my @array;
	#$hash->{$tableName}[$currId]{$dataName}[$unitName]{$key} = $value;
	my $countPos = 0;
	my $totalPos = scalar @$poses;
	my $tenTh    = int($totalPos/10000) || 1;
	print "\tTOTAL $totalPos [$tenTh] MAX $max\n" if ($printGeneratingArray);
	#print "LOADING ARRAY\n";
	#map {$array[$_] = [undef,undef,undef,undef,undef] } (0..$max);
	#print "ARRAY LOADED ", scalar @array, " ",scalar @{$array[0]},"\n";

	#%expectedKeys = (
	#	#xml segment      parser         tag      lane localArrayPos insert
	#	'microarray' => [\&parseMicro, [['micro', 0,   0,            0]]],
	#	'blast'      => [\&parseBlast, [['gene' , 1,   0,            0]]],
	#	'ndMap'      => [\&parseMap,   [['nd'   , 2,   0,            0],
	#									['event', 3,   1,            0],
	#									['snp'  , 4,   2,            0],
	#									['ins'  , 5,   3,            1],
	#									['gap'  , 6,   4,            1],
	#									['qual' , 7,   5,            0]]]
	# );

	for (my $pos = 0; $pos < $max; $pos++)
	{
		my $datasets = $poses->[$pos];
		next if ! defined $datasets;
		print "\t\tPOS $pos\n" if ($printGeneratingArray);
		#if ( ! ($countPos++ % $tenTh)) {$| = 1; print "$pos "; $| =0 };
		$countPos++;

		foreach my $dataset (sort keys %$datasets)
		{
			print "\t\t\tDATASET $dataset\n" if ($printGeneratingArray);
			my $datasetNfo = $expectedKeys{$dataset};
			my $parser     = $datasetNfo->[0];
			my $order      = $datasetNfo->[1];
			my $units      = $datasets->{$dataset};

			for (my $unit = 0; $unit < @$units; $unit++)
			{
				my $keys = $units->[$unit];
				die if ! defined $keys;
				print "\t\t\t\tUNIT $unit\n" if ($printGeneratingArray);
				my $rsvp = $parser->($pos, $keys);

				for (my $r = 0; $r < @$rsvp; $r++)
				{
					my $orderNfo = $order->[$r];
					my $name     = $orderNfo->[0]; # tag
					my $lane     = $orderNfo->[1]; # final lane
					my $insert   = $orderNfo->[3]; # insert or not
					my $value    = $rsvp->[$r];

					print "\t\t\t\tORDER $r NAME $name LANE $lane\n" if ($printGeneratingArray);
					next if ! defined $value;

					my $start = $value->[0];
					my $end   = $value->[1];
					my $desc  = $value->[2];

					#$array[$pos][$lane] = $value;
					#TODO: INSERTION NOT WORKING.
					# NOT EXPAND INSERT
					# EXPAND INSERT ON INSERT INSERT (DAAAAN)
					print "\t\t\t\t\tNAME $name LANE $lane START $start END $end DESC ",$$desc,"\n" if ($printGeneratingArray);
					if ( $insert )
					{
						$array[$lane][$start] = $value;
					} else {
						print "\t\t\t\t\t\tADDING FROM $start TO $end [",($end - $start),"]\n" if ($printGeneratingArray);
						for (my $p = $start; $p <= $end; $p++)
						{
							$array[$lane][$p] = $value;
							#print "\t\t\t\t\t\tADDING FOR LANE $lane POS $p\n";
						}
					}
				}
			}
		}
	}
	print "\n\n";
	#sleep(1000);

	my $currFastaChrom  = $fastaMap->readFasta($chrom);
	my $currContigChrom = $contigMap->readFasta($chrom);

	$array[$lanesValues{reference}] = $currFastaChrom;
	$array[$lanesValues{contig}]    = $currContigChrom;

	print "GENERATING ARRAY...DONE\n";
	return \@array;
}

sub applyInsertions
{
	my $array       = $_[0];
	my $maxLaneSize = $_[1];
	print "APPLYING INSERTIONS...\n";
	#$array[$lane][$p] = $value;

	print "  MAX LANE SIZE $maxLaneSize\n";

	my $iData;
	for ( my $p = $maxLaneSize; $p >= 0; $p--)
	{
		#print "  "x3, "POS $p\n";

		foreach my $insLane ( sort values %insertNumbers )
		{
			#print "  "x4, "CHECKING LANE (",$lanesKeys{$insLane},") $insLane\n";
			if ( defined ${$array->[$insLane]}[$p] )
			{
				my $insValue = $array->[$insLane][$p];
				die if ! defined $insValue;
				my $insStart = $insValue->[0];
				my $insEnd   = $insValue->[1];
				my $insDesc  = $insValue->[2];
				my $insNfo   = $insValue->[3];
				die if ! defined $insStart;
				die if ! defined $insEnd;
				die if ! defined $insDesc;
				die if ! defined $insNfo;
				#print "  "x5,"P $p START $insStart END $insEnd DESC ",$$insDesc,"\n";

				for (my $laneNum = 0; $laneNum < @$array; $laneNum++)
				{
					next if exists $numbersInsert{$laneNum};
					next if ( $lanesKeys{$laneNum} eq "contig" );

					#print "  "x6,"OTHERS LANE NUM (",$lanesKeys{$laneNum},") $laneNum\n";
					my $currLane  = $array->[$laneNum];
					next if ! defined $currLane;
					for (my $iPos = $insStart; $iPos <= $insEnd; $iPos++)
					{
						if ( $iPos <= @$currLane )
						{
							splice(@$currLane, $iPos+1,0,undef) if ($iPos+1 <= @$currLane);
						}
					}
				}

				for (my $laneNum = 0; $laneNum < @$array; $laneNum++)
				{
					next if ( ! exists $numbersInsert{$laneNum} );
					next if ( $lanesKeys{$laneNum} eq "contig" );

					#print "  "x6,"INS LANE NUM (",$lanesKeys{$laneNum},") $laneNum\n";
					my $currLane  = $array->[$laneNum];

					for (my $iPos = $insEnd+1; $iPos > $insStart ; $iPos--)
					{
						#print "  "x7,"INS LANE NUM (",$lanesKeys{$laneNum},") $laneNum > $iPos [$insStart - $insEnd = P $p]\n";
						my $insData;
						if ( $insLane == $laneNum ) { $insData = $insValue; }

						if ( $insEnd <= @$currLane )
						{
							#print "  "x8,"SPLICE\n";
							if ( $laneNum == $lanesValues{gap})
							{
								#print "  "x9,"GAP IPOS $iPos P $p START $insStart END $insEnd\n";
								$currLane->[$p] = $insData;
								splice(@$currLane, $p, 0, undef);
							}
							elsif ( $laneNum == $lanesValues{ins})
							{
								#print "  "x9,"INS IPOS $iPos P $p START $insStart END $insEnd\n";
								$currLane->[$p] = $insData;
								splice(@$currLane, $p, 0, undef);
							} else {
								die "WTF?";
							}
						} else {
							#print "  "x8,"POS $p IPOS $iPos PUSH $iPos LANE NUM (",$lanesKeys{$laneNum},") $laneNum START $insStart END $insEnd\n";
							push(@$currLane, $insData);
							#print  "  "x9,"$insData->[0] $insData->[1] ${$insData->[2]} %{$insData->[3]}\n";
						}
					}
				}
			}
		}
	}
	print "APPLYING INSERTIONS...DONE\n";
}




sub parseMicro
{
	my $pos = $_[0];
	my $nfo = $_[1];
	my @out;

	#<microarray>
	#	<unit id="0">
	#		<ANNO>CP000287_CGB_B9660W_Hypothetical_Protein_2156337_2160406.72976</ANNO>
	#		<CBS7750>-0.55</CBS7750>
	#		<CORR>0.95</CORR>
	#		<DIFF>-1.85</DIFF>
	#		<Hlength>60</Hlength>
	#		<Qlength>60</Qlength>
	#		<Qrylen>60</Qrylen>
	#		<R265>1.3</R265>
	#		<Tlength>60</Tlength>
	#		<WM276>-0.36</WM276>
	#		<consv>100.0</consv>
	#		<end>10405</end>
	#		<gaps>0</gaps>
	#		<gene>366GE_CneoSBc24_6001_12000_s_RC-60-1596|DIFF:-1.85|R265:1.3|CBS7750:-0.55|WM276:-0.36|CORR:0.95|ANNO:CP000287_CGB_B9660W_Hypothetical_Protein_2156337_2160406.72976</gene>
	#		<id>789</id>
	#		<ident>100.0</ident>
	#		<sign>3e-14</sign>
	#		<spotId>GE_CneoSBc24_6001_12000_s_RC-60-1596</spotId>
	#		<spotPos>366</spotPos>
	#		<start>10346</start>
	#		<strand>-1</strand>
	#	</unit>
	#</microarray>

	my $start  = $nfo->{start} - 1;
	my $end    = $nfo->{end}   - 1;
	my $desc   = \$nfo->{gene};

	die if ! defined $start;
	die if ! defined $end;
	die if ! defined $desc;
	my $localLane = $lArrayPos{micro};
	#print "\t\t\t\t[S $start E $end]\n";
	$out[$localLane][0] = $start;
	$out[$localLane][1] = $end;
	$out[$localLane][2] = $desc;
	$out[$localLane][3] = $nfo;

	return \@out;
};

sub parseBlast
{
	my $pos = $_[0];
	my $nfo = $_[1];
	my @out;

	#<blast>
	#	<unit id="0">
	#		<Hlength>1365</Hlength>
	#		<Qlength>1354</Qlength>
	#		<Qrylen>1694</Qrylen>
	#		<Tlength>1365</Tlength>
	#		<consv>95.4</consv>
	#		<end>94596</end>
	#		<gaps>11</gaps>
	#		<gene>CP000287_CGB_B9350W_Seryl_tRNA_synthetase_putative_2069850_2071543</gene>
	#		<id>6419</id>
	#		<ident>95.4</ident>
	#		<method>BLASTN</method>
	#		<sign>0.0</sign>
	#		<size>-1363</size>
	#		<start>93232</start>
	#		<strand>-1</strand>
	#	</unit>
	#</blast>

	my $start  = $nfo->{start} - 1;
	my $end    = $nfo->{end}   - 1;
	my $desc   = \$nfo->{gene};
	die if ! defined $start;
	die if ! defined $end;
	die if ! defined $desc;
	my $localLane = $lArrayPos{gene};
	#print "\t\t\t\t[S $start E $end]\n";
	$out[$localLane][0] = $start;
	$out[$localLane][1] = $end;
	$out[$localLane][2] = $desc;
	$out[$localLane][3] = $nfo;

	return \@out;
};

sub parseMap
{
	my $pos = $_[0];
	my $nfo = $_[1];
	my @out;

	my $start  = $pos;
	my $mod    = "[" . $nfo->{fastaSeq} . ">" . $nfo->{contigSeq} . "]";

	if ( exists $nfo->{nd} )
	{
		my $end    = $nfo->{nd_end} - 1;
		my $desc   = \$x;

		die if ! defined $start;
		die if ! defined $end;
		die if ! defined $desc;
		my $localLane = $lArrayPos{nd};
		#print "\t\t\t\t[ND S $start E $end LANE 0]\n";

		$out[$localLane][0] = $start;
		$out[$localLane][1] = $end;
		$out[$localLane][2] = $desc;
		$out[$localLane][3] = $nfo;
	}

	if ( exists $nfo->{events} )
	{
		my $end              = $nfo->{events_end} - 1;
		my $desc             = \$nfo->{events_tags};
		$nfo->{events_tags} .= "|$mod";

		die if ! defined $start;
		die if ! defined $end;
		die if ! defined $desc;
		my $localLane = $lArrayPos{event};
		#print "\t\t\t\t[EV S $start E $end LANE 1]\n";

		$out[$localLane][0] = $start;
		$out[$localLane][1] = $end;
		$out[$localLane][2] = $desc;
		$out[$localLane][3] = $nfo;
	}

	if ( exists $nfo->{tag} )
	{
		my $localLane = $lArrayPos{qual};
		my $tag       = $nfo->{tag};

		   if ( $tag eq "snp" ) { $localLane = $lArrayPos{snp}; }
		elsif ( $tag eq "ins" )	{ $localLane = $lArrayPos{ins};	}
		elsif ( $tag eq "gap" )	{ $localLane = $lArrayPos{gap};	}
		elsif ( $tag eq "del" )	{ $localLane = $lArrayPos{del};	}
		else  { die "UNKNOWN TAG: $tag\n"};

		my $desc = \$tag;
		my $end;
		#if ( exists $nfo->{tag_end} )	{ $end = $nfo->{tag_end};	}
		#else							{ $end = $start;			}

		if ( exists $nfo->{tag_insertion_seq} )
		{
			$end = $start + length($nfo->{tag_insertion_seq}) - 1;
			$mod = "[" . $nfo->{fastaSeq} . ">" . $nfo->{tag_insertion_seq} . "]";
		} else {
			$end = $start;
		}

		$nfo->{tag} .= "|$mod";

		die if ! defined $start;
		die if ! defined $end;
		die if ! defined $desc;

		#print "\t\t\t\t[TG S $start E $end TAG $tag LOCAL LANE $localLane]\n";

		$out[$localLane][0] = $start;
		$out[$localLane][1] = $end;
		$out[$localLane][2] = $desc;
		$out[$localLane][3] = $nfo;
	}

	return \@out;


			#<ndMap>
			#		<pos id="1">
			#			<contigPos>1</contigPos>
			#			<contigSeq>A</contigSeq>
			#			<fastaPos>-1</fastaPos>
			#			<fastaSeq>-</fastaSeq>
			#			<tag>ins</tag>
			#			<tag_end>50</tag_end>
			#			<tag_insertion_pos>1</tag_insertion_pos>
			#			<tag_insertion_seq>AGCACATCGACAATTTTTGGGGGTCATACACTGATCTCCTGGCTTTAGAT</tag_insertion_seq>
			#		</pos>
			#		<pos id="1">
			#			<contigPos>2</contigPos>
			#			<contigSeq>G</contigSeq>
			#			<events>1</events>
			#			<events_end>5</events_end>
			#			<events_tags>MIRA</events_tags>
			#			<fastaPos>-1</fastaPos>
			#			<fastaSeq>-</fastaSeq>
			#			<tag_insertion_pos>1</tag_insertion_pos>
			#		</pos>
			#		<pos id="1">
			#			<contigPos>51</contigPos>
			#			<contigSeq>C</contigSeq>
			#			<fastaPos>1</fastaPos>
			#			<fastaSeq>A</fastaSeq>
			#			<tag>snp</tag>
			#			<tag_end>53</tag_end>
			#			<tag_insertion_pos>1</tag_insertion_pos>
			#			<tag_insertion_seq>CGC</tag_insertion_seq>
			#		</pos>
			#</ndMap>

			#%expectedKeys = (
			#'microarray' => [\&parseMicro, [['micro', 0, 0, 0]]],
			#'blast'      => [\&parseBlast, [['gene' , 1, 0, 0]]],
			#'ndMap'      => [\&parseMap,   [['nd'   , 2, 0, 0],
			#								['event', 3, 1, 0],
			#								['snp'  , 4, 2, 0],
			#								['ins'  , 5, 3, 1],
			#								['gap'  , 6, 4, 1],
			#								['qual' , 7, 5, 0]]]

			#%lanesValue {micro => 0
			#			  gene  => 1
			#			  nd    => 2
			#			  event => 3
			#			  snp   => 4
			#			  ins   => 5
			#			  qual  => 6}

};

















sub loadXML
{
	my $file    = $_[0];
	my $hash    = $_[1];

	open FILE, "<$file" or die "COULD NOT OPEN FILE $file: $!";

	my $xmlType;
	my $xmlId;
	my $rootType;
	my $origin;
	my $tableType;

	my $tableName   = undef;
	my $dataName    = undef;
	my $currId      = undef;
	my $unitName    = undef;

	my $tableCount  = 0;
	my $posCount    = 0;
	my $lineCount   = 0;
	my $dataCount   = 0;
	my @poses;

	foreach my $line (<FILE>)
	{
		if ( ! $lineCount++ )
		{
			if ($line =~ /<(\S+)\s+id=\"(.*?)\"\s+type=\"(.*?)\"\s+src|origin=\"(.*?)\">/)
			{
				$xmlType  = $1;
				$xmlId    = $2;
				$rootType = $3 || '';
				$origin   = $4;
			} else {
				die "INVALID FIRST LINE :: $line\n";
			}
		}

		if (( ! defined $tableName ) && ($line =~ /<table id=\"(.*)\" type=\"(.*)\">/))
		{
			$tableName = $1;
			$tableType = $2;
		}
		elsif ( defined $tableName )
		{
			if ( $line =~ /<\/table>/ )
			{
				$tableName = undef;
	# 			$register  = 0;
				$tableCount++;
			}
			else
			{
				if ( ! defined $currId )
				{
					if ( $line =~ /\<pos (id=\"(\d+)\").*\>/ )
					{
						if (defined $2)
						{
						  $currId = $2;
						}
						else
						{
						  die "WRONG FORMAT";
						}
						$posCount++;
					}
				}
				else
				{
					if ($line =~ /<\/pos\>/)
					{
						$currId = undef;
					}
					else
					{
						if ( ! defined $dataName )
						{
							if ( ($line =~ /^\s+\<(\S+)\>$/) && ( exists $expectedKeys{$1} ))
							{
								$dataCount++;
								$dataName = $1;
							}
						}
						else
						{
							if ( ($line =~ /^\s+\<\/$dataName\>$/) )
							{
								$dataName = undef;
							}
							else
							{
								if ( ! defined $unitName )
								{
									if ($line =~ /^\s+\<unit id=\"(\d+?)\"\>$/)
									{
										$unitName = $1;
									}
								}
								else
								{
									if ($line =~ /^\s+\<\/unit\>$/)
									{
										$unitName = undef;
									}
									else
									{
										if ( $line =~ /<(\w+)>(\S+)<\/\1>/ )
										{
											my $key   = $1;
											my $value = $2;
											#printf "  %s %7d %10s %1d %-10s %s\n", $tableName, $currId, $dataName, $unitName, $key, $value;
											$hash->{$tableName}[$currId - 1]{$dataName}[$unitName]{$key} = $value;
										} #end if there's key value pair
									} #end else not end unit
								} #end else not defined unit
							} #end else not end dataname
						} #end else not defined data name
					} # end else not end table
				} # end else not defines current id
			} # end else end table
		} #end if defined tablename
	} #end foreach my $file

	close FILE;
	print	"  FILE \"$file\""                . "\n" .
			"    ROOT TYPE : \'$rootType\'"   . "\n" .
			"    ORIGIN    : \'$origin\'"     . "\n" .
			"    TABLE TYPE: \'$tableType\'"  . "\n" .
			"    TABLES    : \'$tableCount\'" . "\n" .
			"    POSITIONS : \'$posCount\'"   . "\n";
			"    REGISTERS : \'$dataCount\'"  . "\n" .

	return $hash;


	#<xmlpos id="XMLpos" type="pos" origin="seq.fasta;assembly.xml;blast.xml;micro.xml">
	#	<table id="supercontig_1.24_of_Cryptococcus_neoformans_Serotype_B" type="chromossome">
	#		<pos id="10405">
	#			<microarray>
	#				<unit id="0">
	#					<Hlength>60</Hlength>
	#					<Qlength>60</Qlength>
	#					<Qrylen>60</Qrylen>
	#					<Tlength>60</Tlength>
	#					<consv>100.0</consv>
	#					<end>10405</end>
	#					<gaps>0</gaps>
	#					<gene>366</gene>
	#					<id>789</id>
	#					<ident>100.0</ident>
	#					<sign>3e-14</sign>
	#					<start>10346</start>
	#					<strand>-1</strand>
	#				</unit>
	#			</microarray>
	#			<ndMap>
	#				<unit id="0">
	#					<contigPos>9482</contigPos>
	#					<contigSeq>*</contigSeq>
	#					<fastaPos>-1</fastaPos>
	#					<fastaSeq>-</fastaSeq>
	#					<tag>gap</tag>
	#				</unit>
	#				<unit id="1">
	#					<contigPos>9483</contigPos>
	#					<contigSeq>*</contigSeq>
	#					<fastaPos>-1</fastaPos>
	#					<fastaSeq>-</fastaSeq>
	#					<tag>gap</tag>
	#				</unit>
	#			</ndMap>
	#			<blast>
	#				<unit id="0">
	#					<Hlength>2244</Hlength>
	#					<Qlength>2248</Qlength>
	#					<Qrylen>2249</Qrylen>
	#					<Tlength>2252</Tlength>
	#					<consv>94.0</consv>
	#					<end>8284</end>
	#					<gaps>12</gaps>
	#					<gene>CP000287_CGB_B9670C_WD_repeat_protein_putative_2160980_2163228</gene>
	#					<id>6388</id>
	#					<ident>94.0</ident>
	#					<method>BLASTN</method>
	#					<sign>0.0</sign>
	#					<size>2244</size>
	#					<start>6041</start>
	#					<strand>1</strand>
	#				</unit>
	#			</blast>
	#		</pos>
	#	</table>
	#</root>
}








sub setup
{
	my $order = 0;
	%expectedKeys = (
		#xml segment      parser             tag     lane localArrayPos insert
		'ndMap'      => [\&parseMap,	[
											['snp'  , 0,   0,            0],
											['ins'  , 1,   1,            1],
											['gap'  , 2,   2,            1],
											['del'  , 3,   3,            0],
											#['qual' , 4,   4,            0],
											['event', 4,   4,            0],
											['nd'   , 5,   5,            0]
										]
						],
		'blast'      => [\&parseBlast,	[
											['gene' , 6,   0,            0]
										]
						],
		'microarray' => [\&parseMicro,	[
											['micro', 7,   0,            0]
										]
						]
	 );


	foreach my $pair (["reference", 0],["contig", 1])
	{
		my $tag            = $pair->[0];
		my $lane           = $pair->[1];
		$maxLineSize       = length $tag > $maxLineSize ? length $tag : $maxLineSize;
		$lines{$tag}       = '';
		$lanesKeys{$lane}  = $tag;
		$lanesValues{$tag} = $lane;
		$lArrayPos{$tag}   = 0;
	}


	foreach my $expect ( sort keys %expectedKeys )
	{
		#print "E $expect\n";
		my $class = $expectedKeys{$expect};
		my $parser = $class->[0];
		my $order  = $class->[1];

		foreach my $data (@$order)
		{
			my $tag      = $data->[0];
			my $lane     = $data->[1] + 2;
			my $lArrayP  = $data->[2];
			my $ins      = $data->[3];
			$data->[1]   = $lane;

			$maxLineSize = length $tag > $maxLineSize ? length $tag : $maxLineSize;

			#print "\t\tLANE $lane NAME $tag INS $ins\n";
			if ( $ins ) { $insertNumbers{$tag} = $lane; $numbersInsert{$lane} = $tag; };
			$lines{$tag}       = '';
			$lanesKeys{$lane}  = $tag;
			$lanesValues{$tag} = $lane;
			$lArrayPos{$tag}   = $lArrayP;
			$maxLineSize       = length $tag > $maxLineSize ? length $tag : $maxLineSize;
		}
	}

	die if ! scalar keys %insertNumbers;

	foreach my $pair ([\%lines, "lines"], [\%lanesKeys,"lanes keys"], [\%lanesValues,"lanes values"], [\%lArrayPos,"local array pos"], [\%insertNumbers,"insert numbers"])
	{
		my $hash = $pair->[0];
		my $name = $pair->[1];
		print uc($name),":\n";
		map { printf "    %".$maxLineSize."s => %s\n", $_, $hash->{$_}; } sort keys %$hash;
		print "\n";
	}

			#LINES:
			#       contig =>
			#          del =>
			#        event =>
			#          gap =>
			#         gene =>
			#          ins =>
			#        micro =>
			#           nd =>
			#         qual =>
			#    reference =>
			#          snp =>
			#
			#LANES KEYS:
			#            0 => reference
			#            1 => contig
			#           10 => micro
			#            2 => snp
			#            3 => ins
			#            4 => gap
			#            5 => del
			#            6 => qual
			#            7 => event
			#            8 => nd
			#            9 => gene
			#
			#LANES VALUES:
			#       contig => 1
			#          del => 5
			#        event => 7
			#          gap => 4
			#         gene => 9
			#          ins => 3
			#        micro => 10
			#           nd => 8
			#         qual => 6
			#    reference => 0
			#          snp => 2
			#
			#LOCAL ARRAY POS:
			#       contig => 0
			#          del => 3
			#        event => 5
			#          gap => 2
			#         gene => 0
			#          ins => 1
			#        micro => 0
			#           nd => 6
			#         qual => 4
			#    reference => 0
			#          snp => 0
			#
			#INSERT NUMBERS:
			#          gap => 4
			#          ins => 3





	my $d = 0;
	while ($d < 10) { $dez .= $d++ . " "x9; };
	substr($dez, 2,1,'');
	$dez .= " ";
	$dez  = " "x($maxLineSize+ 4 + $maxNumberSize) . $dez . "\n";
	$one  = " "x($maxLineSize+ 4 + $maxNumberSize) . "1234567890"x(int($lineSize/10)) . "\n";
}

1;

sub populateLinesRef
{
	my ($contig, $lines, $poses, $currContigChrom, $currFastaChrom) = @_;

	my %seenMapTags;
	my %seenEvents;
	  $lines->{fastaLine}    = $currFastaChrom;
	@{$lines->{ndLine}}      = ('-')x(scalar @$currFastaChrom);
	@{$lines->{eventLine}}   = ('-')x(scalar @$currFastaChrom);

	  $lines->{contigLine}   = $currContigChrom;
	@{$lines->{tagLine}}     = ('-')x(scalar @$currContigChrom);
	@{$lines->{tagDataLine}} = ('-')x(scalar @$currContigChrom);


	for (my $pos = 0; $pos < @$currFastaChrom; $pos++)
	{
		my $unit   = $poses->[$pos];
		#print "POS $pos\n";
		my $nd;
		my $ndEnd;
		my $event;
		my $eventEnd;
		my $eventTags = '';
		my $eventNick = '-';

		my $fastaPos     = $pos;
		#my $fastaSeq     = $currFastaChrom->[ $fastaPos     ];
		my $origFastaSeq = $currFastaChrom->[ $fastaPos     ];

		if (  defined $unit )
		{
			#print "\tUNIT\n";
			for my $nfo (@$unit)
			{
				#print "\t\tNFO\n";
				if ( defined $nfo )
				{
					#print "\t\t\t", join(", ", keys %$nfo), "\n";
					$fastaPos  = $nfo->{fastaPos};
					#$fastaSeq  = $nfo->{fastaSeq};

					die "POSITION $pos HAS NO FASTA  POSITION DEFINED $fastaPos"  if ( ! defined $fastaPos );
					#die "POSITION $pos HAS NO FASTA  SEQUENCE DEFINED $fastaSeq"  if ( ! defined $fastaSeq );

					##print "\t\t\t\tFASTA POS B4 $fastaPos\n";
					#if (($contigPos) && ($contigPos == -1))
					#{
					#	$contigPos = $currContigPos;
					#} else {
					#	#die "FASTA POS $fastaPos CURR $currFastaPos\n"    if $currFastaPos  != $fastaPos;
					#	$currContigPos = $contigPos;
					#}
					##print "\t\t\t\tFASTA POS AF $fastaPos\n";
					$origFastaSeq = " ";

					$nd           = $nfo->{nd};
					$ndEnd        = $nfo->{nd_end};
					$event        = $nfo->{events};
					$eventEnd     = $nfo->{events_end};
					$eventTags    = $nfo->{events_tags};

					$eventNick    = $eventTags ? substr($eventTags,  0, 1) : "-";

					$seenEvents{$eventNick}  = $eventTags;

					if ($event)
					{
						for (my $p = $pos; $p < $eventEnd; $p++)
						{
							$lines->{eventLine}[  $p] = $eventNick;
						};
					}

								#my %mapKeys = (
								#    "fastaPos"          => 0,
								#    "fastaSeq"          => 1,
								#    "contigPos"         => 2,
								#    "contigSeq"         => 3,
								#    "tag"               => 4,
								#	"tag_end"           => 5,
								#	"tag_insertion_pos" => 6,
								#	"tag_insertion_seq" => 7,
								#    "nd"                => 8,
								#	"nd_end"            => 9,
								#    "events"            => 10,
								#	"events_end"        => 11,
								#	"events_tags"       => 12
								#);

					if ($nd)
					{
						for (my $p = $pos; $p < $ndEnd;    $p++)
						{
							$lines->{ndLine}[     $p] = $nd ? "x" : "-";
						};
						#print OUTF &generateFlank($ndCount++, $contig, $poses, $nfo, $pos, $ndEnd, $currContigChrom, $currFastaChrom);
					}

					# PORTION SPECIFIC TO FLANKING CSV FILE
				} #end if defined nfo
				else
				{
					die "UNIT DEFINED BUT NOT NFO\n";
				} # end else if defined nfo

			} # end for my $nfo
		} else {
			#print "\tNO UNIT\n";

			$nd           = 0;
			$event        = 0;
			$eventNick    = "-";
			#print OUTG "$pos\t0\t0\t0\n";
			#print "\t\t[$f] FASTA POS   $fastaPos\n";
		} #end else not defined unit

		$event        = $eventNick;
		$nd           = $nd           ? "x"           : "-";
		#$fastaSeq     = $fastaSeq     ? $fastaSeq     : "-";
		$origFastaSeq = $origFastaSeq ? $origFastaSeq : "-";

		#print "\t\tPOS $pos $fastaPos => FASTA \"$fastaSeq\" CONTIG \"$contigSeq\" TEST \"$origFastaSeq\" MAP \"$mapTag\" ND \"$nd\" EV \"$event\"\n";
		#die "CONTIG $contig POS $pos HAS NO FASTA"      if ! defined $fastaSeq;
		#die "CONTIG $contig POS $pos HAS NO FASTA ORIG" if ! defined $origFastaSeq;

		#$lines->{testLine}[  $pos] = $origFastaSeq;
		#$lines->{ndLine}[    $pos] = $nd     if ! defined $lines->{ndLine}[    $pos];
		#$lines->{eventLine}[ $pos] = $event  if ! defined $lines->{eventLine}[ $pos];
	} # end for my pos
	#last if $s >= 300;
	#die;






	for (my $pos = @$currFastaChrom; $pos >= 0 ; $pos--)
	{
		my $unit   = $poses->[$pos];
		#print "POS $pos\n";
		my $tagNick = '-';
		my $mapTag;
		my $mapTagEnd;
		my $mapTagIPos;
		my $mapTagISeq;

		my $fastaPos     = $pos;
		my $fastaSeq     = $currFastaChrom->[ $fastaPos     ];
		my $origFastaSeq = $currFastaChrom->[ $fastaPos     ];
		my $contigSeq;

		if ( defined $unit )
		{
			my @sortedUnits;
			#print "\tUNIT\n";
			for my $nfo (@$unit)
			{
				if ( defined $nfo )
				{
					my $mapTag     = $nfo->{tag};
					if ( $mapTag )
					{
						   if ( $mapTag eq 'ins' ) {    push(@sortedUnits, $nfo) }
						elsif ( $mapTag eq 'gap' ) {    push(@sortedUnits, $nfo) }
						else                       { unshift(@sortedUnits, $nfo); }
					}
				}
			}



			for my $nfo (@sortedUnits)
			{
				#print "\t\tNFO\n";
				if ( defined $nfo )
				{
					$fastaPos   = $nfo->{fastaPos};
					$fastaSeq   = $nfo->{fastaSeq};
					$contigSeq  = $nfo->{contigSeq};

					$mapTag     = $nfo->{tag};
					$mapTagEnd  = $nfo->{tag_end};
					$mapTagIPos = $nfo->{tag_insertion_pos};
					$mapTagISeq = $nfo->{tag_insertion_seq};

					if ( $mapTag )
					{
							#MAF
							#>supercontig_1.24_of_Cryptococcus_neoformans_Serotype_B
							#AGCACATCGACAATTTTTGGGGGTCATACACTGATCTCCTGGCTTTAGATCGCCA
							#FASTA
							#>supercontig_1.24_of_Cryptococcus_neoformans_Serotype_B
							#ATTCACATCTCTTTGTTGCGCGATGTGATTGGCTTCTTCCCCCTAAGGCGCCGCCAGGGG

							#                  0        1         2         3         4         5         6         7         8         9
							#                  1234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890
							# CONTIG :       1 AGCACATCGACAATTTTTGGGGGTCATACACTGATCTCCTGGCTTTAGATCGCCAACATCTCTTTGTTGCGCGATGTGATTGTCTTCTTCACCGCGAAGG     100
							#  FASTA :       1 A--------------------------------------------------TTC-ACATCTCTTTGTTGCGCGATGTGATTGGCTTCTTC-CCCCTAAGG     100
							#    TAG :       1 siiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiss-i---------------------------s-------i--s-s----     100
							#TAGDATA :       1 CAGCACATCGACAATTTTTGGGGGTCATACACTGATCTCCTGGCTTTAGATGC-A---------------------------T-------A--G-G----     100
							#     ND :       1 ----------------------------------------------------------------------------------------------------     100
							#  EVENT :       1 --------------------------------------------------MSS-SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS-SSSSSSSSSS     100

							#<pos id="1">
							#	<contigPos>1</contigPos>
							#	<contigSeq>A</contigSeq>
							#	<fastaPos>-1</fastaPos>
							#	<fastaSeq>-</fastaSeq>
							#	<tag>ins</tag>
							#	<tag_end>50</tag_end>
							#	<tag_insertion_pos>1</tag_insertion_pos>
							#	<tag_insertion_seq>AGCACATCGACAATTTTTGGGGGTCATACACTGATCTCCTGGCTTTAGAT</tag_insertion_seq>
							#</pos>


						if ( $pos <= 100 ) {
							print "\t\t\t\tBE $pos: ", join('', @{$lines->{contigLine}} [0..99]), "\n";
							print "\t\t\t\tBE $pos: ", join('', @{$lines->{fastaLine}}  [0..99]), "\n";
							#print "\t\t\t\tBE $pos: ", join('', @{$lines->{testLine}}   [1..100]), "\n";
							print "\t\t\t\tBE $pos: ", join('', @{$lines->{tagLine}}    [1..100]), "\n";
							print "\t\t\t\tBE $pos: ", join('', @{$lines->{tagDataLine}}[1..100]), "\n";
							print "\t\t\t\tBE $pos: ", join('', @{$lines->{ndLine}}     [1..100]), "\n";
							print "\t\t\t\tBE $pos: ", join('', @{$lines->{eventLine}}  [1..100]), "\n\n";
						}

						$tagNick    =  substr($mapTag, 0, 1);
						die if ! defined $tagNick;

						map { print "\t\t\t$_ =>", $nfo->{$_}, "\n"} keys %$nfo;
						$seenMapTags{$tagNick}   = $mapTag;

						print "\t\t\tMAP $mapTag\n";

						my $tagLine   = $lines->{tagLine};
						my $tagDLine  = $lines->{tagDataLine};
						my $fastaLine = $lines->{fastaLine};
						#my $testLine  = $lines->{testLine};
						my $ndLine    = $lines->{ndLine};
						my $eventLine = $lines->{eventLine};
						my $seqLen    = ($mapTagISeq ? length($mapTagISeq) : 1);
						my $pEnd      =  $pos + $seqLen;


						print "\t\t\t\tP START $mapTagIPos END $pEnd\n";
						for ( my $p = $pos; $p < $pEnd; $p++ )
						{
							my $char  = $mapTagISeq  ? substr($mapTagISeq, ($p-$pos), 1) : undef;
							if (( $mapTag eq 'ins') && ( ! $mapTagISeq )) { $char = $contigSeq; };
							if ( ! defined $char                        ) { $char = $contigSeq; };

							die if ! defined $char;
							die if ! defined $tagNick;

							print "\t\t\t\t\tMAP ADD ",uc($mapTag)," > $p [",($mapTagISeq || $tagNick),"]($char)\n";

							if (( $mapTag eq 'ins' ) || ( $mapTag eq 'gap' ))
							{
								print "\t\t\t\t\t\tINS ADD ",uc($mapTag)," > $p(",($p+1),") [",($mapTagISeq || $tagNick),"]($char)\n";
								#splice(@$testLine, $pos  ,0, "-");
								splice(@$fastaLine, $p+1 ,0, "-"     );
								splice(@$ndLine   , $p+1 ,0, "-"     );
								splice(@$eventLine, $p+1 ,0, "-"     );
								splice(@$tagLine  , $p+1 ,0, $tagNick);
								splice(@$tagDLine , $p+1 ,0, $char   );
							} else {
								$tagLine-> [$p] = $tagNick;
								$tagDLine->[$p] = $char;
							}
						}
						if ( $pos <= 100 ) {
							print "\t\t\t\tAF $pos: ", join('', @{$lines->{contigLine}} [0..99]), "\n";
							print "\t\t\t\tAF $pos: ", join('', @{$lines->{fastaLine}}  [0..99]), "\n";
							#print "\t\t\t\tAF $pos: ", join('', @{$lines->{testLine}}   [1..100]), "\n";
							print "\t\t\t\tAF $pos: ", join('', @{$lines->{tagLine}}    [1..100]), "\n";
							print "\t\t\t\tAF $pos: ", join('', @{$lines->{tagDataLine}}[1..100]), "\n";
							print "\t\t\t\tAF $pos: ", join('', @{$lines->{ndLine}}     [1..100]), "\n";
							print "\t\t\t\tAF $pos: ", join('', @{$lines->{eventLine}}  [1..100]), "\n\n";
						}
					} # end if maptag
				} # end if nfo
			} # end for my nfo
		} else { # end if defined nfo
			#print "\tNO UNIT\n";
			#$tagNick    = "-";
			#print OUTG "$pos\t0\t0\t0\n";
			#print "\t\t[$f] FASTA POS   $fastaPos\n";
		} #end else not defined unit
	} # end for my pos



	my %captions = (
		"map"    => \%seenMapTags,
		"events" => \%seenEvents
	);

	return (\%captions);


}
