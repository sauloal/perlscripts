#!/usr/bin/perl
use strict;
#use warnings;

use constant MEGABYTE => 2 ** 20;
my $sysBits = 32;



my $inFile = $ARGV[0];

if ( ! $inFile )
{
	die "please define input fasta file\n\n";
}
else
{
	if ( ! -f $inFile )
	{
		die "specified input fasta file doesnt exists :: $inFile\n\n";
	}
}

my $doComp  = 0;
my $doRev   = 0;
my $doRc    = 0;
my $outName = $inFile;
   $outName =~ s/\.\w{2,5}$//;

my $A = 0; # BIN 00
my $C = 1; # BIN 01
my $G = 2; # BIN 10
my $T = 3; # BIN 11

#TODO: CREATE PACK FASTA WHICH CALLS SEVERAL PACK SEQUENCE
# PACK FASTA SHOULD CREATE A HEADER CONTAINING NAMES AND START POSITION OF
# EACH SEQUENCE INSIDE
# EG:
#<TOTAL HEADER SIZE>
#<POS SEQ 1><LENG SEQ 1><LENG NAME SEQ 1><NAME SEQ 1>[POS DESCRIBED BY <LENG NAME SEQ1>]
#<POS SEQ 2><LENG SEQ 2><LENG NAME SEQ 2><NAME SEQ 2>[POS DESCRIBED BY <LENG NAME SEQ2>][POS DESCRIBED <BY HEADER SIZE>]
#[POS <DESCRIBED BY POS SEQ1>]<LENG SEQ 1><SEQ1>[POS <DESCRIBED BY POS SEQ2>]<LENG SEQ2><SEQ2>[EOF]

my $sTime = time;
my $tTime;

$tTime = time;
print "LOADING FASTA...\n";
my $dna      = &loadFastaBin($inFile);
#my $dna = &loadTemplate();
my $dnaCount = (keys %{$dna});
print "\tFASTA LOADED [$dnaCount seqs]",(time - $tTime),"s\n\n";



$tTime = time;
print "PACKING FASTA...\n";
my $fastaBin = &packFastaBin($dna);
print "\tFASTA PACKED ",(time - $tTime),"s\n\n";



$tTime = time;
print "SAVING BINARY FASTA...\n";
&saveBinFile($fastaBin, "fasta");
print "\tBINARY FASTA SAVED ",(time - $tTime),"s\n\n";



$tTime = time;
print "UNPACKING BINARY FASTA...\n";
my $fastaRet = &unpackFasta($fastaBin);
print "\tBINARY FASTA UNPACKED ",(time - $tTime),"s\n\n";
exit 0;


$tTime = time;
print "CONVERTING FASTA HASH...\n";
my $fastaRetStr = &printFasta($fastaRet);
print "\tFASTA HASH CONVERTED ",(time - $tTime),"s\n\n";



$tTime = time;
print "SAVING ASC FASTA FILE...\n";
&saveAscFile($fastaRetStr, "fasta");
print "\tASC FASTA FILE SAVES ",(time - $tTime),"s\n\n";



print "TOTAL TIME: ",(time - $sTime),"\n";





sub printFasta
{
    my $fastaHash = $_[0];
    my $strOut    = '';

    foreach my $key (keys %{$fastaHash})
    {
        my $value = $fastaHash->{$key};
        $strOut  .= ">$key\n$value\n\n";
    }

    return $strOut;
}

