package rnaSeq;
use strict;
use warnings;

my $separator = ":";

sub new {
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

    my $key        = $vars{key};
    $self->{key}   = $key;
    
    my $vals       = $vars{vals};
    $self->{vals}  = $vals;
    
    my $anno       = $vars{anno};
    $self->{anno}  = $anno;
    
    my $setup      = $vars{setup};
    $self->{setup} = $setup;
    
    my $verbose    = $self->{verbose};
    
    die if ! defined $key;
    die if ! defined $vals;
    #die if ! defined $anno;
    die if ! defined $setup;
    
    if ( exists ${$setup}{separator} ) { $separator = ${$setup}{separator}; };
    
    my $outHash = &analyze($self);
    $self->{outHash} = $outHash;
    
    return $self;
}

sub getData
{
    my $self = $_[0];
    return $self->{outHash};
}

sub analyze
{
    my $self      = shift;
    my $key       = $self->{key};
    my $vals      = $self->{vals};
    my $anno      = $self->{anno};
    my $setup     = $self->{setup};
    my $verbose   = $self->{verbose};
    
    my $leftCol   = $setup->{left};
    my $rightCol  = $setup->{right};
    my $mergeCols = $setup->{mergeCols};
    my $extraCols = $setup->{extraCols};
    my $separator = $setup->{separator};
    
    my %classes;
    my %poses;
    my %cols;
    my %outHash;
    my @data;
    my $valCount = 0;
    
    foreach my $valHash (@$vals)
    {
        if ( $verbose )
        {
            my $valStr;
            foreach my $key ( sort keys %$valHash )
            {
                $valStr .= "\t\t\t\t'$key' => '" . $valHash->{$key} . "'\n";
            }
            print "$valStr\n";
        }
        
        my $left  = $valHash->{$leftCol};
        my $right = $valHash->{$rightCol};
        $poses{"poses:$left$right"}++;
        $data[$valCount]{left}  = $left;
        $data[$valCount]{right} = $right;
        print "\t\t\tVAL $valCount LEFT $left RIGHT $right" if ( $verbose );
        
        foreach my $eCol ( @$extraCols )
        {
            #print " ECOL $eCol ";
            my $eData = $valHash->{$eCol};
            $data[$valCount]{$eCol} = $eData;
            $outHash{"chr:$key"}{data}{"left:$left"}{"right:$right"}[$valCount]{$eCol} = $eData;
        }
        
        foreach my $col1 ( @$mergeCols )
        {
            #print "\t\t\tCOL1 $col1\n";
            next if ! exists $valHash->{$col1};
            my $colData1 = $valHash->{$col1};
            $outHash{"chr:$key"}{data}{"left:$left"}{"right:$right"}[$valCount]{$col1} = $colData1;
            $data[$valCount]{$col1} = $colData1;
            $cols{$col1}++ if (( defined $colData1 ) && ( $colData1 ne '' ));
            print " " . uc($col1) . " $colData1" if ( $verbose );
            
            foreach my $col2 ( @$mergeCols )
            {
                #print "\t\t\t\tCOL2 $col2\n";
                next if $col1 eq $col2;
                next if ! exists $valHash->{$col2};
                my $colData2 = $valHash->{$col2};
                
                next if (( ! defined $colData1 ) || ( $colData1 eq '' ));
                next if (( ! defined $colData2 ) || ( $colData2 eq '' ));
                
                #print "\t\t\t\t\tCALC $colData1 / $colData2\n";
                $valHash->{"$col1\_per_$col2"}       = $colData1 / $colData2;
                $valHash->{"$col2\_per_$col1"}       = $colData2 / $colData1;
                $data[$valCount]{"$col1\_per_$col2"} = $colData1 / $colData2;;
                $data[$valCount]{"$col2\_per_$col1"} = $colData2 / $colData1;
            }
        }
        print "\n" if ( $verbose );
        $valCount++;
    }

    
    if ( scalar keys %poses > 1 ) { $classes{splice} = \%poses };
    if ( scalar keys %cols  > 1 ) { $classes{shared} = \%cols  };
    if (( ! exists $classes{splice} ) && ( ! exists $classes{shared} ))
    {
        my %uniq;
        $classes{unique} = \%uniq;
    }
    
    my $span = &getSpan(\@data);
    
    $outHash{"chr:$key"}{span}  = $span;
    $outHash{"chr:$key"}{class} = ( scalar keys %classes ) ? \%classes : undef;
    $outHash{"chr:$key"}{anno}  = $anno;
    
    if ( $verbose )
    #if ( 1 )
    {
        &printOutHash(\%outHash);   
    }
    
    return \%outHash;
}


