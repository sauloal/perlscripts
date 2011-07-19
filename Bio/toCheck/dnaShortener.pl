#!/usr/bin/perl -w
use strict;

my $input = $ARGV[0];
if ( ! (($input) && ( -f $input ))) { die "FILE EITHER NOT FOUND OR NOT EXISTENT\n"; };

my @dnaKey;
my %keyDna;
my @DIGIT_TO_CODE;
my %CODE_TO_DIGIT;
&loadVariables();


open INFILE,   "<$input"      or die "COULD NOT OPEN FILE $input: $!";
open OUTFILE1, ">$input.out2" or die "COULD NOT OPEN FILE $input.out1: $!";
open OUTFILE2, ">$input.out3" or die "COULD NOT OPEN FILE $input.out1: $!";
my $valid   = 0;
my $total   = 0;
my $skipped = 0;
my $nucIn   = 0;
my $nucOut  = 0;
my $nucSkip = 0;
while (my $line = <INFILE>)
{
    $total++;
    $nucIn  += length($line) -1;
    if ($line =~ /[N|n]/)
    {
        $skipped++;
        print "SKIPPED $line";
        $nucSkip += length($line);
        #skip;
    }
    elsif ($line =~ /([A|C|T|G]+)/)
    {
        my $originalSeq = $1;
        my $digit  = &dna2digit2($originalSeq);
        my $recSeq = &digit2dna2($digit);
        print OUTFILE1 "$digit\n";
        print OUTFILE2 "$recSeq\n";
        $nucOut += length($recSeq);
        $valid++;
    }
    else
    {
        die "INVALID LINE $line";
    }
}
close OUTFILE2;
close OUTFILE1;
close INFILE;

print "$valid out of $total ($skipped SKIPPED)\n";
print "IN: $nucIn OUT: $nucOut [" . (int(($nucOut/$nucIn)*100)) . "%] [$nucSkip]\n";
#30619547
#32268651
#1.649.104 1.57m
#FOR 1 MILLION 50BP SEQUENCES
#real   0m26.402s 2 ways
#user   0m26.250s
#sys    0m0.085s
#real   0m15.318s 1 way
#user   0m26.780s
#sys    0m0.109s
#real   0m14.362s 1 WAY NO FILES
#user   0m14.315s
#sys    0m0.028s


#30.8>12.1mb
#30.8>11.6mb = 2.65 (0.38) 2 ways
sub digit2dna2
{
    my $seq  = $_[0];
    my $lengthSeq = length($seq);
    my $outSeq;
#   print "$seq (" . length($seq) . ") > ";
    my $extra = "";
    if ( $seq =~ /([^a|c|t|g|A|C|T|G]*)([a|c|t|g|A|C|T|G]*)/)
    {
        $seq   = $1;
        $extra = uc($2);
    }

    if ($lengthSeq != length("$seq$extra")) { die "ERROR UMPACKING DNA"; };

#   print "$seq (" . length($seq) . ") + $extra (" . length($extra) . ") >> ";

    for (my $s = 0; $s < length($seq); $s+=1)
    {
        my $subSeq  = substr($seq, $s, 1);
        $outSeq    .= $dnaKey[$CODE_TO_DIGIT{$subSeq}];
    }

#   print "$outSeq (" . length($outSeq) . ") -> ";
    $outSeq .= $extra;
#   print "$outSeq (" . length($outSeq) . ")\n\n";
    return $outSeq;
}

sub dna2digit2
{
    my $input = uc($_[0]);
    my $extra = "";
    my $outPut;
#   print "$input (" . length($input) . ") > ";
    while (length($input) % 3) { $extra = chop($input) . $extra; };

#   print "$input (" . length($input) . ") + $extra (" . length($extra) . ")";

#   print "Seq: $input " . length($input) . "\n";
    $input =~ s/\r//g;
    $input =~ s/\n//g;

    for (my $i = 0; $i < length($input); $i+=3)
    {
        my $subInput = substr($input, $i, 3);
        $outPut     .= $DIGIT_TO_CODE[$keyDna{$subInput}];
    }

    if ($extra)
    {
        $outPut .= lc($extra);
    }
#   print " >> $outPut (" . length($outPut) . ")\n";
#   &digit2dna($outputHex);
#   print "Dec: $outputDecStr " . length($outputDec) . "\n";
#   print "Hex: $outputHexStr " . length($outputHex) . "\n";
    return $outPut;
}




