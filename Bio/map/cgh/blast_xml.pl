#!/usr/bin/perl -w
use strict;
use Bio::SearchIO;
use Bio::AlignIO;
use IO::String;
use FindBin qw($Bin);
use lib "$Bin";
use loadconf;

$| = 1;
#my $COMMAND = "$blast2xml $setupFile $blastFolder $outFile $xmlFolder \"$blast_desc\"";
my $setupFile   = $ARGV[0] or die "USAGE: $0 <setup file> <input blast result folder> <input blast result file> [<out folder> <description>]\n";
my $inputFolder = $ARGV[1] or die "USAGE: $0 <setup file> <input blast result folder> <input blast result file> [<out folder> <description>]\n";
my $inputFile   = $ARGV[2] or die "USAGE: $0 <setup file> <input blast result folder> <input blast result file> [<out folder> <description>]\n";
my $outFolder   = $ARGV[3] || "xml";
my $desc        = $ARGV[4] || "";
my $inputPath   = "$inputFolder/$inputFile";

my $verbose     = 0;
my $Log;

if ($verbose) { unlink("$inputPath.log"); };

my %pref = &loadconf::loadConf($setupFile);

die if ! &loadconf::checkNeeds(
	'blastXml.hypothetical',		'blastXml.minIdent',
	'blastXml.minConsv', 			'blastXml.minMaxStretch',
	'blastXml.saveGenes',			'blastXml.saveOrganisms'
);


my $hypothetical   = $pref{'blastXml.hypothetical' };
my $minIdent       = $pref{'blastXml.minIdent'     }; # 60 %
my $minConsv       = $pref{'blastXml.minConsv'     }; # 70 %
my $minMaxStretch  = $pref{'blastXml.minMaxStretch'}; # bp
my $saveGenes      = $pref{'blastXml.saveGenes'    };
my $saveOrganisms  = $pref{'blastXml.saveOrganisms'};
my $totalSimFactor = ($minConsv/100);





#my $minSig       = 1e-2;

$desc .= " PERL :: MINIDENT $minIdent MINCONSV $minConsv MIN MAX STRETCH $minMaxStretch TOTAL SIM FACTOR $totalSimFactor";


# $inputFile = "answer_WM276GBFF10_06_R265_c_neoformans_db_tblastx.bls";
# $inputFile = "answer_WM276GBFF10_06_R265_c_neoformans_db_blastn.bls";
# $inputFile = "answer_WM276GBFF10_06_R265_c_neoformans_db_blastn_MIX.bls";
# $inputFile = "answer_WM276GBFF10_06_R265_c_neoformans_db_blastn.bls";
#$inputFile = "blastaALL.bls";

&fixBlast("$inputFolder/$inputFile");

my @answers;
my ($Gtotal, $GtotalG, $GbyOrg, $GbyGene);
@answers   = &start($inputPath);
$Gtotal    = $answers[0];
$GtotalG   = $answers[1];
$GbyOrg    = $answers[2];
$GbyGene   = $answers[3];

&save_organism($GbyOrg, $inputFile) if ( $saveOrganisms );
&save_genes($GbyGene, $inputFile)   if ( $saveGenes     );
&commitLog();



# <root id="NAME" type="[snp|gap|blast]">
#   <table id="NAME" type="[program|chromossome]">
#     <row>
#       <colum> </colum>
#     <row>
#   </table>
# </root>

