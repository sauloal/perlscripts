#!/usr/bin/perl -w
use strict;


#open file
#get headers
#get number of columns
#generate array with data
#calculate sigma and mi
#subtract mi
#calculate covar
#calculate relative covar
die "USAGE: $0 <INPUT TAB FILE> [-rename from_column_name to_column_name] [-renameRE from_column_name to_column_name] [-exclude from_column_names] [-excludeRE re_from_column_names]" if (@ARGV < 1);
my $inFile = $ARGV[0];

die "INPUT FILE DOES NOT EXISTS" if ( ! -f      $inFile );

my %filters;
my %filtersRE;
my %excludeCols;
my %excludeColsRE;
for (my $a = 1; $a < @ARGV; $a++)
{
	my $arg = $ARGV[$a];
	if ($arg eq "-rename")
	{
		$filters{$ARGV[$a+1]} = $ARGV[$a+2] if (( defined $ARGV[$a+1] ) && ( defined $ARGV[$a+2] ));
		print "RENAMING ", $ARGV[$a+1], " TO ", $ARGV[$a+2], "\n";
		$a += 2;
	}
	elsif ($arg eq "-renameRE")
	{
		$filtersRE{$ARGV[$a+1]} = $ARGV[$a+2] if (( defined $ARGV[$a+1] ) && ( defined $ARGV[$a+2] ));
		print "RENAMING ", $ARGV[$a+1], " TO ", $ARGV[$a+2], "\n";
		$a += 2;
	}
	elsif ($arg eq "-exclude")
	{
		$a++;
		for (;$a < @ARGV; $a++)
		{
			my $col = $ARGV[$a];
			if ( $col eq "-rename")    { $a--; last; }
			if ( $col eq "-renameRE")  { $a--; last; }
			if ( $col eq "-excludeRE") { $a--; last; }
			$excludeCols{$col} = -1;
			print "\tEXCLUDING COLUMNS NAMED $col\n";
		}
	}
	elsif ($arg eq "-excludeRE")
	{
		$a++;
		for (;$a < @ARGV; $a++)
		{
			my $col = $ARGV[$a];
			if ( $col eq "-rename")    { last; }
			if ( $col eq "-renameRE")  { last; }
			if ( $col eq "-exclude") { last; }
			$excludeColsRE{$col} = -1;
			print "\tEXCLUDING COLUMNS CONTAINING $col\n";
		}
	}
	else
	{
		die "UNKNOWN PARAMETER :: $arg\n";
	}
}

my $space                  = 15;
my $ouFile_raw             = $inFile . "_PCA_00_raw.txt";
my $ouFile_raw_stat        = $inFile . "_PCA_00_stat.txt";
my $ouFile_sub             = $inFile . "_PCA_01_sub_0_raw.txt";
my $ouFile_sub_stat        = $inFile . "_PCA_01_sub_0_stat.txt";
my $ouFile_std             = $inFile . "_PCA_02_std_0_raw.txt";
my $ouFile_std_stat        = $inFile . "_PCA_02_std_0_stat.txt";

my $ouFile_sub_cov         = $inFile . "_PCA_01_sub_1_cov.txt";
my $ouFile_sub_cov_std     = $inFile . "_PCA_01_sub_1_cov_0_std.txt";
my $ouFile_std_cov         = $inFile . "_PCA_02_std_1_cov.txt";
my $ouFile_std_cov_std     = $inFile . "_PCA_02_std_1_cov_0_std.txt";

my $ouFile_sub_cov_sqr     = $inFile . "_PCA_01_sub_2_cov_1_sqr.txt";
my $ouFile_sub_cov_sqr_std = $inFile . "_PCA_01_sub_2_cov_1_sqr_std.txt";
my $ouFile_std_cov_sqr     = $inFile . "_PCA_02_std_2_cov_1_sqr.txt";
my $ouFile_std_cov_sqr_std = $inFile . "_PCA_02_std_2_cov_1_sqr_std.txt";






my $lineCount        = -1;
my $columnCount      = 0;
my $totalColumnCount = 0;
my %columnsNames_raw;
my @columnsNumbers_raw;
my @array_raw;

