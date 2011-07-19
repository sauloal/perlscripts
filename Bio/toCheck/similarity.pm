#!/usr/bin/perl -w
# Saulo Aflitos
# 2009 05 27 11 43
use strict;
package similarity;
use dnaCode;
use String::Approx 'adist';
# QUASIBLAST
my $MINSIZEPROP      = 3; # BIGGER MORE STRINGENT. minimum proportion of the sequence to make dictionary eg. having 3, for a 8bp, 1/3 = 2
my $MINWORDLEN       = 3; # SMALLER MORE STRINGENT. minimum word length size. has precedence over $MINSIZEPROP
my $MAXWORDLEN       = 7; # SMALLER MORE STRINGENT. maximum word length size. has precedence over $MINSIZEPROP
my $MAXAPPEARANCEMOD = 0; # SMALLER MORE STRINGENT. modifier to the maximum number of times a word can appear
# ALMOSTBLAST
my $minSub           = 6; # BIGGER MORE SITRINGENT. minimum number of substitutions (included) for ALMOSTBLAST
$| = 1;
#http://search.cpan.org/~jhi/String-Approx-3.26/Approx.pm



##################################
#### QUASI BLAST
##################################
sub quasiBlast
{
    my $Gresult = $_[0];
    my @input   = @_[1 .. (scalar @_ - 1)];
    if ( ! @_ ){ print "QUASIBLAST ::  NEEDS ARRAY REFS\n"; return; }

    if ( ! $Gresult ) { $Gresult = []; };

    foreach my $list (@input)
    {
        if (ref $list ne "ARRAY") { print "QUASIBLAST ::  NOT A ARRAY REF\n"; return; }
    }
    print "\tQUASIBLAST :: ANALIZING SIMILARITY\n";

    my $startTime = time;
    my $listCount = 0;
    foreach my $list (@input)
    {
        #http://www.perl.com/lpt/a/713
        $listCount++;
        my $listSize      = @{$list};
        my $minSize       = 1_000_000;
        my $maxSize       = 0;

        for (my $l1 = 0; $l1 < $listSize; $l1++)
        {
            my $l1Seq  = \$list->[$l1];
            if ($$l1Seq)
            {
                my $len = length($$l1Seq);
                $minSize = $len if ($len < $minSize);
                $maxSize = $len if ($len > $maxSize);
            }
        }

        my $avgSize       = int((($maxSize+$minSize)/2)+.5);
        my $maxAppearance = int(sqrt(&log10($listSize))+$MAXAPPEARANCEMOD);
        my $wordLength    = int(($avgSize / $MINSIZEPROP));
        if ($wordLength > $minSize)    { $wordLength = $minSize; };
        if ($wordLength < $MINWORDLEN) { $wordLength = $MINWORDLEN; };
        if ($wordLength > $MAXWORDLEN) { $wordLength = $MAXWORDLEN; };

        print "\t\tQUASIBLAST :: $listCount : PHRASES LIST SIZE: ", $listSize, " MINSIZE ", $minSize, " MAXSIZE ", $maxSize, " AVGSIZE ", $avgSize, " WORD LENGTH: ", $wordLength," MAX APPEARANCE: ", $maxAppearance, "\n";

        my %wordList;
        # makes word list
        for (my $l1 = 0; $l1 < $listSize; $l1++)
        {
            my $l1Seq  = \$list->[$l1];
            if ($$l1Seq)
            {
                
                my $l1RcSeq = &dnaCode::digit2digitrc($$l1Seq);

                for my $seq ($$l1Seq, $l1RcSeq)
                {
                    for (my $p = 0; $p < (length($seq)-$wordLength)+1; $p+=$wordLength)
                    {
                        $wordList{substr($seq, $p, $wordLength)}++;
                    }
                }
            }
        }

        my $WCvalid    = 0;
        my $WCnonValid = 0;
        my %wordListValid;
        my %wordListInValid;

        #makes list of forbiden words
        #print "WORD LIST SIZE: ", scalar(keys %wordList), "\n";
        foreach my $key (keys %wordList)
        {
            my $value = \$wordList{$key};
            if ($$value <= $maxAppearance)
            {
                $wordListValid{$key} = 0;
                $WCvalid++;
                #print $key, " > ", $$value, "\n";
            }
            else
            {
                $wordListInValid{$key} = 0;
                $WCnonValid++;
                #print $key, " > ", $$value, "\n";              
            }
        }
#       print "WC VALID: ", $WCvalid, " WC NON VALID: ", $WCnonValid, " WC TOTAL: ", ($WCvalid+$WCnonValid), "\n";

        my @resultWord;
        my $resultWordTotal   = 0;
        my $resultWordValid   = 0;
        my $resultWordInValid = 0;
        #check wich sequences doesnt contains the forbiden words
        for (my $l1 = 0; $l1 < $listSize; $l1++)
        {
            my $l1Seq  = \$list->[$l1];
            $resultWordTotal++;
            if (($$l1Seq) && ( ! defined $Gresult->[$l1] ))
            {
                my $l1RcSeq = &dnaCode::digit2digitrc($$l1Seq);
                my $found   = 0;

                for my $seq ($$l1Seq, $l1RcSeq)
                {
                    my $countApp = 0;
                    my $lenWord  = length($seq);
                    for (my $p = 0; $p < ($lenWord-$wordLength+1); $p+=$wordLength)
                    {
                        my $subs = substr($seq, $p, $wordLength);
                        if (exists $wordListInValid{$subs})
                        {
                            $resultWord[$l1]  = 1;
                            $Gresult->[$l1]  += 1;
                            $found            = 1;
                            $resultWordInValid++;

                            last;
                        }
#                       $countApp += $wordList{$subs};
#                       if ((($countApp*$wordLength)*.7) >= $lenWord)
#                       {
                        #   print "CRAZY COUNT ", (($countApp*$wordLength)),"\n";
#                           $resultWord[$l1] = 1;
#                           $result[$l1]     = 1;
#                           $found           = 1;
#                           $resultWordInValid++;

#                           last;
#                       }
                    }
                    if ($found) { last } else { $Gresult->[$l1] = -1; };
                }
            } # end if l1seq
        }

        $resultWordValid = $resultWordTotal - $resultWordInValid;
        print "\t\t\tQUASIBLAST :: RESULT : $listCount : PHRASE VALID = ", $resultWordValid," PHRASE INVALID = ", $resultWordInValid, " TOTAL PHRASES = ", ($resultWordValid+$resultWordInValid),"\n";
    }


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

    print "\tQUASIBLAST :: VALID : ", $resultValid," INVALID : ", $resultInValid,"\n";
    #print "QUASIBLAST :: TOOK ", (int((time - $startTime)+.5)), "s\n\n\n";
    return $Gresult;
}




