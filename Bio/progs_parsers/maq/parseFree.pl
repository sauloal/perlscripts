#!/usr/bin/perl -w
use strict;
use warnings;
use FindBin qw($Bin);

my $printParser    = 0;
my $mkorigbkp      = 1;
my $mkbkp          = 1;
my $progressbar    = 1;
my $originalFolder = "/home/saulo/Desktop/Genome/results/seqs";
my @original       = ("s_4_sequence.txt", "s_8_sequence.txt");
my $mapview        = "all.mapview.asc";
my $PREFIX         = "HWI\-EA332_305ANAAXX_";

$mapview           = "$Bin/$mapview";


if ( ! -f "$mapview" ) { die "\tERROR: MAPVIEW FILE $mapview NOT FOUND $!\n"; };

my %database;
my %chromossome;

&loadMapView;
if ($mkorigbkp) { &loadOriginal; &loadResume; } else { &loadResume; };





sub loadOriginal
{
	print "LOADING ORGINAL\n";
	open RESUMEUSED,   ">$Bin/resumeUSED"   || die "\tERROR: COULD NOT OPEN RESUMEUSED: $!\n";
	open RESUMEUNUSED, ">$Bin/resumeUNUSED" || die "\tERROR: COULD NOT OPEN RESUMEUNUSED: $!\n";
	open RESUMEALL,    ">$Bin/resumeALL"    || die "\tERROR: COULD NOT OPEN RESUMEALL: $!\n";

	my $used; my $notused; my $count;
	my $datain = (keys %database);
	foreach my $original (@original)
	{
		print "LOADING ORIGINAL FILE $original\n";
		my $filename = "$originalFolder/$original";
		if ( ! -f "$filename" ) { die "\tERROR: ORIGNAL FILE $originalFolder/$original NOT FOUND $!\n"; };
		open ORIGINAL, "<$filename" || die "\tERROR: COULD NOT OPEN ORIGINAL FILE: $!\n";
		my $total = `cat $filename | wc -l`; chomp $total;
		my $lcount = 0; my $lused = 0; my $lnotused = 0;
		while (my $line = <ORIGINAL>)
		{
			&progressBar($total,$lcount);
			# HWI-EA332_305ANAAXX:4:4:676:109:ATTGGTCGTCTTATTCCCATTTCAACTACTCCGGTT:bbb`^bb`^b^bT^^Ibb`b`bb^^^^^^bZZC```
			# HWI-EA332_305ANAAXX:4:4:733:1073:ACGGCGTCGCGTCCCCACCCAGCTTGGTAAGTTGGA:bb`bbb`b^b^ZbGC`Qbb`W^bQ`W^Z`^````ZM
			# HWI-EA332_305ANAAXX:4:4:563:79:TTTCTGATAAGTTGCTTGATTTGGTTGGACTTGGTG:bbbbbb`bZ`^bbZb`bZ`bbb^KbbZWWZ``CZ`C
			# HWI-EA332_305ANAAXX:4:4:355:138:GCTTTTTTATGGTTCGTTCTTATTACCCTTCTTAAT:`b``````^`TT```T``T``T``^P^T``T`MAL^
			# HWI-EA332_305ANAAXX:4:4:1333:1412:GATCCCCTCGCTTTCCTGCTCCCCTTCAGTTTATTT:^^^T```]`T`LCE``HL`]``GH^]LXH^^^Y]^F
			# HWI-EA332_305ANAAXX:4:4:1211:949:TTCTGTCTTTTCGTCTGCAGGGCGTTGAGTTCGATA:```^]]`^[]N`XK[MH`H^XX`L^^XX]^^]GY^T
			my @parts = split(":",$line);

			my $read = join("_",@parts[0..4]);
			$read =~ /($PREFIX)/;
			$read = $';
			if ( exists $database{$read} )
			{
# 				print "$read \n";
				print RESUMEUSED $line;
				print RESUMEALL "+$line";
				$database{$read}{"checked"}++;
				$database{$read}{"valid"} = 1;
				$used++;
				$lused++;
			}
			else
			{
#				print "NOT USED $read\n";
				print RESUMEUNUSED $line;
				print RESUMEALL "-$line";
				if ( $database{$read}{"checked"} ) { $database{$read}{"checked"}++; } else { $database{$read}{"checked"} = 1; };
				$database{$read}{"valid"} = 0;
				$notused++;
				$lnotused++;
			}
			$lcount++;
			$count++;
		}
		close ORIGINAL;
		print "ORIGINAL FILE $original LOADED\n";
		my $lperused    = int(($lused/$lcount)*100);
		my $lpernotused = int(($lnotused/$lcount)*100);
		print "\tORIGINAL FILE $original HAS\n\t\t$lused ($lperused%) READS USED\n\t\t$lnotused ($lpernotused%) READS NOT USED\n\t\t$lcount READS IN TOTAL\n";
	}
	close RESUMEUSED;
	close RESUMEUNUSED;
	close RESUMEALL;
	print "ORIGINAL LOADED\n";
	my $dataout   = (keys %database);
	my $total     = $used+$notused;
	my $perused   = int(($used/$total)*100);
	my $perunused = int(($notused/$total)*100);
	print "\tORIGINAL FILES HAVE\n\t\t$used ($perused%) READS USED\n\t\t$notused ($perunused%) READS NOT USED\n\t\t$total ($count) READS IN TOTAL\n";
	print "\tDATA IN $datain, DATA OUT $dataout\n";
}

