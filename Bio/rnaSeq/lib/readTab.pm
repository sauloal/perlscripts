package readTab;

require Exporter;

@ISA       = qw{Exporter};
@EXPORT_OK = qw{new getLine getLineHash getLine getLines getColumns getColumnsNames getColumnsNamesArray getCells getColumByName getColumnByNameReverse hasColumn};


use strict;
use warnings;
use lib '.';
use loadconf;

sub new
{
    my $class = shift;
    my $self = bless {}, $class;
    
    my %vars  = @_;

    my %defaults = (
        firstLine   => 1,   # int    : number of bit necessary to each field
        );
    
    foreach my $key ( sort keys %defaults )
    {
        if ( ! exists $vars{$key} ) { $self->{$key} =  $defaults{$key}; } else { $self->{$key} =  $vars{$key}; };
        #print $key , " -> ", $self->{$key}, "\n";
    }

    die "NO INPUT FILE PROVIDED" if ! exists $vars{inTabFile};
    my $file           = $vars{inTabFile};
    my $stLine         = $vars{firstLine};
    $self->{inFile}    = $file;
    $self->{firstLine} = $stLine;
    
    &parseTab($self);
    
    return $self;
}


sub getLineHash
{
    my $self    = shift;
    my $req     = $_[0];
    
    my $line    = &getLine($self, $req);
    return undef if ! defined $line;
    
    my $header  = &getColumnsNamesArray($self);
    my %hash;
    for ( my $c = 0; $c < @$header; $c++ )
    {
        $hash{$header->[$c]} = $line->[$c];
    }
    
    return \%hash;
}

sub getLine
{
    my $self = shift;
    my $req  = $_[0];
    my $lines = $self->{lines};
    if ( $req < $lines )
    {
        my $line = $self->{data}[$req];
        return $line;
    } else {
        return undef;
    }
}

sub getLines
{
    my $self = shift;
    return $self->{lines};
}

sub getColumns
{
    my $self = shift;
    return $self->{columns};
}

sub getColumnsNames
{
    my $self = shift;
    return $self->{colNames};
}

sub getColumnsNamesArray
{
    my $self  = shift;
    my $hash  = $self->{colNames};
    my @array;
    map { $array[$hash->{$_}] = $_ } keys %$hash;
    return \@array;
}

sub getCells
{
    my $self = shift;
    return $self->{cells};
}

sub getColumByName
{
    my $self  = shift;
    my $req   = $_[0];
    
    return undef if ( ! exists ${$self->{colNames}}{$req} );
    
    my $colNum = $self->{colNames}{$req};
    my $lines  = $self->{lines};
    my $data   = $self->{data};
    my @out;
    
    for ( my $l = 0; $l < $lines; $l++ )
    {
        push(@out, $data->[$l][$colNum])
    }
    
    return \@out;
}

sub getColumnByNameReverse
{
    my $self  = shift;
    my $req   = $_[0];
    my $array = &getColumByName($self, $req);
    my %hash;
    
    for ( my $a = 0; $a < @$array; $a++ )
    {
        push(@{$hash{$array->[$a]}}, $a);
    }
    
    return \%hash;
}


sub hasColumn
{
    my $self  = shift;
    my $col   = $_[0];
    my $names = $self->{colNames};
    return exists $names->{$col};
}

sub parseTab
{
    my $self          = shift;
    my $file          = $self->{inFile};

    print "READING TAB FILE $file\n";
    open FILE, "<$file" or die "COULD NOT OPEN INPUT FILE $file: $!";

    my $lineCount = 0;
    my @colNumbers;
    my %colNames;
    my @data;

    my $stLine      = $self->{firstLine};

    while (my $line = <FILE>)
    {
        #chomp $line;
        $line =~ s/\n//g;
        $line =~ s/\r//g;
        $line =~ s/\x0D//g;
        
        $lineCount++;
        if    ( $lineCount <  $stLine )
        {
                print "\tSKIPPING :: $line\n"; next;
        }
        elsif ( $lineCount == $stLine )
        {
            print "\tACQUIRING HEADERS :: $line\n";
            $line =~ s/\#//;
            $line =~ s/\"//g;

            @colNumbers = split(/\t/, $line);
            #my $cNames;
            for (my $c = 0; $c < @colNumbers; $c++)
            {
                my $colName = $colNumbers[$c];
                #$cNames .= " | '". $colName. "'";
                $colNames{$colName} = $c;
            }
            #print "$cNames\n";

            print "\tACQUIRING DATA\n";
        }
        elsif ( scalar @colNumbers )
        {
            $line =~ s/\"//g;

            my @cols = split(/\t/, $line, (scalar @colNumbers));
            
            for ( my $c = 0; $c < @cols; $c++ )
            {
                my $val = $cols[$c];
                #print "\t$c - $val\n";
                if ( ! defined $val ) { $cols[$c] = '' };
            }

            if ( @cols != @colNumbers )
            {
                print "DIFFERENT NUMBER OF COLUMNS : " . (scalar @cols) . " != " . (scalar @colNumbers) . " : \n\t\t$line\n";
                die;
            }
            
            push(@data, \@cols);
        } else {
            &usage("ERROR READING TAB FILE");
        }
    }

    my $columns = (scalar keys %colNames);
    my $lines   = (scalar @data);
    my $cells   = $columns * $lines;
    
    $self->{colNames}   = \%colNames;
    $self->{colNumbers} = \@colNumbers;
    $self->{data}       = \@data;
    $self->{lines}      = $lines;
    $self->{columns}    = $columns;
    $self->{cells}      = $cells;

    close FILE;
    print "\t\tTAB FILE $file READ :: $columns COLUMNS WITH $lines LINES [$cells CELLS]\n";

    return $self;
}



1;


#sub getReverseKey
#{
#    my $self          = shift;
#    my $table         = $self->{table};
#    my $primaryColumn = $_[0];
#    
#    my $values        = &getColumnByNameReverse($self, $primaryColumn);
#    
#    #print "KEYS ", (scalar keys %$values), "\n";
#    #my $tot;
#    #map { $tot += scalar @{$values->{$_}} } (keys %$values);
#    #print "\tTOT $tot\n";
#    
#    return $values;
#}


#sub new
#    firstLine   => 1,   # int    : number of bit necessary to each field
#    my $file        = $vars{inTabFile};
#    if ( (! exists $vars{setupXmlFile} ) && ( ! exists $vars{setupHash} ))
#        
#    my $checkCols = $cnf->get('tab.checkCols');
#    my $stLine    = $cnf->get('tab.firstLine');
#    return $self;
#
#sub getLine
#    my $self = shift;
#    my $req  = $_[0];
#        my $line = $self->{data}[$req];
#        return $line;
#    } else {
#        return undef;
#
#sub getLines
#   return $self->{lines};
#
#sub getColumns
#    return $self->{columns};
#
#sub getColumnsNames
#    return $self->{colNames};
#
#sub getCells
#    return $self->{cells};
#
#sub getColumByName
#    my $req   = $_[0];
#    
#    my $colNum = $self->{colNames}{$req};
#    my $lines  = $self->{lines};
#    my $data   = $self->{data};
#    my @out;
#   
#    return \@out;
#
#sub hasColumn
#    my $col   = $_[0];
#    my $names = $self->{colNames};
#    return exists $names->{$col};
