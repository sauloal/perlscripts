#!/bin/bash

#./mkalign.sh "seqs/c_neo_r265/c_neo_r265_*.fasta"                           r265      "_of_Cryptococcus_neoformans_Serotype_B"       "seqs/c_neo_r265/c_neo_r265_*.fasta"                           r265      "_of_Cryptococcus_neoformans_Serotype_B"       01 28
#./mkalign.sh "seqs/CBS7750v3_mira.unpadded/CBS7750v3_mira.unpadded_*.fasta" cbs7750v3 "_of_Cryptococcus_gattii_Serotype_B_CBS7750v3" "seqs/CBS7750v3_mira.unpadded/CBS7750v3_mira.unpadded_*.fasta" cbs7750v3 "_of_Cryptococcus_gattii_Serotype_B_CBS7750v3" 01 28

#./mkalign.sh "seqs/c_neo_r265/c_neo_r265_*.fasta" r265 "_of_Cryptococcus_neoformans_Serotype_B" "seqs/CBS7750v3_mira.unpadded/CBS7750v3_mira.unpadded_*.fasta" cbs7750v3 "_of_Cryptococcus_gattii_Serotype_B_CBS7750v3" 01 28
#./mkalign.sh "seqs/c_neo_r265/c_neo_r265_*.fasta" r265 "_of_Cryptococcus_neoformans_Serotype_B" "seqs/CBS7750v2/CBS7750v2_*.fasta" cbs7750v2 "_Cryptococcus_gattii_CBS7750v2" 1 28
#./mkalign.sh "seqs/c_neo_r265/c_neo_r265_*.fasta" r265 "_of_Cryptococcus_neoformans_Serotype_B" "seqs/CBS7750v1/CBS7750v1_*.fasta" cbs7750v1 "_cryptococcus_gattii_CBS7750v1" 1 28


REFFOLDER=$1
REFNAME=$2
REFCHROM=$3 # _of_Cryptococcus_neoformans_Serotype_B

QRYFOLDER=$4
QRYNAME=$5
QRYCHROM=$6 # _Cryptococcus_gattii_CBS7750v2

CHROMMIN=$7 # 1
CHROMMAX=$8 # 28

ITERATING=$9


OUTNAME="out/${REFNAME}_${QRYNAME}/${REFNAME}_${QRYNAME}"

if [[ $ITERATING != 1 ]];
then
    reset
fi

echo "ARGUMENTS GIVEN: "$@
echo "REFFOLDER      : ${REFFOLDER}"
echo "REFNAME        : ${REFNAME}"
echo "REFCHROM       : ${REFCHROM}"
echo "QRYFOLDER      : ${QRYFOLDER}"
echo "QRYNAME        : ${QRYNAME}"
echo "QRYCHROM       : ${QRYCHROM}"
echo "CHROMMIN       : ${CHROMMIN}"
echo "CHROMMAX       : ${CHROMMAX}"
echo "OUTNAME        : ${OUTNAME}"
echo "ITERATING      : ${ITERATING}"
echo ""


function usage
{
    echo "<REF FOLDER> <REF NAME> <REF CHROM> <QRY FOLDER> <QRY NAME> <QRY CHROM> <MIN CHROM | 1> <MAX CHROM | 100>"
    echo "EG.: "'"seqs/c_neo_r265/c_neo_r265_*.fasta" r265 "_of_Cryptococcus_neoformans_Serotype_B" "seqs/CBS7750v3_mira.unpadded/CBS7750v3_mira.unpadded_*.fasta" cbs7750v3 "_of_Cryptococcus_gattii_Serotype_B_CBS7750v3" 01 25'
    exit 1
}

if [ "$#" -lt 8 ];
then
    echo "WRONG NUMBER OF ARGUMENTS: "$#
    usage
fi

if [ ! -d $REFOLDER ];
then
    echo REFERENCE FOLDER NOT DEFINED
    usage
