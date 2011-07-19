#!/usr/bin/perl
# Saulo Aflitos
# 2009 09 15 16 07
use strict;
use warnings;

package similarity4_blastNWG;

#use DBI;

use lib "./";
use blast;
use DBIconnect;

my %pref;
my %vars;
my $DName;

##########
## SIMILARITY 4 - GLOBAL NWBLAST
##########
sub sthAnalizeSimilarity4
{
	my $name            = $_[0];
	my $displayName     = $_[1];
	my $commandGetValid = $_[2];
	my $commandUpdate   = $_[3];
	my $commandGetAll   = $_[4];
    my $columns         = $_[5];
	%pref               = %{$_[6]};
	%vars               = %{$_[7]};
	$DName              = uc($displayName);

	print "_"x2, "$DName :: STARTING SIMILARITY ANALYSIS 4\n";
	print "_"x4, "$DName :: RETRIEVING RESULT\n";

	my $dbh4 = DBI->connect("DBI:mysql:$vars{database}", $vars{user}, $vars{pw}, {RaiseError=>1, PrintError=>1, AutoCommit=>0})
		 or die "COULD NOT CONNECT TO DATABASE $vars{database} $vars{user}: $! $DBI::errstr";

	my $sth4V = $dbh4->prepare($commandGetValid);
	$sth4V->execute();
	my $rowsV = $sth4V->rows;
	print "_"x6, "$DName :: ",$rowsV, " RESULT RETRIEVED SUCCESSIFULLY\n";

	my $sth4A = $dbh4->prepare($commandGetAll);
	$sth4A->execute();
	my $rowsA = $sth4A->rows;
	print "_"x6, "$DName :: ",$rowsA, " RESULTS RETRIEVED SUCCESSIFULLY\n";

	my $startTime = time;

	my @listLigV;
	my @listM13V;
	my @listSeqV;
	my @listLigaV;

	my @listLigA;
	my @listM13A;
	my @listSeqA;
	my @listLigaA;

	my %listsV;
	my %listsA;

	my $countRow  = 0;
	while(my $row = $sth4V->fetchrow_arrayref) 
	{
		$countRow++;
		print "_"x4, "$DName :: ACQUIRING VALID ROW # $countRow\n" if ( ! ($countRow % (int($rowsV / 5))));
		my @row     = @{$row};

		#my $org     = $row[$vars{H_oldColumnIndex}{"idOrganism"}];
		#my $seqLig  = $row[$vars{H_oldColumnIndex}{"sequenceLig"}];
		#my $seqM13  = $row[$vars{H_oldColumnIndex}{"sequenceM13"}];
		#my $seqSeq  = $row[$vars{H_oldColumnIndex}{"sequence"}];
		#my $seqLiga = $row[$vars{H_oldColumnIndex}{"ligant"}];
		my $rowNum  = $row[$vars{H_oldColumnIndex}{$vars{primaryKey}}];

		foreach my $key (@{$columns})
		{
			$listsV{$key}[$rowNum] = $row[$vars{H_oldColumnIndex}{$key}];
		}

		#$listLigV[$rowNum]  = $seqLig;
		#$listM13V[$rowNum]  = $seqM13;
		#$listSeqV[$rowNum]  = $seqSeq;
		#$listLigaV[$rowNum] = $seqLiga;
	}
	$sth4V->finish();

	$countRow    = 0;
	while(my $row = $sth4A->fetchrow_arrayref) 
	{
		$countRow++;
		print "_"x4, "$DName :: ACQUIRING ALL ROW # $countRow\n" if ( ! ($countRow % (int($rowsA / 5))));
		my @row     = @{$row};

		#my $org     = $row[$vars{H_oldColumnIndex}{"idOrganism"}];
		#my $seqLig  = $row[$vars{H_oldColumnIndex}{"sequenceLig"}];
		#my $seqM13  = $row[$vars{H_oldColumnIndex}{"sequenceM13"}];
		#my $seqSeq  = $row[$vars{H_oldColumnIndex}{"sequence"}];
		#my $seqLiga = $row[$vars{H_oldColumnIndex}{"ligant"}];
		my $rowNum  = $row[$vars{H_oldColumnIndex}{$vars{primaryKey}}];

		foreach my $key (@{$columns})
		{
			$listsA{$key}[$rowNum] = $row[$vars{H_oldColumnIndex}{$key}];
		}

		#$listLigA[$rowNum]  = $seqLig;
		#$listM13A[$rowNum]  = $seqM13;
		#$listSeqA[$rowNum]  = $seqSeq;
		#$listLigaA[$rowNum] = $seqLiga;
	}
	$sth4A->finish();

	$dbh4->commit();
	$dbh4->disconnect();


	print "_"x4, "$DName :: DATA GATHERED TO SIMILARITY ANALYSIS 4: ", (int((time - $startTime)+.5)), "s\n";
	#####################
	#&analizeSimilarity4($commandUpdate, \@listSeqV, \@listSeqA, \@listLigaV, \@listLigaA);
	&analizeSimilarity4($commandUpdate, \%listsV, \%listsA);
	#####################
	print "_"x2, "$DName :: SIMILARITY ANALYSIS 4 COMPLETED\n\n\n";
}

sub analizeSimilarity4
{
	my $commandUpdate = $_[0];
	my $listsV        = $_[1];
	my $listsA        = $_[2];

	my $Gresult  = [];

	my $startTime = time;

	#####################
	my @lists;
	foreach my $key (keys %{$listsV})
	{
		my $listV = $listsV->{$key};
		my $listA = $listsA->{$key};
		push(@lists, $listV);
		push(@lists, $listA);
	}
	$Gresult = &blast::blastNWIterateTwo($Gresult, @lists);
	#####################
	my $h = 0;
	for (my $g = 0; $g <@{$Gresult}; $g++)
	{
		if (defined $Gresult->[$g]) { $h++ }
	}
	print "$DName :: AFTER BLASTNWTWO : $h INVALIDS\n";


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
			#$resultValid++;
		}
	}

	print "_"x4, "$DName :: VALID: ", $resultValid," INVALID: ", $resultInValid,"\n";

	# 1=not ok null=ok


	my $queryStart = time;
	#my $ldbh4 = DBI->connect("DBI:mysql:$vars{database}", $vars{user}, $vars{pw}, {RaiseError=>1, PrintError=>1, AutoCommit=>0}) or die "COULD NOT CONNECT TO DATABASE $vars{database} $vars{user}: $! $DBI::errstr";
	my $ldbh4 = &DBIconnect::DBIconnect();
	my $countResults = 0;
	for (my $r = 0; $r < @{$Gresult}; $r++)
	{
		if (defined $Gresult->[$r])
		{
			#print join("\t", @{$result}) . "\n";
			my $updateFirstFh = $ldbh4->prepare_cached($commandUpdate);
			   $updateFirstFh->execute($Gresult->[$r], $r);
			   $updateFirstFh->finish();
			$countResults++;
		}
	}
	$ldbh4->commit();
	$ldbh4->disconnect();

	print "_"x4, "$DName :: UPDATE QUERY TIME : " , (time-$queryStart) , "s FOR ",$countResults," QUERIES\n";
	print "_"x4, "$DName :: TOTAL TIME : ", (int((time - $startTime)+.5)), "s\n";
	return undef;
}

1;

