#!/usr/bin/perl -w
use strict;
use fasta;
#cat crypto_out.maf | grep -E "CS|CO" | perl -ne 's/\015//; s/_bb$//; if (/^CO\s+(\S+)$/) { print ">$1\n" } elsif (/^CS\s+/) { print substr($_,pos($_)+3), "\n"}' > crypto_out.maf.fasta
#reset; ./mafXml2Aln.pl xml/crypto_out.maf.nd.map.con.xml cryptococcus_neoformans_serotype_b_1_R265_supercontigs.fasta crypto_out.maf.fasta
my $size         = 100; #line size for alignment
my $csvFlankSize = 200;
my $outDir       = "xml";

my $inputFile  = $ARGV[0];
my $fastaFile  = $ARGV[1];
my $contigFile = $ARGV[2];

#cat crypto_out.maf | grep -E "CS|CO" | perl -ne 's/\015//; s/_bb$//; if (/^CO\s+(\S+)$/) { print ">$1\n" } elsif (/^CS\s+/) { print substr($_,pos($_)+3), "\n"}' > contig.fasta

die if @ARGV < 3;
die if ! defined $inputFile;
die if ! defined $fastaFile;
die if ! defined $contigFile;
die if ! -f      $inputFile;
die if ! -f      $fastaFile;
die if ! -f      $contigFile;
my $ndCount = 0;

my $fileType;
   if ( index($inputFile, ".ref.xml") != -1 ) { $fileType = "ref"; }
elsif ( index($inputFile, ".con.xml") != -1 ) { $fileType = "con"; }
else { die "UNKNOWN FILE TYPE" };

my $outFile   = "$inputFile.aln";
my $outFileS  = "$inputFile.short.aln";
my $outFileF  = "$inputFile.flanking.csv";
my $outFileG  = "$inputFile.graph";
my $xmlHash   = &loadXML($inputFile);
my $fastaM    = fasta->new($fastaFile);
my $contigM   = fasta->new($contigFile);

&exportAlignmentRich($xmlHash, $fastaM, $contigM, $inputFile, $fileType, $outFile, $outFileS, $outFileF, $outFileG);