sub loadResume
{
	print "LOADING RESUME\n";
	open RESUMEZERO,  ">$Bin/resumeZERO"  || die "\tERROR: COULD NOT OPEN RESUMEZERO: $!\n";
	open RESUMEMONCE, ">$Bin/resumeMONCE" || die "\tERROR: COULD NOT OPEN RESUMEMONCE: $!\n";
	open RESUMEOK,    ">$Bin/resumeOK"    || die "\tERROR: COULD NOT OPEN RESUMEOK: $!\n";

	my $total = (keys %database);
	my $countTotal = 0;
	my $countZero  = 0;
	my $countMonce = 0;
	my $countOk    = 0;

	foreach my $read (keys %database)
	{
		&progressBar($total,$countTotal++);
		my $valid = $database{$read}{"valid"};
		if ( $database{$read}{"checked"} == 0 )
		{
			print "\tINCONSISTENCY ON READ $read ($valid). NEVER CHECKED\n";
			print RESUMEZERO "$read ($valid)\n";
			$countZero++;
		}
		elsif ( $database{$read}{"checked"} == 1)
		{
# 			print "\tREAD $read ($valid) OK\t";
			print RESUMEOK "$read ($valid)\n";
			$countOk++;
		}
		elsif ( $database{$read}{"checked"} > 1)
		{
			my $times = $database{$read}{"checked"};
			print "\tINCONSISTENCY ON READ $read ($valid). CHECKED MORE THAN ONCE: $times TIMES\n";
			print RESUMEMONCE "$read ($valid) $times\n";
			$countMonce++;
		}
		else
		{
			die "LOGIC ERROR ON LOADING RESUME\n";
		}
	}

	close RESUMEZERO;
	close RESUMEMONCE;
	close RESUMEOK;

	print "RESUME LOADED\n";
	print "\tRESUME HAS\n\t\t$countZero READS NEVER CHECKED\n\t\t$countMonce READS CHECKED MORE THAN ONCE\n\t\t$countOk READS OK\n";
}



sub loadMapView
{
	print "LOADING MAPVIEW\n";
	open VIEW, "<$mapview" || die "\tERROR: COULD NOT OPEN MAPVIEW FILE: $!\n";
	my $total = `cat $mapview | wc -l`; chomp $total;
	my $count = 0;
# 	if ($mkbkp) { open PILEBKP, ">$mapview\_short" || die "\tERROR: COULD NOT OPEN $mapview\_short FOR BAKUP: $!\n"; };

	while (my $line = <VIEW>)
	{
		&progressBar($total,$count);
# 		print $line;
#HWI-EA332_305ANAAXX_8_68_724_961       supercontig_1.01_of_Cryptococcus_neoformans_Serotype_B  2       -       0       0       99      99      99	260      1       0       36      tTtTCATTtTTGTTGCGATTTCACTTGCAAAAATGT    :<7???CC7C??CCAA?CCCC>CACCC>CCCCCACC
#HWI-EA332_305ANAAXX_8_24_590_1139      supercontig_1.01_of_Cryptococcus_neoformans_Serotype_B  2       -       0       0       99      99      99	260      1       0       36      TTTTCATTTTTGTTGCGATTTCACTTGCAAAAATGT    <?????CCCCCCCCCCCCCCC>C?CCCCCCCCCCCC
# 			1					2				3	4	5	6	7	8	9	10	11	12	13			14					15
		if ($line =~ /(\S+)\s(\S+)\s(\d+)\s(\S+)\s(\d+)\s(\d+)\s(\d+)\s(\d+)\s(\d+)\s(\d+)\s(\d+)\s(\d+)\s(\d+)\s(\w+)\s(\S+)\s/)
		{
#				1      2      3      4      5      6      7      8      9      10     11     12     13     14     15
			my $read	 = $1;
			my $chromossome  = $2;
			my $position     = $3;
			my $strand       = $4;
			my $ins_size     = $5; #insert size from outer coordinate pair
			my $paired_flag  = $6; 
			my $map_qual     = $7;
			my $se_map_qual  = $8; # single end mapping quality
			my $alt_map_qual = $9; #alternative mapping quality
			my $misbest      = $10; #number of mismatchs of best hit
			my $summisbest   = $11; # sum of qualities of mismatched bases of the best hit
			my $numzero      = $12; # number of zero mismatch hists of the first 24 bases
# 			my $numone       = $13; # number of 1 mismatch hists of the first 24 bases on the reference
			my $length       = $13; #length of the read
			my $read_seq     = $14;
			my $read_qual    = $15;

# 			if ($mkbkp) { print PILEBKP $line; };

# 			print $line;
			$read =~ /($PREFIX)/;
			$read = $';
# 			print $read;
# 			$database{$read}{"line"}     = $line;
# 			$database{$read}{"chr"}      = $chromossome;
# 			$database{$read}{"pos"}      = $position;
			$database{$read}{"cheked"}   = 0;
# 			$database{$read}{"read_seq"} = $read_seq;

			if ($printParser)
			{
				print "\n\n\n";
			}
			$count++
		}
		else
		{
			die "\tERROR: FAILED PARSING MAP VIEW FILE\n$line\n\n";
		}
	}
# 	if ($mkbkp) { close PILEBKP; };
	close VIEW;
	print "MAPVIEW LOADED\n";
	print "\tMAPVIEW HAS $count LINES\n";
}


sub progressBar
{
	if ($progressbar)
	{
		my $total   = $_[0];
		my $current = $_[1];
		my $tenth   = int(($total/10)-0.5);
		my $timex   = (($current-1) % $tenth);
	
	# 	print "$total $current $tenth $timex\n";
	
		if ( ! $timex )
		{
			my $times = ($current-1) / $tenth;
			print STDERR "\t" . sprintf("%03d",($times*10)) . "% 0% " . "#"x$times . " "x(10-$times) . " 100% ( $total / $current )\n";
		}
	}
}