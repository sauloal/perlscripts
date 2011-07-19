#!/usr/bin/perl -w
use strict;
use FindBin qw($Bin);
use lib "$Bin";
use loadconf;

my $setupFile  = $ARGV[0] || die "NO SETUP FILE PROVIDED";
my $baseFolder = $ARGV[1] || die "NO BASE FOLDER PROVIDED";
my $PREFIX     = $ARGV[2] || die "NO PREFIX PROVIDED";
my $maxTime    = 1200; #600s = 10min 800s = 12.5min 900s = 15min 1200s = 20min
my %pids;

die "SETUP FILE $setupFile NOT FOUND"   if ( ! -f $setupFile  );
die "BASE FOLDER $baseFolder NOT FOUND" if ( ! -d $baseFolder );

print "RUNNING CLUSTAL WITH PREFIX $PREFIX\n";

my %pref = &loadconf::loadConf($setupFile);

die if ! &loadconf::checkNeeds(
	#'clustal.run',					'clustal.max',
	#'clustal.clustal',				'clustal.params.tree',
	'clustal.inputFolder', 			'clustal.outputFolder',
	'clustal.sleeptime',			'clustal.run',
	'clustal.max',					'clustal.clustalP',
	'clustal.params.numInter',		'clustal.params.bootstrap',
	'clustal.params.pwgapopen',		'clustal.params.pwgapext',
	'clustal.params.gapopen',		'clustal.params.gapext',
	'clustal.params.tree',
	'clustal.makeConsensus',        'clustal.consensusProg'
);

my $inputFolder   = $baseFolder . "/" . $pref{'clustal.inputFolder'}  || 'xml_merged';
my $outputFolder  = $baseFolder . "/" . $pref{'clustal.outputFolder'} || 'clustal';

my $sleepTime     = $pref{'clustal.sleeptime'       } ;#|| 5;
my $RUN           = $pref{'clustal.run'             } ;#|| 1;
my $MAX           = $pref{'clustal.max'             } ;#|| 3;
my $CLUSTAL       = $pref{'clustal.clustalP'        } ;#|| "./clustalw2";
die "CLUSTAL PROGRAM '$CLUSTAL' NOT FOUND" if ( ! -f $CLUSTAL );
my $numInter      = $pref{'clustal.params.numInter' } ;#|| 1000;
my $bootstrap     = $pref{'clustal.params.bootstrap'} ;#|| 1000;
my $pwgapopen     = $pref{'clustal.params.pwgapopen'} ;#|| 10;
my $pwgapext      = $pref{'clustal.params.pwgapext' } ;#|| 6.66;
my $gapopen       = $pref{'clustal.params.gapopen'  } ;#|| 10;
my $gapext        = $pref{'clustal.params.gapext'   } ;#|| 6.66;
my $tree          = $pref{'clustal.params.tree'     } ;#|| 1;
my $makeConsensus = $pref{'clustal.makeConsensus'   } ;#|| 1;
my $consensusProg = $pref{'clustal.consensusProg'   } ;#|| './consensus.pl';


if ( ! -d $outputFolder ) { mkdir($outputFolder) or die "COULD NOT CREATE FOLDER $outputFolder\n"; };
die "INPUT FOLDER $inputFolder DOESNT EXISTS" if ( ! -d $inputFolder );

print "RUNNING CLUSTAL
    PREFIX    : $PREFIX
    INFOLDER  : $inputFolder
	OUTFOLDER : $outputFolder
    CLUSTAL   : $CLUSTAL
    PWD       : " . `pwd` ."\n\n";


my $treeStr    = '';;
if ( $tree )
{
	die if ! &loadconf::checkNeeds(
	'clustal.params.tree.outputtree',	'clustal.params.tree.clustering',
	'clustal.params.tree.pim',
	);
	my $outputtree = $pref{'clustal.params.tree.outputtree'} || 'NJ';
	my $clustering = $pref{'clustal.params.tree.clustering'} || 'UPGMA';
	my $pim        = $pref{'clustal.params.tree.pim'};
	if ( ! defined $pim ) { $pim = 1 };

	my $pimStr     = $pim ? " -PIM" : "";
	$treeStr = $tree ? " -TREE -ITERATION=TREE  -OUTPUTTREE=$outputtree -CLUSTERING=$clustering $pimStr" : "";
}

