#!/usr/bin/perl -w
use strict;
use warnings;

#  Outputs a list of structural differences for each sequence in
#the reference and query, sorted by position. For a reference
#sequence R, and its matching query sequence Q, differences are
#categorized as
#GAP (gap between two mutually consistent alignments),
#DUP (inserted duplication),
#BRK (other inserted sequence),
#JMP (rearrangement),
#INV (rearrangement with inversion),
#SEQ (rearrangement with another sequence).
#The first five columns of
#the output are
#	seq ID,
#	feature type,
#	feature start,
#	feature end, and
#	feature length.

#Additional columns are added depending on the
#feature type. Negative feature lengths indicate overlapping adjacent
#alignment blocks.
#  IDR GAP gap-start gap-end gap-length-R gap-length-Q gap-diff
#  IDR DUP dup-start dup-end dup-length
#  IDR BRK gap-start gap-end gap-length
#  IDR JMP gap-start gap-end gap-length
#  IDR INV gap-start gap-end gap-length
#  IDR SEQ gap-start gap-end gap-length prev-sequence next-sequence

#Positions always reference the sequence with the given ID. The
#sum of the fifth column (ignoring negative values) is the total
#amount of inserted sequence. Summing the fifth column after removing
#DUP features is total unique inserted sequence. Note that unaligned
#sequence are not counted, and could represent additional "unique"
#sequences. See documentation for tips on how to interpret these
#alignment break features.


#EXAMPLE
#R265_CBS7750v2.QDIFF
#supercontig_1.01_Cryptococcus_gattii_CBS7750v2	GAP	18866	18865	0	100	-100
#	7750v2 1.01 has a gap from 18866 'til 18865 - 0 bp in ref and 100bp in query (-100bp difference)
#supercontig_1.01_Cryptococcus_gattii_CBS7750v2	JMP	478112	478111	0
#supercontig_1.03_Cryptococcus_gattii_CBS7750v2	DUP	1224868	1225396	529
#supercontig_1.06_Cryptococcus_gattii_CBS7750v2	BRK	396150	396151	2

#supercontig_1.10_Cryptococcus_gattii_CBS7750v2	SEQ	706147	703114	-3032	supercontig_1.10_cryptococcus_gattii_CBS7750v1	supercontig_1.17_cryptococcus_gattii_CBS7750v1

#R265_CBS7750v2.RDIFF
#supercontig_1.01_of_Cryptococcus_neoformans_Serotype_B_R265	GAP	18866	18965	100	0	100
#	r265 1.01 has a gap from 18866 'til 18965 - 100bp on reference and 0bp in query (+100bp diff)


my $usage = "USAGE: $0 <OUTPUT DIR> <PREFIX BASE>";
die "$usage" if (@ARGV < 2);

my $outdir       = $ARGV[0];
my $prefix_base  = $ARGV[1];

die "DIR $outdir NOT FOUND\n$usage"  if  ( ! -d $outdir     );

print "RUNNING $0 $outdir $prefix_base\n";
print "OUTDIR \"$outdir\" PREFIXBASE \"$prefix_base\"\n";

my $minGapSize      = 100;

mkdir "xml";

print "PARSING SNP FILES\n";

my $dir     = "$outdir";

&nucmer_gap_parser($dir,$prefix_base);


sub nucmer_gap_parser
{
	my $directory = $_[0];
	my $prefix    = $_[1];

	print "PARSING GAP\n";
	my %hash;
	my %out;
	my @total;

	for my $ext ("rdiff", "qdiff")
	{
		my $file = "$directory/$prefix.$ext";
		if ( -f $file )
		{
			print " " x2 . "$file\n";

			open FILE, "<$file" or die "  COULD NOT OPEN FILE $file: $!";
			@total   = <FILE>;
			close FILE;
			print " " x04 . @total . " LINES LOADED\n";
			&parse_gap(\@total,$prefix, $ext);
			undef @total;
		} else { # end if my file
			die "FILE $file DOESNT EXISTS";
		}
	}

	return %out;
}