sub getSpan
{
    my $array = $_[0];
    my %span;
    my %nTmp;
    
    foreach my $d ( @$array )
    {
        my $lf = $d->{left};
        my $rt = $d->{right};
        #print "\t\t\tCURR LEFT $lf RIGHT $rt";
    
        push(@{$nTmp{"pos:$lf"}}, $d);
        push(@{$nTmp{"pos:$rt"}}, $d);
        
        foreach my $pos ( sort sortByDots keys %nTmp )
        {
            my $posV = &valDots($pos);
            #print " P $pos ";
            if (( $posV >= $lf ) && ( $posV <= $rt ))
            {
                #print " add ";
                
                if ( exists $nTmp{$pos} )
                {
                    my $has = 0;
                    
                    foreach my $dd ( @{$nTmp{$pos}} )
                    {
                        if ( "$d" eq "$dd" ) { $has++ };
                    }
                    
                    if ( ! $has )
                    {
                        #print " (1) ";
                        push(@{$nTmp{$pos}}, $d);
                    }
                } else {
                    push(@{$nTmp{$pos}}, $d);
                }
            }
        }
        #print "\n";
    }

    my $spanStr;
    foreach my $pos ( sort sortByDots keys %nTmp )
    {
        #print "\t\t\t\tPOS $pos\n";
        my $posV  = &valDots($pos);
        my $ds    = $nTmp{$pos};
        $spanStr .= defined $spanStr ? "|" : '';
        $spanStr .= $posV . "(";
        my $dkv;
        for (my $d = 0; $d < @$ds; $d++ )
        {
            $dkv .= defined $dkv ? ";" : '';
            $dkv .= "[";
            my $data = $ds->[$d];
            my $kv;
            foreach my $key ( sort keys %$data )
            {
                my $v = $data->{$key};
                #print "\t\t\t\t\t$d . $key = $v\n";
                $kv .= defined $kv ? "," : '';
                $kv .= "$key:$v"
            }
            $dkv .= "$kv]";
        }
        $spanStr .= "$dkv)";
    }
    #print $spanStr, "\n\n";
    
    $span{hash}   = \%nTmp;
    $span{string} = \$spanStr;
    
    return \%span;
}




sub sortByDots
{
    my $va = substr($a, index($a, $separator)+1);
    my $vb = substr($b, index($b, $separator)+1);
    
    if (( $va =~ /^\d+[\.\d+]*$/ ) && ( $va =~ /^\d+[\.\d+]*$/ ))
    {
        $va <=> $vb;
    } else {
        $va cmp $vb;
    }
}

sub valDots
{
    my $str  = $_[0];
    my $strV = substr($str, index($str, $separator)+1);
    return $strV;
}




sub printOutHash
{
    my $outHash = $_[0];
    
    foreach my $key ( sort keys %$outHash )
    {
        print "\t$key\n";
        my $sources = $outHash->{$key};
        
        foreach my $src ( sort keys %$sources )
        {
            if ( $src eq 'data' )
            {
                print "\t\t$src\n";
                my $lefts = $sources->{$src};
                
                foreach my $left ( sort sortByDots keys %$lefts )
                {
                    my $rights = $lefts->{$left};
                    
                    foreach my $right ( sort sortByDots keys %$rights )
                    {
                        print "\t\t\t$left : $right\n";
                        my $series = $rights->{$right};
                        
                        for ( my $c = 0; $c < @$series; $c++ )
                        {
                            my $cols = $series->[$c];
                            print "\t\t\t\t$c\n";
                            foreach my $col ( sort keys %$cols )
                            {
                                my $val = $cols->{$col};
                                print "\t\t\t\t\t$col => '$val'\n";
                            }
                        }
                    }
                }
            }
            elsif ( $src eq 'anno' )
            {
                print "\t\t$src\n";
            }
            elsif ( $src eq 'class' )
            {
                print "\t\t$src\n";
                my $classes = $sources->{$src};
                
                foreach my $cls ( sort keys %$classes )
                {
                    print "\t\t\t$cls\n";
                    my $names = $classes->{$cls};
                    
                    foreach my $name ( sort keys %$names )
                    {
                        my $val = $names->{$name};
                        print "\t\t\t\t$name = $val\n";
                    }
                }
            }
            elsif ( $src eq 'span' )
            {
                print "\t\t$src\n";
                my $vars = $sources->{$src};
                for my $key ( sort keys %$vars )
                {
                    my $data = $vars->{$key};
                    print "\t\t\t$key\n";
                    
                    if ( $key eq 'hash' )
                    {
                        foreach my $pos ( sort { $a <=> $b } keys %$data )
                        {
                            my $ds = $data->{$pos};
                            print "\t\t\t\t$pos\n";

                            for (my $d = 0; $d < @$ds; $d++ )
                            {
                                my $cols = $ds->[$d];
                                foreach my $key ( sort keys %$cols )
                                {
                                    my $v = $cols->{$key};
                                    print "\t\t\t\t\t$d . $key = $v\n";
                                }
                            }
                        }
                    }
                    elsif ( $key eq 'string' )
                    {
                        print "\t\t\t\t$$data\n";
                    }
                }
            }
        }
    }
}
1;

