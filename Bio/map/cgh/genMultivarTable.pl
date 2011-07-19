#!/usr/bin/perl -w
use strict;

###############################
### SETUP
###############################
my $makeRaw    = 0;
my $makeNumber = 1;
my $printId    = 1;
my $orZero     = 1;

###############################
### CHECKING
###############################
my %nfo;
my $usage    = "USAGE: $0 <DATA (BLAST) FILE> <INFO (EXPRESSION) FILE>\n";
my $dataFile = $ARGV[0] || die $usage;
my $infoFile = $ARGV[1] || die $usage;

die "DATA FILE $dataFile DOESNT EXISTS" if ( ! -f $dataFile );
die "INFO FILE $infoFile DOESNT EXISTS" if ( ! -f $infoFile );

###############################
### CONFIG
###############################
$nfo{data}{file}       = $dataFile;
$nfo{data}{tableKey}   = "probes";
$nfo{data}{dataKey}    = "query";
$nfo{data}{units}      = "matches";
$nfo{data}{subUnits}   = "match";
$nfo{data}{parser}     = \&parseData;
$nfo{data}{precedence} = 1;
$nfo{data}{groupBy}    = "dbname"; # not necessary

my %dataMergeRules = (
	'consv'			=>	[\&sum, \&avg],
	'gaps'			=>	[\&sum, \&avg],
	'ident'			=>	[\&sum, \&avg],
	'totalSim'		=>	[\&sum, \&avg],
	'maxStretch'	=>	[\&sum, \&avg],
	'sign'			=>	[       \&avg],
	'Hlength'		=>	[\&sum       ],
	'Qrylen'		=>	[            ],
);

my $standardCopyNumber  = "Cryptococcus_neoformans_var_neoformans_JEC21_totalHits";
my $standardQueryNumber = "Cryptococcus_neoformans_var_neoformans_JEC21_Qrylen";
my %dataStatRules = (
	'totalSim$'		=>	[\&prop,      'totalSim_prop',     $standardQueryNumber],
	'totalSim_sum$'	=>	[\&prop,      'totalSim_sum_prop', $standardQueryNumber],
	'Hlength$'		=>	[\&prop,      'Hlength_prop',      $standardQueryNumber],
	'Hlength_sum$'	=>	[\&prop,      'Hlength_sum_prop',  $standardQueryNumber],
	'_totalHits$'	=>	[\&copy2fold, '_totalHits_prop',   $standardCopyNumber],
);
$nfo{data}{mergeRules}  = \%dataMergeRules;
$nfo{data}{statRules}   = \%dataStatRules;






$nfo{info}{file}       = $infoFile;
$nfo{info}{tableKey}   = "probes";
$nfo{info}{dataKey}    = "probe";
$nfo{info}{parser}     = \&parseInfo;
$nfo{info}{precedence} = 0;
my %infoMergeRules = (
	'fold_change$'		=>	[],
	'ratio_err$'		=>	[],
	'pvalue_log_ratio$'	=>	[],
	'normalizedmax$'	=>	[],
	'ttestpvalue$'		=>	[],
);

my $standardFoldChange = "Cryptococcus_neoformans_var_neoformans_JEC21_fold_change";
my %infoStatRules = (
	'fold_change$'		=>	[\&foldSubtraction, 'fold_change_subtracted', $standardFoldChange],
	'fold_change$'		=>	[\&foldZerofy,      'fold_change_aroundzero', $standardFoldChange],
);
$nfo{info}{mergeRules} = \%infoMergeRules;
$nfo{info}{statRules}  = \%infoStatRules;


my @outOneArray;

my %colDeleter = (
	'^JEC21'	=> '',
	'^Cryptococcus_neoformans_var_neoformans_JEC21' => '',
	'totalOrgs'	=> '',
	'Qrylen'	=> '',
);


my %colMerger = (
	'Avg_fold_change$'				=> ['00','Avg_fold_change'],
	'Avg_fold_change_aroundzero$'	=> ['01','Avg_fold_change_aroundzero'],
	'Max_pvalue_log_ratio$'			=> ['02','Max_pvalue_log_ratio'],
	'Max_ratio_err$'				=> ['03','Max_ratio_err'],
	'Hlength_sum$'					=> ['04','Hlength_sum'],
	'Hlength_sum_prop$'				=> ['05','Hlength_sum_prop'],
	'consv_avg$'					=> ['06','consv_avg'],
	'consv_sum$'					=> ['07','consv_sum'],
	'gaps_avg$'						=> ['08','gaps_avg'],
	'gaps_sum$'						=> ['09','gaps_sum'],
	'ident_avg$'					=> ['10','ident_avg'],
	'ident_sum$'					=> ['11','ident_sum'],
	'maxStretch_avg$'				=> ['12','maxStretch_avg'],
	'maxStretch_sum$'				=> ['13','maxStretch_sum'],
	'sign_avg$'						=> ['14','sign_avg'],
	'totalHits$'					=> ['15','totalHits'],
	'totalHits_prop$'				=> ['16','totalHits_prop'],
	'totalSim_avg$'					=> ['17','totalSim_avg'],
	'totalSim_sum$'					=> ['18','totalSim_sum'],
	'totalSim_sum_prop$'			=> ['19','totalSim_sum_prop']
);