fi

if [ -z "$REFNAME" ];
then
    echo REFERENCE NAME NOT DEFINED
    usage
fi

if [ -z "$REFCHROM" ];
then
    echo QUERY CHROMOSSOME EPITOPE NOT DEFINED
    usage
fi

if [ ! -d $QRYFOLDER ];
then
    echo QUERY FOLDER NOT DEFINED: $QRYFOLDER
    usage
fi

if [ -z "$QRYNAME" ];
then
    echo QUERY NAME NOT DEFINED
    usage
fi

if [ -z "$QRYCHROM" ];
then
    echo QUERY CHROMOSSOME EPITOPE NOT DEFINED
    usage
fi

if [ -z "$CHROMMIN" ];
then
    echo MINIMUM CHROMOSSOME NOT DEFINED. SETTING TO 1
    CHROMMIN=1
fi

if [ -z "$CHROMMAX" ];
then
    echo LAST CHROMOSSOME NOT DEFINED. SETTING TO 100
    CHROMMAX=100
fi

if [ $CHROMMIN -gt $CHROMMAX ];
then
    echo CHROMOSSOME MINIMUM BIGGER THAN CHROMOSSOME MAX. SWAPING
    CTMP=$CHROMMAX
    CHROMMAX=$CHROMMIN
    CHROMMIN=$CTMP
fi



