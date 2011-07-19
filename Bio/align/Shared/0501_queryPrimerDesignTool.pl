#!/usr/bin/perl -w
use strict;
use WWW::Curl::Simple;
use FindBin qw($Bin);
use lib "$Bin";
use fasta;
#use HTML::FormatText::WithLinks::AndTables;
#use HTML::FormatText::WithLinks;
#use HTML::FormatText;
#use HTML::TreeBuilder;
my $primer_mean_size  = 800;
my $primer_clearance  = 200;

my $maxTries     = 1000;
my $sleepTime    = 40; # in seconds
my $minNSize     = 10;
my $goAroundN    = 1;
my $verbose      = 0;
my $post         = 1;
my $cleanHTML    = 1;
my $shortName    = 1;
my $addTimeStamp = 0;
my $stampEnd     = 0;


my %setup;
my %headers;
my $timestamp;

if ( ! @ARGV )
{
	print"
USAGE: FASTA <input fasta> [<outputFolder>]
       LINE <seq name> <nucleotide sequence>
	   CHECK <JOB ID>\n\n";
	   exit 1;
}

my $CMD = shift @ARGV;
die "NO COMMAND GIVEN" if ! defined $CMD;
die "NO DATA GIVEN"    if @ARGV < 1;

if ( $CMD eq 'FASTA' )
{
	my $input = $ARGV[0];
	my $output = defined $ARGV[1] ? $ARGV[1] : './';

	if ( ! defined $input    ) { print "NO INPUT FILE GIVEN";                exit 1; };
	if ( $input !~ "\.fasta" ) { print "INPUT NOT A FASTA FILE";             exit 1; };
	if ( ! -f $input         ) { print "INPUT '$input' FILE DOESNT EXISTS";  exit 1; };
	if ( ! -d $output        ) { print "OUTPUT '$output' DIR DOESNT EXISTS"; exit 1;};

	print "  GENERATING CHROMOSSOMES TABLE...\n";
	my $fasta = fasta->new($input);
	my $stats = $fasta->getStat();
	print "  SENDING CHROMOSSOMES [",(scalar keys %$stats),"]...\n";

	foreach my $chrom (sort keys %$stats)
	{
		my $size = $stats->{$chrom}{size};
		my $gene = $fasta->readFasta($chrom);
		my $genLeng = scalar @$gene;
		print "    CHROMOSSOME $chrom SIZE $size LENGTH $genLeng\n";
		my $seq = join('', @$gene);
		chomp $seq;

		my $ans = &sendQuestion($seq, $input, $output, $chrom);
		#exit 1 if ( ! $ans );
	} # foreach my $chrom
	exit 0;
}
elsif ( $CMD eq 'LINE' )
{
		my $name   = $ARGV[0];
		my $seq    = $ARGV[1];
		my $output = defined $ARGV[2] ? $ARGV[2] : './';
		if ( ! -d $output        ) { print "OUTPUT '$output' DIR DOESNT EXISTS"; exit 1;};

		chomp $seq;
		$seq =~ s/\?/\-/g;
		my $ans = &sendQuestion($seq, 'single', $output, $name);
		exit 1 if ( ! $ans );
		exit 0;
}
elsif ( $CMD  eq "CHECK" )
{
		&loadSetup();
		my $job_id    = $ARGV[0];
		my $output    = defined $ARGV[1] ? $ARGV[1] : './';
		if ( ! -d $output        ) { print "OUTPUT '$output' DIR DOESNT EXISTS"; exit 1;};

		my $retriever = $headers{JOBRETRIEVE};
		my $link      = $retriever . $job_id;
		print "      CHECK :: JOB ID: $job_id LINK: '$link'\n" if $verbose;
		my $ans = &waitAnswer("CHECK JOB", $job_id, $link, $output);
		exit 1 if ( ! $ans );
		exit 0;
} else {
	die;
}
#$timestamp="2010_10_08_1657_55";



die "HOW DID U GET HERE?";
exit 1;
#my $inputSeq = "ACGGGCAGGCCCAGTTCGACGATAGGTTCTTCATCTTCGTCTTTGACTAACCCTTTCAGGAGATCTTTGGCCGTGTCGTCGCCCTTTTCAAGAAGTAGTTCTTCGACGAGCATGGCAGGGACCGGATCGCCTGCGTCTTCAAATTTGACCATCACTGGAGGAGGAGGAGGAGTTAGCGGGGCTTCGCCCGGGGTATCACCTTCGCCTTCCCCATCTCCCTCTCCTGTACCCACCCACCGCCCAAATTCCTCCCACCCACTTTCCAAGTACACCTCTCTCCCTCTCTCCTCCTCCTCC---------------ACAAACACTAGCATTCCGCCCCTCGCTACAGGTCGTCTCCTAAAGATTATTGCCGACTTTCTCCTCCTCTCCGGCCTTTTCTCAGATAGTATCGTCCTCTATGACGAAGCGATCCAGCGGTGTAAGGAAGTAGGGGATGTGCTTTGGGAAGCGGCAGCGAGGGAGGGAAGGGCGGTGGCGGGCATAGAGGAGGGTTGGGGGTGGAGAGCTGGAGGAGTGAGTCTTTTTTCTTTTTTTCACTA-ATCATATCCT-------AAATCCAGAAGCGCTAA-----TGAAATTCAATCCCACTAAAAACGGGTATTGAAACCAGACCCAAACTCAGCCATTCCCCGCATCTCCCATCCCCAACGAGATCTTTTCACAATTCGTAGCTGCGCTAGGATGTATCAGTTCGGCGCCCTTGCTCTTCCCCGAGTTTGATGCAGGATCAGGATTAGGAATAGAATCAGGAC---AAATGCAACAGACAGCAATAGACCGTGGAACCCATCTCCTTGCCTACTTGTACGCCGGCCTCGCGCTCCGATTGGCTCATTTTTTGCTGATTGTTTGGGCGGCGGGCGGATGGGGCGAGGTGGCGTTGGGTTGTTTGGTGAGGCATGAGTTGCCGAGATCGTTCTTACCCCCCATCCCCCCCATCTCCTCCTCCCCGTCCTCCTCCATGTCCCGTGCCCATGCCACCGCTACTACCTCGACGTACGCGCAAGAGGGAAAACGGAAATCCCACCTCCGGGTCTTATCGACCAGTTCCCAAATCCCGCGTCATTTCATCCTTTCCCTAGCGCGTCTGGCGACATCTCCTCCCATTTTACGATGTCTTCGGTCGTCCNNNNNNNN---NNNNNNNNN------NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNGGGAATGAGAGTGGCCCTGGAGCGAGGGAAGGGAGGGATGGGAATGGAAATCCTGGAAGGGTACCTTCGGATACGGCTGTAACGAATATGGGCACGAACACCAATATCAGCACGGCGAGTATGGGGGGTATGGCAGATAAGGAAAAGGATCGACGATTATCGACCATGAGCCAAGCGAGTTTGAGAAGCCAAACGAGCCAGACCACCGAAACCACTCAAGCTAGCCAAACTGATACCGATCCCGCTTCCGCGTCTGCCTCGGTAGGGTTAGGTCTCGGTATGTCCGTTTCCATTTCCTCCTCTACTTACCCGACAACAACGTCCGAAACCGACTCTCAACGCAGATCAGGGAGAGGGGGGATAACTATCCGCCGGAAAGAAATCACTCAAGGAAACGCCGGTATCTTCTCCATCCTTTCCCAACAGGCAAGGGTCCTAGGAATCGAGATTTTGCGGGATGTATTCCCGACTGAGAGGAGCGTATTTGTGCTTTGGCCACCTGCAGGTTCAGGTCAAGGTGATGGTCGACGGAAAGATATAGGGAAAGGGTTGTCGAGCGGAGGTATGGTAGGAGTTGATGATGAGCTCGGTGTAGGTTTTACCAGAGCTGGAGTTGAAGATTTCGGATGGGCGAGTTTGAAACTTGAGTTTCTGAAGAAGAGTATCACTCTCCTTGGTAACTTGCCCGACCATCCCAACACTGTACGCCTTGCGCTCATCGCTCTCCATCTTCTCCCTTCGTTATCTCATCAGTTGGCCCTGCAATCTGGGTCTGGAGTGGACGGGGGTACGCAAATGGTGTTGAGTCGAGTGTA";






