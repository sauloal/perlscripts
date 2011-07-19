#!/usr/bin/perl -w
# Saulo Aflitos
# 2009 05 27 11 43
use strict;
use Algorithm::NeedlemanWunsch;
#use Benchmark qw( cmpthese timethese );
package blast;
use constant K => 0.711; 

# scoring scheme
my $MATCH          =  1; # +1 for letters that match
my $MISMATCH       = -1; # -1 for letters that mismatch
my $GAP            = -1; # -1 for any gap
my $dictionarySize = 64; # size of the vobabulary (a-z = 26 a-zA-Z=52)
my $verbose        = 0;
my $variables      = &lambda($MATCH, $MISMATCH, $dictionarySize);
my $minIdent       = 60; # MIN IDENTITY TO EXCLUDE. smaller more stringent

#my $st = "COELACANTH";
#my $nd = "PELICAN";
#my $rd = "PELICANM";
#my $th = "ASTROGILDO";

#my $res = &blastNW($nd, $rd); # global 1% slower


#&blastSW($st, $nd); # local 1% faster

#my $result = Benchmark::timethese(1_000_000,{
#"NW"    => sub {&blastNW($st, $rd)},
#"SW"    => sub {&blastSW($st, $rd)}
#}
#);
#Benchmark::cmpthese $result;

#&blastNW($nd, $th); # global
#&blastSW($nd, $th); # local

#&blastSW($st,$nd); # local
#&algNW($st, $nd);
#&algNW($nd, $rd);


##################################
#### NW ITERATORS
##################################
sub blastNWIterate
{
    my $Gresult = $_[0];
    my @input   = @_[1 .. (@_ - 1)];
    if ( ! @_ ){ print "BLASTNW :: NEEDS ARRAY REFS\n"; return; }


    if ( ! defined $Gresult ) { $Gresult = []; };


    foreach my $list (@input)
    {
        if (ref $list ne "ARRAY") { print "BLASTNW :: NOT A ARRAY REF\n"; return; }
    }

    my $listCount = 0;
    my $startTime = time;
    foreach my $list (@input)
    {
        $listCount++;
        my $count = 0;
        my $listSize      = @{$list};

        for (my $g = 0; $g < @{$Gresult}; $g++)
        {
            if ((defined $Gresult->[$g]) && ($Gresult->[$g] == -1)) { $Gresult->[$g] = undef; };
        }

        print "\tBLASTNW :: ANALIZING SIMILARITY : LIST $listCount($listSize)\n";

        for (my $l1 = 0; $l1 < $listSize; $l1++)
        {
            my $l1Seq  = \$list->[$l1];
            if ( (!( $Gresult->[$l1] )) && ( $$l1Seq ) )
            {
                $count++;
                print "\t\tBLASTNW :: $listCount;$count > $l1\n" if ( ! ($count % 100));
                my $l1Rc   = &dnaCode::digit2digitrc($$l1Seq);
                my $leng   = length($$l1Seq);
                for (my $l2 = 0; $l2 < $listSize; $l2++)
                {
                    my $l2Seq = \$list->[$l2];
                    if (($l1 != $l2) && ( $$l2Seq ))
                    {
                        if (( $$l2Seq ) && (( ! (defined $Gresult->[$l2])) || ($Gresult->[$l2] != -1)))
                        {
                            #my $result = &compDigit($list->[$l1], $list->[$l2]);
                            my $result = 0;
                            my $res    = &blastNW($$l1Seq, $$l2Seq);
                            my $ident  = $res->{identity};

                            if ($ident >= $minIdent)
                            {
                                print "\t\t  BLASTNW :: $listCount;$count : IDENTITY $ident MIN IDENT $minIdent POS L1 ", $l1. " \"", $$l1Seq ,"\" POS L2 ", $l2, " \"", $$l2Seq, "\" ALIGN \"", $res->{align1},"\" - \"",$res->{align2},"\"\n";
                                $Gresult->[$l1] += 1_000;
                                $Gresult->[$l2] += 1_000;
                                next;
                            }
                            else
                            {
                                my $rc      = &blastNW($l1Rc, $$l2Seq);
                                my $identRc = $res->{identity};

                                if ($identRc >= $minIdent)
                                {
                                    print "\t\t  BLASTNW :: $listCount;$count : IDENTITY $identRc MIN IDENT $minIdent POS L1 ", $l1. " \"", $$l1Seq ,"\" POS L2 ", $l2, " \"", $$l2Seq,"\" ALIGN \"", $res->{align1},"\" - \"",$res->{align2},"\"\n";
                                    $Gresult->[$l1] += 10_000;
                                    $Gresult->[$l2] += 10_000;
                                    next;
                                }
                            }
                            $Gresult->[$l1] = -1;
                        } # end if l2seq
                    } # end if l1 != l2 and ! defined gresult
                } # end for l2
                #print "\n";
            } # end if ! define gresult and ! defubed l1seq
        } # end for my l1
    } # end for my list


    my $resultValid   = 0;
    my $resultInValid = 0;
    for (my $p = 0; $p < @{$Gresult}; $p++)
    {
        my $resultSum = $Gresult->[$p];

        if (defined $resultSum)
        {
            if ($resultSum == "-1")
            {
                $resultSum     = undef;
                $Gresult->[$p] = undef;
                $resultValid++;
            }
            else
            {
                $resultInValid++;
            }
        }
        else
        {
            #$resultValid++;
        }
    }

#   print "BLASTNW :: VALID: ", $resultValid," INVALID: ", $resultInValid,"\n";
#   print "BLASTNW :: TOOK ", (int((time - $startTime)+.5)), "s\n\n\n";
    return $Gresult;
}





