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

my $side = 20;

# PRINTS XML FILES CONTAINING SNPS IN HTML FILES WITH EMBEDED IMAGES
# INPUTS: XML FILE NAME
#         FASTA ORIGNAL GENOME FILE NAME

my $inputFA  = $ARGV[0];
my $inputPos = $ARGV[1];

my $outputHTML; # output HTML file
my $outputFA;   # output FASTA file
# my $id;
my $rootType;   # type of the root  XML class
my $tableType;  # type of the table XML class
my %XMLsnp;     # SNPs from XMLs
my %XMLgap;     # GAPs from XMLs
my %XMLblast;   # BLASTSs from XMLs
my %XMLpos;     # information from XMLs organized by position
my %XMLtemp;	# tempXML
my %seq;	# temp sequence
my %gen;	# temp gen
my %new;	# temp new
my %chromos;    # NAME > NUMBER
my %chromosMap; # NAME > LINE
my %stat;       # CHROM NUM > STATISTICS
my %blastKey;   # gene id > gene name
my %geneArray;  # chrom num > start pos > gene id
my @image;	# images HTML code
my @gene;       # current gene nucleotides
my $geneName  = ""; # current gene name
my $registre  = 0;
my $iterating = 0;

if (($inputFA) && (@inputXML)) #checks if all parameters are set
{
	if ( -f $inputFA )
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
			die "INVALID FASTA FILE $inputFA";
		}
	
		$outputHTML  = "html/$output.html";
		$outputFA    = "fasta/$output.fasta";
	
		print "  INPUT  FASTA: $inputFA\n";
		print "  INPUT  XML  :\n\t" . join("\n\t", @inputXML) . "\n";
		print "  OUTPUT HTML : $outputHTML\n";
		print "  OUTPUT FASTA: $outputFA\n";
		print "\n";
		mkdir "html";
		mkdir "fasta";

		if ( -f $inputPos )
		{
			&loadXML($inputPos); #obtains the xml as hash
		}
		else
		{
			my $exit;
			if (( ! -f $inputPos) && ( ! -d $inputPos)) { $exit  = "FILE $inputPos DOESNT EXISTS\n";};
			print $exit;
			exit 1; 
		}

		&start($inputFA,$output);

	} # end if file INPUTFA exists
	else
	{
		my $exit;
		if ( ! -f $inputFA)  { $exit .= "FILE $inputFA  DOESNT EXISTS\n";};
		print $exit;
		exit 1; 
	} # end else file INPUTFA exists
} # end if FA & XML were defined
else
{
	print "USAGE: XML_IMAGE.PL <INPUT FASTA.FASTA> <MULTIPLE INPUT XML or INPUT DIR, SNP or GAP>\n";
	print "E.G.: ./xml_image.pl ../../inputs/R265_cryptococcus_neoformans_serotype_b_1_supercontigs.fasta xml_merged/snps.xml ../gaps/cns.indelse.chrom.xml\n";
	print "E.G.: ./xml_image.pl input.fasta input.snp.xml input.gap.xml\n";
	print "E.G.: ./xml_image.pl input.fasta xml_merged/ input.gap.xml\n";
	print "E.G.: ./xml_image.pl input.fasta input.snp.xml input.gap.xml  input.blast.xml\n";
	exit 1;
}


sub exportData
{
# \%XMLpos, \%chromos, \%chromoMap, \%stat, \%blastKey, \%geneArray

my @output;
$output[0] = \%XMLpos;
$output[1] = \%chromos;
$output[2] = \%chromosMap;
$output[3] = \%stat;
$output[4] = \%blastKey;
$output[5] = \%geneArray;


# 			if ( ! defined $blastKey{$id} ) { $blastKey{$id} = $gene; };
# 
# 			if ($start > $end) { my $temp = $start; $start = $end; $end = $temp; }
# 			push (@{$stat{$chromNum}{"BLAST_prog_pos"}{$prog}}, $start);
# 			$XMLpos{$chromNum}{$start}{"gene"}  = $id;
# 			$geneArray{$chromNum}{$start} = $id;
# 
# 			for (my $i = ($start+1); $i <= $end; $i++)
# 			{
# 				push (@{$stat{$chromNum}{"BLAST_prog_pos_total"}{$prog}}, $i);
# 				$geneArray{$chromNum}{$i} = $id;
# 			$XMLpos{$chromNum}{$start}{"gap"}  = $indel;
# 			push (@{$stat{$chromNum}{"SNP_prog_pos"}{$prog}}, $pos);
# 			push(@{$XMLpos{$chromNum}{$pos}{"new"}},  $new);
# 			push(@{$XMLpos{$chromNum}{$pos}{"prog"}}, $prog);

# root xmlpos type data
# 	table chromnum
# 		row pos
# 			@new
# 			@prog
# 			$gene
# 		row
# 	table
# root
# root stat type data
# 	table chromnum
# 		row SNP_prog_pos
# 			subRow prog
# 	 			@pos
# 			subRow
# 		row
# 	table
# root
# root geneArray type data
# 	table chromnum
# 		row pos
# 			$id
# 		row
# 	table
# root
# root blastkey type data
# 	table id
# 		row gene
# 		row
# 	table
# root







}

sub start
{
	my $inputFA = $_[0];
	my $output  = $_[1];

	print "  GENERATING CHROMOSSOMES TABLE...";
	&genChromos($inputFA);
	print "done\n";

	$outputHTML  = "html/$output.html";
	$outputFA    = "fasta/$output.fasta";

	print "  MERGING DATA...";	
	%XMLpos = %{&mergeData(\%XMLsnp, \%XMLgap, \%XMLblast, $inputFA)};
	print "done\n";	
	undef %XMLsnp;
	undef %XMLgap;
	undef %XMLblast;

# 	&exportData(); # to do

	&print_fasta_general(\%XMLpos, $inputFA); #prints fasta (text mode)
# 	&print_graphics(\%XMLpos, $inputFA);

# 
# 	my @html; # @html = @{&print_snps_simple(\%XMLsnp,$inputFA)};
# 
# 	if (@html)
# 	{
# 		open FILE, ">$outputHTML" or die "COULD NOT CREATE OUTPUT FILE $outputHTML: $!";
# 		print "\tGENERATING $outputHTML\n";
# 		print FILE @html; #prints snps 
# 		close FILE;
# 	}
# 	else
# 	{
# 		print "NO HTML GENERATED\n";
# 	}
# 	&printStat;


# 13588 saulo     20   0 5998m 5.7g 2272 R   99 73.2   0:55.80 xml_image.pl  
# 13915 saulo     20   0 5998m 5.7g 2272 R  100 73.2   0:55.49 xml_image.pl 
# 14239 saulo     20   0 5998m 5.7g 2272 R  101 73.2   0:55.83 xml_image.pl 
# 14652 saulo     20   0  157m  16m 2264 R  101  0.2   0:21.66 xml_image.pl  CHROMOS MAP
# 14776 saulo     20   0  157m  16m 2264 R  101  0.2   0:21.80 xml_image.pl  CHROMOS MAP + snp + gap	
# 15817 saulo     20   0  457m 311m 2276 R   81  3.9   0:51.34 xml_image.pl  CHROMOS MAP + snp + gap + merge
# 16715 saulo     20   0  457m 311m 2276 R  101  3.9   0:49.64 xml_image.pl  CHROMOS MAP + snp + gap + merge 
# 17801 saulo     20   0 1059m 913m 2280 R  101 11.4   4:06.37 xml_image.pl  WHOLE
# 28470 saulo     20   0 1108m 962m 2280 R   98 12.0   4:00.40 xml_image.pl  WHOLE 200901161346
# 4222  saulo     20   0  790m 644m 2280 R  101  8.1   2:47.50 xml_image.pl  WHOLE 200901161853
#  6674 saulo     20   0  938m 792m 2280 R   99  9.9   3:30.55 xml_image.pl  WHOLE HTML 200901191429
# 2359    4084416K        3938396K        99      48.1    3:00.87 xml_image.pl WHOLE SELECT 200901281836
# 6808    4168320K        4022300K        99      49.1    6:24.34 xml_image.pl WHOLE SELECT 200901281841


# 	snp		 	0477m	0330m	0:51
#	gap 		 	0808m	0662m	0:24
#	blast			1618m	1472m	0:42
#	snp + gap		0794m	0648m	0:55
#	snp + gap + blast	2254m	2108m	1:17
#	snp + gap + blast2	3101m	29558m	1:18



}


