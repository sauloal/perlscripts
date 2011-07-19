#!/usr/bin/perl -w
use strict;
use warnings;
use List::Util qw(max);
use MIME::Base64;

# INPUTS: XML FILE NAME
#         FASTA ORIGNAL GENOME FILE NAME

(my $inputFA, my @inputXML) = @ARGV;


my $rootType;   # type of the root  XML class
my $tableType;  # type of the table XML class
my %XMLsnp;     # SNPs from XMLs
my %XMLgap;     # GAPs from XMLs
my %XMLblast;   # BLASTSs from XMLs
my @XMLpos;     # information from XMLs organized by position
my %XMLtemp;    # tempXML
my %chromos;    # NAME > NUMBER
my %chromosMap; # NAME > LINE
my %stat;       # CHROM NUM > STATISTICS
my %blastKey;   # gene id > gene name
my @geneArray;  # chrom num > start pos > gene id
my @gapArray;  # chrom num > start pos > gene id
my @gene;       # current gene nucleotides
my $geneName  = ""; # current gene name
my $registre  = 0;
my $iterating = 0;


&init;

sub start
{
    my $inputFA = $_[0];
    my $output  = $_[1];

    print "  GENERATING CHROMOSSOMES TABLE...";
    &genChromos($inputFA);
    print "done\n";

    print "  MERGING DATA...";
    &mergeData(\%XMLsnp, \%XMLgap, \%XMLblast, $inputFA);
    print "done\n"; 

    print "  EXPORTING XMLPOS...";  
    &exportData(\@XMLpos,\@geneArray,\@gapArray);
    print "done\n"; 

    print "  EXPORTING XMLSTAT..."; 
    &exportStat();
    print "done\n"; 
}


sub exportStat
{
    open XML, ">XMLpos/XMLstat.xml"  or die "COULD NOT OPEN XMLpos/XMLSTAT.XML";
    print XML "<root id=\"XMLpos\" type=\"stat\">\n";
    my $id = 0;
    foreach my $chrom (sort {$a <=> $b} keys %stat)
    {
        my $chromName = &reverseHash($chrom);
        my %response  = %{&getStat($chrom)};
        print XML      "\t<table id=\"$chromName\" type=\"chromossome\">\n";
        print XML      "\t\t<row id=\"$id\">\n";
        foreach my $key (sort keys %response)
        {
            my $value = $response{$key};
            if (ref $value eq "ARRAY")
            {
                $value = join(":", @{$value});
            }
#           $value =~ s/\n/\|/g;
            $value = encode_base64($value, "");
#           $value = decode_base64($value);
            #print "$chromName $key $value\n";
            print XML      "\t\t\t<$key>$value</$key>\n";
        } #end foreach my key
        print XML      "\t\t</row>\n";
        print XML      "\t</table>\n";
        $id++;
    } # end foreach my $chrom
    print XML "</root>\n";
    close XML;
    print "EXPORTED $id STATISTICS...";
} #end sub export stat


sub exportData
{
    my @XMLpos    = @{$_[0]};
    my @geneArray = @{$_[1]};
    my @gapArray  = @{$_[2]};
    
    my @gen;
    my @gap;

    open MERGED, ">XMLpos/merged_order.txt"      or die "COULD NOT OPEN MERGED_ORDER.TXT";
    open TAB,    ">XMLpos/merged_order_tab.txt"  or die "COULD NOT OPEN MERGED_ORDER_TAB.TXT";
    open XML,    ">XMLpos/XMLpos.xml"     or die "COULD NOT OPEN XMLpos/XMLPOS.XML";

    my $id = 0;
    print XML "<root id=\"XMLpos\" type=\"pos\">\n";
    print TAB       "pos\n";
    for (my $chromNum = 0; $chromNum < @XMLpos; $chromNum++)
    {
        if (defined @{$XMLpos[$chromNum]})
        {
            my @pos = @{$XMLpos[$chromNum]};
            my $chromName = &reverseHash($chromNum);
            print XML       "\t<table id=\"$chromName\" type=\"chromossome\">\n";
            open  XMLCHROM, ">XMLpos/XMLpos_$chromName.xml"       or die "COULD NOT OPEN XMLpos/XMLPOS_$chromName.XML";
            print XMLCHROM  "<root id=\"XMLpos\" type=\"pos\">\n";
            print XMLCHROM  "\t<table id=\"$chromName\" type=\"chromossome\">\n";
            print TAB       "\t$chromName\n";
            for (my $pos = 0; $pos <  @pos; $pos++)
            {
                if (defined %{$XMLpos[$chromNum][$pos]})
                {
                    print XML      "\t\t<row id=\"$pos\">\n";
                    print XMLCHROM "\t\t<row id=\"$pos\">\n";
                    print TAB      "\t\t$pos\n";
                    $id++;
                    foreach my $key (sort keys  %{$XMLpos[$chromNum][$pos]})
                    {
                        my $value = $XMLpos[$chromNum][$pos]{$key};
                        if ($key eq "gene")
                        {
                            $value = $blastKey{$value};
                        }
                        print MERGED "$chromName >> $pos > $key = $value\n";
                        print TAB "\t\t\t$key\t$value\n";
                        print XML      "\t\t\t<$key>$value</$key>\n";
                        print XMLCHROM "\t\t\t<$key>$value</$key>\n";
                    } # end foreach my key
                    #print XML      "\t\t\t<id>$id</id>\n";
                    print XML      "\t\t\t<pos>$pos</pos>\n";
                    print XML      "\t\t</row>\n";
                    #print XMLCHROM "\t\t\t<id>$id</id>\n";
                    print XMLCHROM "\t\t\t<pos>$pos</pos>\n";
                    print XMLCHROM "\t\t</row>\n";
                } #end if defined pos
            } #end for my pos
            print XML      "\t</table>\n";
            print XMLCHROM "\t</table>\n";
            print XMLCHROM "</root>\n";
            close XMLCHROM;
        } # end if defined chromnum
    } #end for my chromnum
    print XML "</root>\n";
    close XML;
    close TAB;
    close MERGED;
    print "EXPORTED $id DATA...";
} #end sub exportData

