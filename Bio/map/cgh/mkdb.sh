SETUPFILE=$1

#PROGRAMS SETUP
HTML='java -jar /home/saulo/Desktop/blast/cgh/xalan-j_2_7_1/xalan.jar'
BLAST2XML="./blast_xml.pl"
XMLMERGER="./mergeXML.pl"
XML2CSV="./genMultivarTable.pl"
PCA="./PCA.pl"
PCAR="runR ./pca.r "

#FOLDERS SETUP
DBFOLDER='db'
FASTAFOLDER='fasta'
BLASTFOLDER='blast'
XMLFOLDER='xml'
FINALFOLDER='out'
INEXPFOLDER='query_exp'
INFASTAFOLDER='query_fasta'


if [ ! "${SETUPFILE}" ]; then
	echo PLEASE INFORME SETUP FILE
	exit 1;
fi

if [ ! -e "${SETUPFILE}" ]; then
	echo FILE ${SETUPFILE} DOESNT EXISTS
	exit 1;
fi

a=0
while read line
do
	a=$(($a+1));
	echo $a $line;
	eval $line
done < $SETUPFILE




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
		chkFile "${FASTAFOLDER}/${INFAST}"
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
	INFLDER=$1
	INFIL=$2
	D=$3
	OUTFILE="${INFIL}_${D}.blast"
	OUTBLAST="${BLASTFOLDER}/${OUTFILE}"

	echo "BLASTING ${INFLDER}/${INFIL} AGAINST ${D} EVALUE ${EVALUE} THREAD ${THREADS} TASKS ${TASK} IDENTITY ${IDENTITY} OUT ${OUTBLAST}"
	COMMAND="blastn -task ${TASK} -db ${DBFOLDER}/${D} -query ${INFLDER}/${INFIL}.fasta -out ${OUTBLAST}  -evalue ${EVALUE} -num_threads ${THREADS} -perc_identity ${IDENTITY}"

	if [ "${SHORT}" -eq 1 ]
	then
		COMMAND=${COMMAND}" -gapopen ${GAPOPEN} -gapextend ${GAPEXTEND} -word_size ${WORDSIZE} -penalty ${PENALTY} -reward ${REWARD} -window_size ${WINDOWSIZE} -min_raw_gapped_score ${MINRAWGAPSCORE} -xdrop_gap ${XDROP} -no_greedy "
	fi

	#blastn         -task blastn -db db/cgR265        -query 59dup.fasta    -out 59dup_cgR265_id40_long.blast -evalue 100      -num_threads 3        -perc_identity 50 -gapopen 2 -gapextend 2 -word_size 7 -penalty -2 -reward 2
	#blastn         -task blastn -db db/cgR265        -query 59dup.fasta    -out 59dup_cgR265_id40_long.blast -evalue 10       -num_threads 3        -perc_identity 50 -gapopen 2 -gapextend 2 -word_size 4 -penalty -3 -reward 2  -no_greedy -window_size 4 -min_raw_gapped_score 20 -xdrop_gap 50
	echo "	${COMMAND}"

	if [ "${SERIOUS}" -eq 1 ]
	then
		chkFile "${INFLDER}/${INFIL}.fasta"
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
		chkFile "${BLASTFOLDER}/${OUTFILE}"
		eval $XML
	fi

	echo ""
}




