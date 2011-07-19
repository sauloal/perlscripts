#!/usr/bin/perl -w
use strict;
package dnaPack;
my $sysBits = 8;

sub unPackDNA
{
	my $bin    = $_[0];
	my $length = $_[1];
	my $strD;

	for (my $p = 0; $p < $length ; $p++)
	{
		$strD .= vec( $bin, $p, 2 );
	}

	$strD =~ tr/0123/ACGT/;

	return $strD;
}


sub packDNA
{
	my $inputD = $_[0];
	   $inputD =~ tr/ACGT/0123/;
	my $n      = length($inputD);
	my $bin    = 0 x ($n/4);

	for (my $p = 0; $p < $n; $p++)
	{
		vec($bin, $p,2) = substr($inputD, $p, 1);
	}

	return $bin;
}



sub packDNA0
{
	my $inputD = $_[0];
	   $inputD =~ tr/ACGT/0123/d;

	my $n      = length($inputD);

	my $bin    = '';
	my @bytes;
	print "INPU $inputD\n";
	for (my $p = 0; $p < $n; $p += 4)
	{
		my $nuc4 = substr($inputD, $p, 4);
		print "N $n P $p NUC4 $nuc4\n";
		my $byte = 0;
		for (my $pp = 0; $pp < 4; $pp++)
		{
			my $nucD = substr($nuc4, $pp, 1);
#			my $dig  = $corrArray[$nucD][$pp + 1];
#			print "\tNUCD $nucD DIG $dig\n";
#			$byte    = $byte | $dig;
		}
		
		print "BYTE $byte\n";
		push(@bytes, $byte);
	}
	print scalar(@bytes), " BYTES \n";
	for (my $b = 0; $b < @bytes; $b++)
	{
		print "\t\tB $b > $bytes[$b]\n";
		vec( $bin, $b, 8 ) = $bytes[$b];
	}
	print "$bin OUT ",length($bin),"bytes\n\n";
	return $bin;
}


sub unPackDNA2
{
	my $bin    = $_[0];
	my $length = $_[1];
	my $strD;
	my $strS;

	my $n = $length;
	
	for (my $p = 0; $p < $n ; $p++)
	{
		$strD .= vec( $bin, $p, 2 );
	}

	$strS = $strD;
	$strS =~ tr/0123/ACGT/;

	return $strS;
}


sub packDNA2
{
	my $input  = $_[0];
	my $inputD = $input;
	   $inputD =~ tr/ACGT/0123/d;

	my $n      = length($inputD);

	my $bin    = '';

	for (my $p = 0; $p < $n; $p++)
	{
		my $nucD      = substr($inputD, $p, 1);

		vec( $bin, $p, 2 ) = $nucD;
	}
	
	return $bin;
}


sub log_base {
	my ($base, $value) = @_;
	return log($value)/log($base);
}


sub nextBaseTwo
{
	my $in = $_[0];
	
	for ( my $log = &log_base(2, $in) ; $log - int($log) > 0 ; $log = &log_base(2, $in))
	{
	#    print "\&log_base(2, $in) = ",&log_base(2, $in),"\n";
		$in++
	};
	
	return $in;
}


1;