sub mergeData
{
    %XMLsnp     = %{$_[0]};
    %XMLgap     = %{$_[1]};
    %XMLblast   = %{$_[2]};
    my $inputFA =   $_[3];

    my %unique;
    my $prog;
    my $chrom;
    my @prog;
    my @new;

    open MERGED, ">XMLpos/merged_raw.txt" or die "COULD NOT OPEN MERGED";

    foreach my $table (keys %XMLsnp)
    {
        foreach my $register (keys %{$XMLsnp{$table}})
        {
            undef $prog;
            undef $chrom;
            undef @prog;
            undef @new;
            my $new  = $XMLsnp{$table}{$register}{"new"};
            my $orig = $XMLsnp{$table}{$register}{"orig"};
            my $pos  = $XMLsnp{$table}{$register}{"posOrig"};

            if ( ! ((defined $new) && (defined $orig) && (defined $pos))) { die "COULD NOT GET NEW, ORIGINAL AND POSITION"};

            my $chromNum;

            if ($tableType eq "chromossome")
            {
                $prog     = $XMLsnp{$table}{$register}{"program"};
                $chrom    = $table;
                $chromNum = $chromos{$chrom};
            }
            elsif ($tableType eq "program")
            {
                $prog     = $table;
                $chrom    = $XMLsnp{$table}{$register}{"chromR"};
                $chromNum = $chromos{$chrom};
            }
            else
            {
                die "UNKNOWN KIND OF TABLE TYPE: $tableType\n";
            }

            if ( &reverseHash($chromNum) ne $geneName )
            {
#               print "$chromNum (" . &reverseHash($chromNum) . " > $geneName";
                @gene = @{&readFasta($inputFA, $chromNum)};
                if ( ! @gene) { die "COULD NOT READ GENE FROM CHROMOSSOME $chrom"; }; # else {print " (" . @gene . "bp) \n";};
#               $stat{$chromNum}{"size"} = (@gene - 1);
            }

            my $origFA   = $gene[$pos];

            if ( $orig eq "." )
            {
#               die "ORIGNINAL FROM SNP $orig IS DIFFERENT FROM FASTA $origFA\n";
                $new = tr/ACTGactg/12341234/;
    #           $XMLpos{$chromNum}{$pos}{"orig"} = $orig;
            }
            elsif ( $new eq "." )
            {
#               die "ORIGNINAL FROM SNP $orig IS DIFFERENT FROM FASTA $origFA\n";
                $new = tr/ACTGactg/56785678/;
    #           $XMLpos{$chromNum}{$pos}{"orig"} = $orig;
            }
            elsif ( $orig ne $origFA )
            {
                die "ORIGNINAL FROM SNP $orig IS DIFFERENT FROM FASTA $origFA IN POSITION $pos IS WRONG ON TABLE $table REGISTER $register PROGRAM $prog\n";
            }
    
            if ( ! eval { $stat{$chromNum}{"SNP_prog_count"}{$prog}++ }) { $stat{$chromNum}{"SNP_prog_count"}{$prog} = 1; }

            push (@{$stat{$chromNum}{"SNP_prog_pos"}{$prog}}, $pos);
            my %hash;
               %hash = %{$XMLpos[$chromNum][$pos]} if ( defined %{$XMLpos[$chromNum][$pos]});

            $hash{"new"}  = $hash{"new"}  ? $hash{"new"}  . "\t$new"  : $new;
            $hash{"prog"} = $hash{"prog"} ? $hash{"prog"} . "\t$prog" : $prog;
            $XMLpos[$chromNum][$pos] = \%hash;

            my $chromName = &reverseHash($chromNum);
            print MERGED "$chromName >> $pos > new = $new\n";
            print MERGED "$chromName >> $pos > tprog = $prog\n";
        } #end foreach my table
    } #end foreach my register
    undef %unique;


    undef $prog;
    undef $chrom;
    undef @prog;
    undef @new;

    foreach my $table (keys %XMLgap)
    {
        foreach my $register (keys %{$XMLgap{$table}})
        {
            undef $prog;
            undef $chrom;
            undef @prog;
            undef @new;
# 
            my $chromNum;
 
            if ($tableType eq "chromossome")
            {
                $prog     = $XMLgap{$table}{$register}{"program"};
                $chrom    = $table;
                $chromNum = $chromos{$chrom};
            }
            elsif ($tableType eq "program")
            {
                $prog     = $table;
                $chrom    = $XMLgap{$table}{$register}{"chromR"};
                $chromNum = $chromos{$chrom};
            }
            else
            {
                die "UNKNOWN KIND OF TABLE TYPE: $tableType\n";
            }

            if ( ! ((defined $prog) && (defined $chromNum)))
            {
                die "COULD NOT GET PROGRAM OR CHROMOSSOME NUMBER FROM TABLE $table REGISTER NUMBER $register PROG $prog CHROM $chrom CHROMNUM $chromNum";
            }

            my $start  = $XMLgap{$table}{$register}{"start"};
            my $end    = $XMLgap{$table}{$register}{"end"};
            my $length = $XMLgap{$table}{$register}{"length"};
            my $reads  = $XMLgap{$table}{$register}{"reads"};
            my $rLeft  = $XMLgap{$table}{$register}{"rLeft"};
            my $rRight = $XMLgap{$table}{$register}{"rRight"};
            my $id     = $XMLgap{$table}{$register}{"id"};

            if ( ! ((defined $start) && (defined $end) && (defined $length) && (defined $id)))
            {
                die "COULD NOT GET START, END, LENGTH AND ID FROM TABLE $table REGISTER NUMBER $register ID $id PROG $prog CHROM $chrom CHROMNUM $chromNum";
            }

            if   ( ! eval  { $stat{$chromNum}{"GAP_prog_count"}{$prog}++ }) { $stat{$chromNum}{"GAP_prog_count"}{$prog} = 1; }

            my $indel; 
            if ( $length >= 0 )     { $indel = "+"; } else { $indel = "X"; };
            if ( $prog eq "eland" ) { $indel = "X"; };

            push (@{$stat{$chromNum}{"GAP_prog_pos"}{$prog}}, $start);
            my %hash;
               %hash = %{$XMLpos[$chromNum][$start]} if ( defined %{$XMLpos[$chromNum][$start]});

            # 29861   2077060K        1976916K          101     24.1    0:19.39 xml_pos.pl
            # 31217   2060824K        1.960.680K        101     23.9    0:18.84 xml_pos.pl

            $hash{"gap"}      = $indel;
            $hash{"gap_end"}  = $end;
            $XMLpos[$chromNum][$start]   = \%hash;
            $gapArray[$chromNum][$start] = $id;

            for (my $i = ($start+1); $i <= $end; $i++)
            {
                push (@{$stat{$chromNum}{"GAP_prog_pos_total"}{$prog}}, $i);
                $gapArray[$chromNum][$i] = $id;
            }

            my $chromName = &reverseHash($chromNum);
            print MERGED "$chromName >> $start > gap = $indel\n";
            print MERGED "$chromName >> $start > gap_end = $end\n";
#           $max = $pos if ($pos > $max);
        } #end foreach my register
    } #end foreach my table
    undef %unique;


    undef $prog;
    undef $chrom;
    undef @prog;
    undef @new;
            my $total;
    foreach my $table (keys %XMLblast)
    {
#       print "\tTABLE $table\n";
        foreach my $register (keys %{$XMLblast{$table}})
        {
#           print "\t\tREGISTER $register\n";
            undef $prog;
            undef $chrom;
            undef @prog;
            undef @new;
# 
            my $chromNum;
 
            if ($tableType eq "chromossome")
            {
                $prog     = $XMLblast{$table}{$register}{"method"};
                $chrom    = $table;
                $chromNum = $chromos{$chrom};
            }
            elsif ($tableType eq "program")
            {
                $prog     = $table;
                $chrom    = $XMLblast{$table}{$register}{"chromR"};
                $chromNum = $chromos{$chrom};
            }
            else
            {
                die "UNKNOWN KIND OF TABLE TYPE: $tableType\n";
            }

            my $start  = $XMLblast{$table}{$register}{"start"};
            my $end    = $XMLblast{$table}{$register}{"end"};
            my $length = $XMLblast{$table}{$register}{"Qrylen"};
            my $sign   = $XMLblast{$table}{$register}{"sign"};
            my $ident  = $XMLblast{$table}{$register}{"ident"};
            my $consv  = $XMLblast{$table}{$register}{"consv"};
            my $gaps   = $XMLblast{$table}{$register}{"gaps"};
            my $strand = $XMLblast{$table}{$register}{"strand"};
            my $gene   = $XMLblast{$table}{$register}{"gene"};
            my $id     = $XMLblast{$table}{$register}{"id"};

            if ( ! ((defined $start) && (defined $end) && (defined $length) && (defined $sign) && (defined $ident) && (defined $consv) && (defined $gaps) && (defined $strand) && (defined $gene)))
            {
                die "COULD NOT GET START, END, LENGTH, READS, LEFT AND RIGHT FROM TABLE $table REGISTER NUMBER $register ID $gene";
            }

            if ( ! defined $blastKey{$id} ) { $blastKey{$id} = $gene; };

            if ($start > $end) { my $temp = $start; $start = $end; $end = $temp; }

            push (@{$stat{$chromNum}{"BLAST_prog_pos"}{$prog}}, $start);
            my %hash;
               %hash = %{$XMLpos[$chromNum][$start]} if ( defined %{$XMLpos[$chromNum][$start]});
            $hash{"gene"}     = $id;
            $hash{"gene_end"} = $end;
            $XMLpos[$chromNum][$start]    = \%hash;
            $geneArray[$chromNum][$start] = $id;

#           3711    331584K 231.440K 99      2.8     0:13.42 xml_pos.pl
#           4718    273944K 173.800K 99      2.1     0:12.92 xml_pos.pl
            for (my $i = ($start+1); $i <= $end; $i++)
            {
                push (@{$stat{$chromNum}{"BLAST_prog_pos_total"}{$prog}}, $i);
                $geneArray[$chromNum][$i] = $id;
            }

            my $chromName = &reverseHash($chromNum);
            print MERGED "$chromName >> $start > gene = $gene\n";
            print MERGED "$chromName >> $start > gene_end = $end\n";

#           $max = $pos if ($pos > $max);
        } #end foreach my register
    } #end foreach my table
    undef %unique;
    close MERGED;
#   return \%XMLpos;
}



