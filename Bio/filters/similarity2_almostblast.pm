#!/usr/bin/perl
# Saulo Aflitos
# 2009 09 15 16 07
use strict;
use warnings;

package similarity2_almostblast;

#use DBI;
use threads;
use threads::shared;
use threads 'exit'=>'threads_only';

use lib "./";
use similarity;
use DBIconnect;

my %pref;
my %vars;
my $DName;

##########
## SIMILARITY 2 - ALMOSTBLAST + NWBLAST
##########
sub sthAnalizeSimilarity2
{
	my $name          = $_[0];
	my $displayName   = $_[1];
	my $commandGet    = $_[2];
	my $commandUpdate = $_[3];
	my $commadnGetAll = $_[4];
    my $columns       = $_[5];
	%pref             = %{$_[6]};
	%vars             = %{$_[7]};
	$DName            = uc($displayName);

	print "_"x2, "$DName :: STARTING SIMILARITY ANALYSIS 2\n";
	print "_"x4, "$DName :: RETRIEVING RESULT\n";
	#my $dbh2 = DBI->connect("DBI:mysql:$vars{database}", $vars{user}, $vars{pw}, {RaiseError=>1, PrintError=>1, AutoCommit=>0}) or die "COULD NOT CONNECT TO DATABASE $vars{database} $vars{user}: $! $DBI::errstr";
	my $dbh2 = &DBIconnect::DBIconnect();
	my $sth2 = $dbh2->prepare($commandGet);
	$sth2->execute();
	print "_"x6, "$DName :: ", $sth2->rows, " RESULT RETRIEVED SUCCESSIFULLY\n";

	my $countRow    = 0;
	my $startTime   = time;

	#my @listLig;
	#my @listM13;
	my @listSeq;
	my @listLiga;

	while(my $row = $sth2->fetchrow_arrayref) 
	{
		$countRow++;
		print "_"x4, "$DName :: ACQUIRING ROW # $countRow\n" if ( ! ($countRow % 25_000));
		my @row     = @{$row};
#			my $org     = $row[$vars{H_oldColumnIndex}{"idOrganism"}];
#			my $seqLig  = $row[$vars{H_oldColumnIndex}{"sequenceLig"}];
#			my $seqM13  = $row[$vars{H_oldColumnIndex}{"sequenceM13"}];
		my $seqSeq  = $row[$vars{H_oldColumnIndex}{"sequence"}];
		my $seqLiga = $row[$vars{H_oldColumnIndex}{"ligant"}];
		my $rowNum  = $row[$vars{H_oldColumnIndex}{$vars{primaryKey}}];

		#$listLig[$rowNum]  = $seqLig;
		#$listM13[$rowNum]  = $seqM13;
		$listSeq[$rowNum]  = $seqSeq;
		$listLiga[$rowNum] = $seqLiga;
	}
	$sth2->finish();
	$dbh2->commit();
	$dbh2->disconnect();

	print "_"x4, "$DName :: DATA GATHERED TO SIMILARITY ANALYSIS 2: ", (int((time - $startTime)+.5)), "s\n";

#		&analizeSimilarity2($commandUpdate, \@listSeq, \@listLiga);

	my $parts       = $vars{$vars{maxThreads}};
	my $threadCount = 0;
	foreach my $array (\@listSeq, \@listLiga)
	{
		my @part;
		my $arraySize = (scalar @{$array});
		my $fraction  = int($arraySize/$parts)+1;

		for (my $p = 0; $p < $parts; $p++)
		{
			my $start = $p     * $fraction;
			my $end   = $start + $fraction -1;
			while ($end >= $arraySize) {$end--};
#				print "START: $start END: $end FRACTION: $fraction PARTS: $parts TOTAL: ",$arraySize, "\n";
			$part[$p] = @{$array}[$start .. $end];
		}

		for (my $r = 0; $r < $parts; $r++)
		{
			while (threads->list(threads::running) > ($vars{maxThreads}-1))
			{
				sleep($vars{napTime}); 
			}

			foreach my $thr (threads->list(threads::joinable))
			{
				$thr->join();
			}

			$threadCount++;
			print "_"x6, "$DName :: STARTING SIMILARITY ANALYSIS 2 : THREAD ", $threadCount, "\n";
			#####################
			threads->new(\&analizeSimilarity2, ($commandUpdate, $array));
			#####################
		}
	}


	foreach my $thr (threads->list)
	{
		if ($thr->tid && !threads::equal($thr, threads->self))
		{
			while ($thr->is_running())
			{
				sleep($vars{napTime});
			}
		}
	}

	foreach my $thr (threads->list)
	{
		while ($thr->is_running())
		{
			sleep($vars{napTime});
		}
	}

	foreach my $thr (threads->list(threads::joinable))
	{
		$thr->join();
	}


	print "_"x2, "$DName :: SIMILARITY ANALYSIS 2 COMPLETED\n\n\n";
}

sub analizeSimilarity2
{
	my $commandUpdate = $_[0];

	my $Gresult  = [];

	my $startTime = time;

	#####################
	$Gresult  = &similarity::almostBlast($Gresult, @_[1 .. (scalar @_ - 1)]);
	#####################

	my $h = 0;
	for (my $g = 0; $g <@{$Gresult}; $g++)
	{
		if (defined $Gresult->[$g]) { $h++ }
	}
	print "_"x4, "$DName :: AFTER ALMOSTBLAST: $h INVALIDS\n\n";


	my $resultValid   = 0;
	my $resultInValid = 0;
	for (my $p = 0; $p < @{$Gresult}; $p++)
	{
		my $resultSum = $Gresult->[$p];

		if (defined $resultSum)
		{
			if ($resultSum == "-1")
			{
				$resultSum     = undef;
				$Gresult->[$p] = undef;
				$resultValid++;
			}
			else
			{
				$resultInValid++;
			}
		}
		else
		{
			$resultValid++;
		}
	}

	print "_"x4, "$DName :: VALID: ", $resultValid," INVALID: ", $resultInValid,"\n";

	# 1=not ok null=ok

	my $queryStart = time;
	#my $ldbh2 = DBI->connect("DBI:mysql:$vars{database}", $vars{user}, $vars{pw}, {RaiseError=>1, PrintError=>1, AutoCommit=>0}) or die "COULD NOT CONNECT TO DATABASE $vars{database} $vars{user}: $! $DBI::errstr";
	my $ldbh2 = &DBIconnect::DBIconnect();
	my $countResults = 0;
	for (my $r = 0; $r < @{$Gresult}; $r++)
	{
		if (defined $Gresult->[$r])
		{
			#print join("\t", @{$result}) . "\n";
			my $updateFirstFh = $ldbh2->prepare_cached($commandUpdate);
			   $updateFirstFh->execute($Gresult->[$r], $r);
			   $updateFirstFh->finish();
			$countResults++;
		}
	}
	$ldbh2->commit();
	$ldbh2->disconnect();

	print "_"x4, "$DName :: UPDATE QUERY TIME : " , (time-$queryStart) , "s FOR ",$countResults," QUERIES\n";
	print "_"x4, "$DName :: TOTAL TIME : ", (int((time - $startTime)+.5)), "s\n";
	return undef;
}

1;

