#!/usr/bin/perl -w
use strict;
my $nameTag = "DeNovo2";
use Set::IntSpan::Fast;
use Set::IntSpan;
use Data::Dumper;

my $epitope = "";
my $usage   = "USAGE: $0 <maf file name> [<epitope>]";
#./DeNovolast2xml.pl denovo/r265_vs_denovo.maf

my $parseMicroGaps = 1;
my $minMicroGap    = 10;

die "$usage" if (@ARGV < 1);

my $filePath = $ARGV[0];
my $inputDir = substr($filePath, 0, rindex($filePath, "/")) || ".";
my $fileName = substr($filePath, rindex($filePath, "/")+1);
my $ouputDir = "$inputDir/xml";

if ( defined $ARGV[1] )
{
	$epitope = $ARGV[1];
	#$epitope = ".sort.maf.nopar.maf.tab";
}

my %nfo;

my $name   = substr($fileName, 0, index($fileName, "."));
my $folder = $inputDir;
my $file   = $inputDir."/". $fileName . $epitope;

$nfo{nfo}{name}   = $name;
$nfo{nfo}{folder} = $inputDir;
$nfo{nfo}{file}   = $file;

if ( ! -d $folder ) { die "DIR $folder NOT FOUND\n$usage"; }
else                { print "DIR  : $folder FOUND\n";      }

if ( ! -f $file)    { die "FILE $file NOT FOUND\n$usage";  }
else                { print "FILE : $file FOUND\n\n";      }


print "RUNNING $0 $filePath [FOLDER: $inputDir FILE: $fileName NAME: $name OUT DIR: $ouputDir]\n";
mkdir $ouputDir if ( ! -d $ouputDir );


my ($dupPos, $dupSca) = &loadFile($file, \%nfo);
my $results  = &loadResults(\%nfo);
my ($dupPosRange, $nonPosRange) = &findDuplicated($dupPos);
my $dupScaLC = &findDuplicated($dupSca);
&makeGapReport($results, $inputDir);
&makeLCReport($dupPosRange, "dup", $inputDir);
&makeLCReport($nonPosRange, "non", $inputDir);
#&makeLCReport($dupScaLC, "lc", $inputDir);
#&genAssembly($dupPos);


sub genAssembly
{
	my $dups = $_[0];

	#push(@{$dupPos{$refChrom}[$_]}, $qryRef) } ($refStart..$refEnd);
	#$dupPos{$refChrom}[pos][n] = [$qryChrom, $qryStart, $qryEnd, $refStart, $refEnd, $qryAlgLen, $qryFrame, $qryLeng, $gaps];

	foreach my $chrom (sort keys %$dups)
	{
		#print "DUP :: CHROM :: $chrom\n";
		my $array = $dups->{$chrom};

		for (my $pos = 0; $pos < @$array; $pos++)
		{
			#print "  DUP :: CHROM :: $chrom :: POS :: $pos\n";
			my $lArray = $array->[$pos];
			if ( ! defined $lArray )
			{
				#print "    DUP :: CHROM :: $chrom :: POS :: $pos :: 0\n";
			} else {
				my $count = @$lArray;

				#print "    DUP :: CHROM :: $chrom :: POS :: $pos :: $count\n";
				if ( $count > 1 )
				{
					print "    DUP :: CHROM :: $chrom :: POS :: $pos :: $count\n";
				}
				else {
					#print "    UNI :: CHROM :: $chrom :: POS :: $pos :: 1\n";
				}
			}
		}
	}
}