sub fixDigit
{
    my $input  = $_[0];
    my $digits = $_[1];
    my $number = "0"x($digits - length($input)) . "$input";
    return $number;
}


sub getStat
{
    my $chromNum = $_[0];

    if ( ! $chromNum )
    {
        die "CHROMOSSOME NOT DEFINED";
    }
    elsif ( ! $chromNum =~ /^\d+$/ )
    {
        $chromNum = $chromos{$chromNum};
    };

    if ((defined $stat{$chromNum}) && (keys %{$stat{$chromNum}}))
    {
        my %hash = %{$stat{$chromNum}};
        my %response;
        my @positions_both;
        my @progs;
        my @positions;

        my $size = $hash{"size"};         # size of the chromossome

        if (defined %{$hash{"SNP_prog_pos"}})
        {

            my %SNP_prog_pos   = %{$hash{"SNP_prog_pos"}}; # $prog > @pos   
            my %SNP_prog_pos_count; # $prog > @pos  
            my @SNP_prog       = (keys %{$hash{"SNP_prog_pos"}}); # $prog > @pos    
            my @SNP_pos;     #positions of the SNPs
            foreach my $prog (@SNP_prog) { push(@SNP_pos, @{$SNP_prog_pos{$prog}}); };
            my %seen           = ();
            my @sorted         = grep { ! $seen{$_} ++ } @SNP_pos;
               @SNP_pos        = (sort { $a <=> $b} @sorted);

            foreach my $pro ( keys %SNP_prog_pos)
            {
                my @proPos                = @{$SNP_prog_pos{$pro}};
                my $programsP             = &positionTable(\@proPos);
                $SNP_prog_pos{$pro}       = $programsP;
                $SNP_prog_pos_count{$pro} = @proPos;
            }

            my $SNP_count_u    =   0;

            foreach my $po (@SNP_pos)
            {
                $positions_both[$po]++;
                $SNP_count_u++;
            }

            push(@progs, @SNP_prog);
            push(@positions, @SNP_pos);
            my $SNP_prog  = &consensusProgSimple(\@SNP_prog);
            my $SNP_pos   = &positionTable(\@SNP_pos);

            $response{"SNP_prog"}    = $SNP_prog;    # $Str
            $response{"SNP_pos"}     = $SNP_pos;     # $Str
            $response{"SNP_prog_A"}  = \@SNP_prog;   # @Str
            $response{"SNP_pos_A"}   = \@SNP_pos;    # @Int
            $response{"SNP_count_u"} = $SNP_count_u; # $Int
            $response{"SNP"} = 1;
        }
        else
        {
            $response{"SNP"} = 0;
        }

        if (defined %{$hash{"GAP_prog_pos"}})
        {
            my %GAP_prog_pos   = %{$hash{"GAP_prog_pos"}}; # $prog > @pos   
            my %GAP_prog_pos_count; # $prog > @pos  
            my @GAP_prog       = (keys %{$hash{"GAP_prog_pos"}}); # $prog > @pos    
            my @GAP_pos;     #positions of the SNPs
            foreach my $prog (@GAP_prog) { push(@GAP_pos, @{$GAP_prog_pos{$prog}}); };
            my %seen           = ();
            my @sorted         = grep { ! $seen{$_} ++ } @GAP_pos;
               @GAP_pos        = (sort { $a <=> $b} @sorted);

            foreach my $pro ( keys %GAP_prog_pos)
            {
                my @proPos                = @{$GAP_prog_pos{$pro}};
                my $programsP             = &positionTable(\@proPos);
                $GAP_prog_pos{$pro}       = $programsP;
                $GAP_prog_pos_count{$pro} = @proPos;
            }

            my $GAP_count_u    =   0;

            foreach my $po (@GAP_pos)
            {
                $positions_both[$po]++;
                $GAP_count_u++;
            }

            push(@progs, @GAP_prog);
            push(@positions, @GAP_pos);
            my $GAP_prog  = &consensusProgSimple(\@GAP_prog);
            my $GAP_pos   = &positionTable(\@GAP_pos);

            $response{"GAP_prog"}    = $GAP_prog;    # $Str
            $response{"GAP_pos"}     = $GAP_pos;     # $Str
            $response{"GAP_prog_A"}  = \@GAP_prog;   # @Str
            $response{"GAP_pos_A"}   = \@GAP_pos;    # @Int
            $response{"GAP_count_u"} = $GAP_count_u; # $Int
            $response{"GAP"} = 1;
        }
        else
        {
            $response{"GAP"} = 0;
        }


        if (defined %{$hash{"BLAST_prog_pos"}})
        {
            my %BLAST_prog_pos   = %{$hash{"BLAST_prog_pos"}}; # $prog > @pos   
            my %BLAST_prog_pos_count; # $prog > @pos    
            my @BLAST_prog       = (keys %{$hash{"BLAST_prog_pos"}}); # $prog > @pos    
            my @BLAST_pos;     #positions of the SNPs
            foreach my $prog (@BLAST_prog) { push(@BLAST_pos, @{$BLAST_prog_pos{$prog}}); };
            my %seen      = ();
            my @sorted    = grep { ! $seen{$_} ++ } @BLAST_pos;
               @BLAST_pos = (sort { $a <=> $b} @sorted);

            foreach my $pro ( keys %BLAST_prog_pos)
            {
                my @proPos                  = @{$BLAST_prog_pos{$pro}};
                my $programsP               = &positionTable(\@proPos);
                $BLAST_prog_pos{$pro}       = $programsP;
                $BLAST_prog_pos_count{$pro} = @proPos;
            }

            my $BLAST_count_u    =   0;

            foreach my $po (@BLAST_pos)
            {
                $positions_both[$po]++;
                $BLAST_count_u++;
            }

            push(@progs, @BLAST_prog);
            push(@positions, @BLAST_pos);
            my $BLAST_prog  = &consensusProgSimple(\@BLAST_prog);
            my $BLAST_pos   = &positionTable(\@BLAST_pos);

            $response{"BLAST_prog"}    =  $BLAST_prog;    # $Str
            $response{"BLAST_pos"}     =  $BLAST_pos;     # $Str
            $response{"BLAST_prog_A"}  = \@BLAST_prog;    # @Str
            $response{"BLAST_pos_A"}   = \@BLAST_pos;     # @Int
            $response{"BLAST_count_u"} =  $BLAST_count_u; # $Int
            $response{"BLAST"} = 1;
        }
        else
        {
            $response{"BLAST"} = 0;
        }


        for (my $po = 0; $po < @positions_both; $po++)
        {
            if (defined $positions_both[$po])
            {
                if ($positions_both[$po] > 1)
                {
                    print "IN CHROMOSSOME $chromNum THE POSITION $po PRESENTS BOTH A SNP AND A INDEL\n";
                }
            }
        }

        if ( ! defined $size) { die   "COULD NOT GET SIZE"     . " FOR CHROMOSSOME $chromNum " . &reverseHash($chromNum) . "\n"; };
        if ( ! @progs )       { print "COULD NOT GET PROGRAMS" . " FOR CHROMOSSOME $chromNum " . &reverseHash($chromNum) . "\n"; @progs = (); };

        my $programs  = &consensusProgSimple(\@progs);
        my $positions = &consensusProgSimple(\@positions);

        $response{"programs"}    = $programs;    # $Str
        $response{"positions"}   = $positions;   # $Str
        $response{"size"}    = $size;        # $Int

# 
#       $response{"progA"}   = @progs;       # @Str
#       $response{"posSnp"}      = $posSnp;      # $Int
#       $response{"posSnpA"}     = @posSnp;      # @Int
#       $response{"snps"}    = $snps;        # $Int
#       $response{"snpsU"}   = $snpsU;       # $Int
#       $response{"progP"}   = %progsPos;    # % prog > @positions (int)
#       $response{"progC"}   = %progsCount;  # % prog > $count (Int)
#       $response{"programsPos"} = %programsPos; # % prog > $positions (Str)

    #   print "$progs $pos $snps\n";
        return \%response;
    }
    else
    {   die "ERROR GETTING STATISTICS FROM $chromNum " . $chromos{$chromNum};
    }
}


