INFASTA=$1
INMAF=$2

if [ ! $INFASTA ]
then
	echo "NO INPUT FASTA"
	exit 1
fi

if [ ! -e $INFASTA ]
then
	echo "INPUT FASTA $INMAF DOESNT EXISTS"
	exit 1
fi


if [ ! $INMAF ]
then
	echo "NO INPUT MAF"
	exit 1
fi

if [ ! -e $INMAF ]
then
	echo "INPUT MAF $INMAF DOESNT EXISTS"
	exit 1
fi

TOTAL=`grep -cE "^>" ${INFASTA}`

if [ ! $TOTAL ]
then
	echo "NO TOTAL"
	exit 1
fi

echo "INFASTA \"${INFASTA}\""
echo "INMAF   \"${INMAF}\""
echo "TOTAL   \"${TOTAL}\""

echo "RUNNING MAF2ND"
for ((i=1; i<=$TOTAL; i++))
do
	echo -e "\t$i out of $TOTAL"
	echo -e "\t\t./maf2nd.pl $INMAF $INFASTA $i"
	#./maf2nd.pl $INMAF $INFASTA $i
done
echo "MAF2ND PERFORMED"




echo "MERGING DATA"
	cd xml
	mkdir merged 2>/dev/null

	echo -e "\tMERGING XML"
		#cat $INMAF.nd.*.map.con.xml     > merged/$INMAF.nd.map.con.xml
		#cat $INMAF.nd.*.map.ref.xml     > merged/$INMAF.nd.map.ref.xml

	echo -e "\tMERGING TAB"
		#cat $INMAF.nd.*.map.ref.del.tab > merged/$INMAF.nd.map.ref.del.tab
		#cat $INMAF.nd.*.map.ref.evn.tab > merged/$INMAF.nd.map.ref.evn.tab
		#cat $INMAF.nd.*.map.ref.gap.tab > merged/$INMAF.nd.map.ref.gap.tab
		#cat $INMAF.nd.*.map.ref.ins.tab > merged/$INMAF.nd.map.ref.ins.tab
		#cat $INMAF.nd.*.map.ref.nda.tab > merged/$INMAF.nd.map.ref.nda.tab
		#cat $INMAF.nd.*.map.ref.snp.tab > merged/$INMAF.nd.map.ref.snp.tab
echo "DATA MERGED"





echo "FIXING MERGED"
	cd merged
	echo -e "\tFIXING XML"
		for file in *.xml
		do
			echo -e "\t\tXML FILE $file"
			cat $file | perl -ne '
			BEGIN { my $head; my $tail } 
			if ( ! defined $head ) 
			{ 
				#print "FIRST $_"; 
				$header = $_; 
				if ($header =~ /\<(\S+)/) 
				{ 
					$tail = "</$1"; 
					$head = "<$1"; 
				}
				print $header;
			} else {
				print if (( ! /$head/ ) && ( ! /$tail/ ))
			}
			END 
			{ 
				print "$tail>\n";
				#print "HEAD $head TAIL $tail\n"; 
			}' > $file.tmp
			rm $file
			mv $file.tmp $file
		done
	echo -e "\tXML FIXING"

	echo -e "\tFIXING TAB"
		for file in *.tab
		do
			echo -e "\t\tTAB FILE $file"
			cat $file | perl -ne '
			BEGIN { my $head; } 
			if ( ! defined $head ) 
			{ 
				#print "FIRST $_"; 
				$header = $_; 
				if ($header =~ /^\#/) 
				{ 
					$head = $header; 
				}
				print $header;
			} else {
				print if ( ! /$head/ )
			}' > $file.tmp
			rm $file
			mv $file.tmp $file
		done
	echo -e "\tTAB FIXING"
echo "MERGED FIXED"

echo "COMPLETED"