sub findDuplicated
{
	my $dups = $_[0];
	my %dup;
	my %non;

	#push(@{$dupPos{$refChrom}[$_]}, $qryRef) } ($refStart..$refEnd);
	#$dupPos{$refChrom}[pos][n] = qryref

	foreach my $chrom (sort keys %$dups)
	{
		#print "DUP :: KEY :: $key\n";
		my $array = $dups->{$chrom};

		for (my $pos = 0; $pos < @$array; $pos++)
		{
			#print "  DUP :: KEY :: $key :: POS :: $pos\n";
			my $lArray = $array->[$pos];
			if ( ! defined $lArray )
			{
				#print "    DUP :: KEY :: $chrom :: POS :: $pos :: 0\n";
				$non{$chrom} = Set::IntSpan::Fast->new() if ( ! exists $non{$chrom} );
				$non{$chrom}->add($pos);
				next;
			}
			my $count = @$lArray;

			#print "    DUP :: KEY :: $key :: POS :: $pos :: $count\n";
			if ( $count > 1 )
			{
				#print "    DUP :: KEY :: $chrom :: POS :: $pos :: $count\n";
				$dup{$chrom} = Set::IntSpan::Fast->new() if ( ! exists $dup{$chrom} );
				$dup{$chrom}->add($pos);

				if (0)
				{
					print "CHROMOSSOME $chrom POSITION $pos HAS $count COVERAGE\n";
					map {
							printf "\tMATCH %-12s FROM [ START %7d END %7d ] TO [ START %7d END %7d ]\n", @$_;
						} @$lArray;
				}
			}
			else {
				#print "    DUP :: KEY :: $key :: A :: $a :: 1\n";
			}
		}

		if ( exists $dup{$chrom} )
		{
			$dup{$chrom} = $dup{$chrom}->as_string();
			print "DUP :: CHROMOSSOME $chrom HAS DUP AT:", $dup{$chrom}, "\n" ;
		}

		if ( exists $non{$chrom} )
		{
			$non{$chrom} = $non{$chrom}->as_string();
			print "NON :: CHROMOSSOME $chrom HAS NON AT:", $non{$chrom}, "\n" ;
		}
	}

	return (\%dup, \%non);
}







sub loadFile
{
	my $inFile = $_[0];
	my $info   = $_[1];
	my %dupPos;
	my %dupSca;

	open FH, "<$inFile" or die "COULD NOT OPEN FILE $inFile $!";
	while (my $line = <FH>)
	{
		chomp $line;
		#20666 supercontig_1.24_of_Cryptococcus_neoformans_Serotype_B 73865 20731 +	94596	supercontig_1.24_of_Cryptococcus_gattii_Serotype_B_CBS7750v3 73909 20729 + 94694 19839,2:0,890
		#18039 supercontig_1.01_of_Cryptococcus_neoformans_Serotype_B 760   18105 + 1510064 scaffold250                                                  0     18099 - 78247 13308,0:1,863,2:0,300,1:0,165,1:0,2092,3:0,1370
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

			if (( ! exists ${$info}{chrom} ) || ( ! exists ${$info->{chrom}}{$refChrom} ))
			{
				$info->{chrom}{$refChrom} = {};
			}
			my $lRefChrom = $info->{chrom}{$refChrom};
			$lRefChrom->{length} = $refLeng;
			#$nfo{chrom}{$qryChrom}{length} = $qryLeng;

			if ( ! exists ${$lRefChrom}{span} )
			{
				print " "x4, "ANALIZING $refChrom\n";
				$lRefChrom->{span} = Set::IntSpan::Fast->new();
			}

			#if ( ! exists ${$nfo{chrom}{$qryChrom}}{span} )
			#{
			#	$nfo{chrom}{$qryChrom}{span}  = Set::IntSpan->new();
			#}

			my $posNfoRef = \$lRefChrom->{span};
			#my $posNfoRef = \$info->{chrom}{$refChrom}{span};
			#my $posNfoQry = \$nfo{chrom}{$qryChrom}{span};

			#map { $$posNfoRef->add($_) } ($refStart..$refEnd);
			$$posNfoRef->add_range($refStart, $refEnd);
			#map { $$posNfoQry->insert($_) } ($qryStart..$qryEnd);


			#my %dupArray;
			#my %usedScaffold;
			my $refRef = [$refChrom, $refStart, $refEnd, $qryStart, $qryEnd];
			my $qryRef = [$qryChrom, $qryStart, $qryEnd, $refStart, $refEnd, $qryAlgLen, $qryFrame, $qryLeng, $gaps];

			map { push(@{$dupPos{$refChrom}[$_]}, $qryRef) } ($refStart..$refEnd);
			map { push(@{$dupSca{$qryChrom}[$_]}, $refRef) } ($qryStart..$qryEnd);

			#print "$st $nd $refChrom SO FAR: ", $$posNfoRef->run_list, "\n";
			#print "$nd $st $qryChrom SO FAR: ", $$posNfoQry->run_list, "\n";
			#my $gapNfo    = &parseGaps($gaps, $refStart, $qryStart, $refAlgLen, $qryAlgLen, $posNfoRef, $posNfoQry);
			&parseGaps($gaps, $refStart, $refAlgLen, $posNfoRef) if ( $parseMicroGaps );
			#my $gapNfo    = &parseGaps($gaps, $qryStart, $qryAlgLen, $posNfoQry);

			if ( 0 )
			{
				$Data::Dumper::Indent    = 1;
				$Data::Dumper::Purity    = 1;
				$Data::Dumper::Quotekeys = 1;
				print Dumper \%dupPos;
				exit;
			}
			#push(@{$nfo{chrom}{$refChrom}{microGap}}, $gapNfo->{ref});
			#push(@{$nfo{chrom}{$qryChrom}{microGap}}, $gapNfo->{qry});

		} else {
			die "ERROR PARSING LINE\n$line\n";
		}
	}
	close FH;

	return (\%dupPos, \%dupSca);
}


