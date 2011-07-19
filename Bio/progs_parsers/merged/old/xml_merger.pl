#!/usr/bin/perl -w
use strict;
use warnings;
# use AnyData::Format::XML;
# use AnyData;
# use Data::Dumper;
# use XML::Twig;
# use XML::Parser;

# `rm -Rf xml_merged`;
# mkdir "xml_merged";

my %db;
my %XMLhash;
my %parserHash;

# LOAD DIVERSE SNP XML FILES AND MERGES THEM AS A SINGLE FILE
# GENERATES OUTPUTS SORTED BY POSITION, PROGRAM OR CHROMOSSOME

# &load_maq("maq/xml/maq_snps_cns.xml");
&load_slider("slider/xml");
&load_mummer("mummer/xml");
&save_merged();
&save_merged_prog();
&save_chromossome();

sub save_chromossome
{
	print "EXPORTING XML FILE: xml_merged/CHROMOSSOME.xml\n";
	my $count = 0;
	my %files;
	foreach my $prog (keys %db)
	{
	foreach my $chrom (keys %{$db{$prog}})
	{
	foreach my $pos (sort { $a <=> $b } keys %{$db{$prog}{$chrom}})
	{
		my $orig = $db{$prog}{$chrom}{$pos}{"orig"};
		my $new  = $db{$prog}{$chrom}{$pos}{"new"};

		my $out = "\t<row id=\"$count\">\n";
		$out   .= "\t\t<posOrig>$pos</posOrig>\n";
		$out   .= "\t\t<orig>$orig</orig>\n";
		$out   .= "\t\t<new>$new</new>\n";
		$out   .= "\t\t<program>$prog</program>\n";
		$out   .= "\t</row>\n";

		$files{$chrom}{$pos} .= $out;

		$count++;
	} #end foreach my pos
	} #end foreach my chrom
	} #end foreach my prog


	open  FILE2, ">xml_merged/merged_chrom.xml" or die "COULD NOT OPEN merged_chrom.xml XML FILE: $!";
	print FILE2  "<root id=\"merged_chrom\" type=\"snp\">\n";

	foreach my $chrom (sort keys %files)
	{
		my $filename = "xml_merged/$chrom.xml";
		print FILE2 "\t<table id=\"$chrom\" type=\"chromossome\">\n";
		open  FILE, ">$filename" or die "COULD NOT OPEN $filename XML FILE FOR SAVE: $!";
		print FILE  "<root id=\"$chrom\" type=\"chromossome\">\n";
		print FILE  "\t<table id=\"$chrom\" type=\"chromossome\">\n";
		foreach my $pos (sort { $a <=> $b} keys %{$files{$chrom}})
		{
			print FILE  $files{$chrom}{$pos};
			print FILE2 $files{$chrom}{$pos};
		}
		print FILE  "\t</table>\n";
		print FILE  "</root>";
		print FILE2 "\t</table>\n";
	}
	print FILE2 "</root>";

	print "EXPORTED $count REGISTERS TO MERGED FILE\n";
} #end sub parse snps

sub save_merged_prog
{
	print "EXPORTING XML FILE: xml_merged/snps_progs.xml\n";
	open  FILE, ">xml_merged/snps_progs.xml" or die "COULD NOT OPEN XML FILE FOR: $!";
	print FILE  "<root id=\"merged_progs\" type=\"snp\">\n";

	my $count = 0;
	foreach my $prog (sort keys %db)
	{
	open  FILE2, ">xml_merged/snps_$prog.xml" or die "COULD NOT OPEN XML FILE FOR: $!";
	print FILE2  "<root id=\"$prog\" type=\"snp\">\n";
	print FILE2  "\t<table id=\"$prog\" type=\"program\">\n";
	print FILE   "\t<table id=\"$prog\" type=\"program\">\n";
	foreach my $chrom (sort keys %{$db{$prog}})
	{
	foreach my $pos (sort { $a <=> $b } keys %{$db{$prog}{$chrom}})
	{
		my $orig = $db{$prog}{$chrom}{$pos}{"orig"};
		my $new  = $db{$prog}{$chrom}{$pos}{"new"};

		my $out = "\t\t<row id=\"$count\">\n";
		$out .= "\t\t\t<chromR>$chrom</chromR>\n";
		$out .= "\t\t\t<posOrig>$pos</posOrig>\n";
		$out .= "\t\t\t<orig>$orig</orig>\n";
		$out .= "\t\t\t<new>$new</new>\n";
		$out .= "\t\t</row>\n";

		print FILE2 $out;
		print FILE  $out;
		$count++;
	} #end foreach my pos
	} #end foreach my chrom
	print FILE2 "\t</table>\n";
	print FILE2 "</root>\n";
	print FILE  "\t</table>\n";
	} #end foreach my prog
	print FILE  "</root>\n";
	close FILE;
	print "EXPORTED $count REGISTERS TO MERGED FILE WITH PROGRAMS\n";
}

