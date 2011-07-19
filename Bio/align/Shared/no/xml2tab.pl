#!/usr/bin/perl -w
use strict;

my $inFile = $ARGV[0];
die "NO INPUT FILE DEFINED"    if ( !    $inFile );
die "INPUT FILE DOESNT EXISTS" if ( ! -f $inFile );

open IN, "<$inFile" or die "COULD NOT OPEN $inFile: $!";

my %hash;
my $ignore = 0;
my $lHash = \%hash;
foreach my $line (<IN>)
{
	chomp $line;

	my $ignoreThis = 0;
	if ( $line =~ /\<\!--/ ) { $ignore = 1; $ignoreThis = 1; }
	if ( $line =~ /--\>/ )   { $ignore = 0;}
	next if ( $ignore || $ignoreThis );
	next if ( $line =~ /\<\?/);
	next if ( $line =~ /\<\!/);
	last if ( $line =~ /\<xsl\:stylesheet/);

	if ( $line =~ /\<(\S+).*?\>(.+)\<\/\1\>/ )
	{
		my $name  = $1;
		my $value = $2;
		$lHash->{$name} = $value;
		#print "SINGLETON $name => $value ME $lHash\n";
	}
	elsif ( $line =~ /\<\/(\S+)\>/ )
	{
		my $key = $1;
		#print "CLOSE $key ME $lHash PAR $lHash->{par}\n";
		$lHash = $lHash->{par};
	}
	elsif ( $line =~ /\<(\S+)(.*?)\>/ )
	{
		my $key = $1;
		my $nfo = $2;
		print ".";

		my $already = defined $lHash->{$key} ? scalar @{$lHash->{$key}} : 0;
		$lHash->{$key}[$already]{nfo} = $nfo;
		$lHash->{$key}[$already]{par} = $lHash;
		#print "OPEN $key [$nfo] ME $lHash SON ", $lHash->{$key}[$already],"\n";
		$lHash = $lHash->{$key}[$already];

	}
}
close IN;


use Data::Dumper;
$Data::Dumper::Indent    = 1;
$Data::Dumper::Purity    = 1;
$Data::Dumper::Quotekeys = 1;
#print Dumper \%hash;

my %dotHash;
printHash("root",\%hash, \%dotHash, 0);

#map { print $_ , " => " , $dotHash{$_} , "\n"; } sort keys %dotHash;





sub groupBy
{
	my $hash = $_[0];

	foreach my $key (sort keys %$hash)
	{
		my @values = split (/\./, $key);

		for (my $v = @values; $v > 0; $v--)
		{
			my $value = $dotHash{$key};
			printf "%30s => %s\n", $key, $value;
		}
	}
}

sub printHash
{
	my $par   = $_[0];
	my $h     = $_[1];
	my $dot   = $_[2];
	my $level = $_[3];

	my $indentation = "  "x$level . $level . " : ";

	if ( ref $h eq "HASH")
	{
		#print $indentation, "HASH ", scalar keys %$h,"\n";
		foreach my $key ( sort keys %$h )
		{
			next if ( $key eq "par" );
			#print $indentation, "HASH\tKEY $key\n";
			my $value = $h->{$key};
			next if ! defined $value;
			if ( ref $value eq "HASH" )
			{
				#print $indentation, "HASH\tKEY $key\tHASH",scalar keys %$value,"\n";
				#print $indentation, $key, "\n";
				&printHash("$par.$key", $value, $dot, $level+1);
			}
			elsif ( ref $value eq "SCALAR" )
			{
				#print $indentation, "HASH\tKEY $key\tSCALAR\n";
				#print $indentation, $key, " > ", $value, "\n";
			}
			elsif ( ref $value eq "ARRAY")
			{
				#print $indentation, "HASH\tKEY $key\tARRAY ",scalar @$value,"\n";
				for (my $a = 0; $a < @$value; $a++)
				{
					printHash("$par.$key.$a", $value->[$a], $dot, $level+1);
				}
			} else {
				#print $indentation, "HASH\tKEY $key\tVALUE\n";
				my $name = "$par.$key";
				#print $indentation, $name, " > ", $value, "\n";
				$dot->{$name} = $value;
				#print $indentation . "WTF V REF\"" . (ref $value) . "\" VALUE \"$value\"\n";
				#exit 1;
			}
		}
	}
	elsif ( ref $h eq "ARRAY")
	{
		#print $indentation, "ARRAY\n";
		for (my $a = 0; $a < @$h; $a++)
		{
			printHash("$par.$a",$h->[$a], $dot, $level);
		}
	} else {
		#print $indentation . "WTF H REF\"" . (ref $h) . "\" H \"$h\"\n";
		exit 1;
	}
}
