#!/usr/bin/perl -w 
use strict;

my $inPsl      = $ARGV[0];
my $inFa       = $ARGV[1];
my $minSim     = $ARGV[2] || 70;
my $noValidate = $ARGV[3] || 0;

die "USAGE: $0 <PSL FILE> <QUERY FASTA FILE> <MIN SIM>" if ( @ARGV < 3);

die "IN PSL NOT DEFINED"  unless ( defined $inPsl );
die "IN PSL NOT EXISTENT" unless ( -f $inPsl );
die "NOT A PSL FILE"      unless ( $inPsl =~ /(.*).psl/);
my $outPsl = $1;

die "IN FASTA NOT DEFINED"  unless ( defined $inFa );
die "IN FASTA NOT EXISTENT" unless ( -f $inFa );
die "NOT A FASTA FILE"      unless ( $inFa =~ /(.*).[fa|fasta]/);
my $outFa = $1;

die "MINIMUM SIMILARITY NOT A NUMBER OR OUT OF RANGE" if (($minSim < 0) || ($minSim > 100));

my $soulsFa                                   = &checkFasta($inFa);
my ($goodSoulPsl, $badSoulPsl, $maybeSoulPsl) = &checkPsl($inPsl);
#my ($finalAngel, $finalDaemon, $finalHuman)   = &checkSouls($goodSoulPsl, $badSoulPsl, $maybeSoulPsl, $soulsFa);

my $neg = &mergeHashRef($badSoulPsl, $maybeSoulPsl);
&exportSoul($goodSoulPsl,  "good");
&exportSoul($neg,          "neg");
&exportSoul($badSoulPsl,   "bad");
&exportSoul($maybeSoulPsl, "may");

sub mergeHashRef
{
	my $input1 = $_[0];
	my $input2 = $_[1];
	
	my %output;
	foreach my $key (keys %{$input1})
	{
		my $value = $input1->{$key};
		$output{$key} = $value;
	}

	foreach my $key (keys %{$input2})
	{
		my $value = $input2->{$key};
		$output{$key} = $value;
	}
	
	return \%output;
}


sub exportSoul
{
	my $soul   = $_[0];
	my $suffix = $_[1];

	my $outFile = $outPsl . "_threshold_$suffix.lst";

	open OUTFILE, ">$outFile" or die "COULD NOT OPEN OUTFILE: $outFile : $!";
	foreach my $spirit (sort keys %{$soul})
	{
		if ( $spirit =~ /(.*)\|/)
		{
			my $id = $1;
			print OUTFILE $id, "\n";
		}
		else
		{
			die "$spirit IS NOT WELL FORMATED\n"
		}
	}	
	close OUTFILE;
}


sub checkFasta
{
	my $inFile = $_[0];
	print "CHECKING FASTA FILE: $inFile\n";
	open INFILE,  "<$inFile"  or die "COULD NOT OPEN INFILE:  $inFile : $!";
	my $souls;
	while (my $line = <INFILE>)
	{
		if (substr($line,0,1) eq ">")
		{
			chomp $line;
			#my $index = rindex $line, "|";
			my $code = substr($line, 1);
			#print "ADDING $line [$index] $code\n";
			#print "ADDING $code\n" if ($code =~ /240\|240/);
			$souls->{$code}++;
			#print $code;
		}
	}	
	close INFILE;
	print "FASTA CHECKED: ",(int(keys %{$souls})), " SEQUENCES RECOVERED\n";
	return $souls;
}