sub start
{
	my $inputFil = $_[0];
	if ( -f $inputFil ) { &Log("LOADING FILE $inputFil\n"); } else { die "COULD NOT OPEN $inputFil: $!" };
	my $in = new Bio::SearchIO( -format => 'blast',
				   				-file   => $inputFil);
	$| =0;
	my %byGene;
	my %byOrg;

	my $Positives = 0;
	my $Negatives = 0;
	my $Blasts    = 0;
	my $NoHits    = 0;

	my $total     = 0;
	my $totalG    = 0;

	#my $minSize          = 35; #40
	#my $totalSimBaseSize = 60;
	#my $totalSimMinSize  = int($totalSimFactor*$totalSimBaseSize);

	while( my $result = $in->next_result )
	{
		my $RES_method           = $result->algorithm;
		my $RES_num_hits         = $result->num_hits;
		my $RES_databaseName     = $result->database_name;
		my $RES_queryName        = $result->query_name;
		my $RES_queryLength      = $result->query_length;
		#my $RES_queryDescription = $result->query_description;

		print "  "x2, "RESULT :: METHOD $RES_method HITS $RES_num_hits DB NAME $RES_databaseName QUERY NAME  $RES_queryName QUERY LENGTH  $RES_queryLength\n";

		my $hitC = 0;

		$total++;

		if ( $RES_num_hits )
		{
			my $minSize   = int($RES_queryLength * $totalSimFactor);
			print "QUERY LENGTH $RES_queryLength :: MIN SIZE $minSize\n";
			while( my $hit = $result->next_hit )
			{
				my $HIT_name           = $hit->name; $HIT_name =~ s/lcl\|//;
				my $HIT_significance   = $hit->significance;
				my $HIT_numHsps        = $hit->num_hsps;
				my $hit_MaxStretch     = 0;
				my $hit_totalSim       = 0;
				my $hit_totalLength    = 0;

				print "  "x3, "HIT :: HIT NAME $HIT_name SIGNIFICANCE $HIT_significance HSPS $HIT_numHsps\n";

				my %hit;
				$hitC++;
				my $hspC = 0;

				while( my $hsp = $hit->next_hsp )
				{
					my $HSP_Tlength       = $hsp->length('total');
					my $HSP_gaps          = $hsp->gaps;
					my $HSP_fracIdentical = $hsp->frac_identical;
					my $HSP_fracConserved = $hsp->frac_conserved;
					my $HSP_homol         = $hsp->homology_string;
					my $HSP_percIdentity  = $hsp->percent_identity;

					my $HSP_Hstart        = $hsp->start('hit');
					my $HSP_Hend          = $hsp->end('hit');
					my $HSP_Hlength       = $hsp->length('hit');
					my $HSP_Hstrand       = $hsp->strand('hit');
					my $HSP_Hstring       = $hsp->hit_string;

					my $HSP_Qstart        = $hsp->start('query');
					my $HSP_Qend          = $hsp->end('query');
					my $HSP_Qlength       = $hsp->length('query');
					my $HSP_Qstrand       = $hsp->strand('query');
					my $HSP_Qstring       = $hsp->query_string ;

					print "  "x4, "HSP :: TOTAL LENGHT $HSP_Tlength GAPS $HSP_gaps IDENTICAL $HSP_fracIdentical CONSERVED $HSP_fracConserved IDENTITY% $HSP_percIdentity\n";
					print "  "x5, "HIT : START $HSP_Hstart END $HSP_Hend LENGTH $HSP_Hlength STRAND $HSP_Hstrand\n";
					print "  "x5, "QRY : START $HSP_Qstart END $HSP_Qend LENGTH $HSP_Qlength STRAND $HSP_Qstrand\n";

					#if (( $Tlength >= $minSize ) || ( ))
					if( 1 )
					{
						$hspC++;
						if (( $HSP_percIdentity >= ($minIdent/100) ) || ($HSP_fracConserved >= ($minConsv/100) ))
						{
							#if ( $hit->significance <= $minSig )
							#{
								#$stat{$method}{$hsp->evalue}++; $total++;
								$totalG++;

								#next if $hsp->length('total') < $minSize ;

								my %data = (
									"querylength" => $RES_queryLength,
									"dbName"      => $RES_databaseName,
									"hitName"     => $HIT_name,
									"sign"        => $HIT_significance,
									"totalLength" => $HSP_Tlength,
									"gaps"        => $HSP_gaps,
									"ident"       => &roundFrac($HSP_fracIdentical *100),
									"consv"       => &roundFrac($HSP_fracConserved *100),

									"Hstart"      => $HSP_Hstart,
									"Hend"        => $HSP_Hend,
									"Hstrand"     => $HSP_Hstrand,
									"Hlength"     => $HSP_Hlength,

									"Qstart"      => $HSP_Qstart,
									"Qend"        => $HSP_Qend,
									"Qstrand"     => $HSP_Qstrand,
									"Qlength"     => $HSP_Qlength
								);


								#map { print "\t\t$_ > $data{$_}\n" } keys %data;

								#$homol             =~ tr/ /_/;
								my $aln            = "<st>" . $HSP_Qstring . "</st>";
								$aln              .= "<nd>" . $HSP_homol   . "</nd>";
								$aln              .= "<rd>" . $HSP_Hstring . "</rd>";
								$aln               =~ s/\n//g;
								$data{"aln"}       = $aln;

								#my $str;
								#my $str_fh = IO::String->new($str);
								#my $old_fh = select($str_fh);
								#my $alni   = $hsp->get_aln;
								#my $alnIO  = Bio::AlignIO->new(-fh =>$str_fh, -format=>"clustalw");
								#$alnIO->write_aln($alni);
								#select($old_fh) if defined $old_fh;
								#
								#my @str   = split("\n", $str);
								#my $start = index($str[3], $hsp->query_string);
								#$str = "";
								#map { $str .= substr($_, $start) . "\n" } @str[3 .. 5];
								#$data{"alnClustal"}  = $str;

								my $hsp_countStretch = 0;
								my $hsp_totalSim     = 0;
								my $hsp_maxStretch   = 0;
								while (my $char = chop $HSP_homol)
								{
									if ($char eq "|")
									{
										$hsp_countStretch++;
										$hsp_totalSim++;
										$hsp_maxStretch = $hsp_countStretch if ( $hsp_countStretch > $hsp_maxStretch);
									}
									else
									{
										$hsp_countStretch = 0;
									}
								}

								$data{"maxStretch"}  = $hsp_maxStretch;
								$data{"totalSim"}    = $hsp_totalSim;

								$hit_MaxStretch      = $hsp_maxStretch if $hsp_maxStretch > $hit_MaxStretch;
								$hit_totalSim       += $hsp_totalSim;
								$hit_totalLength    += $HSP_Hlength;

								$hit{$HSP_Qstart} = \%data;

							#} # end if sig > 1e-20
						} # end if ident < 80
						else {
							print "  "x4, "FILE $inputFil :: DB ", $RES_databaseName, " :: QUERY: ",$RES_queryName," :: HIT NAME ",$HIT_name," :: SMALL IDENT: ",$HSP_percIdentity," SMALL CONSV: ",$HSP_fracConserved,"\n";
						}
					} # end if length < 50
					else {
						print "  "x4, "FILE $inputFil :: DB ", $RES_databaseName, " :: QUERY: ",$RES_queryName," :: HIT NAME ",$HIT_name," :: TOO SHORT ",$HSP_Tlength,"\n";
					}
				}; # end while hsp


				if (($hit_MaxStretch >= $minMaxStretch) && ($hit_totalSim   >= $minSize) && ($hit_totalLength >= $minSize))
				{
					print "  "x3, "PASSED ::: FILE $inputFil :: DB ", $RES_databaseName, " :: QUERY: ",$RES_queryName," :: HIT NAME ",$HIT_name,"\n";
					print "  "x4, "SIZE $hit_totalLength ($hit_totalLength >= $minSize) && STRETCH ($hit_MaxStretch >= $minMaxStretch) && SIM ($hit_totalSim >= $minSize)\n\n\n";
					push(@{$byGene{$RES_queryName}{$RES_databaseName}}, \%hit);
					push(@{$byOrg{$RES_databaseName}{$RES_queryName}},  \%hit);
				} else {
					print "  "x3, "FAILED ::: FILE $inputFil :: DB ", $RES_databaseName, " :: QUERY: ",$RES_queryName," :: HIT NAME ",$HIT_name,"\n";
					print "  "x4, "TOO SHORT $hit_totalLength ($hit_totalLength < $minSize) || NO STRETCH ($hit_MaxStretch < $minMaxStretch) || NO SIM ($hit_totalSim < $minSize)\n\n\n";
				}
			}; # end while result
		} # end if hits
		else
		{
			print "FILE $inputFil :: DB ", $RES_databaseName, " :: QUERY: ",$RES_queryName," :: NO HITS\n";
		}
	}; # end if $result->num_hits

	$| =1;
	&Log("$inputFil LOADED :: TOTAL $total TOTALG $totalG\n");
	return ($total, $totalG, \%byOrg, \%byGene)
}