my %colGroup =
(
	#'^JEC21' 										  => 0,
	#'^Cryptococcus_neoformans_var_neoformans_JEC21'   => 0,
	'^R265'                                           => 00,
	'^Cryptococcus_gattii_R265'                       => 00,
	'^H99'                                            => 01,
	'^Cryptococcus_neoformans_var_grubii_H99_'        => 01,
	'^B3501'                                          => 02,
	'^Cryptococcus_neoformans_var_neoformans_B-3501A' => 02
);

###############################
### LOAD
###############################
my %data;

foreach my $key (sort keys %nfo)
{
	&getFileInfo($nfo{$key});
}



my $nfoCount   = keys %nfo;
my $countValid = 0;

my @seenKeys;
my @keys;
#$data{$dataId}[$precedence]
foreach my $id (sort keys %data)
{
	my $keysCount = 0;
	my $precArray = $data{$id};
	map { if (defined $_) {$keysCount++} } @{$precArray};
	next if ($keysCount != $nfoCount);


	for (my $p = 0; $p < @$precArray; $p++)
	{
		my $data = $precArray->[$p];
		#print "P $p :: ",(scalar keys %$data)," keys\n";
		foreach my $k (sort { $a cmp $b } keys %$data)
		{
			if ( ! exists ${$seenKeys[$p]}{$k} )
			{
				#print "PRECEDENCE $p = K $k\n";
				push (@{$keys[$p]}, $k);
				$seenKeys[$p]{$k} = 1;
			}
		}
		#@{$keys[$p]} = sort { $a cmp $b } @{$keys[$p]};
	}
}






###############################
### REPORT
###############################
my $nfoFileName = $nfo{info}{file};
$nfoFileName    = substr($nfoFileName, (rindex($nfoFileName,"/")+1));
my $outFile     = $nfo{data}{file}.".EXP." .$nfoFileName;

open OUTCSV,    ">".$outFile.".csv"    or die "COULD NOT OPEN OUTPUT FILE ". $outFile . ".csv : $!";
open OUTCSVONE, ">".$outFile."ONE.csv" or die "COULD NOT OPEN OUTPUT FILE ". $outFile . ".ONE.csv : $!";
open OUTXML,    ">".$outFile.".xml"    or die "COULD NOT OPEN OUTPUT FILE ". $outFile . ".xml : $!";
open OUTLOG,    ">".$outFile.".log"    or die "COULD NOT OPEN OUTPUT FILE ". $outFile . ".log : $!";


my $xmlSource = $nfo{data}{file}               . "|" . $nfo{info}{file};
my $xmlId     = ($nfo{data}{info}{id}   || "") . "|" . ($nfo{info}{info}{id}   || "");
my $xmlType   = ($nfo{data}{info}{type} || "") . "|" . ($nfo{info}{info}{type} || "");
my $xmlDesc   = ($nfo{data}{info}{desc} || "") . "|" . ($nfo{info}{info}{desc} || "");
print OUTXML &getXMLHeader($xmlSource, $xmlId, $xmlType , $xmlDesc);



print OUTCSV "\"ID\"\t" if ($printId);
print OUTLOG "\"ID\"";
for (my $p = 0; $p < @keys; $p++)
{
	for (my $pp = 0; $pp < @{$keys[$p]}; $pp++)
	{
		#%colDeleter;
		#%colMerger;

		my $value   = $keys[$p][$pp];

		foreach my $mer (keys %colMerger)
		{
			if ($value =~ /$mer/)
			{
				my $merNum = $colMerger{$mer}[0];
				my $merNam = $colMerger{$mer}[1];

				#print "ONE NUMBER 0 COLNUM ", $colMerger{$mer}, " MER ", $mer. " VALUE ", $value, "\n";
				foreach my $group (keys %colGroup)
				{
					if ($value =~ /$group/)
					{
						my $groupNum = $colGroup{$group};
						#print "[0] ADDING KEY $value GROUP $group ($groupNum) MERGER $mer ($merNum)  :: ", ($value || 0)," [0, $groupNum, $merNum]\n";
						$outOneArray[0][$groupNum][$merNum] = $merNam;
						last;
					}
				}
				last;
			}
			else
			{
				#print "ONE NUMBER X COLNUM X MER ", $mer. " VALUE ", $value, "\n";
			}
		}

		print OUTLOG  ",\"". $value . "\"";
		if ( ! (($p == 0) && ($pp == 0))) {print OUTCSV "\t"};
		print OUTCSV "\"", $value . "\"";
	}
}
print OUTCSV "\n";
print OUTLOG "\n";


