#!/usr/bin/perl -w
use strict;
use Set::IntSpan;

my $minimum        = 100;
my $fixBySd        = 1;  #fix output by 3xsd instead of maximum value
my $autoRun        = 1;  #execute gnuplot
my $mkPlot         = 1;  #read Files
my $mkIntermediary = 1;  #mk images
my $mkResume       = 1;  #mk resume graphic
my $correctResume  = 1;  #correct resume by 3x sd instead of maximum value
my $mkGaps         = 1;  #mk gaps output
my $minGapCov      = 20; #min gap coverage to merge in gap
my $resumeName     = 'resume';
my $transparent    = 0; #make background transparent or not
my $propMainGraph  = 0.85; #porportion between main graphic and overview


my $transparentStr = '' ;
if ( $transparent ) { $transparentStr = 'transparent' };

my $propSecGraph = 1- $propMainGraph;

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

my %resume;
my %gaps;


foreach my $inFile (@ARGV)
{
  die if ( ! -f $inFile );
  die if ( index($inFile, ".cov") == -1 );

  $gaps{$inFile} = Set::IntSpan->new();

  &mkPlotFile($inFile) if ( $mkPlot );
}

if ( $mkGaps && $mkPlot )
{
  &mkGaps(\%gaps);
}

if ($mkResume && $mkPlot )
{
  &mkResume(\%resume, $resumeName);
}








sub mkGaps
{
  my $gaps = $_[0];
  print "MAKING GAPS\n";
  my $allOut = $resumeName.".gap";

  open ALL, ">$allOut" or die "COULD NOT OPEN \"$allOut\": $!";

  foreach my $chrom (sort keys %$gaps)
  {
    print "\tCROM $chrom\n";
    my $chromName = $chrom;
       $chromName =~ s/\.cov//;
    my $outFile   = $chrom;
       $outFile   =~ s/\.cov/.gap/;
    open FILE, ">$outFile" or die "COULD NOT OPEN \"$outFile\": $!";
    print FILE "$chromName :: ",$gaps->{$chrom}->run_list,"\n";
    print ALL  "$chromName :: ",$gaps->{$chrom}->run_list,"\n";
    print  "\t\t$chromName :: ",$gaps->{$chrom}->run_list,"\n";
    close FILE;
  }

  close ALL;
  #cat $INFILE | perl -M-ne ' BEGIN {$interval =  } END { print $interval->run_list, "\n" } if ((/(\d+)\s+(\d+)/) && (  }'
}


