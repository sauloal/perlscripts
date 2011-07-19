#!/usr/bin/perl -w
use strict;
use warnings;
# use AnyData::Format::XML;
# use AnyData;
# use Data::Dumper;
# use XML::Twig;
# use XML::Parser;

my $outdir          = "out"; #output dir
my $dir_nucmer      = "nucmer"; #nucmer dir
my $prefix_base     = "OUT_nucmer_r265"; #filter dirs
my $subdirFilter    = "supercontig\|112\|111\|solAssembly\|61\|31\|r265_r265\|wm276"; # negative filter subdirs [\S -> only base dir]
# my @dirs_one_by_one = ("maq_run_4", "velvet_nu_03_1", "velvet_us_06_1", "velvet_wh_11_1", "velvet_wh_11_2", "velvet_wh_11_3");

`rm -Rf xml`;
mkdir "xml";

print "PARSING SNP FILES\n";
# my $table;
# my %snpdb;
# my @keys;

my $dir     = "$outdir/$dir_nucmer";
my @subdirs = sort &list_subdir($dir);

&nucmer_snp_parser($dir,\@subdirs);
&nucmer_gap_parser($dir,\@subdirs);

# my $table = adTie( 'XML', "xml/snps.xml", "o",{col_names=>'name,country,sex'});
# $table->{tom}   = {country=>'nl', sex=>'m'};
# $table->{sue}   = {country=>'de', sex=>'f'};
# $table->{saulo} = {country=>'br', sex=>'m'};
# 
# print adExport($table,'XML');


sub nucmer_gap_parser
{
	my $dir     =   $_[0];
	my @subdirs = @{$_[1]};

	map { (my $name)  = ($_ =~ /^OUT_(.*)/); } @subdirs;

	print "dir\n";
	my %hash;
	my %out;
	my @total;
	foreach my $subdir (@subdirs)
	{
		if ($subdir =~ /$prefix_base/)
		{
			print " " x2 . "$subdir\n";
			(my $name)  = ($subdir =~ /^OUT_(.*)/);
	
			my @bases   = ("", "_SNP");
			my @introns = ("", "_filterR");
			my @exts    = (".gap");
	
	
			for my $base (@bases)
			{
	# 		print " " x4 . "$base\n";
			for my $intron (@introns)
			{
	# 		print " " x6 . "$intron\n";
			for my $ext (@exts)
			{
				my $filename  = "$dir/$subdir/$name$base$intron$ext";
				my $shortname = "$name$base$intron$ext";	
				if ( -f "$filename" )
				{
	# 				print " " x8 . "$ext\n";
					if ($filename =~ /.gap$/)
					{
						print " " x10 . "$filename\n";
						open FILE, "<$filename" or die "  COULD NOT OPEN FILE $filename: $!";
						@total   = <FILE>;
						print " " x12 . @total . " LINES TO BE LOADED\n";
						&parse_gap(\@total,$shortname);
						undef @total;
						close FILE;
					}
				} # end if dir/file doesnt exists
			} # end for my ext
			} # end for my intron
			} # end for my base
		} # end if my subdir
	} # end for my subdir
	return %out;
}

