#!/usr/bin/perl -w

use strict;
use lib "./filters";
use dnaCodeOO;

use Benchmark qw(cmpthese timethese :hireswallclock);

my $st =	'Moses supposes his toses are roses';

my $nd = '';
#my $nd =	'Whether the weather be cold, or whether the weather be hot;' .
#			'whether the weather be fine, or whether the weather be not:' .
#			'we whether the weather, whatever the weather, weather we like it or not.';

my $rd =	'';
#my $rd =	'Zermelo-Fraenkel set theory, which forms the main topic of the book, is a' .
#			'rigorous theory, based on a precise set of axioms. However, it is' .
#			'possible to develop the theory of sets considerably without any knowledge' .
#			'of those axioms. Indeed, the axioms can only be fully understood after' .
#			'the theory has been investigated to some extent. This state of affairs is' .
#			'to be expected. The concept of a "set of objects" is a very intuitive' .
#			'one, and, with care, considerable sound progress may be made on the basis' .
#			'of this intuition alone. Then, by analyzing the nature of the "set"' .
#			'concept on the basis of that initial progress, the axioms may be' .
#			'"discovered" in a perfectly natural manner.';

my @inputs = ($st, $nd, $rd);
my %outputs;

my $file = $ARGV[0];

if (($file) && ( -f $file ))
{
	my $seqCount  = -1;
	my $charCount = 0;
	
	if ($file =~ /\.fasta$/)
	{
		print "USING FASTA FILE ", $file ,"\n";
		undef @inputs;
		open FH, "<$file" or die "COULD NOT OPEN $file: $!";
		while (my $line = <FH>)
		{
			chomp $line;
			if (substr($line, 0, 1) eq ">")
			{
				$seqCount++;
			}
			else
			{
				$inputs[$seqCount] .= $line;
				$charCount += length($line);
			}
		}
		close FH;
	}
	elsif ($file =~ /\.wc$/)
	{
		print "USING WC FILE ", $file ,"\n";
		undef @inputs;
		open FH, "<$file" or die "COULD NOT OPEN $file: $!";
		while (my $line = <FH>)
		{
			chomp $line;
			if ($line)
			{
				$seqCount++;
				
				my @seq = split("\t", $line);
				my ($code, $index) = encode($seq[0]);
				print "ANALYZING SEQ ", $line, " CODE: ", $code, " INDEX: ", $index, " #", $seqCount, "\n" if ( ! ($seqCount % 500_000) );
				$outputs{$code}[$index]++;
				print "GOTCHA $code $index ", $outputs{$code}[$index], "\n" if ($outputs{$code}[$index] > 1);
				$charCount += length($seq[0]);
			}
		}
		close FH;
	}
	elsif ($file =~ /\.wc.k$/)
	{
		print "USING WC.K FILE ", $file ,"\n";
		undef @inputs;
		my $dnaCode = dnaCodeOO->new();	
		open FH, "<$file" or die "COULD NOT OPEN $file: $!";
		while (my $line = <FH>)
		{
			chomp $line;
			if ($line)
			{
				$seqCount++;
				my ($code, $index);
				
				$line = $dnaCode->digit2dna($line);
				
				if (exists $outputs{$line})
				{
					$code  = $line;
					$index = -1;
				}
				else
				{
					#$line = $dnaCode->digit2dna($line);
					($code, $index) = &encode($line);
					#$code = $dnaCode->dna2digit($code);
				}

				$outputs{$code}[0]++ if ( ! defined ${$outputs{$code}}[$index + 2] );

				$outputs{$code}[$index + 2]++;
				
				if ( ! ($seqCount % 100_000) )
				{
					my $keys = scalar(keys %outputs);
					my $frac = sprintf("%.2f", ($keys / ($seqCount+1)));
					print "ANALYZING SEQ ", $line, " CODE: ", $code, " INDEX: ", $index, " #", $seqCount, "\n";
					print "\tSEQS = ", ($seqCount+1) ," ; KEYS = ", $keys, " ", $frac,"%\n";
				}
				
				if (0)
				{
					my $outCount = $outputs{$code}[0];
					if ( $outCount > 1 )
					{
						print "\tGOTCHA  $code ", $outCount, "\n";
						print "\t\t";
						map {print "$_," if (defined $_) } @{$outputs{$code}}[1 .. $outCount + 1];
						print "\n";
					}
				}
				$charCount += length($line);
			}
		}
		close FH;
	}
	else
	{
		die "UNKNOWN FORMAT\n";
	}
	
	print "FILE ", $file ," HAS ", ($seqCount+1), " SEQUENCES AND ", $charCount," CHARACTHERS\n";
}
else
{
	print "RUNNING OVER DEFAULT\n";
}




