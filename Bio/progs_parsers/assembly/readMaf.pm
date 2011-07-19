package readMaf;
use strict;
use warnings;
use Set::IntSpan::Fast;
use mem;
#my $hash;

my $skipSynthetic     = 1; #skip synthetic probes
my $skipRef           = 1; #skip reference when searching for gaps
my $skipReads         = 0; #skip reads
my $skipHAF           = 1; #skip HAF tags (alignment quality)

my $printSkips        = 0;
my $printParserResult = 0;
my $printParserSteps  = 0;
my $printParseDb      = 0;
my $printAAO          = 0;
my $printAAOF         = 0;
my $printAAOCluster   = 0;
my $printAAOFCluster  = 0;
my $printGapParser    = 0;
my $printEventsParse  = 0;
my $printMerging      = 0;

#MIN AND MAX NOT WORKING
my $minPK             = undef; # FIRST CHROMOSSOME TO ACTUALLY PARSE
my $maxPK             = undef; # HOW MANY CHROMOSSOMES TO PARSE AFTER THIS

my $pk                = undef; #primary key
my $sp                = undef; #special
my $mapKey            = undef; #map key
my $summaryKey        = undef; #summary key
my $readsKey          = undef; #reads Key
my $eventsKey         = undef; #events Key
my $gapsKey           = undef; #gaps Key
my $coveredKey        = undef; #coveref Key

my @tags              = undef;
my $dash              = undef;
my $zero              = undef;

my %desiredFields;

my %mapKeys = (
    "fastaPos"          => 0,
    "fastaSeq"          => 1,
    "contigPos"         => 2,
    "contigSeq"         => 3,
    "tag"               => 4,
	"tag_end"           => 5,
	"tag_insertion_pos" => 6,
	"tag_insertion_seq" => 7,
    "nd"                => 8,
	"nd_end"            => 9,
    "events"            => 10,
	"events_end"        => 11,
	"events_tags"       => 12
);


sub new
{
    my $class = shift;
    my $self  = bless {}, $class;

    my $iFile  = $_[0];
    my $fFile  = $_[1];
	my $iChrom = $_[2];
    &setup();

	foreach my $key (keys %desiredFields)
	{
		my $value = $desiredFields{$key};
		#print "ANALYZING KEY $key\n";
		if    ( $value->{pk} ) { $pk = $key; }
		elsif ( $value->{sp} ) { $sp = $key; };
	}

	my $mem  = mem->new();						$mem->add("BEFORE");
    my $hash = &readMaf($iFile, $pk, $iChrom);	$mem->add("READ MAF END");
    &parseMafDb($hash);							$mem->add("PARSE DB END");
    &getMaps($hash, $fFile);					$mem->add("GET MAPS END");
    &getMerged($hash);							$mem->add("MERGE END");
	$mem->get();


	if ( ! defined $pk )         { die "PRIMARY KEY NOT DEFINED\n"; };
	if ( ! defined $sp )         { die "SPECIAL KEY NOT DEFINED\n"; };
    if ( ! defined $mapKey )     { die "MAP     KEY NOT DEFINED\n"; };
    if ( ! defined $summaryKey ) { die "SUMMARY KEY NOT DEFINED\n"; };
    if ( ! defined $readsKey )   { die "READS   KEY NOT DEFINED\n"; };
    if ( ! defined $eventsKey )  { die "EVENTS  KEY NOT DEFINED\n"; };
    if ( ! defined $gapsKey )    { die "GAPS    KEY NOT DEFINED\n"; };
    if ( ! defined $coveredKey ) { die "COVERED KEY NOT DEFINED\n"; };

    my %reservedKeys = (
        "map"     => $mapKey,
        "summary" => $summaryKey,
        "reads"   => $readsKey,
        "events"  => $eventsKey,
        "gaps"    => $gapsKey,
        "covered" => $coveredKey
        );

    return ($hash, $pk, $sp, \%reservedKeys, \%mapKeys);
}


############################################
### MERGE DATA
############################################
sub getMerged
{
    my $mafdb = $_[0];
	print "MERGING DATA\n";

	foreach my $contig ( sort keys %$mafdb )
	{
		my $nfo     = $mafdb->{$contig};
		print "\tCHROM $contig\n";

        #TODO : MAKE IT CONSTANTS
        my $events = $mafdb->{$contig}{$eventsKey};
                #$eventsDb{$pS}{start} = $pS;
                #$eventsDb{$pS}{end}   = $pE;
                #$eventsDb{$pS}{tag}   = $ev;
        my $map    = $mafdb->{$contig}{$mapKey};
                #$quimera[$q][$mapKeys{fastaPos}]  = $fastaPos;
                #$quimera[$q][$mapKeys{fastaSeq}]  = $fastaSeq;
                #$quimera[$q][$mapKeys{contigPos}] = $q;
                #$quimera[$q][$mapKeys{contigSeq}] = $contigSeq;
                #$quimera[$q][$mapKeys{tag}]       = $tag;

        my $gapsStr = $mafdb->{$contig}{$gapsKey};
        my $gaps    = &parseGaps($gapsStr);
                #push(@gaps, [$start, $end, $leng]);

        foreach my $gap (@$gaps)
        {
            my $gS = $gap->[0];
            my $gE = $gap->[1];
            my $gL = $gap->[2];

			$map->[$gS][$mapKeys{nd}]     = 1;
			$map->[$gS][$mapKeys{nd_end}] = $gE;
			#print "ADDING ND ($gS $gE $gL)\n";

            #for (my $h = $gS; $h <= $gE; $h++)
            #{
                #print "ADDING ND $h ($gS $gE $gL)\n";
                #$map->[$h][$mapKeys{nd}] = 1;
            #}
        }

        foreach my $e (sort {$a <=> $b} keys %$events)
        {
            my $eS = $events->{$e}{start};
            my $eE = $events->{$e}{end};
            my $eT = $events->{$e}{tag};
			$map->[$eS][$mapKeys{events}]      = 1;
			$map->[$eS][$mapKeys{events_end}]  = $eE;
			$map->[$eS][$mapKeys{events_tags}] = $eT;

            #print "\t\tEVENT :: $e START $eS END $eE TAG $eT\n";
            #for (my $f = $eS-1; $f < $eE; $f++)
            #{
            #    $map->[$f][$mapKeys{events}] = $map->[$f][$mapKeys{events}] ? $map->[$f][$mapKeys{events}] . "," . $eT : $eT;
            #}
        }

        #die;

        if ( $printMerging )
        {
            for (my $pos = 0; $pos < @$map; $pos++)
            {
                my $fastaPos  = $map->[$pos][$mapKeys{fastaPos}];
				my $fastaIPos = $map->[$pos][$mapKeys{tag_insertion_pos}];
                my $fastaSeq  = $map->[$pos][$mapKeys{fastaSeq}];
                my $contigPos = $map->[$pos][$mapKeys{contigPos}];
                my $contigSeq = $map->[$pos][$mapKeys{contigSeq}];
                my $mapTag    = $map->[$pos][$mapKeys{tag}]         || \$zero;
                my $nd        = $map->[$pos][$mapKeys{nd}]          ?  1 : 0;
				my $ndEnd     = $map->[$pos][$mapKeys{nd_end}]      || 0;
                my $event     = $map->[$pos][$mapKeys{events}]      || 0;
				my $eventEnd  = $map->[$pos][$mapKeys{events_end}]  || 0;
				my $eventTags = $map->[$pos][$mapKeys{events_tags}] || '';
                next if (( ! $$mapTag ) && ( ! $nd ) && ( ! $event ));

                printf "\t%7d %7d [%7d]| %s %s | %3s | %s [%7d]| %s [%7d] %s\n",
				$contigPos, $fastaPos, $fastaIPos,
                $$contigSeq, $$fastaSeq,
                ($$mapTag ? $$mapTag : "-"),
                ($nd ? "x" : "-"), $ndEnd,
                ($event ? $event : "-"), $eventEnd, $eventTags;
            }
        }
	} # end foreach my contig

	print "MERGING DATA...DONE\n";
}

