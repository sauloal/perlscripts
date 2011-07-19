package toolsOO;
use strict;
use warnings;
use Storable;
use Data::Dumper;
use folding;

my %array_h;
my %array_s;
my $water;
my %all_na_wts;



sub new {
    my $class      = shift;
    my $self       = {};

    &loadVars($self);

    bless($self, $class);
    return $self;
}

sub loadVars
{
    #my $hash = $_[0];

    #SUB TMPCR3
        # enthalpy values
        $array_h{"AA"}= -7.9;
        $array_h{"AC"}= -8.4;
        $array_h{"AG"}= -7.8;
        $array_h{"AT"}= -7.2;
        $array_h{"CA"}= -8.5;
        $array_h{"CC"}= -8.0;
        $array_h{"CG"}=-10.6;
        $array_h{"CT"}= -7.8;
        $array_h{"GA"}= -8.2;
        $array_h{"GC"}=-10.6;
        $array_h{"GG"}= -8.0;
        $array_h{"GT"}= -8.4;
        $array_h{"TA"}= -7.2;
        $array_h{"TC"}= -8.2;
        $array_h{"TG"}= -8.5;
        $array_h{"TT"}= -7.9;
        # entropy values
        $array_s{"AA"}=-22.2;
        $array_s{"AC"}=-22.4;
        $array_s{"AG"}=-21.0;
        $array_s{"AT"}=-20.4;
        $array_s{"CA"}=-22.7;
        $array_s{"CC"}=-19.9;
        $array_s{"CG"}=-27.2;
        $array_s{"CT"}=-21.0;
        $array_s{"GA"}=-22.2;
        $array_s{"GC"}=-27.2;
        $array_s{"GG"}=-19.9;
        $array_s{"GT"}=-22.4;
        $array_s{"TA"}=-21.3;
        $array_s{"TC"}=-22.2;
        $array_s{"TG"}=-22.7;
        $array_s{"TT"}=-22.2;


    # SUB MOLWHT
        my $rna_A_wt = 329.245;
        my $rna_C_wt = 305.215;
        my $rna_G_wt = 345.245;
        my $rna_U_wt = 306.195;

        my $dna_A_wt = 313.245;
        my $dna_C_wt = 289.215;
        my $dna_G_wt = 329.245;
        my $dna_T_wt = 304.225;

        $water    = 18.015;


        my %dna_wts = (  'A' => [$dna_A_wt, $dna_A_wt, $dna_A_wt],  # Adenine
                         'C' => [$dna_C_wt, $dna_C_wt, $dna_C_wt],  # Cytosine
                         'G' => [$dna_G_wt, $dna_G_wt, $dna_G_wt],  # Guanine
                         'T' => [$dna_T_wt, $dna_T_wt, $dna_T_wt],  # Thymine
                         'M' => [$dna_C_wt, $dna_A_wt, (($dna_C_wt + $dna_A_wt)/2)],  # A or C
                         'R' => [$dna_A_wt, $dna_G_wt, (($dna_A_wt + $dna_G_wt)/2)],  # A or G
                         'W' => [$dna_T_wt, $dna_A_wt, (($dna_T_wt + $dna_A_wt)/2)],  # A or T
                         'S' => [$dna_C_wt, $dna_G_wt, (($dna_C_wt + $dna_G_wt)/2)],  # C or G
                         'Y' => [$dna_C_wt, $dna_T_wt, (($dna_C_wt + $dna_T_wt)/2)],  # C or T
                         'K' => [$dna_T_wt, $dna_G_wt, (($dna_T_wt + $dna_G_wt)/2)],  # G or T
                         'V' => [$dna_C_wt, $dna_G_wt, (($dna_C_wt + $dna_G_wt + $dna_A_wt)/3)],  # A or C or G
                         'H' => [$dna_C_wt, $dna_A_wt, (($dna_C_wt + $dna_A_wt + $dna_T_wt)/3)],  # A or C or T
                         'D' => [$dna_T_wt, $dna_G_wt, (($dna_T_wt + $dna_G_wt + $dna_A_wt)/3)],  # A or G or T
                         'B' => [$dna_C_wt, $dna_G_wt, (($dna_C_wt + $dna_G_wt + $dna_T_wt)/3)],  # C or G or T
                         'X' => [$dna_C_wt, $dna_G_wt, (($dna_C_wt + $dna_G_wt + $dna_T_wt + $dna_A_wt)/4)],  # G, A, T or C
                         'N' => [$dna_C_wt, $dna_G_wt, (($dna_C_wt + $dna_G_wt + $dna_T_wt + $dna_A_wt)/4)]   # G, A, T or C
           );

        my %rna_wts = (  'A' => [$rna_A_wt, $rna_A_wt, $rna_A_wt],  # Adenine
                         'C' => [$rna_C_wt, $rna_C_wt, $rna_C_wt],  # Cytosine
                         'G' => [$rna_G_wt, $rna_G_wt, $rna_G_wt],  # Guanine
                         'U' => [$rna_U_wt, $rna_U_wt, $rna_U_wt],  # Uracil
                         'M' => [$rna_C_wt, $rna_A_wt, (($rna_C_wt + $rna_A_wt)/2)],  # A or C
                         'R' => [$rna_A_wt, $rna_G_wt, (($rna_A_wt + $rna_G_wt)/2)],  # A or G
                         'W' => [$rna_U_wt, $rna_A_wt, (($rna_U_wt + $rna_A_wt)/2)],  # A or U
                         'S' => [$rna_C_wt, $rna_G_wt, (($rna_C_wt + $rna_G_wt)/2)],  # C or G
                         'Y' => [$rna_C_wt, $rna_U_wt, (($rna_C_wt + $rna_U_wt)/2)],  # C or U
                         'K' => [$rna_U_wt, $rna_G_wt, (($rna_U_wt + $rna_G_wt)/2)],  # G or U
                         'V' => [$rna_C_wt, $rna_G_wt, (($rna_A_wt + $rna_C_wt + $rna_G_wt)/3)],  # A or C or G
                         'H' => [$rna_C_wt, $rna_A_wt, (($rna_C_wt + $rna_A_wt + $rna_U_wt)/3)],  # A or C or U
                         'D' => [$rna_U_wt, $rna_G_wt, (($rna_G_wt + $rna_U_wt + $rna_G_wt)/3)],  # A or G or U
                         'B' => [$rna_C_wt, $rna_G_wt, (($rna_C_wt + $rna_G_wt + $rna_U_wt)/3)],  # C or G or U
                         'X' => [$rna_C_wt, $rna_G_wt, (($rna_C_wt + $rna_G_wt + $rna_A_wt + $rna_U_wt)/4)],  # G, A, U or C
                         'N' => [$rna_C_wt, $rna_G_wt, (($rna_C_wt + $rna_G_wt + $rna_A_wt + $rna_U_wt)/4)]   # G, A, U or C
             );

        %all_na_wts = ('DNA' => \%dna_wts, 'RNA' => \%rna_wts);

        #$hash->{dna_wts}    = \%dna_wts;
        #$hash->{rna_wts}    = \%rna_wts;
        #$hash->{all_na_wts} = \%all_na_wts;
        #$hash->{water}      = $water;
}


