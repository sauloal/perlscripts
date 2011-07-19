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
my $minIdent       = 50; # MIN IDENTITY TO EXCLUDE IN %. smaller more stringent

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
		my $count     = 0;
		my $listSize  = @{$list};
		my $countList;

		for (my $l = 0; $l < $listSize; $l++)
		{
			if (defined $list->[$l])
			{
				$countList++;
			}
		}

		for (my $g = 0; $g < @{$Gresult}; $g++)
		{
			my $gg = $Gresult->[$g];
			if ((defined $$gg) && ($$gg == -1)) { $$gg = undef; };
		}

		print "\tBLASTNW :: ANALIZING SIMILARITY : LIST $listCount($listSize rows / $countList valid rows)\n";

		for (my $l1 = 0; $l1 < $listSize; $l1++)
		{
			my $l1Seq  = \$list->[$l1];
			next if ( ! defined $$l1Seq );
			my $gL1    = \$Gresult->[$l1]; 
			next if ( defined $$gL1 );

			$count++;

			if ( ! ( $count % 1 ) )
			{
				printf "\t\t#: % " . (length($listSize)) . "d [ID: % ".(length($listSize))."d]  ", $count, $l1;
				my $elapsed  = (time-$startTime);
				my $elapsedS = &sec2time($elapsed);
				my $ETA      = &sec2time(int((($countList-$count)/$count)*$elapsed));

				printf " BLASTNW :: %02d:% ".(length($listSize))."d > % ".(length($listSize))."d >> ELAPSED: %s (ETA: %s)\n",$listCount,$count,$l1,$elapsedS,$ETA;
			}



			my $l1Rc        = &dnaCode::digit2digitrc($$l1Seq);
			my $leng        = length($$l1Seq);
			my $l2Count     = 0;
			my $startL2Time = time;
			for (my $l2 = 0; $l2 < $listSize; $l2++)
			{
				my $l2Seq = \$list->[$l2];
				next if ( $l1 == $l2 );
				next if ( ! defined $$l2Seq );
				my $gL2 = \$Gresult->[$l2];
				next if (( defined $$gL2 ) && ($$gL2 == -1));
				$l2Count++;

				if ( ! ( $l2Count % 1000 ) )
				{
					printf "\t\t\t#: % ".(length($listSize))."d [ID: % ".(length($listSize))."d]  ", $l2Count, $l2;
					my $elapsed  = (time-$startL2Time);
					my $elapsedS = &sec2time($elapsed);
					my $ETA      = &sec2time(int((($countList-$l2Count)/$l2Count)*$elapsed));

					printf " BLASTNW :: %02d:% ".(length($listSize))."d > % ".(length($listSize))."d >> ELAPSED: %s (ETA: %s)\n",$listCount,$l2Count,$l2,$elapsedS,$ETA;
				}


				my $ident  = &blastNWFast($$l1Seq, $$l2Seq);

				if ($ident >= $minIdent)
				{
					print "\t\t  BLASTNW :NO: ",$listCount,":",$l1,"x",$l2,"(",$count,") : IDENTITY ",$ident," MIN IDENT ",$minIdent," POS L1 ", $l1, " \"", $$l1Seq ,"\" POS L2 ", $l2, " \"", $$l2Seq, "\n";
					$$gL1 += 1_000;
					$$gL2 += 1_000;
					#next;
				}
				else
				{
					my $identRc = &blastNWFast($l1Rc, $$l2Seq);
#sw		2m00s 08m10s
#nw		2m02s 08m18s
#nwfast	2m03s 08m04s
					if ($identRc >= $minIdent)
					{
						print "\t\t  BLASTNW :NORC: ",$listCount,":",$l1,"x",$l2,"(",$count,") : IDENTITY ",$identRc," MIN IDENT ",$minIdent," POS L1 ", $l1, " \"", $l1Rc ,"\" POS L2 ", $l2, " \"", $$l2Seq, "\n";
						$$gL1 += 10_000;
						$$gL2 += 10_000;
						#next;
					}
					else
					{
						#print "BLASTNW :OK: ",$listCount,":",$l1,"x",$l2,"(L1:",$count,", L2:",$l2Count,") : IDENTITY ",$ident," MIN IDENT ",$minIdent," POS L1 ", $l1, " \"", $$l1Seq ,"\" POS L2 ", $l2, " \"", $$l2Seq, "\" ALIGN \"", $res->{align1},"\" - \"",$res->{align2},"\"\n";
					}
				}
			} # end for l2
			if ( ! defined $$gL1 ) { $$gL1 = -1; };
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

	print "BLASTNW :: VALID: ", $resultValid," INVALID: ", $resultInValid,"\n";
	print "BLASTNW :: TOOK ", (int((time - $startTime)+.5)), "s\n\n\n";
	return $Gresult;
}

