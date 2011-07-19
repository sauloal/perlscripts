#!/usr/bin/perl -w
use strict;
package dnaPack;

sub unPackDNA
{
    my $bin    = $_[0];
    my $length = $_[1];
    my $strD;
    for (my $p = 0; $p < $length ; $p++)
    {
        $strD .= vec( $bin, $p, 2 );
    }
    $strD =~ tr/0123/ACGT/;
    return $strD;
}

sub packDNA
{
    my $inputD = $_[0];
    $inputD =~ tr/ACGT/0123/;
    my $n      = length($inputD);
    my $bin    = 0 x ($n/4);
    for (my $p = 0; $p < $n; $p++)
    {
        vec($bin, $p,2) = substr($inputD, $p, 1);
    }
    return $bin;
}


1;