sub checkPsl
{
	print "CHECKING PSL FILE\n";
	my $inFile = $_[0];
	open INFILE,  "<$inFile"  or die "COULD NOT OPEN INFILE:  $inFile : $!";

	my $countLine = 0;
	my $countYes  = 0;
	my $countNo   = 0;
	my %ltMinSim;  # has a low identity - ok sequence
	my %geMinSim;   # has a high identity - bad sequence
	my %listAll; # appears in the psl file
	while (my $line = <INFILE>)
	{
		$countLine++;
		chomp $line;
		my @fields = split("\t", $line);
	#	print join("  ", @fields) . "\n";
		# 40  0  0  0  0  0  0  0  +  60|60_60  63  23  63  51276|51276_51276  90  0  40  1  40,  23,  0,
		# 0   1  2  3  4  5  6  7  8  9         10  11  12  13                 14  15 16  17 18   19   20
	
		my $matches    = $fields[0];
		my $querySize  = $fields[10];
		my $queryName  = $fields[9];
		my $targetName = $fields[13];

		my $perctIdent = int(($matches / $querySize) * 100);

		if ( ! $noValidate )
		{
			if (exists $soulsFa->{$queryName})
			{ $listAll{$queryName}++ }
			else
			{ die "COULD NOT FIND QUERY $queryName ON FASTA" } ;
			
			if (exists $soulsFa->{$targetName})
			{	$listAll{$targetName}++ }
			else
			{	die "COULD NOT FIND TARGET $targetName ON FASTA";	}
		}
		
		
		#    matchs     / qSize		
		if ( $perctIdent < $minSim )
		{
			$countYes++;
			$ltMinSim{$queryName}++;
			$ltMinSim{$targetName}++ if ( ! $noValidate );
		}
		elsif ( $perctIdent >= $minSim )
		{
			$countNo++;
			$geMinSim{$queryName}++;
			$geMinSim{$targetName}++ if ( ! $noValidate );
		}
		
		# $fields[0]  = Number of bases that match that aren't repeats;
		# $fields[1]  = Number of bases that don't match;
		# $fields[2]  = Number of bases that match but are part of repeats;
		# $fields[3]  = Number of 'N' bases;
		# $fields[4]  = Number of inserts in query;
		# $fields[5]  = Number of bases inserted in query;
		# $fields[6]  = Number of inserts in target;
		# $fields[7]  = Number of bases inserted in target;
		# $fields[8]  = + or - for query strand, optionally followed by + or – for target strand;
		# $fields[9] = Query sequence name;
		# $fields[10] = Query sequence size;
		# $fields[11] = Alignment start position in query;
		# $fields[12] = Alignment end position in query;
		# $fields[13] = Target sequence name;
		# $fields[14] = Target sequence size;
		# $fields[15] = Alignment start position in target;
		# $fields[16] = Alignment end position in target;
		# $fields[17] = Number of blocks in alignment. A block contains no gaps.;
		# $fields[18] = Size of each block in a comma separated list;
		# $fields[19] = Start of each block in query in a comma separated list;
		# $fields[20] = Start of each block in target in a comma separated list;
	}
	close INFILE;

	print "YES: $countYes NO: $countNo\n";

	my $yes       = 0;
	my $no        = 0;
	my $maybe     = 0;
	my $goodSoul;
	my $badSoul;
	my $maybeSoul;

	if ( ! $noValidate )
	{
		foreach my $key (keys %{$soulsFa})
		{
			if (exists $geMinSim{$key})
			{
				delete $ltMinSim{$key} if ( exists $ltMinSim{$key} );
				$badSoul->{$key}++;
				$no++;
			}
			elsif (exists $ltMinSim{$key})
			{
				$maybeSoul->{$key}++;
				$maybe++;
			}
			else
			{
				$goodSoul->{$key}++;
				$yes++;
			}
		}
	}
	else
	{
		foreach my $key (keys %geMinSim)
		{
			delete $ltMinSim{$key} if ( exists $ltMinSim{$key} );
			$badSoul->{$key}++;
			$no++;
		}
		
		foreach my $key (keys %ltMinSim)
		{
			$maybeSoul->{$key}++;
			$maybe++;
		}
	}

	print "\tTOTAL PSL LINES  : $countLine\n";
	print "\tTOTAL PSL PROBES : ",int(keys %listAll),"\n";
	print "\tTOTAL DB PROBES  : ",int(keys %{$soulsFa}),"\n";
	print "\tYES   ", "(",    "NOT ON PSL",") : $yes\n" if ( ! $noValidate );
	print "\tNO    ", "(>=" , $minSim     ,") : $no\n";
	print "\tMAYBE ", "(< " , $minSim     ,") : $maybe\n";

	return $goodSoul, $badSoul, $maybeSoul;
}

1;

#    matches int unsigned ,           # Number of bases that match that aren't repeats
#    misMatches int unsigned ,        # Number of bases that don't match
#    repMatches int unsigned ,        # Number of bases that match but are part of repeats
#    nCount int unsigned ,            # Number of 'N' bases
#    qNumInsert int unsigned ,        # Number of inserts in query
#    qBaseInsert int unsigned ,       # Number of bases inserted in query
#    tNumInsert int unsigned ,        # Number of inserts in target
#    tBaseInsert int unsigned ,       # Number of bases inserted in target
#    strand char(2) ,                 # + or - for query strand, optionally followed by + or – for target strand
#    qName varchar(255) ,             # Query sequence name
#    qSize int unsigned ,             # Query sequence size
#    qStart int unsigned ,            # Alignment start position in query
#    qEnd int unsigned ,              # Alignment end position in query
#    tName varchar(255) ,             # Target sequence name
#    tSize int unsigned ,             # Target sequence size
#    tStart int unsigned ,            # Alignment start position in target
#    tEnd int unsigned ,              # Alignment end position in target
#    blockCount int unsigned ,        # Number of blocks in alignment. A block contains no gaps.
#    blockSizes longblob ,            # Size of each block in a comma separated list
#    qStarts longblob ,               # Start of each block in query in a comma separated list
#    tStarts longblob ,               # Start of each block in target in a comma separated list


