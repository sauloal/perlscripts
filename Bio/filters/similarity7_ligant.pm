#!/usr/bin/perl
# Saulo Aflitos
# 2009 08 27 18 11
use strict;
use DBI;
package similarity7_ligant;



#################
####### LIGANT FUNCTIONS
#################
#NOT NEEDED
sub sthGenerateLigants
{
	my $ldbhGL = DBI->connect("DBI:mysql:$database", $user, $pw, {RaiseError=>1, PrintError=>1, AutoCommit=>0})
			or die "COULD NOT CONNECT TO DATABASE $database $user: $! $DBI::errstr";
	my $sthL      = 
#$ldbhGL->prepare_cached($commandGetSim2Results);
	my $countRow    = 0;
	my @batch;

	while(my $row = $sthL->fetchrow_arrayref) 
	{
		$countRow++;
		if ( (scalar @batch) == $batchInsertions )
		{
			my @row = @{$row};
			push(@batch, \@row);
			print "\tANALYZING ROW # $countRow\n";

			&insertLigants(\@batch);
			@batch = ();
		}
		else
		{
			my @row = @{$row};
			push(@batch, \@row);
		};
	}
	&insertLigants(\@batch);
	@batch = ();
	$sthL->finish();
	$ldbhGL->commit();
	$ldbhGL->disconnect();
}

#NOT NEEDED
sub insertLigants
{
	my $startTime   = time;
	my @batch       = @{$_[0]};
	my @results;

	print "\t\tUNPACKING " . (scalar @batch) . " INPUTS\n";
	foreach my $row (@batch)
	{
		my @row      = @{$row};

		my $seqLig   = $row[$oldColumnIndex{"sequenceLig"}];
		my $seqM13   = $row[$oldColumnIndex{"sequenceM13"}];
		my $rowNum   = $row[$oldColumnIndex{"Id"}];
		if ( ! defined $rowNum ) { die "ROWNUM NOT DEFINED"; };

		#my $seq      = $row[$newColumnIndex{"sequence"}];
		#my $ligant   = $row[$newColumnIndex{"ligant"}];

		#print "BEFORE $seqLig $seqM13\n";
		$seqLig    = &dnaCode::digit2dna($seqLig);
		$seqM13    = &dnaCode::digit2dna($seqM13);
		my $seq    = "$seqLig$seqM13";
		my $ligant = substr($seqLig, -10) . substr($seqM13, 0, 10);
		#$ligant    = &dna2digit($ligant);

		#print "AFTER\n$seqLig.$seqM13\n$seq\n$ligant\n";

		#print join("\t", @row[0 .. 15]) . " > $rowNum\n";

		my @newData = ($ligant, $rowNum);
		push(@results, \@newData);
	} # end foreach my row



	my $queryStart = time;
	my $ldbhL = DBI->connect("DBI:mysql:$database", $user, $pw, {RaiseError=>1, PrintError=>1, AutoCommit=>0})
			or die "COULD NOT CONNECT TO DATABASE $database $user: $! $DBI::errstr";
	my $countResults = 0;
	foreach my $result (@results)
	{
		#print join("\t", @{$result}) . "\n";
		my $updateFirstFh = $ldbhL->prepare_cached($commandUpdateLigants);
		   $updateFirstFh->execute(@{$result});
		   $updateFirstFh->finish();
		$countResults++;
	}
	$ldbhL->commit();
	$ldbhL->disconnect();

	print "\t\t\tUPDATE QUERY TOOK " . (time-$queryStart) . "s FOR $countResults QUERIES\n";
	return undef;
}

