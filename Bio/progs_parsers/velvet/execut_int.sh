# INPUT=resumeUNUSED.fastq
# OUTPUT=WHOLE13
INPUT=$1
OUTPUT=$2
MINLENG=40


KMER=("27" "29" "31")
MIN=("1" "2" "5" "40")
MAX=("17" "20" "40" "200")
EXP=("1" "2" "3" "5" "9" "13" "15" "17" "21" "23")
DIV=("0.33")
IND=("6")
GAP=("5")

TOTAL=$((${#KMER[@]}*${#MIN[@]}*${#MAX[@]}*${#EXP[@]}*${#DIV[@]}*${#IND[@]}*${#GAP[@]}))
COUNT=0
#MAX=("5" "17")
echo $TOTAL
for kmer in $(seq 0 $((${#KMER[@]}-1)))
do
  LKMER=${KMER[$kmer]}
  ./velveth output$LKMER $LKMER -fastq input/$INPUT
  for min in $(seq 0 $((${#MIN[@]}-1)))
  do
    for max in $(seq 0 $((${#MAX[@]}-1)))
    do
      for exp in $(seq 0 $((${#EXP[@]}-1)))
      do
        for div in $(seq 0 $((${#DIV[@]}-1)))
        do
          for ind in $(seq 0 $((${#IND[@]}-1)))
          do
            for gap in $(seq 0 $((${#GAP[@]}-1)))
            do
		COUNT=$(($COUNT + 1))
		LMIN=${MIN[$min]}
		LMAX=${MAX[$max]}
		LEXP=${EXP[$exp]}
		LDIV=${DIV[$div]}
		LIND=${IND[$ind]}
		LGAP=${GAP[$gap]}
	
		LNAME=$LKMER\_$LMIN\_$LMAX\_$LEXP\_$LDIV\_$LIND\_$LGAP
		echo "$COUNT OF $TOTAL KMER $LKMER NAME $NAME MIN $LMIN EXP $LEXP MAX $LMAX DIV $LDIV IND $LIND GAP $LGAP NAME $LNAME"
		ln -s output$LKMER output$LNAME

		./velvetg output$LNAME/ -min_contig_lgth $MINLENG -cov_cutoff $LMIN -exp_cov $LEXP -max_coverage $LMAX -max_indel_count $LIND -max_divergence $LDIV -max_gap_count $LGAP > output$LNAME/run.log  

		./r.sh output$LNAME/stats.txt $OUTPUT\_$LNAME

# 		mv $OUTPUT\_$LNAME.pdf output$LNAME/
		tail -n 2 output$LNAME/Log >> resume.log
		cat output$LNAME/contigs.fa | grep -v ">" | wc -m >> output$LNAME/run.log
		tail -n 2 output$LNAME/run.log >> resume.log
		echo "#######################" >> resume.log
		cat output$LNAME/contigs.fa | grep ">" > contigs_$LNAME.idx
		unlink output$LNAME
            done
          done
        done
      done
    done
  done
done

mkdir $OUTPUT
mv run_output.log $OUTPUT
mv contigs*.idx $OUTPUT
mv $OUTPUT*.pdf
mv resume.log $OUTPUT
mv output* $OUTPUT

