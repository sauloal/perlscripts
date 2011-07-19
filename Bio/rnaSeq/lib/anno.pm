package anno;

require Exporter;

@ISA       = qw{Exporter};
@EXPORT_OK = qw{new getAnno};

use strict;
use warnings;

sub new
{
    my $class = shift;
    my $self = bless {}, $class;
    
    my %vars  = @_;

    my %defaults = (
        verbose => 0,
        );
    
    foreach my $key ( sort keys %defaults )
    {
        if ( ! exists $vars{$key} ) { $self->{$key} =  $defaults{$key}; } else { $self->{$key} =  $vars{$key}; };
        #print $key , " -> ", $self->{$key}, "\n";
    }

    my $table              = $vars{inTable};
    $self->{inTable}         = $table;
    
    my $primaryColumn      = $vars{primaryColumn};
    $self->{primaryColumn} = $primaryColumn;
    
    my $verbose            = $self->{verbose};
    
    die if ! defined $table;
    die if ! defined $primaryColumn;
    
    die if ! $table->hasColumn($primaryColumn);
    
    my $mapping = $table->getColumnByNameReverse($primaryColumn);
    $self->{mapping} = $mapping;
    
    #my $anno1 = &getAnno($self, 'NODE_10019_length_175_cov_52.880001');
    #die if ! defined $anno1;
    #
    #my $anno2 = &getAnno($self, 'NODE_10177_length_175_cov_53.885715');
    #die if ! defined $anno2;
    
    return $self;
}

sub getAnno
{
    my $self    = shift;
    my $req     = $_[0];
    my $verbose   = $self->{verbose};
    print "GETTING ANNO $req\n" if $verbose;
    
    my $mapping = $self->{mapping};
    my $table   = $self->{inTable};
    
    return undef if ! exists ${$mapping}{$req};
    
    my $lineNum = $mapping->{$req};
    print "\tLINE NUMS ", (scalar @$lineNum), "\n" if $verbose;
    
    my @outArray;
    foreach my $number ( @$lineNum )
    {
        my $h = $table->getLineHash($number);
        if ( ! defined $h ) { die "LINE $number DOESNT EXISTS" };
        
        if ( $verbose )
        {
            my $val;
            foreach my $key ( sort keys %$h )
            {
                $val .= "      '$key' => '" . $h->{$key} . "'\n";
            }
            print "$val\n";
        }
        push(@outArray, $h);
    }
    print "\tARRAY NUMS ", (scalar @outArray), "\n" if $verbose;
    
    return \@outArray;
}



1;
