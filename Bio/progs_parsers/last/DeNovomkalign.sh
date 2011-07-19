#!/bin/bash
#./DeNovomkalign.sh "seqs/c_neo_r265/c_neo_r265_*.fasta" r265 "_of_Cryptococcus_neoformans_Serotype_B" "seqs/crypto2.soap.denovo.scafSeq.gapclosed/crypto2.soap.denovo.scafSeq.gapclosed*.fasta" cbs7750v5 "_cryptococcus_gattii_CBS7750v5" 1 28
#crypto2.soap.denovo.scafSeq.gapclosed


SRCSEQFOLDER=seqs
QUERYFOLDER=crypto2.soap.denovo.scafSeq.gapclosed/crypto2.soap.denovo.scafSeq.gapclosed_
TARGETFOLDER=c_neo_r265/c_neo_r265_
QUERYNAME=denovo2
TARGETNAME=r265
OUTNAME=r265_vs_denovo2
CHROMMIN=1
CHROMMAX=28
EPITOPEFASTA=CBS7750_SOAP_DE_NOVO2
HTML="display_$QUERYNAME.html"


#FOLDER=seqs
#QUERYFOLDER=crypto2.soap.denovo.scafSeq/crypto2.soap.denovo.scafSeq_
#TARGETFOLDER=c_neo_r265/c_neo_r265_
#QUERYNAME=denovo
#TARGETNAME=r265
#OUTNAME=r265_vs_denovo
#CHROMMIN=1
#CHROMMAX=28
#EPITOPEFASTA=CBS7750_SOAP_DE_NOVO


mkdir $QUERYNAME 2>/dev/null
mkdir db         2>/dev/null

echo "###################################"
echo "MAPPING"
echo "###################################"

echo "MAPPING :: CREATING DB"
CMD="./lastdb -v db/$TARGETNAME $SRCSEQFOLDER/$TARGETFOLDER*.fasta"
echo -e "\t$CMD"
#eval $CMD

echo "MAPPING :: CREATING KEY COUNT"
CMD="./lastdb -x $QUERYNAME/ref $SRCSEQFOLDER/$TARGETFOLDER*.fasta"
echo -e "\t$CMD"
#eval $CMD
CMD="./lastdb -x $QUERYNAME/qry $SRCSEQFOLDER/$QUERYFOLDER*.fasta"
echo -e "\t$CMD"
#eval $CMD

echo "MAPPING :: LASTING"
CMD="./lastal -v -o $QUERYNAME/$OUTNAME.maf db/$TARGETNAME $SRCSEQFOLDER/$QUERYFOLDER*.fasta"
echo -e "\t$CMD"
#eval $CMD

echo "MAPPING :: ADDING STATISTICS TO MAF"
NEWSUF=stat.maf
OLDMAF=$QUERYNAME/$OUTNAME.maf
NEWMAF=$QUERYNAME/$OUTNAME.maf.$NEWSUF
SUFFIX=$NEWSUF
CMD="./lastex $QUERYNAME/ref.prj $QUERYNAME/qry.prj $OLDMAF > $NEWMAF"
echo -e "\t$CMD"
#eval $CMD

echo "MAPPING :: CONVERTING MAF TO TAB"
CMD="scripts/maf-convert.py            tab $NEWMAF           > $NEWMAF.tab"
echo -e "\t$CMD"
#eval $CMD

echo "MAPPING :: SORTING MAF"
NEWSUF=sort.maf
OLDMAF=$NEWMAF
NEWMAF=$NEWMAF.$NEWSUF
SUFFIX=$SUFFIX.$NEWSUF
MAPSUFBEFOREREDUCE=$SUFFIX
CMD="scripts/maf-sort.sh                   $OLDMAF           > $NEWMAF"
echo -e "\t$CMD"
#eval $CMD

echo "MAPPING :: CONVERTING MAF TO TAB"
CMD="scripts/maf-convert.py            tab $NEWMAF           > $NEWMAF.tab"
echo -e "\t$CMD"
#eval $CMD

echo "MAPPING :: REDUCING ALIGNMENT"
NEWSUF=nopar.maf
OLDMAF=$NEWMAF
NEWMAF=$NEWMAF.$NEWSUF
SUFFIX=$SUFFIX.$NEWSUF
MAPSUFAFTERREDUCE=$SUFFIX
CMD="scripts/last-reduce-alignments.sh -d  $OLDMAF           > $NEWMAF"
echo -e "\t$CMD"
#eval $CMD

