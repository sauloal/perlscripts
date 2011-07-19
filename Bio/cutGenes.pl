#!/usr/bin/perl -w
use strict;

my $fastaFile = $ARGV[0];
my $xmlFile   = $ARGV[1];
my $export    = 1;
my $flankSize = 250;
my $verbose   = 0;

my %chromos;
my %chromosMap;
my @chromSize;
my ($seq, $upStream, $geneSeq, $downStream); # perl's fault

if ( @ARGV < 2 )       { print " WRONG NUMBER OF ARGUMENTS\n"; &usage; };
if ( ! -f $fastaFile ) { print " FASTA FILE $fastaFile DOESNT EXISTS\n";  &usage; };
if ( ! -f $xmlFile )   { print " XML FILE $xmlFile DOESNT EXISTS\n";    &usage; };


&genChromos($fastaFile);
my $xmlPos = &parseXML($xmlFile);


if ($export)
{
    foreach (my $chromNum = 0; $chromNum < @{$xmlPos}; $chromNum++)
    {
        print "  EXPORTING CHROMOSSOME ", &reverseHash($chromNum), "\n";
        next if ( ! defined $xmlPos->[$chromNum] );

        foreach (my $pos = 0; $pos < @{$xmlPos->[$chromNum]}; $pos++)
        {
            if (( defined $xmlPos->[$chromNum]->[$pos] ) && ( exists $xmlPos->[$chromNum]->[$pos]{"gene"}))
            {
                my $gene     = $xmlPos->[$chromNum]->[$pos]{"gene"};
                my $gene_end = $xmlPos->[$chromNum]->[$pos]{"gene_end"};

                &exporter($chromNum, $pos, $gene_end, $gene);
            }
        }
    }
}
#my $fasta = $ARGV[0];
#my $chrom = $ARGV[1];
#my $start = $ARGV[2];
#my $end   = $ARGV[3];
#my $name  = $ARGV[4];

#my @gene = @{&readFasta($fasta, $chrom)};
#&returner(\@gene, $start, $end, $name);

# R265_c_neoformans.fasta
# gpd1 824481 823935 supercontig_1.04_of_Cryptococcus_neoformans_Serotype_B
# tef1 288429 287730 supercontig_1.13_of_Cryptococcus_neoformans_Serotype_B
#
# WM276GBFF10_06.fasta
# gpd1 29 576   CP000291_CGB_F2310W_Glyceraldehyde_3_phosphate_dehydrogenase_476378_478056
# tef1 673 1371 CP000298_CGB_M1520C_Translation_elongation_factor_EF1_alpha__putative_323075_324730

# ./cut.pl R265_c_neoformans.fasta supercontig_1.04_of_Cryptococcus_neoformans_Serotype_B 823935 824481 gpd1 > gpd1.265.txt
# ./cut.pl R265_c_neoformans.fasta supercontig_1.13_of_Cryptococcus_neoformans_Serotype_B 287730 288429 tef1 > tef1.265.txt
# ./cut.pl WM276GBFF10_06.fasta CP000291_CGB_F2310W_Glyceraldehyde_3_phosphate_dehydrogenase_476378_478056 29 576 gpd1 > gpd1.276.txt
# ./cut.pl WM276GBFF10_06.fasta CP000298_CGB_M1520C_Translation_elongation_factor_EF1_alpha__putative_323075_324730 673 1371 tef1 > tef1.276.txt


sub exporter
{
    my $chromNum  = $_[0];
    my $start     = $_[1];
    my $end       = $_[2];
    my $name      = $_[3];
    my $chromName = &reverseHash($chromNum);

    print "    EXPORTING GENE AT CHROM ",($chromNum+1)," POSITION ", $start, ":", $end , " > ", $name, "\n";

    if ( ! ((defined $start) && (defined $end))) { die };

    my $newStart = $start - $flankSize;
    my $newEnd   = $end   + $flankSize;

    while ($newStart <= 0)                  { $newStart++ };
    while ($newEnd > $chromSize[$chromNum]) { $newEnd-- };

    $seq = undef;
    $seq = &readFasta($fastaFile, $chromNum, $newStart, $newEnd);
    my $seqLen = length($seq);

    ($upStream, $geneSeq, $downStream) = (undef,undef,undef);
    if ( ! -d "output" ) { mkdir("output") or die "COULD NOT CREATE OUTPUT DIRECTORY" };
    unlink("output/*.fasta");

    my $chromNumName = ($chromNum+1);
    if ($chromNumName < 10) {$chromNumName = "0". $chromNumName; };

    my $filename = $chromNumName."\_$start\_$name.fasta";
    open OUTFILE, ">output/$filename" or die "COULD NOT CREATE OUTPUT FILE $filename $!";

    print OUTFILE ">",$chromNumName,"\_",$chromName,"\_UPSTREAM\_",$start,"\_",$end,"\_",$name,"\n";
    print OUTFILE &faster(substr($seq, 0, ($start-$newStart)));
    print OUTFILE "\n";

    print OUTFILE ">",$chromNumName,"\_",$chromName,"\_",$newStart,"\_",($start-1),"\_",$name,"\n";
    print OUTFILE &faster(substr($seq, $flankSize, ($seqLen - (($start-$newStart)+($newEnd - $end)))));
    print OUTFILE "\n";

    print OUTFILE ">",$chromNumName,"\_",$chromName,"\_DOWNSTREAM\_",($end+1),"\_",$newEnd,"\_",$name,"\n"; 
    print OUTFILE &faster(substr($seq, -($newEnd - $end)));
    print OUTFILE "\n";

    close OUTFILE;
}

