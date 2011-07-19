#!/usr/bin/perl -w
#SAULO AFLITOS
#MAF2ND
#08/06/2010 @ 1300
#Licence: GPL

#reset; ./maf2nd.pl crypto_out.maf cryptococcus_neoformans_serotype_b_1_R265_supercontigs.fasta
use strict;
use readMaf;
use fasta;

my $outDir            = "xml";
my $src               = "mira320_cbs7500_v4";
mkdir($outDir);


my $printExport       = 1;
my $printExportDetail = 1;
my $printExpMap       = 1;
my $minLeng           = 0;


# TODO: REFERENCIATE GAP TO ORIGINAL INSTEAD OF CONTIG POSITION

my $inFile  = $ARGV[0];
my $inFasta = $ARGV[1];
my $inChrom = $ARGV[2];

die "NO INPUT FILE DEFINED"                if ( ! defined $inFile   );
die "NO INPUT FASTA DEFINED"               if ( ! defined $inFasta  );
die "NO CHROMOSSOME NUMBER DEFINED"        if ( ! defined $inChrom  );
die "NO SUCH INPUT FILE :: $inFile"        if ( ! -f      $inFile   );
die "NO SUCH INPUT FASTA :: $inFasta"      if ( ! -f      $inFasta  );
die "WRONG CHROMOSSOME NUMBER :: $inChrom" if ( $inChrom =~ /[^\d]/ );

$inChrom = sprintf("%03d", $inChrom);

my $outFile    = $outDir . "/" . $inFile . ".nd.$inChrom.xml";
my $outFileRAW = $outDir . "/" . $inFile . ".nd.$inChrom.RAW.xml";
my $outMapRef  = $outDir . "/" . $inFile . ".nd.$inChrom.map.ref.xml";
my $outMapCon  = $outDir . "/" . $inFile . ".nd.$inChrom.map.con.xml";
my $outMapRefT = $outDir . "/" . $inFile . ".nd.$inChrom.map.ref.tab";
my $outAln     = $outDir . "/" . $inFile . ".nd.$inChrom.aln.txt";
#&printStructure();


print "#"x30, " INPUT  ", "#"x30,"
INPUT  FILE         : $inFile
INPUT  FASTA        : $inFasta
INPUT  CHROMOSSOME  : $inChrom
", "#"x30, " OUTPUT ",     "#"x30,"
OUTPUT FILE         : $outFile
OUTPUT FILE RAW     : $outFileRAW
OUTPUT MAP REF      : $outMapRef
OUTPUT MAP CON      : $outMapCon
OUTPUT MAP REF TAB  : $outMapRefT
OUTPUT ALIGN        : $outAln
";


my %keys  = (
	'snp'  => [0,$outDir . "/" . $inFile . ".nd.$inChrom.map.ref.snp.tab"],
	'ins'  => [1,$outDir . "/" . $inFile . ".nd.$inChrom.map.ref.ins.tab"],
	'gap'  => [2,$outDir . "/" . $inFile . ".nd.$inChrom.map.ref.gap.tab"],
	'del'  => [3,$outDir . "/" . $inFile . ".nd.$inChrom.map.ref.del.tab"],
	'event'=> [4,$outDir . "/" . $inFile . ".nd.$inChrom.map.ref.evn.tab"],
	'nd'   => [5,$outDir . "/" . $inFile . ".nd.$inChrom.map.ref.nda.tab"]
);

my @values;
print "#"x30, " OUTPUT ", "#"x30,"\n";
map {
	$values[$keys{$_}[0]] = $_;
	printf "OUTPUT MAP REF %-5s: %s\n", uc($_), $keys{$_}[1];
	} keys %keys;

print "#"x30, "#"x9,     "#"x30, "\n";






my $fasta           = fasta->new($inFasta);
my ($maf, $primaryKey, $specialP, $reservedKeys, $mapKeys) = readMaf->new($inFile, $fasta, $inChrom);
my %reserved = reverse %$reservedKeys;

#&exportRawDb($maf, $inFile, $outFileRAW, $inFasta, $fasta, $primaryKey, $specialP, $reservedKeys->{reads}, \%reserved);
&exportMaps($maf, $inFile, $outMapRef, $outMapRefT, $outMapCon, $reservedKeys->{map}, $mapKeys);
#&exportAlignmentRich($maf, $inFile, $outAln, $reservedKeys->{map});
print "COMPLETED!\n";
exit 0;


