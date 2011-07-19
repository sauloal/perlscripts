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

my $outdir          = "out";
my $dir_mummer      = "mummer";
my $dir_mummer3     = "mummer3";
my $dir_nucmer      = "nucmer";
my @dirs_one_by_one = ("maq_run_4", "velvet_nu_03_1", "velvet_us_06_1", "velvet_wh_11_1", "velvet_wh_11_2", "velvet_wh_11_3");
my %tilingdb;
my %snpdb;
my $GD;

# my $format = "jpeg"; #27min 699mb
my $format = "png"; #23min 187mb

`rm -Rf html`;
mkdir "html";
my @allFiles;

# my $out_mummer  = &mummer_parser("$outdir/$dir_mummer");
# my $out_mummer3 = &mummer3_parser("$outdir/$dir_mummer3");
# &printHeader();
&nucmer_parser("$outdir/$dir_nucmer");
# &oneone_parser($outdir, \@dirs_one_by_one);

generateIndex();

# &printFoot();

sub nucmer_parser
{
	my $dir     = $_[0];
	my @subdirs = sort &list_subdir($dir);
	map { (my $name)  = ($_ =~ /^OUT_(.*)/); } @subdirs;

	print "dir\n";

	my %out;
	foreach my $subdir (@subdirs)
	{
		print " " x2 . "$subdir\n";
		(my $name)  = ($subdir =~ /^OUT_(.*)/);
		my @bases   = ("", "_SNP");
		my @introns = ("", "_filterRQ", "_filterR", "_filterQ");
		my @exts    = (".png", ".tiling", ".snps", "_C.snps", "_filter.snps");

		for my $base (@bases)
		{
		print " " x4 . "$base\n";
		for my $intron (@introns)
		{
		print " " x6 . "$intron\n";
		for my $ext (@exts)
		{
			my $filename = "$dir/$subdir/$name$base$intron$ext";
			if ( -f "$filename" )
			{
				print " " x8 . "$ext\n";
				if ($filename =~ /.png$/)
				{
					print " " x10 . "$filename\n";
 					open FILE, "<$filename" or die "  COULD NOT OPEN FILE $filename: $!";
					my $content = join("", <FILE>);
					close FILE;
 					my $size = `identify -size 1 $filename`;
					my $width = "1390"; my $height = "1390";
					if ($size =~ /(\d+)x(\d+)/) { $width = $1; $height = $2;};
					&print_html("<img width=\"$width\" height=\"$height\" src=\"data:image/png;base64," . (encode_base64($content)) . "\"/>\n",$filename, "PNG");
				}
				elsif ($filename =~ /.snps$/)
				{
					print " " x10 . "$filename\t";
					open FILE, "<$filename" or die "  COULD NOT OPEN FILE $filename: $!";
					my @total   = <FILE>;
					close FILE;
					my $total = @total;# - 5;
					print "$total\n";
					if (@total)
					{
						print "$total\n";
						my $stat = "$total SNPs FOUND BY THIS METHOD<p>\n";
						&parse_snps(\@total,$filename,$stat);
# 						(my $st, my $nd) = &parse_snps(\@total);
# 						&print_html("$stat<br>$st", "$filename\_text", "snp");
# 						&print_html("$stat<br>$nd", "$filename", "snp");
					}
				}
				elsif ($filename =~ /.tiling$/)
				{
					print " " x10 . "$filename\t";
					open FILE, "<$filename" or die "  COULD NOT OPEN FILE $filename: $!";
					my @total   = <FILE>;
					close FILE;
					my $total = @total;
					print "$total\n"; 
					if (@total)
					{
						my $stat = "" . ($total/2) . " LINES IN TILLING\n<p>";
						&parse_tiling(\@total,$filename,$stat);
# 						(my $st, my $nd) = &parse_tiling(\@total);
# 						&print_html("$stat<br>$st", "$filename\_text", "tiling");
# 						&print_html("$stat<br>$nd", "$filename", "tiling");
					}
				}
				else
				{
					print " " x10 . "$filename\n";
					open FILE, "<$filename" or die "  COULD NOT OPEN FILE $filename: $!";
# 					my $content = join("", <FILE>);
# 					&print_text("<pre>\n$content\n</pre>\n");
					close FILE;
				}
			} # end if dir/file doesnt exists
# 			else
# 			{
# 				print "$filename DOESNT EXISTS\n";
# 			}
		} # end for my ext
		} # end for my intron
		} # end for my base
	} # end for my subdir
	
	return;
}