sub mergeData
{
	%XMLsnp     = %{$_[0]};
	%XMLgap     = %{$_[1]};
	%XMLblast   = %{$_[2]};
	my $inputFA =   $_[3];
	undef %XMLpos;
	my %unique;
	my $prog;
	my $chrom;
	my @prog;
	my @new;

	foreach my $table (keys %XMLsnp)
	{
		foreach my $register (keys %{$XMLsnp{$table}})
		{
			undef $prog;
			undef $chrom;
			undef @prog;
			undef @new;
			my $new  = $XMLsnp{$table}{$register}{"new"};
			my $orig = $XMLsnp{$table}{$register}{"orig"};
			my $pos  = $XMLsnp{$table}{$register}{"posOrig"};

			if ( ! ((defined $new) && (defined $orig) && (defined $pos))) { die "COULD NOT GET NEW, ORIGINAL AND POSITION"};

			my $chromNum;

			if ($tableType eq "chromossome")
			{
				$prog     = $XMLsnp{$table}{$register}{"program"};
				$chrom    = $table;
				$chromNum = $chromos{$chrom};
			}
			elsif ($tableType eq "program")
			{
				$prog     = $table;
				$chrom    = $XMLsnp{$table}{$register}{"chromR"};
				$chromNum = $chromos{$chrom};
			}
			else
			{
				die "UNKNOWN KIND OF TABLE TYPE: $tableType\n";
			}

			if ( &reverseHash($chromNum) ne $geneName )
			{
# 				print "$chromNum (" . &reverseHash($chromNum) . " > $geneName";
				@gene = @{&readFasta($inputFA, $chromNum)};
				if ( ! @gene) { die "COULD NOT READ GENE FROM CHROMOSSOME $chrom"; }; # else {print " (" . @gene . "bp) \n";};
				$stat{$chromNum}{"size"} = (@gene - 1);
			}

			my $origFA   = $gene[$pos];

			if ( $orig eq "." )
			{
# 				die "ORIGNINAL FROM SNP $orig IS DIFFERENT FROM FASTA $origFA\n";
				$new = tr/ACTGactg/12341234/;
	# 			$XMLpos{$chromNum}{$pos}{"orig"} = $orig;
			}
			elsif ( $new eq "." )
			{
# 				die "ORIGNINAL FROM SNP $orig IS DIFFERENT FROM FASTA $origFA\n";
				$new = tr/ACTGactg/56785678/;
	# 			$XMLpos{$chromNum}{$pos}{"orig"} = $orig;
			}
			elsif ( $orig ne $origFA )
			{
				die "ORIGNINAL FROM SNP $orig IS DIFFERENT FROM FASTA $origFA IN POSITION $pos IS WRONG ON TABLE $table REGISTER $register PROGRAM $prog\n";
	# 			$XMLpos{$chromNum}{$pos}{"orig"} = $orig;
			}
# 			else
# 			{
# 				die "ORIGNINAL FROM SNP $orig IN POSITION $pos IS WRONG ON TABLE $table REGISTER $register PROGRAM $prog ($new)\n";
# 			}
	
# 			if (defined $stat{$chromNum}{"prog"}{$prog}) { $stat{$chromNum}{"prog"}{$prog}++; } else { $stat{$chromNum}{"prog"}{$prog} = 1; };
# 			if (defined $stat{$chromNum}{"snps"}       ) { $stat{$chromNum}{"snps"}++; }        else { $stat{$chromNum}{"snps"}        = 1; };

			if ( ! eval { $stat{$chromNum}{"SNP_prog_count"}{$prog}++ }) { $stat{$chromNum}{"SNP_prog_count"}{$prog} = 1; }

			push (@{$stat{$chromNum}{"SNP_prog_pos"}{$prog}}, $pos);
			push(@{$XMLpos{$chromNum}{$pos}{"new"}},  $new);
			push(@{$XMLpos{$chromNum}{$pos}{"prog"}}, $prog);
		} #end foreach my table
	} #end foreach my register
	undef %unique;


	undef $prog;
	undef $chrom;
	undef @prog;
	undef @new;

	foreach my $table (keys %XMLgap)
	{
		foreach my $register (keys %{$XMLgap{$table}})
		{
			undef $prog;
			undef $chrom;
			undef @prog;
			undef @new;
# 
			my $chromNum;
 
			if ($tableType eq "chromossome")
			{
				$prog     = $XMLgap{$table}{$register}{"program"};
				$chrom    = $table;
				$chromNum = $chromos{$chrom};
			}
			elsif ($tableType eq "program")
			{
				$prog     = $table;
				$chrom    = $XMLgap{$table}{$register}{"chromR"};
				$chromNum = $chromos{$chrom};
			}
			else
			{
				die "UNKNOWN KIND OF TABLE TYPE: $tableType\n";
			}

			if ( ! ((defined $prog) && (defined $chromNum)))
			{
				die "COULD NOT GET PROGRAM OR CHROMOSSOME NUMBER FROM TABLE $table REGISTER NUMBER $register PROG $prog CHROM $chrom CHROMNUM $chromNum";
			}

			my $start  = $XMLgap{$table}{$register}{"start"};
			my $end    = $XMLgap{$table}{$register}{"end"};
			my $length = $XMLgap{$table}{$register}{"length"};
			my $reads  = $XMLgap{$table}{$register}{"reads"};
			my $rLeft  = $XMLgap{$table}{$register}{"rLeft"};
			my $rRight = $XMLgap{$table}{$register}{"rRight"};
			my $id     = $XMLgap{$table}{$register}{"id"};

			if ( ! ((defined $start) && (defined $end) && (defined $length) && (defined $id)))
			{
				die "COULD NOT GET START, END, LENGTH AND ID FROM TABLE $table REGISTER NUMBER $register ID $id PROG $prog CHROM $chrom CHROMNUM $chromNum";
			}

			if   ( ! eval  { $stat{$chromNum}{"GAP_prog_count"}{$prog}++ }) { $stat{$chromNum}{"GAP_prog_count"}{$prog} = 1; }

			my $indel; 
			if ( $length >= 0 )     { $indel = "+"; } else { $indel = "X"; };
			if ( $prog eq "eland" ) { $indel = "X"; };

			push (@{$stat{$chromNum}{"GAP_prog_pos"}{$prog}}, $start);
			$XMLpos{$chromNum}{$start}{"gap"}  = $indel;

			for (my $i = ($start+1); $i <= $end; $i++)
			{
				$XMLpos{$chromNum}{$i}{"gap"} = $indel;
				push (@{$stat{$chromNum}{"GAP_prog_pos_total"}{$prog}}, $i);
			}
# 			$max = $pos if ($pos > $max);
		} #end foreach my register
	} #end foreach my table
	undef %unique;


	undef $prog;
	undef $chrom;
	undef @prog;
	undef @new;
			my $total;
	foreach my $table (keys %XMLblast)
	{
# 		print "\tTABLE $table\n";
		foreach my $register (keys %{$XMLblast{$table}})
		{
# 			print "\t\tREGISTER $register\n";
			undef $prog;
			undef $chrom;
			undef @prog;
			undef @new;
# 
			my $chromNum;
 
			if ($tableType eq "chromossome")
			{
				$prog     = $XMLblast{$table}{$register}{"method"};
				$chrom    = $table;
				$chromNum = $chromos{$chrom};
			}
			elsif ($tableType eq "program")
			{
				$prog     = $table;
				$chrom    = $XMLblast{$table}{$register}{"chromR"};
				$chromNum = $chromos{$chrom};
			}
			else
			{
				die "UNKNOWN KIND OF TABLE TYPE: $tableType\n";
			}

			my $start  = $XMLblast{$table}{$register}{"start"};
			my $end    = $XMLblast{$table}{$register}{"end"};
			my $length = $XMLblast{$table}{$register}{"Qrylen"};
			my $sign   = $XMLblast{$table}{$register}{"sign"};
			my $ident  = $XMLblast{$table}{$register}{"ident"};
			my $consv  = $XMLblast{$table}{$register}{"consv"};
			my $gaps   = $XMLblast{$table}{$register}{"gaps"};
			my $strand = $XMLblast{$table}{$register}{"strand"};
			my $gene   = $XMLblast{$table}{$register}{"gene"};
			my $id     = $XMLblast{$table}{$register}{"id"};

			# $positives{$method}{$result->query_name}{"ident"}   = &roundFrac($hsp->frac_identical *100);
			# $positives{$method}{$result->query_name}{"consv"}   = &roundFrac($hsp->frac_conserved *100);
			# $positives{$method}{$result->query_name}{"sign"}    = $hit->significance;
			# $positives{$method}{$result->query_name}{"Hlength"} = $hsp->length('hit');
			# $positives{$method}{$result->query_name}{"Qlength"} = $hsp->length('query');
			# $positives{$method}{$result->query_name}{"Tlength"} = $hsp->length('total');
			# $positives{$method}{$result->query_name}{"Qrylen"}  = $result->query_length;
			# $positives{$method}{$result->query_name}{"start"}   = $hsp->start('hit');
			# $positives{$method}{$result->query_name}{"end"}     = $hsp->end('hit');
			# $positives{$method}{$result->query_name}{"strand"}  = $hsp->strand('hit');
			# my $name = $hit->name; $name =~ s/lcl\|//;
			# $positives{$method}{$result->query_name}{"chromR"}  = $name;
			# $positives{$method}{$result->query_name}{"gaps"}    = $hsp->gaps;
			# $data{"method"} = $method;
			# $data{"gene"}   = $gene;


			if ( ! ((defined $start) && (defined $end) && (defined $length) && (defined $sign) && (defined $ident) && (defined $consv) && (defined $gaps) && (defined $strand) && (defined $gene)))
			{
				die "COULD NOT GET START, END, LENGTH, READS, LEFT AND RIGHT FROM TABLE $table REGISTER NUMBER $register ID $gene";
			}

# 			print "$chromNum $chrom $start $end $length $sign $ident $consv $gaps $strand $gene\n";
# 			if   ( ! eval  { $stat{$chromNum}{"GAP_prog_count"}{$prog}++ }) { $stat{$chromNum}{"GAP_prog_count"}{$prog} = 1; }
 
			if ( ! defined $blastKey{$id} ) { $blastKey{$id} = $gene; };

			if ($start > $end) { my $temp = $start; $start = $end; $end = $temp; }
			push (@{$stat{$chromNum}{"BLAST_prog_pos"}{$prog}}, $start);
			$XMLpos{$chromNum}{$start}{"gene"}  = $id;
			$geneArray{$chromNum}{$start} = $id;
# 			$XMLpos{$chromNum}{$start}{"gene_info"}  = $gene;

			for (my $i = ($start+1); $i <= $end; $i++)
			{
				push (@{$stat{$chromNum}{"BLAST_prog_pos_total"}{$prog}}, $i);
				$geneArray{$chromNum}{$i} = $id;
			}

# 			$max = $pos if ($pos > $max);
		} #end foreach my register
	} #end foreach my table
	undef %unique;
	return \%XMLpos;
}