sub faster
{
    my $seq = shift;
    $seq =~ s/(.{60})/$1\n/g;
    return $seq;
}

sub readFasta
{
    my $inputFA  = $_[0];
    my $chromNum = $_[1];
    my $start    = $_[2];
    my $end      = $_[3];
    my $chromName;
    my $desiredLine;

    $start = $start ? $start : 0;
    $end   = $end   ? $end   : -1;
    my $length = $end - $start+1;
    if ($length < 0) { $length = undef; };


    if ( $chromNum =~ /^\d+$/ )
    {
        if ( eval { $desiredLine = $chromosMap{&reverseHash($chromNum)} } )
        {
            $chromName   = &reverseHash($chromNum);
        }
        else
        {
            die "CHROMOSSOME $chromNum NOT FOUND IN FASTA";
        }
    }
    elsif ( $chromNum =~ /[\w+]/)
    {
        if ( eval { $desiredLine = $chromosMap{$chromNum} } )
        {
            $chromName   = $chromNum;
        }
        else
        {
            die "CHROMOSSOME $chromNum NOT FOUND IN FASTA";
        }
    }
    else
    {
        die "CHROMOSSOME $chromNum NOT FOUND IN FASTA";
    }

    open FILE, "<$inputFA" or die "COULD NOT OPEN $inputFA: $!";

    my $current;
    my $chromo;
    my $chromoName;

    my $on   = 0;
    my $pos  = 0;
    my $line = 1;
    my $totalSoFar = 0;

#   print "EXTRACTING SEQUENCE FROM CHROMOSSOME ", $chromNum," START ", $start," END ", $end," LENGTH ", ($length || "undef") ,"\n";
    $seq = undef;
    seek(FILE, $desiredLine-200, 0);    
    while (<FILE>)
    {
        chomp;
        if (( /^>/) && ($on))
        {
            $on   = 0;
            $pos  = 1;
            last;
        }

        if ($on)
        {
            my $totalEndLine = ($totalSoFar + length($_));
            if ($totalEndLine >= $start)
            {
                if ($start > 0)
                {
                    if (defined $length)
                    {
                        if ($end > $totalSoFar)
                        {
                            my $newStart = $start - $totalSoFar - 1;
                            if ($newStart > 0) # if positive, needed
                            {
                                if ($totalEndLine < $end)
                                {
                                    $seq .= substr($_,$newStart);
                                }
                                else
                                {
                                    $seq .= substr($_,$newStart,($end-($newStart+$totalSoFar)));
                                }
                            } # end if newstart > 0
                            else # if negative, already found so ignore
                            {
                                if ($totalEndLine < $end)
                                {
                                    $seq .= $_;
                                }
                                else
                                {
                                    $seq .= substr($_,0,($end-$totalSoFar));
                                }
                            } # end else if newstart > 0
                        } # end if end < totalsofar
                        else
                        {
                            last;
                        }
                    } # end if defined length
                    else
                    {
                        $seq .= substr($_, ($start - $totalSoFar));
                        $start = 0;
                    }# end else if defined length
                } # end if start > 0
                else
                {
                    $seq .= $_;
                }# end else if start > 0
            } # end if end of line > start
            $totalSoFar += length($_);
        } #end if on

        if (/^>$chromName/)
        {
            $on         = 1;
            $chromoName = $chromName;
            $pos        = 1;
        }
        $line++;
    }
    undef $chromo;
    close FILE;

    if ( ! $seq ) { die "NO GENE READ\n";};

#   print "SEQUENCE RETRIEVED: ", (length $seq), "bp\n";

    return $seq;
}


