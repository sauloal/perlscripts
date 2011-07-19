#!/usr/bin/perl -w
use strict;
use warnings;
use MIME::Base64;
use Bio::Graphics;
use Bio::SeqFeature::Generic;
use Bio::SearchIO;
use Data::Dumper;
use GD::Graph::bars;
use GD::Image;
use List::Util qw(max);


#TODO
# reformat to use id instead of start position
# export short positive
# reformat to use vector

my $side       = 40;
my $makeShort  = 1;
my $makeLong   = 1;
my $makeNew    = 0;
my $makeResume = 1;
my $makeGene   = 1;
my $verbose    = 0;

# PRINTS XML FILES CONTAINING SNPS IN HTML FILES WITH EMBEDED IMAGES
# INPUTS: XML FILE NAME
#         FASTA ORIGNAL GENOME FILE NAME

my $inputFA   = $ARGV[0];
my $inputPos  = $ARGV[1];
my $inputStat = $ARGV[2];

my $outputHTML; # output HTML file
my $outputFA;   # output FASTA file
my $rootType;   # type of the root  XML class
my $tableType;  # type of the table XML class
my @XMLpos;     # information from XMLs organized by position
my @XMLtemp;	# tempXML
my @seq;	    # temp sequence
my @gen;	    # temp gen
my %chromos;    # NAME > NUMBER
my %chromosMap; # NAME > LINE
my @stat;       # CHROM NUM > STATISTICS
my %blastKey;   # gene id > gene name
my %blastKeyRev;
my @geneArray;  # chrom num > start pos > gene id

my %microKey;   # gene id > gene name
my %microKeyRev;
my @microArray;  # chrom num > start pos > gene id

my @image;	    # images HTML code
my @gene;       # current gene nucleotides
my $geneName  = ""; # current gene name
my $registre  = 0;
my $statistic = 0; # print statistics or not