sub exportMaps
{
	my $mafDb   = $_[0];
	my $in      = $_[1];
	my $outRef  = $_[2];
	my $outRefT = $_[3];
	my $outCon  = $_[4];
	my $mapKey  = $_[5];
	my $mKeys   = $_[6];

	print "EXPORTING MAPPING\n";

	open  OUTMR,  ">$outRef"  or die "COULD NOT OPEN $outRef: $!";
	open  OUTMC,  ">$outCon"  or die "COULD NOT OPEN $outCon: $!";

	print OUTMR  "<ndMap id=\"$in\" type=\"chromossome\" src=\"$src\">\n";
	print OUTMC  "<ndMap id=\"$in\" type=\"chromossome\" src=\"$src\">\n";

	foreach my $tag (sort keys %keys)
	{
		my $fn = $keys{$tag}[1];
		#my $fh;
		print "OPPENING TAG $tag FILE\n";
		open(my $fh, ">$fn") or die "COULD NOT OPEN $fn: $!";
		print $fh "#sequence\tstrand\tstart\tend\tunique name\tcommom name\tgene type\n";
		$keys{$tag}[2] = $fh;
	}

	foreach my $contig ( sort keys %$mafDb )
	{
		print "\tCONTIG $contig\n";
		print OUTMR "\t<table id=\"$contig\" type=\"chromossome\">\n";
		print OUTMC "\t<table id=\"$contig\" type=\"chromossome\">\n";
		my $map = $mafDb->{$contig}{$mapKey};

		my $lastFastaPos = 1;
		for ( my $pos = 0; $pos < @$map; $pos++ )
		{
			my $nfo       = $map->[$pos];
			next if ! defined $nfo;
            my $fastaPos  = $nfo->[$mKeys->{fastaPos} ];
            my $contigPos = $nfo->[$mKeys->{contigPos}];
            my $fastaSeq  = $nfo->[$mKeys->{fastaSeq} ];
            my $contigSeq = $nfo->[$mKeys->{contigSeq}];
            my $mapTag    = $nfo->[$mKeys->{tag}      ];
            my $event     = $nfo->[$mKeys->{events}   ];
            my $nd        = $nfo->[$mKeys->{nd}       ];

			my $fPos;
			if ( $fastaPos eq "-1" )
			{
				$fPos         = $lastFastaPos;
			}
			else
			{
				$fPos         = $fastaPos;
				$lastFastaPos = $fastaPos;
			}


			next if (( ! defined $mapTag || ! $mapTag ) && ( ! $nd ) && ( ! $event));

			my $tabs = &parseMap($fPos, $mKeys, $nfo);

			print OUTMR "\t\t<pos id=\"$fPos\">\n";
			print OUTMC "\t\t<pos id=\"$contigPos\">\n";

			#print TAB "sequence\tstrand\tstart\tend\tunique name\tcommom name\tgene type\n";
			foreach my $tab (@$tabs)
			{
				next if ! defined $tab;
				my $s     = $tab->[0];
				my $e     = $tab->[1];
				my $t     = $tab->[2];
				my $d     = $tab->[3];
				my $tag   = $tab->[4];
				my $uName = "$t\_$s\_$e";
				die if ! exists    $keys{$tag};
				die if ! defined ${$keys{$tag}}[2];

				my $fh = ${$keys{$tag}[2]};
				print $fh "$contig\t+\t$s\t$e\t$uName\t$d\t$t\n";
			}

			foreach my $key (sort keys %$mKeys)
			{
				my $val = $nfo->[$mKeys->{$key}];

				if (defined $val )
				{
					if (ref($val) eq "SCALAR")
					{
						$val = $$val;
					}

					my $str = "\t\t\t<$key>$val</$key>\n";
					print OUTMR $str;
					print OUTMC $str;
				}
			}

			print OUTMR "\t\t</pos>\n";
			print OUTMC "\t\t</pos>\n";

		}
		print OUTMR "\t</table>\n";
		print OUTMC "\t</table>\n";
	}
	print OUTMR "</ndMap>\n";
	print OUTMC "</ndMap>\n";
	close OUTMR;
	close OUTMC;

	foreach my $tag (sort keys %keys)
	{
		print "CLOSING TAG $tag FILE\n";
		next if ! exists $keys{$tag};
		next if ! defined $keys{$tag}[2];
		my $fh = ${$keys{$tag}[2]};
		close $fh;
	}

	print "MAPPING EXPORTED\n";
}