sub unpackFasta
{
    my $binIn  = $_[0];
    my $header = '';
    #my $data   = '';
    #print "$binIn\n";
    my %hashOut;
    my %topstat;

    my $fileOut = $outName . ".fasta.txt";

    #print "EXPORTING TO $fileOut\n";
    open(my $FL, ">$fileOut") or die "can't open $fileOut: $!";

   
    #<TOTAL HEADER SIZE><TOTAL HEADER COUNT><TOTAL DATA SIZE><TOTAL FILE SIZE>
    #<POS SEQ 1><LENG SEQ 1><LENG NAME SEQ 1><NAME SEQ 1>[POS DESCRIBED BY <LENG NAME SEQ1>]
    #<POS SEQ 2><LENG SEQ 2><LENG NAME SEQ 2><NAME SEQ 2>[POS DESCRIBED BY <LENG NAME SEQ2>][POS DESCRIBED <BY HEADER SIZE>]
    #[POS <DESCRIBED BY POS SEQ1>]<LENG SEQ 1><SEQ1>[POS <DESCRIBED BY POS SEQ2>]<LENG SEQ2><SEQ2>[EOF]
    #<12><2><4><16> <12><1><1><seq1> <14><1><1><seq2> <17><CTGACCAATCACGGACA><22><CAAGTGTGGAGTGAGACCAAGT>[EOF]
    #0   1  2  3    4   5  6  7      8   9  10 11     12
    $topstat{totalHeaderSize} = vec( $binIn, 0, $sysBits );
    $topstat{headerCount}     = vec( $binIn, 1, $sysBits );
    $topstat{totalDataSize}   = vec( $binIn, 2, $sysBits );
    $topstat{totalFileSize}   = vec( $binIn, 3, $sysBits );

    if (0)
    {
        print "TOTAL HEADER SIZE  = ", $topstat{totalHeaderSize} ,"\n";
        print "TOTAL HEADER COUNT = ", $topstat{headerCount}     ,"\n";
        print "TOTAL DATA SIZE    = ", $topstat{totalDataSize}   ,"\n";
        print "TOTAL FILE SIZE    = ", $topstat{totalFileSize}   ,"\n";
    }
   
    #<POS SEQ 1><LENG SEQ 1><LENG NAME SEQ 1><NAME SEQ 1>[POS DESCRIBED BY <LENG NAME SEQ1>]
    #<12><1><1><seq1> <14><1><1><seq2> <17><CTGACCAATCACGGACA><22><CAAGTGTGGAGTGAGACCAAGT>[EOF]
    #4   5  6  7      8   9  10 11     12  13                 14  15
   
    my $cursor = 4;
   	my $data   = '';

    for (my $seq = 0; $seq < $topstat{headerCount}; $seq++)
    {
        print "\tEXTRACTING SEQUENCE # $seq\n";
        my $seqPosSys   = vec( $binIn, ($cursor + 0), $sysBits );
        my $seqLengSys  = vec( $binIn, ($cursor + 1), $sysBits );
        my $nameLeng    = vec( $binIn, ($cursor + 2), $sysBits );
        my $nameLengSys = ($nameLeng * 8) / $sysBits;
        if ($nameLengSys > (int($nameLengSys))) { $nameLengSys = int($nameLengSys += 1); };
       
        if (1)
        {
            print "SEQPOSSYS: $seqPosSys SEQLENGSYS: $seqLengSys NAMELENG: $nameLeng NAMELENGSYS: $nameLengSys\n";
        }
       
        my $title = '';

        for (my $s = 0; $s < $nameLengSys; $s++)
        {
            vec($title, $s, $sysBits) = vec( $binIn, ($cursor + 3 + $s), $sysBits );
        }
       
        my $seqName = '';
        for (my $c = 0; $c < $nameLeng; $c++)
        {
            $seqName .= chr(vec( $title, $c, 8));
        }
       
        if (1)
        {
            print "   EXTRACTING SEQ #$seq : $seqName (", ($seqLengSys * ($sysBits/2)) ,"bp)\n";
        }
   
        $cursor += 3 + $nameLengSys;
       
        $data = '';
        for (my $d = $seqPosSys; $d < ($seqPosSys + $seqLengSys + 1); $d++)
        {
            #print "D: $d SEQPOSSYS_START: $seqPosSys SEQPOSSYS_END: ",($seqPosSys + $seqLengSys + 1),"\n";
            #print "DATA: ",($d - $seqPosSys)," VEC: $d\n\n";
           
            vec( $data, ($d - $seqPosSys), $sysBits ) = vec( $binIn, $d, $sysBits );
        }

        #my $bits = unpack("b*", $data);
        #print "$seq: $bits > ",unPackDNA($data),"\n";


	    print $FL ">", $seqName, "\n";
	    print $FL &unPackDNA($data), "\n\n";
        #$hashOut{$seqName} = unPackDNA($data);
       
		if (1)
		{
		    print "SEQ #: $seq SEQPOSSYS: $seqPosSys SEQLENGSYS: $seqLengSys NAMELENG: $nameLeng NAMELENGSYS: $nameLengSys\n";
		    print "NAME: \"$title\" CURSOR: $cursor\n";
		    #print "DATA: \"$data\" > \"",unPackDNA($data),"\"\n\n\n\n\n";
		}
    } # end foreach my seq

    close $FL;
   
    #return \%hashOut;
}


