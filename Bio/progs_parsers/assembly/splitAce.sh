cat crypto_out.caf.ace | perl -w -ne 'BEGIN{ my %c; my $lastFh; print "BEGIN\n" } if (/^CO\s+(\S+)/) { print "HEADER \"$1\" ", $_;open(my $fh, ">crypto_out.caf.ace.$1.ace") or die; $c{$1} = $fh; print $fh $_; $lastFh = $fh; } else { if (defined $lastFh) { print "."; print $lastFh $_; } else { print "IGNORE ", $_;}} END { foreach my $key (keys %c) { print "CLOSING $key\n"; my $fh = $c{$key}; close $fh; }}'
ls -l *.ace.* | perl -ne '@sp = split(/\s+/, $_); open(FH, "<$sp[7]"); @l = <FH>; close FH;print "SIZE ",$sp[4]," NAME ",$sp[7]," LENG ", scalar @l, "\n"; open(FH, ">".$sp[7].".ace"); print FH "AS 1 ", $sp[4], "\n\n", join("", @l);'
