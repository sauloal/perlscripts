#!/usr/bin/perl -w
use strict;

my $outFolder = "report/individual3";

my $bFile  = shift(@ARGV);
my @rFiles = @ARGV;

#./bookmarks_extract.pl bookmarks_09 input_microarray/blast_microarray_Microarray_may_r265_data.csv.xml.ge3.blast.tab
#./bookmarks_extract.pl bookmarks_09 input_assembly2/*.tab input_blast/blast_*.tab input_broad/*.tab input_microarray/blast_microarray_Microarray_may_r265_data.csv.xml.all.blast.tab input_microarray/blast_microarray_Microarray_may_r265_data.csv.xml.blast.tab input_microarray/blast_microarray_Microarray_may_r265_data.csv.xml.ge3.blast.tab input_varscan/s_2_1en2_sorted.pileupheteroindel.tab input_varscan/s_2_1en2_sorted.pileupheterosnp.tab

#./bookmarks_extract.pl bookmarks_NONE input_assembly2/*.tab input_blast/blast_*.tab input_broad/*.tab input_last_denovo/r265_vs_denovo.maf.sort.maf.nopar.maf.tab.* input_microarray/blast_microarray_Microarray_may_r265_data.csv.xml.all.blast.tab input_microarray/blast_microarray_Microarray_may_r265_data.csv.xml.blast.tab input_microarray/blast_microarray_Microarray_may_r265_data.csv.xml.ge3.blast.tab input_varscan/s_2_1en2_sorted.pileupheteroindel.tab input_varscan/s_2_1en2_sorted.pileupheterosnp.tab

die "NO BOOKMARK FILE DEFINED"            if ( ! defined $bFile  );
die "BOOKMARK FILE DOESNT EXISTS: $bFile" if ( ! -f      $bFile  );
die "NO REFERENCE FILES DEFINED"          if ( !         @rFiles );

print "INPUT BOOKMARK FILE  : ",$bFile        , "\n";
print "INPUT REFERENCE FILES: ",$rFiles[0]    , "\n", " "x23;
print join("\n"." "x23, @rFiles[1..@rFiles-1]), "\n";

my ( $wanted, $chroms )= &readBookmark($bFile);
foreach my $file (@rFiles)
{
	&readReference($wanted, $chroms, $file);
}

&printWanted($wanted);





sub printWanted
{
	my $hash = $_[0];

	foreach my $chrom ( sort keys %$hash )
	{
		#print "CHROM :: $chrom\n";
		my $starts = $hash->{$chrom};
		foreach my $start ( sort { $a <=> $b } keys %$starts )
		{
			#print " "x2 . "START :: $start\n";
			my $ends = $starts->{$start};
			foreach my $end ( sort { $a <=> $b } keys %$ends )
			{
				#print " "x4 . "END :: $end\n";
				my $book  = $ends->{$end}[0];
				my $files = $ends->{$end}[1];

				my $name = $book->[3];
				mkdir("$outFolder/$name");
				open FI, ">$outFolder/$name/$name.tab";
				print FI "# ", join("\t", @$book), "\n";

				foreach my $file ( sort keys %$files )
				{
					#print " "x6 . "FILE :: $file\n";
					print FI "# $file\n";
					my $datas = $files->{$file};

					foreach my $data ( @$datas )
					{
						#print " "x8 . "DATA :: ", join("\t", @$data), "\n";
						print FI join("\t", @$data), "\n";
					}
				}

				close FI;
			}
		}
	}
}

sub readBookmark
{
	my $inFile = $_[0];
	my %hash;
	my %chroms;
	open FILE, "<$inFile" or die "COULD NOT OPEN FILE: $inFile :: $!";
	while (my $line = <FILE>)
	{
					#supercontig_1.02_of_Cryptococcus_neoformans_Serotype_B	370436	372193	forward	02_[370436, 372193]_10	DELETED GENE
					#1                                                      2       3       4       5                       6
					#|                                                      |       |       |       |                       |
					#|                                                      |       |       |       |                       |
					#|___        ___________________________________________|       |       |       |                       |
					#    |      |       ____________________________________________|       |       |                       |
					#    |      |      |       _____________________________________________|       |                       |
					#    |      |      |      |       ______________________________________________|                       |
					#    |      |      |      |      |       _______________________________________________________________|
					#    |      |      |      |      |      |
					#    |      |      |      |      |      |
		if ( $line =~ /^(\S+)\t(\d+)\t(\d+)\t(\S+)\t(.+?)\t(.+?)$/)
		{
			my $chromossome = $1;
			my $start       = $2;
			my $end         = $3;
			my $frame       = $4;
			my $name        = $5;
			my $anno        = $6 || "";

			my @array = ($start, $end, $frame, $name, $anno);
			$hash{$chromossome}{$start}{$end}[0] = \@array;

			printf "%s\t%s\t%s\t%s\t%s\t%s\n", $chromossome, $start, $end, $frame, $name, $anno;
			for (my $i = $start; $i <= $end; $i++)
			{
				#print "\tADDING :: $i\n";
				$chroms{$chromossome}[$i] = \@array;
			}


		} else {
			#print "LINE NOT VALID\t",$line,"\n";
		}
	}
	close FILE;
	return (\%hash, \%chroms);
}


