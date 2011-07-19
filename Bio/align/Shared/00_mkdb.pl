#!/usr/bin/perl -w
use strict;
use Cwd;
use FindBin qw($Bin);
use lib "$Bin";
use loadconf;

my $setupFile   = $ARGV[0];
my $inputFolder = $ARGV[1];
my $inFilesStr  = $ARGV[2];

die "USAGE: $0 <SETUP FILE.XML> <INPUT FOLDER> <INPUTFILE.TAB>" if ( !    $setupFile );
die "SETUP FILE $setupFile DOESNT EXISTS"                       if ( ! -f $setupFile );

die "USAGE: $0 <SETUP FILE.XML> <INPUT FOLDER> <INPUTFILE.TAB>" if ( !    $inputFolder );
die "INPUT FOLDER $inputFolder DOESNT EXISTS"                   if ( ! -d $inputFolder );

die "USAGE: $0 <SETUP FILE.XML> <INPUT FOLDER> <INPUTFILE.TAB>" if ( !    $inFilesStr );

my %pref = &loadconf::loadConf($setupFile);

###################################
#PIPELINE SETUP
###################################
die if ! &loadconf::checkNeeds(
	'mkdb.pipeline.serious',	'mkdb.pipeline.mkDb',
	'mkdb.pipeline.blast',		'mkdb.pipeline.xml',
	'mkdb.pipeline.convert',	'mkdb.pipeline.pca'
);


my $serious = $pref{'mkdb.pipeline.serious'};
my $mkDb    = $pref{'mkdb.pipeline.mkDb'   };
my $blast   = $pref{'mkdb.pipeline.blast'  };
my $xml     = $pref{'mkdb.pipeline.xml'    };
my $convert = $pref{'mkdb.pipeline.convert'};
my $pca     = $pref{'mkdb.pipeline.pca'    };


###################################
#CHECK INPUT FILES
###################################
my @inFiles;
for my $file (split(",",$inFilesStr))
{
	die "INPUT FASTA FILE $file DOESNT EXISTS" if ( ! -f "$file" );
	push(@inFiles, $file);
}

die "NO INPUT FILE DEFINED" if ( ! @inFiles );
print "INPUT FILES: ", scalar @inFiles, "\n";

###################################
#LOGIC
###################################

if ( $mkDb    ) { &doMkDb()    };
if ( $blast   ) { &doMkBlast() };
if ( $xml     ) { &doMkXml()   };
if ( $convert ) { &doConvert() };
if ( $pca     ) { &doMkPca()   };



###################################
#CALLERS
###################################

sub doMkDb
{
	print "0"x100, "\n";
	print "MAKING DB\n";
	&doMkDb_doDb();
	print "0"x100, "\n";
}

sub doMkBlast
{
	print "1"x100, "\n";
	print "MAKING BLAST\n";
	&doMkBlast_doBlast();
	print "1"x100, "\n";
}

sub doMkXml
{
	print "2"x100, "\n";
	print "MAKING XML\n";
	die "NEEDS NOT MET" if ! &loadconf::checkNeeds('mkdb.xml.mkXml');
	my $doXml      =  $pref{'mkdb.xml.mkXml'};
	#my $doMergeXml =  $pref{'mkdb.xml.mergeXml'};

	print "21"x50, "\n";
	print "MAKING XML\n";
	&doMkXml_doXml()    if $doXml;
	print "22"x50, "\n";
	#print "MAKING MERGED XML\n";
	#&doMkXml_MergeXml() if $doMergeXml;
	#print "2"x100, "\n";
}

sub doConvert
{
	print "3"x100, "\n";
	print "MAKING CONVERSION\n";
	die if ! &loadconf::checkNeeds('mkdb.convert.doHtml', 'mkdb.convert.doCsv');
	my $doHtml =  $pref{'mkdb.convert.doHtml'};
	my $doCsv  =  $pref{'mkdb.convert.doCsv'};

	print "31"x50, "\n";
	print "CONVERTING TO HTML\n";
	&doConvert_Html() if $doHtml;
	print "32"x50, "\n";
	print "CONVERTING TO CSV\n";
	&doConvert_Csv()  if $doCsv;
	print "3"x100, "\n";
}

