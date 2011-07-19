package mlpaOO;
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
#ADDS TO REFERENCE ARRAY:
 #00 $strand
 #01 ($ligStartF+$offset)
 #02 $allLen
 #03 $allSeq
 #04 $ligLen

    my $maxGCLS;
    my $cleverness;		# whether to skip elongation of m13 and skip half of lig once found a probe
    my $checkQual;
    my $name;

    my $primerFWD;
    my $primerREV;
    my $primerFWDrc;
    my $primerREVrc;

    my $NaK;

    my $ligLenStr;
    my @ligLen;
    my $ligMinGc; # in %
    my $ligMaxGc; # in %
    my $ligMinTm; # in centigrades [69];
    my $ligMaxTm; # in centigrades [76];

    my $m13LenStr;
    my @m13Len;
    my $m13MinGc;
    my $m13MaxGc;
    my $m13MinTm;# in centigrades [70];
    my $m13MaxTm;# in centigrades [100];
    my $minRepeatLegth;
    my $minRepeatNumber;

	my $minLigLen;
	my $minM13Len;
	my $maxLigLen;
	my $maxM13Len;

    my $dnaCode;
    my $tools;

sub new {
    #print "NEW MLPAOO\n";
    my $class      = shift;
    my $self       = {};

    my %pref       = %{$_[0]};

    $dnaCode       = dnaCodeOO->new();
    $tools         = toolsOO->new();

    $tools->checkNeeds("MLPAOO", \%pref, [
    "MLPA.maxGCLS",      "MLPA.cleverness",       "MLPA.primerFWD",      "MLPA.primerREV",    "MLPA.NaK",
    "MLPA.ligLen",       "MLPA.ligMinGc",         "MLPA.ligMaxGc",       "MLPA.ligMinTm",     "MLPA.ligMaxTm",
    "MLPA.m13Len",       "MLPA.m13MinGc",         "MLPA.m13MaxGc",       "MLPA.m13MinTm",     "MLPA.m13MaxTm",
    "MLPA.checkQual",    "MLPA.name",             "MLPA.minRepeatLegth", "MLPA.minRepeatNumber"]);

    $maxGCLS         = $pref{"MLPA.maxGCLS"};        #MAX NUMBER OF CG ALLOWED IN THE LIGANT SITE (included)
    $cleverness      = $pref{"MLPA.cleverness"};		# whether to skip elongation of m13 and skip half of lig once found a probe
    $checkQual       = $pref{"MLPA.checkQual"};
    $name            = $pref{"MLPA.name"};

    $primerFWD       = $pref{"MLPA.primerFWD"};
    $primerREV       = $pref{"MLPA.primerREV"};
    $primerFWDrc     = reverse("$primerFWD");
    $primerREVrc     = reverse("$primerREV");
       $primerFWDrc  =~ tr/ACGT/TGCA/;
       $primerREVrc  =~ tr/ACGT/TGCA/;

    $NaK             = $pref{"MLPA.NaK"};

    $ligLenStr 	     = $pref{"MLPA.ligLen"};

    $ligMinGc        = $pref{"MLPA.ligMinGc"}; # in %
    $ligMaxGc        = $pref{"MLPA.ligMaxGc"}; # in %
    $ligMinTm        = $pref{"MLPA.ligMinTm"}; # in centigrades [69];
    $ligMaxTm        = $pref{"MLPA.ligMaxTm"}; # in centigrades [76];

    $m13LenStr       = $pref{"MLPA.m13Len"};
    $m13MinGc        = $pref{"MLPA.m13MinGc"};
    $m13MaxGc        = $pref{"MLPA.m13MaxGc"};
    $m13MinTm        = $pref{"MLPA.m13MinTm"};# in centigrades [70];
    $m13MaxTm        = $pref{"MLPA.m13MaxTm"};# in centigrades [100];
    $minRepeatLegth  = $pref{"MLPA.minRepeatLegth"};
    $minRepeatNumber = $pref{"MLPA.minRepeatNumber"};

    foreach my $key (split(/,/, $ligLenStr))
    {
        push(@ligLen, $key);
    }

    foreach my $key (split(/,/, $m13LenStr))
    {
        push(@m13Len, $key);
    }

	$minLigLen   = min(@ligLen);
	$minM13Len   = min(@m13Len);
	$maxLigLen   = max(@ligLen);
	$maxM13Len   = max(@m13Len);

    bless($self, $class);
    return $self;
}