sub blastNWIterateTwo
{
    my $Gresult = $_[0];
    my @input   = @_[1 .. (@_ - 1)];
    if ( ! @_ ){ print "BLASTNWTWO :: NEEDS ARRAY REFS\n"; return; }

    if ( ! defined $Gresult ) { $Gresult = []; };

    if (@input % 2) { die "BLASTNWTWO :: NEEDS A EVEN NUMBER OF ARRAYS: ", (scalar @input), " ARRAYS GIVEN\n" };

    foreach my $list (@input)
    {
        if (ref $list ne "ARRAY") { print "BLASTNWTWO :: NOT A ARRAY REF\n"; return; }
    }

    my $listCount = 0;
    my $startTime = time;
    for (my $lc = 0; $lc < @input; $lc+=2)
    {
        $listCount++;
        my $count     = 0;
        my $list      = $input[$lc];
        my $list2     = $input[$lc+1];
        my $listSize  = @{$list};
        my $list2Size = @{$list2};
        my $listSizeValid = 0;

        for (my $g = 0; $g < @{$Gresult}; $g++)
        {
            if ((defined $Gresult->[$g]) && ($Gresult->[$g] == -1)) { $Gresult->[$g] = undef; };
        }

        for (my $g = 0; $g < @{$list}; $g++)
        {
            if (defined $list->[$g]) { $listSizeValid++; };
        }

        print "\tBLASTNWTWO :: ANALIZING SIMILARITY : LIST $listCount($listSizeValid)\n";

        for (my $l1 = 0; $l1 < $listSize; $l1++)
        {
            my $l1Seq  = \$list->[$l1];
            if ( ( $$l1Seq ) && ( ! ( defined $Gresult->[$l1] )) )
            {
                $count++;
                print "\t\tBLASTNWTWO :: $listCount;$count > $l1\n" if ( ! ($count % 100) );
                my $l1Rc   = &dnaCode::digit2digitrc($$l1Seq);
                my $leng   = length($$l1Seq);

                for (my $l2 = 0; $l2 < $list2Size; $l2++)
                {
                    my $l2Seq = \$list2->[$l2];
                    if (($l1 != $l2) && ( $$l2Seq ))
                    {
                        if (( ! (defined $Gresult->[$l2])) || ($Gresult->[$l2] != -1))
                        {
                            #my $result = &compDigit($list->[$l1], $list->[$l2]);
                            #my $result = 0;
                            my $res    = &blastNW($$l1Seq, $$l2Seq);
                            my $ident  = $res->{identity};

                            if ($ident >= $minIdent)
                            {
                                print "\t\t  BLASTNWTWO :: $listCount;$count : IDENTITY $ident MIN IDENT $minIdent POS L1 ", $l1. " \"", $$l1Seq ,"\" POS L2 ", $l2, " \"", $$l2Seq, "\" ALIGN \"", $res->{align1},"\" - \"",$res->{align2},"\"\n";
                                $Gresult->[$l1] += 1;
                                $Gresult->[$l2] += 1;
                                last;
                            }
                            else
                            {
                                my $rc      = &blastNW($l1Rc, $$l2Seq);
                                my $identRc = $res->{identity};

                                if ($identRc >= $minIdent)
                                {
                                    print "\t\t  BLASTNWTWO :: $listCount;$count : IDENTITYRC $identRc MIN IDENT $minIdent POS L1 ", $l1. " \"", $$l1Seq ,"\" POS L2 ", $l2, " \"", $$l2Seq, "\" ALIGN \"", $res->{align1},"\" - \"",$res->{align2},"\"\n";
                                    $Gresult->[$l1] += 10;
                                    $Gresult->[$l2] += 10;
                                    last;
                                }
                            } # end else if ident >= minident
                        } # end if l2seq
                    } # end if l1 != l2 and ! defined gresult
                } # end for l2
                if ( ! defined $Gresult->[$l1] ) { $Gresult->[$l1] = -1; };
                #print "\n";
            } # end if ! define gresult and ! defubed l1seq
        } # end for my l1
    } # end for my list


    my $resultValid   = 0;
    my $resultInValid = 0;
    for (my $p = 0; $p < @{$Gresult}; $p++)
    {
        my $resultSum = $Gresult->[$p];

        if (defined $resultSum)
        {
            if ($resultSum == "-1")
            {
                $resultSum     = undef;
                $Gresult->[$p] = undef;
                $resultValid++;
            }
            else
            {
                $resultInValid++;
            }
        }
        else
        {
            #$resultValid++;
        }
    }

    #print "BLASTNWTWO :: VALID: ", $resultValid," INVALID: ", $resultInValid,"\n";
    #print "BLASTNWTWO :: TOOK ", (int((time - $startTime)+.5)), "s\n\n\n";
    return $Gresult;
}