if (($inputFA) && ($inputPos)) #checks if all parameters are set
{
	if (( -f $inputFA ) && ( -f $inputPos ))
	{
		my $output;
		if ( ! $inputFA =~ /\/*([\w|\.]+)\.fasta/)
		{
			die "COULD NOT RETRIEVE THE NAME FROM $inputFA";
		}
		elsif ( $inputFA =~ /\/*([\w|\.]+)\.fasta/)
		{
			$output = $1;
		}
		else
		{
			print "INVALID FASTA FILE $inputFA";
			print "USAGE: XML_IMAGE.PL <INPUT FASTA.FASTA> <MULTIPLE INPUT XML or INPUT DIR, SNP or GAP>\n";
			print "E.G.: ./xml_image.pl input.fasta XMLpos/XMLpos.xml XMLpos/XMLstat.xml\n";
			print "E.G.: ./xml_image.pl input.fasta XMLpos/XMLpos_supercontig_1.25_of_Cryptococcus_neoformans_Serotype_B.xml XMLpos/XMLstat.xml\n";
			exit 1;
		}
	
		$outputHTML  = "html/$output.html";
		$outputFA    = "fasta/$output.fasta";
	
		print "  INPUT  FASTA: $inputFA\n";
		print "  INPUT  XML  : $inputPos\n";
		print "  OUTPUT HTML : $outputHTML\n";
		print "  OUTPUT FASTA: $outputFA\n";
		print "\n";
		mkdir "html";
		mkdir "fasta";

		&start($inputFA,$output);

	} # end if file INPUTFA exists
	else
	{
		my $exit;
		if ( ! -f $inputFA )					{ $exit .= "FILE $inputFA   DOESNT EXISTS\n";};
		if ( ! -f $inputPos )					{ $exit .= "FILE $inputPos  DOESNT EXISTS\n";};
		if (( defined $inputStat ) && ( ! -f $inputStat))	{ $exit .= "FILE $inputStat DOESNT EXISTS\n";};
		print $exit;
		exit 1; 
	} # end else file INPUTFA exists
} # end if FA & XML were defined
else
{
	print "USAGE: XML_IMAGE.PL <INPUT FASTA.FASTA> <MULTIPLE INPUT XML or INPUT DIR, SNP or GAP>\n";
	print "E.G.: ./xml_image.pl input.fasta XMLpos/XMLpos.xml XMLpos/XMLstat.xml\n";
	print "E.G.: ./xml_image.pl input.fasta XMLpos/XMLpos_supercontig_1.25_of_Cryptococcus_neoformans_Serotype_B.xml XMLpos/XMLstat.xml\n";
	exit 1;
}


sub start
{
    my $inputFA = $_[0];
    my $output  = $_[1];

    print "  GENERATING CHROMOSSOMES TABLE...";
    &genChromos($inputFA);
    print "done\n";

	print "LOADING POSITIONAL XML...";
	&loadXML($inputPos); #obtains the xml as hash
	print "done\n";


    if ( defined $inputStat )
    {
      print "LOADING STATISTICS XML...";
      &loadXML($inputStat); #obtains the xml as hash
      &fixStat();
      $statistic = 1;
      print "done\n";
    }
    
    print "  GENERATING GENE ARRAY...";
    &genGeneArray();
    print "done\n";

    print "  GENERATING MICROARRAY ARRAY...";
    &genMicroArray();
    print "done\n";

    print "  GENERATING EXPRESSION LEVELS...";
    &genExpressionLevels();
    print "done\n";

	if ($verbose)
	{
		foreach my $chromo (sort keys %chromos)
		{
			print "CHROMO $chromo VALUE " . $chromos{$chromo} . "\n";
		}

		foreach my $map (sort keys %chromosMap)
		{
			print "MAP $map VALUE " . $chromosMap{$map} . "\n";
		}

		for (my $table = 0; $table < @XMLpos; $table++)
		{
			next if ( ! defined $XMLpos[$table] );
			for (my $register = 0; $register < @{$XMLpos[$table]} ; $register++)
			{
				next if ( ! defined $XMLpos[$table][$register] );
				foreach my $key  (keys %{$XMLpos[$table][$register]})
				{
		# 		if (defined $XMLpos{$table}{$register}{"gene"})
		# 		{
					print "TABLE $table REGISTER $register KEY $key VALUE " . $XMLpos[$table][$register]{$key} . "\n";
		# 		}
				}
			}
		}


		for (my $table = 0; $table < @geneArray; $table++)
		{
			if (defined $geneArray[$table])
			{
			for (my $pos = 0; $pos < @{$geneArray[$table]}; $pos++)
			{
				my $register   = $geneArray[$table][$pos];
				my $coValue;
				if ( ! $register ) { $register = "undef"; $coValue = "undef"; }
				else { $coValue = $blastKey{$register} };
				print "TABLE $table POS $pos REGISTER $register NAME $coValue\n";
			}
			}
		}
	}


    $outputHTML  = "html/$output.html";
    $outputFA    = "fasta/$output.fasta";

    &print_fasta_general(\@XMLpos, $inputFA); #prints fasta (text mode)
}


sub genExpressionLevels
{
	my $counter    = 0;
	my $counterIn  = 0;
	my $counterOut = 0;

	open EXPCSV1, ">EXPRESSION_LEVELS_1_GENE_ID.csv"             or die "COULD NOT SAVE EXPRESSION_LEVELS_1.CSV";
	open EXPCSV2, ">EXPRESSION_LEVELS_2_GENE_SEPARATED.csv"      or die "COULD NOT SAVE EXPRESSION_LEVELS_2.CSV";
	open EXPCSV3, ">EXPRESSION_LEVELS_3_INTERGENE_ID.csv"        or die "COULD NOT SAVE EXPRESSION_LEVELS_3.CSV";
	open EXPCSV4, ">EXPRESSION_LEVELS_4_INTERGENE_SEPARATED.csv" or die "COULD NOT SAVE EXPRESSION_LEVELS_4.CSV";
	open EXPTXT5, ">EXPRESSION_LEVELS_5_GENE.txt"                or die "COULD NOT SAVE EXPRESSION_LEVELS_5.txt";
	open EXPTXT6, ">EXPRESSION_LEVELS_6_INTERGENE.txt"           or die "COULD NOT SAVE EXPRESSION_LEVELS_6.txt";

	print EXPCSV1 "Gene;MicroarrayID;MicroarrayName\n";
	print EXPCSV2 "Chromossome;Gene;MicroarrayID;Pos;MicroarrayName;ExpressionLevel\n";
	print EXPCSV3 "GeneBefore<=>GeneAfter;MicroarrayID;MicroarrayName\n";
	print EXPCSV4 "Chromossome;MicroarrayID;Pos;MicroarrayName;ExpressionLevel;GeneBefore;GBPos;GeneAfter;GAPos\n";

	for (my $table = 0; $table < @geneArray; $table++)
	{
		my $chromName = reverseHash($table);
		next if ( ! (defined $geneArray[$table]));
		for (my $pos = 0; $pos < @{$geneArray[$table]}; $pos++)
		{
			if ((defined $geneArray[$table][$pos]) && (defined $microArray[$table][$pos]))
			{
				my $probe;
				if ((defined $geneArray[$table][$pos]) && (defined $microArray[$table][$pos]))
				{
					$probe = $microArray[$table][$pos];
					print EXPTXT5 "CHROMOSSOME $chromName ($table) POSITION $pos\n";
					print EXPTXT5 "\tGENE "  . $blastKey{$geneArray[$table][$pos]}  . " (" . $geneArray[$table][$pos] . ")\n";
					print EXPTXT5 "\tPROBE " . $microKey{$probe}                    . " (" . $probe                   . ")\n\n";

					if ($microKey{$probe} =~ /(\d+)_(.+)_FOLDS_(.+)/)
					{
						print EXPCSV1 $blastKey{$geneArray[$table][$pos]} . ";$1;$2\n";
						print EXPCSV2 "$chromName;" . $blastKey{$geneArray[$table][$pos]} . ";$1;$pos;$2;$3\n";
					}
					elsif ($microKey{$probe} =~ /(\d+)_(.+)_CORR_(.+)/)
					{
						print EXPCSV1 $blastKey{$geneArray[$table][$pos]} . ";$1;$2\n";
						print EXPCSV2 "$chromName;" . $blastKey{$geneArray[$table][$pos]} . ";$1;$pos;$2;$3\n";
					}
					elsif ($microKey{$probe} =~ /(\d+)_(\D{1,}_.+)/)
					{
						print EXPCSV1 $blastKey{$geneArray[$table][$pos]} . ";$1;$2\n";
						print EXPCSV2 "$chromName;" . $blastKey{$geneArray[$table][$pos]} . ";$1;$pos;$2;0\n";
						#1_GE_CneoSBc12_624001_630000_s_PSO-60-1621
					}
					elsif ($microKey{$probe} =~ /(\d+)_(\d+)_(.+)/)
					{
						print EXPCSV1 $blastKey{$geneArray[$table][$pos]} . ";$1;$2\n";
						print EXPCSV2 "$chromName;" . $blastKey{$geneArray[$table][$pos]} . ";$1;$2;$pos;$3\n";
					}
					else
					{
						die "COULD NOT EXTRACT INFORMATION FROM PROBES";
					}
					$counter++;
					$counterIn++;
				}
				while ((defined $geneArray[$table][$pos])  && (defined $microArray[$table][$pos]) && ($microArray[$table][$pos] eq $probe)) { $pos++; };
				while ((defined $microArray[$table][$pos]) && ($microArray[$table][$pos] eq $probe)) { $pos++; };
			}
			else
			{
				my $probe;
				if (defined $microArray[$table][$pos])
				{
					$probe = $microArray[$table][$pos];
					print EXPTXT6 "CHROMOSSOME $chromName ($table) POSITION $pos\n";
					print EXPTXT6 "\tPROBE " . $microKey{$probe} . " (" . $probe . ")\n";

					my $genBf = $pos-1;
					while ( !( defined $geneArray[$table][$genBf])) { $genBf--; };
					my $genNx = $pos+1;
					while ( !( defined $geneArray[$table][$genNx])) { $genNx++; };

					print EXPTXT6 "\tGENEBF "  . $blastKey{$geneArray[$table][$genBf]} . " (" . $geneArray[$table][$genBf] . ") POS $genBf\n";
					print EXPTXT6 "\tGENENX "  . $blastKey{$geneArray[$table][$genNx]} . " (" . $geneArray[$table][$genNx] . ") POS $genNx\n\n";

					if ($microKey{$probe} =~ /(\d+)_(.+)_FOLDS_(.+)/)
					{
						print EXPCSV3 $blastKey{$geneArray[$table][$genBf]} . "<=>" . $blastKey{$geneArray[$table][$genNx]} . ";$1;$2\n";
						print EXPCSV4 "$chromName;$1;$pos;$2;$3;" . $blastKey{$geneArray[$table][$genBf]} . ";" . $genBf . ";" . $blastKey{$geneArray[$table][$genNx]} . ";" . $genNx . "\n";
					}
					elsif ($microKey{$probe} =~ /(\d+)_(.+)_CORR_(.+)/)
					{
						print EXPCSV3 $blastKey{$geneArray[$table][$genBf]} . "<=>" . $blastKey{$geneArray[$table][$genNx]} . ";$1;$2\n";
						print EXPCSV4 "$chromName;$1;$pos;$2;$3;" . $blastKey{$geneArray[$table][$genBf]} . ";" . $genBf . ";" . $blastKey{$geneArray[$table][$genNx]} . ";" . $genNx . "\n";
					}
					elsif ($microKey{$probe} =~ /(\d+)_(\D{1,}_.+)/)
					{
						print EXPCSV3 $blastKey{$geneArray[$table][$genBf]} . "<=>" . $blastKey{$geneArray[$table][$genNx]} . ";$1;$2\n";
						print EXPCSV4 "$chromName;$1;$pos;$2;0;" . $blastKey{$geneArray[$table][$genBf]} . ";" . $genBf . ";" . $blastKey{$geneArray[$table][$genNx]} . ";" . $genNx . "\n";
						#1_GE_CneoSBc12_624001_630000_s_PSO-60-1621
					}
					elsif ($microKey{$probe} =~ /(\d+)_(\d+)_(.+)/)
					{
						print EXPCSV3 $blastKey{$geneArray[$table][$genBf]} . "<=>" . $blastKey{$geneArray[$table][$genNx]} . ";$1;$2\n";
						print EXPCSV4 "$chromName;$1;$2;$pos;$3;" . $blastKey{$geneArray[$table][$genBf]} . ";" . $genBf . ";" . $blastKey{$geneArray[$table][$genNx]} . ";" . $genNx . "\n";
					}
					else
					{
						die "COULD NOT EXTRACT INFORMATION FROM PROBES";
					}
					$counter++;
					$counterOut++;
				}
				while ((defined $microArray[$table][$pos]) && ($microArray[$table][$pos] eq $probe)) { $pos++; };
			}
		} # end for my pos
	} #end foreach my table
	close EXPTXT6;
	close EXPTXT5;
	close EXPCSV4;
	close EXPCSV3;
	close EXPCSV2;
	close EXPCSV1;

	print " COUNTER $counter    PROBES LOADED\n";
	print " COUNTER $counterIn  PROBES LOADED INSIDE GENES\n";
	print " COUNTER $counterOut PROBES LOADED IN INTERGENIC REGIONS\n";
}






sub genGeneArray
{
	my $counter = 0;
  # returns value at index 12
#   $value = $geneArray->get(12);

	for (my $table = 0; $table < @XMLpos; $table++)
	{
		next if ( ! (defined $XMLpos[$table]));
		for (my $register = 0; $register < @{$XMLpos[$table]}; $register++)
		{
			next if ( ! (defined $XMLpos[$table][$register]));
			if (defined $XMLpos[$table][$register]{"gene"})
			{
				my $gene  = $XMLpos[$table][$register]{"gene"};
				my $start = $XMLpos[$table][$register]{"pos"};
				my $end   = $XMLpos[$table][$register]{"gene_end"};

				for (my $i = $start; $i <= $end; $i++)
				{
					if (defined $geneArray[$table][$i])
					{
						
						my $idd         = $geneArray[$table][$i];
						my $iddname     = $blastKey{$idd};
						my $idname      = $gene;
						my $mixRegister = "$idd+$register";
						my $mixName     = "$iddname+$gene";
# 						while ((defined $blastKey{$mixRegister}) && ($blastKey{$mixRegister} ne $mixName)) {$mixRegister+};
						if ( ! defined $blastKeyRev{$gene} )     { $blastKeyRev{$gene}     = ((keys %blastKey)+1); $blastKey{$blastKeyRev{$gene}}    = $gene; $counter++;};
						if ( ! defined $blastKeyRev{$mixName} )  { $blastKeyRev{$mixName}  = $mixRegister        ; $blastKey{$blastKeyRev{$mixName}} = $mixName;};
# 						if ( ! defined $blastKey{$mixRegister} ) { $blastKey{$mixRegister} = $mixName; };
						$geneArray[$table][$i] = $mixRegister;
# 						print "CAR CRAAAAAAAAAASSSSSSSSSHHHHHHHHHHHH...$mixRegister $mixName\n";# $table $i $idname $iddname\n"
					}
					else
					{
						if ( ! defined $blastKeyRev{$gene} ) { $blastKeyRev{$gene} = ((keys %blastKey)+1); $blastKey{$blastKeyRev{$gene}} = $gene; $counter++;};
						$geneArray[$table][$i] = $blastKeyRev{$gene};
# 						print "TABLE $table I $i REGISTER " . $blastKeyRev{$gene} . "\n";
					}
				} #end for i = start -> i < end
			}
		} #end foreach my register
    } #end foreach my table
	print " COUNTER $counter GENES LOADED\n";
# 	$counter = 0;
# 	foreach my $name (sort keys %blastKeyRev)
# 	{
# 		if ( ! ($name =~ /\x2B/))
# 		{
# 			$counter++;
# # 			print $counter . " = $name > " . $blastKeyRev{$name} . "\n";
# 		}
# 	}
# 	print " COUNTER $counter UNIQUE GENES LOADED\n";
# my %geneArray;  # chrom num > start pos > gene id
}



sub genMicroArray
{
	my $counter = 0;
  # returns value at index 12
#   $value = $geneArray->get(12);

    for (my $table = 0; $table < @XMLpos; $table++)
    {
		next if ( ! (defined $XMLpos[$table]));
		for (my $register = 0; $register < @{$XMLpos[$table]}; $register++)
		{

#			<row id="3954">
#				<microarray_end>4013</microarray_end>
#				<microarray_exp>-2.49</microarray_exp>
#				<microarray_id>114236_GE_CneoSBc1_1_6000_s_RC-60-1988_FOLDS_-2.49</microarray_id>
#				<pos>3954</pos>
#			</row>

			next if ( ! (defined $XMLpos[$table][$register]));
			if (defined $XMLpos[$table][$register]{"microarray_id"})
			{
				my $gene  = $XMLpos[$table][$register]{"microarray_id"};
				my $start = $XMLpos[$table][$register]{"pos"};
				my $end   = $XMLpos[$table][$register]{"microarray_end"};
				#print "$gene\t$start\t$end\n";
				for (my $i = $start; $i <= $end; $i++)
				{
					if (defined $microArray[$table][$i])
					{
						my $idd         = $microArray[$table][$i];
						my $iddname     = $microKey{$idd};
						my $idname      = $gene;
						my $mixRegister = "$idd+$register";
						my $mixName     = "$iddname+$gene";
# 						while ((defined $blastKey{$mixRegister}) && ($blastKey{$mixRegister} ne $mixName)) {$mixRegister+};
						if ( ! defined $microKeyRev{$gene} )     { $microKeyRev{$gene}     = ((keys %microKey)+1); $microKey{$microKeyRev{$gene}}    = $gene; $counter++;};
						if ( ! defined $microKeyRev{$mixName} )  { $microKeyRev{$mixName}  = $mixRegister        ; $microKey{$microKeyRev{$mixName}} = $mixName;};
# 						if ( ! defined $blastKey{$mixRegister} ) { $blastKey{$mixRegister} = $mixName; };
						$microArray[$table][$i] = $mixRegister;
# 						print "CAR CRAAAAAAAAAASSSSSSSSSHHHHHHHHHHHH...$mixRegister $mixName\n";# $table $i $idname $iddname\n"
					}
					else
					{
						if ( ! defined $microKeyRev{$gene} ) { $microKeyRev{$gene} = ((keys %microKey)+1); $microKey{$microKeyRev{$gene}} = $gene; $counter++;};
						$microArray[$table][$i] = $microKeyRev{$gene};
# 						print "TABLE $table I $i REGISTER " . $blastKeyRev{$gene} . "\n";
					}
				} #end for i = start -> i < end
			}
		} #end foreach my register
    } #end foreach my table
	print " COUNTER $counter MICROARRAYS LOADED\n";
# 	$counter = 0;
# 	foreach my $name (sort keys %blastKeyRev)
# 	{
# 		if ( ! ($name =~ /\x2B/))
# 		{
# 			$counter++;
# # 			print $counter . " = $name > " . $blastKeyRev{$name} . "\n";
# 		}
# 	}
# 	print " COUNTER $counter UNIQUE GENES LOADED\n";
# my %geneArray;  # chrom num > start pos > gene id
}




sub print_fasta_general
{
	@XMLpos  = @{$_[0]};
	$inputFA =   $_[1];

	if ($makeShort) { 	open FASTA1, ">$outputFA\_SHORT"          or die "COULD NOT CREATE OUTPUT FILE $outputFA\_SHORT: $!"; 
						print "\tGENERATING $outputFA\_SHORT\n";
					};
	if ($makeLong)  { 	open FASTA2, ">$outputFA\_LONG"           or die "COULD NOT CREATE OUTPUT FILE $outputFA\_LONG: $!";
						open FASTA5, ">$outputFA\_LONG_SELECTION" or die "COULD NOT CREATE OUTPUT FILE $outputFA\_LONG_SELECTION: $!";
						print "\tGENERATING $outputFA\_LONG\n";
						print "\tGENERATING $outputFA\_LONG_SELECTION\n";
					};
	if ($makeNew)	{	open FASTA3, ">$outputFA\_NEW"            or die "COULD NOT CREATE OUTPUT FILE $outputFA\_NEW: $!";
						open FASTA4, ">$outputFA\_NEW.html"       or die "COULD NOT CREATE OUTPUT FILE $outputFA\_NEW.html: $!";
						print "\tGENERATING $outputFA\_NEW\n";
						print "\tGENERATING $outputFA\_NEW.html\n";
					};

	my %outProg;

	undef @seq;
	undef @gen;
	my $head = "";
	my $output2;
	my %resume;

	for (my $chromNum  = 0; $chromNum < @XMLpos; $chromNum++)
	{
		next if ( ! (defined $XMLpos[$chromNum]));
		undef $output2;

		my $chromName = reverseHash($chromNum);
		#print "CHROM NAME $chromName CHROM NUM $chromNum\n";

		undef @seq;
		undef @gen;

		@seq = @{$XMLpos[$chromNum]};
		@gen = @{$geneArray[$chromNum]};

		if ( $chromNum ne $geneName)
		{
			@gene = @{&readFasta($inputFA, $chromNum)};
		}

#		print "SEQ ", (scalar @seq), "\n";
#		print "GEN ", (scalar @gen), "\n";

		if($statistic)
		{
		    my %response      = %{&getStat($chromNum)};
		    my $totalSeq      = $response{"size"};           # $Int

		    $head  = "INPUT FASTA: $inputFA\n";
		    $head .= "INPUT XML  : $inputPos\n";
		    $head .= "CHROMOSSOME: " . $chromName . "($totalSeq" . "bp)\n";

		    if ($response{"SNP"})
		    {
				my $snp_progs     = $response{"SNP_prog"};       # $Str
				my $snp_positions = $response{"SNP_pos"};        # $Int
				my $snp_countU    = $response{"SNP_count_u"};    # $Int
				$head .= "TOTAL SNPS : $snp_countU\n";
				$head .= "POS   SNPS :\n$snp_positions\n";
		    }

		    if ($response{"GAP"})
		    {
				my $gap_progs     = $response{"GAP_prog"};       # $Str
				my $gap_positions = $response{"GAP_pos"};        # $Int
				my $gap_countU    = $response{"GAP_count_u"};    # $Int
				$head .= "TOTAL GAPS : $gap_countU\n";
				$head .= "POS   GAPS :\n$gap_positions\n";
		    }

		    if ($response{"ND"})
		    {
				my $nd_progs     = $response{"ND_prog"};       # $Str
				my $nd_positions = $response{"ND_pos"};        # $Int
				my $nd_countU    = $response{"ND_count_u"};    # $Int
				$head .= "TOTAL NO DATA : $nd_countU\n";
				$head .= "POS   NO DATA :\n$nd_positions\n";
		    }


		    if ($response{"BLAST"})
		    {
				my $blast_prog      = $response{"BLAST_prog"};    # $Str
				my $blast_positions = $response{"BLAST_pos"};     # $Str
				my $blast_countU    = $response{"BLAST_count_u"}; # $Int
				$head .= "TOTAL GENES : $blast_countU\n";
				$head .= "POS   GENE  :\n$blast_positions\n";
				$head .= "\tGEN[START;END;SIZE] :\n";
				for (my $i = 1; $i <= $totalSeq; $i++)
				{
					if ( defined $gen[$i] )
					{
						my $gen            = $blastKey{$gen[$i]};
						my $currGeneSize   = 1;
						my $y              = $i+1;
						while ((defined $gen[$y]) && ($gen[$y] eq $gen[$i])) { $currGeneSize++; $y++; }
						#print "GENE " . $gen[$i] . " $i $y $gen $currGeneSize\n";
						my $currGeneStr    = "$gen\[$i;$y;$currGeneSize\]";
						$head .= "\t$currGeneStr\n";
						$i = $y+1;
					}
				}
		    }

		    if ($makeShort) { print FASTA1 $head; };
			if ($makeLong)	{ print FASTA2 $head; print FASTA5 $head; };
			if ($makeNew)	{ print FASTA4 &htmlador($head); print FASTA3 $head; };
		}

		my $number;

		my $outGene;
		my $outOri;
		my $outNew;
		my $tempOutNew;
		my $tempOutOld;
		my $output;
		my $ind;
		my $totalSeq = @gene-1;
		my $lengthTotalSequence = length($totalSeq);


		my $currGeneCount  = 0;
		my $currGeneSize   = 0;
		my $currGeneStart  = 0;
		my $currGeneEnd    = 0;
		my $currGene       = "";
		my $currGeneStr    = "";
		my $currGeneStrLen = "";
		my $currLeft       = 0;
		my $currRight      = 0;

		for (my $i = 1; $i <= $totalSeq; $i+=60)
		{
			my $selection = 0;
			my $ii        = $i + 59;
			while ($ii > $totalSeq) {($ii--)};

			$number = &fixDigit($i,$lengthTotalSequence);

			undef $outGene;
			undef $outOri;
			undef $outNew;
			undef $tempOutNew;
			undef $output;

	# 		LONG
			if ($makeLong)
			{
				for (my $z = $i; $z <= $ii; $z++)
				{
					my $out;
					if ( defined $gen[$z] )
					{
						$selection += 1000;
						my $gen     = $blastKey{$gen[$z]};
						if ($gen eq $currGene)
						{
							$currGeneCount++;
							if ($currGeneCount < ($currGeneStrLen+2))
							{
								my $pos = $currGeneCount-2;
								$out = substr($currGeneStr, $pos, 1);
#	 							print "$out $currGeneCount\t";
	# 							if ($pos == length($currGeneStr)-1) { print "\n"; };
	# 							$out = "X";
							} # end ($currGeneCount < ($currGeneStrLen+2))
							elsif (($currGeneCount >= $currLeft) && ($currGeneCount < $currRight))
							{
								my $pos = $currGeneCount - $currLeft;
								$out = substr($currGeneStr, $pos, 1);
	# 							$out = "X";
							} # end (($currGeneCount >= $currLeft) && ($currGeneCount < $currRight))
							elsif (($currGeneCount >= ($currGeneSize - ($currGeneStrLen))) && ($currGeneCount != $currGeneSize) && ($currGeneSize >= ($currGeneStrLen+2))) 
							{
								my $pos = $currGeneCount - ($currGeneSize - ($currGeneStrLen));
								if ( ! $currGeneStr ) { die };
								
								#if ( eval {'$out = substr($currGeneStr, $pos, 1)'}) { $out = " "; };
	# 							if ( ! (eval '$out = substr($currGeneStr, $pos, 1)')) { $out = " "; };
								$out = substr($currGeneStr, $pos, 1);
	# 							print "$currGeneStr $pos $currGeneSize $currGeneStrLen $out\n"; 
	# 							$out = "X";
							}
							elsif ($currGeneCount == $currGeneSize)
							{
								$out = ">";
							}
							elsif ($currGeneCount < $currLeft)
							{
								$out = "<";
							}
							elsif ($currGeneCount >= $currRight)
							{
								$out = ">";
							}
							else
							{
								$out = "E";
							} # end ($currGeneCount < ($currGeneStrLen+2))
						} # end ($gen eq $currGene)
						else
						{
							my $y = $z;
							$currGeneSize   = 0;
							while ((defined $gen[$y]) && ($gen[$y] eq $gen[$z])) { $currGeneSize++; $y++; }
							$currGeneCount  = 1;
							$currGeneStart  = $z;
							$currGeneEnd    = $y;
							#print ";$currGene:$gen:$z:$y;\n";
							$currGene       = $gen;
							$currGeneStr    = "$gen\[$currGeneStart;$currGeneEnd;$currGeneSize\]";
							$currGeneStrLen = length($currGeneStr);
							$currLeft       = int(($currGeneSize/2)-($currGeneStrLen/2));
							$currRight      = int(($currGeneSize/2)+($currGeneStrLen/2));
	# 						print "CURGENE $currGene GENE $gen COUNT $currGeneCount START $currGeneStart END $currGeneEnd SIZE $currGeneSize\n";
							$out = "<";
	# 						print "CURGENE $currGene GENE $gen COUNT $currGeneCount START $currGeneStart END $currGeneEnd SIZE $currGeneSize\n";
						} # end else ($gen eq $currGene)
					} #end if exists gene  ( defined $gen[$z] )
					else
					{
							$currGeneCount  = 0;
							$currGeneSize   = 0;
							$currGeneStart  = 0;
							$currGeneEnd    = 0;
							$currGene       = "";
							$currGeneStr    = "";
							$currGeneStrLen = "";
							$currLeft       = 0;
							$currRight      = 0;
							$out = " ";
	# 						print "CURGENE $currGene GENE     COUNT $currGeneCount START $currGeneStart END $currGeneEnd SIZE$currGeneSize\n";
					} # end else #end if exists gene  ( defined $gen[$z] )
					$outGene .= $out;

					$outOri  .= $gene[$z];
					if (( defined $seq[$z] ) && ( ( exists ${$seq[$z]}{"gap"} ) || ( exists ${$seq[$z]}{"nd"} ) || ( exists ${$seq[$z]}{"new"} ) ))
					{
						my $outNewRGap;
						my $outNewRSnp;
						if ( exists ${$seq[$z]}{"gap"} )
						{
							$selection += 1;
							$outNewRGap = $seq[$z]{"gap"};
						}

						if ( exists ${$seq[$z]}{"nd"} )
						{
							$selection += 1;
							$outNewRGap = $seq[$z]{"nd"};
						}

						if ( exists ${$seq[$z]}{"new"} )
						{
							$selection += 1;
							$outNewRSnp = &consensusSimple(split("\t",$seq[$z]{"new"}));
						}

						# TODO: PLACE ND
						if (( $outNewRGap ) && ( $outNewRSnp ))
						{
							if ((uc($outNewRGap) eq uc($outNewRSnp)))
							{
# 								print "IF 0 SNP $outNewRSnp GAP $outNewRGap\n";
# 								$outNewRSnp =~ tr/ACTGactg/\^/;
								$outNewRSnp = "X";
								# DO NOTHING CASE SNP IS A DELETION OR INSERTION
							}
							elsif ((($outNewRGap eq "+") && ( uc($outNewRSnp) eq "X")) || ((uc($outNewRGap) eq "X") && ( $outNewRSnp eq "+")))
							{
# 								print "ELSEIF 1 SNP $outNewRSnp GAP $outNewRGap\n";
								$outNewRSnp = "X";
							}
							elsif (($outNewRGap eq "+"))
							{
# 								print "ELSEIF 2 SNP $outNewRSnp GAP $outNewRGap\n";
								$outNewRSnp =~ tr/ACTGactg/\*/;
							}
							else
							{
# 								print "ELSE SNP $outNewRSnp GAP $outNewRGap\n";
								$outNewRSnp =~ tr/ACTGactg/56785678/;
							}
							$outNew  .= $outNewRSnp;
						}
						elsif ( $outNewRGap )
						{
							$outNew  .= $outNewRGap;
						}
						elsif ( $outNewRSnp)
						{
							$outNew  .= $outNewRSnp;
						} #end (( $outNewRGap ) && ( $outNewRSnp ))
	# 					else
	# 					{
	# 						$outNew .= ".";
	# 					}
					} # end if (( exists $seq[$z] ) && ( ( exists ${$seq[$z]}{"gap"} ) || ( exists ${$seq[$z]}{"new"} ) ))
					else
					{
						$outNew  .= ".";
					}
				} # end for for (my $z = $i; $z <= $ii; $z++)

				$output  = "$number $outGene ANNOTATION\n";
				$output .= "$number $outOri REFERENCE\n";
				$output .= "$number $outNew NEW\n\n";
				print FASTA2 $output;
				print FASTA5 $output if ($selection > 1000);
				undef $output;
 			} #end if makeLong

 