sub checkComplementarity
{
	my $self  = shift;
	my ($fwdPrimer, $revPrimer) = @_;

	my $revPrimerRC = &revComp($self, $revPrimer);
	my $lengthFP    = length($fwdPrimer);
	my $lengthRP    = length($revPrimer);
	my $fragLength  = int((int(($lengthFP / 12) * 7) + int(($lengthRP / 12) * 7))/2);

	for (my $f = 0; $f < ($lengthFP-$fragLength); $f++)
	{
		my $fPiece = substr($fwdPrimer, $f, $fragLength);
		for (my $r = 0; $r < ($lengthRP-$fragLength); $r++)
		{
			my $rPiece = substr($revPrimerRC, $f, $fragLength);
			if ($fPiece eq $rPiece) { return 1; };
		}
	}

	return 0;
}

sub log10
{
    my $self  = shift;
	my $n     = shift;
	return log($n)/log(10);
}


sub allTms
{
    my $self  = shift;
	my $FWD = $_[0];
    my $REV = $_[1];
	my $PRO = $_[2];

    my $tmFWD = &tmPCR($self, $FWD);
    my $tmREV = &tmPCR($self, $REV);
    my $tmPRO = &tmPCR($self, $PRO);
	my $ta    = &ta($self, $tmFWD, $tmREV, $tmPRO);

	return($tmFWD, $tmREV, $tmPRO, $ta);
}

