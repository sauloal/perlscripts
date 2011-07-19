package pcrOO;
use strict;
use warnings;
use List::Util qw[min max];
use lib "./filters";
#use dnaCode;
use dnaCodeOO;
use toolsOO;
use complexity;
use folding;
my $verbose = 0;

my $tools     = toolsOO->new();
my $dnaCode   = dnaCodeOO->new();

my $length;      #MAX NUMBER OF CG ALLOWED IN THE LIGANT SITE (included)
my $minGc;       # in %
my $maxGc;       # in %
my $minTm;       # in centigrades [69];
my $maxTm;       # in centigrades [76];
my $minPurPyr;   # in %;
my $maxPurPyr;   # in %;
my $conc_salt;   # in mM [50]   50;
my $conc_mg;     # in mM [0]     1.5;
my $conc_primer; # in nM [200] 200;
my $minRepeatLegth;
my $minRepeatNumber;
my $checkQual;
my $name;

#ADDS TO REFERENCE ARRAY:
 #00 $strand
 #01 $startF+$offset
 #02 $length
 #03 $seq


sub new {
    #print "NEW MLPAOO\n";
    my $class      = shift;
    my $self       = {};

    my %pref       = %{$_[0]};

    $tools->checkNeeds("PCROO",\%pref, [
    "PCR.length",
    "PCR.minGc",     "PCR.maxGc",
    "PCR.minTm",     "PCR.maxTm",
    "PCR.minPurPyr", "PCR.maxPurPyr",
	"PCR.conc_salt", "PCR.conc_mg", "PCR.conc_primer"]);

    $length          = $pref{"PCR.length"};      #MAX NUMBER OF CG ALLOWED IN THE LIGANT SITE (included)
    $minGc           = $pref{"PCR.minGc"};       # in %
    $maxGc           = $pref{"PCR.maxGc"};       # in %
    $minTm           = $pref{"PCR.minTm"};       # in centigrades [69];
    $maxTm           = $pref{"PCR.maxTm"};       # in centigrades [76];
    $minPurPyr       = $pref{"PCR.minPurPyr"};   # in %;
    $maxPurPyr       = $pref{"PCR.maxPurPyr"};   # in %;
	$conc_salt       = $pref{"PCR.conc_salt"};   # in mM [50]   50;
	$conc_mg         = $pref{"PCR.conc_mg"};     # in mM [0]     1.5;
	$conc_primer     = $pref{"PCR.conc_primer"}; # in nM [200] 200;
	$minRepeatLegth  = $pref{"PCR.minRepeatLegth"};
    $minRepeatNumber = $pref{"PCR.minRepeatNumber"};
	$checkQual       = $pref{"PCR.checkQual"};
    $name            = $pref{"PCR.name"};

    bless($self, $class);
    return $self;
}