sub print_html
{
	my $text   = $_[0];
	my $file   = $_[1];
	my $folder = $_[2];

	if ( ! ( -d "html/$folder" )) { mkdir "html/$folder"; };

	$file =~ /$outdir\/$dir_nucmer\/OUT_(.+)/;
	$file = $1;
	$file =~ tr/\/\./_/;
	my $title = "<h2><b>$file</b></h2>\n<small><b><i><a href=\"index.html\">INDEX</a></i></b></small>\n<hr />\n";
	$file .= ".html";
	$file  = "html/$folder/$file";
	push(@allFiles,$file);
	print " " x 12 . "$file\n";

	open FILE, ">$file" || die "COULD NOT CREATE FILE $file: $!";
	print FILE &printHeader();
	print FILE $title;
	print FILE $text;
	print FILE &printFoot();
	close FILE;
}

sub generateIndex
{
	open INDEX, ">index.html" || die "COULD NOT CREATE INDEX FILE: $!";
	print INDEX &printHeader();
	print INDEX "<h2><b>INDEX FILE</b></h2><hr />\n";
	foreach my $file (sort @allFiles)
	{
		my $name = $file;
		$name =~ s/html\///;
		print INDEX "<a href=\"$file\">$name</a><p>";
	}
	print INDEX &printFoot();
	close INDEX;
}

sub parse_tiling
{
	my @content  = @{$_[0]};
	my $filename = $_[1];
	my $stat     = $_[2];
	my $total    = @content;
	print " "x12 . "PARSING TILING";
	chomp @content;

	undef %tilingdb;

	my $max = 0;

	for (my $i=0; $i < @content; $i++)
	{
		my $current = $content[$i];
		if ($current =~ /^>/)
		{
			my $bases;
			($current, $bases) = ($current =~ /^>(.+) (\d+) bases$/);
			$tilingdb{$current}{"bases"}{"total"} = $bases;
			$max = $bases if ($bases > $max);
			$i++;
			while (( $i < @content) && ( ! ($content[$i] =~ /^>/)))
			{
				my $tiling = $content[$i];
				my @parts = split(/\s+/,$tiling);
				my $contigID = $parts[7];
				$tilingdb{$current}{$contigID}{"start"}             = $parts[0];
				$tilingdb{$current}{$contigID}{"end"}               = $parts[1];
				$tilingdb{$current}{$contigID}{"gap2next"}          = $parts[2];
				$tilingdb{$current}{$contigID}{"contigLength"}      = $parts[3];
				$tilingdb{$current}{$contigID}{"alignCoverage"}     = $parts[4];
				$tilingdb{$current}{$contigID}{"avgIdentity"}       = $parts[5];
				$tilingdb{$current}{$contigID}{"contigOrientation"} = $parts[6];

				$i++;
			}
			$i--;
		}
	}

	# >supercontig_1.25_of_Cryptococcus_neoformans_Serotype_B 34790 bases
	# 11998	12102	17460	105	99.05	93.69	+	NODE_12_length_75_cov_11.253333
	# 29563	29708	106	146	99.32	93.55	-	NODE_11_length_116_cov_15.939655
	#  [1]   [2]    [3]     [4]      [5]     [6]   [7]      [8]
	# [1] start in the reference 
	# [2] end in the reference 
	# [3] gap between this contig and the next
	# [4] length of this contig 
	# [5] alignment coverage of this contig 
	# [6] average percent identity of this contig 
	# [7] contig orientation 
	# [8] contig ID
	print "."x12 . "TILING PARSED\n";
	if (@content)
	{
		(my $text, my $image) = &parse_tiling_img(\%tilingdb,$max);
		&print_html("$stat<br>$text",  "$filename\_text", "tiling");
		&print_html("$stat<br>$image", "$filename"      , "tiling");
# 		return ($text,$image);
	} #end if content
	else
	{
# 		return ("", "");
	}
}

