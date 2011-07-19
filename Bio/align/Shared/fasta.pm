package fasta;
#saulo aflitos
#2010 09 01 2105
use strict;
use warnings;
my $verbose = 0;

#print "  GENERATING CHROMOSSOMES TABLE...\n";
#my $fasta  = fasta->new($inputFA);
#print "  GENERATING CHROMOSSOMES TABLE...done\n";
#my $gene = $fasta->readFasta($chrom);
#$genLeng = scalar @$gene;
#$stats = $fasta->getStat()
#$size = $stats->{$chrom}{size}



sub new {
    my $class = shift;
    my $self = bless {}, $class;

    print "INFILE ",$_[0],"\n" if $verbose;
    $self->{inFile} = $_[0];
    &genChromos($self, $_[0]);
    return $self;
}




sub readFasta
{
    my $self       = shift;
	my $inputFA    = $self->{inFile};
	my $chromosMap = $self->{cmap};
	my $chromName  = $_[0];
    my $start      = $_[1];
    my $end        = $_[2];
	my @gene;
	my $desiredLine;

	$chromName =~ s/\_bb$//;
    $chromName =~ s/\s/\_/g;
    $chromName =~ s/\_+/\_/g;

 	print "READING FASTA $chromName\n" if $verbose;
    if (( ! exists ${$chromosMap}{$chromName} ) || ( ! defined $chromosMap->{$chromName} ))
    {
        die "FASTA.PM::READFASTA::CHROMOSSOME \"$chromName\" NOT FOUND IN FASTA";
    } else {
        $desiredLine = $chromosMap->{$chromName};
    }

	die "NO POSITION FOUND FOR $chromName" if ( ! defined $desiredLine );

	#$gene[0] = "";
	open FILE, "<$inputFA" or die "COULD NOT OPEN $inputFA: $!";

	my $current;
	my $chromoName;

	my $on   = 0;
	my $pos  = 0;
	my $line = 1;

	print "DESIRE $desiredLine $chromName\n" if $verbose;
	my $leng = 0;
	seek(FILE, $desiredLine, 0);
	while (<FILE>)
	{
# 			if ($line >= $desiredLine)
# 			{
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
				#print "LINE [$line] \"$_\" IS \"", length $_, "\" LONG ($leng) \n";
                my $lineLen = length $_;
                if (( defined $start ) && ( defined $end ))
                {
                    #S 100 + 60 >= 110 = 160 >= 110 = 1
                    #S  10 + 60 >= 110 =  70 >= 110 = 0
                    #S 160 + 60 >= 110 = 210 >= 110 = 1
                    if ( ($leng + $lineLen) >= $start)
                    {
                        # IF END OF THE LINE IS AFTER START
                        #S 100 + 60 >= 110 = 160 >= 110 = 1
                        #S 160 + 60 >= 110 = 210 >= 110 = 1

                        #E 100 + 60 <= 180 = 160 <= 180 = 1
                        #E  10 + 60 <= 180 =  70 <= 180 = 0
                        #E 160 + 60 <= 180 = 210 <= 180 = 1
                        if ( ($leng + $lineLen) <= $end )
                        {
                            # AND END OF THE LINE IS BEFORE END
                            #E 100 + 60 <= 180 = 160 <= 180 = 1
                            #E 160 + 60 <= 180 = 210 <= 180 = 1
                            my $relStart = $start - $leng;
                            #  10        = 110    - 100 = 1
                            # -50        = 110    - 160 = 0
                            if ( $relStart >= 0 )
                            {
                                # AND START IS IN THE SAME LINE
                                #  10        = 110    - 100 = 1
                                my $str = substr($_, $relStart);
                                push(@gene,split("",$str));
                            } else {
                                # AND START IS IN PREVIOUS LINE
                                # whole line
                                push(@gene,split("",$_));
                            }
                        } else {
                            # AND END OF THE LINE IS IN THE LINE
                            #S 100 + 60 >= 110 = 160 >= 110 = 1
                            #S 160 + 60 >= 110 = 210 >= 110 = 1
                            #E  10 + 60 <= 180 =  70 <= 180 = 0
                            my $relStart = $start - $leng;
                            #Rs  10      = 110    - 100
                            #Rs -50      = 110    - 160
                            my $relEnd   = $end   - $leng;
                            #Re  170     = 180    - 10

                            if ( $relStart >= 0 )
                            {
                                # AND START IS IN THE SAME LINE
                                my $str = substr($_, $relStart, ($relEnd - $relStart));
                                push(@gene,split("",$str));
                            } else {
                                # AND START IS IN PREVIOUS LINE
                                my $str = substr($_, 0, $relEnd);
                                push(@gene,split("",$_));
                            } # end if else relstart >= 0
                        } # end if else leng+linelen < leng
                    } # end if > start
                    #S  10 + 60 >= 110 =  70 >= 110 = 0
                } else {
                    push(@gene,split("",$_));
                } # if ! defined $start and $end

                $leng += $lineLen;
			}
			elsif ((/^>(.+)/) && ( ! $on ))
			{
                my $name = $1;
               	$name =~ s/_bb$//;
                $name =~ s/\s/\_/g;
                $name =~ s/\_+/\_/g;
                if ( $name eq $chromName )
                {
                    #print "FIRST LINE [$line]:: \"$_\"\n";
                    $on         = 1;
                    $pos        = 1;
                }
			}
		$line++;
	}

	close FILE;

	print "\t\t\tGENE '$chromName' HAS ", scalar @gene, " bp\n" if $verbose;
	if ( ! @gene ) { die "FASTA.PM::READFASTA::NO GENE READ : '$chromName'\n";};
	return \@gene;
