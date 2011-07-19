#!/usr/bin/perl -w
use strict;

my $verbose = 0;
my $sixty   = 1;
my $iupac   = 0;
# clustalw_consensus.sh using BioPerl AlignIO

my $file = $ARGV[0];
die "INPUT FILE NOT DEFINED\n"         if ( ! defined $file );
die "INPUT FILE $file DOESNT EXISTS\n" if ( ! -f      $file );

print "CREATING ALIGNMENT FOR FILE $file\n";

my ($align, $ident) = &getAlignmentFromFile($file);

my $outFile = "$file.consensus.fasta";
my $name    = $file;
   $name    = substr($file, rindex($file, "/")+1);

open CON, ">$outFile" or die "COULD NOT OPEN $outFile: $!";
print CON ">$name\_consensus_$ident\n";
print     ">$name\_consensus_$ident\n" if $verbose;
print CON "$align\n";
print     "$align\n" if $verbose;
close CON;

sub getAlignmentFromFile
{
	use Bio::AlignIO;
	my $inFile = $_[0];
	my $in  = Bio::AlignIO->new("-format"=>"fasta","-file"=>$inFile);
	my $aln = $in->next_aln();

	my $con;
	if ( $iupac )
	{
		$con = $aln->consensus_iupac(100);
	} else {
		$con = $aln->consensus_string(100);
	}
	$con =~ s/(.{60})/$1\n/g if $sixty;

	my $identity = $aln->average_percentage_identity();
	$identity = int($identity * 100) / 100;


	#my $id  = $file;
	   #$id  =~ s/\..*$//;
	#my $match = $aln->match_line();
	#my $gap   = $aln->gap_line();
	#my $cigar = $aln->cigar_line();
	#my $score = $aln->score();


	#foreach my $seq ( $aln->each_seq())
	#{
	  #print $seq->seq(), "\n";
	#}
	#print "$match\n";
	#print "$gap\n";
	#print "$cigar\n";

	return ($con, $identity);
}

1;
