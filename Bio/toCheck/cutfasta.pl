#!/usr/bin/perl 

my $fasta = $ARGV[0];
my $chrom = $ARGV[1];
my $start = $ARGV[2];
my $end   = $ARGV[3];
my $name  = $ARGV[4];

my @gene = @{&readFasta($fasta, $chrom)};
&returner(\@gene, $start, $end, $name);

# R265_c_neoformans.fasta
# gpd1 824481 823935 supercontig_1.04_of_Cryptococcus_neoformans_Serotype_B
# tef1 288429 287730 supercontig_1.13_of_Cryptococcus_neoformans_Serotype_B
# 
# WM276GBFF10_06.fasta
# gpd1 29 576   CP000291_CGB_F2310W_Glyceraldehyde_3_phosphate_dehydrogenase_476378_478056
# tef1 673 1371 CP000298_CGB_M1520C_Translation_elongation_factor_EF1_alpha__putative_323075_324730

# ./cut.pl R265_c_neoformans.fasta supercontig_1.04_of_Cryptococcus_neoformans_Serotype_B 823935 824481 gpd1 > gpd1.265.txt
# ./cut.pl R265_c_neoformans.fasta supercontig_1.13_of_Cryptococcus_neoformans_Serotype_B 287730 288429 tef1 > tef1.265.txt
# ./cut.pl WM276GBFF10_06.fasta CP000291_CGB_F2310W_Glyceraldehyde_3_phosphate_dehydrogenase_476378_478056 29 576 gpd1 > gpd1.276.txt
# ./cut.pl WM276GBFF10_06.fasta CP000298_CGB_M1520C_Translation_elongation_factor_EF1_alpha__putative_323075_324730 673 1371 tef1 > tef1.276.txt


sub returner
{
    my @gene  = @{$_[0]};
    my $start = $_[1];
    my $end   = $_[2];
    my $name  = $_[3];

    $start = $start - 500;
    $end   = $end   + 500;

    print ">$fasta\_$chrom\_$start\_$end\_$name\n";

    for (my $i = 0; $i < @gene; $i++)
    {
        if (($i <= $end) && ($i >= $start))
        {
            print "$gene[$i]";
        }
    }
}



sub readFasta
{
    my $inputFA  = $_[0];
    my $chrom    = $_[1];

    my @gene;
    my $chromName;
    my $desiredLine;

    undef @gene; $gene[0] = "";
    open FILE, "<$inputFA" or die "COULD NOT OPEN $inputFA: $!";

    my $current;
    my $chromo;
    my $chromoName;

    my $on   = 0;
    my $pos  = 0;
    my $line = 1;


    while (<FILE>)
    {
            chomp;
            if (( /^>/) && ($on))
            {
                $on   = 0;
                $pos  = 1;
            }
    
            if ($on)
            {
                foreach my $nuc (split("",$_))
                {
                    push(@gene,$nuc);
                }
            }
    
            if (/^>$chrom/)
            {
#               print ">$chrom\n";
                $on         = 1;
                $pos        = 1;
            }
    }
#   print "\n\n";
    undef $chromo;
    close FILE;

    return \@gene;
}