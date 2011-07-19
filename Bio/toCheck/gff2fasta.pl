#!/usr/bin/perl -w
use strict;
use warnings;

use Bio::SeqIO;
use Bio::Seq;
use IO::String;

my %ann;

&loadFiles;

foreach my $locus (keys %ann)
{
        my $mRNAPro     = $ann{$locus}{"mRNAPro"};
        if ($mRNAPro)     { $mRNAPro        =~ tr/[a-z][A-Z][0-9]/_/c} else {$mRNAPro = "no_product"};
        my $mRNATransID = $ann{$locus}{"mRNATransID"};
        my $seq         = $ann{$locus}{"seq"};
        my $length      = length($seq);
        while ($length % 3) { $seq .= "N"; $length = length($seq); };
        if ($length % 3) { die "LENGTH $length OF SEQUENCE $locus ISNT DIVISIBLE BY 3"; };
#       print "SIZE = " . $length . "\n";
           $seq         =~ s/(.{60})/$1\n/g;
        my $start       = $ann{$locus}{"start"};
        my $end         = $ann{$locus}{"end"};
        my $id          = $ann{$locus}{"id"};
        my $desc        = $ann{$locus}{"desc"};
        print ">$id $id\_$locus\_$mRNAPro\_$start\_$end\n$seq\n";
}

# my $outseq = Bio::SeqIO->new( -fh     => \*STDOUT,
#               -format => "fasta");

sub loadFiles
{
    opendir (DIR, "./") || die "CANT READ DIRECTORY: $!\n";
    my @dots = grep { (!/^\./) && -f "./$_" && (/\.fa$/ || /\.gbff$/)} readdir(DIR);
    closedir DIR;

    my %hash = map { /^(\S+)\.(fa|gbff)$/; $1 => "file"; } @dots;
    my $countFile = 0;
    my $countSeq  = 0;

    foreach my $key (sort keys %hash)
    {
#       print "\t PARSING $key";
        $countFile++;
        my $countSeqFile = 0;
        my $name     = $key;
        my $string   = `cat $name.gbff`;
        $string     .= "\nORIGIN\n";
        $string     .= `cat $name.fa`;
        my $stringfh = new IO::String($string);
        my $stream   = Bio::SeqIO->new( -fh     => $stringfh,
                        -format => 'GenBank');
    
        while (my $seq = $stream->next_seq())
        {
            my $sequence    = $seq->seq();
            my $anumber = $seq->accession_number();
            my $display_id  = $seq->display_id();
            my $subseq  = $seq->subseq(5,10);
            my $alphabet    = $seq->alphabet();
            my $primary_id  = $seq->primary_id();
            my $length  = $seq->length();
            my $description = $seq->description();
            my $strain  = "";
        
            my $desc = "";
            $desc .= "DISPLAY ID\t" . $display_id   . "\n"; # the human read-able id of the sequence
        #   $desc .= "SUBSEQ    \t" . $subseq   . "\n"; # part of the sequence as a string
            $desc .= "ALPHABET  \t" . $alphabet . "\n"; # one of 'dna','rna','protein'
            $desc .= "PRIMARY ID\t" . $primary_id   . "\n"; # a unique id for this sequence regardless of its display_id or accession number
            $desc .= "LENGTH    \t" . $length   . "\n"; # sequence length
#           if ($length % 3) { die "LENGTH $length OF SEQUENCE $anumber ISNT DIVISIBLE BY 3"; };
            $desc .= "DESCRIPT  \t" . $description  . "\n"; # a description of the sequence
        #   $desc .= "SEQ       \t" . $sequence . "\n";              # string of sequence
            $desc .= "ACC NUMBER\t" . $anumber  . "\n"; # when there, the accession number
    #       print $desc;
        
        
            for my $feat_object ($seq->get_SeqFeatures)
            {
                my $gene;
                my $mRNA_Pro;
                my $locus;
                my $mRNA_Seq;
                my $mRNA_Trans_ID;
        
                my $primary_tag = $feat_object->primary_tag;
        #       print "primary tag: ", $primary_tag , "\n";
                for my $tag ($feat_object->get_all_tags)
                {
        #           print "  tag: ", $tag, "\n";
                    for my $value ($feat_object->get_tag_values($tag))
                    {
                        if ((($primary_tag eq "gene") ||($primary_tag eq "mRNA")) && ($tag eq "locus_tag"))
                        {
                            $locus = $value; 
                            $ann{$locus}{"seq"}   = $feat_object->seq()->seq();
                            $ann{$locus}{"start"} = $feat_object->start;
                            $ann{$locus}{"end"}   = $feat_object->end;
                            $ann{$locus}{"id"}    = $display_id;
                            $ann{$locus}{"desc"}  = $description;
                            $countSeq++;
                            $countSeqFile++;
                        };
                        if ($locus)
                        {
                            if (($primary_tag eq "mRNA") && ($tag eq "product"))       { $ann{$locus}{"mRNAPro"}     = $value; };
                            if (($primary_tag eq "mRNA") && ($tag eq "transcript_id")) { $ann{$locus}{"mRNATransID"} = $value; };
        #                   my $gene = $seq->gene2liveseq(-gene_name => "$locus");
        #                   if ($primary_tag eq "mRNA") { $ann{$locus}{"seq"} = $feat_object->seq(); };
                        }
        #               print "    value: ", $value, "\n";
                    }
                }
            }
        
        #   foreach my $feat ( $seq->top_SeqFeatures )
        #   {
        #       my $locus;
        #       my $mRNA_Pro;
        #       if ( $feat->primary_tag eq 'CDS' )
        #       {
        #       my $cds_obj = $feat->spliced_seq;
        #       print ">".$seq->display_id()."\n".$cds_obj->seq."\n";
        #       }
        #   }
        
        } # end while seq
#   print " > $countSeqFile SEQUENCES\n";
    } #end foreach key hash
#   print "$countFile FILES LOADED WITH $countSeq SEQUENCES\n";
}

1;