sub act
{
    my $self        = shift;
    #print "ACTING MLPAOO\n";

    my $probe          = $_[0];
    my $MKFsequence    = uc($_[1]);
    my $offset         = $_[2] || 0;
    my $revC           = $_[3];

    my $strand         = $revC ? "R" : "F";

    my $sequenceLength = length($MKFsequence);
	my $lastLigStart   = $sequenceLength - ($minLigLen + $minM13Len);

	my $ligEnd;
	my $m13Start;
	my $m13End;
	my $ligSeq;
	my $m13Seq;
	my $ligThree;
	my $m13Three;

    #globals
	my $countValAll = 0;
    my $centimo     = 0;

    my $ligStart    = 1;
    my $count       = 1;
    my $total       = $lastLigStart;
       $centimo     = int(($total / 10) + 0.5);

    my $ite         = 0;

    while ($ligStart < $lastLigStart)
    {
        my $found = 0;
        my $ligLen;
        &printLogAC(3, "\nLIGSTART $ligStart\n");

        for $ligLen (@ligLen)
        {
            if ($found) { last; };

            $ligEnd    = $ligStart + $ligLen - 1;
            $ligSeq = substr($MKFsequence, $ligStart-1, $ligLen);
            &printLogAC(3, "\n  LIG: $ligSeq [$ligLen]... ");

            ############# LIG CONSTRAINS ##################
            my $start = 0;
            $ite++;
            while ((substr($ligSeq, $start, 1) =~ /[A|T]/) && ($start < $ligLen)) { $ligStart++; $start++; };

            &printLogAC(3, "LIG NOT START A|T...");
            if ( $ligSeq =~ /^[A|T]/) { &printLogAC(4, "LIG STARTS WITH A|T @ $ligStart \t$ligSeq\n"); $ligStart--; last; };
            &printLogAC(3, "[OK] ");
            # THE LIGSTART-- IS DUE TO THE WHILE LOOP

            &printLogAC(3, "LIG NOT END GT...");
            if ( $ligSeq =~ /[G|T]$/) { &printLogAC(4, "LIG ENDS WITH G|T @ $ligStart \t$ligSeq\n"); next; }; #
            &printLogAC(3, "[OK] ");

            &printLogAC(3, "LIG HAS NO N...");
            #if ( $ligSeq =~ /N/)             { &printLogAC(0, "HAS N 1 ...\n");};
            if ( index($ligSeq, "N") != -1 ) { &printLogAC(4, "HAS N\n"); last; };
            &printLogAC(3, "[OK] ");

            &printLogAC(3, "LIG HAS NO PRIMER...");
            #if (($ligSeq =~ /$primerFWD/)   || ($ligSeq =~ /$primerREV/)   ||	#PRIMERS
            #    ($ligSeq =~ /$primerFWDrc/) || ($ligSeq =~ /$primerREVrc/))	#PRIMERS REVERSE COMPLEMENTAR
            #{ &printLogAC(0, "HAS PRIMER 1...\n");};
            if (index($ligSeq, $primerFWD  ) != -1 ) { &printLogAC(4, "HAS PRIMER FWD   $primerFWD...\n"); last; }; #PRIMERS
            if (index($ligSeq, $primerREV  ) != -1 ) { &printLogAC(4, "HAS PRIMER REV   $primerREV...\n"); last; }; #PRIMERS
            if (index($ligSeq, $primerFWDrc) != -1 ) { &printLogAC(4, "HAS PRIMER FWDrc $primerFWD...\n"); last; }; #PRIMERS REVERSE COMPLEMENTAR
            if (index($ligSeq, $primerREVrc) != -1 ) { &printLogAC(4, "HAS PRIMER REVrc $primerFWD...\n"); last; }; #PRIMERS REVERSE COMPLEMENTAR
            &printLogAC(3, "[OK] ");

            &printLogAC(3, "LIG PROPER GC%...");
            my $ligGC   = $tools->countGC($ligSeq);
            if ( ! (($ligGC >=       $ligMinGc)  && ($ligGC <=      $ligMaxGc))  ) { &printLogAC(4, "LIG WRONG GC% $ligGC ! ] $ligMinGc, $ligMaxGc [ \t$ligSeq\n"); next; };
            &printLogAC(3, "[$ligGC - OK] ");

            &printLogAC(3, "LIG PROPER TM...");
            my $ligTm   = $tools->tmMLPA($ligSeq, $ligGC, $NaK);
            if      ($ligTm > $ligMaxTm)                                           { &printLogAC(4, "LIG WRONG TM $ligTm >= $ligMaxTm\t$ligSeq\n"); last; };
            if ( ! (($ligTm >=       $ligMinTm)  && ($ligTm <=      $ligMaxTm))  ) { &printLogAC(4, "LIG WRONG TM $ligTm ! ] $ligMinTm, $ligMaxTm [\t$ligSeq\n"); next; };
            &printLogAC(3, "[$ligTm - OK] ");

            &printLogAC(3, "LIG LAST 3 GC%...");
            $ligThree = substr($ligSeq, -3);
            if (($ligThree =~ tr/GCgc//) > $maxGCLS) { &printLogAC(4, "LIG ENDS WITH TOO MANY GC\t$ligSeq\n"); next; };
            &printLogAC(3, "[OK] ");

            if ($checkQual)
            {
                &printLogAC(3, "M13 ENTROPY...");
                my $entropyM13  = &complexity::seFast($m13Seq);
                if ($entropyM13) { &printLogAC(4, "HAS ENTROPY $entropyM13\t$m13Seq\n"); last; };
                &printLogAC(3, "[$entropyM13 - OK] ");

                &printLogAC(3, "LIG MASK...");
                my $maskLig  = &complexity::masker($ligSeq, $minRepeatLegth, $minRepeatNumber);
                if ($maskLig) { &printLogAC(4, "HAS MASK $maskLig\t$m13Seq\n"); $found = 1; $ligStart += $maskLig; last; };
                if ( ! defined $maskLig) { die "COMPLEXITY RETURNED NULL\t$m13Seq"; };
                &printLogAC(3, "[$maskLig - OK] ");

                &printLogAC(3, "LIG FOLDING...");
                my $seqFoldLig = &folding::checkFolding($ligSeq);
                if ($seqFoldLig) { &printLogAC(4, "FOLDS $seqFoldLig\t$ligSeq\n"); last; };
                &printLogAC(3, "[$seqFoldLig - OK] ");
            }

            my $m13Len;
            for $m13Len (@m13Len)
            {
                if ($found && $cleverness) { last; };
                $ite++;
                if ( ! ($m13Len % 3) ) { next; };

                $m13Start = $ligEnd   + 1;
                $m13End   = $m13Start + $m13Len - 1;
                if ( $m13End > $sequenceLength ) { last; };

                ############# M13 CONSTRAINS ##################
                $m13Seq   = substr($MKFsequence, $m13Start-1, $m13Len);
                &printLogAC(3, "M13: $m13Seq [$m13Len]... ");

                &printLogAC(3, "HAS NO N...");
                #if ( $m13Seq =~ /N/)             { &printLogAC(0, "HAS N 1...\n"); };
                if ( index($m13Seq,"N") != -1 )  { &printLogAC(4, "HAS N \t$m13Seq\n"); last; };
                &printLogAC(3, "[OK] ");

                &printLogAC(3, "HAS NO PRIMER...");
                #if (($m13Seq =~ /$primerFWD/)   || ($m13Seq =~ /$primerREV/)   ||	#PRIMERS
                #    ($m13Seq =~ /$primerFWDrc/) || ($m13Seq =~ /$primerREVrc/))     #PRIMERS REVERSE COMPLEMENTAR
                #{ &printLogAC(0, "HAS PRIMER 1...\n"); };
                if (index($m13Seq, $primerFWD)   != -1) { &printLogAC(4, "HAS PRIMER FWD   $primerFWD   \t$m13Seq\n"); last; };#PRIMERS
                if (index($m13Seq, $primerREV)   != -1) { &printLogAC(4, "HAS PRIMER REV   $primerREV   \t$m13Seq\n"); last; };#PRIMERS
                if (index($m13Seq, $primerFWDrc) != -1) { &printLogAC(4, "HAS PRIMER FWDrc $primerFWDrc \t$m13Seq\n"); last; };#PRIMERS REVERSE COMPLEMENTAR
                if (index($m13Seq, $primerREVrc) != -1) { &printLogAC(4, "HAS PRIMER REVrc $primerREVrc \t$m13Seq\n"); last; };#PRIMERS REVERSE COMPLEMENTAR
                &printLogAC(3, "[OK] ");

                &printLogAC(3, "HAS NO RESTRICTION SITE...");
                #if (($m13Seq =~ /GAATGC/) || ($m13Seq =~ /CTTACG/) ||	#BSM1
                #    ($m13Seq =~ /GATATC/) || ($m13Seq =~ /CTATAG/) ||	#ECORV
                #    ($m13Seq =~ /GAGCTC/) || ($m13Seq =~ /CTCGAG/))	    #SCAI
                #{ &printLogAC(0, "HAS RESTRICTION 1...\n"); };
                if ((index($m13Seq, "GAATGC")) != -1 ) { &printLogAC(4, "HAS RESTRICTION SITE BSM1  GAATGC \t$m13Seq\n"); last; };#BSM1
                if ((index($m13Seq, "CTTACG")) != -1 ) { &printLogAC(4, "HAS RESTRICTION SITE BSM1  CTTACG \t$m13Seq\n"); last; };#BSM1
                if ((index($m13Seq, "GATATC")) != -1 ) { &printLogAC(4, "HAS RESTRICTION SITE ECORV GATATC \t$m13Seq\n"); last; };#ECORV
                if ((index($m13Seq, "CTATAG")) != -1 ) { &printLogAC(4, "HAS RESTRICTION SITE ECORV CTATAG \t$m13Seq\n"); last; };#ECORV
                if ((index($m13Seq, "GAGCTC")) != -1 ) { &printLogAC(4, "HAS RESTRICTION SITE SCAI  GAGCTC \t$m13Seq\n"); last; };#SCAI
                if ((index($m13Seq, "CTCGAG")) != -1 ) { &printLogAC(4, "HAS RESTRICTION SITE SCAI  CTCGAG \t$m13Seq\n"); last; };#SCAI
                &printLogAC(3, "[OK] ");

                &printLogAC(3, "M13 PROPER GC%...");
                my $m13GC   = $tools->countGC($m13Seq);
                if ( ! (($m13GC >= $m13MinGc)        && ($m13GC <=      $m13MaxGc))  ) { &printLogAC(4, "M13 WRONG GC% $m13GC ! ] $m13MinGc, $m13MaxGc [ \t$m13Seq\n"); next; };;
                &printLogAC(3, "[$m13GC - OK] ");

                my $m13Tm = $tools->tmMLPA($m13Seq, $m13GC, $NaK);

                &printLogAC(3, "M13 PROPER TM...");
                if ( $m13Tm > $m13MaxTm)                                               { &printLogAC(4, "M13 WRONG TM $m13Tm ! ] $m13MinTm, $m13MaxTm [ \t$m13Seq\n"); last; };
                if ( ! (($m13Tm >=       $m13MinTm)  && ($m13Tm <=      $m13MaxTm))  ) { &printLogAC(4, "M13 WRONG TM $m13Tm ! ] $m13MinTm, $m13MaxTm [ \t$m13Seq\n"); next; };
                &printLogAC(3, "[$m13Tm - OK] ");

                &printLogAC(3, "M13 PROPER TMDIFF...");
                if (( $m13Tm > $ligTm ) && ( ($m13Tm - $ligTm) > 5))                   { &printLogAC(4, "WRONG TM DIFF ($m13Tm - $ligTm) > 5 \t$m13Seq\n"); next; };
                if (( $ligTm > $m13Tm ) && ( ($ligTm - $m13Tm) > 5))                   { &printLogAC(4, "WRONG TM DIFF ($ligTm - $m13Tm) > 5 \t$m13Seq\n"); next; };
                &printLogAC(3, "[OK] ");

                &printLogAC(3, "M13 LAST 3 BP GC%...");
                $m13Three = substr($m13Seq, 0, 3);
                if (($m13Three =~ tr/GCgc//) > $maxGCLS) { &printLogAC(4, "M13 LAST 3 NUC HAVE TOO MUCH GC\t$m13Seq\n"); next; };
                &printLogAC(3, "[$m13Three - OK] ");

                if ($checkQual)
                {
                    &printLogAC(3, "M13 ENTROPY...");
                    my $entropyM13  = &complexity::seFast($m13Seq);
                    if ($entropyM13) { &printLogAC(4, "HAS ENTROPY $entropyM13\t$m13Seq\n"); last; };
                    &printLogAC(3, "[$entropyM13 - OK] ");

                    &printLogAC(3, "M13 MASK...");
                    my $maskM13  = &complexity::masker($m13Seq, $minRepeatLegth, $minRepeatNumber);
                    if ($maskM13) { &printLogAC(4, "HAS MASK $maskM13\t$m13Seq\n"); $found = 1; $ligStart += $maskM13; last; };
                    if ( ! defined $maskM13) { die "COMPLEXITY RETURNED NULL\t$m13Seq"; };
                    &printLogAC(3, "[$maskM13 - OK] ");

                    &printLogAC(3, "M13 FOLDING...");
                    my $seqFoldM13 = &folding::checkFolding($m13Seq);
                    if ($seqFoldM13) { &printLogAC(4, "FOLDS $seqFoldM13\t$m13Seq\n"); last; };
                    &printLogAC(3, "M13 [$seqFoldM13 - OK]\n");
                }

                my $allSeq = $ligSeq . $m13Seq;
                my $allLen = length($allSeq);
                &printLogAC(3, "ALL: $allSeq... ");

                #&printLogAC(3, "ALL ENTROPY...");
                #my $entropyAll  = &complexity::seFast($allSeq);
                #if ($entropyAll) { &printLogAC(4, "HAS ENTROPY $entropyAll\t$m13Seq\n"); last; };
                #&printLogAC(3, "[$entropyAll - OK] ");
                #
                #&printLogAC(3, "ALL MASK...");
                #my $maskAll  = &complexity::masker($allSeq, $minRepeatLegth, $minRepeatNumber);
                #if ($maskAll) { &printLogAC(4, "HAS MASK $maskAll\t$m13Seq\n"); $found = 1; $ligStart += $maskAll; last; };
                #if ( ! defined $maskAll) { die "MASKER RETURNED NULL"; };
                #&printLogAC(3, "[$maskAll - OK] ");

                if ($checkQual)
                {
                    &printLogAC(3, "ALL FOLDING...");
                    my $seqFoldAll = &folding::checkFolding($allSeq);
                    if ($seqFoldAll) { &printLogAC(4, "FOLDS $seqFoldAll\n"); last; };
                    &printLogAC(3, "[OK]\n");
                }

                #my $allGC     = $tools->countGC($allSeq); # todo, delete to be faster
                #my $allTm     = $tools->tmMLPA($allSeq, $allGC, $NaK);

                my $ligStartF = $ligStart;
                my $m13StartF = $m13Start;
                my $m13EndF   = $m13End;

                if ( $revC ) # 0 = fwd 1 = rev
                {
                    $ligStartF = $sequenceLength - $ligStart+1;
                    $m13StartF = $sequenceLength - $m13Start+1;
                    $m13EndF   = $sequenceLength - $m13End+1;
                } #end if rev

                # $frag = $dnaCode->dna2digit($frag);

                &printLogAC(2, "        PUSHING...\n");
                #push (@$probe, [$strand, ($ligStartF+$offset), ($m13StartF+$offset), ($m13EndF+$offset),
                #push (@$probe, [$strand, ($ligStartF+$offset), $ligLen, $allLen,
                #                $ligSeq, $ligGC, $ligTm,
                #                $m13Seq, $m13GC, $m13Tm,
                #                $allSeq, $allGC, $allTm,
                #                substr($ligSeq, -10) . substr($m13Seq, 0, 10)]);

                push (@$probe, [$strand, ($ligStartF+$offset), $allLen, $allSeq, $ligLen]);
                #substr($ligSeq, -10) . substr($m13Seq, 0, 10)

                #ADDS TO REFERENCE ARRAY:
                 #00 $strand
                 #01 ($ligStartF+$offset)
                 #02 $allLen
                 #03 $allSeq
                 #04 $ligLen


                #push (@$probe, [$strand, ($ligStartF+$offset), $ligLen, $allLen,
                #                $ligSeq, $ligGC, $ligTm,
                #                $m13Seq, $m13GC, $m13Tm,
                #                $allSeq, $allGC, $allTm,
                #                substr($ligSeq, -10) . substr($m13Seq, 0, 10)]);


                #push (@$probe, [$strand, ($ligStartF+$offset), $ligLen, $allLen,
                #    $dnaCode->dna2digit($ligSeq), $ligGC, $ligTm,
                #    $dnaCode->dna2digit($m13Seq), $m13GC, $m13Tm,
                #    $dnaCode->dna2digit($allSeq), $allGC, $allTm,
                #    $dnaCode->dna2digit(substr($ligSeq, -10) . substr($m13Seq, 0, 10))]);

                &printLogAC(2, "        DONE\n");

                &printLogAC(1, "        ",
                            ($ligStartF+$offset), ", ", $ligLen, ", ", $allLen, ", ",
                            $allSeq, ", ", substr($ligSeq, -10) . substr($m13Seq, 0, 10), "\n");

                $countValAll++;
                $found = 1;
            }; # END FOR MY M13LEN
            &printLogAC(3, "\n");
        }; # END FOR MY LIGLEN
        &printLogAC(3, "\n");
        $ligStart++;
    } # END FOR MY $LIGSTART

    #print "MLPAOO ACTED\n";
    return ($ite, $countValAll, $centimo, $maxLigLen);
}


sub toSql
{
    my $self       = shift;
    my $orgId      = $_[0];
    my $chrom      = $_[1];
    my $derivated  = $_[2];
    my $localProbe = $_[3];

    my $allSeq = ${$localProbe}[3];
    my $ligLen = ${$localProbe}[4];
    my $ligant = substr($allSeq, ($ligLen - 10), 20);

	return "(\'" .  $orgId             . "\',\'" . $chrom             . "\',\'" .
                    ${$localProbe}[0]  . "\',\'" . ${$localProbe}[1]  . "\',\'" .
                    ${$localProbe}[2]  . "\',\'" . $allSeq            . "\',\'" .
                    $ligLen            . "\',\'" . $derivated         . "\',\'" .
                    $ligant            . "\')";

        #ADDS TO REFERENCE ARRAY:
        #00 $strand
        #01 ($ligStartF+$offset)
        #02 $allLen
        #03 $allSeq
        #04 $ligLen

}


sub toTab
{
    my $self       = shift;
    my $orgId      = $_[0];
    my $chrom      = $_[1];
    my $derivated  = $_[2];
    my $localProbe = $_[3];

    my $allSeq = ${$localProbe}[3];
    my $ligLen = ${$localProbe}[4];
    my $ligant = substr($allSeq, ($ligLen - 10), 20);

    return  $orgId             . "\t" . $chrom             . "\t" . ${$localProbe}[0]  . "\t" .
            ${$localProbe}[1]  . "\t" . ${$localProbe}[2]  . "\t" . $allSeq            . "\t" .
            $ligLen            . $derivated                . "\t" . $ligant            . "\n";

    #ADDS TO REFERENCE ARRAY:
     #00 $strand
     #01 ($ligStartF+$offset)
     #02 $allLen
     #03 $allSeq
     #04 $ligLen
}

sub toHad
{
    my $self       = shift;
    my $orgId      = $_[0];
    my $chrom      = $_[1];
    my $derivated  = $_[2];
    my $localProbe = $_[3];

    my $allSeq = ${$localProbe}[3];
    my $ligLen = ${$localProbe}[4];
    my $ligant = substr($allSeq, ($ligLen - 10), 20);

    return  $ligant           . "\t"   . # ligant
            $orgId            . "{"    . #
            $chrom            . "[("   . #
            ${$localProbe}[0] . ","    . # strand
            ${$localProbe}[1] . ","    . # lig pos
            $allSeq           . ","    . # allSeq
            $ligLen           . ")]}\n"; # ligLen


    #ADDS TO REFERENCE ARRAY:
     #00 $strand
     #01 ($ligStartF+$offset)
     #02 $allLen
     #03 $allSeq
     #04 $ligLen
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

#-rw-rw-r-- 1 saulo saulo 171456051 2010-01-15 16:25 Yarrowia_lipolytica_strain_CLIB122_CHROMOSSOMES.fasta.0001.001.F.mlpa.had
#-rw-rw-r-- 1 saulo saulo 171649988 2010-01-15 16:37 Yarrowia_lipolytica_strain_CLIB122_CHROMOSSOMES.fasta.0001.001.R.mlpa.had
#real	25m22.261s
#user	25m20.236s   1520s
#sys	00m01.602s
#6785 saulo     10 -10  967m 832m 2324 R 100.3 10.4  25:20.41 probe_extractor


#4.004.078 bytes / 1.520 s = 2.634 bytes/s = 2.57 kb/s = 154 Kb/min
#(171.649.988 bytes + 171.456.051 bytes) / 4.004.078 bytes = 343.106.039 / 4.004.078 = 85.7 times original size ON DISK
#872.415.232 bytes (967m) / 4.004.078 = 217.9 times original size ON RAM



1;