##################################
#### BLAST SMITH-WATERMAN (LOCAL)
##################################
sub blastSW()
{
#http://etutorials.org/Misc/blast/Part+II+Theory/Chapter+3.+Sequence+Alignment/3.2+Local+Alignment+Smith-Waterman/
    # Smith-Waterman  Algorithm

    # get sequences from command line
    my ($seq1, $seq2) = @_;

    # initialization
    my @matrix;
    $matrix[0][0]{score}   = 0;
    $matrix[0][0]{pointer} = "none";
    for(my $j = 1; $j <= length($seq1); $j++) {
        $matrix[0][$j]{score}   = 0;
        $matrix[0][$j]{pointer} = "none";
    }
    for (my $i = 1; $i <= length($seq2); $i++) {
        $matrix[$i][0]{score}   = 0;
        $matrix[$i][0]{pointer} = "none";
    }

    # fill
    my $max_i     = 0;
    my $max_j     = 0;
    my $max_score = 0;

    for(my $i = 1; $i <= length($seq2); $i++) {
        for(my $j = 1; $j <= length($seq1); $j++) {
            my ($diagonal_score, $left_score, $up_score);
            
            # calculate match score
            my $letter1 = substr($seq1, $j-1, 1);
            my $letter2 = substr($seq2, $i-1, 1);       
            if ($letter1 eq $letter2) {
                $diagonal_score = $matrix[$i-1][$j-1]{score} + $MATCH;
            }
            else {
                $diagonal_score = $matrix[$i-1][$j-1]{score} + $MISMATCH;
            }
            
            # calculate gap scores
            $up_score   = $matrix[$i-1][$j]{score} + $GAP;
            $left_score = $matrix[$i][$j-1]{score} + $GAP;
            
            if ($diagonal_score <= 0 and $up_score <= 0 and $left_score <= 0) {
                $matrix[$i][$j]{score}   = 0;
                $matrix[$i][$j]{pointer} = "none";
                next; # terminate this iteration of the loop
            }
            
            # choose best score
            if ($diagonal_score >= $up_score) {
                if ($diagonal_score >= $left_score) {
                    $matrix[$i][$j]{score}   = $diagonal_score;
                    $matrix[$i][$j]{pointer} = "diagonal";
                }
                else {
                    $matrix[$i][$j]{score}   = $left_score;
                    $matrix[$i][$j]{pointer} = "left";
                }
            } else {
                if ($up_score >= $left_score) {
                    $matrix[$i][$j]{score}   = $up_score;
                    $matrix[$i][$j]{pointer} = "up";
                }
                else {
                    $matrix[$i][$j]{score}   = $left_score;
                    $matrix[$i][$j]{pointer} = "left";
                }
            }
            
            # set maximum score
            if ($matrix[$i][$j]{score} > $max_score) {
                $max_i     = $i;
                $max_j     = $j;
                $max_score = $matrix[$i][$j]{score};
            }
        }
    }

    # trace-back

    my $align1 = "";
    my $align2 = "";

    my $j = $max_j;
    my $i = $max_i;

    my $score    = -100;
    my $gaps     = 0;
    my $match    = 0;
    my $mismatch = 0;

    while (1) {
        last if $matrix[$i][$j]{pointer} eq "none";
        
        if ($matrix[$i][$j]{pointer} eq "diagonal") {
            my $stLetter = substr($seq1, $j-1, 1);
            my $ndLetter = substr($seq2, $i-1, 1);

            $align1 .= $stLetter;
            $align2 .= $ndLetter;

            if ($stLetter eq $ndLetter) { $match++ }
            else  { $mismatch ++};
            $score = $matrix[$i][$j]{score} if ($matrix[$i][$j]{score} > $score);

            $i--; $j--;
        }
        elsif ($matrix[$i][$j]{pointer} eq "left") {
            $align1 .= substr($seq1, $j-1, 1);
            $align2 .= "-";
            $gaps++;
            $j--;
        }
        elsif ($matrix[$i][$j]{pointer} eq "up") {
            $align1 .= "-";
            $align2 .= substr($seq2, $i-1, 1);
            $gaps++;
            $i--;
        }   
    }

    $align1 = reverse $align1;
    $align2 = reverse $align2;
    $gaps   = (length($seq2) - $match);
    my $rawScore = ($match*$MATCH)+($mismatch*$MISMATCH)+($gaps*$GAP);

    my $result;
    $result->{align1}   = $align1;
    $result->{align2}   = $align2;
    $result->{scoreMax} = $score;
    $result->{scoreBit} = &bitScore($rawScore);
    $result->{scoreRaw} = $rawScore;
    $result->{gaps}     = $gaps;
    $result->{match}    = $match;
    $result->{mismatch} = $mismatch;
    $result->{identity} = int(($match/length($seq1))*100);

    if ($verbose){
        foreach my $key (sort keys %{$result})
        {
            print $key, " > ". $result->{$key}, "\n";
        }
    }
    return $result;
}


