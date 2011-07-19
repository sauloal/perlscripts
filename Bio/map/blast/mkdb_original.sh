#INPUT FILES
INFILES=('CNA_probes')
#INFILES=('jun_CNA1.cdna')
EXPRESSION='ORIGINAL_DATA_FINAL.txt.xml'

#MKDB FASTA FILES
INFASTAS=('Cryptococcus_gattii_R265_CHROMOSSOMES.fasta' 'Cryptococcus_neoformans_var_grubii_H99_SCAFFOLD.fasta' 'Cryptococcus_neoformans_var_neoformans_B3501A_CHROMOSSOMES.fasta' 'Cryptococcus_neoformans_var_neoformans_JEC21_CHROMOSSOMES.fasta')
OUTNAMES=('cgR265'                                      'cngrubiiH99'                                           'cnneoB3501A'                                                      'cnneoJEC21')
TITLES=(  'Cryptococcus gattii R265'                    'Cryptococcus neoformans var grubii H99'                'Cryptococcus neoformans var neoformans B-3501A'                   'Cryptococcus neoformans var neoformans JEC21')
TAXIDS=(  '294750'                                      '235443'                                                '283643'                                                           '214684')


#MKALISAS DB FILES
INDBSS=(  'cngrubiiH99 cnneoB3501A cnneoJEC21 cgR265 cgWM276' 'cngrubiiH99 cnneoB3501A cnneoJEC21 cgR265')
OUTDBS=(  'crypto'                                            'cneo'                                     )
ATITLES=( 'Cryptococcus'                                      'Cryptococcus neoformans')

#FOLDERS SETUP
DBFOLDER='db'
FASTAFOLDER='fasta'
BLASTFOLDER='blast'
XMLFOLDER='xml'
FINALFOLDER='out'

#PROGRAMS SETUP
HTML='java -jar /home/saulo/Desktop/blast/cgh/xalan-j_2_7_1/xalan.jar'
BLAST2XML="./blast_xml.pl"
XMLMERGER="./mergeXML.pl"
XML2CSV="./genMultivarTable.pl"
PCA="./PCA.pl"
PCAR="runR ./pca.r "
PCAPAR="-renameRE JEC21_LT_15FOLD_AND_GT001 JEC21 -renameRE R265_GE_20FOLD_LE_001JEC21_GE_15FOLD_AND_LE001 R265 -renameRE H99_GE_20FOLD_LE_001JEC21_GE_15FOLD_AND_LE001 H99 -renameRE B3501_GE_20FOLD_LE_001JEC21_GE_15FOLD_AND_LE00 B3501 -exclude go_comp go_func go_supp ID -renameRE Cryptococcus_gattii_R265 R265 -renameRE Cryptococcus_neoformans_var_grubii_H99 H99 -renameRE Cryptococcus_neoformans_var_neoformans_B3501A B3501 -renameRE Cryptococcus_neoformans_var_neoformans_JEC21 JEC21"


#BEHAVIOR SETUP
SERIOUS=1
CLEAN=0
CLEANDB=0
MKDB=0
MKALIAS=0
BLAST=0
MKXML=0
MERGEXML=0
CONVHTML=0
CONVCSV=1
MKPCA=0
MKPCAR=0



#BLAST PARAMETERS
SHORT=0
EVALUE='10'
#	TASK="blastn-short"
TASK='blastn'
IDENTITY='50'
DESC="EVALUE ${EVALUE} TASK ${TASK} IDENTITY ${IDENTITY}"
THREADS='6'

if [ "${SHORT}" -eq 1 ]
then
	GAPOPEN=2
	GAPEXTEND=2
	WORDSIZE=4
	PENALTY=-3
	REWARD=2
	WINDOWSIZE=4
	MINRAWGAPSCORE=10
	XDROP=10
	DESC="${DESC} GAPOPEN ${GAPOPEN} GAPEXTEND ${GAPEXTEND} WORDSIZE ${WORDSIZE} PENALTY ${PENALTY} REWARD ${REWARD} WINDOWSIZE ${WINDOWSIZE} MINRAWGAPPEDSCORE ${MINRAWGAPSCORE} XDROPGAP ${XDROP} NOGREEDY"
fi






IFS=$'\n'
function mkdb {
	INFAST=$1
    OUTNAM=$2
    TITL=$3
	TAXI=$4

	echo "CREATING BLAST DB FOR ${FASTAFOLDER}/${INFAST} WITH NAME ${OUTNAM} TITLE ${TITL} TAXID ${TAXI}"
	COMMAND="makeblastdb -in ${FASTAFOLDER}/${INFAST} -dbtype nucl -title \"${TITL}\" -out ${DBFOLDER}/${OUTNAM} -taxid ${TAXI} -logfile ${FASTAFOLDER}/${INFAST}.log"
	echo "	${COMMAND}"

	if [ "${SERIOUS}" -eq 1 ]
	then
		eval $COMMAND
	fi

	echo ""
}

