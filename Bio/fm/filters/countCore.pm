#!/usr/bin/perl -w
# Saulo Aflitos
# 2009 09 15 16 07
use strict;
package countCore;

#print "checking cpuinfo...\n";
sub getCores
{
	if ( -f "/proc/cpuinfo" )
	{
		#print "the file is there... good...\n";
		open INFO, "</proc/cpuinfo" or die "COULD NOT OPEN CPUINFO :$!";
		
		my $processor;
		my $coreId;
		my %seen;
		while (my $line = <INFO>)
		{
			if ($line =~ /^physical id\s+\:\s+(\d)/)
			{
				$processor = $1;
				undef $coreId;
			}
			if ($line =~ /^core id\s+\:\s+(\d)/)
			{
				$coreId = $1;
				$seen{"$processor.$coreId"}++;
				undef $coreId;
			}
		}
		close INFO;
		
		foreach my $key (sort keys %seen)
		{
			#print "KEY $key\n";
		}
		
		return scalar(keys %seen);
	}
	
	return undef;
}