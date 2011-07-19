#!/usr/bin/perl -w
use strict;
use Bio::SearchIO;

$| = 1;
my $inputFile;
my $printData = 0;

if ($ARGV[0])
{
	if ( -f $ARGV[0] )
	{
		$inputFile = $ARGV[0];
	}
	else
	{
		die "INPUT FILE $ARGV[0] DOESNT EXISTS: ./blast_microarray_xml.pl answer_probex.txt.fasta_cbs7750v4.blast";
	}
}
else
{
	die "PLEASE SPECIFY INPUT FILE ./blast_microarray_xml.pl answer_probex.txt.fasta_cbs7750v4.blast";
}

my $verbose = 1;
my $Log;

if ($verbose) { unlink("blast_microarray_xml.log"); };

my $hypothetical = 0;

my %priority =
(
	"BLASTN"  => 1
);

my %minident =
(
	"BLASTN"  => 95
);

my %minconsv =
(
	"BLASTN"  => 95
);

my %minsig =
(
	"BLASTN"  => 1e-05
);

my %minsize =
(
	"BLASTN"  => 50
);


# $inputFile = "answer_WM276GBFF10_06_R265_c_neoformans_db_tblastx.bls";
# $inputFile = "answer_WM276GBFF10_06_R265_c_neoformans_db_blastn.bls";
# $inputFile = "answer_WM276GBFF10_06_R265_c_neoformans_db_blastn_MIX.bls";
# $inputFile = "answer_WM276GBFF10_06_R265_c_neoformans_db_blastn.bls";
#$inputFile = "answer_MIX_ge2x.csv.fasta_R265_c_neoformans_db_blastn.blast";

&fixBlast($inputFile);

my @answers;
my ($Gtotal, $GtotalG, $Gpositives, $Gblasts, $Gnegatives, $GnoIdent, $GnoSig, $Gshort, $GnoHit, $Gstat);
@answers    = &start($inputFile);
$Gtotal     = $answers[0];
$GtotalG    = $answers[1];
$Gpositives = $answers[2];
$Gblasts    = $answers[3];
$Gnegatives = $answers[4];
$GnoIdent   = $answers[5];
$GnoSig     = $answers[6];
$Gshort     = $answers[7];
$GnoHit     = $answers[8];
$Gstat      = $answers[9];


# &printStat($Gtotal, $GtotalG, $Gpositives, $Gblasts, $Gnegatives, $GnoIdent, $GnoSig, $Gshort, $GnoHit, $Gstat);
#

my $inputShort = substr($inputFile, 0, rindex($inputFile, "."));
   $inputShort = substr($inputFile, rindex($inputFile, "/")+1);
&save_chromossome(&genDB($Gpositives , $Gblasts), $inputFile, $inputShort);
&save_chromossome(&genDB($Gpositives)           , $inputFile, $inputShort."_positive");
&save_chromossome(&genDB($Gblasts)              , $inputFile, $inputShort."_blasts");
&save_chromossome(&genDB($Gnegatives)           , $inputFile, $inputShort."_negatives");

&commitLog();







sub commitLog
{
	open FILE, ">blast_microarray_xml.log" or die "COULD NOT CREATE BLAST_XML.LOG";
	print FILE $Log;
	close FILE;
}


sub Log
{
	if ($verbose)
	{
		print $_[0];
	}
	$Log .= $_[0];
}


sub fixBlast
{
	my $input = $_[0];
	if ( ! ( -f "$input.old" ))
	{
		open INFILE,  "<$input"     or die "COULD NOT OPEN INPUT FILE $input FOR FIXING\n";
		open OUTFILE, ">$input.tmp" or die "COULD NOT OPEN INPUT FILE $input.tmp FOR FIXING\n";

		my $on = 0;
		my $query = "";
		while (<INFILE>)
		{
			chomp;

			if ( $on )
			{
				if (/^Length=\d+$/)
				{
					$query =~ s/\_+/\_/g;
					s/\_+/\_/g;
					print OUTFILE "Query=$query\n";
					print OUTFILE "$_\n";
					$on    = 0;
					$query = "";
				}
				else
				{
					$query .= $_;
				}
			} # end if on
			else
			{
				if (/^Query=\s*\d+\s+(\S+)$/)
				{
					$query = $1;
					$on    = 1;
				}
				elsif (/^Query=\s*(\d+)\s*$/)
				{
					$query = $1;
					$on    = 1;
				}
				elsif (/^Query=\s*(\S+)$/)
				{
					$query = "_";
					$on    = 1;
				}
				else
				{
					#s/\_+/\_/g;
					print OUTFILE "$_\n";
				}
			} # end else on
		}
		close INFILE;
		close OUTFILE;
		rename $input, "$input.old";
		rename "$input.tmp", $input;
	}
}