sub loadResults
{
	my $nfo = $_[0];
	my %res;

	foreach my $key ( "nfo", "chrom" )
	{
		my $sec = $nfo->{$key};
		print " "x4 . "$key\n";
		foreach my $sKey ( sort keys %$sec )
		{
			if ($key eq "chrom")
			{
				print " "x6 . "CHROM :: $sKey\n";
				my $chromSize  = $sec->{$sKey}{length};
				my $chromFils  = \$sec->{$sKey}{span};
				my $filsL      = $$chromFils->as_string();
				my $chromGaps  = &holes($filsL, $chromSize);
				my $gapsL      = $chromGaps;

				print " "x8 . "SIZE :: $chromSize\n";
				#print " "x8 . "FILS :: ", $filsL , "\n";
				#print " "x8 . "GAPS :: ", $gapsL , "\n";
				$res{$sKey}{size} = $chromSize;
				$res{$sKey}{fils} = $filsL;
				$res{$sKey}{gaps} = $gapsL;
			} else {
				printf " "x4 . "%-8s :: %s\n", $sKey, $sec->{$sKey};
			}
		}
	}
	return \%res;
}





sub holes
{
	my $fillStr   = $_[0];
	my $chromSize = $_[1];

	my @spaces = split(",", $fillStr);
	my @gaps;

	my $lastEnd   = 0;
	for ( my $p = 0; $p < @spaces; $p++ )
	{
		my $space = $spaces[$p];

		#print "\tSPACE $space\n";

		if ( $space =~ /-/ )
		{
			my ($s, $e) = split("-", $space);
			if ( ( $s - $lastEnd ) > 0 )
			{
				push(@gaps, [$lastEnd+1,$s-1]);
				#print "\t\tGAP : ",$lastEnd+1,"-",$s-1,"\n";
			}

			#if ($p == 0 && $s > 1)
			#{
			#	push(@gaps, [1,$s-1]);
			#	print "\t\tGAP: ",1,"-",$s-1,"\n";
			#}

			$lastEnd = $e;
		} else {
			if ( ($lastEnd - $space) > 0 )
			{
				push(@gaps, [$lastEnd+1,$space-1]);
				#print "\t\tGAP : ",$lastEnd+1,"-",$space-1,"\n";
			}

			if ($p == 0 && $space > 1)
			{
				push(@gaps, [1,$space-1]);
				#print "\t\tGAP : ",1,"-",$space-1,"\n";
			}

			$lastEnd = $space;
		}


		if ( ($p == @spaces-1) && ( $lastEnd < $chromSize ) )
		{
			push(@gaps, [$lastEnd+1,$chromSize]);
			#print "\t\tLE  : ",$lastEnd,"\n";
			#print "\t\tCHRO: ",$chromSize,"\n";
			#print "\t\tGAPF: ",$lastEnd+1,"-",$chromSize,"\n";
		}
	}

	my $gapStr;
	foreach my $gap (@gaps)
	{
		my $s = $gap->[0];
		my $e = $gap->[1];

		my $str = $s != $e ? "$s-$e" : $s;

		$gapStr .= ( $gapStr ? "," : "") . $str;
	}

	return $gapStr;
}