echo "MAPPING :: CONVERTING MAF TO TAB"
CMD="scripts/maf-convert.py            tab $NEWMAF           > $NEWMAF.tab"
echo -e "\t$CMD"
#eval $CMD

echo "MAPPING :: FILTERING ALIGNMENTS"
NEWSUF=small.maf
OLDMAF=$NEWMAF
NEWMAF=$NEWMAF.$NEWSUF
SUFFIX=$SUFFIX.$NEWSUF
MAPSUFAFTERREDUCEAFTERFILTER=$SUFFIX
CMD="./filterReads.pl $OLDMAF $NEWMAF"
echo -e "\t$CMD"
#eval $CMD

echo "MAPPING :: CONVERTING MAF TO TAB AND HTML"
CMD="scripts/maf-convert.py            html $NEWMAF > $NEWMAF.html"
echo -e "\t$CMD"
#eval $CMD
CMD="scripts/maf-convert.py            tab  $NEWMAF > $NEWMAF.tab"
echo -e "\t$CMD"
#eval $CMD
MAPMAF=$NEWMAF

echo "###################################"
echo "ASSEMBLY"
echo "###################################"

echo "ASSEMBLY :: GENERATING ASSEMBLY"
CMD="./DeNovoLastmaf2assembly.pl $NEWMAF $EPITOPEFASTA | tee $EPITOPEFASTA.log"
echo -e "\t$CMD"
eval $CMD
exit
echo "ASSEMBLY :: CONVERTING TO XML"
CMD="./DeNovoLast2xml.pl $QUERYNAME/$OUTNAME.maf .$SUFFIX.tab | tee xml.log"
echo -e "\t$CMD"
#eval $CMD

echo "ASSEMBLY :: CREATING DB"
CMD="./lastdb -v db/$QUERYNAME $SRCSEQFOLDER/$QUERYFOLDER*.fasta"
echo -e "\t$CMD"
#eval $CMD

echo "ASSEMBLY :: FIXING FASTA"
CMD="cat $QUERYNAME/$OUTNAME.maf.$SUFFIX.fasta | tr \"-\" \"n\" > $QUERYNAME/$OUTNAME.maf.$SUFFIX.fasta.nodash.fasta"
echo -e "\t$CMD"
#eval $CMD

echo "ASSEMBLY :: LASTING"
CMD="./lastal -v -o $QUERYNAME/$EPITOPEFASTA.maf \"db/$TARGETNAME\" $QUERYNAME/$OUTNAME.maf.$SUFFIX.fasta.nodash.fasta"
echo -e "\t$CMD"
#eval $CMD

echo "ASSEMBLY :: CREATING KEY COUNT"
CMD="./lastdb -x $QUERYNAME/ref    $SRCSEQFOLDER/$TARGETFOLDER*.fasta"
echo -e "\t$CMD"
#eval $CMD
CMD="./lastdb -x $QUERYNAME/qryAss $QUERYNAME/$OUTNAME.maf.$SUFFIX.fasta.nodash.fasta"
echo -e "\t$CMD"
#eval $CMD

echo "ASSEMBLY :: ADDING STATISTICS TO MAF"
NEWSUF=stat.maf
OLDMAF=$QUERYNAME/$EPITOPEFASTA.maf
NEWMAF=$QUERYNAME/$EPITOPEFASTA.maf.$NEWSUF
SUFFIX=$NEWSUF
CMD="./lastex $QUERYNAME/ref.prj $QUERYNAME/qryAss.prj $OLDMAF > $NEWMAF"
echo -e "\t$CMD"
#eval $CMD

echo "ASSEMBLY :: CONVERTING MAF TO TAB"
CMD="scripts/maf-convert.py            tab $NEWMAF > $NEWMAF.tab"
echo -e "\t$CMD"
#eval $CMD

echo "ASSEMBLY :: SORTING MAF"
NEWSUF=sort.maf
OLDMAF=$NEWMAF
NEWMAF=$NEWMAF.$NEWSUF
SUFFIX=$SUFFIX.$NEWSUF
ASSSUFBEFOREREDUCE=$SUFFIX
CMD="scripts/maf-sort.sh                   $OLDMAF > $NEWMAF"
echo -e "\t$CMD"
#eval $CMD

echo "ASSEMBLY :: CONVERTING MAF TO TAB"
CMD="scripts/maf-convert.py tab $NEWMAF > $NEWMAF.tab"
echo -e "\t$CMD"
#eval $CMD