sub save_chromossome
{
	my $db        = $_[0];
	my $inputFile = $_[1];
	my $title     = $_[2] || "";
	my $name      = $title;
	if ( $title ) { $title .= " :: ";   };
	if ( $name  ) { $name   = "$name"; };
	my $log;

	mkdir "./xml";

	&Log($title."EXPORTING XML FILE: xml/blast_microarray\_$name.xml ". ( scalar keys %$db ) ."\n");
	my $count = 0;
	my %files;


	return 0 if ( ! scalar keys %$db );

	open  FILE, ">xml/blast_microarray\_$name.xml" or die "COULD NOT OPEN blast_microarray\_$name.xml XML FILE: $!";
	open  TAB,  ">xml/blast_microarray\_$name.tab" or die "COULD NOT OPEN blast_microarray\_$name.tab TAB FILE: $!";

	print FILE  "<microarray id=\"$inputFile\" type=\"microarray\">\n";
	print TAB "#sequence\tstrand\tstart\tend\tunique name\tcommom name\tgene type\n";

	foreach my $chrom (sort keys %$db)
	{
		#push(@{$byChrom{$chromR}{$point}}, $data);
		&Log($title."CHROMOSSOME $chrom\n\tSTART\n");
		my $starts = $db->{$chrom};

		print FILE "\t<table id=\"$chrom\" type=\"chromossome\">\n";
		my $startT = 0;
		foreach my $start (sort { $a <=> $b } keys %$starts)
		{
			&Log("\t$start");
			$startT++;
			my $datas = $starts->{$start};

			my $out   = "\t\t<pos id=\"$start\">\n";

			foreach my $data (@$datas)
			{
				#my $startPos = $data->{start};
				$count++;
				$out    .= "\t\t\t<id>$count</id>\n";

				my $strand = $data->{strand} > 0 ? "+" : "-";
				my $end;
				my $fStart;

				if ($strand eq "+")
				{
					$fStart = $data->{start} >= $data->{end} ? $data->{end}   : $data->{start};
					$end    = $data->{start} >= $data->{end} ? $data->{start} : $data->{end};
				}
				else
				{
					$fStart = $data->{start} >= $data->{end} ? $data->{start} : $data->{end};
					$end    = $data->{start} >= $data->{end} ? $data->{end}   : $data->{start};
				}


				my $uName  = $data->{gene} . "." . $chrom . "." . $fStart .  "_" . $end .  "_" . $data->{sign} ;
				my $cName  = $data->{gene};
				my $type   = "rna";
				#print TAB "sequence\tstrand\tstart\tend\tunique name\tcommom name\tgene type\n";
				print TAB "$chrom\t$strand\t$fStart\t$end\t$uName\t$cName\t$type\n";

				foreach my $qual (sort keys %$data)
				{
					if ($qual ne "chromR")
					{
						my $value = $data->{$qual};
						$out .= "\t\t\t<$qual>$value</$qual>\n";
					}
				}
			}
			$out .= "\t\t</pos>\n";
			print FILE $out;
		} #end foreach my start
		&Log("\t".$title."TOTAL POS $startT. TOTAL FEAT $count\n\n");
		print FILE "\t</table>\n";
	} #end foreach my chrom
	print FILE "</microarray>";
	close FILE;
	close TAB;

	&Log($title."EXPORTED $count REGISTERS TO XML FILE\n");

	$count = 0;
	foreach my $key (sort keys %$db)
	{
		my $genes = scalar keys %{$db->{$key}};
		&Log(sprintf($title."CHROMOSSOME %s HAS %06d GENES MAPPED\n", $key, $genes));
	}

} #end sub parse snps


# <root id="NAME" type="[snp|gap|blast]">
#   <table id="NAME" type="[program|chromossome]">
#     <row>
#       <colum> </colum>
#     <row>
#   </table>
# </root>