sub save_merged
{
	print "EXPORTING XML FILE: xml_merged/snps.xml\n";
	open FILE,  ">xml_merged/snps.xml" or die "COULD NOT OPEN XML FILE FOR: $!";
	print FILE  "<root id=\"merged\" type=\"snp\">\n";
	my $count = 0;

	my %chromo;

	foreach my $prog (keys %db)
	{
	foreach my $chrom (keys %{$db{$prog}})
	{
	foreach my $pos (keys %{$db{$prog}{$chrom}})
	{
		
		my $orig = $db{$prog}{$chrom}{$pos}{"orig"};
		my $new  = $db{$prog}{$chrom}{$pos}{"new"};

		my $out .= "\t\t<row id=\"$count\">\n";
# 		print FILE "\t\t\t<chromR>$chrom</chromR>\n";
		$out .= "\t\t\t<posOrig>$pos</posOrig>\n";
		$out .= "\t\t\t<orig>$orig</orig>\n";
		$out .= "\t\t\t<new>$new</new>\n";
		$out .= "\t\t\t<program>$prog</program>\n";
		$out .= "\t\t</row>\n";
		$chromo{$chrom}{$pos} .= $out;

		$count++;
	} #end foreach my pos
	} #end foreach my chrom
	} #end foreach my prog

	foreach my $chrom (sort keys %chromo)
	{
	print FILE  "\t<table id=\"$chrom\" type=\"chromossome\">\n";
	foreach my $pos (sort { $a <=> $b } keys %{$chromo{$chrom}})
	{
		my $out = $chromo{$chrom}{$pos};
		print FILE $out;
	}
	print FILE  "\t</table>\n";
	}


	print FILE  "</root>\n";
	close FILE;
	print "EXPORTED $count REGISTERS TO MERGED FILE\n";
} #end sub parse snps




sub load_mummer
{
	my $dir = $_[0];

	undef %parserHash;

	foreach my $file (&list_dir($dir,".xml"))
	{
		%parserHash = %{&parseXML("$dir/$file")};

		foreach my $id (keys %parserHash)
		{	
# 			print "ID $id\n";
			foreach my $register (keys %{$parserHash{$id}})
			{
	# 			foreach my $key (keys %{$hash{$register}})
	# 			{
	# 				my $value = $hash{$register}{$key};
	# 				print "$register => $key -> $value\n";
	# 			}
				my $chromR = $parserHash{$id}{$register}{"chromR"};
				my $pos    = $parserHash{$id}{$register}{"posOrig"};
				my $orig   = $parserHash{$id}{$register}{"orig"};
				my $new    = $parserHash{$id}{$register}{"new"};
	
				print "$chromR $pos $orig $new\n";
				$db{$id}{$chromR}{$pos}{"orig"} = $orig;
				$db{$id}{$chromR}{$pos}{"new"}  = $new;
			}
		}
		undef %parserHash;
	}
# <root id="mummer" type="snp">
# 	<table id="mummer" type="program">
# 		<row>
# 			<chromR>supercontig_1.01_of_Cryptococcus_neoformans_Serotype_B</chromR>
# 			<chromQ>NODE_12291_length_58_cov_2.327586</chromQ>
# 			<posOrig>14068</posOrig>
# 			<orig>.</orig>
# 			<new>T</new>
# 			<frame>1</frame>
# 			<contR>TTAC.TAGA</contR>
# 			<contQ>TTACTTAGA</contQ>
# 			<id>1</id>
# 		</row>
}