sub readReference
{
	my $wHash = $_[0];
	my $cHash = $_[1];
	my $file  = $_[2];

	open FILE, "<$file" or die "COULD NOT OPEN FILE: $file :: $!";
	my %added;
	while (my $line = <FILE>)
	{
		chomp($line);
	                #supercontig_1.01_of_Cryptococcus_neoformans_Serotype_B + 1 36 INS_1_36 ins [36] INS
					#1                                                      2 3 4  5        6        7
					#|                                                      | | |  |        |        |
					#|                                                      | | |  |        |        |
					#|__        ____________________________________________| | |  |        |        |
					#   |      |      ________________________________________| |  |        |        |
					#   |      |     |       ___________________________________|  |        |        |
					#   |      |     |      |       _______________________________|        |        |
					#   |      |     |      |      |       _________________________________|        |
					#   |      |     |      |      |      |       ___________________________________|
					#   |      |     |      |      |      |      |
		if ( $line =~ /(\S+)\t(\S)\t(\d+)\t(\d+)\t(\S+)\t(.+?)\t(\S+)/)
		{
			my $chromossome = $1;
			my $frame       = $2;
			my $start       = $3;
			my $end         = $4;
			my $uName       = $5;
			my $name        = $6;
			my $type        = $7;

			my $begin  = $start >= $end ? $end   : $start;
			my $finish = $start >= $end ? $start : $end;

			my @array  = ($chromossome, $frame, $start, $end, $uName, $name, $type);
			my $ch     = $cHash->{$chromossome};

			#printf "\n\nFILE %s :: %s\t%s\t%07d\t%07d\t%s\t%s\t%s\n", $file, $chromossome, $frame, $start, $end, $uName, $name, $type;

			for (my $i = $begin; $i <= $finish; $i++)
			{
				#print "\tCHECKING POS $i\n";

				if ( defined $ch->[$i] )
				{
					#print "\t\tTHERE'S SOMETHING HERE :: POS $i\n";
					my $chi    = $ch->[$i];
					my $cStart = $chi->[0];
					my $cEnd   = $chi->[1];

					if ( exists $wHash->{$chromossome} )
					{
						#print "\t\t\tCHROMOSSOME IS ALREADY HERE\n";
						if ( ! exists $added{"$chromossome\_$start\_$end"} )
						{
							#print "\t\t\t\tNEW DATA :: ADDING : $chromossome => $start, $end\n";

							push(@{$wHash->{$chromossome}{$cStart}{$cEnd}[1]{$file}}, \@array);
							$added{"$chromossome\_$start\_$end"} = 1;
						} else {
							#print "\t\t\t\tOLD DATA :: SKIPPING $chromossome => $start, $end\n";
						}
					} else {
						#print "\t\t\tNO CHROMOSSOME :: ADDING : $chromossome => $start, $end\n";

						push(@{$wHash->{$chromossome}{$cStart}{$cEnd}[1]{$file}}, \@array);
						$added{"$chromossome\_$start\_$end"} = 1;
					}
				}
			}
		} else {
			#printf "FILE $file :: LINE NOT CONFORMANT: $line\n";
		}
	}
	close FILE;
}


1;

### BOOKMARK
#>name: bookmarks
#>name: bookmarks
#Chromosome	Start	End	Strand	Name	Annotation
#supercontig_1.01_of_Cryptococcus_neoformans_Serotype_B	636780	730231	forward	01_[636780, 730231]_09
#supercontig_1.01_of_Cryptococcus_neoformans_Serotype_B	638359	644554	none	01_[638359, 644554]_10
#supercontig_1.02_of_Cryptococcus_neoformans_Serotype_B	370436	372193	forward	02_[370436, 372193]_10	DELETED GENE

### FILE
##sequence	strand	start	end	unique name	commom name	gene type
#supercontig_1.01_of_Cryptococcus_neoformans_Serotype_B	+	1	36	INS_1_36	ins [36]	INS
#supercontig_1.01_of_Cryptococcus_neoformans_Serotype_B	+	1	1	INS_1_1	ins [1]	INS