sub genDB
{
	my @hashes  = @_;
	my %byChrom;
	my $countG = 0;
	my $countU = 0;
	my %genCoun;
	my %faulty;

	print "" . @hashes . " HASHES\n";
	foreach my $hashRef (@hashes)
	{
		my $hash = $hashRef;
		&Log("\t THERE ARE " . (keys %$hash) . " METHODS IN THIS HASH\n");
		foreach my $method (sort keys %priority)
		{
			if ( ! defined %{$hash->{$method}} ) { last;};
			&Log("\t\t THE METHOD $method HAS " . (keys %{$hash->{$method}}) . " GENES\n");
			foreach my $gene (sort keys %{$hash->{$method}})
			{
				my $data           = $hash->{$method}{$gene};
				my $chromR         = $data->{"chromR"};
				my $start          = $data->{"start"};
				my $end            = $data->{"end"};
				my $sign           = $data->{"sign"};
				my $ident          = $data->{"ident"};
				my $consv          = $data->{"consv"};
				my $gaps           = $data->{"gaps"};
				my $strand         = $data->{"strand"};
				#my $prop           = abs(1-($data{"Qrylen"} / $data{"Hlength"}));
				my $size;
				my $point;
				if    ($strand ==  1) { $point = $start; $size = $end   - $start+1; }
				elsif ($strand == -1) { $point = $end;   $size = $start - $end+1; }
				else  { die "NO START POSITION FOUND"};

				   #$data{"method"} = $method;
				   $data->{"gene"}   = $gene;
				   #$data{"size"}   = $size;

					$countU++;
					push(@{$byChrom{$chromR}{$point}}, $data);
					$genCoun{$gene} += 1;
# 					$faulty{$gene}++;
#
# 					my %dataOld   = %{$byChrom{$chromR}{$point}};
# 					my $methodOld =   $dataOld{"method"};
# 					my $endOld    =   $dataOld{"end"};
# 					my $geneOld   =   $dataOld{"gene"};
# 					my $signOld   =   $dataOld{"sign"};
# 					my $identOld  =   $dataOld{"ident"};
# 					my $consvOld  =   $dataOld{"consv"};
# 					my $gapsOld   =   $dataOld{"gaps"};
# 					#my $propOld   = abs(1-($dataOld{"Qrylen"} / $dataOld{"Hlength"}));
# 					my $update    = 0;
#
# 					if ($priority{$method} < $priority{$methodOld})
# 					{
# 						&Log(print "GENE $gene ON $chromR WAS UPDATED\n");
# 						${$byChrom{$chromR}{$point}}[0] = \%data;
# 					}
# 					elsif ($priority{$methodOld} == $priority{$method})
# 					{
# 						my $old = 0; my $new = 0; my $draw = 0;
# 						if ($signOld      < $sign)        { $old +=2; } elsif ($signOld   > $sign)           { $new +=2; } else { $draw++; };
# 						if ($propOld      < $prop)        { $old++;   } elsif ($propOld   > $prop)           { $new++;   } else { $draw++; };
# 						if ($gapsOld      < $gaps)        { $old++;   } elsif ($gapsOld   > $gaps)           { $new++;   } else { $draw++; };
# 						if ($identOld     > $ident)       { $old++;   } elsif ($identOld  < $ident)          { $new++;   } else { $draw++; };
# 						if ($consvOld     > $consv)       { $old++;   } elsif ($consvOld  < $consv)          { $new++;   } else { $draw++; };
#
# 						if ((20*$signOld) <      $sign)   { $old++;   } elsif ((20*$sign) >      $signOld)   { $new++;   };
# 						if (( 2*$propOld) <      $prop)   { $old++;   } elsif (( 2*$prop) >      $propOld)   { $new++;   };
# 						if (    $identOld < (1.1*$ident)) { $old++;   } elsif (   $ident  > (1.1*$identOld)) { $new++;   };
# 						if (    $consvOld < (1.2*$consv)) { $old++;   } elsif (   $consv  > (1.2*$consvOld)) { $new++;   };
#
# 						if ($old == $new)                 { if (int(rand(1))) { $old++; } else { $new++; };  };
#
# 						if ($geneOld eq $gene)
# 						{
# 							&Log("DUPLICATION... FIND OUT WHERE IS IT YOUR LAZY FAT ASS\n");
# 							&Log("\t\t$chromR BY ($methodOld vs $method) STARTING AT $point, ENDING AT $endOld AND $end ($old vs $new vs $draw)\n");
# 							&Log("\t\tSIG\t$signOld\tvs\t$sign\n");
# 							&Log("\t\tIDENT\t$identOld\tvs\t$ident\n");
# 							&Log("\t\tPROP\t$propOld\tvs\t$prop\n");
# 							&Log("\t\tGAPS\t$gapsOld\tvs\t$gaps\n");
# 							&Log("\t\tCONSV\t$consvOld\tvs\t$consv\n");
# 							&Log("\t\t$geneOld\n\t\t$gene\n\n\n");
# 						}
# 						elsif ($new > $old)
# 						{
# # 							print "KEEPING NEW DATA $old vs $new\n";
# # 							print "\t\t$chromR BY ($methodOld vs $method) STARTING AT $point, ENDING AT $endOld AND $end ($old vs $new vs $draw)\n";
# # 							print "\t\tSIG\t$signOld\tvs\t$sign\n";
# # 							print "\t\tIDENT\t$identOld\tvs\t$ident\n";
# # 							print "\t\tPROP\t$propOld\tvs\t$prop\n";
# # 							print "\t\tGAPS\t$gapsOld\tvs\t$gaps\n";
# # 							print "\t\tCONSV\t$consvOld\tvs\t$consv\n";
# # 							print "\t\t$geneOld\n\t\t$gene\n\n\n";
# 							$byChrom{$chromR}{$point} = \%data;
# 						}
# 						elsif  ($old > $new)
# 						{
# # 							print "KEEPING OLD DATA $old vs $new\n";
# # 							print "\t\t$chromR BY ($methodOld vs $method) STARTING AT $point, ENDING AT $endOld AND $end ($old vs $new vs $draw)\n";
# # 							print "\t\tSIG\t$signOld\tvs\t$sign\n";
# # 							print "\t\tIDENT\t$identOld\tvs\t$ident\n";
# # 							print "\t\tPROP\t$propOld\tvs\t$prop\n";
# # 							print "\t\tGAPS\t$gapsOld\tvs\t$gaps\n";
# # 							print "\t\tCONSV\t$consvOld\tvs\t$consv\n";
# # 							print "\t\t$geneOld\n\t\t$gene\n\n\n";
# 						}
# 						else
# 						{
# 							&Log("SOMETHING CRAZY HAS HAPPENED: TWO GENES MAPPED TO THE SAME PLACE BY THE SAME METHOD HAVING EVERYTHING EQUAL\n");
# 							&Log("\t\t$chromR BY ($methodOld vs $method) STARTING AT $point, ENDING AT $endOld AND $end ($old vs $new vs $draw)\n");
# 							&Log("\t\tSIG\t$signOld\tvs\t$sign\n");
# 							&Log("\t\tIDENT\t$identOld\tvs\t$ident\n");
# 							&Log("\t\tPROP\t$propOld\tvs\t$prop\n");
# 							&Log("\t\tGAPS\t$gapsOld\tvs\t$gaps\n");
# 							&Log("\t\tCONSV\t$consvOld\tvs\t$consv\n");
# 							&Log("\t\t$geneOld\n\t\t$gene\n\n\n");
# 							$byChrom{$chromR}{$point} = \%data;
# 						} # end if ($new > $old)
# 					} # end if ($priority{$method} < $priority{$methodOld})
				#} # end if ( defined @{$byChrom{$chromR}{$point}} )
				$countG++;
			} # end foreach my $gene (sort keys %{$hash{$method}})
		} # end foreach my $method (sort keys %hash)
	} # end foreach my $hashRef (@hashes)

	&Log("$countG GENES OF INPUT BEING $countU UNIQUES\n");
	return (\%byChrom);
}