sub makeGapReport
{
	my $chroms    = $_[0];
	my $outFolder = $_[1];
	my %total;

	open REP, ">$file.gaps.log" or die "COULD NOT OPEN $file.gaps.log: $!";
	open TAB, ">$file.gaps.tab" or die "COULD NOT OPEN $file.gaps.tab: $!";
	print     "CREATING GAP REPORT :: CHROM $chroms OUTFOLDER $outFolder FILE $file\n";

	print REP "FILE\tCHROM\tCHROMSIZE\tLENGTH\tSTART\tEND\n";
	print TAB "#CHROM\tFRAME\tSTART\tEND\tUNIQ NAME\tNAME\tTYPE\n";
	#supercontig_1.25_of_Cryptococcus_neoformans_Serotype_B	+	611	667	53437GE_CneoSBc25_30001_34790_s_PSO-60-0314|DIFF:-0.77|R265:-0.25|CBS7750:-1.02|WM276:-0.28|CORR:-0.19|ANNO:UNKNOWN.7008.7008.supercontig_1.25_of_Cryptococcus_neoformans_Serotype_B.611_667_3e-14	53437GE_CneoSBc25_30001_34790_s_PSO-60-0314|DIFF:-0.77|R265:-0.25|CBS7750:-1.02|WM276:-0.28|CORR:-0.19|ANNO:UNKNOWN.7008.7008	rna
	#supercontig_1.25_of_Cryptococcus_neoformans_Serotype_B	-	1022	963	53397GE_CneoSBc25_1_6000_s_RC-60-4979|DIFF:-0.51|R265:-0.18|CBS7750:-0.69|WM276:-0.71|CORR:-0.21|ANNO:NAD4.36736.supercontig_1.25_of_Cryptococcus_neoformans_Serotype_B.1022_963_3e-14	53397GE_CneoSBc25_1_6000_s_RC-60-4979|DIFF:-0.51|R265:-0.18|CBS7750:-0.69|WM276:-0.71|CORR:-0.21|ANNO:NAD4.36736	rna

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
			if ( (defined $s) && (defined $e) && ($s ne "") && ($e ne "") && ($s ne "-") && ($e ne "-") )
			{
				my $leng  = ($e > $s ? ($e - $s) : ($s - $e));
				if ( $leng )
				{
					my $uName = "$nameTag\_GAP_$s\_$e\_$leng";
					#print     "$file\t$chrom\t$size\t$l\t$s\t$e\t$leng\n";
					print REP "$file\t$chrom\t$size\t$l\t$s\t$e\t$leng\n";
					print TAB "$chrom\t+\t$s\t$e\t$uName\t$uName\trna\n";
					$total{$chrom} += $leng;
				}
			}
		}
	}

	close REP;
	close TAB;

	print "\n" x3;
	my $totalVal;
	foreach my $chrom (sort keys %total)
	{
		my $val    = $total{$chrom};
		$totalVal += $val;
		my $num    = &getNumber($val/1000, 3, 2);

		#printf "\tCHROM %s HAS GAPS TOTALIZING: %6dbp (%3d.%-2dkb)\n", $chrom, $total{$chrom}, int($total{$chrom}/1000), ((($total{$chrom}/1000)-int($total{$chrom}/1000))*100);
		printf "\tGAP :: CHROM %s HAS GAPS TOTALIZING: %8dbp [ %skb ]\n", $chrom, $total{$chrom}, $num;
	}
	printf "\tGAP :: GENOME HAS GAPS TOTALIZING: %8dbp [ %skb | %s mb ]\n", $totalVal, &getNumber($totalVal/1_000, 3, 2), &getNumber($totalVal/1_000_000, 3, 2);

}


