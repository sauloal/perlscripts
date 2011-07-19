#!/usr/bin/perl -w
use strict;
use FindBin qw($Bin);
use lib "$Bin";
use fasta;
my $printHits = 0;

my $inTab     = $ARGV[0];
my $outFolder = $ARGV[1];
my @inFasta   = @ARGV[2 .. @ARGV -1];

die "NO INPUT TAB"     if ( !    $inTab     );
die "NO INPUT TAB"     if ( ! -f $inTab     );
die "NO OUTPUT FOLDER" if ( !    $outFolder );
die "NO OUTPUT FOLDER" if ( ! -d $outFolder );
die "NO INPUT FASTA"   if ( !    @inFasta   );

die "INPUT TAB DOESNT EXISTS"   if ( ! -f $inTab );
my @titles = qw(name fasta chrom tag start end fwd fwdLen rev revLen amplicom amplicomLen amplicomClean amplicomCleanLen amplicomDiff str);

print "READING TAB\n";
my $pairs   = &readTab($inTab);
print "GENERATING RESULT\n";
my $result  = &readFastas(\@inFasta, $pairs);
my $outFile = $outFolder . "/" . substr($inTab, rindex($inTab, "/")+1) . ".epcr.csv";
print "EXPORTING\n";
&export($result, $outFile);
print "DONE\n";

sub export
{
	my $res = $_[0];
	my $out = $_[1];
	print "  EXPORTING TO $out\n";
	open OUT, ">$out" or die "COULD NOT OPEN OUTPUT $out: $!";
	print OUT join("\t", @titles), "\n";
	foreach my $name ( sort keys %$res )
	{
		my $fastas = $res->{$name};
		print "  "x0, "PROBE NAME: $name :: ", (scalar keys %$fastas), " FASTAS\n";

		foreach my $fasta ( sort keys %$fastas )
		{
			my $chroms = $fastas->{$fasta};
			print "  "x1, "FASTA: $fasta :: ", (scalar keys %$chroms), " CHROMOSSOMES\n";
			foreach my $chrom ( sort keys %$chroms )
			{
				my $poses = $chroms->{$chrom};
				print "  "x2, "CHROM: $chrom :: ", (scalar keys %$poses), " POSITIONS\n";
				foreach my $pos ( sort {$a <=> $b} keys %$poses )
				{
					my $hits = $poses->{$pos};
					print "  "x3, "POSITION: ", $pos+1, " :: ", (scalar @$hits)," HITS\n";
					for (my $h = 0; $h < @$hits; $h++ )
					{
						my $hit = $hits->[$h];
						print "  "x4, "HIT: ", ($h+1), " / ",(scalar @$hits),"\n" if $printHits;

						foreach my $key ( sort keys %$hit )
						{
							my $value = $hit->{$key};
							printf "  "x5 . "%-12s :: %s\n", $key, $value if $printHits;
						}

						my @out;
						foreach my $title ( @titles )
						{
							push( @out, $hit->{$title} );
						}
						print OUT join("\t", @out), "\n";
					}
				}
			}
		}
	}
	# push(@{$out{$nam}{$fastaFile}{$chrom}{$startPos}}, \%hit);
	#my %hit = (
	#			name        => $nam,
	#			chrom       => $chrom,
	#			start       => $startPos,
	#			end         => $endPos,
	#			fwd         => $fwd,
	#			fwdLen      => length($fwd),
	#			rev         => $rev,
	#			revLen      => length($rev),
	#			amplicom    => $amp,
	#			amplicomLen => length($amp),
	#			str         => $out
	#			);
	close OUT;
}


sub readTab
{
	my $tab = $_[0];
	my @pairs;
	open TAB, "<$tab" or die "COULD NOT READ $tab: $!";
	while (my $line = <TAB>)
	{
		chomp $line;
		next if ! $line;
		$line =~ s/\"//g;
		my @cols = split (/\s+/, $line);
		next if ! @cols;
		die "WRONG FORMAT: $line\n" if @cols > 3;
		if ( @cols == 2 )
		{
			$cols[3] = $cols[1] . "_" . $cols[2];
		}
		push(@pairs, \@cols);
	}
	close TAB;
	return \@pairs;
}