sub parse_gap
{
	my @lines = @{$_[0]};
	my $name  = $_[1];
	my %chrom;

	if (@lines)
	{
		print "EXPORTING XML FILE: xml/gap_$name\_prog.xml\n";
		open  FILE, ">xml/gap_$name\_prog.xml" || die "COULD NOT OPEN XML FILE FOR FILENAME gap_$name\_prog: $!";
		print FILE  "<root id=\"mummer\" type=\"gap\">\n";
		print FILE  "\t<table id=\"mummer\" type=\"program\">\n";
		my $id = 0;
		foreach my $line (@lines)
		{
			chomp $line;
			if ($line =~ /^(\S+)\s*(\d+)\s*(\d+)/)
			{
				my $chrom = $1;
				my $start = $2;
				my $end   = $3;
				my $size  = $end - $start + 1;
				my $shortname = $name;
				   $shortname =~ s/\.gap//gi;
				   $shortname =~ s/filterR//gi;
				   $shortname =~ s/nucmer//gi;
				   $shortname =~ s/r265//gi;
				   $shortname =~ s/\_//gi;
				$id++;
				my $out1; my $out2; my $out3; my $out4;
				$out1 .= "\t\t<row>\n";
				$out1 .= "\t\t\t<start>$start</start>\n";
				$out1 .= "\t\t\t<end>$end</end>\n";
				$out1 .= "\t\t\t<length>$size</length>\n";
				$out1 .= "\t\t\t<id>$id</id>\n";
				$out2 .= "\t\t\t<program>mummer_$shortname</program>\n";
				$out3 .= "\t\t\t<chromR>$chrom</chromR>\n";
				$out4 .= "\t\t</row>\n";
				print FILE "$out1$out3$out4";
				$chrom{$chrom} .= "$out1$out2$out4";
			}
			else
			{
				die "UNKNOWN GAP FILE FORMAT";
			}
		}
		print FILE "\t</table>\n";
		print FILE "</root>\n";
		close FILE;

		print "EXPORTING XML FILE: xml/gap_$name\_chrom.xml\n";
		open  FILE, ">xml/gap_$name\_chrom.xml" || die "COULD NOT OPEN XML FILE FOR FILENAME gap_$name\_chrom: $!";
		print FILE "<root id=\"mummer\" type=\"gap\">\n";
		foreach my $chrom (sort keys %chrom)
		{
			print FILE "\t<table id=\"$chrom\" type=\"chromossome\">\n";
			print FILE $chrom{$chrom};
			print FILE "\t</table>\n";
		}
		print FILE "</root>\n";
		close FILE;

		print "\n" . " " x12 . "TOTAL GAPS         = $id\n\n";
		
	} # end if lines
}


sub nucmer_snp_parser
{
	my $dir     =   $_[0];
	my @subdirs = @{$_[1]};

	map { (my $name)  = ($_ =~ /^OUT_(.*)/); } @subdirs;

	print "dir\n";
	my %hash;
	my %out;
	my @total;
	foreach my $subdir (@subdirs)
	{
		if ($subdir =~ /$prefix_base/)
		{
			print " " x2 . "$subdir\n";
			(my $name)  = ($subdir =~ /^OUT_(.*)/);
	# 		my @bases   = ("", "_SNP");
	# 		my @introns = ("", "_filterRQ", "_filterR", "_filterQ");
	# 		my @exts    = (".snps", "_C.snps", "_filter.snps");
	
			my @bases   = ("", "_SNP");
			my @introns = ("", "_filterR");
			my @exts    = ("", "_C.snps");
	
	
			for my $base (@bases)
			{
	# 		print " " x4 . "$base\n";
			for my $intron (@introns)
			{
	# 		print " " x6 . "$intron\n";
			for my $ext (@exts)
			{
				my $filename  = "$dir/$subdir/$name$base$intron$ext";
				my $shortname = "$name$base$intron$ext";	
				if ( -f "$filename" )
				{
	# 				print " " x8 . "$ext\n";
					if ($filename =~ /.snps$/)
					{
						print " " x10 . "$filename\n";
						open FILE, "<$filename" or die "  COULD NOT OPEN FILE $filename: $!";
						@total   = <FILE>;
						print " " x12 . @total . " LINES TO BE LOADED\n";
						if (@total)
						{
							&parse_snps(\@total,$shortname);
						}
						undef @total;
						close FILE;
					}
# 					else
# 					{
# 						print " " x10 . "$filename\n";
# 						open FILE, "<$filename" or die "  COULD NOT OPEN FILE $filename: $!";
# 						my $content = join("", <FILE>);
# 						close FILE;
# 					}
				} # end if dir/file doesnt exists
	# 			else
	# 			{
	# 				print "$filename DOESNT EXISTS\n";
	# 			}
			} # end for my ext
			} # end for my intron
			} # end for my base
		} # end if my subdir
	} # end for my subdir
	return %out;
}