my $oneCount = 1;
foreach my $id (sort keys %data)
{
	my $keysCount = 0;
	map {if ( defined $_ ) { $keysCount++ } } @{$data{$id}};
	next if ($keysCount != $nfoCount);

	$countValid++;
	print OUTLOG "[$countValid] ID :: $id\n";
	my $totalVal  = 0;
	my $precArray = $data{$id};
	my $line;
	$line = "\"".$id."\"\t" if ($printId);
	print OUTXML "\t\t<probe id=\"$id\">\n";
	my %runForId;

	for (my $p = 0; $p < @$precArray; $p++)
	{
		print OUTLOG "\tPREC: $p " , scalar @{$keys[$p]}, "\n";
		my $data = $precArray->[$p];
		my $frag;
		for (my $k = 0; $k < @{$keys[$p]}; $k++)
		{
			my $key = $keys[$p][$k];
			my $v   = $data->{$key};
			print OUTLOG "\t\tKEY $key => ",($v||""),"\n";
			#next if ( $runForId{$key} );

			foreach my $mer (keys %colMerger)
			{
				if ($key =~ /$mer/)
				{
					my $merNum = $colMerger{$mer}[0];
					foreach my $group (keys %colGroup)
					{
						if ($key =~ /$group/)
						{
							my $groupNum = $colGroup{$group};
							#print "[$oneCount] ADDING KEY $key GROUP $group ($groupNum) MERGER $mer ($merNum)  :: ", ($v || 0)," [$oneCount, $groupNum, $merNum]\n";
							$outOneArray[$oneCount][$groupNum][$merNum] = ($v || 0);
							last;
						}
					}
					last;
				}
			}

			$totalVal++;
			if (( defined $v ) && ($v ne "") && ($v ne " "))
			{
				$v =~ s/,/./g;
				#$runForId{$key} = 1;
				print OUTLOG "\t\t\t[$p][$k] $key => \"$v\"\n";
				if ( ! (($p == 0) && ($k == 0)) ) { $frag .= "\t"; };
				$frag .= "\"$v\"";
				print OUTXML "\t\t\t<$key>",($v || "0"),"</$key>\n";
			}
			else
			{
				print OUTLOG "\t\t\t[$p][$k] $key => \"\" (0)\n";
				#$frag .= ",\"\"";
				if ( ! (($p == 0) && ($k == 0))) { $frag .= "\t0"; };
				#$frag .= ",";
			}
			#print OUTXML "\t\t\t<$key>",($v || ""),"</$key>\n";
		}
		$line .= $frag;
	}
	$oneCount++;
	print OUTLOG "\tTOTALVAL :: $totalVal\n";
	print OUTCSV    $line, "\n";
	print OUTXML "\t\t</probe>\n";
	#print OUTLOG $line, "\n";
}
close OUTCSV;
print OUTXML &getXMLTail();
close OUTXML;


#$outOneArray[@outOneArray][$colMerger{$mer}] = $v;
for (my $line = 0; $line < @outOneArray; $line++)
{
	my $group = $outOneArray[$line];
	for (my $g = 0; $g < @$group; $g++)
	{
		my $col = $group->[$g];
		next if ( ! defined $col );
		#print "LINE $line GROUP $g :: ", join("\t", @$col), "\n";
		print OUTCSVONE join("\t", @$col), "\n";
		if ($line == 0) { last; };
	}
}

close OUTCSVONE;

print OUTLOG "$countValid VALID IDS\n";
close OUTLOG;

print "ENDED SUCCESSIFULLY :: OUTPUT: $outFile :: log csv one.csv\n\n";








