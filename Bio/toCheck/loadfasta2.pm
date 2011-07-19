#!/usr/bin/perl -w
use warnings;
use strict;
use Data::Dumper;
package loadFasta;

my $original = "/bio/database/sample.fasta";

sub loadFasta
{
    my $seq = "";
    my $ID  = "";
    my %fasta;

#   print  "\n\tLOADING FASTA........";
    open FASTA, $original or die "FASTA SEQUENCE $original NOT FOUND\n";
    
    while(my $line = <FASTA>) 
    {
        chomp $line;
        $line = uc($line);
        if (substr($line,0,1) eq '>')
        {
            if (defined $fasta{$ID})
            {
                my $sequence = $fasta{$ID} or die "SEQUENCE NOT CREATED $ID\n";
            }

            if ($line =~ /^\>(\S{1,})\s/)
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
                $fasta{$ID} .= $line;
            }
        }
    }
    
    close FASTA;
#   print  "FASTA LOADED\n\t.....................";

#   savedump(\%fasta, "fasta");
    return %fasta;
};

sub loadFastaTair
{
    my $seq = "";
    my $ID  = "";
    my %fasta;
#   print  "\n\tLOADING FASTA........";
    open FASTA, $original;
    
    while(my $line = <FASTA>) {
        chomp $line;
        $line = uc($line);
        if (substr($line,0,1) eq '>')
        {
            if (defined $fasta{$ID}{'seq'})
            {
                my $sequence = $fasta{$ID}{'seq'} or die "SEQUENCE NOT CREATED $ID\n";
            }

            if ($line =~ /^\>(\S{1,})\s/)
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
                $fasta{$ID}{'seq'} .= $line;
            }
        }
    }
    
    close FASTA;
#   print  "FASTA LOADED\n\t.....................";
    return %fasta;
#   savedump(\%fasta, "fasta");
};

sub getReverseComplement($) {
    my $seq   = shift;
    my $rcSeq = reverse($seq);
    $rcSeq    =~ tr/acgtACGT/tgcaTGCA/;
    return $rcSeq;
}

sub getComplement($) {
    my $seq   = shift;
    my $rcSeq = $seq;
    $rcSeq    =~ tr/acgtACGT/tgcaTGCA/;
    return $rcSeq;
}

sub getReverse($) {
    my $seq   = shift;
    my $rcSeq = reverse($seq);
#   $rcSeq    =~ tr/acgtACGT/tgcaTGCA/;
    return $rcSeq;
}

sub savedump
{
    my $ref  = $_[0];
    my $name = $_[1];
    my $d = Data::Dumper->new([$ref],["*$name"]);

    $d->Purity   (1);     # better eval
#   $d->Terse    (0);     # avoid name when possible
    $d->Indent   (3);     # identation
    $d->Useqq    (1);     # use quotes 
    $d->Deepcopy (1);     # enable deep copy, no references
    $d->Quotekeys(1);     # clear code
    $d->Sortkeys (1);     # sort keys
    $d->Varname  ($name); # name of variable
#   open (DUMP, ">".$prefix."_dump_".$name.".dump") or die "Cant save $name.dump file: $!\n";
    print $d->Dump;
#   close DUMP;
};

1;