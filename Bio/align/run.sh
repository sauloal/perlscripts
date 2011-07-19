INPUTFOLDER=$1
SETUPFILE=$2

if [ -d $INPUTFOLDER ]
then
	echo "RUNNING OVER FOLDER $INPUTFOLDER"
else
	echo "FOLDER $INPUTFOLDER DOESNT EXISTS"
	exit 1;
fi

if [ -f "Shared/$SETUPFILE" ]
then
	echo "RUNNING OVER SETUP FILE $SETUPFILE"
else
	echo "SETUP FILE $SETUPFILE DOESNT EXISTS"
	exit 1;
fi

OUTMERGED="xml_merged/"
#SETUPFILE="db_original.xml"
#XALAN="java -jar /home/saulo/Desktop/blast/cgh/xalan-j_2_7_1/xalan.jar"
MKDB=0
MERGE=0
CONVERT=0
CLUSTAL=1

function run
{
	FOLDER=$1
	TYPE=$2

	echo -e "RUNNING FOLDER $FOLDER TYPE $TYPE"
	TAB="${FOLDER}.${TYPE}.csv.out.tab"
	QFASTA="query_fasta/$TAB.fasta"
	XML="db_original_${TYPE}.xml"
	MERGEFOLDER="xml_to_merge_${TYPE}/"
	MTAB="${OUTMERGED}/${TAB}_blast_merged_blast_all_gene.xml.tab"
	echo -e "\tTAB         : $TAB"
	echo -e "\tQUERY FASTA : $QFASTA"
	echo -e "\tMERGE FOLDER: $MERGEFOLDER"
    echo -e "\tOUT MERGED  : $OUTMERGED"
	echo -e "\tMTAB        : $MTAB"
	export TAB

	cd $FOLDER
        ln -s ../Shared/* . 2>/dev/null
		mkdir blast         2>/dev/null
		mkdir db            2>/dev/null
		mkdir out           2>/dev/null
		mkdir xml           2>/dev/null
		mkdir xml_merged    2>/dev/null
		mkdir $MERGEFOLDER  2>/dev/null

		cat $SETUPFILE | perl -ne 'BEGIN { $tab = $ENV{"TAB"}; } { s/\<INFILEREPLACE\/\>/$tab/; print; }' > ${XML}

        if [ $MKDB -ne 0 ]; then
            echo -e "\t\tCREATING DB\n"
            cd xml
                rm -f $TAB*.xml 2>/dev/null
                rm -f $TAB*.tab 2>/dev/null
            cd ..
            ./mkdb.pl $XML
        fi

        if [ $MERGE -ne 0 ]; then
            echo -e "\t\tMERGING XML\n"
            cd $MERGEFOLDER
                rm -f *.xml 2>/dev/null
                ln -s ../xml/${TAB}_*_gene.xml .
            cd ..
            ./mergeXML.pl $MERGEFOLDER $OUTMERGED $TAB
        fi


        if [ $CONVERT -ne 0 ]; then
            echo -e "\t\tCONVERTING TO TAB\n";
            cd $OUTMERGED
                rm -f $MTAB*.fasta 2>/dev/null
                rm -f $MTAB*.log   2>/dev/null
                rm -f $MTAB*.aln   2>/dev/null
                rm -f $MTAB*.tab   2>/dev/null
                rm -f $MTAB*.xml   2>/dev/null
                rm -f $MTAB*.dnd   2>/dev/null
                rm -f $MTAB*.stat  2>/dev/null
            cd ..
            echo -e "\t\t\tQUERY FASTA : $QFASTA"
            echo -e "\t\t\tMTAB        : $MTAB"
            ./mergedTab2Align.pl $MTAB $QFASTA confFile:$XML

        fi

        if [ $CLUSTAL -ne 0 ]; then
            echo -e "\t\tRUNNING CLUSTAL\n"
            cd $OUTMERGED
                rm -f $MTAB*.clustal.dnd    2>/dev/null
                rm -f $MTAB*.clustal.stat   2>/dev/null
                rm -f $MTAB*.clustal.log    2>/dev/null
                rm -f $MTAB*.clustal.fasta  2>/dev/null
            cd ..
            ./clustal.pl $XML $TAB
        fi
	cd ..
}

function iterate
{
	FOLDER=$1
	run $FOLDER GENES
	#run $FOLDER REGIO
	cd Out
		unlink $FOLDER 2>/dev/null
		ln -s ../$FOLDER/$OUTMERGED $FOLDER 2>/dev/null
	cd ..
}


iterate $INPUTFOLDER
#iterate Top17None
#iterate Top17None01
#iterate Top17None02
#iterate Top17None03
#iterate Top48None
#iterate Top82None

#iterate Top05
#iterate Top10
#iterate Top25
#iterate TopAll