sub packFastaBin
{
    my $fastaHash   = $_[0];
    my $header      = '';
    my $body        = '';
    my $headerS     = "";
    my $bodyS       = "";
    my $binOut      = '';
    my $headerCount = 0;
    my @headerArray;
    my %topstat;

   
    foreach my $name (keys %{$fastaHash})
    {
        my $value         = $fastaHash->{$name}[0];

        my $nameLen       = length($name);
        my $nameLenSys    = ($nameLen * 8) / $sysBits;

        my $valueLen      = $fastaHash->{$name}[1];
        my $valueLenSys   = ($valueLen * 2) / $sysBits;
       
        if ( $nameLenSys  > int($nameLenSys)  ) { $nameLenSys  = int($nameLenSys)  + 1; };
        if ( $valueLenSys > int($valueLenSys) ) { $valueLenSys = int($valueLenSys) + 1; };
       
        #print "VALUELENSYS = $valueLenSys\n";
       
        #while ($nameLenSys  % $sysBits) { $nameLenSys++ ; };
        #while ($valueLenSys % $sysBits) { $valueLenSys++; };
       
        #$nameLenSys  = int(($nameLenSys  / $sysBits) + 0.5);
        #$valueLenSys = int(($valueLenSys / $sysBits) + 0.5);
       
        $headerArray[$headerCount]{name}       = $name;
        $headerArray[$headerCount]{nameLen}    = $nameLen;
        $headerArray[$headerCount]{nameLenSys} = $nameLenSys; # to fix. always next int, not round
       
        $headerArray[$headerCount]{data}       = $value;
        $headerArray[$headerCount]{dataLen}    = $valueLen;
        $headerArray[$headerCount]{dataLenSys} = $valueLenSys;

        $topstat{headerSize} += $nameLenSys;
        $topstat{fileSize}   += $valueLenSys;
        $topstat{nucCount}   += $valueLen;
       
        #print "NAME $name NAMELEN $nameLen NAMELENSYS $nameLenSys DATA $value DATALEN $valueLen DATALENSYS $valueLenSys\n";
       
        $headerCount++;
    }
   
    $topstat{headerCount}     = $headerCount;

    #                           sum of names length  +   number of seqs        * 3 fields  + initial 4 fields
    $topstat{totalHeaderSize} = $topstat{headerSize} + ( $topstat{headerCount} * 3       ) + 4;

    #                           size of data sys    + size descriptor      
    $topstat{totalDataSize}   = $topstat{fileSize}  + $topstat{headerCount};
   
    #                           header                    + data
    $topstat{totalFileSize}   = $topstat{totalHeaderSize} + $topstat{totalDataSize};
   
   
    if (0)
    {
        print "TOTAL HEADER SIZE  = ", $topstat{totalHeaderSize} ,"\n";
        print "TOTAL HEADER COUNT = ", $topstat{headerCount}     ,"\n";
        print "      HEADER SIZE  = ", $topstat{headerSize}      ,"\n";
        print "TOTAL DATA SIZE    = ", $topstat{totalDataSize}   ,"\n";
        print "TOTAL FILE SIZE    = ", $topstat{totalFileSize}   ,"\n";
        print "      FILE SIZE    = ", $topstat{fileSize}        ,"\n";
    }
   
    vec( $header, 0, $sysBits ) = $topstat{totalHeaderSize};
    vec( $header, 1, $sysBits ) = $topstat{headerCount};
    vec( $header, 2, $sysBits ) = $topstat{totalDataSize};
    vec( $header, 3, $sysBits ) = $topstat{totalFileSize};

    $headerS .= "<" . $topstat{totalHeaderSize} . ">";
    $headerS .= "<" . $topstat{headerCount}     . ">";
    $headerS .= "<" . $topstat{totalDataSize}   . ">";
    $headerS .= "<" . $topstat{totalFileSize}   . ">";
   
    my $accStart = 0;
    my $lastBin  = 0;

    for (my $h = 0; $h < @headerArray; $h++)
    {
        my $data  = $headerArray[$h];
        $bodyS   .= "<" . $data->{dataLen}  . ">"; #DATA LENG IN BASES
        $bodyS   .= "<" . $data->{data}     . ">"; #DATA ITSELF
        my $bin   = &packDNABin($data->{dataLen}, $data->{data});

        $body    .= $bin;

        #print "bodyLen: ",(length($bin)),"\n";

        #for (my $i = 0; $i < 20; $i++)
        #{
        #    print "BIN I: $i :: ",vec( $body, $i, $sysBits),"\n";
        #}

        my $dStart = $topstat{totalHeaderSize};
        $headerS  .= "<" . ($dStart + $accStart) . ">"; #SEQ START SYS
        $headerS  .= "<" . $data->{dataLenSys}   . ">"; #DATA LENG SYS
        $headerS  .= "<" . $data->{nameLen}      . ">"; #NAME LENG
        $headerS  .= "<" . $data->{name}         . ">"; #NAME
       
        my $headerL = '';
        vec( $headerL, 0, $sysBits ) = ($dStart + $accStart); # SEQ START SYS
        vec( $headerL, 1, $sysBits ) = $data->{dataLenSys};   # DATA LENG SYS
        vec( $headerL, 2, $sysBits ) = $data->{nameLen};      # NAME LENG

        #print "ACCSTART: $accStart\t";
        $accStart += ($data->{dataLenSys}) + 1;
        #print "ACCSTART: $accStart DATALENSYS: ",($data->{dataLenSys}),"\n";
       
        my $title = '';
        for (my $c = 0; $c < $data->{nameLen}; $c++)
        {
            my $char = substr($data->{name}, $c, 1);
            vec( $title, $c, 8) = ord($char);
        }
       
        my $curr = $data->{nameLen};

        while (($curr * 8) % $sysBits)
        {
            #print "CUR: $curr (", $data->{nameLen}, ")\n";
            vec( $title, $curr++, 8) = 0;
        }
       
        #for (my $i = 0; $i < $curr; $i++)
        #{
        #    print "BIN I: $i :: ",chr(vec( $title, $i, 8)),"\n";
        #}
        $headerL .= $title;
        $header  .= $headerL;
    }
   
    #print "$headerS$bodyS\n";
    #print "$header$body\n";
    #print "$body\n";
    $binOut = $header . $body;
   
    #for (my $i = 0; $i < 20; $i++)
    #{
    #    print "I: $i :: ",vec( $binOut, $i, $sysBits),"\n";
    #}
   
    #print "$binOut\n";
    return $binOut;
   
   
    #TODO: CREATE PACK FASTA WHICH CALLS SEVERAL PACK SEQUENCE
    # PACK FASTA SHOULD CREATE A HEADER CONTAINING NAMES AND START POSITION OF
    # EACH SEQUENCE INSIDE
    # EG:
    #<TOTAL HEADER SIZE><TOTAL HEADER COUNT><TOTAL DATA SIZE><TOTAL FILE SIZE>
    #<POS SEQ 1><LENG SEQ 1><LENG NAME SEQ 1><NAME SEQ 1>[POS DESCRIBED BY <LENG NAME SEQ1>]
    #<POS SEQ 2><LENG SEQ 2><LENG NAME SEQ 2><NAME SEQ 2>[POS DESCRIBED BY <LENG NAME SEQ2>][POS DESCRIBED <BY HEADER SIZE>]
    #[POS <DESCRIBED BY POS SEQ1>]<LENG SEQ 1><SEQ1>[POS <DESCRIBED BY POS SEQ2>]<LENG SEQ2><SEQ2>[EOF]
    # for example:
    #$dna{seq1} = "CTGACCAATCACGGACA";
    #$dna{seq2} = "CAAGTGTGGAGTGAGACCAAGT";
    #<88><2><26><114><88><17><4><seq1><122><22><4><seq2><17><CTGACCAATCACGGACAAAA><22><CAAGTGTGGAGTGAGACCAAGTAA>
    #|   |  |   |    |   |   |  |     |    |   |  |    ||   |                     |   |
    #|   |  |   |    |   |   |  |     |    |   |  |    ||   |                     |   '-> SEQ2 DATA
    #|   |  |   |    |   |   |  |     |    |   |  |    ||   |                     '-----> SEQ2 LENGTH
    #|   |  |   |    |   |   |  |     |    |   |  |    ||   '---------------------------> SEQ1 SEQUENCE
    #|   |  |   |    |   |   |  |     |    |   |  |    |'-------------------------------> SEQ1 LENGTH
    #|   |  |   |    |   |   |  |     |    |   |  |    '--------------------------------> --- DATA ---
    #|   |  |   |    |   |   |  |     |    |   |  '-------------------------------------> SEQ2 NAME
    #|   |  |   |    |   |   |  |     |    |   '----------------------------------------> LENGTH SEQ2 NAME
    #|   |  |   |    |   |   |  |     |    '--------------------------------------------> LENGTH SEQ2 DATA
    #|   |  |   |    |   |   |  |     '-------------------------------------------------> START POS SEQ2 (HEADER + SEQ1 DATA)
    #|   |  |   |    |   |   |  '-------------------------------------------------------> SEQ1 NAME
    #|   |  |   |    |   |   '----------------------------------------------------------> LENGTH SEQ1 NAME
    #|   |  |   |    |   '--------------------------------------------------------------> LENGTH SEQ1 DATA
    #|   |  |   |    '------------------------------------------------------------------> START POS SEQ1
    #|   |  |   '-----------------------------------------------------------------------> TOTAL FILE SIZE (88 + 26)
    #|   |  '---------------------------------------------------------------------------> TOTAL DATA SIZE
    #|   '------------------------------------------------------------------------------> NUMBER OF SEQUENCES
    #'----------------------------------------------------------------------------------> TOTAL HEADER SIZE/START DATA
    # OR IN BINARY:
    #    X   ?   ?   r   X   ?   ?seq1   z   ?   ?seq2   ¶-?GJ    ?ü??"??
}