############################################
### FUNCTIONS
############################################
sub parseData
{
	my $setup       = $_[0];
	my $data        = $_[1];
	my $units       = $setup->{units};
	my $subUnits    = $setup->{subUnits};
	my $mergeRules  = $setup->{mergeRules};
	#print $data;

	#my @lines = split("<$units", $data);
	my @lines = split("\n", $data);
	my %groupBy;

	my $currUnitId    = undef;
	my $currSubUnitId = 0;
	my %units;
	foreach my $line (@lines)
	{

		if (index($line,"</$units") != -1)
		{
			$currUnitId    = undef;
			$currSubUnitId = 0;
		}

		if ($currUnitId)
		{
			if ((index($line,"</$subUnits") != -1) && (defined $currSubUnitId))
			{
				$currSubUnitId = undef;
			}

			if (defined $currSubUnitId)
			{
				$units{$currUnitId}[$currSubUnitId] .= $line . "\n";
			}

			if (index($line,"<$subUnits") != -1)
			{
				$line          =~ /\<$subUnits\s+id\=\"(\d*?)\"/;
				$currSubUnitId = $1;
			}
		}

		if (index($line,"<$units") != -1)
		{
			$line          =~ /\<$units\s+id\=\"(.*?)\"/;
			$currUnitId    = $1;
			$currUnitId    =~ tr/ .,/___/;
			$currSubUnitId = undef;
		}
	}

	foreach my $currUnit (sort keys %units)
	{
		#print OUTLOG "\tUNIT $currUnit\n";
		for (my $s = 0; $s < @{$units{$currUnit}}; $s++)
		{
			my $subUnit = $units{$currUnit}[$s];
			next if (! defined $subUnit);
			#print "\t\tSUBUNIT #$s\n";
			my $hash = &extractKV($subUnit, $mergeRules);

			$groupBy{$currUnit}[$s] = $hash;
		}
	}

	my %keys;
	foreach my $currUnit (sort keys %groupBy)
	{
		#print "CURRUNIT $currUnit\n";
		my $unit = $groupBy{$currUnit};
		for (my $u = 0; $u < @{$unit}; $u++)
		{
			#print "\tU $u\n";
			my $subUnit = $unit->[$u];
			foreach my $key (keys %{$subUnit})
			{
				#print "\t\tKEY $key\n";
				if ( exists ${$mergeRules}{$key})
				{
					$keys{$key} = "";
				}
				#die if ( ! exists ${$mergeRules}{$key});
			}
		}
	}

	my %result;
	$result{"totalOrgs"}     = scalar (keys %groupBy);
	$result{"totalOrgs_RAW"} = join(";", (keys %groupBy)) if ($makeRaw);
	foreach my $currUnit (sort keys %groupBy)
	{
		my $subUnits = $groupBy{$currUnit};
		$result{$currUnit."_totalHits"} = scalar @{$subUnits};
		#print "UNIT $currUnit\n";
		foreach my $key (sort keys %keys)
		{
			#print "\tKEY $key\n";
			my @input;
			for (my $u = 0; $u < @$subUnits; $u++)
			{
				next if ( ! defined $subUnits->[$u] );
				my $v    = $subUnits->[$u]{$key};
				next if ( ! defined $v );

				#print "\t\tU $u => $v\n";

				push(@input, $v);
			}

			if ( @{$mergeRules->{$key}} )
			{
				$result{$currUnit."_".$key."_RAW"} = join(";",@input) if ($makeRaw);
				foreach my $function (@{$mergeRules->{$key}})
				{
					my ($result, $name) = $function->(\@input);
					$result{$currUnit."_".$key."_".$name} = $result;
					#print "\t\tKEY $key FUNCTION \"$name\" RESULT = $result\n";
				}
			}
			else
			{
				my %seen;
				map { $seen{$_} = 1 } @input;
				$result{$currUnit."_".$key}        = $input[0];
				$result{$currUnit."_".$key."_RAW"} = join(";",(sort keys %seen)) if ($makeRaw);
				#print "\t\tKEY $key FUNCTION \"none\" RESULT = ", $input[0], "\n";
			}
		}
	}
	return \%result;
}


sub parseInfo
{
	my $setup = $_[0];
	my $data  = $_[1];
	my $mergeRules  = $setup->{mergeRules}  || die "NO MERGERULES DEFINED";
	my $statRules   = $setup->{statRules}   || die "NO STATRULES DEFINED";
	#print $data;
	my $hash = &extractKV($data, $mergeRules);

	return $hash;
}

sub extractKV
{
	my $string = $_[0];
	my $cols   = $_[1];

	my @lines  = split("\n", $string);
	my %hash;
	for (my $l = 0; $l < @lines; $l++)
	{
		my $line = $lines[$l];
		if ($line =~ /<(.*?)>(.*)<\/\1>/)
		{
			my $k    = $1;
			my $v    = $2;
			my $next = 1;

			if ($cols)
			{
				foreach my $col (keys %{$cols})
				{
					#print "CHECKING COL $col\n";
					if ($k =~ /$col/) { $next = 0 }; #print "IN LIST $k.\n"; };
				}
			}

			if ( $next )
			{
				#print "NOT IN LIST $k.\n";
				next;
			}
			$hash{$k} = $v;
		}
	}

	return \%hash;
}

