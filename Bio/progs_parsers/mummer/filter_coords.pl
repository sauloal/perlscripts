#!/usr/bin/perl -w
use strict;
use warnings;

my $coordFile  = $ARGV[0];
my $deltaFile  = $ARGV[1];
my $PREFIX     = $ARGV[2];
my $FOLDER     = $ARGV[3];
my $FILE       = $ARGV[4];
my $REF        = $ARGV[5];
my $QUERY      = $ARGV[6];

print "./filter_coords.pl $coordFile $deltaFile $PREFIX $FOLDER $FILE $REF $QUERY\n";

if ( ! @ARGV )
{
	print 	"./filter_coords.pl "                                                            .
			"out/nucmer/OUT_nucmer_r265_velvetwh113/nucmer_r265_velvetwh113_filterR.coords " .
			"out/nucmer/OUT_nucmer_r265_velvetwh113/nucmer_r265_velvetwh113_filterR.delta "  .
			"out/nucmer/OUT_nucmer_r265_velvetwh113/nucmer_r265_velvetwh113 "                .
			"out/nucmer/ "                                                                   .
			"nucmer_r265_velvetwh113 "                                                       .
			"seqs/c_neo_r265.fasta "                                                         .
			"seqs/velvet_wh_11_3.fasta\n";
	die "PLEASE DEFINE FILE .coords TO BE USED";
};

if ( ! -f $coordFile ) { die "FILE   COORDFILE $coordFile DOESNT EXISTS"; };
if ( ! -f $deltaFile ) { die "FILE   DELTAFILE $deltaFile DOESNT EXISTS"; };
if ( ! -d $FOLDER    ) { die "FOLDER FOLDER    $FOLDER    DOESNT EXISTS"; };
if ( ! -f $REF       ) { die "FILE   REF       $REF       DOESNT EXISTS"; };
if ( ! -f $QUERY     ) { die "FILE   QUERY     $QUERY     DOESNT EXISTS"; };
# if ( ! -f $FILE      ) { die "FILE   FILE      $FILE      DOESNT EXISTS"; };

my %nodes;



open FILE, "<$coordFile" or die "COULD NOT OPEN FILE $coordFile";
while (<FILE>)
{
	if (/\|\s+(\S+)\s+(\S+)$/)
	{
 		#print "$1\t$2\n";
		$nodes{$1}{$2} = 1;
 		# = `column $file | grep NODE | gawk '{print $19}'`;
	}
	else
	{
 		#print;
	}
}
close FILE;

	# foreach my $chrom (sort keys %nodes)
	# {
	# 	print "$chrom\n";
	# 	my $count = 0;
	# 	my $size;
	# 	my $cov;
	# 	foreach my $node (keys %{$nodes{$chrom}})
	# 	{
	# 		$count++;
	# 		print "\t$count\t$node\n";
	# 		if ($node =~ /length\_(\d+)\_cov_(\S+)$/)
	# 		{
	# 			$size += $1;
	# 			$cov  += $2;
	# 		}
	# 	}
	# 	$cov = (int(($cov / $count)*100))/100;
	# 	my $length = int($size / $cov);
	# 	print "\n\tSIZE $size\tCOV $cov\tLEGTH $length\n";
	# }




open FILE, "<$deltaFile" or die "COULD NOT OPEN FILE $deltaFile";
my $on    = 0;
my $chrom = "";
my %delta;
while (<FILE>)
{
	chomp;
	if ( ! /^\d/ )
	{
		$on = 0;
		$chrom = "";
	}

	if (/^>(\S+)/)
	{
		$on    = 1;
		$chrom = $1
	}

	if ($on)
	{
		push(@{$delta{$chrom}}, $_);
	}
}
close FILE;


foreach my $chrom (sort keys %delta)
{
	open FILE, ">$PREFIX\_$chrom.delta" or die "COULD NOT OPEN DELTAFILE $deltaFile\_$chrom";
	#print "$chrom\n";
	print FILE `head -2 $deltaFile`;
	print FILE join("\r", @{$delta{$chrom}});
	close FILE;
	#print "\n\n";
	#print "$PREFIX\_$chrom.delta\n";
	#`./mummerplot --layout --color --large $PREFIX\_$chrom.delta -R $REF -Q $QUERY --prefix $PREFIX\_$chrom\_filterR       --png `;
	#`./mummerplot --layout --color --large $PREFIX\_$chrom.delta -R $REF -Q $QUERY --prefix $PREFIX\_$chrom\_SNP\_filterR  --png 1>/dev/null 2>/dev/null`;
}


foreach my $chrom (sort keys %nodes)
{
	open QUERY, "<$QUERY"     or die "COULD NOT READ QUERY $QUERY FILE";
	open TEMP,  ">$QUERY.tmp" or die "COULD NOT READ QUERY $QUERY.tmp FILE";
	my $on = 0;
	while (<QUERY>)
	{
		if ((/^>(\S+)/) && (exists $nodes{$chrom}{$1}))
		{
			$on = 1;
		}
		elsif (/^>/)
		{
			$on = 0;
		}

		if ($on)
		{
			print TEMP $_;
		}
	}
	close QUERY;
	close TEMP;


	open REF,  "<$REF"     or die "COULD NOT READ REFERENCE $REF FILE";
	open TEMP, ">$REF.tmp" or die "COULD NOT READ REFERENCE $REF.tmp FILE";

	$on = 0;
	while (<REF>)
	{
		if ((/^>(\S+)/) && ($1 eq $chrom))
		{
			$on = 1;
		}
		elsif (/^>/)
		{
			$on = 0;
		}

		if ($on)
		{
			print TEMP $_;
		}
	}
	close REF;
	close TEMP;

# 	die;
	print `./runsingle.sh $FOLDER $FILE\_$chrom $REF.tmp $QUERY.tmp 1`
}













# for element in $(seq 0 $((${#NODES[@]} -1)))
#  do
# 	NODE=${NODES[$element]}
# 	echo $NODE
# done

1;