function mkalias {
	INDB=$1
	OUTD=$2
	TITL=$3

	echo "CREATING BLAST DB ALIAS FOR ${INDB} AS ${OUTD} TITLED ${TITL}"
	COMMAND="blastdb_aliastool -dblist \"${INDB}\" -dbtype nucl -out ${DBFOLDER}/${OUTD} -title \"${TITL}\" -logfile ${OUTD}.log"
	echo "	${COMMAND}"

	if [ "${SERIOUS}" -eq 1 ]
	then
		eval $COMMAND
	fi

	echo ""
}

function blast {
	INFIL=$1
	D=$2
	OUTFILE="${INFIL}_${D}.blast"
	OUTBLAST="${BLASTFOLDER}/${OUTFILE}"

	echo "BLASTING ${INFIL} AGAINST ${D} EVALUE ${EVALUE} THREAD ${THREADS} TASKS ${TASK} IDENTITY ${IDENTITY} OUT ${OUTBLAST}"
	COMMAND="blastn -task ${TASK} -db ${DBFOLDER}/${D} -query ${INFIL}.fasta -out ${OUTBLAST}  -evalue ${EVALUE} -num_threads ${THREADS} -perc_identity ${IDENTITY}"

	if [ "${SHORT}" -eq 1 ]
	then
		COMMAND=${COMMAND}" -gapopen ${GAPOPEN} -gapextend ${GAPEXTEND} -word_size ${WORDSIZE} -penalty ${PENALTY} -reward ${REWARD} -window_size ${WINDOWSIZE} -min_raw_gapped_score ${MINRAWGAPSCORE} -xdrop_gap ${XDROP} -no_greedy "
	fi

	#blastn         -task blastn -db db/cgR265        -query 59dup.fasta    -out 59dup_cgR265_id40_long.blast -evalue 100      -num_threads 3        -perc_identity 50 -gapopen 2 -gapextend 2 -word_size 7 -penalty -2 -reward 2
	#blastn         -task blastn -db db/cgR265        -query 59dup.fasta    -out 59dup_cgR265_id40_long.blast -evalue 10       -num_threads 3        -perc_identity 50 -gapopen 2 -gapextend 2 -word_size 4 -penalty -3 -reward 2  -no_greedy -window_size 4 -min_raw_gapped_score 20 -xdrop_gap 50
	echo "	${COMMAND}"

	if [ "${SERIOUS}" -eq 1 ]
	then
		eval $COMMAND
	fi

	echo ""
}



function convxml {
	INFIL=$1
	D=$2
	OUTFILE="${INFIL}_${D}.blast"

	echo "CONVERTING ${INFIL} DATABASE ${D} FROM ${OUTFILE} FILE TO XML"

	XML="${BLAST2XML} ${BLASTFOLDER}  ${OUTFILE} \"${DESC}\""
	echo "	${XML}"

	if [ "${SERIOUS}" -eq 1 ]
	then
		eval $XML
	fi

	echo ""
}




