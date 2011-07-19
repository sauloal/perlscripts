#!/bin/bash
INFILE=$1
#0                                                      1      2     3    4                                 5                                                                                                                               6
#sequence                                               strand start end  unique name                       commom name                                                                                                                     gene type
#supercontig_1.25_of_Cryptococcus_neoformans_Serotype_B +      611   667  53437GE_CneoSBc25_30001_34790     53437GE_CneoSBc25_30001_34790_s_PSO-60-0314|DIFF:-0.77|R265:-0.25|CBS7750:-1.02|WM276:-0.28|CORR:-0.19|ANNO:UNKNOWN.7008.7008   rna

#0                                                      1           2   3   4      5      6        7        8         9     10     11
#Chrom                                                  Position	Ref Var Reads1 Reads2 VarFreq  Strands1 Strands2  Qual1 Qual2  Pvalue
#supercontig_1.01_of_Cryptococcus_neoformans_Serotype_B 7           C   +A  1920   1940   50.26%   2        2         55    55     0.0

cat $INFILE | perl -ne '
BEGIN {my $count = 0;}
my @s = split(/\t/); 
if ( ! $count++ )
	{
		print "#sequence\tstrand\tstart\tend\tunique name\tcommom name\tgene type\n";
	} else { 
		my @out;
		$out[0] = $s[0]; #sequence
		$out[1] = "+";   # strand
		$out[2] = $s[1]; #start
		my $var = $s[3];
		$var =~ s/[^a-zA-Z]//g;
		$out[3] = $s[1] + length($var) - 1; #end
		#print "VAR $s[3] -> \"$var\" (",length($var),")\n";
		#print "START $s[1] VAR $var END $out[3]\n";
		$out[4] = "$s[0]_$s[1]_$s[2]"; #unique name
		$out[5] = "$s[0]|REF:$s[2]|VAR:$s[3]|FREQ:$s[6]|PVALUE:".sprintf("%.3g",$s[11]); #commom name
		$out[6] = "rna";  #seq type
		print join("\t", @out), "\n";
	}
' > $INFILE.tab
