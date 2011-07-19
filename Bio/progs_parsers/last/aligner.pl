#!/usr/bin/perl -w
use strict;

use Bio::AlignIO;
my $inFasta = $ARGV[0];
my $inMAF   = $ARGV[1];

my $alnFas = Bio::AlignIO->new( -file   => $inFasta ,
                                -format => 'fasta');
#my $alnMaf = Bio::AlignIO->new( -file   => $inMAF ,
#                                -format => 'maf');

my $out = Bio::AlignIO->new(-file   => ">out.aln.pfam" ,
                             -format => 'pfam');

    while ( my $aln = $alnFas->next_aln() ) {
        $out->write_aln($aln);
    }
