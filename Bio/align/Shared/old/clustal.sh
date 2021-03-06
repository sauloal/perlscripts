#!/bin/bash
PREFIX=$1
RUN=1
MAX=3

CLUSTAL="./clustalw2"
PARAM="-BATCH -ALIGN -TREE -PIM -TYPE=DNA -OUTPUT=FASTA"
PARAM="$PARAM -ITERATION=TREE -NUMITER=1000 -BOOTSTRAP=1000"
PARAM="$PARAM -PWGAPOPEN=10 -PWGAPEXT=6.66 -GAPOPEN=10 -GAPEXT=6.66"
PARAM="$PARAM -OUTPUTTREE=NJ -CLUSTERING=UPGMA -KIMURA";
#-ALIGN              :do full multiple alignment.
#-TREE               :calculate NJ tree.
#-PIM                :output percent identity matrix (while calculating the tree)
#-BOOTSTRAP(=n)      :bootstrap a NJ tree (n= number of bootstraps; def. = 1000).
#-QUICKTREE   :use FAST algorithm for the alignment guide tree
#-TYPE=       :PROTEIN or DNA sequences
#-NEGATIVE    :protein alignment with negative values in matrix
#-OUTFILE=    :sequence alignment file name
#-OUTPUT=     :GCG, GDE, PHYLIP, PIR or NEXUS
#-QUIET       :Reduce console output to minimum
#-STATS=      :Log some alignents statistics to file
#-PAIRGAP=n   :gap penalty
#-SCORE       :PERCENT or ABSOLUTE
#-PWDNAMATRIX= :DNA weight matrix=IUB, CLUSTALW or filename
#-PWGAPOPEN=f  :gap opening penalty
#-PWGAPEXT=f   :gap opening penalty
#-DNAMATRIX=    :DNA weight matrix=IUB, CLUSTALW or filename
#-GAPOPEN=f     :gap opening penalty
#-GAPEXT=f      :gap extension penalty
#-TYPE=         :PROTEIN or DNA
#-ITERATION=    :NONE or TREE or ALIGNMENT
#-NUMITER=n     :maximum number of iterations to perform
#-CLUSTERING=   :NJ or UPGMA
#-OUTPUTTREE=nj OR phylip OR dist OR nexus
#-NEWTREE=    :file for new guide tree
#-USETREE=    :file for old guide tree
#-ITERATION=    :NONE or TREE or ALIGNMENT

echo "RUNNING CLUSTAL"
echo "  FOLDER: $INFOLDER"
echo "  PWD   : "`pwd`
##ls -1 xml_merged/*.fasta | grep -v "fasta.clustal.fasta" | xargs --delimiter="\n" -n 1 -r -P 4 ./clustal

for INFILE in `ls -1 $PREFIX*.fasta | grep -v "fasta.clustal.fasta"`
do
    OUTFILEF="$INFILE.clustal.fasta"
    OUTFILET="$INFILE.clustal.dnd"
    OUTFILES="$INFILE.clustal.stat"
    OUTFILEL="$INFILE.clustal.log"
    CMD1="$CLUSTAL $PARAM -INFILE='$INFILE' -OUTFILE='$OUTFILEF' -STATS='$OUTFILES' -NEWTREE='$OUTFILET'"
    echo "     CMD PARAM        : $PARAM"
    echo "     CMD CLUSTAL      : $CLUSTAL"
    echo "     CMD INFILE       : $INFILE"
    #echo "     CMD OUTFILE FASTA: $OUTFILEF"
    #echo "     CMD OUTFILE TREE : $OUTFILET"
    #echo "     CMD OUTFILE STAT : $OUTFILES"
    #echo "     CMD OUTFILE LOG  : $OUTFILEL"
    #echo "     CMD ALIGNMENT    : $CMD1"
    #echo "     CMD TREE         : $CMD1"
    echo
    echo

    if [ $RUN -ne 0 ]; then
        eval "$CMD1 &> '$OUTFILEL' &"

        PIDNO=$( ps ax | grep -v "ps ax" | grep -v grep | grep $CLUSTAL | awk '{ print $1 }' )
        TOTAL=$(echo $PIDNO | wc -w)

        while [ $TOTAL -ge $MAX ]   # If no pid, then process is not running.
        do
          echo "WAITING. $TOTAL"
          sleep 2s
          PIDNO=$( ps ax | grep -v "ps ax" | grep -v grep | grep $CLUSTAL | awk '{ print $1 }' )
          TOTAL=$(echo $PIDNO | wc -w)
        done
    fi
done

#PIDNO=$( ps ax | grep -v "ps ax" | grep -v grep | grep $CLUSTAL | awk '{ print $1 }' )
#while [ -n "$PIDNO" ]   # If no pid, then process is not running.
#do
#  TOTAL=$(echo $PIDNO | wc -w)
#  echo "STILL RUNNING. $TOTAL"
#  sleep 2s
#  PIDNO=$( ps ax | grep -v "ps ax" | grep -v grep | grep $CLUSTAL | awk '{ print $1 }' )
#done
#echo "LEAVING"