sub doMkPca
{
	print "4"x100, "\n";
	print "MAKING PCA\n";
	&doMkPca_doPca();
	print "4"x100, "\n";
}


###################################
#SUB CALLERS
###################################

sub doMkDb_doDb
{
	die if ! &loadconf::checkNeeds('mkdb.MkDb.cleanDb','mkdb.MkDb.cleanFile',
						  'mkdb.MkDb.mkRoot', 'mkdb.MkDb.mkAlias');

	my $cleanDb   = $pref{'mkdb.MkDb.cleanDb'};
	my $cleanFile = $pref{'mkdb.MkDb.cleanFile'};
	my $mkRoot    = $pref{'mkdb.MkDb.mkRoot'};
	my $mkAlias   = $pref{'mkdb.MkDb.mkAlias'};

	my ($db, $alias) = &loadDbAlias();
	die "NO INPUT DATABASE INSERTED" if ( ! @$db );

	my %setup = (
				fastaFolder => $inputFolder . "/" . $pref{'mkdb.MkDb.folders.fastaFolder'},
				dbFolder    => $inputFolder . "/" . $pref{'mkdb.MkDb.folders.dbFolder'}
	);

	foreach my $inFile ( @inFiles )
	{
		&fixFasta($inFile);

		#if ( $cleanFile )
		#{
		#	&clean($inFile);
		#	$cleanFile = 2;
		#	if ( $cleanDb == 1)
		#	{
		#		$cleanDb = 2;
		#	}
		#}

		if ( $mkRoot == 1)
		{
			print "MAKING DB\n";
			for ( my $d = 0; $d < @$db; $d++ )
			{
				my $nfo       = $db->[$d];
				my $inFasta   = $nfo->{fileName} || die "NO FILE NAME INFORMED FOR DB";
				my $inDbName  = $nfo->{dbName}   || die "NO DB NAME   INFORMED FOR DB";
				my $inDbTitle = $nfo->{title}    || die "NO DB TITLE  INFORMED FOR DB";
				my $inDbTaxId = $nfo->{taxId}    || die "NO TAX ID    INFORMED FOR DB";

				&mkdb(\%setup, $inFasta, $inDbName, $inDbTitle, $inDbTaxId);
			}

			$mkDb = 2;
		}

		if ( $mkAlias == 1)
		{
			print "MAKING ALIAS\n";
			for ( my $a = 0; $a < @$alias; $a++ )
			{
				my $nfo        = $alias->[$a];
				my $inDbs      = $nfo->{dbs}    || die "NO INPUT DBS INFORMED FOR ALIAS";
				my $outDbName  = $nfo->{dbName} || die "NO DB NAME   INFORMED FOR ALIAS";
				my $outDbTitle = $nfo->{title}  || die "NO DB TITLE  INFORMED FOR ALIAS";
				&mkalias(\%setup, $inDbs, $outDbName, $outDbTitle);
			}
			$mkAlias = 2;
		}
	}
}

sub doMkBlast_doBlast
{
	print "11"x25, "\n";
	print "  RUNNING BLAST\n";

	die if ! &loadconf::checkNeeds('mkdb.blast.blastRoot', 'mkdb.blast.blastAlias');
	my $blastRoot  = $pref{'mkdb.blast.blastRoot'};
	my $blastAlias = $pref{'mkdb.blast.blastAlias'};
	my $setup      = &loadBlastSetup();

	my ($db, $alias) = &loadDbAlias();
	die "NO INPUT DATABASE INSERTED" if ( ! @$db );
	$setup->{db}    = $db;
	$setup->{alias} = $alias;

	foreach my $inFile ( @inFiles )
	{
		print "    ANALYZING $inFile\n";
		if ( $blastRoot )
		{
			print "111"x12, "\n";
			print "    RUNNING BLAST ROOT\n";
			my $dbs = $setup->{db};
			foreach my $db (@$dbs)
			{
				my $dbName = $db->{dbName};
				&blast($setup, $inFile, $dbName);
			}
		}

		if ( $blastAlias )
		{
			print "112"x12, "\n";
			print "    RUNNING BLAST ALIAS\n";
			my $aliases = $setup->{alias};
			foreach my $alias (@$aliases)
			{
				my $dbName = $alias->{dbName};
				&blast($setup, $inFile, $dbName);
			}
		}
	}
}