##################################
#### ALMOST BLAST
##################################
sub almostBlast
{
    my $Gresult = $_[0];
    my @input   = @_[1 .. (scalar @_ - 1)];

    if ( ! $Gresult ) { $Gresult = []; };

    if ( ! @_ ){ print "ALMOSTBLAST :: NEEDS ARRAY REFS\n"; return; }
    foreach my $list (@input)
    {
        if (ref $list ne "ARRAY") { print "ALMOSTBLAST :: NOT A ARRAY REF\n"; return; }
    }

    my $startTime = time;
    my $listCount = 0;
    foreach my $list (@input)
    {
        $listCount++;
        my $listSize = @{$list};
        print "\tALMOSTBLAST :: ANALIZING SIMILARITY : LIST $listCount ($listSize rows)\n";
        my $count    = 0;

        for (my $g = 0; $g < @{$Gresult}; $g++)
        {
            if ((defined $Gresult->[$g]) && ($Gresult->[$g] == -1)) { $Gresult->[$g] = undef; };
        }

        for (my $l1  = 0; $l1 < $listSize; $l1++)
        {
            my $l1Seq = \$list->[$l1];
            if ( ( defined $$l1Seq ) && ( ! ( defined $Gresult->[$l1] )) )
            {
                $count++;
                print "\t\tALMOSTBLAST :: $listCount;$count > $l1\n" if ( ! ($count % 100));
                my $l1Rc   = &dnaCode::digit2digitrc($$l1Seq);
                my $leng   = length($$l1Seq);
                my $minSub = int(($leng * .1)+.5)+1; # minimum number of substitutions (included);

                for (my $l2 = 0; $l2 < $listSize; $l2++)
                {
                    my $l2Seq = \$list->[$l2];
                    if (($l1 != $l2) && ( $$l2Seq ))
                    {
                        if (( ! ( defined $Gresult->[$l2])) || ($Gresult->[$l2] != -1))
                        {
                            #my $result = &compDigit($list->[$l1], $list->[$l2]);
                            my $result = 0;

                            my $dist   = adist($$l1Seq, $$l2Seq);
                            if ($dist < 0) { $dist   *= -1; };

#                           print "\t SIMILARITY ", $l1. " [", $list->[$l1] ,"] ", $l2, " [", $list->[$l2], "]: ", $result, "\n";
                            if ($dist <= $minSub)
                            {
                                print "\t\t  ALMOSTBLAST :: $listCount;$count : SIMILARITY DIST $dist LENG $leng MIN SUB $minSub POS L1 ", $l1. " \"", $$l1Seq ,"\" POS L2 ", $l2, " \"", $$l2Seq, "\": ", $result, "\n";
                                $Gresult->[$l1] += 1;
                                $Gresult->[$l2] += 1;
#                               next;
                            }
                            else
                            {
                                my $distRc = adist($l1Rc, $$l2Seq);
                                if ($distRc < 0) { $distRc *= -1; };
                                if ($distRc <= $minSub)
                                {
                                    print "\t\t  ALMOSTBLAST :: $listCount;$count : SIMILARITY DISTRC $distRc LENG $leng MIN SUB $minSub POS L1 ", $l1. " \"", $$l1Seq ,"\" POS L2 ", $l2, " \"", $$l2Seq, "\": ", $result, "\n";
                                    $Gresult->[$l1] += 10;
                                    $Gresult->[$l2] += 10;
#                                   next;
                                }
                                else
                                {
                                    my $compRes = &dnaCode::compDigit($$l1Seq, $$l2Seq);
                                    if ($compRes)
                                    {
                                        print "\t\t  ALMOSTBLAST :: $listCount;$count : SIMILARITY COMP DIGIT $compRes DIST $dist LENG $leng MIN SUB $minSub POS L1 ", $l1. " \"", $$l1Seq ,"\" POS L2 ", $l2, " \"", $$l2Seq, "\": ", $result, "\n";
                                        $Gresult->[$l1] += 100;
                                        $Gresult->[$l2] += 100;
                                        #next;
                                    }
                                } #end else if distrc <= minsub
                            } # end else if dist <=min sub
                        }#end if listl2
                    }#end if l1 != l2
                }#end while l2 < listsize
                if ( ! defined $Gresult->[$l1] ) { $Gresult->[$l1] = -1; };
                #print "\n";
            } #end if resultl1 && lseq
        }#end l1 < listsize
    } #end foreach my list

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
            $resultValid++;
        }
    }

    print "\tALMOSTBLAST :: VALID : ", $resultValid," INVALID : ", $resultInValid,"\n";
