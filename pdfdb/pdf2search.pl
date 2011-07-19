#!/usr/bin/perl -w
use Switch;
use MIME::Base64;

my $inFolder = $ARGV[0];
my $prefix   = "pdfDb";
my $base64   = 1;

die "PLEASE DEFINE INPUT FOLDER" if ( ! defined $inFolder );

my $inDbFile = "$prefix\_$inFolder.xml";
my $inDbKey  = "$prefix\_$inFolder\_xml.key.xml";
my $inDbWc   = "$prefix\_$inFolder\_xml.wc.xml";

print "USING $inDbFile, $inDbKey and #inDbWc\n";
die "INPUT FOLDER   $inFolder NOT FOUND" if ( ! -d $inFolder );
die "INPUT DB  FILE $inDbFile NOT FOUND" if ( ! -f $inDbFile );
die "INPUT KEY FILE $inDbkey  NOT FOUND" if ( ! -f $inDbKey  );
die "INPUT WC  FILE $inDbkey  NOT FOUND" if ( ! -f $inDbWc   );

print "=== CHOOSE FUNCTION ===\n";
my $opt = &getOpt("LIST FILES", "SEARCH FILES");

switch ( $opt )
{
	case 1 { &listFiles(); }
	case 2 { &searchDb(); }
}



sub listFiles
{
	print "=== CHOOSE OPTION ===\n";
	my $option = &getOpt("SHOW INFO", "PRINT CONTENT");
   
	my ($filesArray, $names, $maxLength) = &listFilesSub();
   	die "NO FILES IN DATABASE" if ( ! @$names );
	my $fileOpt = &getOpt(@{$names});

	if ( $option == 1 )
	{
		foreach my $key (keys %{$filesArray->[$fileOpt]})
		{
			printf "    %-" . $maxLength . "s = %s\n", $key, $filesArray->[$fileOpt]{$key};
		}
		print "\n";
	}
	elsif ( $option == 2 )
	{
		my $content = &getContent($filesArray, $fileOpt);
	   
		print "="x60, "\n";
		print $content;
		print "="x60, "\n";
	}
	else
	{
		die "INVALID OPTION. HOW DID YOU GET THAT FAR?";
	}
}


sub getContent
{
	my $filesArray = $_[0];
	my $fileOpt    = $_[1];
   
	my $sha     = $filesArray->[$fileOpt]{sha};
	my $content = getContentBySha($sha);
   
	return $content;
}


sub getContentBySha
{
	my $sha     = $_[0];
	my $inFile  = "$inFolder\_xml/$sha.xml";
	my $lineOn  = 0;
	my $content = '';
   
	open FOLDER, "<$inFile" or die "COULD NOT OPEN FILE $inFile: $!";
	while (my $line = <FOLDER>)
	{
		if ( $line =~ /\<\/html\>/) { $lineOn   = 0    ; last; };
		if ( $lineOn              ) { $content .= $line; }
		if ( $line =~ /\<html\>/  ) { $lineOn   = 1    ; };
	}
   
	close FOLDER;
   
	$content = decode_base64($content) if ( $base64 );
   
	return $content;
}


sub listFilesSub
{
	my $bySha = $_[0] || 0;
   
	open FILE, "<$inDbFile" or die "COULD NOT OPEN FILE $inDbFile: $!";
	my $on        = 0;
	my $current   = undef;
	my $maxLength = 10;
	my @filesArray;
	my %filesBySha;
	my @names;

	while (my $line = <FILE>)
	{
		chomp $line;

		if (( defined $current ) && ( $on ) )
		{
			if ( $line  =~ /\<\/pdf$current\>/   )
			{
				if ( $bySha )
				{
					$filesBySha{$filesArray[$current]{sha}} = $filesArray[$current];
				}

				$on = 0;
				$current = undef;
			}
		   
			if ( $line =~ /\<(.*)\>(.*)\<\/\1\>/ )
			{
				if ($1 eq "fileName")
				{
					$names[$current] = $2;
				}
				$maxLength = length($1) if ($maxLength < length($1));

				$filesArray[$current]{$1} = $2;
			   
				#print "\tKEY $1 VALUE $2\n";
			}
		}
		if ($line =~ /\<pdf(\d+)\>/)
		{
			$on      = 1;
			$current = $1;
		}
	}
	close FILE;
   
	return \@filesArray, \@names, $maxLength, \%filesBySha;
}