sub load_slider
{
	my $dir = $_[0];

	undef %parserHash;

	foreach my $file (&list_dir($dir,".xml"))
	{
		%parserHash = %{&parseXML("$dir/$file")};

		foreach my $id (keys %parserHash)
		{	
		foreach my $register (keys %{$parserHash{$id}})
		{
# 			foreach my $key (keys %{$hash{$register}})
# 			{
# 				my $value = $hash{$register}{$key};
# 				print "$register => $key -> $value\n";
# 			}
			my $chromR = $parserHash{$id}{$register}{"chromR"};
			my $pos    = $parserHash{$id}{$register}{"posOrig"};
			my $orig   = $parserHash{$id}{$register}{"orig"};
			my $new    = $parserHash{$id}{$register}{"new"};

			$chromR    = &slider_conversor($chromR);
# 			print "$chromR $orig $new\n";
			$db{$id}{$chromR}{$pos}{"orig"} = $orig;
			$db{$id}{$chromR}{$pos}{"new"}  = $new;
	
	
# 			print FILE "\t<row>\n";
# 			print FILE "\t\t<chromR>$chromR</chromR>\n";
# 			print FILE "\t\t<posOrig>$posOri</posOrig>\n";
# 			print FILE "\t\t<orig>$orig</orig>\n";
# 			print FILE "\t\t<new>$new</new>\n";
# 			print FILE "\t\t<zygo>$status</zygo>\n";
# 			print FILE "\t\t<complexity>$complexity</complexity>\n";
# 			print FILE "\t</row>\n";
		}
		}
		undef %parserHash;
	}
}

sub slider_conversor
{
	my $text = $_[0];

	if ($text =~ /(\d+)$/)
	{
		my $num = $1;
		if ($num <10)
		{
			$num = "0$num";
		}
		$text = "supercontig_1.$num\_of_Cryptococcus_neoformans_Serotype_B";
	}
	else
	{
		die "ERROR IN SLIDER CONVERSION\n";
	}
# 	neo_ref1 => supercontig_1.01_of_Cryptococcus_neoformans_Serotype_B,

	return $text;
}

# my %conversor = (	neo_ref1 => supercontig_1.01_of_Cryptococcus_neoformans_Serotype_B,
# 			neo_ref2 => supercontig_1.02_of_Cryptococcus_neoformans_Serotype_B,
# 			neo_ref3 => supercontig_1.03_of_Cryptococcus_neoformans_Serotype_B,
# 			neo_ref4 => supercontig_1.04_of_Cryptococcus_neoformans_Serotype_B,
# 			neo_ref5 => supercontig_1.05_of_Cryptococcus_neoformans_Serotype_B,
# 			neo_ref6 => supercontig_1.06_of_Cryptococcus_neoformans_Serotype_B,
# 			neo_ref7 => supercontig_1.07_of_Cryptococcus_neoformans_Serotype_B,
# 			neo_ref8 => supercontig_1.08_of_Cryptococcus_neoformans_Serotype_B,
# 			neo_ref9 => supercontig_1.09_of_Cryptococcus_neoformans_Serotype_B,
# 			neo_ref10 => supercontig_1.10_of_Cryptococcus_neoformans_Serotype_B,
# 			neo_ref11 => supercontig_1.11_of_Cryptococcus_neoformans_Serotype_B,
# 			neo_ref12 => supercontig_1.12_of_Cryptococcus_neoformans_Serotype_B,
# 			neo_ref13 => supercontig_1.13_of_Cryptococcus_neoformans_Serotype_B,
# 			neo_ref14 => supercontig_1.14_of_Cryptococcus_neoformans_Serotype_B,
# 			neo_ref15 => supercontig_1.15_of_Cryptococcus_neoformans_Serotype_B,
# 			neo_ref16 => supercontig_1.16_of_Cryptococcus_neoformans_Serotype_B,
# 			neo_ref17 => supercontig_1.17_of_Cryptococcus_neoformans_Serotype_B,
# 			neo_ref18 => supercontig_1.18_of_Cryptococcus_neoformans_Serotype_B,
# 			neo_ref19 => supercontig_1.19_of_Cryptococcus_neoformans_Serotype_B,
# 			neo_ref20 => supercontig_1.20_of_Cryptococcus_neoformans_Serotype_B,
# 			neo_ref21 => supercontig_1.21_of_Cryptococcus_neoformans_Serotype_B,
# 			neo_ref22 => supercontig_1.22_of_Cryptococcus_neoformans_Serotype_B,
# 			neo_ref23 => supercontig_1.23_of_Cryptococcus_neoformans_Serotype_B,
# 			neo_ref24 => supercontig_1.24_of_Cryptococcus_neoformans_Serotype_B,
# 			neo_ref25 => supercontig_1.25_of_Cryptococcus_neoformans_Serotype_B,
# 			neo_ref26 => supercontig_1.26_of_Cryptococcus_neoformans_Serotype_B,
# 			neo_ref27 => supercontig_1.27_of_Cryptococcus_neoformans_Serotype_B,
# 			neo_ref28 => supercontig_1.28_of_Cryptococcus_neoformans_Serotype_B,
# 		);


