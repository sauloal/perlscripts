#!/usr/bin/perl -w
use strict;
use warnings;

my $file = $ARGV[0];

my $doit = 0;
open FILE, "<$file" || die "COULD NOT OPEN $file: $!";

my $count;
my $maxNN   = 0;my $maxNNt;
my $maxNode = 0;my $maxNodet;
my $maxN50  = 0;my $maxN50t;
my $maxMax  = 0;my $maxMaxt;

my $minNN   = 10000000;my $minNNt;
my $minNode = 10000000;my $minNodet;
my $minN50  = 10000000;my $minN50t;
my $minMax  = 10000000;my $minMaxt;

my %NN;
my %Node;
my %N50;
my %Max;
my %stat1;

my @resume = <FILE>;
for (my $i = 0; $i < @resume-1; $i++)
{
	$_ = $resume[$i];
	chomp $_;

	if (/^ \.\/velvetg (\S+)\//)
	{
# 		print "$1\t";

		my $next  = $resume[$i+1]; chomp $next;
		my $last  = $resume[$i+2]; chomp $last;
		my $file  = $1;
		my $fileS;
		if ($file     =~ /(\w+)_(\d+)_(\d+)_(\d+)_(\S+)_(\d+)_(\d+)/)
		{
			#$LKMER $LMIN $LMAX $LEXP $LDIV $LIND $LGAP
			$fileS = "$1\_$2\_$3\_$4\_$5";
		}
		my $node; my $n50; my $max;

		my $line = "$fileS $next $last";
		if ($next =~ /Final graph has (\d+) nodes and n50 of (\d+) max (\d+)/)
		{
			$node = $1;
			$n50  = $2;
			$max  = $3;
			push (@{$Node{$node}}, $line);
			push (@{$N50{$n50}},   $line);
			push (@{$Max{$max}},   $line);
		}
		if ($last =~ /^(\d+)$/)
		{
			push (@{$NN{$last}}, $line);
		}
		my $calc = int($last * ($n50 * (1/$node)));
		push (@{$stat1{$calc}}, "$fileS\t$node\t$n50\t$max\t$last");

	};
# 	if (/Writing into stats/) { $doit = 1; }
# 	if ((/Final graph has (\d+) nodes and n50 of (\d+) max (\d+)/) && ($doit))
	if (/Final graph has (\d+) nodes and n50 of (\d+) max (\d+)/)
	{
# 		print "$1\t$2\t$3\t";
# 		$doit = 0;
		my $next = $resume[$i+1]; chomp $next;

		if ($1 > $maxNode)
		{
			$maxNode  = $1;
			$maxNodet = "$_ $next";
		}
		if ($2 > $maxN50)
		{
			$maxN50   = $2;
			$maxN50t  = "$_ $next";
		}
		if ($3 > $maxMax)
		{
			$maxMax   = $3;
			$maxMaxt  = "$_ $next";
		}
		if ($1 < $minNode)
		{
			$minNode  = $1;
			$minNodet = "$_ $next";
		}
		if ($2 < $minN50)
		{
			$minN50   = $2;
			$minN50t  = "$_ $next";
		}
		if ($3 < $minMax)
		{
			$minMax   = $3;
			$minMaxt  = "$_ $next";
		}
	};
	if (/^(\d+)$/)
	{
# 		print "$1\n";
		my $prev = $resume[$i-1]; chomp $prev;
		if ($1 > $maxNN)
		{
			$maxNN  = $1;
			$maxNNt = "$prev $_ $1";
		}
		if ($1 < $minNN)
		{
			$minNN  = $1;
			$minNNt = "$prev $_ $1";
		}
	};
}

close FILE;

# printHash(\%NN,  "NN", "rev");
# printHash(\%Node,"NODE", "fwd");
# printHash(\%N50, "N50", "rev");
printHash(\%stat1, "stat1", "rev");
# printHash(\%Max, "MAX", "fwd");

print "\n\n";
print "MAX NODE\t$maxNode\t$maxNodet\n";
print "MIN NODE\t$minNode\t$minNodet\n";

print "MAX N50 \t$maxN50\t$maxN50t\n";
print "MIN N50 \t$minN50\t$minN50t\n";

print "MAX MAX \t$maxMax\t$maxMaxt\n";
print "MIN MAX \t$minMax\t$minMaxt\n";

print "MAX NN  \t$maxNN\t$maxNNt\n";
print "MIN NN  \t$minNN\t$minNNt\n";


sub printHash
{
	my %hash  = %{$_[0]};
	my $title = $_[1];
	my $sort  = $_[2];

	my @sorted;

	if ($sort eq "fwd")
	{
		@sorted = sort { $a <=> $b } (keys %hash);
	}
	elsif ($sort eq "rev")
	{
		@sorted = reverse sort { $a <=> $b } (keys %hash);
	}
	else
	{
		@sorted = ();
	}

	my $prev = "";
	foreach my $key (@sorted)
	{
		my $keys = @{$hash{$key}};
		for (my $i = 0; $i < $keys;$i++)
		{
			my $value = ${$hash{$key}}[$i];
			my $pre   = "$title\t$key\t" . ($i+1);
			my $line  = "\t$keys\t$value\n";
			if ( ! ($prev eq $line))
			{
				print "$title\t$key\t$value\n";
			}
			$prev     = $line;
		}
	}

	print "\n\n";

}