sub getChar
{
	my $method     = $_[0];
	my $query_name = $_[1];
	my $valid      = $_[2];
	my $data = ();

	if (exists $Gpositives->{$method}{$query_name})    { $data = $Gpositives->{$method}{$query_name}; }
	elsif (exists $Gblasts->{$method}{$query_name})	   { $data = $Gblasts->{$method}{$query_name};    }
	elsif (exists $Gnegatives->{$method}{$query_name}) { $data = $Gnegatives->{$method}{$query_name}; }
	else
	{
# 		%data = %{$Gnegatives{$method}{$query_name}};
# 		print "*"x20 . "\nTHERE'S NO DATA FOR $query_name IN METHOD $method\n" . "*"x20 . "\n";
	}

	return $data;
}


sub start
{
	my $inputFile = $_[0];
	if ( -f $inputFile ) { &Log("LOADING FILE $inputFile\n"); } else { die "COULD NOT OPEN $inputFile: $!"};
	my $in = new Bio::SearchIO(	-format => 'blast',
								-file   => $inputFile);
	$| =0;
	my %positives = ();
	my %blasts    = ();
	my %negatives = ();
	my %noIdent   = ();
	my %noSig     = ();
	my %short     = ();
	my %noHit     = ();
	my %stat      = ();

	my $Positives = 0;
	my $Negatives = 0;
	my $Blasts    = 0;
	my $NoHits    = 0;

	my $total     = 0;
	my $totalG    = 0;
# 	my %totalG;
# 	my %POSG;
# 	my %NEGG;
# 	my %NOHITG;

	while( my $result = $in->next_result )
	{
	# 	print "METHOD " . $result->algorithm . "\n";
		my $method   = $result->algorithm;
		my $minSize  = $minsize{$method};
		my $minSig   = $minsig{$method};
		my $minIdent = $minident{$method};
		my $minConsv = $minconsv{$method};

# 		print ".";
		#print	"Query Name   = " . $qryName   . "\n";
		#print	"Query Length = " . $result->query_length . "\n";
		my $num_hits = $result->num_hits;
		my $qryName  = $result->query_name;
		#print	"Query Hits   = " . $result->num_hits     . "\n";
		my $hitC = 0;

		$totalG++;
# 		$totalG{$qryName}++;

		if ( $result->num_hits )
		{
			while( my $hit = $result->next_hit )
			{
				$hitC++;
				my $hspC = 0;
				my $name = $hit->name; $name =~ s/lcl\|//;
				my $sign = $hit->significance;
				#print "\tHit # $hitC/$num_hits   = " . $hit->name      . "\n",
				#      "\tHit Significance = " . $hit->significance     . "\n",
				#      "\tHit hsps         = " . $hit->num_hsps         . "\n";
				while( my $hsp = $hit->next_hsp )
				{
					my %bData;
					$bData{"ident"}   = &roundFrac($hsp->frac_conserved *100);
					$bData{"consv"}   = &roundFrac($hsp->frac_identical *100);
					$bData{"sign"}    = $sign;
					$bData{"Hlength"} = $hsp->length('hit');
					$bData{"Qlength"} = $hsp->length('query');
					$bData{"Tlength"} = $hsp->length('total');
					$bData{"Qrylen"}  = $result->query_length;
					$bData{"start"}   = $hsp->start('hit');
					$bData{"end"}     = $hsp->end('hit');
					$bData{"strand"}  = $hsp->strand('hit');
					$bData{"chromR"}  = $name;
					$bData{"gaps"}    = $hsp->gaps;

					#GE_CneoSBc1_1_6000_s_RC-60-4317
					if ($qryName =~ /(\d+)_(.+)_FOLDS_(.+)/)
					{
						#print "QRY NAME :: CLASS 01 : FOLDS : $qryName \n";
						#114236_GE_CneoSBc1_1_6000_s_RC-60-1988_FOLDS_-2.49
						$bData{"spotId"}  = $2; # GE_CneoSBc1_1_6000_s_RC-60-1988
						$bData{"expLev"}  = $3; # -2.49
						$bData{"spotPos"} = $1; # 114236
					}
					elsif ($qryName =~ /(\d+)(.+?)\|DIFF\:(.+?)\|/)
					{
						#print "QRY NAME :: CLASS 011 : DIFF : $qryName \n";
						#750GE_CneoSBc8_636001_642000_s_RC-60-3267|DIFF:-1.86|R265:0.92|CBS7750:-0.94|WM276:-0.53|CORR:0.82|ANNO:
						#print "SPOT $2 POS $1\n";
						$bData{"spotId"}  = $2; # GE_CneoSBc8_636001_642000_s_RC-60-3267
						$bData{"spotPos"} = $1; # 750
						#$bData{"diff"}    = $3; # -1.86

						my @nfo = split(/\|/, $qryName);
						foreach my $nfo (@nfo)
						{
							#print "\tNFO $nfo\n";
							my ($k, $v) = split(":", $nfo);
							next if ((! defined $k) || (! defined $v));
							#print "\t\tK $k V $v\n";
							$bData{$k} = $v; # -1.86
						}

						#print  "\n\tQRY NAME :: $qryName\n";
						#my $latestPos = 0;
						#while ( $qryName =~ /\|(\S+?)\:(.+?)\|/xg )
						#{
						#	my $nfo = $1;
						#	my $dat = $2;
						#	$bData{$nfo} = $dat; # -1.86
						#	print "\t\tNFO $nfo DAT $dat POS ",pos($qryName),"\n";
						#	pos($qryName) = pos($qryName) - 1;
						#	$latestPos = pos($qryName);
						#}
						#print "LATEST $latestPos\n";
						#pos($qryName) = $latestPos;
						#if ($qryName =~ /\|(\S+?)(.+?)$/)
						#{
						#	my $nfo = $1;
						#	my $dat = $2;
						#	$bData{$nfo} = $dat; # -1.86
						#	print "\t\tNFO $nfo DAT $dat POS ",pos($qryName),"\n";
						#	$bData{$1} = $2;
						#}
					}
					elsif ($qryName =~ /(\d+)_(.+)_CORR_(.+)/)
					{
						#print "QRY NAME :: CLASS 02 : CORR : $qryName\n";
						#114236_GE_CneoSBc1_1_6000_s_RC-60-1988_CORR_-2.49
						$bData{"spotId"}      = $2; # GE_CneoSBc1_1_6000_s_RC-60-1988
						$bData{"correlation"} = $3; # -2.49
						$bData{"spotPos"}     = $1; # 114236
					}
					elsif ($qryName =~ /(\d+)_(\D{1,}_.+)/)
					{
						#print "QRY NAME :: CLASS 03 : d_D_. : $qryName \n";
						#1_GE_CneoSBc12_624001_630000_s_PSO-60-1621
						$bData{"spotId"}      = $2; # GE_CneoSBc12_624001_630000_s_PSO-60-1621
						$bData{"correlation"} = 0;
						$bData{"spotPos"}     = $1; # 1
					}
					elsif ($qryName =~ /(\d+)_(\d+)_(.+)/)
					{
						#print "QRY NAME :: CLASS 04 : d_d_. : $qryName \n";
						#1 1_149_GE_CneoSBc7_1068001_1074000_s_RC-60-1329
						$bData{"spotId"}      = $3; # GE_CneoSBc7_1068001_1074000_s_RC-60-1329
						$bData{"correlation"} = 0;
						$bData{"spotPos"}     = "$1\_$2"; # 1 149
					}
					else
					{
						#die "COULD NOT EXTRACT ARRAY INFORMATION";
					}


					$hspC++;
					if (( $hsp->length('total') >= $minSize ) || ($hsp->length('hit') >= $minSize))
					{
						if (( $hsp->percent_identity >= ($minIdent/100) ) && ($hsp->frac_conserved >= ($minConsv/100) ))
						{
							if ( $hit->significance <= $minSig )
							{
								#if (($hsp->rank >= 1) && ($hspC >= 1) && ($hitC >= 1))
								#{
									$stat{$method}{$hsp->evalue}++; $total++;
									#if (($result->num_hits >= 1) && ($hit->num_hsps >= 1))
									#{
 										$positives{$method}{$qryName} = \%bData;
										&printData("POSITIVE", \%bData);
# 										$Positives++;
# 										$POSG{$result->query_name}++;
									#}
									#else
									#{
## 										print ".";
										#$bData{"ERROR"}   = "num_hits GT 1 (" . $result->num_hits . ") || num_hsps GT 1 (" . $hit->num_hsps . ")";
										#$blasts{$method}{$qryName} = \%bData;
										#&printData("BLAST1", \%bData);
## 										$Blasts++;
## 										$POSG{$qryName}++;
									#}
								#}
								#else
								#{
								#	$bData{"ERROR"}   = "rank GT 1 (" . $hsp->rank . ") || hsp_CountGT 1 (" . $hspC . ") || hit_count GT 1(" . $hitC . ")";
								#	$blasts{$method}{$qryName}   = \%bData;
								#	&printData("BLAST2", \%bData);
								#};

							#       print	"\t\tHsp Length       = " . $hsp->length('total')  . "\n",
							# 		"\t\tHsp Percent_id   = " . $hsp->percent_identity . "\n",
							# 		"\t\tHsp e-value      = " . $hsp->evalue           . "\n",
							# 		"\t\tHsp Frac_Identic = " . $hsp->frac_identical   . "\n",
							# 		"\t\tHsp Frac_conserv = " . $hsp->frac_conserved   . "\n",
							# 		"\t\tHsp Rank         = " . $hsp->rank             . "\n",
							# 		"\t\tHsp Gaps         = " . $hsp->gaps             . "\n",
							# 		"\t\tHsp Range      @ = " . join ("\t", $hsp->range('hit'))     . "\n",
							#
							# 		"\t\tHsp Query Strand = " . $hsp->strand('query')  . "\n",
							# 		"\t\tHsp Query Start  = " . $hsp->start('query')   . "\n",
							# 		"\t\tHsp Query End    = " . $hsp->end('query')     . "\n",
							# 		"\t\tHsp Query Length = " . $hsp->length('query')  . "\n",
							# # 		"\t\tHsp Query String = " . $hsp->query_string 	   . "\n",
							#
							# 		"\t\tHsp Hit Strand   = " . $hsp->strand('hit')    . "\n",
							# 		"\t\tHsp Hit Start    = " . $hsp->start('hit')     . "\n",
							# 		"\t\tHsp Hit End      = " . $hsp->end('hit')       . "\n",
							# 		"\t\tHsp Hit Length   = " . $hsp->length('hit')    . "\n",
							# # 		"\t\tHsp Hit String   = " . $hsp->hit_string       . "\n",
							# # 		"\t\tHsp Homology Str = " . $hsp->homology_string  . "\n",
									;
							} # end if sig > 1e-20
							else
							{
								if (($hsp->rank == 1) && ($hspC == 1) && ($hitC == 1))
								{
# 									print ",";
									$noSig{$method}{$qryName}++;
									$bData{"ERROR"}   = "significance LT $minSig (" . $hit->significance .")";
									$negatives{$method}{$qryName}   = \%bData;
									&printData("NEGATIVE1", \%bData);
									#$Negatives++;
# 									$NEGG{$qryName}++;
								};
							};
						} # end if ident < 80
						else
						{
							if (($hsp->rank == 1) && ($hspC == 1) && ($hitC == 1))
							{
# 								print ",";
								$noIdent{$method}{$qryName}++;
								$bData{"ERROR"}   = "identity LT $minIdent (" . &roundFrac($hsp->frac_identical *100) . ") || consv  $minConsv (" . &roundFrac($hsp->frac_conserved *100) . ")";
								$negatives{$method}{$qryName} =  \%bData;
								&printData("NEGATIVE2", \%bData);
# 								$Negatives++;
# 								$NEGG{$qryName}++;
							};
						};
					} # end if length < 50
					else
					{
						if (($hsp->rank == 1) && ($hspC == 1) && ($hitC == 1))
						{
# 							print ",";
							$short{$method}{$qryName}++;
							$bData{"ERROR"}   = "length LT $minSize (" . $hsp->length('total') . "/" . $hsp->length('hit') . ")";
							$negatives{$method}{$qryName}   = \%bData;
							&printData("NEGATIVE3", \%bData);
# 							$Negatives++;
# 							$NEGG{$qryName}++;
						}; # end if hsp rank == 1 hspc == 1 hitc == 1
					}; # end else if length < 50
				}; # end while hsp
			}; # end while result
		} # end if hits
		else
		{
# 			print " ";
			$noHit{$method}{$qryName}++;
			&printData("NOHIT", ());
# 			$NoHits++;
# 			$NOHITG{$qryName}++;
		};
	}; # end if $result->num_hits

	$totalG = ($totalG/((keys %stat)+0.00001));
# 	foreach my $name (keys %POSG)
# 	{
# 		if ($POSG{$name} > 1)
# 		{
# 			print "*"x20 . "\n$name IS DUPLICATED ON POSITIVE\n" . "*"x20;
# 		}
# 	}
#
# 	foreach my $name (keys %NEGG)
# 	{
# 		if ($NEGG{$name} > 1)
# 		{
# 			print "*"x20 . "\n$name IS DUPLICATED ON NEGATIVE\n" . "*"x20;
# 		}
# 	}
#
# 	foreach my $name (keys %NOHITG)
# 	{
# 		if ($NOHITG{$name} > 1)
# 		{
# 			print "*"x20 . "\n$name IS DUPLICATED ON NO HIT\n" . "*"x20;
# 		}
# 	}

# 	my $dv  = $Positives+$Blasts+$Negatives+$NoHits;
# 	my $dv2 = (keys %totalG);
# 	my $dv3 = (keys %POSG);
# 	my $dv4 = (keys %NEGG);
# 	my $dv5 = (keys %NOHITG);
# 	print "POS $Positives + BLAST $Blasts = " . ($Positives+$Blasts) . " ($dv3)\n";
# 	print "NEG $Negatives + NOHIT $NoHits = " . ($Negatives+$NoHits) . " ($dv4 | $dv5)\n";
# 	print "VALID " . ($Positives+$Blasts) . " + INVALID " . ($Negatives+$NoHits) . " = $dv\n";
# 	print "TOTAL $totalG (DV1 $dv | DV2 $dv2)\n";
	$| =1;
	&Log("$inputFile LOADED\n");
	return ($total, $totalG, \%positives, \%blasts, \%negatives, \%noIdent, \%noSig, \%short, \%noHit, \%stat)
}


