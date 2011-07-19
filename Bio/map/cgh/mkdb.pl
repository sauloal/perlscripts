#!/usr/bin/perl -w
use strict;
use loadconf;

my $setupFile = $ARGV[0];
die "USAGE: $0 <SETUP FILE.XML>" if ( ! $setupFile );
die "SETUPFILE $setupFile DOESNT EXISTS" if ( ! -f $setupFile );
###################################
#PROGRAMS SETUP
###################################
my $html         = 'java -jar /home/saulo/Desktop/blast/cgh/xalan-j_2_7_1/xalan.jar';
my $blast2xml    = "./blast_xml.pl";
my $xmlMerger    = "./mergeXML.pl";
my $xml2csv      = "./genMultivarTable.pl";
my $pca          = "./PCA.pl";
my $pcaR         = "runR ./pca.r ";

###################################
#FOLDERS SETUP
###################################
my $dbFolder      = 'db';
my $fastaFolder   = 'fasta';
my $blastFolder   = 'blast';
my $xmlFolder     = 'xml';
my $finalFolder   = 'out';
my $inExpFolder   = 'query_exp';
my $inFastaFolder = 'query_fasta';
die "FOLDER ", $dbFolder      ," DOESNT EXISTS" if ( ! -d $dbFolder     );
die "FOLDER ", $fastaFolder   ," DOESNT EXISTS" if ( ! -d $fastaFolder  );
die "FOLDER ", $blastFolder   ," DOESNT EXISTS" if ( ! -d $blastFolder  );
die "FOLDER ", $xmlFolder     ," DOESNT EXISTS" if ( ! -d $xmlFolder    );
die "FOLDER ", $finalFolder   ," DOESNT EXISTS" if ( ! -d $finalFolder  );
die "FOLDER ", $inExpFolder   ," DOESNT EXISTS" if ( ! -d $inExpFolder  );
die "FOLDER ", $inFastaFolder ," DOESNT EXISTS" if ( ! -d $inFastaFolder );

###################################
#LOAD SETUP
###################################
my %pref = &loadconf::loadConf($setupFile);
&loadconf::checkNeeds(
	'serious',		'doClean',		'doCleanDb',

	'mkDb',			'mkAlias',
	'blast',

	'mkXml',		'mergeXml',		'convertHtml',	'convertCsv',
	'mkPca',		'mkPcaR'
);

my $serious     = $pref{serious}         || 0;
my $clean       = $pref{doClean}         || 0;
my $cleanDb     = $pref{doCleanDb}       || 0;
my $mkDb        = $pref{mkDb}            || 0;
my $mkAlias     = $pref{mkAlias}         || 0;
my $blast       = $pref{blast}           || 0;
my $mkXml       = $pref{mkXml}           || 0;
my $mergeXml    = $pref{mergeXml}        || 0;
my $convertHtml = $pref{convertHtml}     || 0;
my $convertCsv  = $pref{convertCsv}      || 0;
my $mkPca       = $pref{mkPca}           || 0;
my $mkPcaR      = $pref{mkPcaR}          || 0;



&loadconf::checkNeeds(
	'inFiles'
);
my $inFilesStr = $pref{inFiles} || die "NO INPUT FILES DEFINED";


my $blast_evalue;
my $blast_threads;
my $blast_task;
my $blast_identity;
my $blast_desc;
my $blast_short;
my $blast_alias;
if ( $blast )
{

	&loadconf::checkNeeds(
		'blast.evalue',
		'blast.threads',
		'blast.task',
		'blast.identity',
		'blast.desc',
		'blast.doAlias',

	);

	$blast_short    = $pref{'blast.short'}    || 0;
	$blast_evalue   = $pref{'blast.evalue'}   || 10;
	$blast_task     = $pref{'blast.task'}     || 'blastn';
	$blast_identity = $pref{'blast.identity'} || '50';
	$blast_desc     = $pref{'blast.desc'}     || '';
	$blast_threads  = $pref{'blast.threads'}  || 6;
	$blast_alias    = $pref{'blast.doAlias'}  || 0;
}