sub sendQuestion
{
	my $seq    = $_[0];
	my $input  = $_[1];
	my $output = $_[2];
	my $chrom  = $_[3];

	if ( $seq =~ /[^ACGTNacgtn\-\?]/ ) { print "INVALID SEQUENCE\n"; return undef; };

	if ( $goAroundN )
	{
		my $countFrags = 0;
		my $frags      = &getGaps($seq);
		return undef if ( ! defined $frags );
		return undef if ( ! scalar @$frags );

		#my $probeStart  = $pair->{probeStart};
		#my $probeEnd    = $pair->{probeEnd};
		#my $gapStartNum = $pair->{gapNumberStart};
		#my $gapEndNum   = $pair->{gapNumberEnd};
		#$pair->{name}           = $name;
		#$pair->{fragment}       = substr($seq, $probeStart, ($probeEnd - $probeStart));
		#$pair->{fragmentLength} = length($pair->{fragment});
		#$pair->{clearance}{PRIMER5_START} = $probeStart;
		#$pair->{clearance}{PRIMER5_END}   = $pair->{gapStart};
		#$pair->{clearance}{PRIMER3_START} = $pair->{gapEnd};
		#$pair->{clearance}{PRIMER3_END}   = $probeEnd;

		#PRIMER5_START=1&PRIMER5_END=87&PRIMER3_START=89&PRIMER3_END=90
		#&PRIMER5_START=10&PRIMER5_END=30&PRIMER3_START=80&PRIMER3_END=100&
		#print "SEQ $frag\n";

		foreach my $fragData ( @$frags )
		{
			my $target    = &loadSetup();
			my $frag      = $fragData->{fragment};
			my $name      = $fragData->{name};
			my $clearance = $fragData->{clearance};
			foreach my $key (sort keys %$clearance)
			{
				$setup{$key} = $clearance->{$key};
			}
			my $lChrom    = "$chrom\_$name";
			my $queryLine = &genQueryLine($frag);

			print "      FASTA :: NAME: $lChrom TARGET: $target QUERY: '$queryLine'\n" if $verbose;
			my %query = (
				input      => $input,
				output     => $output,
				chrom      => $chrom,
				target     => $target,
				queryLine  => $queryLine,

				chromName  => $lChrom,
				fragData   => $fragData,
			);
			#my $ans = &postRequest($input, $output, $lChrom, $target, $queryLine) if ( $post );
			my $ans = &postRequest(\%query) if ( $post );
			$countFrags++ if ( $ans );
		}
		if ( $countFrags ) { return 1 } else { return undef };
	} else {
		print "SEQ ". substr($seq, 0, 100) . "\n";

		my $target    = &loadSetup();
		my $queryLine = &genQueryLine($seq);

		print "      FASTA :: NAME: $chrom TARGET: $target QUERY: '$queryLine'\n" if $verbose;
		my %query = (
				input      => $input,
				output     => $output,
				chrom      => $chrom,
				target     => $target,
				queryLine  => $queryLine,
			);
		#my $ans = &postRequest($input, $output, $chrom, $target, $queryLine) if ( $post );
		my $ans = &postRequest(\%query) if ( $post );
		return undef if ( ! $ans );
		return 1;
	}


}

sub postRequest
{
	my $query     = $_[0];
	my $target    = $query->{target};
	my $queryLine = $query->{queryLine};

	my $curlF    = WWW::Curl::Simple->new;
	my $response = $curlF->post($target, $queryLine);
	if ( ! $response->is_success )
	{
		if ( $response->code != 100 )
		{
			print "ERROR WITH HTTP REQUEST:\n";
			print "  STATUS   : ". $response->status_line . "\n";
			#print "  CONTENT  : ". $response->content     . "\n";
			#print "  REQUEST  : ". $response->request     . "\n";
			#print "  AS STRING: ". $response->as_string   . "\n";
			my $resp = $response->as_string;
			$query->{type}        = 'request';
			$query->{status}      = 'err';
			$query->{responseStr} = $resp;
			#&printOut($src, $output, $title, 'request', 'err', $resp);
			&printOut($query);
			return undef;
		} else {
			$query->{response} = $response;
			my $chkAns = &checkResponse($query);
			return undef if ! defined $chkAns;
			my ($type, $link) = @$chkAns;
			if ( $type == 0 )
			{
				$query->{link}     = $link;
				$query->{type}     = $type;
				#my $ans = &waitAnswer($src, $title, $link, $output);
				my $ans = &waitAnswer($query);
				return undef if ( ! $ans );
				return 1;
			} else {
				print "SOMETHING WENT CRAZY\n";
				my $resp = $response->as_string;
				$query->{type}        = 'request';
				$query->{status}      = 'err';
				$query->{responseStr} = $resp;
				#&printOut($src, $output, $title, 'request', 'err', $resp);
				&printOut($query);
				return undef;
			}
		}
	} else {
		print "ERROR WITH HTTP REQUEST :: SUCCESS WHEN SHOULD BE 100\n";
		print "  STATUS   : ". $response->status_line . "\n";
		#print "  CONTENT  : ". $response->content     . "\n";
		#print "  REQUEST  : \n";
		#my $req = $response->request;
		#map { print "\t", $_, " => ", $req->{$_}, "\n" } keys %$req;
		#print "  AS STRING: ". $response->as_string   . "\n";
		#my $resp = $response->as_string;
		#&printOut($title, 'request', 'err', $resp);
		$query->{response} = $response;
		my $ans = &checkResponse($query);
		return undef if ( ! $ans );
		#my ($type, $page) = @$ans;
	}
}


