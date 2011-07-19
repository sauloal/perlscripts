#!/usr/bin/perl -w
# Saulo Aflitos
# 2009 05 27 11 43
use strict;
package folding;
use List::Util qw[min max];

#my $baseString;   = "GGTCGTACTGGGTACATTCCTTTAGGTGGTAAACCTAATACTGTTGTAGATGTTTCGCCTG";
#my $baseStringLen = length($baseString);
my $minProportion = 65;
my $spaceLength   = 4; # number of bases between the first two bonds
my %bonds         =	(GT=>0.3,TG=>0.3,AT=>2,TA=>2,CG=>3,GC=>3);
my @structure;
my @bases;
my @c;
my @s;

sub checkFolding
{
	my $baseString    = $_[0];
	if ( ! (defined $baseString)) { die "BASE STRING NOT DEFINED";};
	my $baseStringLen = length($baseString);
	my $maxBonds      = $baseStringLen * 3;

	@s         = ();
	@c         = ();
	@bases     = ();
	@structure = ();

	for (my $x = 0; $x < $baseStringLen+1; $x++)
	{
		for (my $y = 0; $y < $baseStringLen+1; $y++)
		{
			$c[$x][$y] = 0;
		}
	}

	my $hBonds         = &foldRna(\$baseString);
	#my $tracebackStr   = traceBack(1, length($baseString));
	#my $tracebackPos   = traceBackPos(1, length($baseString));
	#my $tracebackBonds = traceBackBonds(1, length($baseString));
	#print "$baseString\n$tracebackStr\n";
#	map { print "$_  " } split(//,($baseString));
#	print "\n";
#	map { if ($_ < 10) { print "0$_ " } else { print "$_ "} } (1 .. $baseStringLen);
	my $proportion = (int(($hBonds/($maxBonds / 2))*100));

	if ($proportion > $minProportion)
	{
		return $proportion;
	}
	else
	{
		return 0;
	}

	#print "\n$tracebackPos\n$tracebackBonds\n$hBonds BONDS\nMAX BONDS $maxBonds\nPROPORTION " . $proportion . "% \n\n";
	#printMatrix();
	#evalRnaStructure($baseString, $traceback);
}