#sub genMerging
#{
#    my $self      = shift;
#    my $mapping   = $self->{mapping};
#    my $table     = $self->{inTable};
#    my $anno      = $self->{anno};
#    my $leftCol   = $self->{leftCol};
#    my $rightCol  = $self->{rightCol};
#    my $mergeCols = $self->{mergeCols};
#    my $verbose   = $self->{verbose};
#    
#    print "\tMAPPING KEYS ",  (scalar keys %$mapping), "\n";
#    my %outHash;
#    my $count = 0;
#    foreach my $key (sort keys %$mapping)
#    {
#        my $vals = $mapping->{$key};
#        printf "\t\t%05d '%-38s' [%02d]\n", $count++, $key,(scalar @$vals) if $verbose;
#
#        my %classes;
#        my %poses;
#        my %cols;
#        my @data;
#        my $valCount = 0;
#        foreach my $valNum (@$vals)
#        {
#            print "\t\t\t$valNum\n" if $verbose;
#            my $valHash = $table->getLineHash($valNum);
#            if ( ! defined $valHash ) { die "LINE $valNum DOESNT EXISTS" };
#
#            #my $valStr;
#            #foreach my $key ( sort keys %$valHash )
#            #{
#            #    $valStr .= "\t\t\t\t'$key' => '" . $valHash->{$key} . "'\n";
#            #}
#            #print "$valStr\n";
#            
#            my $left  = $valHash->{$leftCol};
#            my $right = $valHash->{$rightCol};
#            $poses{"poses:$left$right"}++;
#            $data[$valCount]{left}  = $left;
#            $data[$valCount]{right} = $right;
#            
#            foreach my $col ( @$mergeCols )
#            {
#                my $colData = $valHash->{$col};
#                $outHash{"chr:$key"}{data}{"left:$left"}{"right:$right"}{$col} = $colData;
#                if ( $colData ne '' )
#                {
#                    $cols{$col}++;
#                    $data[$valCount]{$col} = $colData;
#                }
#            }
#            $valCount++;
#        }
#
#        
#        if ( scalar keys %poses > 1 ) { $classes{splice} = \%poses };
#        if ( scalar keys %cols  > 1 ) { $classes{shared} = \%cols  };
#        my $span = &getSpan(\@data);
#        
#        
#        
#        $outHash{"chr:$key"}{span}  = $span;
#        $outHash{"chr:$key"}{class} = \%classes if ( scalar keys %classes );
#        $outHash{"chr:$key"}{anno}  = $anno->getAnno($key);
#    }
#    exit;
#    
#    if ( $verbose )
#    {
#        foreach my $key ( sort keys %outHash )
#        {
#            print "\t$key\n";
#            my $sources = $outHash{$key};
#            
#            foreach my $src ( sort keys %$sources )
#            {
#                if ( $src eq 'data' )
#                {
#                    print "\t\t$src\n";
#                    my $lefts = $sources->{$src};
#                    
#                    foreach my $left ( sort sortByDots keys %$lefts )
#                    {
#                        my $rights = $lefts->{$left};
#                        
#                        foreach my $right ( sort sortByDots keys %$rights )
#                        {
#                            print "\t\t\t$left : $right\n";
#                            my $cols = $rights->{$right};
#                            
#                            foreach my $col ( sort keys %$cols )
#                            {
#                                my $val = $cols->{$col};
#                                print "\t\t\t\t$col => '$val'\n";
#                            }
#                        }
#                    }
#                }
#                elsif ( $src eq 'anno' )
#                {
#                    print "\t\t$src\n";
#                }
#                elsif ( $src eq 'class' )
#                {
#                    print "\t\t$src\n";
#                    my $classes = $sources->{$src};
#                    
#                    foreach my $cls ( sort keys %$classes )
#                    {
#                        print "\t\t\t$cls\n";
#                        my $names = $classes->{$cls};
#                        
#                        foreach my $name ( sort keys %$names )
#                        {
#                            my $val = $names->{$name};
#                            print "\t\t\t\t$name = $val\n";
#                        }
#                    }
#                }
#                elsif ( $src eq 'span' )
#                {
#                    print "\t\t$src\n";
#                }
#            }
#        }
#    }
#    
#    $self->{merged} = \%outHash;
#}