open INFILE, "<$inFile" or die "COULD NOT OPEN INPUT FILE $inFile :: $!";
open (my $fh_raw, ">$ouFile_raw") or die "COULD NOT OPEN $ouFile_raw: $!";
print "OPENING INPUT FILE $inFile\n";


my @excCol;
while (my $line = <INFILE>)
{
	chomp $line;
	#next if ( ! $line);
	my @data = split("\t",$line);
	if ($lineCount == -1)
	{
		print "\tOBTAINING COLUMN HEADERS (",scalar @data,")\n";
		for (my $d = 0 ; $d < @data; $d++)
		{
			my $header = $data[$d];
			#print "HEADER: $header\t";
			$header =~ s/\"//g;
			$header =~ s/[^a-zA-Z0-9_]//g;

			#print "$header\n";
			if (( ! exists $excludeCols{$header} ) && ( $header ne "" ) && ( $header ne " " ))
			{
				my $failRe = 0;
				foreach my $fromRE (keys %excludeColsRE)
				{
					if ($header =~ /$fromRE/)
					{
						print "\t\tFILTERING REGULAR EXPRESSION $fromRE [$d]\n";
						$excCol[$d] = 1;
						$failRe = 1;
						$totalColumnCount++;
						last;
					}
				}

				if ($failRe) { print "\t\t\tSKIPPING\n"; next;};

				foreach my $fromRE (keys %filtersRE)
				{
					if ($header =~ /$fromRE/)
					{
						my $to = $filtersRE{$fromRE};
						$header =~ s/$fromRE/$to/i;
						print "\t\tRENAMING $fromRE TO $to [$d]\n";
					}
				}

				foreach my $from (keys %filters)
				{
					if (index($header, $from) != -1)
					{
						my $to = $filters{$from};
						$header =~ s/$from/$to/i;
						print "\t\tRENAMING $from TO $to [$d]\n";
					}
				}

				if ( $columnCount > 0) { print $fh_raw "\t"; };

				print $fh_raw $header;

				push(@columnsNumbers_raw, $header);
				$columnsNames_raw{$header} = @columnsNumbers_raw - 1;
				print "\t\tADDING COLUMN $header [$d = $columnCount]\n";
				$columnCount++;
			}
			else
			{
				$excCol[$d] = 1;
				print "\t\tSKIPPING COLUMNS [$header] [$d]\n";
			}
			$totalColumnCount++;
		}
		print $fh_raw "\n";
	}
	else
	{
		if ( ! $lineCount ) { print "\tADDING DATA [",scalar(@data)," COLS vs ",$totalColumnCount," COLS]\n"; };

		if (@data != $totalColumnCount)
		{
			print "\tWRONG NUMBER OF COLUMNS: ", scalar(@data), " vs $totalColumnCount. SKIPPING. \"",@array_raw,"\"\n";
			$lineCount++;
			next;
		};

		my @newData;
		my $valid = 1;
		my $error = "";
		for (my $d = 0 ; $d < @data; $d++)
		{
			my $nfo = $data[$d];
			   $nfo =~ s/\"//g;
			#print "$header\t";
			if ( ! defined $nfo )    { $valid = 0; $error = "NOT DEFINED NFO";           last };
			#if ( $nfo eq "" )        { $valid = 0; $error = "EMPTY COLUMN #$d \"$nfo\""; last };
			if ( $nfo eq "" )        { $nfo = 0; };
			if ( ! ($nfo =~ /\d*/) ) { $valid = 0; $error = "NFO NOT NUMBER";            last };

			if ( ! defined $excCol[$d] )
			{
				push(@newData, $nfo);
			}
		}
		#print "\n";
		if  ((@data) && ( $valid ))
		{
			#print "ADDING DATA :: ",(scalar @array_raw)," :: ", $line, " (",scalar @data,")\n";
			push(@array_raw, \@newData);
			print $fh_raw join("\t", @newData), "\n";
		}
		else
		{
			print "SKIPPING DATA :: ",(scalar @data)," COLUMNS :: ", $line, " :: ERROR \"$error\"\n";
		}
	}
	$lineCount++;
}
close INFILE;
close $fh_raw;
print "CLOSING INPUT FILE $inFile\n";
print "TOTAL " , scalar(@array_raw), " REGISTERS IMPORTED EACH CONTAINING ",$columnCount," COLUMNS\n";