sub printData
{
	my $name = $_[0];
	my $hash = $_[1];

	if ( $printData )
	{
		foreach my $key ( sort keys %$hash )
		{
			my $value = $hash->{$key};
			print "\t$name :: $key : $value\n";
		}
		print "\n";
	}
}


sub printStat
{
	my $total     =   $_[0];
	my $totalG    =   $_[1];
	my %positives = %{$_[2]};
	my %blasts    = %{$_[3]};
	my %negatives = %{$_[4]};
	my %noIdent   = %{$_[5]};
	my %noSig     = %{$_[6]};
	my %short     = %{$_[7]};
	my %noHit     = %{$_[8]};
	my %stat      = %{$_[9]};

	foreach my $method (sort {$a cmp $b} keys %stat)
	{
		my $minSize  = $minsize{$method};
		my $minSig   = $minsig{$method};
		my $minIdent = $minident{$method};
		my $minConsv = $minconsv{$method};
		my @resume;
		my $total2;

		foreach my $key (sort {$a <=> $b} keys %{$stat{$method}})
		{
			if ($key == 0.0)
			{
				$resume[0] += $stat{$method}{$key};
				$total2    += $stat{$method}{$key};
			}
			elsif (($key > 0) && ($key <= 1e-100))
			{
				$resume[1] += $stat{$method}{$key};
				$total2    += $stat{$method}{$key};
			}
			elsif (($key > 1e-100) && ($key <= 1e-50))
			{
				$resume[2] += $stat{$method}{$key};
				$total2    += $stat{$method}{$key};
			}
			elsif (($key > 1e-50) && ($key <= $minSig))
			{
				$resume[3] += $stat{$method}{$key};
				$total2    += $stat{$method}{$key};
			}
			else
			{
				die "ERROR COUNTING";
			}
		} # end foreach my key
		my $cum;
		my $cumP;
		if ($total && $total2)
		{
			my $noSig     = (keys %{$noSig{$method}});
			my $noIdent   = (keys %{$noIdent{$method}});
			my $short     = (keys %{$short{$method}});
			my $noHit     = (keys %{$noHit{$method}});
			my $positives = (keys %{$positives{$method}});
			my $blasts    = (keys %{$blasts{$method}});
			my $negatives = (keys %{$negatives{$method}});

			my $invalid   = $noSig+$noIdent+$short+$noHit;
			if ($invalid != ($totalG-$total2))   { die "INVALIDS ($invalid) IS DIFFERENT FROM THE SUBTRATION OF TOTAL ($totalG) MINUS IDENTIFIED ($total2)." };
			if ($invalid != ($negatives+$noHit)) { die "INVALIDS ($invalid) IS DIFFERENT FROM NEGATIVES ($negatives) PLUS NOHITS ($noHit) [" . ($negatives + $noHit) . "]." };

			&Log("FILENAME         : $inputFile\n");
			&Log("METHOD           : $method\n");
			&Log("TOTAL GLOBAL     : $totalG\n");
			&Log("TOTAL INDENTIFIED: $total2"    . "\t( "       . &percentage($total2   ,$totalG) . "% )\n");
			&Log("   UNIQUES       : $positives" . "\t( "       . &percentage($positives,$totalG) . "% )\n");
			&Log("   MULTI RESULTS : $blasts"    . "\t( "       . &percentage($blasts   ,$totalG) . "% )\n");
			&Log("INVALIDS         : $invalid"   . "\t( "       . &percentage($invalid  ,$totalG) . "% )\n");
			&Log("   NEGATIVES     : $negatives" . "\t( "       . &percentage($negatives,$totalG) . "% )\n");
			&Log("   NO HITS       : $noHit"     . "\t( "       . &percentage($noHit    ,$totalG) . "% )\n");

			&Log("\nRESUME \n");
			$cum += $resume[0];

			&Log("   VALIDS  $total2  ("                        . &percentage($total2,$totalG)    . "%)\n"); $cum += $noSig;
			&Log("      E-VALUE == 0.0             : "          . $resume[0]                      . "\t( "  . &percentage($resume[0],$totalG) . "% CUM $cum [ "  . &percentage($cum,$totalG). "%] )\n"); $cum += $resume[1];
			&Log("      0.0     < E-VALUE <= 1e-100: "          . $resume[1]                      . "\t( "  . &percentage($resume[1],$totalG) . "% CUM $cum [ "  . &percentage($cum,$totalG). "%] )\n"); $cum += $resume[2];
			&Log("      1e-100  < E-VALUE <= 1e-50 : "          . $resume[2]                      . "\t( "  . &percentage($resume[2],$totalG) . "% CUM $cum [ "  . &percentage($cum,$totalG). "%] )\n"); $cum += $resume[3];
			&Log("      1e-50   < E-VALUE <= $minSig : "        . $resume[3]                      . "\t( "  . &percentage($resume[3],$totalG) . "% CUM $cum [ "  . &percentage($cum,$totalG). "%] )\n");
			&Log("\n");
			&Log("   INVALIDS  $invalid  ("                     . &percentage($invalid,$totalG)   . "%)\n"); $cum += $noSig;
			&Log("      E-VALUE  > " . $minSig       . "\t\t: " . $noSig                          . "\t( "  . &percentage($noSig  ,$totalG)   . "% CUM $cum [ " . &percentage($cum,$totalG) . "%] )\n"); $cum += $noIdent;
			&Log("      ID < $minIdent% & SIM < $minConsv%\t: " . $noIdent                        . "\t( "  . &percentage($noIdent,$totalG)   . "% CUM $cum [ " . &percentage($cum,$totalG) . "%] )\n"); $cum += $short;
			&Log("      LENGTH   < " . $minSize      . "\t\t: " . $short                          . "\t( "  . &percentage($short  ,$totalG)   . "% CUM $cum [ " . &percentage($cum,$totalG) . "%] )\n"); $cum += $noHit;
			&Log("      NO HIT   \t" .   ""          . "\t\t: " . $noHit                          . "\t( "  . &percentage($noHit  ,$totalG)   . "% CUM $cum [ " . &percentage($cum,$totalG) . "%] )\n");

			&Log("\n\n" . "-"x50 . "\n\n");
			&Log("E-VALUE  > "         . "$minSig  \t("         . (keys %{$noSig{$method}})       . ")    \t:\n"); &printHash(\%noSig,  $method);
			&Log("ID < $minIdent% & SIM < $minConsv\t("         . (keys %{$noIdent{$method}})     . ")" ."\t:\n"); &printHash(\%noIdent,$method);
			&Log("LENGTH   < "         . "$minSize \t("         . (keys %{$short{$method}})       . ")    \t:\n"); &printHash(\%short,  $method);
			&Log("NO HIT   \t(" .  ""                           . (keys %{$noHit{$method}})       . ")    \t:\n"); &printHash(\%noHit,  $method);
			&Log("\n\n" . "="x50 . "\n\n");
		}
		else
		{
			&Log("COULD NOT RETRIEVE RESULTS\n\n");
		}
	} # end foreach my method

	&printHashSumary(\%noSig,\%noIdent,\%short,\%noHit);
}


