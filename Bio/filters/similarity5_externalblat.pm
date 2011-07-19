#!/usr/bin/perl
# Saulo Aflitos
# 2009 09 15 16 07
#TODO: Transform files query in array and split it for multithreading
#
use strict;
use warnings;

package similarity5_externalblat;
#use DBI;
use threads;
use threads::shared;
use threads 'exit'=>'threads_only';

use lib "./";
use dnaCode;
use DBIconnect;

my %pref;
my %vars;
my $DName;

##########
## SIMILARITY 5 - EXTERNAL BLAST
##########
sub sthAnalizeSimilarity5
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

	print "_"x2, "$DName :: STARTING SIMILARITY ANALYSIS 5\n";
	print "_"x4, "$DName :: RETRIEVING RESULT\n";
	print "_"x6, "$DName :: GET ALL $commandGetAll\n";

	unlink("$vars{blatFolder}/*.fa");
	unlink("$vars{blatFolder}/*.psl");
	unlink("$vars{blatFolder}/*.lst");

	#my $dbh5 = DBI->connect("DBI:mysql:$vars{database}", $vars{user}, $vars{pw}, {RaiseError=>1, PrintError=>1, AutoCommit=>0}) or die "COULD NOT CONNECT TO DATABASE $vars{database} $vars{user}: $! $DBI::errstr";
	my $dbh5 = &DBIconnect::DBIconnect();
	my $startTime = time;

	#my @listLigV;
	#my @listM13V;
	#my @listSeqV;
	#my @listLigaV;

	#my @listLigA;
	#my @listM13A;
	#my @listSeqA;
	#my @listLigaA;

	#my @H_filterColums;
	#foreach my $key (sort keys %{$vars{H_filterColums}})
	#{
	#	push (@H_filterColums, $key);
	#}

	my %lists;

	#TODO: SOFTCODE
	my $columnIndexId     = $vars{H_oldColumnIndex}{$vars{primaryKey}};

	my $countRow  = 0;
	my $fileCount = 1;

	my @files;


	my $retT = time;
	print "_"x6, "$DName :: RETRIEVING VALID RESULTS\n";
	my $sth5V = $dbh5->prepare($commandGetValid);
	$sth5V->execute();
	my $rowsV = $sth5V->rows;

	print "_"x6, "$DName :: ",$rowsV, " VALID RESULTS RETRIEVED SUCCESSIFULLY IN " , (time - $retT) , "s\n";

	my $row;
	my $rowNum;


	my $part      = 0;
	my $splitBlat = 1_000_000;
	my $parts     = int($rowsV / $splitBlat) + 1;
	

	my $countKey = scalar @{$columns};
	#foreach my $key (sort keys %{$vars{H_filterColums}})
	

	for (my $part = 0; $part < $parts; $part++)
	{
		foreach my $key (@{$columns})
		{
			my $index = $vars{H_filterColums}{$key};
			$files[$index][$part][0] = "$vars{blatFolder}/Q_query_"  . $key . ".$part.fa";
			$files[$index][$part][1] = "$vars{blatFolder}/Q_db_"     . $key . ".fa";
			$files[$index][$part][2] = "$vars{blatFolder}/Q_result_" . $key . ".$part.fa";
			$files[$index][$part][3] = 0;   # MAX SIZE
			$files[$index][$part][4] = 300; # MIN SIZE
			print "_"x8, "$DName :: SETTING FILES Q: ", $files[$index][$part][0], "\tD: ", $files[$index][$part][1], "  \tR: ", $files[$index][$part][2],"\n";
		}
	}

	my @fhs;
	for (my $f = 0; $f < @files; $f++)
	{
		next if ( ! defined $files[$f] );
		my $d_file = $files[$f][0][1];
		for (my $p = 0; $p < @{$files[$f]}; $p++)
		{
			next if ( ! defined $files[$f][$p] );
			my $q_file = $files[$f][$p][0];
	
			open  my $q_fh, ">$q_file" or die "COULD NOT OPEN $q_file: $!";
			$fhs[$f][$p][0] = $q_fh;
		}
			open  my $d_fh, ">$d_file" or die "COULD NOT OPEN $d_file: $!";
			$fhs[$f][0][1] = $d_fh;
	}




	my $fragment = 0;
	while($row = $sth5V->fetchrow_arrayref) 
	{
		$countRow++;
		die if ( ! defined $row );

		print "_"x8, "$DName :: EXPORTING VALID ROW # $countRow FRAG $fragment\n" if ( ! ($countRow % (int($rowsV / 5))));
		$rowNum = $row->[$columnIndexId];
		die if ( ! defined $rowNum );

		#for (my $k = 0; $k < @H_filterColums; $k++)
		for (my $k = 0; $k < @{$columns}; $k++)
		{
			#my $key = $H_filterColums[$k];
			my $key = $columns->[$k];

			my $index  = $vars{H_filterColums}{$key};
			my $seq    = $row->[$index];

			die "SEQUENCE OF LENGTH 0 FOUND " if (length($seq) == 0);

			my $transSeq      = &dnaCode::digit2dna($seq);
			my $leng          = length($seq);
			$files[$index][0][3] = $leng if (( ! defined $files[$index][0][3]) || ($leng > $files[$index][0][3])); #MAX SIZE
			$files[$index][0][4] = $leng if (( ! defined $files[$index][0][4]) || ($leng < $files[$index][0][4])); #MIN SIZE
			print { $fhs[$index][$fragment][0] } ">", $rowNum , "|" , $rowNum , "_" , $rowNum , "\n" , $transSeq, "\n\n";
		}
		$fragment++ if ( ! ($countRow % $splitBlat));
		$fileCount++;
	}

	if ( ! $fileCount ) { die "NO SEQUENCES TO BLAT"; };

	$sth5V->finish();
	$sth5V = undef;

	print "_"x6, "$DName :: ",$rowsV, " VALID DB RESULTS EXPORTED SUCCESSIFULLY IN " , (time - $retT) , "s IN $fragment FRAGMENTS\n\n";






	$retT = time;
	print "_"x6, "$DName :: RETRIEVING ALL RESULTS\n";
	my $sth5A = $dbh5->prepare($commandGetAll);
	$sth5A->execute();
	my $rowsA = $sth5A->rows;

	print "_"x6, "$DName :: ",$rowsA, " ALL RESULTS RETRIEVED SUCCESSIFULLY IN " , (time - $retT) , "s\n";

	$countRow = 0;
	$rowNum   = 0;
	$row      = undef;

	while($row = $sth5A->fetchrow_arrayref) 
	{
		$countRow++;
		print "_"x8, "$DName :: EXPORTING ALL ROW # $countRow\n" if ( ! ($countRow % (int($rowsA / 5))));
		$rowNum = $row->[$columnIndexId];
		die if ( ! defined $rowNum );
		die if ( ! defined $row );

		#for (my $k = 0; $k < @H_filterColums; $k++)
		for (my $k = 0; $k < @{$columns}; $k++)
		{
			#my $key = $H_filterColums[$k];
			my $key = $columns->[$k];

			#TODO: DONT SKIP THIS WAY
			#next if $key eq "sequenceLig";
			#next if $key eq "sequenceM13";

			my $index  = $vars{H_filterColums}{$key};
			my $seq    = $row->[$index];

			die "SEQUENCE OF LENGTH 0 FOUND " if (length($seq) == 0);

			my $transSeq = &dnaCode::digit2dna($seq);
			my $leng     = length($seq);

			my $comp = "";
			if ($leng < $files[$index][0][3])
			{
				$comp = "N" x ($files[$index][0][3] - $leng + 1);
			};
			#while ( $leng < $files[$index][3] ) { $seq .= "N"; };

			print { $fhs[$index][0][1] } ">", $rowNum , "|" , $rowNum , "_" , $rowNum , "\n" , $transSeq, $comp, "\n\n";
		}
		$fileCount++;
	}
	$sth5A->finish();
	$sth5A = undef;

	print "_"x6, "$DName :: ",$rowsA, " ALL DB RESULTS EXPORTED SUCCESSIFULLY IN " , (time - $retT) , "s\n";

	$dbh5->commit();
	$dbh5->disconnect();





	for (my $fh = 0; $fh < @fhs; $fh++)
	{
		for (my $part = 0; $part < $parts; $part++)
		{
			close $fhs[$fh][$part][0] or die "COULD NOT CLOSE FILEHANDLE";
		}
		close $fhs[$fh][0][1] or die "COULD NOT CLOSE FILEHANDLE";
	}




	print "_"x4, "$DName :: DATA GATHERED TO SIMILARITY ANALYSIS 5: ", (int((time - $startTime)+.5)), "s\n";
	my $threadCount = 1;
	for (my $t = 0; $t < @files; $t++)
	{
		for (my $part = 0; $part < $parts; $part++)
		{
			my $arr = $files[$t][$part];
			next if ( ! $arr );
			
			while (threads->list(threads::running) > ($vars{maxThreads}-1))
			{
				sleep($vars{napTime}); 
			}
	
			foreach my $thr (threads->list(threads::joinable))
			{
				$thr->join();
			}
	
			print "_"x6, "$DName :: STARTING SIMILARITY ANALYSIS 5 : THREAD ", $threadCount, " / ", ((scalar @files) * $parts) ,"\n";
			#####################
			threads->new(\&analizeSimilarity5, ($commandUpdate, $arr));
			#####################
			$threadCount++;
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

	unlink("$vars{blatFolder}/*.fa");
	unlink("$vars{blatFolder}/*.psl");
	unlink("$vars{blatFolder}/*.lst");

	print "_"x2, "$DName :: SIMILARITY ANALYSIS 5 COMPLETED IN ",(int((time - $startTime)+.5)), "s\n\n\n";
}

sub analizeSimilarity5
{
	my $commandUpdate = $_[0];
	my @files         = @{$_[1]};
	my $Gresult       = [];

	my $startTime = time;

#	for (my $f = 0; $f < @files; $f++)
#	{
		my $queryFile  = $files[0];
		my $dbFile     = $files[1];
		my $resultFile = $files[2];
		my $maxSize    = $files[3];
		my $minSize    = $files[4];

		my $retT = time;
		print "_"x6, "$DName :: RUNNING BLAT : $queryFile\n";
		#blat/filterpsl.sh blat blat/Q_db_ligant.fa blat/Q_query_ligant.fa blat/Q_result_ligant.fa 8 50 70
		#FOLDER=$1
		#DATABASE=$2
		#QUERY=$3
		#OUTPUT=$4
		#MINSIZE=$5
		#MINID=$6
		#MINSIM=$7
		################
		my $blatCMD = "$vars{blatFolder}/filterpsl.sh $vars{blatFolder} $dbFile $queryFile $resultFile $minSize $vars{blat_min_identity} $vars{blat_min_similarity} 0";
		print "_"x6, $blatCMD, "\n";
		
		#print `$blatCMD`;
		
		open(ACTUATOR, "$blatCMD 2>&1|") or die "FAILED TO EXECUTE EXTERNAL BLAT: $!";
		while ( my $line = <ACTUATOR> )
		{
			print $line;
		}
		close ACTUATOR;
		
		################
		print "_"x6, "$DName :: BLAT RUNNED IN " . (time - $retT) . "\n";



		$retT = time;
		print "_"x6, "$DName :: LOADING BLAT RESULT\n";

		my $resultFileFinal = `ls $resultFile\_*\_filtered_threshold_neg.lst 2>/dev/null`;
		chomp $resultFileFinal;

		if ( -f $resultFileFinal )
		{
			open RESULT, "<$resultFileFinal" or die "COULD NOT OPEN RESULT FILE $resultFileFinal: $!";
			while (my $line = <RESULT>)
			{
				chomp $line;
				$Gresult->[$line] = 1;
			}
			close RESULT;
		}
		else
		{
			die "COULD NOT RETRIEVE BLAT OUTPUT: $resultFile > $resultFileFinal";
		}
		print "_"x6, "$DName :: BLAT RESULT LOADED IN " . (time - $retT) . "\n";

	#} #for my $f





	my $h = 0;
	for (my $g = 0; $g <@{$Gresult}; $g++)
	{
		if (defined $Gresult->[$g]) { $h++ }
	}
	print "$DName :: AFTER BLAT : $h INVALIDS\n";

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
	#my $ldbh5 = DBI->connect("DBI:mysql:$vars{database}", $vars{user}, $vars{pw}, {RaiseError=>1, PrintError=>1, AutoCommit=>0}) or die "COULD NOT CONNECT TO DATABASE $vars{database} $vars{user}: $! $DBI::errstr";
	my $ldbh5 = &DBIconnect::DBIconnect();
	
	my $countResults = 0;
	for (my $r = 0; $r < @{$Gresult}; $r++)
	{
		if (defined $Gresult->[$r])
		{
			#print join("\t", @{$result}) . "\n";
			my $updateFirstFh = $ldbh5->prepare_cached($commandUpdate);
			   $updateFirstFh->execute($Gresult->[$r], $r);
			   $updateFirstFh->finish();
			$countResults++;
		}
	}
	$ldbh5->commit();
	$ldbh5->disconnect();

	print "_"x4, "$DName :: UPDATE QUERY TIME : " , (time-$queryStart) , "s FOR ",$countResults," QUERIES\n";
	print "_"x4, "$DName :: TOTAL TIME : ", (int((time - $startTime)+.5)), "s\n";

	return undef;
}





sub sthAnalizeSimilarity5_old
{
	my $name            = $_[0];
	my $displayName     = $_[1];
	my $commandGetValid = $_[2];
	my $commandUpdate   = $_[3];
	my $commandGetAll   = $_[4];

	print "_"x2, "$DName :: STARTING SIMILARITY ANALYSIS 5\n";
	print "_"x4, "$DName :: RETRIEVING RESULT\n";

	#my $dbh5 = DBI->connect("DBI:mysql:$vars{database}", $vars{user}, $vars{pw}, {RaiseError=>1, PrintError=>1, AutoCommit=>0}) or die "COULD NOT CONNECT TO DATABASE $vars{database} $vars{user}: $! $DBI::errstr";
	my $dbh5 = &DBIconnect::DBIconnect();

	my $startTime = time;

	my @listLigV;
	my @listM13V;
	my @listSeqV;
	my @listLigaV;

	my @listLigA;
	my @listM13A;
	my @listSeqA;
	my @listLigaA;

	my $sth5V = $dbh5->prepare($commandGetValid);
	$sth5V->execute();
	my $rowsV = $sth5V->rows;
	print "_"x6, "$DName :: ",$rowsV, " VALID RESULTS RETRIEVED SUCCESSIFULLY\n";

	my $columnIndexSeq    = $vars{H_oldColumnIndex}{"sequence"};
	my $columnIndexLigant = $vars{H_oldColumnIndex}{"ligant"};
	my $columnIndexId     = $vars{H_oldColumnIndex}{$vars{primaryKey}};
	

	my $countRow  = 0;
	while(my $row = $sth5V->fetchrow_arrayref) 
	{
		$countRow++;
		print "_"x4, "$DName :: ACQUIRING VALID ROW # $countRow\n" if ( ! ($countRow % (int($rowsV / 5))));

		my $seqSeq  = $row->[$columnIndexSeq];
		my $seqLiga = $row->[$columnIndexLigant];
		my $rowNum  = $row->[$columnIndexId];

		#$listLigV[$rowNum]  = $seqLig;
		#$listM13V[$rowNum]  = $seqM13;
		$listSeqV[$rowNum]  = $seqSeq;
		$listLigaV[$rowNum] = $seqLiga;
	}
	$sth5V->finish();


	my $sth5A = $dbh5->prepare($commandGetAll);
	$sth5A->execute();
	my $rowsA = $sth5A->rows;
	print "_"x6, "$DName :: ",$rowsA, " ALL RESULTS RETRIEVED SUCCESSIFULLY\n";

	$countRow  = 0;
	while(my $row = $sth5A->fetchrow_arrayref) 
	{
		$countRow++;
		print "_"x4, "$DName :: ACQUIRING ALL ROW # $countRow\n" if ( ! ($countRow % (int($rowsA / 5))));

		#my $org     = $row[$vars{H_oldColumnIndex}{"idOrganism"}];
		my $seqSeq  = $row->[$columnIndexSeq];
		my $seqLiga = $row->[$columnIndexLigant];
		my $rowNum  = $row->[$columnIndexId];

		#$listLigA[$rowNum]  = $seqLig;
		#$listM13A[$rowNum]  = $seqM13;
		$listSeqA[$rowNum]  = $seqSeq;
		$listLigaA[$rowNum] = $seqLiga;
	}
	$sth5A->finish();

	$dbh5->commit();
	$dbh5->disconnect();


	print "_"x4, "$DName :: DATA GATHERED TO SIMILARITY ANALYSIS 5: ", (int((time - $startTime)+.5)), "s\n";
	#####################
	&analizeSimilarity5($commandUpdate, \@listSeqV, \@listSeqA, \@listLigaV, \@listLigaA);
	#####################
	print "_"x2, "$DName :: SIMILARITY ANALYSIS 5 COMPLETED\n\n\n";
}

sub analizeSimilarity5_old
{
	my $commandUpdate = $_[0];

	my $Gresult  = [];

	my $startTime = time;

	for (my $r = 1; $r < @_; $r +=2)
	{
		my $arrayV  = $_[$r];

		my $fileCount = 1;

		#$vars{blatFolder} = "blat";
		my $queryFile  = "$vars{blatFolder}/$r\_query.fa";
		my $dbFile     = "$vars{blatFolder}/$r\_db.fa";
		my $resultFile = "$vars{blatFolder}/$r\_result";
#			if(1){
		open  QUERY, ">$queryFile" 
            or die "COULD NOT OPEN $queryFile: $!";
		my $maxSize = 0;
		my $minSize = 300;
		for (my $a = 0; $a < @$arrayV; $a++)
		{
			next if ( ! defined $arrayV->[$a]);
			my $seq   = &dnaCode::digit2dna($arrayV->[$a]);

			die "SEQUENCE OF LENGTH 0 FOUND " if (length($seq) == 0);
			$maxSize  = length($seq) if (length($seq) > $maxSize);
			$minSize  = length($seq) if (length($seq) < $minSize);

			my $query = ">". $a . "|" . $a . "_" . $a . "\n" . $seq . "\n\n";

			print QUERY $query;

			$fileCount++;
		}
		close QUERY;

		if ( ! $fileCount ) { die "NO SEQUENCES TO BLAT"; };

		open  DB, ">$dbFile" or die "COULD NOT OPEN $dbFile: $!";
		my $arrayA  = $_[$r+1];
		for (my $a = 0; $a < @$arrayA; $a++)
		{
			next if ( ! defined $arrayA->[$a]);
			my $seq = &dnaCode::digit2dna($arrayA->[$a]);
			while (length($seq) < $maxSize) { $seq .= "N" };
			print DB ">", $a , "|" , $a , "_" , $a , "\n" , $seq , "\n\n";
		}
		close DB;
#			} #end if 0


		print "_"x6, "$DName :: RUNNING BLAT\n";
		#blat/filterpsl.sh blat blat/3_db.fa blat/3_query.fa blat/3_result 20
		################
		my $blatCMD = "$vars{blatFolder}/filterpsl.sh $vars{blatFolder} $dbFile $queryFile $resultFile $minSize 50 70";
		print "_"x6, $blatCMD, "\n";
		print `$blatCMD`;
		################
		print "_"x6, "$DName :: BLAT RUNNED\n";

		print "_"x6, "$DName :: LOADING BLAT RESULT\n";

		my $resultFileFinal = `ls $resultFile\_*\_filtered_threshold_neg.lst 2>/dev/null`;
		chomp $resultFileFinal;

		if ( -f $resultFileFinal )
		{
			open RESULT, "<$resultFileFinal" or die "COULD NOT OPEN RESULT FILE $resultFileFinal: $!";
			while (my $line = <RESULT>)
			{
				chomp $line;
				$Gresult->[$line] = 1;
			}
			close RESULT;
		}
		else
		{
			die "COULD NOT RETRIEVE BLAT OUTPUT: $resultFileFinal";
		}
		print "_"x6, "$DName :: BLAT RESULT LOADED\n";

	} #for my $r



	my $h = 0;
	for (my $g = 0; $g <@{$Gresult}; $g++)
	{
		if (defined $Gresult->[$g]) { $h++ }
	}
	print "$DName :: AFTER BLAT : $h INVALIDS\n";

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
	#my $ldbh5 = DBI->connect("DBI:mysql:$vars{database}", $vars{user}, $vars{pw}, {RaiseError=>1, PrintError=>1, AutoCommit=>0}) or die "COULD NOT CONNECT TO DATABASE $vars{database} $vars{user}: $! $DBI::errstr";
	my $ldbh5 = &DBIconnect::DBIconnect();
	
	my $countResults = 0;
	for (my $r = 0; $r < @{$Gresult}; $r++)
	{
		if (defined $Gresult->[$r])
		{
			#print join("\t", @{$result}) . "\n";
			my $updateFirstFh = $ldbh5->prepare_cached($commandUpdate);
			   $updateFirstFh->execute($Gresult->[$r], $r);
			   $updateFirstFh->finish();
			$countResults++;
		}
	}
	$ldbh5->commit();
	$ldbh5->disconnect();

	print "_"x4, "$DName :: UPDATE QUERY TIME : " , (time-$queryStart) , "s FOR ",$countResults," QUERIES\n";
	print "_"x4, "$DName :: TOTAL TIME : ", (int((time - $startTime)+.5)), "s\n";

	return undef;
}

1;
