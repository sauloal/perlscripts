#!/usr/bin/perl -w
use strict;
use warnings;
use lib "./lib";
# use loadconf;
# my %pref = &loadconf::loadConf;
package getNCBI;

require Exporter;
our @ISA         = qw(Exporter);
our @EXPORT_OK   = qw(getNCBI);
our $DESCRIPTION = "Returns NCBI entrances from NCBI IDs with custom headers
\tAccepts as input any NCBI reference number (GI,GB,REF,etc) separated by new lines (enter)
\te.g.\n\tEF636668\n\t209863141\n\tNM_001045191\n\tCR457022
\tAccepts as input fasta files separated by new lines (enter)
\te.g.>gi|165881902|gb|EU192366.1| Malassezia pachydermatis strain ATCC 14522 18S ribosomal RNA gene, partial sequence
\tTTTGGGCTTTGGTGAATATAATAACTTCTCGGATCGCATGGCCTTGTGCCGGCGATGCTTCATTCAAATA
\tTCTGCCCTATCAACTGTCGATGGTAGGATAGAGGCCTACCATGGTTGCAACGGGTAACGGGGAATAAGGG
\t
\t>gi|113681126|ref|NP_001038656.1| si:dkey-98n4.1 [Danio rerio]
\tMSNGAAGSGGLTWVTLFDKNNGAKKEEMNGRGDAGKSEVVKKESSKKMSVERIYQKKTQLEHILLRPDTY
\tIGSVEPVTQQMWVFDEEIGMNLREISFVPGLYKIFDEILVNAADNKQRDKNMTTIKITIDPESNTISVWN
\tReturns a fasta file containing SPECIES NAME _ STRAIN _ ACC NUMBER
\tif SPECIES NAME is not found, Taxon ID is placed
\tSTRAIN only appears when the word \"strain\" appears in the text. then, the next 2 words will be used
";

use Bio::DB::GenBank;
use Bio::SeqIO::fasta;

# &getNCBI("EF636668\n209863141\n209862803\nNM_001045191\nCR457022\n>gi|165881902|gb|EU192366.1| Malassezia pachydermatis strain ATCC 14522 18S ribosomal RNA gene, partial sequence
# TTTGGGCTTTGGTGAATATAATAACTTCTCGGATCGCATGGCCTTGTGCCGGCGATGCTTCATTCAAATA
# TCTGCCCTATCAACTGTCGATGGTAGGATAGAGGCCTACCATGGTTGCAACGGGTAACGGGGAATAAGGG
# 
# >gi|113681126|ref|NP_001038656.1| si:dkey-98n4.1 [Danio rerio]
# MSNGAAGSGGLTWVTLFDKNNGAKKEEMNGRGDAGKSEVVKKESSKKMSVERIYQKKTQLEHILLRPDTY
# IGSVEPVTQQMWVFDEEIGMNLREISFVPGLYKIFDEILVNAADNKQRDKNMTTIKITIDPESNTISVWN","getNCBI");

sub getNCBI
{
    my $input = $_[0]; # body of the incoming message untreated
    my $title = $_[1]; # title of the incoming message untreated

    my @input = split("\n",$input);
    my @output = &parse_input(\@input);
#   print $output[0];
#   print $output[1];

    my $output = $output[0];

    return $output; #body of the outgoing message untreated
}



