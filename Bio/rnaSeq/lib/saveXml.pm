package saveXml;

require Exporter;

@ISA       = qw{Exporter};
@EXPORT_OK = qw{new printXml printRef};


use strict;
use warnings;

sub new {
    my $class = shift;
    my $self = bless {}, $class;

    my %vars  = @_;
    my $time  = localtime();
    my %defaults = (
        title     => 'xml',
        date      => $time,
        separator => ':',
        );
    
    foreach my $key ( sort keys %defaults )
    {
        if ( ! exists $vars{$key} ) { $self->{$key} =  $defaults{$key}; } else { $self->{$key} =  $vars{$key}; };
        #print $key , " -> ", $self->{$key}, "\n";
    }
    
    foreach my $key ( sort keys %vars )
    {
        if ( ! exists $defaults{$key} )
        {
            my $extra            = $vars{$key};
            $self->{extra}{$key} = $extra;
        }
    }

    return $self;
}


sub printXml
{
    my $self      = shift;
    die "NO INPUT" if @_ == 0;
    my $ref       = $_[0];
    my $tab       = defined $_[1] ? $_[1] : 1;
    my $title     = $self->{title};
    my $date      = $self->{date};
    my $separator = $self->{separator};
    my $extras    = $self->{extra};
    my $extraStr;
    
    if ( defined $extras )
    {
        foreach my $key ( sort keys %$extras )
        {
            my $val    = $extras->{$key};
            if ( defined $val )
            {
                $extraStr .= defined $extraStr ? " " : '';
                $extraStr .= " $key=\"$val\"";
            }
        }
    }

    my $str;
    if ( ! defined $_[1] )
    {
        $str .= "<?xml version='1.0' encoding='UTF-8'?>\n";
        $str .= "<$title generated_on=\"$date\"$extraStr>\n";
    }

    if ( defined $ref )
    {
        #print ref $ref, " [$ref]\n";
        if ( (ref $ref) eq "HASH" )
        {
            foreach my $key (sort keys %$ref)
            {
                my $valueH = $ref->{$key};
                my $vRef   = ((defined $valueH ) && (( ref $valueH eq 'HASH') || ( ref $valueH eq 'ARRAY')));
                my $space  = "  "x$tab;
                my $first  = $vRef ? "\n"    : " ";
                my $second = $vRef ? $space  : " ";
                
                next if ! defined $valueH;
                my $lKey  = $key;
                $lKey =~ s/ /\_/g;
                
                if ( $lKey =~ /(\S+)$separator(\S+)/)
                {
                    my $sKey = $1;
                    my $sId  = $2;
                    
                    $str .= "$space<$sKey id=\"$sId\">$first";
                    $str .= &printXml($self, $valueH, $tab+1);
                    $str .= "$second</$sKey>\n";
                } else {
                    $str .= "$space<$lKey>$first";
                    $str .= &printXml($self, $valueH, $tab+1);
                    $str .= "$second</$lKey>\n";
                }
            }
        }
        elsif ( (ref $ref) eq "ARRAY" )
        {
            for ( my $r = 0; $r < @$ref; $r++ )
            {
                my $valueA = ${$ref}[$r];
                my $vRef   = ((defined $valueA ) && (( ref $valueA eq 'HASH') || ( ref $valueA eq 'ARRAY')));
                my $space  = "  "x$tab;
                my $first  = $vRef ? "\n"    : " ";
                my $second = $vRef ? $space  : " ";
                next if ! defined $valueA;
                
                $str .= "$space<el id=\"$r\">$first";
                $str .= &printXml($self, $valueA, $tab+1);
                $str .= "$space</el>\n";
            }
        }
        elsif ( (ref $ref) eq "SCALAR" )
        {
            $str .= $$ref;
        }
        else
        {
            $str .= $ref;
        }
    } else {
        $str .= "'undef'";
    }

    if ( ! defined $_[1] )
    {
        $str .= "</$title>\n";
    }
    
    if ( ! defined $str ) { $str = '' };
    
    return $str;
}


sub printRef
{
    my $self = shift;
    die "NO INPUT" if @_ == 0;
    
    my $ref = $_[0];
    my $tab = defined $_[1] ? $_[1] : 0;

    if ( defined $ref )
    {
        #print ref $ref, " [$ref]\n";
        if ( (ref $ref) eq "HASH" )
        {
            foreach my $key (sort keys %$ref)
            {
                my $valueH = $ref->{$key};
                next if ! defined $valueH;
                print "  "x$tab, $key, "\n";
                &printRef($self, $valueH, $tab+1);
            }
        }
        elsif ( (ref $ref) eq "ARRAY" )
        {
            for ( my $r = 0; $r < @$ref; $r++ )
            {
                my $valueA = ${$ref}[$r];
                next if ! defined $valueA;
                print "  "x$tab, $r, "\n";
                &printRef($self, $valueA, $tab+1);
            }
        }
        else
        {
            print "  "x$tab, $ref, "\n";
        }
    } else {
        print "  "x$tab, "'undef'\n";
    }
}
1;