sub taFromSeq
{
    my $self  = shift;
	my $FWD = $_[0];
    my $REV = $_[1];
    my $PRO = $_[2];

    my $tmFWD = &tmPCR($self, $FWD);
    my $tmREV = &tmPCR($self, $REV);
    my $tmPRO = &tmPCR($self, $PRO);

	my $ta = &ta($self, $tmFWD, $tmREV, $tmPRO);
}


sub ta
{
    my $self  = shift;
    my $tmFWD = $_[0];
    my $tmREV = $_[1];
    my $tmPRO = $_[2];

    my $tmPRI = ($tmFWD < $tmREV) ? $tmFWD : $tmREV;
    #my $ta    = (.3 * $tmPRI) + (.7 * $tmPRO) - 25;
	my $ta    = (.3 * $tmPRI) + (.7 * $tmPRO) - 14.9;

    return $ta;

	#http://www.protocol-online.org/biology-forums-2/posts/10841.html
	#Ta Opt = 0.3 x(Tm of primer) + 0.7 x(Tm of product) - 25
	#Tm of primer is the melting temperature of the less stable primer-template pair.
	#Tm of product is the melting temperature of the PCR product.

    #3.Primer annealing temperature : The primer melting temperature is the
	#estimate of the DNA-DNA hybrid stability and critical in determining the
	#annealing temperature. Too high Ta will produce insufficient
	#primer-template hybridization resulting in low PCR product yield.
	#Too low Ta may possibly lead to non-specific products caused by a high
	#number of base pair mismatches,. Mismatch tolerance is found to have
	#the strongest influence on PCR specificity.
	#
    #Ta = 0.3 x Tm(primer) + 0.7 Tm (product) – 14.9
    #where,
    #Tm(primer) = Melting Temperature of the primers
    #Tm(product) = Melting temperature of the product
    #http://www.premierbiosoft.com/tech_notes/PCR_Primer_Design.html
}


sub molwt
{
    my $self     = shift;
    my $sequence = uc($_[0]);
    my $moltype  = "DNA";
    my $limit    = "midlelimit"; # "lowerlimit" | "upperlimit" | "midlelimit"

    # the following are single strand molecular weights / base
    my $na_wts = $all_na_wts{$moltype};

    my $mwt = 0;
    my $NA_len = length($sequence);
    my $wlimit;

    if ( $limit eq "upperlimit" ) { $wlimit = 0; }
    if ( $limit eq "lowerlimit" ) { $wlimit = 1; }
    if ( $limit eq "midlelimit" ) { $wlimit = 2; }

    for ( my $i = 0; $i < $NA_len; $i++ )
    {
        my $NA_base = substr($sequence, $i, 1);
        $mwt += $na_wts->{$NA_base}[$wlimit];
    }

    $mwt += $water;

    return int($mwt * 10) / 10;
}




