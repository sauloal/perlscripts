#!/usr/bin/perl -w
use strict;
use warnings;
use fasta;

#SAULO AFLITOS
#ND2FLANK
#08/06/2010 @ 1300
#Licence: GPL

my $verbose   = 0;
my $fSize     = 250;

if ( @ARGV != 2 ) { &usage(); };
my $inputFA   = $ARGV[0];
my $inputPos  = $ARGV[1];


if (($inputFA) && ($inputPos)) #checks if all parameters are set
{
	if (( -f $inputFA ) && ( -f $inputPos ))
	{
		my $output;
		if ( ! $inputFA =~ /\/*([\w|\.]+)\.fasta/)
		{
			die "COULD NOT RETRIEVE THE NAME FROM $inputFA";
		}
		elsif ( $inputFA =~ /\/*([\w|\.]+)\.fasta/)
		{
			$output = $1;
		}
		else
		{
			print "INVALID FASTA FILE $inputFA";
			&usage();
		}


		print "  INPUT  FASTA: $inputFA\n";
		print "  INPUT  XML  : $inputPos\n";
		print "\n";

		&start($inputFA,$output);

	} # end if file INPUTFA exists
	else
	{
		my $exit;
		if ( ! -f $inputFA )	{ $exit .= "FILE $inputFA   DOESNT EXISTS\n";};
		if ( ! -f $inputPos )	{ $exit .= "FILE $inputPos  DOESNT EXISTS\n";};

		print $exit;
		exit 1;
	} # end else file INPUTFA exists
} # end if FA & XML were defined
else
{
	print "INVALID FASTA FILE $inputFA";
	&usage();
}


sub start
{
    my $inputFA = $_[0];
    my $output  = $_[1];

	my $outCsvFile  = $output . "flanking.csv";
	my $outStatFile = $output . "flanking.csv.stat.txt";
	$| = 1;

    print "  GENERATING CHROMOSSOMES TABLE...\n";
    my $fasta  = fasta->new($inputFA);
    print "  GENERATING CHROMOSSOMES TABLE...done\n";

	print "  LOADING POSITIONAL XML...\n";
	my $XMLpos = &loadXML($inputPos); #obtains the xml as hash
	print "  LOADING POSITIONAL XML...done\n";
	$| = 0;

	if ($verbose)
	{
		my $totalPos = scalar keys %$XMLpos;
		foreach my $chrom (sort keys %$XMLpos)
		{
			next if ( ! defined $XMLpos->{$chrom} );
			my $poses      = $XMLpos->{$chrom};
			my $totalPoses = scalar @{$poses};

			for (my $pos = 0; $pos < $totalPoses ; $pos++)
			{
				my $keys = $poses->[$pos];
				next if ( ! defined $keys );

				printf "\t\tCHROM \'%3d\' :: ",	$chrom;

				foreach my $key (sort keys %$keys)
				{
					printf "\'%-6s\' = \'%8d\'; ", uc($key), $keys->{$key};
				}
				print "\n";
			}
		}
	} # end if verbose

	my $stat = &print_fasta_general($XMLpos, $fasta, $outCsvFile);
	&print_stat($stat, $outStatFile);
}

sub print_stat
{
	my $stat    = $_[0];
	my $outFile = $_[1];
	open STAT, ">$outFile" or die "COULD NOT OPEN $outFile: $!";
	foreach my $chrom (sort keys %$stat)
	{
		my $length = $stat->{$chrom}{"length"};
		my $total  = $stat->{$chrom}{"total"};
		my $genLen = $stat->{$chrom}{"genLen"};
		my $out = "CHROMOSSOME ".$chrom." HAS ".$total.
		" GAPS WITH TOTAL COMBINED SIZE OF ".$length." bp OUT OF ITS ".
		$genLen." bp (".(int(($length/$genLen)*100))."%)\n";

		print "    ", $out;
		print STAT $out;
	}
	close STAT;
}


sub addStat
{
	my $stat   = $_[0];
	my $chrom  = $_[1];
	my $length = $_[2];
	my $genlen = $_[3];
	$stat->{$chrom}{"length"} += $length;
	$stat->{$chrom}{"total"}++;
	$stat->{$chrom}{"genLen"} = $genlen if ( ! defined $stat->{$chrom}{"genLen"});
}


sub print_fasta_general
{
	my $XMLpos  = $_[0];
	my $fasta   = $_[1];
	my $outFile = $_[2];
	my $ndCount = 1;
	my $genLeng = -1;
	my $header  = "\"ID\",\"CHROMOSSOME\",\"START POS\",\"END POS\",".
	"\"GAP LENGTH\",\"GAP SEQ\",\"FLANKING UPSTREAM\",".
	"\"FLANKING UPSTREAM REVERSE COMPLEMENT\",\"FLANKING DOWNTREAM\",".
	"\"FLANKING DOWNTREAM REVERSE COMPLEMENT\",\n";
	my %stat;


	print "    EXPORTING CSV...\n";
	open CSV, ">$outFile" or die "COULD NOT OPEN FILE $outFile: $!";
	print CSV $header;

	my $totalPos = scalar keys %$XMLpos;

	foreach my $chrom (sort keys %$XMLpos)
	{
		my $poses = $XMLpos->{$chrom};
		next if ( ! defined $poses );
		my $gene = $fasta->($chrom);
		$genLeng = scalar @$gene;

		die "NO GENE FOUND" if ( ! defined $gene );

		for (my $pos = 0; $pos < @$poses ; $pos++)
		{
			my $nfo    = $poses->[$pos];
			next if ( ! defined $nfo );

			my $start  = $nfo->{"start"};
			my $end    = $nfo->{"end"};
			my $length = $nfo->{"length"};
			my $strand = 1;

			#printf "\tEXPORTING START %8d END %8d LENGTH %8d (MAX )\n", $start, $end, $length, $genLeng;

			if ((defined $start) && (defined $end) && (defined $strand))
			{
				if ($start > $end)     { my $tmp = $end; $end = $start; $start = $tmp; };
				if ($end   > $genLeng) {die "ERROR IN FILE: GAP END BIGGER THAN SEQUENCE SIZE :: START $start END $end LENGTH $genLeng"; };

				my $fEnd   = ($end+$fSize-2);
				my $fStart = ($start-$fSize);

				if ($fEnd   >= $genLeng) { $fEnd   = $genLeng-1; };
				if ($fStart < 0     )    { $fStart = 0 };
				if ( ! ((defined $fEnd) && (defined $fStart) && (defined $genLeng))) { die "POSITIONS NOT DEFINED"; };

#				if ($fEnd <= $end)     { die "FINAL END WRONG:: END: $end FINAL END: $fEnd GEN LENGTH: $genLeng"; };
#				if ($fStart >= $start) { die "FINAL START WRONG:: END: $start FINAL END: $fStart GEN LENGTH: $genLeng"; };

				my $leng     = $end - $start + 1;
				my $seq      = join("",&arrayRefSlicer($gene, $start, $end  ));
				my $fSeqU    = join("",&arrayRefSlicer($gene, $fStart,  $start-1));
				my $fSeqD;

				my $seqLen   = length($seq);
				print "\tSTART $start END $end LENG $leng SEQLENG $seqLen\n";
				if ($seqLen != $leng) { die "ERROR IN LENGTH: SEQLEN $seqLen DIFF LENGTH $leng ($start-$end : $genLeng) \"$seq\""; };

				if ($fEnd <= $end) {
					$fSeqD   = $gene->[$end-1];
				}
				else
				{
					$fSeqD   = join("", &arrayRefSlicer($gene, $end-1, $fEnd));
					if ( ! defined $fSeqD )
					{
						die "ERROR SLICING:: END: $end FINAL END: $fEnd GEN LENGTH: $genLeng";
					};

					if ( length $fSeqD < ($fEnd - $end-1))
					{
						die "ERROR SIZE SLICING:: LENGTH SEQ ", length $fSeqD,
						" END: $end FINAL END: $fEnd GEN LENGTH: $genLeng";
					};
					if ( ! &arrayRefSlicer($gene, $end-1, $fEnd) )
					{
						die "ERROR ARRAY SLICING:: END: $end FINAL END: $fEnd GEN LENGTH: $genLeng";
					};
				}

				my $fSeqUR   = &revComp($fSeqU);
				my $fSeqDR   = &revComp($fSeqD);
				my $fSeqULen = length($fSeqU);
				my $fSeqDLen = length($fSeqD);

				&addStat(\%stat, $chrom, $seqLen, $genLeng);

				if ( ! ((defined $fSeqU) && (defined $fSeqUR) && (defined $fSeqD) && (defined $fSeqDR)))
				{
					die "SOMEONE IS NOT DEFINED: fSeqU $fSeqU fSeqUR $fSeqUR fSeqD $fSeqD fSeqDR $fSeqDR";
				};


#				my $out = $ndCount++ . ": TABLE " . $chromName . "(" . (scalar @gene) . "bp) POSITION " . $register . ":\n";
#				$out .= "\tSTART: " . $start . " END: " . $end . " LENGTH: " . $leng . " STRAND: " . $strand . "\n";
#				$out .= "\tSEQ: (" . $seqLen . "bp): " . $seq . "\n";
#				$out .= "\tFLANKING UPSTREAM:      (" . $fSeqULen . "bp): " . $fSeqU  . "\n";
#				$out .= "\tFLANKING UPSTREAM RC:   (" . $fSeqULen . "bp): " . $fSeqUR . "\n";
#				$out .= "\tFLANKING DOWNSTREAM:    (" . $fSeqDLen . "bp): " . $fSeqD  . "\n";
#				$out .= "\tFLANKING DOWNSTREAM RC: (" . $fSeqDLen . "bp): " . $fSeqDR . "\n\n";

				my $out = "\"" . $ndCount++ . "\",\"" . $chrom . "\",\"" . $start . "\",\"" . $end . "\",\"" . $seqLen . "\",\"" . $seq . "\",\"" . $fSeqU . "\",\"" . $fSeqUR . "\",\"" . $fSeqD . "\",\"" . $fSeqDR . "\",\n";
				print CSV $out;

#				if (($fSeqULen != $fSize) || ($fSeqDLen != $fSize)) { die "FLANKING REGIONS SIZE ERROR $fSize U: $fSeqULen D: $fSeqDLen"; };
				if ($strand eq "-") {die "minus" };
			} # end if defined
		} # end for my position
	} #end for my table
	close CSV;
	print "    EXPORTING CSV...done\n";
	return \%stat;
}

sub arrayRefSlicer
{
	my $ref   = $_[0];
	my $start = $_[1];
	my $end   = $_[2];
	my @array;

	for (my $a = $start; $a <= $end; $a++)
	{
		push(@array, $ref->[$a]);
	}

	return @array;
}

sub mergeHash
{
	my @hashes = @_;

	my %merged;
	foreach my $hashRef (@hashes)
	{
		while ((my $k, my $v) = each %{$hashRef})
		{
			if (exists $merged{$k})
			{
				while ((my $kk, my $vv) = each %{$v})
				{
					$merged{$k}{$kk} = $vv;
				}
			}
			else
			{
				$merged{$k} = $v;
			}
		}
	}

	return \%merged;
}

sub loadXML
{
	my $file = $_[0];
	open FILE, "<$file" or die "COULD NOT OPEN FILE $file: $!";

	my $row         = 0;
	my $table       = 0;
	my $tableName   = "";
	my $registerT   = 0;
	my $registerTot = 0;
	my %XMLhash;
	my $currId      = "";
	my $rootType;
	my $tableType;

	my $lineCount = 0;
	foreach my $line (<FILE>)
	{
		if (( ! $lineCount++ ) && ($line =~ /<(\w+)\s+id=\"(.+?)\".+?type=\"(.+?)\".*?>/))
		{
			$rootType = $3 ;
		}
		elsif ($line =~ /<table id=\"(.*?)\".*type=\"(.*?)\">/)
		{
			$table     = 1;
			$tableName = $1;
			$tableType = $2;
		}
		elsif ($line =~ /<\/table>/)
		{
			$table     = 0;
			$tableName = "";
# 			$register  = 0;
			$registerT++;
		}
		elsif ($line =~ /<pos\s+(id=\"(\d+)\")*>/)
		{
			if (defined $2)
			{
			  $currId = $2;
			}
			else
			{
			  die "NO CURR ID $line";
			}
			$row = 1;
		}
		elsif ($line =~ /<\/pos>/)
		{
			$row = 0;
			$registerTot++;
		}
		elsif ($row)
		{
			if ($line =~ /\<(\w+)\>(.+?)\<\/\1\>/)
			{
 				#print "$line\n";
				my $key   = $1;
				my $value = $2;
# 				print "$register => $key -> $value\n";
				if ($tableName)
				{
 					#print "\tTABLE \"$tableName\" ID \"$currId\" KEY \"$key\" VALUE \"$value\"\n";
# 					$XMLhash{$tableName}{$registre}{$key} = $value;
					$XMLhash{$tableName}[$currId]{$key} = $value;
					#print "{" . $chromos{$tableName} . "}{$currId}{$key} = $value;\n";
				}
				else
				{
					die "TABLE NAME NOT DEFINED IN XML $file\n";
				}
			} else {
				print "LINE \"$line\" DOESNT COMPLY. WHY?\n";
			}
		}
	}

	close FILE;
	print "  FILE $file PARSED: $registerTot REGISTERS RECOVERED FROM $registerT TABLES\n";
	print "  ROOT TYPE: \'$rootType\' TABLE TYPE: \'$tableType\'\n";
	return \%XMLhash;
}





sub revComp($)
{
    my $sequence = uc(shift);
    $sequence    = reverse($sequence);
    $sequence    =~ tr/ACTG/TGAC/;
    return $sequence;
}



sub usage
{
	print "USAGE: ",uc($0)," <INPUT FASTA.FASTA> <INPUT XMLPOS FILE>\n";
	print "E.G.: ./nd2flank.pl input.fasta XMLPos.xml \n";
	exit 1;
}

1;