my $blast_short_gapOpen;
my $blast_short_gapExtend;
my $blast_short_wordSize;
my $blast_short_penalty;
my $blast_short_reward;
my $blast_short_windowSize;
my $blast_short_minRawGapScore;
my $blast_short_xDrop;
if ( $blast_short )
{
	&loadconf::checkNeeds(
		'blast.short.gapOpen',
		'blast.short.gapExtend',
		'blast.short.wordSize',
		'blast.short.penalty',
		'blast.short.reward',
		'blast.short.windowSize',
		'blast.short.minRawGapScore',
		'blast.short.xDrop'
	);

	$blast_short_gapOpen        = $pref{'blast.short.gapOpen'}        ||  2;
	$blast_short_gapExtend      = $pref{'blast.short.gapExtend'}      ||  2;
	$blast_short_wordSize       = $pref{'blast.short.wordSize'}       ||  4;
	$blast_short_penalty        = $pref{'blast.short.penalty'}        || -3;
	$blast_short_reward         = $pref{'blast.short.reward'}         ||  2;
	$blast_short_windowSize     = $pref{'blast.short.windowSize'}     ||  4;
	$blast_short_minRawGapScore = $pref{'blast.short.minRawGapScore'} || 10;
	$blast_short_xDrop          = $pref{'blast.short.xDrop'}          || 10;
	$blast_desc                .=	" GAPOPEN "           . $blast_short_gapOpen        .
									" GAPEXTEND "         . $blast_short_gapExtend      .
									" WORDSIZE "          . $blast_short_wordSize       .
									" PENALTY "           . $blast_short_penalty        .
									" REWARD "            . $blast_short_reward         .
									" WINDOWSIZE "        . $blast_short_windowSize     .
									" MINRAWGAPPEDSCORE " . $blast_short_minRawGapScore .
									" XDROPGAP "          . $blast_short_xDrop          .
									" NOGREEDY";
}

my $expression;
if ( $mergeXml )
{
	&loadconf::checkNeeds('expression');
	$expression  = $pref{expression}    || die "NO EXPRESSION FILE DEFINED";
	die "EXPRESSION FILE $inExpFolder/$expression DOESNT EXISTS" if ( ! -f "$inExpFolder/$expression" );
}

my $pcaPar = '';
if ( $mkPca )
{
	foreach my $key (keys %pref)
	{
		$pcaPar .= $pref{$key} if (index($key, "pcaPar.") != -1);
	}
}





###################################
#CHECK SETUP
###################################
my @inFiles;
for my $file (split(",",$inFilesStr))
{
	die "INPUT FASTA FILE $inFastaFolder/$file.fasta DOESNT EXISTS" if ( ! -f "$inFastaFolder/$file.fasta" );
	push(@inFiles, $file);
}


my @db;
my @alias;
foreach my $key (keys %pref)
{
	if ($key =~ /^(\S+)\.\1(\d+)\.(\S+)/)
	{
		my $prefix = $1;
		my $count  = $2;
		my $type   = $3;
		if ($prefix eq 'db')
		{
			$db[$2]{$3} = $pref{$key};
		}
		elsif ($prefix eq 'alias')
		{
			$alias[$2]{$3} = $pref{$key};
		}
	}
}

die "NO INPUT DATABASE INSERTED" if ( ! @db );


for ( my $d = 0; $d < @db; $d++ )
{
	my $nfo       = $db[$d];
	my $inFasta   = $nfo->{fileName} || die "FILE NAME NOT INFORMED FOR DB";
	my $inDbName  = $nfo->{dbName}   || die "DB NAME   NOT INFORMED FOR DB";
	my $inDbTitle = $nfo->{title}    || die "DB TITLE  NOT INFORMED FOR DB";
	my $inDbTaxId = $nfo->{taxId}    || die "TAX ID    NOT INFORMED FOR DB";

	die "INPUT DB FILE $fastaFolder/$inFasta DOESTN EXISTS" if ( ! -f "$fastaFolder/$inFasta" );
}










###################################
#LOGIC
###################################