sub parse_tiling_img
{
	%tilingdb = %{$_[0]};
	my $max   = $_[1];
	print " "x12 . "GENERATING TILING IMG";

	my $text = "<pre>\n";
	$text .= "contig\tsize\tstart\tend\tgap2next\tcontigLength\talignCoverage\tavgIdentity\tcontigOrientation\n";

	my $image;
	my $panel;
	my %features;
	my %cov;
	foreach my $chromossome (sort keys %tilingdb)
	{
		undef $panel;
		$panel = Bio::Graphics::Panel->new(
					-length    => $max,
					-width     => 1024,
# 						-key_style => 'between',
					-pad_left  => 100,
					-pad_right => 100,
					);

		my $size = $tilingdb{$chromossome}{"bases"}{"total"};
		my @rep   = ("0") x ($size+1);

		undef %features;
		my %sorter;
		my $feature;
		foreach my $contig (keys %{$tilingdb{$chromossome}})
		{
		if ($contig ne "bases")
		{
			my $start             = $tilingdb{$chromossome}{$contig}{"start"};
			my $end               = $tilingdb{$chromossome}{$contig}{"end"};
			my $gap2next          = $tilingdb{$chromossome}{$contig}{"gap2next"};
			my $contigLength      = $tilingdb{$chromossome}{$contig}{"contigLength"};
			my $alignCoverage     = $tilingdb{$chromossome}{$contig}{"alignCoverage"};
			my $avgIdentity       = $tilingdb{$chromossome}{$contig}{"avgIdentity"};
			my $contigOrientation = $tilingdb{$chromossome}{$contig}{"contigOrientation"};

			$sorter{$start} = $contig;

			$text .= "$contig\t$size\t$start\t$end\t$gap2next\t$contigLength\t$alignCoverage\t$avgIdentity\t$contigOrientation\n";

			undef $feature;
# 				$feature = Bio::SeqFeature::Generic->new(
# 								-display_name =>$contig,
# 								-start        =>$start,
# 								-end          =>$end,
# 								-connector    =>'dashed',
# 								-tag          =>{ description => "$start-$end($contigLength) IDENT:$avgIdentity COV: $alignCoverage"},
# 								);
# 				$features{$contig} = $feature;
			if ($end < $start) { my $startn = $start; $start = $end; $end = $startn;};
			if ($end > $size)  { my $startn = $start; $end = $start; $start = ($start - $end) };
			for (my $i = $start-1; $i <$end; $i++)
			{
				if (defined $rep[$i])
				{
					$rep[$i] = 1;
				}
				else
				{
					print "CHROMOSSOME $chromossome CONTIG $contig SIZE $size START $start END $end ORIENTATION $contigOrientation\n";
				}
			}
		} # end if contig ne bases
		} # end foreach my contig

		undef %cov;
		%cov = &genCoverage(\@rep);
		my $full_length = Bio::SeqFeature::Generic->new(
						-start        =>1,
						-end          =>$size,
						-display_name =>"$chromossome COVERAGE " . $cov{"000"} . "/$size"
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
# 							-description =>"COVERAGE " . $cov{"cov"} . "/$size",
# 							-key =>"COVERAGE " . $cov{"cov"} . "/$size",
# 							-label =>"COVERAGE " . $cov{"cov"} . "/$size",
						);

		foreach my $start (sort { $a <=> $b } (keys %cov))
		{
		if ($start ne "000")
		{
			my $cov = Bio::SeqFeature::Generic->new(
							-start        =>$start,
							-end          =>$cov{$start},
# 								-display_name =>"coverage"
							);
			$track->add_feature($cov);
		}
		}

# 		my $idx    = 0;
# 		my @colors = qw(cyan orange gray blue gold purple green chartreuse magenta yellow aqua pink marine cyan);
# 		foreach my $tag (sort { $a <=> $b } (keys %sorter))
# 		{
# 			$panel->add_track($features{$sorter{$tag}},
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
		$image .= &printGD($panel->height, 10240, $panel->gd);
		$panel->finished;
	} # end foreach my chromossome
	$text  .= "</pre>\n";
	print "."x12 . "TILING IMG GENERATED\n";
	return ($text, $image);
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
	$cov{"000"} = $covered;
	return %cov;
}