#real   2m13.232s 2 WAYS
#user   2m12.576s
#sys    0m0.383s
#real   1m17.088s 1 WAY
#user   1m16.609s
#sys    0m0.300s
#real   1m15.519s 1 WAY NO FILE
#user   1m15.394s
#sys    0m0.069s

#30.8>16.6
sub digit2dna
{
    my $seq       = $_[0];

#   print "$seq (" . length($seq) . ") > ";
    my $extra = "";
    if ( $seq =~ /([[:^lower:]]*)([[:lower:]]+)/)
    {
        $seq   = $1;
        $extra = uc($2);
    }
#   print "$seq (" . length($seq) . ") + $extra (" . length($extra) . ") >> ";

    my $BASE = 4;
    my @str_digits;
    for (my $s = 0; $s < length($seq); $s+=2)
    {
        my $subSeq  = substr($seq, $s, 2);
        my $subs    = 0;

        $subSeq     = hex($subSeq);
        my @digits  = (0) x 4; # cria o array @digits composto de 4 zeros

        my $i = 0; 
#       print "$subSeq\t";
        while ($subSeq) { # loop para decompor o numero
                $digits[4 - ++$i] = $subSeq % $BASE;
                $subSeq = int ($subSeq / $BASE);
        }
#       print "@digits\t"; # imprime o codigo ascII transformado em base 4
        my $subJoin = join("", @digits);
        $subJoin =~ tr/0123/ACGT/;
#       print "$subJoin\n"; # imprime o codigo ascII transformado em base 4
        push @str_digits, $subJoin;    # salva todos os codigos ascII em base
                                        # 4 gerados no array. cada elemento deste
                                        # array ser&#65533; um outro array de 4 elementos..
    }
    my $join = join("", @str_digits);
#   print "$join (" . length($join) . ") -> ";
    $join .= $extra;
#   print "$join (" . length($join) . ")\n\n";
    return $join;
#   print "Hex: $seq  " . length($seq)      . "\n";
#   print "Seq: $join " . length($sequence) . "\n";
}

sub dna2digit
{
    my $input = uc($_[0]);
    my $extra = "";
#   print "$input (" . length($input) . ") > ";
    while (length($input) % 4) { $extra = chop($input) . $extra; };

#   print "$input (" . length($input) . ") + $extra (" . length($extra) . ")";

#     print "Seq: $input " . length($input) . "\n";
    $input =~ s/\r//g;
    $input =~ s/\n//g;
    $input =~ tr/ACGTacgt/01230123/;
#   print "Inp: $input "    . length($input)    . "\n";
    my $outputHex; my $outputHexStr;
    my $outputDec; my $outputDecStr;

    for (my $i = 0; $i < length($input); $i+=4)
    {
        my $subInput = substr($input, $i, 4);
        #print "$i - $subInput\n";
#       my $subInputDec = $subInput;
        my $subInputHex = $subInput;

        $subInputHex =~ s/(.)(.)(.)(.)/(64*$1)+(16*$2)+(4*$3)+$4/gex;
#       $subInputDec =~ s/(.)(.)(.)(.)/(64*$1)+(16*$2)+(4*$3)+$4/gex;

        $subInputHex = sprintf("%X", $subInputHex);
        if (length($subInputHex) <   2) {$subInputHex = "0$subInputHex"; };
#       if ($subInputDec         < 100) {$outputDecStr .= "_" ; };

        $outputHex    .= $subInputHex;
#       $outputHexStr .= "__" . $subInputHex;
# 
#       $outputDec    .= $subInputDec;
#       $outputDecStr .= "_" . $subInputDec;
    }
    if ($extra)
    {
        $outputHex .= lc($extra);
    }
#   print " >> $outputHex (" . length($outputHex) . ")\n";
#   &digit2dna($outputHex);
#   print "Dec: $outputDecStr " . length($outputDec) . "\n";
#   print "Hex: $outputHexStr " . length($outputHex) . "\n";
    return $outputHex;
}






