#!/usr/bin/perl
# Saulo Aflitos
# 2009 09 15 16 07
use strict;
#use DBI;

package similarity1_quasiblast;

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
## SIMILARITY 1 - QUASIBLAST
##########
sub sthAnalizeSimilarity1
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
	my $DNameOrig        = $DName;

	print "_"x2, "$DName :: STARTING SIMILARITY ANALYSIS 1\n";
	print "_"x4, "$DName :: RETRIEVING RESULT\n";
	#my $dbh1 = DBI->connect("DBI:mysql:$vars{database}", $vars{user}, $vars{pw}, {RaiseError=>1, PrintError=>1, AutoCommit=>0}) or die "COULD NOT CONNECT TO DATABASE $vars{database} $vars{user}: $! $DBI::errstr";
	my $dbh1 = &DBIconnect::DBIconnect();
	
	my $sth1 = $dbh1->prepare($commandGet);
	$sth1->execute();
	print "_"x6, "$DName :: ", $sth1->rows, " RESULTS RETRIEVED SUCCESSIFULLY\n";

	my $countRow    = 0;
	my $startTime   = time;

	#my @listLig;
	#my @listM13;
	#my @listSeq;
	#my @listLiga;
	my %lists;

	while(my $row = $sth1->fetchrow_arrayref) 
	{
		$countRow++;


		print "_"x4, "$DName :: ACQUIRING ROW # $countRow\n" if ( ! ($countRow % 25_000));
		my @row     = @{$row};
		#TODO: SOFTCODE
		#my $org     = $row[$vars{H_oldColumnIndex}{"idOrganism"}];
		#my $seqLig = $row[$vars{H_oldColumnIndex}{"sequenceLig"}];
		#my $seqM13 = $row[$vars{H_oldColumnIndex}{"sequenceM13"}];
		#my $seqSeq  = $row[$vars{H_oldColumnIndex}{sequence}];
		#my $seqLiga = $row[$vars{H_oldColumnIndex}{ligant}];
		my $rowNum  = $row[$vars{H_oldColumnIndex}{$vars{primaryKey}}];

		for my $col (@{$columns})
		{
			$lists{$col}[$rowNum] = $row[$vars{H_oldColumnIndex}{$col}];
		}

		#$listLig[$rowNum]  = $seqLig;
		#$listM13[$rowNum]  = $seqM13;
		#$listSeq[$rowNum]  = $seqSeq;
		#$listLiga[$rowNum] = $seqLiga;
	}
	$sth1->finish();
	$dbh1->commit();
	$dbh1->disconnect();

	print "_"x4, "$DName :: DATA GATHERED TO SIMILARITY ANALYSIS 1: ", (int((time - $startTime)+.5)), "s\n";
	#####################
	#&analizeSimilarity1($commandUpdate, \@listLig, \@listM13, \@listSeq, \@listLiga);
	#&analizeSimilarity1($commandUpdate, \@listSeq, \@listLiga);
	#&analizeSimilarity1($commandUpdate, \%lists);
	#####################
	my $tCount = time;
	
	#$vars{maxThreads} = 1;
	my $threadCount = 1;
	foreach my $key (keys %lists)
	{
		my $arr = $lists{$key};
		next if ( ! $arr );
		
		while (threads->list(threads::running) > ($vars{maxThreads}-1))
		{
			sleep($vars{napTime}); 
		}

		foreach my $thr (threads->list(threads::joinable))
		{
			$thr->join();
		}

		print "_"x6, "$DName :: STARTING SIMILARITY ANALYSIS 1 : THREAD ", $threadCount, " / ", (scalar keys %lists) ,"\n";
		#####################
		threads->new(\&analizeSimilarity1, ($commandUpdate, $arr, "$key\_thr$threadCount"));
		#####################
		$threadCount++;
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
	
	print "_"x4, "$DName :: SIMILARITY ANALYSIS 1 THREADS COMPLETED: ", (int((time - $tCount)+.5)), "s\n";
	print "_"x2, "$DName :: SIMILARITY ANALYSIS 1 COMPLETED: ", (int((time - $startTime)+.5)), "s\n\n\n";
}


sub analizeSimilarity1
{
	my $commandUpdate = $_[0];
	my $input         = $_[1];
	my $name          = $_[2];

	my $Gresult  = [];

	my $startTime = time;

	#####################
	#foreach my $key (keys %{$lists})
	#{
	#	my $input = $lists->{$key};
		print "_"x6, "$DName :: SIMILARITY ANALYSIS 1: $name\n";
		$Gresult = &similarity::quasiBlast($Gresult, $input, $name);
	#}
	#####################

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

	print "_"x4, "$DName :: $name : VALID: ", $resultValid," INVALID: ", $resultInValid,"\n";


	# 1=not ok null=OK

	my $queryStart = time;
	#my $ldbh1 = DBI->connect("DBI:mysql:$vars{database}", $vars{user}, $vars{pw}, {RaiseError=>1, PrintError=>1, AutoCommit=>0}) or die "COULD NOT CONNECT TO DATABASE $vars{database} $vars{user}: $! $DBI::errstr";
	my $ldbh1 = &DBIconnect::DBIconnect();
	my $countResults = 0;
	for (my $r = 0; $r < @{$Gresult}; $r++)
	{
		if (defined $Gresult->[$r])
		{
			#print join("\t", @{$result}) . "\n";
			my $updateFirstFh = $ldbh1->prepare_cached($commandUpdate);
			   $updateFirstFh->execute($Gresult->[$r], $r);
			   $updateFirstFh->finish();
			$countResults++;
		}
	}
	$ldbh1->commit();
	$ldbh1->disconnect();

	print "_"x4, "$DName :: $name : UPDATE QUERY TIME : " , (time-$queryStart) , "s FOR ", $countResults," QUERIES\n";
	print "_"x4, "$DName :: $name : TOTAL TIME : ", (int((time - $startTime)+.5)), "s\n";
	return undef;
}

1;