sub print_fasta_general
{
	%XMLpos  = %{$_[0]};
	$inputFA =   $_[1];

	open FASTA1, ">$outputFA\_SHORT"              or die "COULD NOT CREATE OUTPUT FILE $outputFA\_SHORT: $!";
	open FASTA2, ">$outputFA\_LONG"               or die "COULD NOT CREATE OUTPUT FILE $outputFA\_LONG: $!";
	open FASTA5, ">$outputFA\_LONG_SELECTION"     or die "COULD NOT CREATE OUTPUT FILE $outputFA\_LONG_SELECTION: $!";
	open FASTA3, ">$outputFA\_NEW"                or die "COULD NOT CREATE OUTPUT FILE $outputFA\_NEW: $!";
	open FASTA4, ">$outputFA\_NEW.html"           or die "COULD NOT CREATE OUTPUT FILE $outputFA\_NEW.html: $!";
	print "\tGENERATING $outputFA\_SHORT\n";
	print "\tGENERATING $outputFA\_LONG\n";
	print "\tGENERATING $outputFA\_LONG_SELECTION\n";
	print "\tGENERATING $outputFA\_NEW\n";
	print "\tGENERATING $outputFA\_NEW.html\n";

	my %outProg;

	undef %seq;
	undef %gen;
	my $head;
	my $output2;
	my %resume;

	foreach my $chromNum (sort {$a <=> $b} keys %XMLpos)
	{
		undef $output2;
		if ( $chromNum ne $geneName)
		{
			@gene = @{&readFasta($inputFA, $chromNum)};
		}

		my $chromName = &reverseHash($chromNum);

		my %response      = %{&getStat($chromNum)};
		my $snp_progs     = $response{"SNP_prog"};       # $Str
		my $snp_positions = $response{"SNP_pos"};        # $Int
		my $snp_countU    = $response{"SNP_count_u"};    # $Int
		my $gap_progs     = $response{"GAP_prog"};       # $Str
		my $gap_positions = $response{"GAP_pos"};        # $Int
		my $gap_countU    = $response{"GAP_count_u"};    # $Int
		my $totalSeq      = $response{"size"};           # $Int

		my $number;

		$head .= "INPUT FASTA: $inputFA\n";
		$head  = "INPUT XML  :\n\t" . join("\n\t", @inputXML) . "\n";
		$head .= "CHROMOSSOME: " . $chromName . "($totalSeq" . "bp)\n";
		if ($response{"SNP"})
		{
			$head .= "TOTAL SNPS : $snp_countU\n";
			$head .= "POS   SNPS :\n$snp_positions\n";
		}
		if ($response{"GAP"})
		{
			$head .= "TOTAL GAPS : $gap_countU\n";
			$head .= "POS   GAPS :\n$gap_positions\n";
		}
		print FASTA1 $head; print FASTA2 $head; print FASTA3 $head; print FASTA4 &htmlador($head); print FASTA5 $head;

		undef %seq;
		undef %gen;

		%seq = %{$XMLpos{$chromNum}};
		%gen = %{$geneArray{$chromNum}};

		my $outGene;
		my $outOri;
		my $outNew;
		my $tempOutNew;
		my $tempOutOld;
		my $output;
		my $ind;
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
			my $ii = $i + 59;
			while ($ii > $totalSeq) {($ii--)};

# 			print "$chromo " . (keys %seq) . " $i $ii\n";

			$number = &fixDigit($i,$lengthTotalSequence);

			undef $outGene;
			undef $outOri;
			undef $outNew;
			undef $tempOutNew;
			undef $output;

	# 		LONG
			for (my $z = $i; $z <= $ii; $z++)
			{
				my $out;
				if ( exists $gen{$z} )
				{
					$selection += 1000;
					my $gen     = $blastKey{$gen{$z}};
					if ($gen eq $currGene)
					{
						$currGeneCount++;
 						if ($currGeneCount < ($currGeneStrLen+1))
						{
							my $pos = $currGeneCount - 1;
							$out = substr($currGeneStr, $pos, 1);
# 							$out = "X";
						}
 						elsif (($currGeneCount >= $currLeft) && ($currGeneCount < $currRight))
						{
							my $pos = $currGeneCount - $currLeft;
							$out = substr($currGeneStr, $pos, 1);
# 							$out = "X";
						}
 						elsif (($currGeneCount >= ($currGeneSize - ($currGeneStrLen))) && ($currGeneCount != $currGeneSize) && ($currGeneSize >= ($currGeneStrLen+2))) 
						{
							my $pos = $currGeneCount - ($currGeneSize - ($currGeneStrLen));
							if ( ! $currGeneStr ) { die };
							
							if ( eval {'$out = substr($currGeneStr, $pos, 1)'}) { print "$currGeneStr $pos $currGeneSize $currGeneStrLen\n"; $out = " "; };
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
						}
					}
					else
					{
						my $y = $z;
						$currGeneSize   = 0;
						while ((exists $gen{$y}) && ($gen{$y} eq $gen{$z})) { $currGeneSize++; $y++; }
						$currGeneCount  = 1;
						$currGeneStart  = $z;
						$currGeneEnd    = $y;
						$currGene       = $gen;
						$currGeneStr    = "$gen\[$currGeneStart;$currGeneEnd;$currGeneSize\]";
						$currGeneStrLen = length($currGeneStr);
						$currLeft       = int(($currGeneSize/2)-($currGeneStrLen/2));
						$currRight      = int(($currGeneSize/2)+($currGeneStrLen/2));
# 						print "CURGENE $currGene GENE $gen COUNT $currGeneCount START $currGeneStart END $currGeneEnd SIZE $currGeneSize\n";
						$out = "<";
# 						print "CURGENE $currGene GENE $gen COUNT $currGeneCount START $currGeneStart END $currGeneEnd SIZE $currGeneSize\n";
					}
				} #end if exists gene
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
				}
				$outGene .= $out;


				$outOri  .= $gene[$z];
				if (( exists $seq{$z} ) && ( ( exists ${$seq{$z}}{"gap"} ) || ( exists ${$seq{$z}}{"new"} ) ))
				{
					my $outNewRGap;
					my $outNewRSnp;
					if ( exists ${$seq{$z}}{"gap"} )
					{
						$selection += 1;
						$outNewRGap = $seq{$z}{"gap"};
					}
					if ( exists ${$seq{$z}}{"new"} )
					{
						$selection += 1;
						$outNewRSnp = &consensusSimple(@{$seq{$z}{"new"}});
					}

					if (( $outNewRGap ) && ( $outNewRSnp ))
					{
						if ($outNewRGap eq "+")
						{
							$outNewRSnp =~ tr/ACTGactg/BDUHBDUH/;
						}
						else
						{
							$outNewRSnp =~ tr/ACTGactg/bduhbduh/;
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
					}
# 					else
# 					{
# 						$outNew .= ".";
# 					}
				} # end if exists seq_z
				else
				{
					$outNew  .= ".";
				}
			} # end for my z long

			$output  = "$number $outGene ANNOTATION\n";
			$output .= "$number $outOri REFERENCE\n";
			$output .= "$number $outNew NEW\n\n";
			print FASTA2 $output;
			print FASTA5 $output if ($selection > 1000);
			undef $output;


#	 		SHORT
			for (my $z = $i; $z <= $ii; $z++)
			{
				undef $tempOutNew;
				undef $tempOutOld;
				undef $outNew;
				undef $outOri;

# 				$XMLpos{$chromNum}{$start}{"gap"} = $id;
				if (( exists $seq{$z} ) && ( ( exists ${$seq{$z}}{"gap"} ) or ( exists ${$seq{$z}}{"new"} ) ))
				{
					my $start = $z - $side;
					my $end   = $z + $side;

					if ( exists $gen{$z} ) { $resume{$chromNum}{"pos"}{$gen{$z}}++; };

					$tempOutOld = $gene[$z];
# 					@program    = $seq{$z}{"orig"};

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
						if (exists $seq{$r}{"gap"})	{ $outNewRGap = $seq{$r}{"gap"}; }
						if (exists $seq{$r}{"new"})	{ $outNewRSnp = &consensusSimple(@{$seq{$r}{"new"}}); }

						if (( $outNewRGap ) && ( $outNewRSnp))
						{
							if ($outNewRGap eq "+")
							{
								$outNewRSnp =~ tr/ACTGactg/BDUHBDUH/;
							}
							else
							{
								$outNewRSnp =~ tr/ACTGactg/bduhbduh/;
							}
							$outNew    .= $outNewRSnp;
						}
						elsif ( $outNewRGap )	{ $outNew .= $outNewRGap; }
						elsif ( $outNewRSnp)	{ $outNew .= $outNewRSnp; }
						else			{ $outNew .= " ";	  }
					}

					my $desc;
					my $descSNP = "";
					my $descGAP = "";

					if ( exists $seq{$z}{"gap"} )
					{
						   $tempOutNew    = $seq{$z}{"gap"};
						my $tempOutOldGap = $tempOutOld;
						my $a = $z;
						my $mut;
						my $mutL = 1;

						if ($tempOutNew eq "+")
						{
							$mut = "INS";
							while (( exists ${$seq{$a}}{"gap"} ) && ( exists ${$seq{$a+1}}{"gap"} ) && ($a < $totalSeq)) { $a++; };
							$mutL = $a - $z + 1;
						}
						else
						{
							$mut = "DEL";
							while (( exists ${$seq{$a}}{"gap"} ) && ( exists ${$seq{$a+1}}{"gap"} ) && ($a < $totalSeq)) { $a++; $tempOutOldGap .= $gene[$a]; };
							$mutL = $a - $z + 1;
						}
						my $A    = &fixDigit($a,     $lengthTotalSequence);;
						$descGAP = " $mut ($Z - $A) " . $tempOutNew x $mutL . " ($tempOutOldGap)"
					}
					if ( exists $seq{$z}{"new"} )
					{
						$tempOutNew = &consensusSimple(@{$seq{$z}{"new"}});
						$descSNP    = " SNP ($tempOutOld > $tempOutNew)";
					} # end if exists SNP

					if (( exists $seq{$z}{"gap"} ) && ( exists $seq{$z}{"new"} ))
					{
						$tempOutNew = &consensusSimple(@{$seq{$z}{"new"}});
						if ($seq{$z}{"gap"} eq "+")
						{
							$tempOutNew =~ tr/ACTGactg/BDUHBDUH/;
						}
						else
						{
							$tempOutNew =~ tr/ACTGactg/bduhbduh/;
						}
					}
					$desc = "$Z$descSNP$descGAP";

					my %genes;
					for (my $r = $start; $r <= $end; $r++)
					{
						if (exists $seq{$r}{"gene"}) { $genes{$seq{$r}{"gene"}} = 1; };
					}
					$desc .= " { GENES: " . join("; ", (sort keys %genes)) . " }" if ((keys %genes));

					$output  = "$number " . "_"x$mLeft . "$outOri" . "_"x$mRight . "\n";
					$output .= "$number " . " "x$mLeft . "$outNew" . " "x$mRight . " $desc\n\n";

				} # end if exists seq_z AND (GAP or SNP)
				else
				{
					if ( exists $gen{$z} ) { $resume{$chromNum}{"neg"}{$gen{$z}}++; };
				}

				if ($output) { print FASTA1 $output };
				undef $output;
				while (( exists ${$seq{$z}}{"gap"} ) && ( exists ${$seq{$z+1}}{"gap"} ) && ( ! exists ${$seq{$z+1}}{"new"} ) && ($z < $totalSeq)) { $z++; };
			} # end for my z short
		} # end for i < @seq +=60

