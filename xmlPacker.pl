#!/usr/bin/perl -w
use strict;

my $infile = $ARGV[0] || die "NO FILE DESIGNATED";

open INFILE, "<$infile" or die "COULD NOT OPEN IN FILE $infile:$!";
my $unpack    = 0;
my $dic       = 0;
my $doc       = "";
my $dicStart  = 0;
my $dicEnd    = 0;

my %wordDist;
my @wordDistId;

{
    local $/;
    $doc       = <INFILE>;
}
close INFILE;

&findDic();

if ($unpack)
{
    &unpackXML();
    &exportXML();
}
else
{
    &genDic();
    &packXML();
    &exportXML();
}



sub unpackXML
{
    print "UNPACKING XML\n";
#$scape
    for (my $w = 0; $w < @wordDistId; $w++)
    {
        my $value = $wordDistId[$w];
        my $hex   = sprintf("%x", $w);
        printf "CHANGING %-2s (%02d) BY %-s\n", $hex, $w, $value;
        $doc =~ s#\<\{$hex\}(.*?)\>(.*?)\<\/\{$hex\}\>#\<$value$1\>$2\<\/$value\>#sg;
    }
    print "XML UNPACKED\n";
}
sub genDic
{
    print "GENERATING DICTIONARY\n";
    #foreach my $line (split("\n", $doc))
    #{
    #   if ($line =~ m#\<(\w*).*?\>(.*?)\<\/\1\>#sg)
    #   {
    #       my $key   = $1;
    #       my $value = $2;
    #       $wordDist{$key}++;
    #   }
    #}


    if ($doc =~ m#\<(\w*).*?\>(.*?)\<\/\1\>#sg)
    {
        my $key   = $1;
        my $value = $2;
        $wordDist{$key}++;
        findDiamonds($2);
    }


    foreach my $key (sort {$wordDist{$b} <=> $wordDist{$a}} keys %wordDist)
    {
        if ($wordDist{$key} > 1)
        {
            #print $key, " > ", $wordDist{$key} , "\n";
            push(@wordDistId, $key);
        }
    }

    for ( my $w = 0; $w < @wordDistId ; $w++ )
    {
        for ( my $x = 0; $x < @wordDistId ; $x++ )
        {
            if ( $wordDist{$wordDistId[$w]} == $wordDist{$wordDistId[$x]} )
            {
                if (length($wordDistId[$x]) < length($wordDistId[$w]))
                {
                    my $tmpWord = $wordDistId[$w];
                    $wordDistId[$w] = $wordDistId[$x];
                    $wordDistId[$x] = $tmpWord;
                }
            }
        }
    }

    for ( my $w = 0; $w < @wordDistId ; $w++ )
    {
        my $hex = sprintf("%x",$w);
        if (length($wordDistId[$w]) <= length($hex))
        {
            print "JUST NOT WORTH IT MAN: $wordDistId[$w] TO $hex\n";
        }
        printf "%02d (%-2s) > %-12s >> %-d\n", $w, $hex, $wordDistId[$w], $wordDist{$wordDistId[$w]};
    }
    print "DICTIONARY GENERATED\n";
}

sub findDiamonds
{
    my $str = $_[0];
    #print "STR ", $str, "\n";
    while ($str =~ m#\<(\w*).*?\>(.*?)\<\/\1\>#sg)
    {
        my $key   = $1;
        my $value = $2;
        $wordDist{$key}++;
        &findDiamonds($value);
    }
}

sub exportXML
{
    my $ext = "";
    if ($unpack)
    {
        $ext = ".xml"
    }
    else
    {
        $ext = ".zxml"
    }

    open OUTFILE, ">$infile$ext" or die "COULD NOT OPEN OUTPUT FILE $infile$ext: $!";

    if ($unpack)
    {
        my $linecount = 0;
        foreach my $line (split("\n", $doc))
        {   
            $linecount++;;
            if (($linecount < $dicStart) || ($linecount > $dicEnd))
            {
                print OUTFILE $line, "\n";
            }
        }
    }
    else
    {
        print OUTFILE $doc;
    }
    close OUTFILE;
}

sub packXML
{
    print "PACKING XML\n";
    my $dicContent;
    for (my $w = 0; $w < @wordDistId; $w++)
    {
        my $key = $wordDistId[$w];
        my $wh  = sprintf("%x",$w);

        $doc =~ s#\<($key)(.*?)\>(.*?)\<\/\1\>#\<\{$wh\}$2\>$3\<\/\{$wh\}\>#sg;
        $dicContent .= "<\{$wh\}>$key</\{$wh\}>\n";
    }

    my $dicXml  = "<dictionary>\n";
       $dicXml .= $dicContent;
       $dicXml .= "</dictionary>\n";

    $doc = $dicXml . $doc;

    print "XML PACKKED\n";
}

sub findDic
{
    print "SEARCHING FOR DICTIONARY\n";
    my $lineCount = 0;

    foreach my $line (split("\n", $doc))
    {
        $lineCount++;
        if (($lineCount <= 3) && ($line =~ /\<dictionary\>/))
        {
            $unpack = 1;
        }
        if ($unpack)
        {
            if ($line =~ /\<dictionary\>/)
            {
                $dic      = 1;
                $dicStart = $lineCount;
                next;
            }
            if ($line =~ /\<\/dictionary\>/)
            {
                $dic    = 0;
                $dicEnd = $lineCount;
                last;
            }

            if ($dic)
            {
                #print $line . "\n";
                if ($line =~ m#\<\{(\w+)\}.*?\>(.*?)\<\/\{\1\}\>#)
                {
                    my $key   = hex($1);
                    my $value = $2;
                    $wordDistId[$key] = $value;
                    #print "DIC $key > $value\n";
                }
            } # end if dic
        } #end if unpack
    }
    if ($unpack)
    {
        print "DICTIONARY FOUND. UNPACKING\n";
    }
    else
    {
        print "DICTIONARY NOT FOUND. PACKING\n";
    }
}

1;