# #	 		SHORT
			if ($makeShort)
			{
				for (my $z = $i; $z <= $ii; $z++)
				{
					undef $tempOutNew;
					undef $tempOutOld;
					undef $outNew;
					undef $outOri;

	# 				$XMLpos{$chromNum}{$start}{"gap"} = $id;
					if (( defined $seq[$z] ) && ( ( exists ${$seq[$z]}{"gap"} ) || ( exists ${$seq[$z]}{"nd"} ) || ( exists ${$seq[$z]}{"new"} ) ))
					{
						my $start = $z - $side;
						my $end   = $z + $side;

# 						if ( defined $gen[$z] ) { $resume{$chromNum}{"pos"}{$gen[$z]}++; };

						$tempOutOld = $gene[$z];
	# 					@program    = $seq[$z]{"orig"};

						while ($start < 1 )         {($start++)};
						while ($end   > $totalSeq ) {($end--)};

						my $mLeft  = $start - ($z - $side);
						my $mRight = ($z + $side) - $end;

	# 					print "$start $z $end $mLeft $mRight\n";

						$number = &fixDigit($start, $lengthTotalSequence);
						my $Z   = &fixDigit($z,     $lengthTotalSequence);

						for (my $r = $start; $r <= $end; $r++)
						{
							$outOri .= $gene[$r];
							my $outNewRGap;
							my $outNewRSnp;
							if (exists $seq[$r]{"gap"})	{ $outNewRGap = $seq[$r]{"gap"}; };
							if (exists $seq[$r]{"nd"})	{ $outNewRGap = $seq[$r]{"nd"}; };
							if (exists $seq[$r]{"new"})	{ $outNewRSnp = &consensusSimple(split("\t",$seq[$r]{"new"})); };

							if (( $outNewRGap ) && ( $outNewRSnp))
							{
								if ($outNewRGap eq "+")
								{
									$outNewRSnp =~ tr/ACTGactg/56785678/;
								}
								else
								{
									$outNewRSnp =~ tr/ACTGactg/56785678/;
								}
								$outNew    .= $outNewRSnp;
							}
							elsif ( $outNewRGap )
							{
								$outNew .= $outNewRGap;
							}
							elsif ( $outNewRSnp)
							{
								$outNew .= $outNewRSnp;
							}
							else
							{
								$outNew .= " ";
							};
						}; # end for r= start < end

						my $desc;
						my $descSNP = "";
						my $descGAP = "";
						my $descND  = "";

						if ( exists $seq[$z]{"gap"} )
						{
							$tempOutNew    = $seq[$z]{"gap"};
							my $tempOutOldGap = $tempOutOld;
							my $a = $z;
							my $mut;
							my $mutL = 1;

							if ($tempOutNew eq "+")
							{
								$mut = "INS";
								while (( exists ${$seq[$a]}{"gap"} ) && ( exists ${$seq[$a+1]}{"gap"} ) && ($a < $totalSeq)) { $a++; };
								$mutL = $a - $z + 1;
							}
							else
							{
								$mut = "DEL";
								while (( exists ${$seq[$a]}{"gap"} ) && ( exists ${$seq[$a+1]}{"gap"} ) && ($a < $totalSeq)) { $a++; $tempOutOldGap .= $gene[$a]; };
								$mutL = $a - $z + 1;
							}
							my $A    = &fixDigit($a,     $lengthTotalSequence);;
							$descGAP = " $mut ($Z - $A) " . $tempOutNew x $mutL . " ($tempOutOldGap)"
						}


						if ( exists $seq[$z]{"nd"} )
						{
							$tempOutNew    = $seq[$z]{"nd"};
							my $tempOutOldGap = $tempOutOld;
							my $a = $z;
							my $mut;
							my $mutL = 1;

							if ($tempOutNew eq "+")
							{
								$mut = "ND";
								while (( exists ${$seq[$a]}{"nd"} ) && ( exists ${$seq[$a+1]}{"nd"} ) && ($a < $totalSeq)) { $a++; };
								$mutL = $a - $z + 1;
							}
							else
							{
								$mut = "ND";
								while (( exists ${$seq[$a]}{"nd"} ) && ( exists ${$seq[$a+1]}{"nd"} ) && ($a < $totalSeq)) { $a++; $tempOutOldGap .= $gene[$a]; };
								$mutL = $a - $z + 1;
							}
							my $A    = &fixDigit($a,     $lengthTotalSequence);;
							$descND = " $mut ($Z - $A) " . $tempOutNew x $mutL . " ($tempOutOldGap)"
						}


						if ( exists $seq[$z]{"new"} )
						{
							$tempOutNew = &consensusSimple(split("\t",$seq[$z]{"new"}));
							$descSNP    = " SNP ($tempOutOld > $tempOutNew)";
						} # end if exists SNP

						if ( (( exists $seq[$z]{"gap"} ) || ( exists $seq[$z]{"nd"} ))&& ( exists $seq[$z]{"new"} ))
						{
							$tempOutNew = &consensusSimple(split("\t",$seq[$z]{"new"}));
							if ($seq[$z]{"gap"} eq "+")
							{
								$tempOutNew =~ tr/ACTGactg/56785678/;
							}
							else
							{
								$tempOutNew =~ tr/ACTGactg/56785678/;
							}
						}
						$desc = "$Z$descSNP$descGAP$descND";

						my %genes;
						for (my $r = $start; $r <= $end; $r++)
						{
							if (defined $gen[$r]) { $genes{$blastKey{$gen[$r]}} = 1; };
						}
						$desc .= " { GENES: " . join("; ", (sort keys %genes)) . " }" if (keys %genes);

						$output  = "$number " . "_"x$mLeft . "$outOri" . "_"x$mRight . "\n";
						$output .= "$number " . " "x$mLeft . "$outNew" . " "x$mRight . " $desc\n\n";

					} # end if exists seq_z AND (GAP or SNP)
# 					else
# 					{
# 						if ( defined $gen[$z] ) { $resume{$chromNum}{"neg"}{$gen[$z]}++; };
# 					}

					if ($output) { print FASTA1 $output };
					undef $output;
					while (( exists ${$seq[$z]}{"gap"} ) && ( exists ${$seq[$z+1]}{"gap"} ) && ( ! exists ${$seq[$z+1]}{"new"} ) && ($z < $totalSeq)) { $z++; };
					while (( exists ${$seq[$z]}{"nd"} )  && ( exists ${$seq[$z+1]}{"nd"} )  && ( ! exists ${$seq[$z+1]}{"new"} ) && ($z < $totalSeq)) { $z++; };
				} # end for my z short
			} #end if makeShort;