sub load_maq
{
	my $file = $_[0];
	undef %parserHash;
	%parserHash = %{&parseXML($file)};

	foreach my $id (keys %parserHash)
	{
	foreach my $register (keys %{$parserHash{$id}})
	{
# 		foreach my $key (keys %{$hash{$register}})
# 		{
# 			my $value = $hash{$register}{$key};
# 			print "$register => $key -> $value\n";
# 		}
		my $chromR = $parserHash{$id}{$register}{"chromR"};
		my $pos    = $parserHash{$id}{$register}{"posOrig"};
		my $orig   = $parserHash{$id}{$register}{"orig"};
		my $new    = $parserHash{$id}{$register}{"new"};

		$db{$id}{$chromR}{$pos}{"orig"} = $orig;
		$db{$id}{$chromR}{$pos}{"new"}  = $new;


# 	print FILE "\t<row>\n";
# 	print FILE "\t\t<chromR>$chromR</chromR>\n";
# 	print FILE "\t\t<posOrig>$posOri</posOrig>\n";
# 	print FILE "\t\t<orig>$orig</orig>\n";
# 	print FILE "\t\t<new>$new</new>\n";
# 	print FILE "\t\t<quality>$quality</quality>\n";
# 	print FILE "\t\t<depth>$depth</depth>\n";
# 	print FILE "\t\t<hits>$hits</hits>\n";
# 	print FILE "\t\t<maxMap>$maxMap</maxMap>\n";
# 	print FILE "\t\t<minQual>$minQual</minQual>\n";
# 	print FILE "\t</row>\n";
	}
	}
	undef %parserHash;
}

sub parseXML
{
	my $file = $_[0];

	open FILE, "<$file" or die "COULD NOT OPEN FILE $file: $!";
	if ( ! -f $file ) {die "FILE $file DOESNT EXISTS"};

	my $row         = 0;
	my $table       = 0;
	my $register    = 0;
	my $tableName   = "";
	my $registerT   = 0;
	my $registerTot = 0;
	my $currId      = "";
	undef %XMLhash;

	foreach my $line (<FILE>)
	{
		if ($line =~ /<table id=\"(.*)\" type=\".*\">/)
		{
			$table     = 1;
			$tableName = $1;
		}
		if ($line =~ /<\/table>/)
		{
			$table     = 0;
			$tableName = "";
			$register  = 0;
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
			  $currId = $register;
			}
			$row    = 1;
		}
		elsif ($line =~ /<\/row>/)
		{
			$row = 0;
			$register++;
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
					$XMLhash{$tableName}{$register}{$key} = $value;
# 					$XMLhash{$tableName}{$currId}{$key} = $value;
				}
				else
				{
					die "TABLE NAME NOT DEFINED\n";
				}
			}
		}
	}

	close FILE;
	print "  FILE $file \tPARSED: $registerTot REGISTERS RECOVERED FROM $registerT TABLES\n";
	return \%XMLhash;
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


1;
