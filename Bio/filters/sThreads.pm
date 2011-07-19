package sThreads;
use strict;
use warnings;

use threads;
use threads::shared;
use threads 'exit'=>'threads_only';


require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(waitThread newThread);

sub newThread
{
	my $maxThreads = $_[0];
	my $napTime    = $_[1];
	my $function   = $_[2];
	my @parameters = @_[3 .. (@_-1)];
	
	while (threads->list(threads::running) > ($maxThreads-1))
	{
		sleep($napTime); 
	}

	foreach my $thr (threads->list(threads::joinable))
	{
		$thr->join();
	}

	threads->new($function, @parameters);
}

sub waitThread
{
	my $napTime = $_[0];
	
	foreach my $thr (threads->list)
	{
		if ($thr->tid && !threads::equal($thr, threads->self))
		{
			while ($thr->is_running())
			{
				sleep($napTime);
			}
		}
	}

	foreach my $thr (threads->list)
	{
		while ($thr->is_running())
		{
			sleep($napTime);
		}
	}
	
	foreach my $thr (threads->list(threads::joinable))
	{
		$thr->join();
	}
}

1;
