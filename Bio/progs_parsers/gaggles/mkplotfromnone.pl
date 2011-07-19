#!/usr/bin/perl -w
use strict;
use lib "./";
use fasta;
use GD::Graph::pie;
use GD::Text;
#cat cbs7750_DE_NOVO_LAST.fasta | grep -v ">" | grep -E "N|n" | tr -d "ACGT" | wc -c
#650644
#cat R265_c_neoformans.fasta | grep -v ">" | grep -E "N|n" | tr -d "ACGT" | wc -c
#345741



my $forceCovInd = 0;
my $forceCovHor = 0;
my $forceCovPie = 1;
my $transparent = 0; #make background transparent or not

my $transparentStr = '' ;
if ( $transparent ) { $transparentStr = 'transparent' };

my $lineType = 'impulses';
  #dots
  #lines
  #steps
  #impulses
my $smooth = 'frequency';
  #unique
  #frequency
  #csplines
  #bezier
  #sbezier

my %gaps;
my %chroms;

  my $inRefFasta = $ARGV[0] || die;
  my $inRefTab   = $ARGV[1] || die;
  my $inQryTab   = $ARGV[2] || die;
  print "RUNNING WITH $inRefFasta $inRefTab $inQryTab\n";
  die if ( ! -f $inRefFasta );
  die if ( index($inRefFasta, ".fasta") == -1 );
  die if ( ! -f $inRefTab );
  die if ( index($inRefTab, ".tab") == -1 );
  die if ( ! -f $inQryTab );
  die if ( index($inQryTab, ".tab") == -1 );

  foreach my $pair (["ref", $inRefTab], ["qry", $inQryTab])
  {
	my $type = $pair->[0];
	my $file = $pair->[1];
	print "  READING $file [$type]\n";
	my $gaps;
	open IN, "<$file" or die;
	  while ( my $line = <IN> )
	  {
		chomp $line;
		my @cols = split(/\t/, $line);
		if ($cols[0] =~ /1\.(\d+)/)
		{
		  $chroms{$1}{name}{$type} = $cols[0];
		  $gaps++;
		  map { $gaps{$1}{$type}[$_] = 1; } ($cols[2]..$cols[3]);
		}
	  }
	close IN;
	print "    GAPS: $gaps\n";
  }

  my $name      = "$inRefTab\_$inQryTab";
     $name      =~ s/\.tab//g;

print "  GENERATING CHROMOSSOMES TABLE...\n";
my $fasta = fasta->new($inRefFasta);
my $stats = $fasta->getStat();
my $chromC;

foreach my $chrom (sort keys %$stats)
{
	if ($chrom =~ /1\.(\d+)/)
	{
	  my $size = $stats->{$chrom}{size};
	  $chroms{$1}{size} = $size;
	  $chromC++;
	}
}
print "    CHROMS: $chromC\n";

my %plotV;
my %plotH;
my $title       = "$inRefTab VS $inQryTab";
   $title       =~ s/\.tab//g;


&genIndividualChromoPlot();
&genPlotPie();
&genPlotFileHorizontal();
&genPlotFileVertical();
print "COMPLETED\n";
exit 0;