sub parse_snps
{
	my @content = @{$_[0]};
	my $filename = $_[1];
	my $stat     = $_[2];
	print " "x12 . "PARSING SNP";
	undef %snpdb;
	my $max = 0;
	foreach my $line (@content)
	{
		my @pieces = split(/\s+/,$line);
# 		print scalar(@pieces) ."\n";
		my $posOri = $pieces[0];
		my $orig   = $pieces[1];
		my $new    = $pieces[2];
# 		my $posQry = $pieces[3];
# 		my $buff   = $pieces[4];
# 		my $dist   = $pieces[5];

# 		my $repR;
# 		my $repQ;
		my $lenR;
		my $lenQ;
		my $ctxR;
		my $ctxQ;
		my $dirR;
		my $dirQ;
		my $chromR;
		my $chromQ;

		if (scalar(@pieces) == 12)
		{
			$lenR   = $pieces[6];
			$lenQ   = $pieces[7];
			$dirR   = $pieces[8];
			$dirQ   = $pieces[9];
			$chromR = $pieces[10];
			$chromQ = $pieces[11];
			$ctxR   = "";
			$ctxQ   = "";
		}
		elsif ((scalar(@pieces) == 14) && ($pieces[8] =~ /[a|c|t|g]/i))
		{
			$lenR   = $pieces[6];
			$lenQ   = $pieces[7];
			$ctxR   = $pieces[8];
			$ctxQ   = $pieces[9];
			$dirR   = $pieces[10];
			$dirQ   = $pieces[11];
			$chromR = $pieces[12];
			$chromQ = $pieces[13];
		}
		elsif ((scalar(@pieces) == 14) && ( ! ($pieces[8] =~ /[a|c|t|g]/i)))
		{
# 			$repR   = $pieces[6];
# 			$repQ   = $pieces[7];
			$lenR   = $pieces[8];
			$lenQ   = $pieces[9];
			$ctxR   = "";
			$ctxQ   = "";
			$dirR   = $pieces[10];
			$dirQ   = $pieces[11];
			$chromR = $pieces[12];
			$chromQ = $pieces[13];
		}
		elsif (scalar(@pieces) == 16)
		{
# 			$repR   = $pieces[6];
# 			$repQ   = $pieces[7];
			$lenR   = $pieces[8];
			$lenQ   = $pieces[9];
			$ctxR   = $pieces[10];
			$ctxQ   = $pieces[11];
			$dirR   = $pieces[12];
			$dirQ   = $pieces[13];
			$chromR = $pieces[14];
			$chromQ = $pieces[15];
		}
		else
		{
			print "#### PIECES " . scalar(@pieces) . " $line####\n";
			die;
		}

		$snpdb{$chromR}{"bases"} 			= $lenR;
		$max = $lenR if ($lenR > $max);

		$snpdb{$chromR}{$chromQ}{$posOri}{"orig"}	= $orig;
		$snpdb{$chromR}{$chromQ}{$posOri}{"new"}	= $new;
		$snpdb{$chromR}{$chromQ}{$posOri}{"frame"}	= $dirR;
		$snpdb{$chromR}{$chromQ}{$posOri}{"contextR"}	= $ctxR;
		$snpdb{$chromR}{$chromQ}{$posOri}{"contextQ"}	= $ctxQ;
	}

	print "." x12 . "SNP PARSED\n";
	print " " x12 . "MAX  = $max\n";

	if ($max)
	{
		(my $text, my $image) = &parse_snps_img(\%snpdb,$max);
		&print_html("$stat<br>$text",  "$filename\_text", "snp");
		&print_html("$stat<br>$image", "$filename",       "snp");
# 		return ($text,$image);
	}
	else
	{
# 		return ("","");
	}
# ./seqs/c_neo_r265.fasta ./seqs/maq_run_4.fasta
# NUCMER
# 
#     [P1]  [SUB]  [P2]      |   [BUFF]   [DIST]  |  [R]  [Q]  |  [LEN R]  [LEN Q]  | [FRM]  [TAGS]
#      433   G C   252306    |        5      433  |    2    1  |  1510064  1406049  |  1 -1  supercontig_1.01_of_Cryptococcus_neoformans_Serotype_B	supercontig_1.03_of_Cryptococcus_neoformans_Serotype_B_assembly_WT
#      438   A C   252301    |        3      438  |    2    1  |  1510064  1406049  |  1 -1  supercontig_1.01_of_Cryptococcus_neoformans_Serotype_B	supercontig_1.03_of_Cryptococcus_neoformans_Serotype_B_assembly_WT
#
# 433		G	C	252306	5	433	2	1	1510064	1406049	1	-1	supercontig_1.01_of_Cryptococcus_neoformans_Serotype_B	supercontig_1.03_of_Cryptococcus_neoformans_Serotype_B_assembly_WT
# 438		A	C	252301	3	438	2	1	1510064	1406049	1	-1	supercontig_1.01_of_Cryptococcus_neoformans_Serotype_B	supercontig_1.03_of_Cryptococcus_neoformans_Serotype_B_assembly_WT
# 7985    	G       .       29      30      29      		15500   106     1       -1      supercontig_1.26_of_Cryptococcus_neoformans_Serotype_B  contig_371_length_106_nReads_33
# 7985    	G       .       29      30      29      0       0       15500   106     1       -1      supercontig_1.26_of_Cryptococcus_neoformans_Serotype_B  contig_371_length_106_nReads_33
# 7      	 .	A       3338    7       7       		1510064 8196    1       1       supercontig_1.01_of_Cryptococcus_neoformans_Serotype_B  contig_25_length_8196_nReads_67912
# 7985		G	.	29	30	29			15500	106	1	-1	supercontig_1.26_of_Cryptococcus_neoformans_Serotype_B	contig_371_length_106_nReads_33
#     1		2	3	4	5	6	7	8	9	10	11	12	13							14

# [P1] position of the SNP in the reference sequence. For indels, this position refers to the 1-based position of the first 
# character before the indel, e.g. for an indel at the very beginning of a sequence this would report 0. 
# For indels on the reverse strand, this position refers to the forward-strand position of the first character before 
# indel on the reverse-strand, e.g. for an indel at the very end of a reverse complemented sequence this would report 1. 
# [SUB] character or gap at this position in the reference [SUB] character or gap at this position in the query 
# [P2] position of the SNP in the query sequence 
# [BUFF] distance from this SNP to the nearest mismatch (end of alignment, indel, SNP, etc) in the same alignment 
# [DIST] distance from this SNP to the nearest sequence end 
# [R] number of repeat alignments which cover this reference position 
# [Q] number of repeat alignments which cover this query position 
# [LEN R] length of the reference sequence 
# [LEN Q] length of the query sequence 
# [CTX R] surrounding reference context 
# [CTX Q] surrounding query context 
# [FRM] sequence direction (NUCmer) or reading frame (PROmer) 
# [TAGS] the reference and query FastA IDs respectively.
# All positions are relative to the forward strand of the DNA input sequence, 
# while the [BUFF] distance is relative to the sorted sequence.
# The '.' character is used to represent indels, while '-' represents end-of-sequence.
}


