#!/usr/bin/perl -w
use strict;

my $seq        = "ACTGTCGTACTAGCTAGACTGACTGACTGACGACTGTCGTACTGTCGTACTAGCTAGACTGACTGACTGACGACTGTCGT";
my $run        = 1;
my $iterations = 500_000;
my $benchmark  = 1;
my $verbose    = 1;
if ($verbose) { $iterations = 1; $benchmark = 0; $run = 1; };

my %bases;
my @bins;
&loadVariables2();

if ($run)
{
	use dnaCode;
	my $time = time;
	for (my $i = 0; $i < $iterations; $i++)
	{
		print "SEQ BEFORE: ", $seq, " ",(length $seq),"\n" if ($verbose >= 1 );

		$seq = &dna2digit($seq);
		print "SEQ AFTER : ", $seq, " ",(length $seq), "\n" if ($verbose >= 1 );

		$seq = &digit2dna($seq);
		print "SEQ BACK  : ", $seq, " ",(length $seq), "\n\n" if ($verbose >= 1 );
	}
	my $final = time - $time;
	print "TIME1 = $final\n";


if ($benchmark)
{
	$time = time;
	for (my $i = 0; $i < $iterations; $i++)
	{
		print "SEQ BEFORE: ", $seq, " ",(length $seq),"\n" if ($verbose >= 2 );
		$seq = &dnaCode::dna2digit($seq);

		print "SEQ AFTER : ", $seq, " ",(length $seq), "\n" if ($verbose >= 2 );
		$seq = &dnaCode::digit2dna($seq);

		print "SEQ BACK  : ", $seq, " ",(length $seq), "\n" if ($verbose >= 2 );
	}
	$final = time - $time;
	print "TIME2 = $final\n";
}
}




sub loadVariables2
{
   $bases{"A"} = "00";
   $bases{"C"} = "10";
   $bases{"G"} = "01";
   $bases{"T"} = "11";

	while (my ($k, $v) = each %bases) { $bins[$v] = $k };
}


sub dna2digit
{
	my $pack = "";
	my $packLen = (length $_[0]);
	for (my $b = 0; $b < $packLen; $b++)
	{
		$pack .= $bases{substr($_[0], $b, 1)};
	}

	return pack "B".($packLen*2),$pack;
}

sub digit2dna
{
	my $unPackLen = length($_[0])*8;
	   $_[0]      = unpack "B".$unPackLen,$_[0];

	my $unPack = "";
	for (my $s = 0; $s < $unPackLen; $s+=2)
	{
		$unPack .= $bins[substr($_[0], $s, 2)];
	}

	return $unPack;
}

sub revComp($)
{
	my $sequence  = \$_[0];
	$$sequence    = uc($$sequence);
	$$sequence    = reverse($$sequence);
	$$sequence    =~ tr/ACTG/TGAC/;
	return $$sequence;
}


sub digit2digitrc($)
{
	my $digit = \$_[0];
	my $dna   = &revComp(&unpackB($$digit));
	return &packB($dna);
}





sub compDigit($$)
{
	my $digit1 = $_[0];
	my $digit2 = $_[1];

#	print "\tCOMPARING NORMAL vs NORMAL: ", $digit1, " WITH ", $digit2, "\n";
	if ($digit1 =~ /\Q$digit2/) { return 1; };
	if ($digit2 =~ /\Q$digit1/) { return 1; };


	my $digit2Rc  = &digit2digitrc($digit2);
	my $digit1Rc  = &digit2digitrc($digit1);
#	print "\tCOMPARING NORMAL vs RC: ", $digit1, " WITH ", $digit2Rc, "\n";
	if ($digit2Rc =~ /\Q$digit1/)   { return 2; };
	if ($digit1   =~ /\Q$digit2Rc/) { return 2; };


	my $digit1S;
	my $digit2S;
	($digit1S, ) = &splitDigit($digit1);
	($digit2S, ) = &splitDigit($digit2);
#	print "\tCOMPARING STRIPED vs STRIPED: ", $digit1S, " WITH ", $digit2S, "\n";
	if ($digit1S =~ /\Q$digit2S/) { return 3; };
	if ($digit2S =~ /\Q$digit1S/) { return 3; };



	my $digit1SRc = &digit2digitrc($digit1S);
	my $digit2SRc = &digit2digitrc($digit2S);
#	print "\tCOMPARING STRIPED vs NORMAL RC: ", $digit1S, " WITH ", $digit2Rc, "\n";
	if ($digit2Rc =~ /\Q$digit1S/)  { return 4; };
	if ($digit1Rc =~ /\Q$digit2S/)  { return 4; };
	if ($digit2S  =~ /\Q$digit1Rc/) { return 4; };
	if ($digit1S  =~ /\Q$digit2Rc/) { return 4; };



#	print "\tCOMPARING STRIPED vs STRIPED RC: ", $digit1S, " WITH ", $digit2SRc, "\n";
	if ($digit1    =~ /\Q$digit2SRc/) { return 5; };
	if ($digit2SRc =~ /\Q$digit1/)    { return 5; };

	return 0;
}



1;
