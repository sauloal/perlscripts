#!/usr/bin/perl
# Saulo Aflitos
# 2010 01 12 18 11
# - clean code
# - use reference
# - ignore N
# - use rindex instead of RE
# 2009 05 27 11 43
use strict;
package complexity;

#############################################
######## MASKER
#############################################

my $windowsize = 8; # size of repeats to be masked
my $windowstep = 1;
my $minentropy = 0.8;
   #$minentropy = 0.721;
   #$minentropy = 0.98;
   $minentropy = 0.95;
   #$minentropy = 0.965;
my $wordlen    = 2;
my $maskchar   = "X";
#my $pattern    = $maskchar x $windowsize;
my $log2       = log(2);


my @units;
my @voc = ("A", "C", "G", "T");
my $lc1 = 0;
my $lc2 = 0;
my $lc3 = 0;
my $lc4 = 0;

for my $l1 (@voc)
{
	$units[1][$lc1++] = $l1;
	for my $l2 (@voc)
	{
		$units[2][$lc2++] = $l1.$l2;
		for my $l3 (@voc)
		{
			$units[3][$lc3++] = $l1.$l2.$l3;
			#for my $l4 (@voc)
			#{
			#	$units[4][$lc4++] = $l1.$l2.$l3.$l4;
			#}
		}
	}
}


#http://biowiki.org/GffTools

#sub shannonEntropyFast
sub seFast
{
	#http://etutorials.org/Misc/blast/Part+II+Theory/Chapter+4.+Sequence+Similarity/4.1+Introduction+to+Information+Theory/
	# Shannon Entropy Calculator
	my $seq = $_[0];
	if ( ! $seq ) { die "SEQUENCE NOT DEFINED"; };
	my $total = length($seq);  # total symbols counted

	my $a = 0; $a = $seq =~ tr/Aa//;
	my $c = 0; $c = $seq =~ tr/Cc//;
	my $g = 0; $g = $seq =~ tr/Gg//;
	my $t = 0; $t = $seq =~ tr/Tt//;

	#my $pa = $a/$total || 0;
	#my $pc = $c/$total || 0;
	#my $pg = $g/$total || 0;
	#my $pt = $t/$total || 0;
	#
	#my $la = $pa ? $pa * log($pa) : 0;
	#my $lc = $pc ? $pc * log($pc) : 0;
	#my $lg = $pg ? $pg * log($pg) : 0;
	#my $lt = $pt ? $pt * log($pt) : 0;

	$a = $a/$total || 0;
	$c = $c/$total || 0;
	$g = $g/$total || 0;
	$t = $t/$total || 0;

	$a = $a ? $a * log($a) : 0;
	$c = $c ? $c * log($c) : 0;
	$g = $g ? $g * log($g) : 0;
	$t = $t ? $t * log($t) : 0;

	my $H = -($a + $c + $g + $t) / $log2;      # H is the entropy
	return ($H >= $minentropy) ? 0 : $H;
}


sub masker
{
	my $seq       = $_[0];
	my $minLength = $_[1] || $windowsize;
	my $minUnits  = $_[2] || 4;

	if ($minLength % 2) { $minLength++ };

	if ( ! $seq ) { die "SEQUENCE NOT DEFINED"; };

	for (my $size = 0; $size < @units; $size++)
	{
		next if (! defined $units[$size]);
		my $minRep = ($minLength/$size);
		my $rep    = ($minUnits > $minRep) ? $minUnits : $minRep;

		foreach my $frag (@{$units[$size]})
		{
			next if ( ! defined $frag );
			my $repeat = $frag x $rep;
			my $rindex = rindex($seq, $repeat);
			if ( $rindex != -1 )
			{
				my $pos    = $rindex + $minLength;
				#print "REPEAT FOUND :: FRAG $frag REPEAT MIN SIZE $minLength REPEAT $repeat POS $pos SEQ $seq\n";
				return $pos;
			}
		}
	}
	return 0;
}


sub HasMasked
{
	my $seq      = $_[0];
	my $ws       = $_[1] || $windowsize;
	my $minUnits = $_[2] || 4;

	if ( ! (defined $seq)) { die "SEQUENCE NOT DEFINED" };

	my $seq2     = &mask(\$seq, $ws);
	my $pattern  = $maskchar x $ws;
	my $found    = 0;

	#if (($$seq2 =~ /N/) || ($$seq2 =~ /$pattern/))

	if (index($$seq2, $pattern) != -1)
	{
		#print $$seq2, " HAS $pattern\n";
		#my $N = rindex($seq2, "N");
		#my $X = rindex($seq2, "X");

		#my $offset = ($X >= $N) ? ($X - 3) : $N;
		#print "SKIPED\n$MKFallSeq\t$MKFallSeq2 @ $ligStart - OFFSET $offset\n";
		$found = index($$seq2, $pattern) + 1 + $ws;
	}
	else
	{
		#print $$seq2, " DOES NOT HAVE $pattern\n";
	};

	return $found;
}



