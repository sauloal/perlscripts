package Levenshtein;
use strict;
use warnings;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw();


#http://www.perlmonks.org/?node_id=333616

#Levenshtein Distance Algorithm: Perl Implementation
#by Eli Bendersky
#http://www.merriampark.com/ldperl.htm

#/usr/local/bin/perl -w

#use strict;

#($#ARGV == 1) or die "Usage: $0 <string1> <string2>\n";

#my ($s1, $s2) = (@ARGV);

#print "The Levenshtein distance between $s1 and $s2 is: " . levenshtein($s1, $s2) . "\n";



# Return the Levenshtein distance (also called Edit distance)
# between two strings
#
# The Levenshtein distance (LD) is a measure of similarity between two
# strings, denoted here by s1 and s2. The distance is the number of
# deletions, insertions or substitutions required to transform s1 into
# s2. The greater the distance, the more different the strings are.
#
# The algorithm employs a proximity matrix, which denotes the distances
# between substrings of the two given strings. Read the embedded comments
# for more info. If you want a deep understanding of the algorithm, print
# the matrix for some test strings and study it
#
# The beauty of this system is that nothing is magical - the distance
# is intuitively understandable by humans
#
# The distance is named after the Russian scientist Vladimir
# Levenshtein, who devised the algorithm in 1965
#






#package Text::FastLevenshtein;

#use strict;
#use Exporter;
#use vars qw ($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

#$VERSION        = '0.02';
#@ISA            = qw(Exporter);
#@EXPORT         = ();
#@EXPORT_OK      = qw(distance levenshtein);
#%EXPORT_TAGS    = ();




sub levenshtein()
{
        my $word1 = shift;        my $word2 = shift;

        return 0 if $word1 eq $word2;
        my @d;

        my $len1 = length $word1;
        my $len2 = length $word2;

        $d[0][0] = 0;
        for (1 .. $len1) {
                $d[$_][0] = $_;
                return $_ if $_!=$len1 && substr($word1,$_) eq substr($word2,$_);
        }
        for (1 .. $len2) {
                $d[0][$_] = $_;
                return $_ if $_!=$len2 && substr($word1,$_) eq substr($word2,$_);
        }
        for my $i (1 .. $len1) {
                my $w1 = substr($word1,$i-1,1);
                for (1 .. $len2) {
                        $d[$i][$_] = min($d[$i-1][$_]+1, $d[$i][$_-1]+1, $d[$i-1][$_-1]+($w1 eq substr($word2,$_-1,1) ? 0 : 1));
                }
        }
        return $d[$len1][$len2];
}

sub min
{
    return $_[0] < $_[1]
           ?( $_[0] < $_[2] ? $_[0] : $_[2] )
           :( $_[1] < $_[2] ? $_[1] : $_[2] );
}