sub rcDNA
{
    my $input = $_[0];

    $input = reverseDNA($input);
    $input = compDNA($input);

    return $input;
}

sub compDNA
{
    my $bin = $_[0];

    my $n   = vec( $bin, 0, $sysBits );
    $bin    = ~$bin;
    vec( $bin, 0, $sysBits ) = $n;
   
    return $bin;
}

sub reverseDNA
{
    my $bin              = $_[0];
    my $binRev           = '';
    #my $bitsO            = unpack("b*", $bin);
    my $n                = vec( $bin, 0, $sysBits );
    vec( $binRev, 0, $sysBits ) = $n;
   
    for (my $r = 0; $r < $n; $r++)
    {
        vec( $binRev, $r + ($sysBits/2), 2 ) = vec( $bin, ($n - $r + ($sysBits/2) - 1), 2 );
    }
   
    #my $bits    = unpack("b*", $bin);
    #my $bitsR   = unpack("b*", reverse($bin));
    #my $bitsRev = unpack("b*", $binRev);
    #print "BITSO:   $bitsO\nBITS:    $bits\nBITSR:   $bitsR\nBITSREV: $bitsRev\n";
   
    #exit 0;
    return $binRev;
}

sub unPackDNA
{
    my $bin = $_[0];
    my $strD;
    my $strS;

    my $n = vec( $bin, 0, $sysBits );
    #print "N: $n\n";
    for (my $p = 0; $p < $n ; $p++)
    {
        $strD .= vec( $bin, $p + ($sysBits/2), 2 );
    }

    $strS = $strD;
    $strS =~ tr/0123/ACGT/;
    #print "$strD > $strS\n";
    #print "$strS\n";
    return $strS;
}

sub toNum
{
	my $inputD = $_[0];

       $inputD =~ tr/ACGT/0123/d;
       $inputD =~ s/[^0123]//g;

	return $inputD;
}

sub packDNA
{
    my $input  = $_[0];
    my $inputD = $input;
	   $inputD = &toNum($inputD);

    my $n      = length($inputD);

    my $bin    = '';

    #print "CONVERTING STRING $input ($inputD) [$n]:\n";
    vec( $bin, 0, $sysBits ) = $n;
   
	$bin .= &genBin($n, $inputD);
   
    #17bp * 2 = 34 bits % 32 = + 62
    while (  $n % ($sysBits / 2) )
    {
        # if not multiple of byte, zero pad
        #print "$n padding....";
        my $point = (($sysBits / 2) + $n);
        #print "N:$n N*2:", ($n*2), " POINT: $point\t";
        vec( $bin, $point, 2 ) = 0;
        $n++;
    }

    #print "N: $n BYTES: ", length($bin)," bits: ",(length($bin) * 8)," sys: ", ((length($bin) * 8)/32),"\n";

    #printf "BIN: %b VEC2: %s\n", $bin, $vector2;
    #my $bits = unpack("b*", $bin);
    #print "$n $bits > ",&unPackDNA($bin),"\n";

    return $bin;
}

sub packDNABin
{
    my $n      = $_[0];
    my $oldBin = $_[1];
	my $bin    = '';
	vec( $bin, 0, $sysBits ) = $n;
	$bin      .= $oldBin;
   
    #17bp * 2 = 34 bits % 32 = + 62
    while (  $n % ($sysBits / 2) )
    {
        # if not multiple of byte, zero pad
        #print "$n padding....";
        my $point = (($sysBits / 2) + $n);
        #print "N:$n N*2:", ($n*2), " POINT: $point\t";
        vec( $bin, $point, 2 ) = 0;
        $n++;
    }

    return $bin;
}