# 			RESUME
			if ($makeResume)
			{
				for (my $z = $i; $z <= $ii; $z++)
				{
					if (( defined $gen[$z] ) && ( ( exists ${$seq[$z]}{"gap"} ) || ( exists ${$seq[$z]}{"nd"} ) || ( exists ${$seq[$z]}{"new"} ) ))
					{
						$resume{$chromNum}{"pos"}{$gen[$z]}++;
					}
					elsif ( defined $gen[$z] )
					{
						$resume{$chromNum}{"neg"}{$gen[$z]}++;
					}
				} # end for (my $z = $i; $z <= $ii; $z++)
			} # end if make resume


		} # end for (my $i = 1; $i <= $totalSeq; $i+=60)



# 		NEW
		undef $output2;
		if ($makeNew)
		{
			for (my $z = 1; $z <= $totalSeq; $z++)
			{
				if (( defined $seq[$z] ) && ( ( exists ${$seq[$z]}{"gap"} ) || ( exists ${$seq[$z]}{"nd"} ) || ( exists ${$seq[$z]}{"new"} ) ))
				{
					my $outNewRGap;
					my $outNewRSnp;
					if ( exists ${$seq[$z]}{"gap"} )
					{
						$outNewRGap = $seq[$z]{"gap"};
					}

					if ( exists ${$seq[$z]}{"nd"} )
					{
						$outNewRGap = $seq[$z]{"nd"};
					}

					if ( exists ${$seq[$z]}{"new"} )
					{
						$outNewRSnp = &consensusSimple(split("\t",$seq[$z]{"new"}));
					}
		
					if (( $outNewRGap ) && ( $outNewRSnp ))
					{
						$outNewRSnp = $gene[$z];
						if ($outNewRGap eq "+")
						{
							$outNewRSnp =~ tr/ACTGactg/56785678/;
						}
						else
						{
							$outNewRSnp =~ tr/ACTGactg/56785678/;
						}
						$output2 .= $outNewRSnp;
					}
					elsif ( $outNewRGap )
					{
						if ($outNewRGap eq "+")
						{
							$outNewRGap = "+";
							while (( exists ${$seq[$z]}{"gap"} ) && ( exists ${$seq[$z+1]}{"gap"} ) && ( ! exists ${$seq[$z+1]}{"new"} ) && ($z < $totalSeq)) { $z++; $outNewRGap .= "+";};
							while (( exists ${$seq[$z]}{"nd"} )  && ( exists ${$seq[$z+1]}{"nd"} )  && ( ! exists ${$seq[$z+1]}{"new"} ) && ($z < $totalSeq)) { $z++; $outNewRGap .= "*";};
						}
						else
						{
							$outNewRGap = "_";
							while (( exists ${$seq[$z]}{"gap"} ) && ( exists ${$seq[$z+1]}{"gap"} ) && ( ! exists ${$seq[$z+1]}{"new"} ) && ($z < $totalSeq)) { $z++; $outNewRGap .= "_";};
							while (( exists ${$seq[$z]}{"nd"} )  && ( exists ${$seq[$z+1]}{"nd"} )  && ( ! exists ${$seq[$z+1]}{"nd"} )  && ($z < $totalSeq)) { $z++; $outNewRGap .= "*";};
						}
		
						$output2 .= $outNewRGap;
					}
					elsif ( $outNewRSnp)
					{
						$output2 .= $outNewRSnp; 
					}
				} # end if (( exists $seq[$z] ) && ( ( exists ${$seq[$z]}{"gap"} ) or ( exists ${$seq[$z]}{"new"} ) ))
				else
				{
					$output2 .= $gene[$z];
				} # end else if (( exists $seq[$z] ) && ( ( exists ${$seq[$z]}{"gap"} ) or ( exists ${$seq[$z]}{"new"} ) ))
			} #end for my z < totalseq
			$output2 = &faster($output2);
			print FASTA3 $output2;
			print FASTA4 &colorFasta($output2);
			undef $output2;
		} #end if make new
	} #end foreach my chromnum

	if ($makeResume)
	{
		open FASTA6, ">$outputFA\_RESUME_POS" or die "COULD NOT CREATE OUTPUT FILE $outputFA\_RESUME_POS: $!";
		open FASTA7, ">$outputFA\_RESUME_NEG" or die "COULD NOT CREATE OUTPUT FILE $outputFA\_RESUME_NEG: $!";
		print "\tGENERATING $outputFA\_RESUME_POS\n";
		print "\tGENERATING $outputFA\_RESUME_NEG\n";
		my $countPos     = 0;
		my $countPosPlus = 0;
		my $countNeg     = 0;
		my $countNegPlus = 0;
		foreach my $chromNum (sort {$a <=> $b} keys %resume)
		{
# 			print "\tRESUME $chromNum\n";
			my $chromName = &reverseHash($chromNum);
			my $totalPos  = (keys %{$resume{$chromNum}{"pos"}});
			my $totalNeg  = (keys %{$resume{$chromNum}{"neg"}});
			my $totalChr  = $totalPos + $totalNeg;
			my $totalGlo  = (keys %blastKey);

			print FASTA6 "$chromName ($totalPos/$totalChr/$totalGlo)\n";
			print FASTA7 "$chromName ($totalNeg/$totalChr/$totalGlo)\n";

			
			foreach my $id (sort keys %{$resume{$chromNum}{"pos"}})
			{
				my $count = $resume{$chromNum}{"pos"}{$id};
				my $gen   = $blastKey{$id};
				if ( ! ($gen =~ /\x2B/) ) # plus signal
				{	
					$countPos++;
# 					print "ID $id\n";
					print FASTA6 "\t$gen\t$count\n";
				}
				else
				{
					$countPosPlus++;
				}
			}
	
			foreach my $id (sort keys %{$resume{$chromNum}{"neg"}})
			{
				my $count = $resume{$chromNum}{"neg"}{$id};
				my $gen   = $blastKey{$id};
				if ( ! (exists $resume{$chromNum}{"pos"}{$id}) )
				{
					if ( ! ($gen =~ /\x2B/) ) # plus signal
					{
							$countNeg++;
							print FASTA7 "\t$gen\t$count\n";
					}
					else
					{
							$countNegPlus++;
					}
				}
			}
		}
		close FASTA7;
		close FASTA6;
		print "done\n";
		my $cmd  = "cat $outputFA\_RESUME_POS | grep -iv hypothetical > $outputFA\_RESUME_POS_VALID ;";
		   $cmd .= "cat $outputFA\_RESUME_NEG | grep -iv hypothetical > $outputFA\_RESUME_NEG_VALID";
		if (system($cmd)) { print "FAILED TO GENERATE RESUME_VALID\n" };
		print "\tPOS $countPos (DOUBLE: $countPosPlus)\n\tNEG $countNeg (DOUBLE: $countNegPlus)\n";
	} # end if makeResume


	if ($makeShort) { 	close FASTA1;	};
	if ($makeLong)  { 	close FASTA2 ; close FASTA5; };
	if ($makeNew)	{	close FASTA3 ; close FASTA4;  };

	undef @seq;
}


