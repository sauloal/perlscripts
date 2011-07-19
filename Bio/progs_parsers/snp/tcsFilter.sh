INTCS=crypto_out.tcs
INTCSCLEAN=$INTCS'.clean'
INTCSEVENTS=$INTCSCLEAN'.events'
RMALL=0
MKCLEAN=0
MKEVENTS=0
MKNORNAL=0
MKLQ=0
MKTAGS=0
MKTAG=0
MKSNP=1
MKSUMMARY=1
MOVE=1

    #    Short deletions (1 to 10 bases): they'll be tagged SROc or WRMc. General
    #    rule: deletions of up to 10 to 12% of the length of your read should be
    #    found and tagged without problem by MIRA, above that it may or may not,
    #    depending a bit on coverage, indel distribution and luck.
    #
    #    Long deletions (longer than read length): they'll be tagged with MCVc
    #    tag by MIRA ins the consensus. Additionally, when looking at the FASTA
    #    files when running the CAF result through convert_project: long stretches
    #    of sequences without coverage (the @ sign in the FASTAs) of X show
    #    missing genomic DNA.

if [ $RMALL -eq 1 ]; then
    echo DELETING ALL
    rm -f $INTCSCLEAN  2>/dev/null
    rm -f $INTCSCLEAN* 2>/dev/null
fi



if [ $MKCLEAN -eq 1 ]; then
    echo MAKING CLEAN
    rm -f $INTCSCLEAN 2>/dev/null
    cat $INTCS                   | tr -d   "\015"       > $INTCSCLEAN
fi



if [ $MKEVENTS -eq 1 ]; then
    echo MAKING EVENTS
    rm -f $INTCSEVENTS 2>/dev/null
    cat $INTCSCLEAN              | grep    "\!"         > $INTCSEVENTS
fi



if [ $MKNORNAL -eq 1 ]; then
    echo MAKING NORMAL
    rm -f $INTCSCLEAN'.normal' 2>/dev/null
    cat $INTCSCLEAN              | grep -v "\!"         > $INTCSCLEAN'.normal'
fi



if [ $MKLQ -eq 1 ]; then
    echo MAKING LOW QUALITY
    rm -f $INTCSEVENTS'.low_quality'  2>/dev/null
    rm -f $INTCSEVENTS'.low_quality'* 2>/dev/null
    cat $INTCSEVENTS             | grep "\!m"           > $INTCSEVENTS'.low_quality'
    cat $INTCSEVENTS.low_quality | grep -Ev "STMU|STMS" > $INTCSEVENTS'.low_quality.pure'
    cat $INTCSEVENTS.low_quality | grep -E  "STMU|STMS" > $INTCSEVENTS'.low_quality.STM'
fi



if [ $MKTAGS -eq 1 ]; then
    echo MAKING TAGS
    rm -f $INTCSEVENTS.tags           2>/dev/null
    rm -f $INTCSEVENTS.tags*          2>/dev/null
    rm -f $INTCSEVENTS'.no_tags'      2>/dev/null
    rm -f $INTCSEVENTS'.no_tags.no_N' 2>/dev/null
    cat $INTCSEVENTS             | grep '\!\$'          > $INTCSEVENTS'.tags'
    cat $INTCSEVENTS.tags        | grep "*"             > $INTCSEVENTS'.tags.gaps'
    cat $INTCSEVENTS.tags        | grep -v "*"          > $INTCSEVENTS'.tags.others'
    cat $INTCSEVENTS | grep -v "WRM" | grep -v "SRM" | grep -v "STMS" | grep -v "STMU" | grep -v "IUPc" > $INTCSEVENTS'.no_tags'
    cat $INTCSEVENTS'.no_tags' | gawk '$5 !~ /N/ { print }' > $INTCSEVENTS'.no_tags.no_N'
fi



if [ $MKTAG -eq 1 ]; then
    echo MAKING TAG
    rm -f $INTCSEVENTS'.tag.'* 2>/dev/null
    cat $INTCSEVENTS | grep "WRM"                  > $INTCSEVENTS'.tag.wrm'
    cat $INTCSEVENTS | grep "SRM"                  > $INTCSEVENTS'.tag.srm'
	cat $INTCSEVENTS | grep "RM"                   > $INTCSEVENTS'.tag.rm'
    cat $INTCSEVENTS | grep "STMS"                 > $INTCSEVENTS'.tag.stms'
    cat $INTCSEVENTS | grep "STMU"                 > $INTCSEVENTS'.tag.stmu'
	cat $INTCSEVENTS | grep "STM"                  > $INTCSEVENTS'.tag.stm'
    cat $INTCSEVENTS | grep "IUPc"                 > $INTCSEVENTS'.tag.iupac'
    cat $INTCSEVENTS | grep "IUPc" | grep -v "STM" > $INTCSEVENTS'.tag.iupac.noSTM'
    cat $INTCSEVENTS | grep "IUPc" | grep    "STM" > $INTCSEVENTS'.tag.iupac.STM'
    cat $INTCSEVENTS | grep "UNS"                  > $INTCSEVENTS'.tag.uns'
    cat $INTCSEVENTS | grep "DGP"                  > $INTCSEVENTS'.tag.dgp'
    cat $INTCSEVENTS | grep "S[A|R|I]O"            > $INTCSEVENTS'.tag.so'
    cat $INTCSEVENTS | grep "MCV"                  > $INTCSEVENTS'.tag.mcv'
    cat $INTCSEVENTS | grep "MNR"                  > $INTCSEVENTS'.tag.mnr'
    cat $INTCSEVENTS | grep "FpAS"                 > $INTCSEVENTS'.tag.fpas'
    cat $INTCSEVENTS | grep "ED_"                  > $INTCSEVENTS'.tag.ed'
    cat $INTCSEVENTS | grep "HAF"                  > $INTCSEVENTS'.tag.haf'
fi

if [ $MKSNP -eq 1 ]; then
	echo MAKIN SNP
    cat $INTCSEVENTS'.low_quality.STM' > $INTCSCLEAN'.snp'
	cat $INTCSEVENTS'.no_tags.no_N'   >> $INTCSCLEAN'.snp'
	cat $INTCSEVENTS'.tag.iupac'      >> $INTCSCLEAN'.snp'
	cat $INTCSEVENTS'.tag.srm'        >> $INTCSCLEAN'.snp'
	cat $INTCSEVENTS'.tag.stm'        >> $INTCSCLEAN'.snp'
	sort -u $INTCSCLEAN'.snp'          > $INTCSCLEAN'.snp.u.tcs'
fi

if [ $MKSUMMARY -eq 1 ]; then
    echo MAKING SUMMARY
    rm -f $INTCSCLEAN'.summary' 2>/dev/null
    ls $INTCSCLEAN* | xargs wc -l > $INTCSCLEAN'.summary'
    cat $INTCSCLEAN'.summary'
fi

if [ $MOVE -eq 1 ]; then
    echo MOVING TMP FILES
	mkdir tmp 2>/dev/null
	mv $INTCSCLEAN.* tmp/
	mv tmp/$INTCSCLEAN'.summary' .
	mv tmp/$INTCSCLEAN'.snp'     .
	mv tmp/$INTCSCLEAN'.snp.u.tcs'   .

fi

echo COMPLETED

