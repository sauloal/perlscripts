#!/usr/bin/perl -w
use strict;
use warnings;

open FILE, "<".$ARGV[0]."" or die "COULD NOT OPEN ".$ARGV[0]."\n";
my $out;

while (<FILE>)
{
	if (/(\s+)\"(\S+)\"(\s+\S+)\, \\/)
	{
		if (length($2) > 65)
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