sub readFasta
{
    my $inputFA  = $_[0];
    my $chromNum = $_[1];
    my $chromName;
    my $desiredLine;
    undef @gene;

#   print "READING FASTA $chromNum\n";
    if ( $chromNum =~ /^\d+$/ )
    {
        if ( eval { $desiredLine = $chromosMap{&reverseHash($chromNum)} } )
        {
            $chromName   = &reverseHash($chromNum)
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




    if ( $chromName ne $geneName )
    {
        undef @gene; $gene[0] = "";
        open FILE, "<$inputFA" or die "COULD NOT OPEN $inputFA: $!";
    
        my $current;
        my $chromo;
        my $chromoName;
    
        my $on   = 0;
        my $pos  = 0;
        my $line = 1;

        $geneName = $chromName;

#       print "DESIRE $desiredLine $chromName\n";
        seek(FILE, $desiredLine-200, 0);    
        while (<FILE>)
        {
#           if ($line >= $desiredLine)
#           {
                chomp;
                if (( /^>/) && ($on))
                {
                    $on   = 0;
                    $pos  = 1;
#                   print "LAST\n";
                    last;
                }
        
                if ($on)
                {
                    foreach my $nuc (split("",$_))
                    {
                        if ( ! defined $chromos{$chromoName})
                        { 
                            my $next = (keys %chromos)+1;
                            $chromos{$chromoName} = $next;
#                           print "CHROMOSSOME $chromo IS NUMBER $next\n";
                        }
                        $current = $chromos{$chromoName};
#                       print "CURRENT $current\n";
    #                   $XMLpos{$current}{$pos++}{"orig"} = $nuc;
                        push(@gene,$nuc);
#                       print $nuc;
                        undef $current;
                    }
        #           push(@{$seq{$chromo}}, (split("",$_)));
                }
        
                if (/^>$chromName/)
                {
#                   print ">$chromName\n";
                    $on         = 1;
                    $chromoName = $chromName;
                    $pos        = 1;
                }
#               else
#               {
#                   print "$_\n";
#                   die;
#               }
#           }
            $line++;
        }
#       print "FASTA LOADED\n";
    #   print "\n\n";
        undef $chromo;
        close FILE;
    }
#   else
#   {
#       print "CHROM $chromName IN LINE $desiredLine ALREADY IN MEMORY ($geneName)\n";
#   }
    if ( ! @gene ) { die "NO GENE READ\n";};
    return \@gene;
#   return \%XMLpos;
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
            foreach my $nuc (split("",$_))
            {
                if ( ! defined $chromos{$chromo})
                { 
                    my $next             = (keys %chromos)+1;
                    $chromos{$chromo}    = $next;
                    $stat{$next}{"size"} = 0;
                }
                $stat{$chromos{$chromo}}{"size"}++;
            }
#           $tell = tell(FILE);
        }

        if (/^>(.*)/)
        {
            $on     = 1;
            $chromo = $1;
            $pos    = 1;
            $chromosMap{$chromo} = tell(FILE);
#           $chromosMap{$chromo} = $line;
        }
        $line++;
    }
    undef $chromo;
    close FILE;
}