sub commitLog
{
	open FILE, ">$inputPath.log" or die "COULD NOT CREATE BLAST_XML.LOG";
	print FILE $Log;
	close FILE;
}


sub Log
{
	if ($verbose)
	{
		print $_[0];
	}
	$Log .= time . "\t" . $_[0];
}


sub fixBlast
{
	my $input = $_[0];
	print "\tFIXING BLAST $input\n";
	#if ( -f "$input.old" ) { warn "FILE $input NOT FIXED. APARENTLY ALREADY FIXED"; return 0 };
	my $printFix = 0;

	open INFILE,  "<$input"     or die "COULD NOT OPEN INPUT FILE $input FOR FIXING\n";
	open OUTFILE, ">$input.tmp" or die "COULD NOT OPEN INPUT FILE $input.tmp FOR FIXING\n";

	my $onQ = 0;
	my $onF = 0;
	my $query = "";
	my $hit   = "";
	while (<INFILE>)
	{
		chomp;
		if ((/^Length=/) && ($onQ))
		{
			print "\t\tONQ OFF  : $_\n" if ($printFix);
			print "\t\tONQ PRINT: $query\n" if ($printFix);
			$query =~ s/\s/\_/g;
			$query =~ s/\_+/\_/g;
			s/\s/\_/g;
			s/\_+/\_/g;
			print OUTFILE "Query=$query\n";
			print OUTFILE "$_\n";
			$onQ   = 0;
			$query = "";
		}
		elsif (( ! $onQ ) && ( ! (/^Query=\s*(.+)/)))
		{
			#print "\t\tONQ NULL: $_\n";
			#s/\_+/\_/g;
			#print OUTFILE "$_\n";

			if ((/^Length=/) && ($onF))
			{
				print "\t\tONF OFF  : $_\n" if ($printFix);
				print "\t\tONF PRINT: $hit\n" if ($printFix);
				$hit =~ s/\s/\_/g;
				$hit =~ s/\_+/\_/g;
				s/\s/\_/g;
				s/\_+/\_/g;
				print OUTFILE "> $hit\n";
				print OUTFILE "$_\n";
				$onF = 0;
				$hit = "";
			}
			elsif (( ! $onF ) && ( ! (/^\>\s*(.+)/)))
			{
				print "\t\tONF NULL: $_\n" if ($printFix);
				s/\_+/\_/g;
				print OUTFILE "$_\n";
			}

			if ($onF)
			{
				print "\t\tONF ADD: $_\n" if ($printFix);
				$hit .= $_;
			}
			elsif (/^\>\s*(.+)/)
			{
				print "\t\tONF: $_\n" if ($printFix);
				$hit = $1;
				$onF = 1;
			}



		}

		if ($onQ)
		{
			print "\t\tONQ ADD: $_\n" if ($printFix);
			$query .= $_;
		}
		elsif (/^Query=\s*(.+)/)
		{
			print "\t\tONQ ON: $_\n" if ($printFix);
			$query = $1;
			$onQ   = 1;
		}
	}
	close INFILE;
	close OUTFILE;
	rename $input, "$input.old";
	rename "$input.tmp", $input;
}