sub makeLCReport
{
	my $chroms    = $_[0];
	my $name      = $_[1];
	my $outFolder = $_[2];
	my %total;

	open REP, ">$file.$name.log" or die "COULD NOT OPEN $file.$name.log: $!";
	open TAB, ">$file.$name.tab" or die "COULD NOT OPEN $file.$name.tab: $!";
	#print     "FILE\tCHROM\tCHROMSIZE\tLENGTH\tSTART\tEND\n";

	print REP "FILE\tCHROM\tCHROMSIZE\tLENGTH\tSTART\tEND\n";
	print TAB "#CHROM\tFRAME\tSTART\tEND\tUNIQ NAME\tNAME\tTYPE\n";
	#supercontig_1.25_of_Cryptococcus_neoformans_Serotype_B	+	611	667	53437GE_CneoSBc25_30001_34790_s_PSO-60-0314|DIFF:-0.77|R265:-0.25|CBS7750:-1.02|WM276:-0.28|CORR:-0.19|ANNO:UNKNOWN.7008.7008.supercontig_1.25_of_Cryptococcus_neoformans_Serotype_B.611_667_3e-14	53437GE_CneoSBc25_30001_34790_s_PSO-60-0314|DIFF:-0.77|R265:-0.25|CBS7750:-1.02|WM276:-0.28|CORR:-0.19|ANNO:UNKNOWN.7008.7008	rna
	#supercontig_1.25_of_Cryptococcus_neoformans_Serotype_B	-	1022	963	53397GE_CneoSBc25_1_6000_s_RC-60-4979|DIFF:-0.51|R265:-0.18|CBS7750:-0.69|WM276:-0.71|CORR:-0.21|ANNO:NAD4.36736.supercontig_1.25_of_Cryptococcus_neoformans_Serotype_B.1022_963_3e-14	53397GE_CneoSBc25_1_6000_s_RC-60-4979|DIFF:-0.51|R265:-0.18|CBS7750:-0.69|WM276:-0.71|CORR:-0.21|ANNO:NAD4.36736	rna

	foreach my $chrom (sort keys %$chroms)
	{
		my $lcs  = $chroms->{$chrom};
		my $poses = &parseIntRanges($lcs);

		foreach my $pos (@$poses)
		{
			my $l = $pos->[0];
			my $s = $pos->[1];
			my $e = $pos->[2];
			if ( (defined $s) && (defined $e) && ($s ne "") && ($e ne "") && ($s ne "-") && ($e ne "-") )
			{
				if ( $l )
				{
					my $uName = "$nameTag\_".uc($name)."_$s\_$e\_$l";
					#print     "$file\t$chrom\t$size\t$l\t$s\t$e\t$leng\n";
					print REP "$file\t$chrom\t$l\t$s\t$e\t$l\n";
					print TAB "$chrom\t+\t$s\t$e\t$uName\t$uName\trna\n";
					$total{$chrom} += $l;
				}
			}
		}
	}

	close REP;
	close TAB;

	print "\n" x3;
	my $totalVal;
	foreach my $chrom (sort keys %total)
	{
		my $val    = $total{$chrom};
		$totalVal += $val;
		my $num    = &getNumber($val/1000, 3, 2);

		#printf "\tCHROM %s HAS GAPS TOTALIZING: %6dbp (%3d.%-2dkb)\n", $chrom, $total{$chrom}, int($total{$chrom}/1000), ((($total{$chrom}/1000)-int($total{$chrom}/1000))*100);
		printf "\t",uc($name),"  :: CHROM %s HAS ",uc($name)," TOTALIZING: %8dbp [ %skb ]\n", $chrom, $total{$chrom}, $num;
	}
	printf "\t",uc($name),"  :: GENOME HAS ",uc($name)," TOTALIZING: %8dbp [ %skb | %s mb ]\n", $totalVal, &getNumber($totalVal/1_000, 3, 2), &getNumber($totalVal/1_000_000, 3, 2);

}