sub parse_snps_img
{
		print " " x12 . "GENERATING SNP IMG";
		%snpdb    = %{$_[0]};
		my $max   = $_[1];
		my $total = 0;
		my $text  = "<pre>\n";
		$text    .= "chromReference\tchromQuery\tstartPosRef\tbaseOrig\tbaseNew\tcontextRef\tcontextQuery\tFrame\n";
		my $image;


		my %new;
		my $panel;
		my %features;
		my %cov;
		my $full_length;
		my $track;
		foreach my $chromR (sort keys %snpdb)
		{
			my $size = $snpdb{$chromR}{"bases"};
			undef %new;
			foreach my $keys (keys %{$snpdb{$chromR}})
			{
				if ($keys ne "bases")
				{
				foreach my $pos (keys %{$snpdb{$chromR}{$keys}})
				{
					$new{$pos} = $snpdb{$chromR}{$keys}{$pos};
				}
				}
			} # end foreach my keys

			undef $panel;
			$panel = Bio::Graphics::Panel->new(
						-length    => ($size*1.1),
						-width     => 1024,
# 						-key_style => 'between',
						-pad_left  => 10,
						-pad_right => 100,
						);

			my @rep   = ("0") x ($size+1);

			undef %features;
			my $feature;
			foreach my $pos (keys %new)
			{
				my $orig     = $new{$pos}{"orig"};
				my $new      = $new{$pos}{"new"};
				my $frame    = $new{$pos}{"frame"};
				my $contextR = $new{$pos}{"contextR"};
				my $contextQ = $new{$pos}{"contextQ"};
				my $context  = "";
				$context     = "$contextR\t$contextQ" if (($contextR) && ($contextQ));
				$text       .= "$chromR\t$pos\t$orig\t$new\t$context\t$frame\n";

				undef $feature;
# 				$feature = Bio::SeqFeature::Generic->new(
# 								-display_name =>"$pos $orig->$new",
# 								-start        =>$pos,
# 								-end          =>($pos+1),
# 								-connector    =>'dashed',
# 								-tag          =>{ description => "REF:$contextR QUERY:$contextQ FRAME:$frame"},
# 								);
# 				$features{$pos} = $feature;

				if (($pos > $size) || ($pos < 0)) { die "START $pos IS ILEGAL ($size)"};

				if (defined $rep[$pos])
				{
					$rep[$pos] = 1;
				}
				else
				{
					die "ERROR IN LOGIC $pos IN \@REP DOESNT EXISTS";
				}
				$total++;
			} #end foreach my pos

			undef %cov;
			%cov = &genCoverage(\@rep);

			undef $full_length;
			$full_length = Bio::SeqFeature::Generic->new(
							-start        =>1,
							-end          =>$size,
							-display_name =>"$chromR COVERAGE " . $cov{"000"} . "/$size"
							);

			$panel->add_track($full_length,
						-glyph   => 'arrow',
						-tick    => 3,
						-fgcolor => 'black',
						-double  => 1,
						-label   => 1,
						);
			undef $track;
			$track = $panel->add_track(	-glyph       => 'generic',
# 							-double      => 1,
							-label       => 1,
							-connector   =>'dashed',
							-bgcolor     => 'blue',
# 							-description =>"COVERAGE " . $cov{"cov"} . "/$size",
# 							-key =>"COVERAGE " . $cov{"cov"} . "/$size",
# 							-label =>"COVERAGE " . $cov{"cov"} . "/$size",
							);
			my $cov;
			foreach my $start (sort { $a <=> $b } (keys %cov))
			{
			if ($start ne "cov")
			{
				undef $cov;
				$cov = Bio::SeqFeature::Generic->new(
								-start        =>$start,
								-end          =>$cov{$start},
# 								-display_name =>"coverage"
								);
				$track->add_feature($cov);
			}
			}

# 			my $idx    = 0;
# 			my @colors = qw(cyan orange gray blue gold purple green chartreuse magenta yellow aqua pink marine cyan);
# 			foreach my $tag (sort { $a <=> $b } (keys %features))
# 			{
# 				$panel->add_track($features{$tag},
# 						-glyph       =>  'generic',
# 						-bgcolor     =>  $colors[$idx++ % @colors],
# 						-fgcolor     => 'black',
# 						-font2color  => 'red',
# 						-connector   => 'dashed',
# # 						-key         => $tag,
# 						-bump        => +1,
# 						-height      => 8,
# 						-label       => 1,
# 						-description => 1,
# 						);
# 			}#END FOR MY TAG
			$image .= &printGD($panel->height, 5120, $panel->gd);
			$panel->finished;

		} #end foreach my $chrmR
		print "." x12 . "SNP IMG GENERATED\n";
		print " " x12 . "SNPs = $total\n";

		$text  .= "SNPs = $total\n";
		$text  .= "</pre>\n";
		return ($text, $image);
} #end sub parse_snps_img