sub getSumaryStr
{
	my @hashes  = @_;
	my %sumary;
	my %methodC;
	foreach my $hashRef (@hashes)
	{
		my %hash = %{$hashRef};
		foreach my $method (sort keys %hash)
		{
			foreach my $gene (sort keys %{$hash{$method}})
			{
				my $data  = &getCharStr($method,$gene);
				if (! $data ) {die "NO DATA RETRIEVED"; };
				my $value      = $hash{$method}{$gene};
				$sumary{$gene}{"count"} += 1;
				push(@{$sumary{$gene}{"char"}}, $data);
				$methodC{$method}++;
			}
		}
	}
	return (\%sumary, \%methodC);
}

sub printHashSumary
{
	my @result  = &getSumaryStr(@_);
	my %sumary  = %{$result[0]};
	my %methodC = %{$result[1]};
	my %stat;

	if ((keys %methodC) > 1)
	{
		&Log("\n\n" . "#"x50 . "\n" . "#"x50 . "\n" . "#"x50 . "\n");
		&Log("NOT IDENTIFIED GENES : \n");
		&Log("\n\n" . "#"x50 . "\n" . "#"x50 . "\n" . "#"x50 . "\n");
		my $countRec  = 0;
		my $countLost = 0;

		my $outRec  = "";
		my $outLost = "";

		foreach my $gene (sort keys %sumary)
		{
			my $value =   $sumary{$gene}{"count"};
			my @data  = @{$sumary{$gene}{"char"}};
			my $valid = 1;

			if ( ( ! $hypothetical ) && ( $gene =~ /hypothetical.protein/sig ) && ( ! ($gene =~ /conserved/sig ) ) ) { $valid = 0; };

			if    ($value == 1) # found in only one of the lists, so, was a match in the other
			{
				my $data  = $data[0];
				$countRec++;
				if ($valid) { $outRec  .= "\t$countRec\t$data\t$gene\n"};
				$stat{"rec"}++;
			}
			elsif ($value > 1) # found in both lists, so was a mismatch every time
			{
				$countLost++;
				$outLost .= "\t$countLost" if ($valid);
				my $second = 0;
				foreach my $data (@data)
				{
					if ($valid)
					{
						if ($second++) { $outLost .= "\t"; };
						$outLost .= "\t$data\t$gene\n";
					}
				}
				$stat{"lost"}++;
			}
		}

		my $total = $countRec+$countLost;

		&Log(
		"XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX\n",
		"X              LOST             X\n",
		"X===============================X\n",
		"X    LOST      BEFORE  AFTER    X\n");
			foreach my $prog (keys %methodC)
			{
				my $value = $methodC{$prog};
				&Log("X    $prog\t$value\t$countLost\tX\n");
			}
		&Log(
		"X===============================X\n",
		"X           RECOVERED           X\n",
		"X===============================X\n",
		"X    LOST              AFTER    X\n");
			foreach my $prog (keys %methodC)
			{
				my $value = $methodC{$prog};
				my $minus = $value - $countLost;
				&Log("X    $prog\t\t$minus\tX\n");
			}
		&Log(
		"X===============================X\n",
		"X             TOTAL             X\n",
		"X===============================X\n",
		"X    LOST	    	$countLost\tX\n",
		"X    RECOVERED	    	$countRec\tX\n",
		"X    TOTAL	    	$total\tX\n",
		"XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX\n");


		&Log("\n\tTOTAL $total\n");
		&Log("\tRECUPERED $countRec\n");
		&Log("\tCOUNT\tMETHOD\tHITS\tIDENT\tCONSV\tSIGN\tHLENGTH\tQLENGTH\tTLENGTH\tSTART\tEND\tSTRAND\tNAME\n");
		&Log($outRec);
		&Log("\n" . "-"x50 . "\n");
		&Log("\n\tLOST $countLost\n");
		&Log("\tCOUNT\tMETHOD\tHITS\tIDENT\tCONSV\tSIGN\tHLENGTH\tQLENGTH\tTLENGTH\tSTART\tEND\tSTRAND\tNAME\n");
		&Log($outLost);
		&Log("\n\n");
	} #end if keys methodC > 1
}



