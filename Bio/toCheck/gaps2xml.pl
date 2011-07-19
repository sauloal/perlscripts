#!/usr/bin/perl -w
use strict;
use warnings;
# use AnyData::Format::XML;
use AnyData;
use Data::Dumper;
# use XML::Twig;
# use XML::Parser;

print "PARSING SNP FILES\n";
mkdir "xml";

# &parse_eland("eland","eland");
# &parse_maq("cns.indelse","maq");
&parse_maq("cns.indelsa","maq");

sub parse_maq
{
    my $file   = $_[0];
    my $folder = $_[1];

    print "READING FILE $folder/$file\n";
    my $prog = "maq";

    if ( -f "$folder/$file" )
    {
        open FILEIN, "<$folder/$file" or die "  COULD NOT OPEN FILE $folder/$file: $!";
        my @total   = <FILEIN>;
        print " " x4 . @total . " LINES LOADED FROM $file\n";
        close FILEIN;

        open  FILERAW, ">xml/$file.raw.xml" or die "  COULD NOT SAVE FILE $file.raw.xml: $!";
        print "SAVING FILE xml/$file.raw.xml\t";
        print FILERAW  "<root id=\"indelse\" type=\"gap\">\n";
        print FILERAW  "\t<table id=\"$prog\" type=\"program\">\n";

        if (@total)
        {
            my %byChrom;
            my $reg = 0;
            foreach my $line (@total)
            {
    # supercontig_1.01_of_Cryptococcus_neoformans_Serotype_B    43  -1  0   36  23  59
    # supercontig_1.01_of_Cryptococcus_neoformans_Serotype_B    3095    4   2   1   2   1
    # supercontig_1.01_of_Cryptococcus_neoformans_Serotype_B    6873    5   2   1   1   0
    # supercontig_1.01_of_Cryptococcus_neoformans_Serotype_B    8721    2   1   1   1   1
    # supercontig_1.01_of_Cryptococcus_neoformans_Serotype_B    11719   3   0   1   1   2
    # chromossome                           coord   length  reads   readLef readRig ign
                if ($line =~ /(\S+)\s+(\S+)\s+(\S+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\S+)$/)
                #             chromo  start   length  reads    rLeft  rRight  Ignobio
                {
                    my $chrom  = $1;
                    my $start  = $2;
                    my $length = $3;
                    my $reads  = $4;    
                    my $rLeft  = $5;
                    my $rRight = $6;
    
                    my $end    = $start;
                    if ($length > 0)
                    {
                        $end += $length-1;
                    }
                    else
                    {
                        $end -= $length+1;
                    };
    
                    $byChrom{$chrom}{$start}{"end"}     = $end;
                    $byChrom{$chrom}{$start}{"length"}  = $length;
                    $byChrom{$chrom}{$start}{"reads"}   = $reads;
                    $byChrom{$chrom}{$start}{"rLeft"}   = $rLeft;
                    $byChrom{$chrom}{$start}{"rRight"}  = $rRight;
                    $byChrom{$chrom}{$start}{"program"} = $prog;
                    $byChrom{$chrom}{$start}{"id"}      = $reg;
    
    #               print "$chrom $start $end $length $reads $rLeft $rRight\n";
                    
                    print FILERAW "\t\t<row id=\"$reg\">\n";
                    print FILERAW "\t\t\t<chromR>$chrom</chromR>\n";
                    print FILERAW "\t\t\t<start>$start</start>\n";
                    print FILERAW "\t\t\t<end>$end</end>\n";
                    print FILERAW "\t\t\t<length>$length</length>\n";
                    print FILERAW "\t\t\t<reads>$reads</reads>\n";
                    print FILERAW "\t\t\t<rLeft>$rLeft</rLeft>\n";
                    print FILERAW "\t\t\t<rRight>$rRight</rRight>\n";
                    print FILERAW "\t\t\t<id>$reg</id>\n";
                    print FILERAW "\t\t</row>\n";
                    $reg++;
                } #end if match re
                else
                {
                    $reg++;
                    print "$reg $line DIDNT MATCH RE\n";
                }
            } #end foreach my line
            print FILERAW  "\t</table>\n";
            print FILERAW  "</root>\n";
            close FILERAW;
            print "DONE: $reg REGISTERS\n";
    





            open  FILECHROM, ">xml/$file.chrom.xml" or die "  COULD NOT SAVE FILE xml/$file.chrom.xml: $!";
            print FILECHROM  "<root id=\"indelse\" type=\"gap\">\n";
            print "SAVING FILE xml/$file.chrom.xml\n";
            my $reg2 = 0;
            my $reg3 = 0;

            foreach my $chrom (sort keys %byChrom)
            {
                $reg = 0;
                print "SAVING FILE $file.$chrom.xml\t";
                open  FILE2,     ">xml/$file.$chrom.xml" or die "  COULD NOT SAVE FILE $file.$chrom.xml: $!";
                print FILE2      "<root id=\"indelse\" type=\"gap\">\n";
                print FILE2      "\t<table id=\"$chrom\" type=\"chromossome\">\n";
                print FILECHROM  "\t<table id=\"$chrom\" type=\"chromossome\">\n";
                foreach my $start (sort { $a <=> $b} keys %{$byChrom{$chrom}})
                {
                    my $end    = $byChrom{$chrom}{$start}{"end"};
                    my $length = $byChrom{$chrom}{$start}{"length"};
                    my $reads  = $byChrom{$chrom}{$start}{"reads"};
                    my $rLeft  = $byChrom{$chrom}{$start}{"rLeft"};
                    my $rRight = $byChrom{$chrom}{$start}{"rRight"};
                    my $prog   = $byChrom{$chrom}{$start}{"program"};
                    my $id     = $byChrom{$chrom}{$start}{"id"};
        
                    my $row;
                    $row .= "\t\t<row id=\"$id\">\n";
    #               print FILE "\t\t\t<chrom>$chrom</chrom>\n";
                    $row .= "\t\t\t<start>$start</start>\n";
                    $row .= "\t\t\t<end>$end</end>\n";
                    $row .= "\t\t\t<length>$length</length>\n";
                    $row .= "\t\t\t<reads>$reads</reads>\n";
                    $row .= "\t\t\t<rLeft>$rLeft</rLeft>\n";
                    $row .= "\t\t\t<rRight>$rRight</rRight>\n";
                    $row .= "\t\t\t<program>$prog</program>\n";
                    $row .= "\t\t\t<id>$id</id>\n";
                    $row .= "\t\t</row>\n";
                    print FILECHROM $row; print FILE2 $row;
                    $reg++; $reg2++;
                } # end foreach my $start
                print FILE2 "\t</table>\n";
                print FILE2 "</root>\n";
                close FILE2;
                print FILECHROM  "\t</table>\n";
                print "DONE: $reg REGISTERS\n";
                $reg3 += $reg;
            } #end foreach my chrom
            print FILECHROM "</root>\n";
            close FILECHROM;
            print "SAVING FILE xml/$file.chrom.xml\tDONE:$reg2 ($reg3) REGISTERS\n";
        } # end if total
        else
        {
            print "FILE $folder/$file IS EMPTY\n";
        }
#       close FILE;
    } # end if dir/file doesnt exists
    else
    {
        die "FILE $folder/$file DOESNT EXISTS\n"
    }

}