sub parse_input
{
    my @input = @{$_[0]};

    my @NCID; my @NCACC; my @NCGI; my @fasta;
    my $fasta = 0;

    foreach my $unit (@input)
    {
        if (($unit =~ /^>/) || ($fasta))
        {
            if ( $unit =~ /^\s+$/ )  #if it is a empty line
            {
                $fasta = 0; push (@fasta, $unit); #stop fasta but insert the empty line on the array
            }
            else # if it is not empty, it is the sequence, keep pushing
            {
                $fasta = 1; push (@fasta, $unit);
            };
        }
        elsif ($unit =~ /\A((NT)|(NC)|(NG)|(NM)|(NP)|(XM)|(XR)|(XP))\_\d{5,8}/i)
        {
            push (@NCID, $unit);
#           print "$unit is ID\n";
        }
        elsif ($unit =~ /^[a-zA-Z]{2}\d{6,8}/)
        {
            push (@NCACC, $unit);
#           print "$unit is ACC\n";
        }
        elsif ($unit =~ /\d{6,10}/)
        {
            push (@NCGI, $unit);
#           print "$unit is GI\n";
        }
        else
        {
            print "$unit is an unidentified type code\n";
        }
    }

    my @fastaRefs = &get_fasta_id(\@fasta);
    my @fastaGI   = @{$fastaRefs[0]};
    my @fastaGB   = @{$fastaRefs[1]};
    my @fastaSP   = @{$fastaRefs[2]};
    my @fastaRef  = @{$fastaRefs[3]};
    my @fastaCon  = @{$fastaRefs[4]};

    my $output1;
    my $output2;
    my @output;

    ($output1, $output2) = &parse_input(\@fastaCon) if (@fastaCon);
    $output[1] = $output1;
    $output[2] = $output2;

    ($output1, $output2) = &queryGB(\@NCID,"id");
    $output[1] .= $output1;
    $output[2] .= $output2;

    ($output1, $output2) = &queryGB(\@NCACC,"acc");
    $output[1] .= $output1;
    $output[2] .= $output2;

    ($output1, $output2) = &queryGB(\@NCGI,"gi");
    $output[1] .= $output1;
    $output[2] .= $output2;

    return ($output[1], $output[2]);
}


sub queryGB
{
        my @input = @{$_[0]};
        my $type  = $_[1];
        my $gb    = new Bio::DB::GenBank;

        my $output = "";
        my $desc   = "";

        my $seqio;

        if ($type eq "id")
        {
            $seqio = $gb->get_Stream_by_id(\@input);
        }
        elsif ($type eq "acc")
        {

            $seqio = $gb->get_Stream_by_acc(\@input);
        }
        elsif ($type eq "gi")
        {
            $seqio = $gb->get_Stream_by_gi(\@input);
        }
        else
        {
            return "";
        }


        while ( my $seq = $seqio->next_seq() )
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

            my $organism;

            for my $feats ($seq->get_SeqFeatures)
            {
                if ($feats->primary_tag eq "source")
                {
                    my @organism = $feats->get_tag_values("organism");
                    $organism = $organism[0];
                }
            }

            if ( ! $organism )
            {
                for my $feats ($seq->get_SeqFeatures)
                {
                    if ($feats->primary_tag eq "source")
                    {

                        my @organism = $feats->get_tag_values("db_xref");
                        $organism = $organism[0] if ($organism[0] =~ /taxon:/);
                    }
                }
            }

            if ( ! $organism )
            {
                $organism = "unknown";
            }

            $desc .= "CLASS     \t" . $type     . "\n"; # type of accession number
            $desc .= "DISPLAY ID\t" . $display_id   . "\n"; # the human read-able id of the sequence
            $desc .= "SUBSEQ    \t" . $subseq   . "\n"; # part of the sequence as a string
            $desc .= "ALPHABET  \t" . $alphabet . "\n"; # one of 'dna','rna','protein'
            $desc .= "PRIMARY ID\t" . $primary_id   . "\n"; # a unique id for this sequence regardless of its display_id or accession number
            $desc .= "LENGTH    \t" . $length   . "\n"; # sequence length
            $desc .= "DESCRIPT  \t" . $description  . "\n"; # a description of the sequence 
            $desc .= "SEQ       \t\n" . &faster($sequence)  . "\n";              # string of sequence
            $desc .= "ACC NUMBER\t" . $anumber      . "\n"; # when there, the accession number
            $desc .= "ORGANISM  \t" . $organism . "\n";
            if ($desc =~ /strain ((\w+) (\w+))/i) { $strain = $1; };
            $desc .= "STRAIN    \t" . $strain   . "\n\n\n";

            $output .= &make_fasta($organism,$strain,$anumber,$sequence);;

#           for my $feat_object ($seq->get_SeqFeatures)
#           {          
#               print "primary tag: ", $feat_object->primary_tag, "\n";          
#               for my $tag ($feat_object->get_all_tags)
#               {             
#                   print "  tag: ", $tag, "\n";             
#                   for my $value ($feat_object->get_tag_values($tag))
#                   {                
#                       print "    value: ", $value, "\n";             
#                   }          
#               }       
#           }
        }
    return ($output, $desc);
}