die "FAILED TO LOAD DATA." if ( ! scalar(@array_raw) );

my $maxX = $columnCount;
my $maxY = scalar(@array_raw);

my ($raw_sum, $raw_avg, $raw_mi, $raw_var, $raw_sd, $raw_order, $sub_names, $sub_numbers) = &statArray(\@array_raw, \%columnsNames_raw, \@columnsNumbers_raw, $ouFile_raw_stat);


open (my $fh_sub, ">$ouFile_sub") or die "COULD NOT OPEN $ouFile_sub: $!";
open (my $fh_std, ">$ouFile_std") or die "COULD NOT OPEN $ouFile_std: $!";
for (my $c = 0; $c < $maxX; $c++)
{
	if ( $c != 0 ) { print $fh_sub "\t"; };
	if ( $c != 0 ) { print $fh_std "\t"; };
	print $fh_sub $columnsNumbers_raw[$c];
	print $fh_std $columnsNumbers_raw[$c];

}
print $fh_sub "\n";
print $fh_std "\n";

my @array_sub;
my @array_std;
for (my $y = 0; $y < $maxY; $y++)
{
	my $order = 0;
	foreach my $x (@{$raw_order})
	{
		#print "VALUE = ", $array_raw[$y][$x], " - ", $raw_mi->[$x], " = ", ($array_raw[$y][$x] - $raw_mi->[$x]), "\n";
		$array_sub[$y][$order] =  ($array_raw[$y][$x] - $raw_mi->[$x]);

		if ( $raw_var->[$x] )
		{
			$array_std[$y][$order] = (($array_raw[$y][$x] - $raw_mi->[$x]) / $raw_var->[$x]) || 0;
		} else {
			$array_std[$y][$order] = 0;
			die "INVALID COLUMN ", $columnsNumbers_raw[$x],". NO VARIANCE.\n";
		}

		$order++;
	}
	print $fh_sub join("\t", @{$array_sub[$y]}), "\n";
	print $fh_std join("\t", @{$array_std[$y]}),   "\n";
}
close $fh_std;
close $fh_sub;

my ($sub_sum, $sub_avg, $sub_mi, $sub_var, $sub_sd, $sub_order, $sub_names_new, $sub_numbers_new) = &statArray(\@array_sub, $sub_names, $sub_numbers, $ouFile_sub_stat);
my ($std_sum, $std_avg, $std_mi, $std_var, $std_sd, $std_order, $std_names_new, $std_numbers_new) = &statArray(\@array_std, $sub_names, $sub_numbers, $ouFile_std_stat);

my ($sub_covar, $sub_covar_std) = &covarMatrix(\@array_sub, $sub_names_new, $sub_numbers_new, $ouFile_sub_cov, $ouFile_sub_cov_std);
my ($std_covar, $std_covar_std) = &covarMatrix(\@array_std, $std_names_new, $std_numbers_new, $ouFile_std_cov, $ouFile_std_cov_std);

my $sub_sqDistCovar      = &sqDistCovar($sub_covar,     $sub_names_new, $sub_numbers_new, $ouFile_sub_cov_sqr);
my $sub_sqDistCovar_std  = &sqDistCovar($sub_covar_std, $sub_names_new, $sub_numbers_new, $ouFile_sub_cov_sqr_std);

my $std_sqDistCovar      = &sqDistCovar($std_covar,     $std_names_new, $std_numbers_new, $ouFile_std_cov_sqr);
my $std_sqDistCovar_std  = &sqDistCovar($std_covar_std, $std_names_new, $std_numbers_new, $ouFile_std_cov_sqr_std);