sub act
{
    my $self        = shift;
    #print "ACTING MLPAOO\n";

    my $probe     = $_[0];
    my $sequence  = uc($_[1]);
    my $offset    = $_[2] || 0;
    my $revC      = $_[3];

    my $strand    = $revC ? "R" : "F";

    my $sequenceLength = length($sequence);
	my $lastStart      = $sequenceLength - $length;

	my $end;
	my $seq;

    #globals
	my $countValAll = 0;
    my $centimo     = 0;

    my $start    = 1;
    my $count    = 1;
    my $total    = $lastStart;
       $centimo  = int(($total / 10) + 0.5);

    my $ite = 0;

    for (my $start = 0; $start <= $lastStart; $start++)
    {
        #print "LIGSTART $start... ";

        $end = $start + $length - 1;
        $seq = substr($sequence, $start-1, $length);

        #print "SEQ $seq... ";

		printLogAC(3, "DOESNT HAS N...");
        #if ( $seq =~ /N/)                           { &printLogAC(3, "HAS N. SKIPPING\n"); next; };
		if ( index($seq, "N") != -1 ) 				{ &printLogAC(4, "HAS N\t$seq\n"); next; };
		printLogAC(3, "[OK] ");

		printLogAC(3, "ENDS WITH C|G...");
        if ( ! ( substr($seq, -2) =~ /[C|G]/))      { &printLogAC(4, "DOESNT HAVE C|G AT 3'\t$seq\n"); next; };
        printLogAC(3, "[OK] ");

		printLogAC(3, "PROPER GC%...");
        my $seqGc   = $tools->countGC($seq);
        if ( ! (($seqGc >=       $minGc)  && ($seqGc <=      $maxGc))  ) { &printLogAC(4, "WRONG GC = $seqGc ! ] $minGc, $maxGc [ \t$seq\n"); next; };
        printLogAC(3, "[$seqGc - OK] ");

		printLogAC(3, "PROPER TM...");
        my $seqTm   = $tools->tmPCR($seq);
        if ( ! (($seqTm >=       $minTm)  && ($seqTm <=      $maxTm))  ) { &printLogAC(4, "WRONG TM = $seqTm ! ] $minTm, $maxTm [ \t$seq\n"); next; };
        printLogAC(3, "[$seqTm - OK] ");

		printLogAC(3, "PROPER PURPYR...");
        my $purPyrRatio   = $tools->countPurinePyrimidine($seq);
        if ( ! (($purPyrRatio >= $minPurPyr)  && ($purPyrRatio <=  $maxPurPyr))  ) { &printLogAC(4, "WRONG PURPYR = $purPyrRatio ! ] $minPurPyr, $maxPurPyr [ \t$seq\n"); next; };
        printLogAC(3, "[$purPyrRatio - OK] ");


        my $startF = $start;
        my $endF   = $end;

        if ( $revC ) # 0 = fwd 1 = rev
        {
            $startF = $sequenceLength - $start + 1;
            $endF   = $sequenceLength - $end   + 1;
        } #end if rev


		&printLogAC(3, "ENTROPY...");
		my $entropy  = &complexity::seFast($seq);
		if ($entropy) { &printLogAC(4, "HAS ENTROPY $entropy\t$seq\n"); next; };
		&printLogAC(3, "[$entropy - OK] ");

		if ($checkQual)
		{
			#my $seqTm2    = $tools->tmPCR2($seq);
			#my $seqTm3    = $tools->tmPCR3($seq, $conc_salt, $conc_mg, $conc_primer);
			#my $seqTmMLPA = $tools->tmMLPA($seq, $seqGc);
			#my $molwt     = $tools->molwt($seq);
			#
			#printLogAC  (5, "START FINAL $startF END FINAL $endF STRAND $strand SEQ $seq
			#				 GC $seqGc TM1 $seqTm TM2 $seqTm2 TM3 $seqTm3
			#				 TMMLPA $seqTmMLPA MLWT $molwt PURPYR $purPyrRatio\n");

			&printLogAC(3, "MASK...");
			my $mask  = &complexity::masker($seq, $minRepeatLegth, $minRepeatNumber);
			if ($mask) { &printLogAC(4, "HAS MASK $mask\t$seq\n"); $start += $mask; next; };
			if ( ! defined $mask) { die "MASKER RETURNED NULL"; };
			&printLogAC(3, "[$mask - OK] ");

			&printLogAC(3, "LIG FOLDING...");
			my $seqFold = &folding::checkFolding($seq);
			if ($seqFold) { &printLogAC(4, "FOLDS $seqFold\t$seq\n"); next; };
			&printLogAC(3, "[$seqFold - OK] ");

		}
		printLogAC(2, "PUSHING...");

        push (@$probe, [$strand, ($startF+$offset), $length, $seq]);

		printLogAC(2, "[DONE]\n");
		printLogAC(1, $strand, ", ", ($startF+$offset), ", ", $length, ", ", $seq, "\n");
#		push (@$probe, [
#            $strand, ($startF+$offset), $length,
#            $dnaCode->dna2digit($seq), $seqGc, $seqTm]);

        $ite++;
        $countValAll++;
    } # END FOR MY $start

    #print "MLPAOO ACTED\n";
    return ($ite, $countValAll, $centimo, $length);
}