sub readFastas
{
	my $fastas  = $_[0];
	my $couples = $_[1];
	my %out;
	foreach my $fastaFile ( @$fastas )
	{
		die "INPUT FASTA DOESNT EXISTS" if ( ! -f $fastaFile );
		my $fasta = fasta->new($fastaFile);
		my $stats = $fasta->getStat();
		foreach my $chrom (sort keys %$stats)
		{
			my $size = $stats->{$chrom}{size};
			my $gene = $fasta->readFasta($chrom);
			my $genLeng = scalar @$gene;
			print "  FASTA $fastaFile CHROMOSSOME $chrom SIZE $size LENGTH $genLeng\n";
			my $seq = join('', @$gene);
			foreach my $pair ( @$couples )
			{
				my $fwd = $pair->[0];
				my $rev = $pair->[1];
				my $nam = $pair->[2] || '';
				die "NO FORWARD GENE" if ! $fwd;
				die "NO REVERSE GENE" if ! $rev;

				my $revRev = &rc($rev);
				my $fwdRev = &rc($fwd);

				#&searchInside(\$seq, $fwd   , $rev   , 'FWD+REV'      , $nam, $chrom, $fastaFile, \%out);
				&searchInside(\$seq, $fwd   , $revRev, 'FWD+REVREV'   , $nam, $chrom, $fastaFile, \%out);
				&searchInside(\$seq, $fwdRev, $rev   , 'FWDREV+REV'   , $nam, $chrom, $fastaFile, \%out);
				#&searchInside(\$seq, $fwdRev, $revRev, 'FWDREV+REVREV', $nam, $chrom, $fastaFile, \%out);
				&searchInside(\$seq, $fwd   , $fwdRev, 'FWD+FWDREV'   , $nam, $chrom, $fastaFile, \%out);
				&searchInside(\$seq, $rev   , $revRev, 'REV+REVREV'   , $nam, $chrom, $fastaFile, \%out);

			} #end foreach my pair
		} #end foreach my chrom
	} #end foreach my fasta
	return \%out;
} #end sub read fasta


sub searchInside
{
	my $seq   = $_[0];
	my $fwd   = $_[1];
	my $rev   = $_[2];
	my $tag   = $_[3];
	my $nam   = $_[4];
	my $chrom = $_[5];
	my $fasta = $_[6];
	my $hash  = $_[7];

	my $out;
	my $countPair = 0;

	while ( $$seq =~ /($fwd)(.+)($rev)/g )
	{
		my $fwdS     = $1;
		my $ampS     = $2;
		my $revS     = $3;

		my $ampClean = $ampS;
		   $ampClean =~ s/N//ig;
		#print "AMP      $amp\n";
		#print "AMPCLEAN $ampClean\n\n";

		my $endPos   = pos($$seq);
		my $startPos = $endPos - length($fwdS) - length($ampS) - length($revS);
		$out .= ++$countPair . " ";
		$out .= "NAME $nam " if ( $nam );
		$out .= "CHROM $chrom START $startPos END $endPos FWD ". length($fwdS). " REV ". length($revS). " AMPLICOM ". length($ampS) . " AMPLICOM CLEAN ". length($ampClean). " AMPLICOM DIFF". (length($ampS) - length($ampClean));
		my %hit = (
					name             => $nam,
					fasta            => $fasta,
					chrom            => $chrom,
					tag              => $tag,
					start            => $startPos,
					end              => $endPos,
					fwd              => $fwdS,
					fwdLen           => length($fwdS),
					rev              => $revS,
					revLen           => length($revS),
					amplicom         => $ampS,
					amplicomLen      => length($ampS),
					amplicomClean    => $ampClean,
					amplicomCleanLen => length($ampClean),
					amplicomDiff     => (length($ampS) - length($ampClean)),
					str              => $out
				   );
		push(@{$hash->{$nam}{$fasta}{$chrom}{$startPos}}, \%hit);
	} #end while my pair
}


sub rc
{
	my $seq = $_[0];
	$seq =~ tr/ACGT/TGCA/;
	$seq = reverse $seq;
	return $seq;
}
