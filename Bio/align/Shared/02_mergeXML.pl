#!/usr/bin/perl -w
use strict;
use warnings;
#use FindBin qw($Bin);
#use lib "$Bin";
#use loadconf;

#Shared/02_mergeXML.pl /home/saulo/Desktop/blast/Ferry_Genome/Top17None01/02_xml
#/home/saulo/Desktop/blast/Ferry_Genome/Top17None01/04_xml_merged
#/home/saulo/Desktop/Genome/results4/gaggles/report/individual3/Top17None01/Top17None01.GENES.csv.out.tab.fasta
my $usage    = "USAGE: $0 <input XML folder> <OUTPUT XML folder> <INPUT FILE NAME>\n";
my $inFolder = $ARGV[0] or die $usage;
my $ouFolder = $ARGV[1] or die $usage;
my $inFile   = $ARGV[2] or die $usage;
my $ouFile   = $inFile;

$ouFile .= "_blast_merged";

if ( ! -d $inFolder ) { die "FOLDER $inFolder DOESNT EXISTS\n"};
#if ( ! -f $inFile   ) { die "INPUT FILE $inFile DOESNT EXISTS\n"}
if ( ! -d $ouFolder ) { mkdir $ouFolder };

#`rm -Rf xml_merged`;
#mkdir "xml_merged";


# LOAD DIVERSE SNP XML FILES AND MERGES THEM AS A SINGLE FILE
# GENERATES OUTPUTS SORTED BY POSITION, PROGRAM OR CHROMOSSOME


my $xmlHash = &load_blast($inFolder, $inFile, "org.xml");
&save_merged($ouFolder, "org", $xmlHash);

$xmlHash = &load_blast($inFolder, $inFile, "gene.xml");
&save_merged($ouFolder, "gene", $xmlHash);

#&save_merged_prog();
#&save_chromossome();

sub load_blast
{
	my $dir   = $_[0];
	my $begin = $_[1];
	my $ext   = $_[2];

	my %hash;

	my $beginShort = substr($begin, rindex($begin, "/")+1);

	foreach my $file (&list_dir($dir,$beginShort,$ext))
	{
		&parseXML("$dir/$file", \%hash);
	}

	return \%hash;
}

