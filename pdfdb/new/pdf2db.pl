#!/usr/bin/perl -w
use strict;
use Cwd 'abs_path';
use MIME::Base64;
use Lingua::Stem;
my $startTime = time;

die "USAGE: $0 <INPUT FOLDER>" if ( ! $ARGV[0] );
my $inFolder       = $ARGV[0];
die "INPUT FOLDER $inFolder DOEST EXISTS" if ( ! -d $inFolder );

my $dbNameGlobal   = $inFolder;
my $outputPrefix   = "pdfDb";
$dbNameGlobal      =~ s/\//\_/;
$dbNameGlobal      =~ s/ /\_/;
if (substr($dbNameGlobal, -1) eq "_") { chop $dbNameGlobal };
$dbNameGlobal = "$outputPrefix\_" . $dbNameGlobal . ".xml";

my $outputFolder   = "$inFolder";
if ($outputFolder  =~ /\/$/) { chop $outputFolder; };
   $outputFolder  .= "\_xml/";
my $cleanTmp       = 1; # delete converted files
my $cleanXml       = 0;
my $redo           = 0; # re-convert files
my $store          = 1; # store info to xml file
 my $wc            = 1; # do word count and store to xml file
 my $wcStem        = 1; # stem word count
 my $storePdfInfo  = 1; # store pdf information to xml file
 #my $storePdfText  = 1; # store converted text and html to xml file
 my $storePdfHtml  = 1; # store converted text and html to xml file
 my $storeRaw      = 0; # raw or base64



die "INPUT FOLDER NOT DEFINED! "              if ( ! defined $inFolder );
die "INPUT FOLDER DOESNT EXISTS: $inFolder! " if ( ! -d $inFolder );

if ( ! -d $outputFolder )
{
	mkdir $outputFolder or die "COULD NOT CREATE OUTPUT FOLDER: $outputFolder : $!";
}

my $stemmer;
if ($wcStem)
{
	$stemmer = Lingua::Stem->new;
	$stemmer->stem_caching({ -level => 2});
}

my $files = &listFolder($inFolder);

if ($cleanTmp)
{
	&cleanTmpFiles($files);
}

if ($cleanXml)
{
	&cleanXmlFiles($files);
}
else
{
	if($redo)
	{
		&cleanXmlFiles($files);
	}

	&exportDocInfo($files);
   
	if ($store)
	{
		print "\tEXPORTING INDEX DB XML FILE...";
		$files = &count2sha($files);
		#&printHash($files);
		&xmlExport($dbNameGlobal, $files);
		&makeResume($dbNameGlobal, $files);
		print "DONE\n";
	}

	if( ! $redo )
	{
		&cleanDoc($outputFolder, $files);
	}

	print "GOOD BYE!\n";
}
print "EXECUTED IN", (time - $startTime), "s\n\n";


&exportSearchXml($outputFolder);



sub printHash
{
		my $hash = $_[0];
		foreach my $book ( keys %{$hash})
		{
				print "BOOK $book\n";
				foreach my $key ( keys %{$hash->{$book}})
				{
						my $value = $hash->{$book}{$key};
						print "KEY $key\tVALUE $value\n";
				}
				print "\n";
		}
}


sub count2sha
{
		my $files = $_[0];
		my %nFiles;
	   
		foreach my $count ( sort keys %{$files} )
		{
				my $sha = $files->{$count}{sha};
			   
				foreach my $key ( sort keys %{$files->{$count}} )
				{
						$nFiles{"pdf id=\"$sha\""}{$key} = $files->{$count}{$key};
				}
		}

		return \%nFiles;
}