my $PARAM =	" -BATCH -ALIGN -TYPE=DNA -OUTPUT=FASTA -KIMURA"                                .
			$treeStr .
			" -NUMITER=$numInter -BOOTSTRAP=$bootstrap"                                     .
			" -PWGAPOPEN=$pwgapopen -PWGAPEXT=$pwgapext -GAPOPEN=$gapopen -GAPEXT=$gapext";


##ls -1 xml_merged/*.fasta | grep -v "fasta.clustal.fasta" | xargs --delimiter="\n" -n 1 -r -P 4 ./clustal
opendir(DIR, $inputFolder) or die "COULD NOT OPEN DIR: $!";
my @inFiles = grep(!/fasta\.clustal\.fasta/, grep(/\.fasta$/, grep(/$PREFIX/, readdir(DIR))));
closedir DIR;

die "NO INPUT FILES FOUND IN $inputFolder" if ( ! scalar @inFiles );

foreach my $INFILE (sort @inFiles)
{
	my $OUTFILEF = "$outputFolder/$INFILE.clustal.fasta";
    my $OUTFILET = "$outputFolder/$INFILE.clustal.dnd";
    my $OUTFILES = "$outputFolder/$INFILE.clustal.stat";
    my $OUTFILEL = "$outputFolder/$INFILE.clustal.log";

	my $CMD1 = "$CLUSTAL $PARAM -INFILE='$inputFolder/$INFILE' -OUTFILE='$OUTFILEF' -STATS='$OUTFILES'" . ($tree ?  " -NEWTREE='$OUTFILET'" : "");
    my $RUNCMD = $CMD1 . ' &> \'' . $OUTFILEL . '\' &';
	print "     CMD PARAM    : $PARAM\n";
    print "     CMD INFILE   : $inputFolder/$INFILE\n";
	print "     CMD ALL      : $CMD1\n";
	print "        OUT FASTA : $OUTFILEF\n";
	print "        OUT TREE  : $OUTFILET\n";
	print "        OUT STAT  : $OUTFILES\n";
	print "        OUT LOG   : $OUTFILEL\n\n";


    if ( $RUN )
	{
		unlink($OUTFILEF) if ( -f $OUTFILEF );
		unlink($OUTFILET) if ( -f $OUTFILET );
		unlink($OUTFILES) if ( -f $OUTFILES );
		unlink($OUTFILEL) if ( -f $OUTFILEL );

		print "RUNNING: $RUNCMD\n";
		&loopwait($CLUSTAL);
		&runCmd($RUNCMD);
        #print `$RUNCMD`;
	}
}

&loopwait($CLUSTAL, 1);

if ( $makeConsensus )
{
	print "GENERATING CONSENSUS\n";
	foreach my $file ( glob("$outputFolder/*.clustal.fasta") )
	{
		my $outF      = "$file.consensus.fasta";
		my $outFL     = "$outF.log";
		my $consensus = "$consensusProg '$file'";
		my $CMD2 = "$consensus &> '$outFL'";
		print "  FILE  : $file\n";
		print "     CMD: $CMD2\n\n";
		if ( $RUN )
		#if ( 1 )
		{
			unlink ( $outF  ) if ( -f $outF  );
			unlink ( $outFL ) if ( -f $outFL );
			&runCmd($CMD2);
			#print `$CMD2`;
		}
	}
}


exit 0;