sub genBin
{
	my $n      = $_[0];
	my $inputD = $_[1];
	my $bin    = '';

    for (my $p = 0; $p < $n; $p++)
    {
        my $nucD      = substr($inputD, $p, 1);
        #my $offset    = (($n*2) - ($p * 2) - 2);
        #print "\tP > $p\tNUC > $nucD\n";
        #                as we're counting in two-by-two, the sysbyte is divided by two
        vec( $bin, $p, 2 ) = $nucD;
       
        #my $nucDshift = $nucD << $offset;
        #$bin = $bin | $nucDshift;
        #print "POS $p IS $nucD SHIFTED IS $nucDshift $offset = (" , ($n * 2), " - ", ($p * 2), ") = (", (($n*2) - ($p * 2)),") >> $bin\n";
        #printf "POS %02d IS %d (+%02d pos) IS %010u (%0". ($n*2) . "b) >> %010u\n", $p, $nucD, $offset, $nucDshift, $nucDshift, $bin;
    }

	die if (length($bin) == 0);
	return $bin;
}

sub truncate
{
    my $in  = $_[0];
    my $out = "";

    if (length $in > 32)
    {
        $out  = substr($in, 0, 13);
        $out .= " .... ";
        $out .= substr($in, length($in) - 13);
    }

    return $out;
}

sub saveAscFile
{
    my $DATA = $_[0];
    my $ext  = $_[1];
    my $fileOut = $outName . ".$ext.txt";

    #print "EXPORTING TO $fileOut\n";
    open(my $FL, ">$fileOut") or die "can't open $fileOut: $!";
    print $FL $DATA;
    close $FL;
}

sub saveBinFile
{
    my $DATA    = $_[0];
    my $ext     = $_[1];
    my $fileOut = $outName . ".$ext.dat";

    #print "EXPORTING TO $fileOut\n";
    open(my $FL, ">$fileOut") or die "can't open $fileOut: $!";
    binmode($FL);
    print $FL $DATA;
    close $FL;
}

























sub test
{
    my $name   = $_[0];
    my $string = $_[1];

    my $strLen = length($string);
   
    die if ( ! $strLen );
    my $pattern = "%-11s : \"%-32s\" CHAR [%04d bytes (%04d bits)]\n";
    my $outS    = "";
    my $outB    = "";
   
    my $binary  = packDNA($string);
    my $return  = unPackDNA($binary);
   
    my $pString = $string;
    my $pReturn = $return;
    my $pBinary = $binary;
   
    if (length($pString) > 32) { $pString = &truncate($pString) };
    if (length($pReturn) > 32) { $pReturn = &truncate($pReturn) };
    if (length($pBinary) > 32) { $pBinary = &truncate($pBinary) };
   
    $outS .= sprintf $pattern, "THEORETICAL", $pString,  $strLen ,         $strLen,          ($strLen*8);
    $outS .= sprintf $pattern, "RETURN",      $pReturn,  length($return),  length($return),  (length($return)*8);
    $outB .= sprintf $pattern, "BINARY",      $pBinary,  length($binary),  length($binary),  (length($binary)*8);
    &saveAscFile($string, "$name.orig");
    &saveBinFile($binary, "$name.orig");
   

    if ($doComp)
    {
        my $compBin    = compDNA($binary);
        my $comp       = unPackDNA($compBin);
     
        my $pComp     = $comp;
        my $pCompBin  = $compBin;
       
        if (length($pComp)    > 32) { $pComp    = &truncate($pComp)    };
        if (length($pCompBin) > 32) { $pCompBin = &truncate($pCompBin) };
       
        $outS .= sprintf $pattern, "RETURN COMP", $pComp,    length($comp),    length($comp),    (length($comp)*8);
        $outB .= sprintf $pattern, "BINARY COMP", $pCompBin, length($compBin), length($compBin), (length($compBin)*8);
        &saveAscFile($comp,    "$name.comp");
        &saveBinFile($compBin, "$name.comp");
   
    }
   
    if ($doRev)
    {
        my $revBin  = reverseDNA($binary);
        my $rev     = unPackDNA($revBin);
       
        my $pRev    = $rev;
        my $pRevBin = $revBin;
       
        if (length($pRev)    > 32) { $pRev    = &truncate($pRev)    };
        if (length($pRevBin) > 32) { $pRevBin = &truncate($pRevBin) };
       
        $outS .= sprintf $pattern, "RETURN REV",  $pRev,     length($rev),     length($rev),     (length($rev)*8);
        $outB .= sprintf $pattern, "BINARY REV",  $pRevBin,  length($revBin),  length($revBin),  (length($revBin)*8);
        &saveAscFile($rev,    "$name.rev");
        &saveBinFile($revBin, "$name.rev");
    }
   
    if ($doRc)
    {
        my $rcBin      = rcDNA($binary);
        my $rc         = unPackDNA($rcBin);
       
        my $pRc         = $rc;
        my $pRcBin      = $rcBin;
       
        if (length($pRc)    > 32) { $pRc    = &truncate($pRc) };
        if (length($pRcBin) > 32) { $pRcBin = &truncate($pRc) };
       
        $outS .= sprintf $pattern, "RETURN RC",   $pRc,      length($rc),      length($rc),      (length($rc)*8);
        $outB .= sprintf $pattern, "BINARY RC",   $pRcBin,   length($rcBin),   length($rcBin),   (length($rcBin)*8);
        &saveAscFile($rc,    "$name.rc");
        &saveBinFile($rcBin, "$name.rc");
    }
   
    #printf "%0.1fM\n", length( $vector2 ) / MEGABYTE;
   
    my $strSize  = size($string);
    my $binSize  = size($binary);
    my $unpSize  = size($return);
    print "SEQUENCE: $name\n";
    print "ACTUAL SIZE : STR: $strSize bits vs BIN: $binSize bits vs RETURN: $unpSize bits\n";
    print "$outS\n";
    print "$outB\n\n";
   
   
   
    #&searchBin($binary, packDNA("GGGGTGGCACCCCAA"));
    #&searchBin($binary, packDNA("GGGGTGGCACCCCA"));
    #&searchBin($binary, packDNA("GGGGTGGCACCCC"));
    #&searchBin($binary, packDNA("GGGGTGGCACCC"));
    #&searchBin($binary, packDNA("GGGGTGGCACC"));
    #&searchBin($binary, packDNA("GGGGTGGCAC"));
    #&searchBin($binary, packDNA("GGGGTGGCA"));
    #&searchBin($binary, packDNA("GGGGTGGC"));
    #&searchBin($binary, packDNA("GGGGTGG"));
    #&searchBin($binary, packDNA("GGGGTG"));
    #&searchBin($binary, packDNA("GGGGT"));
    #&searchBin($binary, packDNA("GGGG"));
    #&searchBin($binary, packDNA("GGG"));
    #&searchBin($binary, packDNA("GG"));
    #&searchBin($binary, packDNA("G"));
    #0102110030000310
   
}









