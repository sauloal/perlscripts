#!/usr/bin/perl
# Saulo Aflitos
# 2009 09 15 16 07
#
use strict;
use warnings;

package similarity8_externalBlatInput;
#use DBI;
use threads;
use threads::shared;
use threads 'exit'=>'threads_only';

use lib "./";
use dnaCode;
use DBIconnect;
use idd2file;

my %pref;
my %vars;
my $DName;

##########
## Similarity 8 - EXTERNAL BLAST
##########
sub sthAnalizeSimilarity8
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

	print "_"x2, "$DName :: STARTING SIMILARITY ANALYSIS 8\n";
	print "_"x4, "$DName :: RETRIEVING RESULT\n";
	print "_"x6, "$DName :: GET ALL \"$commandGetAll\"\n";

	unlink("$vars{blatFolder}/*.fa");
	unlink("$vars{blatFolder}/*.psl");
	unlink("$vars{blatFolder}/*.lst");

	my $dbh5 = &DBIconnect::DBIconnect();
	my $startTime = time;

	my %lists;

	my $columnIndexId     = $vars{H_oldColumnIndex}{$pref{primaryKey}};
	my $columnIndexSppId  = $vars{H_oldColumnIndex}{$pref{originalTableOrganismId}};

	my $countRow  = 0;
	my $fileCount = 1;

	my @files;

	my $retT = time;
	print "_"x6, "$DName :: RETRIEVING RESULTS: \"$commandGetValid\"\n";
	my $sth5V = $dbh5->prepare($commandGetValid);
	$sth5V->execute();
	my $rowsV = $sth5V->rows;

	print "_"x6, "$DName :: ",$rowsV, " VALID RESULTS RETRIEVED SUCCESSIFULLY IN " , (time - $retT) , "s\n";

	my $row;
	my $rowNum;

	my $part      = 0;
	my $splitBlat = 350;
	my $parts     = int($rowsV / $splitBlat) + 1;
	print "_"x6, "$DName :: SPLITTING $rowsV IN $parts PARTS OF $splitBlat UNITS\n";
	
	print "_"x6, "$DName :: GETTING SPECIES FILENAMES\n";
	my $idd2file = &idd2file::idd2file();
	print "_"x6, "$DName :: SPECIES FILENAMES ACQUIRED\n";


	my $countKey = scalar @{$columns};
	die "COUNTKEY == 0" if ($countKey == 0);

	if (0)
	{
		foreach my $key (sort keys %{$idd2file}) 			 { print "\t\tFILES FOUND: $key ", $idd2file->{$key}, "\n"; 			  }
		foreach my $key (@{$columns}) 						 { print "\t\tDESIRED   COLUMN $key INDEX $vars{H_filterColums}{$key}\n"; }
		foreach my $key (sort keys %{$vars{H_filterColums}}) { print "\t\tAVAILABLE COLUMN $key INDEX $vars{H_filterColums}{$key}\n"; }
	}
	
	#TODO: EITHER EXPORT OR LINK THE FASTA ORIGINAL FILES AS DB. OR EXECUTE WITH THEM IN THEIR ORIGINAL PLACE (BETTER)

	my %idd2orgcount;
	my $countIdd = 0;
	foreach my $key (keys %{$idd2file})
	{
		$idd2orgcount{$key} = $countIdd++;
	}

	for (my $part = 0; $part < $parts; $part++)
	{
		foreach my $column (@{$columns})
		{
			foreach my $organismId ( sort keys %{$idd2file} )
			{
				#foreach my $input fastas
				my $organismFile = $idd2file->{$organismId};
				my $organismCount = $idd2orgcount{$organismId};

				my $columnIndex = $vars{H_filterColums}{$column};
				die "INDEX NOT DEFINED" if ( ! defined $columnIndex );
				die "FILE $pref{indir}/$organismFile DOESNT EXISTS" if ( ! -f "$pref{indir}/$organismFile" );

				#column sequence for organism 1 will run all sequences against organism one
				$files[$columnIndex][$part][$organismCount][0] = "$vars{blatFolder}/Q_query_"  . $column . ".$part.$organismId.fa"; # query file
				$files[$columnIndex][$part][$organismCount][1] = "$pref{indir}/"               . $organismFile; 					   # db file
				$files[$columnIndex][$part][$organismCount][2] = "$vars{blatFolder}/Q_result_" . $column . ".$part.$organismId.fa";    #outputfile
				$files[$columnIndex][$part][$organismCount][3] = 0;   # MAX SIZE
				$files[$columnIndex][$part][$organismCount][4] = 300; # MIN SIZE
				$files[$columnIndex][$part][$organismCount][5] = $organismId; # ORGANISMID
				if (1)
				{
					print "_"x8, "$DName :: SETTING FILES Q: ", $files[$columnIndex][$part][$organismCount][0], "\tD: ", $files[$columnIndex][$part][$organismCount][1], "  \tR: ", $files[$columnIndex][$part][$organismCount][2],"\n";
				}
				$organismCount++;
			}
		}
	}

	my @fhs;
	for (my $columnId = 0; $columnId < @files; $columnId++)
	{
		next if ( ! defined $files[$columnId] );
		for (my $part = 0; $part < @{$files[$columnId]}; $part++)
		{
			next if ( ! defined $files[$columnId][$part] );

			for ( my $organismCount = 0; $organismCount < @{$files[$columnId][$part]}; $organismCount++)
			{
				next if ( ! defined $files[$columnId][$part][$organismCount] );
				my $q_file = $files[$columnId][$part][$organismCount][0];
				my $d_file = $files[$columnId][$part][$organismCount][1];
				#CONSIDER TRANSFER TO FILES INSTEAD OF UNING ANOTHER IDENTICAL ARRAY
				open  my $q_fh, ">$q_file" or die "COULD NOT OPEN $q_file: $!";
				$fhs[$columnId][$part][$organismCount] = $q_fh;
			}
		}
			#open  my $d_fh, ">$d_file" or die "COULD NOT OPEN $d_file: $!";
			#$fhs[$p][0][1] = $d_fh;
	}




	my $fragment = 0;
	while($row = $sth5V->fetchrow_arrayref) 
	{
		$countRow++;
		die if ( ! defined $row );

		print "_"x8, "$DName :: EXPORTING VALID ROW # $countRow FRAG $fragment\n" if ( ! ($countRow % (int($rowsV / 5))));
		$rowNum   = $row->[$columnIndexId];
		
		die if ( ! defined $rowNum );

		my $orgId = $row->[$columnIndexSppId];
		if ($orgId =~ /(\d+)\.(\d+)/) {	$orgId = $1; };

		for (my $cIndex = 0; $cIndex < @fhs; $cIndex++)
		{
			next if ( ! defined $fhs[$cIndex] );
			
			foreach my $organismId ( sort keys %{$idd2file} )
			{
				next if ($organismId eq $orgId);
				my $organismCount = $idd2orgcount{$organismId};
	
				my $seq    = $row->[$cIndex];
	
				die "SEQUENCE NULL FOUND "        if ( ! defined $seq );
				die "SEQUENCE OF LENGTH 0 FOUND " if (length($seq) == 0);
				
				#print "EXPORTING TO FILE C: $cIndex P: $fragment Oid: $organismId DBOid: $orgId Oc: $organismCount\n";
	
				my $transSeq      = &dnaCode::digit2dna($seq);
				#my $leng          = length($seq);
				#$files[$cIndex][0][0][3] = $leng if (( ! defined $files[$cIndex][0][0][3]) || ($leng > $files[$cIndex][0][0][3])); #MAX SIZE
				#$files[$cIndex][0][0][4] = $leng if (( ! defined $files[$cIndex][0][0][4]) || ($leng < $files[$cIndex][0][0][4])); #MIN SIZE
				print { $fhs[$cIndex][$fragment][$organismCount] } ">", $rowNum , "|" , $rowNum , "_" , $rowNum , "\n" , $transSeq, "\n\n";
			}
		}
		$fragment++ if ( ! ($countRow % $splitBlat));
		$fileCount++;
	}

	if ( ! $fileCount ) { die "NO SEQUENCES TO BLAT"; };

	$sth5V->finish();
	$sth5V = undef;

	print "_"x6, "$DName :: ",$rowsV, " VALID DB RESULTS EXPORTED SUCCESSIFULLY IN " , (time - $retT) , "s IN $fragment FRAGMENTS\n\n";

	$dbh5->commit();
	$dbh5->disconnect();


	for (my $c = 0; $c < @fhs; $c++)
	{
		next if ( ! defined $fhs[$c]);
		for (my $p = 0; $p < @{$fhs[$c]}; $p++)
		{
			next if ( ! defined $fhs[$c][$p]);
			for (my $o = 0; $o < @{$fhs[$c][$p]}; $o++)
			{
				next if ( ! defined $fhs[$c][$p][$o]);
				close $fhs[$c][$p][$o] or die "COULD NOT CLOSE FILEHANDLE";
			}
		}
	}




	print "_"x4, "$DName :: DATA GATHERED TO SIMILARITY ANALYSIS 5: ", (int((time - $startTime)+.5)), "s\n";
	my $threadCount = 1;
	for (my $c = 0; $c < @files; $c++)
	{
		next if ( ! defined $files[$c] );
		for (my $p = 0; $p < @{$files[$c]}; $p++)
		{
			next if ( ! defined $files[$c][$p] );
			for (my $d = 0; $d < @{$files[$c][$p]}; $d++)
			{
				next if ( ! defined $files[$c][$p][$d] );
				my $arr = $files[$c][$p][$d];
				
				next if ( ! $arr );
				
				if (0)
				{
					print "\t\tRUNNING COLUMN $c PART $p DB $d:\n";
					for (my $key = 0; $key < @{$arr}; $key++ ) { print "\t\t\t#$key > ", $arr->[$key], "\n"; }
				}
				
				while (threads->list(threads::running) > ($vars{maxThreads}-1))
				{
					sleep($vars{napTime}); 
				}
		
				foreach my $chr (threads->list(threads::joinable))
				{
					$chr->join();
				}
		
				print "_"x6, "$DName :: STARTING SIMILARITY ANALYSIS 5 : THREAD ", $threadCount, " / ", ((scalar @files) * $parts) ,"\n";
				#####################
				threads->new(\&analizeSimilarity8, ($commandUpdate, $arr));
				#####################
				$threadCount++;
			}
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

sub analizeSimilarity8
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

		my $parserNoValidate = 1;

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
		my $blatCMD = "$vars{blatFolder}/filterpsl.sh $vars{blatFolder} $dbFile $queryFile $resultFile $minSize $vars{blat_min_identity} $vars{blat_min_similarity} $parserNoValidate";
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
		print "\t\tRESULTFILEFINAL: $resultFileFinal\n";
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
	print "_"x4, "$DName :: UPDATING TABLE WITH: \"$commandUpdate\"\n";

	# 1=not ok null=ok


	my $queryStart = time;
	#my $ldbh5 = DBI->connect("DBI:mysql:$vars{database}", $vars{user}, $vars{pw}, {RaiseError=>1, PrintError=>1, AutoCommit=>0}) or die "COULD NOT CONNECT TO DATABASE $vars{database} $vars{user}: $! $DBI::errstr";
	my $ldbh5 = &DBIconnect::DBIconnect();
	
	my $countResults = 0;
	for (my $r = 0; $r < @{$Gresult}; $r++)
	{
		if (defined $Gresult->[$r])
		{
			#print "INSERTING ", $Gresult->[$r], " FOR SEQUENCE $r\n";
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





























sub sthAnalizeSimilarity8_old
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
	&analizeSimilarity8($commandUpdate, \@listSeqV, \@listSeqA, \@listLigaV, \@listLigaA);
	#####################
	print "_"x2, "$DName :: SIMILARITY ANALYSIS 5 COMPLETED\n\n\n";
}

sub analizeSimilarity8_old
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