sub colorFasta
{
	my $string = $_[0];
# 	$string =~ s/b/<b>b<\\b>/g;
	$string =~ s/([bduh])/&colorFastaGenCode("yellow","red","4",$1)/eg;
	$string =~ s/([BDUH])/&colorFastaGenCode("red","blue","4",$1)/eg;
	$string =~ s/([actg])/&colorFastaGenCode("yellow","green","4",$1)/eg;
	$string =~ s/_/&colorFastaGenCode("black","red","5","_")/eg;
	$string =~ s/\+/&colorFastaGenCode("black","red","4","+")/eg;
	$string =~ s/\n/<br\/>\n/g;
# 	$string =~ s/bduh/<b>$1<b>/;
# 	$string =~ s/actg/<b>$1<b>/;
	$string = "<font color=\"gray\" face=\"courier\" size=\"3\">$string</font>";
	return $string;
}

sub colorFastaGenCode
{
	my $bg    = $_[0];
	my $color = $_[1];
	my $size  = $_[2];
	my $text  = $_[3];
	my $out = "<font color=\"$color\" size=\"$size\" face=\"courier\" style=\"BACKGROUND-COLOR: $bg\"><b>$text</b></font>";
	return $out;
}


sub htmlador
{
	my $string = $_[0];

	my @array = split("\n", $string);
	my @array2;
	foreach my $line (@array)
	{
		if ($line =~ /^(.*)(\s*):(\s*)(.*)/)
		{
			$line = "<b><u>$1</u></b>$2:$3<i>$4</i><br />\n";
		}
		else
		{
			$line = "<tt>$line</tt><br />\n";
		}
		push (@array2, $line);
	}
	$string = join("", @array2);
	return $string
}