sub getNumber
{
	my $num = $_[0];
	my $int = $_[1];
	my $dec = $_[2];

	my $intStr   = sprintf("%".$int."d", $num);
	my $floatStr = sprintf("%.".$dec."f", $num);
	$floatStr = substr($floatStr, index($floatStr,".")+1);
	return "$intStr.$floatStr";
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
	my $refLen    = $_[2];
	my $posNfoRef = $_[3];
	#print "GAP STR  : $gapStr\n";
	#print "REF START: $refStart\n";
	#print "REF LENG : $refLen\n";

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
	my %gaps;

	for (my $g = 0; $g < @gapArr; $g++)
	{
		my $nfo = $gapArr[$g];
		if ( $nfo =~ /(\d+)\:(\d+)/ )
		{
			#print "\tGAP  : $nfo\n";
			my $ref = $1;
			#my $qry = $2;
			#print "\t\tGAPR : $ref\n";
			#print "\tGAPQ : $qry\n";
			next if ( $ref == 0 );
			my $refAbsStart = ($refStart+$refSum+1);
			my $refAbsEnd   = ($refAbsStart+$ref-1);

			#print "\t\t\tGAP ABS START: $refAbsStart\n";
			#print "\t\t\tGAP ABS END  : $refAbsEnd\n";
			#push(@{$gaps{ref}}, $refAbsStart."-".$refAbsEnd) if ($refAbsStart != $refAbsEnd);

			#map { $$posNfoRef->remove($_) } ($refAbsStart..$refAbsEnd);

			if (( $refAbsEnd - $refAbsStart ) > $minMicroGap )
			{
				print "\t\t\tGAP ABS START: $refAbsStart\n";
				print "\t\t\tGAP ABS END  : $refAbsEnd\n";
				$$posNfoRef->remove_range($refAbsStart, $refAbsEnd);
			}

			$refSum += $ref;
		} else {
			#print "\tBLOCK: $nfo\n";
			$refSum += $nfo;
		}
	}

	if ($refSum != $refLen) { die "SUM OF BLOCKS AND GAPS ($refSum) NOT EQUAL TO ALIGNMENT SIZE ($refLen)" };

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


sub parseGaps_QRY
{
	my $gapStr    = $_[0];
	my $qryStart  = $_[1];
	my $qryLen    = $_[2];
	my $posNfoQry = $_[3];

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
			my $qryAbsStart = ($qryStart+$qrySum);
			my $qryAbsEnd   = ($qryStart+$qrySum+$qry);
			#push(@{$gaps{ref}}, $refAbsStart."-".$refAbsEnd) if ($refAbsStart != $refAbsEnd);
			#push(@{$gaps{qry}}, $qryAbsStart."-".$qryAbsEnd) if ($qryAbsStart != $qryAbsEnd);

			map { $$posNfoQry->remove($_) } ($qryAbsStart..$qryAbsEnd);

			$qrySum += $qry;
		} else {
			#print "\tBLOCK: $nfo\n";
			$qrySum += $nfo;
		}
	}

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


sub parseGaps_OLD
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