echo "ASSEMBLY :: REDUCING ALIGNMENT"
NEWSUF=nopar.maf
OLDMAF=$NEWMAF
NEWMAF=$NEWMAF.$NEWSUF
SUFFIX=$SUFFIX.$NEWSUF
ASSSUFAFTEREDUCE=$SUFFIX
CMD="scripts/last-reduce-alignments.sh -d  $OLDMAF             > $NEWMAF"
echo -e "\t$CMD"
#eval $CMD

echo "ASSEMBLY :: CONVERTING MAF TO TAB AND HTML"
CMD="scripts/maf-convert.py            tab $NEWMAF             > $NEWMAF.tab"
echo -e "\t$CMD"
#eval $CMD
CMD="scripts/maf-convert.py            html $NEWMAF             > $NEWMAF.tab"
echo -e "\t$CMD"
#eval $CMD

echo "ASSEMBLY :: CONVERTING MAF TO TAB AND HTML"
CMD="scripts/maf-convert.py tab $NEWMAF > $NEWMAF.tab"
echo -e "\t$CMD"
#eval $CMD
CMD="scripts/maf-convert.py html $NEWMAF > $NEWMAF.html"
echo -e "\t$CMD"
#eval $CMD

ASSMAF=$NEWMAF



echo "###################################"
echo "EXPORT OVERALL"
echo "###################################"
echo "OVERALL :: CREATING OVERALL PLOTS"
CMD="scripts/last-dotplot.py $MAPMAF.tab $MAPMAFF.tab.png"
echo -e "\t$CMD"
#eval $CMD
CMD="scripts/last-dotplot.py $ASSMAF.tab $ASSMAF.tab.png"
echo -e "\t$CMD"
#eval $CMD





echo "OVERALL :: CREATING HTML BROWSER TO OVERALL $HTML"
SIZE=350
TDSTYLE=' style="width:25%;"'
IMGSTYLE=' HEIGHT="'$SIZE'" WIDTH="'$SIZE'"'
echo -e "\tcreating header"
echo "<html>
    <body>
        <table>
            <tr>
                <th$TDSTYLE>reads dirty</td>
                <th$TDSTYLE>reads clean</td>
                <th$TDSTYLE>assembly dirty</td>
                <th$TDSTYLE>assembly clean</td>
            </tr>
" > $HTML


echo -e "\tcreating overal"
echo -e "\t\tcreating sub-header"
echo -e "            <tr>" >> $HTML
for begin in $OUTNAME $EPITOPEFASTA
do
    echo -e "                <th colspan=\"2\">$begin</td>" >> $HTML
done
echo -e "            </tr>\n" >> $HTML



echo -e "\t\tcreating table"
echo -e "            <tr>" >> $HTML
for begin in $OUTNAME $EPITOPEFASTA
do
    echo -e "\t\t\tcreating table $begin"

    AFTER=$MAPSUFAFTERREDUCE
    if [ -s $QUERYNAME/$begin.maf.$MAPSUFAFTERREDUCEAFTERFILTER.tab ];
    then
        AFTER=$MAPSUFAFTERREDUCEAFTERFILTER
    fi

    for end in $MAPSUFBEFOREREDUCE $AFTER
    do
        echo -e "\t\t\t\tcreating row $end $QUERYNAME"
        tab=$begin.maf.$end.tab
        echo -e "\t\t\t\t\tchecking file $QUERYNAME/$tab"
        if [ -s "$QUERYNAME/$tab" ];
        then
            echo -e "\t\t\t\t\treading tab $tab"
            CMD="scripts/last-dotplot.py $QUERYNAME/$tab $QUERYNAME/$tab.png"
            echo -e "\t\t\t\t\t\t$CMD"
            #eval $CMD

            if [ -s "$QUERYNAME/$tab.png" ];
            then
                echo -e "\t\t\t\t\t\tIMAGE $QUERYNAME/$tab.png EXISTS. ADDING THUMBNAIL TO $HTML"
                echo "                <td$TDSTYLE><a href=\"$QUERYNAME/$tab.png\" target=\"_blank\"><img src=\"$QUERYNAME/$tab.png\"$IMGSTYLE/></a></td>" >> $HTML
            else
                echo -e "\t\t\t\t\t\tIMAGE $QUERYNAME/$tab.png DOESNT EXISTS"
                echo "                <td$TDSTYLE>none</td>" >> $HTML
            fi
        fi
    done
