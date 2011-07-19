#!/usr/bin/perl -w
# Saulo Aflitos
# 2009 06 18 19 47
use strict;

package similarity;

use String::Approx 'adist';
use Fcntl;

use Tie::Hash::Indexed;

use BerkeleyDB;
use DB_File ;

use lib "./";
use dnaCode;


# QUASIBLAST - vector search engine (google)
	my $MINSIZEPROP       = 3; # BIGGER MORE STRINGENT. minimum proportion of the sequence to make dictionary eg. having 3, for a 8bp, 1/3 = 2
	my $MINWORDLEN        = 5; # SMALLER MORE STRINGENT. minimum word length size. has precedence over $MINSIZEPROP
	#my $MAXWORDLEN       = 7; # SMALLER MORE STRINGENT. maximum word length size. has precedence over $MINSIZEPROP
	#my $MAXAPPEARANCEMOD = 0; # SMALLER MORE STRINGENT. modifier to the maximum number of times a word can appear
	my $minPercentil      = 97;
	my $bdbFolder         = "/mnt/ssd/probes";
# ALMOSTBLAST - distance + contains/is contained by
	my $minSub            = 6; # BIGGER MORE SITRINGENT. minimum number of substitutions (included) for ALMOSTBLAST


$| = 1;
#QUASIBLAST  - http://www.perl.com/lpt/a/713
#ALMOSTBLAST - http://search.cpan.org/~jhi/String-Approx-3.26/Approx.pm