sub make_fasta
{
    my $organism = $_[0];
    my $strain   = $_[1];
    my $anumber  = $_[2];
    my $sequence = $_[3];
    my $title;

    $organism =~ tr/a-zA-Z0-9_./_/c;
    $organism = "$organism\_";
    $strain   =~ tr/a-zA-Z0-9_./_/c;
    $strain   = "$strain\_" if $strain;
    $title    = ">$organism$strain$anumber";
    $sequence = &faster($sequence);

    my $concac = "$title\n$sequence\n";

    return $concac;
}

sub faster
{
    my $seq = $_[0];
    my $out = "";
    my $len = length($seq);          # This time, we will write

    my $numLines = int($len / 60);           # 60 characters per line

    if(($len % 60) != 0) { $numLines++; };

    for(my $i = 0; $i < $numLines; $i++)
    {
        my $sub = substr($seq, ($i * 60), 60) . "\n";
        $out .= $sub;
#       print "$numLines\t$i\t$sub";
    }
    return $out;
}

sub get_fasta_id
{
    my @fasta = @{$_[0]};
    my @gis;
    my @gbs;
    my @sps;
    my @refs;
    my @consol;

    foreach my $line (@fasta)
    {
#       print "$line\n";
#       >gi|165881902|gb|EU192366.1| Malassezia pachydermatis strain ATCC 14522 18S ribosomal RNA gene, partial sequence
#       TTTGGGCTTTGGTGAATATAATAACTTCTCGGATCGCATGGCCTTGTGCCGGCGATGCTTCATTCAAATA
#       TCTGCCCTATCAACTGTCGATGGTAGGATAGAGGCCTACCATGGTTGCAACGGGTAACGGGGAATAAGGG
#       >gi|113681126|ref|NP_001038656.1| si:dkey-98n4.1 [Danio rerio]
#       MSNGAAGSGGLTWVTLFDKNNGAKKEEMNGRGDAGKSEVVKKESSKKMSVERIYQKKTQLEHILLRPDTY
#       IGSVEPVTQQMWVFDEEIGMNLREISFVPGLYKIFDEILVNAADNKQRDKNMTTIKITIDPESNTISVWN
        my ($gi, $gb, $sp, $ref, $cons);

        if ($line =~ /^>/)
        {
            if ($line =~ /gi\|(\d+)\b/g)
            {
                $gi = $1;
            }
            if ($line =~ /gb\|([A-Z]{2}[0-9.]+)/g)
            {
                $gb = $1;
            }
            if ($line =~ /sp\|([A-Z]\d{5})\b/g)
            {
                $sp = $1;
            }
            if ($line =~ /ref\|([A-Z_]{3}[0-9.]+)\b/g)
            {
                $ref = $1;
            }
            push (@gis,$gi) if ($gi);
            push (@gbs,$gb) if ($gb);
            push (@sps,$sp) if ($sp);
            push (@refs,$ref) if ($ref);
            if ($gb) { $cons = $gb; } elsif ($ref) { $cons = $ref; } elsif ($gi) { $cons = $gi; };
            push(@consol, $cons) if $cons;
        }
    }

#   print "GIS :\t" . join("\n", @gis) . "\n";
#   print "GBS :\t" . join("\n", @gbs) . "\n";
#   print "SPS :\t" . join("\n", @sps) . "\n";
#   print "REF :\t" . join("\n", @refs) . "\n";
#   print "CON :\t" . join("\n", @consol) . "\n";

    return (\@gis,\@gbs,\@sps,\@refs,\@consol);
}