#sub getSpanOld
#{
#    my $array = $_[0];
#    my %span;
#    my %tmp;
#    
#    foreach my $d ( @$array )
#    {
#        my $lf = $d->{left};
#        my $rt = $d->{right};
#        my @keys;
#        $tmp{$lf}{end} = $rt;
#    
#        foreach my $key ( sort keys %$d )
#        {
#            next if $key eq 'left';
#            next if $key eq 'right';
#            
#            push(@keys, $key);            
#            $tmp{$lf}{$key}  = $d->{$key};
#        }
#        
#        foreach my $key1 ( @keys )
#        {
#            foreach my $key2 ( @keys )
#            {
#                next if ( $key1 eq $key2 );
#                $tmp{$lf}{"$key1/$key2"} = $d->{$key1} / $d->{$key2};
#            }
#        }
#    }
#    
#    my @poses = sort {$a <=> $b} keys %tmp;
#    
#    #todo: calc and next if only 1
#    #      full calc otherwise
#
#    
#    for (my $s = 0; $s < @poses; $s++)
#    {
#        my $cStart = $poses[$s];
#        my $cData  = $tmp{$cStart};
#        my $cEnd   = $cData->{end};
#        my $nStart = defined $poses[$s+1] ? $poses[$s+1] : undef;
#        my $pEnd   = defined $poses[$s-1] ? $poses[$s-1] : undef;
#        
#        print "\t\t\tCURR START $cStart CURR END $cEnd NEXT START ", (defined $nStart ? $nStart : ''), " PREVIOUS END ", (defined $pEnd ? $pEnd : ''),"\n";
#
#        if ( defined $nStart )
#        {
#            if ( $cEnd > $nStart )
#            {
#                my $range1 = $cStart . "-" . ($nStart-1);
#                foreach my $name ( sort keys %$cData )
#                {
#                    next if ( $name eq 'end' );
#                    print "\t\t\t\tRANGE 1 [$range1]: $name => ", $cData->{$name}, "\n";
#                    $span{$range1}{$name} = $cData->{$name};
#                }
#                
#                my $range2 = $nStart . "-" . $cEnd;
#                foreach my $name ( sort keys %$cData )
#                {
#                    next if ( $name eq 'end' );
#                    print "\t\t\t\tRANGE 2 [$range2]: $name => ", $cData->{$name}, "\n";
#                    $span{$range2}{$name} = $cData->{$name};
#                }
#            } else {
#                my $range3 = $cStart . "-" . $cEnd;
#                foreach my $name ( sort keys %$cData )
#                {
#                    next if ( $name eq 'end' );
#                    print "\t\t\t\tRANGE 3 [$range3]: $name => ", $cData->{$name}, "\n";
#                    $span{$range3}{$name} = $cData->{$name};
#                }
#            }
#        } else {
#            my $range4 = "$cStart-$cEnd";
#
#            foreach my $name ( sort keys %$cData )
#            {
#                next if ( $name eq 'end' );
#                print "\t\t\t\tRANGE 4 [$range4]: $name => ", $cData->{$name}, "\n";
#                $span{$range4}{$name} = $cData->{$name};
#            }
#        }
#        
#
#        if ( defined $pEnd )
#        {
#            if ( $cEnd > $nStart )
#            {
#                my $range1 = $cStart . "-" . ($nStart-1);
#                foreach my $name ( sort keys %$cData )
#                {
#                    next if ( $name eq 'end' );
#                    print "\t\t\t\tRANGE 1 [$range1]: $name => ", $cData->{$name}, "\n";
#                    $span{$range1}{$name} = $cData->{$name};
#                }
#                
#                my $range2 = $nStart . "-" . $cEnd;
#                foreach my $name ( sort keys %$cData )
#                {
#                    next if ( $name eq 'end' );
#                    print "\t\t\t\tRANGE 2 [$range2]: $name => ", $cData->{$name}, "\n";
#                    $span{$range2}{$name} = $cData->{$name};
#                }
#            } else {
#                my $range3 = $cStart . "-" . $cEnd;
#                foreach my $name ( sort keys %$cData )
#                {
#                    next if ( $name eq 'end' );
#                    print "\t\t\t\tRANGE 3 [$range3]: $name => ", $cData->{$name}, "\n";
#                    $span{$range3}{$name} = $cData->{$name};
#                }
#            }
#        } else {
#            my $range4 = "$cStart-$cEnd";
#
#            foreach my $name ( sort keys %$cData )
#            {
#                next if ( $name eq 'end' );
#                print "\t\t\t\tRANGE 4 [$range4]: $name => ", $cData->{$name}, "\n";
#                $span{$range4}{$name} = $cData->{$name};
#            }
#        }
#
#        
#        print "\n";
#    }
#    return \%span;
#}