sub foldRna
{
	my $s    = $_[0];
	my $slen = length($$s);
	#print "S: $s SLEN: $slen\n";
	@s = ('X',split(//,$$s));
	#print "SARRAY: " . join("",@s) . "\n";
	for (my $len = ($spaceLength+2); $len <= $slen; $len++)
	{
		for (my $i = 1; $i <= ($slen-$len+1); $i++)
		{
			my $j = $i + $len - 1;
			#print "LEN:$len I:$i J:$j\n";
			#print " C:" . $c[$i+1][$j];
			#print " BONDS:$s[$i]$s[$j] ";
			my $bondsT = $bonds{$s[$i].$s[$j]} || -3;

			#print $bonds;
			#print " C2:" . $c[$i+1][$j-1];
			#print "\n";
			$c[$i][$j] = max($c[$i+1][$j], $bondsT+$c[$i+1][$j-1]);
			for (my $k = $i+1; $k < $j; $k++)
			{
				#print "\tI: $i K: $k J: $j\n";
				#print "\tC1:" . @c . " C2:" . @{$c[$i]} . "\n";
				my $c1 = $c[$i][$j];
				my $c2 = $c[$i][$k]+$c[$k+1][$j];
				#print "\tC1:" . $c1 . " C2:" . $c2 . "\n";
				$c[$i][$j] = ($c1 > $c2) ? $c1 : $c2;
			} #end for my k
		} #end for my i
	} #end for my len
	#print "RETURN " . $c[1][$slen] . "\n";
	return $c[1][$slen];
}






sub printMatrix
{
	print "   ";
	for (my $y = 0; $y < @{$c[0]}; $y++)
	{
		print "  ";
		print $y < 10 ? "0$y" : $y;
	}
	print "\n";
	for (my $x = 0; $x < @c; $x++)
	{
		print "0$x " if ($x <  10);
		print "$x " if ($x >= 10);
		for (my $y = 0; $y < @{$c[$x]}; $y++)
		{
			print "  ";
			print $c[$x][$y] < 10 ? "0$c[$x][$y]" : $c[$x][$y];
		}
		print "\n";
	}
}

sub evalRnaStructure
{
	my ($basestring,$structurestring)= @_;
	@bases     = split(//,"5.$basestring.3");
	@structure = split(//,"($structurestring)");
	my $numBonds = evalRna(0,$#structure);
	print "$numBonds\n";
	return $numBonds;
}

sub evalRna
{
	my ($l,$r) = @_;

	my $numBonds = $bonds{$bases[$l].$bases[$r]} ? $bonds{$bases[$l].$bases[$r]} : 0;
	my $level = 0;
	my $ii = $l;
#	print join("",@bases)     . "\n";
#	print " " . join("",@structure) . "\n";

	for (my $i = $l+1; $i<$r;$i++)
	{
		$level-- if ($structure[$i] eq ")");
		if ($level == 0)
		{
			$numBonds += evalRna($ii,$i) if ($structure[$i] eq ")");
			$ii = $i;
		}
		$level++ if ($structure[$i] eq "(");
		print "$i\t $level" . $structure[$i] . "\n";
	}
#	print "$numBonds\n";
	return $numBonds;
}





sub traceBack
{
	my ($i,$j) = @_;
	my $cij = $c[$i][$j];
	return("."x($j-$i+1)) if ($cij == 0); # easy

	return "." . traceBack($i+1,$j) if ($cij == $c[$i+1][$j]); #foldrna 7

	my $bonds = $bonds{"$s[$i]$s[$j]"} ? $bonds{"$s[$i]$s[$j]"} : -1;
	return "(" . traceBack($i+1,$j-1) . ")" if ($cij == $bonds+$c[$i+1][$j-1]); #foldrna 8

	for (my $k = $i+1; $k<$j; $k++)
	{
		return traceBack($i,$k) . traceBack($k+1,$j) if ($cij == ($c[$i][$k]+$c[$k+1][$j])); #foldrna 10
	}
}

sub traceBackPos
{
	my ($i,$j) = @_;
	my $cij = $c[$i][$j];
	return("__ "x($j-$i+1)) if ($cij == 0); # easy

	return "__ " . traceBackPos($i+1,$j) if ($cij == $c[$i+1][$j]); #foldrna 7

	my $bonds = $bonds{"$s[$i]$s[$j]"} ? $bonds{"$s[$i]$s[$j]"} : -1;
	my $jStr = $j < 10 ? "0$j" : $j;
	my $iStr = $i < 10 ? "0$i" : $i;
	return "$jStr " . traceBackPos($i+1,$j-1) . "$iStr " if ($cij == $bonds+$c[$i+1][$j-1]); #foldrna 8

	for (my $k = $i+1; $k<$j; $k++)
	{
		return traceBackPos($i,$k) . traceBackPos($k+1,$j) if ($cij == ($c[$i][$k]+$c[$k+1][$j])); #foldrna 10
	}
}

sub traceBackBonds
{
	my ($i,$j) = @_;
	my $cij = $c[$i][$j];
	return("00 "x($j-$i+1)) if ($cij == 0); # easy

	return "00 " . traceBackBonds($i+1,$j) if ($cij == $c[$i+1][$j]); #foldrna 7

	my $bonds = $bonds{"$s[$i]$s[$j]"} ? $bonds{"$s[$i]$s[$j]"} : -1;
	my $bondsStr = $bonds < 1 ? "<1" : "0$bonds";
	return "$bondsStr " . traceBackBonds($i+1,$j-1) . "$bondsStr " if ($cij == $bonds+$c[$i+1][$j-1]); #foldrna 8

	for (my $k = $i+1; $k<$j; $k++)
	{
		return traceBackBonds($i,$k) . traceBackBonds($k+1,$j) if ($cij == ($c[$i][$k]+$c[$k+1][$j])); #foldrna 10
	}
}


1;