sub positionTable
{
    my @unsorted = @{$_[0]};

    my %seen     = ();
    my @sorted   = grep { ! $seen{$_} ++ } @unsorted;
       @sorted   = (sort { $a <=> $b}  @sorted);
    my $totalSeq = &max(@sorted);

    my $list = "";
    for (my $s = 0; $s < @sorted; $s += 10)
    {
        my $max    = $s+9;
        if ($max  >= @sorted-1) { $max = @sorted-1; };
        for (my $i = $s; $i <= $max; $i++)
        {
            $list .= "0"x((length $totalSeq) - (length $sorted[$i])) . $sorted[$i] . "\t";
        }
        $list .= "\n";
    }
#   print "$list";
    return $list;
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


sub consensus
{
    my @array = @_;
    my $output;

    if (@array == 1)
    {
        my $new = ${$array[0]}{"new"};
        if ($new eq ".") {$new = "*";};
        $output .= lc($new);
    #   print "SINGLE ON $id POS $j " . @{$new{$j}} . "\n";
    }
    else
    {
        my $prev  = "";
        my $equal = 1;
    
        foreach my $part (@array)
        {
            my $new = ${$part}{"new"};
            if ($prev eq "")   { $prev = $new; };
            if ($prev ne $new) { $equal = 0;   };
        }
    
        if ($equal)
        {
        #   print "DUAL NEW ON $id POS $j " . @{$new{$j}};
            my $new = ${$array[0]}{"new"};
            if ($new eq ".") {$new = "*";};
            $output .= uc($new);
        #   print " EQUAL $new";
        }
        else
        {
            print "*" x100 . "DUAL NEW ON @array " . @array . " DIFF ";
            foreach my $part (@array)
            {
                my $new = ${$array[$part]}{"new"};
                if ($new eq ".") {$new = "*";};
                $output .= "$new+";
                print "$new ";
            }
            print "\n";
        }
    } # end if more than 1 element
    return $output;
}


sub consensusProg
{
    my @array = @_;
    my $output = "";

    if (@array == 1)
    {
        my $new = ${$array[0]}{"program"};
        $output .= $new;
    }
    else
    {
        foreach my $part (sort @array)
        {
            if ($output) { $output .= "+" . ${$part}{"program"}; }
            else         { $output .= ${$part}{"program"}; };
        }

    }
    return $output;
}


sub consensusSimple
{
    my @array;
    my $output = "";

    if (defined $_[0])
    {
        @array = @_;

#       print @array;
#       sleep 3;

        if (@array == 1)
        {
            my $new = $array[0];
            if ($new eq ".") {$new = "*";};
            $output .= lc($new);
        #   print "SINGLE ON $id POS $j " . @{$new{$j}} . "\n";
        }
        elsif (@array > 1)
        {
            my $prev  = "";
            my $equal = 1;
        
            foreach my $part (@array)
            {
                if ($prev eq "")    { $prev = $part; };
                if ($prev ne $part) { $equal = 0;   };
            }
        
            if ($equal)
            {
            #   print "DUAL NEW ON $id POS $j " . @{$new{$j}};
                my $new = $array[0];
                if ($new eq ".") {$new = "*";};
                $output .= uc($new);
            #   print " EQUAL $new";
            }
            else
            {
                print "*" x100 . "DUAL NEW ON @array " . @array . " DIFF ";
                foreach my $part (@array)
                {
                    my $new = $part;
                    if ($new eq ".") {$new = "*";};
                    $output .= "$new+";
                    print "$new ";
                }
                print "\n";
            }
        } # end elsif @array has more than 1 element
        else
        {
            $output = "";
        }
    } #end if $_[0]
    else
    {
        $output = "";
    }

    return $output;
}


sub consensusProgSimple
{
    my @array;
    my $output = "";

    if (defined $_[0])
    {
        @array = @_;

        if (@array == 1)
        {
            my $new  = $array[0];
            $output  = $new;
        }
        elsif (@array > 1)
        {
            foreach my $part (sort @array)
            {
                if ($output) { $output .= "+" . $part; }
                else         { $output .= $part; };
            }
        }
        else
        {
            $output = "";
        }
    }
    else
    {
        $output = "";
    }

    return $output;
}

sub consensusProgArray
{
    my @array = @_;
    my @output;

    if (@array == 1)
    {
        my $new = ${$array[0]}{"program"};
        $output[0] = $new;
    }
    else
    {
        foreach my $part (sort @array)
        {
            push(@output, ${$part}{"program"});
        }
    }
    return @output;
}


sub loadXML
{
    my $file = $_[0];
    %XMLtemp = %{&parseXML($file)};

    if ($rootType eq "snp")
    {
        %XMLsnp   = %{&mergeHash(\%XMLsnp, \%XMLtemp)};
    }
    elsif ($rootType eq "gap")
    {
        %XMLgap   = %{&mergeHash(\%XMLgap, \%XMLtemp)};
    }
    elsif ($rootType eq "blast")
    {
        %XMLblast = %{&mergeHash(\%XMLblast, \%XMLtemp)};
    }
    else
    {
        die "UNKNOWN ROOT TYPE";
    }
    undef %XMLtemp;
}




sub mergeHash
{
    my @hashes = @_;

    my %merged;
    foreach my $hashRef (@hashes)
    {
        while ((my $k, my $v) = each %{$hashRef})
        {
            if (exists $merged{$k})
            {
                while ((my $kk, my $vv) = each %{$v})
                {
                    $merged{$k}{$kk} = $vv;
                }
            }
            else
            {
                $merged{$k} = $v;
            }
        }
    }

    return \%merged;
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
    my $currId      = "";
    my %XMLhash;

    foreach my $line (<FILE>)
    {
        if ($line =~ /<root id=\"(.*)\" type=\"(.*)\">/)
        {
            $rootType = $2 ;
        }
        if ($line =~ /<table id=\"(.*)\" type=\"(.*)\">/)
        {
            $table     = 1;
            $tableName = $1;
            $tableType = $2;
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
            if ($line =~ /<(\w+)>(\S+)<\/\1>/)
            {
#               print "$line\n";
                my $key   = $1;
                my $value = $2;
#               print "$register => $key -> $value\n";
                if ($tableName)
                {
#                   print "$tableName $register $key $value\n";
                    $XMLhash{$tableName}{$registre}{$key} = $value;
#                   $XMLhash{$tableName}{$currId}{$key} = $value;
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
    print "  ROOT TYPE: $rootType TABLE TYPE: $tableType\n";
    return \%XMLhash;
}


sub list_dir
{
    my $dir = $_[0];
    my $ext = $_[1];
#   print "openning dir $dir and searching for extension $ext\n";

    opendir (DIR, "$dir") or die "CANT READ DIRECTORY $dir: $!\n";
    my @ext = grep { (!/^\./) && -f "$dir/$_" && (/$ext$/)} readdir(DIR);
    closedir DIR;

    return @ext;
}

sub list_subdir
{
    my $dir = $_[0];

#   print "openning dir $dir and searching for subdirs\n";

    opendir (DIR, "$dir") or die "CANT READ DIRECTORY $dir: $!\n";
    my @dirs = grep { (!/^\./) && -d "$dir/$_" } readdir(DIR);
    closedir DIR;

    return @dirs;
}

sub genCoverage
{
    my @rep = @{$_[0]};
    my $start;
    my $end;
    my %cov;
    my $total   = @rep;
    my $covered = 0;

    for (my $i = 0; $i < @rep; $i++)
    {
        if ($rep[$i])
        {
            $start = $i+1;
            while ($rep[++$i]) {};
            $end   = $i+1;
            $covered += ($end-$start);
            $i--;
            $cov{$start} = $end; 
        };
    }
    $cov{"cov"} = $covered;
    return \%cov;
}


sub init
{
    if (($inputFA) && (@inputXML)) #checks if all parameters are set
    {
        if ( -f $inputFA )
        {
            my $output;
            if ( ! $inputFA =~ /\/*([\w|\.]+)\.fasta/)
            {
                die "COULD NOT RETRIEVE THE NAME FROM $inputFA";
            }
            elsif ( $inputFA =~ /\/*([\w|\.]+)\.fasta/)
            {
                $output = $1;
            }
        
            print "  INPUT  FASTA: $inputFA\n";
            print "  INPUT  XML  :\n\t" . join("\n\t", @inputXML) . "\n";
            print "\n";
    
            foreach my $inputXML (@inputXML)
            {
                if ( -f $inputXML )
                {
                    &loadXML($inputXML); #obtains the xml as hash
                }
                elsif ( -d $inputXML)
                {
                    my @files = &list_dir($inputXML,".xml");
                    print "ITERATING OVER " . @files . " FILES UNDER $inputXML\n";
                    $iterating = 1;
                    foreach my $file (sort @files)
                    {
                        &loadXML("$inputXML/$file"); #obtains the xml as hash
                    }
                }
                else
                {
                    my $exit;
                    if (( ! -f $inputXML) && ( ! -d $inputXML)) { $exit  = "FILE $inputXML DOESNT EXISTS\n";};
                    if (( ! -d $inputXML) && ( ! -f $inputXML)) { $exit .= "DIR  $inputXML DOESNT EXISTS\n";};
                    print $exit;
                    exit 1; 
                }
            } # end foreach my inputxml
            mkdir("XMLpos");
            &start($inputFA,$output);
    
        } # end if file INPUTFA exists
        else
        {
            my $exit;
            if ( ! -f $inputFA)  { $exit .= "FILE $inputFA  DOESNT EXISTS\n";};
            print $exit;
            exit 1; 
        } # end else file INPUTFA exists
    } # end if FA & XML were defined
    else
    {
        print "USAGE: XML_IMAGE.PL <INPUT FASTA.FASTA> <MULTIPLE INPUT XML or INPUT DIR, SNP or GAP>\n";
        print "E.G.: ./xml_image.pl ../../inputs/R265_cryptococcus_neoformans_serotype_b_1_supercontigs.fasta xml_merged/snps.xml ../gaps/cns.indelse.chrom.xml\n";
        print "E.G.: ./xml_image.pl input.fasta input.snp.xml input.gap.xml\n";
        print "E.G.: ./xml_image.pl input.fasta xml_merged/ input.gap.xml\n";
        print "E.G.: ./xml_image.pl input.fasta input.snp.xml input.gap.xml  input.blast.xml\n";
        print "E.G.: ./xml_pos.pl input.fasta input.gap.indelsa.xml input.gap.mummer.xml input.blast.xml input.snp.xml\n";
        exit 1;
    }
}


exit 0;

1;