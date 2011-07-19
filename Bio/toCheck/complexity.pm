#!/usr/bin/perl
# Saulo Aflitos
# 2009 05 27 11 43
use strict;
package complexity;

#############################################
######## MASKER
#############################################

my $windowsize = 8; # size of repeats to be masked
my $windowstep = 1;
my $minentropy = 0.721;
   $minentropy = 0.98;
my $wordlen    = 2;
my %ecount;
my $maskchar = "X";
my $pattern  = $maskchar x $windowsize;
my $log2     = log(2);

#http://biowiki.org/GffTools




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
    $H = -$H/log(2);                    # negate sum, convert base e to base 2
    print "H = $H bits\n";              # output
}

sub HasMasked
{
    my $seq = $_[0];
    if ( ! (defined $seq)) { die "SEQUENCE NOT DEFINED" };
    my $seq2   = &mask($seq);

    my $found = 0;

    if (($seq2 =~ /N/) || ($seq2 =~ /$pattern/))
    {
        my $N = rindex($seq2, "N");
        my $X = rindex($seq2, "X");

        my $offset = ($X >= $N) ? ($X - 3) : $N;
        #print "SKIPED\n$MKFallSeq\t$MKFallSeq2 @ $ligStart - OFFSET $offset\n";
        $found = 1;
    };
    return $found;
}


sub entropy {
    my ($string) = @_;
    my %freq = ();
    my $total = 0;
    my $i;

    for ( my $i=0;$i<=(length($string) - $wordlen);$i++)
    {
        my $word = substr $string,$i,$wordlen;
        $freq{$word}++;
        $total++;
    }
    my $entropy = 0;
    foreach my $word (keys %freq) { $entropy -= ($freq{$word}/$total) * log($freq{$word}/$total); }

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


sub mask 
{
    my $linepos  = 0;
    my $sequence = $_[0];
    my $output;
    if ($sequence)
    {
        my $maskstart   = -1;
        my $unmaskstart = -1;
        for (my $wpos=0;$wpos<length $sequence;$wpos++)
        {
            if ($wpos % $windowstep == 0)
            {
                if ($wpos<=length($sequence)-$windowsize || $wpos==0)
                {
                    my $entropy = entropy(substr($sequence,$wpos,$windowsize));
                    $ecount{$entropy}++;
                    if ($entropy<$minentropy)
                    {
                        $unmaskstart = $wpos + $windowsize;
                    }
                }
            }
            if ($wpos>=$unmaskstart) { $output .= substr($sequence,$wpos,1); }
            else { $output .= $maskchar; }
        }
    }
    return $output;
}


1;