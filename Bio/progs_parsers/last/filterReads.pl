#!/usr/bin/perl -w
use strict;


my $gapLetter       = "-";
my $dubiousLetter   = "N";
my $skipSmallerThan = 120;
my $skipSingleton   = 0;
#reset; ./DeNovoLastmaf2assembly.pl denovo/r265_vs_denovo.maf.sort.maf.nopar.maf CBS7750_SOAP_DE_NOVO

my $inMafFile = $ARGV[0];
my $ouMafFile = $ARGV[1];
die "NO IN MAF FILE GIVEN"                 if ! defined $inMafFile;
die "IN MAF FILE $inMafFile DOESNT EXISTS" if ! -f $inMafFile;
die "NO OUT MAF FILE GIVEN"                if ! defined $ouMafFile;
print "IN  MAF FILE: $inMafFile\n";
print "OUT MAF FILE: $ouMafFile\n";

open IN, "<$inMafFile"  or die "COULD NOT OPEN MAF FILE $inMafFile: $!";
open OUT, ">$ouMafFile" or die "COULD NOT OPEN MAF FILE $ouMafFile: $!";

my $dataCount = 0;
my %skipped;
while (my $line = <IN>)
{
	chomp $line;
	$dataCount++;
	#print "LINE '$line'\n";
	next if (( ! defined $line ) || ( $line eq "" ) || $line =~ /^#/);

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
	my ( $refChrom, $refStart, $refLength, $refEnd, $refFrame, $refLengthTotal, $refSeq );
	my ( $qryChrom, $qryStart, $qryLength, $qryEnd, $qryFrame, $qryLengthTotal, $qrySeq );




	#a score=18039
	if ( $scoreLine =~ /^a score\=(\d+)/)
	{
		$score = $1;
	} else {
		die "WRONG SCORE LINE FORMAT: \"$scoreLine\"";
	}

	#s supercontig_1.01_of_Cryptococcus_neoformans_Serotype_B 760 18105 + 1510064 TGGTTGGTGACTGCACCTTCACCAACAAGTTATTAACTGGCATATCCAG
	if ( $refLine   =~ /^s\s+(\S+)\s+(\d+)\s+(\d+)\s+(\S)\s+(\d+)\s+(\S+)/)
	{
		$refChrom       = $1;
		$refStart       = $2;
		$refLength      = $3;
		$refEnd         = $refStart + $refLength;
		$refFrame       = $4;
		$refLengthTotal = $5;
		$refSeq         = $6;
		#print "CHROM $refChrom START $refStart END $refEnd LENGTH $refLength FRAME $refFrame LENGTH TOTAL $refLengthTotal SEQ ", substr($refSeq, 0, 50),"\n";
	} else {
		die "WRONG REFERENCE LINE FORMAT: \"$refLine\"";
	}

	#s scaffold250                                              0 18099 -   78247 TGGTTGGTGACTGCACCTTCACCAACAAGTTATTAACTGGCATATCCAG
	if ( $qryLine   =~ /^s\s+(\S+)\s+(\d+)\s+(\d+)\s+(\S)\s+(\d+)\s+(\S+)/)
	{
		$qryChrom       = $1;
		$qryStart       = $2;
		$qryLength      = $3;
		$qryEnd         = $4 eq "+" ? $qryStart + $qryLength : $qryStart - $qryLength;
		#$qryEnd         = $3;
		$qryFrame       = $4;
		$qryLengthTotal = $5;
		$qrySeq         = $6;
		#print substr($qryLine, 0, 150), "\n";
		#print "CHROM $qryChrom START $qryStart END $qryEnd LENGTH $qryLength FRAME $qryFrame LENGTH TOTAL $qryLengthTotal SEQ ", substr($qrySeq, 0, 50),"\n";
	} else {
		die "WRONG QUERY LINE FORMAT: \"$qryLine\"";
	}

	my $qryEffLeng = $qryEnd > $qryStart ? ($qryEnd - $qryStart) : ($qryStart - $qryEnd);
	if    (( $skipSingleton   ) && ( $qryChrom       !~ /scaffold/           ))
	{
		print "SKIPPED $qryChrom :: SINGLETON ($qryLength) [EFF $qryEffLeng / LENG $qryLength / TLENG $qryLengthTotal]\n";
		$skipped{singleton}{count}++;
		$skipped{singleton}{sum} += $qryLength;
		next;
	}
	#if (( $skipSmallerThan ) && ( $refLength     <= $skipSmallerThan     )) { print "SKIPPED SMALLER THAN REFERENCE\n"; next; };
	elsif (( $skipSmallerThan ) && ( $qryLengthTotal <= $skipSmallerThan     ))
	{
		print "SKIPPED $qryChrom :: QUERY TOTAL LENGTH ($qryLengthTotal) SMALLER THAN THRESHOLD ($skipSmallerThan) [EFF $qryEffLeng / LENG $qryLength / TLENG $qryLengthTotal]\n";
		$skipped{'QUERY TOTAL LENGTH'}{count}++;
		$skipped{'QUERY TOTAL LENGTH'}{sum} += $qryLength;
		next;
	#}
	#elsif (( $skipSmallerThan ) && ( $qryEffLeng     <= $skipSmallerThan     ))
	#{
	#	print "SKIPPED $qryChrom :: QUERY EFFECTIVE LENGH ($qryEffLeng) SMALLER THAN THRESHOLD ($skipSmallerThan) [EFF $qryEffLeng / LENG $qryLength / TLENG $qryLengthTotal]\n";
	#	$skipped{'QUERY EFFECTIVE LENGH'}{count}++;
	#	$skipped{'QUERY EFFECTIVE LENGH'}{sum} += $qryLength;
	#	next;
	#}
	#elsif (( $skipSmall       ) && ( $qryEffLeng     < (.33 * $qryLengthTotal)) && ( $qryEffLeng     < 2* $skipSmallerThan))
	#{
	#	print "SKIPPED $qryChrom :: QUERY EFFECTIVE LENGTH ($qryEffLeng) SMALLLER THAN 33% OF QUERY TOTAL LENGTH ($qryLengthTotal)\n";
	#	next;
	} else {
		print "QUERY $qryChrom ACCEPTED [EFF $qryEffLeng / LENG $qryLength / TLENG $qryLengthTotal]\n"
	};
	print OUT $scoreLine, "\n", $refLine, "\n", $qryLine, "\n\n";
}
close IN;
close OUT;


if ( $skipSmallerThan )
{
	open LOG, ">$ouMafFile.log" or die "COULD NOT OPEN MAF FILE $ouMafFile.log: $!";
	foreach my $key ( %skipped )
	{
		my $names = $skipped{$key};
		foreach my $name (sort keys %$names )
		{
			my $value = $names->{$name};
			printf     "%-21s :: %-5s = %s\n", $key, $name, $value;
			printf LOG "%-21s :: %-5s = %s\n", $key, $name, $value;
		}
	}
	close LOG;
}


#a score=18039
#s supercontig_1.01_of_Cryptococcus_neoformans_Serotype_B 760 18105 + 1510064 TGGTTGGTGACTGCACCTTCACCAACAAGTTATTAACTGGCATATCCAG
#s scaffold250                                              0 18099 -   78247 TGGTTGGTGACTGCACCTTCACCAACAAGTTATTAACTGGCATATCCAG



#18039	supercontig_1.01_of_Cryptococcus_neoformans_Serotype_B	760	18105	+	1510064	scaffold250	0	18099	-	78247	13308,0:1,863,2:0,300,1:0,165,1:0,2092,3:0,1370
#2019	supercontig_1.01_of_Cryptococcus_neoformans_Serotype_B	18965	2033	+	1510064	scaffold250	18117	2034	-	78247	2022,0:1,11

1;