sub save_merged
{
	my $folder      = $_[0];
	my $epitope     = $_[1];
	my $hash        = $_[2];
	my $ouFileShort = substr($ouFile, rindex($ouFile, "/")+1);
	my $count       = 0;

	my %chromo;
	#push(@{$hash->{$jobType}[0]}, $jobId);
	#$hash->{$jobType}[1] = $jobDesc;
	#$hash->{$jobType}[2]{all}{$queryType}{$queryId}{$hitsType}{$hitsId}{$hitId}{$hspId}{$key} = $value;

	foreach my $jobType (sort keys %$hash)
	{
		my $ids  = $hash->{$jobType}[0];
		my $desc = $hash->{$jobType}[1];
		my $job  = $hash->{$jobType}[2];
		foreach my $jobId (sort keys %$job)
		{
			my $outFileName = $ouFileShort . '_' . $jobType . '_' . $jobId . '_' . $epitope . ".xml";
			print "EXPORTING XML FILE: $folder/$outFileName\n";
			open FILEX, ">$folder/$outFileName"     or die "COULD NOT OPEN $folder/$outFileName     XML FILE: $!";
			open FILET, ">$folder/$outFileName.tab" or die "COULD NOT OPEN $folder/$outFileName.tab TAB FILE: $!";

			#print FILE "<job id=\"$jobId\" type=\"$jobType\">\n";
			print FILEX &getXMLHeader("$ouFileShort\_$epitope", $jobId, $jobType, $desc);


			my %headerKeys;
			%headerKeys = ( 'queryId' => 0, 'hitsId' => 1, 'hitId' => 2, 'hspId' => 3);
			my $col = scalar keys %headerKeys;


			my $jobs = $job->{$jobId};
			foreach my $queryType (sort keys %$jobs)
			{
				my $queries = $jobs->{$queryType};
				foreach my $queryId (sort keys %$queries)
				{
					#$hash->{$jobType}[2]{all}{$queryType}{$queryId}{$hitsType}{$hitsId}{$hitId}{$hspId}{$key} = $value;
					my $hits = $queries->{$queryId};
					foreach my $hitsType (sort keys %$hits)
					{
						my $hitsIds = $hits->{$hitsType};
						foreach my $hitsId (sort keys %$hitsIds)
						{
							my $hit = $hitsIds->{$hitsId};
							foreach my $hitId (sort keys %$hit)
							{
								my $hspIds = $hit->{$hitId};
								foreach my $hspId (sort keys %$hspIds)
								{
									my $values = $hspIds->{$hspId};
									foreach my $key (sort keys %$values)
									{
										if ( ! exists $headerKeys{$key} )
										{
											$headerKeys{$key} = $col++;
										}
									}
								}
							}
						}
					}
				}
			}
			my @headerValues;

			map { $headerValues[$headerKeys{$_}] = $_; } keys %headerKeys;


			print FILET "#JOB ID     : $jobId\n";
			print FILET "#DESCRIPTION: $desc\n";
			print FILET "#", join("\t", @headerValues), "\n";


			foreach my $queryType (sort keys %$jobs)
			{
				my $queries = $jobs->{$queryType};
				foreach my $queryId (sort keys %$queries)
				{
					print FILEX "\t\t<query id=\"$queryId\" type=\"$queryType\" count=\"",(scalar keys %$queries),"\">\n";
					my $hits = $queries->{$queryId};
					foreach my $hitsType (sort keys %$hits)
					{
						my $hitsIds = $hits->{$hitsType};
						foreach my $hitsId (sort keys %$hitsIds)
						{
							print FILEX "\t\t\t<hits id=\"$hitsId\" type=\"$hitsType\" count=\"",(scalar keys %$hitsIds),"\">\n";
							my $hit      = $hitsIds->{$hitsId};
							my $hitCount = 0;
							foreach my $hitId (sort keys %$hit)
							{
								print FILEX "\t\t\t\t<hit id=\"$hitId\" count=\"",++$hitCount,"\">\n";
								my $hspIds   = $hit->{$hitId};
								my $hspCount = 0;
								foreach my $hspId (sort keys %$hspIds)
								{
									my $outT;
									my $outX   = "\t\t\t\t\t<hsp id=\"$hspId\" count=\"". ++$hspCount . "\">\n";
									my $values = $hspIds->{$hspId};



									my %colsData = ( 'queryId' => $queryId, 'hitsId' => $hitsId, 'hitId' => $hitId, 'hspId' => $hspId );

									foreach my $key (sort keys %$values)
									{
										my $value       = $values->{$key};
										$outX          .= "\t\t\t\t\t\t<$key>$value</$key>\n";
										$colsData{$key} = $value;
									}

									for ( my $c = 0 ; $c < @headerValues; $c++ )
									{
										my $colName = $headerValues[$c];
										my $v       = $colsData{$colName};
										if ( ! defined $v ) {$v = ''; };
										#print "COL NUMBER '$c' COL NAME '$colName' VALUE '",substr($v,0,100),"'\n";
										$outT .= ($c ? "\t" : '') . $v;
									}
									#print "\n";




									$outX .= "\t\t\t\t\t</hsp>\n";
									print FILET $outT, "\n";
									print FILEX $outX;
								} #end foreach my hspid
								print FILEX "\t\t\t\t</hit>\n";
							} #end foreach my hitid
							print FILEX "\t\t\t</hits>\n";
						} # end foreach my hitsid
					} # end foreach my hitstype
					print FILEX "\t\t</query>\n";
				} #end foreach my queryid
			} #end foreach my querytype
			#print FILE "</job>\n";
			print FILEX &getXMLTail();
			close FILEX;
			close FILET;
		} #end foreach my jobid
	} #end foreach my jobtype
} #end sub parse snps