sub searchBin
{
    my $template = $_[0];
    my $pattern  = $_[1];

    #print "SEARCHING FOR PATTERN \"$pattern\"\n";
    my $tBin     = length(unpack("b*", $template)) / 2;
    my $t        = length($template);
    my $pLenBin  = length(unpack("b*", $pattern))  / 2;
    my $pLen     = length($pattern);

    #$pLen = &nextBaseTwo($pLen);

    my $w = 0;
    print "N = $tBin\tpLEN ($pattern)= $pLen\tpLenBin = $pLenBin\n";

   
    for (my $p = 0; $p < $tBin; $p++)
    {
        my $fail = 0;
        my $i    = 0;
        while (vec($pattern, $i, 2))
        {
            if (vec($pattern, $i, 2) != vec( $template, $p + $i, 2 )) { $fail = 1; }
            $i++;
            last if $fail;
        }

        next if $fail;
        my $frag = substr($template, int($p/4), $pLen + 1);
        print "N = $tBin\tpLEN = $pLenBin\tP = $p\tFRAG = $frag\tPAT = $pattern\n";
        print "FRAG = ",unPackDNA($frag),"\nPAT  = ","_"x($p % 4), unPackDNA($pattern),"_"x(($p + $pLenBin + ($p % 4) - 1) % 4),"\n\n";
    }
}





sub searchBin2
{
    my $template = $_[0];
    my $pattern  = $_[1];

    print "SEARCHING FOR PATTERN \"$pattern\"\n";
    my $pLen     = length($pattern);
    my $n        = length($template);
    my $pLenBin  = $pLen * 4;
    my $nBin     = $n    * 4 - $pLenBin;

    #$pLen = &nextBaseTwo($pLen);

    print "N = $nBin\tpLEN = $pLenBin\n";
   
    for (my $p = 0; $p < $nBin; $p++)
    {
        my $frag = '';
        for (my $i = 0; $i < $pLenBin; $i++)
        {
            vec($frag, $i, 2) = vec( $template, $p + $i, 2 );
        }

        if ($frag eq $pattern)
        {
            print "N = $nBin\tpLEN = $pLenBin\tP = $p\tFRAG = $frag\tPAT = $pattern\n";
        }
    }
}

















sub readFile
{
    my $fileName = $_[0];

    open(my $FL, "<$fileName") or die "can't open $fileName: $!";
    binmode($FL);

    return $FL;
}

sub readFile3
{
    my $gifname = "picture.gif";

    open(GIF, $gifname)         or die "can't open $gifname: $!";
    my $buff;

    binmode(GIF);               # now DOS won't mangle binary input from GIF
    binmode(STDOUT);            # now DOS won't mangle binary output to STDOUT
   
    while (read(GIF, $buff, 8 * 2**10))
	{
        print STDOUT $buff;
    }
}

sub readFile2
{
    open I, '<:raw', $ARGV[0] or die $!;
    my $regex = $ARGV[1] or die 'No search pattern supplied.';
   
    my $o = 0;
    my $buffer;
   
    ## Read into the buffer after any residual copied from the last chunk
    while( my $read = read I, $buffer, 4096, pos( $buffer )||0 )
	{
        while( $buffer =~ m[$regex]gc )
		{
   
            ## Print the offset, the matched text plus (following) context
            print $o + $-[0], ':', substr $buffer, $-[0], 100;
	    }
   
        ## Slide the unsearched remainer to the front of the buffer.
        substr( $buffer, 0, pos( $buffer ) ) = substr $buffer, pos( $buffer );
   
        $o += $read; ## track the overall offset.
    }
   
    close I;
}


sub log_base {
    my ($base, $value) = @_;
    return log($value)/log($base);
}


sub nextBaseTwo
{
    my $in = $_[0];
   
    for ( my $log = &log_base(2, $in) ; $log - int($log) > 0 ; $log = &log_base(2, $in))
    {
    #    print "\&log_base(2, $in) = ",&log_base(2, $in),"\n";
        $in++
    };
   
    return $in;
}



