package fastaOO;
use strict;
use warnings;

our @EXPORT = qw ( destroy getFH getChrom getPos );

my $dna = 0;
my $fh;
my $fileName;
my @chromPos;

if (($ARGV[0]) && ( $ARGV[0] eq "test" ))
{
    &selftest();
}

#sub selftest
#{
#    print "SELF TESTING\n";
#    my $inFile = '/var/rolf/input/Debaryomyces_hansenii_CBS767_CHROMOSSOMES.fasta';
#    my @pairs;
#    $pairs[0] = [0, 1, 10];
#    $pairs[1] = [1, 1, 11];
#    $pairs[2] = [2, 50, 30];
#    $pairs[3] = [0, 170, 20];
#
#    use lib './';
#    use fastaOO;
#    my $fasta = fastaOO->new($inFile);
#
#    foreach my $pair (@pairs)
#    {
#        my $chrom  = $pair->[0];
#        my $pos    = $pair->[1];
#        my $length = $pair->[2];
#        print "GETTING CHROM $chrom POS $pos LENGTH $length\n";
#        my $seq = $fasta->getPos($chrom, $pos, $length);
#        print $seq, "\n";
#    }
#
#
#}

sub new {
    my $class    = shift;
    my $fileNam  = $_[0];
    my $self     = {};

    $fileName = $fileNam;

    if ( ! -f $fileName ) {die "FILE $fileName DOESNT EXISTS. PLEASE CHECK."};

    #print "OPENNING $fileName\n";
    open ($fh, "<" , "$fileName") or die "COULD NOT OPEN $fileName: $!\n";

    bless($self, $class);
    return $self;
}

sub DESTROY
{
    my $self      = shift;
    close $fh;
}

sub getFH
{
    my $self      = shift;
    return $fh;
}

sub getChrom
{
    my $self       = shift;
    my $chromNum   = $_[0];

    #print "GETTING CHROM $chromNum\n";

    my $chromCount = -1;
    my $on         = 0;
    my $seq        = '';
    my $start      = 0;

    if (defined $chromPos[$chromNum])
    {
        $start      = $chromPos[$chromNum];
        $chromCount = $chromNum - 1;
    }

    seek($fh, $start, 0);
    while (my $line = <$fh>)
    {
        chomp $line;
        if (substr($line, 0, 1) eq ">")
        {
            $chromCount++;
            my $tell = (tell($fh) - 200);
            $tell = 0 if ($tell < 0);
            $chromPos[$chromCount] = $tell;

            if ($on)
            {
                $on = 0;
                last;
            }
        }

        if ($on)
        {
            $seq .= $line;
        }

        if ($chromCount == $chromNum)
        {
            $on = 1;
        }
    }

    return $seq;
}


sub getPos
{
    my $self       = shift;
    my $chromNum   = $_[0];
    my $begin      = $_[1];
    my $length     = $_[2];
    my $end        = $begin + $length;
    my $diff       = 0;
    if ($dna)
    {
        $end -= 1;
        $diff = 1;
    }

    #print "GETTING CHROM $chromNum BEGIN $begin LENGTH $length END $end\n";
    #print "KNOWN CHROM POS: ",join(",", @{$chromPos}),"\n";

    my $chromCount = -1;
    my $on         = 0;
    my $seq        = undef;
    my $start      = 0;
    my $pos        = 0;
    my $foundChrom = 0;
    my $foundPos   = 0;
    my @chroms;

    if (defined $chromPos[$chromNum])
    {
        $start      = $chromPos[$chromNum];
        $chromCount = $chromNum - 1;
    }

    seek($fh, $start, 0);
    while (my $line = <$fh>)
    {
        chomp $line;
        if (substr($line, 0, 1) eq ">")
        {
            $chromCount++;
            my $tell = (tell($fh) - 200);
            $tell = 0 if ($tell < 0);
            $chromPos[$chromCount] = $tell;
            push(@chroms, $line);
            if ($on)
            {
                $on = 0;
                last;
            }

        }

        if ($on)
        {
            my $lengthLine = length($line);
            my $terminal   = $pos + $lengthLine;
            if ($terminal <= ($begin - $diff))
            {
                #print "IF1: BEGIN $begin END $end POS $pos LENGTHLINE $lengthLine TERMINAL $terminal\n";
                $pos = $terminal;
                next;
            }
            elsif ($pos > $end)
            {
                #print "IF2: BEGIN $begin END $end POS $pos LENGTHLINE $lengthLine TERMINAL $terminal\n";
                last;
            }
            else
            {
                #print "IF3: BEGIN $begin END $end POS $pos LENGTHLINE $lengthLine TERMINAL $terminal\n";
                for (my $p = 0; $p < $lengthLine; $p++)
                {
                    my $posP = $pos + $p;

                    #print "\tPOS $pos P $p POSP $posP";
                    if (($posP >= ($begin - $diff)) && ($posP < $end))
                    {
                        #print " JOIN";
                        $seq .= substr($line, $p, 1);
                    }
                    #print "\n";
                }
                $pos = $terminal;
            }
        }

        if ($chromCount == $chromNum)
        {
            $foundChrom = 1;
            $on         = 1;
        }
    }

    die "CHROMOSSOME NOT FOUND" if ( ! $foundChrom );
    if ( ! defined $seq )
    {
        print "GETTING CHROM $chromNum BEGIN $begin LENGTH $length END $end POS $pos\n";
        print join("\t\n", @chroms), "\n";
        die "SEQUENCE NOT FOUND" ;
    }
    return $seq;
}


1;