sub searchDb
{
	my $outOpt = &getOpt("SHOW INFO", "PRINT CONTENT", "BOTH");
	my $option = &waitResponse("PLACE QUERY WORDS", '\w');
   
	$option =~ s/\s+/ /;
	$option = lc($option);
	my @query = split(" ", $option);
	my %query;
   
	print "QUERY: \n";
	foreach my $word (@query)
	{
		$query{$word} = 1;
		print "\t$word\n";
	}
	print "\n";
   
	my @words;
	my %positions;
	my %occurrences;
   
	open FILE, "<$inDbKey" or die "COULD NOT OPEN FILE $inDbKey: $!";
	while (my $line = <FILE>)
	{
		chomp $line;

		if ($line =~ /\<(.*)\>(.*)\<\/\1\>/)
		{
			if ( exists $query{$1} )
			{
				$positions{$1} = $2;
				#print "    WORD $1 POS $2\n";
			}
		}        
	}
	close FILE;
   
	my @sortedPos = sort { $positions{$a} <=> $positions{$b} } keys %positions;
	my %byBook;
   
	open FILE, "<$inDbWc" or die "COULD NOT OPEN FILE $inDbWc: $!";
	foreach my $word (@sortedPos)
	{
		seek(FILE, $positions{$word}, 0);
		$posOn = 0;
		#print "\t\tSEEKING $pos\n";
		while (my $line = <FILE>)
		{
			chomp $line;
			last if ( $line =~ /\<\/$word\>/ );
		   
			if ( $posOn )
			{
				if ( $line =~ /\<book id=\"(.*)\"\>(\d+)\<\/book\>/)
				{
					my $book = $1;
					my $app  = $2;
					my $bookKeys = 0;
					if ( exists $byBook{$book} )
					{$bookKeys = @{$byBook{$book}}}
				   
					$occurrences{$word}{$book}   = $app;
					$byBook{$book}[$bookKeys][0] = $word;
					$byBook{$book}[$bookKeys][1] = $app;
					#print "$line\n";
				}
			}
		   
			$posOn = 1 if ( $line =~ /\<$word\>/ );
		}
	}
	close FILE;
   
   
	foreach my $word (keys %occurrences)
	{
		print "WORD $word:\n";
		foreach my $book (keys %{$occurrences{$word}})
		{
			my $times = $occurrences{$word}{$book};
			print "\tBOOK $book TIMES $times\n";
		}
	}


	if (($outOpt == 1) || ($outOpt == 3))
	{
		my ($filesArray, $names, $maxLength, $filesBySha) = &listFilesSub(1);
   
		foreach my $book (reverse sort { scalar(@{$byBook{$a}}) <=> scalar(@{$byBook{$b}}) } keys %byBook)
		{
			print "BOOK $book:\n";
   
			for (my $occ = 0; $occ < @{$byBook{$book}}; $occ++)
			{            
				my $word = $byBook{$book}[$occ][0];
				my $app  = $byBook{$book}[$occ][1];
				print "\tWORD $word TIMES $app\n";
			}
   
			my $details = $filesBySha->{$book};
			foreach my $key (keys %{$details})
			{
				printf "\t\tKEY %-" . $maxLength . "s VALUE %s\n", $key, $details->{$key};
			}
		   
			print "\n\n";
		}
	}
	elsif (($outOpt == 2) || ($outOpt == 3))
	{
		foreach my $book (reverse sort { scalar(@{$byBook{$a}}) <=> scalar(@{$byBook{$b}}) } keys %byBook)
		{
			my $content = &getContentBySha($book);
			#$content = decode_base64($content);
			print "="x60, "\n";
			print $content, "\n";
			print "="x60, "\n";
		}
	}
	else
	{
		die "INVALID OUTPUT OPTION $outOpt. HOW THE HELL DID U GET THAT FAR?";
	}
   
	last;
}





sub getOpt
{
	my @choices = (0);
	push(@choices, @_);
   
	my $opt  = 0;
	my $resp = 0;

	my $str = "CHOOSE YOUR OPTION:\n";
   
	for (my $o = 1; $o < @choices; $o++)
	{
		$str .= " [" . sprintf("%0".(length(scalar(@choices) - 1))."d",$o) . "] = " . $choices[$o] . "\n";
	}
   
	do
	{
		print $str;
	   
		$opt = <STDIN>;
		chomp $opt;
	   
		$resp   = 0;
   
		if ((defined $opt ) && ($opt !~ /^[^\d]$/) && ($opt > 0) && ($opt < @choices))
		{
			$resp = $opt;
		}
	}
	while ( ! $resp );

	return $resp;
}


sub waitResponse
{
	my $question = $_[0];
	my $rule     = $_[1];
	#print "RULE: $rule\n";
   
	my $opt  = undef;
	my $resp = undef;
   
	do
	{
		print $question, " : ";
	   
		$opt = <STDIN>;
		chomp $opt;
	   
		$resp   = undef;
   
		#print "OPT $opt\n";
		if ((defined $opt ) && ($opt =~ /$rule/))
		{
			#print "VALID $opt\n";
			$resp = $opt;
		}
	}
	while ( ! defined $resp );
   
	return $resp;
}

1;
