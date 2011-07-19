#!/usr/bin/perl -w
use strict;

my $inFile;
#if ($ARGV[0]) { $inFile = $ARGV[0] } else { die "NEED IN FILE\n" ; };

$inFile = "matrix.dat";

my $filterPlant = 1;

my %DB;

%DB = &readFile($inFile);
%DB = &makeTables(\%DB);
my %pfm = &exportPFM(\%DB);
&printPFM(\%pfm);

my %pwm = &exportPWM(\%DB); #MOTIFSCANNER
&printPWM(\%pwm); #MOTIFSCANNER


sub exportPWM
{
# motifscanner
    my %db = %{$_[0]};
    my %pwm;
    foreach my $ac (sort keys %db)
    {
        my $ba        =   $db{$ac}{"ba"};           # base - number or genes
        my $sequence  =   $db{$ac}{"seq"};          # base - number or genes
        my $max       =   $db{$ac}{"max"};          # base - number or genes
        my $sumAll    =   $db{$ac}{"sumAll"};       # base - number or genes
        my @sumNuc    = @{$db{$ac}{"sumNuc"}};      # base - number or genes
        my @sumPos    = @{$db{$ac}{"sumPos"}};      # base - number or genes
        my @matrixPWM = @{$db{$ac}{"matrixPWM"}};   # base - number or genes
        my $id        =   $db{$ac}{"id"};           # id long
        my $na        =   $db{$ac}{"na"};           # gene

        my $out;
        my $size     = 0;
        my $maxScore = 0;
        for (my $i = 0; $i <= $#matrixPWM; $i++)
        {
            for (my $j = 0; $j <= ($#{$matrixPWM[$i]}); $j++)
            {
                my $value = $matrixPWM[$i][$j];
        
                $maxScore  = $value if ($value > $maxScore);
                $size = $i if ($i >= $size);
                if ($value < 10)
                {
                    $value = "$value";
                    $out  .= $value . " ";
                }
                else
                {
                    $out  .= $value . " ";
                }
            } # end for my j
            $out .= "\n";
        } # end for my i

        $size+=1;
        my $score = .85 * $maxScore;
        $pwm{$ac}{"matrix"} =  $out;
        my $head  = "#ID = $ac-$id\n";
           $head .= "#w = $size\n";
           $head .= "#Score = $score\n";
           $head .= "#Consensus = $sequence\n";
           $pwm{$ac}{"head"} = $head;
    } #end foreach my ac
    return %pwm;
} # end sub exportPFM


sub printPWM
{
#motifscanner
    my %pwm = %{$_[0]};


# #INCLUSive Motif Model v1.0
# #
# #ID = M00001-V$MYOD_01
# #W = 12
# #Score = 0.73600134818241
# #Conensus = SRACAGGTGKYG
# 0.208333333333333 0.375   0.375   0.0416666666666667  
# 0.208333333333333 0.0416666666666667  0.541666666666667   0.208333333333333   
# 
# #ID = M00002-V$E47_01
# #W = 15
# #Score = 0.783350672433995
# #Conensus = VSNGCAGGTGKNCNN

    open  LIST, ">transfac_v11.mtrx" || die "COULD NOT OPEN transfac_v11.mtrx: $!";
    print LIST "#INCLUSive Motif Model v1.0\n#\n";
    foreach my $ac (sort keys %pwm)
    {
        my $table = $pwm{$ac}{"matrix"};
        my $line  = $pwm{$ac}{"head"};

        print LIST "$line";
        print LIST "$table\n";
    }
    close LIST;
}









sub exportPFM
{
#signalscan
    my %db = %{$_[0]};
    my %pfm;
    foreach my $ac (sort keys %db)
    {
        my $ba        =   $db{$ac}{"ba"};           # base - number or genes
        my $sequence  =   $db{$ac}{"seq"};          # base - number or genes
        my $max       =   $db{$ac}{"max"};          # base - number or genes
        my $sumAll    =   $db{$ac}{"sumAll"};       # base - number or genes
        my @sumNuc    = @{$db{$ac}{"sumNuc"}};      # base - number or genes
        my @sumPos    = @{$db{$ac}{"sumPos"}};      # base - number or genes
        my @matrixPFM = @{$db{$ac}{"matrixPFM"}};   # base - number or genes
        my $id        =   $db{$ac}{"id"};           # id long
        my $na        =   $db{$ac}{"na"};           # gene

        my $de      = $db{$ac}{"de"};   # description
        my $bf      = $db{$ac}{"bf"};   # species
        my $bs      = $db{$ac}{"bs"};   # binding site
        my $cc      = $db{$ac}{"cc"};   # description
        my $info    = $db{$ac}{"info"}; # bibliography
        my $idShort = $db{$ac}{"idShort"};
        my $sp      = $db{$ac}{"sp"};

        my $out;
        my $size = 0;
        for (my $i = 0; $i <= $#matrixPFM; $i++)
        {
            for (my $j = 0; $j <= ($#{$matrixPFM[$i]}); $j++)
            {
                my $value = $matrixPFM[$i][$j];
                $size = $j if ($j > $size);
                $max  = $value if ($value > $max);
                if ($value < 10) # place a space to number bellow 10
                {
                    $value = " $value";
                    $out  .= $value . " ";
                }
                else
                {
                    $out  .= $value . " ";
                }
            } # end for my j
            $out .= "\n";
        } # end for my i

# TRANSFAC.DAT ISGF-3          ISRE                 AAAGGGAAACCGAAACTG             18 R00947  
#       na      ID          sequence           size ac
# TRANSFAC11    ISGF-3      ISRE        CAGTTTCWCTTTYCC         15      M00258

        $size+=1;

#       $sequence =~ tr/actgACTG/n/c;
        $na       =~ tr/ /_/;
        $sequence =~ tr/N/n/;

        $pfm{$ac}{"matrix"} =  $out;
        $pfm{$ac}{"name"}   = "$na\t$idShort\t$sequence\t$size\t$ac";
        $pfm{$ac}{"sp"}     = "$sp";
    } #end foreach my ac
    return %pfm;
} # end sub exportPFM


sub printPFM
{
#signalscan
    my %pfm = %{$_[0]};

    mkdir ("signal");
    my @filelist = glob("signal/*");
    unlink @filelist;

    open  LIST,  ">signal/transfac11.dat" or die "COULD NOT OPEN TRANSFAC11.DAT.txt: $!";

    foreach my $ac (sort keys %pfm)
    {
        my $table = $pfm{$ac}{"matrix"};
        my $line  = $pfm{$ac}{"name"};
        my $sp    = $pfm{$ac}{"sp"};

        print LIST "$line\n";

        open  LIST2, ">>signal/transfac11_$sp.dat" or die "COULD NOT OPEN TRANSFAC11_$sp.txt: $!";
        print LIST2 "$line\n";
        close LIST2;

        open  MATRIX, ">signal/$ac.pfm" or die "COULD NOT OPEN $ac.pfm: $!";
        print MATRIX "$table";
        close MATRIX;
    }
    close LIST;
#   close LIST2;
}


sub makeTables
{
    my %db = %{$_[0]};
    foreach my $ac (sort keys %db)
    {
        my $matrix = $db{$ac}{"matrix"};
        my $ba     = $db{$ac}{"ba"};     # base - number or genes
#       print "$matrix\n";

        my @response = &parseMatrix($matrix);

        my $sequence  =   $response[0];
        my $max       =   $response[1];
        my @matrixPFM = @{$response[2]};
        my @matrixPWM = @{$response[3]};
        my @sumNuc    = @{$response[4]};
        my @sumPos    = @{$response[5]};
        my $sumAll    =   $response[6];

        undef @response;

#       print "PFM $ac " . $#{$matrixPFM[0]} . "\n";
#       print "PWM $ac " . $#matrixPWM . "\n";

        if (($ba =~ /^(\d+)/) || ($ba =~ /^total weight of sequences: (\d+.\d+)/))
        { $ba = $1; } else { $ba = $max; };

          $db{$ac}{"ba"}         = $ba;        # base - number or genes
          $db{$ac}{"seq"}        = $sequence;  # base - number or genes
          $db{$ac}{"max"}        = $max;       # base - number or genes
          $db{$ac}{"sumAll"}     = $sumAll;    # base - number or genes
        @{$db{$ac}{"sumNuc"}}    = @sumNuc;    # base - number or genes
        @{$db{$ac}{"sumPos"}}    = @sumPos;    # base - number or genes
        @{$db{$ac}{"matrixPFM"}} = @matrixPFM; # base - number or genes
        @{$db{$ac}{"matrixPWM"}} = @matrixPWM; # base - number or genes
    }
    return %db;
}



sub parseMatrix
{
    my $matrix = $_[0];

    my @matri = split("\n",$matrix);

    my $lines  = @matri;
    my $colums = 5;

    my @matrixPFM;
    my @matrixPWM;
    my $max = 0;
    my @sumX;
    my @sumY;
    my $sumAll;

    my $sequence;

    for (my $x = 0; $x < $lines; $x++)
    {
        my $sumX  = 0;
        my @temp = split(/\s+/,$matri[$x]);

        for (my $y = 0; $y < $colums; $y++)
        {
#           print "$x x $y > " .  $temp[$y] . "\n";
            if ($y < $colums-1)
            {
                $sumX              += $temp[$y];
                $matrixPFM[$y][$x]  = $temp[$y];
                $matrixPWM[$x][$y]  = $temp[$y];
                $sumY[$y]          += $temp[$y];
            }
            if ($y == $colums-1) { $sequence .= $temp[$y]; };
        }
        $max      = $sumX if ($sumX > $max);
        $sumX[$x] = $sumX;
        $sumAll  += $sumX;
    }


    for (my $x = 0; $x < @matrixPWM; $x++)
    {
        my $sum  = 0;
#       print "" . ($x + 1) . "\t" . $sumX[$x] . "\t";
        for (my $y = 0; $y < @{$matrixPWM[$x]}; $y++)
        {
#           print $matrixPWM[$x][$y] . ">";
            $matrixPWM[$x][$y]  = &converter($matrixPWM[$x][$y],$sumX[$x],$sumY[$y],$sumAll);
#           print $matrixPWM[$x][$y] . "\t";
        }
#       print "\n";
    }
#   print "SS\t\t" . join("\t",@sumY);
#   print "\n\n";

    return ($sequence, $max, \@matrixPFM, \@matrixPWM, \@sumX, \@sumY, $sumAll);
}

sub converter
{
    my $value  = $_[0];
    my $maxX   = $_[1];
    my $maxY   = $_[2];
    my $sumAll = $_[3];
    # http://tfbs.genereg.net/DOC/TFBS/Matrix/PFM.html#POD5

    #p[i,k] = PFM[i,k] / Z
    my $result1 = $value / $maxX;

    #p'[i,k] = (PFM[i,k] + 0.25*sqrt(Z)) / (Z + sqrt(Z))
    my $result2 = ($value + (0.25 * sqrt($maxX))) / ($maxX + sqrt($maxX));

    #p'[i,k] = (PFM[i,k] + q[k]*B) / (Z + B)
    my $result3 = ($value + (($maxY / $sumAll) * sqrt($maxX))) / ($maxX + sqrt($maxX));

    my $result4 = ((($result3 * 3) + ($result2 * 2) + ($result1 * 1)) / 6);

    return $result4;
}


sub readFile
{
    open IN, "<$inFile" || die "COULD NOT OPEN FILE $inFile: $!";
    my %db;
    my $ac;
    my $id;
    my $de;
    my $na;
    my $bf;
    my $bs;
    my $p0;
    my $matrix;
    my $ba;
    my $cc;
    my $info;
    my $reset        = 0;
    my $count        = 0;
    my $countValid   = 0;
    my $contar       = -1;
    my $countReg     = -1;
    my $countInValid = -1;
    
    while (<IN>)
    {
    #   print $_;
        chomp;
        if ($_ eq "//")
        {
            $countReg++;
    #       print "$count\n";
            if (($count == 4) && ($de eq ""))
            {
                $count++;
                $de = "Unknown";
            }

            if ($count >= 5)
            {
                chomp($id);     # id long
                chomp($na);     # gene
                chomp($de);     # description
                chomp($bf);     # species
                chomp($bs);     # binding site
                chomp($p0);     # matrix header
                chomp($matrix);
                chomp($ba);     # base - number of genes
                chomp($cc);     # description
                chomp($info);   # bibliography


                my $idShort = $id;
                my $sp = "";
                if ($id =~ /(\S+)\$(\S+)/)
                {
                    $sp      = $1;
                    $idShort = $2;
#                   print "ID $id IDSHORT $idShort SP $sp\n";
                }
                if ($idShort =~ /(\S+)\_(\d+)$/)
                {
                    $idShort = $1;
                }

                $db{$ac}{"idShort"} = $idShort;   # id long
                $db{$ac}{"sp"}      = $sp;   # gene
                $db{$ac}{"id"}      = $id;   # id long
                $db{$ac}{"na"}      = $na;   # gene
                $db{$ac}{"de"}      = $de;   # description
                $db{$ac}{"bf"}      = $bf;   # species
                $db{$ac}{"bs"}      = $bs;   # binding site
                $db{$ac}{"p0"}      = $p0;   # matrix header
                $db{$ac}{"ba"}      = $ba;   # base - number of genes
                $db{$ac}{"cc"}      = $cc;   # description
                $db{$ac}{"info"}    = $info; # bibliography
                $db{$ac}{"matrix"}  = $matrix;
                $countValid++;
            } # end if count >= 5
            else
            {
                $countInValid++;
                print "$countInValid $count AC $ac\n" if ($ac);
                print "$countInValid $count ID $id\n" if ($id);
                print "$countInValid $count DE $de\n" if ($de);
                print "$countInValid $count NA $na\n" if ($na);
            }
            $ac     = "";
            $id     = "";
            $de     = "";
            $na     = "";
            $bf     = "";
            $bs     = "";
            $p0     = "";
            $matrix = "";
            $ba     = "";
            $cc     = "";
            $info   = "";
            $contar++;
            $count = 0;
        } # end if //
        else
        {
    #       print "$contar $count $_\n";
            if (/^AC\s+(.*)/)  { $ac      =   $1   ; $count += 1; };    # id short
            if (/^ID\s+(.*)/)  { $id      =   $1   ; $count += 1; };    # id long
            if (/^DE\s+(.*)/)  { $de      =   $1   ; $count += 1; };    # id long
            if (/^NA\s+(.*)/)  { $na      =   $1   ; $count += 1; };    # gene
            if (/^P0\s+(.*)/)  { $p0      =   $1   ; $count += 1; };    # matrix header

            if (/^BF\s+(.*)/)  { $bf     .=  "$1\n"; };                 # species
            if (/^BS\s+(.*)/)  { $bs     .=  "$1\n"; };                 # binding site
            if (/^\d+\s+(.*)/) { $matrix .=  "$1\n"; };                 # matrix
            if (/^BA\s+(.*)/)  { $ba     .=  "$1\n"; };                 # base - number of genes
            #if (/^CC\s+(.*)/)  { $cc      = " $1"  ; $count += 1; };   # description
            if (/^R\w\s+(.*)/) { $info   .= " $1"  ; };                 # bibliography
        } # end else if //
    } # end while line
    
    print "TOTAL   $contar\n";
    print "VALID   $countValid\n";
    print "INVALID $countInValid\n";

    close IN;

    return %db;
}

## SIGNALSCAN
# ISGF-3          ISRE                 nGGAAAnTGAAACT                 14 R00001  
# ICSBP           ISRE                 GGGGAAAATGAAACTGCA             18 R00002  
# M_factor        ISRE                 AGGAAATAGAAACT                 14 R00003  
# Sp1             PPE                  ACCCCTCCCACTT                  13 R00004  
# NF-4FA          unknown              CTCCTTTCTTTGAAG                15 R00005  
# NF-4FC          unknown              CTCCGTCACGAGGGTGG              17 R00006  
# c-Jun           unknown              GTGACTCA                       8  R00007  
# NF-4FB          unknown              AGAAGCCAGTTGCAACCGGTTTCTG      25 R00008  




## MOTIFSCANNER
# #ID = M00001-V$MYOD_01
# #W = 12
# #Score = 0.73600134818241
# #Conensus = SRACAGGTGKYG
# 0.208333333333333 0.375           0.375           0.0416666666666667  
# 0.375         0.208333333333333   0.375           0.0416666666666667  
# 0.541666666666667 0.0416666666666667  0.208333333333333   0.208333333333333   
# 0.0416666666666667    0.875           0.0416666666666667  0.0416666666666667  
# 0.875         0.0416666666666667  0.0416666666666667  0.0416666666666667  
# 0.0416666666666667    0.0416666666666667  0.708333333333333   0.208333333333333   
# 0.0416666666666667    0.208333333333333   0.708333333333333   0.0416666666666667  
# 0.0416666666666667    0.0416666666666667  0.0416666666666667  0.875   
# 0.0416666666666667    0.0416666666666667  0.875           0.0416666666666667  
# 0.0416666666666667    0.208333333333333   0.375           0.375   
# 0.0416666666666667    0.375           0.0416666666666667  0.541666666666667   
# 0.208333333333333 0.0416666666666667  0.541666666666667   0.208333333333333   



## TRANSFAC
# AC  M01185
# XX
# ID  V$BCL6_02
# XX
# DT  16.04.2008 (created); vma.
# DT  27.04.2008 (updated); vma.
# CO  Copyright (C), Biobase GmbH.
# XX
# NA  BCL6
# XX
# BF  T09129; BCL-6; Species: human, Homo sapiens.
# XX
# P0      A      C      G      T
# 01      3      0      1      5      W
# 02      3      0      5      1      R
# 03      0      9      0      0      C
# 04      0      0      0     10      T
# 05      0      0      0     10      T
# 06      0      0      0     10      T
# 07      0     10      0      0      C
# 08      0      2      3      5      K
# 09      8      0      0      2      A
# 10      1      2      7      0      G
# 11      1      0      9      0      G
# 12      6      0      4      0      R
# 13      7      1      0      2      A
# 14      0      0      0     10      T
# XX
# BA  10 selected sequences (SELEX)
# XX
# CC  sequence selected from a pool of ds 64-mers containing 26 random base pairs, by GST-fusion protein of the BCL6 zinc finger region, 6 rounds of selection [2]
# XX
# RN  [1]; RE0052624.
# RA  TRANSFAC_Team.
# RT  New matrix entries.
# RL  TRANSFAC Reports Rel122:0001 (2008).
# RN  [2]; RE0052169.
# RX  PUBMED: 7945383.
# RA  Kawamata N., Miki T., Ohashi K., Suzuki K., Fukuda T., Hirosawa S., Aoki N.
# RT  Recognition DNA sequence of a novel putative transcription factor, BCL6.
# RL  Biochem. Biophys. Res. Commun. 204:366-374 (1994).
# XX
# //