sub sqDistCovar
{
	my $covar      = $_[0];
	my $colNames   = $_[1];
	my $colNumbers = $_[2];
	my $fileOut    = $_[3];

	open (my $fh, ">$fileOut") or die "COULD NOT OPEN $fileOut: $!";

	my @sqCovar;

	for (my $x1 = 0; $x1 < $maxX; $x1++)
	{
		for (my $x2 = 0; $x2 < $maxX; $x2++)
		{
			$sqCovar[$x1][$x2] = $covar->[$x1][$x1] + $covar->[$x2][$x2] - (2*$covar->[$x1][$x2]);
		}
	}


	print $fh "\t", join("\t", @{$colNumbers}), "\n";
	for (my $x1 = 0; $x1 < @sqCovar; $x1++)
	{
		print $fh $colNumbers->[$x1], "\t";
		print $fh join( "\t", map { (int(($_)*100)/100) } @{$sqCovar[$x1]} ), "\n";
	}

	close $fh;
	return \@sqCovar;
}

sub covarMatrix
{
	my $array      = $_[0];
	my $colNames   = $_[1];
	my $colNumbers = $_[2];
	my $fileOutC   = $_[3];
	my $fileOutSC  = $_[4];

	my @covarSum;
	for (my $y = 0; $y < $maxY; $y++)
	{
		for (my $x1 = 0; $x1 < $maxX; $x1++)
		{
			for (my $x2 = 0; $x2 < $maxX; $x2++)
			{
				$covarSum[$x1][$x2] += $array->[$y][$x1] * $array->[$y][$x2];
			}
		}
	}

	my @covar;
	my @sumCovar;
	my @miCovar;
	for (my $x1 = 0; $x1 < $maxX; $x1++)
	{
		for (my $x2 = 0; $x2 < $maxX; $x2++)
		{
			$covar[$x1][$x2] = $covarSum[$x1][$x2] / ($maxY-1);
			$sumCovar[$x1] += $covar[$x1][$x2];
		}
		$miCovar[$x1] = $sumCovar[$x1] / ($maxX - 1);
		#print "FOR $x1: SUM $sumCovar[$x1] / ", ($maxX)," = $miCovar[$x1]\n";
	}

	my @sdSumCovar;
	for (my $x1 = 0; $x1 < $maxX; $x1++)
	{
		for (my $x2 = 0; $x2 < $maxX; $x2++)
		{
			$sdSumCovar[$x1] += ($covar[$x1][$x2] - $miCovar[$x1]) ** 2;
		}
		#print "FOR $x1: SDSUM $sdSumCovar[$x1]\n";
	}

	my @varCovar;
	my @sdCovar;
	for (my $x1 = 0; $x1 < $maxX; $x1++)
	{
		for (my $x2 = 0; $x2 < $maxX; $x2++)
		{
			$varCovar[$x2] =     ($sdSumCovar[$x2] / ($maxX - 1));
			$sdCovar[$x2]  = sqrt($sdSumCovar[$x2] / ($maxX - 1));
		}
		#print "FOR $x1: VAR:      ", $sdSumCovar[$x1], " / ",$maxX - 1,"  = $varCovar[$x1]\n";
		#print "FOR $x1: SD : SQRT(", $sdSumCovar[$x1], " / ",$maxX - 1,") = $sdCovar[$x1]\n";
	}


	my @scovar;
	for (my $x1 = 0; $x1 < $maxX; $x1++)
	{
		for (my $x2 = 0; $x2 < $maxX; $x2++)
		{
			my $mi  = $miCovar[$x2];
			my $var = $varCovar[$x2];
			my $sd  = $sdCovar[$x2];

			if ( $sd )
			{
				$scovar[$x1][$x2] = ($covar[$x1][$x2] - $mi) / $sd;
			} else {
				$scovar[$x1][$x2] = 0;
				print "INVALID COLUMN ", $colNumbers->[$x1], " or ",$colNumbers->[$x2],". NO VARIANCE.\n";
			}
		}
	}

	open (my $fhC,  ">$fileOutC" ) or die "COULD NOT OPEN $fileOutC: $!";
	open (my $fhSC, ">$fileOutSC") or die "COULD NOT OPEN $fileOutSC: $!";

	print $fhC "\t", join("\t", @{$colNumbers}), "\n";
	for (my $x1 = 0; $x1 < @covar; $x1++)
	{
		print $fhC $colNumbers->[$x1], "\t";
		print $fhC join( "\t", map { (int(($_)*100)/100) } @{$covar[$x1]} ), "\n";
	}


	print $fhSC "\t", join("\t", @{$colNumbers}), "\n";
	for (my $x1 = 0; $x1 < @scovar; $x1++)
	{
		print $fhSC $colNumbers->[$x1], "\t";
		print $fhSC join( "\t", map { (int(($_)*100)/100) } @{$scovar[$x1]} ), "\n";
	}

	close $fhC;
	close $fhSC;

	return (\@covar, \@scovar);
}

