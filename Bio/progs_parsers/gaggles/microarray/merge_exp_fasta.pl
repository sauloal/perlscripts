#!/usr/bin/perl -w
use strict;
my @fields;
my $sequenceField = "Sequence";

   $fields[0][0]  = "R265";
   $fields[0][1]  = "R265";
   $fields[0][2]  = \&roundExp;

   $fields[1][0]  = "CBS7750";
   $fields[1][1]  = "CBS7750";
   $fields[1][2]  = \&roundExp;

   $fields[2][0]  = "WM276";
   $fields[2][1]  = "WM276";
   $fields[2][2]  = \&roundExp;

   $fields[3][0]  = "Corr";
   $fields[3][1]  = "CORR";
   $fields[3][2]  = \&roundExp;

   $fields[4][0]  = "Annotation";
   $fields[4][1]  = "ANNO";
   #$fields[4][2]  = ;

my @formulas;
   $formulas[0][0] = ["CBS7750", "R265"];
   $formulas[0][1] = \&subtractFold;
   $formulas[0][2] = "DIFF";

my %thresholds = (
   'CBS7750' => "0.4",
   'CORR'    => "0.7",
   'R265'    => "0.4",
   'DIFF'    => "1.5"
	);



if ( ! @ARGV )
{
	die "USAGE: $0 <EXPRESSION XML FILE>"
}

my $expFile    = $ARGV[0];
my $outFile    = $expFile;
my $outFileAll = $expFile;
   $outFile    .= ".fasta";
   $outFileAll .= ".all.fasta";

if ( ! -f $expFile ) { die "EXPRESSION FILE $expFile WAS NOT FOUND"};

for (my $f = 0; $f < @formulas; $f++)
{
	unshift @fields, [undef, $formulas[$f][2]];
}

&openExp($expFile, $outFile, $outFileAll);