sub cleanDoc
{
	my $lFolder = $_[0];
	my $lHash   = $_[1];
	my $seenHash;

	print "\tCLEANING HASH TABLE ON \"$lFolder\" ...";

	my $array = &findAndSplitFile($lFolder, "xml");

	foreach my $key (sort keys %{$lHash})
	{
		$seenHash->{$lHash->{$key}{sha}}++;
	}

	for (my $i = 0; $i < @{$array}; $i++)
	{
		my $fileName = $array->[$i][1];
		my $path     = $array->[$i][0];
		if ( $fileName =~ s/.xml$//i )
		{
			if ( ! exists $seenHash->{$fileName} )
			{
				unlink("$path/$fileName.xml");
				print "DELETING HASH $fileName.xml\n";
			}
		}
		else
		{
			die "FILE $fileName ISNT A XML FILE";
		}
	}

	print "DONE\n";
}

sub makeResume
{
	my $outName         = $_[0];
	my $lHash           = $_[1];
	my $originalOutName = $outName;
	$outName           .= ".nfo";

	my $total        = scalar(keys %{$lHash});
	my $totalPdfSize = 0;
	my $totalDbSize  = 0;
	my $seenHash;
   
	foreach my $key (sort keys %{$lHash})
	{
		#print "KEY      \"", $key,                   "\"\n";
		#print "\tDBSIZE \"", $lHash->{$key}{dbSize}, "\"\n";
		#print "\tSIZE   \"", $lHash->{$key}{size},   "\"\n";
		#print "\tSHA    \"", $lHash->{$key}{sha},    "\"\n\n";
	   
		#$hash->{$key}{dbSizeMb} = &byte2Mb($fileSize);
		$totalDbSize  += $lHash->{$key}{dbSize};
		$totalPdfSize += $lHash->{$key}{size};
		push(@{$seenHash->{$lHash->{$key}{sha}}}, $key);
	}
	my $totalSeenHash = scalar(keys %{$seenHash});

	foreach my $key (sort keys %{$seenHash})
	{
		if (scalar(@{$seenHash->{$key}}) > 1)
		{
			print "$key\n";
			for my $sKey (@{$seenHash->{$key}})
			{
				print "\t", $lHash->{$sKey}{folder},
					  "/" , $lHash->{$sKey}{fileName}, "\n";
			}
		}
	}

	my $outHash;
	my $indexSize = -s $originalOutName;
	$outHash->{info}{totalDbSize}    = $totalDbSize;
	$outHash->{info}{totalPdfSize}   = $totalPdfSize;
	$outHash->{info}{totalDbSizeMb}  = &byte2Mb($totalDbSize);
	$outHash->{info}{totalPdfSizeMb} = &byte2Mb($totalPdfSize);
	$outHash->{info}{totalSeenHash}  = $totalSeenHash;
	$outHash->{info}{totalPdfs}      = $total;
	$outHash->{info}{repeated}       = $total - $totalSeenHash;
	$outHash->{info}{indexSize}      = $indexSize;
	$outHash->{info}{indexSizeMb}    = &byte2Mb($indexSize);
	&xmlExport($outName, $outHash);
}


sub exportDocInfo
{
	my $hash  = $_[0];
	my $count = 0;

	print "EXPORTING DOC FILES...\n";
	foreach my $key (sort keys %{$hash})
	{
		my $fullPath = $hash->{$key}{fullPathReal};
		my $size     = $hash->{$key}{sizeMb};
	   
		if ( -f $fullPath )
		{
			print "\tCONVERTING #", ++$count ," \"", &trunc($fullPath,50),"\" [$size MB]:\n";

			#my $outFile  = $fullPath;
			#   $outFile  =~ s/.pdf$/.xml/i;

			my $shaSumNew = &getSha256($fullPath);
			$hash->{$key}{sha} = $shaSumNew;
			my $shaKey = "pdf id=\"$shaSumNew\"";

			my $outFile  = "$outputFolder/$shaSumNew.xml";

			if ( -f $outFile )
			{
				print "\t\tCHECKING...";

				if ($redo == 0)
				{
					print "OK... SKIPPING\n";
					my $shaSumDb = &getSha256($outFile);
					$hash->{$key}{shaDb} = $shaSumDb;
					my $fileSize = -s $outFile;
					$hash->{$key}{dbSize}   = $fileSize;
					$hash->{$key}{dbSizeMb} = &byte2Mb($fileSize);
					#print "FILESIZE $fileSize\n";
					next;
				}
				else
				{
					print "OK... BUT REDOING ANYWAYS\n";                   
				}
			}

			my $lHash;

			$lHash->{$key}{sha} = $shaSumNew;

			if ($wc || $storePdfHtml)
			{
				my $html = &getPdf2html($fullPath);
				if ($storePdfHtml)
				{
					if ( $storeRaw )
					{
						$lHash->{$key}{pdf}{html} = $$html;
					}
					else
					{
						$lHash->{$key}{pdf}{html} = encode_base64($$html);
					}
				}

				#if (($storePdfText) || ($wc))
				if ($wc)
				{
					#my $text = &getPdf2text($fullPath);
					if ($wc)
					{
						$lHash->{$key}{wc} = &wc($$html);
					}

					#if ($storePdfText)
					#{
					#   if ( $storeRaw )
					#   {
					#       $lHash->{pdf0}{pdf}{text} = $$text;
					#   }
					#   else
					#   {
					#       $lHash->{pdf0}{pdf}{text} = encode_base64($$text);
					#   }
					#}
				}
			}

			if ($storePdfInfo)
			{
				$lHash->{$key}{pdf}{info} = &parsePdfInfo(&getPdfInfo($fullPath)); 
			}

			&xmlExport($outFile, $lHash);
			my $shaSumDb = &getSha256($outFile);
			my $fileSize = -s $outFile;
			$hash->{$key}{shaDb}    = $shaSumDb;
			$hash->{$key}{dbSize}   = $fileSize;
			$hash->{$key}{dbSizeMb} = &byte2Mb($fileSize);
			#print "FILESIZE $fileSize\n";
		}
		else
		{
			die "FILE NOT FOUND $$fullPath: $!\n";
		}
	}
}


sub checkSha256
{
	my $fileName = $_[0];
	my $result   = "";
   
	open FH, "<$fileName" or die "COULD NOT OPEN FILE $fileName: $!";
	while (my $line = <FH>)
	{
		if ($line =~ /\<sha\>(.*)\<\/sha\>/)
		{
			$result = $1;
			last;
		}
	}
	close FH;

	return $result;
}









sub getPdf2html
{
	my $fileName = $_[0];
	my $outFile  = $fileName;
	   $outFile  =~ s/.pdf$/.html/i;
	   
	print "\t\tHTML>";
	print "CONVERTING...";
	#pdftotext -htmlmeta -layout Synthetic_probe_design.pdf
	my $output = `pdftotext -htmlmeta -layout "$fileName" 2>&1`;
   
	if ( -f $outFile )
	{
		my $data = &blurpFile($outFile);
		unlink($outFile);
		print "DONE...\n";
		return $data;
	}
	else
	{
		die "OUT FILE $outFile DOESNT EXISTS! ERROR CONVERTING TO HTML: $output";
	}
}


sub getPdf2text
{
	my $fileName = $_[0];
	my $outFile  = $fileName;
	   $outFile  =~ s/.pdf$/.txt/i;

	print "\t\tTEXT>";
	print "CONVERTING...";
	#pdftotext -layout Synthetic_probe_design.pdf
	my $output = `pdftotext -layout "$fileName" 2>&1`;
	   
	if ( -f $outFile )
	{
		my $data = &blurpFile($outFile);
		unlink($outFile);
		print "DONE...\n";
		return $data;
	}
	else
	{
		die "OUT FILE $outFile DOESNT EXISTS! ERROR CONVERTING TO TEXT: $output";
	}
}


sub getPdfInfo
{
	my $fileName = $_[0];
	my $outFile  = $fileName;
	   $outFile  =~ s/.pdf$/.nfo/i;

	print "\t\tINFO>";
	print "CONVERTING...";
	#pdfinfo semantic-web.pdf
	my $output = `pdfinfo "$fileName" 2>&1`;
	print "DONE...\n";
	return \$output;
}


sub parsePdfInfo
{
	my $input = $_[0];
	my @input = split("\n", $$input);
	my $lHash;
   
	die "NO VALID INPUT: ", $$input, "\n" if (@input < 6);
	my $lastTitle;
	foreach my $line (@input)
	{
		chomp $line;
		chomp $line;
		if (($line =~ /(.+?):\s+(.+)/) && ( ! ($line =~ /^#/)))
		{
			my $title        = $1;
			my $content      = $2;
			$content         =~ s/\&/\&amp\;/;
			$title           =~ s/\s//g;
			$lastTitle       = $title;
			$lHash->{$title} = $content;
		}
		elsif ($line ne "\n")
		{
			$lHash->{$lastTitle} .= " $line";
		}
		else
		{
			warn "ILL FORMATED INFO FILE:\n$line\n\n",join("\n",@input),"\n";
		}
	}
   
	return $lHash;
	#pdfinfo /home/saulo/Desktop/pdfinfo/input/info/semantic-web-technologies-trends-and-research-in-ontology-based-systems.9780470025963.23359.pdf
	#Title:          Semantic Web Technologies
	#Subject:        TEAM DDU
	#Author:         John Davies,Rudi Studer & Paul Warren
	#Creator:        3B2 Total Publishing System 7.51n/W
	#Producer:       Acrobat Distiller 5.0.5 (Windows)
	#CreationDate:   Fri May 26 17:18:24 2006
	#ModDate:        Fri May 26 17:21:03 2006
	#Tagged:         yes
	#Pages:          327
	#Encrypted:      no
	#Page size:      335 x 503 pts
	#File size:      4572927 bytes
	#Optimized:      yes
	#PDF version:    1.6  
}


sub blurpFile
{
	my $inFile = $_[0];
	open OUT, "<$inFile" or die "COULD NOT OPEN FILE $inFile: $!";
	local $/ = undef;
	my $result = <OUT>;
	close OUT;
	$result =~ tr/\x00-\x08\x0E-\x1F\x7F-\xFF//d;
	return \$result;
}


sub getSha256
{
	my $fullPath   = $_[0];
	my $shaSum     = `sha256sum "$fullPath" 2>&1`;

	$shaSum = &parseSha($shaSum, $fullPath);

	return $shaSum;
}


sub parseSha
{
	my $shaSum   = $_[0];
	my $fullPath = $_[1];

	if ($shaSum =~ /(.+?)\s+\Q$fullPath\E/)
	{
		$shaSum = $1;
	}
	else
	{
		die "\nERROR CALCULATING SHASUM: $fullPath:\n$shaSum\n\n";
	}

	return $shaSum;
}


sub findFile
{
	my $folder = $_[0];
	$folder    = abs_path($folder);
	if (substr($folder, -1) ne "/") {$folder .= "/"; };
	my $ext    = $_[1];
	#print "\t\t\tFINDING *.$ext ON $folder...\n";
	my $COMMAND = "find \"$folder\" -depth -type f -iname \"*.$ext\" -printf \"%h _*_ %f %s\\n\"";
	#print "\t\t\t\tRUNNING: $COMMAND\n";
	my @arr = `$COMMAND`;
	#print "DONE\n";
	return \@arr;
}


sub splitFindFile
{
	my $arr = $_[0];
	my $ext = $_[1];
	#print "\t\t\tSPLIT FIND \"$ext\"...";
	for (my $i = 0; $i < @{$arr}; $i++)
	{
		my $file = $arr->[$i];
		chomp $file;
		#folder     file name                                                                                       size in bytes
		#input/info semantic-web-technologies-trends-and-research-in-ontology-based-systems.9780470025963.23359.pdf 4572927
		#|          |                                                                                          |    |
		#|          |                                                                                          |    |
		#|          |          .-------------------------------------------------------------------------------'    |
		#|          |          |          .-------------------------------------------------------------------------'
		#|          `------.   |          |
		#`-------------.   |   |          |
		if ($file =~ /(.+?)\s\_\*\_\s(.+?\.$ext)\s(\d+)/i)
		{
			my $folder    = $1;
			my $fileName  = $2;
			my $size      = $3;
			$arr->[$i]    = undef;
			$arr->[$i][0] = $folder;
			$arr->[$i][1] = $fileName;
			$arr->[$i][2] = $size;
		}
		else
		{
			print "\tELSE $i $file\n";
		}

	}
	#print "SPLITTED\n";

	return $arr;
}


sub findAndSplitFile
{
	my $folder = $_[0];
	my $ext    = $_[1];

	my $array = &findFile($folder, $ext);
	   $array = &splitFindFile($array, $ext);

	return $array;
}


sub listFolder
{
	my $in = $_[0];
	print "LISTING FILES in \"$in\"... ";
	if ( ! -d $in ) { return undef; };
	my $array = &findAndSplitFile($in, "pdf");
	my $lHash;
   
	print scalar(@{$array}), " FILES FOUND... ";
   
	for (my $i = 0; $i < @{$array}; $i++)
	{
		my $ii           = sprintf("%04d", $i);

		my $folder       = $array->[$i][0];
		my $fileName     = $array->[$i][1];
		my $size         = $array->[$i][2];

	#$folder          = &fixSpace($folder);
	#$fileName        = &fixSpace($fileName);

		my $sizeMb       = &byte2Mb($size);
		my $absFolder    = abs_path($folder);
		my $fullPath     = $folder    ."/" .$fileName;
		my $fullPathReal = $absFolder ."/" .$fileName;
		die "LISTFILE     :: #$ii"               .
			"FOLDER        : \"$folder\" "       .
			"FILENAME      : \"$fileName\" "     .
			"FULLPATH      : \"$fullPathReal\" " .
			"DOESNT EXISTS : $!" if ( ! -f $fullPathReal);

		#print "I:$i SIZE: $size [$sizeMb MB] FILE: $fileName FOLDER: $folder\n";
		$lHash->{"pdf$ii"}{fileName}     = $fileName;
		$lHash->{"pdf$ii"}{folder}       = $folder;
		$lHash->{"pdf$ii"}{folderReal}   = $absFolder;
		$lHash->{"pdf$ii"}{size}         = $size;
		$lHash->{"pdf$ii"}{sizeMb}       = $sizeMb;
		$lHash->{"pdf$ii"}{fullPath}     = $fullPath;
		$lHash->{"pdf$ii"}{fullPathReal} = $fullPathReal;
	}
	print "DONE\n";
	return $lHash;
}


sub fixSpace
{
	my $in = $_[0];
	$in =~ s/\&/\&amp\;/;
	#   $in =~ s/\s/\\ /g;
	#   $in =~ s/,/\\,/g;
	return $in;

}


sub unFixSpace
{
	my $in = $_[0];
	$in =~ s/\&amp\;/\&/;
	#   $in =~ s/\s/\\ /g;
	#   $in =~ s/,/\\,/g;
	return $in;

}


sub byte2Mb
{
	my $in = $_[0];
	my $mb = (($in / 1024) / 1024);
	return sprintf("%.1f",$mb);
}

sub wc
{
	my $in = $_[0];
	my $lHash;
   
	$in =~ s/[[:^alpha:]]/ /gs;
	$in =~ s/\n//gs;
	$in =~ s/\s+/ /gs;
	$in = lc($in);

	if ($wcStem)
	{
		my $stemmed_words = $stemmer->stem( split(' ', $in) );
		#my $stemmed_words = Lingua::Stem::stem( split(' ', $in) );
		foreach my $word (@{$stemmed_words})
		{
			next if ( ! $word );
			next if (length $word <= 2);
			next if (length $word >= 20);
			$lHash->{$word}++;
		}
	}
	else
	{
		foreach my $word (split(' ', $in))
		{
			next if (!$word);
			next if (length $word <= 2);
			$lHash->{$word}++;
		}
	}
	#print scalar(keys %{$lHash}), " WORDS ACQUIRED\n";
   
	return $lHash;
}


sub xmlExport
{
	my $dbName = $_[0];
	my $lHash  = $_[1];

	print "\t\tEXPORTING XML ", &trunc($dbName, 50),"... ";

	open  DB, ">$dbName" or die "COULD NOT OPEN DB FILE $dbName\n";
	print DB "<XML>\n";

	foreach my $key (sort keys %{$lHash})
	{
		print DB "\t<$key>\n";
	   
		foreach my $skey (sort keys %{$lHash->{$key}})
		{
			if ($skey eq "pdf")
			{
				print DB "\t\t<$skey>\n";
				foreach my $sskey (sort keys %{$lHash->{$key}{$skey}})
				{
					if ($sskey ne "info")
					{
						print DB "\t\t\t<$sskey>\n", &fixAmp($lHash->{$key}{$skey}{$sskey}),"\n\t\t\t</$sskey>\n";
					}
					else
					{
						print DB "\t\t\t<$sskey>\n";
						foreach my $ssskey (sort keys %{$lHash->{$key}{$skey}{$sskey}})
						{
							my $pSsskey = &htmlEncode($ssskey);
							print DB "\t\t\t\t<$ssskey>$lHash->{$key}{$skey}{$sskey}{$ssskey}</$ssskey>\n";
						}
						print DB "\t\t\t</$sskey>\n";
					}
				}
				print DB "\t\t</$skey>\n";
			}
			elsif ($skey eq "wc")
			{
				print DB "\t\t<$skey>\n";
				foreach my $sskey (sort keys %{$lHash->{$key}{$skey}})
				{
					print DB "\t\t\t<$sskey>", &fixAmp($lHash->{$key}{$skey}{$sskey}), "</$sskey>\n";
				}
				print DB "\t\t</$skey>\n";
			}
			else
			{
				print DB "\t\t<$skey>", &fixAmp($lHash->{$key}{$skey}), "</$skey>\n";
			}
		}
		if ($key =~ /^pdf/) {$key = "pdf"};
		print DB "\t</$key>\n";
	}
   
	print DB "</XML>";
	close DB;
	print "DONE\n";
}


sub fixAmp
{
	my $str = $_[0];
	$str =~ s/\&/\&amp\;/;
	return $str
}


sub cleanTmpFiles
{
	print "CLEANING TMP FILES...\n";
	my $lHash = $_[0];

	foreach my $key (sort keys %{$lHash})
	{
		my $fullPath = $lHash->{$key}{fullPathReal};

		if ( -f $fullPath )
		{
			my $htmlOutFile  = $fullPath;
			my $textOutFile  = $fullPath;
			my $infoOutFile  = $fullPath;
			my $shaOutFile   = $fullPath;
			my $XMLOutFile   = $fullPath;

			$htmlOutFile =~ s/.pdf$/.html/i;
			$textOutFile =~ s/.pdf$/.txt/i;
			$infoOutFile =~ s/.pdf$/.nfo/i;
			$shaOutFile  =~ s/.pdf$/.sha/i;
			$XMLOutFile  =~ s/.pdf$/.xml/i;

			#print "\tDELETING ",&trunc($fullPath, 50)," CONVERTED FILES\n";
			if ( -f $htmlOutFile ) { unlink($htmlOutFile); };
			if ( -f $textOutFile ) { unlink($textOutFile); };
			if ( -f $infoOutFile ) { unlink($infoOutFile); };
			if ( -f $shaOutFile  ) { unlink($shaOutFile);  };
			if ( -f $XMLOutFile  ) { unlink($XMLOutFile);  };
		}
		else
		{
			die "cleanFiles :: FILE \"$fullPath\" DOESNT EXISTS\n";
		}
	}
	print "FILES CLEANED\n\n";
}


sub cleanXmlFiles
{
	print "CLEANING XML FILES...\n";

	unlink glob ("$outputFolder/*");
	unlink("$outputFolder");

	print "FILES CLEANED\n\n";
}


sub cleanXmlFolder
{
	print "CLEANING XML FOLDER...\n";

#LIST XML FOLDER
#LIST FILES SHAs
#SUBSTRACT LIST
#DELETE REST (OR NOT)

	print "FOLDER CLEANED\n\n";
}


sub trunc
{
	my $inStr = $_[0];
	my $size  = $_[1] || 300;
	my $half  = int((($size - 6)/2)+0.5);

	$inStr =~ s/\/.*\///;

	my $len   = length($inStr);
	my $outStr;

	if ($len > $size)
	{
		$outStr  = substr($inStr, 0, $half);
		$outStr .= " .... ";
		$outStr .= substr($inStr, $len-$half);
	}
	else
	{
		$outStr = $inStr;
	}
	return $outStr;
}


sub exportSearchXml
{
		my $shFolder = $_[0];
		my $xmlKey   = "wc";
	   
		die "FOLDER NOT DEFINED\n"      if ( ! $shFolder );
		die "$shFolder DOESNT EXISTS\n" if ( ! -d $shFolder );
	   
		print "FOLDER: $shFolder\n";
	   
		opendir DIR, "$shFolder" or die "COULD NOT OPEN DIR $shFolder: $!";
	   
		my @files = grep { /\.xml/ } readdir(DIR);
	   
		closedir(DIR);
	   
		my $fileCount = 0;
		my $on        = 0;
		my %wc;
	   
		foreach my $file (@files)
		{
			my $sha;
		   
			if ( $file =~ /(.*)\.xml/ )
			{
				$sha = $1;
			}
		   
			die if ( ! defined $sha );
	   
			printf "\t%04d\t%s\t%s\n",$fileCount++, $file, "";
		   
			open FILE, "<$shFolder/$file" or die "COULD NOT OPEN FILE $file: $!";
			while (my $line = <FILE>)
			{
				chomp $line;
				next if ( ! defined $line );
	   
				if (($on) && ($line =~ /\<\/$xmlKey\>/)) { $on = 0; }
	   
				if ($on)
				{
					if ($line =~ /\<(.*)\>(.*)\<\/\1\>/)
					{
						my $key   = $1;
						my $value = $2;
					   
						die if ( ! defined $key );
						die if ( ! defined $value );
					   
						#printf "\t\t\tKEY %-20s VALUE %03d\n", $key, $value;
						my $keys = 0;
						if ( defined $wc{$key} )
						{
							$keys = scalar(@{$wc{$key}});
						}
	   
						$wc{$key}[ $keys ][0] = $sha;
						$wc{$key}[ $keys ][1] = $value;
					}
				}
	   
				if ($line =~ /\<$xmlKey\>/)   { $on = 1; }
			}
			close FILE;
		}
	   
	   
		if ($shFolder =~ /(.*)\//) { $shFolder = $1; };
		print "EXPORTING TO $outputPrefix\_$shFolder.xml\n";
		my %pos;
	   
	   
		open FILE, ">$outputPrefix\_$shFolder.wc.xml" or die "COULD NOT OPEN $outputPrefix\_$shFolder.xml: $!";
		print FILE "<xml>\n";
		print FILE "\t<wc>\n";
		foreach my $word ( sort keys %wc)
		{
			#print "WORD $word\n";
			$pos{$word} = tell FILE;
			print FILE "\t\t<$word>\n";
		   
			my @books = @{$wc{$word}};
			foreach my $register (@books)
			{
				my ($book, $cCount) = @{$register};
	   
				die if ( ! defined $book);
				die if ( ! defined $cCount);
	   
				#printf "\t%s\t%03d\n", $book, $count;
				#print "REGISTER $register\n";
	   
				print FILE "\t\t\t<book id=\"$book\">$cCount</book>\n";
			}
			print FILE "\t\t</$word>\n";
		}
		print FILE "\t</wc>\n";
		print FILE "</xml>\n";
		close FILE;
	   
	   
		open FILE, ">$outputPrefix\_$shFolder.key.xml" or die "COULD NOT OPEN $outputPrefix\_$shFolder.key.xml: $!";
		print FILE "<xml>\n";
		foreach my $word ( sort keys %pos )
		{
			print FILE "\t<$word>", $pos{$word}, "</$word>\n";
		}
		print FILE "</xml>\n";
		close FILE;
}


















sub htmlEncode
{
	my $in = $_[0];
	# TO FIX: TAKE SPACES OUT!!!
	$in =~ s/([^A-Za-z0-9])/sprintf("% % %02X", ord($1))/seg;
	&fixAmp($in);
	return $in;
}

sub htmlDeEncode
{
	my $in = $_[0];
	$in =~ s/\%([A-Fa-f0-9]{2})/pack('C', hex($1))/seg;
	return $in;
}

1;