sub save_organism
{
	my %db       = %{$_[0]};
	my $inputFil =   $_[1];
	my $log;

	mkdir "./xml";

	&Log("EXPORTING XML FILE: $outFolder/$inputFil\_org.xml\n");
	my $count = 0;
	my %files;

	open  FILE, ">$outFolder/$inputFil\_org.xml" or die "COULD NOT OPEN $outFolder/$inputFil\_org.xml XML FILE: $!";
	print FILE  "<job id=\"$inputFil\" type=\"blast\" desc=\"$desc\">\n";

	foreach my $org (sort keys %db)
	{
		&Log("CHROMOSSOME $org\n\tSTART\n");
		print FILE "\t<query id=\"$org\" type=\"organism\">\n";
		my $startT = 0;
		foreach my $gene (sort keys %{$db{$org}})
		{
			&Log("\t$gene");
			$startT++;
			$count++;
			my $occur = $db{$org}{$gene};

			my $out  = "\t\t<hits id=\"$gene\" type=\"gene\">\n";
			my $countOcc = 0;

			foreach my $hits (@$occur)
			{
				$countOcc++;
				my $countHsps = 0;
				$out  .= "\t\t\t<hit id=\"$countOcc\">\n";

				foreach my $dataKey (sort {$a <=> $b} keys %$hits)
				{
					$count++;
					$countHsps++;

					$out   .= "\t\t\t\t<hsp id=\"$dataKey\" count=\"$countHsps\">\n";
					$out   .= "\t\t\t\t\t<id>$count</id>\n";
					my $data = $hits->{$dataKey};
					foreach my $qual (sort keys %$data)
					{
						my $value = $data->{$qual};
						$out .= "\t\t\t\t\t<$qual>$value</$qual>\n";

					} #end foreach my qual
					$out .= "\t\t\t\t</hsp>\n";
				} # end foreach my datakey
				$out .= "\t\t\t</hit>\n";
			} # end foreach my hits
			$out .= "\t\t</hits>\n";
			print FILE $out;
		} #end foreach my start
		&Log("\tTOTAL $startT\n\n");
		print FILE "\t</query>\n";
	} #end foreach my chrom
	print FILE "</job>";
	close FILE;

	&Log("EXPORTED $count REGISTERS TO XML FILE\n");

	$count = 0;
	foreach my $key (sort keys %db)
	{
		my $genes = (keys %{$db{$key}});
		&Log("CHROMOSSOME $key HAS $genes GENES MAPPED\n");
	}

} #end sub parse snps




