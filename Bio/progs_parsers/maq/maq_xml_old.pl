#!/usr/bin/perl -w
use strict;
use warnings;
# use AnyData::Format::XML;
use AnyData;
use Data::Dumper;
# use XML::Twig;
# use XML::Parser;

my $outdir          = "./";

`rm -Rf xml`;
mkdir "xml";

print "PARSING SNP FILES\n";

&parser("$outdir");

sub parser
{
	my $dir     = $_[0];

	print "dir\n";

	my @files = &list_dir($dir,"final.snp");

	foreach my $file (sort @files)
	{
		print " " x2 . "$file\n";
		(my $name)  = ($file =~ /^(.*).final.snp$/);
		my $filename = "$dir/$file";
		if ( -f "$filename" )
		{
			open FILE, "<$filename" or die "  COULD NOT OPEN FILE $filename: $!";
			my @total   = <FILE>;
			print " " x4 . @total . " LINES TO BE LOADED\n";
			if (@total)
			{
				&parse_snps(\@total,$name);
			}
			close FILE;
		} # end if dir/file doesnt exists
	} # end foreach my file
}


sub parse_snps
{
	my @content  = @{$_[0]};
	my $name     = $_[1];
	print " " x6 . "LINES  = " . scalar(@content) . "\n";

	if (@content)
	{
		print " " x6 . "EXPORTING XML FILE: xml/maq_snps_$name.xml\n";
		open FILE,  ">xml/maq_snps_$name.xml" || die "COULD NOT OPEN XML FILE FOR FILENAME $name: $!";
		print FILE  "<root id=\"maq\" type=\"snp\">\n";
		print FILE  "\t<table id=\"maq\" type=\"program\">\n";
		foreach my $line (@content)
		{
# 				chrom							pos     orig    new     qual    depth   hits    Maxmap  minqual
# 				supercontig_1.01_of_Cryptococcus_neoformans_Serotype_B	6	T	C	135	36	1.00	63	56
# 				supercontig_1.01_of_Cryptococcus_neoformans_Serotype_B	7	C	A	171	48	1.00	63	62
# 				supercontig_1.01_of_Cryptococcus_neoformans_Serotype_B	3099	G	T	48	7	1.00	63	34
# 				supercontig_1.01_of_Cryptococcus_neoformans_Serotype_B	8784	C	G	48	7	1.00	63	22
			if ($line =~ /(\S+)\s+(\d+)\s+(\w+)\s+(\w+)\s+(\d+)\s+(\d+)\s+(\S+)\s+(\d+)\s+(\d+)/)
				#     chrom   pos     orig    new     qual    depth   hits     Maxmap  minqual
				#     1       2       3       4       5       6       7        8       9
			{
				my $chromR     = $1;
				my $posOri     = $2;
				my $orig       = $3;
				my $new        = $4;	
				my $quality    = $5;
				my $depth      = $6;
				my $hits       = $7;
				my $maxMap     = $8;
				my $minQual    = $9;

# 				print "$chromR\t$posOri\t$orig\t$new\n";
				
				print FILE "\t\t<row>\n";
				print FILE "\t\t\t<chromR>$chromR</chromR>\n";
				print FILE "\t\t\t<posOrig>$posOri</posOrig>\n";
				print FILE "\t\t\t<orig>$orig</orig>\n";
				print FILE "\t\t\t<new>$new</new>\n";
				print FILE "\t\t\t<quality>$quality</quality>\n";
				print FILE "\t\t\t<depth>$depth</depth>\n";
				print FILE "\t\t\t<hits>$hits</hits>\n";
				print FILE "\t\t\t<maxMap>$maxMap</maxMap>\n";
				print FILE "\t\t\t<minQual>$minQual</minQual>\n";
				print FILE "\t\t</row>\n";
			} #end if match re
		} #end foreach my line
		print FILE  "\t</table>\n";
		print FILE  "</root>\n";
		close FILE;
	} #end if @content
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
	my @dirs = grep { (!/^\./) && -d "$dir/$_" } readdir(DIR);
	closedir DIR;

	return @dirs;
}


1;