sub exportAlignmentRich
{
	my $mafDb     = $_[0];
	my $fastaMap  = $_[1];
	my $contigMap = $_[2];
	my $in        = $_[3];
	my $fType     = $_[4];
	my $out       = $_[5];
	my $outS      = $_[6];
	my $outF      = $_[7];
	my $outG      = $_[8];

	print "PRINTING ALIGNMENT\n";

	open  OUTA, ">$out"  or die "COULD NOT OPEN $out  :$!\n";
	open  OUTS, ">$outS" or die "COULD NOT OPEN $outS :$!\n";
	open  OUTF, ">$outF" or die "COULD NOT OPEN $outF :$!\n";
	#open  OUTG, ">$outG" or die "COULD NOT OPEN $outG :$!\n";

	print OUTF 	"\"count\",\"chrom\",".
				"\"refStart\",\"refEnd\",\"refSize\","                .
				"\"refSeq\",\"refSeqUpstream\",\"refSeqDownstream\"," .
				"\"qryStart\",\"qryEnd\",\"qrySize\","                .
				"\"qrySeq\",\"qrySeqUpstream\",\"qrySeqDownstream\""  .
				"\n";

	print OUTA "INPUT: $in\n";
	print OUTS "INPUT: $in\n";
	print "INPUT: $in\n";

	my $format  = "%7s : %7d %-s %7d\n";

	my $dez;
	my $one;
	my $d = 0;
	while ($d < 10) { $dez .= $d++ . " "x9; };
	substr($dez, 2,1,'');
	$dez .= " ";
	$dez = " "x18 . $dez . "\n";
	$one = " "x18 . "1234567890"x10 . "\n";


	foreach my $contig ( sort keys %$mafDb)
	{
		print    "\tCONTIG $contig\n";
		print OUTA "CONTIG $contig\n";
		print OUTS "CONTIG $contig\n";
		my $poses           = $mafDb->{$contig};
		my $currFastaChrom  = $fastaMap->readFasta($contig);
		my $currContigChrom = $contigMap->readFasta($contig);
		#$hash->{$tableName}[$currId][$poses[$tableCount][$currId] - 1]{$key} = $value;

		#print "\t",join('', @{$currFastaChrom}[0..99]),"\n";
		#print "\t",join('', @{$currContigChrom}[0..99]),"\n";



		my %lines = (
			"fastaLine"   => [],
			"contigLine"  => [],
			#"testLine"    => [],
			"tagLine"     => [],
			"tagDataLine" => [],
			"ndLine"      => [],
			"eventLine"   => []
		);

		my ($captions) = &populateLines($fType, $contig, \%lines, $poses, $currContigChrom, $currFastaChrom);

		print "LENGTH : ", scalar @{$lines{fastaLine}}, "\n";
		my $cap = "CAPTION\n";

		foreach my $title (keys %$captions)
		{
			$cap .= "\t" . uc($title) . "\n";
			my $hash  = $captions->{$title};
			foreach my $nick (keys %$hash)
			{
				my $value = $hash->{$nick} || 'none';
				$cap .= "\t\t$nick = $value\n";
			}
		}

		print OUTA $cap, "\n";
		print OUTS $cap, "\n";
		#print      $cap, "\n";

		my $maxChrom = 0;
		if    ($fType eq 'ref') { $maxChrom = @$currFastaChrom  }
		elsif ($fType eq 'con') { $maxChrom = @$currContigChrom }
		else                    { die "NOR REF NOR CON"; };

		for (my $pos = 0; $pos < $maxChrom; $pos+=$size)
		{
			my $sizeF = $size;
			while ($pos+$sizeF >= $maxChrom) { $sizeF--; };

			my $posS  = $pos;
			my $posE  = $pos+$sizeF-1;
			#print "\tSTART $posS END $posE MAX ", scalar @$currContigChrom,"\n";
			#print "\t\tCONTIG :", scalar @{$lines{contigLine}}, " => ",@{$lines{contigLine}}[$posS..$posE],"\n";
			#print "\t\tFASTA  :", scalar @{$lines{fastaLine}} , " => ",@{$lines{fastaLine}}[$posS..$posE] ,"\n";
			#print "\t\tTEST   :", scalar @{$lines{testLine}}  , " => ",@{$lines{testLine}}[$posS..$posE]  ,"\n";
			#print "\t\tTAG    :", scalar @{$lines{tagLine}}   , " => ",@{$lines{tagLine}}[$posS..$posE]   ,"\n";
			#print "\t\tND     :", scalar @{$lines{ndLine}}    , " => ",@{$lines{ndLine}}[$posS..$posE]    ,"\n";
			#print "\t\tEVENT  :", scalar @{$lines{eventLine}} , " => ",@{$lines{eventLine}}[$posS..$posE] ,"\n";
			my $cLine = join('', @{$lines{contigLine}} [$posS..$posE]);
			my $fLine = join('', @{$lines{fastaLine}}  [$posS..$posE]);
			#my $oLine = join('', @{$lines{testLine}}   [$posS..$posE]);
			my $tLine = join('', @{$lines{tagLine}}    [$posS..$posE]);
			my $dLine = join('', @{$lines{tagDataLine}}[$posS..$posE]);
			my $nLine = join('', @{$lines{ndLine}}     [$posS..$posE]);
			my $eLine = join('', @{$lines{eventLine}}  [$posS..$posE]);


#die;
			my $posSP = $pos  + 1;
			my $posEP = $posE + 1;
			my $line = $dez . $one .
					sprintf($format , "CONTIG" , $posSP , $cLine , $posEP) .
					sprintf($format , "FASTA"  , $posSP , $fLine , $posEP) .
					#sprintf($format , "FASTAO" , $posSP , $oLine , $posEP) .
					sprintf($format , "TAG"    , $posSP , $tLine , $posEP) .
					sprintf($format , "TAGDATA", $posSP , $dLine , $posEP) .
					sprintf($format , "ND"     , $posSP , $nLine , $posEP) .
					sprintf($format , "EVENT"  , $posSP , $eLine , $posEP);

			if ((index($lines{ndLine},"x") != -1) || ($lines{tagLine} =~ /[^\-]/) || ($lines{eventLine} =~ /[^\-]/))
			{
				print OUTA $line, "\n";
				print OUTS $line, "\n";
			} else {
				print OUTA $line, "\n";
			}

			#last if $s >= 300;
			#die;
		} # end for my f
	} # end foreach my contig

	close OUTA;
	close OUTS;
	close OUTF;
	#close OUTG;

	print "PRINT ALIGNMENT...DONE\n";
}