sub mask
{
	my $sequence = $_[0];
	my $ws       = $_[1];
	my $linepos  = 0;
	my $output;

	if ($$sequence)
	{
		my $seqLen      = length($$sequence);
		my $maskstart   = -1;
		my $unmaskstart = -1;

		for (my $wpos = 0; $wpos < length($$sequence); $wpos++)
		{
			if ($wpos % $windowstep == 0)
			{
				if (($wpos <= $seqLen-$ws+1) || ($wpos == 0))
				{
					my $entropy = &entropy(substr($$sequence,$wpos,$ws));
					if ($entropy < $minentropy)
					{
						$unmaskstart = $wpos + $ws;
					}
				}
			}

			if ($wpos >= $unmaskstart)
			{
				$output .= substr($$sequence,$wpos,1);
			}
			else
			{
				$output .= $maskchar;
			}
		}
	}
	else
	{
		die "NO SEQUENCE TO MASK";
	}

    return \$output;
}




sub entropy {
    my $string = $_[0];
    my %freq   = ();
    my $total  = 0;
    my $i;

	#print "\tENTROPY $string\n";

    for ( my $i = 0; $i <= (length($string) - $wordlen); $i++)
	{
		my $word = substr($string, $i, $wordlen);
		$freq{$word}++;
		$total++;
    }

    my $entropy = 0;
    foreach my $word (keys %freq)
	{
		$entropy -= ($freq{$word}/$total) * log($freq{$word}/$total);
	}

	if (0)
	{
		print "\nSTRING $string\t";
		foreach my $word (keys %freq) {
			print "WORD $word\t";
		}
		print "ENTROPY " . $entropy / $log2 . "\t";
	}

    return $entropy / $log2;
}











