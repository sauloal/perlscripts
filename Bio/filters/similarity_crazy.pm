#!/usr/bin/perl -w
# Saulo Aflitos
# 2009 05 27 11 43
use strict;
package similarity;
use dnaCode;
use String::Approx 'adist';
use Fcntl;

use Tie::Hash::Indexed;

use BerkeleyDB;
use DB_File ;

# QUASIBLAST
my $MINSIZEPROP      = 3; # BIGGER MORE STRINGENT. minimum proportion of the sequence to make dictionary eg. having 3, for a 8bp, 1/3 = 2
my $MINWORDLEN       = 3; # SMALLER MORE STRINGENT. minimum word length size. has precedence over $MINSIZEPROP
#my $MAXWORDLEN       = 7; # SMALLER MORE STRINGENT. maximum word length size. has precedence over $MINSIZEPROP
#my $MAXAPPEARANCEMOD = 0; # SMALLER MORE STRINGENT. modifier to the maximum number of times a word can appear
# ALMOSTBLAST
my $minSub           = 6; # BIGGER MORE SITRINGENT. minimum number of substitutions (included) for ALMOSTBLAST
$| = 1;
my $bdbFolder = "/mnt/ssd/probes";
#http://search.cpan.org/~jhi/String-Approx-3.26/Approx.pm