# 		NEW
		undef $output2;
		for (my $z = 1; $z <= $totalSeq; $z++)
		{
			if (( exists $seq{$z} ) && ( ( exists ${$seq{$z}}{"gap"} ) or ( exists ${$seq{$z}}{"new"} ) ))
			{
				my $outNewRGap;
				my $outNewRSnp;
				if ( exists ${$seq{$z}}{"gap"} )
				{
					$outNewRGap = $seq{$z}{"gap"};
				}
				if ( exists ${$seq{$z}}{"new"} )
				{
					$outNewRSnp = &consensusSimple(@{$seq{$z}{"new"}});
				}
	
				if (( $outNewRGap ) && ( $outNewRSnp ))
				{
					$outNewRSnp = $gene[$z];
					if ($outNewRGap eq "+")
					{
						$outNewRSnp =~ tr/ACTGactg/BDUHBDUH/;
					}
					else
					{
						$outNewRSnp =~ tr/ACTGactg/bduhbduh/;
					}
					$output2 .= $outNewRSnp;
				}
				elsif ( $outNewRGap )
				{
					if ($outNewRGap eq "+")
					{
						$outNewRGap = "+";
						while (( exists ${$seq{$z}}{"gap"} ) && ( exists ${$seq{$z+1}}{"gap"} ) && ( ! exists ${$seq{$z+1}}{"new"} ) && ($z < $totalSeq)) { $z++; $outNewRGap .= "+";};
					}
					else
					{
						$outNewRGap = "_";
						while (( exists ${$seq{$z}}{"gap"} ) && ( exists ${$seq{$z+1}}{"gap"} ) && ( ! exists ${$seq{$z+1}}{"new"} ) && ($z < $totalSeq)) { $z++; $outNewRGap .= "_";};
					}
	
					$output2 .= $outNewRGap;
				}
				elsif ( $outNewRSnp)
				{
					$output2 .= $outNewRSnp; 
				}
			} # end if exists seq_z
			else
			{
				$output2 .= $gene[$z];
			}
		} #end for my z < totalseq

		$output2 = &faster($output2);
		print FASTA3 $output2;
		print FASTA4 &colorFasta($output2);
		undef $output2;
	} #end foreach my chromo


	open FASTA6, ">$outputFA\_RESUME_POS" or die "COULD NOT CREATE OUTPUT FILE $outputFA\_RESUME_POS: $!";
	open FASTA7, ">$outputFA\_RESUME_NEG" or die "COULD NOT CREATE OUTPUT FILE $outputFA\_RESUME_NEG: $!";
	foreach my $chromNum (sort {$a <=> $b} keys %resume)
	{
		my $chromName = &reverseHash($chromNum);
		my $totalPos  = (keys %{$resume{$chromNum}{"pos"}});
		my $totalNeg  = (keys %{$resume{$chromNum}{"neg"}});
		my $totalChr  = $totalPos + $totalNeg;
		my $totalGlo  = (keys %blastKey);
		print FASTA6 "$chromName ($totalPos/$totalChr/$totalGlo)\n";
		print FASTA7 "$chromName ($totalNeg/$totalChr/$totalGlo)\n";
		foreach my $id (sort {$a <=> $b} keys %{$resume{$chromNum}{"pos"}})
		{
			my $count = $resume{$chromNum}{"pos"}{$id};
			my $gen   = $blastKey{$id};
			print FASTA6 "\t$gen\t$count\n";
		}

		foreach my $id (keys %{$resume{$chromNum}{"neg"}})
		{
			my $count = $resume{$chromNum}{"neg"}{$id};
			my $gen   = $blastKey{$id};
			print FASTA7 "\t$gen\t0\n";
		}
	}
	close FASTA7;
	close FASTA6;

	close FASTA5;
	close FASTA4;
	close FASTA3;
	close FASTA2;
	close FASTA1;
	my $cmd = "cat $outputFA\_RESUME_POS | grep -iv hypothetical > $outputFA\_RESUME_POS_VALID";
	   $cmd = "cat $outputFA\_RESUME_NEG | grep -iv hypothetical > $outputFA\_RESUME_NEG_VALID";
	if (system($cmd)) { print "FAILED TO GENERATE RESUME_VALID\n" };
	undef %seq;
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
	my $seq  = $_[0];
	my @seq  = split ("", $seq);
	my $size = @seq;