sub faster
{
	my $seq  = shift;
	$
}


# sub print_graphics
# {
# 	%XMLsnp      = %{$_[0]};
# 	my $inputSNP = $_[1];
# 
# 	undef @image;
# 	undef %new;
# 
# 	foreach my $table (sort (keys %XMLsnp))
# 	{
# 		my $total = 0;
# 		my $max   = 0;
# 		undef %new;
# 
# 		foreach my $key (sort { $a <=> $b } (keys %{$XMLsnp{$table}}))
# 		{
# 			my $pos    = $XMLsnp{$table}{$key}{"posOrig"};
# 			$new{$pos} = $XMLsnp{$table}{$key};
# 			$max       = $pos if ($pos >= $max);
# 		} # end foreach my keys
# 		$max += 5000;
# 
# 		my $panel = Bio::Graphics::Panel->new(
# 					-length    => ($max*1.1),
# 					-width     => 1024,
# # 					-key_style => 'between',
# 					-pad_left  => 10,
# 					-pad_right => 100,
# 					);
# 
# 		my @rep   = ("0") x ($max+1);
# 		my %features;
# 		my $feature;
# 		print "\t\tANALYSING POSITION #: ";
# 		my $poscount = 1;
# 
# 		foreach my $pos (keys %new)
# 		{
# 			print "$poscount " if (( ! ($poscount % 100)) || ($poscount == 1));
# 			$poscount++;
# 			my $orig = $new{$pos}{"orig"};
# 			my $new  = $new{$pos}{"new"};
# 			my $prog = $new{$pos}{"program"};
# 			undef $feature;
# 
# 			$feature = Bio::SeqFeature::Generic->new(
# 							-display_name =>"$pos $orig->$new ($prog)",
# 							-start        =>$pos,
# 							-end          =>($pos+1),
# 							-connector    =>'dashed',
# # 							-tag          =>{ description => "REF:$contextR QUERY:$contextQ FRAME:$frame"},
# 							);
# 			$features{$pos} = $feature;
# 			if (($pos > $max) || ($pos < 0)) { die "START $pos IS ILEGAL ($max)"};
# 
# 			if (defined $rep[$pos])
# 			{
# 				$rep[$pos] = 1;
# 			}
# 			else
# 			{
# 				die "ERROR IN LOGIC $pos IN \@REP DOESNT EXISTS";
# 			}
# 			$total++;
# 		}
# 		print "DONE\n";
# 		my %cov = %{&genCoverage(\@rep)};
# 
# 		my $full_length = Bio::SeqFeature::Generic->new(
# 						-start        =>1,
# 						-end          =>$max,
# 						-display_name =>"$inputSNP || $table (~$max" . "bp) || ($total SNPs)"
# 						);
# 
# 		$panel->add_track($full_length,
# 					-glyph   => 'arrow',
# 					-tick    => 3,
# 					-fgcolor => 'black',
# 					-double  => 1,
# 					-label   => 1,
# 					);
# 
# 
# 		my $track = $panel->add_track(	-glyph       => 'generic',
# 	# 							-double      => 1,
# 						-label       => 1,
# 						-connector   =>'dashed',
# 						-bgcolor     => 'blue',
# # 						-description =>"COVERAGE " . $cov{"cov"} . "/$size",
# # 						-key =>"COVERAGE " . $cov{"cov"} . "/$size",
# # 						-label =>"COVERAGE " . $cov{"cov"} . "/$size",
# 							);
# 
# 		foreach my $start (keys %cov)
# 		{
# 		if ($start ne "cov")
# 		{
# 			my $cov = Bio::SeqFeature::Generic->new(
# 							-start        =>$start,
# 							-end          =>$cov{$start},
# # 							-display_name =>"coverage"
# 							);
# 			$track->add_feature($cov);
# 		}
# 		}
# 
# 		my $idx    = 0;
# 		my @colors = qw(cyan orange gray blue gold purple green chartreuse magenta yellow aqua pink marine cyan);
# 
# 		print "\t\tADDING TAG: ";
# 
# 		my $tagcount = 1;
# 		foreach my $tag (sort { $a <=> $b} (keys %features))
# 		{
# 			print "$tagcount "  if (( ! ($tagcount % 100)) || ($tagcount == 1));
# 			$tagcount++;
# 			$panel->add_track($features{$tag},
# 					-glyph       =>  'generic',
# 					-bgcolor     =>  $colors[$idx++ % @colors],
# 					-fgcolor     => 'black',
# 					-font2color  => 'red',
# 					-connector   => 'dashed',
# # 					-key         => $tag,
# 					-bump        => +1,
# 					-height      => 8,
# 					-label       => 1,
# 					-description => 1,
# 					);
# 		}#END FOR MY TAG
# 		print "DONE\t";
# 		push (@image, &printGD($panel->height, 10240, $panel->gd));
# 		$panel->finished;
# 		print " " x12 . "TABLE $table SNPs = $total\n";
# 	} # end foreach my table
# 
# 	return \@image;
# } #end sub parse_snps_img


sub fixDigit
{
	my $input  = $_[0];
	my $digits = $_[1];
	my $number = "0"x($digits - length($input)) . "$input";
	return $number;
}

sub getStat
{
  my $chromNum = $_[0];

  if ( ! $chromNum )
  {
      die "CHROMOSSOME NOT DEFINED";
  }
  elsif ( ! $chromNum =~ /^\d+$/ )
  {
      $chromNum = $chromos{$chromNum};
  };

  if ((defined $stat[$chromNum]) && (keys %{$stat[$chromNum]}))
  {
    my %response = %{$stat[$chromNum]};
    return \%response;
  } #end if defined stat
  else
  {
    die "ERROR GETTING STATISTICS FROM $chromNum " . reverseHash($chromNum);
  }
}


sub fixStat
{
  my @tempStat;
  for (my $chrom = 0; $chrom < @stat; $chrom++)
  {
	next if ( ! (defined $stat[$chrom]) );
    for (my $id = 0; $id < @{$stat[$chrom]}; $id++)
    {
	  next if ( ! (defined $stat[$chrom][$id]) );

      foreach my $key (sort keys %{$stat[$chrom][$id]})
      {
		my $value = $stat[$chrom][$id]{$key};
		$value = decode_base64($value);
		if ($value =~ /:/)
		{
		my @array = split(":",$value);
		$value = \@array;
		}
		$tempStat[$chrom]{$key} = $value;

      } #end foreach my key
    } # end foreach my id
  } # end foreach my chrom
  @stat = @tempStat;
  undef @tempStat;
}