sub oneone_parser
{
	my $root_dir = $_[0];
	my @dirs     = @{$_[1]};
	
	return;
}

sub printGD
{
	my $heig  = $_[0];
	my $chunk = $_[1];
	$GD       = $_[2];
	if ( ! ( $heig && $chunk && $GD )) { die "NOT ENOUGH PARAMETERS PASSED TO PRINGD FUNCTION";};
	my $out;
	if ($heig > $chunk)
	{
		$out = &splitGD($heig, $chunk, $GD);
	}
	else
	{
		$out = "<img width=\"1024\" height=\"$heig\" src=\"data:image/$format;base64," . (encode_base64($GD->$format)) . "\"/>\n";
	}
	undef $GD;
	return $out;
}

sub splitGD
{
	my $heig  = $_[0];
	my $chunk = $_[1];
	$GD       = $_[2];
	if ( ! ( $heig && $chunk && $GD )) { die "NOT ENOUGH PARAMETERS PASSED TO SPLITGD FUNCTION";};
	bless $GD,"GD::Image";

	my $imgtot = (int($heig / $chunk) + 1);
	my $out = "";

	for (my $i = 1; $i <= $imgtot; $i++)
	{
		my $start = ($i - 1) * $chunk;
		my $end   = $i * $chunk;
		$end = $heig if ($end > $heig);
		my $size = $end-$start;
		my $image = new GD::Image(1024,($size));
		$image->copy($GD,0,0,0,$start,1024,$chunk);
		$out .= "<img width=\"1024\" height=\"$size\" src=\"data:image/png;base64," . (encode_base64($image->png)) . "\"/>\n";
	}
	undef $GD;
	return $out;
}