sub waitAnswer
{
	my $query     = $_[0];
	my $link      = $query->{link};

	my $curlW     = WWW::Curl::Simple->new;
	my $responseW = $curlW->get($link);
	my $tries     = 0;
	my $rid       = '';
	my $error     = '';

	while (( $responseW->is_success ) && ( $tries++ < $maxTries ))
	{
		if ( ! defined $responseW ) { warn "NO RESPONSE"; return undef; };
		print "  [$tries] CHECKING AGAIN\n";
		$query->{response} = $responseW;
		my $responseAns = &checkResponse($query);
		return undef if ( ! defined $responseAns );
		my ($type, $page) = @$responseAns;
		return undef if ( ! defined $page );

		print "    TYPE $type PAGE $page\n";

		if ( $type == 0 )
		{
			print "  $tries - SLEEPING\n";
			sleep $sleepTime;
			print "  $tries - RE-TRYING: $page\n";
			$responseW = $curlW->get($page);
			if ( ! defined $responseW )
			{
				warn "NO RESULT RETURNED";
				return undef;
			};
		}
		elsif ( $type == 1 )
		{
			print "  SUCCESS!! RID: $page\n";
			my $resp = $responseW->decoded_content;
			$query->{type}        = 'response';
			$query->{status}      = 'ok';
			$query->{responseStr} = $resp;
			my $ouAns = &printOut($query);
			return undef if ! defined $ouAns;
			return 1;
		} else {
			warn "UNKNOWN TYPE: $type\n";
			return undef;
		}
	}

	if ( $tries++ < $maxTries )
	{
		warn "TOO MANY TRIES $tries";
		return undef
	} else {
		warn "HOW DID YOU LEAVE THE LOOP? $tries";
		return undef
	}
}