my $string = "";
#$string .= "AAACAGATCACCCGCTGAGCGGGTTATCTGTT";
#$string .= "ACGTACGTACGTACGTG";
#$string .= "ACGTACGTACGTACGT";
#$string .= "ACGTACGTACGTACG";
#$string .= "ACGTACGTACGTAC";
#$string .= "ACGTACGTACGTA";
#$string .= "ACGTACGTACGT";
#$string .= "ACGTACGTACG";
#$string .= "ACGTACGTAC";
#$string .= "ACGTACGT";
#$string .= "ACGTACG";
#$string .= "ACGTAC";
#$string .= "ACGTA";
#$string .= "ACGT";
#$string .= "ACG";
#$string .= "AC";
#$string .= "A";

#$string .= "AAAAAAAAAAAAAAAA";
#$string .= "CCCCCCCCCCCCCCCC";
#$string .= "GGGGGGGGGGGGGGGG";
#$string .= "TTTTTTTTTTTTTTTT";
#$string .= "CGCGCGCGCGCGCGCG";

#$string    = $dna;


sub loadTemplate
{
	$outName = $0;
	$outName =~ s/\.\w{2,5}$//;

    my %dnaT;
    $dnaT{"VERY VERY VERY LONG TITLE FOR seq1"}[0] ="CTGACCAATCACGGACA";
    $dnaT{"VERY VERY VERY LONG TITLE FOR seq2 ex"}[0] = "CAAGTGTGGAGTGAGACCAAGT";
    $dnaT{"VERY VERY VERY LONG TITLE FOR seq3 extended"}[0] = "GTGTGGGGCTCTCCAGGTGGGGAGGGCACAGGGGACCTGGACGAATTTGACTTCTGAGACC
AACACTACACTTGACCCTTCACGGAATCCAGACTCTTCCTGGACTGGCTTGCCTCCTCCCCACCTCCCCA
CCCTGGAACCCCTGAGGGCCAAACAGCAGAGTGGAGCTGAGCTGTGGACCTCTCGGGCAACTCTGTGGGT
GTGGGGGCCCTGGGTGAATGCTGCTGCCCCTGCTGGCAGCCACCTTGAGACCTCACCGGGCCTGTGATAT
TTGCTCTCCTGAACTCTCACTCAATCCTCTTCCTCTCCTCTGTGGCTTTTCCTGTTATTGTCCCCTAATG
ATAGGATATTCCCTGCTGCCTACCTGGAGATTCAGTAGGATCTTTTGAGTGGAGGTGGGTAGAGAGAGCA
AGGAGGGCAGGACACTTAGCAGGCACTGAGCAAGCAGGCCCCCACCTGCCCTTAGTGATGTTTGGAGTCG
TTTTACCCTCTTCTATTGAATTGCCTTGGGATTTCCTTCTCCCTTTCCCTGCCCACCCTGTCCCCTACAA
TTTGTGCTTCTGAGTTGAGGAGCCTTCACCTCTGTTGCTGAGGAAATGGTAGAATGCTGCCTATCACCTC
CAGCACAATCCCAGTGAAAAAG";
    $dnaT{seqT}[0] =
"CTGACCAATCACGGACAGCGATTGATATTTCTAATCGTCGTGATCCACCTCCCCAGGACCTTGGAGCCAC
GTTTACAAATAGGAATAGGGTACGTGGGAGGGATAGAACGTACAGCCAATAAAATCATGTGGCGCCGATG
GGCGTGTTGAGGCCGCTGCCTGGCTTAGGGCGGAAACAGATTCTCTGCATAAGAAGGGGAACGAAAGATG
GCGGCGGAAACGCTGCTGTCCAGTTTGTTAGGACTGCTGCTTCTGGGACTCCTGTTACCCGCAAGTCTGA
CCGGCGGTGTCGGGAGCCTGAACCTGGAGGAGCTGAGTGAGATGCGTTATGGGATCGAGATCCTGCCGTT
GCCTGTCATGGGAGGGCAGAGCCAATCTTCGGACGTGGTGATTGTCTCCTCTAAGTACAAACAGCGCTAT
GAGTGTCGCCTGCCAGCTGGAGCTATTCACTTCCAGCGTGAAAGGGAGGAGGAAACACCTGCTTACCAAG
GGCCTGGGATCCCTGAGTTGTTGAGCCCAATGAGAGATGCTCCCTGCTTGCTGAAGACAAAGGACTGGTG
GACATATGAATTCTGTTATGGACGCCACATCCAGCAATACCACATGGAAGATTCAGAGATCAAAGGTGAA
GTCCTCTATCTCGGCTACTACCAATCAGCCTTCGACTGGGATGATGAAACAGCCAAGGCCTCCAAGCAGC
ATCGTCTTAAACGCTACCACAGCCAGACCTATGGCAATGGGTCCAAGTGCGACCTTAATGGGAGGCCCCG
GGAGGCCGAGGTTCGGTTCCTCTGTGACGAGGGTGCAGGTATCTCTGGGGACTACATCGATCGCGTGGAC
GAGCCCTTGTCCTGCTCTTATGTGCTGACCATTCGCACTCCTCGGCTCTGCCCCCACCCTCTCCTCCGGC
CCCCACCCAGTGCTGCACCGCAGGCCATCCTCTGTCACCCTTCCCTACAGCCTGAGGAGTACATGGCCTA
CGTTCAGAGGCAAGCCGACTCAAAGCAGTATGGAGATAAAATCATAGAGGAGCTGCAAGATCTAGGCCCC
CAAGTGTGGAGTGAGACCAAGTCTGGGGTGGCACCCCAAAAGATGGCAGGTGCGAGCCCGACCAAGGATG
ACAGTAAGGACTCAGATTTCTGGAAGATGCTTAATGAGCCAGAGGACCAGGCCCCAGGAGGGGAGGAGGT
GCCGGCTGAGGAGCAGGACCCAAGCCCTGAGGCAGCAGATTCAGCTTCTGGTGCTCCCAATGATTTTCAG
AACAACGTGCAGGTCAAAGTCATTCGAAGCCCTGCGGATTTGATTCGATTCATAGAGGAGCTGAAAGGTG
GAACAAAAAAGGGGAAGCCAAATATAGGCCAAGAGCAGCCTGTGGATGATGCTGCAGAAGTCCCTCAGAG
GGAACCAGAGAAGGAAAGGGGTGATCCAGAACGGCAGAGAGAGATGGAAGAAGAGGAGGATGAGGATGAG
GATGAGGATGAAGATGAGGATGAACGGCAGTTACTGGGAGAATTTGAGAAGGAACTGGAAGGGATCCTGC
TTCCGTCAGACCGAGACCGGCTCCGTTCGGAGACAGAGAAAGAGCTGGACCCAGATGGGCTGAAGAAGGA
GTCAGAGCGGGATCGGGCAATGCTGGCTCTCACATCCACTCTCAACAAACTCATCAAAAGACTGGAGGAA
AAACAGAGTCCAGAGCTGGTGAAGAAGCACAAGAAAAAGAGGGTTGTCCCCAAAAAGCCTCCCCCATCAC
CCCAACCTACAGAGGAGGATCCTGAGCACAGAGTCCGGGTCCGGGTCACCAAGCTCCGTCTCGGAGGCCC
TAATCAGGATCTGACTGTCCTCGAGATGAAACGGGAAAACCCACAGCTGAAACAAATCGAGGGGCTGGTG
AAGGAGCTGCTGGAGAGGGAGGGACTCACAGCTGCAGGGAAAATTGAGATCAAAATTGTCCGCCCATGGG
CTGAAGGGACTGAAGAGGGTGCACGTTGGCTGACTGATGAGGACACGAGAAACCTCAAGGAGATCTTCTT
CAATATCTTGGTGCCGGGAGCTGAAGAGGCCCAGAAGGAACGCCAGCGGCAGAAAGAGCTGGAGAGCAAT
TACCGCCGGGTGTGGGGCTCTCCAGGTGGGGAGGGCACAGGGGACCTGGACGAATTTGACTTCTGAGACC
AACACTACACTTGACCCTTCACGGAATCCAGACTCTTCCTGGACTGGCTTGCCTCCTCCCCACCTCCCCA
CCCTGGAACCCCTGAGGGCCAAACAGCAGAGTGGAGCTGAGCTGTGGACCTCTCGGGCAACTCTGTGGGT
GTGGGGGCCCTGGGTGAATGCTGCTGCCCCTGCTGGCAGCCACCTTGAGACCTCACCGGGCCTGTGATAT
TTGCTCTCCTGAACTCTCACTCAATCCTCTTCCTCTCCTCTGTGGCTTTTCCTGTTATTGTCCCCTAATG
ATAGGATATTCCCTGCTGCCTACCTGGAGATTCAGTAGGATCTTTTGAGTGGAGGTGGGTAGAGAGAGCA
AGGAGGGCAGGACACTTAGCAGGCACTGAGCAAGCAGGCCCCCACCTGCCCTTAGTGATGTTTGGAGTCG
TTTTACCCTCTTCTATTGAATTGCCTTGGGATTTCCTTCTCCCTTTCCCTGCCCACCCTGTCCCCTACAA
TTTGTGCTTCTGAGTTGAGGAGCCTTCACCTCTGTTGCTGAGGAAATGGTAGAATGCTGCCTATCACCTC
CAGCACAATCCCAGTGAAAAAGGTGTGAAGCACCCACCATGTTCTTGAACAATCAGGTTTCTAAATAAAC
AACTGGACCATC";

	foreach my $key (keys %dnaT)
	{
		my $seq    = $dnaT{$key}[0];
		my $seqNum = &toNum($seq);
		my $leng   = length($seqNum);
		
		$dnaT{$key}[0] = &genBin($leng, $seqNum);
		$dnaT{$key}[1] = $leng;
	}
   
    return \%dnaT;
}