sub sec2time
{
	my $in    = shift;
	my $days  = int((($in/60)/60)/24);
	my $hours = int(($in/60)/60) - ($days * 24);
	my $mins  = int($in/60) - ($days * 24 * 60) - ($hours * 60);
	my $secs  = $in - ($days * 24 * 60 * 60) - ($hours * 60 * 60) - ($mins * 60);
	my $time  = sprintf("%02dd %02dh %02dm %02ds",$days, $hours, $mins, $secs);
	return $time;
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
								my $identRc = $rc->{identity};

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
	$matrix[0][0][0] = 0;
	$matrix[0][0][1] = 0;
	for(my $j = 1; $j <= length($seq1); $j++) {
		$matrix[0][$j][0] = 0;
		$matrix[0][$j][1] = 0;
	}
	for (my $i = 1; $i <= length($seq2); $i++) {
		$matrix[$i][0][0] = 0;
		$matrix[$i][0][1] = 0;
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
		        $diagonal_score = $matrix[$i-1][$j-1][0] + $MATCH;
		    }
		    else {
		        $diagonal_score = $matrix[$i-1][$j-1][0] + $MISMATCH;
		    }
		    
		    # calculate gap scores
		    $up_score   = $matrix[$i-1][$j][0] + $GAP;
		    $left_score = $matrix[$i][$j-1][0] + $GAP;
		    
		    if ($diagonal_score <= 0 and $up_score <= 0 and $left_score <= 0) {
		        $matrix[$i][$j][0] = 0;
		        $matrix[$i][$j][1] = 0;
		        next; # terminate this iteration of the loop
		    }
		    
		    # choose best score
		    if ($diagonal_score >= $up_score) {
		        if ($diagonal_score >= $left_score) {
		            $matrix[$i][$j][0] = $diagonal_score;
		            $matrix[$i][$j][1] = 3;
		        }
		        else {
		            $matrix[$i][$j][0] = $left_score;
		            $matrix[$i][$j][1] = 1;
		        }
		    } else {
		        if ($up_score >= $left_score) {
		            $matrix[$i][$j][0] = $up_score;
		            $matrix[$i][$j][1] = 2;
		        }
		        else {
		            $matrix[$i][$j][0] = $left_score;
		            $matrix[$i][$j][1] = 1;
		        }
		    }
		    
		    # set maximum score
		    if ($matrix[$i][$j][0] > $max_score) {
		        $max_i     = $i;
		        $max_j     = $j;
		        $max_score = $matrix[$i][$j][0];
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
		last if $matrix[$i][$j][1] == 0;
		
		if ($matrix[$i][$j][1] == 3) {
			my $stLetter = substr($seq1, $j-1, 1);
			my $ndLetter = substr($seq2, $i-1, 1);

		    $align1 .= $stLetter;
		    $align2 .= $ndLetter;

			if ($stLetter eq $ndLetter) { $match++ }
			else  { $mismatch ++};
			$score = $matrix[$i][$j][0] if ($matrix[$i][$j][0] > $score);

		    $i--; $j--;
		}
		elsif ($matrix[$i][$j][1] == 1) {
		    $align1 .= substr($seq1, $j-1, 1);
		    $align2 .= "-";
			$gaps++;
		    $j--;
		}
		elsif ($matrix[$i][$j][1] == 2) {
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
	$result->[1]   = $align1;
	$result->[2]   = $align2;
	$result->[0] = int(($match/length($seq1))*100);

	return $result;
}


sub blastSWoriginal()
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
sub blastNWFast()
{
#http://etutorials.org/Misc/blast/Part+II+Theory/Chapter+3.+Sequence+Alignment/3.1+Global+Alignment+Needleman-Wunsch/
# Needleman-Wunsch  Algorithm 
#[0] = score
#[1] = pointer
#0 = none
#1 = left
#2 = up
#3 = diagonal

	my ($seq1, $seq2) = @_;
	# initialization
	my @matrix;
	$matrix[0][0][0] = 0;
	$matrix[0][0][1] = 0;
	my $lSeq1 = length($seq1);
	my $lSeq2 = length($seq2);

	for(my $j = 1; $j <= $lSeq1; $j++) {
		$matrix[0][$j][0] = $GAP * $j;
		$matrix[0][$j][1] = 1;
	}
	for (my $i = 1; $i <= $lSeq2; $i++) {
		$matrix[$i][0][0] = $GAP * $i;
		$matrix[$i][0][1] = 2;
	}

	# fill
	for(my $i = 1; $i <= $lSeq2; $i++) {
		for(my $j = 1; $j <= $lSeq1; $j++) {
		    my ($diagonal_score, $left_score, $up_score);

		    # calculate match score
		    my $letter1 = substr($seq1, $j-1, 1);
		    my $letter2 = substr($seq2, $i-1, 1);                            
		    if ($letter1 eq $letter2) {
		        $diagonal_score = $matrix[$i-1][$j-1][0] + $MATCH;
		    }
		    else {
		        $diagonal_score = $matrix[$i-1][$j-1][0] + $MISMATCH;
		    }

		    # calculate gap scores
		    $up_score   = $matrix[$i-1][$j][0] + $GAP;
		    $left_score = $matrix[$i][$j-1][0] + $GAP;

		    # choose best score
		    if ($diagonal_score >= $up_score) {
		        if ($diagonal_score >= $left_score) {
		            $matrix[$i][$j][0] = $diagonal_score;
		            $matrix[$i][$j][1] = 3;
		        }
		    	else {
		            $matrix[$i][$j][0] = $left_score;
		            $matrix[$i][$j][1] = 1;
		        }
		    } else {
		        if ($up_score >= $left_score) {
		            $matrix[$i][$j][0] = $up_score;
		            $matrix[$i][$j][1] = 2;
		        }
		        else {
		            $matrix[$i][$j][0] = $left_score;
		            $matrix[$i][$j][1] = 1;
		        }
		    }

		} #end for my j
	}#end for my i
	#end fill

	# trace-back

	# start at last cell of matrix
	my $j = $lSeq1;
	my $i = $lSeq2;

	my $score    = 100;
	my $gaps     = 0;
	my $match    = 0;
	my $mismatch = 0;
	while (1) {
		last if $matrix[$i][$j][1] == 0; # ends at first cell of matrix

		if ($matrix[$i][$j][1] == 3) {
			my $stLetter = substr($seq1, $j-1, 1);
			my $ndLetter = substr($seq2, $i-1, 1);

			if ($stLetter eq $ndLetter) { $match++ }

		    $i--;
		    $j--;
		}
		elsif ($matrix[$i][$j][1] == 1) {
		    $j--;
		}
		elsif ($matrix[$i][$j][1] == 2) {
		    $i--;
		}    
	}

	my $result = int(($match/$lSeq1)*100);

	return $result;
}





sub blastNWOriginal()
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
#			$score = $matrix[$i][$j]{score} if ($matrix[$i][$j]{score} < $score);
			$gaps++;
		    $j--;
		}
		elsif ($matrix[$i][$j]{pointer} eq "up") {
		    $align1 .= "-";
		    $align2 .= substr($seq2, $i-1, 1);
#			$score = $matrix[$i][$j]{score} if ($matrix[$i][$j]{score} < $score);
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
#	$bitScore = (($variables->{lambdaNats} * $rawScore)-log(K))/log(2);
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

#	use constant Pn => 0.25; # probability of any nucleotide

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