sub genChromos
{
    my $inputFA = $_[0];
    my $on = 0;
    my $chromo;
    my $total;
    open FILE, "<$inputFA" or die "COULD NOT OPEN $inputFA: $!";
    my $pos  = 0;
    my $line = 1;
    my $current;
#   my $tell = 0;
    print "  GENERATING FASTA MAP...";

    while (<FILE>)
    {
        chomp;
        if ( /^>/)
        {
            $on   = 0;
            $pos  = 1;
        }

        if ($on)
        {
            $chromSize[$chromos{$chromo}] += length($_);
        }

        if (/^>(.*)/)
        {
            $on     = 1;
            $chromo = $1;
            $pos    = 1;
            $chromos{$chromo}    = scalar (keys %chromos);
            $chromosMap{$chromo} = tell(FILE);
#           $chromosMap{$chromo} = $line;
        }
        $line++;
    }
    undef $chromo;
    close FILE;
    print "done: ", (scalar keys %chromos) ," CHROMOSSOMES RETRIEVED\n";
    if ($verbose)
    {
        print "CHROMOSMAP:\n";
        foreach my $chromName (sort keys %chromosMap)
        {
            print "  ", $chromName, " ", $chromosMap{$chromName}, "\n";
        }

        print "CHROMOS:\n";
        foreach my $chromName (sort keys %chromos)
        {
            print "  ", $chromName, " ", $chromos{$chromName}, "\n";
        }

        print "CHROMSIZE:\n";
        for (my $c = 1; $c < @chromSize; $c++)
        {
            print "  CHOMOSSOME ", $c, " HAS ", $chromSize[$c], "bp\n";
        }
    }
}



sub parseXML
{
    my $file = $_[0];
    open FILE, "<$file" or die "COULD NOT OPEN FILE $file: $!";

    my $row         = 0;
    my $table       = 0;
    my $tableName   = "";
    my $registerT   = 0;
    my $registerTot = 0;
    my @XMLhash;
    my $currId      = "";
    my $registre    = 0;

    foreach my $line (<FILE>)
    {
        if ($line =~ /<root id=\"(.*)\" type=\"(.*)\">/)
        {
            my $rootType = $2 ;
            if ($rootType ne "pos") { print "ONLY XMLPOS XML ACCEPTED. $rootType RECEIVED INSTEAD"; &usage; };
        }
        if ($line =~ /<table id=\"(.*)\" type=\"(.*)\">/)
        {
            $table     = 1;
            $tableName = $1;
            my $tableType = $2;
            if ($tableType ne "chromossome") { print "ONLY CHROMOSSOME XML ACCEPTED. $tableType RECEIVED INSTEAD"; &usage; };
        }
        if ($line =~ /<\/table>/)
        {
            $table     = 0;
            $tableName = "";
#           $register  = 0;
            $registerT++;
        }
        if ($line =~ /<row( id=\"(\d+)\")*>/)
        {
            if (defined $2)
            {
              $currId = $2;
            }
            else
            {
              $currId = $registre;
            }
            $row = 1;
        }
        elsif ($line =~ /<\/row>/)
        {
            $row = 0;
            $registre++;
            $registerTot++;
        }
        if ($row)
        {
            if ($line =~ /<(\w+)>(.+)<\/\1>/)
            {
#               print "$line\n";
                my $key   = $1;
                my $value = $2;
#               print "$register => $key -> $value\n";
                if ($tableName)
                {
#                   print "$tableName $register $key $value\n";
#                   $XMLhash{$tableName}{$registre}{$key} = $value;

                    if ( ! defined $chromos{$tableName} )
                    {
                        die "FASTA FILE DOESNT CONTAINS $tableName CHROMOSSOME\n";
                    }

                    $XMLhash[$chromos{$tableName}][$currId]{$key} = $value;
                    #print "{" . $chromos{$tableName} . "}{$currId}{$key} = $value;\n";
                }
                else
                {
                    die "TABLE NAME NOT DEFINED IN XML $file\n";
                }
            }
        }
    }

    close FILE;
    print "  FILE $file PARSED: $registerTot REGISTERS RECOVERED FROM $registerT TABLES\n";
    return \@XMLhash;
}

sub usage
{
    print " $0 <INPUT.FASTA> <XMLPOS.XML>\n\n";
    exit 1;

}

sub reverseHash
{
    my $chromNum = $_[0];
    my %temp;
    foreach my $chromName (keys %chromos)
    {
        my $value = $chromos{$chromName};
        $temp{$value} = $chromName;
    }
    return $temp{$chromNum}; # return the name
}

1;