sub doMkXml_doXml
{
	print "211"x25, "\n";
	print "  MAKING XML\n";
	my $setup = &loadXmlSetup();

	my ($db, $alias) = &loadDbAlias();
	die "NO INPUT DATABASE INSERTED" if ( ! @$db );

	foreach my $inFile ( @inFiles )
	{
		print "    READING FILE $inFile\n";
		foreach my $db (@$db)
		{
			my $dbName = $db->{dbName};
			&convXml($setup, $inFile, $dbName);
		}

		foreach my $alias (@$alias)
		{
			my $dbName = $alias->{dbName};
			&convXml($setup, $inFile, $dbName);
		}
	}
}



#sub doMkXml_MergeXml
#{
#	my $setup        = &loadXmlSetup();
#	my $xmlFolder    = $setup->{xmlFolder};
#	my $mergedFolder = $setup->{mergedFolder};
#	my $xmlMerger    = $setup->{xmlMerger};
#
#
#	my $expression  = $pref{'mkdb.xml.expression'};
#	if ( $expression )
#	{
#		die if ! &loadconf::checkNeeds('mkdb.xml.expressionInFolder');
#		my $inExpFolder = $pref{'mkdb.xml.expressionInFolder'};
#		die "EXPRESSION FILE $inExpFolder/$expression DOESNT EXISTS" if ( ! -f "$inExpFolder/$expression" );
#	}
#
#	foreach my $inFile ( @inFiles )
#	{
#		print "MERGING XML FROM FOLDER $xmlFolder TO FOLDER $mergedFolder INFILE $inFile\n";
#		my $COMMAND = "$xmlMerger $xmlFolder $mergedFolder $inFile";
#		print "\t$COMMAND\n";
#
#		if ( $serious )
#		{
#			&runCmd($COMMAND);
#			#print `$COMMAND`;
#		}
#	}
#}



sub doConvert_Html
{
	die if ! &loadconf::checkNeeds('mkdb.convert.folders.merged');
	my $mergedFolder = $pref{'mkdb.convert.folders.merged'};
	foreach my $inFile ( @inFiles )
	{
		&convHtml("$mergedFolder/$inFile\_blast_merged_blast_all_gene");
		&convHtml("$mergedFolder/$inFile\_blast_merged_blast_all_org");
	}
}


sub doConvert_Csv
{
	die if ! &loadconf::checkNeeds('mkdb.convert.folders.merged');
	my $mergedFolder = $pref{'mkdb.convert.folders.merged'};
	my $doXml        = $pref{'mkdb.convert.doXml'};
	my $doCsv        = $pref{'mkdb.convert.doCsv'};
	my $expression   = $pref{'mkdb.convert.expression'};

	if ( $expression )
	{
		die if ! &loadconf::checkNeeds('mkdb.convert.expressionInFolder');
		my $inExpFolder = $pref{'mkdb.convert.expressionInFolder'};

		die "EXPRESSION FILE $inExpFolder/$expression DOESNT EXISTS" if ( ! -f "$inExpFolder/$expression" );

		if ( $doCsv )
		{
			die if ! &loadconf::checkNeeds('mkdb.convert.xml2csv');
			my $xml2csv     = $pref{'mkdb.convert.xml2csv'};
			foreach my $inFile ( @inFiles )
			{
				my $INTX="$mergedFolder/$inFile\_blast_merged_blast_all_gene.xml";
				print "CONVERTING XML $INTX TO CSV USING $inExpFolder/$expression\n";
				my $COMMAND = "$xml2csv $INTX $inExpFolder/$expression";
				print "\t$COMMAND\n";

				if ( $serious )
				{
					die "FILE $INTX DOESNT EXISTS" if ( ! -f $INTX );
					die "FILE $inExpFolder/$expression DOESNT EXISTS" if ( ! -f "$inExpFolder/$expression" );
					&runCmd($COMMAND);
					#print `$COMMAND`;

				}
			}
		}
	}
}