sub printHash
{
	my %hash   = %{$_[0]};
	my $method = $_[1];
	my @methods;

	if (defined $method) { $methods[0] = $method; } else { @methods = (keys %hash); };

	my $count = 1;

	&Log("\tCOUNT\tMETHOD\tHITS\tIDENT\tCONSV\tSIGN\tHLENGTH\tQLENGTH\tTLENGTH\tSTART\tEND\tSTRAND\tNAME\n");
	foreach my $method (sort @methods)
	{
		foreach my $name (sort keys %{$hash{$method}})
		{
			my $valid = 1;
			my $value = $hash{$method}{$name};
			my $data  = &getCharStr($method,$name);

			if ( ( ! $hypothetical ) && ( $name =~ /hypothetical.protein/sig ) && ( ! ( $name =~ /conserved/sig ) ) ) { $valid = 0; };

			if ($value == 1)
			{
				if ($valid) { &Log("\t" . $count++ . "\t$data\t$name\n") };
			}
			elsif ($value >= 2)
			{
				if ($valid) { &Log("\t" . $count++ . "\t$data\t$name\n") };
			}
			else
			{
				&Log("GENE $name SHOUDNT BE HERE\n");
			}
		}
	}
}


sub getCharStr
{
	my $method      = $_[0];
	my $query_name  = $_[1];
	my $result;
	my $colums = 10;

	my $data = &getChar($method,$query_name);

	if (defined $data)
	{
		my $ident = $data->{"ident"};
		my $consv = $data->{"consv"};
		$result = "$method\t" . $data->{"hits"} . "\t" . $ident . "\t" . $consv . "\t" . $data->{"sign"} . "\t" . $data->{"Hlength"} . "\t" . $data->{"Qlength"} . "\t" . $data->{"Tlength"} . "\t" . $data->{"start"} . "\t" . $data->{"end"} . "\t" . $data->{"strand"};
	}
	else
	{
		$result = "\t"x$colums;
	}

	return $result;
}

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