sub loadFastaBin
{
	my $original = $_[0];
    my $seq      = "";
    my $ID       = "";
    my %fasta;

	#print  "\n\tLOADING FASTA........";
    open FASTA, $original or die "FASTA SEQUENCE $original NOT FOUND\n";
   
    while(my $line = <FASTA>)
    {
        chomp $line;
        $line = uc($line);
        if (substr($line,0,1) eq '>')
        {
            if (defined $fasta{$ID})
            {
                my $sequence    = $fasta{$ID}[0] or die "SEQUENCE NOT CREATED $ID\n";
				my $seqNum      = &toNum($sequence);
                $fasta{$ID}[0]  = &genBin(length($seqNum), $seqNum);
                $fasta{$ID}[1]  = length($seqNum);
				die if (length($seqNum) == 0);
            }

            if ($line =~ /^\>(.*)/)
            {
                $ID  = $1;
                $seq = "";
            }
            else
            {
                $ID  = "empty";
                $seq = "";
                print "ID EMPTY!! $line";
            };
        }
        else
        {
            if (($ID ne "") && ($ID ne " ") && ($ID))
            {
                $fasta{$ID}[0] .= $line;

            }
        }
    }
   
    close FASTA;
#   print  "FASTA LOADED\n\t.....................";

	if ((keys %fasta) == 0)
	{
		die "LOADFASTA ERROR: NO SEQUENCE RECOVERED\n";
	}

#   savedump(\%fasta, "fasta");
    return \%fasta;
};


1;
