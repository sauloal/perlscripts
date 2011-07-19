#!/usr/bin/perl -w
use strict;
use List::Util qw(max);
use MIME::Base64;

# INPUTS: XML FILE NAME
#         FASTA ORIGNAL GENOME FILE NAME

(my $inputFA, my @inputXML) = @ARGV;

&init($inputFA, @inputXML);



sub exportData
{
	my $XMLpos    = $_[0];
	mkdir("XMLpos");

	my @gen;
	my @gap;

	open MERGED, ">XMLpos/merged_order.txt"      or die "COULD NOT OPEN MERGED_ORDER.TXT";
	open TAB,    ">XMLpos/merged_order_tab.txt"  or die "COULD NOT OPEN MERGED_ORDER_TAB.TXT";
	open XML,    ">XMLpos/XMLpos.xml"     or die "COULD NOT OPEN XMLpos/XMLPOS.XML";

	my $id = 0;
		#<pos id="XMLpos" type="pos">
		#	<table id="CP000286_CGB_A1680C_Nucleic_acid_binding_protein_putative_352276_358966" type="chromossome">
		#		<pos id="1">
		#			<id>1</id>
	print XML    "<pos id=\"XMLpos\" type=\"pos\">\n";
	print TAB    "pos\n";
	print MERGED "pos\tchromName\tpos\ttype\tfeat\tvalue\n";

	#$hash->{$tableName}[$currId]{$rootType}{$key} = $value;
	foreach my $chromName( sort keys %$XMLpos)
	{
		my $poses = $XMLpos->{$chromName};

		print XML       "\t<table id=\"$chromName\" type=\"chromossome\">\n";
		open  XMLCHROM, ">XMLpos/XMLpos_$chromName.xml"       or die "COULD NOT OPEN XMLpos/XMLPOS_$chromName.XML";
		print XMLCHROM  "<pos id=\"XMLpos\" type=\"pos\">\n";
		print XMLCHROM  "\t<table id=\"$chromName\" type=\"chromossome\">\n";
		print TAB       "\t$chromName\n";
		for (my $pos = 0; $pos <  @$poses; $pos++)
		{
			if (defined $poses->[$pos])
			{
				print XML      "\t\t<pos id=\"$pos\">\n";
				print XMLCHROM "\t\t<pos id=\"$pos\">\n";
				print TAB      "\t\t$pos\n";
				$id++;

				my $types = $poses->[$pos];
				foreach my $type (sort keys %$types)
				{
					print TAB      "\t\t\t$type\n";
					print XML      "\t\t\t<$type>\n";
					print XMLCHROM "\t\t\t<$type>\n";

					my $keys = $types->{$type};
					foreach my $key (sort keys  %$keys)
					{
						my $value = $keys->{$key};
						print MERGED   "$chromName >>> $pos >> $type > $key = $value\n";
						print TAB      "\t\t\t\t$key\t$value\n";
						print XML      "\t\t\t\t<$key>$value</$key>\n";
						print XMLCHROM "\t\t\t\t<$key>$value</$key>\n";
					} # end foreach my key
					#print XML      "\t\t\t<id>$id</id>\n";

					print XML      "\t\t\t</$type>\n";
					print XMLCHROM "\t\t\t</$type>\n";
				}
				print XMLCHROM "\t\t\t<pos>$pos</pos>\n";
				print XML      "\t\t\t<pos>$pos</pos>\n";
			} #end if defined pos
		} #end for my pos
		print XML      "\t</table>\n";
		print XMLCHROM "\t</table>\n";
		print XMLCHROM "</root>\n";
		close XMLCHROM;
	} #end for my chromnum
	print XML "</pos>\n";
	close XML;
	close TAB;
	close MERGED;
	print "EXPORTED $id DATA...";
} #end sub exportData


sub loadXML
{
	my $file    = $_[0];
	my $hash    = $_[1];
	my $chromos = $_[2];
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
	my $origin;
	my $tableType;
	my $tableName   = "";
	my $tableNum;
	my $row         = 0;
	my $table       = 0;
	my $currId      = "";

	my $tableCount  = 0;
	my $posCount    = 0;
	my $lineCount   = 0;

	foreach my $line (<FILE>)
	{
		if ( ! $lineCount++ )
		{
			if ($line =~ /<(\S+) id=\"(.*)\" type=\"(.*)\">/)
			{
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
			if ( ! exists ${$chromos->[0]}{$tableName} )
			{
				die "CHROMOSSOME $tableName FROM XML FILE $file DOESNT EXISTS IN FASTA FILE";
			};
			$tableNum  = $chromos->[0]{$tableName};
			$tableType = $2;
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
# 					print "$tableName $register $key $value\n";
					$hash->{$tableName}[$currId]{$rootType}{$key} = $value;
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
	my %chromos;
	my %stat;
	my %chromosMap;

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
				if ( ! defined $chromos{$chromo} )
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

	return (\%chromos, \%stat, \%chromosMap);
}


sub init
{
	my ($fastaInput, @xmlInput) = @_;
	my %XMLhash;


	if (($fastaInput) && (@xmlInput)) #checks if all parameters are set
	{
		if ( -f $fastaInput )
		{
			my $output;
			if ( ! $fastaInput =~ /\/*([\w|\.]+)\.fasta/)
			{
				die "COULD NOT RETRIEVE THE NAME FROM $fastaInput";
			}
			elsif ( $fastaInput =~ /\/*([\w|\.]+)\.fasta/)
			{
				$output = $1;
			}

			print "  INPUT  FASTA: $fastaInput\n";
			print "  INPUT  XML  :\n\t" . join("\n\t", @xmlInput) . "\n";
			print "\n";

			print "  GENERATING CHROMOSSOMES TABLE...";
			my @chromos = &genChromos($inputFA);
			print "done\n";

			foreach my $inputXML (@xmlInput)
			{
				if ( -f $inputXML )
				{
					&loadXML($inputXML, \%XMLhash, \@chromos); #obtains the xml as hash
				}
				else
				{
					my $exit;
					if (( ! -f $inputXML) && ( ! -d $inputXML)) { $exit  = "FILE $inputXML DOESNT EXISTS\n";};
					if (( ! -d $inputXML) && ( ! -f $inputXML)) { $exit .= "DIR  $inputXML DOESNT EXISTS\n";};
					print $exit;
					exit 1;
				}
			} # end foreach my inputxml


			print "  EXPORTING XMLPOS...";
			&exportData(\%XMLhash);
			print "done\n";

			#print "  EXPORTING XMLSTAT...";
			#&exportStat();
			#print "done\n";

		} # end if file INPUTFA exists
		else
		{
			my $exit;
			if ( ! -f $fastaInput)  { $exit .= "FILE $fastaInput  DOESNT EXISTS\n";};
			print $exit;
			exit 1;
		} # end else file INPUTFA exists
	} # end if FA & XML were defined
	else
	{
		print "USAGE: XML_POS.PL <INPUT FASTA.FASTA> <MULTIPLE INPUT XML>\n";
		#print "E.G.: ./xml_pos.pl input.fasta input.gap.indelsa.xml input.blast.xml input.snp.xml microarray.xml\n";
		print "E.G.: ./xml_pos2.pl original/cbs7750v4.fasta blast/blast_wm276_vs_cbs7750.blast.xml micro/blast_microarray_positive.xml snp/snp_mosaik.xml\n";
		exit 1;
	}
}


exit 0;

1;