############################################
### REAF MAF FILE
############################################
sub readMaf
{
	my $inputFile  = $_[0];
	my $pk         = $_[1];
	my $inputChrom = $_[2];
	my $countPK    = 0;
	my %mafHash;
	my %tmpData;

	print "PARSING FILE $inputFile\n";
	open FILE, "<$inputFile" or die "COULD NOT OPEN FILE $inputFile: $!";

	my $seekPos;
	if ( defined $inputChrom )
	{
		print "SEARCHING FOR POSITION OF CHROMOSSOME $inputChrom\n";
		my @indexes;
		if ( -f "$inputFile.mafindex" )
		{
			open FI, "<$inputFile.mafindex" or die "COULD NOT OPEN $inputFile.mafindex: $!";
			@indexes = <FI>;
			close FI;
		} else {
			@indexes  = `cat $inputFile | grep -bE "^$pk" | perl -ne  's/\015//; print'`;
			open FI, ">$inputFile.mafindex" or die "COULD NOT OPEN $inputFile.mafindex: $!";
			print FI @indexes;
			close FI;
		}

		my $indCount = 0;
		foreach my $index (@indexes)
		{
			$indCount++;
			my $ind = substr($index,0,(index($index, ":")));
			chomp $ind;
			chomp $index;
			printf "\t%03d :: \"%s\" => POS \"%010d\" %s\n", $indCount, $index, $ind, (($indCount == $inputChrom) ? " *" : "");
			if ($indCount == $inputChrom)
			{
				$seekPos = $ind;
				$countPK = $indCount - 1;
			}
		}
	}

	seek(FILE, $seekPos, 0);
	while (my $line = <FILE> )
	{
		chomp $line;
		my $key = substr($line, 0,2);

		#print "KEY \"$key\"\n";
		if ( exists $desiredFields{$key} )
		{
			my $value = substr($line, (index($line, "\t")+1));
			$value    =~ s/\015//;
			chomp $value;

			#print "\tKEY ACCEPTED \"$key\"\n";
			if ( defined $desiredFields{$key}{pk} )
			{
				$countPK++;
				#return \%mafHash if ( $only1st && ( $only1st < $countPK ) );
                if (( defined $maxPK      ) && ( ( $countPK - $minPK ) > $maxPK  ) ) { print "\t\tLASTING\n"; last; };

				print "\tANALYZING [$countPK] \"$value\"\n";

				if (( defined $minPK      ) && (   $countPK            < $minPK  ) ) { print "\t\tNEXTING\n"; next; };
				if (( defined $inputChrom ) && (   $inputChrom         < $countPK) ) { print "\t\tLASTING\n"; last; };
				print "\t\tPARSING\n";
			}

			if ( ( defined $minPK ) && ( $countPK < $minPK ) ) { next; };

			if ( ! defined $inputChrom )
			{
				#print "\t\tPARSING [$countPK] \"$value\"\n";
				my $function = $desiredFields{$key}{func};
				$function->(\%mafHash, \%tmpData, $key, $value);
			} else {
				if ( $inputChrom == $countPK )
				{
					#print "\t\tPARSING [$countPK == $inputChrom] \"$value\"\n";
					my $function = $desiredFields{$key}{func};
					$function->(\%mafHash, \%tmpData, $key, $value);
				}
				else
				{
					#print "\t\tSKIPPING [$countPK != $inputChrom] \"$value\"\n";
					next;
				}
			}
		}
	}
	close FILE;
	print "FILE $inputFile PARSED WITH ",(scalar keys %mafHash),"\n";

	return \%mafHash;
}





############################################
### PARSE MAF DB SEARCHING FOR NDS
############################################