sub genPlotPie
{
  print "  GENERATING PIE OVERVIEW\n";

  my $outImgPAll  = "$name.pie.all.png";
  my $outImgPGap  = "$name.pie.gap.png";
  my $outImgDat   = "$name.pie.dat";
  my $covCumPos   = 1;
  my $lTitle      = $title;
  my %datData;

  if (( ! -f $outImgDat ) || ( $forceCovPie ))
  {
	print "    GENERATING PIE OVERVIEW :: READING PLOT FILES\n";
	my @total;
	my $sum = 0;
	foreach my $chromNum (sort {$a <=> $b} keys %plotV)
	{
	  my $cov = $plotV{$chromNum};
	  print "    READING $cov\n";
	  open IN, "<$cov" or die;
	  while (my $line = <IN>)
	  {
		chomp $line;
		next if ! $line;
		my @cols = split /\t/, $line;
		next if ! @cols;
		next if @cols == 1;
		$total[0] += $cols[1];
		$total[1] += $cols[2];
		$total[2] += $cols[3];
		$sum++;
	  }
	  close IN;
	  print "      READING $cov DONE\n";
	}
	print "    GENERATING PIE OVERVIEW :: READING PLOT FILES DONE\n";
	print "    GENERATING PIE OVERVIEW :: EXPORTING DAT FILE\n";
	my $ref    = $total[0];
	my $qry    = $total[1];
	my $shr    = $total[2];
	my $gapSum = $ref + $qry + $shr;

	my $rst    = ($sum - $gapSum);

	my $refPS  = ((int(($ref / $sum)*1000))/10);
	my $qryPS  = ((int(($qry / $sum)*1000))/10);
	my $shrPS  = ((int(($shr / $sum)*1000))/10);
	my $rstPS  = ((int(($rst / $sum)*1000))/10);

	my $refPR  = ((int(($ref / $gapSum)*1000))/10);
	my $qryPR  = ((int(($qry / $gapSum)*1000))/10);
	my $shrPR  = ((int(($shr / $gapSum)*1000))/10);

	%datData = (
	  ref    => $ref,
	  qry    => $qry,
	  shr    => $shr,
	  gapSum => $gapSum,
	  rst    => $rst,
	  rstPS  => $rstPS,
	  refPS  => $refPS,
	  qryPS  => $qryPS,
	  shrPS  => $shrPS,
	  refPR  => $refPR,
	  qryPR  => $qryPR,
	  shrPR  => $shrPR,
	  sum    => $sum
	);

	my $dat;
	my $fmt =            "      %-6s  "."%8d "."%3d.%1d%% "."%3d.%1d%%\n";
	$dat   .=            "      SOURCE  TOTAL    %TOTAL  %GAP\n";
	$dat   .= sprintf($fmt,     "REF",    $ref, int $refPS, (($refPS - int $refPS)*10), int $refPR, (($refPR - int $refPR)*10));
	$dat   .= sprintf($fmt,     "QRY",    $qry, int $qryPS, (($qryPS - int $qryPS)*10), int $qryPR, (($qryPR - int $qryPR)*10));
	$dat   .= sprintf($fmt,     "SHARED", $shr, int $shrPS, (($shrPS - int $shrPS)*10), int $shrPR, (($shrPR - int $shrPR)*10));
	$dat   .= sprintf($fmt,     "REST",   $rst, int $rstPS, (($rstPS - int $rstPS)*10),          0,                          0);
	$dat   .=             "      TOTAL  $sum\n\n";

	$dat .= "\n
ref    => $ref
qry    => $qry
shr    => $shr
gapSum => $gapSum
rst    => $rst
rstPS  => $rstPS
refPS  => $refPS
qryPS  => $qryPS
shrPS  => $shrPS
refPR  => $refPR
qryPR  => $qryPR
shrPR  => $shrPR
sum    => $sum
";

	open DAT, ">$outImgDat" or die;
	print DAT $dat;
	print     $dat;
	close DAT;
	print "    GENERATING PIE OVERVIEW :: EXPORTING DAT FILE DONE \n";
  } else {
	print "    GENERATING PIE OVERVIEW :: READING DAT FILE\n";
	open DAT, "<$outImgDat" or die;
	while (my $line = <DAT>)
	{
	  print $line;
	  chomp $line;
	  if ($line =~ /(\S+)\s+\=\>\s+(\S+)/)
	  {
		$datData{$1} = $2;
	  }
	}
	close DAT;
	print "    GENERATING PIE OVERVIEW :: READING DAT FILE DONE\n";
  }

  my $ref     = defined $datData{ref}    ? $datData{ref}    : die;
  my $qry     = defined $datData{qry}    ? $datData{qry}    : die;
  my $shr     = defined $datData{shr}    ? $datData{shr}    : die;
  my $gapSum  = defined $datData{gapSum} ? $datData{gapSum} : die;
  my $rst     = defined $datData{rst}    ? $datData{rst}    : die;
  my $rstPS   = defined $datData{rstPS}  ? $datData{rstPS}  : die;
  my $refPS   = defined $datData{refPS}  ? $datData{refPS}  : die;
  my $qryPS   = defined $datData{qryPS}  ? $datData{qryPS}  : die;
  my $shrPS   = defined $datData{shrPS}  ? $datData{shrPS}  : die;
  my $refPR   = defined $datData{refPR}  ? $datData{refPR}  : die;
  my $qryPR   = defined $datData{qryPR}  ? $datData{qryPR}  : die;
  my $shrPR   = defined $datData{shrPR}  ? $datData{shrPR}  : die;
  my $sum     = defined $datData{sum}    ? $datData{sum}    : die;


  print "    GENERATING PIE OVERVIEW :: GENERATING PIE PLOT\n";

  &mkPie({
	title   => $lTitle . " ALL",
	file    => $outImgPAll,
	headers => ["Gap Ref only ($ref $refPS%)", "Gap Qry only ($qry $qryPS%)", "Gap Shared ($shr $shrPS%)", "Equal ($rst $rstPS%)"],
	values  => [$ref,  $qry,  $shr, $rst]
  });
  &mkPie({
	title   => $lTitle . " GAP",
	file    => $outImgPGap,
	headers => ["ref only ($ref $refPR%)", "qry only ($qry $qryPR%)", "shared ($shr $shrPR%)"],
	values  => [$ref,  $qry,  $shr]
  });

  #&genPlotFile($outCovPAll, $outPlotHAll, $outImgHAll, $lTitle, $covCumPos, 1);
  #print OUT
  print "    GENERATING PIE OVERVIEW :: GENERATING PIE PLOT DONE\n";

  if ( ! -f $outImgPAll ) { die; };
  print "    GENERATING PIE OVERVIEW :: RUNNING GNUPLOT DONE\n";
  print "  GENERATING PIE OVERVIEW COMPLETED\n\n\n";
}


