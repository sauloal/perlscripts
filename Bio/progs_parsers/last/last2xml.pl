#!/usr/bin/perl -w
use strict;
use warnings;
use Set::IntSpan;

my $epitope = "_sort_no_par.tab";
my $usage   = "USAGE: $0 <inputdir> <reference name> <query name>";
die "$usage" if (@ARGV < 3);

my $inputDir = $ARGV[0];
my $ref_base = $ARGV[1];
my $qry_base = $ARGV[2];
my $ouputDir = "$inputDir/xml";

my %nfo;

foreach my $st ($ref_base, $qry_base)
{
	foreach my $nd ($ref_base, $qry_base)
	{
		next if ($st eq $nd);
		my $name   = $st . "_" . $nd;
		my $folder = $inputDir."/".$st ."_" . $nd;
		my $file   = $inputDir."/".$st ."_" . $nd ."/" . $st ."_" . $nd . $epitope;

		$nfo{$st}{$nd}{nfo}{name}   = $name;
		$nfo{$st}{$nd}{nfo}{folder} = $folder;
		$nfo{$st}{$nd}{nfo}{file}   = $file;

		if ( ! -d $folder )
		{
			die "DIR $folder NOT FOUND\n$usage";
		} else {
			print "DIR  : $folder FOUND\n";
		}

		if ( ! -f $file)
		{
			die "FILE $file NOT FOUND\n$usage";
		} else {
			print "FILE : $file FOUND\n\n";
		}

	}
}




print "RUNNING $0 $inputDir $ref_base $qry_base\n";

mkdir $ouputDir if ( ! -d $ouputDir );


