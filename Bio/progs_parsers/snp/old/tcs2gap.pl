#!/usr/bin/perl -w
use strict;

if ( @ARGV != 2 ) { die "NO INPUT GIVEN :: USAGE: <INPUT FASTA> <INPUT TCS>" };

my $inFast = $ARGV[0];
my $inTcsF = $ARGV[1];


if ( ! -f $inFast ) { die "INPUT FASTA DOESNT EXISTS" }
if ( ! -f $inTcsF ) { die "INPUT TCS   DOESNT EXISTS" }

if ( ! $inFast =~ /\.fasta$/i ) { die "INPUT FASTA NOT ENDING IN .FASTA" };
if ( ! $inTcsF =~ /\.tcs$/i   ) { die "INPUT TCS   NOT ENDING IN .TCS"   };


my @names;
$names[0]{name}   = "REF";
$names[0]{file}   = $inFast;
$names[0]{parser} = \&loadFasta;

$names[1]{name}   = "TCS";
$names[1]{file}   = $inTcsF;
$names[1]{parser} = \&loadTcs;

my %nfo;

for (my $n = 0; $n < @names; $n++)
{
    next if ( ! defined $names[$n] );
    my $name   = exists ${$names[$n]}{name}   ? $names[$n]{name}   : '';
    my $parser = exists ${$names[$n]}{parser} ? $names[$n]{parser} : '';
    my $file   = exists ${$names[$n]}{file}   ? $names[$n]{file}   : '';
    next if (( ! $name ) || ( ! $parser ) || ( ! $file ));
    $parser->($file, \%nfo, $n);
}

&printHash(\%nfo, \@names);


