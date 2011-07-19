#!/usr/bin/perl -w
use warnings;
use strict;
use Data::Dumper;
package printPos;
use lib "./";
use loadFasta;

my $header = "
0--------------------------------------------------------------------------------------------------1---------------------------------------------------------------------------------------------------2---------------------------------------------------------------------------------------------------3---------------------------------------------------------------------------------------------------4---------------------------------------------------------------------------------------------------5
         10        20        30        40        50        60        70        80        90        100       10        20        30        40        50        60        70        80        90        100       10        20        30        40        50        60        70        80        90        100       10        20        30        40        50        60        70        80        90        100       10        20        30        40        50        60        70        80        90        100
----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|\n";

sub printPos
{
    my %database = %{$_[0]};
    my $title    = $_[1];
    my $posname  = $_[2];
    my $idname   = $_[3];
    my $seq      = $_[4];
    my %fasta    = &loadFasta::loadFasta;
    my %seq;

    print  "PRINTING POSITION\n";
    my @lines;

    foreach my $oligomer (sort keys %database)
    {
        foreach my $count (sort keys %{$database{$oligomer}})
        {
            my $pos;
            my $id;

            $pos = $database{$oligomer}{$count}{$posname};
            $id  = $database{$oligomer}{$count}{$idname};

            if ($seq)
            {
                $seq{$id}{$pos} = $database{$oligomer}{$count}{$seq};
            }
            else
            {
                $seq{$id}{$pos} = $oligomer;
            }
        }
    }

    my $lines;
    foreach my $id (sort keys %seq)
    {
#       push(@lines, "#" x 50 . "\n");
#       push(@lines, "ID $id\n");
        my $seq = $fasta{$id};
        if ($seq)
        {
            push(@lines, "*" x 10 . $id . "*" x 10);
            push(@lines, $header);
            push(@lines, &loadFasta::getReverseComplement($seq) . "\n");
            push(@lines, &loadFasta::getReverse($seq)           . "\n");
            push(@lines, &loadFasta::getComplement($seq)        . "\n");
            push(@lines, $seq . "\n");
    
            my @array;
            foreach my $pos (sort keys %{$seq{$id}})
            {
                my $oligo = $seq{$id}{$pos};
                my $start = ($pos - 1);
                my $end   = (($pos - 1) + length($oligo));
                my $j     = 0;
                for (my $i = $start; $i < $end; $i++)
                {
                    $array[$i] = substr($oligo,$j++,1);
                }
            }
            for (my $i = 0; $i < length($seq); $i++)
            {
                my $line;
                if (exists $array[$i])
                {
                    $line .= $array[$i];
                }
                else
                {
                    $line .= "-";
                }
                push(@lines, $line);
            }
            push(@lines, "\n\n\n");
            push(@lines, "#" x 50 . "\n");
            $lines++;
        }
        else
        {
            print "NON EXISTENT ID: $id\n";
        }
    }

    open (FILE,">$title.txt");
    print FILE @lines;
    close FILE;
    print  "\t.....................POSITION PRINTED " . scalar(keys %seq) . "/" . $lines . " SEQUENCES\n";
}

sub printPosTair
{
    my %fasta = %{$_[0]};
    my %seq   = %{$_[1]};

#   print  "PRINTING POSITION\n";
    my @lines;
    foreach my $id (sort keys %seq)
    {
#       push(@lines, "#" x 50 . "\n");
#       push(@lines, "ID $id\n");
        foreach my $frame (sort keys %{$seq{$id}})
        {
            my $seq = $fasta{$id}{$frame};
            push(@lines, "*" x 10 . uc($frame) . "*" x 10);
            push(@lines, $header);
            push(@lines, $fasta{$id}{$frame} . "\n");
            my @array;
            foreach my $pos (sort keys %{$seq{$id}{$frame}})
            {
                my $oligo = $seq{$id}{$frame}{$pos};
                my $start = ($pos - 1);
                my $end   = (($pos - 1) + length($oligo));
                my $j     = 0;
                for (my $i = $start; $i < $end; $i++)
                {
                    $array[$i] = substr($oligo,$j++,1);
                }
            }
            for (my $i = 0; $i < length($seq); $i++)
            {
                my $line;
                if (exists $array[$i])
                {
                    $line .= $array[$i];
                }
                else
                {
                    $line .= "-";
                }
                push(@lines, $line);
            }
            push(@lines, "\n\n\n\n");
        }
#       push(@lines, "#" x 50 . "\n");
        open (FILE,">>$id.txt");
        print FILE @lines;
        close FILE;
    }
#   print @lines;

#   print  "POSITION PRINTED\n";
}

1;