sub populateLines
{
	my $fType = shift;
	my ($contig, $lines, $poses, $currContigChrom, $currFastaChrom) = @_;

	if ( $fType eq "ref" )
	{
		return &populateLinesRef(@_);
	}
	elsif ( $fType eq "con" )
	{
		return &populateLinesCon(@_);
	} else
	{
		die "UNKNOWN FILE TYPE $fType";
	}
}
#ATTCACATCTCTTTGTTGCGCG
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
						print OUTF &generateFlank($ndCount++, $contig, $poses, $nfo, $pos, $ndEnd, $currContigChrom, $currFastaChrom);
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
							#print "\t\t\t\tBE $pos: ", join('', @{$lines->{contigLine}} [0..99]), "\n";
							#print "\t\t\t\tBE $pos: ", join('', @{$lines->{fastaLine}}  [0..99]), "\n";
							##print "\t\t\t\tBE $pos: ", join('', @{$lines->{testLine}}   [1..100]), "\n";
							#print "\t\t\t\tBE $pos: ", join('', @{$lines->{tagLine}}    [1..100]), "\n";
							#print "\t\t\t\tBE $pos: ", join('', @{$lines->{tagDataLine}}[1..100]), "\n";
							#print "\t\t\t\tBE $pos: ", join('', @{$lines->{ndLine}}     [1..100]), "\n";
							#print "\t\t\t\tBE $pos: ", join('', @{$lines->{eventLine}}  [1..100]), "\n\n";
						}

						$tagNick    =  substr($mapTag, 0, 1);
						die if ! defined $tagNick;

						#map { print "\t\t\t$_ =>", $nfo->{$_}, "\n"} keys %$nfo;
						$seenMapTags{$tagNick}   = $mapTag;

						#print "\t\t\tMAP $mapTag\n";

						my $tagLine   = $lines->{tagLine};
						my $tagDLine  = $lines->{tagDataLine};
						my $fastaLine = $lines->{fastaLine};
						#my $testLine  = $lines->{testLine};
						my $ndLine    = $lines->{ndLine};
						my $eventLine = $lines->{eventLine};
						my $seqLen    = ($mapTagISeq ? length($mapTagISeq) : 1);
						my $pEnd      =  $pos + $seqLen;


						#print "\t\t\t\tP START $mapTagIPos END $pEnd\n";
						for ( my $p = $pos; $p < $pEnd; $p++ )
						{
							my $char  = $mapTagISeq  ? substr($mapTagISeq, ($p-$pos), 1) : undef;
							if (( $mapTag eq 'ins') && ( ! $mapTagISeq )) { $char = $contigSeq; };
							if ( ! defined $char                        ) { $char = $contigSeq; };

							die if ! defined $char;
							die if ! defined $tagNick;

							#print "\t\t\t\t\tMAP ADD ",uc($mapTag)," > $p [",($mapTagISeq || $tagNick),"]($char)\n";

							if (( $mapTag eq 'ins' ) || ( $mapTag eq 'gap' ))
							{
								#print "\t\t\t\t\t\tINS ADD ",uc($mapTag)," > $p(",($p+1),") [",($mapTagISeq || $tagNick),"]($char)\n";
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
							#print "\t\t\t\tAF $pos: ", join('', @{$lines->{contigLine}} [0..99]), "\n";
							#print "\t\t\t\tAF $pos: ", join('', @{$lines->{fastaLine}}  [0..99]), "\n";
							##print "\t\t\t\tAF $pos: ", join('', @{$lines->{testLine}}   [1..100]), "\n";
							#print "\t\t\t\tAF $pos: ", join('', @{$lines->{tagLine}}    [1..100]), "\n";
							#print "\t\t\t\tAF $pos: ", join('', @{$lines->{tagDataLine}}[1..100]), "\n";
							#print "\t\t\t\tAF $pos: ", join('', @{$lines->{ndLine}}     [1..100]), "\n";
							#print "\t\t\t\tAF $pos: ", join('', @{$lines->{eventLine}}  [1..100]), "\n\n";
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

sub populateLinesCon
{
	my ($contig, $lines, $poses, $currContigChrom, $currFastaChrom) = @_;

	my $currFastaPos = 1;

	my %seenMapTags;
	my %seenEvents;

	for (my $pos = 1; $pos < @$currContigChrom; $pos++)
	{
		my $unit   = $poses->[$pos];
		print "POS $pos\n";
		my $mapTag;
		my $mapTagEnd;
		my $mapTagIPos;
		my $mapTagISeq;
		my $nd;
		my $ndEnd;
		my $event;
		my $eventEnd;
		my $eventTags = '';
		my $eventNick = '-';
		my $tagNick   = '-';
		my $tagData   = '-';

		my $fastaPos     = $currFastaPos;
		my $contigPos    = $pos;
		my $fastaSeq     = $currFastaChrom->[ $fastaPos     ];
		my $contigSeq    = $currContigChrom->[$contigPos - 1];
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
					$contigPos = $nfo->{contigPos};
					$fastaSeq  = $nfo->{fastaSeq};
					$contigSeq = $nfo->{contigSeq};

					die "POSITION $pos HAS NO FASTA  POSITION DEFINED $fastaPos"  if ( ! defined $fastaPos );
					die "POSITION $pos HAS NO FASTA  SEQUENCE DEFINED $fastaSeq"  if ( ! defined $fastaSeq );
					die "POSITION $pos HAS NO CONTIG POSITION DEFINED $contigPos" if ( ! defined $contigPos );
					die "POSITION $pos HAS NO CONTIG SEQUENCE DEFINED $contigSeq" if ( ! defined $contigSeq );

					#print "\t\t\t\tFASTA POS B4 $fastaPos\n";
					if (($fastaPos) && ($fastaPos == -1))
					{
						$fastaPos = $currFastaPos;
					} else {
						#die "FASTA POS $fastaPos CURR $currFastaPos\n"    if $currFastaPos  != $fastaPos;
						$currFastaPos = $fastaPos;
					}
					#print "\t\t\t\tFASTA POS AF $fastaPos\n";
					$origFastaSeq = " ";
					$mapTag       = $nfo->{tag};
					$mapTagEnd    = $nfo->{tag_end};
					$mapTagIPos   = $nfo->{tag_insertion_pos};
					$mapTagISeq   = $nfo->{tag_insertion_seq};
					$nd           = $nfo->{nd};
					$ndEnd        = $nfo->{nd_end};
					$event        = $nfo->{events};
					$eventEnd     = $nfo->{events_end};
					$eventTags    = $nfo->{events_tags};

					$tagNick      = $mapTag    ? substr($mapTag,     0, 1) : "-";
					$eventNick    = $eventTags ? substr($eventTags,  0, 1) : "-";

					$seenMapTags{$tagNick}   = $mapTag;
					$seenEvents{$eventNick}  = $eventTags;

					#print OUTG "$contig\t$pos",
					#		"\t",($mapTag ? 0 : 1),
					#		"\t",($nd     ? 0 : 1),
					#		"\t",($event  ? 0 : 1),"\n";

					if ($event)
					{
						for (my $p = $pos; $p < $eventEnd; $p++)
						{
							$lines->{eventLine}[  $p] = $eventNick;
						};
					}


					#my %mapKeys = (
					#	"fastaPos"          => 0,
					#	"fastaSeq"          => 3,
					#	"contigPos"         => 4,
					#	"contigSeq"         => 5,
					#	"tag"               => 6,
					#	"tag_end"           => 7,
					#	"tag_insertion_pos" => 1,
					#	"tag_insertion_seq" => 2,
					#	"nd"                => 8,
					#	"nd_end"            => 9,
					#	"events"            => 10,
					#	"events_end"        => 11,
					#	"events_tags"       => 12
					#);


					if ($mapTag)
					{
						#print "\t\t\tMAP $mapTag\n";
						for (my $p = $pos; $p < $mapTagEnd; $p++)
						{
							#my $char = substr($mapTagISeq, ($p-$pos), 1);
							#print "\t\t\t\tMAP ADD $p > $tagNick\n";
							$lines->{tagLine}[  $p] = $tagNick;
						};
					}

					# PORTION SPECIFIC TO FLANKING CSV FILE
					if ($nd)
					{
						for (my $p = $pos; $p < $ndEnd;    $p++)
						{
							$lines->{ndLine}[     $p] = $nd ? "x" : "-";
						}
						print OUTF &generateFlank($ndCount++, $contig, $poses, $nfo, $pos, $ndEnd, $currContigChrom, $currFastaChrom);
					}
				} #end if defined nfo
				else
				{
					die "UNIT DEFINED BUT NOT NFO\n";
				}

			} # end for my $nfo
		} else {
			#print "\tNO UNIT\n";
			$currFastaPos++;
			$mapTag       = 0;
			$nd           = 0;
			$event        = 0;
			$tagNick      = "-";
			$eventNick    = "-";
			#print OUTG "$pos\t0\t0\t0\n";
			#print "\t\tFASTA POS   $fastaPos\n";
		} #end else not defined unit


		$mapTag       = $tagNick;
		$nd           = $nd           ? "x"           : "-";
		$event        = $eventNick;
		$fastaSeq     = $fastaSeq     ? $fastaSeq     : "-";
		$origFastaSeq = $origFastaSeq ? $origFastaSeq : "-";

		#print "\t\tPOS $pos $fastaPos => FASTA \"$fastaSeq\" CONTIG \"$contigSeq\" TEST \"$origFastaSeq\" MAP \"$mapTag\" ND \"$nd\" EV \"$event\"\n";
		die "CONTIG $contig POS $pos HAS NO FASTA"      if ! defined $fastaSeq;
		die "CONTIG $contig POS $pos HAS NO CONTIG"     if ! defined $contigSeq;
		die "CONTIG $contig POS $pos HAS NO FASTA ORIG" if ! defined $origFastaSeq;

		$lines->{fastaLine}  [$pos] = $fastaSeq;
		$lines->{contigLine} [$pos] = $contigSeq;
		#$lines->{testLine}   [$pos] = $origFastaSeq;
		$lines->{tagLine}    [$pos] = $mapTag  if ! defined $lines->{tagLine}    [$pos];
		$lines->{tagDataLine}[$pos] = $tagData if ! defined $lines->{tagDataLine}[$pos];
		$lines->{ndLine}     [$pos] = $nd      if ! defined $lines->{ndLine}     [$pos];
		$lines->{eventLine}  [$pos] = $event   if ! defined $lines->{eventLine}  [$pos];
	} # end for my pos
	#last if $s >= 300;
	#die;

	my %captions = (
		"map"    => \%seenMapTags,
		"events" => \%seenEvents
	);

	return (\%captions);
}