sub parseMafDb
{
	my $mafdb = $_[0];
	print "COMPILING DB\n";

	foreach my $contig ( sort keys %$mafdb )
	{
		print "\tCONTIG $contig\n";
        my $nfo        = $mafdb->{$contig};
		my $cSize      = $nfo->{LC}                 || die "NO LENGTH DEFINED FOR CONTIG $contig\n";
        my $ct         = $nfo->{CT};
        my $reads      = $nfo->{$readsKey}          || die "NO READS DEFINED FOR CONTIG $contig\n";
		my $introStart = 0;
        my $introEnd   = $cSize;




        if (( defined $ct ) && ($ct ne ""))
        {
            print "\t\t\tGENERATING EVENTS [",
            (scalar keys %{$mafdb->{$contig}{$eventsKey}} || 0),
            "]\n" if ($printEventsParse);

            print "\t\t\t\tCT :: \"$ct\"\n" if ($printEventsParse);

            my $events     = &parseEvents($ct);

            if (scalar keys %$events)
            {
                if ( ! defined $mafdb->{$contig}{$eventsKey} )
                {
                    $mafdb->{$contig}{$eventsKey} = {};
                }
                my $eventsHash = $mafdb->{$contig}{$eventsKey};
                print "\t\t\t\t\tEVENTS :: ",(scalar keys %$events),"\n";

                map { $eventsHash->{$_} = $events->{$_} } keys %$events;
            }
        }





        my $gaps       = Set::IntSpan::Fast->new();
           $gaps->add($introStart, $introEnd);

		my $sortedReads = &sortByAT($reads);

        my $totalReads = scalar keys %$reads;
		my $tenthReads = int($totalReads / 10);
		my $readsDone  = 1;
		my $countReads = 0;

		$| = 1;
        my $max = 0;

        print "\t\t$cSize bp AND $totalReads READS\n";

		foreach my $read ( @$sortedReads )
		{
            print "..",int(( $readsDone / $tenthReads )*10), "%" if ( ! ( $readsDone++ % $tenthReads ) );

			my $readInfo = $reads->{$read};

			my $ib = $readInfo->{IB};

			if (($skipSynthetic) && ($read =~ /rr_####\d+####/))
			{
				if($printSkips) { print "\t\t\tSKIPPING READ $read\n" };
				next;
			}

			if (($skipReads) && ($read !~ /rr_####\d+####/))
			{
				if($printSkips) { print "\t\t\tSKIPPING READ $read\n" };
				next;
			}

			if (($skipRef) && ( $ib ))
			{
				if($printSkips) { print "\t\t\tSKIPPING READ $read\n" };
				next;
			};
			#print "\t\tPARSING READ $read\n";

			my $at = $readInfo->{AT} || die "NO AT DEFINE TO CONTIG $contig READ $read\n";
			my $ao = $readInfo->{AO}; # alignment to original
            #my $rt = $readInfo->{RT}; # read tag

			my $posPairs   = &parseAo($ao, $at);
            #print "\t\t\tPAIRS :: ", scalar @$posPairs, "\n";

			foreach my $posPair ( sort {$a->[0] <=> $b->[0]} @$posPairs)
			{
				my $pairStart  = $posPair->[0];
				my $pairEnd    = $posPair->[1];

				printf "\t\t\tPAIR %5d/%5d | START %8d END %8d LENG %8d [MAX %6d]\n",
				$countReads++, $totalReads, $pairStart, $pairEnd,
                ($pairEnd - $pairStart - 1), $cSize
                if ( $printParserSteps );

				#die "END ($pairEnd) BIGGER THEN ORIGINAL SEQUENCE SIZE ($cSize)" if ($pairEnd-1 > $cSize);
				$gaps->add_range($pairStart,$pairEnd);
                $max = $pairEnd if ($pairEnd > $max);
			}

			printf "\t\t%-60s AT \"%8d %8d %8d %8d\" IB \"%d\" RT \"%s\"\n",
                $read, split(" ",$at), ($ib||0), ($readInfo->{RT}||'') if ($printParseDb);
		}
		print "\n";
		$| = 0;

		my $comp = $gaps->complement();
		$comp->remove_range(($introEnd+1)           , $comp->POSITIVE_INFINITY-1);
		$comp->remove_range($comp->NEGATIVE_INFINITY, 0);
		$gaps->remove_range($introEnd               , $introEnd+1);
        $gaps->remove_range($introEnd+1             , $max) if ($max > $introEnd+1);

		$nfo->{$coveredKey} = $gaps->as_string();
		$nfo->{$gapsKey}    = $comp->as_string();

        if ( $printParserResult )
		{
			print "\t\tSPAN: \n";
			map { print "\t\t\t$_\n" } split(",", $nfo->{$coveredKey});
			print "\t\tGAPS: \n";
			map { print "\t\t\t$_\n" } split(",", $nfo->{$gapsKey});
		}
    }
}




############################################
### MAP CONTIG TO FASTA
############################################

sub getMaps
{
	my $mafdb      = $_[0];
	my $fastaM     = $_[1];
	print "GENERATING MAPS\n";

	foreach my $contig ( sort keys %$mafdb )
	{
		print "\tCHROM $contig\n";
		my $nfo       = $mafdb->{$contig};
		my $currChrom = $fastaM->readFasta($contig);

        #TODO : MAKE IT CONSTANTS
        my $map                    = &getMap($nfo->{R_AO}, $nfo->{R_AT}, \$nfo->{CS}, $currChrom);
        $mafdb->{$contig}{$mapKey} = $map;

	} # end foreach my contig

	print "GENERATING MAPS...DONE\n";
}

sub getMap
{
	my ($ao, $at, $contigSeqStr, $fastaSeq) = @_;

	#my @contigSeq = split('', $$contigSeqStr);
    my $contigSeqLength = length $$contigSeqStr;
    my $fastaSeqLength  = scalar @$fastaSeq;
    my $max = ($fastaSeqLength > $contigSeqLength) ? $fastaSeqLength : $contigSeqLength;

	print "\tMAPPING\n";
	print "\t\tCONTIG : ", $contigSeqLength, "\n";
	print "\t\tFASTA  : ", $fastaSeqLength , "\n";

	my @ao      = split(";",$ao);

	my @at      = split(" ", $at);
	my $atStart = $at[0];
	my $atEnd   = $at[1];
	if ($atEnd < $atStart) { my $atmp = $atEnd; $atEnd = $atStart; $atStart = $atmp; };

	my @quimera;

	for (my $f = 0; $f < $fastaSeqLength; $f++)
	{
		$quimera[$f][$mapKeys{fastaPos}] = $f + 1;
		$quimera[$f][$mapKeys{fastaSeq}] = \$fastaSeq->[$f];
	}

	my $lastEnd = 1;
	my @aDiff;
	foreach (my $a = 0; $a < @ao; $a++)
	{
		my @aa = split(" ", $ao[$a]);
		my $aS = $aa[0];
		my $aE = $aa[1];

		if (($aS - $lastEnd) != 0)
		{
			push(@aDiff, [$lastEnd+1, $aS-1]);
		}
		$lastEnd = $aE;
	}


	for (my $a = 0; $a < @aDiff; $a++)
	{
		my $aS   = $aDiff[$a][0];
		my $aE   = $aDiff[$a][1];
		my $diff = ($aE-$aS) + 1;
		next if ($diff == 0);

		for (my $b = $aS; $b <= $aE; $b++)
		{
			splice @quimera, $b-1, 0, [];
		}
	}

	map { splice @quimera, $_, 0, []; } (0..$atStart-2);



	#for ( my $s = scalar @$fastaSeq; $s < $max; $s++) { splice @quimera, $s, 0, {} };

	my $size   = 100;
	my $format = "%7s : %7d %-s %7d\n";

	my $lastFastaPos  = 0;
	my $lastFastaPosQ = 0;
	my $lastFastaPosT = '';
	for (my $q = 0; $q < $contigSeqLength; $q++)
	{
		my $fastaPos      = $quimera[$q][$mapKeys{fastaPos}] || -1;
		my $fastaSeq      = $quimera[$q][$mapKeys{fastaSeq}] || \$dash;
		my $contigSeq     = substr($$contigSeqStr, $q, 1)    || "*";

		my $tag;
		if    ( $contigSeq eq $$fastaSeq)                  { }#next }
		elsif (($contigSeq eq "*") && ($$fastaSeq eq "-")) { $tag = \$tags[0]; }
		elsif (($contigSeq eq "*") && ($$fastaSeq ne "-")) { $tag = \$tags[1]; }
		elsif (($contigSeq ne "*") && ($$fastaSeq eq "-")) { $tag = \$tags[2]; }
		elsif ( $contigSeq ne $$fastaSeq )                 { $tag = \$tags[3]; }

		my @lArray;
		$lArray[$mapKeys{fastaPos}]          = $fastaPos;
		$lArray[$mapKeys{tag_insertion_pos}] = $lastFastaPos + 1;
		$lArray[$mapKeys{fastaSeq}]          = $fastaSeq;
		$lArray[$mapKeys{contigPos}]         = $q +1;
		$lArray[$mapKeys{contigSeq}]         = \$contigSeq;
		$quimera[$q]                         = \@lArray;

		if ( ! $tag )
		{
			$lastFastaPos  = $fastaPos;
			$lastFastaPosQ = $q;
			#$quimeraQ      = \@lArray;
		}
		else
		{
			#print "FASTA POS ", $fastaPos, " => [$q] ",$lastFastaPosQ," (C $contigSeq F ", $$fastaSeq, ")\n";
			if ( $lastFastaPosT )
			{
				if ( $tag == $lastFastaPosT )
				{
					# if the same tag in a row
					my $lastLArray = $quimera[$lastFastaPosQ];
					if ( defined ${$lastLArray}[$mapKeys{tag_insertion_seq}] )
					{
						#print "\t!!! INCREMENTING Q $q TAG ",$$tag," SEQ $contigSeq\n";
						$lastLArray->[$mapKeys{tag_insertion_seq}] .= $contigSeq;
						$lastLArray->[$mapKeys{tag_end}]            = $q+1;
					} else {
						#print "\t!!! CREATING Q $q TAG ",$$tag," SEQ $contigSeq FIRST ",${$lastLArray->[$mapKeys{contigSeq}]},"\n";
						$lastLArray->[$mapKeys{tag_insertion_seq}]  = ${$lastLArray->[$mapKeys{contigSeq}]};
						$lastLArray->[$mapKeys{tag_insertion_seq}] .= $contigSeq;
						$lastLArray->[$mapKeys{tag_end}]            = $q+1;
					}

				} else {
					# if first time tag appears
					#print "\t!!! IGNORING Q $q TAG ",$$tag," SEQ $contigSeq\n";
					$lastFastaPosQ                   = $q;
					#$lArray[$mapKeys{tag_insertion_seq}] .= $contigSeq;
					#$quimera[$q]                     = \@lArray;
					$lArray[$mapKeys{tag}]           = $tag;
					$lArray[$mapKeys{tag_end}]       = $q;
				}
				#$quimeraQ              = \@lArray;
			} else {
				#if first tag after a while
				#print "\t!!! NO IDEA Q $q TAG ",$$tag," SEQ $contigSeq\n";
				$lastFastaPosQ                   = $q;
				#$lArray[$mapKeys{tag_insertion_seq}] .= $contigSeq;
				#$quimera[$q]                     = \@lArray;
				$lArray[$mapKeys{tag}]           = $tag;
				$lArray[$mapKeys{tag_end}]       = $q;
			}

		}

		$lastFastaPosT = $tag;

		#printf "Q %7d F_POS \'%7d\' F_SEQ \'%1s\' L_F_POS \'%7d\' L_F_POS_Q \'%7d\' C_POS \'%7d\' C_SEQ \'%1s\' TAG \'%3s\' L_TAG \'%3s\' \n",
		#          $q, $fastaPos, $$fastaSeq, $lastFastaPos, $lastFastaPosQ, ($q+1), $contigSeq, ($tag ? $$tag : '-'), ($lastFastaPosT ? $$lastFastaPosT : '-');

		#$lastFastaPosQ = $q;


		#printf "    %7d %7d | %1s %1s | TAG %s\n", $q, $fastaPos, $contigSeq, $fastaSeq, $tag;
	}

	print "\tMAPPING...DONE  [",scalar @quimera,"]\n";
	return \@quimera;
}



#
#NO MAP
#	PROCESS ./maf2nd.pl [20388]:: top -b -n 1 | grep 20388 : BEFORE         : 20388 saulo     20   0  127m 4212 2016 S  0.0  0.1   0:00.60 maf2nd.pl
#	PROCESS ./maf2nd.pl [20388]:: top -b -n 1 | grep 20388 : READ MAF END   : 20388 saulo     20   0  200m  77m 2016 S  0.0  1.0   1:54.18 maf2nd.pl
#	PROCESS ./maf2nd.pl [20388]:: top -b -n 1 | grep 20388 : PARSE DB END   : 20388 saulo     20   0  226m 102m 2080 S  0.0  1.3   1:56.65 maf2nd.pl
#	PROCESS ./maf2nd.pl [20388]:: top -b -n 1 | grep 20388 : GET MAPS END   : 20388 saulo     20   0  336m 212m 2080 S 11.8  2.6   1:57.35 maf2nd.pl
#	PROCESS ./maf2nd.pl [20388]:: top -b -n 1 | grep 20388 : GET EVENTS END : 20388 saulo     20   0  336m 212m 2080 S  0.0  2.6   1:57.37 maf2nd.pl
#	PROCESS ./maf2nd.pl [20388]:: top -b -n 1 | grep 20388 : MERGE END      : 20388 saulo     20   0  366m 242m 2080 S  0.0  3.0   1:57.71 maf2nd.pl
#MAP NO SAVE
#	PROCESS ./maf2nd.pl [16660]:: top -b -n 1 | grep 16660 : BEFORE         : 16660 saulo     20   0  127m 4216 2016 S  0.0  0.1   0:00.59 maf2nd.pl
#	PROCESS ./maf2nd.pl [16660]:: top -b -n 1 | grep 16660 : READ MAF END   : 16660 saulo     20   0  200m  77m 2016 S  0.0  1.0   1:54.14 maf2nd.pl
#	PROCESS ./maf2nd.pl [16660]:: top -b -n 1 | grep 16660 : PARSE DB END   : 16660 saulo     20   0  226m 102m 2080 S  0.0  1.3   1:56.63 maf2nd.pl
#	PROCESS ./maf2nd.pl [16660]:: top -b -n 1 | grep 16660 : GET MAPS END   : 16660 saulo     20   0 1009m 886m 2080 S 62.6 11.0   2:06.21 maf2nd.pl
#	PROCESS ./maf2nd.pl [16660]:: top -b -n 1 | grep 16660 : GET EVENTS END : 16660 saulo     20   0 1009m 886m 2080 S  0.0 11.0   2:06.25 maf2nd.pl
#	PROCESS ./maf2nd.pl [16660]:: top -b -n 1 | grep 16660 : MERGE END      : 16660 saulo     20   0 1039m 916m 2080 S  5.9 11.4   2:06.72 maf2nd.pl
#MAPPING
#	PROCESS ./maf2nd.pl [25906]:: top -b -n 1 | grep 25906 : BEFORE         : 25906 saulo     20   0  127m 4220 2016 S  0.0  0.1   0:00.58 maf2nd.pl
#	PROCESS ./maf2nd.pl [25906]:: top -b -n 1 | grep 25906 : READ MAF END   : 25906 saulo     20   0  200m  77m 2016 S  0.0  1.0   1:54.24 maf2nd.pl
#	PROCESS ./maf2nd.pl [25906]:: top -b -n 1 | grep 25906 : PARSE DB END   : 25906 saulo     20   0  226m 102m 2080 S  0.0  1.3   1:56.74 maf2nd.pl
#	PROCESS ./maf2nd.pl [25906]:: top -b -n 1 | grep 25906 : GET MAPS END   : 25906 saulo     20   0 1025m 902m 2080 S  0.0 11.2   2:04.99 maf2nd.pl
#	PROCESS ./maf2nd.pl [25906]:: top -b -n 1 | grep 25906 : GET EVENTS END : 25906 saulo     20   0 1026m 902m 2080 S  0.0 11.2   2:05.02 maf2nd.pl
#	PROCESS ./maf2nd.pl [25906]:: top -b -n 1 | grep 25906 : MERGE END      : 25906 saulo     20   0 1040m 916m 2080 S  0.0 11.4   2:05.21 maf2nd.pl
#MAPPING NO ADD TAG - FASTA REF
#	PROCESS ./maf2nd.pl [30476]:: top -b -n 1 | grep 30476 : BEFORE         : 30476 saulo     20   0  127m 4204 2016 S  0.0  0.1   0:00.59 maf2nd.pl
#	PROCESS ./maf2nd.pl [30476]:: top -b -n 1 | grep 30476 : READ MAF END   : 30476 saulo     20   0  200m  77m 2016 S  0.0  1.0   1:54.17 maf2nd.pl
#	PROCESS ./maf2nd.pl [30476]:: top -b -n 1 | grep 30476 : PARSE DB END   : 30476 saulo     20   0  226m 102m 2080 S  0.0  1.3   1:56.66 maf2nd.pl
#	PROCESS ./maf2nd.pl [30476]:: top -b -n 1 | grep 30476 : GET MAPS END   : 30476 saulo     20   0  757m 633m 2080 S  0.0  7.9   2:01.43 maf2nd.pl
#	PROCESS ./maf2nd.pl [30476]:: top -b -n 1 | grep 30476 : GET EVENTS END : 30476 saulo     20   0  757m 634m 2080 S  0.0  7.9   2:01.45 maf2nd.pl
#	PROCESS ./maf2nd.pl [30476]:: top -b -n 1 | grep 30476 : MERGE END      : 30476 saulo     20   0  772m 648m 2080 S  0.0  8.0   2:01.63 maf2nd.pl
#MAPPING NO ADD TAG - FASTA NO REF
    #PROCESS ./maf2nd.pl [1611]:: top -b -n 1 | grep 1611 : BEFORE         :  1611 saulo     20   0  127m 4204 2016 S  0.0  0.1   0:00.59 maf2nd.pl
    #PROCESS ./maf2nd.pl [1611]:: top -b -n 1 | grep 1611 : READ MAF END   :  1611 saulo     20   0  200m  77m 2016 S  0.0  1.0   1:54.41 maf2nd.pl
    #PROCESS ./maf2nd.pl [1611]:: top -b -n 1 | grep 1611 : PARSE DB END   :  1611 saulo     20   0  226m 102m 2080 S  0.0  1.3   1:56.91 maf2nd.pl
    #PROCESS ./maf2nd.pl [1611]:: top -b -n 1 | grep 1611 : GET MAPS END   :  1611 saulo     20   0  850m 726m 2080 S 11.8  9.0   2:01.88 maf2nd.pl
    #PROCESS ./maf2nd.pl [1611]:: top -b -n 1 | grep 1611 : GET EVENTS END :  1611 saulo     20   0  850m 726m 2080 S  0.0  9.0   2:01.90 maf2nd.pl
    #PROCESS ./maf2nd.pl [1611]:: top -b -n 1 | grep 1611 : MERGE END      :  1611 saulo     20   0  850m 726m 2080 S  0.0  9.0   2:02.11 maf2nd.pl
#MAPPING NO ADD TAG - FASTA REF NO CONTIG
    #PROCESS ./maf2nd.pl [5179]:: top -b -n 1 | grep 5179 : BEFORE         :  5179 saulo     20   0  127m 4208 2016 S  0.0  0.1   0:00.59 maf2nd.pl
    #PROCESS ./maf2nd.pl [5179]:: top -b -n 1 | grep 5179 : READ MAF END   :  5179 saulo     20   0  200m  77m 2016 S  0.0  1.0   1:54.15 maf2nd.pl
    #PROCESS ./maf2nd.pl [5179]:: top -b -n 1 | grep 5179 : PARSE DB END   :  5179 saulo     20   0  226m 102m 2080 S  0.0  1.3   1:56.64 maf2nd.pl
    #PROCESS ./maf2nd.pl [5179]:: top -b -n 1 | grep 5179 : GET MAPS END   :  5179 saulo     20   0  757m 633m 2080 S  0.0  7.9   2:03.03 maf2nd.pl
    #PROCESS ./maf2nd.pl [5179]:: top -b -n 1 | grep 5179 : GET EVENTS END :  5179 saulo     20   0  757m 634m 2080 S  0.0  7.9   2:03.05 maf2nd.pl
    #PROCESS ./maf2nd.pl [5179]:: top -b -n 1 | grep 5179 : MERGE END      :  5179 saulo     20   0  772m 648m 2080 S  0.0  8.0   2:03.24 maf2nd.pl
#MAPPING NO ADD TAG - FASTA REF NO CONTIG - RE FASTA
    #PROCESS ./maf2nd.pl [10893]:: top -b -n 1 | grep 10893 : BEFORE         : 10893 saulo     20   0  127m 4204 2016 S  0.0  0.1   0:00.59 maf2nd.pl
    #PROCESS ./maf2nd.pl [10893]:: top -b -n 1 | grep 10893 : READ MAF END   : 10893 saulo     20   0  200m  77m 2016 S  0.0  1.0   1:54.11 maf2nd.pl
    #PROCESS ./maf2nd.pl [10893]:: top -b -n 1 | grep 10893 : PARSE DB END   : 10893 saulo     20   0  226m 102m 2080 S  0.0  1.3   1:56.60 maf2nd.pl
    #PROCESS ./maf2nd.pl [10893]:: top -b -n 1 | grep 10893 : GET MAPS END   : 10893 saulo     20   0  792m 669m 2080 S  0.0  8.3   2:03.82 maf2nd.pl
    #PROCESS ./maf2nd.pl [10893]:: top -b -n 1 | grep 10893 : GET EVENTS END : 10893 saulo     20   0  793m 669m 2080 S  0.0  8.3   2:03.85 maf2nd.pl
    #PROCESS ./maf2nd.pl [10893]:: top -b -n 1 | grep 10893 : MERGE END      : 10893 saulo     20   0  807m 683m 2080 S  0.0  8.5   2:04.03 maf2nd.pl
#MAPPING - ARRAY
    #PROCESS ./maf2nd.pl [32505]:: top -b -n 1 | grep 32505 : BEFORE         : 32505 saulo     20   0  127m 4216 2016 S  0.0  0.1   0:00.59 maf2nd.pl
    #PROCESS ./maf2nd.pl [32505]:: top -b -n 1 | grep 32505 : READ MAF END   : 32505 saulo     20   0  200m  77m 2016 S  0.0  1.0   1:54.23 maf2nd.pl
    #PROCESS ./maf2nd.pl [32505]:: top -b -n 1 | grep 32505 : PARSE DB END   : 32505 saulo     20   0  226m 102m 2080 S  0.0  1.3   1:56.72 maf2nd.pl
    #PROCESS ./maf2nd.pl [32505]:: top -b -n 1 | grep 32505 : GET MAPS END   : 32505 saulo     20   0  876m 752m 2080 S  0.0  9.3   2:04.87 maf2nd.pl
    #PROCESS ./maf2nd.pl [32505]:: top -b -n 1 | grep 32505 : GET EVENTS END : 32505 saulo     20   0  876m 752m 2080 S  0.0  9.3   2:04.89 maf2nd.pl
    #PROCESS ./maf2nd.pl [32505]:: top -b -n 1 | grep 32505 : MERGE END      : 32505 saulo     20   0  888m 764m 2080 S  0.0  9.5   2:05.11 maf2nd.pl
#MAPPING - ARRAY
    #PROCESS ./maf2nd.pl [29389]:: top -b -n 1 | grep 29389 : BEFORE         : 29389 saulo     20   0  127m 4224 2016 S  0.0  0.1   0:00.59 maf2nd.pl
    #PROCESS ./maf2nd.pl [29389]:: top -b -n 1 | grep 29389 : READ MAF END   : 29389 saulo     20   0  200m  77m 2016 S  0.0  1.0   1:54.94 maf2nd.pl
    #PROCESS ./maf2nd.pl [29389]:: top -b -n 1 | grep 29389 : PARSE DB END   : 29389 saulo     20   0  226m 102m 2080 S  0.0  1.3   1:57.45 maf2nd.pl
    #PROCESS ./maf2nd.pl [29389]:: top -b -n 1 | grep 29389 : GET MAPS END   : 29389 saulo     20   0  876m 752m 2080 S  0.0  9.3   2:07.05 maf2nd.pl
    #PROCESS ./maf2nd.pl [29389]:: top -b -n 1 | grep 29389 : GET EVENTS END : 29389 saulo     20   0  876m 752m 2080 S  0.0  9.3   2:07.07 maf2nd.pl
    #PROCESS ./maf2nd.pl [29389]:: top -b -n 1 | grep 29389 : MERGE END      : 29389 saulo     20   0  888m 764m 2080 S  0.0  9.5   2:07.30 maf2nd.pl




#sub printAlignment
#{
#	my ($map, $contigSeqStr, $fastaSeq) = @_;
#
#	my @contigSeq = split('', $$contigSeqStr);
#
#
#	print "PRINTING ALIGNTMENT\n";
#	print "\tCONTIG  : ", scalar @contigSeq  , "\n";
#	print "\tFASTA   : ", scalar @$fastaSeq  , "\n";
#	print "\tMAP     : ", scalar @$map       , "\n";
#
#	while (scalar @contigSeq < @$map) { push(@contigSeq, "-")};
#
#	my $size   = 100;
#	my $format = "%7s : %7d %-s %7d\n";
#	for (my $s = 0; $s <= @$map; $s+=$size)
#	{
#		my $sizeF = $size;
#		while ($s+$sizeF >= @$map) { $sizeF--; };
#
#		my $fastaLine = "";
#		#join('',@{$fastaSeq}[$s..$s+$sizeF-1])
#		for (my $f = $s; $f<$s+$sizeF; $f++)
#		{
#			my $fPos  = $map->[$f][$mapKeys{fastaPos}];
#			my $fBase = $fPos == -1 ? "-" : $fastaSeq->[$fPos];
#			$fastaLine .= $fBase;
#		}
#
#		printf $format, "CONTIG", $s+1, join('',@contigSeq[  $s..$s+$sizeF-1]), $s+$sizeF;
#		printf $format, "FASTA",  $s+1, $fastaLine                            , $s+$sizeF;
#		#last if $s >= 300;
#		print "\n";
#	}
#
#	print "PRINTING ALIGNTMENT...DONE\n";
#}












#=========================================
#== TOOLKIT READ MAF
#=========================================


sub saveLine
{
	my ($hash, $tmpHash, $key, $value) = @_;

	#print "KEY SAVE LINE $key\n";
	my $treatment1 = $desiredFields{$key}{trea1};
	my $treatment2 = $desiredFields{$key}{trea2};
	if ( defined $treatment1 && defined $treatment2 )
	{
		#print "APPLYING TREATMENT $treatment1 >> $treatment2\n";
		$value =~ s/$treatment1/$treatment2/g;
	}

	if ($desiredFields{$key}{rese})
	{
		$tmpHash->{$key} .= $value . "\n";
	} else {
		$tmpHash->{$key}  = $value . "\n";
	}

	#print "ADDING KEY $key => $value\n";

}

sub saveData
{
	my ($hash, $tmpHash, $key, $value) = @_;

	$tmpHash->{$key} .= $value;

	&storeValue($hash, $tmpHash);

	foreach my $key (keys %$tmpHash)
	{
		if ($desiredFields{$key}{rese})
		{
			#print "CLEANING ", $desiredFields{$key}{desc}, "\n";
			$tmpHash->{$key} = undef;
		}
	}
}

sub saveSeq
{
	my ($hash, $tmpHash,$key, $value) = @_;

	#print "EXTRACTING SIZE:\n";
	my $sValue      = $value;
	my $readStarPos = '';
	if (index($sValue, "*") != -1)
	{
		while ( $sValue =~ /\*/xg )
		{
			$readStarPos .= "," if ( defined $readStarPos);
			$readStarPos .= pos($sValue) - 1;
		}
		$sValue =~ s/\*//g;
	} else {
		$readStarPos = '';
	}

	$tmpHash->{$key}              = $value;
	$tmpHash->{$key."_Leng"}      = length $value;
	$tmpHash->{$key."_LengSmall"} = length $sValue;
	$tmpHash->{$key."_StarPos"}   = $readStarPos;
}


sub storeValue
{
	my $hash    = $_[0];
	my $tmpHash = $_[1];

	#print "STORING:\n";

	my $pk;
    my $sp;
	my $sk;
    my %always;

	foreach my $key (keys %desiredFields)
	{
		my $value = $desiredFields{$key};
		chomp $value;
		#print "ANALYZING KEY $key\n";
		if    ($value->{pk})   { $pk           = $key; }
		elsif ($value->{sp})   { $sp           = $key; }
		elsif ($value->{sk})   { $sk           = $key; }
		elsif ($value->{alwa}) { $always{$key} = 1; }
	}

	if ( ! defined $pk )   { die "PRIMARY KEY NOT DEFINED\n";   };
	if ( ! defined $sk )   { die "SECUNDARY KEY NOT DEFINED\n";  };
	if ( ! defined $sp )   { die "SPECIAL KEY NOT DEFINED\n"; };


	if ( ! defined $tmpHash->{$pk}   ) { map { print "$_ => ",substr($tmpHash->{$_}, 0,80),"\n";} keys %$tmpHash; die "PRIMARY KEY [$pk] NOT FOUND";   }
	#if ( ! defined $tmpHash->{$sk}   ) { map { print "$_ => ",substr($tmpHash->{$_}, 0,80),"\n";} keys %$tmpHash; die "SECUNDARY KEY [$sk] NOT FOUND"; }
	if ( ! defined $tmpHash->{$sk}   ) { map { print "$_ => ",substr($tmpHash->{$_}, 0,80),"\n";} keys %$tmpHash; die "SECUNDARY KEY [$sk] NOT FOUND";  }

	foreach my $key (sort keys %$tmpHash)
	{
		my $value = $tmpHash->{$key} || '';
		#$value    = substr($value, 1, 80) if (length $value > 80);
		chomp $value;
		$value    =~ s/\n/\;/g;

		my $valueShort = ((length $value > 80 ) ? substr($value, 1, 80) : $value);
		my $pkValue    = $tmpHash->{$pk};
		my $skValue    = $tmpHash->{$sk};
		chomp $pkValue;
		chomp $skValue;

		#print "\t", $key, " => ",$valueShort,"\n";

        if ( $desiredFields{$key}{glob} ) #if global save once
        {
            if ( ! defined ${$hash->{$pkValue}}{$key} )
            {
                $hash->{$pkValue}{$key} = $value;
                #print "\t\tADDING MAIN      ", $pkValue, "=>$key=$valueShort\n";
            }
        }
        else # if not global
        {
            if ( ( exists $always{$key} ) && ( ! $tmpHash->{$sp}) ) # if always saved
            {
                $hash->{$pkValue}{$readsKey}{$skValue}{$key} = $value;
                #print "\t\tADDING SPEC SEC  ", $pkValue, "=>READS->$skValue->$key=$valueShort\n";
            }
            else # if not always saved
            {
                if ( $tmpHash->{$sp} ) # if special (special key) IB
                {
                    my $ind = index($key,"_");
                    if ( $ind == -1)
                    {
                        $hash->{$pkValue}{"R_".$key}                 = $value;
                        $hash->{$pkValue}{$readsKey}{$skValue}{$key} = $value;
                        #print "\t\tADDING IB        ", $pkValue, "=>R_$key=$valueShort\n";
                    }
                    else
                    {
                        my $k = substr($key, 0, $ind);
                        #print "\t\t\tANALYZING K \"$k\"\n";
                        if (( exists $desiredFields{$k} ) && ( exists $desiredFields{$k}{glob} ) && (! $desiredFields{$k}{glob}))
                        {
                            $hash->{$pkValue}{"R_".$key}                 = $value;
                            $hash->{$pkValue}{$readsKey}{$skValue}{$key} = $value;
                            #print "\t\tADDING IB 2      ", $pkValue, "=>R_$key=$valueShort\n";
                        }
                    }
                }
            }
        }
	}
}















#=========================================
#== TOOLKIT PARSE DB
#=========================================

sub parseAo
{
	my $ao      = $_[0];
	my $at      = $_[1];
	my $contig  = $_[2] || 0;
	my @pairs;


	#AO	1 801 1 801
	#AO	803 2023 802 2022
	#ST	Sanger
	#IB	1
	#ER
	#AT	1 2023 1 2023

	#AO	1 102 1 102
	#AT	147 217 16 86

	#AT :: 697 929 1 233
	#	AO ::   1 105   1 105
	#		  107 233 106 232
	#
	#		AAO  ::   1 105   1 105 => START   1  END 105
	#		AAOF ::   1 105   1 105 => START 697  END 801
	#		AAO  :: 107 233 106 232 => START 107  END 233
	#		AAOF :: 107 233 106 232 => START 803  END 929

	my @allAo = split("\n",$ao);
	#print "\tAT :: $at\n";
	#print "\t\tAO :: $ao\n";

	my @at      = split(" ", $at);
	my $atStart = $at[0];
	my $atEnd   = $at[1];

	if ($atEnd < $atStart) { my $atmp = $atEnd; $atEnd = $atStart; $atStart = $atmp; };
	#for (my $a = $aStart; $a < $aEnd; $a++)
	#{
	#	$gaps->insert($a);
	#}
	my $lastEnd = 1;
	my $diff    = 0;
	foreach my $aao (@allAo)
	{
		my @ao       = split(" ", $aao);
		my $aoRStart = $ao[0];
		my $aoREnd   = $ao[1];
		my $aoQStart = $ao[2];
		my $aoQEnd   = $ao[3];
		my $aoStart  = $contig ? $aoRStart : $aoQStart;
		my $aoEnd    = $contig ? $aoREnd   : $aoQEnd;

		if ($aoREnd < $aoRStart)
		{
			my $atmp  = $aoREnd;
			$aoREnd   = $aoRStart;
			$aoRStart = $atmp;
		};

		my $fStart = ($atStart + $aoStart  - 1);
		my $fEnd   = ($atStart + $aoEnd    - 1);
		my $lDiff  =  $fStart  - $lastEnd  - 1;
		   $lDiff  =  $lDiff   < 0 ? 0 : $lDiff;
		   $diff  +=  $lDiff;
		   $diff   =  $diff    < 0 ? 0 : $diff;

		printf "\t\t\tAAO  :: %7d %7d %7d %7d => START %7d END %7d LAST END %7d ($contig)\n",
			@ao, $aoStart, $aoEnd, $lastEnd  if (($printAAO) || ($printAAOCluster && $contig));
		printf "\t\t\tAAOF :: %7d %7d %7d %7d => AT %7d %7d %7d %7d START %7d END %7d | LDIFF %7d DIFF %7d ($contig)\n",
			@ao, $fStart, $fEnd, @at, $lDiff, $diff if (($printAAOF) || ($printAAOFCluster && $contig));

		push(@pairs, [$fStart, $fEnd, $aoQStart, $aoQEnd, $lDiff, $diff]);

		$lastEnd = $fEnd;
	}
	return \@pairs;
}


sub parseEvents
{
    my $eventsStr = $_[0];

    my %eventsDb;
    return \{} if ( ! defined $eventsStr );
    print "\t\t\t\t\tPARSING EVENTS :: $eventsStr\n" if ($printEventsParse);

    #WRMr 59624 59625 :WRMr 59635 59636 :WRMr 60954 60955 :
    my @events = split(";", $eventsStr);

	my $lastEv = '';
	my $lastPE = 0;
	my $lastPS = 0;
    foreach my $event (@events)
    {
        if ($event =~ /(\S+)\s+(\d+)\s+(\d+)\s+(.+)/)
        {
            my $ev   = $1;
            my $pS   = $2 >= $3 ? $3 : $2;
            my $pE   = $2 >= $3 ? $2 : $3;
            my $desc = $4;

            if ($skipHAF && ($ev =~ /^HAF/)) {next};


			my %lHash = (
				"start" => $pS,
				"end"   => $pE,
				"tag"   => $ev,
				"desc"  => $desc
			);

			my $hashKey = $pS;
			if (($ev eq $lastEv) && ($pS == $lastPE+1))
			{
				$eventsDb{$lastPS}{end}   = $pE;
				$eventsDb{$lastPS}{desc} .= ";". $desc;
				$lastPE                   = $pE;
				$hashKey                  = $lastPS;
			} else {
				$eventsDb{$pS} = \%lHash;
				$lastEv = $ev;
				$lastPE = $pE;
				$lastPS = $pS;
			}

			if ($printEventsParse)
			{
				print "\t\t\t\t\t\tEVENT ";
				map { print uc($_), " = \"",$eventsDb{$hashKey}{$_},"\"; "; } reverse sort keys %{$eventsDb{$hashKey}};
				print "\n";
			}
        }
    }
    return \%eventsDb;
}

sub parseGaps
{
	my $gapStr = $_[0];
	my @gaps;

	print "\tPARSING GAP\n";
	my @gapsLines = split(",",$gapStr);
	#map { print "\t\t$_\n" } @gapsLines;
	#print "\t\tGAP \"$gapStr\"\n";
	#return \@gaps if (( index($gapStr, "-") == -1 ) || ($gapStr eq "-"));

	foreach my $stretch (@gapsLines)
	{
		my $start = undef;
		my $end   = undef;
		my $leng  = undef;
		if ( index($stretch, "-") != -1 )
		{
			#print "\tSTRETCH $stretch >> ";
			$start = substr($stretch, 0, index($stretch,"-"));
			$end   = substr($stretch, (index($stretch,"-")+1));
			$leng  = $end - $start;
		} else {
			$start = $stretch;
			$end   = $stretch;
			$leng  = 1;
		}

		die "ERROR PARSING GAP $stretch"
		if ((! defined $start) || (! defined $end) || (! defined $leng));

		printf "\t\tSTART %8d END %8d LENG %8d\n", $start, $end, $leng
        if ($printGapParser);

		push(@gaps, [$start, $end, $leng]);
	}
	#print "\tGAP PARSED\n";
	return \@gaps;
}

sub sortByAT
{
	my $hash = $_[0];
	my %array;

	map {
		my $at = (split(" ", $hash->{$_}{AT}))[0];
		$array{$at} = $_;
		} keys %$hash;

	my @array;
	map {
		push(@array, $array{$_} );
		} sort { $a <=> $b } keys %array;

	return \@array;
}

#
#sub parseAo2
#{
#	my $ao      = $_[0];
#	my $at      = $_[1];
#	my $mapping = $_[2];
#	my $contig  = $_[3] || 0;
#	my @pairs;
#
#
#	#AO	1 801 1 801
#	#AO	803 2023 802 2022
#	#ST	Sanger
#	#IB	1
#	#ER
#	#AT	1 2023 1 2023
#
#	#AO	1 102 1 102
#	#AT	147 217 16 86
#
#	#AT :: 697 929 1 233
#	#	AO ::   1 105   1 105
#	#		  107 233 106 232
#	#
#	#		AAO  ::   1 105   1 105 => START   1  END 105
#	#		AAOF ::   1 105   1 105 => START 697  END 801
#	#		AAO  :: 107 233 106 232 => START 107  END 233
#	#		AAOF :: 107 233 106 232 => START 803  END 929
#
#	my @allAo = split("\n",$ao);
#	#print "\tAT :: $at\n";
#	#print "\t\tAO :: $ao\n";
#
#	my @at      = split(" ", $at);
#	my $atStart = $at[0];
#	my $atEnd   = $at[1];
#
#	if ( ! $contig )
#	{
#		#print "NOT CONTIG\n";
#		$atStart = &posToMappedPos($mapping, $atStart);
#		$atEnd   = &posToMappedPos($mapping, $atEnd);
#		#print "NOT CONTIG DONE\n";
#	}
#
#
#	if ($atEnd < $atStart) { my $atmp = $atEnd; $atEnd = $atStart; $atStart = $atmp; };
#	#for (my $a = $aStart; $a < $aEnd; $a++)
#	#{
#	#	$gaps->insert($a);
#	#}
#	my $lastEnd = 1;
#	my $diff    = 0;
#	foreach my $aao (@allAo)
#	{
#		my @ao       = split(" ", $aao);
#		my $aoRStart = $ao[0];
#		my $aoREnd   = $ao[1];
#		my $aoQStart = $ao[2];
#		my $aoQEnd   = $ao[3];
#		my $aoStart  = $contig ? $aoRStart : $aoQStart;
#		my $aoEnd    = $contig ? $aoREnd   : $aoQEnd;
#
#		if ($aoREnd < $aoRStart)
#		{
#			my $atmp  = $aoREnd;
#			$aoREnd   = $aoRStart;
#			$aoRStart = $atmp;
#		};
#
#		my $fStart = ($atStart + $aoStart  - 1);
#		my $fEnd   = ($atStart + $aoEnd    - 1);
#		my $lDiff  =  $fStart  - $lastEnd  - 1;
#		   $lDiff  =  $lDiff   < 0 ? 0 : $lDiff;
#		   $diff  +=  $lDiff;
#		   $diff   =  $diff    < 0 ? 0 : $diff;
#
#		printf "\t\t\tAAO  :: %7d %7d %7d %7d => START %7d END %7d LAST END %7d ($contig)\n",
#			@ao, $aoStart, $aoEnd, $lastEnd  if (($printAAO) || ($printAAOCluster && $contig));
#		printf "\t\t\tAAOF :: %7d %7d %7d %7d => AT %7d %7d %7d %7d START %7d END %7d | LDIFF %7d DIFF %7d ($contig)\n",
#			@ao, $fStart, $fEnd, @at, $lDiff, $diff if (($printAAOF) || ($printAAOFCluster && $contig));
#
#		push(@pairs, [$fStart, $fEnd, $aoQStart, $aoQEnd, $lDiff, $diff]);
#
#		$lastEnd = $fEnd;
#	}
#	return \@pairs;
#}


#
#
#
#
#sub posToMappedPos
#{
#	my $map       = $_[0];
#	my $pos       = $_[1];
#	my $newPos    = $pos;
#	my $diff      = 0;
#
#	$newPos = $pos;
#	foreach my $s (reverse @{$map->[0]})
#	{
#		if ($pos >= $s)
#		{
#			die "ERROR IN MAPPING" if (( ! defined $map->[1] ) || ( ! exists ${$map->[1]}{$s}));
#			$diff   = $map->[1]{$s};
#			$newPos = $pos - $diff;
#			printf "\tIF   POS %7d S %7d DIFF %7d NEW POS %7d\n",
#			$pos, $s, $diff, $newPos if ($printMappedPosIF);
#			return $newPos;
#		} else {
#			#$lastStart = $s;
#			printf "\tELSE POS %7d S %7d DIFF %7d NEW POS %7d\n",
#			$pos, $s, $diff, $newPos if ($printMappedPosEL);
#		}
#	}
#
#	die "NO NEW POS\n";
#}
#
#sub pairsToMapping
#{
#	my $alnToOrigPairs = $_[0];
#	my $starsPos       = $_[1];
#	my $maxSize        = $_[2];
#	my @map;
#
#	my $lastQEnd = 0;
#	push(@{$map[0]}, 0);
#	$map[1]{0} = 0;
#	$map[2]{0} = 0;
#
#	print "\tMAPPING\n";
#	foreach my $pair( @$alnToOrigPairs )
#	{
#		my $rStart       = $pair->[0];
#		my $rEnd         = $pair->[1];
#		my $qStart       = $pair->[2];
#		my $qEnd         = $pair->[3];
#		my $lDiff        = $pair->[4];
#		my $diff         = $pair->[5];
#
#		printf "\t\tRSTART %7d REND %7d QSTART %7d QEND %7d LAST QEND %7d LDIFF %7d DIFF %7d {%7d = %4d}\n",
#		$rStart, $rEnd, $qStart, $qEnd, $lastQEnd, $lDiff, $diff, $rStart, $diff if ($printPairs2Map);
#
#		die if ( ( ! defined $qEnd ) || ( ! defined $qStart) || ( ! defined $rStart ));
#
#		$lastQEnd        = $qEnd;
#		$map[1]{$rStart} = $diff;
#		$map[2]{$rStart} = $qStart;
#		push(@{$map[0]}, $rStart);
#	}
#
#	#my @poses = split(",", $starsPos);
#	#print "TOTAL STARS :: ", scalar @poses, "\n";
#	#foreach my $pos (@poses)
#	#{
#	#	printf "\t\tSTAR POS START %7d\n", $pos if ($printPairs2Map);
#	#}
#
#	if ($printMapValues)
#	{
#		print "\t\tVALUES\n";
#		map { printf "\t\t\t%7d\n", $_; } @{$map[0]};
#	}
#
#	if ($printMapDiffs)
#	{
#		print "\t\tDIFFS\n";
#		map { printf "\t\t\t%7d => %7d\n", $_, $map[1]{$_} } sort { $a <=> $b } keys %{$map[1]};
#	}
#	print "\tMAPPED\n";
#	return \@map;
#}
#



#sub parseMafDb2
#{
#    my $self  = shift;
#	my $mafdb = $self->{hash};
#	print "COMPILING DB\n";
#	my %maps;
#
#	#$storeHash->{$co}{leng}           = $cl;
#	#$storeHash->{$co}{$readsKey}{$rd}{at} = $at;
#	#$storeHash->{$co}{$readsKey}{$rd}{rt} = $rt;
#
#	foreach my $contig ( sort keys %$mafdb )
#	{
#		print "CONTIG $contig\n";
#		my $nfo           = $mafdb->{$contig};
#		my $cSize         = $nfo->{LC}                 || die "NO LENGTH DEFINED FOR CONTIG $contig\n";
#		my $tSize         = $nfo->{targetLeng}         || die "NO TARGET LENGTH DEFINED FOR CONTIG $contig\n";
#		my $tSizeSeq      = $nfo->{targetSeqLeng}      || die "NO TARGET SEQ LENGTH DEFINED FOR CONTIG $contig\n";
#		my $tSizeSeqSmall = $nfo->{targetSeqLengSmall} || die "NO TARGET SEQ SHORT LENGTH DEFINED FOR CONTIG $contig\n";
#		my $reads         = $nfo->{$readsKey}              || die "NO READS DEFINED FOR CONTIG $contig\n";
#		my $ref           = $nfo->{ref}                || die "NO REFERENCE DEFINED FOR CONTIG $contig\n";
#		my $alnToOrig     = $nfo->{alignToOrig}        || die "NO ALIGNMENT TO ORIGINAL DEFINED FOR CONTIG $contig\n";
#		my $starPos       = $nfo->{starPos}            || die "NO STARS DEFINED FOR CONTIG $contig\n";
#		my $alnAt         = $nfo->{at}                 || die "NO AT DEFINED FOR CONTIG $contig\n";
#
#		printf "\t%s[CONTIG %8dbp | TARGET %8dbp | TARGETSEQ %8dbp | TARGETSEQSMALL %8dbp | AT %s] REF \"%s\"\n",
#		          $contig,  $cSize,        $tSize,           $tSizeSeq,             $tSizeSeqSmall, $ref, $alnAt;
#
#		my $alnToOrigPairs = &parseAo($alnToOrig, $alnAt, undef , 1);
#		my $mapping        = &pairsToMapping($alnToOrigPairs, $starPos, $cSize);
#		$maps{$ref}        = $mapping;
#
#		my $gaps = Set::IntSpan::Fast->new();
#		my $introStart = 0;
#		#TODO: COMPLETELY WRONG !!
#		my $introEnd   = $tSizeSeqSmall; #&posToMappedPos($mapping, $tSizeSeq);
#		print "\tADDING INTRO START $introStart AND INTRO END $introEnd\n";
#
#		$gaps->add($introStart, $introEnd);
#		#$gaps->insert(1);
#		#$gaps->run_list;
#
#		$| = 1;
#		my $totalReads = scalar keys %$reads;
#		my $tenthReads = int($totalReads / 10)+1;
#		my $readsDone  = 0;
#		my $countReads = 0;
#		my $readsT     = scalar keys %$reads;
#
#		my $sortedReads = &sortByAT($reads);
#		#my @sortedReads = keys %$reads;
#
#		foreach my $read ( @$sortedReads )
#		{
#			print "..",(( $readsDone / $tenthReads )*10), "%" if ( ! ( ++$readsDone % $tenthReads ) );
#			#print "." if ( ! ( $readsDone++ % 10 ) );
#			#print ".";
#			my $readInfo = $reads->{$read};
#
#			my $ib = $readInfo->{ib};
#
#			if (($skipSynthetic) && ($read =~ /rr_####\d+####/))
#			{
#				if($printSkips) { print "\t\t\tSKIPPING READ $read\n" };
#				next;
#			}
#
#			if (($skipReads) && ($read !~ /rr_####\d+####/))
#			{
#				if($printSkips) { print "\t\t\tSKIPPING READ $read\n" };
#				next;
#			}
#
#			if (($skipRef) && ( $ib ))
#			{
#				print "IB READ SIZE $cSize REFSIZE $tSize REFERENCE $ref\n";
#				if($printSkips) { print "\t\t\tSKIPPING READ $read\n" };
#				next;
#			};
#			#print "\t\t\tPARSING READ $read\n";
#
#			my $at = $readInfo->{at} || die "NO AT DEFINE TO CONTIG $contig READ $read\n";
#			my $rt = $readInfo->{rt}; # read tag
#			my $ao = $readInfo->{ao}; # alignment to original
#
#			my $posPairs   = &parseAo($ao, $at, $mapping);
#
#			foreach my $posPair ( sort {$a->[0] <=> $b->[0]} @$posPairs)
#			{
#				my $pairStart  = $posPair->[0];
#				my $pairEnd    = $posPair->[1];
#				my $pairStartF = &posToMappedPos($mapping, $pairStart);
#				my $pairEndF   = &posToMappedPos($mapping, $pairEnd);
#				printf "\t\t\tPAIR %5d/%5d | START %8d END %8d STARTF %8d ENDF %8d LENG %8d DIFF %6d [MAX %6d]\n",
#				$countReads++, $readsT, $pairStart, $pairEnd, $pairStartF,
#				$pairEndF, ($pairEnd - $pairStart - 1), ($pairStart - $pairStartF ),
#				$tSizeSeqSmall
#				if ( $printParserSteps );
#
#				die "END ($pairEndF) BIGGER THEN ORIGINAL SEQUENCE SIZE ($tSizeSeqSmall)" if ($pairEndF > $tSizeSeqSmall);
#				$gaps->add_range($pairStartF,$pairEndF);
#				#for (my $a = $pairStart; $a < $pairEnd; $a++)
#				#{
#				#	$gaps->insert(&posToMappedPos($mapping, $a));
#				#}
#			}
#
#			printf "\t\t%-60s AT \"%8d %8d %8d %8d\" IB \"%d\" RT \"%s\"\n",
#				$read, split(" ",$at), ($ib||0), ($rt||'') if ($printParseDb);
#		}
#		print "\n";
#		$| = 0;
#
#		my $comp = $gaps->complement();
#		$comp->remove_range(($introEnd+1)           , $comp->POSITIVE_INFINITY-1);
#		$comp->remove_range($comp->NEGATIVE_INFINITY, 0);
#		$gaps->remove_range($introEnd               , $introEnd+1);
#
#		$nfo->{covered} = $gaps->as_string();
#		$nfo->{gaps}    = $comp->as_string();
#
#		if ( $printParserResult )
#		{
#			print "\t\tSPAN: \n";
#			map { print "\t\t\t$_\n" } split(",", $nfo->{covered});
#			print "\t\tGAPS: \n";
#			map { print "\t\t\t$_\n" } split(",", $nfo->{gaps});
#		}
#	}
#
#
#	print "DB PARSED\n";
#	return \%maps;
#}


#sub parseRt
#{
#	my $rt = $_[0];
#	my $nrt;
#
#	#RT	HAF5 20 31
#	#RT	HAF6 32 44
#	#RT	HAF5 45 53
#	#RT	HAF4 54 54
#	#RT	HAF3 55 56
#	#RT	HAF4 57 61
#	#RT	HAF5 62 72
#
#	foreach my $r (split("\n", $rt))
#	{
#		#print "R: $r\t";
#		if ( $r =~ /\D+\d+\s+(\d+)\s+(\d+)/ )
#		{
#			my $start = $1;
#			my $end   = $2;
#			#print $start, " - ", $end, "\n";
#			if ($nrt ) { $nrt .= ","; };
#			$nrt .= "$start-$end";
#		}
#	}
#
#	return $nrt;
#}






#sub ao2gaps
#{
#	my $ao      = $_[0] || die "NO AO DEFINED";
#	my $at      = $_[1] || die "NO AT DEFINED";
#	my $chrom   = $_[2] || die "NO CHROM DEFINED";
#
#	my @allAo   = split("\n",$ao);
#	my @at      = split(" ", $at);
#
#	my $atStart = $at[0];
#	my $atEnd   = $at[1];
#
#	if ($atEnd < $atStart) { my $atmp = $atEnd; $atEnd = $atStart; $atStart = $atmp; };
#
#	my $gaps = Set::IntSpan::Fast->new();
#	$gaps->add($atStart, $atEnd);
#
#	my $lastEnd = 1;
#	my $diff    = 0;
#	#my @pairs;
#	foreach my $aao (@allAo)
#	{
#		my @ao       = split(" ", $aao);
#		my $aoRStart = $ao[0];
#		my $aoREnd   = $ao[1];
#		my $aoQStart = $ao[2];
#		my $aoQEnd   = $ao[3];
#		my $aoStart  = $aoRStart;
#		my $aoEnd    = $aoREnd;
#
#		if ($aoREnd < $aoRStart)
#		{
#			my $atmp  = $aoREnd;
#			$aoREnd   = $aoRStart;
#			$aoRStart = $atmp;
#		};
#
#		my $fStart = ($atStart + $aoStart  - 1);
#		my $fEnd   = ($atStart + $aoEnd    - 1);
#		my $lDiff  =  $fStart  - $lastEnd  - 1;
#		   $lDiff  =  $lDiff   < 0 ? 0 : $lDiff;
#		   $diff  +=  $lDiff;
#		   $diff   =  $diff    < 0 ? 0 : $diff;
#
#
#
#		printf "\t\t\tAAO  :: %7d %7d %7d %7d => START %7d END %7d LAST END %7d\n",
#			@ao, $aoStart, $aoEnd, $lastEnd  if (($printAAO) || $printAAOCluster);
#		printf "\t\t\tAAOF :: %7d %7d %7d %7d => AT %7d %7d %7d %7d FSTART %7d FEND %7d | LDIFF %7d DIFF %7d\n",
#			#@ao, @at, $fStart, $fEnd, $lDiff, $diff if (1);
#			@ao, $fStart, $fEnd, @at, $lDiff, $diff if (($printAAOF) || ($printAAOFCluster));
#
#		$gaps->add_range($fStart, $fEnd);
#
#		#push(@pairs, [$fStart, $fEnd, $aoQStart, $aoQEnd, $lDiff, $diff]);
#
#		$lastEnd = $fEnd;
#	}
#
#	my $comp = $gaps->complement();
#	#$comp->remove_range(($introEnd+1)           , $comp->POSITIVE_INFINITY-1);
#	$comp->remove_range($comp->NEGATIVE_INFINITY, 0);
#	#$gaps->remove_range($introEnd               , $introEnd+1);
#
#	#print "FILLED :: ", $gaps->as_string, "\n";
#	#print "GAPS   :: ", $gaps->as_string, "\n";
#
#	#$nfo->{covered} = $gaps->as_string();
#	#$nfo->{gaps}    = $comp->as_string();
#	#$gaps->add_range($pairStartF,$pairEndF);
#
#	#return \@pairs;
#	return "IN DEVELOPMENT";
#}

#=========================================
#== TOOLKIT SETUP
#=========================================

sub setup
{
    $mapKey     = "map";
    $summaryKey = "summary";
    $readsKey   = "reads";
    $eventsKey  = "events";
    $gapsKey    = "gaps";
    $coveredKey = "covered";

    @tags       = qw(gap del ins snp);
    $dash       = "-";
	$zero       = "0";

    $desiredFields{CO} = {
        "desc"  => "Contig Name",
        "name"  => "ContigName",
        "func"  => \&saveLine,
        "rese"  => 0, #reset on new contig
        "pk"    => 1, #primary key
        "trea1" => "_bb\$", #re for treatment
        "trea2" => '',      #replacement
        "glob"  => 1        #global
    };

    $desiredFields{LC} = {
        "desc"  => "Contig Length",
        "name"  => "ContigLength",
        "func"  => \&saveLine,
        "rese"  => 0,
        "glob"  => 1
    };

    $desiredFields{CS} = {
        "desc"  => "Contig Sequence",
        "name"  => "ContigSequence",
        "func"  => \&saveSeq,
        "rese"  => 0,
        "glob"  => 1
    };

    $desiredFields{CT} = {
        "desc"  => "Contig Tags",
        "name"  => "ContigTags",
        "func"  => \&saveLine,
        "rese"  => 1,
        "glob"  => 1
    };

    $desiredFields{AT} = {
        "desc"  => "Read Spam",
        "name"  => "ReadSpam",
        "func"  => \&saveData,
        "rese"  => 1,
        "glob"  => 0,
        "alwa"  => 1, #always save
    };

    $desiredFields{RD} = {
        "desc"  => "Read Name",
        "name"  => "ReadName",
        "func"  => \&saveLine,
        "rese"  => 1,
        "sk"    => 1, #secundary key
        "alwa"  => 1  #always save
    };

    $desiredFields{RT} = {
        "desc"  => "Read Tags",
        "name"  => "ReadTags",
        "func"  => \&saveLine,
        "rese"  => 1,
        "alwa"  => 1  #always save
    };

    $desiredFields{LR} = {
        "desc"  => "Read Length",
        "name"  => "ReadLength",
        "func"  => \&saveLine,
        "rese"  => 1,
        "alwa"  => 1  #always save
    };

    $desiredFields{RS} = {
        "desc"  => "Read Sequence",
        "name"  => "ReadSequence",
        "func"  => \&saveSeq,
        "rese"  => 1,
        "alwa"  => 0  # 1 always save 0 saves only on IB
    };

    $desiredFields{AO} = {
        "desc"  => "Alignment to Original",
        "name"  => "AlignmentToOriginal",
        "func"  => \&saveLine,
        "rese"  => 1,
        "alwa"  => 1  #always save
    };

    $desiredFields{IB} = {
        "desc"  => "Is BackBone",
        "name"  => "IsBackBone",
        "func"  => \&saveLine,
        "rese"  => 1,
        "sp"    => 1, # special key
        "alwa"  => 1  #always save
    };

}

1;