1;
__END__


# sub parse_input
# {
#   my $input = $_[0];
#   my %input;
#   map { $input{$_}{"working"} = 1; } split("\n",$input);
# 
#   foreach my $key (keys %input)
#   {
#       print "$key\n";
#       $input{$key}{"raw"} = &query_genbank($key);
#   }
# }

# nuc  fasta http://www.ncbi.nlm.nih.gov/entrez/viewer.fcgi?query_key=7&db=nucleotide&qty=1&term=EF636668&c_start=1&uids=&dopt=fasta&dispmax=20&sendto=t&from=begin&to=end
#    nuc  fasta http://www.ncbi.nlm.nih.gov/entrez/viewer.fcgi?query_key=7&db=nucleotide&qty=1&term=EF636668&dopt=fasta&dispmax=1&sendto=t
# prot fasta http://www.ncbi.nlm.nih.gov/entrez/viewer.fcgi?WebEnv=1noB9M_nmYezmAq6g9GWWdqrgL1qovFPrCeVhDfNwLBpUujorfaubbR2xc9-jgqy_dgEJ7QaCyVUbTRRMxqwUT%402644478B9002AD30_0161SID&query_key=13&db=protein&qty=1&term=ABU96614&c_start=1&uids=&dopt=fasta&dispmax=20&sendto=t&from=begin&to=end
# 
# nuc  ans.1 http://www.ncbi.nlm.nih.gov/entrez/viewer.fcgi?WebEnv=1F5XsSc_aetk6zoGShVg612s3XRpqggBG6bn_B47aYcD3BqLPQOhOfIPzMoaIoSQ2CJs6Q7f-Azd3xw-1unwtA%402644478B9002AD30_0161SID&db=nucleotide&qty=1&c_start=1&list_uids=156887923&uids=&dopt=asn&dispmax=5&sendto=t&extrafeatpresent=1&ef_CDD=8&ef_MGC=16&ef_HPRD=32&ef_STS=64&ef_tRNA=128&ef_microRNA=256&ef_Exon=512
#    nuc  ans.1 http://www.ncbi.nlm.nih.gov/entrez/viewer.fcgi?db=nucleotide&qty=1&c_start=1&list_uids=156887923&uids=&dopt=asn&dispmax=5&sendto=t
#    nuc  ans.1 http://www.ncbi.nlm.nih.gov/entrez/viewer.fcgi?query_key=7&db=nucleotide&qty=1&term=EF636668&c_start=1&uids=&dopt=asn&dispmax=20&sendto=t
# prot ans.1 http://www.ncbi.nlm.nih.gov/entrez/viewer.fcgi?query_key=13&db=protein&qty=1&term=ABU96614&c_start=1&uids=&dopt=asn&dispmax=20&sendto=t