sub mummer3_parser
{
	my $dir = $_[0];
	my @alignss = &list_dir($dir,".align");
	my @gaps    = &list_dir($dir,".gaps");
	my @outs    = &list_dir($dir,".outs");
	my %out;
	
	return "";
}


sub mummer_parser
{
	my $dir = $_[0];
	my @mgaps = &list_dir($dir,".mgaps");
	my @mums  = &list_dir($dir,".mums");
	my %out;

	foreach my $mgap (@mgaps)
	{
		my $Smgap            = &strip_ext($mgap);
		$out{$Smgap}{"mgap"} = &parse_mgap($dir,$mgap);
# 		print "$Smgap\n";
	}

	foreach my $mum (@mums)
	{
		my $Smum           = &strip_ext($mum);
		$out{$Smum}{"mum"} = &parse_mum($dir,$mum);
# 		print "$Smum\n";
	}

	return;
}

sub parse_mgap
{
	# no mgaps to analyze. not spending time... yet
	my $dir  = $_[0];
	my $mgap = $_[1];
	return "";
}

sub parse_mum
{
	# no mums to analyze. not spending time... yet
	my $dir = $_[0];
	my $mum = $_[1];
	return "";
}





sub strip_ext
{
	my $in = $_[0];
	chomp $in;
	if ($in =~ /^(.+)\.(.+)$/) { $in = $1;};

	return $in;
}

sub list_dir
{
	my $dir = $_[0];
	my $ext = $_[1];
# 	print "openning dir $dir and searching for extension $ext\n";

	opendir (DIR, "$dir") || die "CANT READ DIRECTORY $dir: $!\n";
	my @ext = grep { (!/^\./) && -f "$dir/$_" && (/$ext$/)} readdir(DIR);
	closedir DIR;

	return @ext;
}

sub list_subdir
{
	my $dir = $_[0];

# 	print "openning dir $dir and searching for subdirs\n";

	opendir (DIR, "$dir") || die "CANT READ DIRECTORY $dir: $!\n";
	my @dirs = grep { (!/^\./) && -d "$dir/$_" } readdir(DIR);
	closedir DIR;

	return @dirs;
}