sub generateFlank
{
	my ($ndCount, $contig, $poses, $nfo, $pos, $ndEnd, $currContigChrom, $currFastaChrom) = @_;

	my $refNdStart = $pos;
	my $refNdEnd   = $ndEnd;
	my $refNdSize  = $ndEnd - $refNdStart;

	my $qryNdStart = $nfo->{fastaPos};
	my $qryNdEnd   = $qryNdStart + $refNdSize ;
	my $qryNdSize  = $refNdSize;

	#print "\tND REF START $refNdStart END $refNdEnd SIZE $refNdSize\n";
	#print "\tND QRY START $qryNdStart END $qryNdEnd SIZE $qryNdSize\n";

	my $refNdFlankEnd   = $refNdEnd   + $csvFlankSize;
	my $refNdFlankStart = $refNdStart - $csvFlankSize;

	my $qryNdFlankEnd   = $qryNdEnd   + $csvFlankSize;
	my $qryNdFlankStart = $qryNdStart - $csvFlankSize;

	if ( $refNdFlankStart <= 0 )                 { $refNdFlankStart = 0; };
	#if ( $refNdFlankStart <= $lastRefNdBefore )  { $refNdFlankStart = $lastRefNdBefore  + 1; };
	if ( $refNdFlankEnd   >= @$currContigChrom ) { $refNdFlankEnd   = @$currContigChrom - 1; };
	if ( $refNdEnd        >= @$currContigChrom ) { $refNdEnd        = @$currContigChrom - 1; };

	if ( $qryNdFlankStart <= 0 )                 { $qryNdFlankStart = 0; };
	#if ( $qryNdFlankStart <= $lastQryNdBefore )  { $qryNdFlankStart = $lastQryNdBefore  + 1; };
	if ( $qryNdFlankEnd   >= @$currFastaChrom )  { $qryNdFlankEnd   = @$currFastaChrom  - 1; };
	if ( $qryNdEnd        >= @$currFastaChrom )  { $qryNdEnd        = @$currFastaChrom  - 1; };

	#print "\t\tND REF $refNdFlankStart .. $refNdStart | $refNdStart .. $refNdEnd | $refNdEnd .. $refNdFlankEnd | $refNdSize\n";
	#print "\t\tND QRY $qryNdFlankStart .. $qryNdStart | $qryNdStart .. $qryNdEnd | $qryNdEnd .. $qryNdFlankEnd | $qryNdSize\n";

	my $refSeq       = join('',@{$currContigChrom}[$refNdStart      .. $refNdEnd      ]);
	my $refSeqD      = join('',@{$currContigChrom}[$refNdEnd        .. $refNdFlankEnd ]);
	my $refSeqU      = join('',@{$currContigChrom}[$refNdFlankStart .. $refNdStart    ]);

	my $qrySeq       = join('',@{$currFastaChrom}[$qryNdStart      .. $qryNdEnd       ]);
	my $qrySeqD      = join('',@{$currFastaChrom}[$qryNdEnd        .. $qryNdFlankEnd  ]);
	my $qrySeqU      = join('',@{$currFastaChrom}[$qryNdFlankStart .. $qryNdStart     ]);

	return 		"\"" . $ndCount    . "\",\"" . $contig    . "\","   .
				"\"" . $refNdStart . "\",\"" . $refNdEnd  . "\",\"" . $refNdSize  . "\"," .
				"\"" . $refSeq     . "\",\"" . $refSeqU   . "\",\"" . $refSeqD    . "\"," .
				"\"" . $qryNdStart . "\",\"" . $qryNdEnd  . "\",\"" . $qryNdSize  . "\"," .
				"\"" . $qrySeq     . "\",\"" . $qrySeqU   . "\",\"" . $qrySeqD    . "\""  .
				"\n";
	#print "\t\t\t", $out;
}