sub loadTcs
{
    my $inFile    = $_[0];
    my $hash      = $_[1];
    my $pos       = $_[2];
    my $countLine = 0;
    my $countSnp  = 0;
    my %summary;
    print "LOADING TCS FILE $inFile\n";

    $|++;
    open TCS, "<$inFile" or die "COULD NOT OPEN QUALITY FILE";
    while ( my $line = <TCS> )
    {
        chomp $line;
        next if (index($line, "#") == 0);

        $line =~ s/[^a-zA-z0-9._]//;
        $line =~ s/_bb//;

        if ($line =~ /^(\S+)\s+(\d+)/)
        {
            my $seqName = $1;
            $summary{$seqName}{all}++;
            $countLine++;
            $hash->{$seqName}[$pos][$2] = [];

            if ( ! $line =~ /\!/ ) { next };

            #supercontig_1.01_of_Cryptococcus_neoformans_Serotype_B^M_bb       91       91 | T 71 |    4    0    0    4 3800  213 | -- -- 47 72 90 | !$ | "STMS WRMc"
            #supercontig_1.01_of_Cryptococcus_neoformans_Serotype_B_bb        149       -1 | * 75 |    4    1    0    0    0  749 | 32 -- -- -- 90 |  : |
            #1                                                                 2        3    4 5       6    7    8    9 10    11    12 13 14 15 16   17   18
            #|____________        _____________________________________________|        |    | |       |    |    |    | |     |     |  |  |  |  |    |    |
            #             |       |       ______________________________________________|    | |       |    |    |    | |     |     |  |  |  |  |    |    |
            #             |       |       |            ______________________________________| |       |    |    |    | |     |     |  |  |  |  |    |    |
            #             |       |       |            |       ________________________________|       |    |    |    | |     |     |  |  |  |  |    |    |
            #             |       |       |            |       |            ___________________________|    |    |    | |     |     |  |  |  |  |    |    |
            #             |       |       |            |       |            |       ________________________|    |    | |     |     |  |  |  |  |    |    |______________________________
            #             |       |       |            |       |            |       |       _____________________|    | |     |     |  |  |  |  |    |________________________          |
            #             |       |       |            |       |            |       |       |       __________________| |     |     |  |  |  |  |________________             |         |
            #             |       |       |            |       |            |       |       |       |       ____________|     |     |  |  |  |___________        |            |         |
            #             |       |       |            |       |            |       |       |       |       |       __________|     |  |  |______        |       |            |         |
            #             |       |       |            |       |            |       |       |       |       |       |            ___|  |__       |       |       |            |         |
            #             |       |       |            |       |            |       |       |       |       |       |            |       |       |       |       |            |         |
            #             |       |       |            |       |            |       |       |       |       |       |            |       |       |       |       |            |         18____
            #             1       2       3            4       5            6       7       8       9       10      11           12      13      14      15      16           17        18    19
            if ($line =~ /^(\S+)\s+(\d+)\s+(\S+)\s+\|\s+(\S+)\s+(\d+)\s+\|\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+\|\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+\|\s+(\S+)\s+\|(\s+\"(.+)\")*/)
            {
                #supercontig_1.01_of_Cryptococcus_neoformans_Serotype_B^M_bb       91       91 | T 71 |    4    0    0    4 3800  213 | -- -- 47 72 90 | !$ | "STMS WRMc"
                #1                                                                 2        3    4 5       6    7    8    9 10    11    12 13 14 15 16   17   18
                my %data;
                $data{status}              = $17;
                    #Status. This field sums up the evaluation of MIRA whether you should have a
                    #   look at this base or not. The content can be one of the following:
                    #       everything OK: a colon (:)
                    #       unclear base calling (IUPAC base): a "!M"
                    #       potentially problematic base calling involving a gap or low quality: a "!m"
                    #       consensus tag(s) of MIRA that hint to problems: a "!$". Currently, the
                    #          following tags will lead to this marker: SRMc, WRMc, DGPc, UNSc, IUPc.
                next if $data{status} eq ":";
                $data{snpId}               = $countSnp++;
                $data{id}                  = $countLine;
                $data{seqName}             = $seqName;
                $data{paddedPos}           = $2;
                $data{unPaddedPos}         = $3;
                $data{calledConsensus}     = $4;
                $data{calledConsensusQual} = $5; #0-90
                $data{totalCov}            = $6;
                $data{totalCovA}           = $7;
                $data{totalCovC}           = $8;
                $data{totalCovG}           = $9;
                $data{totalCovT}           = $10;
                $data{totalCovGap}         = $11;
                $data{qualityA}            = $12 eq "--" ? 0 : $12;
                $data{qualityC}            = $13 eq "--" ? 0 : $13;
                $data{qualityG}            = $14 eq "--" ? 0 : $14;
                $data{qualityT}            = $15 eq "--" ? 0 : $15;
                $data{qualityGap}          = $16 eq "--" ? 0 : $16;
                #$data{tags1}                = $18 ? $18 : "";
                $data{tags}                = $19 ? $19 : "";
                $data{line}                = $line;

                $hash->{$seqName}[$pos][$data{paddedPos}] = \%data;


                $summary{$seqName}{snp}++;
                $summary{$seqName}{mut}++ if (($data{status} eq '!m') || ($data{status} eq '!M'));
                $summary{$seqName}{del}++ if  ($data{status} eq '!$');
                print "."                  if ( ! ( $countSnp %  10 ) );
                printf " %8d\n", $countSnp if ( ! ( $countSnp % 100 ) );
                #foreach my $key (sort keys %data)
                #{
                #    print "\t\t$key = ", $data{$key}, "\n";
                #}
                #print "\n";
                #print "\tLOADING SEQ $seqName\n";
            } else {
                die "WRONG FROMAT :: $line";
            }
        } else {
            print "INVALID\n";
        }
    }
    close TCS;
    $| = 0;


    print " $countSnp\n";
    print "\t", (scalar keys %$hash), " CHROMOSSOMES RETRIEVED\n";
    my %totals;
    foreach my $chrom (sort keys %summary)
    {
        print "\t\t$chrom\n";
        foreach my $type ( sort keys %{$summary{$chrom}} )
        {
            printf "\t\t\t%s :: %8d\n", uc($type), ($summary{$chrom}{$type} || 0);
            $totals{$type} += ($summary{$chrom}{$type} || 0);
        }
    }

    foreach my $total (sort keys %totals)
    {
        printf "\t\tTOTAL %s :: %8d\n", uc($total), $totals{$total};
    }
    print "TCS FILE LOADED $inFile\n";
}


sub loadFasta
{
    my $inFile = $_[0];
    my $hash   = $_[1];
    my $pos    = $_[2];
    my %summary;

    print "LOADING FASTA FILE $inFile\n";

    open FA, "<$inFile" or die "COULD NOT OPEN FASTA FILE";
    my $seqName;
    while ( my $line = <FA> )
    {
        chomp $line;
        if ( index($line, ">") != -1 )
        {
            if ( defined $seqName )
            {
                printf "\t\t%s LOADED WITH %8d ELEMENTS\n",
                    $seqName,
                    ( scalar @{$hash->{$seqName}[$pos]} );
                $summary{$seqName} = ( scalar @{$hash->{$seqName}[$pos]});
                #for (my $e = 0; $e < @{$hash->{$seqName}[$pos]}; $e++)
                #{
                #    print "E $e => ", $hash->{$seqName}[$pos][$e], "\n";
                #}
            };
            $seqName = substr($line,1);
            $seqName =~ s/[^a-zA-z0-9._]//;
            $seqName =~ s/_bb$//;
            print "\tLOADING SEQ $seqName\n";
        }
        else
        {
            $line =~ s/\s//g;
            my @values = split("", $line);
            push(@{$hash->{$seqName}[$pos]}, @values);
        }
    }
    if ( defined $seqName ) { printf "\t\t%s LOADED WITH %8d ELEMENTS\n", $seqName, ( scalar @{$hash->{$seqName}[$pos]} ); };
    close FA;

    print "\t", (scalar keys %$hash), " CHROMOSSOMES RETRIEVED\n";
    my $total;
    foreach my $key (sort keys %summary)
    {
        printf "\t\t%s\t%8d\n", $key, $summary{$key};
        $total += $summary{$key};
    }
    print "\t\tTOTAL :: $total\n";
    print "FASTA FILE LOADED $inFile\n";
}

sub loadQual
{
    my $inFile = $_[0];
    my $hash   = $_[1];
    my $pos    = $_[2];
    my %summary;
    print "LOADING QUALITY FILE $inFile\n";

    open QA, "<$inFile" or die "COULD NOT OPEN QUALITY FILE";
    my $seqName;
    while ( my $line = <QA> )
    {
        chomp $line;
        if ( index($line, ">") != -1 )
        {
            if ( defined $seqName ) { print "\t\t$seqName LOADED WITH ",( scalar @{$hash->{$seqName}[$pos]})," ELEMENTS\n"; $summary{$seqName} = ( scalar @{$hash->{$seqName}[$pos]})};
            $seqName = substr($line,1);
            $seqName =~ s/[^a-zA-z0-9._]//;
            $seqName =~ s/_bb$//;
            print "\tLOADING SEQ $seqName\n";
        }
        else
        {
            my @values = split(" ", $line);
            #print join(" ", @values);
            push(@{$hash->{$seqName}[$pos]}, @values);
        }
    }
    if ( defined $seqName ) { print "\t\t$seqName LOADED WITH ",( scalar @{$hash->{$seqName}[$pos]})," ELEMENTS\n"; };
    close QA;
    print "\t", (scalar keys %$hash), " CHROMOSSOMES RETRIEVED\n";
    my $total;
    foreach my $key (sort keys %summary)
    {
        print "\t\t$key\t", $summary{$key}, "\n";
        $total += $summary{$key};
    }
    print "\t\tTOTAL :: $total\n";
    print "QUALITY FILE LOADED $inFile\n";
}


sub printHash
{
    my $hash  = $_[0];
    my $names = $_[1];
    print "PRINTING HASH FOR REFERENCE\n";

    my %allKeys;
    #print join("", %$hash), "\n";
    map { $allKeys{$_}++; } keys %$hash;
    print "\t", (scalar keys %allKeys), " CHROMOSSOMES RETRIEVED\n";

    my %total;
    foreach my $key (sort keys %allKeys )
    {
        my $lHash = $hash->{$key};

        printf "\tKEY \"$key\" ::";
        for (my $n = 0; $n < @$names; $n++)
        {
            my $var                   = ( defined ${$lHash}[$n] ) ? $lHash->[$n] : [];
            my $varLen                = scalar @$var;
            next if ( ! exists ${$names[$n]}{name} );
            $total{$names[$n]{name}} += $varLen;
            printf " " . $names[$n]{name} . " %8d", $varLen;
        }
        print "\n";

        #my $diff    = $seqLen - $qualLen;
        #$totalDiff += $diff > 0 ? $diff : ( $diff * -1 );
    }

    foreach my $name (  sort keys %total )
    {
        printf "\t%-5s: %8d\n",$name, $total{$name};
    }
    print "HASH PRINTED FOR REFERENCE\n";
}

1;



##TCS V1.0
##
## contig name          padPos  upadPos | B  Q | tcov covA covC covG covT cov* | qA qC qG qT q* |  S | Tags
##
#supercontig_1.01_of_Cryptococcus_neoformans_Serotype_B^M_bb        0        0 | T 69 |    4    0    0    0   33    0 | -- -- -- 69 -- |  : | "MIRA"
#supercontig_1.01_of_Cryptococcus_neoformans_Serotype_B^M_bb       82       82 | A 76 |    4 3987    0    0    0    0 | 90 -- -- -- -- |  : |
#supercontig_1.01_of_Cryptococcus_neoformans_Serotype_B^M_bb       83       83 | T 76 |    4    0    1    1 3974    0 | --  3 16 90 -- |  : |
#supercontig_1.01_of_Cryptococcus_neoformans_Serotype_B^M_bb       84       84 | G 76 |    4    0    0 3969    0    0 | -- -- 90 -- -- |  : |
#supercontig_1.01_of_Cryptococcus_neoformans_Serotype_B^M_bb       85       85 | T 76 |    4    0    2    0 3979    0 | -- 24 -- 90 -- |  : |
#supercontig_1.01_of_Cryptococcus_neoformans_Serotype_B^M_bb       86       86 | G 76 |    4    0    2 3979    1    0 | -- 16 90 32 -- |  : |
#supercontig_1.01_of_Cryptococcus_neoformans_Serotype_B^M_bb       87       87 | C 76 |    4    0 3994    0    2    0 | -- 90 -- 24 -- |  : |
#supercontig_1.01_of_Cryptococcus_neoformans_Serotype_B^M_bb       88       88 | A 76 |    4 4006    0    4    1    0 | 90 -- 58 14 -- |  : |
#supercontig_1.01_of_Cryptococcus_neoformans_Serotype_B^M_bb       89       89 | G 76 |    4    1    3 4068    1    0 |  8 44 90  8 -- |  : |
#supercontig_1.01_of_Cryptococcus_neoformans_Serotype_B^M_bb       90       90 | G 10 |    4    0    1 3969  113    0 | -- 13 90 70 -- | !m | "STMS"
#supercontig_1.01_of_Cryptococcus_neoformans_Serotype_B^M_bb       91       91 | T 71 |    4    0    0    4 3800  213 | -- -- 47 72 90 | !$ | "STMS WRMc"
#supercontig_1.01_of_Cryptococcus_neoformans_Serotype_B^M_bb       92       92 | T 76 |    4    0    6    0 4013    0 | -- 58 -- 90 -- |  : |
#supercontig_1.01_of_Cryptococcus_neoformans_Serotype_B^M_bb       93       93 | A 76 |    4 3849    0    1    6    0 | 90 -- 21 67 -- |  : |
#supercontig_1.01_of_Cryptococcus_neoformans_Serotype_B^M_bb       94       94 | A 76 |    4 3784    0    1    0    0 | 90 --  6 -- -- |  : |
#supercontig_1.01_of_Cryptococcus_neoformans_Serotype_B^M_bb       95       95 | C 76 |    4    1 3683    3    2    0 | 32 90 47 30 -- |  : |
#supercontig_1.01_of_Cryptococcus_neoformans_Serotype_B^M_bb       96       96 | C 76 |    4    1 3623    1    0    0 | 32 90 30 -- -- |  : |
#supercontig_1.01_of_Cryptococcus_neoformans_Serotype_B^M_bb       97       97 | G 76 |    4    0    0 3556    1    0 | -- -- 90  4 -- |  : |
#supercontig_1.01_of_Cryptococcus_neoformans_Serotype_B^M_bb       98       98 | C 76 |    4    1 3514    2    0    0 |  6 90 29 -- -- |  : |

#http://mira-assembler.sourceforge.net/docs/mira_faq.html
#Can I see deletions?
    #Suppose you ran the genome of a strain that had one or more large
    #deletions. Would it be clear from the data that a deletion had occurred?
    #    In the question above, I assume you'd compare your strain X to a strain
    #    Ref and that X had deletions compared to Ref. Furthermore, I base my
    #    answer on data sets I have seen, which presently were 36 and 76 mers,
    #    paired and unpaired.
    #
    #    Yes, this would be clear. And it's a piece of cake with MIRA.
    #
    #    Short deletions (1 to 10 bases): they'll be tagged SROc or WRMc. General
    #    rule: deletions of up to 10 to 12% of the length of your read should be
    #    found and tagged without problem by MIRA, above that it may or may not,
    #    depending a bit on coverage, indel distribution and luck.
    #
    #    Long deletions (longer than read length): they'll be tagged with MCVc
    #    tag by MIRA ins the consensus. Additionally, when looking at the FASTA
    #    files when running the CAF result through convert_project: long stretches
    #    of sequences without coverage (the @ sign in the FASTAs) of X show
    #    missing genomic DNA.


#http://mira-assembler.sourceforge.net/docs/mira.html
#TCS
    #Transpose Contig Summary. A text file as written by mira which gives a
    #   summary of a contig in tabular fashion, one line per base. Nicely
    #   suited for "quick" analyses from command line tools, scripts, or even
    #   visual inspection in file viewers or spreadsheet programs.
    #In the current file version (TCS 1.0), each column is separated by at
    #   least one space from the next. Vertical bars are inserted as visual
    #   delimiter to help inspection by eye. The following columns are written
    #   into the file:
    #contig name (width 20)
    #padded position in contigs (width 3)
    #unpadded position in contigs (width 3)
    #separator (a vertical bar)
    #called consensus base
    #quality of called consensus base (0-100), but MIRA itself caps at 90.
    #separator (a vertical bar)
    #total coverage in number of reads. This number can be higher than the sum
    #   of the next five columns if Ns or IUPAC bases are present in the
    #   sequence of reads.
    #coverage of reads having an "A"
    #coverage of reads having an "C"
    #coverage of reads having an "G"
    #coverage of reads having an "T"
    #coverage of reads having an "*" (a gap)
    #separator (a vertical bar)
    #quality of "A" or "--" if none
    #quality of "C" or "--" if none
    #quality of "G" or "--" if none
    #quality of "T" or "--" if none
    #quality of "*" (gap) or "--" if none
    #separator (a vertical bar)
    #Status. This field sums up the evaluation of MIRA whether you should have a
    #   look at this base or not. The content can be one of the following:
    #       everything OK: a colon (:)
    #       unclear base calling (IUPAC base): a "!M"
    #       potentially problematic base calling involving a gap or low quality: a "!m"
    #       consensus tag(s) of MIRA that hint to problems: a "!$". Currently, the
    #          following tags will lead to this marker: SRMc, WRMc, DGPc, UNSc, IUPc.
    #list of a consensus tags at that position, tag are delimited by a space.
    #   E.g.: "DGPc H454"

#Tags set (and used)
    #This section lists tags which MIRA sets (and reads of course), but that
    #   other software packages might not know about.
        #UNSr, UNSc: UNSure R respectively Contig. These tags denote positions
        #   in an assembly with conflicts that could not be resolved
        #   automatically by mira. These positions should be looked at during
        #   the finishing process.
        #   For assemblies using good sequences and enough coverage, something
        #   0.01% of the consensus positions have such a tag. (e.g.  300 UNSc
        #   tags for a genome of 3 megabases).
        #SRMr, WRMc: Strong Repeat Marker and Weak Repeat Marker. These tags are
        #   set in two flavours: as SRMr and WRMr when set in reads, and as SRMc
        #   and WRMc when set in the consensus. These tags are used on an
        #   individual per base basis for each read. They denote bases that have
        #   been identified as crucial for resolving repeats, often denoting a
        #   single SNP within several hundreds or thousands of bases. While a
        #   SRM is quite certain, the WRM really is either weak (there wasn't
        #   enough comforting information in the vicinity to be really sure) or
        #   involves gap columns (which is always a bit tricky).
        #   mira will automatically set these tags when it encounters repeats
        #   and will tag exactly those bases that can be used to discern the
        #   differences.
        #   Seeing such a tag in the consensus means that mira was not able to
        #   finish the disentanglement of that special repeat stretch or that
        #   it found a new one in one of the last passes without having the
        #   opportunity to resolve the problem.
        #DGPc: Dubious Gap Position in Consensus. Set whenever the gap to base
        #   ratio in a column of 454 reads is between 40% and 60%.
        #SAO, SRO, SIO: SNP intrA Organism, SNP R Organism, SNP Intra and inter
        #   Organism. As for SRM and WRM, these tags have a r appended when set
        #   in reads and a c appended when set in the consensus. These tags
        #   denote SNP positions.
        #   mira will automatically set these tags when it encounters SNPs and
        #   will tag exactly those bases that can be used to discern the
        #   differences. They denote SNPs as they occur within an organism (SAO),
        #   between two or more organisms (SRO) or within and between organisms (SIO).
        #   Seeing such a tag in the consensus means that mira set this as a
        #   valid SNP in the assembly pass. Seeing such tags only in reads (but
        #   not in the consensus) shows that in a previous pass, mira thought
        #   these bases to be SNPs but that in later passes, this SNP does not
        #   appear anymore (perhaps due to resolved misassemblies).
        #STMS: (only hybrid assemblies). The Sequencing Type Mismatch Solved is
        #   tagged to positions in the assembly where the consensus of different
        #   sequencing technologies (Sanger, 454, Solexa, SOLiD) reads differ,
        #   but mira thinks it found out the correct solution. Often this is due
        #   to low coverage of one of the types and an additional base calling error.
        #   Sometimes this depicts real differences where possible explanation
        #   might include: slightly different bugs were sequenced or a mutation
        #   occurred during library preparation.
        #STMU: (only hybrid assemblies). The Sequencing Type Mismatch Unresolved
        #   is tagged to positions in the assembly where the consensus of
        #   different sequencing technologies (Sanger, 454, Solexa, SOLiD) reads
        #   differ, but mira could not find a good resiltion. Often this is due
        #   to low coverage of one of the types and an additional base calling error.
        #   Sometimes this depicts real differences where possible explanation
        #   might include: slightly different bugs were sequenced or a mutation
        #   occurred during library preparation.
        #MCVc: The Missing Co{V}erage in Consensus. Set in assemblies with more
        #   than one strain. If a strain has no coverage at a certain position,
        #   the consensus gets tagged with this tag (and the name of the strain
        #   which misses this position is put in the comment). Additionally, the
        #   sequence in the result files for this strain will have an @ character.
        #MNRr: (only with -SK:mnr active). The Masked Nasty Repeat tags are set
        #   over those parts of a read that have been detected as being many
        #   more times present than the average subsequence. mira will hide
        #   these parts during the initial all-against-all overlap finding
        #   routine (SKIM3) but will otherwise happily use these sequences for
        #   consensus generation during contig building.
        #FpAS: See "Tags read (and used)" above.
        #ED_C, ED_I, ED_D: EDit Change, EDit Insertion, EDit Deletion. These
        #   tags are set by the integrated automatic editor EdIt and show which
        #   edit actions have been performed.
        #HAF2, HAF3, HAF4, HAF5, HAF6, HAF7. These are HAsh Frequency tags which
        #   show the status of read parts in comparison to the whole project.
        #   Only set if -AS:ard is active (default for genome assemblies).
        #   More info on how to use the information conveyed by HAF tags in the
        #   section dealing with repeats and HAF tags in finishing programs
        #   further down in this manual.
        #HAF2 coverage below average (<0.5 times average)
        #HAF3 coverage is at average (>=0.5 times average and <= 1.5 times average)
        #HAF4 coverage above average (>1.5 times average and < 2 times average)
        #HAF5 probably repeat (>=2 times average and < 5 times average)
        #HAF6 'heavy' repeat (> 8 times average)
        #HAF7 'crazy' repeat (> 20 times average)