sub save_genes
{
	my $db       = $_[0];
	my $inputFil = $_[1];
	my $log;

	#push(@{$byGene{$gene}{$dbname}}, $data);

	mkdir "./xml";

	&Log("EXPORTING XML FILE: $outFolder/$inputFil\_gene.xml\n");
	&Log("EXPORTING TAB FILE: $outFolder/$inputFil\_gene.tab\n");
	my %files;
	my $count = 0;
	open  FILEX, ">$outFolder/$inputFil\_gene.xml" or die "COULD NOT OPEN $inputFil\_gene.xml XML FILE: $!";
	open  FILET, ">$outFolder/$inputFil\_gene.tab" or die "COULD NOT OPEN $inputFil\_gene.tab XML FILE: $!";
	print FILEX  "<job id=\"$inputFil\" type=\"blast\" desc=\"$desc\">\n";

	my %headerKeys;
	%headerKeys = ( 'queryGene' => 0, 'blastOrg' => 1 );
	my $col = scalar keys %headerKeys;

	foreach my $gene (sort keys %{$db})
	{
		foreach my $org (sort keys %{$db->{$gene}})
		{
			my $occur = $db->{$gene}{$org};
			foreach my $hits (@$occur)
			{
				foreach my $dataKey (sort {$a <=> $b} keys %$hits)
				{
					my $data = $hits->{$dataKey};
					foreach my $qual (sort keys %$data)
					{
						if ( ! exists $headerKeys{$qual} )
						{
							$headerKeys{$qual} = $col++;
						}
					}
				}
			}
		}
	}
	my @headerValues;

	map { $headerValues[$headerKeys{$_}] = $_; } keys %headerKeys;

	print FILET "#INPUT FILE: $inputFil\n";
	print FILET "#DESCRIPTION: $desc\n";
	print FILET "#", join("\t", @headerValues), "\n";

	foreach my $gene (sort keys %{$db})
	{
		&Log("GENE $gene\n\tSTART\n");
		print FILEX "\t<query id=\"$gene\" type=\"gene\">\n";

		my $orgs = $db->{$gene};
		foreach my $org (sort keys %$orgs)
		{
			&Log("\t$org");
			my $countMatches = 0;
			print FILEX "\t\t<hits id=\"$org\" type=\"organism\">\n";
			my $occur = $orgs->{$org};
			foreach my $hits (@$occur)
			{
				$countMatches++;
				my $countHsps = 0;
				print FILEX "\t\t\t<hit id=\"$countMatches\">\n";

				foreach my $dataKey (sort {$a <=> $b} keys %$hits)
				{
					$count++;
					$countHsps++;
					my %colsData = ('queryGene' => $gene, 'blastOrg' => $org);

					my $out = "\t\t\t\t<hsp id=\"$dataKey\" count=\"$countHsps\">\n";
					$out   .= "\t\t\t\t\t<id>$count</id>\n";
					my $data = $hits->{$dataKey};
					foreach my $qual (sort keys %$data)
					{
						my $value = $data->{$qual};
						$out .= "\t\t\t\t\t<$qual>$value</$qual>\n";
						$colsData{$qual} = $value;
					}
					$out .= "\t\t\t\t</hsp>\n";

					for ( my $c = 0 ; $c < @headerValues; $c++ )
					{
						my $colName = $headerValues[$c];
						my $v       = $colsData{$colName};
						if ( ! defined $v ) {$v = ''; };
						#print "COL NUMBER '$c' COL NAME '$colName' VALUE '",substr($v,0,100),"'\n";
						print FILET ($c ? "\t" : ''), $v;
					}

					#print "\n";
					print FILET "\n";
					print FILEX $out;
				} #end foreach my datakey
				print FILEX "\t\t\t</hit>\n";
			} #end foreach my hits
			print FILEX "\t\t</hits>\n";
		} #end foreach my start
		print FILEX "\t</query>\n";
	} #end foreach my chrom
	print FILEX "</job>";
	close FILEX;
	close FILET;

	&Log("EXPORTED $count REGISTERS TO XML FILE\n");

	$count = 0;
	foreach my $key (sort keys %{$db})
	{
		my $genes = (keys %{$db->{$key}});
		&Log("GENE $key HAS $genes ORGS MAPPED\n");
	}

} #end sub parse snps




sub roundFrac
{
	my $number = $_[0];

	$number = sprintf("%03.1f", $number);

	return $number;
}

sub percentage
{
	my $value = $_[0];
	my $total = $_[1];
	my $result;# = sprintf("%.1f", (($value/$total)*100));

	$value    = (($value/$total)*100);

# 	if ($value < 10)
# 	{
# 		$result = sprintf("%.1f", $value);
		$result = sprintf("%05.1f", $value);
# 	}

	return $result;
}


1;
