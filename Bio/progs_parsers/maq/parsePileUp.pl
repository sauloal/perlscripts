#!/usr/bin/perl -w
use strict;
use warnings;
use FindBin qw($Bin);

my $printParser = 0;
my $readbkp     = 1;
my $mkbkp       = 1;

my $pileup         = "all.map.pileup";
my $snp            = "cns.final.snp";

$pileup = "$Bin/$pileup";
$snp    = "$Bin/$snp";
if ($readbkp)
{
	if ( -f "$pileup\_short" )
	{
		$pileup = $pileup . "_short"; $mkbkp = 0;
	}
	else
	{
		$readbkp = 0;
	}
};



if ( ! -f "$pileup" )    { die "\tERROR: PILE UP FILE $pileup NOT FOUND $!\n"; };
if ( ! -f "$snp" )       { die "\tERROR: SNP FILE $snp NOT FOUND $!\n"; };




my %database;


# &loadSNP;
# &parsePileUp;
# &analyzeDB;




sub analyzeDB
{
	my $chromolist1 = "";
	my $chromolist2 = "";
	my $chromolist3 = "";
	my $chromolist4 = "";
	my $chromolist5 = "";
	my $chromolist6 = "";
	my $snpTotal = 0;
	foreach my $chromossome (sort keys %database)
	{
		my $chrcount  = 0;
		my $poses1    = "";
		my $poses2    = "";
		my $poses3    = "";
		my $poses4    = "";
		my $poses5    = "";
		my $poses6    = "";

		foreach my $position (sort { $a <=> $b } keys %{$database{$chromossome}})
		{
			my $original = $database{$chromossome}{$position}{"original"};
			my $snp      = $database{$chromossome}{$position}{"snp"};
			my $depth    = $database{$chromossome}{$position}{"depth"};
			my $repre    = $database{$chromossome}{$position}{"representation"};
			my $count    = $database{$chromossome}{$position}{"count"};

			$depth    = &corrnum($depth,3);
			$count    = &corrnum($count,3);
			$position = &corrnum($position,7);

			my @repre = split(//,$repre);
			my %repre;
			my $repres  = "";
			my $repres2 = "";
			foreach my $unit (@repre)
			{
				if (($unit eq ".") || ($unit eq ",")) {$unit = $original;};
				$unit = uc($unit);
				$repre{$unit}++;
			}

			foreach my $key (sort keys %repre)
			{
				my $value = $repre{$key};
# 				my $prop = sprintf("%02d", int(($value/$count)*1000)/10);
				my $prop = sprintf("%02d", ($value/$count)*100);
				$value = &corrnum($value,3);
				if (length $repres)  {$repres .= ";"; };
				if (length $repres2) {$repres2 .= ";"; };
				$repres  .= "$key=>$value";
				$repres2 .= "$key=>$value\[$prop%\]";
			}

			$chrcount++;
			$snpTotal++;

			if ($depth != $count)
			{
				$count = "$depth-" . ($depth-$count);
# 				$count = "$count\\$depth";
			}

			$poses1 .= "\t$position";
			$poses2 .= "\t$position($original->$snp)\n";
			$poses3 .= "\t$position($original->$snp) CONFIRMED BY $count READS\n";
			$poses4 .= "\t$position($original->$snp) CONFIRMED BY $count READS ($repre)\n";
			$poses5 .= "\t$position($original->$snp) CONFIRMED BY $count READS ($repres)\n";
			$poses6 .= "\t$position($original->$snp) CONFIRMED BY $count READS ($repres2)\n";
		}
		$chrcount     = &corrnum($chrcount,3);
		$chromolist1 .= "CHROMOSSOME $chromossome HAVE $chrcount SNPS IN POSITIONS\n$poses1\n\n";
		$chromolist2 .= "CHROMOSSOME $chromossome HAVE $chrcount SNPS IN POSITIONS\n$poses2\n\n";
		$chromolist3 .= "CHROMOSSOME $chromossome HAVE $chrcount SNPS IN POSITIONS\n$poses3\n\n";
		$chromolist4 .= "CHROMOSSOME $chromossome HAVE $chrcount SNPS IN POSITIONS\n$poses4\n\n";
		$chromolist5 .= "CHROMOSSOME $chromossome HAVE $chrcount SNPS IN POSITIONS\n$poses5\n\n";
		$chromolist6 .= "CHROMOSSOME $chromossome HAVE $chrcount SNPS IN POSITIONS\n$poses6\n\n";
	}
	$snpTotal    = &corrnum($snpTotal,4);
	print "THERE ARE $snpTotal SNPs IN TOTAL\n";
	print $chromolist6;
}


sub corrnum
{
	my $number = $_[0];
	my $digits = $_[1];

# 	my $leng = length $number;
# 	my $missing = $digits - $leng;
# 	if ($missing < 0) {die "\tERROR: ZERO FILLING BELOW 0, CONSIDER INCREASING NUMBER OF DIGITS\n";};
# 	my $result = "0"x$missing . $number;
	my $result = sprintf("%0" . $digits ."d", $number);

	return $result;
}

sub fixDec
{
	my $number = $_[0];

	$number = int($number*100)/100;

	return $number;
}


sub loadSNP
{
	open SNP, "<$snp" || die "\tERROR: COULD NOT OPEN SNP FILE: $!\n";

	while (my $line = <SNP>)
	{
		# supercontig_1.01_of_Cryptococcus_neoformans_Serotype_B  6       T       C       135     36      1.00    63      56
		# supercontig_1.01_of_Cryptococcus_neoformans_Serotype_B  7       C       A       171     48      1.00    63      62
		# supercontig_1.01_of_Cryptococcus_neoformans_Serotype_B  3099    G       T       48      7       1.00    63      34
		# supercontig_1.01_of_Cryptococcus_neoformans_Serotype_B  8784    C       G       48      7       1.00    63      22
		# supercontig_1.01_of_Cryptococcus_neoformans_Serotype_B  8880    G       T       45      6       1.00    63      32
		if ($line =~ /(\S+)\s(\d+)\s(\w)\s(\w)\s(\d+)\s(\d+)\s(\S+)\s(\d+)\s(\d+)/)
		{
			my $chromossome = $1;
			my $position    = $2;
			my $original	= $3;
			my $snp		= $4;  # consensus
			my $phred	= $5;  # phred consensus quality
			my $depth	= $6;  # read depth
			my $avghit	= $7;  # average number of hits of reads covering this position
			my $maxqual	= $8;  # highest mapping quality of the reads covering this position
			my $minqual	= $9;  # minimum consensus quality in the 3bp flanking region at each side of the site (6bp in total)
# 			my $secondbest	= $10; # second best call
# 			my $likelihood	= $11; # log likelihood ratio of the second best and the third best call
# 			my $third	= $12; # third best call

			$database{$chromossome}{$position}{"original"} = $original;
			$database{$chromossome}{$position}{"snp"}      = $snp;
			$database{$chromossome}{$position}{"depth"}    = $depth;
			$database{$chromossome}{$position}{"phred"}    = $phred;

			if ($printParser)
			{
				print "CHROMOSSOME   $chromossome\n";
				print "POSITION      $position\n";
				print "ORIGINAL BASE $original\n";
				print "SNP BASE      $snp\n";
				print "PHRED STAT    $phred\n";
				print "DEPTH         $depth\n";
				print "AVG HIT       $avghit\n";
				print "MAX QUAL      $maxqual\n";
				print "MIN QUAL      $minqual\n";
	# 			print " $secondbest\n";
	# 			print " $likelihood\n";
	# 			print " $third\n";
				print "\n\n\n";
			}
		}
		else
		{
			die "\tERROR: FAILED PARSING SNP FILE\n$line\n\n";
		}
	}
	close SNP;
}

sub parsePileUp
{
	open PILEUP, "<$pileup" || die "\tERROR: COULD NOT OPEN PILE UP FILE: $!\n";

	if ($mkbkp) { open PILEBKP, ">$pileup\_short" || die "\tERROR: COULD NOT OPEN $pileup\_short FOR BAKUP: $!\n"; };

	while (my $line = <PILEUP>)
	{
		# supercontig_1.01_of_Cryptococcus_neoformans_Serotype_B  6       T       36      @CcccCCCcccCCCccccCCCCccccCCCCccccccc
		# supercontig_1.01_of_Cryptococcus_neoformans_Serotype_B  7       C       48      @AaaaAAAaaaAAAaaaaAAAAaaaaAAAAaaaaaaaAAAAAAAAaaaa
		# supercontig_1.01_of_Cryptococcus_neoformans_Serotype_B  3099    G       6       @tTTttt
		# supercontig_1.01_of_Cryptococcus_neoformans_Serotype_B  8784    C       7       @GggGGgg
		if ($line =~ /(\S+)\s(\d+)\s(\w)\s(\d+)\s\@(\S*)/)
		{
			my $chromossome = $1;
			my $position    = $2;
			my $original	= $3;
			my $count	= $4;
			my $repre	= $5;
			my @repre	= split(//,$repre);

			if (exists $database{$chromossome}{$position})
			{
				my $original2 = $database{$chromossome}{$position}{"original"};
				my $snp       = $database{$chromossome}{$position}{"snp"};
				my $depth     = $database{$chromossome}{$position}{"depth"};
				my $phred     = $database{$chromossome}{$position}{"phred"};

				if ($mkbkp) { print PILEBKP $line; };

				if ($original ne $original2) { die "ORIGINAL FROM SNP ($original2) IS DIFFERENT FROM ORIGINAL OF PILEUP ($original)\n";};
# 				if ($count    != $depth)     { die "DEPTH FROM SNP ($depth) IS DIFFERENT FROM DEPTH OF PILEUP ($count)\n";};
				if ($count    != $depth)
				{
					if ($printParser) { print "*"x20 . "\nDEPTH FROM SNP ($depth) IS DIFFERENT FROM DEPTH OF PILEUP ($count)\n" . "*"x20 . "\n"; };
					$database{$chromossome}{$position}{"warning"} = 1;
				}
				else
				{
					$database{$chromossome}{$position}{"warning"} = 0;
				}


				if ($printParser)
				{	
					print "CHR   $chromossome\n";
					print "POS   $position\n";
					print "ORIG  $original vs ORIG2 $original2\n";
					print "SNP   $snp\n";
					print "PHRED $phred\n";
					print "COUNT $count vs DEPTH $depth\n";
					print "REPRE $repre\n";
					print "\n\n\n";
				}


				$database{$chromossome}{$position}{"representation"} = $repre;
				$database{$chromossome}{$position}{"count"}          = $count;
			}

			if ($printParser)
			{	
				print "CHR   $chromossome\n";
				print "POS   $position\n";
				print "ORIG  $original\n";
				print "COUNT $count\n";
				print "REPRE " . join(" ",@repre) . "\n";
				print "\n\n\n";
			}
		}
		else
		{
			die "\tERROR: FAILED PARSING PILEUP FILE\n$line\n\n";
		}
	}
	if ($mkbkp) { close PILEBKP; };
	close PILEUP;
}