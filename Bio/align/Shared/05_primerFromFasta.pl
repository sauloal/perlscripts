#!/usr/bin/perl -w
use strict;
use WWW::Curl::Simple;
use FindBin qw($Bin);
use lib "$Bin";
use loadconf;
my $only1  = 0;

die if @ARGV != 3;
#'$SETUPFILE' '$INPUTFOLDER' '$MTAB'
my $setupFile       = $ARGV[0];
my $baseFolder      = $ARGV[1];
my $inputFilePrenom = $ARGV[2];

die if ! defined $setupFile;
die if ! defined $baseFolder;
die if ! defined $inputFilePrenom;

print "\n\n", "8"x40, "\n";
print "  PROBE DESIGN :\n";
print "    SETUP      : $setupFile\n";
print "    BASE FOLDER: $baseFolder\n";
print "    INPUT      : $inputFilePrenom\n";

die "SETUP FILE DOESNT EXISTS"  if ( ! -f $setupFile      );
die "BASE FOLDER DOESNT EXISTS" if ( ! -d $baseFolder     );

my %pref = &loadconf::loadConf($setupFile);
&loadconf::checkNeeds(
	'probes.run',

	'probes.do.design',					'probes.do.test',
	'probes.do.pcr'
);

my $run             = $pref{'probes.run'         };
my $doDesign        = $pref{'probes.do.design'   };
my $doTest          = $pref{'probes.do.test'     };
my $doPcr           = $pref{'probes.do.pcr'      };

print "    DO DESIGN  : $doDesign\n";
print "    DO TEST    : $doTest\n";
print "    DO ePCR    : $doPcr\n";


if ( $doDesign )
{
	&loadconf::checkNeeds(	'probes.folders.inputFolder',		'probes.folders.outputFolder',
							'probes.programs.primerDesign');
	my $primerDesign    = $pref{'probes.programs.primerDesign'};
	my $inputFolder     = $baseFolder . "/" . $pref{'probes.folders.inputFolder'    };
	my $outputFolder    = $baseFolder . "/" . $pref{'probes.folders.outputFolder'   };

	die "AUXILIAR PROGRAM NOT FOUND: $primerDesign"  if ! -f $primerDesign;
	die "INPUT FOLDER DOESNT EXISTS: $inputFolder"   if ! -d $inputFolder;
	if ( ! -d $outputFolder ) { mkdir($outputFolder) };

	print "    DESIGNER   : $primerDesign\n";

	my $prenom = $inputFolder . "/" . $inputFilePrenom;

	#unlink glob("$PROBESFOLDER/$MTAB*.consensus.fasta.html");
	#unlink glob("$PROBESFOLDER/$MTAB*.consensus.fasta.txt");

	my @fastaFiles = glob("$prenom*.fasta");
	die "NO FILES WITH PRENOM: $prenom" if ! @fastaFiles;
	print "    FASTA FILES: ", ( scalar @fastaFiles ),"\n\n";
	#map { print "               > $_\n"; } @fastaFiles;

	foreach my $file ( @fastaFiles )
	{
		print " $file\n";
		my $dCmd = "$primerDesign FASTA '$file' '$outputFolder'";
		print "  DESIGN CMD: $dCmd\n";
		&runCmd($dCmd) if $run;
		last if ( $only1 );
	}

	print '7'x40, "\n"x3;
}

if ( $doTest )
{
	&loadconf::checkNeeds('probes.folders.outputFolder',	'probes.programs.primerTest',
						  'probes.folders.alignmentFolder');

	my $primerTest      = $pref{'probes.programs.primerTest'  };
	my $outputFolder    = $baseFolder . "/" . $pref{'probes.folders.outputFolder'   };
	my $alignmentFolder = $baseFolder . "/" . $pref{'probes.folders.alignmentFolder'};

	die "AUXILIAR PROGRAM NOT FOUND: $primerTest" if ! -f $primerTest;
	die "INPUT FOLDER NOT FOUND: $outputFolder"   if ! -d $outputFolder;

	if ( ! -d $alignmentFolder ) { mkdir($alignmentFolder) };
	print "    TESTER     : $primerTest\n";

	my @htmlFiles = glob("$outputFolder/*.html");
	die "NO HTML FILES AT $outputFolder" if ! @htmlFiles;
	print "    HTML FILES : ", ( scalar @htmlFiles ),"\n\n";
	#map { print " > $_\n"; } @htmlFiles;

	foreach my $file ( @htmlFiles )
	{
		print " $file\n";
		my $tCmd = "$primerTest '$file' '$alignmentFolder'";
		print "  TEST CMD  : $tCmd\n";
		&runCmd($tCmd) if $run;
		last if ( $only1 );
	}
	print '6'x40, "\n"x3;
}

if ( $doPcr )
{

	&loadconf::checkNeeds(	'probes.programs.epcr',				'probes.pcrFasta',
							'probes.folders.alignmentFolder',	'probes.folders.pcrFolder');

	my $pcrFasta        =                     $pref{'probes.pcrFasta'               };
	my $epcr            =                     $pref{'probes.programs.epcr'          };
	my $pcrFolder       = $baseFolder . "/" . $pref{'probes.folders.pcrFolder'      };
	my $alignmentFolder = $baseFolder . "/" . $pref{'probes.folders.alignmentFolder'};

	die "PCR FASTA FILE NOT FOUND: $pcrFasta"          if ! -f $pcrFasta;
	die "ALIGNMENT FOLDER NOT FOUND: $alignmentFolder" if ! -d $alignmentFolder;
	die "AUXILIAR PROGRAM NOT FOUND: $epcr"            if ! -f $epcr;

	if ( ! -d $pcrFolder ) { mkdir($pcrFolder) };

	print "    ePCR       : $epcr\n";
	print "    FASTA      : $pcrFasta\n";
	print "    IN  FOLDER : $alignmentFolder\n";
	print "    OUT FOLDER : $pcrFolder\n";

	my @tabFiles = glob("$alignmentFolder/*.tab");
	die "NO TAB FILES AT $alignmentFolder" if ! @tabFiles;
	print "    TAB FILES  : ", ( scalar @tabFiles ),"\n\n";
	#map { print " > $_\n"; } @tabFiles;

	foreach my $file (  @tabFiles )
	{
		print " $file\n";
		my $eCmd = "$epcr '$file' '$pcrFolder' '$pcrFasta'";
		print "  ePCR CMD  : $eCmd\n";
		&runCmd($eCmd) if $run;
		last if ( $only1 );
	}
	print '5'x40, "\n"x3;
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
