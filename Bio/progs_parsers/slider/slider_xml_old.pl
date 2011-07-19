#!/usr/bin/perl -w
use strict;
use warnings;
# use AnyData::Format::XML;
use AnyData;
use Data::Dumper;
# use XML::Twig;
# use XML::Parser;

my $outdir          = "data/OUT/neo/neo/Results/ScoreResults";

`rm -Rf xml`;
mkdir "xml";

print "PARSING SNP FILES\n";

&parser("$outdir");

sub parser
{
	my $dir     = $_[0];

	print "dir\n";

	my @files = &list_dir($dir,".snp");

	foreach my $file (sort @files)
	{
		print " " x2 . "$file\n";
		(my $name)  = ($file =~ /^(.*).fa.snp$/);
		my $filename = "$dir/$file";
		if ( -f "$filename" )
		{
			open FILE, "<$filename" or die "  COULD NOT OPEN FILE $filename: $!";
			my @total   = <FILE>;
			print " " x4 . @total . " LINES TO BE LOADED\n";
			if (@total > 5)
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
	my $name = $_[1];
	print " " x6 . "LINES  = " . scalar(@content) . "\n";

	if (@content > 5)
	{
		print " " x6 . "EXPORTING XML FILE: xml/snps_$name.xml\n";
		open FILE,  ">xml/snps_$name.xml" || die "COULD NOT OPEN XML FILE FOR FILENAME $name: $!";
		print FILE  "<root id=\"slider\" type=\"snp\">\n";
		print FILE  "\t<table id=\"slider\" type=\"program\">\n";
		foreach my $line (@content)
		{
				#     total  coverage:        (       4717801 +       5908    +       959422  ) =     5683131 X =     7.87
				#     actual coverage:        (       704542  +       5756    +       502749  ) =     1213047 X =     0.97
				#     cut:    1.0378511       Average:        7.878904        var:    2.689648
				#     SNPid   Location map    cmCount mCount  nmCount wSNP%   cSNP%   ncSNP%  cmScore nmScore1 Ref     MPB    Pm(A)   Pm(C)   Pm(G)   Pm(T)   Pnm(A)  Pnm(C)  Pnm(G) Pnm(T)
				#     -----   -----   -----   -----   -----   -----   -----   -----   -----   -----   -----   -----   -----   -----   -----   -----   -----   -----   -----
				#       0       6675    72      0       2       5       99.97%  100.0%  87.73%  0.0     4.51    G       T       0.49    0.0     12.2    87.29   0.0     0.0     0.0     99.97
				#       1       53436   72      0       0       4       99.79%  100.0%  0.0%    0.0     2.84    C       T       0.0     0.0     0.0     0.0     0.18    0.0     0.0     99.79
			if ($line =~ /(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\S+)%\s+(\S+)%\s+(\S+)%\s+(\S+)\s+(\S+)\s+(\w+)\s+(\w)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)/)
			#             id      loc     map     cmCo    mC      nmC     wsnp     csnp     ncsn     cms     nmsco  ref    mpb     pma     pmc     pmg     pmt     pnma    pnmc    pnmg    pnmt
			#             1       2       3       4       5       6       7        8        9        10      11     12     13      14      15      16      17      18      19       20      21 
			{
				my $posOri     = $2;
				my $complexity = $3;
				my $wsnp       = $7;
				my $csnp       = $8;
				my $orig       = $12;
				my $new        = $13;	
				my $status     = "homozygous";

				if (($wsnp < 70) || ($csnp < 70))
				{
					print "#"x10 . "\nDANGER" . "#"x10;
					$status = "heterozygous";
				}

				my $chromR = $name;
# 				print "$chromR\t$posOri\t$orig\t$new\n";
				
				print FILE "\t\t<row>\n";
				print FILE "\t\t\t<chromR>$chromR</chromR>\n";
				print FILE "\t\t\t<posOrig>$posOri</posOrig>\n";
				print FILE "\t\t\t<orig>$orig</orig>\n";
				print FILE "\t\t\t<new>$new</new>\n";
				print FILE "\t\t\t<zygo>$status</zygo>\n";
				print FILE "\t\t\t<complexity>$complexity</complexity>\n";
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