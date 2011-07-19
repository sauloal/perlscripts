#!/usr/bin/perl -w
use strict;
use warnings;
use List::Util qw(max);
use MIME::Base64;
use fasta;
my $outDir = "xmlPos";
mkdir($outDir);

die if @ARGV < 2;
(my $inputFA, my @inputXML) = @ARGV;
my $from = join(";", @ARGV);

die "FASTA FILE $inputFA DOESNT EXISTS\n" if ( ! -f $inputFA );
foreach my $inputXml (@inputXML)
{
	die "XML FILE $inputXml NOT FOUND" if ( ! -f $inputXml);
}

my $outputFile;
if ( $inputFA =~ /\/*([\w|\.]+)\.fasta/i)
{
	$outputFile = $1;
} else {
	die "FASTA FILE $inputFA NOT ENDING IN .fasta";
}

print "  READING FASTA...\n";
my $fasta = fasta->new($inputFA);
print "  READING FASTA...done\n";

my %xmlHash;
print "  LOADING XML...\n";
foreach my $inputXML (@inputXML)
{

	if ( -f $inputXML )
	{
		print "    LOADING XML FILE $inputXML\n";
		if ( $inputXML =~ /\/*([\w|\.]+)\.xml/i)
		{
			$outputFile .= "_" . $1;
		}
		&loadXML($inputXML, \%xmlHash); #obtains the xml as hash
		print "    LOADING XML FILE $inputXML...done\n";
	}
} # end foreach my inputxml
print "  LOADING XML...done\n";
my $outputFullPath = $outDir . "/" . $outputFile;

print "  INPUT  FASTA: $inputFA\n";
print "  INPUT  XML  :\n\t" . join("\n\t", @inputXML) . "\n";
print "  OUTPUT XML  : $outputFullPath.XMLpos.xml\n";
print "\n";



print "  EXPORTING XML POS\n";
&exportData(\%xmlHash, $from, $outDir, $outputFullPath);
print "  EXPORTING XML POS...done\n";
#print "  EXPORTING XMLPOS...";
#&exportData(\@XMLpos);
#print "done\n";
#
#print "  EXPORTING XMLSTAT...";
#&exportStat();
#print "done\n";


sub exportData
{
	my $XMLpos      = $_[0];
	my $origin      = $_[1];
	my $outPath     = $_[2];
	my $outFullPath = $_[3];

	open MERGED, ">$outFullPath.merged_order.txt"      or die "COULD NOT OPEN $outFullPath.merged_order.txt";
	#open TAB,    ">$outDir/merged_order_tab.txt"  or die "COULD NOT OPEN $outDir/MERGED_ORDER_TAB.TXT";
	open XML,    ">$outFullPath.XMLpos.xml"            or die "COULD NOT OPEN $outFullPath.XMLpos.xml";

	my $id = 0;
	print XML "<xmlpos id=\"XMLpos\" type=\"pos\" origin=\"$origin\">\n";
	#print TAB "\"chrom\"\t\"pos\"\ttype\tnfo\n";
	foreach my $chrom (sort keys %$XMLpos)
	{
			my $poses = $XMLpos->{$chrom};

			print XML       "\t<table id=\"$chrom\" type=\"chromossome\">\n";
			open  XMLCHROM, ">$outFullPath.XMLpos.$chrom.xml"       or die "COULD NOT OPEN $outDir/XMLPOS_$chrom.XML";
			print XMLCHROM  "<xmlpos id=\"XMLpos\" type=\"pos\" origin=\"$origin\">\n";
			print XMLCHROM  "\t<table id=\"$chrom\" type=\"chromossome\">\n";
			#print TAB       "\t$chrom\n";
			for (my $pos = 0; $pos <  @$poses; $pos++)
			{
				my $types = $poses->[$pos];
				next if ! defined $types;

				print XML      "\t\t<pos id=\"$pos\">\n";
				print XMLCHROM "\t\t<pos id=\"$pos\">\n";
				#print TAB      "\t\t$pos\n";

				foreach my $type (sort keys %$types)
				{
					my $units = $types->{$type};
					print XML      "\t\t\t<$type>\n";
					print XMLCHROM "\t\t\t<$type>\n";

					for (my $k = 0; $k < @$units; $k++)
					{
						my $keys = $units->[$k];
						print XML      "\t\t\t\t<unit id=\"$k\">\n";
						print XMLCHROM "\t\t\t\t<unit id=\"$k\">\n";

						if (defined $keys)
						{
							foreach my $key (sort keys %$keys)
							{
								my $value = $keys->{$key};
								print MERGED "$chrom >> $pos > $type : $k :: $key = $value\n";
								#print        "$chrom >> $pos > $type : $k :: $key = $value\n";
								print XML      "\t\t\t\t\t<$key>$value</$key>\n";
								print XMLCHROM "\t\t\t\t\t<$key>$value</$key>\n";
							}
						}
						print XML      "\t\t\t\t</unit>\n";
						print XMLCHROM "\t\t\t\t</unit>\n";
					}
					print XML      "\t\t\t</$type>\n";
					print XMLCHROM "\t\t\t</$type>\n";
				}

				print XML      "\t\t</pos>\n";
				print XMLCHROM "\t\t</pos>\n";

			} #end for my pos
			print XML      "\t</table>\n";
			print XMLCHROM "\t</table>\n";
			print XMLCHROM "</root>\n";
			close XMLCHROM;
	} #end for my chromnum
	print XML "</root>\n";
	close XML;
	#close TAB;
	close MERGED;
} #end sub exportData


sub loadXML
{
	my $file    = $_[0];
	my $hash    = $_[1];

	open FILE, "<$file" or die "COULD NOT OPEN FILE $file: $!";
		#<blast id="r265_vs_wm276.blast" type="blast">
		#	<table id="CP000286_CGB_A1680C_Nucleic_acid_binding_protein_putative_352276_358966" type="chromossome">
		#		<pos id="1">
		#			<id>1</id>

		#<microarray id="Microarray_may_r265_data.csv.xml.blast" type="microarray">
		#	<table id="supercontig_1.01_of_Cryptococcus_gattii_CBS7750v4" type="chromossome">
		#		<pos id="14642">
		#			<id>1</id>

		#<snp id="mosaik" type="snp">
		#	<table id="supercontig_1.01_of_Cryptococcus_neoformans_Serotype_B" type="chromossome">
		#		<pos id="7">
		#			<Pvalue>0.0</Pvalue>
	my $rootType;
	my $rootOrig;
	my $origin;
	my $tableType;
	my $tableName   = "";

	my $row         = 0;
	my $table       = 0;
	my $currId      = "";

	my $tableCount  = 0;
	my $posCount    = 0;
	my $lineCount   = 0;
	my @poses;

	foreach my $line (<FILE>)
	{
		if ( ! $lineCount++ )
		{
			if ($line =~ /<(\S+) id=\"(.*)\" type=\"(.*)\">/)
			{
				$rootOrig = $1;
				$origin   = $2;
				$rootType = $3;
			} else {
				die "INVALID FIRST LINE\n";
			}
		}
		elsif (( ! $table ) && ($line =~ /<table id=\"(.*)\" type=\"(.*)\">/))
		{
			$table     = 1;
			$tableName = $1;
			$tableType = $2;
			print "      IMPORTING INFO FOR TABLE :: $tableName\n";
		}
		elsif (( $table ) && ($line =~ /<\/table>/))
		{
			$table     = 0;
			$tableName = "";
# 			$register  = 0;
			$tableCount++;
		}
		elsif (( $table ) && ( $line =~ /\<pos (id=\"(\d+)\").*\>/ ))
		{
			if (defined $2)
			{
			  $currId = $2;
			}
			else
			{
			  die "WRONG FORMAT";
			}
			$row = 1;
			$posCount++;
			$poses[$tableCount][$currId]++;
		}
		elsif (( $row ) && ($line =~ /<\/pos\>/))
		{
			$row = 0;
		}
		elsif ( $row )
		{
			if ($line =~ /<(\w+)>(\S+)<\/\1>/)
			{
# 				print "$line\n";
				my $key   = $1;
				my $value = $2;
# 				print "$register => $key -> $value\n";
				if ($tableName)
				{
 					#print "$tableName $currId $rootOrig ",($poses[$tableCount][$currId] - 1)," $key $value\n";
					$hash->{$tableName}[$currId]{$rootOrig}[$poses[$tableCount][$currId] - 1]{$key} = $value;
# 					$XMLhash{$tableName}{$currId}{$key} = $value;
				}
				else
				{
					die "TABLE NAME NOT DEFINED IN XML $file\n";
				}
			}
		}
	}

	close FILE;
	print "  FILE $file PARSED: $posCount REGISTERS RECOVERED FROM $tableCount TABLES\n";
	print "  ROOT TYPE: $rootType TABLE TYPE: $tableType\n";
	return $hash;
}




1;
