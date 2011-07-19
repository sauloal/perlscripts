package rna;

require Exporter;

@ISA       = qw{Exporter};
@EXPORT_OK = qw{new};

use strict;
use warnings;
use rnaSeq;

sub new
{
    my $class = shift;
    my $self = bless {}, $class;

    my %vars   = @_;

    my @mCols = qw/FPKM_1 FPKM_2/;
    my %defaults = (
        mergeCols => \@mCols,
        leftCol   => 'left',
    	rightCol  => 'right',
        verbose   => '1',
        separator => ':'
        );
    
    foreach my $key ( sort keys %defaults )
    {
        if ( ! exists $vars{$key} )
        {
            $self->{$key} =  $defaults{$key};
            #print "default $key" , " -> ", $defaults{$key}, "\n";
        } else {
            $self->{$key} =  $vars{$key};
            #print "override $key" , " -> ", $self->{$key},   "\n";
        }
    }

    my $table         = $vars{inTable};
    my $primaryColumn = $vars{primaryColumn};
    my $mergeCols     = $vars{mergeCols};
    my $extraCols     = $vars{extraCols};
    my $leftCol       = $vars{leftCol};
    my $rightCol      = $vars{rightCol};
    
    die if ! defined $table;
    die if ! defined $primaryColumn;
    die if ! defined $mergeCols;
    die if ! defined $leftCol;
    die if ! defined $rightCol;

    $self->{inTable}       = $table;
    $self->{primaryColumn} = $primaryColumn;
    $self->{leftCol}       = $leftCol;
    $self->{rightCol}      = $rightCol;

    my $anno               = $vars{anno};
    $self->{anno}          = $anno;

    my $verbose            = $self->{verbose};
    #$separator             = $self->{separator};

    die if ! $table->hasColumn($primaryColumn);
    die if ! $table->hasColumn($leftCol);
    die if ! $table->hasColumn($rightCol);

    delete $self->{mergeCols} if ( defined $mergeCols );    
    foreach my $col ( split(",", $mergeCols) )
    {
        die if ! $table->hasColumn($col);
        push(@{$self->{mergeCols}}, $col);
    }
    
    if ( defined $extraCols )
    {
        delete $self->{extraCols};
        foreach my $col ( split(",", $extraCols) )
        {
            die if ! $table->hasColumn($col);
            push(@{$self->{extraCols}}, $col);
        }
    }
    
    my $mapping      = $table->getColumnByNameReverse($primaryColumn);
    $self->{mapping} = $mapping;
    
    #my $anno1 = $anno->getAnno('NODE_10019_length_175_cov_52.880001');
    #die if ! defined $anno1;
    #my $anno2 = $anno->getAnno('NODE_10177_length_175_cov_53.885715');
    #die if ! defined $anno2;
    
    &genMerging($self);

    return $self;
}

sub getData
{
    my $self = shift;
    return $self->{merged};
}

sub genMerging
{
    my $self      = shift;
    
    my $mapping   = $self->{mapping};
    my $table     = $self->{inTable};
    my $anno      = $self->{anno};
    my $leftCol   = $self->{leftCol};
    my $rightCol  = $self->{rightCol};
    my $mergeCols = $self->{mergeCols};
    my $extraCols = $self->{extraCols};
    my $separator = $self->{separator};
    my $verbose   = $self->{verbose};
    
    my %setup     = (
        left      => $leftCol,
        right     => $rightCol,
        mergeCols => $mergeCols,
        extraCols => $extraCols,
        separator => $separator,
    );
    
    print "\tMAPPING KEYS ",  (scalar keys %$mapping), "\n";
    my %outHash;
    my %rnaSeq;
    my $count = 0;
    
    foreach my $key (sort keys %$mapping)
    {
        my $vals = $mapping->{$key};
        my @valHashes;
        
        foreach my $valNum (@$vals)
        {
            push(@valHashes, $table->getLineHash($valNum));
        }
        
        printf "\t\t%05d '%-38s' [%02d]\n", $count++, $key,(scalar @$vals) if $verbose;
        my $rnaSeq = rnaSeq->new(
                                     key   => $key,
                                     vals  => \@valHashes,
                                     anno  => $anno->getAnno($key),
                                     setup => \%setup
                                     );
        $rnaSeq{$key} = $rnaSeq;
        $outHash{$key} = $rnaSeq->getData();
        #exit if $count == 5;
        #last if $count == 5;
    }
    
    $self->{merged} = \%outHash;
}


1;
