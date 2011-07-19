#!/usr/bin/perl -w
#stack smashing detected
#gnuplot
#length > 70 crashes

#or fix
#line 1215
#    my $scrn = "$dir$ylabel";
#    if (length $scrn > 70) {$scrn = substr ($scrn, 0, 70)};
#    print GFILE " \"$scrn\" $tic, \\\n";
#line 1235
#        "set tics scale 0,0\n",

use strict;
use warnings;

open FILE, "<".$ARGV[0]."" or die "COULD NOT OPEN ".$ARGV[0]."\n";
my $out;

while (<FILE>)
{
    if (/(\s+)\"(\S+)\"(\s+\S+)\, \\/)
    {
        if (length($2) > 70)
        {
            $out .= "$1\"" . substr ($2, 0, 70) . "\"$3, \\\n";
        }
    }
    else
    {
        $out .= $_;
    }
}

close FILE;

#print $out;

open FILE, ">".$ARGV[0]."" or die "COULD NOT OPEN ".$ARGV[0]."\n";
print FILE $out;
close FILE;