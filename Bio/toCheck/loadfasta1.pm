package fasta;
use strict;
use warnings;


sub new {
    my $class = shift;
    my $self = bless {}, $class;

    print "INFILE ",$_[0],"\n";
    $self->{inFile} = $_[0];
    ($self->{cmap}, $self->{sta}) = &genChromos($_[0]);
    return $self;
}




sub readFasta
{
    my $self       = shift;
    my $inputFA    = $self->{inFile};
    my $chromosMap = $self->{cmap};
    my $chromName  = $_[0];
    my @gene;
    my $desiredLine;

    $chromName =~ s/_bb$//;

#   print "READING FASTA $chromNum\n";
    if ( $chromName =~ /[\w+]/)
    {
        if ( ! eval { $desiredLine = $chromosMap->{$chromName} } )
        {
            die "CHROMOSSOME \"$chromName\" NOT FOUND IN FASTA";
        }
    }

    die "NO POSITION FOUND FOR $chromName" if ( ! defined $desiredLine );

    #$gene[0] = "";
    open FILE, "<$inputFA" or die "COULD NOT OPEN $inputFA: $!";

    my $current;
    my $chromoName;

    my $on   = 0;
    my $pos  = 0;
    my $line = 1;

#       print "DESIRE $desiredLine $chromName\n";
    my $leng = 0;
    seek(FILE, $desiredLine-200, 0);
    while (<FILE>)
    {
#           if ($line >= $desiredLine)
#           {
            chomp;
            s/\015//;
            if (( /^>/) && ($on))
            {
                $on   = 0;
                $pos  = 1;
                #print "LAST LINE :: \"$_\"\n";
                last;
            }
            elsif ($on)
            {
                $leng += length $_;
                #print "LINE [$line] \"$_\" IS \"", length $_, "\" LONG ($leng) \n";
                push(@gene,split("",$_));
            }
            elsif (/^>$chromName/)
            {
                #print "FIRST LINE [$line]:: \"$_\"\n";
                $on         = 1;
                $pos        = 1;
            }
        $line++;
    }

    close FILE;

    print "\t\t\tGENE $chromName HAS ", scalar @gene, " bp\n";
    if ( ! @gene ) { die "NO GENE READ\n";};
    return \@gene;
#   return \%XMLpos;
}

sub genChromos
{
    my $inputFA = $_[0];
    my $on = 0;
    my $chromo;
    my $total;
    open FILE, "<$inputFA" or die "COULD NOT OPEN $inputFA: $!";
    my $pos  = 0;
    my $line = 1;
    my $current;
#   my $tell = 0;
    my %chromos;
    my %stat;
    my %chromosMap;

    while (<FILE>)
    {
        chomp;
        s/\015//;
        if ( /^>/)
        {
            $on   = 0;
            $pos  = 1;
        }

        if ($on)
        {
            $stat{$chromo}{size} += length $_;
        }

        if (/^>(.*)/)
        {
            $on     = 1;
            $pos    = 1;
            $chromo = $1;
            $chromosMap{$chromo} = tell(FILE);
            $stat{$chromo}{pos}  = tell(FILE);
            $stat{$chromo}{size} = 0;
#           $chromosMap{$chromo} = $line;
        }
        $line++;
    }
    undef $chromo;
    close FILE;

    &printChromStat(\%stat);

    return (\%chromosMap, \%stat);
}

sub printChromStat
{
    my $stat = $_[0];
    foreach my $chromName (sort keys %$stat)
    {
        printf "\tCHROM \"%s\"", $chromName;
        foreach my $key (sort keys %{$stat->{$chromName}})
        {
            my $value = $stat->{$chromName}{$key};
            printf " %4s => %9d", $key, $value;
        }
        print "\n";
    }
}



1;