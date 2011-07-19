#!/usr/bin/perl
use strict;
# Cuts a specified piece of a sequence in a fasta file
# needs fasta name, chromossome, start position, end position and sequence output name
# prints to stdout

my $fasta = $ARGV[0];
die "NO INPUT FASTA DEFINED"           if ( ! defined $fasta );
die "INPUT FASTA $fasta DOESNT EXISTS" if ( ! -f      $fasta );

print "CUTFASTA :: INFASTA '$fasta'\n";

if ( @ARGV == 2 )
{
	print "CUTFASTA :: ENTERING TAB MODE\n";
	my $tab   = $ARGV[1];

	die "NO INPUT TAB DEFINED"         if ( ! defined $tab );
	die "INPUT TAB $tab DOESNT EXISTS" if ( ! -f      $tab );

	print "  "x1 . "RUNNING WITH FASTA: $fasta TAB: $tab\n";

	my $lines = &loadTab($tab);
	if ( -f "$tab.fasta" ) { unlink("$tab.fasta"); };

	foreach my $cols ( @$lines )
	{
		my $chrom = $cols->[0];
		my $start = $cols->[1];
		my $end   = $cols->[2];
		my $name  = $cols->[3];
		my $gene  = &readFasta($fasta, $chrom);
		&returner($fasta, $chrom, $gene, $start, $end, $name, $tab);
	}
}
elsif ( @ARGV == 5 )
{
	print "CUTFASTA :: ENTERING STDIN MODE: @ARGV\n";
	my $chrom = $ARGV[1];
	my $start = $ARGV[2];
	my $end   = $ARGV[3];
	my $name  = $ARGV[4];
	print "  "x1 . "RUNNING WITH FASTA: \"$fasta\" CHROM: \"$chrom\" START: \"$start\" END: \"$end\" NAME: \"$name\"\n";
	exit 0;

	my $gene  = &readFasta($fasta, $chrom);
	&returner($fasta, $chrom, $gene, $start, $end, $name);
} else {
	die "NOT ENOUGHT PARAMETERS: @ARGV";
}



sub loadTab
{
	my $tabFile = $_[0];
	open FI, "<$tabFile" or die "COULD NOT OPEN $tabFile: $!";
	my @a;
	foreach my $line (<FI>)
	{
		chomp $line;
		next if ! $line;
		my @cols = split(/\t/, $line);
		next if ! @cols;
		push(@a, \@cols);
	}
	close FI;

	return \@a;
}


# R265_c_neoformans.fasta
# gpd1 824481 823935 supercontig_1.04_of_Cryptococcus_neoformans_Serotype_B
# tef1 288429 287730 supercontig_1.13_of_Cryptococcus_neoformans_Serotype_B
#
# WM276GBFF10_06.fasta
# gpd1 29 576   CP000291_CGB_F2310W_Glyceraldehyde_3_phosphate_dehydrogenase_476378_478056
# tef1 673 1371 CP000298_CGB_M1520C_Translation_elongation_factor_EF1_alpha__putative_323075_324730

# ./cut.pl R265_c_neoformans.fasta supercontig_1.04_of_Cryptococcus_neoformans_Serotype_B 823935 824481 gpd1 > gpd1.265.txt
# ./cut.pl R265_c_neoformans.fasta supercontig_1.13_of_Cryptococcus_neoformans_Serotype_B 287730 288429 tef1 > tef1.265.txt
# ./cut.pl WM276GBFF10_06.fasta CP000291_CGB_F2310W_Glyceraldehyde_3_phosphate_dehydrogenase_476378_478056 29 576 gpd1 > gpd1.276.txt
# ./cut.pl WM276GBFF10_06.fasta CP000298_CGB_M1520C_Translation_elongation_factor_EF1_alpha__putative_323075_324730 673 1371 tef1 > tef1.276.txt


sub returner
{
	my $f     = $_[0];
	my $c     = $_[1];
	my $gene  = $_[2];
	my $start = $_[3];
	my $end   = $_[4];
	my $name  = $_[5];
	my $tab   = $_[6] || '';

#	$start = $start - 500;
#	$end   = $end   + 500;

	my $header = "$f\_$c\_$start\_$end\_$name";
	   $header =~ s/\.\.\///g;
	print "  "x2 . "SAVING $header\n";

	my $fn = defined $tab ? ">>$tab.fasta" : ">$name.out.fasta";

	open FO, $fn or die "COULD NOT OPEN $fn: $!";

	print FO ">$header\n";

	my $seq = join('', @$gene[$start..$end]);
	print "  "x3 , length $seq, " bp\n";
	$seq =~ s/(.{60})/$1\n/g;
	print FO $seq, "\n";


	close FO;
}



sub readFasta
{
	my $inputFA  = $_[0];
	my $chrom    = $_[1];

	my @gene;
	my $chromName;
	my $desiredLine;

	undef @gene; $gene[0] = "";
	open FILE, "<$inputFA" or die "COULD NOT OPEN $inputFA: $!";

	my $current;
	my $chromo;
	my $chromoName;

	my $on   = 0;
	my $pos  = 0;
	my $line = 1;


	while (<FILE>)
	{
			chomp;
			if (( /^>/) && ($on))
			{
				$on   = 0;
				$pos  = 1;
			}

			if ($on)
			{
				foreach my $nuc (split("",$_))
				{
					push(@gene,$nuc);
				}
			}

			if (/^>$chrom/)
			{
# 				print ">$chrom\n";
				$on         = 1;
				$pos        = 1;
			}
	}
# 	print "\n\n";
	undef $chromo;
	close FILE;

	return \@gene;
}

1;