sub parse_gap
{
	my @lines = @{$_[0]};
	my $name  = $_[1];
	my $ext   = $_[2];
	my %chrom;

	if (@lines)
	{
		#  IDR GAP gap-start gap-end gap-length-R gap-length-Q gap-diff
		#  IDR DUP dup-start dup-end dup-length
		#  IDR BRK gap-start gap-end gap-length
		#  IDR JMP gap-start gap-end gap-length
		#  IDR INV gap-start gap-end gap-length
		#  IDR SEQ gap-start gap-end gap-length prev-sequence next-sequence
		my %files;
		for my $type ("GAP", "DUP", "BRK", "JMP", "INV", "SEQ")
		{
			my $fnp = "xml/ND_$name\_$ext\_$type\_prog.xml";
			my $fnc = "xml/ND_$name\_$ext\_$type\_chro.xml";
			open(my $fhp, ">$fnp") or die "COULD NOT OPEN $fnp: $!";
			open(my $fhc, ">$fnc") or die "COULD NOT OPEN $fnc: $!";
			$files{$type}{prog}{fh} = $fhp;
			$files{$type}{prog}{fn} = $fnp;
			$files{$type}{chro}{fh} = $fhc;
			$files{$type}{chro}{fn} = $fnc;
			$files{$type}{id}       = 1;
			print "  "x3, "OPENING TYPE \"$type\" SORT \"PROG\" FILENAME \"$fnp\"\n";
			print "  "x3, "OPENING TYPE \"$type\" SORT \"CHRO\" FILENAME \"$fnc\"\n";

			print $fhp "<root id=\"mummer\" type=\"$type\">\n";
			print $fhp "\t<table id=\"mummer\" type=\"program\">\n";
			print $fhc "<root id=\"mummer\" type=\"$type\">\n";
		}

		my $id        = 0;
		my %typeChrom;
		for (my $l = 0; $l < @lines; $l++)
		{
			my $line = $lines[$l];
			chomp $line;
			#EXAMPLE
			#R265_CBS7750v2.QDIFF
			#supercontig_1.01_Cryptococcus_gattii_CBS7750v2	JMP	478112	478111		0
			#supercontig_1.03_Cryptococcus_gattii_CBS7750v2	DUP	1224868	1225396		529
			#supercontig_1.06_Cryptococcus_gattii_CBS7750v2	BRK	396150	396151		2
			#supercontig_1.10_Cryptococcus_gattii_CBS7750v2	SEQ	706147	703114		-3032	supercontig_1.10_cryptococcus_gattii_CBS7750v1	supercontig_1.17_cryptococcus_gattii_CBS7750v1
			#supercontig_1.01_Cryptococcus_gattii_CBS7750v2	GAP	18866	18865		0	100	-100
			#	7750v2 1.01 has a gap from 18866 'til 18865 - 0 bp in ref and 100bp in query (-100bp difference)

			if ($line =~ /^(\S+)\s*(\S+)\s*(\d+)\s*(\d+)\s*(.+)/)
			{
				my $chrom = $1;
				my $type  = $2;
				my $start = $3;
				my $end   = $4;
				my $rest  = $5;
				my $fhp   = $files{$type}{prog}{fh};
				my $fhc   = $files{$type}{chro}{fh};
				my $id    = $files{$type}{id}++;

				my ($outShared, $outProg, $outChrom);
				my $outTable;
				my ($outRow1, $outRow2);
				my $outSpecific;

				if ($type =~ /JMP|DUP|BRK|INV/)
				{
					$outSpecific .= "\t\t\t" . "<length>" . $rest . "</length>\n";
				}
				elsif ($type =~ /GAP/)
				{
					#  IDR GAP gap-start gap-end gap-length-R gap-length-Q gap-diff
					if ($rest =~ /(\S+)\s*(\S+)\s*(\S+)/)
					{
						my $gapLengR = $1;
						my $gapLengQ = $2;
						my $gapDiff  = $3;
						$outSpecific .= "\t\t\t" . "<gapLengthR>" . $gapLengR . "</gapLengthR>\n";
						$outSpecific .= "\t\t\t" . "<gapLengthQ>" . $gapLengQ . "</gapLengthQ>\n";
						$outSpecific .= "\t\t\t" . "<gapDiff>"    . $gapDiff  . "</gapDiff>\n";
					} else {
						die "WRONG REST \"$rest\" :: $line";
					}
				}
				elsif ($type =~ /SEQ/)
				{
					#  IDR SEQ gap-start gap-end gap-length prev-sequence next-sequence
					if ($rest =~ /(\S+)\s*(\S+)\s*(\S+)/)
					{
						my $length    = $1;
						my $prevSeq   = $2;
						my $nextSeq   = $3;
						$outSpecific .= "\t\t\t" . "<length>"  . $length  . "</length>\n";
						$outSpecific .= "\t\t\t" . "<prevSeq>" . $prevSeq . "</prevSeq>\n";
						$outSpecific .= "\t\t\t" . "<nextSeq>" . $nextSeq . "</nextSeq>\n";
					} else {
						die "WRONG REST \"$rest\" :: $line";
					}
				} else {
					die "UNKNOWN TYPE \"$type\" :: $line";
				}

				if (( ! $typeChrom{$type} ) || ($typeChrom{$type} ne $chrom))
				{
					print "  "x4, "$l :: NAME $name EXT $ext TYPE $type CHROM $chrom (LASTCHROM ",($typeChrom{$type}||""),")\n";
					$outTable .= "\t</table>\n" if ( $typeChrom{$type} );
					$outTable .= "\t<table id=\"$chrom\" type=\"chromossome\">\n";
				} else {
					$outTable = "";
				}

				$outRow1    = "\t\t"   . "<row id=\"$id\">\n";
				$outRow2    = "\t\t"   . "</row>\n";

				$outShared .= "\t\t\t" . "<start>"   . "$start"             . "</start>\n";
				$outShared .= "\t\t\t" . "<end>"     . "$end"               . "</end>\n";
				$outShared .= "\t\t\t" . "<id>"      . "$id"                . "</id>\n";
				$outChrom  .= "\t\t\t" . "<program>" . "mummer_$name\_$ext" . "</program>\n";
				$outProg   .= "\t\t\t" . "<chromR>"  . "$chrom"             . "</chromR>\n";

				print $fhp           $outRow1,$outShared,$outProg ,$outSpecific,$outRow2;
				print $fhc $outTable,$outRow1,$outShared,$outChrom,$outSpecific,$outRow2;

				$typeChrom{$type} = $chrom;
			}
			else
			{
				die "UNKNOWN GAP FILE FORMAT";
			}
		} #end foreach my $line

		foreach my $key (keys %files)
		{
			foreach my $type (keys %{$files{$key}})
			{
				next if ($type eq "id");
				my $fh = $files{$key}{$type}{fh};
				my $fn = $files{$key}{$type}{fn};
				my $id = $files{$key}{id};

				print $fh "\t</table>\n" if ($id > 1);
				print $fh "</root>\n";

				print "  "x3, "CLOSING TYPE \"$key\" SORT \"$type\" FILENAME \"$fn\" WITH ", ($id-1)," REPORTS\n";
				close $fh;
			}
		} #end forach my key
	} # end if lines
}

1;