# 	print "size $size\n";
	$seq = "";
	for (my $i = 0; $i < $size; $i+=60)
	{
		my $end = $i+59;
# 		print "start $i end $end\n";
		while ($end >= $size) { $end--; };
		$seq .= join("", @seq[$i .. $end]);
		$seq .= "\n";
	}
# 	print $seq;
	return $seq;
}


sub print_graphics
{
	%XMLsnp      = %{$_[0]};
	my $inputSNP = $_[1];

	undef @image;
	undef %new;

	foreach my $table (sort (keys %XMLsnp))
	{
		my $total = 0;
		my $max   = 0;
		undef %new;

		foreach my $key (sort { $a <=> $b } (keys %{$XMLsnp{$table}}))
		{
			my $pos    = $XMLsnp{$table}{$key}{"posOrig"};
			$new{$pos} = $XMLsnp{$table}{$key};
			$max       = $pos if ($pos >= $max);
		} # end foreach my keys
		$max += 5000;

		my $panel = Bio::Graphics::Panel->new(
					-length    => ($max*1.1),
					-width     => 1024,
# 					-key_style => 'between',
					-pad_left  => 10,
					-pad_right => 100,
					);

		my @rep   = ("0") x ($max+1);
		my %features;
		my $feature;
		print "\t\tANALYSING POSITION #: ";
		my $poscount = 1;

		foreach my $pos (keys %new)
		{
			print "$poscount " if (( ! ($poscount % 100)) || ($poscount == 1));
			$poscount++;
			my $orig = $new{$pos}{"orig"};
			my $new  = $new{$pos}{"new"};
			my $prog = $new{$pos}{"program"};
			undef $feature;

			$feature = Bio::SeqFeature::Generic->new(
							-display_name =>"$pos $orig->$new ($prog)",
							-start        =>$pos,
							-end          =>($pos+1),
							-connector    =>'dashed',
# 							-tag          =>{ description => "REF:$contextR QUERY:$contextQ FRAME:$frame"},
							);
			$features{$pos} = $feature;
			if (($pos > $max) || ($pos < 0)) { die "START $pos IS ILEGAL ($max)"};

			if (defined $rep[$pos])
			{
				$rep[$pos] = 1;
			}
			else
			{
				die "ERROR IN LOGIC $pos IN \@REP DOESNT EXISTS";
			}
			$total++;
		}
		print "DONE\n";
		my %cov = %{&genCoverage(\@rep)};

		my $full_length = Bio::SeqFeature::Generic->new(
						-start        =>1,
						-end          =>$max,
						-display_name =>"$inputSNP || $table (~$max" . "bp) || ($total SNPs)"
						);

		$panel->add_track($full_length,
					-glyph   => 'arrow',
					-tick    => 3,
					-fgcolor => 'black',
					-double  => 1,
					-label   => 1,
					);


		my $track = $panel->add_track(	-glyph       => 'generic',
	# 							-double      => 1,
						-label       => 1,
						-connector   =>'dashed',
						-bgcolor     => 'blue',
# 						-description =>"COVERAGE " . $cov{"cov"} . "/$size",
# 						-key =>"COVERAGE " . $cov{"cov"} . "/$size",
# 						-label =>"COVERAGE " . $cov{"cov"} . "/$size",
							);

		foreach my $start (keys %cov)
		{
		if ($start ne "cov")
		{
			my $cov = Bio::SeqFeature::Generic->new(
							-start        =>$start,
							-end          =>$cov{$start},
# 							-display_name =>"coverage"
							);
			$track->add_feature($cov);
		}
		}

		my $idx    = 0;
		my @colors = qw(cyan orange gray blue gold purple green chartreuse magenta yellow aqua pink marine cyan);

		print "\t\tADDING TAG: ";

		my $tagcount = 1;
		foreach my $tag (sort { $a <=> $b} (keys %features))
		{
			print "$tagcount "  if (( ! ($tagcount % 100)) || ($tagcount == 1));
			$tagcount++;
			$panel->add_track($features{$tag},
					-glyph       =>  'generic',
					-bgcolor     =>  $colors[$idx++ % @colors],
					-fgcolor     => 'black',
					-font2color  => 'red',
					-connector   => 'dashed',
# 					-key         => $tag,
					-bump        => +1,
					-height      => 8,
					-label       => 1,
					-description => 1,
					);
		}#END FOR MY TAG
		print "DONE\t";
		push (@image, &printGD($panel->height, 10240, $panel->gd));
		$panel->finished;
		print " " x12 . "TABLE $table SNPs = $total\n";
	} # end foreach my table

	return \@image;
} #end sub parse_snps_img


sub fixDigit
{
	my $input  = $_[0];
	my $digits = $_[1];
	my $number = "0"x($digits - length($input)) . "$input";
	return $number;
}