if [[ $ITERATING != 1 ]];
then
    mkdir db 2>/dev/null
    echo "CREATING DB"
    ./lastdb -v db/${REFNAME} ${REFFOLDER}/*.fasta
    ./lastdb -v db/${QRYNAME} ${QRYFOLDER}/*.fasta
fi




if [[ $ITERATING != 1 ]];
then
    COMMAND="$QRYFOLDER $QRYNAME $QRYCHROM $REFFOLDER $REFNAME $REFCHROM $CHROMMIN $CHROMMAX 1"
    echo "STARTING ITERATION :: $COMMAND"
    $0 $COMMAND

    COMMAND="$QRYFOLDER $QRYNAME $QRYCHROM $QRYFOLDER $QRYNAME $QRYCHROM $CHROMMIN $CHROMMAX 1"
    echo "STARTING ITERATION :: $COMMAND"
    $0 $COMMAND

    COMMAND="$REFFOLDER $REFNAME $REFCHROM $REFFOLDER $REFNAME $REFCHROM $CHROMMIN $CHROMMAX 1"
    echo "STARTING ITERATION :: $COMMAND"
    $0 $COMMAND
fi


mkdir out 2>/dev/null
mkdir "out/${REFNAME}_${QRYNAME}" 2>/dev/null
rm    "${OUTNAME}*"               2>/dev/null

echo "LASTING"
    ./lastal -v -o ${OUTNAME}.maf db/${REFNAME} ${QRYFOLDER}/*.fasta
	if [ ! -s "${OUTNAME}.maf" ];
	then
		echo FILE ${OUTNAME}.maf NOT FOUND
		exit 1;
	fi

echo "CONVERTING TO TAB"
    scripts/maf-convert.py tab           ${OUTNAME}.maf        > ${OUTNAME}.tab
	if [ ! -s "${OUTNAME}.tab" ];
	then
		echo FILE ${OUTNAME}.tab NOT FOUND
		exit 1;
	fi

echo "SORTING"
    scripts/maf-sort.sh                  ${OUTNAME}.maf             > ${OUTNAME}_sort.maf
	if [ ! -s "${OUTNAME}_sort.maf" ];
	then
		echo FILE ${OUTNAME}_sort.maf NOT FOUND
		exit 1;
	fi

echo "CONVERTING TO TAB"
    scripts/maf-convert.py tab           ${OUTNAME}_sort.maf        > ${OUTNAME}_sort.tab
	if [ ! -s "${OUTNAME}_sort.tab" ];
	then
		echo FILE ${OUTNAME}_sort.tab NOT FOUND
		exit 1;
	fi

echo "EXCLUDING PARALOGOUS"
    scripts/last-reduce-alignments.sh -d ${OUTNAME}_sort.maf        > ${OUTNAME}_sort_no_par.maf
	if [ ! -s "${OUTNAME}_sort_no_par.maf" ];
	then
		echo FILE ${OUTNAME}_sort_no_par.maf NOT FOUND
		exit 1;
	fi

echo "CONVERTING TO HTML"
    scripts/maf2html.py                  ${OUTNAME}_sort_no_par.maf > ${OUTNAME}_sort_no_par.html
	if [ ! -s "${OUTNAME}_sort_no_par.html" ];
	then
		echo FILE ${OUTNAME}_sort_no_par.html NOT FOUND
		exit 1;
	fi

echo "CONVERTING TO TAB"
    scripts/maf-convert.py tab           ${OUTNAME}_sort_no_par.maf > ${OUTNAME}_sort_no_par.tab
	if [ ! -s "${OUTNAME}_sort_no_par.tab" ];
	then
		echo FILE ${OUTNAME}_sort_no_par.tab NOT FOUND
		exit 1;
	fi


#scripts/last-dotplot2.py             ${OUTNAME}.tab          ${OUTNAME}.png


echo "EXPORTING CHROMOSSOMES"
for (( NUMBER=${CHROMMIN}; NUMBER<=${CHROMMAX}; NUMBER++ ))
{
	NNUMBER=${NUMBER}
	if [ "$NNUMBER" -lt "10" ]
	then
		NNUMBER="0${NUMBER}"
	fi
	echo "EXPORTING CHROM ${NNUMBER} FROM CHROMS ${REFCHROM} ${QRYCHROM}  FOR FILES FOR FILE ${OUTNAME}.tab AND ${OUTNAME}_sort.tab AND ${OUTNAME}_sort_no_par.tab"


	cat ${OUTNAME}.tab             |  perl -ne '@_ = split("\t", $_); print $_ if (($_[1] =~ "'${NNUMBER}${REFCHROM}'") && ($_[6] =~ "'${NNUMBER}${QRYCHROM}'"))'   > ${OUTNAME}_${NNUMBER}.tab
	cat ${OUTNAME}_sort.tab        |  perl -ne '@_ = split("\t", $_); print $_ if (($_[1] =~ "'${NNUMBER}${REFCHROM}'") && ($_[6] =~ "'${NNUMBER}${QRYCHROM}'"))'   > ${OUTNAME}_sort_${NNUMBER}.tab
	cat ${OUTNAME}_sort_no_par.tab |  perl -ne '@_ = split("\t", $_); print $_ if (($_[1] =~ "'${NNUMBER}${REFCHROM}'") && ($_[6] =~ "'${NNUMBER}${QRYCHROM}'"))'   > ${OUTNAME}_sort_no_par_${NNUMBER}.tab

	if [ -s "${OUTNAME}_${NNUMBER}.tab" ];
	then
		scripts/last-dotplot2.py             ${OUTNAME}_${NNUMBER}.tab          ${OUTNAME}_${NNUMBER}.png
	fi

	if [ -s "${OUTNAME}_sort_${NNUMBER}.tab" ];
	then
		scripts/last-dotplot2.py             ${OUTNAME}_sort_${NNUMBER}.tab          ${OUTNAME}_sort_${NNUMBER}.png
	fi

	if [ -s "${OUTNAME}_sort_no_par_${NNUMBER}.tab" ];
	then
		scripts/last-dotplot2.py             ${OUTNAME}_sort_no_par_${NNUMBER}.tab          ${OUTNAME}_sort_no_par_${NNUMBER}.png
	fi
}



#bscripts/last-map-probs.py            ${OUTNAME}_sort_no_par.tab > ${OUTNAME}_sort_no_par_probs.tab