sub statArray
{
	my $array      = $_[0];
	my $colNames   = $_[1];
	my $colNumbers = $_[2];
	my $fileOut    = $_[3];

	open (my $fh, ">$fileOut") or die "COULD NOT OPEN $fileOut: $!";

	print $fh "\t", join("\t", @{$colNumbers}), "\n";

	my @sum;
	for (my $y = 0; $y < $maxY; $y++)
	{
		for (my $x = 0; $x < $maxX; $x++)
		{
			$sum[$x] += $array->[$y][$x];
		}
		printf $fh "Y%04d", $y;
		print $fh "\t", join("\t", map { (int(($_)*100)/100) } @{$array->[$y]}), "\n";
	}


	my @avg;
	for (my $x = 0; $x < $maxX; $x++)
	{
		$avg[$x] = ($sum[$x]/($maxY-1));
	}


	my @mi;
	for (my $x = 0; $x < $maxX; $x++)
	{
		$mi[$x] = ($sum[$x]/($maxY));
	}


	my @sdSum;
	for (my $y = 0; $y < $maxY; $y++)
	{
		for (my $x = 0; $x < $maxX; $x++)
		{
			#print "VALUE = ", $array_raw[$y][$x], " - ", $mi[$x], " = ", (($array_raw[$y][$x] - $mi[$x]) ** 2), " + ",($sdSum[$x] || 0),"\n";
			$sdSum[$x] += (($array->[$y][$x] - $mi[$x]) ** 2);
		}
		#print "\n";
	}

	my @var;
	my @sd;
	for (my $x = 0; $x < $maxX; $x++)
	{
		#print "SDSUM: ", $sdSum[$x], " / ",$maxY-1,"\n";
		$var[$x] =     ($sdSum[$x] / ($maxY-1));
		$sd[$x]  = sqrt($sdSum[$x] / ($maxY-1));
	}

	print $fh "SUM\t", join("\t",map { (int(($_)*100)/100) } @sum), "\n";
	print $fh "AVG\t", join("\t",map { (int(($_)*100)/100) } @avg), "\n";
	print $fh "MI\t" , join("\t",map { (int(($_)*100)/100) } @mi ), "\n";
	print $fh "SD\t" , join("\t",map { (int(($_)*100)/100) } @sd ), "\n";
	print $fh "VAR\t", join("\t",map { (int(($_)*100)/100) } @var), "\n";



	my %seen;
	for (my $s = 0; $s < @var; $s++)
	{
		my $v = int(($var[$s]+100) * 10_000_000);
		#my $v = $var[$s];
		while ( exists $seen{$v} )
		{
			if ( exists $seen{$v + 1} )
			{
				#die "NOW YOU HAVE TO FIX IT YOUR LAZY GUY";
				$| = 1;
				#print "S $s V $v EXISTS\n";
			}
			$v++;
		}
		$seen{$v} = $s;
	}

	my @order;
	map { push(@order, $seen{$_}) } sort {$b <=> $a} keys %seen;
	my %newColNames;
	my @newColNumbers;

	for (my $o = 0; $o < @order; $o++)
	{
		my $name = $colNumbers->[$order[$o]];
		$newColNames{$name} = $o;
		$newColNumbers[$o]  = $name;
	}
	print $fh "\n"x3;

	close $fh;

	return (\@sum, \@avg, \@mi, \@var, \@sd, \@order, \%newColNames, \@newColNumbers);
}

1;