done
echo -e "            </tr>\n" >> $HTML


echo -e "\tindividual"
for (( NUMBER=${CHROMMIN}; NUMBER<=${CHROMMAX}; NUMBER++ ))
{
    NNUMBER=${NUMBER}
    if [ "$NNUMBER" -lt "10" ]
    then
        NNUMBER="0${NUMBER}"
    fi

    echo -e "\t\t$NNUMBER"
    echo -e "            <tr>\n                <th colspan=\"4\">chr ${NNUMBER}</td>\n            </tr>\n" >> $HTML
    echo    "            <tr>" >> $HTML

    for begin in $OUTNAME $EPITOPEFASTA
    do
        echo -e "\t\t\tcreating table $begin"

        AFTER=$MAPSUFAFTERREDUCE
        if [ -s $QUERYNAME/$begin.maf.$MAPSUFAFTERREDUCEAFTERFILTER.tab ];
        then
            AFTER=$MAPSUFAFTERREDUCEAFTERFILTER
        fi

        for end in $MAPSUFBEFOREREDUCE $AFTER
        do
            echo -e "\t\t\t\tcreating row $end $QUERYNAME"
            tab=$begin.maf.$end.tab
            echo -e "\t\t\t\t\tchecking file $QUERYNAME/$tab"

            if [ -s $QUERYNAME/$tab ];
            then
                echo -e "\t\t\t\t\treading tab $tab"
                echo -e "\t\t\t\t\tEXPORTING CHROM ${NNUMBER} FROM FILE $QUERYNAME/$tab"
                CMD="cat $QUERYNAME/$tab | perl -ne 'if (/supercontig_1.'${NNUMBER}'.+supercontig_1.'${NNUMBER}'/) { print }' > $QUERYNAME/$tab.${NNUMBER}.tab"
                echo -e "\t\t\t\t\t\t$CMD"
                #eval $CMD

                if [ -s "$QUERYNAME/$tab.${NNUMBER}.tab" ];
                then
                    echo -e "\t\t\t\t\tCONVERTING QUERY: $QUERYNAME/$tab.${NNUMBER}.tab TO IMAGE"
                    CMD="scripts/last-dotplot.py $QUERYNAME/$tab.${NNUMBER}.tab $QUERYNAME/$tab.${NNUMBER}.tab.png"
                    echo -e "\t\t\t\t\t\t$CMD"
                    #eval $CMD
                else
                    CMD="cat $QUERYNAME/$tab | perl -ne 'if (/supercontig_1.'${NNUMBER}'/) { print }' > $QUERYNAME/$tab.${NNUMBER}.tab"
                    echo -e "\t\t\t\t\t\t$CMD"
                    #eval $CMD
                    if [ -s "$QUERYNAME/$tab.${NNUMBER}.tab" ];
                    then
                        echo -e "\t\t\t\t\t\tCONVERTING QUERY: $QUERYNAME/$tab.${NNUMBER}.tab TO IMAGE"
                        CMD="scripts/last-dotplot.py $QUERYNAME/$tab.${NNUMBER}.tab $QUERYNAME/$tab.${NNUMBER}.tab.png"
                        echo -e "\t\t\t\t\t\t\t$CMD"
                        #eval $CMD
                    fi
                fi

                if [ -s "$QUERYNAME/$tab.${NNUMBER}.tab.png" ];
                then
                    echo "IMAGE $QUERYNAME/$tab.${NNUMBER}.tab.png EXISTS. ADDING THUMBNAIL TO $HTML"
                    echo "                <td$TDSTYLE><a href=\"$QUERYNAME/$tab.${NNUMBER}.tab.png\" target=\"_blank\"><img src=\"$QUERYNAME/$tab.${NNUMBER}.tab.png\"$IMGSTYLE/></a></td>" >> $HTML
                else
                    echo "IMAGE $QUERYNAME/$tab.${NNUMBER}.tab.png DOESNT EXISTS"
                    echo "                <td$TDSTYLE>none</td>" >> $HTML
                fi
            fi
        done
    done

    echo "            </tr>
" >> $HTML
}


echo "        </table>
    </body>
</html>
" >> $HTML

echo "###################################"
echo "DONE"
echo "###################################"