sub checkResponse
{
	my $query    = $_[0];
	my $response = $query->{response};

	my $resp     = $response->decoded_content;
	if ( ! defined $resp ) { warn "NO RESPONSE HERE\n"; return undef };
	#print "RESP $resp\n";

		#print "  AS STRING: ". $err . "\n";
	if ( $resp =~ /\<p class\=\"error\"\>(.+?)\<\/p\>/s )
	{
		my $error = $1;
		$error =~ s/\n//g;
		print "  ERROR: \"$error\"\n\n";
		$query->{type}        = 'request';
		$query->{status}      = 'err';
		$query->{responseStr} = $resp;
		&printOut($query);
		return undef;
	}
	#<p class="info">No primers were found...see explanation below:  Exon/exon junction cannot be found for submitted PCR template.  Try search again without exon/intron requirements.
	elsif ( $resp =~ /\<p class\=\"info\"\>(.+?)\<\/p\>/s )
	{
		my $error = $1;
		$error =~ s/\n//g;
		print "  INFO: \"$error\"\n\n";
		$query->{type}        = 'request';
		$query->{status}      = 'err';
		$query->{responseStr} = $resp;
		&printOut($query);
		return undef;
	}
	#<META HTTP-EQUIV=Refresh CONTENT="20; URL=http://www.ncbi.nlm.nih.gov/tools/primer-blast/primertool.cgi?ctg_time=1286794847&job_key=JSID_01_554285_130.14.22.21_9000">
	#<FORM METHOD="GET" ACTION="http://www.ncbi.nlm.nih.gov/tools/primer-blast/primertool.cgi?ctg_time=1286794847&job_key=JSID_01_554285_130.14.22.21_9000">
	#<INPUT TYPE="HIDDEN" NAME="ctg_time" VALUE="1286794847">
	#<INPUT TYPE="HIDDEN" NAME="job_key" VALUE="JSID_01_554285_130.14.22.21_9000">
	elsif ( $resp =~ /\<META HTTP-EQUIV\=Refresh .+? URL\=(.+?)\"\>/s )
	{
		print "  SUCCESS :: REDIRECTING\n\n";
		my $respDec = $response->decoded_content;
		return undef if ( ! defined $respDec );

		#my $data0 = &readOut0($out0);
		my $page = $1;
		#http://www.ncbi.nlm.nih.gov/tools/primer-blast/primertool.cgi?ctg_time=1286794847&job_key=JSID_01_554285_130.14.22.21_9000"
		if ( $page =~ /ctg_time\=(\d+)\&job_key=(\S+)/ )
		{
			my $ctg_time = $1;
			my $job_key  = $2;
			print "    CTG TIME: $ctg_time\n";
			print "    JOB KEY : $job_key\n\n";
			$query->{type}        = 'request';
			$query->{status}      = 'ok';
			$query->{responseStr} = $resp;
			my $ouAns = &printOut($query);
			return undef if ! defined $ouAns;
			return [ 0, $page ];
		} else {
			warn "    PROBLEM PARSING ANSWER:\n";
			$query->{type}        = 'request';
			$query->{status}      = 'err';
			$query->{responseStr} = $resp;
			my $ouAns = &printOut($query);
			warn $resp;
			return undef;
		}
	}
	elsif ( $resp =~ /\<\!--RID=\s*(.+?)--\>/s )
	{
		#<!--RID= 1286802244-9323-194455683964.BLASTQ6 -->
		my $rid = $1;
		$rid =~ s/\s+//g;
		return[1, $rid ];
	} else {
		warn "  UNKNOWN ERROR $resp";
		$query->{type}        = 'request';
		$query->{status}      = 'err';
		$query->{responseStr} = $resp;
		my $ouAns = &printOut($query);
		return undef;
	}
}

sub htmlParser
{
	my $html = $_[0];

	#my $htmlParser = HTML::FormatText::WithLinks->new();
	#return $htmlParser->parse($html);

	my $tree = HTML::TreeBuilder->new->parse($html);
	my $htmlParser = HTML::FormatText->new();
	return $htmlParser->format($tree);
}

sub printOut
{
	my $query       = $_[0];
	my $input       = $query->{input};
	my $output      = $query->{output};
	my $chrom       = $query->{chrom};
	my $type        = $query->{type};
	my $status      = $query->{status};
	my $responseStr = $query->{responseStr};
	my $inputName   = substr($input, rindex($input,'/')+1);


	my $titleShort = $inputName;
	if ( $shortName )
	{
		$titleShort =~ s/csv\.out\.tab_blast_merged_blast_all_gene\.xml\.tab\.fasta\.//g;
		$titleShort =~ s/neoformans/neo/g;
		$titleShort =~ s/fasta\.clustal\.fasta_consensus/clustal_consensus/g;
		$titleShort =~ s/supercontig/scontig/g;
	}

	my $prefix        = $titleShort . ($addTimeStamp ? ".$timestamp" : "");
	my $suffix        = ($stampEnd ? "." . &genTimeStamp() : '');
	my $fileName      = $prefix . ".$type.$status" . $suffix;

	print"
SAVING ::
   INPUT       : '$input'
   CHROMOSSOME : '$chrom'
   TITLE SHORT : '$titleShort'
   TYPE        : '$type'
   STATUS      : '$status'
   TO FOLDER   : '$output'
   FILE        : '$fileName.html'\n";

#'request', 'err',
#'request', 'ok',
#'response', 'ok',

#my $out0     = "$timestamp.0.submit.html";
#my $out0e    = "$timestamp.0.submit.err.html";
#my $out0et   = "$timestamp.0.submit.err.txt";
#my $out0t    = "$timestamp.0.submit.txt";
#my $out1     = "$timestamp.1.response.html";
#my $out1e    = "$timestamp.1.response.err.html";
#my $out1et   = "$timestamp.1.response.err.txt";
#my $out1t    = "$timestamp.1.response.txt";

	if ($type eq 'response')
	{
		unlink glob ("$output/$prefix" . '.request.*');
	}


	open  OUT, ">$output/$fileName.html" or (warn "$!" && return undef);
	if ( $cleanHTML )
	{
		$responseStr =~ s/\n.+?\<tr.*?hidden.*?\/tr\>//g;
		$responseStr =~ s/\<div class\=\"prPairTl\"\>.*?\<\/div\>//gs;
		$responseStr =~ s/\<div class\=\"prPairDtl\"\>.*?\<\/div\>//gs;
		$responseStr =~ s/\<div class\=\"hidden.*?\<\/div\>//gs;
		$responseStr =~ s/\<link.+?stylesheet.+?\/\>//gs;
		$responseStr =~ s/\<script.+?\<\/script\>//gs;
		$responseStr =~ s/\<style.+?\<\/style\>//gs;
		$responseStr =~ s/\<\!--.+?--\>//gs;
		$responseStr =~ s/\<img.+?\>//g;
		$responseStr =~ s/\<div id\=\"graphicInfo\".+?\<\/div\>//gs;
		$responseStr =~ s/\<a href\=.+?\<\/a\>//gs;
		$responseStr =~ s/\<a.+?\<\/a\>//gs;
		#$response =~ s/ +/ /gs;
		$responseStr =~ s/\s+\n/\n/g;
		$responseStr =~ s/\n+/\n/g;
		#$response =~ s/(\n.*?\<tr.*?hidden.*?\/tr\>\s*\n)/\n/g;
	}



	my $chromName = exists ${$query}{chromName} ? $query->{chromName} : $chrom;
	my $fragData  = $query->{fragData},
	my $start     = $query->{start};
	my $end       = $query->{end};

	my $srcTxt = "INPUT:$input:;:CHROM:$chrom";
	$srcTxt   .= ":;:CHROMNAME:$chromName" if defined $chromName;
	$srcTxt   .= ":;:START:$start"         if defined $start;
	$srcTxt   .= ":;:END:$end"             if defined $end;
	if ( defined $fragData )
	{
		foreach my $key ( sort keys %$fragData )
		{
			#$pair->{clearance}{PRIMER5_START} = $probeStart;
			next if $key eq 'clearance';
			my $data = $fragData->{$key};
			$srcTxt .= ":;:" . uc($key) . ":$data";
		}
	}
	$responseStr =~ s/(\<div id\=\"breadcrumb\"\>)/$1\nSRC: \<src\>$srcTxt\<\/src\><br\/\>\n\n/gs;
	print OUT $responseStr;
	close OUT;

	if ( -f "$output/$fileName.html" )
	{
		if ( -s "$output/$fileName.html" )
		{
			print "    CONVERTING TO TEXT\n";
			print `lynx -dump -nonumbers -nolist -pseudo_inlines '$output/$fileName.html' > '$output/$fileName.txt'`;
			if ( ! -f "$output/$fileName.txt" ) { warn "FILE '$output/$fileName.txt' DOESNT EXISTS. ERROR EXPORTING"; return undef };
			if ( ! -s "$output/$fileName.txt" ) { warn "FILE '$output/$fileName.txt' HAS SIZE ZERO. ERROR EXPORTING"; return undef };
			return 1;
		} else {
			warn "FILE '$output/$fileName.html' HAS SIZE ZERO. ERROR EXPORTING";
			return undef;
		}
	} else {
		warn "FILE '$output/$fileName.html' DOESNT EXISTS. ERROR EXPORTING";
		return undef;
	}
}







sub getGaps
{
	my $seq = $_[0];
	print "GETTING GAPS\n";
	my $seqLen  = length $seq;
	my $minSize = $primer_mean_size - $primer_clearance;
	my $maxSize = $primer_mean_size + $primer_clearance;
	my $clearance = int($minSize - 10);
	print "  MIN $minSize MAX $maxSize - SEQ LENGTH $seqLen\n";

	my $lastEnd;
	my $lastStart;
	my @poses;
	my $gapCount = 0;
	print "  SEARCHING FOR LIMITS:\n";
	while ( $seq =~ /([N|n|\?]+)/g )
	{
		my $frag    = $1;
		my $fragLen = length ($frag);
		my $end     = pos($seq) - 1;
		my $start   = $end - $fragLen + 1;
		my $diff    = $lastEnd ? $start - $lastEnd : '-';
		next if ( $fragLen < $minNSize );
		$poses[$gapCount]{start}    = $start;
		$poses[$gapCount]{end}      = $end;
		$poses[$gapCount]{fragLen}  = $fragLen;

		printf "    COUNT %02d START %04d END %04d LENGTH %04d\n", $gapCount, $start, $end, $fragLen;
		#print  "    START $start END $end LAST END ", ( $lastEnd ? $lastEnd : '-'), " DIFF $diff LENG $fragLen\n";
		#my $before  = substr($seq, $start-9, 10);
		#my $proof   = substr($seq, $start  , $fragLen);
		#my $after   = substr($seq, $end    , 10);
		#print "      $before - $proof - $after\n";

		$gapCount++;
		$lastEnd = $end;
	}

	my @pairs;
	print "  SEARCHING FOR PAIRS:\n";
	my $fmt = "    %02d :: %-3s %-8s %-5s (%04s) %-5s %05d [%s]\n";
	for ( my $p = 0; $p < @poses; $p++ )
	{
		my $curr  = $poses[$p];
		my $prev  = $p > 0      ? $poses[($p - 1)] : undef;
		my $next  = $p < @poses ? $poses[($p + 1)] : undef;

		my %data = (
			cStart => $curr->{start},
			cEnd   => $curr->{end},
			cLeng  => $curr->{fragLen}
		);
		printf "    %02d :: GAP  : START %04d END %04d LENGTH %04d\n", $p, $data{cStart}, $data{cEnd}, $data{cLeng};

		if ( defined $prev )
		{
			$data{pStart} = $prev->{start};
			$data{pEnd}   = $prev->{end};
			$data{pLeng}  = $prev->{fragLen};
		}
		if ( defined $next )
		{
			$data{nStart} = $next->{start};
			$data{nEnd}   = $next->{end};
			$data{nLeng}  = $next->{fragLen};
		}

		my $start;
		my $end;
		my $halfLeng = int ( $data{cLeng} / 2 );

		if ( exists $data{pEnd} )
		{
			$start = $data{cStart} - $maxSize;
			if ( $start <= $data{pEnd} )
			{
				$start = $data{pEnd} + 1 ;
				#printf $fmt, $p, 'HAS', 'PREVIOUS', 'END', $data{pEnd}, 'START', $start, "$start = $data{cStart} + $halfLeng - $halfAvgSize => $start = $data{pEnd} + 1";
			} else {
				#printf $fmt, $p, 'HAS', 'PREVIOUS', 'END', $data{pEnd}, 'START', $start, "$start = $data{cStart} + $halfLeng - $halfAvgSize";
			}
		} else {
			$start = $data{cStart} - $maxSize;
			$start = 0 if $start < 0;
			#printf $fmt, $p, 'NO', 'PREVIOUS', 'END', 0, 'START', $start, "$start = $data{cStart} + $halfLeng - $halfAvgSize";
		}

		if ( exists $data{nStart} )
		{
			$end = $data{cEnd} + $maxSize;
			if ( $end >= $data{nStart} )
			{
				$end = ( $data{nStart} - 1 );
				#printf $fmt, $p, 'HAS', 'NEXT', 'START', $data{nStart}, 'END', $end, "$end = $start + $avgSize => $end = ( $data{nStart} - 1 )";
			} else {
				#printf $fmt, $p, 'HAS', 'NEXT', 'START', $data{nStart}, 'END', $end, "$end = $start + $avgSize";
			}
		} else {
			$end = $data{cEnd} + $maxSize;
			#printf $fmt, $p, 'NO', 'NEXT', 'START', 0, 'END', $end, "$end = $start + $avgSize";
		}
		$end = $seqLen - 1 if ( $end >= $seqLen );

		printf "    %02d :: FRAG : START %04d END %04d LENGTH %04d\n\n", $p, $start, $end, ($end - $start);

		push(@pairs, {gapStart => $data{cStart}, gapEnd => $data{cEnd}, probeStart => $start, probeEnd => $end});
	}


	my @finalPairs;

	print "  COLAPSING PAIRS:\n";
	for ( my $p = 0; $p < @pairs; $p++ )
	{
		my $probeStart = $pairs[$p]{probeStart};
		my $probeEnd   = $pairs[$p]{probeEnd};
		my $gapStart   = $pairs[$p]{gapStart};
		my $gapEnd     = $pairs[$p]{gapEnd};

		my $pp = $p;

		#printf "    %02d :: START P  = %02d\n", $p, $p;
		while ( ( defined $pairs[$pp + 1] ) && ( ($pairs[$pp + 1][1] - $probeStart) <= $maxSize ) )
		{
			my $nStart = $pairs[$pp + 1]{probeStart};
			my $nEnd   = $pairs[$pp + 1]{probeEnd};
			print "    UNION :: $p ", ($pp+1), " :: [$probeStart-$probeEnd] + [$nStart-$nEnd] = [$probeStart $nEnd]\n";
			$pp++;
		}

		my $newProbeEnd = $pairs[$pp]{probeEnd};
		my $newGapEnd   = $pairs[$pp]{gapEnd};
		push(@finalPairs, {probeStart     => $probeStart,  gapStart     => $gapStart,
						   probeEnd       => $newProbeEnd, gapEnd       => $newGapEnd,
						   gapNumberStart => $p,           gapNumberEnd => $pp});
		#printf "    %02d :: FINAL PP = %02d\n", $p, $pp;
		printf "    %02d :: START %04d END %04d LENGTH %04d\n\n", $p, $probeStart, $newProbeEnd, ($newProbeEnd - $probeStart);
		$p = $pp;
	}

	print "  EXTRACTING PAIRS:\n";
	foreach my $pair ( @finalPairs )
	{
		#push(@finalPairs, (probeStart     => $probeStart,  gapStart     => $gapStart,
		#				   probeEnd       => $newProbeEnd, gapEnd       => $newGapEnd,
		#				   gapNumberStart => $p,           gapNumberEnd => $pp));
		my $probeStart  = $pair->{probeStart};
		my $probeEnd    = $pair->{probeEnd};
		my $gapStartNum = $pair->{gapNumberStart};
		my $gapEndNum   = $pair->{gapNumberEnd};
		my $g           = sprintf("G%02d", $gapStartNum);

		if ( $gapStartNum != $gapEndNum )
		{
			$g = sprintf("G%02d-%02d", $gapStartNum, $gapEndNum);
		}
		my $name  = sprintf("%04d_%04d_%s", $probeStart, $probeEnd,$g);

		$pair->{name}                     = $name;
		$pair->{fragment}                 = substr($seq, $probeStart, ($probeEnd - $probeStart));
		$pair->{fragmentLength}           = length($pair->{fragment});
		$pair->{clearance}{PRIMER5_START} = 1;
		$pair->{clearance}{PRIMER5_END}   = $pair->{gapStart} - $probeStart;
		$pair->{clearance}{PRIMER3_START} = $pair->{gapEnd}   - $probeStart;
		$pair->{clearance}{PRIMER3_END}   = $probeEnd         - $probeStart;
		#PRIMER5_START=1&PRIMER5_END=87&PRIMER3_START=89&PRIMER3_END=90

		printf "    PROBE START %04d GAP START %04d GAP END %04d PROBE END %04d GAP START NUM %02d GAP END NUM %02d NAME %s SEQLENGTH %04d SEQ\n",
		$pair->{probeStart},     $pair->{gapStart},
		$pair->{gapEnd},         $pair->{probeEnd},
		$pair->{gapNumberStart}, $pair->{gapNumberEnd},
		$pair->{name},           $pair->{fragmentLength},
		$pair->{fragment};
		#my $seqF = $pair->[5];
		#$seqF =~ s/(.{60})/$1\n/g;
		#print $seqF, "\n";
	}

	if ( scalar @finalPairs )
	{
		return \@finalPairs;
	} else {
		return undef;
	}
}


sub genQueryLine
{
	my $inSeq = $_[0];
	   $inSeq =~ s/\?/N/g;

	my $queryLine;
	foreach my $key (sort keys %setup)
	{
		$queryLine .= "&"if ( defined $queryLine );
		$queryLine .= "$key=$setup{$key}";
	}

	$queryLine   = "LINK_LOC=bookmark&INPUT_SEQUENCE=%0A$inSeq%0A&" . $queryLine;

	my $origin   = $headers{ORIGIN};
	my $request  = "$origin?$queryLine";

	#my $command  = "curl -d \"$request\" \"$target\"";
	#print "$command\n";

	return $request;
}




sub loadSetup
{
	my $primer_min_size = $primer_mean_size - $primer_clearance;
	my $primer_max_size = $primer_mean_size + $primer_clearance;

	%setup = (
	#	INPUT_SEQUENCE 				=> $inputSeq,
		PRIMER_PRODUCT_MIN 			=> $primer_min_size,
		PRIMER_PRODUCT_MAX 			=> $primer_max_size,
		PRIMER_NUM_RETURN 			=> 35,
		PRIMER_MIN_TM 				=> 50,
		PRIMER_OPT_TM 				=> 60,
		PRIMER_MAX_TM 				=> 65,
		PRIMER_MAX_DIFF_TM 			=> 0,
		PRIMER_ON_SPLICE_SITE 		=> 0,
		#SPLICE_SITE_OVERLAP_5END 	=> 7,
		#SPLICE_SITE_OVERLAP_3END 	=> 4,
		#SPAN_INTRON 				=> 'off',
		#MIN_INTRON_SIZE 			=> 1000,
		#MAX_INTRON_SIZE 			=> 1000000,
		SEARCH_SPECIFIC_PRIMER 		=> 'on',
		ORGANISM 					=> 'Filobasidiella/Cryptococcus%20neoformans%20species%20complex%20%28taxid%3A552466%29',
		PRIMER_SPECIFICITY_DATABASE => 'nt',
		TOTAL_PRIMER_SPECIFICITY_MISMATCH 	=> 1,
		PRIMER_3END_SPECIFICITY_MISMATCH 	=> 1,
		MISMATCH_REGION_LENGTH 		=> 5,
		TOTAL_MISMATCH_IGNORE 		=> 7,
		PRODUCT_SIZE_DEVIATION 		=> 4000,
		ALLOW_TRANSCRIPT_VARIANTS 	=> 'off',
		HITSIZE 					=> 50000,
		EVALUE 						=> 30000,
		WORD_SIZE 					=> 6,
		MAX_CANDIDATE_PRIMER 		=> 1000,
		PRIMER_MIN_SIZE 			=> 18,
		PRIMER_OPT_SIZE 			=> 20,
		PRIMER_MAX_SIZE 			=> 25,
		PRIMER_MIN_GC 				=> 20.0,
		PRIMER_MAX_GC 				=> 80.0,
		GC_CLAMP 					=> 0,
		POLYX 						=> 5,
		SELF_ANY 					=> 8.00,
		SELF_END 					=> 3.00,
		PRIMER_MISPRIMING_LIBRARY 	=> 'AUTO',
		#NO_SNP 						=> 'off',
		LOW_COMPLEXITY_FILTER 		=> 'on',
		#MONO_CATIONS 				=> 50.0,
		#DIVA_CATIONS 				=> 0.0,
		#CON_ANEAL_OLIGO 			=> 50.0,
		#CON_DNTPS 					=> 0.0,
		#SALT_FORMULAR 				=> 1,
		#TM_METHOD 					=> 1,
		#PRIMER_INTERNAL_OLIGO_MIN_SIZE 			=> 18,
		#PRIMER_INTERNAL_OLIGO_OPT_SIZE 			=> 20,
		#PRIMER_INTERNAL_OLIGO_MAX_SIZE 			=> 27,
		#PRIMER_INTERNAL_OLIGO_MIN_TM 			=> 57.0,
		#PRIMER_INTERNAL_OLIGO_OPT_TM 			=> 60.0,
		#PRIMER_INTERNAL_OLIGO_MAX_TM 			=> 63.0,
		#PRIMER_INTERNAL_OLIGO_MAX_GC 			=> 80.0,
		#PRIMER_INTERNAL_OLIGO_OPT_GC_PERCENT 	=> 50,
		#PRIMER_INTERNAL_OLIGO_MIN_GC 			=> 20.0,
		#PICK_HYB_PROBE 	=> 'off',
		#NEWWIN 			=> 'off'
	);



	%headers = (
		#ORIGIN 			=> "http://www.ncbi.nlm.nih.gov/tools/primer-blast/index.cgi",
		ORIGIN 			=> "http://www.ncbi.nlm.nih.gov/tools/primer-blast/primertool.cgi",
		ROOT 			=> "http://www.ncbi.nlm.nih.gov/tools/primer-blast/",
		SCRIPT 			=> "primertool.cgi",
		JOBRETRIEVE     => "http://www.ncbi.nlm.nih.gov/tools/primer-blast/primertool.cgi?job_key="
	);


	$timestamp = &genTimeStamp();
	my $target   = $headers{ROOT} . $headers{SCRIPT};
	return $target;
}


sub genTimeStamp
{
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime(time);
	return sprintf "%4d_%02d_%02d_%02d_%02d_%02d", $year+1900,$mon+1,$mday,$hour,$min,$sec;
}


sub readOut0
{
	my $in = $_[0];
	if ( ! -f "$in" )
	{
		warn "OUTPUT FILE '$in' COULD NOT BE CREATED";
		return undef;
	}


	my %data;
	open IN, "<$in" or (warn "%!" && return undef);
	while (my $line = <IN>)
	{
		#<!--RID=  -->
		if ( $line =~ /\<\!--RID=(.*?)--\>/ )
		{
			my $rid = $1;
			$rid =~ s/\s+//g;
			$data{rid} = $rid;
		}

		#Job id=JSID_01_16006_130.14.22.10_9000
		if ( $line =~ /Job id\=(\S+)/ )
		{
			my $jobId = $1;
			$data{JobId} = $jobId;
		}

	#	<p class="error">Exception error: No sequence input was provided
	#. </p>
		if ( $line =~ /\<p class\=\"error\"\>(.+)/ )
		{
			my $error = $1;
			$data{error} = $error;
		}
	}
	close IN;

	if ( ! exists $data{rid} )
	{
		warn "ERROR ON REQUEST. NO RID. JOB ID ", ($data{jobId} || 'none'), ". ERROR ", ($data{error} || 'none'), "\n";
		return undef;
	} else {
		print "RID    : $data{rid}\n";
		print "JOB ID : " . ( $data{jobId} || 'none' ) . "\n";
		print "ERROR  : " . ( $data{error} || 'none' ) . "\n";
	}

	return \%data;
}

	#./justniffer -i eth0 -p "tcp port 80"
	#QUERY
		#http://www.ncbi.nlm.nih.gov/tools/primer-blast/index.cgi?LINK_LOC=bookmark&INPUT_SEQUENCE=%0ACGGGCAGGCCCAGTTCGACGATAGGTTCTTCATCTTCGTCTTTGACTAACCCTTTCAGGAGATCTTTGGCCGTGTCGTCGCCCTTTTCAAGAAGTAGTTCTTCGACGAGCATGGCAGGGACCGGATCGCCTGCGTCTTCAAATTTGACCATCACTGGAGGAGGAGGAGGAGTTAGCGGGGCTTCGCCCGGGGTATCACCTTCGCCTTCCCCATCTCCCTCTCCTGTACCCACCCACCGCCCAAATTCCTCCCACCCACTTTCCAAGTACACCTCTCTCCCTCTCTCCTCCTCCTCC---------------ACAAACACTAGCATTCCGCCCCTCGCTACAGGTCGTCTCCTAAAGATTATTGCCGACTTTCTCCTCCTCTCCGGCCTTTTCTCAGATAGTATCGTCCTCTATGACGAAGCGATCCAGCGGTGTAAGGAAGTAGGGGATGTGCTTTGGGAAGCGGCAGCGAGGGAGGGAAGGGCGGTGGCGGGCATAGAGGAGGGTTGGGGGTGGAGAGCTGGAGGAGTGAGTCTTTTTTCTTTTTTTCACTA-ATCATATCCT-------AAATCCAGAAGCGCTAA-----TGAAATTCAATCCCACTAAAAACGGGTATTGAAACCAGACCCAAACTCAGCCATTCCCCGCATCTCCCATCCCCAACGAGATCTTTTCACAATTCGTAGCTGCGCTAGGATGTATCAGTTCGGCGCCCTTGCTCTTCCCCGAGTTTGATGCAGGATCAGGATTAGGAATAGAATCAGGAC---AAATGCAACAGACAGCAATAGACCGTGGAACCCATCTCCTTGCCTACTTGTACGCCGGCCTCGCGCTCCGATTGGCTCATTTTTTGCTGATTGTTTGGGCGGCGGGCGGATGGGGCGAGGTGGCGTTGGGTTGTTTGGTGAGGCATGAGTTGCCGAGATCGTTCTTACCCCCCATCCCCCCCATCTCCTCCTCCCCGTCCTCCTCCATGTCCCGTGCCCATGCCACCGCTACTACCTCGACGTACGCGCAAGAGGGAAAACGGAAATCCCACCTCCGGGTCTTATCGACCAGTTCCCAAATCCCGCGTCATTTCATCCTTTCCCTAGCGCGTCTGGCGACATCTCCTCCCATTTTACGATGTCTTCGGTCGTCCNNNNNNNN---NNNNNNNNN------NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNGGGAATGAGAGTGGCCCTGGAGCGAGGGAAGGGAGGGATGGGAATGGAAATCCTGGAAGGGTACCTTCGGATACGGCTGTAACGAATATGGGCACGAACACCAATATCAGCACGGCGAGTATGGGGGGTATGGCAGATAAGGAAAAGGATCGACGATTATCGACCATGAGCCAAGCGAGTTTGAGAAGCCAAACGAGCCAGACCACCGAAACCACTCAAGCTAGCCAAACTGATACCGATCCCGCTTCCGCGTCTGCCTCGGTAGGGTTAGGTCTCGGTATGTCCGTTTCCATTTCCTCCTCTACTTACCCGACAACAACGTCCGAAACCGACTCTCAACGCAGATCAGGGAGAGGGGGGATAACTATCCGCCGGAAAGAAATCACTCAAGGAAACGCCGGTATCTTCTCCATCCTTTCCCAACAGGCAAGGGTCCTAGGAATCGAGATTTTGCGGGATGTATTCCCGACTGAGAGGAGCGTATTTGTGCTTTGGCCACCTGCAGGTTCAGGTCAAGGTGATGGTCGACGGAAAGATATAGGGAAAGGGTTGTCGAGCGGAGGTATGGTAGGAGTTGATGATGAGCTCGGTGTAGGTTTTACCAGAGCTGGAGTTGAAGATTTCGGATGGGCGAGTTTGAAACTTGAGTTTCTGAAGAAGAGTATCACTCTCCTTGGTAACTTGCCCGACCATCCCAACACTGTACGCCTTGCGCTCATCGCTCTCCATCTTCTCCCTTCGTTATCTCATCAGTTGGCCCTGCAATCTGGGTCTGGAGTGGACGGGGGTACGCAAATGGTGTTGAGTCGAGTGTA%0A&PRIMER_PRODUCT_MIN=600&PRIMER_PRODUCT_MAX=1000&PRIMER_NUM_RETURN=35&PRIMER_MIN_TM=50&PRIMER_OPT_TM=60&PRIMER_MAX_TM=65&PRIMER_MAX_DIFF_TM=0&PRIMER_ON_SPLICE_SITE=0&SPLICE_SITE_OVERLAP_5END=7&SPLICE_SITE_OVERLAP_3END=4&SPAN_INTRON=off&MIN_INTRON_SIZE=1000&MAX_INTRON_SIZE=1000000&SEARCH_SPECIFIC_PRIMER=on&ORGANISM=Filobasidiella/Cryptococcus%20neoformans%20species%20complex%20(taxid:552466)&PRIMER_SPECIFICITY_DATABASE=nt&TOTAL_PRIMER_SPECIFICITY_MISMATCH=1&PRIMER_3END_SPECIFICITY_MISMATCH=1&MISMATCH_REGION_LENGTH=5&TOTAL_MISMATCH_IGNORE=7&PRODUCT_SIZE_DEVIATION=4000&ALLOW_TRANSCRIPT_VARIANTS=off&HITSIZE=50000&EVALUE=30000&WORD_SIZE=6&MAX_CANDIDATE_PRIMER=1000&PRIMER_MIN_SIZE=18&PRIMER_OPT_SIZE=20&PRIMER_MAX_SIZE=25&PRIMER_MIN_GC=20.0&PRIMER_MAX_GC=80.0&GC_CLAMP=0&POLYX=5&SELF_ANY=8.00&SELF_END=3.00&PRIMER_MISPRIMING_LIBRARY=AUTO&NO_SNP=off&LOW_COMPLEXITY_FILTER=on&MONO_CATIONS=50.0&DIVA_CATIONS=0.0&CON_ANEAL_OLIGO=50.0&CON_DNTPS=0.0&SALT_FORMULAR=1&TM_METHOD=1&PRIMER_INTERNAL_OLIGO_MIN_SIZE=18&PRIMER_INTERNAL_OLIGO_OPT_SIZE=20&PRIMER_INTERNAL_OLIGO_MAX_SIZE=27&PRIMER_INTERNAL_OLIGO_MIN_TM=57.0&PRIMER_INTERNAL_OLIGO_OPT_TM=60.0&PRIMER_INTERNAL_OLIGO_MAX_TM=63.0&PRIMER_INTERNAL_OLIGO_MAX_GC=80.0&PRIMER_INTERNAL_OLIGO_OPT_GC_PERCENT=50&PRIMER_INTERNAL_OLIGO_MIN_GC=20.0&PICK_HYB_PROBE=off&NEWWIN=on&NEWWIN=on
	#POST
		#10.136.201.22 - - [08/Oct/2010:16:30:18 +0200] "POST /tools/primer-blast/primertool.cgi HTTP/1.1" 200 0 "http://www.ncbi.nlm.nih.gov/tools/primer-blast/index.cgi?LINK_LOC=bookmark&INPUT_SEQUENCE=%0ACGGGCAGGCCCAGTTCGACGATAGGTTCTTCATCTTCGTCTTTGACTAACCCTTTCAGGAGATCTTTGGCCGTGTCGTCGCCCTTTTCAAGAAGTAGTTCTTCGACGAGCATGGCAGGGACCGGATCGCCTGCGTCTTCAAATTTGACCATCACTGGAGGAGGAGGAGGAGTTAGCGGGGCTTCGCCCGGGGTATCACCTTCGCCTTCCCCATCTCCCTCTCCTGTACCCACCCACCGCCCAAATTCCTCCCACCCACTTTCCAAGTACACCTCTCTCCCTCTCTCCTCCTCCTCC---------------ACAAACACTAGCATTCCGCCCCTCGCTACAGGTCGTCTCCTAAAGATTATTGCCGACTTTCTCCTCCTCTCCGGCCTTTTCTCAGATAGTATCGTCCTCTATGACGAAGCGATCCAGCGGTGTAAGGAAGTAGGGGATGTGCTTTGGGAAGCGGCAGCGAGGGAGGGAAGGGCGGTGGCGGGCATAGAGGAGGGTTGGGGGTGGAGAGCTGGAGGAGTGAGTCTTTTTTCTTTTTTTCACTA-ATCATATCCT-------AAATCCAGAAGCGCTAA-----TGAAATTCAATCCCACTAAAAACGGGTATTGAAACCAGACCCAAACTCAGCCATTCCCCGCATCTCCCATCCCCAACGAGATCTTTTCACAATTCGTAGCTGCGCTAGGATGTATCAGTTCGGCGCCCTTGCTCTTCCCCGAGTTTGATGCAGGATCAGGATTAGGAATAGAATCAGGAC---AAATGCAACAGACAGCAATAGACCGTGGAACCCATCTCCTTGCCTACTTGTACGCCGGCCTCGCGCTCCGATTGGCTCATTTTTTGCTGATTGTTTGGGCGGCGGGCGGATGGGGCGAGGTGGCGTTGGGTTGTTTGGTGAGGCATGAGTTGCCGAGATCGTTCTTACCCCCCATCCCCCCCATCTCCTCCTCCCCGTCCTCCTCCATGTCCCGTGCCCATGCCACCGCTACTACCTCGACGTACGCGCAAGAGGGAAAACGGAAATCCCACCTCCGGGTCTTATCGACCAGTTCCCAAATCCCGCGTCATTTCATCCTTTCCCTAGCGCGTCTGGCGACATCTCCTCCCATTTTACGATGTCTTCGGTCGTCCNNNNNNNN---NNNNNNNNN------NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNGGGAATGAGAGTGGCCCTGGAGCGAGGGAAGGGAGGGATGGGAATGGAAATCCTGGAAGGGTACCTTCGGATACGGCTGTAACGAATATGGGCACGAACACCAATATCAGCACGGCGAGTATGGGGGGTATGGCAGATAAGGAAAAGGATCGACGATTATCGACCATGAGCCAAGCGAGTTTGAGAAGCCAAACGAGCCAGACCACCGAAACCACTCAAGCTAGCCAAACTGATACCGATCCCGCTTCCGCGTCTGCCTCGGTAGGGTTAGGTCTCGGTATGTCCGTTTCCATTTCCTCCTCTACTTACCCGACAACAACGTCCGAAACCGACTCTCAACGCAGATCAGGGAGAGGGGGGATAACTATCCGCCGGAAAGAAATCACTCAAGGAAACGCCGGTATCTTCTCCATCCTTTCCCAACAGGCAAGGGTCCTAGGAATCGAGATTTTGCGGGATGTATTCCCGACTGAGAGGAGCGTATTTGTGCTTTGGCCACCTGCAGGTTCAGGTCAAGGTGATGGTCGACGGAAAGATATAGGGAAAGGGTTGTCGAGCGGAGGTATGGTAGGAGTTGATGATGAGCTCGGTGTAGGTTTTACCAGAGCTGGAGTTGAAGATTTCGGATGGGCGAGTTTGAAACTTGAGTTTCTGAAGAAGAGTATCACTCTCCTTGGTAACTTGCCCGACCATCCCAACACTGTACGCCTTGCGCTCATCGCTCTCCATCTTCTCCCTTCGTTATCTCATCAGTTGGCCCTGCAATCTGGGTCTGGAGTGGACGGGGGTACGCAAATGGTGTTGAGTCGAGTGTA%0A&PRIMER_PRODUCT_MIN=600&PRIMER_PRODUCT_MAX=1000&PRIMER_NUM_RETURN=35&PRIMER_MIN_TM=50&PRIMER_OPT_TM=60&PRIMER_MAX_TM=65&PRIMER_MAX_DIFF_TM=0&PRIMER_ON_SPLICE_SITE=0&SPLICE_SITE_OVERLAP_5END=7&SPLICE_SITE_OVERLAP_3END=4&SPAN_INTRON=off&MIN_INTRON_SIZE=1000&MAX_INTRON_SIZE=1000000&SEARCH_SPECIFIC_PRIMER=on&ORGANISM=Filobasidiella/Cryptococcus%20neoformans%20species%20complex%20%28taxid%3A552466%29&PRIMER_SPECIFICITY_DATABASE=nt&TOTAL_PRIMER_SPECIFICITY_MISMATCH=1&PRIMER_3END_SPECIFICITY_MISMATCH=1&MISMATCH_REGION_LENGTH=5&TOTAL_MISMATCH_IGNORE=7&PRODUCT_SIZE_DEVIATION=4000&ALLOW_TRANSCRIPT_VARIANTS=off&HITSIZE=50000&EVALUE=30000&WORD_SIZE=6&MAX_CANDIDATE_PRIMER=1000&PRIMER_MIN_SIZE=18&PRIMER_OPT_SIZE=20&PRIMER_MAX_SIZE=25&PRIMER_MIN_GC=20.0&PRIMER_MAX_GC=80.0&GC_CLAMP=0&POLYX=5&SELF_ANY=8.00&SELF_END=3.00&PRIMER_MISPRIMING_LIBRARY=AUTO&NO_SNP=off&LOW_COMPLEXITY_FILTER=on&MONO_CATIONS=50.0&DIVA_CATIONS=0.0&CON_ANEAL_OLIGO=50.0&CON_DNTPS=0.0&SALT_FORMULAR=1&TM_METHOD=1&PRIMER_INTERNAL_OLIGO_MIN_SIZE=18&PRIMER_INTERNAL_OLIGO_OPT_SIZE=20&PRIMER_INTERNAL_OLIGO_MAX_SIZE=27&PRIMER_INTERNAL_OLIGO_MIN_TM=57.0&PRIMER_INTERNAL_OLIGO_OPT_TM=60.0&PRIMER_INTERNAL_OLIGO_MAX_TM=63.0&PRIMER_INTERNAL_OLIGO_MAX_GC=80.0&PRIMER_INTERNAL_OLIGO_OPT_GC_PERCENT=50&PRIMER_INTERNAL_OLIGO_MIN_GC=20.0&PICK_HYB_PROBE=off&NEWWIN=on&NEWWIN=on" "Mozilla/5.0 (X11; U; Linux x86_64; en-US) AppleWebKit/534.7 (KHTML, like Gecko) Chrome/7.0.517.24 Safari/534.7"
	#RESULT
		#http://www.ncbi.nlm.nih.gov/tools/primer-blast/primertool.cgi?ctg_time=1286548232&job_key=JSID_01_545859_130.14.22.21_9000
		#10.136.201.22 - - [08/Oct/2010:16:30:49 +0200] "GET /tools/primer-blast/primertool.cgi?ctg_time=1286548232&job_key=JSID_01_545859_130.14.22.21_9000 HTTP/1.1" 200 0 "http://www.ncbi.nlm.nih.gov/tools/primer-blast/primertool.cgi" "Mozilla/5.0 (X11; U; Linux x86_64; en-US) AppleWebKit/534.7 (KHTML, like Gecko) Chrome/7.0.517.24 Safari/534.7"
		#10.136.201.22 - - [08/Oct/2010:16:31:10 +0200] "GET /tools/primer-blast/primertool.cgi?ctg_time=1286548232&job_key=JSID_01_545859_130.14.22.21_9000 HTTP/1.1" 200 0 "http://www.ncbi.nlm.nih.gov/tools/primer-blast/primertool.cgi?ctg_time=1286548232&job_key=JSID_01_545859_130.14.22.21_9000" "Mozilla/5.0 (X11; U; Linux x86_64; en-US) AppleWebKit/534.7 (KHTML, like Gecko) Chrome/7.0.517.24 Safari/534.7"
		#10.136.201.22 - - [08/Oct/2010:16:30:53 +0200] "GET /linux/rpm/stable/x86_64/google-chrome-beta-7.0.517.36-61761.x86_64.rpm HTTP/1.1" 200 24570151 "" "urlgrabber/3.9.1 yum/3.2.28"
		#10.136.201.22 - - [08/Oct/2010:16:31:30 +0200] "GET /tools/primer-blast/primertool.cgi?ctg_time=1286548232&job_key=JSID_01_545859_130.14.22.21_9000 HTTP/1.1" 200 0 "http://www.ncbi.nlm.nih.gov/tools/primer-blast/primertool.cgi?ctg_time=1286548232&job_key=JSID_01_545859_130.14.22.21_9000" "Mozilla/5.0 (X11; U; Linux x86_64; en-US) AppleWebKit/534.7 (KHTML, like Gecko) Chrome/7.0.517.24 Safari/534.7"
	#RESULT FINAL
		#http://www.ncbi.nlm.nih.gov/tools/primer-blast/primertool.cgi?ctg_time=1286548232&job_key=JSID_01_545859_130.14.22.21_9000

1;