#http://blog.urbanomic.com/robin2/archives/2006/03/blockpl_1.html
# Given an input text, find all of its rotations and sort
# them into alphabetical order. If this is imagined as
# forming a grid, which one rotation on each row, then the
# code consists of the characters in the last column,
# together with the index of the row containing the original
# input.
sub encode
{
    my ($s)       = @_;
    my @rotations = ();
    my $length    = length($s);
	
	#print "\tENCODE SEQ $s LENGTH = $length\n";	
    foreach my $i (0 .. $length-1)
    {
        my $rot = substr($s, $length-$i, $i) . substr($s, 0, $length-$i);
		push @rotations, [$rot, $i == 0];
    }

	#print "\tENCODE ROTATIONS = ",scalar(@rotations),"\n";

    @rotations = sort { $a->[0] cmp $b->[0] } @rotations;

    my $code = "";
    my $index = 0;

    foreach my $i (0 .. $#rotations)
    {
		$code  .= substr($rotations[$i]->[0], $length-1);
		$index  = $i if ( $rotations[$i]->[1] );
    }

    return $code, $index;
}

# Here, as in decode3, we avoid looping over the columns for
# each character. For the first column, all we need to find
# out is where the first occurrence of each character is.
# But we don't need to explicitly know have the first
# column: knowing how many of each character there are and
# the order of the distinct characters is enough.
sub decode5
{
    my ($code, $index) = @_;
    my @l = split(//, $code);

    my @which_occurrence;
    my %firsts;
    my %counts = ();
    foreach my $ch (@l)
    {
        if (!defined($counts{$ch}))
        {
            $counts{$ch} = 0;
        }

        push @which_occurrence, $counts{$ch};
        $counts{$ch} += 1;
    }

    my $count = 0;
    foreach my $ch (sort keys %counts)
    {
        $firsts{$ch} = $count;
        $count += $counts{$ch};
    }

    my $rev_decoded = '';
    for (0 .. $#l)
    {
        my $ch = $l[$index];
        $rev_decoded .= $ch;
        $index = $firsts{$ch} + $which_occurrence[$index];
    }
    my $decoded = reverse($rev_decoded);
    return $decoded;
}



# This is the stupid way to decode, as it involves
# reconstructing the entire grid, column by column. However
# it's only this I could honestly say I understand.
#
# Each column contains the same characters, but in a different
# order. We are given the content of the last column, so if
# we sort it into alphabetical order this will give us the
# content of the first column. If we rotate the grid one
# space to the right - so bringing the last column to the
# front - and sort again, then this will give us the content
# of the first two columns. If we rotate one space to the
# right and sort again this will give the first three
# columns. And so on.
sub decode1
{
    my ($code, $index) = @_;
    my @code = split(//, $code);
    my $length = length($code);
    my @rotations = ('') x $length;

    for (0 .. $length-1)
    {
        foreach my $i (0 .. $length-1)
        {
            $rotations[$i] =  $code[$i] . $rotations[$i];
        }
        @rotations = sort @rotations;
    }

    return $rotations[$index];
}


# The smart way is only to reconstruct the row of the grid
# that contained the original input. We are given the last
# column, and can easily construct the first column as
# before. We are also told which row of the full grid
# contains the original input, and this tells us the entry
# in the first column containing the first character. Because
# all the rows are rotations, if we knew for which row this
# entry appeared in the last column, the the entry for the
# same row in the first column would give us the second
# character. And if we knew where *this* entry appeared in
# the last column we could look to the first column again to
# give us the third character. Etc.
#
# The obvious problem is working out the correspondence
# between entries in the first and last columns. Any given
# character may occur many times, and you've got to pick the
# right occurrence, otherwise it all just goes horribly
# wrong.
#
# According to the original Burrows & Wheeler paper this
# is actually easy: for a given character the entries in the
# first column appear in the same order as the corresponding
# entries in the last column, e.g. the tenth letter 'e' in
# the first column matches up with the tenth letter 'e' in
# the last column.  This I don't understand. There's an
# explanation in the paper, but it didn't sink in. Look:
# I've been a bit stressed recently and I haven't been
# sleeping properly, and now I've lost an hour in bed due to
# British Summer Time. So I'm happy just to take it on trust
# for now.
#
# In the code l has the content of the last column, and f
# has the content of the first.
#
# After a night's sleep, my confusion over decode2 dispersed.
#
# Consider all the occurrences of a given character in the first
# column. As the rows are sorted alphabetically, these occurrences
# can be considered to be ordered according to the subsequent 
# characters in the rows.
#
# Now consider the occurrences of this character in the last column.
# As the rows are all rotations, these same "subsequent" characters
# appear at the beginnings of the rows. So (as the rows are sorted)
# the order of the occurrences will be the same as that in the first
# column.

sub decode2
{
    my ($code, $index) = @_;
    my @l = split(//, $code);
    my @f = sort(@l);
    
    my $which_occurrence = sub
    {
        my ($index) = @_;
        my $ch = $f[$index];
        my $n = 0;
        foreach my $i (0 .. $index-1)
        {
            if ($f[$i] eq $ch)
            {
                $n += 1;
            }
        }
        return ($ch, $n);
    };

    my $nth_occurrence = sub
    {
        my ($ch, $n) = @_;
        my $count = 0;
        foreach my $i (0 .. $#l)
        {
            if ($l[$i] eq $ch)
            {
                if ($count == $n)
                {
                    return $i;
                }
                else
                {
                    $count += 1;
                }
            }
        }

        die "This can't happen\n";
    };

    my $decoded = '';
    for (0 .. $#f)
    {
        my ($ch, $n) = $which_occurrence->($index);
        $decoded .= $ch;
        $index = $nth_occurrence->($ch, $n);
    }
    return $decoded;
}


# We need to loop over the first and last columns in order
# to match up corresponding entries, but this can happen
# once rather than for every character.
sub decode3
{
    my ($code, $index) = @_;
    my @l = split(//, $code);
    my @f = sort(@l);
    my @next_index;

    my %occurrences;
    foreach my $i (0 .. $#l)
    {
        my $ch = $l[$i];
        if (!defined($occurrences{$ch}))
        {
            $occurrences{$ch} = [];
        }
        push @{$occurrences{$ch}}, $i;
    }

	my $count;
	my $last_ch = '';
    foreach my $i (0 .. $#f)
    {
        my $ch = $f[$i];
        $count = 0 if ($ch ne $last_ch);

        push @next_index, $occurrences{$ch}->[$count];

        $count += 1;
        $last_ch = $ch;
    }

    my $decoded = '';
    for (0 .. $#f)
    {
        $decoded .= $f[$index];
        $index = $next_index[$index];
    }
    return $decoded;
}


# Reconstruct the
# original message starting from the end and working
# backwards. Conceptually, this makes no difference: the
# roles of the first and last columns are swapped in the
# algorithm. The following version is therefore very similar
# to decode2. However, there is less work to do in finding
# the nth occurrence of a character in the first column: as
# the rows are sorted it suffices to find the first
# occurrence and then go n spaces further.
 #
 #Given the other Robin's comment on my posting of a Perl implementation
 #of the non-compressing step in bzip, there could be no
 #stronger evidence that we are not the same person than
 #for me to post a follow-up.
 #
 #First off, I didn't give any indication before as to how
 #the algorithm implemented relates to data compression.
 #The encoded text is just a permutation of the input text;
 #it isn't any shorter. In fact there is an extra piece of
 #information that goes with this permutation, so the complete
 #encoded form is actually a little bit longer that the original.
 #
 #However, the nature of the permutation will generally make
 #it easy to compress subsequently. Recall that the encoding
 #algorithm works by sorting all the rotations of the input
 #text into alphabetical order, and then taking the last
 #character from each as the output. Suppose you have an
 #input text where the phrase "gentle reader" crops up a lot.
 #This means there would be a lot of rotations that started
 #"entle reader" and ended in "g". These rotations would appear
 #bunched up, due to the ordering of the rotations, and so the
 #output would have a long sequence of ‘g’s. Similarly, there
 #output would have a long sequence of ‘e’ due to the rotations
 #starting "ntle reader". Although the test cases I had in my
 #code don't show this up very well, in general the encoded
 #text will contain a great many sequences of repeated characters,
 #and so will provide very good input for something like run-length
 #encoding. It would be this next step that performs actual compression.
 #
 #Back to the Perl implementation. I had a number of variations 
 #for decoding, but they all worked by reconstructing the original
 #message starting with the first character, and moving forwards.
 #This follows very easily from the dumb implementation in decode1.
 #But it turns out that Burrows & Wheeler suggest starting from the
 #end and moving backwards. Well, you can imagine my embarrassment.
 #Here are a couple of variations on doing it this way: 
 #


sub decode4
{
    my ($code, $index) = @_;
    my @l = split(//, $code);
    my @f = sort(@l);

    my $which_occurrence = sub
    {
        my ($index) = @_;
        my $ch = $l[$index];
        my $n = 0;
        foreach my $i (0 .. $index-1)
        {
            if ($l[$i] eq $ch)
            {
                $n += 1;
            }
        }
        return ($ch, $n);
    };

    my $nth_occurrence = sub
    {
        my ($ch, $n) = @_;
        foreach my $i (0 .. $#l)
        {
            if ($f[$i] eq $ch)
            {
                return $i + $n;
            }
        }

        die "This can't happen\n";
    };

    my $rev_decoded = '';
    for (0 .. $#f)
    {
        my ($ch, $n) = $which_occurrence->($index);
        $rev_decoded .= $ch;
        $index = $nth_occurrence->($ch, $n);
    }
    my $decoded = reverse($rev_decoded);
    return $decoded;
}








sub time_repeated_runs
{
    my ($sub) = @_;
    my $iterations = 0;
    my $start = time;
    while ((time - $start) < 5)
    {
        $sub->();
        $iterations += 1;
    }
    return (time - $start) / $iterations;
}









if (0)
{
	foreach my $input (@inputs)
	{
		my $start = time;
		my ($code, $index) = encode($input);
		my $encTime = (time - $start);
		
		push(@{$outputs{$code}}, $index);
			
		if (0)
		{
			foreach my $decoder (\&decode1, \&decode2, \&decode3, \&decode4)
			{
				my $decoded = $decoder->($code, $index);
				#print "DECODED SEQUENCE: ", $decoded , "\n";
				die "Decoder error\n" if $decoded ne $input;
				print "Decoding time: ", time_repeated_runs(sub { $decoder->($code, $index) }), "\n";
			}
		}
	
		if (0)
		{
			my $r = timethese(1000, {
				'decode1' => sub { &decode1($code, $index) },
				'decode2' => sub { &decode2($code, $index) },
				'decode3' => sub { &decode3($code, $index) },
				'decode4' => sub { &decode4($code, $index) },
				'decode5' => sub { &decode5($code, $index) }
			});
			cmpthese $r;
		}
		
		if (1)
		{
			my $dTime  = time;
			my $return = &decode5($code, $index);
	
			my $nicely_formatted_code = $code;
			$nicely_formatted_code =~ s/\n/ /g;
			$nicely_formatted_code =~ s/(.{60})/$1\n/g;
	
			print "INDEX  $index\n";
			print "INPUT  $input\n";
			print "CODE   \n$nicely_formatted_code\n";
			print "RETURN $return\n";
			
			print "Encoding time: ", $encTime , "s\n";
			print "Decoding time: ", (time - $dTime), "s\n";
			#print "Encoding time: ", time_repeated_runs(sub { encode($input) }), "\n";
			
			print "Total time: ", (time - $start), "s\n";
			
			print "=" x 60, "\n\n";
		}
	}
}
print "TOTAL OUTPUTS: ", scalar(keys %outputs), "\n";


#Benchmark: timing 1000 iterations of decode1, decode2, decode3, decode4, decode5...
#   decode1: 410.49 wallclock secs (409.19 usr +  0.27 sys = 409.46 CPU) @    2.44/s (n=1000)
#   decode2: 109.89 wallclock secs (109.57 usr +  0.04 sys = 109.61 CPU) @    9.12/s (n=1000)
#   decode3:   1.85 wallclock secs (  1.85 usr +  0.00 sys =   1.85 CPU) @  540.54/s (n=1000)
#   decode4: 102.36 wallclock secs (102.22 usr +  0.04 sys = 102.26 CPU) @    9.78/s (n=1000)
#   decode5:   0.99 wallclock secs (  0.98 usr +  0.00 sys =   0.98 CPU) @ 1020.41/s (n=1000)
#          Rate decode1 decode2 decode4 decode3 decode5
#decode1    2.44/s     --     -73%    -75%   -100%   -100%
#decode2    9.12/s    274%     --      -7%    -98%    -99%
#decode4    9.78/s    300%      7%     --     -98%    -99%
#decode3  541.00/s  22033%   5825%   5428%     --     -47%
#decode5 1020.00/s  41682%  11085%  10335%     89%     --
#Total time: 626s