sub parseMap
{
	my $pos  = $_[0];
	my $nfoK = $_[1];
	my $nfo  = $_[2];
	my $x    = 'x';
	my @out;
	my %lines;

	my $order = 0;
	my $start = $pos;


	if ( exists $nfo->[$nfoK->{nd}] )
	{
		my $end    = $nfo->[$nfoK->{nd_end}] - 1;

		die if ! defined $start;
		die if ! defined $end;
		my $localLane = $keys{nd}[0];
		#print "\t\t\t\t[ND S $start E $end LANE 0]\n";

		$out[$localLane][0] = $start;
		$out[$localLane][1] = $end;
		$out[$localLane][2] = "NO_DATA";
		$out[$localLane][3] = "NO_DATA :: N";
		$out[$localLane][4] = "nd";
	}

	if ( exists $nfo->[$nfoK->{events}] )
	{
		my $end              = $nfo->[$nfoK->{events_end}] - 1;
		my $desc             = $nfo->[$nfoK->{events_tags}];

		die if ! defined $start;
		die if ! defined $end;
		die if ! defined $desc;
		my $localLane = $keys{event}[0];
		#print "\t\t\t\t[EV S $start E $end LANE 1]\n";

		$out[$localLane][0] = $start;
		$out[$localLane][1] = $end;
		$out[$localLane][2] = "QUALITY";
		$out[$localLane][3] = "QUALITY :: " . $desc;
		$out[$localLane][4] = "event";
	}

	if ( exists $nfo->[$nfoK->{tag}] )
	{
		my $localLane = $keys{qual}[0];
		my $tag       = $nfo->[$nfoK->{tag}];

		if (ref($tag) eq "SCALAR")
		{
			$tag = $$tag;
		}

		   if ( $tag eq "snp" ) { $localLane = $keys{snp}[0]; }
		elsif ( $tag eq "ins" )	{ $localLane = $keys{ins}[0]; }
		elsif ( $tag eq "gap" )	{ $localLane = $keys{gap}[0]; }
		elsif ( $tag eq "del" )	{ $localLane = $keys{del}[0]; }
		else  { die "UNKNOWN TAG: \"$tag\"\n"};

		my $desc = $tag;
		my $end;
		#if ( exists $nfo->{tag_end} )	{ $end = $nfo->{tag_end};	}
		#else							{ $end = $start;			}

		if ( exists $nfo->[$nfoK->{tag_insertion_seq}] )
		{
			my $fseq = $nfo->[$nfoK->{fastaSeq}];
			if (ref($fseq) eq "SCALAR")
			{
				$fseq = $$fseq;
			}

			$end   = $start + length($nfo->[$nfoK->{tag_insertion_seq}]) - 1;
			$desc .= " [" . length($nfo->[$nfoK->{tag_insertion_seq}]) . "]";
		} else {
			$desc .= " [1]";
			$end   = $start;
		}

		die if ! defined $start;
		die if ! defined $end;

		#print "\t\t\t\t[TG S $start E $end TAG $tag LOCAL LANE $localLane]\n";

		$out[$localLane][0] = $start;
		$out[$localLane][1] = $end;
		$out[$localLane][2] = uc($tag);
		$out[$localLane][3] = $desc;
		$out[$localLane][4] = $tag;
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




sub exportRawDb
{
	my $mafdb      = $_[0];
	my $in         = $_[1];
	my $out        = $_[2];
	my $inputFasta = $_[3];
	my $fastaM     = $_[4];
	my $pk         = $_[5]; #primary key
	my $sk         = $_[6]; #secundary key - reference - IB
	my $readsKey   = $_[7];
	my $reserved   = $_[8];

	print "EXPORTING RAW DB\n";

	#<microarray id="Microarray_may_r265_data.csv.xml.blast" type="microarray">
	#	<table id="supercontig_1.03_of_Cryptococcus_gattii_CBS7750v4" type="chromossome">
	#		<pos id="713266">
	#			<id>1</id>


	open  OUT,  ">$out" or die "COULD NOT OPEN $out: $!";
	open  OUTS, ">$out.small.xml" or die "COULD NOT OPEN $out.small.xml: $!";
	print OUT   "<maf id=\"$in\" type=\"chromossome\" src=\"$src\">\n";
	print OUTS  "<maf id=\"$in\" type=\"chromossome\" src=\"$src\">\n";

	foreach my $contig ( sort keys %$mafdb )
	{
		my $nfo     = $mafdb->{$contig};
		print OUT  "\t<table id=\"$contig\" type=\"chromossome\">\n";
		print OUTS "\t<table id=\"$contig\" type=\"chromossome\">\n";
		print "\tCHROM $contig\n" if ($printExport);
		my $currChrom = $fastaM->readFasta($contig);

		foreach my $info ( sort keys %$nfo )
		{
			if ($info eq $readsKey)
			{
				my $reads = $nfo->{$info};
				foreach my $read (sort keys %$reads)
				{
					#print "\t\tREAD \"$read\"\n";
					my $keys = $reads->{$read};
					my $skOk = (( exists ${$keys}{$sk} ) && ($keys->{$sk}));
					print OUT  "\t\t", "<read id=\"$read\">\n";
					print OUTS "\t\t", "<read id=\"$read\">\n" if $skOk;

					foreach my $key (sort keys %$keys)
					{
						my $value = $keys->{$key};
						next if ( ! defined $value );
						chomp $value;

						#$value =~ s/\n/\:/g;
						#my $sValue = length $value > 80 ? substr($value, 0, 80) : $value;
						#print "\t\t\tINFO $info READ VALUE $read KEY $key VALUE $sValue\n";
						print OUT  "\t\t\t", "<$key>" , $value , "</$key>\n";
						print OUTS "\t\t\t", "<$key>" , $value , "</$key>\n"
							if $skOk;
					}

					print OUT  "\t\t", "</read>\n";

					if ($skOk)
					{
					#	my $aoParsed = &ao2gaps($keys->{AO}, $keys->{AT}, $currChrom);
					#	print OUT  "\t\t\t", "<aoParsed>"   , $aoParsed , "</aoParsed>\n";
					#	print OUTS "\t\t\t", "<aoParsed>"   , $aoParsed , "</aoParsed>\n";
						print OUTS "\t\t", "</read>\n";
					}
				}
			}
			elsif( ! exists ${$reserved}{$info} )
			{
				my $value = $nfo->{$info};
				chomp $value;
				#$value =~ s/\n/\:/g;
				#print "INFO $info VALUE: ",(length $value > 80 ? substr($value, 0, 80) : $value),"\n";

				print OUT  "\t\t", "<$info>"   , $value , "</$info>\n";
				print OUTS "\t\t", "<$info>"   , $value , "</$info>\n";
			}else {

			}
		}

		#print OUT  "\t\t", "<aoParsed>"   , $aoParsed , "</aoParsed>\n";
		#print OUTS "\t\t", "<aoParsed>"   , $aoParsed , "</aoParsed>\n";

		print OUT  "\t</table>\n";
		print OUTS "\t</table>\n";

	} # end foreach my contig
	print OUT  "</maf>\n";
	print OUTS "</maf>\n";
	close OUT;
	close OUTS;
	print "RAW DB EXPORTED\n";
}
















sub printStructure
{
	print `cat ./maf2nd.pl | perl -ne ' BEGIN {print "main\\n" }; if (/^(sub\\s+\\w+)/) { print \$1,"\\n" } elsif ( /(\\&\\w+)\\(/ ) { print "\\t", \$1,"\\n" }'`;
	#main
	#	&printStructure
	#	&readMaf
	#	&parseMafDb
	#	&exportDb
	#	&exportMaps
	#sub printStructure
	#sub exportMaps
	#sub exportDb
	#	&parseGap
	#sub parseGap
	#sub parseMafDb
	#	&parseAo
	#	&pairsToMapping
	#	&posToMappedPos
	#	&parseAo
	#	&posToMappedPos
	#	&posToMappedPos
	#sub posToMappedPos
	#sub pairsToMapping
	#sub parseAo
	#sub readMaf
	#	&storeValue
	#sub storeValue
	#	&parseRt
	#	&parseRt
	#sub parseRt

}



#CO string: contig name
#	CO starts a contig, the contig name behind is mandatory but can be any
#	string, including numbers
#AT Four integers: x1 y1 x2 y2
#	The AT (Assemble_To) line defines the placement of the read in the contig
#	and follows immediately the closing "ER" of a read so that parsers do not
#	need to perform time consuming string lookups. Every read in a contig has
#	exactly one AT line.
#	The interval [x2 y2] of the read (i.e., the unclipped data, also called the
#	'clear range') aligns with the interval [x1 y1] of the contig. If x1 > y1
#	(the contig positions), then the reverse complement of the read is aligned
#	to the contig. For the read positions, x2 is always < y2.
#AO four integers: x1 y1 x2 y2
#	AO stands for "Align to Original". The interval [x1 y1] in the read as
#	stored in the MAF file aligns with [x2 y2] in the original, unedited read
#	sequence. This allows to model insertions and deletions in the read and
#	still be able to find the correct position in the original, base-called
#	sequence data.
#	A read can have several AO lines which together define all the edits
#	performed to this read.
#	Assumed to be "1 x 1 x" if not present, where 'x' is the length of the
#	unclipped sequence.
#IB boolean (0 or 1): is backbone
#	Whether the read is a backbone. Reads used as reference (backbones) in
#	mapping assemblies get this attribute.
#RD string: readname
#	RD followed by the readname starts a read.
#LR integer: read length
#	The length of the read can be given optionally in LR. This is meant to help
#	the parser perform sanity checks and eventually pre-allocate memory for
#	sequence and quality.

#RD      supercontig_1.28_of_Cryptococcus_neoformans_Serotype_B
#LR      2023
#AO      1 801 1 801
#AO      803 2023 802 2022
#IB      1
#RD      HWUSI-EAS509_0001:2:14:8944:1772#0/2
#AO      1 102 1 102


#^CO|^AO|^IB|^LR|^RD"

1;