function clean {
	INFILE=$1
	echo "CLEANING THE MESS OF ${INFILE}"

	if [ "${CLEANDB}" -eq 1 ]
	then
		rm ${DBFOLDER}/* 2>/dev/null
		rm ${FASTAFOLDER}/*.log 2>/dev/null
	fi

	rm ${BLASTFOLDER}/${INFILE}* 2>/dev/null
	rm ${XMLFOLDER}/${INFILE}* 2>/dev/null
	rm ${FINALFOLDER}/${INFILE}* 2>/dev/null

	echo ""
}




function mkAll {
	INFILE=$1
	INFASTAS_str="$2[*]"
	OUTNAMES_str="$3[*]"
	TITLES_str="$4[*]"
	TAXIDS_str="$5[*]"
	INDBSS_str="$6[*]"
	OUTDBSS_str="$7[*]"
	ATITLES_str="$8[*]"

	INFASTAS=(${!INFASTAS_str})
	OUTNAMES=(${!OUTNAMES_str})
	TITLES=(${!TITLES_str})
	TAXIDS=(${!TAXIDS_str})
	INDBSS=(${!INDBSS_str})
	OUTDBSS=(${!OUTDBSS_str})
	ATITLES=(${!ATITLES_str})


	if [ "${CLEAN}" -eq 1 ]
	then
		clean ${INFILE}

		CLEAN=2
		if [ "${CLEANDB}" -eq 1 ]
		then
			CLEANDB=2
		fi
	fi


	if [ "${MKDB}" -eq 1 ]
	then
		echo MAKING DB
		element_count1=${#INFASTAS[@]}
		index1=0;

		while [ "$index1" -lt "$element_count1" ]
		do
			INFASTA=${INFASTAS[${index1}]}
			OUTNAME=${OUTNAMES[${index1}]}
			TITLE=${TITLES[${index1}]}
			TAXID=${TAXIDS[${index1}]}
			mkdb "$INFASTA" "$OUTNAME" "$TITLE" "$TAXID"
		    ((index1++))
		done
		MKDB=2
	fi


	if [ "${MKALIAS}" -eq 1 ]
	then
		echo MAKING ALIAS
		element_count2=${#INDBSS[@]}
		index2=0;

		while [ "$index2" -lt "$element_count2" ]
		do
			INDBS=${INDBSS[${index2}]}
			OUTDB=${OUTDBS[${index2}]}
			TITLE=${ATITLES[${index2}]}
			mkalias "${INDBS}" "${OUTDB}" "${TITLE}"
		    ((index2++))
		done
		MKALIAS=2
	fi


	if [ "${BLAST}" -eq 1 ]
	then
		element_count3=${#OUTNAMES[@]}
		index3=0;

		while [ "$index3" -lt "$element_count3" ]
		do
			DB=${OUTNAMES[${index3}]}
			blast   "$INFILE" "$DB"
		    ((index3++))
		done

		element_count4=${#OUTDBS[@]}
		index4=0;

		if [ "${MKALIAS}" -eq 2 ]
		then
			while [ "$index4" -lt "$element_count4" ]
			do
				DB=${OUTDBS[${index4}]}
				blast   "$INFILE" "$DB"
				((index4++))
			done
		fi
	fi


	if [ "${MKXML}" -eq 1 ]
	then 
		element_count5=${#OUTNAMES[@]}
		index5=0;

		while [ "$index5" -lt "$element_count5" ]
		do
			DB=${OUTNAMES[${index5}]}
			convxml "$INFILE" "$DB"
		    ((index5++))
		done

		element_count6=${#OUTDBS[@]}
		index6=0;

		if [ "${MKALIAS}" -eq 2 ]
		then
			while [ "$index6" -lt "$element_count6" ]
			do
				DB=${OUTDBS[${index6}]}
				convxml "$INFILE" "$DB"
				((index6++))
			done
		fi
	fi


	if [ "${MERGEXML}" -eq 1 ]
	then
		echo "MERGING XML FROM FOLDER ${XMLFOLDER} TO FOLDER ${FINALFOLDER} IN FILE ${INFILE}"
		COMMAND="${XMLMERGER} ${XMLFOLDER} ${FINALFOLDER} ${INFILE}"
		echo "	${COMMAND}"

		if [ "${SERIOUS}" -eq 1 ]
		then
			eval ${COMMAND}
		fi
		echo ""
		echo ""
	fi


	if [ "${CONVHTML}" -eq 1 ]
	then
		INTX="${FINALFOLDER}/${INFILE}_blast_merged_blast_all_gene"
		echo "CONVERTING XML ${INTX}.xml TO HTML"
		COMMAND="${HTML} -IN ${INTX}.xml -OUT ${INTX}.html"
		echo "	${COMMAND}"

		if [ "${SERIOUS}" -eq 1 ]
		then
			eval ${COMMAND}
		fi

		INTX="${FINALFOLDER}/${INFILE}_blast_merged_blast_all_org"
		echo "CONVERTING XML ${INTX}.xml TO HTML"
		COMMAND="${HTML} -IN ${INTX}.xml -OUT ${INTX}.html"
		echo "	${COMMAND}"
		if [ "${SERIOUS}" -eq 1 ]
		then
			eval ${COMMAND}
		fi
	fi


	if [ "${CONVCSV}" -eq 1 ]
	then
		INTX="${FINALFOLDER}/${INFILE}_blast_merged_blast_all_gene.xml"
		echo "CONVERTING XML ${INTX} TO CSV USING ${EXPRESSION}"
		COMMAND="${XML2CSV} ${INTX} ${EXPRESSION}"
		echo "	${COMMAND}"
		if [ "${SERIOUS}" -eq 1 ]
		then
			eval ${COMMAND}
		fi
	fi


	if [ "${MKPCA}" -eq 1 ]
	then
		INTX="${FINALFOLDER}/${INFILE}_blast_merged_blast_all_gene.xml.EXP.${EXPRESSION}.csv"
		echo "RUNNING PCA ON CSV ${INTX} USING PARAMETERS :: ${PCAPAR}"
		COMMAND="${PCA} ${INTX} ${PCAPAR}"
		echo "	${COMMAND}"

		if [ "${SERIOUS}" -eq 1 ]
		then
			eval ${COMMAND}

		fi

		if [ "${MKPCAR}" -eq 1 ]
		then
			INTR="${INTX}_PCA_00_raw.txt"
			echo "RUNNING PCA R ON CSV ${INTR}"
			COMMANDR="${PCAR} ${INTR}"
			echo "	${COMMANDR}"
			if [ "${SERIOUS}" -eq 1 ]
			then
				eval ${COMMANDR}
			fi
		fi
	fi
}






element_countf=${#INFILES[@]}
indexf=0;

while [ "$indexf" -lt "$element_countf" ]
do
	INFILE=${INFILES[${indexf}]}
	mkAll ${INFILE} INFASTAS OUTNAMES TITLES TAXIDS INDBSS OUTDBS ATITLES
    ((indexf++))
	echo ""	
	echo ""	
	echo ""	
	echo ""	
	echo ""
done