function clean {
	INFILE0=$1
	echo "CLEANING THE MESS OF ${INFILE0}"

	if [ "${CLEANDB}" -eq 1 ]
	then
		rm ${DBFOLDER}/* 2>/dev/null
		rm ${FASTAFOLDER}/*.log 2>/dev/null
	fi

	rm ${BLASTFOLDER}/${INFILE0}* 2>/dev/null
	rm ${XMLFOLDER}/${INFILE0}* 2>/dev/null
	rm ${FINALFOLDER}/${INFILE0}* 2>/dev/null

	echo ""
}


function mkAll {
	INFASTAFOLDER=$1
	INFILE1=$2
	INFASTAS_str="$3[*]"
	OUTNAMES_str="$4[*]"
	TITLES_str="$5[*]"
	TAXIDS_str="$6[*]"
	INDBSS_str="$7[*]"
	OUTDBSS_str="$8[*]"
	ATITLES_str="$9[*]"

	INFASTAS=(${!INFASTAS_str})
	OUTNAMES=(${!OUTNAMES_str})
	TITLES=(${!TITLES_str})
	TAXIDS=(${!TAXIDS_str})
	INDBSS=(${!INDBSS_str})
	OUTDBSS=(${!OUTDBSS_str})
	ATITLES=(${!ATITLES_str})


	if [ "${CLEAN}" -eq 1 ]
	then
		clean ${INFILE1}

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
			blast   "${INFASTAFOLDER}" "${INFILE1}" "$DB"
		    ((index3++))
		done

		element_count4=${#OUTDBS[@]}
		index4=0;

		if [ "${MKALIAS}" -eq 2 ]
		then
			while [ "$index4" -lt "$element_count4" ]
			do
				DB=${OUTDBS[${index4}]}
				blast   "${INFASTAFOLDER}" "${INFILE1}" "$DB"
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
			convxml "$INFILE1" "$DB"
		    ((index5++))
		done

		element_count6=${#OUTDBS[@]}
		index6=0;

		if [ "${MKALIAS}" -eq 2 ]
		then
			while [ "$index6" -lt "$element_count6" ]
			do
				DB=${OUTDBS[${index6}]}
				convxml "$INFILE1" "$DB"
				((index6++))
			done
		fi
	fi


	if [ "${MERGEXML}" -eq 1 ]
	then
		echo "MERGING XML FROM FOLDER ${XMLFOLDER} TO FOLDER ${FINALFOLDER} IN FILE ${INFILE1}"
		COMMAND="${XMLMERGER} ${XMLFOLDER} ${FINALFOLDER} ${INFILE1}"
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
		INTX="${FINALFOLDER}/${INFILE1}_blast_merged_blast_all_gene"
		echo "CONVERTING XML ${INTX}.xml TO HTML"
		COMMAND="${HTML} -IN ${INTX}.xml -OUT ${INTX}.html"
		echo "	${COMMAND}"

		if [ "${SERIOUS}" -eq 1 ]
		then
			chkFile "${INTX}.xml"
			eval ${COMMAND}
		fi

		INTX="${FINALFOLDER}/${INFILE1}_blast_merged_blast_all_org"
		echo "CONVERTING XML ${INTX}.xml TO HTML"
		COMMAND="${HTML} -IN ${INTX}.xml -OUT ${INTX}.html"
		echo "	${COMMAND}"
		if [ "${SERIOUS}" -eq 1 ]
		then
			chkFile "${INTX}.xml"
			eval ${COMMAND}
		fi
	fi


	if [ "${CONVCSV}" -eq 1 ]
	then
		INTX="${FINALFOLDER}/${INFILE1}_blast_merged_blast_all_gene.xml"
		echo "CONVERTING XML ${INTX} TO CSV USING ${INEXPFOLDER}/${EXPRESSION}"
		COMMAND="${XML2CSV} ${INTX} ${INEXPFOLDER}/${EXPRESSION}"
		echo "	${COMMAND}"

		if [ "${SERIOUS}" -eq 1 ]
		then
			chkFile $INTX
			chkFile "${INEXPFOLDER}/${EXPRESSION}"
			eval ${COMMAND}
		fi
	fi


	if [ "${MKPCA}" -eq 1 ]
	then
		INTX="${FINALFOLDER}/${INFILE1}_blast_merged_blast_all_gene.xml.EXP.${EXPRESSION}.csv"
		echo "RUNNING PCA ON CSV ${INTX} USING PARAMETERS :: ${PCAPAR}"
		COMMAND="${PCA} ${INTX} ${PCAPAR}"
		echo "	${COMMAND}"

		if [ "${SERIOUS}" -eq 1 ]
		then
			chkFile $INTX
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

				chkFile ${INTR}
				eval ${COMMANDR}
			fi
		fi
	fi
}



function chkFolders {
	INFOLDERS0_str="$1[*]"
	INFOLDERS0=(${!INFOLDERS0_str})

	element_count0=${#INFOLDERS0[@]}
	index0=0;

	while [ "$index0" -lt "$element_count0" ]
	do
		INFOLDER0=${INFOLDER0[${index0}]}

		if [ ! -d ${INFOLDER0} ]
		then
			echo -e "\n\tFOLDER ${INFOLDER0} DOESNT EXISTS"
			exit 1;
		else
			echo -e "\n\tFOLDER ${INFOLDER0} EXISTS"
		fi
		((index0++));
	done
}

function chkFolder {
	INFOLDER1=$1
	if [ ! -d ${INFOLDER1} ]
	then
		echo -e "\n\tFOLDER ${INFOLDER1} DOESNT EXISTS"
		exit 1;
	else
		echo -e "\n\tFOLDER ${INFOLDER1} EXISTS"
	fi
}

function chkFiles {
	INFLES_str="$1[*]"
	INFOLDER3=$2
	INEXT=$3
	INFLES=(${!INFLES_str})

	element_count7=${#INFLES[@]}
	index7=0;

	while [ "$index7" -lt "$element_count7" ]
	do
		INFILE3="${INFOLDER3}/"${INFLES[${index7}]}${INEXT}

		if [ ! -e ${INFILE3} ]
		then
			echo -e "\n\tFILE ${INFILE3} DOESNT EXISTS"
			exit 1;
		else
			echo -e "\n\tFILE ${INFILE3} EXISTS"
		fi
		((index7++));
	done
}

function chkFile {
	INFILE4=$1
	if [ ! -e ${INFILE4} ]
	then
		echo -e "\n\tFILE ${INFILE4} DOESNT EXISTS"
		exit 1;
	else
		echo -e "\n\tFILE ${INFILE4} EXISTS"
	fi
}


################################
### CHECKING FILES
################################
#chkFiles 
#chkFolders 
#chkFile
#chkFolder
chkFolder $INEXPFOLDER
chkFolder $INFASTAFOLDER
chkFolder $DBFOLDER
chkFolder $FASTAFOLDER
chkFolder $BLASTFOLDER
chkFolder $XMLFOLDER
chkFolder $FINALFOLDER
chkFile   "${INEXPFOLDER}/${EXPRESSION}"
chkFiles INFASTAS $FASTAFOLDER
chkFiles INFILES  $INFASTAFOLDER ".fasta"

echo ALL FILES CHECKED AND PASSED


################################
### ITERATION
################################
element_countf=${#INFILES[@]}
indexf=0;

while [ "$indexf" -lt "$element_countf" ]
do
	INFILE=${INFILES[${indexf}]}
	mkAll ${INFASTAFOLDER} ${INFILE} INFASTAS OUTNAMES TITLES TAXIDS INDBSS OUTDBS ATITLES
    ((indexf++))
	echo ""	
	echo ""	
	echo ""
done