sub getFileInfo
{
	my $hash       = $_[0];
	my $in         = $hash->{file}        || die "NO IN FILE DEFINED";
	my $tableKey   = $hash->{tableKey}    || die "NO TABLE KEY DEFINED";
	my $dataKey    = $hash->{dataKey}     || die "NO DATA KEY DEFINED";
	my $parser     = $hash->{parser}      || die "NO PARSER DEFINED";
	my $statRules  = $hash->{statRules}   || die "NO STAT RULES DEFINED";

	my $precedence = $hash->{precedence};
	die "NO PRECEDENCE DEFINED" if ( ! defined $precedence );

	#print OUTLOG "PARAMETERS:\n";
	#foreach my $key (sort keys %$hash)
	#{
		#print OUTLOG "\t$key\t=>\t", $hash->{$key}, "\n";
	#}

	die "NO FILE GIVEN"                if ( !    $in );
	die "INPUT FILE $in DOESNT EXISTS" if ( ! -f $in );

	#print OUTLOG "GETTING INFO :: $in\n";
	my $table     = 0;
	my $tableId   = "";
	my $data      = 0;
	my $dataId    = "";
	my $accData   = "";
	my $countData = 0;
	open IN, "<$in" or die "COULD NOT OPEN INPUT DATA FILE $in: $!";
	while (my $line = <IN>)
	{
		chomp $line;

		if ($table && (index($line, "</$tableKey>") != -1))
		{
			#print "\tFOUND END OF TABLE $tableKey :: ID $tableId : $line\n";
			$table = 0;
		}

		if ($table)
		{
			if (index($line, "</$dataKey>") != -1)
			{
				$data{$dataId}[$precedence] = $parser->($hash, $accData);
				#print "\t\tFOUND END OF DATA $dataKey :: ID: $dataId\n";
				$countData++;
				$data    = 0;
				$dataId  = "";
				$accData = "";
			}

			if ($data)
			{
				$accData .= $line . "\n";
			}

			if (index($line, "<$dataKey ") != -1)
			{
				if ($line   =~ /id=\"(.*?)\"/) { $dataId = $1; }
				else { die "NO DATA ID IN :: \"$line\""; }
				#print "\t\tFOUND DATA $dataKey :: ID: $dataId : $line\n";
				$data   = 1;
			}
		}




		if (index($line, "<$tableKey ") != -1)
		{
			if ($line    =~ /id=\"(.*?)\"/) { $tableId = $1; $hash->{info}{id}   = $1;}
			else { die "NO TABLE ID :: \"$line\"" }

			if ($line =~ /type=\"(.*?)\"/) { $hash->{info}{type} = $1; };
			if ($line =~ /desc=\"(.*?)\"/) { $hash->{info}{desc} = $1; };

			$table    = 1;
			#print "\tFOUND TABLE $tableKey :: ID $tableId : $line\n";
		}
	}
	close IN;
	#print OUTLOG "FINISHED GETTING DATA :: $in : TOTAL $countData\n";






	foreach my $id (keys %data)
	{
		my $hash = $data{$id}[$precedence];
		foreach my $key (keys %$hash)
		{
			my $value = $hash->{$key};
			#print "\tID $id KEY $key VALUE $value\n";


			#my %dataStatRules = (
			#	'totalSim'		=>	[\&prop,      'totalSim_prop',   'Qrylen'],
			#	'Hlength'		=>	[\&prop,      'Hlength_prop',    'Qrylen'],
			#	'_totalHits$'	=>	[\&copy2fold, '_totalHits_prop', $standardCopyNumber],
			#);

			foreach my $rule (keys %$statRules)
			{
				if ($key =~ /(.*)$rule(.*)/)
				{
					my $prefix        = $1;
					my $sufix         = $2;
					my $function      = $statRules->{$rule}[0];
					my $outputName    = $statRules->{$rule}[1];
					my $statColumn    = $statRules->{$rule}[2];
					my $firstValue    = $hash->{$key};
					my $secondValue   = $hash->{$statColumn};
					my $newName       = $key;
					   $newName       =~ s/$rule/$outputName/;
					my $fResult       = $function->($firstValue, $secondValue);
					$hash->{$newName} = $fResult;

					#print "\tID $id KEY $key VALUE $value\n";
					#print "\t\tPREFIX $prefix RULE $rule SUFIX $sufix OUTPUT $outputName COLUMN $statColumn\n";
					#print "\t\tFIRST VALUE $firstValue SECOND VALUE $secondValue NEW NAME $newName\n";
					#print "\t\tRESULT $fResult\n\n";
				}
			}
		}
	}

	#my %infoStatRules = (
	#'fold_change$'		=>	[\&foldSubtraction, 'fold_change_subtracted', $standardFoldChange],
	#'fold_change$'		=>	[\&foldZerofy,      'fold_change_aroundzero', $standardFoldChange],
	#);
}



########################################
### DATA SUBFUNCTIONS
########################################
sub prop
{
	my $toDivide = $_[0];
	my $base     = $_[1];
	if ( ( ! $toDivide) || ( $toDivide == 0 )) { return  111 }; #print "\t\tPROP :: TO DIVIDE undef BASE $base\n";
	if ( ( ! $base    ) || ( $base     == 0 )) { return -111 }; #print "\t\tPROP :: TO DIVIDE $toDivide BASE undef\n";

	#print "\t\tPROP :: TO DIVIDE $toDivide BASE $base\n";

	return ((int((($toDivide / $base)*100)+.5))/100) || -1;
}

sub copy2fold
{
	my $new  = $_[0];
	my $base = $_[1];

	# BASE NEW  (NEW / BASE)	=> LOG(;2)    =        => +-1
	# 2		2 = (2 / 2) = 1		=> LOG(1.0;2) =  0.00  =>  1.00
	# 2		3 = (3 / 2) = 1.5	=> LOG(1.5;2) =  0.58  =>  1.58
	# 3		2 = (2 / 3) = 0.6	=> LOG(0.6;2) = -0.58  => -1.58
	# 2		4 = (4 / 2) = 2	    => LOG(2.0;2) =  1.00  => +2.0
	# 4		2 = (2 / 4) = 0.5	=> LOG(0.5;2) = -1.00  => -2.0
	# 0		2 = (2 / 0) = X		=> LOG(;2)    = +111   => +111
	# 2		0 = (0 / 2) = X		=> LOG(;2)    = -111   => -111
		#ID 184.m04912 KEY Cryptococcus_gattii_R265_totalHits VALUE 3
		#COPY2FOLD :: NEW 3 BASE 2
		#PREFIX Cryptococcus_gattii_R265 RULE _totalHits$ SUFIX  OUTPUT _totalHits_prop COLUMN Cryptococcus_neoformans_var_neoformans_JEC21_totalHits
		#FIRST VALUE 3 SECOND VALUE 2 NEW NAME Cryptococcus_gattii_R265_totalHits_prop
		#RESULT 1.58496250072116

	if ($new && $base)
	{
		#print "\t\tCOPY2FOLD :: NEW $new BASE $base\n";
		my $result1 = $new / $base;
		my $result2 = log($result1)/log(2);

		if ($result2 >= 0 )
		{
			return int((($result2 + 1)*100)+.5)/100;
		} else {
			return int((($result2 - 1)*100)+.5)/100;
		}

	} else {
		if ( (! $new ) && ( ! $base) )
		{
			die "WTH? NEW AND BASE ARE BOTH ZERO? NO DATA AT ALL? REALLY?";
		}
		elsif ( ! $new )
		{
			#print "\t\tCOPY2FOLD :: NEW undef BASE $base\n";
			return "-111";
		}
		elsif ( ! $base )
		{
			#print "\t\tCOPY2FOLD :: NEW $new BASE undef\n";
			return "+111";
		}
	}
}

sub foldSubtraction
{
	my $base   = $_[0];
	my $toSub  = $_[1];
	my $result = 0;

	if ( $base >= 0 )
	{
		if ( $toSub >= 0)
		{
			#+1 +2
			#+2 +1
			$result = $toSub - $base;
		} else {
			#+1 -2
			$result = (($toSub*-1) + $base) * -1;
		}
	}
	else
	{
		if ( $toSub >= 0)
		{
			#-1 +2
			$result = $toSub + ($base * -1);
		} else {
			#-1 -2
			#-2 -1
			$result = $base - $toSub;
		}
	}

	return $result;
}

sub foldZerofy
{
	my $fold1 = $_[0];
	my $fold2 = $_[0];

	if ($fold1 != $fold2)
	{
		die "WTH. FOLDS SHOULD BE THE SAME AND YOU KNOW IT."
	} else {
		if ($fold1 >= 0)
		{
			return int((($fold1 - 1)*100)-.5)/100;
		} else {
			return int((($fold1 + 1)*100)+.5)/100;
		}
	}
}

sub sum
{
	my $array = $_[0];
	my $name  = "sum";
	my $sum;

	map {$sum += $_} @$array;

	return ($sum, $name);
}


sub avg
{
	my $array = $_[0];
	my $name  = "avg";
	my $count = @$array;
	my $sum;
	my $avg;

	if ($count > 1)
	{
		map {$sum += $_} @$array;
		$avg = $sum / $count;
		return ($avg, $name);
	}
	else
	{
		return ($array->[0], $name);
	}
}


sub median
{
	my $array = $_[0];
	my $name  = "median";
	my $count = @$array;
	my $median;
	@$array = sort{ $a <=> $b } @$array;

	if ($count > 1)
	{
		$median = ($count % 2)	?	$array->[int($count/2)]
								:	($array->[int($count/2)] + $array->[int($count/2) - 1]) / 2
								;

		return ($median, $name);
	}
	else
	{
		return ($array->[0], $name);
	}
}


sub stdDev
{
	my $array   = $_[0];
	my $name    = "stddev";
	my $count   = @$array;
	my $total   = 0;
	my $sqTotal = 0;

	if ($count > 1)
	{
		foreach my $v (@$array)
		{
			$total += $v;
		}

		my $average = $total/$count;

		foreach my $v (@$array)
		{
			$sqTotal += ($average - $v) **2;
		}

		my $std = ($sqTotal / $count) ** 0.5;

		return ($std, $name);
	} else {
		return (0, $name);
	}
}


















#################################
### XML EXPORT
#################################

sub getXMLHeader
{
	my $source = $_[0];
	my $id     = $_[1];
	my $type   = $_[2];
	my $desc   = $_[3];

	#<?xml-stylesheet type="text/xml" href="#stylesheet"?>
	#<!DOCTYPE doc [
	#<!ATTLIST xsl:stylesheet id ID #REQUIRED>
	#]>
	my $HEADER =
'<?xml version="1.0" encoding="ISO-8859-1"?>
<data>
<!-- 	PROBES DATA 	-->
'.
"\t<probes id=\"$source\" type=\"$type\" desc=\"$desc\">\n";

	return $HEADER;
}




sub getXMLTail
{
	my $TAIL = "\t</probes>\n" .
'
</data>

';
	return $TAIL;
}



1;


#CNA BAD
#ID
#AMC7706160FL08fl0gs
#AMC770616AFLP8normalized
#B35010FL12fl0gs
#B3501AFLP2normalized
#CBS1321FL13fl1gs
#CBS132AFLP3normalized
#CBS60930FL0Outgrou0fl0gs
#CBS6093AFLPOutgroupnormalized
#CBS69550FL05fl0gs
#CBS6955AFLP5normalized
#CDCR2650FL16fl0gs
#CDCR265AFLP6normalized
#chrom
#class
#codeCN
#codeGI
#codeNum
#codeXM
#codeXMFull
#Cryptococcus_gattii_R265_dbname
#Cryptococcus_gattii_R265_Qrylen
#Cryptococcus_neoformans_var_grubii_H99_dbname
#Cryptococcus_neoformans_var_grubii_H99_Qrylen
#Cryptococcus_neoformans_var_neoformans_B-3501A_dbname
#Cryptococcus_neoformans_var_neoformans_B-3501A_Qrylen
#Cryptococcus_neoformans_var_neoformans_JEC21_dbname
#Cryptococcus_neoformans_var_neoformans_JEC21_Qrylen
#E5660FL14fl0gs
#E566AFLP4normalized
#geneId
#geneType
#genome_annott.codeM
#go_comp
#go_func
#go_supp
#H991FL11fl1gs
#H99AFLP1normalized
#JEC210FL12fl0gs
#JEC21AFLP2normalized
#origing
#pos
#probeSeq
#RV581461FL11Bfl1gs
#RV58146AFLP1Bnormalized
#RV646101FL111fl1gs
#RV64610AFLP1Anormalized
#W07791FL17fl1gs
#WM779AFLP7normalized

#CNA GOOD
#AMC770616AFLP8max
#AMC770616AFLP8mean
#AMC770616AFLP8min
#AMC770616AFLP8ttestpvalue
#B3501AFLP2max
#B3501AFLP2mean
#B3501AFLP2min
#B3501AFLP2ttestpvalue
#CBS132AFLP3max
#CBS132AFLP3mean
#CBS132AFLP3min
#CBS132AFLP3ttestpvalue
#CBS6093AFLPOutgroupmax
#CBS6093AFLPOutgroupmean
#CBS6093AFLPOutgroupmin
#CBS6093AFLPOutgroupttestpvalue
#CBS6955AFLP5max
#CBS6955AFLP5mean
#CBS6955AFLP5min
#CBS6955AFLP5ttestpvalue
#CDCR265AFLP6max
#CDCR265AFLP6mean
#CDCR265AFLP6min
#CDCR265AFLP6ttestpvalue
#Cryptococcus_gattii_R265_consv_avg
#Cryptococcus_gattii_R265_consv_median
#Cryptococcus_gattii_R265_consv_stddev
#Cryptococcus_gattii_R265_consv_sum
#Cryptococcus_gattii_R265_gaps_avg
#Cryptococcus_gattii_R265_gaps_median
#Cryptococcus_gattii_R265_gaps_stddev
#Cryptococcus_gattii_R265_gaps_sum
#Cryptococcus_gattii_R265_ident_avg
#Cryptococcus_gattii_R265_ident_median
#Cryptococcus_gattii_R265_ident_stddev
#Cryptococcus_gattii_R265_ident_sum
#Cryptococcus_gattii_R265_maxStretch_avg
#Cryptococcus_gattii_R265_maxStretch_median
#Cryptococcus_gattii_R265_maxStretch_stddev
#Cryptococcus_gattii_R265_maxStretch_sum
#Cryptococcus_gattii_R265_sign_avg
#Cryptococcus_gattii_R265_sign_median
#Cryptococcus_gattii_R265_sign_stddev
#Cryptococcus_gattii_R265_totalHits
#Cryptococcus_gattii_R265_totalSim_avg
#Cryptococcus_gattii_R265_totalSim_median
#Cryptococcus_gattii_R265_totalSim_stddev
#Cryptococcus_gattii_R265_totalSim_sum
#Cryptococcus_neoformans_var_grubii_H99_consv_avg
#Cryptococcus_neoformans_var_grubii_H99_consv_median
#Cryptococcus_neoformans_var_grubii_H99_consv_stddev
#Cryptococcus_neoformans_var_grubii_H99_consv_sum
#Cryptococcus_neoformans_var_grubii_H99_gaps_avg
#Cryptococcus_neoformans_var_grubii_H99_gaps_median
#Cryptococcus_neoformans_var_grubii_H99_gaps_stddev
#Cryptococcus_neoformans_var_grubii_H99_gaps_sum
#Cryptococcus_neoformans_var_grubii_H99_ident_avg
#Cryptococcus_neoformans_var_grubii_H99_ident_median
#Cryptococcus_neoformans_var_grubii_H99_ident_stddev
#Cryptococcus_neoformans_var_grubii_H99_ident_sum
#Cryptococcus_neoformans_var_grubii_H99_maxStretch_avg
#Cryptococcus_neoformans_var_grubii_H99_maxStretch_median
#Cryptococcus_neoformans_var_grubii_H99_maxStretch_stddev
#Cryptococcus_neoformans_var_grubii_H99_maxStretch_sum
#Cryptococcus_neoformans_var_grubii_H99_sign_avg
#Cryptococcus_neoformans_var_grubii_H99_sign_median
#Cryptococcus_neoformans_var_grubii_H99_sign_stddev
#Cryptococcus_neoformans_var_grubii_H99_totalHits
#Cryptococcus_neoformans_var_grubii_H99_totalSim_avg
#Cryptococcus_neoformans_var_grubii_H99_totalSim_median
#Cryptococcus_neoformans_var_grubii_H99_totalSim_stddev
#Cryptococcus_neoformans_var_grubii_H99_totalSim_sum
#Cryptococcus_neoformans_var_neoformans_B-3501A_consv_avg
#Cryptococcus_neoformans_var_neoformans_B-3501A_consv_median
#Cryptococcus_neoformans_var_neoformans_B-3501A_consv_stddev
#Cryptococcus_neoformans_var_neoformans_B-3501A_consv_sum
#Cryptococcus_neoformans_var_neoformans_B-3501A_gaps_avg
#Cryptococcus_neoformans_var_neoformans_B-3501A_gaps_median
#Cryptococcus_neoformans_var_neoformans_B-3501A_gaps_stddev
#Cryptococcus_neoformans_var_neoformans_B-3501A_gaps_sum
#Cryptococcus_neoformans_var_neoformans_B-3501A_ident_avg
#Cryptococcus_neoformans_var_neoformans_B-3501A_ident_median
#Cryptococcus_neoformans_var_neoformans_B-3501A_ident_stddev
#Cryptococcus_neoformans_var_neoformans_B-3501A_ident_sum
#Cryptococcus_neoformans_var_neoformans_B-3501A_maxStretch_avg
#Cryptococcus_neoformans_var_neoformans_B-3501A_maxStretch_median
#Cryptococcus_neoformans_var_neoformans_B-3501A_maxStretch_stddev
#Cryptococcus_neoformans_var_neoformans_B-3501A_maxStretch_sum
#Cryptococcus_neoformans_var_neoformans_B-3501A_sign_avg
#Cryptococcus_neoformans_var_neoformans_B-3501A_sign_median
#Cryptococcus_neoformans_var_neoformans_B-3501A_sign_stddev
#Cryptococcus_neoformans_var_neoformans_B-3501A_totalHits
#Cryptococcus_neoformans_var_neoformans_B-3501A_totalSim_avg
#Cryptococcus_neoformans_var_neoformans_B-3501A_totalSim_median
#Cryptococcus_neoformans_var_neoformans_B-3501A_totalSim_stddev
#Cryptococcus_neoformans_var_neoformans_B-3501A_totalSim_sum
#Cryptococcus_neoformans_var_neoformans_JEC21_consv_avg
#Cryptococcus_neoformans_var_neoformans_JEC21_consv_median
#Cryptococcus_neoformans_var_neoformans_JEC21_consv_stddev
#Cryptococcus_neoformans_var_neoformans_JEC21_consv_sum
#Cryptococcus_neoformans_var_neoformans_JEC21_gaps_avg
#Cryptococcus_neoformans_var_neoformans_JEC21_gaps_median
#Cryptococcus_neoformans_var_neoformans_JEC21_gaps_stddev
#Cryptococcus_neoformans_var_neoformans_JEC21_gaps_sum
#Cryptococcus_neoformans_var_neoformans_JEC21_ident_avg
#Cryptococcus_neoformans_var_neoformans_JEC21_ident_median
#Cryptococcus_neoformans_var_neoformans_JEC21_ident_stddev
#Cryptococcus_neoformans_var_neoformans_JEC21_ident_sum
#Cryptococcus_neoformans_var_neoformans_JEC21_maxStretch_avg
#Cryptococcus_neoformans_var_neoformans_JEC21_maxStretch_median
#Cryptococcus_neoformans_var_neoformans_JEC21_maxStretch_stddev
#Cryptococcus_neoformans_var_neoformans_JEC21_maxStretch_sum
#Cryptococcus_neoformans_var_neoformans_JEC21_sign_avg
#Cryptococcus_neoformans_var_neoformans_JEC21_sign_median
#Cryptococcus_neoformans_var_neoformans_JEC21_sign_stddev
#Cryptococcus_neoformans_var_neoformans_JEC21_totalHits
#Cryptococcus_neoformans_var_neoformans_JEC21_totalSim_avg
#Cryptococcus_neoformans_var_neoformans_JEC21_totalSim_median
#Cryptococcus_neoformans_var_neoformans_JEC21_totalSim_stddev
#Cryptococcus_neoformans_var_neoformans_JEC21_totalSim_sum
#E566AFLP4max
#E566AFLP4mean
#E566AFLP4min
#E566AFLP4ttestpvalue
#H99AFLP1normalizedmax
#H99AFLP1normalizedmean
#H99AFLP1normalizedmin
#H99AFLP1ttestpvalue
#JEC21AFLP2max
#JEC21AFLP2mean
#JEC21AFLP2min
#JEC21AFLP2ttestpvalue
#RV58146AFLP1Bmax
#RV58146AFLP1Bmean
#RV58146AFLP1Bmin
#RV58146AFLP1Bttestpvalue
#RV64610AFLP1Amax
#RV64610AFLP1Amean
#RV64610AFLP1Amin
#RV64610AFLP1Attestpvalue
#totalOrgs
#WM779AFLP7max
#WM779AFLP7mean
#WM779AFLP7min
#WM779AFLP7ttestpvalue