sub mkPie
{
  my $lTitle  = $_[0]->{title};
  my $oFile   = $_[0]->{file};
  my $headers = $_[0]->{headers};
  my $values  = $_[0]->{values};

  print " EXPORTING PIE $lTitle $oFile\n";

  my $chart = GD::Graph::pie->new(1024,768);
  $chart->set(
	title      => $lTitle,
	'3d'       => 0,
	showvalues => 1,
	label      => 1
  );
  $chart->set_value_font(['verdana', GD::gdLargeFont], 128);
  $chart->set_title_font(['verdana', GD::gdGiantFont], 128);

  my @dataset= (
	$headers,
	$values
  );

  my $image = $chart->plot(\@dataset) or die $chart->error;

  open IMG, ">$oFile" or die;
  binmode IMG;
  print IMG $image->png;
  close IMG;
}

sub genIndividualChromoPlot
{
  print "  GENERATING INDIVIDUAL PLOTS\n";
  foreach my $chromNum (sort keys %gaps)
  {
	my $lTitle      = "$title CHR $chromNum";
	print "    GENERATING INDIVIDUAL PLOTS :: PROCESSING $lTitle ";

	my $outCovFile  = "$name.$chromNum.cov";
	my $outPlotFile = "$name.$chromNum.plot";
	my $outImgFile  = "$name.$chromNum.png";
	my $size        = $chroms{$chromNum}{size};
	my $lChrom      = $gaps{$chromNum};

	$plotV{$chromNum} = $outCovFile;
	if (( ! -f $outCovFile ) || ( $forceCovInd ))
	{
	  print "      GENERATING INDIVIDUAL PLOTS :: $lTitle :: EXPORTING COVERAGE FILE $outCovFile\n";
	  &genCov($outCovFile, $size, $lChrom);
	  print "      GENERATING INDIVIDUAL PLOTS :: $lTitle :: EXPORTING COVERAGE FILE $outCovFile DONE\n";
	}

	print "      GENERATING INDIVIDUAL PLOTS :: $lTitle :: EXPORTING PLOT FILE\n";
	print "      $name $chromNum $lTitle $outCovFile $outPlotFile $outImgFile\n";
	&genPlotFile($outCovFile, $outPlotFile, $outImgFile, $lTitle, $size, 1);
	print "      GENERATING INDIVIDUAL PLOTS :: $lTitle :: EXPORTING PLOT FILE DONE\n";

	print "      GENERATING INDIVIDUAL PLOTS :: $lTitle :: RUNNING GNUPLOT\n";
	if (( -f $outPlotFile ) && ( -f $outCovFile ))
	{
	  print `gnuplot $outPlotFile`;
	} else {
	  die;
	}

	if ( ! -f $outImgFile ) { die; };
	print "      GENERATING INDIVIDUAL PLOTS :: $lTitle :: RUNNING GNUPLOT DONE\n";
	print "    GENERATING INDIVIDUAL PLOTS :: PROCESSING $lTitle DONE";
	#last if $chromNum == 2;
  }
  print "  GENERATING INDIVIDUAL PLOTS COMPLETED\n\n\n";
}