sub parse_eland
{
    my $file   = $_[0];
    my $folder = $_[1];
    my $prog   = "eland";

    print "READING FILE $folder/$file\n";

    if ( -f "$folder/$file" )
    {
        open FILEIN, "<$folder/$file" or die "  COULD NOT OPEN FILE $folder/$file: $!";
        my @total   = <FILEIN>;
        print " " x4 . @total . " LINES LOADED\n";
        close FILEIN;

        if (@total)
        {
            open  FILERAW, ">xml/$file.raw.xml" or die "  COULD NOT SAVE FILE $file.raw.xml: $!";
            print "SAVING FILE xml/$file.raw.xml\t";
            print FILERAW  "<root id=\"eland\" type=\"gap\">\n";
            print FILERAW  "\t<table id=\"$prog\" type=\"program\">\n";

            my %chroms;
            my $chrom;
            my $reg = 0;
            foreach my $line (@total)
            {
#               >Cryptococcus_neoformans_Serotype_B_supercontig_1.11
#               1   1   39  39  1
#               2   8439    8443    5   1
#               3   12733   13396   664 1
#               172 696596  696620  25  1
#               173 698038  698145  108 1
#               >Cryptococcus_neoformans_Serotype_B_supercontig_1.6
#               174 1   837 837 1

                if ($line =~ /^>(\S+)/)
                {
                    $chrom = $1;
                    if ( $chrom =~ /(\d)\.(\d+)$/)
                    {
                        my $number = $2;
                        if ($number < 10) { $number = "0$number"; };
                        $chrom = "supercontig_$1.$number\_of_Cryptococcus_neoformans_Serotype_B"
                    }
#                   supercontig_1.01_of_Cryptococcus_neoformans_Serotype_B
#                   Cryptococcus_neoformans_Serotype_B_supercontig_1.10
                }
                elsif ($line =~ /(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)$/)
                #             count   start   end     size    unknown
                {
                    my $count   = $1;
                    my $start   = $2;
                    my $end     = $3;
                    my $size    = $4;   
                    my $unknown = $5;
                    $reg++;

                    my $out1;my $out2;my $out3;my $out4;
                    $out1  = "\t\t<row id=\"$count\">\n";
                    $out2  = "\t\t\t<chromR>$chrom</chromR>\n";
                    $out3  = "\t\t\t<start>$start</start>\n";
                    $out3 .= "\t\t\t<end>$end</end>\n";
                    $out3 .= "\t\t\t<length>$size</length>\n";
                    $out3 .= "\t\t\t<id>$count</id>\n";
                    $out3 .= "\t\t</row>\n";
                    $out4  = "\t\t\t<program>$prog</program>\n";
                    print FILERAW "$out1$out2$out3";
                    push(@{$chroms{$chrom}}, "$out1$out4$out3");
                } #end if match re
                else
                {
                    die "ERROR PARSING: $line";
                }
            } #end foreach my line
            print FILERAW  "\t</table>\n";
            print FILERAW  "</root>\n";
            close FILERAW;
            print "done ($reg)\n";



            open  FILECHROM, ">xml/$file.chrom.xml" or die "  COULD NOT SAVE FILE xml/$file.chrom.xml: $!";
            print FILECHROM  "<root id=\"eland\" type=\"gap\">\n";
            print "SAVING FILE xml/$file.chrom.xml\n";

            foreach my $chrom (sort keys %chroms)
            {
                print "SAVING FILE xml/$file.$chrom.xml...";
                open  FILE2,     ">xml/$file.$chrom.xml" or die "  COULD NOT SAVE FILE xml/$file.$chrom.xml: $!";
                print FILE2      "<root id=\"eland\" type=\"gap\">\n";
                print FILE2      "\t<table id=\"$chrom\" type=\"chromossome\">\n";
                print FILECHROM  "\t<table id=\"$chrom\" type=\"chromossome\">\n";
                print FILECHROM   join("", @{$chroms{$chrom}});
                print FILE2       join("", @{$chroms{$chrom}});
                print FILECHROM  "\t</table>\n";
                print FILE2      "\t</table>\n";
                print FILE2      "</root>\n";
                close FILE2;
                print "done\n";
            }

            print FILECHROM "</root>\n";
            close FILECHROM;
            print "SAVING FILE xml/$file.chrom.xml...DONE\n";

        } #end if @total
    } # end if dir/file doesnt exists
}




1;