sub toSql
{
    my $self       = shift;
    my $orgId      = $_[0];
    my $chrom      = $_[1];
    my $derivated  = $_[2];
    my $localProbe = $_[3];

#ADDS TO REFERENCE ARRAY:
 #00 $strand
 #01 $startF+$offset
 #02 $length
 #03 $seq

	return "(\'"	. $orgId			. "\',\'" . $chrom			  . "\',\'"
					. ${$localProbe}[0] . "\',\'" . ${$localProbe}[1] . "\',\'"
					. ${$localProbe}[2] . "\',\'" . $derivated 		  . "\',\'"
					. ${$localProbe}[3] . "\')";
}

sub toTab
{
    my $self       = shift;
    my $orgId      = $_[0];
    my $chrom      = $_[1];
    my $derivated  = $_[2];
    my $localProbe = $_[3];
    return              $orgId            . "\t" . $chrom             . "\t" .
						${$localProbe}[0] . "\t" . ${$localProbe}[1]  . "\t" .
                        ${$localProbe}[2] . "\t" . $derivated         . "\t" .
						${$localProbe}[3] . "\n";

#ADDS TO REFERENCE ARRAY:
 #00 $strand
 #01 $startF+$offset
 #02 $length
 #03 $seq

}

sub toHad
{
    my $self       = shift;
    my $orgId      = $_[0];
    my $chrom      = $_[1];
    my $derivated  = $_[2];
    my $localProbe = $_[3];

#ADDS TO REFERENCE ARRAY:
 #00 $strand
 #01 $startF+$offset
 #02 $length
 #03 $seq

    return  ${$localProbe}[3]  . "\t"   . # probe seq
            $orgId             . "{"    . #
            $chrom             . "[("   . #
            ${$localProbe}[0]  . ","    . # strand
            ${$localProbe}[1]  . ","    . # start pos
            ${$localProbe}[2]  . ")]}\n"; # length
}


sub getName
{
    my $self       = shift;
    return $name;
}

sub printLogAC
{
    my $level = $_[0];

    if ($level <= $verbose)
    {
        print @_[1 .. (@_-1)];
    }
}

sub DESTROY {};



#-rw-rw-r-- 1 saulo saulo 4004078 2010-01-13 13:31 Linkprobes/dumps/Yarrowia_lipolytica_strain_CLIB122_CHROMOSSOMES.fasta_0001.znm
#-rw-rw-r-- 1 saulo saulo   8605599 2010-01-15 16:54 Yarrowia_lipolytica_strain_CLIB122_CHROMOSSOMES.fasta.0001.001.F.pcr.had
#-rw-rw-r-- 1 saulo saulo   8609532 2010-01-15 16:55 Yarrowia_lipolytica_strain_CLIB122_CHROMOSSOMES.fasta.0001.001.R.pcr.had
#15871 saulo     10 -10  249m 114m 2320 R 100.0  1.4   1:14.26 probe_extractor
#real	1m16.909s
#user	1m16.696s 76s
#sys	0m00.172s

#4.004.078 bytes / 76s = 52.685 bytes/s = 51.4 kb/s = 3.087.0 kb/min = 3 mb/min
#(8.605.599 + 8.609.532) / 4.004.078 = 17.215.131 / 4.004.078 = 4.3 times original size ON DISK
#261.095.424 (249m) / 4.004.078 = 65.2 times original size ON RAM

#total 763M / 3mb/min = 254.3 min
#254.3 min / 3 cores = 84.8 min = 1h24min
#-rw-rw-r-- 1 saulo saulo   20M 2010-01-15 17:10 Caenorhabditis_elegans_CHROMOSSOMES.fasta_0004.xml
#20 Mb * 65.2 = 1.304 Mb = 1.27 Gb ON RAM TOPS * 3 cores = 3.82 Gb
#763 Mb * 4.3 = 3280.9 Mb = 3.2 Gb ON DISK

1;
