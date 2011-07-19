INFILE=$1

cat $INFILE | perl -MSet::IntSpan::Fast -ane 'BEGIN { my %hash; } END{ map { print "$_ => ", $hash{$_}->as_string(), "\n"; } sort keys %hash; } next if (/^#/); next if ( ! $_ ); if ( ! exists $hash{$F[0]} ) { $hash{$F[0]} = Set::IntSpan::Fast->new(); };  print STDERR "$F[0] = $F[3] - $F[2]\n"; map{ $hash{$F[0]}->add($_)} ($F[2]..$F[3]); ' > $INFILE.span

cat $INFILE.span | perl -ne '
	BEGIN { $hash; } 
	END   { map { $sum += $hash{$_}; print "$_ => $hash{$_}\n"; } sort keys %hash; print "SUM => $sum\n"; } 
	chomp;
	$pos   = index($_, " => "); 
	$chrom = substr($_, 0, $pos);
	$data  = substr($_, $pos+4);
	@data  = split(",", $data);
	print STDERR "CHROM \"$chrom\" DATA \"$data\"\n";
	foreach my $pair ( @data )
	{
		$s = substr($pair, 0, index($pair, "-"));
		$e = substr($pair, index($pair, "-")+1);
		print STDERR "\tSTART $s END $e\n";
		$hash{$chrom} += $e - $s + 1;
	};
' 