sub openExp
{
	my $inFile  = $_[0];
	my $ouFile  = $_[1];
	my $ouFileA = $_[2];

	print "OPENING $inFile AND SAVING IN $ouFile\n";
	open INFH, "<$inFile"  or die "COULD NOT OPEN IN  FASTA FILE: $inFile";
	open OUFH, ">$ouFile"  or die "COULD NOT OPEN OUT FASTA FILE: $ouFile";
	open OUFA, ">$ouFileA" or die "COULD NOT OPEN OUT FASTA FILE: $ouFileA";

	my $id       = undef;
	my %nfo;
	my $seq      = undef;
	my $count    = 1;
	while (my $line = <INFH>)
	{
		#print $line;
		chomp $line;
		if ( index($line, "<probe ") != -1 )
		{
			#print "PROBE :: $line\n";
			if ( $line =~ /\<probe id\=\"(\S+)\"\>/ )
			{
				$id = $1;
			} else {
				die "NO ID";
			}
			#print "\tID :: ", $id, "\n";
			undef %nfo;
		}
		elsif ( index($line, "</probe>") != -1 )
		{
			#print "/PROBE :: $line\n";

			if (( defined $id ) && (defined $seq) && ( scalar keys %nfo ))
			{
				#my $fold = int(($refField / $qryField) * 100) / 10;

				#my $foldRef   = &log2($refField);
				#my $foldQry   = &log2($qryField);


				for (my $f = 0; $f < @formulas; $f++)
				{
					my $fields = $formulas[$f][0];
					my $functi = $formulas[$f][1];
					my $name   = $formulas[$f][2];
					my $result = $functi->( map{ $nfo{$_} } @$fields);
					$nfo{$name} = $result;
				}


				my $invalid = 0;
				foreach my $tField (keys %thresholds)
				{
					if ( ! exists $nfo{$tField} )
					{
						$invalid++;
						last;
					}
					elsif ( ! &checkThreshold($nfo{$tField}, $thresholds{$tField}) )
					{
						$invalid++;
						last;
					}
				}

				my $header = ">".$count++." $id";
				for (my $f = 0; $f < @fields; $f++)
				{
					my $fNick = $fields[$f][1];
					my $value = $nfo{$fNick};
					$header  .= "|" . $fNick . ":" . $value;
				}

				if ( ! $invalid )
				{
					print      "$header\n";
					print OUFH "$header\n";
					print OUFH "$seq\n";
				} else {
					print OUFA "$header\n";
					print OUFA "$seq\n";
				}

				undef %nfo;
			} else {
				die "INCOMPLETE SET\n";
			}
		}
		else
		{ #else elsif /probe
			if ( index($line, "<$sequenceField>") != -1 )
			{
				#print "\tSEQUENCE :: $line\n";
				if ( $line =~ /\<$sequenceField\>(\S+)\<\/$sequenceField\>/ )
				{
					$seq = $1;
					#print "\tSEQUENCE :: $seq\n";
				}
			} else { #end if sequence
				for (my $f = 0; $f < @fields; $f++)
				{
					my $field = $fields[$f];
					next if ! defined $field;
					my $fName = $field->[0];
					next if ! defined $fName;
					my $fNick = $field->[1];
					my $fFunc = $field->[2];

					if ( index($line, "<$fName") != -1 )
					{
						#print "\t", uc($fName), " :: $line\n";
						if ( $line =~ /\<$fName\>(\S+)\<\/$fName\>/ )
						{
							my $value = $1;
							$nfo{$fNick} = $fFunc ? $fFunc->($value) : $value;
							#print "\t", uc($fName), " :: $value\n";
						}
						last;
					}
				}
			} #end if else sequence
		} #end else elsif /probe
	} # end while File
	close INFH;
	close OUFH;
	close OUFA;
	print "DONE\n";
}

sub subtractFold
{
	my $foldQry = $_[0];
	my $foldRef = $_[1];

	my $expChange;

	if    (($foldQry > 0) && ($foldRef > 0)) { $expChange =   $foldQry       -  $foldRef;       }   # 1  2 = 1-2                           = -1
																									# 2  1 = 2-1                           = +1
	elsif (($foldQry > 0) && ($foldRef < 0)) { $expChange =   $foldQry       + ($foldRef * -1); }   # 1 -1 = 1+(-1*-1)        =  1+1       = +2
	elsif (($foldQry < 0) && ($foldRef < 0)) { $expChange =   $foldQry       -  $foldRef;       }   #-1 -2 = -1--2            = -1+2       = +1
																									#-2 -1 = -2--1            = -2+1       = -1
	elsif (($foldQry < 0) && ($foldRef > 0)) { $expChange = (($foldQry * -1) +  $foldRef) * -1; }   #-1  1 = ((-1*-1) + 1)*-1 = (1 + 1)*-1 = +2*-1 = -2
	elsif ($foldQry == 0)                    { $expChange =   $foldRef * -1;                    }	# 0  1 = -1
																									# 0 -1 = +1
	elsif ($foldRef == 0)                    { $expChange =   $foldQry;                         }	# 1  0 = +1
																									#-1  0 = -1
	elsif ($foldQry == $foldRef)             { $expChange = 0;                                  }

	return &roundExp($expChange);
}


sub checkThreshold
{
	my $in = $_[0];
	my $t  = $_[1];
	return ( $in >= $t ) || ( $in <= ($t*-1) );
}

sub roundExp
{
	my $in = shift;
	return (int(($in >0 ? $in+.005 : $in-0.005) * 100) / 100);
}

sub log10 {
  my $n = shift;
  return log($n)/log(10);
}

sub log2 {
	my $n = shift;
	return (log($n)/log(2));
}

1;

#ROBIN FORMAT
	#<probe id="GE_CneoSBc10_102001_108000_s_PSO-60-0007">
	#	<Sequence>TGGGAGCAGAGGGTTGAGGATGAGCAGGAGAGATATGGGGATGAGAGTGGATGTGAGCAG</Sequence>
	#	<Annotation>CP000296_CGB_K4240W_UDP_N_acetylglucosamine_dolichyl_phosphate_N_acetylglucosaminephosphotransferase_putative_912491_914289.117976</Annotation>
	#	<CBS7750>-0.307992432</CBS7750>
	#	<R265>-0.374662956</R265>
	#	<WM276>-0.030697139</WM276>
	#	<Corr>-0.589300833</Corr>
	#</probe>



#CGH FORMAT
	#<probe id="162.m02150">
	#	<codeCN>CNI03990</codeCN>
	#	<codeNum>58270919</codeNum>
	#	<codeXM>XM_572616.1</codeXM>
	#	<codeXMFull>XM_572616_Filobasidiella neoformans hypothetical protein </codeXMFull>
	#	<codeGI>GI:58270919</codeGI>
	#	<pos>9:1067494..1068857</pos>
	#	<chrom>9</chrom>
	#	<geneId>GeneID:3259431</geneId>
	#	<genome_annott.codeM>162.m02150</genome_annott.codeM>
	#	<geneType>CDS</geneType>
	#	<origing>mRNA</origing>
	#	<class>Gene</class>
	#	<probeSeq>GCCGGCAAGTAGGGGTGTTGAGTCGTTGAAAAAGGTTAACACCAACAAGATGGCAAAATT</probeSeq>
	#	<H99AFLP1normalized>0.725 (0.616 to 0.863)</H99AFLP1normalized>
	#	<H99AFLP1normalizedmean>0.73</H99AFLP1normalizedmean>
	#	<H99AFLP1normalizedmin>0.62</H99AFLP1normalizedmin>
	#	<H99AFLP1normalizedmax>0.86</H99AFLP1normalizedmax>
	#	<H99AFLP1ttestpvalue>0.04</H99AFLP1ttestpvalue>
	#	<H991FL11fl1gs>1</H991FL11fl1gs>
	#	<RV64610AFLP1Anormalized>0.906 (0.878 to 0.926)</RV64610AFLP1Anormalized>
	#	<RV64610AFLP1Amean>0.91</RV64610AFLP1Amean>
	#	<RV64610AFLP1Amin>0.88</RV64610AFLP1Amin>
	#	<RV64610AFLP1Amax>0.93</RV64610AFLP1Amax>
	#	<RV64610AFLP1Attestpvalue>0.38</RV64610AFLP1Attestpvalue>
	#	<RV646101FL111fl1gs>0</RV646101FL111fl1gs>
	#	<RV58146AFLP1Bnormalized>0.873 (0.531 to 1.203)</RV58146AFLP1Bnormalized>
	#	<RV58146AFLP1Bmean>0.87</RV58146AFLP1Bmean>
	#	<RV58146AFLP1Bmin>0.53</RV58146AFLP1Bmin>
	#	<RV58146AFLP1Bmax>1.2</RV58146AFLP1Bmax>
	#	<RV58146AFLP1Bttestpvalue>0.63</RV58146AFLP1Bttestpvalue>
	#	<RV581461FL11Bfl1gs>0</RV581461FL11Bfl1gs>
	#	<B3501AFLP2normalized>1.188 (1.16 to 1.21)</B3501AFLP2normalized>
	#	<B3501AFLP2mean>1.19</B3501AFLP2mean>
	#	<B3501AFLP2min>1.16</B3501AFLP2min>
	#	<B3501AFLP2max>1.21</B3501AFLP2max>
	#	<B3501AFLP2ttestpvalue>0.17</B3501AFLP2ttestpvalue>
	#	<B35010FL12fl0gs>0</B35010FL12fl0gs>
	#	<JEC21AFLP2normalized>1144</JEC21AFLP2normalized>
	#	<JEC21AFLP2mean>1144</JEC21AFLP2mean>
	#	<JEC21AFLP2min>1144</JEC21AFLP2min>
	#	<JEC21AFLP2max>1144</JEC21AFLP2max>
	#	<JEC21AFLP2ttestpvalue>0.39</JEC21AFLP2ttestpvalue>
	#	<JEC210FL12fl0gs>0</JEC210FL12fl0gs>
	#	<CBS132AFLP3normalized>0.67 (0.623 to 0.715)</CBS132AFLP3normalized>
	#	<CBS132AFLP3mean>0.67</CBS132AFLP3mean>
	#	<CBS132AFLP3min>0.62</CBS132AFLP3min>
	#	<CBS132AFLP3max>0.72</CBS132AFLP3max>
	#	<CBS132AFLP3ttestpvalue>0.03</CBS132AFLP3ttestpvalue>
	#	<CBS1321FL13fl1gs>1</CBS1321FL13fl1gs>
	#	<E566AFLP4normalized>0.888 (0.824 to 0.952)</E566AFLP4normalized>
	#	<E566AFLP4mean>0.89</E566AFLP4mean>
	#	<E566AFLP4min>0.82</E566AFLP4min>
	#	<E566AFLP4max>0.95</E566AFLP4max>
	#	<E566AFLP4ttestpvalue>0.36</E566AFLP4ttestpvalue>
	#	<E5660FL14fl0gs>0</E5660FL14fl0gs>
	#	<CBS6955AFLP5normalized>1.002 (0.972 to 1.055)</CBS6955AFLP5normalized>
	#	<CBS6955AFLP5mean>1</CBS6955AFLP5mean>
	#	<CBS6955AFLP5min>0.97</CBS6955AFLP5min>
	#	<CBS6955AFLP5max>1.06</CBS6955AFLP5max>
	#	<CBS6955AFLP5ttestpvalue>1</CBS6955AFLP5ttestpvalue>
	#	<CBS69550FL05fl0gs>0</CBS69550FL05fl0gs>
	#	<CDCR265AFLP6normalized>1.019 (0.945 to 1.129)</CDCR265AFLP6normalized>
	#	<CDCR265AFLP6mean>1.02</CDCR265AFLP6mean>
	#	<CDCR265AFLP6min>0.95</CDCR265AFLP6min>
	#	<CDCR265AFLP6max>1.13</CDCR265AFLP6max>
	#	<CDCR265AFLP6ttestpvalue>0.83</CDCR265AFLP6ttestpvalue>
	#	<CDCR2650FL16fl0gs>0</CDCR2650FL16fl0gs>
	#	<WM779AFLP7normalized>1.175 (1.01 to 1.289)</WM779AFLP7normalized>
	#	<WM779AFLP7mean>1.18</WM779AFLP7mean>
	#	<WM779AFLP7min>1.01</WM779AFLP7min>
	#	<WM779AFLP7max>1.29</WM779AFLP7max>
	#	<WM779AFLP7ttestpvalue>0.14</WM779AFLP7ttestpvalue>
	#	<W07791FL17fl1gs>0</W07791FL17fl1gs>
	#	<AMC770616AFLP8normalized>1.289 (1.252 to 1.327)</AMC770616AFLP8normalized>
	#	<AMC770616AFLP8mean>1.29</AMC770616AFLP8mean>
	#	<AMC770616AFLP8min>1.25</AMC770616AFLP8min>
	#	<AMC770616AFLP8max>1.33</AMC770616AFLP8max>
	#	<AMC770616AFLP8ttestpvalue>0.76</AMC770616AFLP8ttestpvalue>
	#	<AMC7706160FL08fl0gs>0</AMC7706160FL08fl0gs>
	#	<CBS6093AFLPOutgroupnormalized>1.86 (1.536 to 2.078)</CBS6093AFLPOutgroupnormalized>
	#	<CBS6093AFLPOutgroupmean>1.86</CBS6093AFLPOutgroupmean>
	#	<CBS6093AFLPOutgroupmin>1.54</CBS6093AFLPOutgroupmin>
	#	<CBS6093AFLPOutgroupmax>2.08</CBS6093AFLPOutgroupmax>
	#	<CBS6093AFLPOutgroupttestpvalue>0.46</CBS6093AFLPOutgroupttestpvalue>
	#	<CBS60930FL0Outgrou0fl0gs>0</CBS60930FL0Outgrou0fl0gs>
	#</probe>