sub shannonEntropy
{
	#http://etutorials.org/Misc/blast/Part+II+Theory/Chapter+4.+Sequence+Similarity/4.1+Introduction+to+Information+Theory/
	# Shannon Entropy Calculator
	my $seq = $_[0];
	if ( ! $seq ) { die "SEQUENCE NOT DEFINED"; };
	my %Count;      # stores the counts of each symbol
	my $total = 0;  # total symbols counted

	foreach my $char (split(//, $seq)) { # split the line into characters
	    $Count{$char}++;               # add one to this character count
	    $total++;                      # add one to total counts
	}

	my $H = 0;                          # H is the entropy
	foreach my $char (keys %Count) {    # iterate through characters
		my $p = $Count{$char}/$total;   # probability of character
		$H += $p * log($p);             # p * log(p)
	}
	$H = -$H/$log2;                    # negate sum, convert base e to base 2
	#print "H = $H bits\n";              # output
}


sub seQuasi
{
	#http://etutorials.org/Misc/blast/Part+II+Theory/Chapter+4.+Sequence+Similarity/4.1+Introduction+to+Information+Theory/
	# Shannon Entropy Calculator
	my $seq = $_[0];
	if ( ! $seq ) { die "SEQUENCE NOT DEFINED"; };
	my @Count;
	$seq =~ tr/AaCcGgTt/00112233/;

	my $total = 0;  # total symbols counted

	foreach my $char (split(//, $seq)) { # split the line into characters
	    $Count[$char]++;               # add one to this character count
	    $total++;                      # add one to total counts
	}

	my $H = 0;                          # H is the entropy
	for (my $char = 0 ;$char < 4 ; $char++)
	{    # iterate through characters
		next if ( ! defined $Count[$char]);
		my $p = $Count[$char]/$total;   # probability of character
		$H += $p * log($p);             # p * log(p)
	}
	$H = -$H/$log2;                     # negate sum, convert base e to base 2
	#print "H = $H bits\n";              # output
}

sub seQuasiFast
{
	#http://etutorials.org/Misc/blast/Part+II+Theory/Chapter+4.+Sequence+Similarity/4.1+Introduction+to+Information+Theory/
	# Shannon Entropy Calculator
	my $seq = $_[0];
	if ( ! $seq ) { die "SEQUENCE NOT DEFINED"; };
	my $total = length($seq);  # total symbols counted
	$seq =~ tr/AaCcGgTt/00112233/;
	my @Count;

	for (my $c = 0; $c <$total; $c++) { # split the line into characters
	    $Count[substr($seq, $c, 1)]++;               # add one to this character count
	}

	my $H = 0;                   # H is the entropy
	for (my $char = 0 ;$char < 4 ; $char++)
	{    # iterate through characters
		next if ( ! defined $Count[$char]);
		my $p = $Count[$char]/$total;   # probability of character
		$H += $p * log($p);             # p * log(p)
	}

	$H = -$H/$log2;              # negate sum, convert base e to base 2
	#print "H = $H bits\n";      # output
	return $H;
}




use constant Pn => 0.25; # probability of any nucleotide
sub lambda
{
	#http://etutorials.org/Misc/blast/Part+II+Theory/Chapter+4.+Sequence+Similarity/4.4+Target+Frequencies+lambda+and+H/

	die "usage: $0 <match> <mismatch>\n" unless @ARGV == 2;
	my ($match, $mismatch) = @ARGV;
	my $expected_score = $match * 0.25 + $mismatch * 0.75;
	die "illegal scores\n" if $match <= 0 or $expected_score >= 0;

	# calculate lambda
	my ($lambda, $high, $low) = (1, 2, 0); # initial estimates
	while ($high - $low > 0.001) {         # precision

		# calculate the sum of all normalized scores
		my $sum = Pn * Pn * exp($lambda * $match)    * 4
				+ Pn * Pn * exp($lambda * $mismatch) * 12;

		# refine guess at lambda
		if ($sum > 1) {
			$high = $lambda;
			$lambda = ($lambda + $low)/2;
		}
		else {
			$low = $lambda;
			$lambda = ($lambda + $high)/2;
		}
	}

	# compute target frequency and H
	my $targetID = Pn * Pn * exp($lambda * $match) * 4;
	my $H = $lambda * $match    *     $targetID
		  + $lambda * $mismatch * (1 -$targetID);

	# output
	print "expscore: $expected_score\n";
	print "lambda:   $lambda nats (", $lambda/log(2), " bits)\n";
	print "H:        $H nats (", $H/log(2), " bits)\n";
	print "%ID:      ", $targetID * 100, "\n";
}


#[saulo@SRV-FUNGI rolf]$ time perl -Mfilters::complexity -e '$seq = "CAGCTACGATCAGCTAAAAACGATCACGTCGCTCGTCGCT"; while($i++ < 1_000_000) { &complexity::seFast($seq); }'
#real	0m4.985s
#user	0m4.969s
#sys	0m0.002s
#[saulo@SRV-FUNGI rolf]$ time perl -Mfilters::complexity -e '$seq = "CAGCTACGATCAGCTAAAAACGATCACGTCGCTCGTCGCT"; while($i++ < 1_000_000) { &complexity::seFast($seq); }'
#real	0m4.891s
#user	0m4.881s
#sys	0m0.003s


#[saulo@SRV-FUNGI rolf]$ time perl -Mfilters::complexity -e '$seq = "CAGCTACGATCAGCTAAAAACGATCACGTCGCTCGTCGCT"; while($i++ < 1_000_000) { &complexity::seQuasi($seq); }'
#real	0m23.614s
#user	0m23.546s
#sys	0m0.002s

#[saulo@SRV-FUNGI rolf]$ time perl -Mfilters::complexity -e '$seq = "CAGCTACGATCAGCTAAAAACGATCACGTCGCTCGTCGCT"; while($i++ < 1_000_000) { &complexity::seQuasiFast($seq); }'
#real	0m18.877s
#user	0m18.870s
#sys	0m0.001s

#[saulo@SRV-FUNGI rolf]$ time perl -Mfilters::complexity -e '$seq = "CAGCTACGATCAGCTAAAAACGATCACGTCGCTCGTCGCT"; while($i++ < 1_000_000) { &complexity::shannonEntropy($seq); }'
#real	0m22.712s
#user	0m22.608s
#sys	0m0.007s

#[saulo@SRV-FUNGI rolf]$ time perl -Mfilters::complexity -e '$seq = "CAGCTACGATCAGCTAAAAACGATCACGTCGCTCGTCGCT"; while($i++ < 1_000_000) { &complexity::HasMasked($seq); }'
#real	10m31.120s
#user	10m30.306s
#sys	0m0.168s

#[saulo@SRV-FUNGI rolf]$ time perl -Mfilters::complexity -e '$seq = "CAGCTACGATCAGCTATATATATCGATCACGTCGCTCGTCGCT"; while($i++ < 1_000_000) { &complexity::masker($seq); }'
#real	1m10.243s
#user	1m10.080s
#sys	0m0.008s

1;