sub loadVariables
{
    $dnaKey[0]  = "AAA";
    $dnaKey[1]  = "AAC";
    $dnaKey[2]  = "AAG";
    $dnaKey[3]  = "AAT";
    $dnaKey[4]  = "ACA";
    $dnaKey[5]  = "ACC";
    $dnaKey[6]  = "ACG";
    $dnaKey[7]  = "ACT";
    $dnaKey[8]  = "AGA";
    $dnaKey[9]  = "AGC";
    $dnaKey[10] = "AGG";
    $dnaKey[11] = "AGT";
    $dnaKey[12] = "ATA";
    $dnaKey[13] = "ATC";
    $dnaKey[14] = "ATG";
    $dnaKey[15] = "ATT";

    $dnaKey[16] = "CAA";
    $dnaKey[17] = "CAC";
    $dnaKey[18] = "CAG";
    $dnaKey[19] = "CAT";
    $dnaKey[20] = "CCA";
    $dnaKey[21] = "CCC";
    $dnaKey[22] = "CCG";
    $dnaKey[23] = "CCT";
    $dnaKey[24] = "CGA";
    $dnaKey[25] = "CGC";
    $dnaKey[26] = "CGG";
    $dnaKey[27] = "CGT";
    $dnaKey[28] = "CTA";
    $dnaKey[29] = "CTC";
    $dnaKey[30] = "CTG";
    $dnaKey[31] = "CTT";

    $dnaKey[32] = "GAA";
    $dnaKey[33] = "GAC";
    $dnaKey[34] = "GAG";
    $dnaKey[35] = "GAT";
    $dnaKey[36] = "GCA";
    $dnaKey[37] = "GCC";
    $dnaKey[38] = "GCG";
    $dnaKey[39] = "GCT";
    $dnaKey[40] = "GGA";
    $dnaKey[41] = "GGC";
    $dnaKey[42] = "GGG";
    $dnaKey[43] = "GGT";
    $dnaKey[44] = "GTA";
    $dnaKey[45] = "GTC";
    $dnaKey[46] = "GTG";
    $dnaKey[47] = "GTT";

    $dnaKey[48] = "TAA";
    $dnaKey[49] = "TAC";
    $dnaKey[50] = "TAG";
    $dnaKey[51] = "TAT";
    $dnaKey[52] = "TCA";
    $dnaKey[53] = "TCC";
    $dnaKey[54] = "TCG";
    $dnaKey[55] = "TCT";
    $dnaKey[56] = "TGA";
    $dnaKey[57] = "TGC";
    $dnaKey[58] = "TGG";
    $dnaKey[59] = "TGT";
    $dnaKey[60] = "TTA";
    $dnaKey[61] = "TTC";
    $dnaKey[62] = "TTG";
    $dnaKey[63] = "TTT";


    for (my $k = 0; $k < @dnaKey; $k++)
    {
        $keyDna{$dnaKey[$k]} = $k;
    }


    @DIGIT_TO_CODE = qw (0 1 2 3 4 5 6 7 8 9 b d e f h i j k l m n o p q r s u v w x y z B D E F H I J K L M N O P Q R S U V W X Y Z ! - = + ] [ : > < . ? );
    #                    0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5
    #                    0                   10                  20        25        30        35        40  42              50                  60                  70                  80        85

    for (my $i = 0; $i < @DIGIT_TO_CODE; $i++)
    {
        $CODE_TO_DIGIT{$DIGIT_TO_CODE[$i]} = $i;
    }
}

1;