sub mkPlotFile
{
  my $inFile = $_[0];
  print "ANALIZING $inFile\n";

  my $title     = $inFile;
     $title     =~ s/\.cov//;
  my $outFile   = $inFile;
     $outFile   =~ s/\.cov/.plot/;
  my $outImg    = $inFile;
     $outImg    =~ s/\.cov/.png/;


  my $fileSize = `wc -l $inFile`;

  if ($fileSize =~ /^(\d+)/)
  {
    $fileSize = $1;
  } else {
    die;
  }

  my $maxCov = 0;
  my $minCov = 999999999;
  my $sumCov = 0;
  open IN, "<$inFile" or die;
  while (my $line = <IN>)
  {
    chomp $line;
    if ($line =~ /(\d+)\s+(\d+)/)
    {
      if ( $2 > $maxCov ) { $maxCov = $2; };
      if ( $2 < $minCov ) { $minCov = $2; };
      $sumCov += $2;
      if ( $2 <= $minGapCov ) { $gaps{$inFile}->insert($1); }; # print "ADDING \"$inFile\" \"$line\" \"$1\"\n";
    }
  }
  close IN;

  my $avgCov = int(($sumCov / $fileSize)+.5) || 0;

  my $sdSum = 0;
  open IN, "<$inFile" or die;
  while (my $line = <IN>)
  {
    if ($line =~ /\d+\s+(\d+)/)
    {
      $sdSum += ($1 - $avgCov)**2;
    }
  }
  close IN;

  my $sd        = int(sqrt($sdSum / $fileSize)+.5);
  my $sdProp    = int(($sd / ($avgCov || 1)) * 100) || 0;
  my $sdMax     = $sdProp > 100 ? $avgCov + (2*$sd) : $avgCov + (3*$sd);
  if ($sdMax > (3 * $avgCov)) { $sdMax = (3 * $avgCov) };
  my $oldMaxCov = $maxCov;

  if ($fixBySd && ($maxCov > $sdMax))
  {
    $maxCov = $sdMax;
  }

  if    ($maxCov < $minimum ) { $maxCov = $minimum; };
  if    ($maxCov < 100      ) { $maxCov = 100 }
  elsif ($maxCov < 1000     ) { while ( $maxCov % 100  ) { $maxCov++ } }
  elsif ($maxCov < 10000    ) { while ( $maxCov % 1000 ) { $maxCov++ } }
  elsif ($maxCov < 100000   ) { while ( $maxCov % 1000 ) { $maxCov++ } }

  $resume{$title}{min}   = $minCov;
  $resume{$title}{max}   = $oldMaxCov;
  $resume{$title}{sd}    = $sd;
  $resume{$title}{sdMax} = $sdMax;
  $resume{$title}{sum}   = $sumCov;
  $resume{$title}{avg}   = $avgCov;
  $resume{$title}{size}  = $fileSize;

  print "\tNAME \"$inFile\" SIZE \"$fileSize\" ORIGMAX \"$oldMaxCov\" NEWMAX \"$maxCov\" MIN \"$minCov\" SUM \"$sumCov\" AVG \"$avgCov\" SD \"$sd\" 3SDMAX \"$sdMax\"\n";

  if ($mkIntermediary)
  {
    print "\t\tEXPORTING $inFile\n";
    &genPlotFile($inFile, $outFile, $outImg, $title, $fileSize, $maxCov, $avgCov, $sd, $oldMaxCov, $minCov, $propMainGraph, $propSecGraph);
    if ($autoRun)
    {
      if ( -f $outFile )
      {
		print `gnuplot $outFile`;
      }
    }
  }
}




sub genPlotFile
{
  my $inFile        = $_[0];
  my $outPlotFile   = $_[1];
  my $outImgFile    = $_[2];
  my $title         = $_[3];
  my $xSize         = $_[4];
  my $ySize         = $_[5];
  my $avg           = $_[6];
  my $sd            = $_[7];
  my $max           = $_[8];
  my $min           = $_[9];
  my $propMainGraph = $_[10];
  my $propSecGraph  = $_[11];

  my $sdProp       = int(($sd / ($avg || 1)) * 100) || 0;
  my $avgPlusSdCov =     ($avg + $sd) || 0;
  my $avgMinSdCov  =     ($avg - $sd) || 0;
  my $split        = int($ySize / 2);

  open OUT, ">$outPlotFile" or die;

  print OUT <<CONF
set title "$title"
set ylabel "coverage depth"
set xrange [0:$xSize]
set yrange [0:$ySize]
set bars large

set label "AVG COV     : $avg"            at graph 0.05,0.98 front left
set label "STD DEV COV : $sd ($sdProp%)"  at graph 0.05,0.95 front left
set label "MAX COV     : $max"            at graph 0.05,0.92 front left
set label "MIN COV     : $min"            at graph 0.05,0.89 front left
set label "LENG REF    : $xSize"          at graph 0.05,0.86 front left

set style line 1 lt rgb 'red'   lw 1
set style line 2 lt rgb 'black' lw 3
set style line 3 lt rgb 'red'   lw 2
set style line 4 lt rgb 'black' lw 1

set grid
set format x ""
set palette model RGB
set pointsize 0.5
set origin 0, $propSecGraph
set size   1, $propMainGraph
set bmargin 0

set terminal png size 1024,768 large font "/usr/share/fonts/default/ghostscript/putr.pfa,12" $transparentStr
set output "$outImgFile"

set multiplot

plot '$inFile' using 1:2 notitle with $lineType ls 1
unset label 1
unset label 2
unset label 3
unset label 4
unset label 5
set ylabel " "
set title " "

plot [0:$xSize] $avgPlusSdCov notitle with lines ls 2
plot [0:$xSize] $avg          notitle with lines ls 2
plot [0:$xSize] $avgMinSdCov  notitle with lines ls 2

unset title
set format x
set ylabel " "
set tmargin 0
set bmargin
set origin  0, 0
set size    1, $propSecGraph
set xlabel "position reference"
set ytics $split
plot '$inFile' using 1:2 notitle with steps smooth $smooth ls 3
plot [0:$xSize] $avg     notitle with lines ls 4

unset multiplot

exit

CONF
;

  close OUT;

}