sub parse_snps
{
	my @content  = @{$_[0]};
	my $filename = $_[1];
	print " " x12 . "LINES  = " . scalar(@content) . " ";
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
# 	undef %snpdb;
	my $max = 0;
	my $cc  = 1;

	if (@content)
	{
		my $name = $filename;
		$name =~ tr/\/\./_/;
		print "EXPORTING XML FILE: xml/snps_$name.xml\n";
		open FILE,  ">xml/snps_$name.xml" || die "COULD NOT OPEN XML FILE FOR FILENAME snps_$name: $!";
		print FILE  "<root id=\"mummer\" type=\"snp\">\n";
		print FILE  "\t<table id=\"mummer\" type=\"program\">\n";
		my $id = 0;
		print " "x21;
		foreach my $line (@content)
		{
			if ((@content > 1000) && ( ! ($cc++ % (@content/10)))) { print $cc . " "; };
	
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
			my $ctxR; #surrounding reference context
			my $ctxQ; #surrounding query     context
			my $dirR; #frame reference
			my $dirQ; #frame query
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
	
	# 		my $keydR = 0;
	# 		my $keydQ = 0;
	# 		for (my $i = 0; $i < @keys; $i++)
	# 		{
	# 			my $key = $keys[$i];
	# 			if ($chromR eq $key)
	# 			{
	# 				$chromR = $i;
	# 				$keydR  = 1;
	# 			}
	# 			if ($chromQ eq $key)
	# 			{
	# 				$chromQ = $i;
	# 				$keydQ  = 1;
	# 			}
	# 		}
	
	# 		if ( ! $keydR )
	# 		{
	# 			push (@keys, $chromR);
	# 			$chromR = (@keys-1);
	# 		}
	# 		if ( ! $keydQ )
	# 		{
	# 			push (@keys, $chromQ);
	# 			$chromQ = (@keys-1);
	# 		}
	
	
	# 		$snpdb{$chromR}{"bases"} 			= $lenR;
			$max = $lenR if ($lenR > $max);
	# 
	# 		$snpdb{$chromR}{$chromQ}{$posOri}{"orig"}	= $orig;
	# 		$snpdb{$chromR}{$chromQ}{$posOri}{"new"}	= $new;
	# 		$snpdb{$chromR}{$chromQ}{$posOri}{"frame"}	= $dirR;
	# 		$snpdb{$chromR}{$chromQ}{$posOri}{"conR"}	= $ctxR;
	# 		$snpdb{$chromR}{$chromQ}{$posOri}{"conQ"}	= $ctxQ;
	
	
		# 	my $table = adTie( 'XML', "xml/snps_$name.xml", "o",{col_names=>'chromR,chromQ,posOri,orig,new,frame,contextR,contextQ',prettyPrint=>'idented'});
		# 	my $table = adTie( 'XML', undef, "o",{col_names=>'chromR,chromQ,posOri,orig,new,frame,contextR,contextQ',prettyPrint=>'idented'});
		#	$table = adTie( 'XML', undef, "o",{col_names=>'chromR,chromQ,posOri,orig,new,frame,contextR,contextQ',prettyPrint=>'idented'});
			$id++;
			print FILE "\t\t<row>\n";
			print FILE "\t\t\t<chromR>" . $chromR . "</chromR>\n";
			print FILE "\t\t\t<chromQ>" . $chromQ . "</chromQ>\n";
			print FILE "\t\t\t<posOrig>$posOri</posOrig>\n";
			print FILE "\t\t\t<orig>$orig</orig>\n";
			print FILE "\t\t\t<new>$new</new>\n";
			print FILE "\t\t\t<frame>$dirR</frame>\n";
			print FILE "\t\t\t<contR>$ctxR</contR>\n";
			print FILE "\t\t\t<contQ>$ctxQ</contQ>\n";
			print FILE "\t\t\t<id>$id</id>\n";
			print FILE "\t\t</row>\n";
	
	# 	return \%snpdb;
		} #end foreach my line
	print FILE  "\t</table>\n";
	print FILE  "</root>\n";
	close FILE;
	print "\n" . " " x12 . "MAX REFERENCE SIZE = $max";
	print "\n" . " " x12 . "TOTAL SNPS         = $id\n\n";
	} #end if @content
	undef @content;
} #end sub parse snps


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
	my @dirs = grep { (!/^\./) && -d "$dir/$_" && ( ! /$subdirFilter/ )} readdir(DIR);

	closedir DIR;

	return @dirs;
}