foreach my $inFile ( @inFiles )
{
	if ( $clean )
	{
		&clean($inFile);
		$clean = 2;
		if ( $cleanDb == 1)
		{
			$cleanDb = 2;
		}
	}


	if ( $mkDb == 1)
	{
		print "MAKING DB\n";
		for ( my $d = 0; $d < @db; $d++ )
		{
			my $nfo       = $db[$d];
			my $inFasta   = $nfo->{fileName} || die "NO FILE NAME INFORMED FOR DB";
			my $inDbName  = $nfo->{dbName}   || die "NO DB NAME   INFORMED FOR DB";
			my $inDbTitle = $nfo->{title}    || die "NO DB TITLE  INFORMED FOR DB";
			my $inDbTaxId = $nfo->{taxId}    || die "NO TAX ID    INFORMED FOR DB";

			&mkdb($inFasta, $inDbName, $inDbTitle, $inDbTaxId);
		}

		$mkDb = 2;
	}

	if ( $mkAlias == 1)
	{
		print "MAKING ALIAS\n";
		for ( my $a = 0; $a < @alias; $a++ )
		{
			my $nfo        = $alias[$a];
			my $inDbs      = $nfo->[0] || die "NO INPUT DBS INFORMED FOR ALIAS";
			my $outDbName  = $nfo->[1] || die "NO DB NAME   INFORMED FOR ALIAS";
			my $outDbTitle = $nfo->[2] || die "NO DB TITLE  INFORMED FOR ALIAS";
			&mkalias($inDbs, $outDbName, $outDbTitle);
		}
		$mkAlias = 2;
	}


	if ( $blast )
	{
		foreach my $db (@db)
		{
			my $dbName = $db->{dbName};
			&blast($inFastaFolder, $inFile, $dbName);
		}
	}

	if ( $blast_alias )
	{
		foreach my $alias (@alias)
		{
			my $dbName = $alias->{dbName};
			&blast($inFastaFolder, $inFile, $dbName);
		}
	}

	if ( $mkXml )
	{
		foreach my $db (@db)
		{
			my $dbName = $db->{dbName};
			&convXml($inFile, $dbName);
		}

		foreach my $alias (@alias)
		{
			my $dbName = $alias->{dbName};
			&convXml($inFile, $dbName);
		}
	}


	if ( $mergeXml )
	{
		print "MERGING XML FROM FOLDER $xmlFolder TO FOLDER $finalFolder INFILE $inFile\n";
		my $COMMAND = "$xmlMerger $xmlFolder $finalFolder $inFile";
		print "\t$COMMAND\n";

		if ( $serious )
		{
			print `$COMMAND`;
		}
	}


	if ( $convertHtml )
	{
		my $INTX="$finalFolder/$inFile\_blast_merged_blast_all_gene";
		print "CONVERTING XML $INTX.xml TO HTML\n";
		my $COMMAND = "$html -IN $INTX.xml -OUT $INTX.html";
		print "\t$COMMAND\n";

		if ( $serious )
		{
			die "FILE $INTX.xml DOESNT EXISTS" if ( ! -f "$INTX.xml" );
			print `$COMMAND`;
		}

		my $INTY = "$finalFolder/$inFile\_blast_merged_blast_all_org";
		print "CONVERTING XML $INTY.xml TO HTML\n";
		$COMMAND = "$html -IN $INTY.xml -OUT $INTY.html";
		print "\t$COMMAND\n";

		if ( $serious )
		{
			die "FILE $INTY.xml DOESNT EXISTS" if ( ! -f "$INTY.xml" );
			print `$COMMAND`;
		}
	}


	if ( $convertCsv )
	{
		my $INTX="$finalFolder/$inFile\_blast_merged_blast_all_gene.xml";
		print "CONVERTING XML $INTX TO CSV USING $inExpFolder/$expression\n";
		my $COMMAND = "$xml2csv $INTX $inExpFolder/$expression";
		print "\t$COMMAND\n";

		if ( $serious )
		{

			die "FILE $INTX DOESNT EXISTS" if ( ! -f $INTX );
			die "FILE $inExpFolder/$expression DOESNT EXISTS" if ( ! -f "$inExpFolder/$expression" );
			print `$COMMAND`;

		}
	}


	if ( $mkPca )
	{
		my $INTX = "$finalFolder/$inFile\_blast_merged_blast_all_gene.xml.EXP.$expression.csv";
		print "RUNNING PCA ON CSV $INTX USING PARAMETERS :: $pcaPar\n";
		my $COMMAND = "$pca $INTX $pcaPar";
		print "\t$COMMAND\n";

		if ( $serious )
		{
			die "FILE $INTX DOESNT EXISTS" if ( ! -f $INTX );
			print `$COMMAND`;
		}

		if ( $mkPcaR )
		{
			my $INTR="$INTX\_PCA_00_raw.txt";
			print "RUNNING PCA R ON CSV $INTR\n";
			my $COMMANDR = "$pcaR $INTR";
			print "\t$COMMANDR\n";

			if ( $serious )
			{
				die "FILE $INTR DOESNT EXISTS" if ( ! -f $INTR );
				print `$COMMANDR`;
			}
		}
	}
}












