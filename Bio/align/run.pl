#!/usr/bin/perl -w
use strict;
use Cwd 'abs_path';
use Shared::loadconf;

my $INPUTFOLDER      = $ARGV[0] || die "NO INPUT FOLDER DEFINED";
my $SETUPFILE        = $ARGV[1] || die "NO SETUP FILE DEFINED";
my $folderName       = substr($INPUTFOLDER, rindex($INPUTFOLDER, "/")+1);

my (	$grouping, 	$dryRun);
my (	$DOMKDB,		$DOMERGE, 		$DOCONVERT, 		$DOCLUSTAL,
		$DOPROBES);
my (	$OUTMERGED,		$CLUSTALFOLDER,	$QUERYFASTAFOLDER,	$XMLTOMERGE,
		$BLASTOUT, 		$DBOUT,			$XMLOUT,			$CONVERTERFILTER,
		#$OUTOUT,
		$PROBESFOLDER,	$ALNFOLDER);
my (	$DBMAKER,		$MERGER,		$CONVERTER,			$CLUSTAL,
		$PROBE);

my $setup = &loadConfig();
&printSetup($setup);

foreach my $group (split (/,/, $grouping))
{
	&run($INPUTFOLDER, $group);
}
#&run($INPUTFOLDER, 'REGIO');

sub run
{
	my $FOLDER     = $_[0];
	my $TYPE       = $_[1];

	my $TAB         = "$folderName.$TYPE.csv.out.tab";
	my $QFASTA      = "$QUERYFASTAFOLDER/$TAB.fasta";
	my $MERGEFOLDER = "$XMLTOMERGE\_$TYPE/";
	mkdir($MERGEFOLDER);
	#TODO: not working with .organism.xml
	#		not that i care
	my $MTAB        = "$TAB\_blast_merged_blast_all_gene.xml.tab";

	print "RUNNING FOLDER $folderName TYPE $TYPE\n";
	print " "x1 . "TAB         : $TAB\n";
	print " "x1 . "QUERY FASTA : $QFASTA\n";
	print " "x1 . "MERGE FOLDER: $MERGEFOLDER\n";
    print " "x1 . "OUT MERGED  : $OUTMERGED\n";
	print " "x1 . "MTAB        : $MTAB\n";

	if ( $DOMKDB )
	{
		print " "x2 . "CREATING DB\n";

		print " "x3 . "CLEANING: $BLASTOUT/$TAB*[.blast, .log]\n";
		if ( ! $dryRun )
		{
			unlink glob ("$BLASTOUT/$TAB*.blast");
			unlink glob ("$BLASTOUT/$TAB*.log");
		}

		print " "x3 . "CLEANING: $XMLOUT/$TAB*[.xml, .tab]\n";
		if ( ! $dryRun )
		{
			unlink glob ("$XMLOUT/$TAB*.xml");
			unlink glob ("$XMLOUT/$TAB*.tab");
		}

		my $cmdmkdb = "$DBMAKER '$SETUPFILE' '$INPUTFOLDER' '$QFASTA' ";
		print " "x3 . "CMD MKDB: $cmdmkdb\n";
		if ( ! $dryRun )
		{
			&runCmd($cmdmkdb);
			#print `$cmdmkdb`;
		}
	}

	if ( $DOMERGE )
	{
		print " "x2 . "MERGING XML\n";

		print " "x3 . "CLEANING: $MERGEFOLDER/*.xml\n";
			unlink glob ("$MERGEFOLDER/*.xml")  if ( ! $dryRun );

		print " "x3 . "LINKING : $XMLOUT/$TAB*.xml $MERGEFOLDER\n";
			if ( ! $dryRun )
			{
				map
				{
					print " "x4 . "LINKING $_\n";
					print `ln -s $_ $MERGEFOLDER`;
				} glob("$XMLOUT/$TAB*.xml");
			}

		my $cmdmerge = "$MERGER $MERGEFOLDER $OUTMERGED $TAB";
		print " "x3 . "CMD MERG: $cmdmerge\n";
		if ( ! $dryRun )
		{
			&runCmd($cmdmerge);
			#print `$cmdmerge`;
		}
	}

	if ( $DOCONVERT )
	{
		print " "x2 . "CONVERTING TO TAB\n";

		print " "x3 . "CLEANING: $OUTMERGED/$MTAB*[.fasta, .log, .tab, .xml]\n";
		if ( ! $dryRun )
		{
			unlink glob("$OUTMERGED/$MTAB*.fasta");
			unlink glob("$OUTMERGED/$MTAB*.log");
			unlink glob("$OUTMERGED/$MTAB*.tab");
			unlink glob("$OUTMERGED/$MTAB*.xml");
			unlink glob("$OUTMERGED/$MTAB*.aln");
			#unlink glob("$OUTMERGED/$MTAB*.dnd");
			#unlink glob("$OUTMERGED/$MTAB*.stat");
		}

		#TODO: CONSIDER EXPORTING TO DIFFERENT FOLDER
		my $filterStr = '';
		if ( $CONVERTERFILTER ) { $filterStr = "groupByCol1Filter:$CONVERTERFILTER" };
		my $cmdconv = "$CONVERTER '$OUTMERGED/$MTAB' '$QFASTA' '$INPUTFOLDER' confFile:$SETUPFILE $filterStr";
		print " "x3 . "MERGEDTAB  : $OUTMERGED/$MTAB\n";
		print " "x3 . "QUERY FASTA: $QFASTA\n";
		print " "x3 . "CMD CONV   : $cmdconv\n";
		if ( ! $dryRun )
		{
			&runCmd($cmdconv);
			#print `$cmdconv` if ( ! $dryRun );
		}
	}

	if ( $DOCLUSTAL )
	{
		print " "x2 . "RUNNING CLUSTAL\n";

		print " "x3 . "CLEANING: $CLUSTALFOLDER/$MTAB*.clustal[.dnd, .stat, .log, .fasta]\n";
		if ( ! $dryRun )
		{
			unlink glob("$CLUSTALFOLDER/$MTAB*.clustal.dnd");
			unlink glob("$CLUSTALFOLDER/$MTAB*.clustal.stat");
			unlink glob("$CLUSTALFOLDER/$MTAB*.clustal.log");
			unlink glob("$CLUSTALFOLDER/$MTAB*.clustal.fasta");
			unlink glob("$CLUSTALFOLDER/$MTAB*.clustal.fasta.log");
			unlink glob("$CLUSTALFOLDER/$MTAB*.clustal.fasta.consensus.fasta");
		}

		my $cmdclustal = "$CLUSTAL '$SETUPFILE' '$INPUTFOLDER' '$MTAB'";
		print " "x3 . "CMD CLUSTAL: $cmdclustal\n";
		&runCmd($cmdclustal) if ( ! $dryRun );
		#print `$cmdclustal` if ( ! $dryRun );
	}

	if ( $DOPROBES )
	{
		print " "x2 . "CREATING PROBES\n";
		print " "x3 . "CLEANING: $CLUSTALFOLDER/$MTAB*.consensus.fasta[.html, .txt]\n";
		if ( ! $dryRun )
		{
			#unlink glob("$PROBESFOLDER/$MTAB*.consensus.fasta.html");
			#unlink glob("$PROBESFOLDER/$MTAB*.consensus.fasta.txt");
			#todo: not workig because probes changes name of file
			#unlink glob("$ALNFOLDER/$MTAB*.html");
			#unlink glob("$ALNFOLDER/$MTAB*.txt");
			#unlink glob("$ALNFOLDER/$MTAB*.tab");
		}

		my $cmdprobe = "$PROBE '$SETUPFILE' '$INPUTFOLDER' '$MTAB'";
		print " "x3 . "CMD PROBE: $cmdprobe\n";
		&runCmd($cmdprobe) if ( ! $dryRun );
		exit 0;
	}
}