sub countGC
{
    my $self     = shift;
	my $seqGc    = $_[0];

	my $lengthGC = length($seqGc);
# 	print "$seq (" . length($seq) . ")\t";
	my $count    = ($seqGc =~ tr/CGcg//);
# 	print "$seq (" . length($seq) . ")\t$count\t";
	my $gc       = ($count / $lengthGC) * 100;
# 	print "gc $gc\n";
	return int($gc + .5);
}


sub countPurinePyrimidine
{
    my $self   = shift;
	my $seq    = $_[0];
	my $length = length($seq);
	my $count  = ($seq =~ tr/AGag//);
	my $ratio  = ($count / $length) * 100;

	return int($ratio + .5);
}



sub tmPCR
{
    my $self      = shift;
	my $seq       = $_[0];

 	my $cgCount   = $seq;
 	   $cgCount   = ($cgCount =~ tr/CGcg//);

	my $tm   = 64.9 + ((41*($cgCount - 16.4))  / length($seq));
#       Tm   = 64.9 + 41(G + C - 16.4)/L

	return int($tm + .5);
    #http://www.biocenter.helsinki.fi/bi/Programs/manual.htm
}


sub tmPCR2
{
    my $self       = shift;
	my $seq        = $_[0];

    my $primer_len = length($seq);
    my $n_AT       = $seq;
 	   $n_AT       = ($n_AT =~ tr/ATat//);
    my $n_CG       = $seq;
 	   $n_CG       = ($n_CG =~ tr/CGcg//);

    if ($primer_len < 14)
    {
            return int((2 * ($n_AT) + 4 * ($n_CG)) + .5);
    }
    else
    {
            return int((64.9 + 41*(($n_CG-16.4)/$primer_len)) + .5);
    }

    #function Tm_min($primer){
    #    $primer_len=strlen($primer);
    #    $primer2=preg_replace("/A|T|Y|R|W|K|M|D|V|H|B|N/","A",$primer);
    #    $n_AT=substr_count($primer2,"A");
    #    $primer2=preg_replace("/C|G|S/","G",$primer);
    #    $n_CG=substr_count($primer2,"G");
    #
    #            if ($primer_len > 0) {
    #                    if ($primer_len < 14) {
    #                            return round(2 * ($n_AT) + 4 * ($n_CG));
    #                    }else{
    #                            return round(64.9 + 41*(($n_CG-16.4)/$primer_len),1);
    #                    }
    #            }
    #}

}





sub tmPCR3
{
    my $self        = shift;
	my $seq         = $_[0];
    my $conc_salt   = $_[1] || 50;   # 50 mM [50]
    my $conc_mg     = $_[2] || 1.5;  # 1.5 mM [0]
    my $conc_primer = $_[3] || 200;  # 200 nM [200]

    my $h = 0;
    my $s = 0;

    # effect on entropy by salt correction; von Ahsen et al 1999
    # Increase of stability due to presence of Mg;
    my $salt_effect = ($conc_salt/1000)+(($conc_mg/1000) * 140);
    # effect on entropy
    $s += 0.368 * (length($seq)-1)* log($salt_effect);

    # terminal corrections. Santalucia 1998
    my $firstnucleotide  = substr($seq,0,1);
    if ($firstnucleotide eq "G" or $firstnucleotide eq "C") { $h += 0.1; $s += -2.8; }
    if ($firstnucleotide eq "A" or $firstnucleotide eq "T") { $h += 2.3; $s +=  4.1; }

    my $lastnucleotide = substr($seq,length($seq)-1,1);
    if ($lastnucleotide eq "G" or $lastnucleotide eq "C") { $h += 0.1; $s += -2.8; }
    if ($lastnucleotide eq "A" or $lastnucleotide eq "T") { $h += 2.3; $s +=  4.1; }

    # compute new H and s based on sequence. Santalucia 1998
    for(my $i = 0; $i < length($seq)-1; $i++){
            my $subc = substr($seq,$i,2);
            $h += $array_h{$subc};
            $s += $array_s{$subc};
    }

    my $tm = ((1000*$h)/($s+(1.987*log($conc_primer/2_000_000_000))))-273.15;
    return int($tm + .5);

#function tm_Base_Stacking($c,$conc_primer,$conc_salt,$conc_mg){
#
#        if (CountATCG($c)!= strlen($c)){print "The oligonucleotide is not valid";return;}
#        $h=$s=0;
#
#        // enthalpy values
#        $array_h{"AA"]= -7.9;
#        $array_h{"AC"]= -8.4;
#        $array_h{"AG"]= -7.8;
#        $array_h{"AT"]= -7.2;
#        $array_h{"CA"]= -8.5;
#        $array_h{"CC"]= -8.0;
#        $array_h{"CG"]=-10.6;
#        $array_h{"CT"]= -7.8;
#        $array_h{"GA"]= -8.2;
#        $array_h{"GC"]=-10.6;
#        $array_h{"GG"]= -8.0;
#        $array_h{"GT"]= -8.4;
#        $array_h{"TA"]= -7.2;
#        $array_h{"TC"]= -8.2;
#        $array_h{"TG"]= -8.5;
#        $array_h{"TT"]= -7.9;
#        // entropy values
#        $array_s{"AA"]=-22.2;
#        $array_s{"AC"]=-22.4;
#        $array_s{"AG"]=-21.0;
#        $array_s{"AT"]=-20.4;
#        $array_s{"CA"]=-22.7;
#        $array_s{"CC"]=-19.9;
#        $array_s{"CG"]=-27.2;
#        $array_s{"CT"]=-21.0;
#        $array_s{"GA"]=-22.2;
#        $array_s{"GC"]=-27.2;
#        $array_s{"GG"]=-19.9;
#        $array_s{"GT"]=-22.4;
#        $array_s{"TA"]=-21.3;
#        $array_s{"TC"]=-22.2;
#        $array_s{"TG"]=-22.7;
#        $array_s{"TT"]=-22.2;
#
#        // effect on entropy by salt correction; von Ahsen et al 1999
#                // Increase of stability due to presence of Mg;
#                $salt_effect= ($conc_salt/1000)+(($conc_mg/1000) * 140);
#                // effect on entropy
#                $s+=0.368 * (strlen($c)-1)* log($salt_effect);
#
#        // terminal corrections. Santalucia 1998
#                $firstnucleotide=substr($c,0,1);
#                if ($firstnucleotide=="G" or $firstnucleotide=="C"){$h+=0.1; $s+=-2.8;}
#                if ($firstnucleotide=="A" or $firstnucleotide=="T"){$h+=2.3; $s+=4.1;}
#
#                $lastnucleotide=substr($c,strlen($c)-1,1);
#                if ($lastnucleotide=="G" or $lastnucleotide=="C"){$h+=0.1; $s+=-2.8;}
#                if ($lastnucleotide=="A" or $lastnucleotide=="T"){$h+=2.3; $s+=4.1;}
#
#        // compute new H and s based on sequence. Santalucia 1998
#        for($i=0; $i<strlen($c)-1; $i++){
#                $subc=substr($c,$i,2);
#                $h+=$array_h{$subc];
#                $s+=$array_s{$subc];
#        }
#        $tm=((1000*$h)/($s+(1.987*log($conc_primer/2000000000))))-273.15;
#        print "Tm:                 <font color=880000><b>".round($tm,1)." &deg;C</b></font>";
#        print  "\n<font color=008800>  Enthalpy: ".round($h,2)."\n  Entropy:  ".round($s,2)."</font>";

        #http://www.astro.yale.edu/tal/dilcalc.html
        #http://www.biophp.org/minitools/melting_temperature/
}



sub tmMLPA
{
    my $self      = shift;
	my $seq       = $_[0];
	my $gc        = $_[1];
	my $NaK       = $_[2] || 0.05; # 35mM 0.035M
# 	my $cgCount   = $seq;
# 	   $cgCount   = ($cgCount =~ s/[C|G]//gi);;

	my $tm   = 81.5    + (16.6    *  (&log10($self, $NaK)))       + (0.41   *   $gc)   - (675/length($seq));
#       Tm   = 81.5°C  +  16.6°C  x  (log10[Na+] + [K+])  +  0.41°C  x  (%GC)  –  675/N

	$tm = (1.0701*$tm) + 14.646; # regression from 4 points to raw-probe

	return int($tm + .5);


#http://www.promega.com/biomath/calc11.htm#melt_results
#Where N is the length of the primer.

}




sub checkNeeds
{
    my $self = shift;
    my $name = $_[0];
    my $hash = $_[1];
    my $vars = $_[2];

	for my $need (@{$vars})
	{
		if ( ! exists $hash->{$need})
		{
			die "$name :: CONFIG $need NOT FOUND";
		}
        else
        {
            #printf "CONFIG %-15s EXISTS :: %s\n", $need, $hash->{$need};
        };
	}

	print "$name :: NEEDS MET\n";
}


sub getTaxonomy
{
    my $self     = shift;
	my $file     = $_[0];
    my $taxonomy = $_[1];
	open FILE, "<$file" or die "COULD NOT OPEN FASTA FILE $file: $!\n";
	my $count = 0;
	my $countValid = 0;
	while (<FILE>)
	{
		chomp;
		if (($count++) && ($_))
		{
			if (/.\t\d+\t\d+\t\d+/)
			{
				$countValid++;
				my ($fasta, $taxID, $variant, $fileType);
				($fasta, $taxID, $variant, $fileType) = split("\t",$_);
				if ((defined $fasta) && (defined $taxID) && (defined $variant) && (defined $fileType))
				{
			#		print "FASTA $fasta TAXID $taxID FILETYPE $fileType\n";
					$taxonomy->{$fasta}[0] = $taxID;
					$taxonomy->{$fasta}[1] = $variant;
					$taxonomy->{$fasta}[2] = $fileType;
				}
			}
			elsif (/^#/)
			{

			}
			else
			{
				print "SKIPPED: ", $_, "\n"
			}
		}
	}
	close FILE;
	print "$countValid FILES IN TAXONOMIC INDEX\n";
}


sub zerofy
{
	my $self      = shift;
	my $number    = $_[0];
	my $zeroes    = $_[1];
	my $outnumber = sprintf("%0".$zeroes."d", $number);
	return $outnumber;
}


sub revComp
{
	my $self     = shift;
	my $sequence = uc($_[0]);
	my $rev = reverse($sequence);
	$rev =~ tr/ACTG/TGAC/;
	return $rev;
}


sub savedump
{
	my $self    = shift;
    my $ref     = $_[0]; #reference
    my $name    = $_[1]; #name of variable to save
	my $outFile = $_[2];
    my $d = Data::Dumper->new([$ref],["*$name"]);

    $d->Purity   (1);     # better eval
#   $d->Terse    (0);     # avoid name when possible
    $d->Indent   (3);     # identation
    $d->Useqq    (1);     # use quotes
    $d->Deepcopy (1);     # enable deep copy, no references
    $d->Quotekeys(1);     # clear code
    $d->Sortkeys (1);     # sort keys
    $d->Varname  ($name); # name of variable
#    open (DUMP, ">$outFile.dump") or die "Cant save $outFile.dump file: $!\n";
    print $d->Dump or die "COULD NOT EXPORT HASH DUMP FROM PROBE_EXTRACTOR TO PROBE_EXTRACTOR_ACTUATOR: $!";
#    close DUMP;
};


sub load
{
	my $self = shift;
    my $ref  = $_[0];
	my $file = $_[1];
	#	my $name = $_[1];

	die "DIED: FILE $file NOT FOUND" if ( ! -f $file );

    if (ref($ref) eq "HASH")
    {
            %{$ref} = %{retrieve("$file")} or die "DIED: COULD NOT RETRIEVE FILE $file: $!";
    }
	elsif (ref($ref) eq "ARRAY")
    {
            @{$ref} = @{retrieve("$file")} or die "DIED: COULD NOT RETRIEVE FILE $file: $!";;
    };

	#	return $ref;
    #%database = %{retrieve($prefix."_".$name."_store.dump")};
};

sub save
{
	my $self = shift;
    my $ref  = $_[0];
    my $file = $_[1];
    store $ref, "$file" or die "COULD NOT SAVE DUMP FILE $file: $!";
#	return $ref;
};

sub DESTROY {};

1;