##################################
#### QUASI BLAST
##################################
sub quasiBlast
{
	my $Gresult = $_[0];
	my $list    = $_[1];
	my $name    = $_[2];
	my $extra   = $_[3];
	if (defined $name) { $name .= " :"; };
	$name  |= "";
	
	$extra |= 0;
	my $list2;
	
	my $listSize              = @{$list};
	my $minSize               = 1_000_000;
	my $maxSize       		  = 0;
	my $maxAppearanceModifier = 1.8;

	if ( ! @_ ){ print "QUASIBLAST ::$name NEEDS ARRAY REFS\n"; return; }

	if ( ! defined $Gresult ) { $Gresult = []; };

	print "\tQUASIBLAST ::$name ANALIZING SIMILARITY\n";

	my $startTime = time;
	my $listCount = 0;

	#http://www.perl.com/lpt/a/713
	$listCount++;

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

	if ($minSize <=3 ) { $minSize = 6; };

	
	#######
	# generating initial parameters
	#######
	my $avgSize       = int((($maxSize+$minSize)/2)+.5);
	my $wordLength    = int(($avgSize / $MINSIZEPROP)+.5) - $extra;
	if ($wordLength > $minSize)    { $wordLength = $minSize; };
	if ($wordLength < $MINWORDLEN) { $wordLength = $MINWORDLEN; };
	my $maxAppearance = int((int((&log10($listSize))-((&log10($listSize)/$wordLength))) * $maxAppearanceModifier) + 0.5);


	#######
	# linking dbs
	#######
	my %wordListH;
	my @wordListA;

	my $filenameH = "$bdbFolder/WordListH_";
	if ($wordLength < 10) { $filenameH .= "0"; };
	$filenameH .= "$wordLength.db";

	`rm -f $filenameH 2>/dev/null`;
	unlink($filenameH);

	my $dbH = new DB_File::HASHINFO;
	if ( -f $filenameH )
	{
 		tie %wordListH, "DB_File", $filenameH, O_RDWR, $dbH 
		or die "$name Cannot open $filenameH: $!\n";
		print "\t\tQUASIBLAST ::$name REUSING EXISTING DB FILE: $filenameH\n";
	}
	else
	{
  		tie %wordListH, "DB_File", $filenameH, O_RDWR|O_CREAT, 0666, $dbH 
		or die "$name Cannot open $filenameH: $!\n";
		print "\t\tQUASIBLAST ::$name CREATING NEW DB FILE: $filenameH\n";
	}

#	tie @wordListA, "BerkeleyDB::Recno", 
#	    -Filename => "$bdbFolder/WordListA.db", 
 #       -Flags => DB_CREATE 
  #      or die "COULD NOT OPEN FILE $bdbFolder/WordListA.db : $! $BerkeleyDB::Error\n";

	my $expectWLA = int((($avgSize - $wordLength + 1) * $listSize)) + 1;
	print "\t\t\tQUASIBLAST ::$name EXPECTED ARRAY SIZE: ", $expectWLA, "\n";

	#http://search.cpan.org/~beppu/Tie-Array-Pointer-0.000059/lib/Tie/Array/Pointer.pm
	#use Tie::Array::Pointer;
	#tie @wordListA, 'Tie::Array::Pointer', {
	#	length => $expectWLA+1,
	#	type   => 'L',
	#};

	#http://search.cpan.org/~dsugal/Packed-Array-0.01/Array.pm
#	use Packed::Array;
#  	tie @wordListA, "Packed::Array";


	########
	# check how many valids already
	########
	my $resultInValid = 0;
	my $resultValid   = 0;
	my $gTotal        = @{$Gresult};
	for (my $p = 0; $p < $gTotal; $p++)
	{
		if (defined $Gresult->[$p])
		{
			$resultInValid++;
		}
		else
		{
			$resultValid++;
		}
	} # end for my p


	print	"\t\tQUASIBLAST ::$name $listCount : PROBES LIST SIZE: ", $listSize, " VALIDS: ",$resultValid ," INVALIDS: ",$resultInValid,
			" MINSIZE ", $minSize, " MAXSIZE ", $maxSize, " AVGSIZE ", $avgSize, " WORD LENGTH: ", $wordLength," MAX APPEARANCE: ", $maxAppearance, "\n";
	$resultInValid = 0;
	$resultValid   = 0;

	my $time = time;
	#######
	# makes word list
	#######
	my $lastId = 0;
#	@wordListA = (0)x$expectWLA;
	#while ($expectWLA+1) {$wordListA[$expectWLA--] = 0};

	print "\t\t\tQUASIBLAST ::$name WORD LIST : ",$listSize," > ";
	for (my $l1 = 0; $l1 < $listSize; $l1++)
	{
		if ( ! ($l1 % (int($listSize/5)))) { print $l1, "..."; };
		my $l1Seq  = \$list->[$l1];
		if ($$l1Seq)
		{
			my $l1RcSeq = &dnaCode::digit2digitrc($$l1Seq);

			#$$l1Sedistance + contains/is contained byq  =~ s/[a|c|t|g]//g;
			#$l1RcSeq =~ s/[a|c|t|g]//g;
			my %doneSeqs;
			for my $seq ($l1Seq, \$l1RcSeq)
			{
				#for (my $p = 0; $p < (length($seq)-$wordLength)+1; $p+=$wordLength) # jumpiiinggggg
				for (my $p = 0; $p < (length($$seq)-$wordLength)+1; $p++) # slidiniingggg
				{
					my $sseq = substr($$seq, $p, $wordLength);

					if ( $doneSeqs{$sseq} ) { next; }
					else                    { $doneSeqs{$sseq} = 1; };

					my $id = $wordListH{$sseq};

					if ( defined $id ) 
					{
						$wordListA[$id]++;
					}
					else
					{ 
						$id = $lastId++;
						$wordListH{$sseq} = $id;
					};

#					my $dec = &dnaCode::digit2number($sseq);
#					print "ADDING DEC: ", $dec, "\n";
#					$wordListA[$dec]++;

#					if (defined $id)
#					{
#						print $sseq, " ", $id, "\n";
						
						#push(@{$list->[$l1]}, $id);
#					}
#					else
#					{
#						die "no id";
#					}
				} #end for my p
			} #end for my seq
		}#end if l1
	} #end for my l1
	print "SURVIVED WL CREATION: ", (time - $time), "s though\n";
	$time = time;

	my $WCvalid       = 0;
	my $WCnonValid    = 0;
	my $wordListASize = @wordListA;
	#######
	# creates distribution tables
	#######
	if (0)
	{
		my %dist;
		my %cumDist;

		print "\t\t\tQUASIBLAST ::$name DIST TABLE : ",$wordListASize," > ";
		for (my $wa = 0; $wa < $wordListASize; $wa++)
		{
			if ( ! ($wa % (int($wordListASize/5)))) { print $wa, "..."; };
	#		if ($$value <= $maxAppearance) OLD
			my $value = $wordListA[$wa];
			if ((defined $value) && ($value > 0))
			{
				$dist{$value}++;
				if ($value <= $maxAppearance)
				{
					$WCvalid++;
				}
				else
				{
					$WCnonValid++;
				}
			}
		}
		print "SURVIVED DIST TABLE CREATION: ", (time - $time), "s though\n";
		$time = time;
		print "\t\tQUASIBLAST ::$name WORD LENGTH: ", $wordLength," NEW MAX APPEARANCE (80%): ", $maxAppearance, "\n";
		print "\t\t\tBEFORE :: $name WC VALID: ", $WCvalid, " WC NON VALID: ", $WCnonValid, " WC TOTAL: ", ($WCvalid+$WCnonValid), "\n";

		my $totalApp = 0;
		foreach my $d (sort {$a <=> $b} keys %dist)
		{
			if ($dist{$d} > 0)
			{
				$cumDist{$d}  = $dist{$d};
				my $prevD = $d-1;
				while (( ! defined $cumDist{$prevD} ) && ($prevD > 0)) { $prevD--; };
				$cumDist{$d} += $cumDist{$prevD} if (defined $cumDist{$prevD});
				$totalApp = $cumDist{$d};
				#print "\t\t\t\t", $d, " APPEARANCE APPEARED ", $dist{$d}, " TIMES\n";
			}
		}



		foreach my $cd (sort {$a <=> $b} keys %cumDist)
		{
			if (defined $cumDist{$cd})
			{
				my $percentil = (int(($cumDist{$cd}/$totalApp)*100));
				#print "\t\t\t\t", $cd, " APPEARANCE ACCUMULATES ", $cumDist{$cd}, " TIMES (", $percentil ,"%)\n";
				if (( $percentil <= $minPercentil ) && ($cd > $maxAppearance)) { $maxAppearance = $cd };
			}
		}

		print "\t\t\t\tQUASIBLAST ::$name SURVIVED CUM DIST TABLE CREATION: ", (time - $time), "s though\n";
		$time = time;

		if ( ! $maxAppearance ) { $maxAppearance++ };
		#$maxAppearance++;

		$WCvalid    = 0;
		$WCnonValid = 0;
	} #end if fix maxapp

	###########
	# count valids with final parameters
	###########
	$wordListASize = @wordListA;
	print "\t\t\tQUASIBLAST ::$name COUNT VALIDS ",$wordListASize," > ";
	for (my $wa = 0; $wa < $wordListASize; $wa++)
	{
		if ( ! ($wa % (int($wordListASize/5)))) { print $wa, "..."; };
		#	if ($$value <= $maxAppearance) OLD
		my $value = $wordListA[$wa];
		if ((defined $value) && ($value > 0))
		{
			if ($value <= $maxAppearance)
			{
				$WCvalid++;
			}
			else
			{
				$WCnonValid++;
			}
		}
	}
	
	print "\n";
	print "\t\t\t\tQUASIBLAST ::$name SURVIVED VALID COUNT CREATION: ", (time - $time), "s though\n";
	$time = time;

	print "\t\tQUASIBLAST ::$name WORD LENGTH: ", $wordLength," NEW MAX APPEARANCE (",$minPercentil,"%): ", $maxAppearance, "\n";
	print "\t\t\tAFTER :: $name WC VALID: ", $WCvalid, " WC NON VALID: ", $WCnonValid, " WC TOTAL: ", ($WCvalid+$WCnonValid), "\n";

	if ( ! $WCvalid ) { die "$name NOT WORTH LIVING WHEN THERE'S NO RESULT"; };


	#######
	# actual filtering with final results
	#######
	print "\t\tQUASIBLAST ::$name FILTERING\n";
	my @resultWord;
	my $resultWordTotal   = 0;
	my $resultWordValid   = 0;
	my $resultWordInValid = 0;
	#check wich sequences doesnt contains the forbiden words
	print "\t\t\tQUASIBLAST ::$name FILTER ",$listSize," > ";
	for (my $l1 = 0; $l1 < $listSize; $l1++)
	{
		if ( ! ($l1 % (int($listSize/5)))) { print $l1, "..."; };
		my $l1Seq  = \$list->[$l1];

		if ($$l1Seq)
		{
			$resultWordTotal++;
			if ( ! defined $Gresult->[$l1] )
			{
				my $l1RcSeq = &dnaCode::digit2digitrc($$l1Seq);
				my $found   = 0;
				my %seqName;
				$seqName{original} = $l1Seq;
				$seqName{reverse}  = \$l1RcSeq;

				foreach my $sName (sort keys %seqName)
				{
					my $seq      = $seqName{$sName};
					my $countApp = 0;
					my $lenWord  = length($$seq);
					#print "OUTSEQ $sName ", $$seq, "\n";
					#for (my $p = 0; $p < ($lenWord-$wordLength+1); $p+=$wordLength) # JUMPING
					for (my $p = 0; $p < (($lenWord-$wordLength)+1); $p++) # SLIDING
					{
						my $subs = substr($$seq, $p, $wordLength);
						#print " "x$p , $subs, "\n";
						if ( exists $wordListH{$subs} )
						{
							my $valueWLA = $wordListA[$wordListH{$subs}];
							#if (( ! $valueWLA ) || ( defined $valueWLA ))
							#{
								if ( ! defined $valueWLA )
								{
									$wordListA[$wordListH{$subs}] = 0;
									$valueWLA 					  = 0;
								}
								
								if ( $valueWLA > $maxAppearance )
								{
									#	$resultWord[$l1]  = 1;
									#print "INVALID P", $l1,"WORD ", $subs, " WC ", $wordListA[$wordListH{$subs}], "\n";
									#print "$sName - WORD $subs ID ", $wordListH{$subs}, " LENGTH $lenWord P $p VALUEWLA $valueWLA EXISTS\n";
									$Gresult->[$l1]   = $valueWLA if (( ! defined $Gresult->[$l1] ) || ($Gresult->[$l1] < $valueWLA));
									$found            = 1;
									$resultWordInValid++;

									last; # last for my p
								} # if > max app
								else
								{
									#print "$sName - WORD $subs ID ", $wordListH{$subs}, " LENGTH $lenWord P $p VALUEWLA $valueWLA EXISTS\n";
									#print "VALID P",$l1,"WORD ", $subs, " WC ", $wordListA[$wordListH{$subs}], "\n";
								}
							#} #end if defined wordlista id
							#else
							#{
							#	die "\n$sName - WORD $subs ID ", $wordListH{$subs}, " LENGTH $lenWord P $p DOESNT EXISTS. LOGIC ERROR\n";
							#}
						} #end if exists wordlist subs
						else
						{
							warn "$name - $sName - WORD $subs NOT FOUND. LOGIC ERROR";
						}
					} #end for my p
					if ($found) { last } # last for my seq
					else
					{
						#print "you see.. i have survived SO FAR\t ",$l1," > ", $$seq, "\n";
					}
				} # end for my seq seqRc
				if ($found) { next } # next l1
				else 
				{
					#print "you see.. i have survived ALL\t ",$l1," > ", $$l1Seq, "\n"; 
					$resultWordValid++;
				}
			} #end if ! defined gresult
			else
			{
				#skipping bad sequence
			}
		} # end if l1seq
		else
		{
			#die "L1SEQ NOT DEFINED";
		}
	} # end for my l1

	print "SURVIVED FILTERING: ", (time - $time), "s though\n";
	$time = time;

#	$resultWordValid = $resultWordTotal - $resultWordInValid;
	print "\t\tQUASIBLAST ::$name RESULT : ",$listCount, " TOTAL INITIAL WORDS = ", $resultWordTotal, " : PROBES VALID = ", $resultWordValid," PROBES INVALID = ", $resultWordInValid,"\n";

	if ( $resultWordValid < (0.1*$listSize)) 
	{  
		#die "NOT WORTH LIVING THIS LIFE WITHOUT RESULT. I'M QUINTTING. SORRY MASTER.";
	}

	$resultValid   = 0;
	$resultInValid = 0;

	$gTotal        = @{$Gresult};
	print "\t\t\t$name GTOTAL ", $gTotal ," > ";
	for (my $p = 0; $p < $gTotal; $p++)
	{
		if ( ! ($p % (int($gTotal/5)))) { print $p, "..."; };

		if (defined $Gresult->[$p])
		{
			$resultInValid++;
		}
		else
		{
			$resultValid++;
		}
	} # end for my p

	print "SURVIVED VALID COUNT: ", (time - $time), "s though\n";
	$time = time;

	print "\tQUASIBLAST ::$name VALID : ", $resultValid," INVALID : ", $resultInValid,"\n";
	print "\tQUASIBLAST ::$name FINISHED";

	if ( $resultValid < (0.1*$listSize)) 
	{  
		die "$name NOT WORTH LIVING THIS LIFE WITHOUT RESULT. I'M QUITTING. SORRY MASTER.";
	}

	#print "QUASIBLAST :: TOOK ", (int((time - $startTime)+.5)), "s\n\n\n";

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
#### ALMOST BLAST - distance + contains/is contained by
##################################
sub almostBlast
{
	#http://search.cpan.org/~jhi/String-Approx-3.26/Approx.pm
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

		my $doADist     = 0;
		my $doADistRc   = 0;
		my $doCompDigit = 1;






		if ($doADist)
		{
			my $countList;

			for (my $l = 0; $l < $listSize; $l++)
			{
				if (defined $list->[$l])
				{
					$countList++;
				}
			}

			print "\tALMOSTBLAST :: ADIST :: ANALIZING SIMILARITY : LIST $listCount ($listSize rows / $countList valid rows)\n";
			my $count    = 0;

			for (my $g = 0; $g < @{$Gresult}; $g++)
			{
				my $gg = \$Gresult->[$g];
				if ((defined $gg) && ($$gg == -1))
				{
					$$gg = undef; 
				}
			}

			my $lastTime = time;
			for (my $l1  = 0; $l1 < $listSize; $l1++)
			{
				my $l1Seq = \$list->[$l1];
				my $gL1   = \$Gresult->[$l1];

				next if ( ! defined $$l1Seq );
				$count++;
				print $l1,"(",$count,")\t";
				next if ( defined $$gL1 );

				if ( ! ($count % 100) )
				{
					my $elapsed = (time-$lastTime);
					my $ETA     = int((($countList-$count)/100)*$elapsed);
					$lastTime   = time;
					print "\n\t\tALMOSTBLAST :: ADIST :: ",$listCount,":",$count," > ",$l1," ",$elapsed,"s (ETA:",$ETA,"s)\n" ;
				}

				my $leng   = length($$l1Seq);
				my $minSub = int(($leng * .1)+.5)+1; # minimum number of substitutions (included);

				for (my $l2 = 0; $l2 < $listSize; $l2++)
				{
					my $l2Seq = \$list->[$l2];
					next if ( $l1 == $l2 );
					next if ( ! defined $$l2Seq );

					my $gL2 = \$Gresult->[$l2];
					if ( defined $$gL2 )
					{
						next if ( $$gL2 == -1 );
					}

					my $result = 0;

					my $dist   = adist($$l1Seq, $$l2Seq);
					if ($dist < 0) { $dist *= -1; };

					if ($dist <= $minSub)
					{
						print "\t\t  ALMOSTBLAST :: ADIST :: ",$listCount,":",$l1,"x",$l2,"(",$count,") : SIMILARITY DIST ",$dist," LENG ",$leng," MIN SUB ",$minSub," POS L1 ", $l1, " \"", $$l1Seq ,"\" POS L2 ", $l2, " \"", $$l2Seq, "\": ", $result, "\n";
						$$gL1 += 1;
						$$gL2 += 1;
						#next;
					}
				}#end for my l2 < listsize
				if ( ! defined $$gL1 ) { $$gL1 = -1; };
			}#end l1 < listsize
		} #end if doADist








		if ($doADistRc)
		{
			my $countList;

			for (my $l = 0; $l < $listSize; $l++)
			{
				if (defined $list->[$l])
				{
					$countList++;
				}
			}

			print "\tALMOSTBLAST :: ADISTRC :: ANALIZING SIMILARITY : LIST $listCount ($listSize rows / $countList valid rows)\n";
			my $count    = 0;

			for (my $g = 0; $g < @{$Gresult}; $g++)
			{
				my $gg = \$Gresult->[$g];
				if ((defined $gg) && ($$gg == -1))
				{
					$$gg = undef; 
				}
			}

			my $lastTime = time;
			for (my $l1  = 0; $l1 < $listSize; $l1++)
			{
				my $l1Seq = \$list->[$l1];
				my $gL1   = \$Gresult->[$l1];

				next if ( ! defined $$l1Seq );
				$count++;
				print $l1,"(",$count,")\t";
				next if ( defined $$gL1 );

				if ( ! ($count % 100) )
				{
					my $elapsed = (time-$lastTime);
					my $ETA     = int((($countList-$count)/100)*$elapsed);
					$lastTime   = time;
					print "\n\t\tALMOSTBLAST :: ADISTRC :: ",$listCount,":",$count," > ",$l1," ",$elapsed,"s (ETA:",$ETA,"s)\n" ;
				}

				my $l1Rc   = &dnaCode::digit2digitrc($$l1Seq);
				my $leng   = length($$l1Seq);
				my $minSub = int(($leng * .1)+.5)+1; # minimum number of substitutions (included);

				for (my $l2 = 0; $l2 < $listSize; $l2++)
				{
					my $l2Seq = \$list->[$l2];
					next if ( $l1 == $l2 );
					next if ( ! defined $$l2Seq );

					my $gL2 = \$Gresult->[$l2];
					if ( defined $$gL2 )
					{
						next if ( $$gL2 == -1 );
					}

					my $result = 0;

					my $distRc = adist($l1Rc, $$l2Seq);
					if ($distRc < 0) { $distRc *= -1; };
					if ($distRc <= $minSub)
					{
						print "\t\t  ALMOSTBLAST :: ADISTRC :: ",$listCount,":",$l1,"x",$l2,"(",$count,") : SIMILARITY DIST ",$distRc," LENG ",$leng," MIN SUB ",$minSub," POS L1 ", $l1, " \"", $$l1Seq ,"\" POS L2 ", $l2, " \"", $$l2Seq, "\": ", $result, "\n";
						$$gL1 += 100;
						$$gL2 += 100;
						#next;
					}
				}#end for my l2 < listsize
				if ( ! defined $$gL1 ) { $$gL1 = -1; };
				#print "\n";
			}#end l1 < listsize
		} #end if doADistRc








		if ($doCompDigit)
		{
			my $countList;

			for (my $l = 0; $l < $listSize; $l++)
			{
				if (defined $list->[$l])
				{
					$countList++;
				}
			}

			print "\tALMOSTBLAST :: COMPDIGIT :: ANALIZING SIMILARITY : LIST $listCount ($listSize rows / $countList valid rows)\n";
			my $count    = 0;

			for (my $g = 0; $g < @{$Gresult}; $g++)
			{
				my $gg = \$Gresult->[$g];
				if ((defined $gg) && ($$gg == -1))
				{
					$$gg = undef; 
				}
			}

			my $lastTime = time;
			for (my $l1  = 0; $l1 < $listSize; $l1++)
			{
				my $l1Seq = \$list->[$l1];
				my $gL1   = \$Gresult->[$l1];

				next if ( ! defined $$l1Seq );
				$count++;
				print $l1,"(",$count,")\t";
				next if ( defined $$gL1 );

				if ( ! ($count % 100) )
				{
					my $elapsed = (time-$lastTime);
					my $ETA     = int((($countList-$count)/100)*$elapsed);
					$lastTime   = time;
					print "\n\t\tALMOSTBLAST :: COMPDIGIT :: ",$listCount,":",$count," > ",$l1," ",$elapsed,"s (ETA:",$ETA,"s)\n" ;
				}

				my $leng   = length($$l1Seq);

				for (my $l2 = 0; $l2 < $listSize; $l2++)
				{
					my $l2Seq = \$list->[$l2];
					next if ( $l1 == $l2 );
					next if ( ! defined $$l2Seq );

					my $gL2 = \$Gresult->[$l2];
					if ( defined $$gL2 )
					{
						next if ( $$gL2 == -1 );
					}

					my $result = 0;


					my $compRes = &dnaCode::compDigit($$l1Seq, $$l2Seq);
					if ($compRes)
					{
						print "\t\t  ALMOSTBLAST :: COMPDIGIT :: ",$listCount,":",$l1,"x",$l2,"(",$count,") : SIMILARITY DIST ",$compRes," LENG ",$leng," MIN SUB ",$minSub," POS L1 ", $l1, " \"", $$l1Seq ,"\" POS L2 ", $l2, " \"", $$l2Seq, "\": ", $result, "\n";
						$$gL1 += 10_000;
						$$gL2 += 10_000;
						#next;
					}
				}#end for my l2 < listsize
				if ( ! defined $$gL1 ) { $$gL1 = -1; };
				#print "\n";
			}#end l1 < listsize
		} #end if doADistRc


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