##scripts/last-dotplot.py               $QUERYNAME/$OUTNAME.maf.sort.maf.tab           $QUERYNAME/$OUTNAME.maf.sort.maf.tab.png
##scripts/last-dotplot.py               $QUERYNAME/$OUTNAME.maf.sort.maf.nopar.maf.tab $QUERYNAME/$OUTNAME.maf.sort.maf.nopar.maf.tab.png
##for (( NUMBER=${CHROMMIN}; NUMBER<=${CHROMMAX}; NUMBER++ ))
##{
##	NNUMBER=${NUMBER}
##	if [ "$NNUMBER" -lt "10" ]
##	then
##		NNUMBER="0${NUMBER}"
##	fi
##	echo "EXPORTING CHROM ${NNUMBER} FROM FILE $QUERYNAME/$OUTNAME.maf.sort.maf.nopar.maf.sort.maf.tab"
##	cat $QUERYNAME/$OUTNAME.maf.sort.maf.nopar.maf.tab |  grep "supercontig_1.${NNUMBER}" > $QUERYNAME/$OUTNAME.maf.sort.maf.nopar.maf.tab.${NNUMBER}.tab
##
##	if [ -s "$QUERYNAME/$OUTNAME.maf.sort.maf.nopar.maf.tab.${NNUMBER}.tab" ];
##	then
##		echo "CONVERTING $QUERYNAME/$OUTNAME.maf.sort.maf.nopar.maf.tab.${NNUMBER}.tab TO IMAGE"
##		scripts/last-dotplot.py $QUERYNAME/$OUTNAME.maf.sort.maf.nopar.maf.tab.${NNUMBER}.tab $QUERYNAME/$OUTNAME.maf.sort.maf.nopar.maf.tab.${NNUMBER}.tab.png
##	fi
##}


##for (( NUMBER=${CHROMMIN}; NUMBER<=${CHROMMAX}; NUMBER++ ))
##{
##	NNUMBER=${NUMBER}
##	if [ "$NNUMBER" -lt "10" ]
##	then
##		NNUMBER="0${NUMBER}"
##	fi
##	echo "EXPORTING CHROM ${NNUMBER} FROM FILE $QUERYNAME/$EPITOPEFASTA.maf.sort.maf.nopar.maf.tab"
##	cat $QUERYNAME/$EPITOPEFASTA.maf.sort.maf.nopar.maf.tab | perl -ne 'if (/supercontig_1.'${NNUMBER}'.+supercontig_1.'${NNUMBER}'/) { print }' > $QUERYNAME/$EPITOPEFASTA.maf.sort.maf.nopar.maf.tab.${NNUMBER}.tab
##
##	if [ -s "$QUERYNAME/$EPITOPEFASTA.maf.sort.maf.nopar.maf.tab.${NNUMBER}.tab" ];
##	then
##		echo "CONVERTING $EPITOPEFASTA/$OUTNAME.maf.sort.maf.nopar.maf.tab.${NNUMBER}.tab TO IMAGE"
##		scripts/last-dotplot.py $QUERYNAME/$EPITOPEFASTA.maf.sort.maf.nopar.maf.tab.${NNUMBER}.tab $QUERYNAME/$EPITOPEFASTA.maf.sort.maf.nopar.maf.tab.${NNUMBER}.tab.png
##	fi
##}
#
##for (( NUMBER=${CHROMMIN}; NUMBER<=${CHROMMAX}; NUMBER++ ))
##{
##	NNUMBER=${NUMBER}
##	if [ "$NNUMBER" -lt "10" ]
##	then
##		NNUMBER="0${NUMBER}"
##	fi
##	echo "EXPORTING CHROM ${NNUMBER} FROM FILE $QUERYNAME/$EPITOPEFASTA.maf.sort.maf.tab"
##	cat $QUERYNAME/$EPITOPEFASTA.maf.sort.maf.tab | perl -ne 'if (/supercontig_1.'${NNUMBER}'.+supercontig_1.'${NNUMBER}'/) { print }' > $QUERYNAME/$EPITOPEFASTA.maf.sort.maf.tab.${NNUMBER}.tab
##
##	if [ -s "$QUERYNAME/$EPITOPEFASTA.maf.sort.maf.tab.${NNUMBER}.tab" ];
##	then
##		echo "CONVERTING $EPITOPEFASTA/$OUTNAME.maf.sort.maf.tab.${NNUMBER}.tab TO IMAGE"
##		scripts/last-dotplot.py $QUERYNAME/$EPITOPEFASTA.maf.sort.maf.tab.${NNUMBER}.tab $QUERYNAME/$EPITOPEFASTA.maf.sort.maf.tab.${NNUMBER}.tab.png
##	fi
##}