sub printStat
{
	foreach my $chrom (sort keys %stat)
	{
	foreach my $key (sort keys %{$stat{$chrom}})
	{
		my $value = $stat{$chrom}{$key};
		if (ref $value eq "ARRAY")
		{
			print "$chrom >> $key = " . join("\t", @{$value}) . "\n";
		}
		elsif  (ref $value eq "HASH")
		{
			foreach my $subKey (keys %{$value})
			{
				my $subValue = ${$value}{$subKey};
				print "$chrom >> $key - $subKey = " . $subValue . "\n";
			}
		}
# 		elsif  (ref $value eq "SCALAR")
# 		{
# 			print "$chrom >> $key = $value\n";
# 		}
		else
		{
# 			print "KEY $key HAS VALUE $value WHICH IS A REF: " . (ref $value) . "\n";
			print "$chrom >> $key = $value\n";
		}
	}
	}
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

	if ((defined $stat{$chromNum}) && (keys %{$stat{$chromNum}}))
	{
		my %hash = %{$stat{$chromNum}};
		my %response;
		my @positions_both;
		my @progs;
		my @positions;

		my $size = $hash{"size"};         # size of the chromossome

		if (defined %{$hash{"SNP_prog_pos"}})
		{

			my %SNP_prog_pos   = %{$hash{"SNP_prog_pos"}}; # $prog > @pos	
			my %SNP_prog_pos_count; # $prog > @pos	
			my @SNP_prog       = (keys %{$hash{"SNP_prog_pos"}}); # $prog > @pos	
			my @SNP_pos;     #positions of the SNPs
			foreach my $prog (@SNP_prog) { push(@SNP_pos, @{$SNP_prog_pos{$prog}}); };
			my %seen           = ();
			my @sorted         = grep { ! $seen{$_} ++ } @SNP_pos;
			   @SNP_pos        = (sort { $a <=> $b} @sorted);

			foreach my $pro ( keys %SNP_prog_pos)
			{
				my @proPos                = @{$SNP_prog_pos{$pro}};
				my $programsP             = &positionTable(\@proPos);
				$SNP_prog_pos{$pro}       = $programsP;
				$SNP_prog_pos_count{$pro} = @proPos;
			}

			my $SNP_count_u    =   0;

			foreach my $po (@SNP_pos)
			{
				$positions_both[$po]++;
				$SNP_count_u++;
			}

			push(@progs, @SNP_prog);
			push(@positions, @SNP_pos);
			my $SNP_prog  = &consensusProgSimple(\@SNP_prog);
			my $SNP_pos   = &positionTable(\@SNP_pos);

			$response{"SNP_prog"}  	 = $SNP_prog;    # $Str
			$response{"SNP_pos"}  	 = $SNP_pos;     # $Str
			$response{"SNP_prog_A"}	 = \@SNP_prog;   # @Str
			$response{"SNP_pos_A"}   = \@SNP_pos;    # @Int
			$response{"SNP_count_u"} = $SNP_count_u; # $Int
			$response{"SNP"} = 1;
		}
		else
		{
			$response{"SNP"} = 0;
		}

		if (defined %{$hash{"GAP_prog_pos"}})
		{
			my %GAP_prog_pos   = %{$hash{"GAP_prog_pos"}}; # $prog > @pos	
			my %GAP_prog_pos_count; # $prog > @pos	
			my @GAP_prog       = (keys %{$hash{"GAP_prog_pos"}}); # $prog > @pos	
			my @GAP_pos;     #positions of the SNPs
			foreach my $prog (@GAP_prog) { push(@GAP_pos, @{$GAP_prog_pos{$prog}}); };
			my %seen           = ();
			my @sorted         = grep { ! $seen{$_} ++ } @GAP_pos;
			   @GAP_pos        = (sort { $a <=> $b} @sorted);

			foreach my $pro ( keys %GAP_prog_pos)
			{
				my @proPos                = @{$GAP_prog_pos{$pro}};
				my $programsP             = &positionTable(\@proPos);
				$GAP_prog_pos{$pro}       = $programsP;
				$GAP_prog_pos_count{$pro} = @proPos;
			}

			my $GAP_count_u    =   0;

			foreach my $po (@GAP_pos)
			{
				$positions_both[$po]++;
				$GAP_count_u++;
			}

			push(@progs, @GAP_prog);
			push(@positions, @GAP_pos);
			my $GAP_prog  = &consensusProgSimple(\@GAP_prog);
			my $GAP_pos   = &positionTable(\@GAP_pos);

			$response{"GAP_prog"}  	 = $GAP_prog;    # $Str
			$response{"GAP_pos"}  	 = $GAP_pos;     # $Str
			$response{"GAP_prog_A"}	 = \@GAP_prog;   # @Str
			$response{"GAP_pos_A"}   = \@GAP_pos;    # @Int
			$response{"GAP_count_u"} = $GAP_count_u; # $Int
			$response{"GAP"} = 1;
		}
		else
		{
			$response{"GAP"} = 0;
		}


		if (defined %{$hash{"BLAST_prog_pos"}})
		{
			my %GAP_prog_pos   = %{$hash{"BLAST_prog_pos"}}; # $prog > @pos	
			my %GAP_prog_pos_count; # $prog > @pos	
			my @GAP_prog       = (keys %{$hash{"BLAST_prog_pos"}}); # $prog > @pos	
			my @GAP_pos;     #positions of the SNPs
			foreach my $prog (@GAP_prog) { push(@GAP_pos, @{$GAP_prog_pos{$prog}}); };
			my %seen           = ();
			my @sorted         = grep { ! $seen{$_} ++ } @GAP_pos;
			   @GAP_pos        = (sort { $a <=> $b} @sorted);

			foreach my $pro ( keys %GAP_prog_pos)
			{
				my @proPos                = @{$GAP_prog_pos{$pro}};
				my $programsP             = &positionTable(\@proPos);
				$GAP_prog_pos{$pro}       = $programsP;
				$GAP_prog_pos_count{$pro} = @proPos;
			}

			my $GAP_count_u    =   0;

			foreach my $po (@GAP_pos)
			{
				$positions_both[$po]++;
				$GAP_count_u++;
			}

			push(@progs, @GAP_prog);
			push(@positions, @GAP_pos);
			my $GAP_prog  = &consensusProgSimple(\@GAP_prog);
			my $GAP_pos   = &positionTable(\@GAP_pos);

			$response{"BLAST_prog"}    = $GAP_prog;    # $Str
			$response{"BLAST_pos"}     = $GAP_pos;     # $Str
			$response{"BLAST_prog_A"}  = \@GAP_prog;   # @Str
			$response{"BLAST_pos_A"}   = \@GAP_pos;    # @Int
			$response{"BLAST_count_u"} = $GAP_count_u; # $Int
			$response{"BLAST"} = 1;
		}
		else
		{
			$response{"BLAST"} = 0;
		}


		for (my $po = 0; $po < @positions_both; $po++)
		{
			if (defined $positions_both[$po])
			{
				if ($positions_both[$po] > 1)
				{
					print "IN CHROMOSSOME $chromNum THE POSITION $po PRESENTS BOTH A SNP AND A INDEL\n";
				}
			}
		}

		if ( ! defined $size) { die   "COULD NOT GET SIZE"     . " FOR CHROMOSSOME $chromNum " . $chromos{$chromNum} . "\n"; };
		if ( ! @progs )       { print "COULD NOT GET PROGRAMS" . " FOR CHROMOSSOME $chromNum " . $chromos{$chromNum} . "\n"; @progs = (); };

		my $programs  = &consensusProgSimple(\@progs);
		my $positions = &consensusProgSimple(\@positions);

		$response{"programs"}  	 = $programs;    # $Str
		$response{"positions"} 	 = $positions;   # $Str
		$response{"size"}  	 = $size;        # $Int

# 
# 		$response{"progA"} 	 = @progs;       # @Str
# 		$response{"posSnp"}   	 = $posSnp;      # $Int
# 		$response{"posSnpA"}  	 = @posSnp;      # @Int
# 		$response{"snps"}  	 = $snps;        # $Int
# 		$response{"snpsU"} 	 = $snpsU;       # $Int
# 		$response{"progP"} 	 = %progsPos;    # % prog > @positions (int)
# 		$response{"progC"} 	 = %progsCount;  # % prog > $count (Int)
# 		$response{"programsPos"} = %programsPos; # % prog > $positions (Str)

	# 	print "$progs $pos $snps\n";
		return \%response;
	}
	else
	{	die "ERROR GETTING STATISTICS FROM $chromNum " . $chromos{$chromNum};
	}
}