sub genPlotFileHorizontal
{
  print "  GENERATING HORIZONTAL OVERVIEW\n";
  my $outCovHAll  = "$name.allH.cov";
  my $outPlotHAll = "$name.allH.plot";
  my $outImgHAll  = "$name.allH.png";
  my $covCumPos   = 1;
  my $lTitle      = $title . " ALL";

  unlink($outCovHAll);

  if (( ! -f $outCovHAll ) || ( $forceCovHor ))
  {
	print "    GENERATING HORIZONTAL OVERVIEW :: GENERATING PLOT FILE\n";
	open OUT, ">$outCovHAll" or die;
	foreach my $chromNum (sort {$a <=> $b} keys %plotV)
	{
	  my $cov = $plotV{$chromNum};
	  print "    READING $cov\n";
	  open IN, "<$cov" or die;
	  while (my $line = <IN>)
	  {
		chomp $line;
		next if ! $line;
		my @cols = split /\t/, $line;
		next if ! @cols;
		next if @cols == 1;
		print OUT $covCumPos++, "\t", join("\t", @cols[1..@cols-1]), "\n";
	  }
	  close IN;
	  print "      READING $cov DONE\n";
	}
	close OUT;
	print "    GENERATING HORIZONTAL OVERVIEW :: GENERATING PLOT FILE DONE\n";
  }

  print "    GENERATING HORIZONTAL OVERVIEW :: GENERATING PLOT FILE\n";
  &genPlotFile($outCovHAll, $outPlotHAll, $outImgHAll, $lTitle, $covCumPos, 1);
  print "    GENERATING HORIZONTAL OVERVIEW :: GENERATING PLOT FILE DONE\n";

  print "    GENERATING HORIZONTAL OVERVIEW :: RUNNING GNUPLOT\n";
  if (( -f $outPlotHAll ) && ( -f $outCovHAll ))
  {
	print `gnuplot $outPlotHAll`;
  } else {
	die;
  }

  if ( ! -f $outImgHAll ) { die; };
  print "    GENERATING HORIZONTAL OVERVIEW :: RUNNING GNUPLOT DONE\n";
  print "  GENERATING HORIZONTAL OVERVIEW COMPLETED\n\n\n";
}