##################################
#### BLAST NEEDLEMAN-WUNSCH (GLOBAL)
##################################
sub blastNW()
{
#http://etutorials.org/Misc/blast/Part+II+Theory/Chapter+3.+Sequence+Alignment/3.1+Global+Alignment+Needleman-Wunsch/
# Needleman-Wunsch  Algorithm 
    my ($seq1, $seq2) = @_;
    # initialization
    my @matrix;
    $matrix[0][0]{score}   = 0;
    $matrix[0][0]{pointer} = "none";
    for(my $j = 1; $j <= length($seq1); $j++) {
        $matrix[0][$j]{score}   = $GAP * $j;
        $matrix[0][$j]{pointer} = "left";
    }
    for (my $i = 1; $i <= length($seq2); $i++) {
        $matrix[$i][0]{score}   = $GAP * $i;
        $matrix[$i][0]{pointer} = "up";
    }

    # fill
    for(my $i = 1; $i <= length($seq2); $i++) {
        for(my $j = 1; $j <= length($seq1); $j++) {
            my ($diagonal_score, $left_score, $up_score);

            # calculate match score
            my $letter1 = substr($seq1, $j-1, 1);
            my $letter2 = substr($seq2, $i-1, 1);                            
            if ($letter1 eq $letter2) {
                $diagonal_score = $matrix[$i-1][$j-1]{score} + $MATCH;
            }
            else {
                $diagonal_score = $matrix[$i-1][$j-1]{score} + $MISMATCH;
            }

            # calculate gap scores
            $up_score   = $matrix[$i-1][$j]{score} + $GAP;
            $left_score = $matrix[$i][$j-1]{score} + $GAP;

            # choose best score
            if ($diagonal_score >= $up_score) {
                if ($diagonal_score >= $left_score) {
                    $matrix[$i][$j]{score}   = $diagonal_score;
                    $matrix[$i][$j]{pointer} = "diagonal";
                }
                else {
                    $matrix[$i][$j]{score}   = $left_score;
                    $matrix[$i][$j]{pointer} = "left";
                }
            } else {
                if ($up_score >= $left_score) {
                    $matrix[$i][$j]{score}   = $up_score;
                    $matrix[$i][$j]{pointer} = "up";
                }
                else {
                    $matrix[$i][$j]{score}   = $left_score;
                    $matrix[$i][$j]{pointer} = "left";
                }
            }

        } #end for my j
    }#end for my i
    #end fill

    # trace-back

    my $align1 = "";
    my $align2 = "";

    # start at last cell of matrix
    my $j = length($seq1);
    my $i = length($seq2);

    my $score    = 100;
    my $gaps     = 0;
    my $match    = 0;
    my $mismatch = 0;
    while (1) {
        last if $matrix[$i][$j]{pointer} eq "none"; # ends at first cell of matrix

        if ($matrix[$i][$j]{pointer} eq "diagonal") {
            my $stLetter = substr($seq1, $j-1, 1);
            my $ndLetter = substr($seq2, $i-1, 1);

            $align1 .= $stLetter;
            $align2 .= $ndLetter;

            if ($stLetter eq $ndLetter) { $match++ }
            else  { $mismatch ++};
            $score = $matrix[$i][$j]{score} if ($matrix[$i][$j]{score} < $score);

            $i--;
            $j--;
        }
        elsif ($matrix[$i][$j]{pointer} eq "left") {
            $align1 .= substr($seq1, $j-1, 1);
            $align2 .= "-";
#           $score = $matrix[$i][$j]{score} if ($matrix[$i][$j]{score} < $score);
            $gaps++;
            $j--;
        }
        elsif ($matrix[$i][$j]{pointer} eq "up") {
            $align1 .= "-";
            $align2 .= substr($seq2, $i-1, 1);
#           $score = $matrix[$i][$j]{score} if ($matrix[$i][$j]{score} < $score);
            $gaps++;
            $i--;
        }    
    }

    $align1 = reverse $align1;
    $align2 = reverse $align2;
    my $rawScore = ($match*$MATCH)+($mismatch*$MISMATCH)+($gaps*$GAP);

    my $result;
    $result->{align1}   = $align1;
    $result->{align2}   = $align2;
    $result->{scoreMax} = $score;
    $result->{scoreBit} = &bitScore($rawScore);
    $result->{scoreRaw} = $rawScore;
    $result->{gaps}     = $gaps;
    $result->{match}    = $match;
    $result->{mismatch} = $mismatch;
    $result->{identity} = int(($match/length($seq1))*100);

    if ($verbose){
        foreach my $key (sort keys %{$result})
        {
            print $key, " > ". $result->{$key}, "\n";
        }
    }

    return $result;
}