sub readFasta
{
	my $inputFA  = $_[0];
	my $chromNum = $_[1];
	my $chromName;
	my $desiredLine;
	undef @gene;

# 	print "READING FASTA $chromNum\n";
	if ( $chromNum =~ /^\d+$/ )
	{
		if ( eval { $desiredLine = $chromosMap{&reverseHash($chromNum)} } )
		{
			$chromName   = &reverseHash($chromNum)
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
		# 			push(@{$seq{$chromo}}, (split("",$_)));
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
					$stat{$next}{"size"} = 0;
				}
				$stat{$chromos{$chromo}}{"size"}++;
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
		if ($new eq ".") {$new = "*";};
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
			if ($new eq ".") {$new = "*";};
			$output .= uc($new);
		#	print " EQUAL $new";
		}
		else
		{
			print "*" x100 . "DUAL NEW ON @array " . @array . " DIFF ";
			foreach my $part (@array)
			{
				my $new = ${$array[$part]}{"new"};
				if ($new eq ".") {$new = "*";};
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
			if ($new eq ".") {$new = "*";};
			$output .= lc($new);
		# 	print "SINGLE ON $id POS $j " . @{$new{$j}} . "\n";
		}
		elsif (@array > 1)
		{
			my $prev  = "";
			my $equal = 1;
		
			foreach my $part (@array)
			{
				if ($prev eq "")    { $prev = $part; };
				if ($prev ne $part) { $equal = 0;   };
			}
		
			if ($equal)
			{
			# 	print "DUAL NEW ON $id POS $j " . @{$new{$j}};
				my $new = $array[0];
				if ($new eq ".") {$new = "*";};
				$output .= uc($new);
			#	print " EQUAL $new";
			}
			else
			{
				print "*" x100 . "DUAL NEW ON @array " . @array . " DIFF ";
				foreach my $part (@array)
				{
					my $new = $part;
					if ($new eq ".") {$new = "*";};
					$output .= "$new+";
					print "$new ";
				}
				print "\n";
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
# 			push(@{$seq{$title}}, (split("",$_)));
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
	%XMLpos   =  %{&parseXML($file)};
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
	my %XMLhash;
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
			if (defined $1)
			{
			  $currId = $1;
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
			if ($line =~ /<(\w+)>(\S+)<\/\1>/)
			{
# 				print "$line\n";
				my $key   = $1;
				my $value = $2;
# 				print "$register => $key -> $value\n";
				if ($tableName)
				{
# 					print "$tableName $register $key $value\n";
# 					$XMLhash{$tableName}{$registre}{$key} = $value;
					$XMLhash{$tableName}{$currId}{$key} = $value;
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
	return \%XMLhash;
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





































# sub print_snps_simple
# {
# 	%XMLsnp      = %{$_[0]};
# 	my $inputSNP = $_[1];
# 
# 	my @image;
# 	my %new;
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
# 		my %cov = &genCoverage(\@rep);
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
# 	return @image;
# } #end sub parse_snps_img
# 
# sub print_fasta_simple
# {
# 	%XMLsnp     = %{$_[0]};
# 	my $inputFA = $_[1];
# 	my %new;
# 	my %newP;
# 	my $max = 0;
# 	my @chroms;
# 
# 	foreach my $table (keys %XMLsnp)
# 	{
# 	foreach my $register (keys %{$XMLsnp{$table}})
# 	{
# 		if ($rootType eq "chromossome")
# 		{
# 			my $pos    = $XMLsnp{$table}{$register}{"posOrig"};
# 			my $prog   = $XMLsnp{$table}{$register}{"program"};
# 			my $chrom  = $table;
# 
# 			$newP{$prog}{$chrom}{$pos} = $XMLsnp{$table}{$register};
# 			push (@{$new{$chrom}{$pos}}, $XMLsnp{$table}{$register});
# 			$max    = $pos if ($pos > $max);
# 		}
# 		elsif ($rootType eq "program")
# 		{
# 			my $pos    = $XMLsnp{$table}{$register}{"posOrig"};
# 			my $prog   = $table;
# 			my $chrom  = $XMLsnp{$table}{$register}{"chromR"};
# 			$XMLsnp{$table}{$register}{"program"} = $table;
# 
# 			$newP{$prog}{$chrom}{$pos} = $XMLsnp{$table}{$register};
# 			push (@{$new{$chrom}{$pos}}, $XMLsnp{$table}{$register});
# 			$max    = $pos if ($pos > $max);
# 		}
# 		else
# 		{
# 			die "UNKNOWN KIND OF ROOT TYPE: $rootType\n";
# 		}
# 	}
# 	}
# 
# 
# 	my %seq = %{&arrayFasta($inputFA)};
# 
# 	foreach my $chromXML (sort keys %new)
# 	{
# 		if ( ! defined $seq{$chromXML})
# 		{
# 			if ($iterating)
# 			{
# 				print "COULD NOT FIND CHROMOSSOME $chromXML IN $inputFA\n";
# 			}
# 			else
# 			{
# 				die "COULD NOT FIND CHROMOSSOME $chromXML IN $inputFA\n";
# 			}
# 		}
# 		else
# 		{
# # 			print "CHROMOSSOME $chromXML TO BE ANALYZED AND FOUND IN FASTA FILE\n";
# 		}
# 	}
# 
# 
# 	open FASTA1, ">$outputFA\_SHORT" or die "COULD NOT CREATE OUTPUT FILE $outputFA: $!";
# 	open FASTA2, ">$outputFA\_LONG"  or die "COULD NOT CREATE OUTPUT FILE $outputFA: $!";
# 	print "\tGENERATING $outputFA\_SHORT\n";
# 	print "\tGENERATING $outputFA\_LONG\n";
# 	foreach my $chromo (sort keys %new)
# 	{
# 		my @seq      = @{$seq{$chromo}};
# 		my $totalSeq = @seq;
# 		my $number;
# # 
# 		my $head  = "INPUT XML  : $inputSNP\nINPUT FASTA: $inputFA\nCHROMOSSOME: $chromo ($totalSeq" . "bp)\nPROGRAMS   : " . join(" ",(sort keys %newP)) . "\n";
# 		   $head .= "TOTAL SNPS : " .  (keys %{$new{$chromo}}) . "\n";
# 		   $head .= "POSITIONS  :\n";
# 		print FASTA1 $head; print FASTA2 $head; 
# 
# 
# 
# 		my @sorted = (sort { $a <=> $b} (keys %{$new{$chromo}}));
# 		my $list;
# 		for (my $s = 0; $s < @sorted; $s += 10)
# 		{
# 			my $max = $s+9;
# 			if ($max >= @sorted-1) { $max = @sorted-1; };
# 			for (my $i = $s; $i <= $max; $i++)
# 			{
# 				$list .= "0"x((length $totalSeq) - (length $sorted[$i])) . $sorted[$i] . " " . ${$new{$chromo}{$sorted[$i]}[0]}{"orig"} . ">" . &consensus(@{$new{$chromo}{$sorted[$i]}}) . "\t";
# 			}
# 			$list .= "\n";
# 		}
# 		print FASTA1 "$list\n\n"; print FASTA2 "$list\n\n";
# 
# 
# 
# 		#SHORT
# 		foreach my $pos (@sorted)
# 		{
# 			my $orig  = ${$new{$chromo}{$pos}[0]}{"orig"};
# 			my $new   = &consensus(@{$new{$chromo}{$pos}});
# 			my $prog  = &consensusProg(@{$new{$chromo}{$pos}});
# 
# 			my $side   = 20;
# 			my $start  = $pos - $side - 1;
# 			my $end    = $pos + $side - 1;
# 	
# 			while ($start <  0)    {$start++;};
# 			while ($end   >= @seq) {$end--;  };
# 	
# 			my $text = join("", @seq[$start .. $end]);
# 	
# 			if ( ! (defined $start) ) { die "NO START $start $pos $end"; };
# 			if ( ! (defined $end)   ) { die "NO END   $start $pos $end"; };
# 			if ( ! (defined $text)  ) { die "NO TEXT  $text $start $pos $end"; };
# 
# 			my $numberS = "0"x(length($totalSeq) - length($start)) . ($start+1) . "";
# 			my $numberE = "0"x(length($totalSeq) - length($end))   . ($end+1)   . "";
# 
# 			my $left  = length($numberS) + 1 + ($pos - $start - 1) + (($side - ($pos-$start)) + 1);
# 			my $right = ($end - $pos   + 2);
# 			my $out  = $numberS  . " " . "_"x(($side - ($pos-$start)) + 1) .  $text . " "        . $numberE . "\n";
# 	# 		   $out .= " "x$left .                                "^"  . " "x$right . "\n";
# 			$out .= " "x$left .                              "$new" . " "x$right . "$prog ($pos $orig>$new)\n\n";
# 
# 			print FASTA1 $out;
# 		}
# 
# 
# 
# 
# 		#LONG
# 		for (my $i = 1; $i < @seq; $i+=60)
# 		{
# 			my $ii = $i + 58;
# 			while ($ii >= @seq) {($ii--)};
# # 	
# 			$number = "0"x(length($max) - length($i)) . "$i";
# 	
# 			my $output = "$number " . join("",@seq[$i-1 .. $ii]) . " REFERENCE\n";
# 	
# 			$output .= "$number ";
# # 			for (my $j = $i; $j <= $ii+1; $j++)
# # 			{
# # 				if (exists $new{$chromo}{$j})
# # 				{
# # 					my $orig = ${$new{$chromo}{$j}[0]}{"orig"};
# # 					if ($orig eq ".") {$orig = "^";};
# # # 					$output .= $orig;
# # 				}
# # 				else
# # 				{
# # # 					$output .= ".";
# # 				}
# # 			}
# # 			$output .= " OLD\n$number ";
# 			for (my $j = $i; $j <= $ii+1; $j++)
# 			{
# 				if (exists $new{$chromo}{$j})
# 				{
# 					$output .= &consensus(@{$new{$chromo}{$j}});
# 				}
# 				else
# 				{
# 					$output .= ".";
# 				}
# 			}
# 			$output .= " NEW\n\n";
# 			print FASTA2 $output;
# 		} # end for i < @seq
# 	} #end foreach my chromo
# 	close FASTA2;
# 	close FASTA1;
# 
# 
# 
# 
# 
# 
# 
# 
# 
# 
# 
# 
# 
# 	foreach my $prog (sort keys %newP)
# 	{
# 		open FASTAP, ">$outputFA\_SHORT_$prog" or die "COULD NOT CREATE OUTPUT FILE $outputFA: $!";
# 		print "\tGENERATING $outputFA\_SHORT_$prog\n";
# 		my $head  = "INPUT XML  : $inputSNP\nINPUT FASTA: $inputFA\nPROGRAM    : $prog\n\n\n";
# 		print FASTAP $head;
# 
# 		foreach my $chromo (sort keys %{$newP{$prog}})
# 		{
# 			my $total = keys %{$newP{$prog}{$chromo}};
# 
# 			my @seq      = @{$seq{$chromo}};
# 			my $totalSeq = @seq;
# # 			print "LENGTH $length\n";
# 
# 			my $header .= "CHROMOSSOME: $chromo ($totalSeq" . "bp)\n";
# 			   $header .= "TOTAL SNPS : $total\n";
# 			   $header .= "POSITIONS  : \n";
# 			print FASTAP $header;
# 
# 			my @sorted = sort { $a <=> $b} (keys %{$newP{$prog}{$chromo}});
# 
# 			for (my $s = 0; $s < @sorted; $s += 10)
# 			#prints a list of all positions in the header of the file
# 			{
# 				my $max   = $s+9;
# 				if ($max >= @sorted-1) { $max = @sorted-1; };
# # 				my $out  = join("\t", @sorted[$s .. $max]) . "\n";
# 				for (my $i = $s; $i <= $max; $i++)
# 				{
# 					my $out = "0"x((length $totalSeq) - (length $sorted[$i])) . $sorted[$i] . " " . $newP{$prog}{$chromo}{$sorted[$i]}{"orig"} . ">" . $newP{$prog}{$chromo}{$sorted[$i]}{"new"} . "\t";
# 					print FASTAP $out;
# 				}
# 				print FASTAP "\n";
# 			}
# 			print FASTAP "\n\n";
# 	
# 			foreach my $pos (@sorted)
# 			{
# 				my $orig   = $newP{$prog}{$chromo}{$pos}{"orig"};
# 				my $new    = $newP{$prog}{$chromo}{$pos}{"new"};
# 	
# 				my $side   = 10;
# 		
# 				my $start  = $pos - $side - 1;
# 				my $end    = $pos + $side - 1;
# 		
# 				while ($start <  0)    {$start++;};
# 				while ($end   >= @seq) {$end--;  };
# 		
# 				my $text = join("", @seq[$start .. $end]);
# 		
# 				if ( ! (defined $start) ) { die "NO START $start $pos $end"; };
# 				if ( ! (defined $end)   ) { die "NO END   $start $pos $end"; };
# 				if ( ! (defined $text)  ) { die "NO TEXT  $text $start $pos $end"; };
# 
# 				my $numberS = "0"x(length($totalSeq) - length($start)) . ($start+1) . "";
# 				my $numberE = "0"x(length($totalSeq) - length($end))   . ($end+1)   . "";
# 
# 				my $left  = length($numberS) + 1 + ($pos - $start - 1) + (($side - ($pos-$start)) + 1);
# 				my $right = ($end - $pos   + 2);
# 				my $out  = $numberS  . " " . "_"x(($side - ($pos-$start)) + 1) .  $text . " "        . $numberE . "\n";
# # 				   $out .= " "x$left .                                "^"  . " "x$right . "\n";
# 				   $out .= " "x$left .                              "$new" . " "x$right . "$prog ($pos $orig>$new)\n\n";
# 
# 				print FASTAP $out;
# 			}
# 		}
# 		close FASTAP;
# 	}
# 
# 
# 	foreach my $prog (sort keys %newP)
# 	{
# 		open FASTA3, ">$outputFA\_LONG_$prog" or die "COULD NOT CREATE OUTPUT FILE $outputFA: $!";
# 		print "\tGENERATING $outputFA\_LONG_$prog\n";
# 
# 		foreach my $chromo (sort keys %{$newP{$prog}})
# 		{
# 			my $total = keys %{$newP{$prog}{$chromo}};
# 	 		my @seq      = @{$seq{$chromo}};
# 			my $totalSeq = @seq;
# 	
# 			print FASTA3 "INPUT XML   : $inputSNP\nINPUT FASTA : $inputFA\nPROGRAM     : $prog\n";
# 			print FASTA3 "CHROMOSSOME : $chromo ($totalSeq" . "bp)\n";
# 			print FASTA3 "TOTAL SNPS  : $total\n";
# 			print FASTA3 "POSITIONS   :\n";
# 			my @sorted = (sort { $a <=> $b } (keys %{$newP{$prog}{$chromo}}));
# 
# 			my $number;
# 	
# 			for (my $s = 0; $s < @sorted; $s += 10)
# 			{
# 				my $max = $s+9;
# 				if ($max >= @sorted-1) { $max = @sorted-1; };
# # 				print FASTA3 join("\t", @sorted[$s .. $max]);
# 
# 				for (my $i = $s; $i <= $max; $i++)
# 				{
# 					print FASTA3 "0"x((length $totalSeq) - (length $sorted[$i])) . $sorted[$i] . " " . $newP{$prog}{$chromo}{$sorted[$i]}{"orig"} . ">" . $newP{$prog}{$chromo}{$sorted[$i]}{"new"} . "\t";
# 				}
# 
# 				print FASTA3 "\n";
# 			}
# 			print FASTA3 "\n\n";
# 
# 			for (my $i = 1; $i < @seq; $i+=60)
# 			{
# 				my $ii = $i + 58;
# 				while ($ii >= @seq) {($ii--)};
# 		
# 				$number = "0"x(length($max) - length($i)) . "$i";
# 		
# 				my $output = "$number " . join("",@seq[$i-1 .. $ii]) . " REFERENCE\n";
# 		
# 				$output   .= "$number ";
# # 				for (my $j = $i; $j <= $ii+1; $j++)
# # 				{
# # 					if (exists $newP{$prog}{$chromo}{$j})
# # 					{
# # # 						my $orig = $newP{$prog}{$chromo}{$j}{"orig"};
# # # 						if ($orig eq ".") {$orig = "^";};
# # # 						$output .= $orig;
# # 					}
# # 					else
# # 					{
# # # 						$output .= ".";
# # 					}
# # 				}
# 
# # 				$output .= " OLD\n$number ";
# 				for (my $j = $i; $j <= $ii+1; $j++)
# 				{
# 					if (exists $newP{$prog}{$chromo}{$j})
# 					{
# 						my $new  = $newP{$prog}{$chromo}{$j}{"new"};
# 						if ($new eq ".") {$new = "*";};
# 						$output .= $new;
# 					}
# 					else
# 					{
# 						$output .= ".";
# 					}
# 				}
# 				$output .= " NEW\n\n";
# 				print FASTA3 $output;
# 			}
# 		} #end foreach my chromo
# 		close FASTA3;
# 	} #end foreach my prog
# }