sub levenshtein2
{
    # $s1 and $s2 are the two strings
    # $len1 and $len2 are their respective lengths
    #
    my ($s1, $s2) = @_;
    my ($len1, $len2) = (length $s1, length $s2);

    # If one of the strings is empty, the distance is the length
    # of the other string
    #
    return $len2 if ($len1 == 0);
    return $len1 if ($len2 == 0);

    my @mat;

    # Init the distance matrix
    #
    # The first row to 0..$len1
    # The first column to 0..$len2
    # The rest to 0
    #
    # The first row and column are initialized so to denote distance
    # from the empty string
    #
    for (my $i = 0; $i <= $len1; ++$i)
    {
        for (my $j = 0; $j <= $len2; ++$j)
        {
            $mat[$i][$j] = 0;
            $mat[0][$j]  = $j;
        }

        $mat[$i][0] = $i;
    }

    # Some char-by-char processing is ahead, so prepare
    # array of chars from the strings
    #
    my @ar1 = split(//, $s1);
    my @ar2 = split(//, $s2);

    for (my $i = 1; $i <= $len1; ++$i)
    {
        for (my $j = 1; $j <= $len2; ++$j)
        {
            # Set the cost to 1 iff the ith char of $s1
            # equals the jth of $s2
            #
            # Denotes a substitution cost. When the char are equal
            # there is no need to substitute, so the cost is 0
            #
            my $cost = ($ar1[$i-1] eq $ar2[$j-1]) ? 0 : 1;

            # Cell $mat{$i}{$j} equals the minimum of:
            #
            # - The cell immediately above                 plus 1
            # - The cell immediately to the left           plus 1
            # - The cell diagonally  above and to the left plus the cost
            #
            # We can either insert a new char, delete a char or
            # substitute an existing char (with an associated cost)
            #
            $mat[$i][$j] = min([$mat[$i-1][$j  ] + 1,
                                $mat[$i  ][$j-1] + 1,
                                $mat[$i-1][$j-1] + $cost]);
        }
    }

    # Finally, the Levenshtein distance equals the rightmost bottom cell
    # of the matrix
    #
    # Note that $mat{$x}{$y} denotes the distance between the substrings
    # 1..$x and 1..$y
    #
    return $mat[$len1][$len2];
}


# minimal element of a list
#

sub minOld4
{
        my $min = $_[0];
        $min = $_[1] if $_[1] < $min;
        $min = $_[2] if $_[2] < $min;

        return $min;
}

sub minOld3
{
     my $min  = $_[0];
	$min = $_[1] if $_[1] < $min;
    $min = $_[2] if $_[2] < $min;

    return $min;
}



sub minOld2
{
    my $list = $_[0];
    my $min  = $list->[0];

    foreach my $i (@{$list})
    {
        $min = $i if ($i < $min);
    }

    return $min;
}





sub levenshteinOld
{
    # $s1 and $s2 are the two strings
    # $len1 and $len2 are their respective lengths
    #
    my ($s1, $s2) = @_;
    my ($len1, $len2) = (length $s1, length $s2);

    # If one of the strings is empty, the distance is the length
    # of the other string
    #
    return $len2 if ($len1 == 0);
    return $len1 if ($len2 == 0);

    my %mat;

    # Init the distance matrix
    #
    # The first row to 0..$len1
    # The first column to 0..$len2
    # The rest to 0
    #
    # The first row and column are initialized so to denote distance
    # from the empty string
    #
    for (my $i = 0; $i <= $len1; ++$i)
    {
        for (my $j = 0; $j <= $len2; ++$j)
        {
            $mat{$i}{$j} = 0;
            $mat{0}{$j} = $j;
        }

        $mat{$i}{0} = $i;
    }

    # Some char-by-char processing is ahead, so prepare
    # array of chars from the strings
    #
    my @ar1 = split(//, $s1);
    my @ar2 = split(//, $s2);

    for (my $i = 1; $i <= $len1; ++$i)
    {
        for (my $j = 1; $j <= $len2; ++$j)
        {
            # Set the cost to 1 iff the ith char of $s1
            # equals the jth of $s2
            #
            # Denotes a substitution cost. When the char are equal
            # there is no need to substitute, so the cost is 0
            #
            my $cost = ($ar1[$i-1] eq $ar2[$j-1]) ? 0 : 1;

            # Cell $mat{$i}{$j} equals the minimum of:
            #
            # - The cell immediately above plus 1
            # - The cell immediately to the left plus 1
            # - The cell diagonally above and to the left plus the cost
            #
            # We can either insert a new char, delete a char or
            # substitute an existing char (with an associated cost)
            #
            $mat{$i}{$j} = min([$mat{$i-1}{$j} + 1,
                                $mat{$i}{$j-1} + 1,
                                $mat{$i-1}{$j-1} + $cost]);
        }
    }

    # Finally, the Levenshtein distance equals the rightmost bottom cell
    # of the matrix
    #
    # Note that $mat{$x}{$y} denotes the distance between the substrings
    # 1..$x and 1..$y
    #
    return $mat{$len1}{$len2};
}


sub minOld
{
    my @list = @{$_[0]};
    my $min = $list[0];

    foreach my $i (@list)
    {
        $min = $i if ($i < $min);
    }

    return $min;
}

1;