foreach my $st (sort keys %nfo)
{
	foreach my $nd (sort keys %{$nfo{$st}})
	{
		next if ($st eq $nd);
		print " "x2, "RUNNING $st AGAINST $nd\n";
		my $name   = $nfo{$st}{$nd}{nfo}{name};
		my $folder = $nfo{$st}{$nd}{nfo}{folder};
		my $file   = $nfo{$st}{$nd}{nfo}{file};

		#12925 supercontig_1.24_of_Cryptococcus_neoformans_Serotype_B     4 12966 + 94596 supercontig_1.24_of_Cryptococcus_gattii_Serotype_B_CBS7750v3    55 12966 + 94694 38,0:1,36,1:0,12891
		#25777 supercontig_1.24_of_Cryptococcus_neoformans_Serotype_B 13096 25830 + 94596 supercontig_1.24_of_Cryptococcus_gattii_Serotype_B_CBS7750v3 13148 25829 + 94694 14,0:1,3354,1:0,574,1:0,2888,1:0,1590,0:1,17407
		#22035 supercontig_1.24_of_Cryptococcus_neoformans_Serotype_B 41598 22109 + 94596 supercontig_1.24_of_Cryptococcus_gattii_Serotype_B_CBS7750v3 41649 22101 + 94694 10283,1:0,1722,5:0,1381,1:0,5868,2:0,2832,0:1,14
		# 6215 supercontig_1.24_of_Cryptococcus_neoformans_Serotype_B 64392  6254 + 94596 supercontig_1.24_of_Cryptococcus_gattii_Serotype_B_CBS7750v3 64435  6255 + 94694 1128,1:0,5054,0:1,48,0:1,23
		# 2837 supercontig_1.24_of_Cryptococcus_neoformans_Serotype_B 70892  2873 + 94596 supercontig_1.24_of_Cryptococcus_gattii_Serotype_B_CBS7750v3 70936  2873 + 94694 22,1:0,92,1:0,2703,0:1,10,0:1,44
		#20666 supercontig_1.24_of_Cryptococcus_neoformans_Serotype_B 73865 20731 + 94596 supercontig_1.24_of_Cryptococcus_gattii_Serotype_B_CBS7750v3 73909 20729 + 94694 19839,2:0,890

		#14252 supercontig_1.25_of_Cryptococcus_neoformans_Serotype_B     0 14490 + 34790 supercontig_1.25_of_Cryptococcus_gattii_Serotype_B_CBS7750v3     0 14466 + 34729 1184,3:0,62,1:0,600,1:0,28,1:0,61,1:0,6177,1:0,2871,2:0,413,1:0,62,2:0,18,1:0,538,1:0,23,1:0,13,2:0,29,3:0,101,0:1,516,1:0,1005,1:0,16,1:0,230,1:0,518
		#19650 supercontig_1.25_of_Cryptococcus_neoformans_Serotype_B 14590 20200 + 34790 supercontig_1.25_of_Cryptococcus_gattii_Serotype_B_CBS7750v3 14566 20146 + 34729 14,0:1,648,1:0,9,1:0,964,2:0,3811,1:0,17,1:0,3059,1:0,21,1:0,62,1:0,2172,1:0,3404,1:0,60,1:0,7,1:0,42,1:0,101,1:0,27,1:0,34,1:0,309,2:0,40,1:0,6,2:0,16,1:0,9,1:0,23,3:0,43,1:0,79,1:0,7,3:0,33,1:0,7,1:0,6,1:0,11,2:0,16,1:0,82,1:0,80,1:0,9,1:0,13,1:0,4,1:0,25,1:0,295,1:0,119,1:0,655,1:0,73,1:0,2318,1:0,128,1:0,304,1:0,319,1:0,328,2:0,141,1:0,195

		#the sequence name, the start position
		#of the alignment, the number of nucleotides in the alignment, the
		#strand, the total size of the sequence, and the aligned nucleotides.
		#If the alignment starts at the beginning of the sequence, the start
		#position is zero.  If the strand is "-", the start position is as if
		#we had used the reverse-complemented sequence.  The line starting with
		#"p" contains the probability of each pair of aligned letters.  The
		#same alignment in tabular format looks like this::
		#
		#  15 chr3L 19433515 23 + 24543557 H04BA01F1907 2 21 + 25 17,2:0,4
		#
		#The final column shows the sizes and offsets of gapless blocks in the
		#alignment.  In this case, we have a block of size 17, then an offset
		#of size 2 in the upper sequence and 0 in the lower sequence, then a
		#block of size 4.

		open FH, "<$file" or die "COULD NOT OPEN FILE $file $!";
		while (my $line = <FH>)
		{
			chomp $line;
			#20666 supercontig_1.24_of_Cryptococcus_neoformans_Serotype_B 73865 20731 +	94596	supercontig_1.24_of_Cryptococcus_gattii_Serotype_B_CBS7750v3 73909 20729 + 94694 19839,2:0,890
			#    1 2                                                      3     4     5 6       7                                                            8     9    10 11    12
			#    | |_(\S+)_________         ________________________(\d+)_|     |     | |       |                                                            |     |     | |     |
			#    |_(\d+)___        |       |        ______________________(\d+)_|     | |       |                                                            |     |     | |     |
			#              |       |       |       |       _________________([\+|\-])_| |       |                                                            |     |     | |     |
			#              |       |       |       |      |            ___________(\d+)_|       |                                                            |     |     | |     |
			#              |       |       |       |      |           |         __________(\S+)_|                                                            |     |     | |     |
			#              |       |       |       |      |           |        |       ________________________________________________________________(\d+)_|     |     | |     |
			#              |       |       |       |      |           |        |      |       _______________________________________________________________(\d+)_|     | |     |
			#              |       |       |       |      |           |        |      |       |       _________________________________________________________([\+|\-])_| |     |
			#              |       |       |       |      |           |        |      |       |       |           ___________________________________________________(\d+)_|     |
			#              |       |       |       |      |           |        |      |       |       |           |       _________________________________________________(\S+)_|
			#              |       |       |       |      |           |        |      |       |       |           |       |
			#              |       |       |       |      |           |        |      |       |       |           |       |
			if ($line =~ /(\d+)\s+(\S+)\s+(\d+)\s+(\d+)\s+([\+|\-])\s+(\d+)\s+(\S+)\s+(\d+)\s+(\d+)\s+([\+|\-])\s+(\d+)\s+(\S+)/)
			{
				my $score     = $1;

				my $refChrom  = $2;
				my $refStart  = $3;
				my $refAlgLen = $4;
				my $refEnd    = $refStart + $refAlgLen - 1;
				my $refFrame  = $5;
				my $refLeng   = $6;

				my $qryChrom  = $7;
				my $qryStart  = $8;
				my $qryAlgLen = $9;
				my $qryEnd    = $qryStart + $qryAlgLen - 1;
				my $qryFrame  = $10;
				my $qryLeng   = $11;

				my $gaps      = $12;

				#print $line, "\n";
					#$gaps{$inFile} = Set::IntSpan->new();
					#$gaps{$inFile}->insert($1);
					#$gaps->{$chrom}->run_list,"\n";

				$nfo{$st}{$nd}{chrom}{$refChrom}{length} = $refLeng;
				$nfo{$nd}{$st}{chrom}{$qryChrom}{length} = $qryLeng;

				if ( ! exists ${$nfo{$st}{$nd}{chrom}{$refChrom}}{span} )
				{
					print " "x4, "ANALIZING $st $nd $refChrom\n";
					$nfo{$st}{$nd}{chrom}{$refChrom}{span} = Set::IntSpan->new();
				}

				if ( ! exists ${$nfo{$nd}{$st}{chrom}{$qryChrom}}{span} )
				{
					$nfo{$nd}{$st}{chrom}{$qryChrom}{span}  = Set::IntSpan->new();
				}

				#push(@{$nfo{$st}{$nd}{chrom}{$refChrom}{microGap}}, $gapNfo->{ref});
				#push(@{$nfo{$nd}{$st}{chrom}{$qryChrom}{microGap}}, $gapNfo->{qry});

				my $posNfoRef = \$nfo{$st}{$nd}{chrom}{$refChrom}{span};
				my $posNfoQry = \$nfo{$nd}{$st}{chrom}{$qryChrom}{span};

				map { $$posNfoRef->insert($_) } ($refStart..$refEnd);
				map { $$posNfoQry->insert($_) } ($qryStart..$qryEnd);

				#print "$st $nd $refChrom SO FAR: ", $$posNfoRef->run_list, "\n";
				#print "$nd $st $qryChrom SO FAR: ", $$posNfoQry->run_list, "\n";
				my $gapNfo    = &parseGaps($gaps, $refStart, $qryStart, $refAlgLen, $qryAlgLen, $posNfoRef, $posNfoQry);
			} else {
				die "ERROR PARSING LINE\n$line\n";
			}
		}
		close FH;
	}
}