#TO FIX
sub analyzeLigants
{
	my $commandUpdateExtra = "UPDATE \`probe\`.\`$originalTable\` SET LigantUnique = ?, AnalysisResult = (AnalysisResult + ?) WHERE Id = ?";
	my $commandGetLigant   = "SELECT Id, Ligant, nameOrganism FROM $originalTable";
	my %ligantSeen;



	print "\tANALYZING LIGANTS\n";	
	my $ligantsTime = time;
	my $queryStart  = time;	
	my $ldbhAL      = DBI->connect("DBI:mysql:$database", $user, $pw, {RaiseError=>1, PrintError=>1, AutoCommit=>0}) or die "COULD NOT CONNECT TO DATABASE $database $user: $! $DBI::errstr";
	my $resultFh    = $ldbhAL->prepare($commandGetLigant);
	$resultFh->execute() or print "COULD NOT EXECUTE QUERY: " . $DBI::errstr . "\n";;
	my $countRow    = 0;
	while(my $row = $resultFh->fetchrow_arrayref) 
	{
		$countRow++;
		my $id       = ${$row}[0];
		my $ligant   = ${$row}[1];
		my $org      = ${$row}[2];
		#print "ID $id LIGANT $ligant ORG $org\n";
		push(@{$ligantSeen{$ligant}[0]}, $id);
		push(@{$ligantSeen{$ligant}[1]}, $org);
	}
	$resultFh->finish();
	print "\t\tQUERY FOR LIGANTS TOOK " . (time-$queryStart) . "s FOR $countRow ROWS AND " . (keys %ligantSeen) . " LIGANTS\n";



	print "\t\tANALYZING SPECIE SPECIFIC LIGANTS\n";
	my $specificityTime        = time;
	my $ligantCount            = 0;
	my $DoubleligantCount      = 0;
	my $DoubleligantEqualCount = 0;
	my $DoubleligantDiffCount  = 0;
	my $SingleligantCount      = 0;
	my @position;
	my @orgs;
	my @result;

	foreach my $ligant (sort keys %ligantSeen)
	{
		@position = @{$ligantSeen{$ligant}[0]};
		@orgs     = @{$ligantSeen{$ligant}[1]};
		if (@position > 1)
		{
			my $notEqual = 0;
			foreach my $org1 (@orgs)
			{
				foreach my $org2 (@orgs)
				{
					if ( ! ($org1 eq $org2)) { $notEqual = 1; }
				}
			};

			if ($notEqual)
			{
				foreach my $pos (@position) { $result[$pos][0] += 16; };
				$DoubleligantDiffCount++;
				#foreach my $pos (@position) { print "$ligant $pos NOT EQUAL " . join(" ", @orgs) ."\n" };
			}
			else
			{
				foreach my $pos (@position) { $result[$pos][0] += 0; };
				$DoubleligantEqualCount++;
				#foreach my $pos (@position) { print "$ligant $pos EQUAL " . join(" ", @orgs) ."\n" };
				#print "\n";
			};
			$DoubleligantCount++;
		}
		else
		{
			$result[$position[0]][0] += 0;
			$SingleligantCount++;
		}
		#print "$ligant > " . join(",", @position) . "\n";
	}
	print "\t\tANALYZING SPECIE SPECIFIC LIGANTS COMPLETED IN " . (time - $specificityTime) . "s\n";
	print "\t\tSINGLE:$SingleligantCount DOUBE: $DoubleligantCount DOUBLE EQUAL: $DoubleligantEqualCount DOUBLE DIFF: $DoubleligantDiffCount\n";

	my $analizeSim = 1;
	if ($analizeSim)
	{
		print "\t\tANALYZING LIGANTS SIMILARITIES\n";	
		my $similarityTime = time;
		my @ligants        = (sort keys %ligantSeen);

		print "\t\t\tGETTING MATRIX\n";
		my $matrixTime = time;
		my $ligantsSim = &similarity::getSimilaritiesMatrix(@ligants);
		print "\t\t\tMATRIX OBTAINED IN " . (time - $matrixTime) . "s\n";

		if ( ! (@ligants && @{$ligantsSim})) { die "COULD NOT RETRIEVE LIGANTS INFORMATION"; };
		for (my $l = 0; $l < @ligants; $l++)
		{
			my @pos = @{$ligantSeen{$ligants[$l]}[0]};

			if (${$ligantsSim}[$l])
			{
				foreach my $pos (@pos)
				{
					$result[$pos][0] += 32;
					$result[$pos][1]  = ${$ligantsSim}[$l];
				#	print "POS $pos LIGANT " . $ligants[$l] . " HAD MORE THAN 50% SIMILARITY " . $ligantsSim[$l] . " TIMES\n";
				}
			}
		}
		print "\t\tANALYZING LIGANTS SIMILARITIES COMPLETED IN " . (time - $similarityTime) . "\n";
	}

	my $valid    = 0;
	my $notValid = 0;
	my $kc       = 1;

	print "\t\tUPDATING TABLE WITH " . (@result-1) . " RESULTS\n";
	my $updateTime = time;
	for (my $k = (@result-1); $k > 0 ; $k--) # THE ID FROM SQL STARTS ON 1
	{
		if   (( defined $result[$k] ) && ($result[$k][0] > 0)) 
		{
			$notValid++;
		}
		elsif (( defined $result[$k] ) && ($result[$k][0] == 0)) 
		{
			$valid++; 
		}
		else
		{
			die "VALUE FOR $k IS UNDEF";
		};

		my $result = $result[$k][0];
		my $value  = $result[$k][1];
		if ( ! defined $result ) { $result = 0; };
		if ( ! defined $value  ) { $value  = 0; };
		my $updateExtraFh = $ldbhAL->prepare_cached($commandUpdateExtra);
		   $updateExtraFh->execute($value, $result, $k);
		#if   ($result[$k] > 1) { printf "%20s => %02d\t", ${$rows}[$k][$indLig], $result[$k]; if ( ! ($kc++ % 5)) {print "\n"; }; }
	}

	$ldbhAL->commit();
	$ldbhAL->disconnect();
	print "\t\tUPDATING TABLE COMPLETED IN " . (time - $updateTime) . "s\n";

	print "\tLIGANTS ANALYSIS COMPLETED IN " . (time - $ligantsTime) . "s\n";
	print "\tVALID: $valid\tNOT VALID: $notValid\n";
}




1;