# 	return \%XMLpos;
}

sub genChromos
{
    my $self    = shift;
	my $inputFA = $_[0];
	my $on   = 0;
	my $line = 1;
	my $chromo;
	my $total;
	my $current;
# 	my $tell = 0;

	my %chromos;
	my %stat;
	my %chromosMap;

	open FILE, "<$inputFA" or die "COULD NOT OPEN $inputFA: $!";
    my $lastPos = 0;

	while (<FILE>)
	{
		chomp;
		s/\015//;
		if ( /^>/)
		{
			$on   = 0;
		}

		if ($on)
		{
			$stat{$chromo}{size} += length $_;
		}

		if (/^>(.*)/)
		{
			$on     = 1;
			$chromo = $1;
            $chromo =~ s/\s/_/g;
            $chromo =~ s/_+/_/g;
            #my $tell = tell(FILE);
            print "GC CHROM '$chromo' POS ", tell(FILE), " LAST POS $lastPos\n" if $verbose;
			$chromosMap{$chromo}   = $lastPos;
			$stat{$chromo}{'pos'}  = $lastPos;
			$stat{$chromo}{'size'} = 0;
# 			$chromosMap{$chromo} = $line;
		} else {
            $lastPos = tell(FILE);
        }

		$line++;
	}
	undef $chromo;
	close FILE;

    ($self->{cmap}, $self->{sta}) = (\%chromosMap, \%stat);
	&printChromStat($self) if $verbose;
}

sub printChromStat
{
    my $self = shift;
	my $stat = $self->{sta};

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

sub getFragment
{
    my $self  = shift;
    my $chrom = $_[0];
    my $start = $_[1];
    my $end   = $_[2];

    my $gen = &readFasta($self, $chrom);
	if ( scalar @$gen < $end )
	{
		warn "LENGTH OF FRAGMENT ( ", scalar @$gen, " ) IS SMALLER THAN END ( $end ) [CHROM $chrom START $start END $end]\n";
		return undef;
	}

    my @frag = @$gen[$start-1..$end-1];
    return \@frag;
}


sub getFragment2
{
    my $self  = shift;
    my $chrom = $_[0];
    my $start = $_[1];
    my $end   = $_[2];

    my $gen = &readFasta($self, $chrom, $start, $end);
    return undef if ( scalar @$gen < $end );

    my @frag = @$gen[$start-1..$end-1];
    return \@frag;
}

sub getStat{
	my $self       = shift;
	return $self->{sta};
}

1;