sub loadConfig
{
	if ( -d $INPUTFOLDER )
	{
		print "RUNNING OVER FOLDER $INPUTFOLDER\n";
	} else {
		print "FOLDER $INPUTFOLDER DOESNT EXISTS\n";
		exit 1;
	}

	if ( -f $SETUPFILE )
	{
		print "RUNNING OVER SETUP FILE $SETUPFILE\n";
	} else {
		print "SETUP FILE $SETUPFILE DOESNT EXISTS\n";
		exit 1;
	}

	&absAndCheck(	'file',        \$SETUPFILE   );
	&absAndCheck(	'folderCheck', \$INPUTFOLDER );

	my %pref = &loadconf::loadConf($SETUPFILE);
	&loadconf::checkNeeds(
		'run.mkdb',						'run.merge',
		'run.convert',					'run.clustal',
		'run.grouping',					'run.dryRun',
		'run.converterFilter',

		'run.folders.outmerged', 		'run.folders.clustal',
		'run.folders.queryfasta',	 	'run.folders.xmltomerge',
		'run.folders.blast', 			'run.folders.db',
		'run.folders.xml',
#		'run.folders.out',

		'run.programs.dbmaker',			'run.programs.merger',
		'run.programs.converter', 		'run.programs.clustal',
		'run.programs.primerFromFasta'
	);


	$grouping           = $pref{'run.grouping'        };
	$dryRun             = $pref{'run.dryRun'          };
	$DOMKDB             = $pref{'run.mkdb'            };
	$DOMERGE            = $pref{'run.merge'           };
	$DOCONVERT          = $pref{'run.convert'         };
	$DOCLUSTAL          = $pref{'run.clustal'         };
	$DOPROBES           = $pref{'run.probes'          };
	$CONVERTERFILTER    = $pref{'run.converterFilter' };

	$OUTMERGED          = "$INPUTFOLDER/" . $pref{'run.folders.outmerged' };
	$CLUSTALFOLDER      = "$INPUTFOLDER/" . $pref{'run.folders.clustal'   };
	$PROBESFOLDER       = "$INPUTFOLDER/" . $pref{'run.folders.probes'    };
	$ALNFOLDER          = "$INPUTFOLDER/" . $pref{'run.folders.alignments'};
	$QUERYFASTAFOLDER   = "$INPUTFOLDER/" . $pref{'run.folders.queryfasta'};
	$XMLTOMERGE         = "$INPUTFOLDER/" . $pref{'run.folders.xmltomerge'};
	$BLASTOUT           = "$INPUTFOLDER/" . $pref{'run.folders.blast'     };
	$DBOUT              = "$INPUTFOLDER/" . $pref{'run.folders.db'        };
	#$OUTOUT             = "$INPUTFOLDER/" . ( $pref{'run.folders.out'       } || 'out'          );
	$XMLOUT             = "$INPUTFOLDER/" . $pref{'run.folders.xml'       };

	$DBMAKER            = $pref{'run.programs.dbmaker'         } || './mkdb.pl';
	$MERGER             = $pref{'run.programs.merger'          } || './mergeXML.pl';
	$CONVERTER          = $pref{'run.programs.converter'       } || './mergedTab2Align.pl';
	$CLUSTAL            = $pref{'run.programs.clustal'         } || './clustal.pl';
	$PROBE              = $pref{'run.programs.primerFromFasta' } || './primerFromFasta.pl';

	&absAndCheck(	'folderMake',
					\$OUTMERGED,	\$CLUSTALFOLDER,	\$QUERYFASTAFOLDER,
					\$XMLTOMERGE,	\$BLASTOUT,			\$DBOUT,
					\$XMLOUT,		\$PROBESFOLDER,
					#\$OUTOUT,
					\$ALNFOLDER);
	&absAndCheck(	'file',
					\$DBMAKER,		\$MERGER,			\$CONVERTER,
					\$CLUSTAL,		\$PROBE);

	my %setup = (
		"Input"=>
			{
			"Input Folder"			=> $INPUTFOLDER,
			"Setup File"  			=> $SETUPFILE,
			"Name Short", 			=> $folderName,
			"Grouping",  			=> $grouping,
			"Dry Run",   			=> $dryRun,
			},
		"Behavior" =>
			{
			"Make DB"				=> $DOMKDB,
			"Merge"					=> $DOMERGE,
			"Convert"				=> $DOCONVERT,
			"Do Alignment"			=> $DOCLUSTAL,
			"Make Probes"			=> $DOPROBES,
			"Converter Filder"		=> $CONVERTERFILTER,
			},
		"Folders" =>
			{
			"Merged Output"			=> $OUTMERGED,
			"Clustal Output"		=> $CLUSTALFOLDER,
			"Query Fasta"			=> $QUERYFASTAFOLDER,
			"Blast XML Output"		=> $XMLTOMERGE,
			"Blast Output"			=> $BLASTOUT,
			"Blast DB"				=> $DBOUT,
			"XML Output"			=> $XMLOUT,
			"Probes"				=> $PROBESFOLDER,
			"Alignments"			=> $ALNFOLDER,
			},
		"Programs" =>
			{
			"DB maker"				=> $DBMAKER,
			"XML merger"			=> $MERGER,
			"XML to TAB converter"	=> $CONVERTER,
			"Clustal"				=> $CLUSTAL,
			"Probes"				=> $PROBE,
			}
		);
	return \%setup;
}