sub mkResume
{
  my $hash = $_[0];
  my $name = $_[1];
  print "MAKING RESUME $name\n";

  my $gAvg    = 0;
  my $gSum    = 0;
  my $gMin    = 9999999;
  my $gMax    = 0;
  my $gSd     = 0;
  my $gSdMax  = 0;
  my $gSize   = 0;
  my $gAvgMin = 0;
  my $gAvgMax = 0;

  my $plotStr;
  my $c = 1;

  foreach my $title (sort keys %$hash)
  {
    my $min   = $hash->{$title}{min};
    my $max   = $hash->{$title}{max};
    my $sd    = $hash->{$title}{sd};
    my $sdMax = $hash->{$title}{sdMax};
    my $sum   = $hash->{$title}{sum};
    my $avg   = $hash->{$title}{avg};
    my $size  = $hash->{$title}{size};

    my $maxD  = $correctResume ? $sdMax : $max;
    $gMin     = $min if $min < $gMin;
    $gMax     = $max if $max > $gMax;
    $gAvgMin += $min;
    $gAvgMax += $max;
    $gSd     += $sd;
    $gSdMax  += $sdMax;
    $gSum    += $avg;
    $gSize   += $size;

    print "\tCHROM \"$title\" MIN \"$min\" MAX \"$max\" SD \"$sd\" SDMAX \"$sdMax\" SUM \"$sum\" AVG \"$avg\" SIZE \"$size\"\n";

    $plotStr .= "$c " . ($avg-$sd) . " $min " . $maxD . " " . ($avg+$sd) . " $avg $title\n";
    $c++;
  }

  my $total = $c - 1;

  $gAvg    = $total ? int(($gSum    / $total)+.5) : 0;
  $gSd     = $total ? int(($gSd     / $total)+.5) : 0;
  $gSdMax  = $total ? int(($gSdMax  / $total)+.5) : 0;
  $gAvgMin = $total ? int(($gAvgMin / $total)+.5) : 0;
  $gAvgMax = $total ? int(($gAvgMax / $total)+.5) : 0;

  if ($plotStr)
  {
    open OUTDAT, ">$name.dat" or die;
    print OUTDAT $plotStr;
    close OUTDAT;

    open OUTPLOT, ">$name.plot" or die;
    print OUTPLOT <<PLOT
set bars     4.0
set style    fill empty
set title   "RESUME"
set xlabel  "chromossome"
set ylabel  "coverage"
set xtics   1

set label "AVG COV         : $gAvg"      at graph 0.05,0.95 front left
set label "AVG STD DEV COV : $gSd"       at graph 0.05,0.92 front left
set label "MAX COV         : $gMax"      at graph 0.05,0.89 front left
set label "AVG MAX COV     : $gAvgMax"   at graph 0.05,0.86 front left
set label "MIN COV         : $gMin"      at graph 0.05,0.83 front left
set label "AVG MIN COV     : $gAvgMin"   at graph 0.05,0.80 front left
set label "LENG REF        : $gSize"     at graph 0.05,0.77 front left

set terminal png size 1024,768 large font "/usr/share/fonts/default/ghostscript/putr.pfa,12" $transparentStr
set output "$name.png"

plot  "$name.dat" [0:$total] using 1:2 notitle with lines, \\
      "$name.dat" [0:$total] using 1:6 notitle with lines, \\
      "$name.dat" [0:$total] using 1:5 notitle with lines, \\
      "$name.dat" [0:$total] using 1:2:3:4:5 notitle with candlesticks

PLOT
;
    close OUTPLOT;

    print `gnuplot $name.plot`;
  }
  #print "echo -e 'set boxwidth -2;\\nplot $plotStr notitle with boxerrorbars' | gnuplot\n";
}

1;