my %result;
foreach my $pair ([$ref_base, $qry_base], [$qry_base,$ref_base])
{
	my $st = $pair->[0];
	my $nd = $pair->[1];
	my $nfoRef = $nfo{$st}{$nd};

	print " "x2, "FILE :: $st\n";
	foreach my $key ( "nfo", "chrom" )
	{
		my $sec = $nfoRef->{$key};
		print " "x4 . "$key\n";
		foreach my $sKey ( sort keys %{$sec} )
		{
			if ($key eq "chrom")
			{
				print " "x6 . "CHROM :: $sKey\n";
				my $chromSize  = $sec->{$sKey}{length};
				my $chromFils  = \$sec->{$sKey}{span};
				my $chromGaps  = holes $$chromFils;
				my $filsL      = $$chromFils->run_list;
				my $gapsL      = $chromGaps->run_list;

				print " "x8 . "SIZE :: $chromSize\n";
				print " "x8 . "FILS :: ", $filsL , "\n";
				print " "x8 . "GAPS :: ", $gapsL , "\n";
				$result{$st}{$sKey}{size} = $chromSize;
				$result{$st}{$sKey}{fils} = $filsL;
				$result{$st}{$sKey}{gaps} = $gapsL;

			} else {
				printf " "x4 . "%-8s :: %s\n", $sKey, $sec->{$sKey};
			}
		}
	}
}

&makeReport(\%result);

sub makeReport
{
	open REP, ">gaps.log" or die "COULD NOT OPEN gaps.log: $!";
	my $hash = $_[0];
	print     "FILE\tCHROM\tCHROMSIZE\tLENGTH\tSTART\tEND\n";
	print REP "FILE\tCHROM\tCHROMSIZE\tLENGTH\tSTART\tEND\n";
	foreach my $file (sort keys %$hash)
	{
		my $chroms = $hash->{$file};
		foreach my $chrom (sort keys %$chroms)
		{
			my $chrNfo = $chroms->{$chrom};
			my $size   = $chrNfo->{size};
			my $fils   = $chrNfo->{fils};
			my $gaps   = $chrNfo->{gaps};

			my $poses = &parseIntRanges($gaps);

			foreach my $pos (@$poses)
			{
				my $l = $pos->[0];
				my $s = $pos->[1];
				my $e = $pos->[2];
				print     "$file\t$chrom\t$size\t$l\t$s\t$e\n";
				print REP "$file\t$chrom\t$size\t$l\t$s\t$e\n";
			}
		}
	}
	close REP;
}


sub parseIntRanges
{
	my $gapsStr = $_[0];
	my @gaps = split(",", $gapsStr);
	my @gOut;

	for (my $g = 0; $g < @gaps; $g++)
	{
		my $gp = $gaps[$g];
		if ( $gp =~ /(\d+)-(\d+)/ )
		{
			push(@gOut, [($2 - $1), $1, $2])
		} else {
			push(@gOut, [1, $gp, $gp])
		}
	}

	return \@gOut;
}