sub loadXML
{
	my $file    = $_[0];
	my $hash    = $_[1];

	open FILE, "<$file" or die "COULD NOT OPEN FILE $file: $!";
		#<blast id="r265_vs_wm276.blast" type="blast">
		#	<table id="CP000286_CGB_A1680C_Nucleic_acid_binding_protein_putative_352276_358966" type="chromossome">
		#		<pos id="1">
		#			<id>1</id>

		#<microarray id="Microarray_may_r265_data.csv.xml.blast" type="microarray">
		#	<table id="supercontig_1.01_of_Cryptococcus_gattii_CBS7750v4" type="chromossome">
		#		<pos id="14642">
		#			<id>1</id>

		#<snp id="mosaik" type="snp">
		#	<table id="supercontig_1.01_of_Cryptococcus_neoformans_Serotype_B" type="chromossome">
		#		<pos id="7">
		#			<Pvalue>0.0</Pvalue>

	#<ndMap id="crypto_out.maf" type="chromossome" src="mira303_cbs7500_v4">
	#	<table id="supercontig_1.01_of_Cryptococcus_neoformans_Serotype_B" type="chromossome">
	#		<pos id="1">
	#			<contigPos>1</contigPos>
	#			<contigSeq>T</contigSeq>
	#			<fastaPos>-1</fastaPos>
	#			<fastaSeq>-</fastaSeq>
	#			<tag>ins</tag>
	#		</pos>
	my $rootType;
	my $origin;
	my $tableType;
	my $tableName   = "";

	my $row         = 0;
	my $table       = 0;
	my $currId      = "";

	my $tableCount  = 0;
	my $posCount    = 0;
	my $lineCount   = 0;
	my @poses;

	foreach my $line (<FILE>)
	{
		if ( ! $lineCount++ )
		{
			if ($line =~ /<(\S+) id=\"(.*)\" type=\"(.*)\">/)
			{
				$origin   = $2;
				$rootType = $3;
			} else {
				die "INVALID FIRST LINE\n";
			}
		}
		elsif (( ! $table ) && ($line =~ /<table id=\"(.*)\" type=\"(.*)\">/))
		{
			$table     = 1;
			$tableName = $1;
			$tableType = $2;
		}
		elsif (( $table ) && ($line =~ /<\/table>/))
		{
			$table     = 0;
			$tableName = "";
# 			$register  = 0;
			$tableCount++;

		}
		elsif (( $table ) && ( $line =~ /\<pos (id=\"(\d+)\").*\>/ ))
		{
			if (defined $2)
			{
			  $currId = $2;
			}
			else
			{
			  die "WRONG FORMAT";
			}
			$row = 1;
			$posCount++;
			$poses[$tableCount][$currId]++;
		}
		elsif (( $row ) && ($line =~ /<\/pos\>/))
		{
			$row = 0;
		}
		elsif ( $row )
		{
			if ($line =~ /<(\w+)>(\S+)<\/\1>/)
			{
# 				print "$line\n";
				my $key   = $1;
				my $value = $2;
# 				print "$register => $key -> $value\n";
				if ($tableName)
				{
					my $unit = $poses[$tableCount][$currId] - 1;
 					#print "$tableName $currId $unit $key $value\n";
					$hash->{$tableName}[$currId - 1][$unit]{$key} = $value;
# 					$XMLhash{$tableName}{$currId}{$key} = $value;
				}
				else
				{
					die "TABLE NAME NOT DEFINED IN XML $file\n";
				}
			}
		}
	}

	close FILE;
	print "  FILE $file PARSED: $posCount REGISTERS RECOVERED FROM $tableCount TABLES\n";
	print "  ROOT TYPE: $rootType TABLE TYPE: $tableType\n";
	return $hash;
}




sub revComp($)
{
    my $sequence = uc(shift);
    $sequence    = reverse($sequence);
    $sequence    =~ tr/ACTG/TGAC/;
    return $sequence;
}



1;
