#!/usr/bin/perl
# Saulo Aflitos
# 2009 09 15 16 07
use strict;
use warnings;

package similarity6_complexity;

#use DBI;
use threads;
use threads::shared;
use threads 'exit'=>'threads_only';

use lib "./";
use dnaCode;
use complexity;
use folding;
use DBIconnect;

my %pref;
my %vars;
my $DName;

#################
####### FOLD COMPLEXITY
#################
sub sthAnalizeFoldComplexity
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

	my $startComplexity = time;
	print "_"x2, "$DName :: STARTING FOLD COMPLEXITY ANALYSIS\n";
	print "_"x4, "$DName :: RETRIEVING RESULT\n";
	#my $ldbhC = DBI->connect("DBI:mysql:$vars{database}", $vars{user}, $vars{pw}, {RaiseError=>1, PrintError=>1, AutoCommit=>0}) or die "COULD NOT CONNECT TO DATABASE $vars{database} $vars{user}: $! $DBI::errstr";
    my $ldbhC = &DBIconnect::DBIconnect();
    
	my $sthC = $ldbhC->prepare($commandGet);
	$sthC->execute();
	print "_"x6, "$DName :: ", $sthC->rows, " RESULTS RETRIEVED SUCCESSIFULLY\n";
	my $rc = $sthC->rows;
	my $LbatchInsertions = $vars{batchInsertions};
	if ($LbatchInsertions > ($rc/$vars{maxThreads}))
	{
		$LbatchInsertions = int($rc/$vars{maxThreads});
	}

	my $countRow = 0;
	my @batch;

	my $threadCount = 0;
	while(my $row = $sthC->fetchrow_arrayref) 
	{
		$countRow++;
		if ( (scalar @batch) == $LbatchInsertions )
		{
			my @row = @{$row};
			push(@batch, \@row);

			while (threads->list(threads::running) > ($vars{maxThreads}-1))
			{
				sleep($vars{napTime}); 
			}

			print "\t$DName :: ANALYZING ROW # $countRow\n";
			foreach my $thr (threads->list(threads::joinable))
			{
				$thr->join();
			}
			print "\t\t$DName :: STARTING THREAD $threadCount ($countRow)\n";
			threads->new(\&analizeFoldComplexityRow, (\@batch, $threadCount, $commandUpdate, $columns));
			$threadCount++;
			@batch = ();
		}
		else
		{
			my @row = @{$row};
			push(@batch, \@row);
		};
	}
	print "\t\t$DName :: STARTING LAST THREAD $threadCount\n";
	threads->new(\&analizeFoldComplexityRow, (\@batch, $threadCount, $commandUpdate));
	@batch = ();



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

	$sthC->finish();
	$ldbhC->commit();
	$ldbhC->disconnect();
	print "_"x2, "$DName :: FOLD COMPLEXITY ANALYSIS COMPLETED IN ", (int(time-$startComplexity)),"s\n\n\n";
}




sub analizeFoldComplexityRow
{
	my @batch         = @{$_[0]};
	my $innerThread   =   $_[1];
	my $commandUpdate =   $_[2];
    my $columns       =   $_[3];
	my $startTime     = time;
	my @results;


	my ($indexStartLig,				$indexStartM13,				$indexIdOrganism,				$indexSequenceLig,				$indexSequenceM13,				$indexId) =
	($vars{H_oldColumnIndex}{"startLig"}, $vars{H_oldColumnIndex}{"startM13"}, $vars{H_oldColumnIndex}{"idOrganism"}, $vars{H_oldColumnIndex}{"sequenceLig"}, $vars{H_oldColumnIndex}{"sequenceM13"}, $vars{H_oldColumnIndex}{$vars{primaryKey}});


	print "\t\t$DName :: THREAD $innerThread RUNNING WITH " . (scalar @batch) . " INPUTS\n";
	foreach my $row (@batch)
	{
		#my $ligStart = $row[$indexStartLig];
		#my $m13Start = $row[$indexStartM13];
		#my $org      = $row[$indexIdOrganism];
		my $seqLig   = $row->[$indexSequenceLig];
		my $seqM13   = $row->[$indexSequenceM13];
		my $rowNum   = $row->[$indexId];

		if ( ! defined $rowNum ) { die "ROWNUM NOT DEFINED"; };

		#my $seq      = $row[$newColumnIndex{"sequence"}];
		#my $ligant   = $row[$newColumnIndex{"ligant"}];

		#print "BEFORE $seqLig $seqM13\n";
		$seqLig    = &dnaCode::digit2dna($seqLig);
		$seqM13    = &dnaCode::digit2dna($seqM13);
		my $seq    = "$seqLig$seqM13";
		#my $ligant = substr($seqLig, -10) . substr($seqM13, 0, 10);

		#print "AFTER\n$seqLig.$seqM13\n$seq\n$ligant\n";

		#print join("\t", @row[0 .. 15]) . " > $rowNum\n";

		my $result = 0;

		#my $m13StartRel = $m13Start - $ligStart;
		#my $ligStartRel = 0;

		my $complexity  = &complexity::HasMasked($seq);
		if ($complexity) { $result += 1; };
		if ( ! defined $complexity) { die "COMPLEXITY RETURNED NULL"; };

		my $seqFold = &folding::checkFolding($seq);
		my $ligFold = &folding::checkFolding($seqLig);
		my $m13Fold = &folding::checkFolding($seqM13);

		if ( ! defined $seqFold) { die "seqFOLD RETURNED NULL"; };
		if ( ! defined $ligFold) { die "ligFOLD RETURNED NULL"; };
		if ( ! defined $m13Fold) { die "m13FOLD RETURNED NULL"; };

		if ($seqFold) { $result += 2};
		if ($ligFold) { $result += 4};
		if ($m13Fold) { $result += 8};

		if ($result > 16)
		{
			#print "LIGSTART: $ligStart M13START: $m13Start\n$seq\n";
			#print " "x($m13StartRel-10) . "$ligant\n$seqLig.$seqM13\n";
			print "RESULT     : $result\n";
			print "COMPLEXITY : $complexity\n";
			print "FOLDING    : LIG=$ligFold, M13=$m13Fold, SEQ=$seqFold\n\n";
		}

		if ( ! defined $result) { die "RESULT RETURNED NULL"; };
		my @newData = ($complexity, $seqFold, $ligFold, $m13Fold, $result, $rowNum);
		push(@results, \@newData);
	} # end foreach my row



	my $queryStart = time;
	#my $ldbhAC = DBI->connect("DBI:mysql:$vars{database}", $vars{user}, $vars{pw}, {RaiseError=>1, PrintError=>1, AutoCommit=>0}) or die "COULD NOT CONNECT TO DATABASE $vars{database} $vars{user}: $! $DBI::errstr";
    my $ldbhAC = &DBIconnect::DBIconnect();
	my $countResults = 0;

#	print "UPDATE: $commandUpdate\n";

	foreach my $result (@results)
	{
		#print join("\t", @{$result}) . "\n";
		my $updateFirstFh = $ldbhAC->prepare_cached($commandUpdate);
		   $updateFirstFh->execute(@{$result});
		   $updateFirstFh->finish();
		$countResults++;
	}
	$ldbhAC->commit();
	$ldbhAC->disconnect();

	print "\t\t\t$DName :: UPDATE QUERY FOR THREAD $innerThread TOOK " . (time-$queryStart) . "s FOR $countResults QUERIES\n";
	print "\t\t$DName :: THREAD $innerThread HAS FINISHED (" . (time-$startTime) . "s)\n";
	return undef;
}




1;