##################################
#### QUASI BLAST
##################################
sub quasiBlast
{
	my $Gresult = $_[0];
	my $list    = $_[1];
	my $extra   = $_[2];
	$extra |= 0;
	my $list2;
	if ( ! @_ ){ print "QUASIBLAST ::  NEEDS ARRAY REFS\n"; return; }

	if ( ! $Gresult ) { $Gresult = []; };

#	foreach my $list (@input)
#	{
#		if (ref $list ne "ARRAY") { print "QUASIBLAST ::  NOT A ARRAY REF\n"; return; }
#	}
	print "\tQUASIBLAST :: ANALIZING SIMILARITY\n";

	my $startTime = time;
	my $listCount = 0;

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
	my $wordLength    = int(($avgSize / $MINSIZEPROP)+.5) - $extra;
	if ($wordLength > $minSize)    { $wordLength = $minSize; };
	if ($wordLength < $MINWORDLEN) { $wordLength = $MINWORDLEN; };
	my $maxAppearance = int((&log10($listSize))-((&log10($listSize)/$wordLength)));
#		if ($wordLength > $MAXWORDLEN) { $wordLength = $MAXWORDLEN; };

#		my $avgSize       = int((($maxSize+$minSize)/2)+.5);
#		my $maxAppearance = int(sqrt(&log10($listSize))+$MAXAPPEARANCEMOD);
#		my $wordLength    = int(($avgSize / $MINSIZEPROP));
#		if ($wordLength > $minSize)    { $wordLength = $minSize; };
#		if ($wordLength < $MINWORDLEN) { $wordLength = $MINWORDLEN; };
#		if ($wordLength > $MAXWORDLEN) { $wordLength = $MAXWORDLEN; };


	my %wordListH;
	my @wordListA;

	`rm -f $bdbFolder/WordList*.db 2>/dev/null`;

	my $filenameH = "$bdbFolder/WordListH_";
	if ($wordLength < 10) { $filenameH .= "0"; };
	$filenameH .= "$wordLength.db";

	my $dbH = new DB_File::HASHINFO;
	if ( -f $filenameH )
	{
 		tie %wordListH, "DB_File", $filenameH, O_RDWR, $dbH 
		or die "Cannot open $filenameH: $!\n";
		print "\t\tREUSING EXISTING DB FILE: $filenameH\n";
	}
	else
	{
  		tie %wordListH, "DB_File", $filenameH, O_RDWR|O_CREAT, 0666, $dbH 
		or die "Cannot open $filenameH: $!\n";
		print "\t\tCREATING NEW DB FILE: $filenameH\n";
	}

	tie @wordListA, "BerkeleyDB::Recno", 
	    -Filename => "$bdbFolder/WordListA.db", 
        -Flags => DB_CREATE 
        or die "COULD NOT OPEN FILE $bdbFolder/WordListA.db : $! $BerkeleyDB::Error\n";

	my $expectWLA = int((($avgSize - $wordLength + 1) * $listSize)*.7);
#	(((26-9+1)*1335334)*.7) = 16825208
#                              1665334

#http://search.cpan.org/~beppu/Tie-Array-Pointer-0.000059/lib/Tie/Array/Pointer.pm
#	use Tie::Array::Pointer;
#	  tie @wordListA, 'Tie::Array::Pointer', {
#		length => $expectWLA,
#		type   => 'L',
#	  };




	print "\t\tQUASIBLAST :: $listCount : PHRASES LIST SIZE: ", $listSize, " MINSIZE ", $minSize, " MAXSIZE ", $maxSize, " AVGSIZE ", $avgSize, " WORD LENGTH: ", $wordLength," MAX APPEARANCE: ", $maxAppearance, "\n";
	my $time = time;
	# makes word list
	my $lastId = (scalar keys %wordListH);
	@wordListA = (0)x$lastId;

	my @modifiers = qw(16 4 1);

	my %dist;
	my %cumDist;
	my %cumDistPercentil;
	my $originalMaxAppearance = $maxAppearance;

	foreach my $modifier (@modifiers)
	{
		for (my $mod = 0; $mod < $modifier; $mod++)
		{
			my $listSlice = int($listSize / $modifier)+1;

			my $listStart = $mod     * $listSlice;
			my $listEnd   = ($mod+1) * $listSlice - 1;

			while ($listEnd > $listSize) { $listEnd--; };

#			for (my $slice = $listStart; $slice < $listEnd; $slice++)
			#{

	$maxAppearance = $originalMaxAppearance;
	print "MODIFIER $modifier MOD $mod LISTSTART $listStart LISTEND $listEnd\n";
	%wordListH = ();
	$lastId = (scalar keys %wordListH);
	@wordListA = (0)x$lastId;
	print "\t\t\t",$listSlice," > ";
	for (my $l1 = $listStart; $l1 < $listEnd; $l1++)
	{
		if ( ! (($l1-$listStart) % (int($listSlice/20)))) { print $l1, "..."; };
		if ( $Gresult->[$l1] ) { next; };
		my $l1Seq  = \$list->[$l1];
		if ($$l1Seq)
		{
			my $l1RcSeq = &dnaCode::digit2digitrc($$l1Seq);

			for my $seq ($l1Seq, \$l1RcSeq)
			{
				#for (my $p = 0; $p < (length($seq)-$wordLength)+1; $p+=$wordLength) # jumpiiinggggg
				for (my $p = 0; $p < (length($$seq)-$wordLength)+1; $p++) # slidiniingggg
				{
					my $sseq = substr($$seq, $p, $wordLength);
					my $id;

					if (exists $wordListH{$sseq}) { $id = $wordListH{$sseq}; }
					else { $id = $lastId++; $wordListH{$sseq} = $id; };

					if (defined $id)
					{
#							print $sseq, " ", $id, "\n";
						$wordListA[$id]++;
					}
					else
					{
						die "no id";
					}
				}
			}
		}
	}



	print "SO FAR SURVIVED: ", (time - $time), "s though\n";

	$time = time;
#untie %wordListH;

	my $WCvalid    = 0;
	my $WCnonValid = 0;
	%dist = ();
	%cumDist = ();

	my $wordListASize = @wordListA;
	print "\t\t\t",$wordListASize," > ";
	for (my $wa = 0; $wa < $wordListASize; $wa++)
	{
		if ( ! ($wa % (int($wordListASize/20)))) { print $wa, "..."; };
#			if ($$value <= $maxAppearance) OLD
		my $value = $wordListA[$wa];
		if ((defined $value) && ($value > 0))
		{
			$dist{$value}++;
			if ($value <= $maxAppearance)
			{
				#$v->[1] = 1;
				$WCvalid++;
				#print $key, " > ", $$value, "\n";
			}
			else
			{
				$WCnonValid++;
				#print $key, " > ", $$value, "\n";				
			}
		}
	}
	print "\n";

	foreach my $d (sort {$a <=> $b} keys %dist)
	{
		if ($dist{$d} > 0)
		{
			$cumDist{$d}  = $dist{$d};
			my $prevD = $d-1;
			while (( ! defined $cumDist{$prevD} ) && ($prevD > 0)) { $prevD--; };
			$cumDist{$d} += $cumDist{$prevD} if (defined $cumDist{$prevD});
			#print "\t\t\t", $d, " APPEARANCE APPEARED ", $dist{$d}, " TIMES\n";
		}
	}

	print "\n";
	%cumDistPercentil = ();

	foreach my $cd (sort {$a <=> $b} keys %cumDist)
	{
		if (defined $cumDist{$cd})
		{
			my $percentil = (int(($cumDist{$cd}/$wordListASize)*100));
			$cumDistPercentil{$cd} = $percentil;
			#print "\t\t\t", $cd, " APPEARANCE ACCUMULATES ", $cumDist{$cd}, " TIMES (", $percentil ,"%)\n";
			if ( $percentil < 50 ) { $maxAppearance = $cd };
		}
	}

	
	while ($maxAppearance > 1)
	{
		if (( defined $cumDistPercentil{$maxAppearance}) && ($cumDistPercentil{$maxAppearance} > 50))
		{
		 	$maxAppearance--;
		}
		elsif (( defined $cumDistPercentil{$maxAppearance}) && ($cumDistPercentil{$maxAppearance} <= 50))
		{
			last;
		}
		else
		{
		 	$maxAppearance--;
		}
	};

	print "\n";

	#if ( ! $maxAppearance ) { $maxAppearance++ };
	$maxAppearance++;

	print "\t\tQUASIBLAST ::  WORD LENGTH: ", $wordLength," NEW MAX APPEARANCE (20%): ", $maxAppearance, "\n";

	print "\t\t\tWC VALID: ", $WCvalid, " WC NON VALID: ", $WCnonValid, " WC TOTAL: ", ($WCvalid+$WCnonValid), "\n";
	if ( ! $WCvalid ) 
	{  
		$Gresult = ();
		$Gresult = &quasiBlast($Gresult, $list, $extra++);
	}
	else
	{
		print "SO FAR SURVIVED... too... ", (time - $time), "s though\n";
		$time = time;

		my $resultWordTotal   = 0;
		my $resultWordValid   = 0;
		my $resultWordInValid = 0;
		#check wich sequences doesnt contains the forbiden words
		print "\t\t\t",$listSlice," > ";
		for (my $l1 = $listStart; $l1 < $listEnd; $l1++)
		{
			if ( ! (($l1-$listStart) % (int($listSlice/20)))) { print $l1, "..."; };
			my $l1Seq  = \$list->[$l1];
			if (($$l1Seq) && ( ! defined $Gresult->[$l1] ))
			{
				$resultWordTotal++;
				my $l1RcSeq = &dnaCode::digit2digitrc($$l1Seq);
				my $found   = 0;

				for my $seq ($$l1Seq, $l1RcSeq)
				{
					my $countApp = 0;
					my $lenWord  = length($seq);
	#					for (my $p = 0; $p < ($lenWord-$wordLength+1); $p+=$wordLength) # JUMPING
					for (my $p = 0; $p < ($lenWord-$wordLength+1); $p++) # SLIDING
					{
						my $subs = substr($seq, $p, $wordLength);
						if (( exists $wordListH{$subs} ) && ( defined $wordListA[$wordListH{$subs}] ) && ( $wordListA[$wordListH{$subs}] > $maxAppearance ))
						{
							$Gresult->[$l1]   = 1;
							$found            = 1;
							$resultWordInValid++;

							last;
						}
						elsif (( exists $wordListH{$subs} ) && ( ! defined $wordListA[$wordListH{$subs}] ))
						{
							die "KEY NOT DEFINED";
						}
	#						$countApp += $wordList{$subs};
	#						if ((($countApp*$wordLength)*.7) >= $lenWord)
	#						{
						#	print "CRAZY COUNT ", (($countApp*$wordLength)),"\n";
	#							$resultWord[$l1] = 1;
	#							$result[$l1]     = 1;
	#							$found           = 1;
	#							$resultWordInValid++;

	#							last;
	#						}
					}
					if ($found) { last };
				} # end for my seq seqRc
			} # end if l1seq
		} # end for my l1

		print "SO FAR SURVIVED... too... again... ", (time - $time), "s though\n";
		$time = time;
		$resultWordValid = $resultWordTotal - $resultWordInValid;
		print "\t\t\tQUASIBLAST :: RESULT : $listCount : PHRASE VALID = ", $resultWordValid," PHRASE INVALID = ", $resultWordInValid, " TOTAL PHRASES = ", ($resultWordValid+$resultWordInValid),"\n";


		my $resultValid   = 0;
		my $resultInValid = 0;
		my $gTotal        = @{$Gresult};

		print "\t\t\t", $gTotal ," > ";
		for (my $p = 0; $p < $gTotal; $p++)
		{
			if ( ! ($p % (int($gTotal/20)))) { print $p, "..."; };
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
		} # end for my p

		print "\tQUASIBLAST :: VALID : ", $resultValid," INVALID : ", $resultInValid,"\n";

		if ( ! $resultValid ) 
		{  
			die "NOT WORTH LIVING THIS LIFE WITHOUT RESULT. I'M QUINTTING. SORRY MASTER.";
		}

		#print "QUASIBLAST :: TOOK ", (int((time - $startTime)+.5)), "s\n\n\n";
	} # end if wcvalid

		}
	}
	undef $dbH;
	untie %wordListH;
	untie @wordListA;


	return $Gresult;
}


