sub printHeader
{
my $header =<<_EOF_
<html>
<head>
<meta http-equiv="Content-Language" content="en-us">
<meta http-equiv="Content-Type" content="text/html; charset=windows1252">
<base href="../"/>
<title>MUMMER OUTPUT</title>
</head>
<body link="#000000" vlink="#000000" alink="#0000FF" bgcolor="#c0c0c0">
<a name=INDEX></a><h1><font size=\"8\">MUMMER OUTPUT</font></h1>
_EOF_
;
return $header;
# &print_short($header);
}

sub printFoot
{
my $foot =<<_EOF_
</body>
</html>
_EOF_
;
return $foot;
# &print_short($foot);
}

# opendir (DIR, "./") || die "CANT READ DIRECTORY: $!\n";
# my @dots = grep { (!/^\./) && -f "./$_" && (/\.fa$/ || /\.gbff$/)} readdir(DIR);
# closedir DIR;
# 
# my %hash = map { /^(\S+)\.(fa|gbff)$/; $1 => "file"; } @dots;
# my $countFile = 0;
# my $countSeq  = 0;




# open FASTA, "<$fasta" || die "COULD NOT OPEN $fasta FILE: $!";
# my $i = 1;
# while (<FASTA>)
# {
# 	if (/^>/)
# 	{
# 		close SPLIT;
# 		my $it = $i;
# # 		if ($i < 10) { $it = "0$i";} else {$it = $i;};
# 		open SPLIT, ">$folder$base/$base$it$ext" || die "COULD NOT OPEN $fasta.$i FILE: $!";
# 		$i++;
# 	}
# 	print SPLIT;
# }
# close FASTA;

# sub print_png
# {
# 	open FILE, ">>html/short_png.html" || die "COULD NOT OPEN html/short_png.html: $!";
# 	print FILE $_[0];
# 	close FILE;
# 
# 	&print_long($_[0]) if ( ! $_[2]);
# }
# 
# sub print_snp
# {
# 	&print_text($_[0]) if ( ! $_[3]);
# 	my $name;
# 	if ($_[2]) { $name = "_" . $_[2];} else {$name = "";};
# 	open FILE, ">>html/short_snp_text.html" || die "COULD NOT OPEN html/short_snp_text.html: $!";
# 	print FILE $_[0];
# 	close FILE;
# 
# 	open FILE, ">>html/short_snp$name.html"      || die "COULD NOT OPEN html/short_snp.html: $!";
# 	print FILE $_[1];
# 	close FILE;
# 
# 	&print_long($_[1]) if ( ! $_[3]);
# }
# 
# sub print_tiling
# {
# 	&print_text($_[0]) if ( ! $_[3]);
# 	my $name;
# 	if ($_[2]) { $name = "_" . $_[2];} else {$name = "";};
# 	open FILE, ">>html/short_tiling_text.html" || die "COULD NOT OPEN html/short_tiling_text.html: $!";
# 	print FILE $_[0];
# 	close FILE;
# 
# 	open FILE, ">>html/short_tiling$name.html"      || die "COULD NOT OPEN html/short_tiling.html: $!";
# 	print FILE $_[1];
# 	close FILE;
# 
# 	&print_long($_[1]) if ( ! $_[3]);
# }
# 
# sub print_text
# {
# 	open FILE, ">>html/short_text.html" || die "COULD NOT OPEN html/short_text.html: $!";
# 	print FILE $_[0];
# 	close FILE;
# 	&print_long($_[0]) if ( ! $_[1]);
# }
# 
# sub print_short
# {
# 	print_tiling($_[0],$_[0],1);
# 	print_snp($_[0],$_[0],,1);
# 	print_png($_[0],$_[0],,1);
# 	print_text($_[0]);
# 	print_long($_[0]);
# }
# 
# sub print_long
# {
# 	open FILE, ">>html/long.html" || die "COULD NOT OPEN html/short.html: $!";
# 	print FILE $_[0];
# 	close FILE;
# }

1;