sub absAndCheck
{
	my $type = shift @_;
	if ( $type eq 'file' )
	{
		foreach my $file (@_)
		{
			if ( ! -f $$file )
			{
				die "FILE $$file DOESNT EXISTS\n"
			} else {
				$$file = abs_path($$file);
			}
		}
	}
	elsif ( $type eq 'folderMake' )
	{
		foreach my $folder (@_)
		{
			if ( ! -d $$folder )
			{
				mkdir($$folder);
				$$folder = abs_path($$folder);
			} else {
				$$folder = abs_path($$folder);
			}
		}
	}
	elsif ( $type eq 'folderCheck' )
	{
		foreach my $folder (@_)
		{
			if ( ! -d $$folder )
			{
				die "FOLDER $$folder DOESNT EXISTS\n";
			} else {
				$$folder = abs_path($$folder);
			}
		}
	} else {
		die 'WRONG REQUIREMENT';
	}
}

sub printSetup
{
	my $hash     = $_[0];
	my $lineSize = 110;
	print "#"x$lineSize, "\n";
	print " "x(($lineSize - 46)/2), "AUTOMATIC BLAST EXTRACTOR, SCISOR AND ALIGNER\n";
	print "#"x$lineSize, "\n";

	while (my ( $k, $v ) = each %$hash)
	{
		print "="x$lineSize, "\n";
		printf "   %s\n", $k;
		print "-"x$lineSize, "\n";
		while ( my ( $kk, $vv ) = each %$v)
		{
			printf "      %-20s: %s\n", $kk, $vv;
		}
	}

	print "#"x40, "\n";
}

sub runCmd
{
	my $cmd = $_[0];
	print "  $0 :: RUNNING COMMAND $cmd\n";
	open (PIPE, "$cmd 2>&1 |");
	while (<PIPE>) { print };
	close PIPE;
	print "  $0 :: RUNNING COMMAND DONE $cmd\n";
}

1;