sub readFasta
{
	my $inputFA  = $_[0];
	my $chromNum = $_[1];
	my $chromName;
	my $desiredLine;
# 	undef @gene;

# 	print "READING FASTA $chromNum\n";
	if ( $chromNum =~ /^\d+$/ )
	{
		if ( eval { $desiredLine = $chromosMap{&reverseHash($chromNum)} } )
		{
			$chromName   = &reverseHash($chromNum);
		}
		else
		{
			die "CHROMOSSOME $chromNum NOT FOUND IN FASTA";
		}
	}
	elsif ( $chromNum =~ /[\w+]/)
	{
		if ( eval { $desiredLine = $chromosMap{$chromNum} } )
		{
			$chromName   = $chromNum;
		}
		else
		{
			die "CHROMOSSOME $chromNum NOT FOUND IN FASTA";
		}
	}
	else
	{
		die "CHROMOSSOME $chromNum NOT FOUND IN FASTA";
	}




	if ( $chromName ne $geneName )
	{
		undef @gene; $gene[0] = "";
		open FILE, "<$inputFA" or die "COULD NOT OPEN $inputFA: $!";
	
		my $current;
		my $chromo;
		my $chromoName;
	
		my $on   = 0;
		my $pos  = 0;
		my $line = 1;

		$geneName = $chromName;

# 		print "DESIRE $desiredLine $chromName\n";
		seek(FILE, $desiredLine-200, 0);	
		while (<FILE>)
		{
# 			if ($line >= $desiredLine)
# 			{
				chomp;
				if (( /^>/) && ($on))
				{
					$on   = 0;
					$pos  = 1;
# 					print "LAST\n";
					last;
				}
		
				if ($on)
				{
					foreach my $nuc (split("",$_))
					{
						if ( ! defined $chromos{$chromoName})
						{ 
							my $next = (keys %chromos)+1;
							$chromos{$chromoName} = $next;
# 							print "CHROMOSSOME $chromo IS NUMBER $next\n";
						}
						$current = $chromos{$chromoName};
# 						print "CURRENT $current\n";
	# 					$XMLpos{$current}{$pos++}{"orig"} = $nuc;
						push(@gene,$nuc);
# 						print $nuc;
						undef $current;
					}
		# 			push(@{$seq[$chromo]}, (split("",$_)));
				}
		
				if (/^>$chromName/)
				{
# 					print ">$chromName\n";
					$on         = 1;
					$chromoName = $chromName;
					$pos        = 1;
				}
# 				else
# 				{
# 					print "$_\n";
# 					die;
# 				}
# 			}
			$line++;
		}
# 		print "FASTA LOADED\n";
	# 	print "\n\n";
		undef $chromo;
		close FILE;
	}
# 	else
# 	{
# 		print "CHROM $chromName IN LINE $desiredLine ALREADY IN MEMORY ($geneName)\n";
# 	}
	if ( ! @gene ) { die "NO GENE READ\n";};
	return \@gene;
# 	return \%XMLpos;
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
# 	my $tell = 0;

	while (<FILE>)
	{
		chomp;
		if ( /^>/)
		{
			$on   = 0;
			$pos  = 1;
		}

		if ($on)
		{
			foreach my $nuc (split("",$_))
			{
				if ( ! defined $chromos{$chromo})
				{ 
					my $next             = (keys %chromos)+1;
					$chromos{$chromo}    = $next;
# 					$stat[$next]{"size"} = 0;
				}
				#$stat[$chromos{$chromo}]{"size"}++;
			}
# 			$tell = tell(FILE);
		}

		if (/^>(.*)/)
		{
			$on     = 1;
			$chromo = $1;
			$pos    = 1;
			$chromosMap{$chromo} = tell(FILE);
# 			$chromosMap{$chromo} = $line;
		}
		$line++;
	}
	undef $chromo;
	close FILE;
}

sub positionTable
{
	my @unsorted = @{$_[0]};

	my %seen     = ();
	my @sorted   = grep { ! $seen{$_} ++ } @unsorted;
	   @sorted   = (sort { $a <=> $b}  @sorted);
	my $totalSeq = &max(@sorted);

	my $list = "";
	for (my $s = 0; $s < @sorted; $s += 10)
	{
		my $max    = $s+9;
		if ($max  >= @sorted-1) { $max = @sorted-1; };
		for (my $i = $s; $i <= $max; $i++)
		{
			$list .= "0"x((length $totalSeq) - (length $sorted[$i])) . $sorted[$i] . "\t";
		}
		$list .= "\n";
	}
# 	print "$list";
	return $list;
}


sub reverseHash
{
	my $chromNum = $_[0];
	my %temp;
	foreach my $chromName (keys %chromos)
	{
		my $value = $chromos{$chromName};
		$temp{$value} = $chromName;
	}
	return $temp{$chromNum}; # return the name
}



sub consensus
{
	my @array = @_;
	my $output;

	if (@array == 1)
	{
		my $new = ${$array[0]}{"new"};
		if ($new eq ".") {$new = "X";};
		$output .= lc($new);
	# 	print "SINGLE ON $id POS $j " . @{$new{$j}} . "\n";
	}
	else
	{
		my $prev  = "";
		my $equal = 1;
	
		foreach my $part (@array)
		{
			my $new = ${$part}{"new"};
			if ($prev eq "")   { $prev = $new; };
			if ($prev ne $new) { $equal = 0;   };
		}
	
		if ($equal)
		{
		# 	print "DUAL NEW ON $id POS $j " . @{$new{$j}};
			my $new = ${$array[0]}{"new"};
			if ($new eq ".") {$new = "X";};
			$output .= uc($new);
		#	print " EQUAL $new";
		}
		else
		{
			print "*" x20 . "DUAL NEW : " . @array . " DIFF ";
			foreach my $part (@array)
			{
				my $new = ${$array[$part]}{"new"};
				if ($new eq ".") {$new = "X";};
				$output .= "$new+";
				print "$new ";
			}
			print "\n";
		}
	} # end if more than 1 element
	return $output;
}


sub consensusProg
{
	my @array = @_;
	my $output = "";

	if (@array == 1)
	{
		my $new = ${$array[0]}{"program"};
		$output .= $new;
	}
	else
	{
		foreach my $part (sort @array)
		{
			if ($output) { $output .= "+" . ${$part}{"program"}; }
			else         { $output .= ${$part}{"program"}; };
		}

	}
	return $output;
}


sub consensusSimple
{
	my @array;
	my $output = "";

	if (defined $_[0])
	{
		@array = @_;

# 		print @array;
# 		sleep 3;

		if (@array == 1)
		{
			my $new = $array[0];
# 			if (uc($new) eq "X") {$new = "X";};
# 			if ($new     eq "+") {$new = "+";};
			$output .= lc($new);
		# 	print "SINGLE ON $id POS $j " . @{$new{$j}} . "\n";
		}
		elsif (@array > 1)
		{
			my $prev  = "";
			my $equal = 1;
		


# a       1
# c       2
# t       4
# g       8
# x		 16
# +		 32
# r ag    9
# y ct    6
# m ca    3
# k tg   12
# w ta    5
# s cg   10
# b ctg  14
# d atg  13
# h atc   7
# v acg  11
# n actg 15
my %letters;
$letters{"A"} =  1; 
$letters{"C"} =  2;
$letters{"T"} =  4;
$letters{"G"} =  8;
$letters{"X"} = 16;
$letters{"+"} = 32;
my %sum;
$sum{"3"}  = "M";
$sum{"5"}  = "W";
$sum{"6"}  = "Y";
$sum{"7"}  = "H";
$sum{"9"}  = "R";
$sum{"10"} = "S";
$sum{"11"} = "V";
$sum{"12"} = "K";
$sum{"13"} = "D";
$sum{"14"} = "B";
$sum{"15"} = "N";
$sum{"16"} = "X";
$sum{"32"} = "+";

my %seen;

			foreach my $part (@array)
			{
				if ($prev eq "")    { $prev  = $part; };
				if ($prev ne $part) { $equal = 0;   };

				   if (uc($part) eq "A") {$seen{"A"} = 1;}
				elsif (uc($part) eq "C") {$seen{"C"} = 1;}
				elsif (uc($part) eq "T") {$seen{"T"} = 1;}
				elsif (uc($part) eq "G") {$seen{"G"} = 1;}
				elsif (uc($part) eq "X") {$seen{"X"} = 1;}
				elsif (uc($part) eq "+") {$seen{"+"} = 1;}
				elsif (uc($part) eq "M") {$seen{"C"} = 1; $seen{"A"} = 1;}
				elsif (uc($part) eq "W") {$seen{"T"} = 1; $seen{"A"} = 1;}
				elsif (uc($part) eq "Y") {$seen{"C"} = 1; $seen{"T"} = 1;}
				elsif (uc($part) eq "H") {$seen{"A"} = 1; $seen{"T"} = 1; $seen{"C"} = 1;}
				elsif (uc($part) eq "R") {$seen{"A"} = 1; $seen{"G"} = 1;}
				elsif (uc($part) eq "S") {$seen{"C"} = 1; $seen{"G"} = 1;}
				elsif (uc($part) eq "V") {$seen{"A"} = 1; $seen{"C"} = 1; $seen{"G"} = 1;}
				elsif (uc($part) eq "K") {$seen{"T"} = 1; $seen{"G"} = 1;}
				elsif (uc($part) eq "D") {$seen{"A"} = 1; $seen{"T"} = 1; $seen{"G"} = 1;}
				elsif (uc($part) eq "B") {$seen{"C"} = 1; $seen{"T"} = 1; $seen{"G"} = 1;}
				elsif (uc($part) eq "N") {$seen{"T"} = 1; $seen{"G"} = 1; $seen{"A"} = 1; $seen{"C"} = 1;}
				else { print "WHAT DOES MEANS THIS SIMBOL?... $part"; die; };
			}
		
			if ($equal)
			{
			# 	print "DUAL NEW ON $id POS $j " . @{$new{$j}};
				my $new = $array[0];
# 				if ($new =~ /[A|C|T|G|a|c|t|g]/) {$new = "*";};
				$output .= uc($new);
			#	print " EQUAL $new";
			}
			else
			{
# 				print "*" x10 . "DUAL NEW : " . @array . " DIFF ";
				my $sum = 0;
				for my $letter (keys %seen)
				{
					if (defined $letters{$letter})
					{
						$sum+= $letters{$letter};
					}
					else
					{
						die "I DONT UNDERSTAND THIS LETTER... $letter";
					}
				}

				if (($sum < 16) && ($sum > 0))
				{
					$output = $sum{$sum};
				}
				elsif (($sum == 16) || ($sum == 32))
				{
					$output = $sum{$sum};
				}
				elsif (($sum > 16) && ($sum < 32))
				{
					$output = "Z";
				}
				elsif (($sum > 32) && ($sum < 48))
				{
					$output = "-";
				}
				elsif (($sum == 48))
				{
					$output = "*";
				}
				elsif (($sum > 48))
				{
					$output = "^";
				}
				else
				{
					foreach my $part (@array)
					{
						my $new = $part;
# 						if (uc($new) eq "X") {$new = "*";};
						$output .= "$new+";
						print "$new ";
					}
					die "IM GOING CRAZY HERE ($sum)";
				}

				if ( ! $output )
				{ 
					foreach my $part (@array)
					{
						my $new = $part;
# 						if (uc($new) eq "X") {$new = "*";};
						$output .= "$new+";
						print "$new ";
					}
					die "SOMETHIG WRONG ($sum): ";
				}

# 				if ((((exists $seen{"X"}) || (exists $seen{"x"})) && (exists $seen{"+"})) && ($total == 0))
# 				{
# 					$total = -6;
# 				}
# 				elsif ((((exists $seen{"X"}) || (exists $seen{"x"})) && (exists $seen{"+"})) && ($total > 0))
# 				{
# 					$total = -5;
# 				}
# 				elsif ((exists $seen{"+"}) && ($total == 0))
# 				{
# 					$total = -4;
# 				}
# 				elsif ((exists $seen{"+"}) && ($total > 0))
# 				{
# 					$total = -3;
# 				}
# 				elsif (((exists $seen{"X"}) || (exists $seen{"x"})) && ($total == 0))
# 				{
# 					$total = -2;
# 				}
# 				elsif (((exists $seen{"X"}) || (exists $seen{"x"})) && ($total > 0))
# 				{
# 					$total = -1;
# 				}

# 				foreach my $part (@array)
# 				{
# 					my $new = $part;
# 					if (uc($new) eq "X") {$new = "*";};
# 					$output .= "$new+";
# 					print "$new ";
# 				}



# 				print "($total)\n";
			}
		} # end elsif @array has more than 1 element
		else
		{
			$output = "";
		}
	} #end if $_[0]
	else
	{
		$output = "";
	}

	return $output;
}