sub parseXML
{
	my $file = $_[0];
	my $hash = $_[1];

	open FILE, "<$file" or die "COULD NOT OPEN FILE $file: $!";
	if ( ! -f $file ) {die "FILE $file DOESNT EXISTS"};


	#<job id="59dup_cngrubiiH99.blast" type="blast">
	#	<query id="162.m02386" type="gene">
	#		<matches id="Cryptococcus neoformans var grubii H99" type="organism">
	#			<match id="1">
	#				<id>1</id>
	#				<strand>-1</strand>
	#			</match>
	#		</matches>
	#	</query>
	#</job>

	my $job             = 0;
	my $jobId           = "";
	my $jobType         = "";
	my $jobDesc         = "";

	my $query           = 0;
	my $queryId         = "";
	my $queryType       = "";

	my $hits            = 0;
	my $hitsId          = "";
	my $hitsType        = "";

	my $hit             = 0;
	my $hitId           = "";

	my $hsp             = 0;
	my $hspId           = 0;
	my $hspCount        = 0;

	my $registerJob     = 0;
	my $registerQuery   = 0;
	my $registerMatches = 0;
	my $registerMatch   = 0;

	foreach my $line (<FILE>)
	{
		chomp $line;
		#print $line, "\t";
		if (( ! $job ) && ( $line =~ /<job/ ))
		{
			if ($line =~ /id=\"(.*?)\"/)   { $jobId     = $1; }
			if ($line =~ /type=\"(.*?)\"/) { $jobType   = $1; }
			if ($line =~ /desc=\"(.*?)\"/) { $jobDesc   = $1; }
			#print "<JOB>\n";
			$registerJob++;
			$job       = 1;
			next;
		}

		if (( $job ) && ($line =~ /<\/job>/))
		{
			#print "</JOB>\n";
			$job       = 0;
			$jobId     = "";
			#$jobType   = "";
			next;
		}

		if ( $job )
		{
			die if ! defined $jobId;
			die if ! defined $jobType;
			if (( ! $query ) && ( $line =~ /<query\s+id=\"(.+)\"\s+type=\"(.*)\">/ ))
			{
				#print "<QUERY>\n";
				$registerQuery++;
				$query     = 1;
				$queryId   = $1;
				$queryType = $2;
				next;
			}

			if (( $query ) && ( $line =~ /<\/query>/ ))
			{
				#print "</QUERY>\n";
				$query     = 0;
				$queryId   = "";
				#$queryType = "";
				next;
			}

			if ( $query )
			{
				if (( ! $hits ) && ( $line =~ /<hits\s+id=\"(.+)\"\s+type=\"(.*)\">/ ))
				{
					#print "<MATCHES>\n";
					$registerMatches++;
					$hits     = 1;
					$hitsId   = $1;
					$hitsType = $2;
					next;
				}

				if (( $hits ) && ( $line =~ /<\/hits>/ ))
				{
					#print "</MATCHES>\n";
					$hits     = 0;
					$hitsId   = "";
					#$matchesType = "";
					next;
				}

				if ( $hits )
				{
					if (( ! $hit ) &&( $line =~ /<hit\s+id=\"(.+)\">/ ))
					{
						#print "<MATCH>\n";
						$registerMatch++;
						$hit      = 1;
						$hitId    = $1;
						$hspId    = "";
						next;
					}

					if (( $hit ) &&( $line =~ /<\/hit>/ ))
					{
						#print "</MATCH>\n";
						$hit   = 0;
						$hitId = "";
						next;
					}

					#<match id="1">
					if ( $hit )
					{
						if (( ! $hsp ) && ( $line =~ /<hsp\s+id\=\"(\S+?)\"\s+count\=\"\S+?\"/ ))
						{
							$hsp      = 1;
							$hspId    = $1;
							$hspCount++;
						}

						if (( $hsp ) && ( $line =~ /<\/hsp>/ ))
						{
							$hsp      = 0;
							$hspId    = "";
						}

						if ( $hsp )
						{
							if ( $line =~ /<(\w+)>(.+)<\/\1>/ )
							{
								#print "<VALUE>\n";
								my $key   = $1;
								my $value = $2;
								push(@{$hash->{$jobType}[0]}, $jobId);
								$hash->{$jobType}[1] = $jobDesc;
								$hash->{$jobType}[2]{all}{$queryType}{$queryId}{$hitsType}{$hitsId}{$hitId}{$hspId}{$key} = $value;
							} #end if value
						} # end if hsp
					} #end if match
				} #end if matches
			} #end if query
		} # end if job
	}

	close FILE;
	printf "  FILE %-40s PARSED: %02d JOBS (%-10s) ANALYZED CONTAINING %03d QUERIES (%-10s) %03d MATCHES (CLASS %-10s) AND %03d MATCHES [%-s]\n",
	$file, $registerJob, $jobType, $registerQuery, $queryType, $registerMatches, $hitsType, $registerMatch, $jobDesc;
}

sub list_dir
{
	my $dir   = $_[0];
	my $begin = $_[1];
	my $ext   = $_[2];
 	print "OPENNING DIR $dir AND SEARCHING FOR EXTENSIONLS $ext\n";

	my @ext;

	opendir (DIR, "$dir") or die "CANT READ DIRECTORY $dir: $!\n";
	if ($begin)
	{
		@ext = grep { (!/^\./) && -f "$dir/$_" && (/$ext$/) && (/$begin/)} readdir(DIR);
	}
	else
	{
		@ext = grep { (!/^\./) && -f "$dir/$_" && (/$ext$/)} readdir(DIR);
	}
	closedir DIR;

	print "ANALIZING BEGIN: \"$begin\" EXT: \"$ext\" FOLDER \"$dir\" RESULT: \"", join(", ", @ext), "\"\n";

	return @ext;
}

sub list_subdir
{
	my $dir = $_[0];

# 	print "openning dir $dir and searching for subdirs\n";

	opendir (DIR, "$dir") or die "CANT READ DIRECTORY $dir: $!\n";
	my @dirs = grep { (!/^\./) && -d "$dir/$_" } readdir(DIR);
	closedir DIR;

	return @dirs;
}








sub getXMLHeader
{
	my $source = $_[0];
	my $id     = $_[1];
	my $type   = $_[2];
	my $desc   = $_[3];


	my $HEADER =
'<?xml version="1.0" encoding="ISO-8859-1"?>
<?xml-stylesheet type="text/xml" href="#stylesheet"?>
<!DOCTYPE doc [
<!ATTLIST xsl:stylesheet id ID #REQUIRED>
]>
<data>
<!-- 	PROBES DATA 	-->
'.
"\t<probes id=\"$source\" type=\"$type\" desc=\"$desc\">\n";

return $HEADER;
}

sub getXMLTail
{
	my $TAIL = "\t</probes>\n" .
'

<!--       STYLESHEET         -->
	<xsl:stylesheet id="stylesheet" version="1.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
		<xsl:output method="html"/>

<!--    VARIABLES DECLARATION        -->
		<xsl:param name="queryTxt"         select="\'QUERY: \'"/>
		<xsl:param name="matchesTxt"       select="\'MATCHES: \'"/>
		<xsl:param name="matchTxt"         select="\'MATCH: \'"/>
		<xsl:param name="sumaryTitle"      select="\'SUMARY\'"/>
		<xsl:param name="probesTxt"        select="\'probes\'"/>
		<xsl:param name="descTxt"          select="\'blast parameters: \'"/>
		<xsl:param name="probeTitle"       select="\'PROBE NAME\'"/>
		<xsl:param name="probeCount"       select="\'APPEARANCES\'"/>

		<xsl:param name="space"            select="\', \'"/>

		<xsl:param name="h"                select="round(count(data/probes/query) div 2) + 1"/>
		<xsl:param name="i"                select="$h - 1"/>


<!--    HTML DATA       -->
		<xsl:template match="data">
			<html>
<!--    HEADER          -->
				<body style="font-family:Arial;font-size:12pt;background-color:#EEEEEE">
					<title><xsl:value-of select="probes/@id"/></title>
					<p align="center"><h1><b><xsl:value-of select="probes/@id"/></b></h1></p>
					<a>
						<xsl:attribute name="name">
						  <xsl:value-of select="top"/>
						</xsl:attribute>
					</a>
					<p align="right"><h4><i><xsl:value-of select="concat(count(probes/query), \' \', $probesTxt)"/></i></h4></p>
					<p align="right"><h4><i><xsl:value-of select="concat($descTxt, \' \', probes/@desc)"/></i></h4></p>




<!--    SUMARY          -->
					<span style="font-family: \'Courrier New\'">
						<table border="0" cellpadding="0" align="center" style="border-width:0px" witdh="100%">
<!--	FIRST HALF OF TABLE     -->
							<th align="left" valign="top">
								<table border="0" cellpadding="0" align="left" style="border-width:0px" witdh="50%">
									<tr bgcolor="#9acd32">
										<th align="left"><xsl:value-of select="$probeTitle"/> </th>
										<th align="left"><xsl:value-of select="$probeCount"/>  </th>
									</tr>
									<xsl:for-each select="probes/query[position() &lt; $h]">
										<tr>
											<th align="left" valign="top">
												<a>
													<xsl:attribute name="href">#<xsl:value-of select="@id"/>
													</xsl:attribute>
													<xsl:value-of select="@id"/>
												</a>
												<br/>[<xsl:value-of select="count(./matches)"/><xsl:value-of select="./matches[1]/@type"/>]
											</th>
											<th align="left" valign="top">
												<xsl:for-each select="matches">
													[<xsl:value-of select="count(./match)"/> matches] <xsl:value-of select="./@id"/><xsl:value-of select="$space"/><br/>
												</xsl:for-each> <!-- end foreach org -->
											</th>
										</tr>
										<tr>
											<th align="left" valign="top"/>
											<th align="left" valign="top">
												DESC <xsl:value-of select="./matches[1]/match[1]/queryDesc/."/>
											</th>
										</tr>
										<tr>
											<th align="left" valign="top" colspan="2">
												<br/>
											</th>
										</tr>
									</xsl:for-each> <!-- end foreach fwd -->
								</table>
							</th>

<!-- 	SECOND HALF OF TABLE 		-->
							<th align="right" valign="top">
								<table border="0" cellpadding="0" align="right" style="border-width:0px" witdh="50%">
									<tr bgcolor="#9acd32">
										<th valign="top" align="left"><xsl:value-of select="$probeTitle"/> </th>
										<th valign="top" align="left"><xsl:value-of select="$probeCount"/> </th>
									</tr>
									<xsl:for-each select="probes/query[position() &gt; $i]">
										<tr>
											<th align="left" valign="top">
												<a>
													<xsl:attribute name="href">#<xsl:value-of select="@id"/>
													</xsl:attribute>
													<xsl:value-of select="@id"/>
												</a>
												 <br/>[<xsl:value-of select="count(./matches)"/><xsl:value-of select="./matches[1]/@type"/>]
											</th>
											<th valign="top" align="left">
												<xsl:for-each select="matches">
													[<xsl:value-of select="count(./match)"/> matches] <xsl:value-of select="./@id"/><xsl:value-of select="$space"/><br/>
												</xsl:for-each> <!-- end foreach org -->
											</th>
										</tr>
										<tr>
											<th align="left" valign="top"/>
											<th align="left" valign="top">
												DESC <xsl:value-of select="./matches[1]/match[1]/queryDesc/."/>
											</th>
										</tr>
										<tr>
											<th align="left" valign="top" colspan="2">
												<br/>
											</th>
										</tr>
									</xsl:for-each> <!-- end foreach fwd -->
								</table>
							</th>
						</table>
					</span>


<!--	BODY 		-->
					<span style="font-family: \'Courrier New\'">
						<xsl:for-each select="probes/query">
							<div width="100%" style="background-color:red;color:white;padding:8px;padding-left=0px;width:100%" name="query">
								<span style="font-weight:bold">
									<a>
										<xsl:attribute name="name">
										  <xsl:value-of select="@id"/>
										</xsl:attribute>
									</a>
									<xsl:value-of select="$queryTxt"/><xsl:value-of select="@id"/>
									[<xsl:value-of select="count(./matches)"/><xsl:text> </xsl:text> <xsl:value-of select="./matches[1]/@type"/>]
									<a>
										<xsl:attribute name="href">#<xsl:value-of select="top"/>
										</xsl:attribute>
										top
									</a>
								</span>
							</div>

							<xsl:for-each select="matches">
								<div width="100%" style="background-color:coral;color:white;padding:4px;padding-left:16px;width:100%" name="matchesHeader">
									<span style="font-weight:bold">
										<xsl:value-of select="$matchesTxt"/><xsl:value-of select="@id"/> [<xsl:value-of select="count(./match)"/> matches]
									</span>
								</div>
								<xsl:for-each select="match">
								<!-- <xsl:sort/> -->
								<xsl:sort select="@id" data-type="number"/>
								<!-- <xsl:copy-of select="."/> -->
									<div width="100%" style="background-color:lightSalmon;color:white;padding:2px;padding-left:32px;width:100%" name="matchHeader">
										<span style="font-weight:bold">
											<xsl:value-of select="$matchTxt"/><xsl:value-of select="@id"/>
										</span>
									</div>

									<div width="100%" style="background-color:white;color:white;padding:2px;padding-left:32px;width:100%" name="matchBody">
										<table width="100%" border="0" cellpadding="0" align="center" style="border-width:0px; padding:0px">
											<tr border="0" bgcolor="#9acd32" style="border-width:0px; padding:0px">
												<th valign="top" border="0" align="left" style="border-width:0px; padding:0px">
													<div width="100%" style="background-color:white;color:black;padding:0px;padding-left:48px;width:100%">
														<table width="100%" border="0" cellpadding="0" align="center" style="border-width:0px; padding:0px">
															<tr border="0" bgcolor="#9acd32" style="border-width:0px; padding:0px">
																<xsl:for-each select="child::*">
																	<xsl:choose>
																		<xsl:when test="name()=\'aln\'">
																		</xsl:when>
																		<xsl:when test="name()=\'chromR\'">
																		</xsl:when>
																		<xsl:when test="name()=\'queryDesc\'">
																		</xsl:when>
																		<xsl:otherwise>
																			<th valign="top" border="0" align="left" style="border-width:0px; padding:0px">
																				<xsl:value-of select="name()"/>
																			</th>
																		</xsl:otherwise>
																	</xsl:choose>
																</xsl:for-each>
															</tr>
															<tr border="0" style="border-width:0px; padding:0px">
																<xsl:for-each select="child::*">
																	<xsl:choose>
																		<xsl:when test="name()=\'aln\'">
																		</xsl:when>
																		<xsl:when test="name()=\'chromR\'">
																		</xsl:when>
																		<xsl:when test="name()=\'queryDesc\'">
																		</xsl:when>
																		<xsl:otherwise>
																			<th valign="top" border="0" align="left" style="border-width:0px; padding:0px">
																				<xsl:value-of select="."/>
																			</th>
																		</xsl:otherwise>
																	</xsl:choose>
																</xsl:for-each>
															</tr>
														</table>
													</div>
												</th>
											</tr>


											<tr bgcolor="#9acd32" border="0" style="border-width:0px; padding:0px">
												<th valign="top" align="left" border="0" style="border-width:0px; padding:0px">
													<div width="100%" style="background-color:white; color:black; padding:0px; padding-left:48px; width:100%">
														<table width="100%" border="0" cellpadding="0" align="center" style="border-width:0px; padding:0px">
															<tr border="0" bgcolor="#9acd32" style="border-width:0px; padding:0px">
																<th valign="top" border="0" align="left" style="border-width:0px; padding:0px">
																	<xsl:text>Chromossome</xsl:text>
																</th>

																<!-- <xsl:for-each select="child::*"> -->
																<!-- 	<xsl:if test="name()=\'chromR\'"> -->
																<!--		<th valign="top" border="0" align="left" style="border-width:0px; padding:0px"> -->
																<!--			<xsl:text>Chromossome</xsl:text> -->
																<!--		</th> -->
																<!-- 	</xsl:if> -->
																<!-- </xsl:for-each> -->
															</tr>
															<tr border="0" style="border-width:0px; padding:0px">
																<th valign="top" border="0" align="left" style="border-width:0px; padding:0px">
																	<xsl:value-of select="chromR"/>
																</th>

																<!-- <xsl:for-each select="child::*"> -->
																<!-- 	<xsl:if test="name()=\'chromR\'"> -->
																<!-- 	</xsl:if> -->
																<!-- </xsl:for-each> -->
															</tr>
														</table>
													</div>
												</th>
											</tr>


											<tr bgcolor="#9acd32" border="0" style="border-width:0px; padding:0px">
												<th valign="top" align="left" border="0" style="border-width:0px; padding:0px">
													<div width="100%" style="background-color:white; color:black; padding:0px; padding-left:48px; width:100%">
														<table width="100%" border="0" cellpadding="0" align="center" style="border-width:0px; padding:0px">
															<tr border="0" bgcolor="#9acd32" style="border-width:0px; padding:0px">
																<th valign="top" border="0" align="left" style="border-width:0px; padding:0px">
																	<xsl:text>Query Description</xsl:text>
																</th>

																<!-- <xsl:for-each select="child::*"> -->
																<!-- 	<xsl:if test="name()=\'queryDesc\'"> -->
																<!-- 		<th valign="top" border="0" align="left" style="border-width:0px; padding:0px"><xsl:value-of select="name()"/></th> -->
																<!-- 	</xsl:if> -->
																<!-- </xsl:for-each> -->
															</tr>
															<tr border="0" style="border-width:0px; padding:0px">
																<th valign="top" align="left" border="0" style="border-width:0px; padding:0px">
																	<xsl:value-of select="queryDesc"/>
																</th>

																<!-- <xsl:for-each select="child::*"> -->
																<!-- 	<xsl:if test="name()=\'queryDesc\'"> -->
																<!-- 		<th valign="top" align="left" border="0" style="border-width:0px; padding:0px"><xmp><xsl:value-of select="."/></xmp></th> -->
																<!-- 	</xsl:if> -->
																<!-- </xsl:for-each> -->
															</tr>
														</table>
													</div>
												</th>
											</tr>


											<tr bgcolor="#9acd32" border="0" style="border-width:0px; padding:0px">
												<th valign="top" align="left" border="0" style="border-width:0px; padding:0px">
													<div width="100%" style="background-color:white; color:black; padding:0px; padding-left:48px; width:100%">
														<table width="100%" border="0" cellpadding="0" align="center" style="border-width:0px; padding:0px; width:100%; border-collapse: collapse">
															<tr bgcolor="#9acd32"  border="0" style="border-width:0px; padding:0px">
																<th valign="top" align="left" border="0" style="border-width:0px; padding:0px; border:0px">
																	<xsl:text>Alignment</xsl:text>
																</th>

																<!-- <xsl:for-each select="child::*"> -->
																<!-- 	<xsl:choose> -->
																<!-- 		<xsl:when test="name()=\'aln\'"> -->
																<!-- 			<th valign="top" align="left" border="0" style="border-width:0px; padding:0px"><xsl:value-of select="name()"/></th> -->
																<!-- 		</xsl:when> -->
																<!-- 	</xsl:choose> -->
																<!-- </xsl:for-each> -->
															</tr>

															<tr style="border-width:0px; padding:0px; border:0px">
																<th valign="top" align="left" border="0" style="border-width:0px; padding:0px; border:0px">
																	<!-- <table border="0" cellpadding="0" style="border-width:0px"> -->
																		<xsl:for-each select="aln">
																			<pre><xsl:value-of select="./st"/><br/>
																				<xsl:value-of select="./nd"/><br/>
																				<xsl:value-of select="./rd"/>
																			</pre>
																				<!-- <tr border="0" cellpadding="0" style="border-width:0px"> -->
																				<!-- 	<th valign="top" align="left" style="border-width:0px; padding:0px"><code><xsl:value-of select="./st"/></code></th> -->
																				<!-- </tr> -->
																				<!-- <tr border="0" cellpadding="0" style="border-width:0px"> -->
																				<!-- 	<th valign="top" align="left" border="0" style="border-width:0px; padding:0px"><xsl:value-of select="./nd"/></th> -->
																				<!-- </tr> -->
																				<!-- <tr border="0" cellpadding="0" style="border-width:0px"> -->
																				<!-- 	<th valign="top" align="left" border="0" style="border-width:0px; padding:0px"><code><xsl:value-of select="./rd"/></code></th> -->
																				<!-- </tr> -->
																		</xsl:for-each>
																	<!-- </table> -->
																</th>


																<!-- <xsl:for-each select="child::*"> -->
																<!-- 	<xsl:choose> -->
																<!-- 		<xsl:when test="name()=\'aln\'"> -->
																<!-- 			<th valign="top" align="left" border="0" style="border-width:0px; padding:0px"> -->
																<!-- 				<table border="0" cellpadding="0" style="border-width:0px"> -->
																<!-- 					<tr border="0" cellpadding="0" style="border-width:0px"> -->
																<!-- 						<th valign="top" align="left" style="border-width:0px; padding:0px"><code><xsl:value-of select="./st"/></code></th> -->
																<!-- 					</tr> -->
																<!-- 					<tr border="0" cellpadding="0" style="border-width:0px"> -->
																<!-- 						<th valign="top" align="left" border="0" style="border-width:0px; padding:0px"><code><xsl:value-of select="./nd"/></code></th> -->
																<!-- 					</tr> -->
																<!-- 					<tr border="0" cellpadding="0" style="border-width:0px"> -->
																<!-- 						<th valign="top" align="left" border="0" style="border-width:0px; padding:0px"><code><xsl:value-of select="./rd"/></code></th> -->
																<!-- 					</tr> -->
																<!-- 				</table> -->
																<!-- 			 </th> -->
																<!-- 		</xsl:when> -->
																<!-- 	</xsl:choose> -->
																<!-- </xsl:for-each> -->
															</tr>
														</table>
													</div>
												</th>
											</tr>
										</table>
									</div>
								</xsl:for-each> <!-- MATCH -->
							</xsl:for-each> <!-- MATCHES -->
						</xsl:for-each> <!-- PROBE/QUERY -->
					</span>
				</body>
			</html>
		</xsl:template>
	</xsl:stylesheet>
</data>
';




return $TAIL;
}



1;