sub genPlotFileVertical
{
  print "  GENERATING VERTICAL OVERVIEW\n";
  my $outPlotVAll = "$name.allV.plot";
  my $outImgVAll  = "$name.allV.png";
  my $vSize       = (391 / 2 ) * ( $chromC + 1);
  my $tenthProp   = 1 / ($chromC + 1);

  print "    GENERATING VERTICAL OVERVIEW :: GENERATING PLOT FILE\n";
 #$plotH{$inCov} = [$title, $xSize, $ySize, $tenth];
  open OUT, ">$outPlotVAll";
  my $settings = <<CONF
set title "$title"
set output "$outImgVAll"
set terminal png size 2048,$vSize large font "/usr/share/fonts/default/ghostscript/putr.pfa,14" $transparentStr
set multiplot
CONF
;

  my $format   = &getPlotFormat();
  my $curProp  = 0;
  my $out;
  foreach my $cov (sort keys %plotH)
  {
	my $data    = $plotH{$cov};
	my $lTitle  = $data->[0];
	my $xSize   = $data->[1];
	my $ySize   = $data->[2];
	my $tenth   = $data->[3];
	$curProp   += $tenthProp;
	my $multi  =  "
####### START $cov ########
set origin 0, ". (1 - $curProp) . "
set size   1, ". $tenthProp     . "
set title \"$lTitle\"
"
;

	my $lSettings = <<CONF
set xrange [0:$xSize]
set yrange [0:$ySize]
set xtics $tenth

CONF
;
	my $lData = <<CONF
plot  '$cov' [0:$xSize] using 1:2 notitle with lines ls 2, \\
      '$cov' [0:$xSize] using 1:3 notitle with lines ls 3, \\
      '$cov' [0:$xSize] using 1:4 notitle with lines ls 4

CONF
;
	my $clear = "
unset xrange
unset yrange
unset xtics
unset title

####### END $cov ########
";
	$out .= $multi . $lSettings . $lData . $clear . "\n"x3;
  }

  my $close = "
unset multiplot
exit
";

  print OUT $settings, $format, $out, $close;
  close OUT;
  print "    GENERATING VERTICAL OVERVIEW :: GENERATING PLOT FILE DONE\n";

  print "    GENERATING VERTICAL OVERVIEW :: RUNNING GNUPLOT\n";
  if ( -f $outPlotVAll )
  {
	print `gnuplot $outPlotVAll`;
  } else {
	die;
  }

  if ( ! -f $outImgVAll ) { die; };
  print "    GENERATING VERTICAL OVERVIEW :: RUNNING GNUPLOT DONE\n";

  print "  GENERATING VERTICAL OVERVIEW COMPLETED\n\n\n";
}

sub genCov
{
  my $outFile = $_[0];
  my $max     = $_[1];
  my $lChrom  = $_[2];
  #&genCov($outCovFile, $size, $lChrom);
  #map { $gaps{$1}{$type}[$_] = $1 } ($cols[2]..$cols[3]);
  open OUT, ">$outFile" or die;

  print OUT "# reference-pos ref qry both\n";
  for (my $pos = 1; $pos <= $max; $pos++)
  {
	my $ref = $lChrom->{ref}[$pos];
	my $qry = $lChrom->{qry}[$pos];
	$ref = 0 if ( ! defined $ref );
	$qry = 0 if ( ! defined $qry );
	my $value = $ref + ($qry * -1);
	my $st = $ref && $qry ? 0 : $ref; #1+1=0 1+0=1 0+1=0 0+0=0
	my $nd = $ref && $qry ? 0 : $qry; #1+1=0 1+0=0 0+1=1 0+0=0
	my $rd = $ref && $qry ? 1 : 0;    #1+1=1 1+0=0 0+1=0 0+0=0

	print OUT    "$pos\t$st\t$nd\t$rd\n";
  }
  close OUT;
}




sub genPlotFile
{
  my $inCov         = $_[0];
  my $outPlotFile   = $_[1];
  my $outImgFile    = $_[2];
  my $lTitle        = $_[3];
  my $xSize         = $_[4];
  my $ySize         = $_[5];
  my $tenth         = int($xSize / 10);

  open OUT, ">$outPlotFile" or die;

  my $settings = <<CONF
set title "$lTitle"
set xrange [0:$xSize]
set yrange [0:$ySize]
set xtics $tenth
set output "$outImgFile"
set terminal png size 1024,391 large font "/usr/share/fonts/default/ghostscript/putr.pfa,12" $transparentStr
CONF
;

  my $format   = &getPlotFormat();

my $data = <<CONF

plot  '$inCov' [0:$xSize] using 1:2 notitle with lines ls 2, \\
      '$inCov' [0:$xSize] using 1:3 notitle with lines ls 3, \\
      '$inCov' [0:$xSize] using 1:4 notitle with lines ls 4

exit
CONF
;

  $plotH{$inCov} = [$lTitle, $xSize, $ySize, $tenth];
  print OUT $settings, $format, $data;
  close OUT;
}

sub getPlotFormat
{
  return <<CONF
set ylabel ""
set xlabel ""
set bars  large
set bars  4.0
set style fill empty

set grid
set format y ""
set format x "%.1le%L"
set palette model RGB
set pointsize 0.2
set ytics 1
set rmargin 5

set style line 2 lt rgb 'blue'  lw 1
set style line 3 lt rgb 'red'   lw 1
set style line 4 lt rgb 'black' lw 1
CONF
;

}


1;