###################################
#FUNCTIONS
###################################


sub mkdb {
	my $inFasta = $_[0];
    my $outName = $_[1];
    my $title   = $_[2];
	my $taxId   = $_[3];

	print "CREATING BLAST DB FOR $fastaFolder/$inFasta WITH NAME $outName TITLE $title TAXID $taxId\n";
	my $COMMAND = "makeblastdb -in $fastaFolder/$inFasta -dbtype nucl -title \"$title\" -out $dbFolder/$outName -taxid $taxId -logfile $fastaFolder/$inFasta.log";
	print "\t$COMMAND\n";

	if ( $serious )
	{
		die "FILE $fastaFolder/$inFasta DOESNT EXISTS" if ( ! -f "$fastaFolder/$inFasta" );
		print `$COMMAND`;
	}

	print "\n";
}

sub mkalias {
	my $inDb  = $_[0];
	my $outDb = $_[1];
	my $title = $_[2];

	print "CREATING BLAST DB ALIAS FOR $inDb AS $outDb TITLED $title\n";
	my $COMMAND = "blastdb_aliastool -dblist \"$inDb\" -dbtype nucl -out $dbFolder/$outDb -title \"$title\" -logFILE $outDb.log";
	print "\t$COMMAND\n";

	if ( $serious )
	{
		print `$COMMAND`;
	}

	print "\n";
}

sub blast {
	my $inFolder = $_[0];
	my $inFile   = $_[1];
	my $Db       = $_[2];

	my $outFile  = "$inFile\_$Db.blast";
	my $outBlast = "$blastFolder/$outFile";

	print "BLASTING $inFolder/$inFile AGAINST $Db EVALUE $blast_evalue THREAD $blast_threads TASKS $blast_task IDENTITY $blast_identity OUT $outBlast\n";
	my $COMMAND = "blastn -task $blast_task -db $dbFolder/$Db -query $inFolder/$inFile.fasta -out $outBlast  -evalue $blast_evalue -num_threads $blast_threads -perc_identity $blast_identity";

	if ( $blast_short )
	{
		$COMMAND .= " -gapopen $blast_short_gapOpen -gapextend $blast_short_gapExtend -word_size $blast_short_wordSize -penalty $blast_short_penalty -reward $blast_short_reward -window_size $blast_short_windowSize -min_raw_gapped_score $blast_short_minRawGapScore -xdrop_gap $blast_short_xDrop -no_greedy ";
	}

	#blastn         -task blastn -db db/cgR265        -query 59dup.fasta    -out 59dup_cgR265_id40_long.blast -evalue 100      -num_threads 3        -perc_identity 50 -gapopen 2 -gapextend 2 -word_size 7 -penalty -2 -reward 2
	#blastn         -task blastn -db db/cgR265        -query 59dup.fasta    -out 59dup_cgR265_id40_long.blast -evalue 10       -num_threads 3        -perc_identity 50 -gapopen 2 -gapextend 2 -word_size 4 -penalty -3 -reward 2  -no_greedy -window_size 4 -min_raw_gapped_score 20 -xdrop_gap 50
	print "\t$COMMAND\n";

	if ( $serious )
	{
		die "FILE $inFolder/$inFile.fasta DOESNT EXISTS" if ( ! -f "$inFolder/$inFile.fasta" );
		print `$COMMAND`;
	}

	print "\n";
}



sub convXml {
	my $inFile  = $_[0];
	my $db      = $_[1];
	my $outFile ="$inFile\_$db.blast";

	return 0 if ( ! -f $outFile );

	print "CONVERTING $inFile DATABASE $db FROM $outFile FILE TO XML\n";

	my $COMMAND = "$blast2xml $blastFolder  $outFile \"$blast_desc\"";
	print "\t$COMMAND\n";

	if ( $serious )
	{
		die "FILE $blastFolder/$outFile DOESNT EXISTS" if ( ! -f "$blastFolder/$outFile" );
		print `$COMMAND`;
	}

	print "\n";
}




sub clean {
	my $inFile = $_[0];
	print "CLEANING THE MESS OF $inFile\n";

	if ( $cleanDb == 1)
	{
		unlink("$dbFolder/*");
		unlink("$fastaFolder/*.log");
	}

	if ( $clean == 1)
	{
		unlink("$blastFolder/$inFile*");
		unlink("$xmlFolder/$inFile*");
		unlink("$finalFolder/$inFile*");
	}

	print "\n";
}

1;