# sub query_genbank_nuc
# {
#   my $query   = $_[0];
#   
#   chomp $query;
#   my $url      = "http://www.ncbi.nlm.nih.gov/entrez/viewer.fcgi?query_key=7&db=nucleotide&qty=1&term=$query&c_start=1&uids=&dopt=asn&dispmax=20&sendto=t";
#   my $agent    = new LWP::UserAgent();
#   my $request  = new HTTP::Request('GET' => $url); # get the URL
#   my $response = $agent->request($request); # get the response of the request
#   my $answer;
# 
# 
#   if ($response->is_success()) # if got the page successifully
#   {
#       $answer = $response->content();
#       print $answer;
#   } # END if response success
#   else # else (if doesnt get a response from the site)
#   {
#       print "redo $query\n";
#       $answer = &query_genbank_nuc($query);
#       print $answer;
#   } # END else response success
# 
#   return $answer;
# } # sub query genbank
# 
# 
# 
# 
# sub query_genbank2
# {
#   open(TEMP2, "temp2.txt") or die("Error on file oppening: " . "temp2.txt\n");
#   
#   my $number_of_queries;
#   
#   while (<TEMP2>)
#   {
#       ++$number_of_queries;
#       `wget "http://www.ncbi.nlm.nih.gov/entrez/viewer.fcgi?val=$_"`; 
#   }
#   
#   close(TEMP2) or die("Error on file closing: temp2.txt\n");
#   
#   for (my $i = 1; $i < 10; ++$i)
#   {
#       `cat viewer.fcgi?val=$i* >> viewer.out`;
#   }
# }
# 
# 
# sub get_sequences_IDs
# {
# #     print "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@\n";
# #     print "@@@@@@@@@@> GET SEQUENCES IDs <@@@@@@@@@@\n";
# #     print "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@\n";
# #     open(LOG, ">>log") or die("Error on file oppening: LOG\n");
# #     print LOG "GET SEQUENCES ID: START AT " . `date` . "\n";
# # 
# #     $nome_final = "temp1_" . $suffix . ".txt";
# #     print "LOADING TEMP1 - $nome_final\n";
# #     open (TEMP1, "$nome_final") or die("Error on file oppening: TEMP1\n");
# # 
# #     $nome_final = "temp2_" . $suffix . ".txt";
# #     print "LOADING TEMP1 - $nome_final\n";
# #     open (TEMP2, ">$nome_final") or die("Error on file oppening: TEMP2\n");
# #     print "TEMP1 LOADED\n";
# # 
# #     while (<TEMP1>)
# #     {
# #     # se houverem d?gitos na linha
# #     if (/\d/)
# #         {
# #             #>gi|15595213|ref|NP_248705.1| hypothetical protein PA0015 [Pseudomonas aeruginosa PAO1]
# #         #             ^>
# #         # substitua globalmente por nada qualquer um destes nomes mais o que vier depois deles
# #         s/(ref|gb|emb|dbj|pir|prf|sp|pdb|pat|bbs|gnl|lcl).+//g;
# #         #substitua globalmente ">gi" e "|" por nada, sobrando assim apenas o GI#
# #         #>gi|15595213|
# #         #^^^^        ^
# #         s/(^>gi|\|)//g;
# # 
# #             print "ID number: " . ++$number_of_IDs . "\n";
# #             print "$_";
# #             print TEMP2 "$_";
# #         }
# #     }
# }





#           for my $feat_object ($seq->get_SeqFeatures)
#           {
#               if ($feat_object->has_tag("organism"))
#               {
#                   $organism = $feat_object->get_tag_values("organism");
#                   print "ORGANISM L11 \t$organism\n";
#               }
#               if ($feat_object->has_tag("source"))
#               {
#                   $organism = $feat_object->get_tag_values("source");
#                   print "ORGANISM L12 \t$organism\n";
#               }
#               elsif ($feat_object->has_tag("db_xref"))
#               {
#                   if ($feat_object->get_tag_values("db_xref") =~ /~taxon:(.*)/)
#                   {
#                       $organism = $1;
#                       print "ORGANISM L2 \t$organism\n";
#                   }
#                   else
#                   {
#                       print "ORGANISM L3 \t$organism\t";
#                       print $feat_object->get_tag_values("db_xref");
#                       print "\n";
#                       if ( ! $organism )
#                       {
#                           $organism = "unknown";
#                           print "ORGANISM L4 \t$organism\n";
#                       }
#                   }
#               }
#               else
#               {
#                   if ( ! $organism )
#                   {
#                       $organism = "unknown";
#                       print "ORGANISM L5 \t$organism\n";
#                   }
#               }
#           }