sub consensusProgSimple
{
	my @array;
	my $output = "";

	if (defined $_[0])
	{
		@array = @_;

		if (@array == 1)
		{
			my $new  = $array[0];
			$output  = $new;
		}
		elsif (@array > 1)
		{
			foreach my $part (sort @array)
			{
				if ($output) { $output .= "+" . $part; }
				else         { $output .= $part; };
			}
		}
		else
		{
			$output = "";
		}
	}
	else
	{
		$output = "";
	}

	return $output;
}

sub consensusProgArray
{
	my @array = @_;
	my @output;

	if (@array == 1)
	{
		my $new = ${$array[0]}{"program"};
		$output[0] = $new;
	}
	else
	{
		foreach my $part (sort @array)
		{
			push(@output, ${$part}{"program"});
		}
	}
	return @output;
}



# sub arrayFasta
# {
# 	my $inputFa = $_[0];
# 	undef %seq;
# 	my $on = 0;
# 	open FILE, "<$inputFA" or die "COULD NOT OPEN $inputFA: $!";
# 	my $title;
# 	while (<FILE>)
# 	{
# 		chomp;
# 		if ( /^>/)
# 		{
# 			$on   = 0;
# 		}
# 
# 		if ($on)
# 		{
# 			push(@{$seq[$title]}, (split("",$_)));
# 		}
# 
# 		if (/^>(.*)/)
# 		{
# 			$on    = 1;
# 			$title = $1;
# 		}
# 	}
# 	undef $title;
# 	close FILE;
# 	return \%seq;
# }

sub loadXML
{
	my $file = $_[0];
	#%XMLpos   =  %{&parseXML($file)};

	@XMLtemp = @{&parseXML($file)};

	if ($rootType eq "pos")
	{
		@XMLpos   = @XMLtemp;
	}
	elsif ($rootType eq "stat")
	{
		@stat     = @XMLtemp;
	}
	else
	{
		die "UNKNOWN ROOT TYPE";
	}
	undef @XMLtemp;
}


sub mergeHash
{
	my @hashes = @_;

	my %merged;
	foreach my $hashRef (@hashes)
	{
		while ((my $k, my $v) = each %{$hashRef})
		{
			if (exists $merged{$k})
			{
				while ((my $kk, my $vv) = each %{$v})
				{
					$merged{$k}{$kk} = $vv;
				}
			}
			else
			{
				$merged{$k} = $v;
			}
		}
	}

	return \%merged;
}

sub parseXML
{
	my $file = $_[0];
	open FILE, "<$file" or die "COULD NOT OPEN FILE $file: $!";

	my $row         = 0;
	my $table       = 0;
	my $tableName   = "";
	my $registerT   = 0;
	my $registerTot = 0;
	my @XMLhash;
	my $currId      = "";

	foreach my $line (<FILE>)
	{
		if ($line =~ /<root id=\"(.*)\" type=\"(.*)\">/)
		{
			$rootType = $2 ;
		}
		if ($line =~ /<table id=\"(.*)\" type=\"(.*)\">/)
		{
			$table     = 1;
			$tableName = $1;
			$tableType = $2;
		}
		if ($line =~ /<\/table>/)
		{
			$table     = 0;
			$tableName = "";
# 			$register  = 0;
			$registerT++;
		}
		if ($line =~ /<row( id=\"(\d+)\")*>/)
		{
			if (defined $2)
			{
			  $currId = $2;
			}
			else
			{
			  $currId = $registre;
			}
			$row = 1;
		}
		elsif ($line =~ /<\/row>/)
		{
			$row = 0;
			$registre++;
			$registerTot++;
		}
		if ($row)
		{
			if ($line =~ /<(\w+)>(.+)<\/\1>/)
			{
# 				print "$line\n";
				my $key   = $1;
				my $value = $2;
# 				print "$register => $key -> $value\n";
				if ($tableName)
				{
# 					print "$tableName $register $key $value\n";
# 					$XMLhash{$tableName}{$registre}{$key} = $value;
					$XMLhash[$chromos{$tableName}][$currId]{$key} = $value;
					#print "{" . $chromos{$tableName} . "}{$currId}{$key} = $value;\n";
				}
				else
				{
					die "TABLE NAME NOT DEFINED IN XML $file\n";
				}
			}
		}
	}

	close FILE;
	print "  FILE $file PARSED: $registerTot REGISTERS RECOVERED FROM $registerT TABLES\n";
	print "  ROOT TYPE: $rootType TABLE TYPE: $tableType\n";
	return \@XMLhash;
}

sub printGD
{
	my $heig  = $_[0];
	my $chunk = $_[1];
	my $GD    = $_[2];
	my $format = "png";
	if ( ! ( $heig && $chunk && $GD )) { die "NOT ENOUGH PARAMETERS PASSED TO PRINGD FUNCTION";};
	my $out;
	print "\t\t\tPRINTING IMAGES:\n";
	if ($heig > $chunk)
	{
		print "\t\t\t\tHEIGHT BIGGER THAN CHUNK ($heig vs $chunk)\n";
		$out = &splitGD($heig, $chunk, $GD);
	}
	else
	{
		print "\t\t\t\tPRINTING SINGLE IMAGE\n";
		$out = "<img width=\"1024\" height=\"$heig\" src=\"data:image/$format;base64," . (encode_base64($GD->$format)) . "\"/>\n";
	}
	return $out;
}

sub splitGD
{
	my $heig  = $_[0];
	my $chunk = $_[1];
	my $GD    = $_[2];
	if ( ! ( $heig && $chunk && $GD )) { die "NOT ENOUGH PARAMETERS PASSED TO SPLITGD FUNCTION";};
	bless $GD,"GD::Image";

	my $imgtot = (int($heig / $chunk) + 1);
	my $out = "";

	for (my $i = 1; $i <= $imgtot; $i++)
	{
		print "\t\t\t\t\tPRINTING PART $i OF $imgtot\n";
		my $start = ($i - 1) * $chunk;
		my $end   = $i * $chunk;
		$end = $heig if ($end > $heig);
		my $size = $end-$start;
		my $image = new GD::Image(1024,($size));
		$image->copy($GD,0,0,0,$start,1024,$chunk);
		$out .= "<img width=\"1024\" height=\"$size\" src=\"data:image/png;base64," . (encode_base64($image->png)) . "\"/>\n";
	}
	print "\t\t\t\t\tDONE\n";
	return $out;
}




sub list_dir
{
	my $dir = $_[0];
	my $ext = $_[1];
# 	print "openning dir $dir and searching for extension $ext\n";

	opendir (DIR, "$dir") or die "CANT READ DIRECTORY $dir: $!\n";
	my @ext = grep { (!/^\./) && -f "$dir/$_" && (/$ext$/)} readdir(DIR);
	closedir DIR;

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

sub genCoverage
{
	my @rep = @{$_[0]};
	my $start;
	my $end;
	my %cov;
	my $total   = @rep;
	my $covered = 0;

	for (my $i = 0; $i < @rep; $i++)
	{
		if ($rep[$i])
		{
			$start = $i+1;
			while ($rep[++$i]) {};
			$end   = $i+1;
			$covered += ($end-$start);
			$i--;
			$cov{$start} = $end; 
		};
	}
	$cov{"cov"} = $covered;
	return \%cov;
}

exit 0;

1;