sub parseGaps
{
	my $gapStr    = $_[0];
	my $refStart  = $_[1];
	my $qryStart  = $_[2];
	my $refLen    = $_[3];
	my $qryLen    = $_[4];
	my $posNfoRef = $_[5];
	my $posNfoQry = $_[6];

	# 2837 supercontig_1.24_of_Cryptococcus_neoformans_Serotype_B 70892  2873 + 94596 supercontig_1.24_of_Cryptococcus_gattii_Serotype_B_CBS7750v3 70936  2873 + 94694 22,1:0,92,1:0,2703,0:1,10,0:1,44
	#20666 supercontig_1.24_of_Cryptococcus_neoformans_Serotype_B 73865 20731 + 94596 supercontig_1.24_of_Cryptococcus_gattii_Serotype_B_CBS7750v3 73909 20729 + 94694 19839,2:0,890

	#14252 supercontig_1.25_of_Cryptococcus_neoformans_Serotype_B     0 14490 + 34790 supercontig_1.25_of_Cryptococcus_gattii_Serotype_B_CBS7750v3     0 14466 + 34729 1184,3:0,62,1:0,600,1:0,28,1:0,61,1:0,6177,1:0,2871,2:0,413,1:0,62,2:0,18,1:0,538,1:0,23,1:0,13,2:0,29,3:0,101,0:1,516,1:0,1005,1:0,16,1:0,230,1:0,518
	#19650 supercontig_1.25_of_Cryptococcus_neoformans_Serotype_B 14590 20200 + 34790 supercontig_1.25_of_Cryptococcus_gattii_Serotype_B_CBS7750v3 14566 20146 + 34729 14,0:1,648,1:0,9,1:0,964,2:0,3811,1:0,17,1:0,3059,1:0,21,1:0,62,1:0,2172,1:0,3404,1:0,60,1:0,7,1:0,42,1:0,101,1:0,27,1:0,34,1:0,309,2:0,40,1:0,6,2:0,16,1:0,9,1:0,23,3:0,43,1:0,79,1:0,7,3:0,33,1:0,7,1:0,6,1:0,11,2:0,16,1:0,82,1:0,80,1:0,9,1:0,13,1:0,4,1:0,25,1:0,295,1:0,119,1:0,655,1:0,73,1:0,2318,1:0,128,1:0,304,1:0,319,1:0,328,2:0,141,1:0,195

	#  15 chr3L 19433515 23 + 24543557 H04BA01F1907 2 21 + 25 17,2:0,4
	#
	#The final column shows the sizes and offsets of gapless blocks in the
	#alignment.  In this case, we have a block of size 17, then an offset
	#of size 2 in the upper sequence and 0 in the lower sequence, then a
	#block of size 4.
	my @gapArr = split(",", $gapStr);
	my $refSum = 0;
	my $qrySum = 0;
	#my %gaps;

	for (my $g = 0; $g < @gapArr; $g++)
	{
		my $nfo = $gapArr[$g];
		if ( $nfo =~ /(\d+)\:(\d+)/ )
		{
			#print "\tGAP  : $nfo\n";
			my $ref = $1;
			my $qry = $2;
			#print "\tGAPR : $ref\n";
			#print "\tGAPQ : $qry\n";
			my $refAbsStart = ($refStart+$refSum);
			my $refAbsEnd   = ($refStart+$refSum+$ref);
			my $qryAbsStart = ($qryStart+$qrySum);
			my $qryAbsEnd   = ($qryStart+$qrySum+$qry);
			#push(@{$gaps{ref}}, $refAbsStart."-".$refAbsEnd) if ($refAbsStart != $refAbsEnd);
			#push(@{$gaps{qry}}, $qryAbsStart."-".$qryAbsEnd) if ($qryAbsStart != $qryAbsEnd);

			map { $$posNfoRef->remove($_) } ($refAbsStart..$refAbsEnd);
			map { $$posNfoQry->remove($_) } ($qryAbsStart..$qryAbsEnd);

			$refSum += $ref;
			$qrySum += $qry;
		} else {
			#print "\tBLOCK: $nfo\n";
			$refSum += $nfo;
			$qrySum += $nfo;
		}
	}

	if ($refSum != $refLen) { die "SUM OF BLOCKS AND GAPS ($refSum) NOT EQUAL TO ALIGNMENT SIZE ($refLen)" };
	if ($qrySum != $qryLen) { die "SUM OF BLOCKS AND GAPS ($qrySum) NOT EQUAL TO ALIGNMENT SIZE ($qryLen)" };

	#print "REFSUM: $refSum\n";
	#print "QRYSUM: $qrySum\n";



	#foreach my $seq ("ref", "qry")
	#{
	#	next if ( ! exists  $gaps{$seq}    );
	#	my $gapsPos = $gaps{$seq};
	#	next if ( ! $gapsPos );
	#	for (my $g = 0; $g < @$gapsPos; $g++)
	#	{
	#		#print "\t", uc($seq), "\t", $gapsPos->[$g], "\n";
	#	}
	#}

	#return \%gaps;
}

1;