# sub xml_it
# {
# # 	%snpdb       = %{$_[0]};
# 	my $filename = $_[0];
# 	print "EXPORTING XML\n";
# 
# 	my $name = $filename;
# 	$name =~ tr/\/\./_/;
# 	print "EXPORTING XML FILE: xml/snps_$name.xml\n";
# # 	my $table = adTie( 'XML', "xml/snps_$name.xml", "o",{col_names=>'chromR,chromQ,posOri,orig,new,frame,contextR,contextQ',prettyPrint=>'idented'});
# # 	my $table = adTie( 'XML', undef, "o",{col_names=>'chromR,chromQ,posOri,orig,new,frame,contextR,contextQ',prettyPrint=>'idented'});
# #	$table = adTie( 'XML', undef, "o",{col_names=>'chromR,chromQ,posOri,orig,new,frame,contextR,contextQ',prettyPrint=>'idented'});
# 	my $count = 0;
# 	open FILE,  ">xml/snps_$name.xml" || die "COULD NOT OPEN XML FILE FOR FILENAME $name: $!";
# 	open FILE2, ">xml/snps2_$name.xml" || die "COULD NOT OPEN XML FILE FOR FILENAME $name: $!";
# 	print FILE  "<table>\n";
# 	print FILE2 "<table>\n";
# #<table>
# # <row>
# # <chromR>supercontig_1.01_of_Cryptococcus_neoformans_Serotype_B</chromR>
# # <chromQ>contig_25_length_8196_nReads_67912</chromQ>
# # <posOri>42</posOri>
# # <orig>.</orig>
# # <new>T</new>
# # <frame>1</frame>
# # <contextR></contextR>
# # <contextQ></contextQ>
# # </row>
# 	foreach my $chromR (sort keys %snpdb)
# 	{
# 		print "PARSING " . $keys[$chromR] . " ($chromR)\n";
# 		print FILE2 "\t<chromR id=\"" . $keys[$chromR] . "\">\n";
# 		foreach my $chromQ (sort keys %{$snpdb{$chromR}})
# 		{
# 			my $length;
# 			if ($chromQ eq "bases")
# 			{
# 				$length = $snpdb{$chromR}{"bases"};
# 			}
# 			else
# 			{
# 				print FILE2 "\t\t<chromQ id=\"" . $keys[$chromQ] . "\">\n";
# 				foreach my $posOri (sort keys %{$snpdb{$chromR}{$chromQ}})
# 				{
# 					my $orig = $snpdb{$chromR}{$chromQ}{$posOri}{"orig"};
# 					my $new  = $snpdb{$chromR}{$chromQ}{$posOri}{"new"};
# 					my $dirR = $snpdb{$chromR}{$chromQ}{$posOri}{"frame"};
# 					my $ctxR = $snpdb{$chromR}{$chromQ}{$posOri}{"conR"};
# 					my $ctxQ = $snpdb{$chromR}{$chromQ}{$posOri}{"conQ"};
# 					$count++;
# # 					$table->{$keys[$chromR]} = {chromQ=>$keys[$chromQ],posOri=>$posOri,orig=>$orig,new=>$new,frame=>$dirR,contextR=>$ctxR,contextQ=>$ctxQ};
# 					print FILE "\t<row>\n";
# 					print FILE "\t\t<chromR>" . $keys[$chromR] . "</chromR>\n";
# 					print FILE "\t\t<chromQ>" . $keys[$chromQ] . "</chromQ>\n";
# 					print FILE "\t\t<posOrig>$posOri</posOrig>\n";
# 					print FILE "\t\t<orig>$orig</orig>\n";
# 					print FILE "\t\t<new>$new</new>\n";
# 					print FILE "\t\t<frame>$dirR</frame>\n";
# 					print FILE "\t\t<contR>$ctxR</contR>\n";
# 					print FILE "\t\t<contQ>$ctxQ</contQ>\n";
# 					print FILE "\t</row>\n";
# 
# 					print FILE2 "\t\t\t<posOrig id=\"$posOri\">\n";
# 					print FILE2 "\t\t\t\t<orig>$orig</orig>\n";
# 					print FILE2 "\t\t\t\t<new>$new</new>\n";
# 					print FILE2 "\t\t\t\t<frame>$dirR</frame>\n";
# 					print FILE2 "\t\t\t\t<contR>$ctxR</contR>\n";
# 					print FILE2 "\t\t\t\t<contQ>$ctxQ</contQ>\n";
# 					print FILE2 "\t\t\t</posOrig>\n";
# 				}
# 			}
# 			print FILE2 "\t\t\t</chromQ>\n";
# 		}
# 		print FILE2 "\t\t</chromR>\n";
# 	}
# 	print FILE2 "</table>\n";
# 	close FILE2;
# 	print FILE  "</table>\n";
# 	close FILE;
# 
# 	# print adExport($table,'XML');
# # 	if ($count)
# # 	{
# # 		open FILE, ">xml/snps_$name.xml" || die "COULD NOT OPEN XML FILE FOR FILENAME $name: $!";
# # 		print FILE adExport($table,'XML');
# # 		close FILE;
# # 		print "FILE xml/snps_$name.xml CREATED\n";
# # 	}
# 	undef %snpdb;
# 	undef $table;
# 	print "DONE.\n";
# }

1;