sub doMkPca_doPca
{
	my $expression  = $pref{'mkdb.pca.expression'};

	if ( $expression )
	{
		my $pcaPar = '';
		foreach my $key (keys %pref)
		{
			$pcaPar .= $pref{$key} if (index($key, "pcaPar.") != -1);
		}

		die if ! &loadconf::checkNeeds('mkdb.pca.folders.merged');
		my $mergedFolder = $pref{'mkdb.pca.folders.merged'};
		my $mkPca        = $pref{'mkdb.pca.mkPca'};
		my $mkPcaR       = $pref{'mkdb.pca.mkPcaR'};

		foreach my $inFile ( @inFiles )
		{
			my $INTX = "$mergedFolder/$inFile\_blast_merged_blast_all_gene.xml.EXP.$expression.csv";
			print "RUNNING PCA ON CSV $INTX USING PARAMETERS :: $pcaPar\n";
			my $COMMAND = "$pca $INTX $pcaPar";
			print "\t$COMMAND\n";

			if ( $serious )
			{
				die "FILE $INTX DOESNT EXISTS" if ( ! -f $INTX );
				&runCmd($COMMAND);
				#print `$COMMAND`;
			}

			if ( $mkPcaR )
			{
				die if ! &loadconf::checkNeeds('mkdb.pca.pcaR');
				my $pcaR = $pref{'mkdb.pca.pcaR'};
				my $INTR="$INTX\_PCA_00_raw.txt";
				print "RUNNING PCA R ON CSV $INTR\n";
				my $COMMANDR = "$pcaR $INTR";
				print "\t$COMMANDR\n";

				if ( $serious )
				{
					die "FILE $INTR DOESNT EXISTS" if ( ! -f $INTR );
					&runCmd($COMMAND);
					#print `$COMMANDR`;
				}
			}
		}
	}
}