sub loopwait
{
	my $program = $_[0];
	my $max     = defined $_[1] ? $_[1] : $MAX;
	my ($total, @pids) = &getProgramTotal($program);

	while (  $total >= $max )   # If no pid, then process is not running.
	{
		sleep $sleepTime;
		($total, @pids) = &getProgramTotal($program);
		print "WAITING $program. $total [" . join(", ", @pids) . "]\n";
		foreach my $pid ( @pids )
		{
			if ( exists $pids{$pid} )
			{
				my $startTime = $pids{$pid};
				my $currTime  = time;
				my $diff = $currTime - $startTime;
				printf "    PID %06d :: %04ds SO FAR\n", $pid, $startTime, $diff;
				if ( $diff > $maxTime )
				{
					printf "    PID %06d LASTED TOO LONG (%04ds). KILLING\n", $pid, $diff;
					`kill $pid`;
					delete $pids{$pid};
				}
			} else {
				$pids{$pid} = time;
			}
		}
		sleep $sleepTime;
	}
}

sub getProgramTotal
{
	my $program = $_[0];
	my $pidnocmd = 'echo -n $( ps ax | grep -v "ps ax" | grep -v grep | grep '.$program.' | awk \'{ print $1 }\' )';
	#print "PIDNOCMD '$pidnocmd'\n";

	my $PIDNO = `$pidnocmd`;
	chomp($PIDNO);
	#print "PIDNO '$PIDNO'\n";

	my $totalcmd = 'echo -n $(echo -n \''.$PIDNO.'\' | wc -w)';
	#print "TOTALCMD $totalcmd\n";

	my $TOTAL = `$totalcmd`;
	chomp($TOTAL);
	#print "TOTAL $TOTAL\n";

	return ($TOTAL, split(/\s+/, $PIDNO));
}

sub runCmd
{
	my $cmd = $_[0];

	open (PIPE, "$cmd |");
	while (<PIPE>) { print };
	close PIPE;
}

#PIDNO=$( ps ax | grep -v "ps ax" | grep -v grep | grep $CLUSTAL | awk '{ print $1 }' )
#while [ -n "$PIDNO" ]   # If no pid, then process is not running.
#do
#  TOTAL=$(echo $PIDNO | wc -w)
#  echo "STILL RUNNING. $TOTAL"
#  sleep 2s
#  PIDNO=$( ps ax | grep -v "ps ax" | grep -v grep | grep $CLUSTAL | awk '{ print $1 }' )
#done
#echo "LEAVING"


#-ALIGN              :do full multiple alignment.
#-TREE               :calculate NJ tree.
#-PIM                :output percent identity matrix (while calculating the tree)
#-BOOTSTRAP(=n)      :bootstrap a NJ tree (n= number of bootstraps; def. = 1000).
#-QUICKTREE   :use FAST algorithm for the alignment guide tree
#-TYPE=       :PROTEIN or DNA sequences
#-NEGATIVE    :protein alignment with negative values in matrix
#-OUTFILE=    :sequence alignment file name
#-OUTPUT=     :GCG, GDE, PHYLIP, PIR or NEXUS
#-QUIET       :Reduce console output to minimum
#-STATS=      :Log some alignents statistics to file
#-PAIRGAP=n   :gap penalty
#-SCORE       :PERCENT or ABSOLUTE
#-PWDNAMATRIX= :DNA weight matrix=IUB, CLUSTALW or filename
#-PWGAPOPEN=f  :gap opening penalty
#-PWGAPEXT=f   :gap opening penalty
#-DNAMATRIX=    :DNA weight matrix=IUB, CLUSTALW or filename
#-GAPOPEN=f     :gap opening penalty
#-GAPEXT=f      :gap extension penalty
#-TYPE=         :PROTEIN or DNA
#-ITERATION=    :NONE or TREE or ALIGNMENT
#-NUMITER=n     :maximum number of iterations to perform
#-CLUSTERING=   :NJ or UPGMA
#-OUTPUTTREE=nj OR phylip OR dist OR nexus
#-NEWTREE=    :file for new guide tree
#-USETREE=    :file for old guide tree
#-ITERATION=    :NONE or TREE or ALIGNMENT

1;