##################################
#### BLAST - NeedlemanWunsch - GLOBAL - CPAN
##################################
sub algNW
{
    (my $a, my $b) = @_;
    my @a = split(//, $a);
    my @b = split(//, $b);

    # http://search.cpan.org/~vbar/Algorithm-NeedlemanWunsch-0.03/lib/Algorithm/NeedlemanWunsch.pm
    my $matcher = Algorithm::NeedlemanWunsch->new(\&score_sub);
    my $score = $matcher->align(
               \@a,
               \@b);
    if (0){
    print "ALGNW SCORE: $a vs $b -> ", $score,"\n";
    }
}
sub score_sub {
    if (!@_) {
        return -2; # gap penalty
    }

    return ($_[0] eq $_[1]) ? 1 : -1;
}



##################################
#### TOOLS
##################################
sub bitScore
{
    my $rawScore = $_[0];
    my $bitScore;

    $bitScore = (($variables->{lambdaBits} * $rawScore)-log(K));
#   $bitScore = (($variables->{lambdaNats} * $rawScore)-log(K))/log(2);
    return $bitScore;
}


sub lambda()
{
#http://etutorials.org/Misc/blast/Part+II+Theory/Chapter+4.+Sequence+Similarity/4.4+Target+Frequencies+lambda+and+H/
#Now let's determine the target frequencies of a +1/-1 scoring scheme. 
#We will explore this in the case of DNA alignments where match/mismatch scoring 
#is frequently employed. For generality, assume that all nucleotide frequencies 
#are equal to 0.25. This fixes the previous pi and pj terms. Example 4-1 shows a 
#Perl script that contains an implementation for estimating lambda by making 
#increasingly refined guesses at its value. Table 4-1 displays the expected score, 
#lambda, H, and the expected percent identity for several nucleotide scoring schemes. 
#Note that the match/mismatch ratio determines H and percent identity. As the 
#ratio approaches 0, lambda approaches 2 bits, and the target frequency 
#approaches 100 percent identity. Intuitively, this makes sense; if the 
#mismatch score is -figs/U221E.gif, all alignments have 100 percent identity, 
#and observing an A is the same as observing an A-A pair. 

#   use constant Pn => 0.25; # probability of any nucleotide

    die "usage: lambda(match, mismatch, dictionarySize)\n" unless @_ == 3;
    my ($match, $mismatch, $dicSize) = @_;
    my $Pn = 1/$dicSize;
    my $expected_score     = ($match * ($Pn)) + ($mismatch * (1-($Pn)));
    die "illegal scores for MATCH: $match (>0) MIS: $mismatch PN: $Pn EXP: $expected_score (<0)\n" if $match <= 0 or $expected_score >= 0;

    # calculate lambda
    my ($lambda, $high, $low) = (1, 2, 0); # initial estimates
    while ($high - $low > 0.001) {         # precision

        # calculate the sum of all normalized scores
        my $sum = $Pn * $Pn * exp($lambda * $match)    * $dicSize
                + $Pn * $Pn * exp($lambda * $mismatch) * (3*$dicSize);

        # refine guess at lambda
        if ($sum > 1) {
            $high   = $lambda;
            $lambda = ($lambda + $low)/2;
        }
        else {
            $low    = $lambda;
            $lambda = ($lambda + $high)/2;
        }
    }

    # compute target frequency and H
    my $targetID = $Pn * $Pn * exp($lambda * $match) * $dicSize;
    my $H = $lambda * $match    *     $targetID
          + $lambda * $mismatch * (1 -$targetID);

    # output
    my $result;
    $result->{expScore}    = $expected_score;
    $result->{lambdaNats}  = $lambda;
    $result->{lambdaBits}  = $lambda/log(2);
    $result->{Hnats}       = $H;
    $result->{Hbits}       = $H/log(2);
    $result->{percent}     = $targetID*100;

    if ($verbose){
        foreach my $key (sort keys %{$result})
        {
            print $key, " > ". $result->{$key}, "\n";
        }
    }
    return $result;
}

1;