#   print "ALMOSTBLAST :: TOOK ", (int((time - $startTime)+.5)), "s\n\n\n";
    return $Gresult;
}



##################################
#### ACESSORIES
##################################
sub getSimilaritiesMatrix
{
    my @inputs = @_;
    if ( ! (@inputs))   { die "NO INPUTS DEFINED"};
    if ( @inputs == 1 ) { die "ONLY 1 INPUT DEFINED"};

    my $dimensions = @inputs;

    my @results;
    for (my $row = 0; $row < $dimensions; $row++)
    {
        my @dist = adist($inputs[$row], @inputs);
        $results[$row] = \@dist;
    }

    my @answer = (0) x $dimensions;
    for (my $row = 0; $row < $dimensions; $row++)
    {
#       print "$inputs[$row] ";
        for (my $col = 0; $col < $dimensions; $col++)
        {
            if (($row != $col) && ($results[$row][$col] <= $minSub)) {$answer[$row]++; $answer[$col]++;  }; #print "ROW $row COL $col $inputs[$row] $inputs[$col] VALUE $results[$row][$col]\n"; };
        }
#       print "\n";
    }

#   for (my $k = 0; $k < $dimensions; $k++)
#   {
#       print "$k > $answer[$k]\t";
#       if ( ! ($k % 5)) { print "\n"; };
#   }

#   for (my $row = 0; $row < $dimensions; $row++)
#   {
#       print "$inputs[$row] ";
#       for (my $col = 0; $col < $dimensions; $col++)
#       {
#           print $results[$row][$col] . " "x10;
#       }
#       print "\n";
#   }
    return \@answer;
}


sub log10 {
    my $n = shift;
    return log($n)/log(10);
}











#http://search.cpan.org/~jhi/String-Approx-3.26/Approx.pm

#   my @inputs;
#   open FILE, "<resultset.txt" or die "couldnt";
#   while (<FILE>)
#   {
#       chomp;
#       push(@inputs, $_);
#   }

#   $dimensions = @inputs;

#   my @results;
#   for (my $row = 0; $row < $dimensions; $row++)
#   {
#       my @dist = adist($inputs[$row], @inputs);
#       $results[$row] = \@dist;
#   }

    #print " "x11 . join(" ", @inputs[0 .. ($dimensions-1)]) . "\n";

#   for (my $row = 0; $row < $dimensions; $row++)
#   {
        #print "$inputs[$row] ";
#       for (my $col = 0; $col < $dimensions; $col++)
#       {
            #print $results[$row][$col] . " "x10;
#       }
        #print "\n";
#   }
#   print "\n";


1;