sub quasiBlastMatrix
{
	my $Gresult = $_[0];
	my $list    = $_[1];
	if ( ! @_ ){ print "QUASIBLAST ::  NEEDS ARRAY REFS\n"; return; }

	if ( ! $Gresult ) { $Gresult = []; };

#	foreach my $list (@input)
#	{
#		if (ref $list ne "ARRAY") { print "QUASIBLAST ::  NOT A ARRAY REF\n"; return; }
#	}
	print "\tQUASIBLAST :: ANALIZING SIMILARITY\n";

	my $startTime = time;
	my $listCount = 0;
	my %wordList;
	tie %wordList, "BerkeleyDB::Hash", -Filename => "/mnt/ssd/probes/WordListMatrix.db", -Flags => DB_CREATE or die "COULD NOT OPEN FILE: $! $BerkeleyDB::Error\n";
	my %MatrixWordList;


#	foreach my $list (@input)
#	{
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
		my $wordLength    = int(($avgSize / $MINSIZEPROP)+.5);
		if ($wordLength > $minSize)    { $wordLength = $minSize; };
		if ($wordLength < $MINWORDLEN) { $wordLength = $MINWORDLEN; };
		my $maxAppearance = int((&log10($listSize))-((&log10($listSize)/$wordLength)));
#		if ($wordLength > $MAXWORDLEN) { $wordLength = $MAXWORDLEN; };

#		my $avgSize       = int((($maxSize+$minSize)/2)+.5);
#		my $maxAppearance = int(sqrt(&log10($listSize))+$MAXAPPEARANCEMOD);
#		my $wordLength    = int(($avgSize / $MINSIZEPROP));
#		if ($wordLength > $minSize)    { $wordLength = $minSize; };
#		if ($wordLength < $MINWORDLEN) { $wordLength = $MINWORDLEN; };
#		if ($wordLength > $MAXWORDLEN) { $wordLength = $MAXWORDLEN; };


		print "\t\tQUASIBLAST :: $listCount : PHRASES LIST SIZE: ", $listSize, " MINSIZE ", $minSize, " MAXSIZE ", $maxSize, " AVGSIZE ", $avgSize, " WORD LENGTH: ", $wordLength," MAX APPEARANCE: ", $maxAppearance, "\n";

		# makes matrix word list
		for (my $l1 = 0; $l1 < $listSize; $l1++)
		{
			my $l1Seq  = \$list->[$l1];
			if ($$l1Seq)
			{
				my $l1RcSeq = &dnaCode::digit2digitrc($$l1Seq);

				for my $seq ($l1Seq, \$l1RcSeq)
				{
					for (my $p = 0; $p < length($$seq)-1; $p+=2) # jumpiiinggggg
					{
						$MatrixWordList{substr($$seq, $p, 2)} = 0;
					}
				}
			}
		}

		my $countMWL = 0;
		while ((my $k, my $v) = each %MatrixWordList)
		{
			$MatrixWordList{$k} = $countMWL++;
		}

		print "MatrixWordList: ", $countMWL, "\n";

		# makes word list
		my @mwc;
		for (my $l1 = 0; $l1 < $listSize; $l1++)
		{
			my $l1Seq  = \$list->[$l1];
			if ($$l1Seq)
			{
				my $l1RcSeq = &dnaCode::digit2digitrc($$l1Seq);

				for my $seq ($l1Seq, \$l1RcSeq)
				{
					#for (my $p = 0; $p < (length($seq)-$wordLength)+1; $p+=$wordLength) # jumpiiinggggg
					for (my $p = 0; $p < (length($$seq)-$wordLength)+1; $p++) # slidiniingggg
					{
						my $fragment = substr($$seq, $p, $wordLength);
						my $extra;
						while (length($fragment) % 3) { $extra = chop($fragment) . $extra; };
						my @out;
						for (my $f = 0; $f < length($fragment)-1; $f+=2)
						{
							push(@{$mwc[$l1]}, \$MatrixWordList{substr($fragment, $f, 2)});
						}

#						$wordList{$out}++;
					}
				}
			}
		}

		


		my $WCvalid    = 0;
		my $WCnonValid = 0;
		print "\t\t\tWC VALID: ", $WCvalid, " WC NON VALID: ", $WCnonValid, " WC TOTAL: ", ($WCvalid+$WCnonValid), "\n";

		use Devel::Refcount;

		my @resultWord;
		my $resultWordTotal   = 0;
		my $resultWordValid   = 0;
		my $resultWordInValid = 0;
		#check wich sequences doesnt contains the forbiden words
		for (my $l1 = 0; $l1 < $listSize; $l1++)
		{
			my $appearance = 0;
			for (my $O = 0; $O < $mwc[$l1]; $O++)
			{
				my $count = refcount($mwc[$l1][$O]);
				$appearance = $count if ($count > $appearance);
				print "L1 :: ", $l1 ," O : ", $O, " > ", $appearance, "\n";
			}
			print "L1 :: ", $l1 ," FINAL APP : ", $appearance, "\n";

			if ( $appearance > $maxAppearance )
			{
#				$resultWord[$l1]  = 1;
				$Gresult->[$l1]   = 1;
				$resultWordInValid++;
			}

			if ( $appearance == 0 )
			{
				die "shit";	
			}
		} # end for my l1

		$resultWordValid = $resultWordTotal - $resultWordInValid;
		print "\t\t\tQUASIBLAST :: RESULT : $listCount : PHRASE VALID = ", $resultWordValid," PHRASE INVALID = ", $resultWordInValid, " TOTAL PHRASES = ", ($resultWordValid+$resultWordInValid),"\n";
#	} #end for my list


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

	untie %wordList;
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

#							print "\t SIMILARITY ", $l1. " [", $list->[$l1] ,"] ", $l2, " [", $list->[$l2], "]: ", $result, "\n";
							if ($dist <= $minSub)
							{
								print "\t\t  ALMOSTBLAST :: $listCount;$count : SIMILARITY DIST $dist LENG $leng MIN SUB $minSub POS L1 ", $l1. " \"", $$l1Seq ,"\" POS L2 ", $l2, " \"", $$l2Seq, "\": ", $result, "\n";
								$Gresult->[$l1] += 1;
								$Gresult->[$l2] += 1;
#								next;
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
#									next;
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
#	print "ALMOSTBLAST :: TOOK ", (int((time - $startTime)+.5)), "s\n\n\n";
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
#		print "$inputs[$row] ";
		for (my $col = 0; $col < $dimensions; $col++)
		{
			if (($row != $col) && ($results[$row][$col] <= $minSub)) {$answer[$row]++; $answer[$col]++;  }; #print "ROW $row COL $col $inputs[$row] $inputs[$col] VALUE $results[$row][$col]\n"; };
		}
#		print "\n";
	}

#	for (my $k = 0; $k < $dimensions; $k++)
#	{
#		print "$k > $answer[$k]\t";
#		if ( ! ($k % 5)) { print "\n"; };
#	}

#	for (my $row = 0; $row < $dimensions; $row++)
#	{
#		print "$inputs[$row] ";
#		for (my $col = 0; $col < $dimensions; $col++)
#		{
#			print $results[$row][$col] . " "x10;
#		}
#		print "\n";
#	}
	return \@answer;
}


sub log10 {
	my $n = shift;
	return log($n)/log(10);
}











#http://search.cpan.org/~jhi/String-Approx-3.26/Approx.pm

#	my @inputs;
#	open FILE, "<resultset.txt" or die "couldnt";
#	while (<FILE>)
#	{
#		chomp;
#		push(@inputs, $_);
#	}

#	$dimensions = @inputs;

#	my @results;
#	for (my $row = 0; $row < $dimensions; $row++)
#	{
#		my @dist = adist($inputs[$row], @inputs);
#		$results[$row] = \@dist;
#	}

	#print " "x11 . join(" ", @inputs[0 .. ($dimensions-1)]) . "\n";

#	for (my $row = 0; $row < $dimensions; $row++)
#	{
		#print "$inputs[$row] ";
#		for (my $col = 0; $col < $dimensions; $col++)
#		{
			#print $results[$row][$col] . " "x10;
#		}
		#print "\n";
#	}
#	print "\n";


1;