###################################
#FUNCTIONS
###################################
sub loadBlastSetup
{
	die if ! &loadconf::checkNeeds(
		'mkdb.blast.doShort',		'mkdb.blast.blastRoot',
		'mkdb.blast.blastAlias',
		'mkdb.blast.threads',		'mkdb.blast.task',
		'mkdb.blast.evalue',		'mkdb.blast.identity',
		'mkdb.blast.desc'
	);

	my $blast_short    = defined $pref{'mkdb.blast.doShort'   } ? $pref{'mkdb.blast.doShort'   } : die;#|| 0;
	my $blast_root     = defined $pref{'mkdb.blast.blastRoot' } ? $pref{'mkdb.blast.blastRoot' } : die;#|| 0;
	my $blast_alias    = defined $pref{'mkdb.blast.blastAlias'} ? $pref{'mkdb.blast.blastAlias'} : die;#|| 0;
	my $blast_threads  = defined $pref{'mkdb.blast.threads'   } ? $pref{'mkdb.blast.threads'   } : die;#|| 6;
	my $blast_task     = defined $pref{'mkdb.blast.task'      } ? $pref{'mkdb.blast.task'      } : die;#|| 'blastn';
	my $blast_evalue   = defined $pref{'mkdb.blast.evalue'    } ? $pref{'mkdb.blast.evalue'    } : die;#|| 10;
	my $blast_identity = defined $pref{'mkdb.blast.identity'  } ? $pref{'mkdb.blast.identity'  } : die;#|| '50';
	my $blast_desc     = defined $pref{'mkdb.blast.desc'      } ? $pref{'mkdb.blast.desc'      } : die;#|| '';

	my %setup = (
		doShort  => $blast_short,
		doRoot   => $blast_root,
		doAlias  => $blast_alias,
		threads  => $blast_threads,
		task     => $blast_task,
		eValue   => $blast_evalue,
		identity => $blast_identity,
	);

	die if ! &loadconf::checkNeeds(
		'mkdb.blast.folders.dbFolder', 	'mkdb.blast.folders.fastaFolder',
		'mkdb.blast.folders.blastFolder'
	);

	my $fastaFolder   = $inputFolder . "/" . $pref{'mkdb.blast.folders.fastaFolder'  };# || 'fasta'      ;
	die   "FOLDER ", $fastaFolder   ," DOESNT EXISTS. QUITTING." if ( ! -d $fastaFolder  );

	my $dbFolder      = $inputFolder . "/" . $pref{'mkdb.blast.folders.dbFolder'     };# || 'db'         ;
	my $blastFolder   = $inputFolder . "/" . $pref{'mkdb.blast.folders.blastFolder'  };# || 'blast'      ;
	if ( ! -d $dbFolder     ) { mkdir ($dbFolder)    };
	if ( ! -d $blastFolder  ) { mkdir ($blastFolder) };

	$setup{fastaFolder} = $fastaFolder;
	$setup{dbFolder}    = $dbFolder;
	$setup{blastFolder} = $blastFolder;

	if ( $blast_short )
	{
		die if ! &loadconf::checkNeeds(
			'mkdb.blast.doShort.gapOpen',			'mkdb.blast.doShort.gapExtend',
			'mkdb.blast.doShort.wordSize',			'mkdb.blast.doShort.penalty',
			'mkdb.blast.doShort.reward',			'mkdb.blast.doShort.windowSize',
			'mkdb.blast.doShort.minRawGapScore',	'mkdb.blast.doShort.xDrop'
		);

		my $blast_short_gapOpen        = defined $pref{'mkdb.blast.doShort.gapOpen'}        ? $pref{'mkdb.blast.doShort.gapOpen'}        : die;#||  2;
		my $blast_short_gapExtend      = defined $pref{'mkdb.blast.doShort.gapExtend'}      ? $pref{'mkdb.blast.doShort.gapExtend'}      : die;#||  2;
		my $blast_short_wordSize       = defined $pref{'mkdb.blast.doShort.wordSize'}       ? $pref{'mkdb.blast.doShort.wordSize'}       : die;#||  4;
		my $blast_short_penalty        = defined $pref{'mkdb.blast.doShort.penalty'}        ? $pref{'mkdb.blast.doShort.penalty'}        : die;#|| -3;
		my $blast_short_reward         = defined $pref{'mkdb.blast.doShort.reward'}         ? $pref{'mkdb.blast.doShort.reward'}         : die;#||  2;
		my $blast_short_windowSize     = defined $pref{'mkdb.blast.doShort.windowSize'}     ? $pref{'mkdb.blast.doShort.windowSize'}     : die;#||  4;
		my $blast_short_minRawGapScore = defined $pref{'mkdb.blast.doShort.minRawGapScore'} ? $pref{'mkdb.blast.doShort.minRawGapScore'} : die;#|| 10;
		my $blast_short_xDrop          = defined $pref{'mkdb.blast.doShort.xDrop'}          ? $pref{'mkdb.blast.doShort.xDrop'}          : die;#|| 10;

		%setup = {
			%setup,
			short_gapOpen        => $blast_short_gapOpen,
			short_gapExtend      => $blast_short_gapExtend,
			short_wordSize       => $blast_short_wordSize,
			short_penalty        => $blast_short_penalty,
			short_reward         => $blast_short_reward,
			short_windowSize     => $blast_short_windowSize,
			short_minRawGapScore => $blast_short_minRawGapScore,
			short_xDrop          => $blast_short_xDrop,
		};

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

	$setup{desc}  = $blast_desc;

	return \%setup;
}

sub loadDbAlias
{
	my @db;
	my @alias;
	my $fastaFolder = $inputFolder . "/" . $pref{'mkdb.folders.fastaFolder'};
	foreach my $key (sort keys %pref)
	{
		if ($key =~ /^mkdb\.(\S+)\.\1(\d+)\.(\S+)/)
		{
			my $prefix = $1;
			my $count  = $2;
			my $type   = $3;

			if ($prefix eq 'db')
			{
				#print "DB :: PREFIX $prefix COUNT $count TYPE $type => $pref{$key}\n";
				$db[$2]{$3} = $pref{$key};
			}
			elsif ($prefix eq 'alias')
			{
				#print "ALIAS :: PREFIX $prefix COUNT $count TYPE $type => $pref{$key}\n";
				$alias[$2]{$3} = $pref{$key};
			}
		}
	}

	for ( my $d = 0; $d < @db; $d++ )
	{
		my $nfo       = $db[$d];
		my $inFasta   = $nfo->{fileName} || die "FILE NAME NOT INFORMED FOR DB";
		my $inDbName  = $nfo->{dbName}   || die "DB NAME   NOT INFORMED FOR DB";
		my $inDbTitle = $nfo->{title}    || die "DB TITLE  NOT INFORMED FOR DB";
		my $inDbTaxId = $nfo->{taxId}    || die "TAX ID    NOT INFORMED FOR DB";
		die "INPUT DB FILE $fastaFolder/$inFasta DOESTN EXISTS" if ( ! -f "$fastaFolder/$inFasta" );
	}

	return (\@db, \@alias);
}

sub fixFasta
{
	my $inputFile = $_[0];

	print "\tFIXING FASTA $inputFile\n";
	if ( -f "$inputFile.old" ) { warn "FILE '$inputFile' NOT FIXED. APARENTLY ALREADY FIXED"; return 0 };

	open INFILE,  "<$inputFile"     or die "COULD NOT OPEN INPUT FILE '$inputFile' FOR FIXING\n";
	open OUTFILE, ">$inputFile.tmp" or die "COULD NOT OPEN INPUT FILE '$inputFile.tmp' FOR FIXING\n";

	while (<INFILE>)
	{
		chomp;
		if (/^\>/)
		{
			s/\s/\_/g;
			s/\_+/\_/g;
			print OUTFILE $_, "\n";
		} else {
			print OUTFILE $_, "\n";
		}
	}
	close INFILE;
	close OUTFILE;
	rename "$inputFile"    , "$inputFile.old";
	rename "$inputFile.tmp", "$inputFile";
}

sub mkdb
{
	my $setup       = $_[0];
	my $inFasta     = $_[1];
    my $outName     = $_[2];
    my $title       = $_[3];
	my $taxId       = $_[4];

	my $fastaFolder = $setup->{fastaFolder};
	my $dbFolder    = $setup->{dbFolder};

	die "FASTA FOLDER $fastaFolder DOESNT EXISTS" if ( ! defined $fastaFolder ) || ( ! -d $fastaFolder );
	die "DB FOLDER $dbFolder DOESNT EXISTS"       if ( ! defined $dbFolder    ) || ( ! -d $dbFolder    );

	print "CREATING BLAST DB FOR $fastaFolder/$inFasta WITH NAME $outName TITLE $title TAXID $taxId\n";
	my $COMMAND = "makeblastdb -in $fastaFolder/$inFasta -dbtype nucl -title \"$title\" -out $dbFolder/$outName -taxid $taxId -logfile $fastaFolder/$inFasta.log";
	print "\t$COMMAND\n";

	if ( $serious )
	{
		die "FILE $fastaFolder/$inFasta DOESNT EXISTS" if ( ! -f "$fastaFolder/$inFasta" );
		&runCmd($COMMAND);
		#print `$COMMAND`;
	}

	print "\n";
}

sub mkalias
{
	my $setup = $_[0];
	my $inDb  = $_[1];
	my $outDb = $_[2];
	my $title = $_[3];

	my $dbFolder = $setup->{dbFolder};
	die if ( ! defined $dbFolder    ) || ( ! -f $dbFolder    );

	print "CREATING BLAST DB ALIAS FOR $inDb AS $outDb TITLED $title\n";
	my $COMMAND = "blastdb_aliastool -dblist \"$inDb\" -dbtype nucl -out $dbFolder/$outDb -title \"$title\" -logfile $outDb.log";
	print "\t$COMMAND\n";

	if ( $serious )
	{
		&runCmd($COMMAND);
		#print `$COMMAND`;
	}

	print "\n";
}

sub blast
{
	my $setup       = $_[0];
	my $inFile      = $_[1];
	my $Db          = $_[2];

	my $doShort     = $setup->{doShort};
	my $doRoot      = $setup->{doRoot};
	my $doAlias     = $setup->{doAlias};
	my $threads     = $setup->{threads};
	my $task        = $setup->{task};
	my $eValue      = $setup->{eValue};
	my $identity    = $setup->{identity};
	my $fastaFolder = $setup->{fastaFolder};
	my $dbFolder    = $setup->{dbFolder};
	my $blastFolder = $setup->{blastFolder};
	my $desc        = $setup->{desc};
	my $db          = $setup->{db};
	my $alias       = $setup->{alias};

	my $inShortFile = substr($inFile, rindex($inFile, "/")+1);
	my $outFile     = "$inShortFile\_$Db.blast";
	my $outBlast    = "$blastFolder/$outFile";

	print "BLASTING $inFile AGAINST $Db EVALUE $eValue THREAD $threads TASKS $task IDENTITY $identity OUT $outBlast\n";
	my $COMMAND = "blastn -task $task -db $dbFolder/$Db -query $inFile -out $outBlast  -evalue $eValue -num_threads $threads -perc_identity $identity";

	if ( $doShort )
	{
		my $short_gapOpen        = $setup->{short_gapOpen};
		my $short_gapExtend      = $setup->{short_gapExtend};
		my $short_wordSize       = $setup->{short_wordSize};
		my $short_penalty        = $setup->{short_penalty};
		my $short_reward         = $setup->{short_reward};
		my $short_windowSize     = $setup->{short_windowSize};
		my $short_minRawGapScore = $setup->{short_minRawGapScore};
		my $short_xDrop          = $setup->{short_xDrop};

		$COMMAND .= " -gapopen $short_gapOpen -gapextend $short_gapExtend -word_size $short_wordSize -penalty $short_penalty -reward $short_reward -window_size $short_windowSize -min_raw_gapped_score $short_minRawGapScore -xdrop_gap $short_xDrop -no_greedy ";
	}

	#blastn         -task blastn -db db/cgR265        -query 59dup.fasta    -out 59dup_cgR265_id40_long.blast -evalue 100      -num_threads 3        -perc_identity 50 -gapopen 2 -gapextend 2 -word_size 7 -penalty -2 -reward 2
	#blastn         -task blastn -db db/cgR265        -query 59dup.fasta    -out 59dup_cgR265_id40_long.blast -evalue 10       -num_threads 3        -perc_identity 50 -gapopen 2 -gapextend 2 -word_size 4 -penalty -3 -reward 2  -no_greedy -window_size 4 -min_raw_gapped_score 20 -xdrop_gap 50
	print "\t$COMMAND\n";

	if ( $serious )
	{
		die "FILE $inFile DOESNT EXISTS" if ( ! -f "$inFile" );
		&runCmd($COMMAND);
		#print `$COMMAND`;
	}

	print "\n";
}



sub convXml
{
	my $setup       = $_[0];
	my $inFile      = $_[1];
	my $db          = $_[2];
	my $inShortFile = substr($inFile, rindex($inFile, "/")+1);
	my $outFile     ="$inShortFile\_$db.blast";

	my $blast2xml   = $setup->{blast2xml};
	my $blastFolder = $setup->{blastFolder};
	my $xmlFolder   = $setup->{xmlFolder};
	my $blast_desc  = $setup->{desc};

	print "CONVERTING $inFile DATABASE $db FROM $blastFolder/$outFile FILE TO XML\n";

	my $COMMAND = "$blast2xml $setupFile $blastFolder $outFile $xmlFolder \"$blast_desc\"";
	print "\t$COMMAND\n";

	if ( $serious )
	{
		if ( ! -f "$blastFolder/$outFile" ) { die "\tCOULD NOT FIND $blastFolder/$outFile TO BE CONVERTED TO XML"; };
		&runCmd($COMMAND);
		#print `$COMMAND`;
	}

	print "\n";
}



sub loadXmlSetup
{
	my %setup;

	my $mkXml    = $pref{'mkdb.xml.mkXml'};
	my $mergeXml = $pref{'mkdb.xml.mergeXml'};

	if ( $mkXml )
	{
		die if ! &loadconf::checkNeeds(
			'mkdb.xml.desc',		'mkdb.xml.blast2xml',
		);

		my $blast_desc    = defined $pref{'mkdb.xml.desc'      } ? $pref{'mkdb.xml.desc'      } : die;#|| '';
		my $blast2xml     = $pref{'mkdb.xml.blast2xml'};
		die   "FILE "  , $blast2xml     ," DOESNT EXISTS. QUITTING." if ( ! -f $blast2xml    );

		$setup{blast2xml}   = $blast2xml;
		$setup{desc}        = $blast_desc;
	}

	if ( $mergeXml )
	{
		die if ! &loadconf::checkNeeds('mkdb.xml.xmlMerger', 'mkdb.xml.folders.merged');

		my $mergedFolder    = $inputFolder . "/" . $pref{'mkdb.xml.folders.merged'    };# || 'blast'      ;
		die   "FOLDER ", $mergedFolder     ," DOESNT EXISTS. QUITTING." if ( ! -d $mergedFolder    );
		$setup{mergedFolder} = $mergedFolder;

		my $xmlMerger        = $pref{'mkdb.xml.xmlMerger'};
		$setup{xmlMerger}    = $xmlMerger;

	}

	if ( $mkXml || $mergeXml )
	{
		die if ! &loadconf::checkNeeds(
			'mkdb.xml.folders.xml', 	'mkdb.xml.folders.blast'
		);
		my $xmlFolder     = $inputFolder . "/" . $pref{'mkdb.xml.folders.xml'    };# || 'blast'      ;
		die   "FOLDER ", $xmlFolder     ," DOESNT EXISTS. QUITTING." if ( ! -d $xmlFolder    );
		$setup{xmlFolder}   = $xmlFolder;

		my $blastFolder   = $inputFolder . "/" . $pref{'mkdb.xml.folders.blast' };# || 'blast'      ;
		die   "FOLDER ", $blastFolder   ," DOESNT EXISTS. QUITTING." if ( ! -d $blastFolder  );
		$setup{blastFolder}  = $blastFolder;
	}

	return \%setup;
}

sub convHtml
{
	my $inXmlFile = $_[0];

	die if ! &loadconf::checkNeeds('mkdb.convert.xml2tml');
	my $html =  $pref{'mkdb.convert.xml2tml'};

	print "CONVERTING XML $inXmlFile.xml TO HTML\n";
	my $COMMANDX = "$html -IN $inXmlFile.xml -OUT $inXmlFile.html";
	print "\t$COMMANDX\n";

	if ( $serious )
	{
		die "FILE $inXmlFile.xml DOESNT EXISTS" if ( ! -f "$inXmlFile.xml" );
		&runCmd($COMMANDX);
		#print `$COMMANDX`;
	}
}





sub runCmd
{
	my $cmd = $_[0];

	open (PIPE, "$cmd |");
	while (<PIPE>) { print };
	close PIPE;
}

1;



#sub clean
#{
#	my $inFile = $_[0];
#	print "CLEANING THE MESS OF $inFile\n";
#
#	if ( $cleanDb == 1)
#	{
#		print "CLEANING THE MESS OF $inFile\n";
#		unlink glob("$dbFolder/*");
#		unlink glob("$fastaFolder/*.log");
#	}
#
#	if ( $clean == 1)
#	{
#		unlink glob("$blastFolder/$inFile*");
#		unlink glob("$xmlFolder/$inFile*");
#		unlink glob("$finalFolder/$inFile*");
#	}
#
#	print "\n";
#}

			#
			#
			#
			#
			#
			####################################
			##PROGRAMS SETUP
			####################################
			#
			#die if ! &loadconf::checkNeeds(
			#	'mkdb.programs.html',		'mkdb.programs.blast2xml',		'mkdb.programs.xmlMerger',
			#	'mkdb.programs.xml2csv',	'mkdb.programs.pca',			'mkdb.programs.pcaR'
			#);
			#
			#
			#my $html         = $pref{'mkdb.programs.html'};
			#my $blast2xml    = $pref{'mkdb.programs.blast2xml'};
			#my $xmlMerger    = $pref{'mkdb.programs.xmlMerger'};
			#my $xml2csv      = $pref{'mkdb.programs.xml2csv'};
			#my $pca          = $pref{'mkdb.programs.pca'};
			#my $pcaR         = $pref{'mkdb.programs.pcaR'};
			#
			#
			####################################
			##FOLDERS SETUP
			####################################
			#
			#my $xmlFolder     = $inputFolder . "/" . $pref{'mkdb.folders.xmlFolder'    };# || 'xml'        ;
			#my $finalFolder   = $inputFolder . "/" . $pref{'mkdb.folders.finalFolder'  };# || 'out'        ;
			#my $inExpFolder   = $inputFolder . "/" . $pref{'mkdb.folders.inExpFolder'  };# || 'query_exp'  ;
			#my $inFastaFolder = $inputFolder . "/" . $pref{'mkdb.folders.inFastaFolder'};# || 'query_fasta';
			#
			#
			#die   "FOLDER ", $inFastaFolder ," DOESNT EXISTS. QUITTING." if ( ! -d $inFastaFolder );
			#print "FOLDER ", $inExpFolder   ," DOESNT EXISTS. RESUMING." if ( ! -d $inExpFolder  );
			#
			#
			#if ( ! -d $xmlFolder    ) { mkdir ($xmlFolder)   };
			#
